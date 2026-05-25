defmodule Relyra.Security.AlgorithmPolicyTest do
  @moduledoc """
  D-06 / D-07 coverage for `digest_atom_for_signature_method/1`: RSA-SHA{256,384,512}
  URIs map to the correct digest atom, while ECDSA and unknown / non-binary input
  fail CLOSED with `:unsupported_signature_algorithm` (Pitfall 5 — ECDSA must NOT
  fail open). The reject lives in this function, not in `default/0`'s allowlist, so
  the test also pins that ECDSA URIs remain allowlisted (proving fail-CLOSED, not
  allowlist-removal).
  """
  use ExUnit.Case, async: true

  alias Relyra.Security.AlgorithmPolicy

  @rsa_sha256 "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
  @rsa_sha384 "http://www.w3.org/2001/04/xmldsig-more#rsa-sha384"
  @rsa_sha512 "http://www.w3.org/2001/04/xmldsig-more#rsa-sha512"
  @ecdsa_sha256 "http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha256"
  @ecdsa_sha384 "http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha384"
  @ecdsa_sha512 "http://www.w3.org/2001/04/xmldsig-more#ecdsa-sha512"

  describe "digest_atom_for_signature_method/1 (D-06 RSA → atom)" do
    test "rsa-sha256 URI maps to :sha256" do
      assert AlgorithmPolicy.digest_atom_for_signature_method(@rsa_sha256) == {:ok, :sha256}
    end

    test "rsa-sha384 URI maps to :sha384" do
      assert AlgorithmPolicy.digest_atom_for_signature_method(@rsa_sha384) == {:ok, :sha384}
    end

    test "rsa-sha512 URI maps to :sha512" do
      assert AlgorithmPolicy.digest_atom_for_signature_method(@rsa_sha512) == {:ok, :sha512}
    end
  end

  describe "digest_atom_for_signature_method/1 (D-07 fail-closed)" do
    test "ecdsa-sha256 URI fails closed" do
      assert AlgorithmPolicy.digest_atom_for_signature_method(@ecdsa_sha256) ==
               {:error, :unsupported_signature_algorithm}
    end

    test "all ECDSA URIs fail closed (sha384 / sha512 too)" do
      assert AlgorithmPolicy.digest_atom_for_signature_method(@ecdsa_sha384) ==
               {:error, :unsupported_signature_algorithm}

      assert AlgorithmPolicy.digest_atom_for_signature_method(@ecdsa_sha512) ==
               {:error, :unsupported_signature_algorithm}
    end

    test "an unknown URI fails closed" do
      assert AlgorithmPolicy.digest_atom_for_signature_method(
               "http://www.w3.org/2000/09/xmldsig#rsa-sha1"
             ) ==
               {:error, :unsupported_signature_algorithm}

      assert AlgorithmPolicy.digest_atom_for_signature_method("urn:example:not-a-real-alg") ==
               {:error, :unsupported_signature_algorithm}
    end

    test "nil fails closed (no raise)" do
      assert AlgorithmPolicy.digest_atom_for_signature_method(nil) ==
               {:error, :unsupported_signature_algorithm}
    end

    test "non-binary input fails closed (no raise)" do
      assert AlgorithmPolicy.digest_atom_for_signature_method(:rsa_sha256) ==
               {:error, :unsupported_signature_algorithm}

      assert AlgorithmPolicy.digest_atom_for_signature_method(%{}) ==
               {:error, :unsupported_signature_algorithm}
    end
  end

  describe "ECDSA reject is fail-CLOSED, not allowlist-removal" do
    test "ECDSA URIs remain in default/0 allowlist (unchanged)" do
      allowed = AlgorithmPolicy.default().allowed_signature_methods

      assert @ecdsa_sha256 in allowed
      assert @ecdsa_sha384 in allowed
      assert @ecdsa_sha512 in allowed
    end
  end
end
