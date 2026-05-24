defmodule Relyra.Security.SignatureCryptoTest do
  @moduledoc """
  Phase 29 Plan 03 — cryptographic XMLDSig verification of the `[candidate]`
  arm of `verified_signed_node` (the published-hex auth-bypass site, D-01).

  This file owns the crypto negative controls that do NOT require a genuine
  signer (forged / garbage / non-base64 SignatureValue, truncated / malformed
  DigestValue, ECDSA fail-closed, malformed configured cert) PLUS a single
  GENUINE positive smoke that proves the wiring reaches `:public_key.verify`
  and the Reference-digest recompute (so broken wiring surfaces here, in
  Wave 2, not Wave 3). The fuller positive control + wrong-key / tampered-NameID
  negatives (driven by the reusable D-11 signer) and the existing-test triage
  land in Plan 04.

  Each negative control asserts a typed `{:error, %Relyra.Error{type: ...}}`
  and that the call RETURNS (never raises) — the auth path must fail CLOSED to a
  typed error, never crash (Pitfalls 3 and 4).
  """
  use ExUnit.Case, async: true

  alias Relyra.Error
  alias Relyra.Security.Signature
  alias Relyra.Security.XML.C14N
  alias Relyra.Security.XML.PureBeam
  alias Relyra.Security.XML.SaxyTree.Node

  @rsa_sha256 "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
  @rsa_sha256_digest "http://www.w3.org/2001/04/xmlenc#sha256"
  @ecdsa_sha256 "http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha256"

  # ---------------------------------------------------------------------------
  # Task 1 — the two new error atoms + the fail-closed PEM→pubkey helper.
  #
  # The helper (public_key_from_cert_chain/1) is private; it is exercised
  # end-to-end through Signature.verify/4: a GENUINE candidate with a MALFORMED
  # configured cert must map to :untrusted_certificate without raising (the
  # helper's contract). A genuine candidate with the matching cert verifies
  # {:ok, _} (proving the helper extracts a usable key) — covered by the
  # positive smoke below.
  # ---------------------------------------------------------------------------

  describe "new error atoms (xml_error_type union, D-08)" do
    test "Relyra.Error accepts :digest_mismatch and :unsupported_signature_algorithm" do
      assert %Error{type: :digest_mismatch} = Error.new(:digest_mismatch, "x")
      assert %Error{type: :unsupported_signature_algorithm} =
               Error.new(:unsupported_signature_algorithm, "x")
    end
  end

  describe "public_key_from_cert_chain/1 fail-closed (via Signature.verify/4)" do
    test "a deliberately-corrupt cert PEM → :untrusted_certificate (no raise)" do
      signed = genuine_signed_doc()

      corrupt_chain = ["-----BEGIN CERTIFICATE-----\nnot-base64-!!!\n-----END CERTIFICATE-----"]

      assert {:error, %Error{type: :untrusted_certificate}} =
               Signature.verify(signed.parsed_doc, connection(), corrupt_chain)
    end

    test "an empty-string cert PEM → :untrusted_certificate (no raise)" do
      signed = genuine_signed_doc()

      assert {:error, %Error{type: :untrusted_certificate}} =
               Signature.verify(signed.parsed_doc, connection(), [""])
    end

    test "a non-PEM garbage cert → :untrusted_certificate (no raise)" do
      signed = genuine_signed_doc()

      assert {:error, %Error{type: :untrusted_certificate}} =
               Signature.verify(signed.parsed_doc, connection(), ["not a pem at all"])
    end
  end

  # ---------------------------------------------------------------------------
  # Task 2 — crypto negative controls (no genuine signer required).
  # ---------------------------------------------------------------------------

  describe "signature math negative controls (SIGV-01, T-29-07)" do
    test "forged (well-formed, valid-base64) SignatureValue → :invalid_signature" do
      signed = genuine_signed_doc()
      # Replace the genuine SignatureValue with valid base64 of the right byte
      # length but the wrong bytes (a forged signature).
      forged_b64 = Base.encode64(:crypto.strong_rand_bytes(byte_size(signed.signature_bytes)))
      parsed_doc = put_candidate(signed.parsed_doc, :signature_value_b64, forged_b64)

      assert {:error, %Error{type: :invalid_signature}} =
               Signature.verify(parsed_doc, connection(), signed.cert_chain)
    end

    test "non-base64 SignatureValue → :invalid_signature (Base.decode64 :error mapped)" do
      signed = genuine_signed_doc()
      parsed_doc = put_candidate(signed.parsed_doc, :signature_value_b64, "!!!not-base64!!!")

      assert {:error, %Error{type: :invalid_signature}} =
               Signature.verify(parsed_doc, connection(), signed.cert_chain)
    end
  end

  describe "digest recompute negative controls (SIGV-02, T-29-08, Pitfall 4)" do
    test "truncated DigestValue (wrong decoded length) → :digest_mismatch (no crash)" do
      signed = genuine_signed_doc()
      # A base64 that decodes to fewer than 32 bytes — must NOT crash
      # :crypto.hash_equals (length guard must run first).
      truncated_b64 = Base.encode64(<<1, 2, 3>>)
      parsed_doc = put_candidate(signed.parsed_doc, :digest_value_b64, truncated_b64)

      assert {:error, %Error{type: :digest_mismatch}} =
               Signature.verify(parsed_doc, connection(), signed.cert_chain)
    end

    test "non-base64 DigestValue → :digest_mismatch (no crash)" do
      signed = genuine_signed_doc()
      parsed_doc = put_candidate(signed.parsed_doc, :digest_value_b64, "!!!not-base64!!!")

      assert {:error, %Error{type: :digest_mismatch}} =
               Signature.verify(parsed_doc, connection(), signed.cert_chain)
    end

    test "right-length-but-wrong DigestValue → :digest_mismatch" do
      signed = genuine_signed_doc()
      wrong_b64 = Base.encode64(:crypto.strong_rand_bytes(32))
      parsed_doc = put_candidate(signed.parsed_doc, :digest_value_b64, wrong_b64)

      assert {:error, %Error{type: :digest_mismatch}} =
               Signature.verify(parsed_doc, connection(), signed.cert_chain)
    end
  end

  describe "algorithm fail-closed (D-07, Pitfall 5)" do
    test "ECDSA signature method → :unsupported_signature_algorithm (before any verify)" do
      signed = genuine_signed_doc()
      # The allowlist permits ECDSA URIs (for SHA-2 strength); the digest-atom
      # gate is what rejects ECDSA before any crypto runs.
      parsed_doc = %{signed.parsed_doc | signature_method: @ecdsa_sha256}

      assert {:error, %Error{type: :unsupported_signature_algorithm}} =
               Signature.verify(parsed_doc, connection(), signed.cert_chain)
    end
  end

  describe "malformed configured cert (D-04, Pitfall 3)" do
    test "malformed cert with a genuine candidate → :untrusted_certificate (no raise)" do
      signed = genuine_signed_doc()

      assert {:error, %Error{type: :untrusted_certificate}} =
               Signature.verify(
                 signed.parsed_doc,
                 connection(),
                 ["-----BEGIN CERTIFICATE-----\ngarbage\n-----END CERTIFICATE-----"]
               )
    end
  end

  describe "pre-crypto trust gates still reject BEFORE crypto (D-01 regression)" do
    test "empty cert_chain rejects before crypto (:untrusted_certificate)" do
      signed = genuine_signed_doc()

      assert {:error, %Error{type: :untrusted_certificate}} =
               Signature.verify(signed.parsed_doc, connection(), [])
    end

    test "document KeyInfo trust rejects before crypto (:untrusted_certificate)" do
      signed = genuine_signed_doc()
      parsed_doc = Map.put(signed.parsed_doc, :key_info_trust, true)

      assert {:error, %Error{type: :untrusted_certificate, details: %{reason: :document_keyinfo_forbidden}}} =
               Signature.verify(parsed_doc, connection(), signed.cert_chain)
    end
  end

  # ---------------------------------------------------------------------------
  # GENUINE POSITIVE SMOKE (Wave 2 — proves the wiring reaches the crypto).
  # ---------------------------------------------------------------------------

  describe "genuine positive smoke (the wiring reaches :public_key.verify + digest recompute)" do
    test "a genuinely-signed candidate verifies {:ok, %SignedNode{}}" do
      signed = genuine_signed_doc()

      assert {:ok, %Relyra.Security.SignedNode{} = signed_node} =
               Signature.verify(signed.parsed_doc, connection(), signed.cert_chain)

      assert signed_node.signature_method == @rsa_sha256
      assert signed_node.digest_method == @rsa_sha256_digest
    end
  end

  # ---------------------------------------------------------------------------
  # In-test genuine XMLDSig signer (D-11 minimal local signer).
  #
  # Builds a real RSA-2048 keypair + self-signed cert PEM, a referenced
  # Assertion node, computes the REAL DigestValue over the canonicalized
  # Assertion (via PureBeam.canonicalize, the SAME engine the verifier uses),
  # embeds it in a SignedInfo, signs the canonicalized SignedInfo
  # (C14N.serialize, the SAME engine), and assembles a parsed_doc whose single
  # :signed_candidates entry carries the genuine D-02 values. This guarantees
  # the signer and verifier canonicalize identically (D-12).
  # ---------------------------------------------------------------------------

  defp genuine_signed_doc do
    {priv, cert_pem} = keypair_and_cert()

    assertion_id = "assertion-smoke-1"

    # The referenced Assertion (whitespace-free to keep the smoke independent of
    # pretty-print mixed-content concerns; the C14N walk is exercised either way).
    assertion_xml =
      "<Assertion xmlns=\"urn:oasis:names:tc:SAML:2.0:assertion\" ID=\"#{assertion_id}\">" <>
        "<Issuer>https://idp.example.com</Issuer>" <>
        "<Subject><NameID>user@example.com</NameID></Subject>" <>
        "</Assertion>"

    assertion_node = parse_node(assertion_xml)

    # Compute the genuine DigestValue over the canonicalized referenced element,
    # using the SAME canonicalize path the verifier uses (no ds:Transforms → plain
    # exclusive-C14N over the bound node).
    {:ok, %{canonical_xml: ref_bytes}} =
      PureBeam.canonicalize(%{node: assertion_node})

    digest = :crypto.hash(:sha256, ref_bytes)
    digest_value_b64 = Base.encode64(digest)

    # Build a SignedInfo embedding that DigestValue, then canonicalize it bare
    # (C14N.serialize, D-03 — SignedInfo carries no enveloped-signature transform).
    signed_info_xml =
      "<SignedInfo xmlns=\"http://www.w3.org/2000/09/xmldsig#\">" <>
        "<CanonicalizationMethod Algorithm=\"http://www.w3.org/2001/10/xml-exc-c14n#\"/>" <>
        "<SignatureMethod Algorithm=\"#{@rsa_sha256}\"/>" <>
        "<Reference URI=\"##{assertion_id}\">" <>
        "<DigestMethod Algorithm=\"#{@rsa_sha256_digest}\"/>" <>
        "<DigestValue>#{digest_value_b64}</DigestValue>" <>
        "</Reference>" <>
        "</SignedInfo>"

    signed_info_node = parse_node(signed_info_xml)

    {:ok, c14n_signed_info} = C14N.serialize(signed_info_node)
    signature_bytes = :public_key.sign(c14n_signed_info, :sha256, priv)
    signature_value_b64 = Base.encode64(signature_bytes)

    candidate = %{
      xml_id: assertion_id,
      xpath: "/Response/Assertion[1]",
      signed_xml: assertion_xml,
      node: assertion_node,
      signature_node: nil,
      transforms_node: nil,
      signed_info_node: signed_info_node,
      digest_value_b64: digest_value_b64,
      signature_value_b64: signature_value_b64
    }

    parsed_doc = %{
      key_info_trust: false,
      duplicate_ids: [],
      signature_method: @rsa_sha256,
      digest_method: @rsa_sha256_digest,
      signed_candidates: [candidate]
    }

    %{
      parsed_doc: parsed_doc,
      cert_chain: [cert_pem],
      signature_bytes: signature_bytes
    }
  end

  defp keypair_and_cert do
    priv = :public_key.generate_key({:rsa, 2048, 65_537})
    %{cert: cert_der} = :public_key.pkix_test_root_cert(~c"CN=relyra-crypto-test", [{:key, priv}])
    pem = :public_key.pem_encode([{:Certificate, cert_der, :not_encrypted}])
    {priv, pem}
  end

  defp parse_node(xml) do
    {:ok, %Node{} = node} = Relyra.Security.XML.SaxyTree.parse(xml)
    node
  end

  defp put_candidate(parsed_doc, key, value) do
    [candidate] = parsed_doc.signed_candidates
    %{parsed_doc | signed_candidates: [Map.put(candidate, key, value)]}
  end

  defp connection, do: %{connection_id: "conn-crypto"}
end
