defmodule Relyra.Protocol.LogoutRequest do
  @moduledoc false

  alias Relyra.Error
  alias Relyra.Security.XML.SaxyTree.Node

  @default_name_id_format "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified"
  @request_id_prefix "id_"

  @spec build(map(), map(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def build(connection, relay_context, opts \\ [])

  def build(connection, relay_context, opts) when is_map(connection) and is_map(relay_context) do
    _ = relay_context

    with {:ok, destination} <-
           required_field(connection, [:destination, :idp_slo_url], "destination"),
         {:ok, issuer} <- required_field(connection, [:issuer, :sp_entity_id], "issuer"),
         {:ok, name_id} <- required_opt(opts, :name_id, "name_id"),
         {:ok, session_index} <- required_opt(opts, :session_index, "session_index") do
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
         name_id: name_id,
         name_id_format: name_id_format,
         session_index: session_index
       }}
    end
  end

  def build(_connection, _relay_context, _opts) do
    {:error,
     Error.new(:logout_request_invalid, "Connection and relay context must be maps", %{
       required: [:connection, :relay_context]
     })}
  end

  @doc """
  Strictly parses a LogoutRequest from a SaxyTree root node.
  We must rely exclusively on the `SaxyTree` (from `PureBeam.parse_safely/2`) 
  to extract elements like `<samlp:SessionIndex>` and `<saml:NameID>`.
  """
  @spec from_parsed_doc(term()) :: {:ok, map()} | {:error, Error.t()}
  def from_parsed_doc(%Node{} = root) do
    id = attr(root, "ID")
    destination = attr(root, "Destination")
    issue_instant = attr(root, "IssueInstant")

    issuer = first_text(root, "Issuer")
    name_id = first_text(root, "NameID")
    session_index = first_text(root, "SessionIndex")

    fields = %{
      id: id,
      destination: destination,
      issue_instant: issue_instant,
      issuer: issuer,
      name_id: name_id,
      session_index: session_index
    }

    require_present_fields(
      fields,
      [:id, :issuer, :name_id, :session_index],
      :missing_protocol_field,
      "Required fields are missing from LogoutRequest payload"
    )
  end

  def from_parsed_doc(parsed_doc)
      when is_map(parsed_doc) and is_map_key(parsed_doc, :parse_tree) do
    from_parsed_doc(parsed_doc.parse_tree)
  end

  def from_parsed_doc(_),
    do: {:error, Error.new(:invalid_parsed_doc, "Invalid parsed document format", %{})}

  @spec to_xml(map()) :: binary()
  def to_xml(
        %{
          id: id,
          issue_instant: issue_instant,
          destination: destination,
          issuer: issuer,
          name_id: name_id,
          session_index: session_index
        } = map
      ) do
    name_id_format = Map.get(map, :name_id_format, @default_name_id_format)

    ~s(<samlp:LogoutRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="#{id}" Version="2.0" IssueInstant="#{issue_instant}" Destination="#{destination}"><saml:Issuer>#{issuer}</saml:Issuer><saml:NameID Format="#{name_id_format}">#{name_id}</saml:NameID><samlp:SessionIndex>#{session_index}</samlp:SessionIndex></samlp:LogoutRequest>)
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
         Error.new(:logout_request_invalid, "Missing required LogoutRequest field", %{
           field: label
         })}
    end
  end

  defp required_opt(opts, key, label) do
    case Keyword.get(opts, key) do
      value when is_binary(value) and value != "" ->
        {:ok, value}

      _ ->
        {:error,
         Error.new(:logout_request_invalid, "Missing required LogoutRequest option", %{
           field: label
         })}
    end
  end

  defp require_present_fields(fields, required_keys, error_type, message) do
    missing =
      Enum.reject(required_keys, fn key ->
        present?(Map.get(fields, key))
      end)

    if missing == [] do
      {:ok, fields}
    else
      {:error,
       Error.new(error_type, message, %{
         expected: required_keys,
         actual: required_keys -- missing,
         missing: missing
       })}
    end
  end

  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(value) when is_list(value), do: value != []
  defp present?(value), do: not is_nil(value)

  # --- tree-walk derivation helpers ------------------------------------------

  defp find_first(%Node{local: local} = node, local), do: node

  defp find_first(%Node{children: children}, local) do
    Enum.find_value(children, fn child -> find_first(child, local) end)
  end

  defp find_first(_other, _local), do: nil

  defp first_text(%Node{} = root, local) do
    case find_first(root, local) do
      %Node{} = node -> trimmed_text(node)
      _ -> nil
    end
  end

  defp trimmed_text(%Node{text: text}), do: String.trim(text)

  defp attr(%Node{attrs: attrs}, attribute_name) do
    case List.keyfind(attrs, attribute_name, 0) do
      {_name, value} -> String.trim(value)
      nil -> nil
    end
  end

  defp attr(_other, _attribute_name), do: nil
end
