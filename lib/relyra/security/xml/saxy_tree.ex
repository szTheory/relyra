defmodule Relyra.Security.XML.SaxyTree do
  @moduledoc """
  `Saxy.Handler` that turns a raw SAML XML binary into a structured parse tree
  carrying, per element node: the verbatim qualified name, raw attributes in
  document order, and a computed in-scope namespace stack inherited from
  ancestors.

  This module is the parse-substrate foundation for Phase 28. It applies the
  three Relyra-owned infoset-normalization layers that Saxy does **not** provide
  (Saxy performs zero namespace resolution, zero attribute-value normalization,
  and zero line-ending normalization):

    1. **In-scope namespace stack** (`xml-exc-c14n` visibly-utilized precondition):
       each element node's `:ns` map = the parent's in-scope map overlaid with the
       element's own `xmlns` / `xmlns:prefix` declarations.
    2. **Attribute-value whitespace normalization** (XML 1.0 §3.3.3, CDATA-type
       rule — SAML is DTD-less so every attribute is CDATA-type): each literal
       `#x9` (tab) / `#xA` (LF) / `#xD` (CR) inside an attribute value becomes a
       single `#x20` (space).
    3. **Line-ending normalization** (XML 1.0 §2.11): `\\r\\n` and a lone `\\r`
       become `\\n` in all parsed text / CDATA content.

  These are *infoset* normalizations applied at tree-build time. They are kept
  STRICTLY SEPARATE from C14N *escaping* (e.g. `&#x9;` / `&#xD;`), which is a
  serialize-time concern owned by the exclusive-C14N engine in a later plan.

  ## Tree-node shape (the contract for Plans 02 and 03)

  The tree is built from `#{inspect(__MODULE__)}.Node` structs. This shape is the
  stable interface the exclusive-C14N engine (Plan 02) and the seam re-wiring
  (Plan 03) build against — do not reshape it without updating those plans.

      %#{inspect(__MODULE__)}.Node{
        qname:    String.t(),                      # verbatim qualified name, e.g. "ds:Signature" or "Assertion"
        prefix:   String.t(),                      # derived namespace prefix; "" when the element is unprefixed
        local:    String.t(),                      # derived local name (qname with the prefix stripped)
        attrs:    [{String.t(), String.t()}],      # raw attributes in DOCUMENT ORDER; each value is
                                                   #   attribute-value normalized (layer #2). xmlns / xmlns:*
                                                   #   declarations are retained here verbatim (as attrs) so the
                                                   #   C14N engine can render them; they are ALSO surfaced in :ns.
        ns:       %{optional(String.t()) => String.t()},
                                                   # in-scope namespace map: prefix => URI. The default namespace
                                                   #   uses the "" key. Inherited from ancestors + this element's
                                                   #   own declarations (layer #1).
        children: [t()],                           # child element nodes in document order
        text:     String.t()                       # accumulated character + CDATA content, line-ending
                                                   #   normalized (layer #3), in document order; NOT
                                                   #   whitespace-collapsed.
      }
  """

  @behaviour Saxy.Handler

  defmodule Node do
    @moduledoc """
    A single element node in the `Relyra.Security.XML.SaxyTree` parse tree.

    See `Relyra.Security.XML.SaxyTree` for the full field contract (the stable
    interface consumed by Plans 02 and 03).
    """

    @enforce_keys [:qname, :prefix, :local]
    defstruct qname: nil,
              prefix: "",
              local: nil,
              attrs: [],
              ns: %{},
              children: [],
              text: ""

    @type t :: %__MODULE__{
            qname: String.t(),
            prefix: String.t(),
            local: String.t(),
            attrs: [{String.t(), String.t()}],
            ns: %{optional(String.t()) => String.t()},
            children: [t()],
            text: String.t()
          }
  end

  @type t :: Node.t()

  @doc """
  Parse an XML binary into a `Relyra.Security.XML.SaxyTree.Node` tree.

  Returns `{:ok, root_node}` for well-formed input, or
  `{:error, %Saxy.ParseError{}}` for input Saxy rejects as not well-formed.
  Callers in the seam (Plan 03) map the `Saxy.ParseError` to the existing
  `:malformed_xml` member of the `Relyra.Security.XML.xml_error_type` union — no
  new error atom is introduced.
  """
  @spec parse(binary()) :: {:ok, t()} | {:error, Saxy.ParseError.t()}
  def parse(xml) when is_binary(xml) do
    case Saxy.parse_string(xml, __MODULE__, %{stack: [], root: nil}) do
      {:ok, %{root: %Node{} = root}} -> {:ok, root}
      {:error, %Saxy.ParseError{} = error} -> {:error, error}
    end
  end

  @impl true
  def handle_event(:start_document, _prolog, state), do: {:ok, state}

  @impl true
  def handle_event(:start_element, {qname, attrs}, %{stack: stack} = state) do
    {prefix, local} = split_qname(qname)

    parent_ns =
      case stack do
        [%Node{ns: ns} | _] -> ns
        [] -> %{}
      end

    own_ns = ns_declarations(attrs)

    node = %Node{
      qname: qname,
      prefix: prefix,
      local: local,
      attrs: Enum.map(attrs, fn {name, value} -> {name, normalize_attr_value(value)} end),
      ns: Map.merge(parent_ns, own_ns),
      children: [],
      text: ""
    }

    {:ok, %{state | stack: [node | stack]}}
  end

  @impl true
  def handle_event(:characters, text, state), do: {:ok, append_text(state, text)}

  @impl true
  def handle_event(:cdata, text, state), do: {:ok, append_text(state, text)}

  @impl true
  def handle_event(:end_element, _qname, %{stack: [%Node{} = node | rest]} = state) do
    finished = finalize_node(node)

    case rest do
      [%Node{} = parent | tail] ->
        updated_parent = %Node{parent | children: [finished | parent.children]}
        {:ok, %{state | stack: [updated_parent | tail]}}

      [] ->
        {:ok, %{state | stack: [], root: finished}}
    end
  end

  @impl true
  def handle_event(:end_document, _data, state), do: {:ok, state}

  # --- internal helpers -----------------------------------------------------

  # Children are accumulated head-first during the walk; restore document order
  # once the element is complete.
  defp finalize_node(%Node{children: children} = node) do
    %Node{node | children: Enum.reverse(children)}
  end

  defp append_text(%{stack: [%Node{} = node | rest]} = state, text) do
    updated = %Node{node | text: node.text <> normalize_line_endings(text)}
    %{state | stack: [updated | rest]}
  end

  # Text content arriving before any element (e.g. ignorable prolog whitespace)
  # has no node to attach to; drop it.
  defp append_text(%{stack: []} = state, _text), do: state

  # Derive {prefix, local} from a verbatim qname. The qname itself is stored
  # verbatim by the caller; this only splits for prefix/local derivation.
  defp split_qname(qname) do
    case String.split(qname, ":", parts: 2) do
      [prefix, local] -> {prefix, local}
      [local] -> {"", local}
    end
  end

  # Collect this element's own namespace declarations from its attributes:
  #   xmlns="..."        -> %{"" => uri}    (default namespace)
  #   xmlns:prefix="..." -> %{"prefix" => uri}
  defp ns_declarations(attrs) do
    Enum.reduce(attrs, %{}, fn {name, value}, acc ->
      cond do
        name == "xmlns" -> Map.put(acc, "", value)
        String.starts_with?(name, "xmlns:") -> Map.put(acc, String.replace_prefix(name, "xmlns:", ""), value)
        true -> acc
      end
    end)
  end

  # XML 1.0 §3.3.3 attribute-value normalization for CDATA-type attributes
  # (SAML is DTD-less, so all attributes are CDATA-type): each literal #x9 / #xA
  # / #xD becomes a single #x20. Per §3.3.3 a literal #xD#xA pair (or lone #xD)
  # is first treated as a single end-of-line, then mapped to a single space, so
  # the CRLF pair collapses to ONE space (line-ending normalization precedes the
  # whitespace mapping).
  defp normalize_attr_value(value) do
    value
    |> normalize_line_endings()
    |> String.replace("\t", " ")
    |> String.replace("\n", " ")
  end

  # XML 1.0 §2.11 line-ending normalization: \r\n and a lone \r become \n.
  defp normalize_line_endings(text) do
    text
    |> String.replace("\r\n", "\n")
    |> String.replace("\r", "\n")
  end
end
