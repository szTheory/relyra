defmodule Relyra.Security.XML.PureBeamMetadataRootTest do
  @moduledoc """
  SIGV-04 plumbing (D-13): `PureBeam.parse_metadata_root_safely/2` emits the SAME
  canonical signed-candidate shape the assertion path emits — carrying the D-02
  crypto inputs (`:signed_info_node` / `:digest_value_b64` / `:signature_value_b64`)
  plus the bound `:node` — but rooted at the metadata envelope
  (`<EntityDescriptor>` / `<EntitiesDescriptor>`).

  This is the metadata-path producer that closes the regex-candidate gap: the
  metadata root now routes through the SAME SaxyTree builder (D-04, one trust
  path) and surfaces the crypto inputs Plan 03's `do_verify/4` consumes, with the
  XXE/DOCTYPE/size guards preserved (XXE-before-verify, D-09).
  """
  use ExUnit.Case, async: true

  alias Relyra.Error
  alias Relyra.Security.XML.PureBeam
  alias Relyra.Security.XML.SaxyTree.Node

  @digest_value "Yp4z9Q3X1dabc+DigestBase64=="
  @signature_value "Sg9q1RqVerySignatureBase64Value=="
  @rsa_sha256 "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
  @sha256 "http://www.w3.org/2001/04/xmlenc#sha256"

  # A signed <EntityDescriptor> root carrying a child <ds:Signature> with a full
  # SignedInfo / DigestValue / SignatureValue. No document KeyInfo on the root
  # (the KeyDescriptor's KeyInfo lives under IDPSSODescriptor — operator pins the
  # signing cert out-of-band; document KeyInfo is never the trust source).
  @signed_entity_descriptor """
  <md:EntityDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata" xmlns:ds="http://www.w3.org/2000/09/xmldsig#" entityID="https://idp.example.com/entity" ID="_root">\
  <ds:Signature>\
  <ds:SignedInfo>\
  <ds:SignatureMethod Algorithm="#{@rsa_sha256}"/>\
  <ds:Reference URI="#_root"><ds:DigestMethod Algorithm="#{@sha256}"/><ds:DigestValue>#{@digest_value}</ds:DigestValue></ds:Reference>\
  </ds:SignedInfo>\
  <ds:SignatureValue>#{@signature_value}</ds:SignatureValue>\
  </ds:Signature>\
  <md:IDPSSODescriptor>\
  <md:SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="https://idp.example.com/sso/redirect"/>\
  </md:IDPSSODescriptor>\
  </md:EntityDescriptor>
  """

  @signed_entities_descriptor """
  <md:EntitiesDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata" xmlns:ds="http://www.w3.org/2000/09/xmldsig#" ID="_group">\
  <ds:Signature>\
  <ds:SignedInfo>\
  <ds:SignatureMethod Algorithm="#{@rsa_sha256}"/>\
  <ds:Reference URI="#_group"><ds:DigestMethod Algorithm="#{@sha256}"/><ds:DigestValue>#{@digest_value}</ds:DigestValue></ds:Reference>\
  </ds:SignedInfo>\
  <ds:SignatureValue>#{@signature_value}</ds:SignatureValue>\
  </ds:Signature>\
  <md:EntityDescriptor entityID="https://idp.example.com/entity">\
  <md:IDPSSODescriptor>\
  <md:SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="https://idp.example.com/sso/redirect"/>\
  </md:IDPSSODescriptor>\
  </md:EntityDescriptor>\
  </md:EntitiesDescriptor>
  """

  # A metadata root with NO child ds:Signature (unsigned) — fail closed.
  @unsigned_entity_descriptor """
  <md:EntityDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata" entityID="https://idp.example.com/entity" ID="_root">\
  <md:IDPSSODescriptor>\
  <md:SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="https://idp.example.com/sso/redirect"/>\
  </md:IDPSSODescriptor>\
  </md:EntityDescriptor>
  """

  describe "parse_metadata_root_safely/2 candidate shape (same as the assertion path)" do
    test "the single signed candidate carries the D-02 crypto inputs" do
      assert {:ok, %{signed_candidates: [candidate]}} =
               PureBeam.parse_metadata_root_safely(@signed_entity_descriptor)

      assert %Node{local: "SignedInfo"} = candidate.signed_info_node
      assert candidate.digest_value_b64 == @digest_value
      assert candidate.signature_value_b64 == @signature_value
      assert %Node{local: "Signature"} = candidate.signature_node
    end

    test "the candidate :node is the EntityDescriptor tree node (anti-XSW)" do
      assert {:ok, %{signed_candidates: [candidate]}} =
               PureBeam.parse_metadata_root_safely(@signed_entity_descriptor)

      assert %Node{local: local} = candidate.node
      assert local in ["EntityDescriptor", "EntitiesDescriptor"]
      assert local == "EntityDescriptor"
    end

    test "an EntitiesDescriptor root is also bound as the candidate :node" do
      assert {:ok, %{signed_candidates: [candidate]}} =
               PureBeam.parse_metadata_root_safely(@signed_entities_descriptor)

      assert %Node{local: "EntitiesDescriptor"} = candidate.node
      assert candidate.xpath == "/EntitiesDescriptor"
    end

    test "signature_method / digest_method are derived from the SignedInfo" do
      assert {:ok, parsed_doc} =
               PureBeam.parse_metadata_root_safely(@signed_entity_descriptor)

      assert parsed_doc.signature_method == @rsa_sha256
      assert parsed_doc.digest_method == @sha256
    end

    test "key_info_trust and duplicate_ids are present (tree-derived)" do
      assert {:ok, parsed_doc} =
               PureBeam.parse_metadata_root_safely(@signed_entity_descriptor)

      assert Map.has_key?(parsed_doc, :key_info_trust)
      assert Map.has_key?(parsed_doc, :duplicate_ids)
      # No KeyInfo on this root → false; no duplicate IDs → [].
      assert parsed_doc.key_info_trust == false
      assert parsed_doc.duplicate_ids == []
    end
  end

  describe "parse_metadata_root_safely/2 fail-closed and guards" do
    test "an unsigned metadata root fails closed with :missing_signature" do
      assert {:error, %Error{type: :missing_signature}} =
               PureBeam.parse_metadata_root_safely(@unsigned_entity_descriptor)
    end

    test "a non-metadata root fails closed with :missing_signature" do
      assert {:error, %Error{type: :missing_signature}} =
               PureBeam.parse_metadata_root_safely("<Response><Issuer>x</Issuer></Response>")
    end

    test "a DOCTYPE metadata input is rejected BEFORE Saxy (XXE-before-verify, D-09)" do
      doctype_xml =
        "<!DOCTYPE foo [<!ENTITY xxe \"x\">]>" <> @signed_entity_descriptor

      assert {:error, %Error{type: :doctype_forbidden}} =
               PureBeam.parse_metadata_root_safely(doctype_xml)
    end

    test "an ENTITY metadata input is rejected BEFORE Saxy" do
      entity_xml = "<!ENTITY foo \"bar\">" <> @signed_entity_descriptor

      assert {:error, %Error{type: :entity_expansion_forbidden}} =
               PureBeam.parse_metadata_root_safely(entity_xml)
    end

    test "an oversize metadata input is rejected" do
      assert {:error, %Error{type: :payload_too_large}} =
               PureBeam.parse_metadata_root_safely(@signed_entity_descriptor, max_bytes: 10)
    end

    test "non-binary input is rejected as malformed_xml" do
      assert {:error, %Error{type: :malformed_xml}} =
               PureBeam.parse_metadata_root_safely(nil)
    end

    test "a document KeyInfo on the metadata root surfaces key_info_trust: true" do
      xml =
        """
        <md:EntityDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata" xmlns:ds="http://www.w3.org/2000/09/xmldsig#" entityID="https://idp.example.com/entity" ID="_root">\
        <ds:Signature>\
        <ds:SignedInfo>\
        <ds:SignatureMethod Algorithm="#{@rsa_sha256}"/>\
        <ds:Reference URI="#_root"><ds:DigestMethod Algorithm="#{@sha256}"/><ds:DigestValue>#{@digest_value}</ds:DigestValue></ds:Reference>\
        </ds:SignedInfo>\
        <ds:SignatureValue>#{@signature_value}</ds:SignatureValue>\
        <ds:KeyInfo><ds:X509Data><ds:X509Certificate>STUB</ds:X509Certificate></ds:X509Data></ds:KeyInfo>\
        </ds:Signature>\
        </md:EntityDescriptor>
        """

      assert {:ok, parsed_doc} = PureBeam.parse_metadata_root_safely(xml)
      assert parsed_doc.key_info_trust == true
    end
  end
end
