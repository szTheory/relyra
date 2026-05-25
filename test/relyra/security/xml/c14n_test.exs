defmodule Relyra.Security.XML.C14NTest do
  use ExUnit.Case, async: true

  alias Relyra.Error
  alias Relyra.Security.XML.C14N
  alias Relyra.Security.XML.SaxyTree
  alias Relyra.Security.XML.SaxyTree.Node

  # Parse an XML binary into the SaxyTree node shape, then locate the subtree to
  # canonicalize. The C14N engine consumes the SaxyTree.Node shape VERBATIM
  # (the contract from 28-01-SUMMARY.md); these helpers only build/locate inputs.
  defp parse!(xml) do
    {:ok, root} = SaxyTree.parse(xml)
    root
  end

  defp find(%Node{qname: q} = node, q), do: node

  defp find(%Node{children: children}, q) do
    Enum.find_value(children, fn child -> find(child, q) end)
  end

  defp find(_other, _q), do: nil

  # Canonicalize a node and unwrap to the raw binary (assertion failure otherwise).
  defp c14n!(node, opts \\ []) do
    assert {:ok, bytes} = C14N.serialize(node, opts)
    bytes
  end

  describe "namespace rendering — visibly utilized + no over-render (Pitfall 1)" do
    test "a prefix used only in an attribute name renders on the node that uses it" do
      # ds is declared on the root; the inner element uses ds: only in an attribute
      # name, so the ds declaration is visibly utilized there and must render.
      xml = """
      <Root xmlns:ds="http://www.w3.org/2000/09/xmldsig#"><Inner ds:role="x"></Inner></Root>
      """

      out = c14n!(parse!(xml) |> find("Inner"))

      assert out =~ ~s(xmlns:ds="http://www.w3.org/2000/09/xmldsig#")
      assert out =~ ~s(ds:role="x")
    end

    test "an output ancestor's identical binding is NOT re-rendered on a child (no over-render)" do
      # Root uses ds: in its own qname (visibly utilized -> rendered on root).
      # Child also uses ds: -> visibly utilized, BUT root already rendered the
      # identical binding, so the child must NOT re-render xmlns:ds.
      xml = """
      <ds:Root xmlns:ds="http://www.w3.org/2000/09/xmldsig#"><ds:Child></ds:Child></ds:Root>
      """

      out = c14n!(parse!(xml))

      # Exactly one occurrence of the ds declaration (rendered on the apex only).
      occurrences =
        out
        |> String.split(~s(xmlns:ds="http://www.w3.org/2000/09/xmldsig#"))
        |> length()
        |> Kernel.-(1)

      assert occurrences == 1
    end

    test "a child that does not re-utilize an ancestor prefix does not render it" do
      xml = """
      <Root xmlns:ds="http://www.w3.org/2000/09/xmldsig#" ds:apex="1"><Plain></Plain></Root>
      """

      out = c14n!(parse!(xml))

      # The apex utilizes ds (attribute name) -> renders once. <Plain> does not
      # utilize ds at all -> the declaration must NOT appear on the child.
      apex_and_child = out

      occurrences =
        apex_and_child
        |> String.split(~s(xmlns:ds=))
        |> length()
        |> Kernel.-(1)

      assert occurrences == 1
    end
  end

  describe "default-namespace handling (Pitfall 2)" do
    test "an unprefixed element visibly utilizes the default namespace and renders xmlns=" do
      xml = ~s(<Assertion xmlns="urn:default"></Assertion>)

      out = c14n!(parse!(xml))

      assert out =~ ~s(xmlns="urn:default")
    end

    test "a prefixed element does NOT render the inherited default namespace" do
      # ds:Sig is prefixed -> it does NOT visibly utilize the default ns,
      # so xmlns="urn:default" must not appear on it.
      xml = """
      <Root xmlns="urn:default" xmlns:ds="http://www.w3.org/2000/09/xmldsig#"><ds:Sig></ds:Sig></Root>
      """

      out = c14n!(parse!(xml) |> find("ds:Sig"))

      refute out =~ ~s(xmlns="urn:default")
      assert out =~ ~s(xmlns:ds="http://www.w3.org/2000/09/xmldsig#")
    end

    test "an inherited non-empty default cleared by xmlns=\"\" renders the undeclaration when needed" do
      # Root declares a default; Child is unprefixed and clears it with xmlns="".
      # Canonicalizing from Root, the Child must emit xmlns="" to undeclare the
      # inherited default that the output ancestor rendered.
      xml = """
      <Root xmlns="urn:default"><Child xmlns=""></Child></Root>
      """

      out = c14n!(parse!(xml))

      assert out =~ ~s(<Child xmlns=""></Child>)
    end
  end

  describe "sort order — ns before attrs; attrs by resolved URI then local (Pitfall 8)" do
    test "namespace nodes always precede attribute nodes; ns sorted by local name (default least)" do
      xml =
        ~s(<E xmlns:zeta="urn:z" xmlns="urn:def" xmlns:alpha="urn:a" alpha:a="1" zeta:z="2"></E>)

      out = c14n!(parse!(xml))

      # default ns ("") sorts least, then alpha, then zeta among ns nodes; all ns
      # nodes precede attribute nodes.
      assert out =~
               ~r/<E xmlns="urn:def" xmlns:alpha="urn:a" xmlns:zeta="urn:z" alpha:a="1" zeta:z="2">/
    end

    test "attributes sort by RESOLVED namespace-URI then local name, no-namespace attrs first" do
      # Prefix lexical order (p1, p2) is the REVERSE of resolved-URI order:
      #   p1 -> urn:zzz   (sorts last by URI)
      #   p2 -> urn:aaa   (sorts first by URI)
      # A no-namespace attribute (plain) must sort before any namespaced attr.
      xml =
        ~s(<E xmlns:p1="urn:zzz" xmlns:p2="urn:aaa" p1:b="1" p2:a="2" plain="0"></E>)

      out = c14n!(parse!(xml))

      # Expected attribute order after the ns declarations:
      #   plain (no namespace) , p2:a (urn:aaa) , p1:b (urn:zzz)
      attr_segment = out |> String.replace(~r/^<E[^>]*?(?= plain| p1| p2)/, "")

      assert out =~ ~r/plain="0" p2:a="2" p1:b="1"/
      assert attr_segment =~ ~r/plain="0" p2:a="2" p1:b="1"/
    end
  end

  describe "escaping — two distinct functions, exact W3C char sets (Pitfall 3 distinction)" do
    test "text-escape: & < > and #xD -> &#xD; ; NOT \" / #x9 / #xA" do
      # Char refs deliver literal control chars into the text node; SaxyTree
      # line-ending-normalizes #xD->#xA at build time, so to assert text #xD
      # escaping we feed the char ref and check the engine escapes the surviving
      # carriage returns. Use a plain ampersand/lt/gt + quote/tab/newline body.
      xml = ~s(<T>a&amp;b&lt;c&gt;d"e&#x9;f&#xA;g</T>)

      out = c14n!(parse!(xml))

      assert out =~ "a&amp;b&lt;c&gt;d"
      # In text content, the double quote is NOT escaped.
      assert out =~ ~s(d"e)
      # In text content, tab (#x9) and newline (#xA) are NOT escaped.
      assert out =~ "e\tf"
      assert out =~ "f\ng"
    end

    test "text-escape: carriage return (#xD) becomes &#xD;" do
      # Feed a literal CR via char ref; C14N text-escape converts #xD to &#xD;.
      # SaxyTree normalizes line endings in :text, so we canonicalize a node
      # whose content we know contains a CR by constructing it directly. The
      # engine now walks the ORDERED `content` (D-09), so the CR text lives in a
      # {:text, _} segment (the document-order single source of truth); :text is
      # kept as the byte-identical derived view.
      node = %Node{
        qname: "T",
        prefix: "",
        local: "T",
        attrs: [],
        ns: %{},
        content: [{:text, "a\rb"}],
        children: [],
        text: "a\rb"
      }

      out = c14n!(node)

      assert out == "<T>a&#xD;b</T>"
    end

    test "attribute-escape: & < \" and #x9->&#x9; #xA->&#xA; #xD->&#xD; ; NOT > / '" do
      node = %Node{
        qname: "E",
        prefix: "",
        local: "E",
        attrs: [{"a", "x&y<z>q\"r'\ts\nu\rv"}],
        ns: %{},
        children: [],
        text: ""
      }

      out = c14n!(node)

      assert out =~ "x&amp;y&lt;z"
      # In attribute values, > is NOT escaped and ' is NOT escaped.
      assert out =~ "z>q"
      assert out =~ "r'"
      # The double quote IS escaped in attribute values.
      assert out =~ "q&quot;r"
      # Whitespace control chars ARE escaped in attribute values.
      assert out =~ "&#x9;s"
      assert out =~ "&#xA;u"
      assert out =~ "&#xD;v"
    end
  end

  describe "empty-element expansion + structural invariants" do
    test "an empty element serializes as a start+end tag pair, not a self-closing tag" do
      xml = ~s(<a></a>)

      out = c14n!(parse!(xml))

      assert out == "<a></a>"
      refute out =~ "/>"
    end

    test "output starts with < and ends with > and has no trailing newline (Pitfall 4)" do
      xml = """
      <Root xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <ds:Child>text</ds:Child>
      </Root>
      """

      out = c14n!(parse!(xml))

      assert String.starts_with?(out, "<")
      assert String.ends_with?(out, ">")
      refute String.ends_with?(out, "\n")
    end

    test "output is a UTF-8 binary preserving non-ASCII content (Pitfall 6)" do
      xml = ~s(<NameID>José Müller — café</NameID>)

      out = c14n!(parse!(xml))

      assert is_binary(out)
      assert String.valid?(out)
      assert out == "<NameID>José Müller — café</NameID>"
    end
  end

  describe "document-order content walk (D-09 mixed content)" do
    test "mixed content emits text and child elements in source order, not text-before-children" do
      # <a>x<b/>y</a> must canonicalize as <a>x<b></b>y</a> (text/element/text in
      # source order), NOT <a>xy<b></b></a> (the pre-D-09 text-before-children bug).
      xml = ~s(<a>x<b/>y</a>)

      out = c14n!(parse!(xml))

      assert out == "<a>x<b></b>y</a>"
      refute out == "<a>xy<b></b></a>"
    end

    test "inter-element whitespace between children is preserved in document order" do
      # Pretty-printed signed XML: the whitespace between <First/> and <Second/>
      # must canonicalize in document position (the bug class D-09 fixes).
      xml = "<Root>\n  <First></First>\n  <Second></Second>\n</Root>"

      out = c14n!(parse!(xml))

      assert out == "<Root>\n  <First></First>\n  <Second></Second>\n</Root>"
    end
  end

  describe "idempotence and stability (L5)" do
    test "canonicalize(parse(canonical_bytes)) round-trips to the same bytes" do
      xml = """
      <Root xmlns:ds="http://www.w3.org/2000/09/xmldsig#" xmlns="urn:default">
        <ds:Child attr="v">body</ds:Child>
      </Root>
      """

      once = c14n!(parse!(xml))
      twice = c14n!(parse!(once))

      assert once == twice
    end

    test "reordering insignificant ns declarations on input yields identical output bytes" do
      a = ~s(<E xmlns:alpha="urn:a" xmlns:zeta="urn:z" alpha:x="1" zeta:y="2"></E>)
      b = ~s(<E xmlns:zeta="urn:z" xmlns:alpha="urn:a" alpha:x="1" zeta:y="2"></E>)

      assert c14n!(parse!(a)) == c14n!(parse!(b))
    end
  end

  describe "fail-closed on incomplete / non-bindable nodes (Pitfall 9)" do
    test "a non-Node value returns {:error, :canonicalization_failed} (no invented atom)" do
      assert {:error, %Error{type: :canonicalization_failed}} =
               C14N.serialize(%{not: :a_node}, [])
    end

    test "a node missing required structural keys fails closed as :canonicalization_failed" do
      # qname nil -> non-bindable; the engine must refuse rather than emit garbage.
      bad = %Node{qname: nil, prefix: "", local: nil, attrs: [], ns: %{}, children: [], text: ""}

      assert {:error, %Error{type: :canonicalization_failed}} = C14N.serialize(bad, [])
    end
  end
end
