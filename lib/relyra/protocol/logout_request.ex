defmodule Relyra.Protocol.LogoutRequest do
  @moduledoc false

  alias Relyra.Error

  @request_id_prefix "id_"

  @spec build(map(), map(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def build(connection, subject, opts \\ [])

  def build(connection, subject, opts) when is_map(connection) and is_map(subject) do
    with {:ok, destination} <- required_field(connection, [:idp_slo_url], "destination"),
         {:ok, issuer} <- required_field(connection, [:issuer, :sp_entity_id], "issuer"),
         {:ok, name_id} <- required_field(subject, [:name_id], "name_id") do
      session_index = Map.get(subject, :session_index)

      {:ok,
       %{
         id:
           ensure_request_id_prefix(
             Base.url_encode64(:crypto.strong_rand_bytes(16), padding: false)
           ),
         issue_instant: current_issue_instant(opts),
         destination: destination,
         issuer: issuer,
         name_id: name_id,
         session_index: session_index
       }}
    end
  end

  def build(_connection, _subject, _opts) do
    {:error,
     Error.new(:logout_request_invalid, "Connection and subject must be maps", %{
       required: [:connection, :subject]
     })}
  end

  @spec to_xml(map()) :: binary()
  def to_xml(
        %{
          id: id,
          issue_instant: issue_instant,
          destination: destination,
          issuer: issuer,
          name_id: name_id
        } = data
      ) do
    session_index_xml =
      case Map.get(data, :session_index) do
        nil -> ""
        val -> ~s(<samlp:SessionIndex>#{val}</samlp:SessionIndex>)
      end

    ~s(<samlp:LogoutRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="#{id}" Version="2.0" IssueInstant="#{issue_instant}" Destination="#{destination}"><saml:Issuer>#{issuer}</saml:Issuer><saml:NameID>#{name_id}</saml:NameID>#{session_index_xml}</samlp:LogoutRequest>)
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

  defp required_field(data, candidate_keys, label) do
    value =
      Enum.find_value(candidate_keys, fn key ->
        Map.get(data, key) || Map.get(data, Atom.to_string(key))
      end)

    case value do
      value when is_binary(value) and value != "" ->
        {:ok, value}

      _ ->
        {:error,
         Error.new(:logout_request_invalid, "Missing required LogoutRequest field", %{
           field: label
         })}
    end
  end
end
