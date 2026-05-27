defmodule Relyra.Security.AdversarialCryptoTest do
  @moduledoc """
  Phase 30 Plan 02 (ASSUR-01 / ASSUR-02) — the PERMANENT, FakeIdP-driven
  adversarial crypto corpus.

  This suite PROMOTES the proven Phase-29 crypto recipes (from
  `test/relyra/security/signature_crypto_test.exs`) into a single permanent,
  `@moduletag :adversarial_crypto`-gated corpus and adds the genuinely-NEW
  c14n-differential `:digest_mismatch` case (D-06). It proves the FROZEN
  Phase-29 verify path (`Relyra.Security.Signature.verify/4`) rejects every
  named attack category and accepts only a genuine signature:

    * POSITIVE control — a genuinely `FakeIdP.sign`-signed Response verifies
      `{:ok, %SignedNode{}}` (drives END-TO-END through the promoted ASSUR-02
      real-signing path).
    * forged-sig — same-length random base64 SignatureValue → `:invalid_signature`.
    * wrong-key — a genuine doc verified against a throwaway cert → `:invalid_signature`.
    * tampered-content — post-signing NameID rewrite → `:digest_mismatch`.
    * c14n-differential (D-06) — a C14N-PRESERVED post-signing mutation (an added
      non-namespace attribute on the `<Assertion>` apex) → `:digest_mismatch`.
    * ECDSA carry-over — the algorithm-substitution sample → `:unsupported_signature_algorithm`.

  Every assertion pins the EXACT `%Relyra.Error{type: ...}` (or `%SignedNode{}`
  for the positive control), never a bare `{:error, _}`, so a no-op
  (C14N-normalized) mutation surfaces immediately as a `{:ok}` failure.

  Production crypto is FROZEN: this suite EXERCISES `Signature.verify/4` and the
  C14N engine; it does NOT modify `lib/relyra/security/signature.ex` or
  `lib/relyra/security/xml/pure_beam.ex` (D-10). No XSW-shaped input is built
  (that would brush a WR-03 fix — out of phase).

  Gating this suite into `ci.security` (`--only adversarial_crypto`) is Plan 04.
  """
  use ExUnit.Case, async: true

  @moduletag :adversarial_crypto

  alias Relyra.Error
  alias Relyra.Security.Signature
  alias Relyra.Security.XML.PureBeam
  alias Relyra.TestSupport.FakeIdP
  alias Relyra.TestSupport.XmldsigSigner

  @rsa_sha256 "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
  @ecdsa_sha256 "http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha256"

  # ---------------------------------------------------------------------------
  # POSITIVE CONTROL — ASSUR-02 end-to-end through the promoted FakeIdP.sign.
  #
  # `FakeIdP.sign/2` now delegates to the genuine Phase-29 signer (real
  # DigestValue + SignatureValue), so this literally exercises the real-signing
  # path: sign → base64-decode → parse → verify against the FakeIdP trust cert.
  # Only a genuine signature should return {:ok, %SignedNode{}}.
  # ---------------------------------------------------------------------------

  describe "positive control (ASSUR-02 — genuine FakeIdP.sign end-to-end)" do
    test "a genuinely FakeIdP-signed Response verifies {:ok, %SignedNode{}}" do
      b64 = FakeIdP.sign(FakeIdP.build_response())
      {:ok, xml} = Base.decode64(b64, padding: false)
      {:ok, parsed_doc} = PureBeam.parse_safely(xml, [])

      assert {:ok, %Relyra.Security.SignedNode{} = node} =
               Signature.verify(parsed_doc, connection(), [FakeIdP.self_signed_cert_pem()])

      assert node.signature_method == @rsa_sha256
    end
  end

  # ---------------------------------------------------------------------------
  # NEGATIVE CONTROLS — every attack category rejected with an EXACT typed error.
  #
  # The negatives drive through `XmldsigSigner.signed_response/1` (the cleaner
  # mutation seam); post-promotion both it and `FakeIdP.sign` go through the SAME
  # genuine signing path (D-01). Each negative reaches the FROZEN Phase-29 verify
  # path via `PureBeam.parse_safely → Signature.verify/4`.
  # ---------------------------------------------------------------------------

  describe "forged signature (ASSUR-01, T-30-06)" do
    test "same-length random-base64 SignatureValue → :invalid_signature" do
      signed = XmldsigSigner.signed_response()
      {:ok, parsed_doc} = PureBeam.parse_safely(signed.response_xml, [])

      # The genuine SignatureValue, decoded, is N bytes; forge N random bytes so
      # the forged value is valid base64 of the right length but the wrong bytes.
      [candidate] = parsed_doc.signed_candidates
      {:ok, genuine_bytes} = Base.decode64(candidate.signature_value_b64)
      forged_b64 = Base.encode64(:crypto.strong_rand_bytes(byte_size(genuine_bytes)))
      parsed_doc = put_candidate(parsed_doc, :signature_value_b64, forged_b64)

      assert {:error, %Error{type: :invalid_signature}} =
               Signature.verify(parsed_doc, connection(), signed.cert_chain)
    end
  end

  describe "wrong key (ASSUR-01, T-30-06)" do
    test "a genuine Response verified against a throwaway cert → :invalid_signature" do
      signed = XmldsigSigner.signed_response()
      {:ok, parsed_doc} = PureBeam.parse_safely(signed.response_xml, [])

      assert {:error, %Error{type: :invalid_signature}} =
               Signature.verify(parsed_doc, connection(), [throwaway_cert_pem()])
    end
  end

  describe "tampered content (ASSUR-01, T-30-07)" do
    test "NameID rewritten AFTER signing → :digest_mismatch" do
      signed = XmldsigSigner.signed_response(tamper_name_id: "attacker@evil.example.com")
      {:ok, parsed_doc} = PureBeam.parse_safely(signed.response_xml, [])

      assert {:error, %Error{type: :digest_mismatch}} =
               Signature.verify(parsed_doc, connection(), signed.cert_chain)
    end
  end

  describe "algorithm substitution (ASSUR-01, T-30-08)" do
    test "ECDSA signature method → :unsupported_signature_algorithm" do
      signed = XmldsigSigner.signed_response()
      {:ok, parsed_doc} = PureBeam.parse_safely(signed.response_xml, [])

      # The allowlist permits ECDSA URIs (for SHA-2 strength); the digest-atom
      # gate fail-closes ECDSA before any crypto runs.
      parsed_doc = %{parsed_doc | signature_method: @ecdsa_sha256}

      assert {:error, %Error{type: :unsupported_signature_algorithm}} =
               Signature.verify(parsed_doc, connection(), signed.cert_chain)
    end
  end

  # ---------------------------------------------------------------------------
  # C14N-DIFFERENTIAL (D-06, T-30-05) — the genuinely-NEW case.
  #
  # Mint a genuine doc, then apply a post-signing C14N-PRESERVED mutation into
  # the signed <Assertion> subtree WITHOUT recomputing the digest/signature
  # (mirroring the signer's `maybe_tamper_name_id` String.replace seam). The
  # mutation MUST change the recomputed exclusive-C14N digest so the Reference
  # digest no longer matches → :digest_mismatch.
  #
  # CHOSEN mutation: add a non-namespace attribute (`Foo="bar"`) to the
  # <Assertion ID="assertion-1"> apex. PROVENANCE Pitfall 8: C14N sorts
  # attributes by resolved-URI-then-local but NEVER drops them, so an added
  # non-namespace attribute is unambiguously C14N-PRESERVED (it appears in the
  # canonical output) → the recomputed digest differs.
  #
  # AVOID-list mutations (attribute reordering / unused-ns decl / empty-element
  # expansion / text re-escaping) are deliberately NOT used — C14N normalizes
  # them away, leaving the digest UNCHANGED, which would falsely pass {:ok}.
  # The assertion pins :digest_mismatch EXACTLY so a no-op surfaces as a {:ok}
  # failure immediately.
  #
  # No XSW-shaped input (genuine sig over assertion-A + injected attacker
  # assertion-B) is constructed — that would brush WR-03 (out of phase, D-10).
  # ---------------------------------------------------------------------------

  describe "c14n-differential tamper (ASSUR-01, D-06, T-30-05)" do
    test "added non-namespace attribute on <Assertion> apex → :digest_mismatch" do
      signed = XmldsigSigner.signed_response()

      # Post-signing C14N-PRESERVED mutation: add `Foo="bar"` to the apex.
      # `global: false` so only the apex <Assertion ID="assertion-1"> is touched.
      mutated_xml =
        String.replace(
          signed.response_xml,
          ~s(<Assertion ID="assertion-1">),
          ~s(<Assertion ID="assertion-1" Foo="bar">),
          global: false
        )

      # Guard: the mutation actually landed (a no-op replace would silently make
      # this test assert against the un-mutated, still-valid doc).
      assert mutated_xml =~ ~s(<Assertion ID="assertion-1" Foo="bar">)
      refute mutated_xml == signed.response_xml

      {:ok, parsed_doc} = PureBeam.parse_safely(mutated_xml, [])

      assert {:error, %Error{type: :digest_mismatch}} =
               Signature.verify(parsed_doc, connection(), signed.cert_chain)
    end
  end

  # ---------------------------------------------------------------------------
  # HTTP-REDIRECT BINDING TAMPERING (Phase 38 SLO)
  #
  # Ensure verify_redirect_signature/4 strictly rejects tampered query string bytes.
  # ---------------------------------------------------------------------------

  describe "HTTP-Redirect binding signature tampering (SLO-01, T-38-01)" do
    test "tampered query string → :invalid_signature" do
      raw_query =
        "SAMLRequest=fZJfa8IwFMXf%2FRQh7%2F1jhzKCrThFVnBb0bqHvYwsvWogTWpu6vTbr1ZlbqCQp5tzuL9zksFwXyqyA4vS6Jh2%2FZAS0MIUUq9jusyn3iMdJp0B8lJVbFS7jZ7DtgZ0pDFqZO1FTGurmeEokWleAjIn2GL0MmORH7LKGmeEUfTKct%2FBEcG6hoiSdBLTTwvqYLlXbTjCQ89bG1WA9viRxsKWkvcLf3TkTxFrSDU6rl0zCqO%2BF%2Fa8qJ%2BHIWvPByWTJoHU3LWujXMVsiCQReXDnpeVAl%2BYMkA0lIwuLGOjsS7BLsDupIDlfPbrxH%2FGJmHABVKSnbM%2FSX2q9F7sr5MI2XOeZ172tshp0jbP2kg2ubGuBMcL7vgguBaf3%2By1WZNOMqOkOJCpsSV3tym6fredyMJbtVJWa6xAyJWEoulCKfM9tsAdxNTZGigJktPWv58j6fwA&RelayState=TAMPERED_STATE&SigAlg=http%3A%2F%2Fwww.w3.org%2F2001%2F04%2Fxmldsig-more%23rsa-sha256"

      signature_b64_url =
        "pVBo9GCensNYwFWmcqMvInMx6e65BQeeUE%2FtW%2FjByVmSk4tFGFVRAYRGuz0NMzpvYARVpg1hniD8bOkUpGZifEf3C2Pr26r4rdFzWtLoYSHruANnXpYnJVvaT4VFnPBEun4tRYqNyVz5NZ%2FxmoossFnlHxbamy9FSnukDzZHaA4l6lsvsJRpEHCAc6nCe3Umq02xxg0A1ujfzpyGxsI46UZu4AcEv4HAcyFxHpU6Ij1aFi%2B37zg6UF7tSmlEOuK6styi1WD%2Brta3xnMUtddD2eFT9cl%2F85KBNryORonup0hMUQmQhgpe%2F6tpGafFg7V5hBYU0wuJnKZm6h1NfBl7vQ%3D%3D"

      signature_bytes = signature_b64_url |> URI.decode_www_form() |> Base.decode64!()

      pem =
        File.read!(
          Path.join([
            __DIR__,
            "../../fixtures/security/authn_request_signing/golden_signing_key.pem"
          ])
        )

      [entry | _] = :public_key.pem_decode(pem)
      private_key = :public_key.pem_entry_decode(entry)

      {:RSAPrivateKey, _version, modulus, public_exponent, _d, _p, _q, _exp1, _exp2, _coeff,
       _other} = private_key

      public_key = {:RSAPublicKey, modulus, public_exponent}

      assert {:error, %Error{type: :invalid_signature}} =
               Signature.verify_redirect_signature(
                 raw_query,
                 :sha256,
                 signature_bytes,
                 public_key
               )
    end
  end

  # ---------------------------------------------------------------------------
  # Local helpers (copied verbatim from the analog, signature_crypto_test.exs).
  # ---------------------------------------------------------------------------

  # A self-signed cert from a throwaway RSA keypair distinct from FakeIdP's, for
  # the wrong-key negative.
  defp throwaway_cert_pem do
    priv = :public_key.generate_key({:rsa, 2048, 65_537})
    %{cert: der} = :public_key.pkix_test_root_cert(~c"CN=relyra-wrong-key", key: priv)
    :public_key.pem_encode([{:Certificate, der, :not_encrypted}])
  end

  defp put_candidate(parsed_doc, key, value) do
    [candidate] = parsed_doc.signed_candidates
    %{parsed_doc | signed_candidates: [Map.put(candidate, key, value)]}
  end

  defp connection, do: %{connection_id: "conn-crypto"}
end
