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
        content:  [{:text, String.t()} | {:element, t()}],
                                                   # ORDERED document-order content (D-09): interleaved text
                                                   #   segments and child elements in source order, e.g.
                                                   #   `[{:text, "x"}, {:element, %Node{}}, {:text, "y"}]`. This is
                                                   #   the SINGLE SOURCE OF TRUTH for document order, consumed by
                                                   #   the exclusive-C14N engine (Plan 02) so text and child
                                                   #   elements canonicalize in source order (mixed content /
                                                   #   inter-element whitespace). Text segments are line-ending
                                                   #   normalized (layer #3), not whitespace-collapsed.
        children: [t()],                           # DERIVED view: the `{:element, _}` segments of `content`, in
                                                   #   document order (kept for downstream helpers; unchanged shape).
        text:     String.t(),                      # DERIVED view: concatenation of the `{:text, _}` segments of
                                                   #   `content`, line-ending normalized (layer #3), in document
                                                   #   order; NOT whitespace-collapsed.
        start_byte: non_neg_integer() | nil,       # OPTIONAL wire-format span: inclusive start offset of the
                                                   #   opening `<` in the source binary (nil when unavailable).
        end_byte:   non_neg_integer() | nil        # OPTIONAL wire-format span: exclusive end offset after the
                                                   #   element's closing `>` (or `/>`) in the source binary.
      }

  > **`content` vs `children`/`text` (D-09):** `content` is the ordered single
  > source of truth; `children` and `text` are DERIVED views over it (the element
  > segments and the concatenated text segments respectively), kept byte-identical
  > to their pre-D-09 values so downstream helpers (`Relyra.Security.XML.PureBeam`
  > field derivation) need no change.
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
              content: [],
              children: [],
              text: "",
              start_byte: nil,
              end_byte: nil

    @type t :: %__MODULE__{
            qname: String.t(),
            prefix: String.t(),
            local: String.t(),
            attrs: [{String.t(), String.t()}],
            ns: %{optional(String.t()) => String.t()},
            content: [{:text, String.t()} | {:element, t()}],
            children: [t()],
            text: String.t(),
            start_byte: non_neg_integer() | nil,
            end_byte: non_neg_integer() | nil
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
    case Saxy.parse_string(xml, __MODULE__, %{stack: [], root: nil, source: xml, pos: 0}) do
      {:ok, %{root: %Node{} = root}} -> {:ok, root}
      {:error, %Saxy.ParseError{} = error} -> {:error, error}
    end
  end

  @impl true
  def handle_event(:start_document, _prolog, state), do: {:ok, state}

  @impl true
  def handle_event(
        :start_element,
        {qname, attrs},
        %{stack: stack, source: source, pos: pos} = state
      ) do
    {prefix, local} = split_qname(qname)

    parent_ns =
      case stack do
        [%Node{ns: ns} | _] -> ns
        [] -> %{}
      end

    own_ns = ns_declarations(attrs)

    {start_byte, end_byte, pos} =
      case locate_open_tag(source, pos, qname) do
        {:ok, open_start, after_tag} ->
          if self_closing_tag?(source, after_tag) do
            {open_start, after_tag, after_tag}
          else
            {open_start, nil, after_tag}
          end

        :error ->
          {nil, nil, pos}
      end

    node = %Node{
      qname: qname,
      prefix: prefix,
      local: local,
      attrs: Enum.map(attrs, fn {name, value} -> {name, normalize_attr_value(value)} end),
      ns: Map.merge(parent_ns, own_ns),
      # ORDERED document-order content (D-09), head-first during the walk;
      # reversed and projected to :children/:text in finalize_node/1.
      content: [],
      children: [],
      text: "",
      start_byte: start_byte,
      end_byte: end_byte
    }

    {:ok, %{state | stack: [node | stack], pos: pos}}
  end

  @impl true
  def handle_event(:characters, text, %{source: source, pos: pos} = state) do
    new_pos = advance_past_text(source, pos, text)
    {:ok, append_text(%{state | pos: new_pos}, text)}
  end

  @impl true
  def handle_event(:cdata, text, %{source: source, pos: pos} = state) do
    new_pos = advance_past_cdata(source, pos, text)
    {:ok, append_text(%{state | pos: new_pos}, text)}
  end

  @impl true
  def handle_event(
        :end_element,
        qname,
        %{stack: [%Node{} = node | rest], source: source, pos: pos} = state
      ) do
    {node, pos} =
      case node.end_byte do
        end_byte when is_integer(end_byte) ->
          {node, pos}

        _ ->
          case locate_close_tag(source, pos, qname) do
            {:ok, end_byte, after_tag} ->
              {%Node{node | end_byte: end_byte}, after_tag}

            :error ->
              {node, pos}
          end
      end

    finished = finalize_node(node)

    case rest do
      [%Node{} = parent | tail] ->
        # Prepend to the head-accumulated ORDERED content (D-09); :children is a
        # derived view recomputed once the parent finalizes.
        updated_parent = %Node{parent | content: [{:element, finished} | parent.content]}
        {:ok, %{state | stack: [updated_parent | tail], pos: pos}}

      [] ->
        {:ok, %{state | stack: [], root: finished, pos: pos}}
    end
  end

  @impl true
  def handle_event(:end_document, _data, state), do: {:ok, state}

  # --- internal helpers -----------------------------------------------------

  # Ordered `content` is accumulated head-first during the walk (text segments and
  # child elements interleaved in reverse document order); restore document order
  # once the element is complete, then PROJECT the derived views (`:children` =
  # the `{:element, _}` segments, `:text` = the concatenation of `{:text, _}`
  # segments) so both stay byte-identical to their pre-D-09 values (D-09).
  defp finalize_node(%Node{content: content} = node) do
    ordered = Enum.reverse(content)

    children = for {:element, child} <- ordered, do: child

    text =
      ordered
      |> Enum.flat_map(fn
        {:text, t} -> [t]
        _ -> []
      end)
      |> IO.iodata_to_binary()

    %Node{node | content: ordered, children: children, text: text}
  end

  # Accumulate the text segment into the head-first ORDERED `content` list (D-09);
  # the flat `:text` derived view is recomputed from `content` in finalize_node/1.
  defp append_text(%{stack: [%Node{} = node | rest]} = state, text) do
    updated = %Node{node | content: [{:text, normalize_line_endings(text)} | node.content]}
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
        name == "xmlns" ->
          Map.put(acc, "", value)

        String.starts_with?(name, "xmlns:") ->
          Map.put(acc, String.replace_prefix(name, "xmlns:", ""), value)

        true ->
          acc
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

  # --- wire-format byte span tracking ---------------------------------------

  defp locate_open_tag(source, pos, qname) do
    needle = "<" <> qname
    rest = binary_part(source, pos, byte_size(source) - pos)

    case :binary.match(rest, needle) do
      {rel_start, _} ->
        open_start = pos + rel_start
        after_name = open_start + byte_size(needle)

        case byte_size(source) > after_name && :binary.at(source, after_name) do
          char when char in [?\s, ?>, ?/, ?\t, ?\n, ?\r] ->
            case scan_to_tag_close(source, after_name) do
              {:ok, after_tag} -> {:ok, open_start, after_tag}
              :error -> :error
            end

          _ ->
            :error
        end

      :nomatch ->
        :error
    end
  end

  defp locate_close_tag(source, pos, qname) do
    needle = "</" <> qname
    rest = binary_part(source, pos, byte_size(source) - pos)

    case :binary.match(rest, needle) do
      {rel_start, _} ->
        close_start = pos + rel_start
        after_name = close_start + byte_size(needle)

        case byte_size(source) > after_name && :binary.at(source, after_name) do
          char when char in [?\s, ?>, ?\t, ?\n, ?\r] ->
            case scan_to_tag_close(source, after_name) do
              {:ok, after_tag} -> {:ok, after_tag, after_tag}
              :error -> :error
            end

          _ ->
            :error
        end

      :nomatch ->
        :error
    end
  end

  defp self_closing_tag?(source, after_tag) when after_tag >= 2 do
    :binary.at(source, after_tag - 2) == ?/
  end

  defp self_closing_tag?(_source, _after_tag), do: false

  defp scan_to_tag_close(source, pos) when pos >= byte_size(source), do: :error

  defp scan_to_tag_close(source, pos) do
    scan_to_tag_close(source, pos, false, ?")
  end

  defp scan_to_tag_close(source, pos, _in_quote, _quote_char) when pos >= byte_size(source),
    do: :error

  defp scan_to_tag_close(source, pos, in_quote, quote_char) do
    <<char, _rest::binary>> = binary_part(source, pos, byte_size(source) - pos)

    cond do
      not in_quote and char == ?> ->
        {:ok, pos + 1}

      not in_quote and char in [?", ?'] ->
        scan_to_tag_close(source, pos + 1, true, char)

      in_quote and char == quote_char ->
        scan_to_tag_close(source, pos + 1, false, ?")

      true ->
        scan_to_tag_close(source, pos + 1, in_quote, quote_char)
    end
  end

  defp advance_past_text(source, pos, text) do
    rest = binary_part(source, pos, byte_size(source) - pos)

    case :binary.match(rest, text) do
      {0, len} ->
        pos + len

      _ ->
        case consume_normalized_text(source, pos, text) do
          {:ok, new_pos} -> new_pos
          :error -> pos + byte_size(text)
        end
    end
  end

  defp advance_past_cdata(source, pos, text) do
    rest = binary_part(source, pos, byte_size(source) - pos)
    marker = "<![CDATA["

    case :binary.match(rest, marker) do
      {rel_start, _} ->
        cdata_start = pos + rel_start + byte_size(marker)

        case :binary.match(
               binary_part(source, cdata_start, byte_size(source) - cdata_start),
               "]]>"
             ) do
          {rel_end, end_len} ->
            cdata_start + rel_end + end_len

          :nomatch ->
            advance_past_text(source, pos, text)
        end

      :nomatch ->
        advance_past_text(source, pos, text)
    end
  end

  defp consume_normalized_text(source, pos, target) do
    consume_normalized_text(source, pos, target, "")
  end

  defp consume_normalized_text(source, pos, target, acc) when pos >= byte_size(source) do
    if normalize_line_endings(acc) == target, do: {:ok, pos}, else: :error
  end

  defp consume_normalized_text(source, pos, target, acc) do
    <<char, _rest::binary>> = binary_part(source, pos, byte_size(source) - pos)
    next_acc = acc <> <<char>>
    normalized = normalize_line_endings(next_acc)

    cond do
      normalized == target ->
        {:ok, pos + 1}

      String.starts_with?(target, normalized) ->
        consume_normalized_text(source, pos + 1, target, next_acc)

      true ->
        :error
    end
  end
end
