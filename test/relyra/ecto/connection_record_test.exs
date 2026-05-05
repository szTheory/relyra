defmodule Relyra.Ecto.ConnectionRecordTest do
  use Relyra.TestSupport.MigrationCase, async: false

  alias Relyra.Ecto.{AuditEvent, Certificate, Connections}

  @repo Relyra.TestSupport.EctoTestRepo

  test "create, update, enable, and disable records through the persistence API" do
    audit = %{actor: "ops@example.com", cause: "manual_change", correlation_id: "conn-123"}

    assert {:ok, created} =
             Connections.create(
               %{
                 display_name: "Draft connection",
                 organization_id: "org_123"
               },
               repo: @repo,
               audit: audit
             )

    assert created.status == :draft
    assert is_binary(created.connection_id)

    assert {:ok, updated} =
             Connections.update(
               created.connection_id,
               %{
                 sp_entity_id: "https://sp.example.com/metadata",
                 acs_url: "https://sp.example.com/saml/acs",
                 idp_entity_id: "https://idp.example.com/metadata",
                 idp_sso_url: "https://idp.example.com/sso",
                 runtime_policy: %{
                   allow_idp_initiated?: false,
                   require_signed_assertions?: true,
                   require_signed_response?: true
                 }
               },
               repo: @repo,
               audit: audit
             )

    assert updated.sp_entity_id == "https://sp.example.com/metadata"

    %Certificate{}
    |> Certificate.changeset(%{
      connection_record_id: updated.id,
      fingerprint_sha256: "abc123",
      pem: "-----BEGIN CERTIFICATE-----\nMIIB\n-----END CERTIFICATE-----",
      source: "manual"
    })
    |> @repo.insert!()

    assert {:ok, enabled} = Connections.enable(created.connection_id, repo: @repo, audit: audit)
    assert enabled.status == :enabled
    assert length(enabled.certificates) == 1

    assert {:ok, disabled} = Connections.disable(created.connection_id, repo: @repo, audit: audit)
    assert disabled.status == :disabled

    events =
      AuditEvent
      |> @repo.all()
      |> Enum.sort_by(&DateTime.to_unix(&1.inserted_at, :microsecond))

    assert Enum.map(events, & &1.action) == [:created, :updated, :enabled, :disabled]
    assert Enum.map(events, & &1.domain) == [:connection, :connection, :connection, :connection]
    assert Enum.all?(events, &(&1.actor == "ops@example.com"))
    assert List.first(events).after_summary["status"] == "draft"
    assert List.last(events).after_summary["status"] == "disabled"
  end

  test "invalid audited writes roll back the connection mutation without orphan audit rows" do
    assert {:error, %Relyra.Error{type: :invalid_connection_record}} =
             Connections.create(
               %{
                 display_name: "Draft connection",
                 organization_id: "org_rollback"
               },
               repo: @repo,
               audit: %{cause: "missing_actor"}
             )

    assert @repo.aggregate(AuditEvent, :count) == 0
    assert @repo.aggregate(Relyra.Ecto.Connection, :count) == 0
  end
end
