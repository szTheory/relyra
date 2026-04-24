defmodule Relyra.Protocol.AuthnRequest do
  @moduledoc false

  alias Relyra.Error

  @default_protocol_binding "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
  @default_name_id_format "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified"
  @request_id_prefix "id_"

  @spec build(map(), map(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def build(connection, relay_context, opts \\ [])

  def build(connection, relay_context, opts) when is_map(connection) and is_map(relay_context) do
    _ = relay_context

    with {:ok, destination} <- required_field(connection, [:destination, :idp_sso_url], "destination"),
         {:ok, issuer} <- required_field(connection, [:issuer, :sp_entity_id], "issuer"),
         {:ok, acs_url} <- required_field(connection, [:acs_url], "acs_url") do
      protocol_binding = Keyword.get(opts, :protocol_binding, @default_protocol_binding)
      name_id_format = Keyword.get(opts, :name_id_format, @default_name_id_format)

      {:ok,
       %{
         id:
           ensure_request_id_prefix(
             Base.url_encode64(:crypto.strong_rand_bytes(16), padding: false)
           ),
         issue_instant: current_issue_instant(opts),
         destination: destination,
         issuer: issuer,
         acs_url: acs_url,
         protocol_binding: protocol_binding,
         name_id_format: name_id_format
       }}
    end
  end

  def build(_connection, _relay_context, _opts) do
    {:error,
     Error.new(:authn_request_invalid, "Connection and relay context must be maps", %{
       required: [:connection, :relay_context]
     })}
  end

  @spec to_xml(map()) :: binary()
  def to_xml(%{
        id: id,
        issue_instant: issue_instant,
        destination: destination,
        issuer: issuer,
        acs_url: acs_url,
        protocol_binding: protocol_binding,
        name_id_format: name_id_format
      }) do
    ~s(<samlp:AuthnRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="#{id}" Version="2.0" IssueInstant="#{issue_instant}" Destination="#{destination}" AssertionConsumerServiceURL="#{acs_url}" ProtocolBinding="#{protocol_binding}"><saml:Issuer>#{issuer}</saml:Issuer><samlp:NameIDPolicy Format="#{name_id_format}" AllowCreate="true" /></samlp:AuthnRequest>)
  end

  defp current_issue_instant(opts) do
    opts
    |> Keyword.get(:now, DateTime.utc_now())
    |> DateTime.truncate(:second)
    |> DateTime.to_iso8601()
  end

  defp ensure_request_id_prefix(id) when is_binary(id) do
    if String.starts_with?(id, @request_id_prefix), do: id, else: "id_" <> id
  end

  defp required_field(connection, candidate_keys, label) do
    value =
      Enum.find_value(candidate_keys, fn key ->
        Map.get(connection, key) || Map.get(connection, Atom.to_string(key))
      end)

    case value do
      value when is_binary(value) and value != "" ->
        {:ok, value}

      _ ->
        {:error,
         Error.new(:authn_request_invalid, "Missing required AuthnRequest field", %{field: label})}
    end
  end
end
