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
      "<Response Destination='https://sp.example.com/saml/acs' InResponseTo='id_request_123'><Issuer>https://idp.example.com/metadata</Issuer><Status><StatusCode Value='urn:oasis:names:tc:SAML:2.0:status:Success'/></Status><Assertion ID='assertion-1'><Conditions NotBefore='2026-04-24T15:58:00Z' NotOnOrAfter='2026-04-24T16:05:00Z'><AudienceRestriction><Audience>https://sp.example.com/metadata</Audience></AudienceRestriction></Conditions><Subject><SubjectConfirmation><SubjectConfirmationData Recipient='https://sp.example.com/saml/acs' NotOnOrAfter='2026-04-24T16:05:00Z'/></SubjectConfirmation></Subject></Assertion><Signature><SignedInfo><SignatureMethod Algorithm='http://www.w3.org/2001/04/xmldsig-more#rsa-sha256'/><Reference URI='#assertion-1'><DigestMethod Algorithm='http://www.w3.org/2001/04/xmlenc#sha256'/></Reference></SignedInfo></Signature></Response>"

    assert {:ok, parsed_doc} = PureBeam.parse_safely(xml)
    refute is_binary(parsed_doc)
  end

  @tag :xml_seam
  test "select_signed_node and canonicalize return typed placeholder errors" do
    assert {:error, %Error{type: :missing_signature}} = PureBeam.select_signed_node(:doc, [])
    assert {:error, %Error{type: :canonicalization_failed}} = PureBeam.canonicalize(:node, [])
  end
end
