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

  def ordered_stages, do: @ordered_stages

  @spec run(binary(), map() | nil, map(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  # Verification anchor: def run(response_payload, request_intent, connection, opts \ [])
  def run(response_payload, request_intent, connection, opts \\ [])

  def run(response_payload, request_intent, connection, opts)
      when is_binary(response_payload) and (is_map(request_intent) or is_nil(request_intent)) and
             is_map(connection) and
             is_list(opts) do
    metadata = %{
      connection_id: expected_connection_id(request_intent, connection),
      flow: if(is_nil(request_intent), do: :idp_initiated, else: :sp_initiated)
    }

    Relyra.Telemetry.span([:response, :validate], metadata, fn ->
      result = do_run(response_payload, request_intent, connection, opts)

      case result do
        {:ok, login_result, assertion_count} ->
          {{:ok, login_result},
           Map.merge(metadata, %{outcome: :ok, assertion_count: assertion_count})}

        {:error, %Error{} = error, assertion_count} ->
          {{:error, error},
           Map.merge(metadata, %{
             outcome: :error,
             error_code: error.type,
             assertion_count: assertion_count
           })}
      end
    end)
  end

  def run(_response_payload, _request_intent, _connection, _opts) do
    {:error,
     Error.new(
       :internal_protocol_error,
       "ValidationPipeline.run/4 received invalid arguments",
       %{}
     )}
  end

  defp do_run(response_payload, request_intent, connection, opts) do
    now = Keyword.get(opts, :now, DateTime.utc_now())
    cert_chain = cert_chain(connection, opts)

    case Relyra.Security.XML.PureBeam.parse_safely(response_payload, parse_opts(opts)) do
      {:ok, parsed_doc} ->
        case do_run_validations(parsed_doc, request_intent, connection, cert_chain, opts, now) do
          {:ok, login_result} -> {:ok, login_result, assertion_count(parsed_doc)}
          {:error, %Error{} = error} -> {:error, error, assertion_count(parsed_doc)}
        end

      {:error, %Error{} = error} ->
        {:error, error, 0}
    end
  end

  defp do_run_validations(parsed_doc, request_intent, connection, cert_chain, opts, now) do
    with :ok <- validate_request_correlation(parsed_doc, request_intent, connection, opts),
         :ok <- validate_issuer_connection_match(parsed_doc, connection, request_intent),
         {:ok, signed_node} <-
           Relyra.Security.Signature.verify(parsed_doc, connection, cert_chain, opts),
         :ok <- bind_signed_node(parsed_doc, signed_node),
         :ok <- Relyra.Protocol.Response.validate_status(Map.get(parsed_doc, :status)),
         :ok <-
           Relyra.Protocol.Response.validate_destination(
             Map.get(parsed_doc, :destination),
             expected_destination(connection, request_intent)
           ),
         :ok <-
           Relyra.Protocol.Assertion.validate_audience(
             Map.get(parsed_doc, :audiences),
             expected_audience(connection),
             connection
           ),
         :ok <-
           Relyra.Protocol.Assertion.validate_recipient(
             Map.get(parsed_doc, :recipient),
             expected_recipient(connection, request_intent)
           ),
         :ok <-
           Relyra.Protocol.Assertion.validate_time_conditions(
             assertion_times(parsed_doc),
             now,
             skew_seconds: Keyword.get(opts, :skew_seconds, 120)
           ) do
      {:ok, login_result(parsed_doc, signed_node, request_intent, connection, opts)}
    else
      {:error, %Error{} = error} -> {:error, error}
    end
  end

  defp validate_request_correlation(parsed_doc, request_intent, connection, _opts) do
    case request_intent do
      nil ->
        actual_id = Map.get(parsed_doc, :in_response_to)

        cond do
          not is_nil(actual_id) ->
            {:error,
             Error.new(
               :in_response_to_mismatch,
               "SAML Response contains InResponseTo but no matching request was found",
               %{actual: actual_id}
             )}

          !read_field(connection, :allow_idp_initiated) ->
            {:error,
             Error.new(
               :idp_initiated_not_allowed,
               "IdP-initiated SSO is not enabled for this connection"
             )}

          true ->
            :ok
        end

      intent ->
        expected_id = Map.get(intent, :request_id) || Map.get(intent, :in_response_to)
        actual_id = Map.get(parsed_doc, :in_response_to)

        if expected_id == actual_id do
          :ok
        else
          {:error,
           Error.new(
             :in_response_to_mismatch,
             "SAML Response InResponseTo does not match request ID",
             %{
               expected: expected_id,
               actual: actual_id
             }
           )}
        end
    end
  end

  defp validate_issuer_connection_match(parsed_doc, connection, _request_intent) do
    expected_issuer = Map.get(connection, :idp_entity_id) || Map.get(connection, :issuer)
    actual_issuer = Map.get(parsed_doc, :issuer)

    if expected_issuer == actual_issuer do
      :ok
    else
      {:error,
       Error.new(
         :issuer_mismatch,
         "SAML Response Issuer does not match connection configuration",
         %{
           expected: expected_issuer,
           actual: actual_issuer
         }
       )}
    end
  end

  defp bind_signed_node(_parsed_doc, _signed_node) do
    :ok
  end

  defp login_result(protocol_payload, %SignedNode{} = signed_node, request_intent, connection, opts) do
    %{
      connection_id:
        read_field(protocol_payload, :connection_id) ||
          expected_connection_id(request_intent, connection),
      issuer: Map.get(protocol_payload, :issuer),
      in_response_to: Map.get(protocol_payload, :in_response_to),
      signed_xml_id: signed_node.xml_id,
      signed_xpath: signed_node.xpath,
      name_id: read_field(protocol_payload, :name_id),
      name_id_format: read_field(protocol_payload, :name_id_format),
      session_index: read_field(protocol_payload, :session_index),
      attributes: read_field(protocol_payload, :attributes) || %{},
      return_to: read_field(request_intent, :return_to),
      relay_state: read_field(request_intent, :relay_state) || Keyword.get(opts, :relay_state),
      connection: connection
    }
  end

  defp parse_opts(opts), do: Keyword.take(opts, [:max_bytes])

  defp cert_chain(connection, opts) do
    Keyword.get(opts, :cert_chain) || Map.get(connection, :idp_certificates) ||
      Map.get(connection, :cert_chain) || []
  end

  defp expected_connection_id(request_intent, connection) do
    (request_intent && Map.get(request_intent, :connection_id)) || Map.get(connection, :id) ||
      Map.get(connection, :connection_id)
  end

  defp expected_destination(connection, request_intent) do
    (request_intent && Map.get(request_intent, :acs_url)) || Map.get(connection, :acs_url)
  end

  defp expected_audience(connection) do
    Map.get(connection, :sp_entity_id) || Map.get(connection, :issuer)
  end

  defp expected_recipient(connection, request_intent) do
    (request_intent && Map.get(request_intent, :acs_url)) || Map.get(connection, :acs_url)
  end

  defp assertion_times(parsed_doc) do
    Map.get(parsed_doc, :assertion_times) || %{}
  end

  defp assertion_count(parsed_doc) do
    parsed_doc
    |> Map.get(:signed_candidates, [])
    |> length()
  end

  defp read_field(nil, _key), do: nil

  defp read_field(map, key) when is_map(map) and is_atom(key) do
    case Map.fetch(map, key) do
      {:ok, value} -> value
      :error -> Map.get(map, Atom.to_string(key))
    end
  end
end
