defmodule Relyra.Ecto.CertificateInventoryTransitionTest do
  use Relyra.TestSupport.MigrationCase, async: false

  alias Relyra.ConnectionResolver.Ecto, as: EctoResolver
  alias Relyra.Ecto.{AuditEvent, Certificate, CertificateInventory, Connection}

  @repo Relyra.TestSupport.EctoTestRepo

  test "invalid lifecycle transitions return typed invalid_lifecycle_transition reasons" do
    connection = insert_enabled_connection!("01JT91G7NBQPZ29RX4X2N5RM11")

    assert {:error, %Relyra.Error{details: activate_details}} =
             CertificateInventory.activate_signing_certificate(
               @repo,
               connection.connection_id,
               "active-cert"
             )

    assert activate_details.reason == :invalid_lifecycle_transition
    assert activate_details.from == :active
    assert activate_details.to == :active

    assert {:error, %Relyra.Error{details: retire_details}} =
             CertificateInventory.retire_signing_certificate(
               @repo,
               connection.connection_id,
               "next-cert"
             )

    assert retire_details.reason == :invalid_lifecycle_transition
    assert retire_details.from == :next
    assert retire_details.to == :retired
  end

  test "rollback restores the retired predecessor and retires the replacement" do
    connection = insert_enabled_connection!("01JT91G7NBQPZ29RX4X2N5RM12")

    assert {:ok, _} =
             CertificateInventory.activate_signing_certificate(
               @repo,
               connection.connection_id,
               "next-cert",
               audit: %{actor: "ops@example.com", cause: "promote_next"}
             )

    assert {:ok, _} =
             CertificateInventory.retire_signing_certificate(
               @repo,
               connection.connection_id,
               "active-cert",
               audit: %{actor: "ops@example.com", cause: "retire_previous"}
             )

    assert {:ok, [_restored, _retired]} =
             CertificateInventory.rollback_signing_certificate(
               @repo,
               connection.connection_id,
               "active-cert",
               "next-cert",
               audit: %{actor: "ops@example.com", cause: "rollback_bad_promotion"}
             )

    assert {:ok, resolved} =
             EctoResolver.resolve_connection(%{connection_id: connection.connection_id},
               repo: @repo
             )

    assert resolved.idp_certificates == [
             "-----BEGIN CERTIFICATE-----\nACTIVE\n-----END CERTIFICATE-----"
           ]

    events =
      AuditEvent
      |> @repo.all()
      |> Enum.sort_by(&DateTime.to_unix(&1.inserted_at, :microsecond))

    assert Enum.map(events, & &1.action) == [:activated, :retired, :replaced]
    assert List.last(events).diff_summary["restore_fingerprint"] == "active-cert"
    assert List.last(events).diff_summary["retire_fingerprint"] == "next-cert"
  end

  test "lock conflicts fail closed without orphan audit rows" do
    connection = insert_enabled_connection!("01JT91G7NBQPZ29RX4X2N5RM13")

    assert {:error, %Relyra.Error{details: details}} =
             CertificateInventory.activate_signing_certificate(
               @repo,
               connection.connection_id,
               "next-cert",
               audit: %{actor: "ops@example.com", cause: "promote_next"},
               after_fetch: fn ->
                 connection
                 |> Ecto.Changeset.change(updated_at: DateTime.utc_now())
                 |> Ecto.Changeset.optimistic_lock(:lock_version)
                 |> @repo.update!()
               end
             )

    assert details.reason == :conflict
    assert @repo.aggregate(AuditEvent, :count) == 0

    persisted =
      @repo.get_by!(Connection, connection_id: connection.connection_id)
      |> @repo.preload(:certificates)

    assert Enum.any?(
             persisted.certificates,
             &(&1.fingerprint_sha256 == "active-cert" and &1.lifecycle_state == :active)
           )

    assert Enum.any?(
             persisted.certificates,
             &(&1.fingerprint_sha256 == "next-cert" and &1.lifecycle_state == :next)
           )
  end

  defp insert_enabled_connection!(connection_id) do
    now = DateTime.utc_now()

    connection =
      %Connection{
        id: Ecto.UUID.generate(),
        connection_id: connection_id,
        display_name: "Transition test",
        organization_id: "org_transition",
        status: :enabled,
        sp_entity_id: "https://sp.example.com/metadata",
        acs_url: "https://sp.example.com/saml/acs",
        idp_entity_id: "https://idp.example.com/metadata",
        idp_sso_url: "https://idp.example.com/sso",
        inserted_at: now,
        updated_at: now
      }
      |> @repo.insert!()

    insert_certificate!(connection.id, %{
      fingerprint_sha256: "active-cert",
      pem: "-----BEGIN CERTIFICATE-----\nACTIVE\n-----END CERTIFICATE-----",
      lifecycle_state: :active,
      activated_at: now
    })

    insert_certificate!(connection.id, %{
      fingerprint_sha256: "next-cert",
      pem: "-----BEGIN CERTIFICATE-----\nNEXT\n-----END CERTIFICATE-----",
      lifecycle_state: :next,
      staged_at: now
    })

    @repo.get!(Connection, connection.id)
  end

  defp insert_certificate!(connection_id, attrs) do
    %Certificate{
      id: Ecto.UUID.generate(),
      connection_record_id: connection_id,
      source: "manual",
      role: :signing,
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    }
    |> Certificate.changeset(attrs)
    |> @repo.insert!()
  end
end
