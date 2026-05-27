defmodule Relyra.Protocol.LogoutResponse do
  @moduledoc false

  alias Relyra.Error
  alias Relyra.Protocol.Response
  alias Relyra.Security.XML.SaxyTree.Node

  @request_id_prefix "id_"
  @success_status "urn:oasis:names:tc:SAML:2.0:status:Success"

  @spec build(map(), map(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def build(connection, relay_context, opts \\ [])

  def build(connection, relay_context, opts) when is_map(connection) and is_map(relay_context) do
    _ = relay_context

    with {:ok, destination} <-
           required_field(connection, [:destination, :idp_slo_url], "destination"),
         {:ok, issuer} <- required_field(connection, [:issuer, :sp_entity_id], "issuer") do
      in_response_to = Keyword.get(opts, :in_response_to)
      status = Keyword.get(opts, :status, @success_status)

      {:ok,
       %{
         id:
           ensure_request_id_prefix(
             Base.url_encode64(:crypto.strong_rand_bytes(16), padding: false)
           ),
         issue_instant: current_issue_instant(opts),
         destination: destination,
         issuer: issuer,
         in_response_to: in_response_to,
         status: status
       }}
    end
  end

  def build(_connection, _relay_context, _opts) do
    {:error,
     Error.new(:logout_response_invalid, "Connection and relay context must be maps", %{
       required: [:connection, :relay_context]
     })}
  end

  @doc """
  Strictly parses a LogoutResponse from a SaxyTree root node.
  We must rely exclusively on the `SaxyTree` (from `PureBeam.parse_safely/2`) 
  to extract elements like `<saml:Issuer>` and `<samlp:StatusCode>`.
  """
  @spec from_parsed_doc(term()) :: {:ok, map()} | {:error, Error.t()}
  def from_parsed_doc(%Node{} = root) do
    id = attr(root, "ID")
    destination = attr(root, "Destination")
    in_response_to = attr(root, "InResponseTo")
    issue_instant = attr(root, "IssueInstant")

    issuer = first_text(root, "Issuer")
    status = first_attr(root, "StatusCode", "Value")

    fields = %{
      id: id,
      destination: destination,
      in_response_to: in_response_to,
      issue_instant: issue_instant,
      issuer: issuer,
      status: status
    }

    require_present_fields(
      fields,
      [:id, :issuer, :status],
      :missing_protocol_field,
      "Required fields are missing from LogoutResponse payload"
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
          status: status
        } = map
      ) do
    in_response_to = Map.get(map, :in_response_to)
    in_response_to_attr = if in_response_to, do: ~s( InResponseTo="#{in_response_to}"), else: ""

    ~s(<samlp:LogoutResponse xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="#{id}" Version="2.0" IssueInstant="#{issue_instant}" Destination="#{destination}"#{in_response_to_attr}><saml:Issuer>#{issuer}</saml:Issuer><samlp:Status><samlp:StatusCode Value="#{status}" /></samlp:Status></samlp:LogoutResponse>)
  end

  defdelegate validate_issuer(actual, expected), to: Response

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
         Error.new(:logout_response_invalid, "Missing required LogoutResponse field", %{
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

  defp find_all(%Node{} = node, local) do
    node
    |> collect(local, [])
    |> Enum.reverse()
  end

  defp collect(%Node{local: local, children: children} = node, local, acc) do
    Enum.reduce(children, [node | acc], fn child, a -> collect(child, local, a) end)
  end

  defp collect(%Node{children: children}, local, acc) do
    Enum.reduce(children, acc, fn child, a -> collect(child, local, a) end)
  end

  defp first_text(%Node{} = root, local) do
    case find_first(root, local) do
      %Node{} = node -> trimmed_text(node)
      _ -> nil
    end
  end

  defp trimmed_text(%Node{text: text}), do: String.trim(text)

  defp first_attr(%Node{} = root, local, attribute_name) do
    root
    |> find_all(local)
    |> Enum.find_value(fn node -> attr(node, attribute_name) end)
  end

  defp attr(%Node{attrs: attrs}, attribute_name) do
    case List.keyfind(attrs, attribute_name, 0) do
      {_name, value} -> String.trim(value)
      nil -> nil
    end
  end

  defp attr(_other, _attribute_name), do: nil
end
