defmodule Relyra.Security.SignedNodeBindingTest do
  use ExUnit.Case, async: true

  alias Relyra.Error
  alias Relyra.Security.Signature

  @allowed_signature_method "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
  @allowed_digest_method "http://www.w3.org/2001/04/xmlenc#sha256"

  test "verify/4 rejects key-info trust elevation" do
    parsed_doc = base_parsed_doc(%{key_info_trust: true})

    assert {:error, %Error{type: :untrusted_certificate, details: details}} =
             Signature.verify(parsed_doc, connection(), cert_chain())

    assert details.reason == :document_keyinfo_forbidden
    assert details.connection_id == "conn-1"
  end

  test "verify/4 rejects duplicate xml ids before signed-node success" do
    parsed_doc = base_parsed_doc(%{duplicate_ids: ["dup-1", "dup-1"]})

    assert {:error, %Error{type: :duplicate_xml_id, details: details}} =
             Signature.verify(parsed_doc, connection(), cert_chain())

    assert details.duplicate_count == 2
    assert details.connection_id == "conn-1"
  end

  test "verify/4 rejects ambiguous signed-node candidates" do
    parsed_doc =
      base_parsed_doc(%{
        signed_candidates: [
          %{
            xml_id: "assertion-1",
            xpath: "/Response/Assertion[1]",
            signed_xml: "<Assertion>1</Assertion>"
          },
          %{
            xml_id: "assertion-2",
            xpath: "/Response/Assertion[2]",
            signed_xml: "<Assertion>2</Assertion>"
          }
        ]
      })

    assert {:error, %Error{type: :ambiguous_signed_node, details: details}} =
             Signature.verify(parsed_doc, connection(), cert_chain())

    assert details.candidate_count == 2
    assert details.connection_id == "conn-1"
  end

  test "verify/4 rejects when configured cert chain is empty" do
    parsed_doc = base_parsed_doc()

    assert {:error, %Error{type: :untrusted_certificate, details: details}} =
             Signature.verify(parsed_doc, connection(), [])

    assert details.connection_id == "conn-1"
  end

  # Phase 29 Plan 03 triage (Rule 1/3): once real crypto is wired into the
  # [candidate] arm (D-01), a SINGLE structure-only candidate that selects past
  # all trust gates can no longer return {:ok} — it carries no SignedInfo /
  # SignatureValue / DigestValue, so the crypto fails CLOSED. This is the
  # bypass being closed: the selection path reaches exactly one candidate, then
  # rejects it for lacking signature material instead of trusting structure
  # alone. The genuine {:ok, %SignedNode{}} positive lives in
  # test/relyra/security/signature_crypto_test.exs (the in-test genuine signer);
  # the fuller end-to-end pipeline triage is Plan 04.
  test "verify/4 fails closed on a single structure-only candidate (no crypto inputs)" do
    assert {:error, %Error{type: :missing_signature, details: details}} =
             Signature.verify(base_parsed_doc(), connection(), cert_chain())

    assert details.reason == :missing_signature_input
    assert details.connection_id == "conn-1"
  end

  defp base_parsed_doc(overrides \\ %{}) do
    Map.merge(
      %{
        key_info_trust: false,
        duplicate_ids: [],
        signature_method: @allowed_signature_method,
        digest_method: @allowed_digest_method,
        signed_candidates: [
          %{
            xml_id: "assertion-1",
            xpath: "/Response/Assertion[1]",
            signed_xml: "<Assertion>signed</Assertion>"
          }
        ]
      },
      overrides
    )
  end

  defp connection do
    %{connection_id: "conn-1"}
  end

  defp cert_chain do
    ["pem-cert-chain"]
  end
end
