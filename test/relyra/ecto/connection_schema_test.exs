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

    assert "are managed through metadata apply or Relyra.Ecto.CertificateInventory" in errors_on(
             changeset
           ).certificates
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

    assert "are managed through metadata apply or Relyra.Ecto.CertificateInventory" in errors_on(
             changeset
           ).certificates
  end

  # ---------------------------------------------------------------------------
  # T6c — AUTHN-02 / T-32-06: Connection :sign_authn_requests field
  # ---------------------------------------------------------------------------

  describe "sign_authn_requests field (boolean, default false)" do
    test "draft_changeset casts sign_authn_requests true from attrs" do
      changeset =
        Connection.draft_changeset(%Connection{}, %{sign_authn_requests: true})

      assert Ecto.Changeset.get_change(changeset, :sign_authn_requests) == true,
             "expected draft_changeset to cast sign_authn_requests: true but field was not changed"
    end

    test "draft_changeset casts sign_authn_requests false from attrs" do
      changeset =
        Connection.draft_changeset(%Connection{}, %{sign_authn_requests: false})

      # get_change returns nil when no change (field value matches struct default).
      # Use get_field which reads through to the struct default.
      assert Ecto.Changeset.get_field(changeset, :sign_authn_requests) == false,
             "expected draft_changeset to reflect sign_authn_requests: false"
    end

    test "draft_changeset defaults sign_authn_requests to false when not provided" do
      changeset = Connection.draft_changeset(%Connection{}, %{})

      assert Ecto.Changeset.get_field(changeset, :sign_authn_requests) == false,
             "expected sign_authn_requests to default to false when absent from attrs"
    end

    test "update_changeset casts sign_authn_requests true from attrs" do
      changeset =
        Connection.update_changeset(%Connection{}, %{sign_authn_requests: true})

      assert Ecto.Changeset.get_change(changeset, :sign_authn_requests) == true,
             "expected update_changeset to cast sign_authn_requests: true but field was not changed"
    end

    test "update_changeset casts sign_authn_requests false from attrs" do
      # Start from a struct with sign_authn_requests: true to make false a real change.
      connection = %Connection{sign_authn_requests: true}
      changeset = Connection.update_changeset(connection, %{sign_authn_requests: false})

      assert Ecto.Changeset.get_change(changeset, :sign_authn_requests) == false,
             "expected update_changeset to cast sign_authn_requests: false but field was not changed"
    end
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, _opts} -> message end)
  end
end
