defmodule Relyra.Security.SignaturePolicyTest do
  use ExUnit.Case, async: true

  alias Relyra.Error
  alias Relyra.Security.AlgorithmPolicy

  @rsa_sha1 "http://www.w3.org/2000/09/xmldsig#rsa-sha1"
  @digest_sha1 "http://www.w3.org/2000/09/xmldsig#sha1"

  test "default policy rejects sha1 methods with deprecated_algorithm" do
    policy = AlgorithmPolicy.default()

    assert %Error{type: :deprecated_algorithm} =
             AlgorithmPolicy.enforce_signature_method(policy, @rsa_sha1)

    assert %Error{type: :deprecated_algorithm} =
             AlgorithmPolicy.enforce_digest_method(policy, @digest_sha1)
  end

  test "non-expired legacy sha1 override allows sha1 methods" do
    override = %{
      reason: "Legacy IdP migration window",
      expires_at: DateTime.add(DateTime.utc_now(), 3_600, :second)
    }

    policy = %{AlgorithmPolicy.default() | legacy_sha1: override}

    assert :ok = AlgorithmPolicy.enforce_signature_method(policy, @rsa_sha1)
    assert :ok = AlgorithmPolicy.enforce_digest_method(policy, @digest_sha1)
  end

  test "expired legacy sha1 override rejects with explicit expiry error" do
    override = %{
      reason: "Temporary compatibility expired",
      expires_at: DateTime.add(DateTime.utc_now(), -60, :second)
    }

    policy = %{AlgorithmPolicy.default() | legacy_sha1: override}

    assert %Error{type: :legacy_algorithm_override_expired} =
             AlgorithmPolicy.enforce_signature_method(policy, @rsa_sha1)

    assert %Error{type: :legacy_algorithm_override_expired} =
             AlgorithmPolicy.enforce_digest_method(policy, @digest_sha1)
  end
end
