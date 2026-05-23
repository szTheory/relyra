defmodule Relyra.Security.XML.C14N do
  @moduledoc """
  Hand-rolled **Exclusive XML Canonicalization 1.0 (no-comments)**
  (`http://www.w3.org/2001/10/xml-exc-c14n#`) engine over the
  `Relyra.Security.XML.SaxyTree.Node` parse-tree shape.

  This is the only net-new algorithm in Phase 28 and has NO in-repo analog.
  Hand-rolling is mandated by ADR-0001 / decision D-05: no correct exclusive-C14N
  BEAM library exists (`esaml`/`xmerl_c14n` is inclusive-only, xmerl-DOM-based,
  and carries CVE-2026-28809 XXE). It serializes a tree node to byte-exact
  canonical UTF-8 — the precondition for Phase 29's `:public_key.verify` and
  `DigestValue` recompute. A single byte-divergence here silently defeats the
  downstream digest check and re-opens the confirmed SAML auth-bypass class, so
  byte-equality against an independent golden oracle is proven in Plan 04.

  ## Correctness surface (decision D-06)

    * **Visibly-utilized namespace rendering** against a *rendered-namespaces*
      stack distinct from the *in-scope* stack (no over-rendering — Pitfall 1).
    * **Default-namespace handling**: an unprefixed element visibly utilizes the
      default namespace; a prefixed element does not. `xmlns=""` undeclaration is
      rendered only when needed to clear an inherited default in output
      (Pitfall 2).
    * **`InclusiveNamespaces/@PrefixList`** prefixes (and `#default`) are
      force-rendered, bypassing the visibly-utilized test (Pitfall 7) — wired via
      the `:prefix_list` option (transform-chain parsing lives in
      `Relyra.Security.XML.C14N` transform helpers).
    * **Sort order**: namespace nodes before attribute nodes; namespaces sorted by
      local name (default ns `""` sorts least); attributes sorted by RESOLVED
      namespace-URI then local name (no-namespace attributes sort first —
      Pitfall 8).
    * **Two escaping functions** with the EXACT W3C char sets — text content
      escapes `&` `<` `>` and `#xD`; attribute values escape `&` `<` `"` and
      `#x9`/`#xA`/`#xD`.
    * **Empty elements** expanded to start+end tag pairs (`<a></a>`, never
      `<a/>`).
    * **No trailing newline** — output starts with `<` and ends with `>`
      (Pitfall 4); output is a UTF-8 binary (Pitfall 6).

  Fail-closed (Pitfall 9): an incomplete / non-bindable node returns
  `{:error, %Relyra.Error{type: :canonicalization_failed}}`. Only the existing
  `:canonicalization_failed` atom is reused — no new error atom is invented.

  The line-ending normalization layer (XML 1.0 §2.11) is applied at tree-build
  time by `Relyra.Security.XML.SaxyTree`; this engine does NOT re-trim or strip
  (the legacy `String.trim/1` from `normalize_signed_xml/1` is deliberately
  dropped — it violates byte-exact C14N).
  """

  alias Relyra.Error
  alias Relyra.Security.XML.SaxyTree.Node

  @typedoc "Options for `serialize/2`."
  @type opt :: {:prefix_list, [String.t()]}

  # Transform allowlist (decision D-06, threat T-28-05): the ONLY transform URIs
  # this engine will apply. Any other URI — XSLT, XPath/xmldsig-filter2, or even
  # *inclusive* C14N (which this exclusive engine does NOT implement, so claiming
  # support would emit wrong bytes) — is rejected fail-closed.
  @enveloped_signature "http://www.w3.org/2000/09/xmldsig#enveloped-signature"
  @exc_c14n "http://www.w3.org/2001/10/xml-exc-c14n#"
  @allowed_transforms [@enveloped_signature, @exc_c14n]

  @doc """
  Serialize a `Relyra.Security.XML.SaxyTree.Node` subtree to canonical
  exclusive-C14N 1.0 (no-comments) UTF-8 bytes.

  Returns `{:ok, binary()}` of canonical bytes (starts with `<`, ends with `>`,
  no trailing newline), or `{:error, %Relyra.Error{type: :canonicalization_failed}}`
  for an incomplete / non-bindable node (fail-closed, Pitfall 9).

  ## Options

    * `:prefix_list` — a list of namespace prefixes (and/or the literal
      `"#default"`) drawn from `InclusiveNamespaces/@PrefixList`. Listed prefixes
      are force-rendered on the apex element bypassing the visibly-utilized test
      (Pitfall 7). Defaults to `[]`.
  """
  @spec serialize(term(), [opt()]) :: {:ok, binary()} | {:error, Error.t()}
  def serialize(node, opts \\ [])

  def serialize(%Node{} = node, opts) when is_list(opts) do
    prefix_list = Keyword.get(opts, :prefix_list, [])

    if bindable?(node) do
      try do
        bytes = render_element(node, %{}, prefix_list)
        {:ok, IO.iodata_to_binary(bytes)}
      rescue
        _ -> canonicalization_failed(:non_bindable_node)
      end
    else
      canonicalization_failed(:non_bindable_node)
    end
  end

  def serialize(_other, _opts), do: canonicalization_failed(:invalid_signed_node_handle)

  # ---------------------------------------------------------------------------
  # Transform chain (decision D-06): enveloped-signature pruning + exclusive
  # C14N, gated by the transform allowlist, with InclusiveNamespaces/@PrefixList
  # threaded into the serializer.
  # ---------------------------------------------------------------------------

  @doc """
  Apply a signed Reference's transform chain to `referenced_node` and serialize
  the result to canonical exclusive-C14N 1.0 bytes.

  `transform_uris` is the ordered list of transform `Algorithm` URIs (see
  `transform_uris/1`). Only the enveloped-signature
  (`#{@enveloped_signature}`) and exclusive-C14N (`#{@exc_c14n}`) transforms are
  accepted; ANY other URI (XSLT, XPath/xmldsig-filter2, inclusive C14N) is
  rejected fail-closed with `:canonicalization_failed` (threat T-28-05).

  When the chain includes the enveloped-signature transform, the SPECIFIC
  `signature_subtree` node (the `ds:Signature` containing the Reference being
  processed) is pruned from `referenced_node` — and only that node; an unrelated
  sibling `ds:Signature` survives (anti-XSW, D-10). Pass `nil` when no
  enveloped-signature transform applies.

  `opts` accepts `:prefix_list` (typically from `prefix_list_from_transforms/1`),
  which is force-rendered per `serialize/2`.

  Returns `{:ok, binary()}` or
  `{:error, %Relyra.Error{type: :canonicalization_failed}}` (fail-closed for a
  non-`Node` referenced value or a rejected transform).
  """
  @spec canonicalize_reference(term(), [String.t()], Node.t() | nil, [opt()]) ::
          {:ok, binary()} | {:error, Error.t()}
  def canonicalize_reference(%Node{} = referenced, transform_uris, signature_subtree, opts)
      when is_list(transform_uris) and is_list(opts) do
    if Enum.all?(transform_uris, &allowed_transform?/1) do
      referenced
      |> maybe_prune_signature(transform_uris, signature_subtree)
      |> serialize(opts)
    else
      canonicalization_failed(:unsupported_transform)
    end
  end

  def canonicalize_reference(_referenced, _transform_uris, _signature_subtree, _opts) do
    canonicalization_failed(:non_bindable_node)
  end

  @doc """
  Read the ordered transform `Algorithm` URIs from a `ds:Transforms` parse-tree
  node (its `ds:Transform` children), in document order.
  """
  @spec transform_uris(term()) :: [String.t()]
  def transform_uris(%Node{children: children}) do
    for %Node{local: "Transform", attrs: attrs} <- children,
        uri = attr_value(attrs, "Algorithm"),
        is_binary(uri),
        do: uri
  end

  def transform_uris(_other), do: []

  @doc """
  Read `InclusiveNamespaces/@PrefixList` from a `ds:Transforms` parse-tree node,
  returning the whitespace-separated prefixes (e.g. `["ec", "saml"]`), or `[]`
  when no `InclusiveNamespaces` element / `PrefixList` attribute is present.
  """
  @spec prefix_list_from_transforms(term()) :: [String.t()]
  def prefix_list_from_transforms(%Node{} = transforms) do
    case find_descendant(transforms, "InclusiveNamespaces") do
      %Node{attrs: attrs} ->
        case attr_value(attrs, "PrefixList") do
          value when is_binary(value) -> String.split(value)
          _ -> []
        end

      _ ->
        []
    end
  end

  def prefix_list_from_transforms(_other), do: []

  defp allowed_transform?(uri), do: uri in @allowed_transforms

  # Prune ONLY when the chain requests the enveloped-signature transform AND a
  # concrete signature node is supplied; nil (or a bare exc-c14n chain) is a
  # no-op (returns the node unchanged).
  defp maybe_prune_signature(node, transform_uris, %Node{} = signature_subtree) do
    if @enveloped_signature in transform_uris do
      prune_subtree(node, signature_subtree)
    else
      node
    end
  end

  defp maybe_prune_signature(node, _transform_uris, _signature_subtree), do: node

  # Remove the exact `target` subtree (value-equal, so an unrelated sibling
  # Signature with different content is left intact) wherever it appears beneath
  # `node`, rebuilding the surrounding tree.
  defp prune_subtree(%Node{children: children} = node, target) do
    pruned =
      children
      |> Enum.reject(&(&1 == target))
      |> Enum.map(&prune_subtree(&1, target))

    %Node{node | children: pruned}
  end

  # First descendant-or-self node whose local name matches, in document order.
  defp find_descendant(%Node{local: local} = node, local), do: node

  defp find_descendant(%Node{children: children}, local) do
    Enum.find_value(children, fn child -> find_descendant(child, local) end)
  end

  defp find_descendant(_other, _local), do: nil

  defp attr_value(attrs, name) do
    case List.keyfind(attrs, name, 0) do
      {_name, value} -> value
      nil -> nil
    end
  end

  # A node is bindable only if it carries the structural keys C14N needs:
  # a non-nil verbatim qname and local name, a list of attrs, an in-scope ns map,
  # a list of children, and binary text. Anything else fails closed (Pitfall 9).
  defp bindable?(%Node{qname: qname, local: local, attrs: attrs, ns: ns, children: children, text: text}) do
    is_binary(qname) and qname != "" and is_binary(local) and local != "" and
      is_list(attrs) and is_map(ns) and is_list(children) and is_binary(text)
  end

  defp bindable?(_), do: false

  # Render one element (and recursively its children). `rendered` is the
  # rendered-namespaces map carried down from output ancestors (prefix => URI of
  # what has actually been emitted, distinct from the in-scope stack). The
  # `prefix_list` forced-render set only applies to the apex; descendants receive
  # an empty forced set.
  defp render_element(%Node{} = node, rendered, prefix_list) do
    ns_to_render = namespaces_to_render(node, rendered, prefix_list)
    new_rendered = apply_rendered(rendered, ns_to_render)

    ns_iodata =
      ns_to_render
      |> sort_namespaces()
      |> Enum.map(&render_ns_decl/1)

    attr_iodata =
      node
      |> real_attributes()
      |> sort_attributes(node.ns)
      |> Enum.map(&render_attribute/1)

    child_iodata =
      node.children
      |> Enum.map(fn child -> render_element(child, new_rendered, []) end)

    [
      "<",
      node.qname,
      ns_iodata,
      attr_iodata,
      ">",
      escape_text(node.text),
      child_iodata,
      "</",
      node.qname,
      ">"
    ]
  end

  # ---------------------------------------------------------------------------
  # Namespace rendering (visibly-utilized + rendered-vs-in-scope, Pitfalls 1/2/7)
  # ---------------------------------------------------------------------------

  # Returns the list of {prefix, uri} namespace nodes to render on this element.
  defp namespaces_to_render(%Node{} = node, rendered, prefix_list) do
    candidate_prefixes =
      MapSet.union(
        visibly_utilized_prefixes(node),
        forced_prefixes(prefix_list)
      )

    rendered_decls =
      candidate_prefixes
      |> Enum.flat_map(fn prefix ->
        case Map.fetch(node.ns, prefix) do
          {:ok, uri} ->
            # Render only if not already rendered with an identical binding by an
            # output ancestor (no over-render, Pitfall 1). Treat an in-scope
            # empty default ("" => "") as "no default" — handled by undeclaration
            # below, not here.
            cond do
              prefix == "" and uri == "" -> []
              Map.get(rendered, prefix) == uri -> []
              true -> [{prefix, uri}]
            end

          :error ->
            []
        end
      end)

    rendered_decls ++ default_undeclaration(node, rendered)
  end

  # The default-namespace undeclaration case (Pitfall 2): if an output ancestor
  # rendered a non-empty default and THIS element's in-scope default is empty
  # (cleared by xmlns="" or simply absent) AND this element is unprefixed (so it
  # visibly utilizes the default), emit xmlns="" to clear it.
  defp default_undeclaration(%Node{prefix: ""} = node, rendered) do
    ancestor_default = Map.get(rendered, "")
    in_scope_default = Map.get(node.ns, "", "")

    if is_binary(ancestor_default) and ancestor_default != "" and in_scope_default == "" do
      [{"", ""}]
    else
      []
    end
  end

  defp default_undeclaration(_node, _rendered), do: []

  # Prefixes visibly utilized by this element: the element's own qname prefix,
  # plus the prefix of every real (non-xmlns) attribute name. The default ns
  # (prefix "") is visibly utilized iff the element itself is unprefixed.
  defp visibly_utilized_prefixes(%Node{prefix: el_prefix} = node) do
    attr_prefixes =
      node
      |> real_attributes()
      |> Enum.map(fn {name, _v} -> attr_prefix(name) end)
      # An UNPREFIXED attribute has no namespace and does NOT utilize the default
      # namespace (XML namespaces: default ns never applies to attributes).
      |> Enum.reject(&(&1 == ""))
      |> MapSet.new()

    MapSet.put(attr_prefixes, el_prefix)
  end

  # Forced-render prefixes from InclusiveNamespaces/@PrefixList. The literal
  # "#default" maps to the default-namespace prefix "".
  defp forced_prefixes(prefix_list) when is_list(prefix_list) do
    prefix_list
    |> Enum.map(fn
      "#default" -> ""
      prefix -> prefix
    end)
    |> MapSet.new()
  end

  defp forced_prefixes(_), do: MapSet.new()

  # Fold the just-rendered declarations into the rendered-namespaces map carried
  # to children. An xmlns="" undeclaration clears the default in the map.
  defp apply_rendered(rendered, ns_to_render) do
    Enum.reduce(ns_to_render, rendered, fn
      {"", ""}, acc -> Map.put(acc, "", "")
      {prefix, uri}, acc -> Map.put(acc, prefix, uri)
    end)
  end

  # Namespace nodes sort by local name; the default namespace ("" prefix) sorts
  # least. Sort key uses a leading boolean so "" (default) comes first.
  defp sort_namespaces(ns_decls) do
    Enum.sort_by(ns_decls, fn {prefix, _uri} -> {prefix != "", prefix} end)
  end

  defp render_ns_decl({"", uri}), do: [" xmlns=\"", escape_attr(uri), "\""]
  defp render_ns_decl({prefix, uri}), do: [" xmlns:", prefix, "=\"", escape_attr(uri), "\""]

  # ---------------------------------------------------------------------------
  # Attribute rendering + sort (Pitfall 8)
  # ---------------------------------------------------------------------------

  # The element's REAL attributes (xmlns / xmlns:* declarations stripped — those
  # are rendered as namespace nodes, not attribute nodes).
  defp real_attributes(%Node{attrs: attrs}) do
    Enum.reject(attrs, fn {name, _v} -> namespace_declaration?(name) end)
  end

  defp namespace_declaration?("xmlns"), do: true
  defp namespace_declaration?(name), do: String.starts_with?(name, "xmlns:")

  # Attributes sort by RESOLVED namespace-URI then local name. No-namespace
  # attributes (unprefixed) sort FIRST (Pitfall 8). The sort key uses a leading
  # boolean so the no-namespace group (false) precedes the namespaced group
  # (true); within each group order is {uri, local}.
  defp sort_attributes(attrs, ns_map) do
    Enum.sort_by(attrs, fn {name, _v} ->
      prefix = attr_prefix(name)
      local = attr_local(name)

      case prefix do
        "" -> {false, "", local}
        p -> {true, Map.get(ns_map, p, ""), local}
      end
    end)
  end

  defp render_attribute({name, value}), do: [" ", name, "=\"", escape_attr(value), "\""]

  defp attr_prefix(name) do
    case String.split(name, ":", parts: 2) do
      [prefix, _local] -> prefix
      [_local] -> ""
    end
  end

  defp attr_local(name) do
    case String.split(name, ":", parts: 2) do
      [_prefix, local] -> local
      [local] -> local
    end
  end

  # ---------------------------------------------------------------------------
  # Escaping — two distinct functions with the EXACT W3C char sets
  #   text content : & < > and #xD (NOT " , NOT #x9 / #xA)
  #   attr value   : & < " and #x9 / #xA / #xD (NOT > , NOT ')
  # (Canonical XML 1.0 §3.5)
  # ---------------------------------------------------------------------------

  defp escape_text(text) when is_binary(text) do
    text
    |> :binary.replace("&", "&amp;", [:global])
    |> :binary.replace("<", "&lt;", [:global])
    |> :binary.replace(">", "&gt;", [:global])
    |> :binary.replace("\r", "&#xD;", [:global])
  end

  defp escape_attr(value) when is_binary(value) do
    value
    |> :binary.replace("&", "&amp;", [:global])
    |> :binary.replace("<", "&lt;", [:global])
    |> :binary.replace("\"", "&quot;", [:global])
    |> :binary.replace("\t", "&#x9;", [:global])
    |> :binary.replace("\n", "&#xA;", [:global])
    |> :binary.replace("\r", "&#xD;", [:global])
  end

  # ---------------------------------------------------------------------------
  # Fail-closed error construction — reuse :canonicalization_failed ONLY
  # ---------------------------------------------------------------------------

  defp canonicalization_failed(reason) do
    {:error,
     Error.new(
       :canonicalization_failed,
       "Signed node handle could not be canonicalized",
       %{reason: reason}
     )}
  end
end
