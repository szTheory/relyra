defmodule Relyra.Security.XML.SaxyTreeTest do
  use ExUnit.Case, async: true

  alias Relyra.Security.XML.SaxyTree
  alias Relyra.Security.XML.SaxyTree.Node

  # Parse helper: returns {:ok, root_node} | {:error, %Saxy.ParseError{}}
  defp parse(xml), do: SaxyTree.parse(xml)

  # Find the first descendant (or self) whose verbatim qname matches.
  defp find(%Node{qname: q} = node, q), do: node

  defp find(%Node{children: children}, q) do
    Enum.find_value(children, fn child -> find(child, q) end)
  end

  defp find(_other, _q), do: nil

  describe "in-scope namespace stack (Relyra layer #1)" do
    test "a nested ds:Signature inherits the ds->URI binding declared on the root" do
      xml = """
      <samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <ds:Signature>
          <ds:SignedInfo/>
        </ds:Signature>
      </samlp:Response>
      """

      {:ok, root} = parse(xml)
      sig = find(root, "ds:Signature")

      assert %Node{} = sig
      # The ds binding is inherited from the ancestor, not declared on ds:Signature itself.
      assert sig.ns["ds"] == "http://www.w3.org/2000/09/xmldsig#"
      assert sig.ns["samlp"] == "urn:oasis:names:tc:SAML:2.0:protocol"
      # ds:Signature has NO own xmlns attribute.
      refute Enum.any?(sig.attrs, fn {name, _v} -> String.starts_with?(name, "xmlns") end)
    end

    test "a child with no own xmlns declarations inherits the full ancestor in-scope ns map" do
      xml = """
      <Response xmlns="urn:default" xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <Assertion>
          <Subject/>
        </Assertion>
      </Response>
      """

      {:ok, root} = parse(xml)
      subject = find(root, "Subject")

      assert %Node{} = subject
      assert subject.ns[""] == "urn:default"
      assert subject.ns["ds"] == "http://www.w3.org/2000/09/xmldsig#"
    end

    test "a child overlays its own xmlns over the inherited binding" do
      xml = """
      <Root xmlns:ds="http://example.com/old">
        <Child xmlns:ds="http://www.w3.org/2000/09/xmldsig#"/>
      </Root>
      """

      {:ok, root} = parse(xml)
      child = find(root, "Child")

      assert child.ns["ds"] == "http://www.w3.org/2000/09/xmldsig#"
      # Root keeps the old binding.
      assert root.ns["ds"] == "http://example.com/old"
    end
  end

  describe "attribute ordering and verbatim qnames" do
    test "raw attributes are preserved in DOCUMENT ORDER (not sorted)" do
      xml = ~s(<Assertion zeta="1" alpha="2" middle="3"/>)

      {:ok, root} = parse(xml)

      names = Enum.map(root.attrs, fn {name, _v} -> name end)
      assert names == ["zeta", "alpha", "middle"]
    end

    test "element qnames are stored VERBATIM with prefix preserved" do
      xml = """
      <samlp:Response xmlns:samlp="urn:p" xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <Assertion>
          <ds:Signature/>
        </Assertion>
      </samlp:Response>
      """

      {:ok, root} = parse(xml)
      assert root.qname == "samlp:Response"

      assertion = find(root, "Assertion")
      assert assertion.qname == "Assertion"

      sig = find(root, "ds:Signature")
      assert sig.qname == "ds:Signature"
    end

    test "qname is split into prefix/local additively while qname stays verbatim" do
      xml = ~s(<samlp:Response xmlns:samlp="urn:p"/>)
      {:ok, root} = parse(xml)

      assert root.qname == "samlp:Response"
      assert root.prefix == "samlp"
      assert root.local == "Response"
    end

    test "an unprefixed element has empty-string prefix and qname == local" do
      xml = ~s(<Assertion/>)
      {:ok, root} = parse(xml)

      assert root.qname == "Assertion"
      assert root.prefix == ""
      assert root.local == "Assertion"
    end
  end

  describe "attribute-value normalization (Relyra layer #2, XML 1.0 3.3.3)" do
    test "literal tab/newline/CR in an attribute value normalize to single spaces" do
      # Use numeric character references so the literal whitespace chars reach the parser
      # inside the attribute value (CDATA-type, since SAML is DTD-less).
      xml = ~s(<Assertion Issuer="a&#x9;b&#xA;c&#xD;d"/>)

      {:ok, root} = parse(xml)
      {"Issuer", value} = Enum.find(root.attrs, fn {n, _} -> n == "Issuer" end)

      assert value == "a b c d"
    end

    test "a literal tab character inside an attribute value normalizes to a space" do
      xml = "<Assertion Issuer=\"a\tb\"/>"

      {:ok, root} = parse(xml)
      {"Issuer", value} = Enum.find(root.attrs, fn {n, _} -> n == "Issuer" end)

      assert value == "a b"
    end
  end

  describe "text and CDATA normalization (Relyra layer #3, XML 1.0 2.11)" do
    test "text content with CRLF and lone CR normalizes to LF (not whitespace-collapsed)" do
      # Carriage returns delivered via char refs so they survive into :characters.
      xml = "<Note>line1&#xD;&#xA;line2&#xD;line3</Note>"

      {:ok, root} = parse(xml)

      assert root.text == "line1\nline2\nline3"
    end

    test "text content is NOT whitespace-collapsed (only attr values are)" do
      xml = "<Note>a    b\t\tc</Note>"

      {:ok, root} = parse(xml)

      # Internal runs of spaces/tabs preserved in text (no collapse).
      assert root.text == "a    b\t\tc"
    end

    test "CDATA content is captured and normalized identically to characters text" do
      xml = "<Note><![CDATA[hello\r\nworld]]></Note>"

      {:ok, root} = parse(xml)

      assert root.text == "hello\nworld"
    end

    test "mixed characters and CDATA accumulate in document order" do
      xml = "<Note>foo<![CDATA[bar]]>baz</Note>"

      {:ok, root} = parse(xml)

      assert root.text == "foobarbaz"
    end
  end

  describe "encoding (Pitfall 6 smoke check)" do
    test "a non-ASCII character in element text is preserved as UTF-8" do
      xml = "<NameID>José Müller — café</NameID>"

      {:ok, root} = parse(xml)

      assert root.text == "José Müller — café"
    end
  end

  describe "malformed input" do
    test "a not-well-formed XML binary surfaces as a Saxy.ParseError" do
      xml = "<Response><Assertion></Response>"

      assert {:error, %Saxy.ParseError{}} = parse(xml)
    end
  end

  describe "tree structure" do
    test "children are attached to their parent in document order" do
      xml = """
      <Response>
        <First/>
        <Second/>
        <Third/>
      </Response>
      """

      {:ok, root} = parse(xml)

      child_qnames =
        root.children
        |> Enum.filter(fn %Node{} -> true end)
        |> Enum.map(& &1.qname)

      assert child_qnames == ["First", "Second", "Third"]
    end
  end

  describe "ordered content (D-09 document order)" do
    test "mixed content interleaves text and child elements in source order" do
      xml = ~s(<a>x<b/>y</a>)

      {:ok, root} = parse(xml)

      assert [{:text, "x"}, {:element, %Node{local: "b"} = b}, {:text, "y"}] = root.content
      assert b.qname == "b"

      # :children and :text remain DERIVED views over :content.
      assert Enum.map(root.children, & &1.local) == ["b"]
      assert root.text == "xy"
    end

    test "content is empty for a self-closing element with no text or children" do
      xml = ~s(<Assertion/>)
      {:ok, root} = parse(xml)

      assert root.content == []
      assert root.children == []
      assert root.text == ""
    end

    test ":children is exactly the {:element, _} segments of :content, in document order" do
      xml = """
      <Response>
        <First/>
        <Second/>
        <Third/>
      </Response>
      """

      {:ok, root} = parse(xml)

      elements_from_content = for {:element, child} <- root.content, do: child
      assert elements_from_content == root.children
      assert Enum.map(root.children, & &1.qname) == ["First", "Second", "Third"]
    end

    test ":text is exactly the concatenation of the {:text, _} segments of :content" do
      xml = ~s(<Note>foo<Inner/>bar</Note>)

      {:ok, root} = parse(xml)

      text_from_content =
        root.content
        |> Enum.flat_map(fn
          {:text, t} -> [t]
          _ -> []
        end)
        |> Enum.join()

      assert text_from_content == root.text
      assert root.text == "foobar"
    end
  end
end
