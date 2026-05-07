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
