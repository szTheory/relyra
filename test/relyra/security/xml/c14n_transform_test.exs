defmodule Relyra.Security.XML.C14NTransformTest do
  use ExUnit.Case, async: true

  alias Relyra.Error
  alias Relyra.Security.XML.C14N
  alias Relyra.Security.XML.SaxyTree
  alias Relyra.Security.XML.SaxyTree.Node

  @enveloped "http://www.w3.org/2000/09/xmldsig#enveloped-signature"
  @exc_c14n "http://www.w3.org/2001/10/xml-exc-c14n#"

  defp parse!(xml) do
    {:ok, root} = SaxyTree.parse(xml)
    root
  end

  defp find(%Node{qname: q} = node, q), do: node

  defp find(%Node{children: children}, q) do
    Enum.find_value(children, fn child -> find(child, q) end)
  end

  defp find(_other, _q), do: nil

  # Find ALL descendants (and self) matching a verbatim qname, in document order.
  defp find_all(node, q, acc \\ [])

  defp find_all(%Node{qname: q, children: children} = node, q, acc) do
    Enum.reduce(children, [node | acc], fn child, a -> find_all(child, q, a) end)
  end

  defp find_all(%Node{children: children}, q, acc) do
    Enum.reduce(children, acc, fn child, a -> find_all(child, q, a) end)
  end

  defp find_all(_other, _q, acc), do: acc

  describe "enveloped-signature transform — prune the SPECIFIC ds:Signature subtree" do
    test "prunes only the Signature subtree containing the Reference; canonical bytes have no Signature" do
      xml = """
      <Assertion xmlns:ds="http://www.w3.org/2000/09/xmldsig#" ID="a1">
        <Issuer>idp</Issuer>
        <ds:Signature><ds:SignedInfo></ds:SignedInfo><ds:SignatureValue>sig</ds:SignatureValue></ds:Signature>
      </Assertion>
      """

      assertion = parse!(xml)
      signature = find(assertion, "ds:Signature")

      assert {:ok, bytes} =
               C14N.canonicalize_reference(
                 assertion,
                 [@enveloped, @exc_c14n],
                 signature,
                 []
               )

      refute bytes =~ "Signature"
      refute bytes =~ "SignatureValue"
      assert bytes =~ "<Issuer>idp</Issuer>"
    end

    test "an unrelated sibling Signature subtree is NOT pruned" do
      # Two ds:Signature subtrees in the document; only the one bound to the
      # Reference being processed is pruned. The other survives canonicalization.
      xml = """
      <Response xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <ds:Signature ID="outer"><ds:SignatureValue>outer-sig</ds:SignatureValue></ds:Signature>
        <Assertion ID="a1">
          <ds:Signature ID="inner"><ds:SignatureValue>inner-sig</ds:SignatureValue></ds:Signature>
          <Issuer>idp</Issuer>
        </Assertion>
      </Response>
      """

      response = parse!(xml)
      # The Reference being processed is bound to the INNER signature inside the Assertion.
      inner_signature =
        find_all(response, "ds:Signature")
        |> Enum.find(fn sig -> Enum.any?(sig.attrs, &(&1 == {"ID", "inner"})) end)

      assert {:ok, bytes} =
               C14N.canonicalize_reference(response, [@enveloped, @exc_c14n], inner_signature, [])

      # The inner signature (the one being processed) is pruned...
      refute bytes =~ "inner-sig"
      # ...but the unrelated outer signature subtree survives.
      assert bytes =~ "outer-sig"
    end
  end

  describe "transform chain ordering + allowlist" do
    test "an enveloped-signature then exc-c14n chain is accepted and applied in order" do
      xml = """
      <Assertion xmlns:ds="http://www.w3.org/2000/09/xmldsig#" ID="a1">
        <ds:Signature><ds:SignatureValue>sig</ds:SignatureValue></ds:Signature>
        <Body>payload</Body>
      </Assertion>
      """

      assertion = parse!(xml)
      signature = find(assertion, "ds:Signature")

      assert {:ok, bytes} =
               C14N.canonicalize_reference(assertion, [@enveloped, @exc_c14n], signature, [])

      assert bytes =~ "<Body>payload</Body>"
      refute bytes =~ "SignatureValue"
      assert String.starts_with?(bytes, "<")
      assert String.ends_with?(bytes, ">")
    end

    test "a bare exc-c14n chain (no enveloped transform) canonicalizes without pruning" do
      xml = ~s(<Assertion ID="a1"><Body>payload</Body></Assertion>)
      assertion = parse!(xml)

      assert {:ok, bytes} = C14N.canonicalize_reference(assertion, [@exc_c14n], nil, [])
      assert bytes =~ "<Body>payload</Body>"
    end

    test "an unexpected transform URI (XSLT) is rejected as :canonicalization_failed" do
      xml = ~s(<Assertion ID="a1"><Body>payload</Body></Assertion>)
      assertion = parse!(xml)

      assert {:error, %Error{type: :canonicalization_failed}} =
               C14N.canonicalize_reference(
                 assertion,
                 ["http://www.w3.org/TR/1999/REC-xslt-19991116"],
                 nil,
                 []
               )
    end

    test "an unexpected XPath transform URI is rejected as :canonicalization_failed" do
      xml = ~s(<Assertion ID="a1"><Body>payload</Body></Assertion>)
      assertion = parse!(xml)

      assert {:error, %Error{type: :canonicalization_failed}} =
               C14N.canonicalize_reference(
                 assertion,
                 ["http://www.w3.org/2002/06/xmldsig-filter2", @exc_c14n],
                 nil,
                 []
               )
    end
  end

  describe "transform URIs read from a ds:Transforms parse-tree node" do
    test "transform URIs and PrefixList are read from ds:Transforms / ds:Transform nodes" do
      # A real ds:Transforms subtree as it appears in a signed Reference. The
      # enveloped transform + exc-c14n with an InclusiveNamespaces PrefixList.
      transforms_xml = """
      <ds:Transforms xmlns:ds="http://www.w3.org/2000/09/xmldsig#" xmlns:ec="http://www.w3.org/2001/10/xml-exc-c14n#">
        <ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"></ds:Transform>
        <ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#">
          <ec:InclusiveNamespaces PrefixList="ec saml"></ec:InclusiveNamespaces>
        </ds:Transform>
      </ds:Transforms>
      """

      transforms = parse!(transforms_xml)

      assert ["http://www.w3.org/2000/09/xmldsig#enveloped-signature", @exc_c14n] =
               C14N.transform_uris(transforms)

      assert ["ec", "saml"] = C14N.prefix_list_from_transforms(transforms)
    end

    test "absent InclusiveNamespaces yields an empty PrefixList" do
      transforms_xml = """
      <ds:Transforms xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"></ds:Transform>
      </ds:Transforms>
      """

      assert [] = C14N.prefix_list_from_transforms(parse!(transforms_xml))
    end
  end

  describe "InclusiveNamespaces/@PrefixList forced rendering (Pitfall 7)" do
    test "listed prefixes force-render on the apex even when not visibly utilized" do
      # ec and saml are declared on the apex but NOT visibly utilized by it
      # (apex is unprefixed; no ec:/saml: attribute names). Under plain exclusive
      # C14N they would be omitted; the PrefixList forces them.
      xml = """
      <Body xmlns:ec="http://www.w3.org/2001/10/xml-exc-c14n#" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" xmlns:other="urn:other">payload</Body>
      """

      body = parse!(xml)

      assert {:ok, bytes} =
               C14N.canonicalize_reference(body, [@exc_c14n], nil, prefix_list: ["ec", "saml"])

      assert bytes =~ ~s(xmlns:ec="http://www.w3.org/2001/10/xml-exc-c14n#")
      assert bytes =~ ~s(xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion")
    end

    test "a prefix NOT in the list still follows the visibly-utilized rule (omitted when unused)" do
      xml = """
      <Body xmlns:ec="http://www.w3.org/2001/10/xml-exc-c14n#" xmlns:other="urn:other">payload</Body>
      """

      body = parse!(xml)

      assert {:ok, bytes} =
               C14N.canonicalize_reference(body, [@exc_c14n], nil, prefix_list: ["ec"])

      assert bytes =~ ~s(xmlns:ec="http://www.w3.org/2001/10/xml-exc-c14n#")
      # other is neither visibly utilized nor in the PrefixList -> omitted.
      refute bytes =~ ~s(xmlns:other="urn:other")
    end

    test "#default in the PrefixList force-renders the default namespace" do
      xml = ~s(<saml:Body xmlns="urn:default" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion">payload</saml:Body>)

      body = parse!(xml)

      assert {:ok, bytes} =
               C14N.canonicalize_reference(body, [@exc_c14n], nil, prefix_list: ["#default", "saml"])

      assert bytes =~ ~s(xmlns="urn:default")
      assert bytes =~ ~s(xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion")
    end
  end

  describe "fail-closed on non-bindable referenced node" do
    test "a non-Node referenced value fails closed as :canonicalization_failed" do
      assert {:error, %Error{type: :canonicalization_failed}} =
               C14N.canonicalize_reference(%{not: :a_node}, [@exc_c14n], nil, [])
    end
  end
end
