defmodule Relyra.Security.XML.PureBeamTest do
  use ExUnit.Case, async: true

  alias Relyra.Error
  alias Relyra.Security.XML.PureBeam
  alias Relyra.Security.XML.SaxyTree.Node

  @signature_method "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
  @digest_method "http://www.w3.org/2001/04/xmlenc#sha256"

  # A well-formed single-signed-node SAML Response (the seam_contract fixture
  # shape). Single-quoted attrs are valid XML 1.0 and Saxy parses them; the tree
  # path must re-derive the SAME flat field values the regex path produced.
  @well_formed_response "<Response Destination='https://sp.example.com/saml/acs' InResponseTo='id_request_123' ConnectionId='conn-123'><Issuer>https://idp.example.com/metadata</Issuer><Status><StatusCode Value='urn:oasis:names:tc:SAML:2.0:status:Success'/></Status><Assertion ID='assertion-1'><Issuer>https://idp.example.com/metadata</Issuer><Subject><NameID Format='urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress'>user@example.com</NameID><SubjectConfirmation><SubjectConfirmationData Recipient='https://sp.example.com/saml/acs' NotOnOrAfter='2026-04-24T16:05:00Z'/></SubjectConfirmation></Subject><Conditions NotBefore='2026-04-24T15:58:00Z' NotOnOrAfter='2026-04-24T16:05:00Z'><AudienceRestriction><Audience>https://sp.example.com/metadata</Audience></AudienceRestriction></Conditions><AuthnStatement SessionIndex='session-xyz'><AttributeStatement><Attribute Name='email'><AttributeValue>user@example.com</AttributeValue></Attribute></AttributeStatement></AuthnStatement></Assertion><Signature><SignedInfo><SignatureMethod Algorithm='http://www.w3.org/2001/04/xmldsig-more#rsa-sha256'/><Reference URI='#assertion-1'><DigestMethod Algorithm='http://www.w3.org/2001/04/xmlenc#sha256'/></Reference></SignedInfo></Signature></Response>"

  describe "parse_safely/2 onto the saxy tree (Task 1)" do
    test "returns a non-binary parsed_doc carrying every legacy key plus :parse_tree" do
      assert {:ok, parsed_doc} = PureBeam.parse_safely(@well_formed_response)
      refute is_binary(parsed_doc)

      for key <- [
            :issuer,
            :status,
            :destination,
            :in_response_to,
            :audiences,
            :recipient,
            :assertion_times,
            :name_id,
            :name_id_format,
            :session_index,
            :attributes,
            :connection_id,
            :signature_method,
            :digest_method,
            :signed_candidates,
            :duplicate_ids,
            :key_info_trust,
            :parse_tree
          ] do
        assert Map.has_key?(parsed_doc, key), "parsed_doc is missing #{inspect(key)}"
      end
    end

    test "the :parse_tree key carries the SaxyTree root node" do
      assert {:ok, %{parse_tree: %Node{} = root}} = PureBeam.parse_safely(@well_formed_response)
      assert root.local == "Response"
    end

    test "each legacy field is re-derived from the tree and matches the regex-era values" do
      assert {:ok, parsed_doc} = PureBeam.parse_safely(@well_formed_response)

      assert parsed_doc.issuer == "https://idp.example.com/metadata"
      assert parsed_doc.status == "urn:oasis:names:tc:SAML:2.0:status:Success"
      assert parsed_doc.destination == "https://sp.example.com/saml/acs"
      assert parsed_doc.in_response_to == "id_request_123"
      assert parsed_doc.connection_id == "conn-123"
      assert parsed_doc.audiences == ["https://sp.example.com/metadata"]
      assert parsed_doc.recipient == "https://sp.example.com/saml/acs"
      assert parsed_doc.name_id == "user@example.com"

      assert parsed_doc.name_id_format ==
               "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"

      assert parsed_doc.session_index == "session-xyz"
      assert parsed_doc.attributes == %{"email" => ["user@example.com"]}
      assert parsed_doc.signature_method == @signature_method
      assert parsed_doc.digest_method == @digest_method
    end

    test "assertion_times is re-derived from Conditions / SubjectConfirmationData" do
      assert {:ok, %{assertion_times: times}} = PureBeam.parse_safely(@well_formed_response)

      assert times == %{
               not_before: "2026-04-24T15:58:00Z",
               not_on_or_after: "2026-04-24T16:05:00Z",
               subject_confirmation_not_on_or_after: "2026-04-24T16:05:00Z"
             }
    end

    test "signed_candidates carry xml_id/xpath/signed_xml + algorithm methods" do
      assert {:ok, %{signed_candidates: [candidate]}} =
               PureBeam.parse_safely(@well_formed_response)

      assert candidate.xml_id == "assertion-1"
      assert candidate.xpath == "/Response/Assertion[1]"
      assert is_binary(candidate.signed_xml)
      assert candidate.signed_xml =~ "Assertion"
      assert candidate.signature_method == @signature_method
      assert candidate.digest_method == @digest_method
    end
  end

  describe "parse_safely/2 pre-parse byte guards run BEFORE Saxy (Task 1)" do
    test "DOCTYPE is rejected on the raw binary" do
      assert {:error, %Error{type: :doctype_forbidden}} =
               PureBeam.parse_safely("<!DOCTYPE Response><Response/>")
    end

    test "ENTITY is rejected on the raw binary" do
      assert {:error, %Error{type: :entity_expansion_forbidden}} =
               PureBeam.parse_safely("<!ENTITY xxe 'boom'><Response/>")
    end

    test "oversize payload is rejected" do
      assert {:error, %Error{type: :payload_too_large}} =
               PureBeam.parse_safely(@well_formed_response, max_bytes: 8)
    end
  end

  describe "parse_safely/2 malformed mapping (Task 1)" do
    test "not-well-formed XML maps Saxy.ParseError to :malformed_xml" do
      assert {:error, %Error{type: :malformed_xml}} =
               PureBeam.parse_safely("<Response><Issuer>oops</Response>")
    end

    test "a non-binary input returns :malformed_xml via the kept fallback" do
      assert {:error, %Error{type: :malformed_xml}} = PureBeam.parse_safely(:not_a_binary, [])
    end
  end

  describe "tree-derived guards (Task 1)" do
    test "a document containing a KeyInfo element yields key_info_trust == true" do
      xml =
        "<Response Destination='https://sp.example.com/saml/acs' InResponseTo='id_request_123'><Issuer>https://idp.example.com/metadata</Issuer><Status><StatusCode Value='urn:oasis:names:tc:SAML:2.0:status:Success'/></Status><Assertion ID='assertion-1'><Conditions NotBefore='2026-04-24T15:58:00Z' NotOnOrAfter='2026-04-24T16:05:00Z'><AudienceRestriction><Audience>https://sp.example.com/metadata</Audience></AudienceRestriction></Conditions><Subject><SubjectConfirmation><SubjectConfirmationData Recipient='https://sp.example.com/saml/acs' NotOnOrAfter='2026-04-24T16:05:00Z'/></SubjectConfirmation></Subject></Assertion><Signature><KeyInfo><X509Data>cert</X509Data></KeyInfo><SignedInfo><SignatureMethod Algorithm='http://www.w3.org/2001/04/xmldsig-more#rsa-sha256'/><Reference URI='#assertion-1'><DigestMethod Algorithm='http://www.w3.org/2001/04/xmlenc#sha256'/></Reference></SignedInfo></Signature></Response>"

      assert {:ok, %{key_info_trust: true}} = PureBeam.parse_safely(xml)
    end

    test "a document with no KeyInfo yields key_info_trust == false" do
      assert {:ok, %{key_info_trust: false}} = PureBeam.parse_safely(@well_formed_response)
    end

    test "duplicate ID attrs across the tree yield a non-empty duplicate_ids list" do
      xml =
        "<Response Destination='https://sp.example.com/saml/acs' InResponseTo='id_request_123'><Issuer>https://idp.example.com/metadata</Issuer><Status><StatusCode Value='urn:oasis:names:tc:SAML:2.0:status:Success'/></Status><Assertion ID='dup'><Conditions NotBefore='2026-04-24T15:58:00Z' NotOnOrAfter='2026-04-24T16:05:00Z'><AudienceRestriction><Audience>https://sp.example.com/metadata</Audience></AudienceRestriction></Conditions><Subject><SubjectConfirmation><SubjectConfirmationData Recipient='https://sp.example.com/saml/acs' NotOnOrAfter='2026-04-24T16:05:00Z'/></SubjectConfirmation></Subject></Assertion><Assertion ID='dup'><Conditions NotBefore='2026-04-24T15:58:00Z' NotOnOrAfter='2026-04-24T16:05:00Z'><AudienceRestriction><Audience>https://sp.example.com/metadata</Audience></AudienceRestriction></Conditions><Subject><SubjectConfirmation><SubjectConfirmationData Recipient='https://sp.example.com/saml/acs' NotOnOrAfter='2026-04-24T16:05:00Z'/></SubjectConfirmation></Subject></Assertion><Signature><SignedInfo><SignatureMethod Algorithm='http://www.w3.org/2001/04/xmldsig-more#rsa-sha256'/><Reference URI='#dup'><DigestMethod Algorithm='http://www.w3.org/2001/04/xmlenc#sha256'/></Reference></SignedInfo></Signature></Response>"

      assert {:ok, %{duplicate_ids: dups}} = PureBeam.parse_safely(xml)
      assert "dup" in dups
    end
  end

  describe "select_signed_node/2 guard cascade (unchanged behaviour, Task 1)" do
    test "returns the only signed candidate with signature metadata" do
      assert {:ok, parsed_doc} = PureBeam.parse_safely(@well_formed_response)
      assert {:ok, handle} = PureBeam.select_signed_node(parsed_doc)

      assert handle.xml_id == "assertion-1"
      assert handle.xpath == "/Response/Assertion[1]"
      assert handle.signature_method == @signature_method
      assert handle.digest_method == @digest_method
    end

    test "rejects document-provided key info" do
      parsed_doc = base_parsed_doc(%{key_info_trust: true})

      assert {:error, %Error{type: :untrusted_certificate, details: details}} =
               PureBeam.select_signed_node(parsed_doc)

      assert details.reason == :document_keyinfo_forbidden
    end

    test "rejects duplicate ids before selecting a node" do
      parsed_doc = base_parsed_doc(%{duplicate_ids: ["dup-1", "dup-1"]})

      assert {:error, %Error{type: :duplicate_xml_id, details: details}} =
               PureBeam.select_signed_node(parsed_doc)

      assert details.duplicate_ids == ["dup-1", "dup-1"]
      assert details.duplicate_count == 2
    end

    test "rejects ambiguous candidates" do
      parsed_doc =
        base_parsed_doc(%{
          signed_candidates: [
            %{xml_id: "assertion-1", xpath: "/Response/Assertion[1]", signed_xml: "<a/>"},
            %{xml_id: "assertion-2", xpath: "/Response/Assertion[2]", signed_xml: "<a/>"}
          ]
        })

      assert {:error, %Error{type: :ambiguous_signed_node, details: details}} =
               PureBeam.select_signed_node(parsed_doc)

      assert details.candidate_count == 2
    end

    test "returns :missing_signature for a non-map handle (kept fallback)" do
      assert {:error, %Error{type: :missing_signature}} = PureBeam.select_signed_node(:doc, [])
    end
  end

  describe "node binding (D-10, Task 2)" do
    test "the selected handle carries a :node referencing the exact bound tree node" do
      assert {:ok, parsed_doc} = PureBeam.parse_safely(@well_formed_response)
      assert {:ok, handle} = PureBeam.select_signed_node(parsed_doc)

      assert %Node{} = handle.node
      assert handle.node.local == "Assertion"

      # The bound node is the SAME object reachable in the parse tree (no
      # re-found / re-parsed substring): it is the Assertion node under Response.
      tree_assertion =
        Enum.find(parsed_doc.parse_tree.children, fn child -> child.local == "Assertion" end)

      assert handle.node == tree_assertion
    end

    test "the handle binds the document's ds:Signature node for the enveloped transform" do
      assert {:ok, parsed_doc} = PureBeam.parse_safely(@well_formed_response)
      assert {:ok, handle} = PureBeam.select_signed_node(parsed_doc)

      assert %Node{local: "Signature"} = handle.signature_node
    end
  end

  describe "canonicalize/2 delegates to the C14N engine (Task 2)" do
    test "on a bound node returns {:ok, %{canonical_xml: bytes, xml_id:, xpath:}}" do
      assert {:ok, parsed_doc} = PureBeam.parse_safely(@well_formed_response)
      assert {:ok, handle} = PureBeam.select_signed_node(parsed_doc)
      assert {:ok, result} = PureBeam.canonicalize(handle)

      assert is_binary(result.canonical_xml)
      assert result.xml_id == "assertion-1"
      assert result.xpath == "/Response/Assertion[1]"

      # Canonical exclusive-C14N output starts with `<`, ends with `>`, and has
      # no trailing newline (Pitfall 4).
      assert String.starts_with?(result.canonical_xml, "<")
      assert String.ends_with?(result.canonical_xml, ">")
      refute String.ends_with?(result.canonical_xml, "\n")
    end

    test "canonical bytes derive from the exact bound node (the reference transform chain)" do
      assert {:ok, parsed_doc} = PureBeam.parse_safely(@well_formed_response)
      assert {:ok, handle} = PureBeam.select_signed_node(parsed_doc)
      assert {:ok, %{canonical_xml: out}} = PureBeam.canonicalize(handle)

      # These fixtures carry no ds:Transforms subtree, so the transform list is
      # empty: no prune, plain exclusive-C14N over the bound node. That equals
      # canonicalize_reference over the same node with an empty transform list.
      {:ok, expected} =
        Relyra.Security.XML.C14N.canonicalize_reference(
          handle.node,
          [],
          handle.signature_node,
          prefix_list: []
        )

      assert out == expected
    end
  end

  describe "canonicalize/2 fail-closed (Pitfall 9 / GATE-02, Task 2)" do
    test "the whole parsed_doc map fails closed as :canonicalization_failed" do
      assert {:ok, parsed_doc} = PureBeam.parse_safely(@well_formed_response)

      assert {:error, %Error{type: :canonicalization_failed, details: details}} =
               PureBeam.canonicalize(parsed_doc, [])

      assert details.reason == :invalid_signed_node_handle
    end

    test "a bare atom handle fails closed (seam_contract contract)" do
      assert {:error, %Error{type: :canonicalization_failed}} = PureBeam.canonicalize(:node, [])
    end

    test "a handle lacking a bindable :node fails closed" do
      assert {:error, %Error{type: :canonicalization_failed, details: details}} =
               PureBeam.canonicalize(%{xml_id: "assertion-1"})

      assert details.reason == :invalid_signed_node_handle
    end
  end

  defp base_parsed_doc(overrides) do
    Map.merge(
      %{
        key_info_trust: false,
        duplicate_ids: [],
        signature_method: @signature_method,
        digest_method: @digest_method,
        signed_candidates: [
          %{
            xml_id: "assertion-1",
            xpath: "/Response/Assertion[1]",
            signed_xml: "<Assertion ID='assertion-1'>signed payload</Assertion>"
          }
        ]
      },
      overrides
    )
  end
end
