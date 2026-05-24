defmodule Relyra.Security.XML.PureBeamCandidateTest do
  @moduledoc """
  D-02 coverage: the SignedInfo node + base64 DigestValue + base64 SignatureValue
  surface per signed candidate and survive `select_signed_node/2` onto the handle
  Plan 03's crypto reads. Absent DigestValue / SignatureValue must yield nil (no
  crash) — these are attacker-controlled DATA fields, never required to be present
  for the seam to return a handle.
  """
  use ExUnit.Case, async: true

  alias Relyra.Security.XML.PureBeam
  alias Relyra.Security.XML.SaxyTree.Node

  @digest_value "Yp4z9Q3X1dabc+DigestBase64=="
  @signature_value "Sg9q1RqVerySignatureBase64Value=="

  # A well-formed single-signed-node SAML Response carrying a full
  # <Signature><SignedInfo>…<DigestValue>…</SignedInfo><SignatureValue>…</Signature>.
  @signed_response """
  <Response Destination='https://sp.example.com/saml/acs' InResponseTo='id_request_123'>\
  <Issuer>https://idp.example.com/metadata</Issuer>\
  <Status><StatusCode Value='urn:oasis:names:tc:SAML:2.0:status:Success'/></Status>\
  <Assertion ID='assertion-1'>\
  <Subject><NameID>user@example.com</NameID>\
  <SubjectConfirmation><SubjectConfirmationData Recipient='https://sp.example.com/saml/acs' NotOnOrAfter='2026-04-24T16:05:00Z'/></SubjectConfirmation></Subject>\
  <Conditions NotBefore='2026-04-24T15:58:00Z' NotOnOrAfter='2026-04-24T16:05:00Z'>\
  <AudienceRestriction><Audience>https://sp.example.com/metadata</Audience></AudienceRestriction></Conditions>\
  </Assertion>\
  <Signature>\
  <SignedInfo>\
  <SignatureMethod Algorithm='http://www.w3.org/2001/04/xmldsig-more#rsa-sha256'/>\
  <Reference URI='#assertion-1'><DigestMethod Algorithm='http://www.w3.org/2001/04/xmlenc#sha256'/><DigestValue>  #{@digest_value}  </DigestValue></Reference>\
  </SignedInfo>\
  <SignatureValue>
    #{@signature_value}
  </SignatureValue>\
  </Signature>\
  </Response>
  """

  # The same single-signed-node Response but with NO DigestValue and NO
  # SignatureValue inside the Signature — the absent-value path.
  @signed_response_without_values """
  <Response Destination='https://sp.example.com/saml/acs' InResponseTo='id_request_123'>\
  <Issuer>https://idp.example.com/metadata</Issuer>\
  <Status><StatusCode Value='urn:oasis:names:tc:SAML:2.0:status:Success'/></Status>\
  <Assertion ID='assertion-1'>\
  <Subject><NameID>user@example.com</NameID>\
  <SubjectConfirmation><SubjectConfirmationData Recipient='https://sp.example.com/saml/acs' NotOnOrAfter='2026-04-24T16:05:00Z'/></SubjectConfirmation></Subject>\
  <Conditions NotBefore='2026-04-24T15:58:00Z' NotOnOrAfter='2026-04-24T16:05:00Z'>\
  <AudienceRestriction><Audience>https://sp.example.com/metadata</Audience></AudienceRestriction></Conditions>\
  </Assertion>\
  <Signature>\
  <SignedInfo>\
  <SignatureMethod Algorithm='http://www.w3.org/2001/04/xmldsig-more#rsa-sha256'/>\
  <Reference URI='#assertion-1'><DigestMethod Algorithm='http://www.w3.org/2001/04/xmlenc#sha256'/></Reference>\
  </SignedInfo>\
  </Signature>\
  </Response>
  """

  defp select(xml) do
    assert {:ok, parsed_doc} = PureBeam.parse_safely(xml)
    PureBeam.select_signed_node(parsed_doc, [])
  end

  describe "D-02 fields on the handle returned by select_signed_node/2" do
    test ":signed_info_node is the SignedInfo SaxyTree.Node" do
      assert {:ok, handle} = select(@signed_response)
      assert %Node{local: "SignedInfo"} = handle.signed_info_node
    end

    test ":digest_value_b64 equals the trimmed base64 DigestValue text" do
      assert {:ok, handle} = select(@signed_response)
      assert handle.digest_value_b64 == @digest_value
    end

    test ":signature_value_b64 equals the trimmed base64 SignatureValue text" do
      assert {:ok, handle} = select(@signed_response)
      assert handle.signature_value_b64 == @signature_value
    end

    test "absent DigestValue / SignatureValue yield nil (no raise)" do
      assert {:ok, handle} = select(@signed_response_without_values)
      # SignedInfo is still present, so the node surfaces; the two base64 values
      # are absent and must be nil rather than crashing.
      assert %Node{local: "SignedInfo"} = handle.signed_info_node
      assert handle.digest_value_b64 == nil
      assert handle.signature_value_b64 == nil
    end
  end

  describe "D-02 fields on the candidate map in parse_safely/2" do
    test "each signed candidate carries the three new keys (additive)" do
      assert {:ok, %{signed_candidates: [candidate]}} = PureBeam.parse_safely(@signed_response)

      assert %Node{local: "SignedInfo"} = candidate.signed_info_node
      assert candidate.digest_value_b64 == @digest_value
      assert candidate.signature_value_b64 == @signature_value

      # existing keys remain unchanged (regression guard)
      assert candidate.xml_id == "assertion-1"
      assert %Node{local: "Assertion"} = candidate.node
      assert %Node{local: "Signature"} = candidate.signature_node
    end
  end
end
