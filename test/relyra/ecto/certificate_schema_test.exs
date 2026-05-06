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
end
