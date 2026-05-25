defmodule Relyra.Ecto.CertificateSchemaTest do
  use ExUnit.Case, async: true

  alias Relyra.Ecto.Certificate

  test "certificate changeset requires fingerprint, pem, and source" do
    changeset = Certificate.changeset(%Certificate{}, %{})

    refute changeset.valid?

    errors = Ecto.Changeset.traverse_errors(changeset, fn {message, _opts} -> message end)

    assert "can't be blank" in errors.fingerprint_sha256
    assert "can't be blank" in errors.pem
    assert "can't be blank" in errors.source
  end

  test "certificate changeset defaults lifecycle fields for active signing certificates" do
    changeset =
      Certificate.changeset(%Certificate{}, %{
        fingerprint_sha256: "abc123",
        pem: "-----BEGIN CERTIFICATE-----\nMIIB\n-----END CERTIFICATE-----",
        source: "manual"
      })

    assert changeset.valid?
    certificate = Ecto.Changeset.apply_changes(changeset)
    assert certificate.role == :signing
    assert certificate.lifecycle_state == :active
    assert %DateTime{} = certificate.activated_at
  end

  # ---------------------------------------------------------------------------
  # T6a — ENC-04 / T-32-05: Certificate :party Ecto.Enum field
  # ---------------------------------------------------------------------------

  describe "party field (Ecto.Enum [:idp, :sp])" do
    @base_attrs %{
      fingerprint_sha256: "sha256abc",
      pem: "-----BEGIN CERTIFICATE-----\nMIIB\n-----END CERTIFICATE-----",
      source: "metadata"
    }

    test "changeset accepts :idp as a valid party value" do
      changeset = Certificate.changeset(%Certificate{}, Map.put(@base_attrs, :party, :idp))

      assert changeset.valid?, "expected changeset to be valid with party: :idp"
      assert Ecto.Changeset.get_field(changeset, :party) == :idp
    end

    test "changeset accepts :sp as a valid party value" do
      changeset = Certificate.changeset(%Certificate{}, Map.put(@base_attrs, :party, :sp))

      assert changeset.valid?, "expected changeset to be valid with party: :sp"
      assert Ecto.Changeset.get_field(changeset, :party) == :sp
    end

    test "changeset rejects an invalid party value with a changeset error" do
      changeset =
        Certificate.changeset(%Certificate{}, Map.put(@base_attrs, :party, :attacker_injected))

      refute changeset.valid?,
             "expected changeset to be invalid with party: :attacker_injected but it was valid"

      errors = Ecto.Changeset.traverse_errors(changeset, fn {message, _opts} -> message end)

      assert Map.has_key?(errors, :party),
             "expected :party error but errors were: #{inspect(errors)}"
    end

    test "changeset defaults party to :idp when not supplied" do
      changeset = Certificate.changeset(%Certificate{}, @base_attrs)

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :party) == :idp
    end
  end

  # ---------------------------------------------------------------------------
  # T6b — ENC-04 / T-32-05: Certificate :use Ecto.Enum field
  # ---------------------------------------------------------------------------

  describe "use field (Ecto.Enum [:signing, :encryption])" do
    @base_attrs %{
      fingerprint_sha256: "sha256def",
      pem: "-----BEGIN CERTIFICATE-----\nMIIC\n-----END CERTIFICATE-----",
      source: "metadata"
    }

    test "changeset accepts :signing as a valid use value" do
      changeset = Certificate.changeset(%Certificate{}, Map.put(@base_attrs, :use, :signing))

      assert changeset.valid?, "expected changeset to be valid with use: :signing"
      assert Ecto.Changeset.get_field(changeset, :use) == :signing
    end

    test "changeset accepts :encryption as a valid use value" do
      changeset = Certificate.changeset(%Certificate{}, Map.put(@base_attrs, :use, :encryption))

      assert changeset.valid?, "expected changeset to be valid with use: :encryption"
      assert Ecto.Changeset.get_field(changeset, :use) == :encryption
    end

    test "changeset rejects an invalid use value with a changeset error" do
      changeset =
        Certificate.changeset(%Certificate{}, Map.put(@base_attrs, :use, :malicious_value))

      refute changeset.valid?,
             "expected changeset to be invalid with use: :malicious_value but it was valid"

      errors = Ecto.Changeset.traverse_errors(changeset, fn {message, _opts} -> message end)

      assert Map.has_key?(errors, :use),
             "expected :use error but errors were: #{inspect(errors)}"
    end

    test "changeset defaults use to :signing when not supplied" do
      changeset = Certificate.changeset(%Certificate{}, @base_attrs)

      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :use) == :signing
    end
  end
end
