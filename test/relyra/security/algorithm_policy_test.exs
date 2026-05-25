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

  @rsa_pkcs1_uri "http://www.w3.org/2001/04/xmlenc#rsa-1_5"
  @rsa_oaep_uri "http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p"
  @aes128_gcm_uri "http://www.w3.org/2001/04/xmlenc#aes128-gcm"
  @aes256_gcm_uri "http://www.w3.org/2001/04/xmlenc#aes256-gcm"
  @aes128_cbc_uri "http://www.w3.org/2001/04/xmlenc#aes128-cbc"
  @aes256_cbc_uri "http://www.w3.org/2001/04/xmlenc#aes256-cbc"

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

  describe "enforce_key_transport_algorithm/2 (PKCS1v1.5 hard-reject)" do
    test "RSA-PKCS1v1.5 URI is hard-rejected with default policy" do
      policy = AlgorithmPolicy.default()
      result = AlgorithmPolicy.enforce_key_transport_algorithm(policy, @rsa_pkcs1_uri)
      assert %Relyra.Error{type: :deprecated_algorithm} = result
    end

    test "RSA-PKCS1v1.5 URI is hard-rejected even when added to the allowlist" do
      policy = %{
        AlgorithmPolicy.default()
        | allowed_key_transport_algorithms: [@rsa_pkcs1_uri]
      }

      result = AlgorithmPolicy.enforce_key_transport_algorithm(policy, @rsa_pkcs1_uri)
      assert %Relyra.Error{type: :deprecated_algorithm} = result
    end

    test "RSA-OAEP (mgf1p) is allowed by default" do
      policy = AlgorithmPolicy.default()
      assert :ok = AlgorithmPolicy.enforce_key_transport_algorithm(policy, @rsa_oaep_uri)
    end

    test "unknown key transport URI is rejected" do
      policy = AlgorithmPolicy.default()

      result =
        AlgorithmPolicy.enforce_key_transport_algorithm(
          policy,
          "http://www.w3.org/2001/04/xmlenc#some-unknown"
        )

      assert %Relyra.Error{type: :deprecated_algorithm} = result
    end

    test "default/0 includes RSA-OAEP mgf1p in allowed_key_transport_algorithms" do
      policy = AlgorithmPolicy.default()
      assert is_list(policy.allowed_key_transport_algorithms)
      assert @rsa_oaep_uri in policy.allowed_key_transport_algorithms
    end

    test "default/0 has legacy_aes_cbc: nil" do
      policy = AlgorithmPolicy.default()
      assert policy.legacy_aes_cbc == nil
    end
  end

  describe "enforce_content_encryption_algorithm/3 (AES-GCM allowed by default)" do
    test "AES-128-GCM is allowed by default" do
      policy = AlgorithmPolicy.default()
      assert :ok = AlgorithmPolicy.enforce_content_encryption_algorithm(policy, @aes128_gcm_uri)
    end

    test "AES-256-GCM is allowed by default" do
      policy = AlgorithmPolicy.default()
      assert :ok = AlgorithmPolicy.enforce_content_encryption_algorithm(policy, @aes256_gcm_uri)
    end
  end

  describe "enforce_content_encryption_algorithm/3 (AES-CBC default reject + hatch)" do
    test "AES-128-CBC is rejected by default" do
      policy = AlgorithmPolicy.default()

      result = AlgorithmPolicy.enforce_content_encryption_algorithm(policy, @aes128_cbc_uri)
      assert %Relyra.Error{type: :deprecated_algorithm} = result
    end

    test "AES-256-CBC is rejected by default" do
      policy = AlgorithmPolicy.default()

      result = AlgorithmPolicy.enforce_content_encryption_algorithm(policy, @aes256_cbc_uri)
      assert %Relyra.Error{type: :deprecated_algorithm} = result
    end

    test "AES-128-CBC is allowed when legacy_aes_cbc hatch is active and not expired" do
      policy = %{
        AlgorithmPolicy.default()
        | legacy_aes_cbc: %{
            reason: "Legacy IdP compatibility",
            expires_at: DateTime.add(DateTime.utc_now(), 3600, :second)
          }
      }

      assert :ok = AlgorithmPolicy.enforce_content_encryption_algorithm(policy, @aes128_cbc_uri)
    end

    test "AES-128-CBC is rejected with :legacy_algorithm_override_expired when hatch is expired" do
      policy = %{
        AlgorithmPolicy.default()
        | legacy_aes_cbc: %{
            reason: "Expired window",
            expires_at: DateTime.add(DateTime.utc_now(), -60, :second)
          }
      }

      result = AlgorithmPolicy.enforce_content_encryption_algorithm(policy, @aes128_cbc_uri)
      assert %Relyra.Error{type: :legacy_algorithm_override_expired} = result
    end
  end

  describe "enforce_content_encryption_algorithm/3 (auth tag guard — D-03)" do
    test "auth_tag of 3 bytes (< 16) returns :decryption_failed" do
      policy = AlgorithmPolicy.default()

      assert :decryption_failed =
               AlgorithmPolicy.enforce_content_encryption_algorithm(policy, @aes128_gcm_uri,
                 auth_tag: <<1, 2, 3>>
               )
    end

    test "auth_tag of 15 bytes (one short) returns :decryption_failed" do
      policy = AlgorithmPolicy.default()

      assert :decryption_failed =
               AlgorithmPolicy.enforce_content_encryption_algorithm(policy, @aes128_gcm_uri,
                 auth_tag: :binary.copy(<<0>>, 15)
               )
    end

    test "auth_tag of exactly 16 bytes returns :ok for AES-GCM" do
      policy = AlgorithmPolicy.default()

      assert :ok =
               AlgorithmPolicy.enforce_content_encryption_algorithm(policy, @aes128_gcm_uri,
                 auth_tag: :binary.copy(<<0>>, 16)
               )
    end

    test "auth_tag < 16 bytes returns :decryption_failed even for AES-CBC (guard fires FIRST)" do
      policy = AlgorithmPolicy.default()

      # AES-256-CBC would normally be rejected as :deprecated_algorithm,
      # but the auth tag guard fires FIRST and returns the opaque :decryption_failed atom.
      assert :decryption_failed =
               AlgorithmPolicy.enforce_content_encryption_algorithm(policy, @aes256_cbc_uri,
                 auth_tag: <<1, 2, 3>>
               )
    end
  end
end
