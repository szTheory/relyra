defmodule Relyra.Security.StrictDefaultProofTest do
  use ExUnit.Case, async: true

  alias Relyra.Error
  alias Relyra.Security.{AlgorithmPolicy, RelayState, Signature}

  @rsa_sha1 "http://www.w3.org/2000/09/xmldsig#rsa-sha1"
  @digest_sha1 "http://www.w3.org/2000/09/xmldsig#sha1"
  @allowed_signature_method "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
  @allowed_digest_method "http://www.w3.org/2001/04/xmlenc#sha256"

  test "deprecated_algorithm stays fail-closed for SHA-1 by default" do
    policy = AlgorithmPolicy.default()

    assert %Error{type: :deprecated_algorithm} =
             AlgorithmPolicy.enforce_signature_method(policy, @rsa_sha1)

    assert %Error{type: :deprecated_algorithm} =
             AlgorithmPolicy.enforce_digest_method(policy, @digest_sha1)
  end

  test "legacy_algorithm_override_expired rejects expired SHA-1 compatibility windows" do
    override = %{
      reason: "Compatibility window expired",
      expires_at: DateTime.add(DateTime.utc_now(), -60, :second)
    }

    policy = %{AlgorithmPolicy.default() | legacy_sha1: override}

    assert %Error{type: :legacy_algorithm_override_expired} =
             AlgorithmPolicy.enforce_signature_method(policy, @rsa_sha1)

    assert %Error{type: :legacy_algorithm_override_expired} =
             AlgorithmPolicy.enforce_digest_method(policy, @digest_sha1)
  end

  test "relay_state rejects raw URL values at the trust boundary" do
    assert {:error, %Error{type: :relay_state_rejected, details: details}} =
             RelayState.validate("https://tenant.example.com/dashboard")

    assert details.reason == :raw_url
  end

  test "signed content rejects document-provided key_info trust elevation" do
    parsed_doc = %{
      key_info_trust: true,
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
    }

    assert {:error, %Error{type: :untrusted_certificate, details: details}} =
             Signature.verify(parsed_doc, %{connection_id: "conn-proof"}, ["pem-cert-chain"])

    assert details.reason == :document_keyinfo_forbidden
  end
end
