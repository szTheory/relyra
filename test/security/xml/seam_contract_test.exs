defmodule Relyra.Security.XML.SeamContractTest do
  use ExUnit.Case, async: true

  alias Relyra.Error
  alias Relyra.Security.XML
  alias Relyra.Security.XML.PureBeam

  @tag :xml_seam
  test "xml seam behaviour exposes required callbacks" do
    callbacks =
      XML.behaviour_info(:callbacks)
      |> Enum.map(&elem(&1, 0))

    assert :parse_safely in callbacks
    assert :select_signed_node in callbacks
    assert :canonicalize in callbacks
  end

  @tag :xml_seam
  test "parse_safely tuple contract returns parsed structure, not raw XML binary" do
    xml =
      "<samlp:Response xmlns:samlp='urn:oasis:names:tc:SAML:2.0:protocol' xmlns:saml='urn:oasis:names:tc:SAML:2.0:assertion' xmlns:ds='http://www.w3.org/2000/09/xmldsig#' Destination='https://sp.example.com/saml/acs' InResponseTo='id_request_123'><saml:Issuer>https://idp.example.com/metadata</saml:Issuer><samlp:Status><samlp:StatusCode Value='urn:oasis:names:tc:SAML:2.0:status:Success'/></samlp:Status><saml:Assertion ID='assertion-1'><saml:Issuer>https://idp.example.com/metadata</saml:Issuer><ds:Signature><ds:SignedInfo><ds:CanonicalizationMethod Algorithm='http://www.w3.org/2001/10/xml-exc-c14n#'/><ds:SignatureMethod Algorithm='http://www.w3.org/2001/04/xmldsig-more#rsa-sha256'/><ds:Reference URI='#assertion-1'><ds:Transforms><ds:Transform Algorithm='http://www.w3.org/2000/09/xmldsig#enveloped-signature'/><ds:Transform Algorithm='http://www.w3.org/2001/10/xml-exc-c14n#'/></ds:Transforms><ds:DigestMethod Algorithm='http://www.w3.org/2001/04/xmlenc#sha256'/><ds:DigestValue>AA==</ds:DigestValue></ds:Reference></ds:SignedInfo><ds:SignatureValue>AA==</ds:SignatureValue></ds:Signature><saml:Subject><saml:NameID>user@example.com</saml:NameID><saml:SubjectConfirmation Method='urn:oasis:names:tc:SAML:2.0:cm:bearer'><saml:SubjectConfirmationData Recipient='https://sp.example.com/saml/acs' NotOnOrAfter='2026-04-24T16:05:00Z'/></saml:SubjectConfirmation></saml:Subject><saml:Conditions NotBefore='2026-04-24T15:58:00Z' NotOnOrAfter='2026-04-24T16:05:00Z'><saml:AudienceRestriction><saml:Audience>https://sp.example.com/metadata</saml:Audience></saml:AudienceRestriction></saml:Conditions></saml:Assertion></samlp:Response>"

    assert {:ok, parsed_doc} = PureBeam.parse_safely(xml)
    refute is_binary(parsed_doc)
  end

  @tag :xml_seam
  test "select_signed_node and canonicalize return typed placeholder errors" do
    assert {:error, %Error{type: :missing_signature}} = PureBeam.select_signed_node(:doc, [])
    assert {:error, %Error{type: :canonicalization_failed}} = PureBeam.canonicalize(:node, [])
  end
end
