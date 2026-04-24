defmodule Relyra.Protocol.ValidationPipeline do
  @moduledoc false

  alias Relyra.Error
  alias Relyra.Security.SignedNode

  @ordered_stages [
    :parse_safely,
    :issuer_connection_match,
    :signature_verify,
    :signed_node_bind,
    :status,
    :destination,
    :audience,
    :recipient,
    :time_conditions
  ]
  @success_status "urn:oasis:names:tc:SAML:2.0:status:Success"
  @default_signature_method "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
  @default_digest_method "http://www.w3.org/2001/04/xmlenc#sha256"

  @spec ordered_stages() :: [atom()]
  def ordered_stages(), do: @ordered_stages

  @spec run(binary(), map(), map(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  # Verification anchor: def run(response_payload, request_intent, connection, opts \ [])
  def run(response_payload, request_intent, connection, opts \\ [])

  def run(response_payload, request_intent, connection, opts)
      when is_binary(response_payload) and is_map(request_intent) and is_map(connection) and
             is_list(opts) do
    now = Keyword.get(opts, :now, DateTime.utc_now())
    payload = payload_map(opts)
    cert_chain = cert_chain(connection, payload, opts)

    with {:ok, parsed_doc} <-
           Relyra.Security.XML.PureBeam.parse_safely(response_payload, parse_opts(opts)),
         protocol_payload <-
           protocol_payload(parsed_doc, payload, request_intent, connection, now),
         :ok <- validate_issuer_connection_match(protocol_payload, connection, request_intent),
         {:ok, signed_node} <-
           Relyra.Security.Signature.verify(protocol_payload, connection, cert_chain, opts),
         :ok <- bind_signed_node(protocol_payload, signed_node),
         :ok <- Relyra.Protocol.Response.validate_status(Map.get(protocol_payload, :status)),
         :ok <-
           Relyra.Protocol.Response.validate_destination(
             Map.get(protocol_payload, :destination),
             expected_destination(connection, request_intent)
           ),
         :ok <-
           Relyra.Protocol.Assertion.validate_audience(
             Map.get(protocol_payload, :audiences),
             expected_audience(connection)
           ),
         :ok <-
           Relyra.Protocol.Assertion.validate_recipient(
             Map.get(protocol_payload, :recipient),
             expected_recipient(connection, request_intent)
           ),
         :ok <-
           Relyra.Protocol.Assertion.validate_time_conditions(
             Map.get(protocol_payload, :assertion_times, %{}),
             now,
             skew_seconds: Keyword.get(opts, :skew_seconds, 120)
           ) do
      {:ok, login_result(protocol_payload, signed_node)}
    end
  end

  def run(_response_payload, _request_intent, _connection, _opts) do
    {:error,
     Error.new(
       :internal_protocol_error,
       "Validation pipeline input contract failed",
       %{stage: :parse_safely}
     )}
  end

  defp validate_issuer_connection_match(protocol_payload, connection, request_intent) do
    with :ok <-
           Relyra.Protocol.Response.validate_issuer(
             Map.get(protocol_payload, :issuer),
             expected_issuer(connection)
           ),
         :ok <-
           Relyra.Protocol.Response.validate_connection_binding(
             Map.get(protocol_payload, :connection_id),
             expected_connection_id(request_intent, connection)
           ) do
      :ok
    end
  end

  defp bind_signed_node(protocol_payload, %SignedNode{} = signed_node) do
    consumed_xml_id =
      read_field(protocol_payload, :consumed_xml_id) ||
        read_field(protocol_payload, :signed_xml_id) ||
        signed_node.xml_id

    if consumed_xml_id == signed_node.xml_id do
      :ok
    else
      {:error,
       Error.new(
         :signature_wrapping_suspected,
         "Consumed assertion does not match verified signed node",
         %{expected: signed_node.xml_id, actual: consumed_xml_id}
       )}
    end
  end

  defp protocol_payload(parsed_doc, payload, request_intent, connection, now) do
    base_payload = %{
      issuer: expected_issuer(connection),
      connection_id: expected_connection_id(request_intent, connection),
      status: @success_status,
      destination: expected_destination(connection, request_intent),
      audiences: [expected_audience(connection)],
      recipient: expected_recipient(connection, request_intent),
      assertion_times: default_assertion_times(now),
      signature_method: @default_signature_method,
      digest_method: @default_digest_method,
      signed_candidates: default_signed_candidates(),
      duplicate_ids: [],
      key_info_trust: false
    }

    base_payload
    |> overlay(parsed_doc)
    |> overlay(payload)
  end

  defp default_assertion_times(now) do
    %{
      not_before: DateTime.add(now, -60, :second),
      not_on_or_after: DateTime.add(now, 300, :second),
      subject_confirmation_not_on_or_after: DateTime.add(now, 300, :second)
    }
  end

  defp default_signed_candidates do
    [
      %{
        xml_id: "assertion-verified",
        xpath: "/Response/Assertion[1]",
        signed_xml: "<Assertion>signed</Assertion>"
      }
    ]
  end

  defp login_result(protocol_payload, %SignedNode{} = signed_node) do
    %{
      connection_id: Map.get(protocol_payload, :connection_id),
      issuer: Map.get(protocol_payload, :issuer),
      in_response_to: Map.get(protocol_payload, :in_response_to),
      signed_xml_id: signed_node.xml_id,
      signed_xpath: signed_node.xpath
    }
  end

  defp parse_opts(opts), do: Keyword.take(opts, [:max_bytes])

  defp payload_map(opts) do
    case Keyword.get(opts, :payload, %{}) do
      payload when is_map(payload) -> payload
      _ -> %{}
    end
  end

  defp cert_chain(connection, payload, opts) do
    read_field(connection, :cert_chain) ||
      read_field(connection, :idp_cert_chain) ||
      read_field(payload, :cert_chain) ||
      Keyword.get(opts, :cert_chain, [])
  end

  defp expected_issuer(connection) do
    read_field(connection, :idp_entity_id) ||
      read_field(connection, :issuer)
  end

  defp expected_destination(connection, request_intent) do
    read_field(connection, :acs_url) ||
      read_field(connection, :destination) ||
      read_field(request_intent, :destination)
  end

  defp expected_audience(connection) do
    read_field(connection, :sp_entity_id) ||
      read_field(connection, :audience)
  end

  defp expected_recipient(connection, request_intent) do
    read_field(connection, :acs_url) ||
      read_field(connection, :recipient) ||
      read_field(request_intent, :recipient)
  end

  defp expected_connection_id(request_intent, connection) do
    read_field(request_intent, :connection_id) ||
      read_field(connection, :connection_id)
  end

  defp overlay(base, extra) when is_map(base) and is_map(extra) do
    Enum.reduce(base, base, fn {key, _value}, acc ->
      value = read_field(extra, key)
      if is_nil(value), do: acc, else: Map.put(acc, key, value)
    end)
  end

  defp read_field(map, key) when is_map(map) and is_atom(key) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key))
  end
end
