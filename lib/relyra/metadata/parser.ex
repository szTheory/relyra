defmodule Relyra.Metadata.Parser do
  @moduledoc false

  alias Relyra.Error
  alias Relyra.Security.XML.SaxyTree
  alias Relyra.Security.XML.SaxyTree.Node

  @default_opts [max_bytes: 1_048_576]

  @metadata_ns "urn:oasis:names:tc:SAML:2.0:metadata"
  @dsig_ns "http://www.w3.org/2000/09/xmldsig#"

  @spec parse(binary(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def parse(xml, opts \\ [])

  def parse(xml, opts) when is_binary(xml) and is_list(opts) do
    max_bytes = Keyword.get(Keyword.merge(@default_opts, opts), :max_bytes)
    trimmed = String.trim(xml)

    cond do
      byte_size(xml) > max_bytes ->
        {:error,
         Error.new(:payload_too_large, "XML payload exceeds max_bytes limit", %{
           max_bytes: max_bytes
         })}

      trimmed == "" ->
        malformed_xml_error()

      String.contains?(trimmed, "<!DOCTYPE") ->
        {:error, Error.new(:doctype_forbidden, "DOCTYPE declarations are forbidden")}

      String.contains?(trimmed, "<!ENTITY") ->
        {:error, Error.new(:entity_expansion_forbidden, "ENTITY declarations are forbidden")}

      true ->
        parse_tree(trimmed)
    end
  end

  def parse(_xml, _opts), do: malformed_xml_error()

  # Invariant #2: metadata is derived through the SAME single SaxyTree seam as
  # the assertion path — never a second regex pass (S18). Every field is read
  # from the authoritative EntityDescriptor node: the one the signature binds
  # (its direct-child ds:Signature) when present, otherwise the root. A value
  # placed in a comment, in an unsigned wrapper, or inside a ds:KeyInfo is never
  # imported, because the tree walk is scoped to that bound node's descendants.
  defp parse_tree(xml) do
    case SaxyTree.parse(xml) do
      {:ok, %Node{} = root} ->
        case authoritative_entity(root) do
          %Node{} = entity ->
            extract_metadata(entity)

          nil ->
            {:error,
             Error.new(:metadata_wrong_root, "Metadata XML must start with EntityDescriptor")}
        end

      {:error, _parse_error} ->
        malformed_xml_error()
    end
  end

  # The EntityDescriptor that carries the trust: prefer one with a direct-child
  # ds:Signature (the signed envelope), else the first EntityDescriptor in
  # document order (unsigned manual import).
  defp authoritative_entity(%Node{} = root) do
    descriptors = find_all(root, "EntityDescriptor")

    Enum.find(descriptors, fn node -> direct_child_ns(node, "Signature", @dsig_ns) != nil end) ||
      List.first(descriptors)
  end

  defp extract_metadata(%Node{} = entity) do
    with {:ok, entity_id} <- fetch_entity_id(entity),
         {:ok, sso_services} <- fetch_sso_services(entity),
         {:ok, certificates} <- fetch_certificates(entity) do
      {:ok,
       %{
         entity_id: entity_id,
         sso_services: sso_services,
         certificates: certificates,
         valid_until: fetch_valid_until(entity)
       }}
    end
  end

  defp extract_metadata(_other),
    do: {:error, Error.new(:metadata_wrong_root, "Metadata XML must start with EntityDescriptor")}

  defp fetch_entity_id(%Node{} = entity) do
    case attr(entity, "entityID") do
      value when is_binary(value) and value != "" ->
        {:ok, value}

      _ ->
        {:error, Error.new(:metadata_missing_entity_id, "Metadata entity ID is required")}
    end
  end

  defp fetch_sso_services(%Node{} = entity) do
    services =
      entity
      |> find_all("SingleSignOnService")
      |> Enum.map(fn node ->
        %{binding: attr(node, "Binding"), location: attr(node, "Location")}
      end)
      |> Enum.reject(fn svc -> blank?(svc.binding) or blank?(svc.location) end)

    if services == [] do
      {:error,
       Error.new(:metadata_missing_sso_service, "Metadata XML must include a SingleSignOnService")}
    else
      {:ok, services}
    end
  end

  # Signing certificates from within the bound EntityDescriptor. A KeyDescriptor
  # with use="encryption" is skipped (only signing / unspecified keys verify
  # assertions); certs are read from KeyDescriptor subtrees, never from an
  # enveloping ds:Signature's own KeyInfo.
  defp fetch_certificates(%Node{} = entity) do
    certs =
      entity
      |> find_all("KeyDescriptor")
      |> Enum.filter(fn kd -> attr(kd, "use") in [nil, "", "signing"] end)
      |> Enum.flat_map(fn kd -> find_all(kd, "X509Certificate") end)
      |> Enum.map(fn node -> node.text |> String.replace(~r/\s+/, "") |> String.trim() end)
      |> Enum.reject(&blank?/1)
      |> Enum.uniq()

    if certs == [] do
      {:error,
       Error.new(
         :metadata_missing_certificate,
         "Metadata XML must include at least one certificate"
       )}
    else
      {:ok, certs}
    end
  end

  defp fetch_valid_until(%Node{} = entity) do
    case attr(entity, "validUntil") do
      iso8601 when is_binary(iso8601) and iso8601 != "" ->
        case DateTime.from_iso8601(iso8601) do
          {:ok, dt, _offset} -> dt
          _ -> nil
        end

      _ ->
        nil
    end
  end

  defp malformed_xml_error do
    {:error, Error.new(:malformed_xml, "Metadata XML is malformed")}
  end

  defp blank?(value), do: is_nil(value) or value == ""

  # --- tree-walk helpers (local name + namespace URI, or no namespace) -------

  defp find_all(%Node{} = node, local) do
    node |> collect(local, []) |> Enum.reverse()
  end

  defp collect(%Node{local: local, children: children} = node, local, acc) do
    acc = if metadata_ns?(node), do: [node | acc], else: acc
    Enum.reduce(children, acc, fn child, a -> collect(child, local, a) end)
  end

  defp collect(%Node{children: children}, local, acc) do
    Enum.reduce(children, acc, fn child, a -> collect(child, local, a) end)
  end

  defp direct_child_ns(%Node{children: children}, local, uri) do
    Enum.find(children, fn
      %Node{local: ^local} = child -> ns_uri(child) in [uri, nil, ""]
      _ -> false
    end)
  end

  # SAML-metadata elements match in the metadata namespace or with no namespace;
  # SingleSignOnService/KeyDescriptor/X509Certificate carry their own namespaces
  # (metadata / dsig) which we accept, while a foreign-namespace lookalike does
  # not match (the authoritative-node scoping already excludes unsigned wrappers).
  defp metadata_ns?(%Node{} = node) do
    ns_uri(node) in [@metadata_ns, @dsig_ns, nil, ""]
  end

  defp ns_uri(%Node{prefix: prefix, ns: ns}), do: Map.get(ns, prefix)

  defp attr(%Node{attrs: attrs}, name) do
    case List.keyfind(attrs, name, 0) do
      {_name, value} -> String.trim(value)
      nil -> nil
    end
  end

  defp attr(_other, _name), do: nil
end
