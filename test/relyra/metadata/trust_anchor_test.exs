defmodule Relyra.Metadata.TrustAnchorTest do
  use ExUnit.Case, async: true
  alias Relyra.Error
  alias Relyra.Metadata.TrustAnchor

  @pem_a "-----BEGIN CERTIFICATE-----\nAAAA\n-----END CERTIFICATE-----"
  @pem_b "-----BEGIN CERTIFICATE-----\nBBBB\n-----END CERTIFICATE-----"
  @pem_c "-----BEGIN CERTIFICATE-----\nCCCC\n-----END CERTIFICATE-----"

  describe "fingerprint/1" do
    test "produces a 64-char lowercase hex SHA-256 (no colons)" do
      fp = TrustAnchor.fingerprint(@pem_a)
      assert String.length(fp) == 64
      assert fp == String.downcase(fp)
      refute String.contains?(fp, ":")
    end

    test "CR-02: hashes the certificate DER bytes (matches openssl), NOT the PEM text" do
      # A real self-signed cert. The operator pins the DER SHA-256 via
      # `openssl x509 -outform DER | openssl dgst -sha256`; the trust check MUST
      # compute the SAME thing or the pin can never match.
      pem = Relyra.TestSupport.XmldsigSigner.self_signed_cert_pem()
      [{:Certificate, der, :not_encrypted} | _] = :public_key.pem_decode(pem)

      expected_der_fp = :crypto.hash(:sha256, der) |> Base.encode16(case: :lower)
      legacy_pem_text_fp = :crypto.hash(:sha256, pem) |> Base.encode16(case: :lower)

      assert TrustAnchor.fingerprint(pem) == expected_der_fp
      refute TrustAnchor.fingerprint(pem) == legacy_pem_text_fp
    end

    test "returns a non-64-hex sentinel for undecodable input (fail-closed)" do
      # Junk can never collide with a real (64-hex) pinned fingerprint.
      refute String.length(TrustAnchor.fingerprint("not a certificate")) == 64
    end
  end

  describe "matching_pems/2 (CR-01: verify against pinned certs ONLY)" do
    test "returns ONLY the pinned candidate(s) — an unpinned cert prepended FIRST is excluded" do
      # The CR-01 attack shape: an attacker prepends their own cert (@pem_a) ahead
      # of the legitimate, public, pinned cert (@pem_b). matching_pems must hand
      # the caller ONLY the pinned cert so the signature is verified against it —
      # never the attacker's first cert.
      pinned = [TrustAnchor.fingerprint(@pem_b)]

      assert {:ok, matched} = TrustAnchor.matching_pems([@pem_a, @pem_b], pinned)
      assert matched == [@pem_b]
      refute @pem_a in matched
    end

    test "returns all pinned matches (rotation window), preserving document order" do
      pinned = [TrustAnchor.fingerprint(@pem_a), TrustAnchor.fingerprint(@pem_b)]
      assert {:ok, [@pem_a, @pem_b]} = TrustAnchor.matching_pems([@pem_a, @pem_b, @pem_c], pinned)
    end

    test "rejects with :trust_anchor_mismatch / :no_match when no candidate is pinned" do
      assert {:error, %Error{type: :trust_anchor_mismatch, details: %{reason: :no_match}}} =
               TrustAnchor.matching_pems([@pem_a, @pem_c], [TrustAnchor.fingerprint(@pem_b)])
    end

    test "rejects with :no_pinned_fingerprints on an empty pinned list (no-TOFU, D-17)" do
      assert {:error,
              %Error{type: :trust_anchor_mismatch, details: %{reason: :no_pinned_fingerprints}}} =
               TrustAnchor.matching_pems([@pem_a], [])
    end
  end

  describe "check/2" do
    test "returns :ok when at least one candidate PEM matches a pinned fingerprint" do
      pinned = [TrustAnchor.fingerprint(@pem_a), TrustAnchor.fingerprint(@pem_b)]
      assert :ok = TrustAnchor.check([@pem_a, @pem_c], pinned)
    end

    test "supports multi-valued pinned fingerprints (rotation — D-17)" do
      # Pinning two fingerprints during a rotation window
      pinned = [TrustAnchor.fingerprint(@pem_a), TrustAnchor.fingerprint(@pem_b)]
      assert :ok = TrustAnchor.check([@pem_b], pinned)
    end

    test "rejects with :trust_anchor_mismatch when no candidate matches" do
      pinned = [TrustAnchor.fingerprint(@pem_a)]

      assert {:error, %Error{type: :trust_anchor_mismatch} = err} =
               TrustAnchor.check([@pem_b, @pem_c], pinned)

      assert err.details.reason == :no_match
    end

    test "rejects with :no_pinned_fingerprints when pinned list is empty (defense-in-depth — schema gate from Plan 01 should prevent this)" do
      assert {:error, %Error{type: :trust_anchor_mismatch} = err} =
               TrustAnchor.check([@pem_a], [])

      assert err.details.reason == :no_pinned_fingerprints
    end

    test "case-normalizes pinned fingerprints (handles operator pasting uppercase from openssl output)" do
      pinned = [String.upcase(TrustAnchor.fingerprint(@pem_a))]
      assert :ok = TrustAnchor.check([@pem_a], pinned)
    end
  end
end
