defmodule Relyra.Ecto.ConnectionSchemaTest do
  use ExUnit.Case, async: true

  alias Relyra.Ecto.Connection

  test "publish_changeset rejects incomplete runtime configuration" do
    changeset = Connection.publish_changeset(%Connection{status: :draft, certificates: []}, %{})

    refute changeset.valid?
    assert "is required before enable" in errors_on(changeset).sp_entity_id

    assert "must include at least one active signing certificate" in errors_on(changeset).certificates
  end

  test "runtime_ready requires enabled status and a certificate inventory" do
    connection = %Connection{
      status: :enabled,
      connection_id: "01JT6YXBK1Q3DNEJQY23WJ6TB2",
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs",
      idp_entity_id: "https://idp.example.com/metadata",
      idp_sso_url: "https://idp.example.com/sso",
      certificates: []
    }

    assert {:error, %Relyra.Error{type: :connection_not_runtime_ready}} =
             Connection.runtime_ready(connection)
  end

  test "publish_changeset rejects inventories with only staged certificates" do
    changeset =
      Connection.publish_changeset(
        %Connection{
          status: :draft,
          certificates: [
            %Relyra.Ecto.Certificate{
              fingerprint_sha256: "next-only",
              pem: "-----BEGIN CERTIFICATE-----\nNEXT\n-----END CERTIFICATE-----",
              source: "metadata",
              lifecycle_state: :next,
              role: :signing
            }
          ]
        },
        %{}
      )

    refute changeset.valid?

    assert "must include at least one active signing certificate" in errors_on(changeset).certificates
  end

  test "update_changeset rejects certificate management through generic attrs" do
    changeset =
      Connection.update_changeset(
        %Connection{},
        %{
          display_name: "Renamed",
          certificates: [%{fingerprint_sha256: "replace-me"}]
        }
      )

    refute changeset.valid?

    assert "are managed through metadata apply or Relyra.Ecto.CertificateInventory" in
             errors_on(changeset).certificates
  end

  test "publish_changeset rejects certificate payloads before enable" do
    changeset =
      Connection.publish_changeset(
        %Connection{
          status: :draft,
          certificates: [
            %Relyra.Ecto.Certificate{
              fingerprint_sha256: "active-cert",
              pem: "-----BEGIN CERTIFICATE-----\nACTIVE\n-----END CERTIFICATE-----",
              source: "manual",
              lifecycle_state: :active,
              role: :signing
            }
          ]
        },
        %{
          sp_entity_id: "https://sp.example.com/metadata",
          acs_url: "https://sp.example.com/saml/acs",
          idp_entity_id: "https://idp.example.com/metadata",
          idp_sso_url: "https://idp.example.com/sso",
          certificates: []
        }
      )

    refute changeset.valid?

    assert "are managed through metadata apply or Relyra.Ecto.CertificateInventory" in
             errors_on(changeset).certificates
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, _opts} -> message end)
  end
end
