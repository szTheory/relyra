defmodule LedgerLoop.Demo.TrustLifecycleTest do
  use LedgerLoop.DataCase, async: false

  import Ecto.Query

  alias Ecto.Changeset
  alias LedgerLoop.Demo.{Fixtures, Reset}
  alias LedgerLoop.Repo
  alias Relyra.ConnectionResolver.Ecto, as: ConnectionResolver
  alias Relyra.Ecto.{AuditEvent, Certificate, CertificateInventory, Connection, MetadataApply}
  alias Relyra.Metadata.Import

  @actor "northstar-trust-admin@example.com"
  @connection_record_id Fixtures.trust_scenario_connection_id()
  @connection_id "01H0B4Y1A2B3C4D5E6F7G8H9J2"
  @correlation_id "jour-05-northstar-rollover"

  setup do
    Reset.reset!()
    :ok
  end

  test "fresh metadata staging, activation, and recovery keep resolver trust and audit history aligned" do
    connection = Repo.get!(Connection, @connection_record_id)
    original_revision_id = connection.active_metadata_revision_id
    certificates = certificates_for(connection.id)
    active = Enum.find(certificates, &(&1.lifecycle_state == :active))
    staged = Enum.find(certificates, &(&1.lifecycle_state == :next))
    assert active && staged

    assert {:ok, before_resolver} =
             ConnectionResolver.resolve_connection(%{connection_id: @connection_id}, repo: Repo)

    assert before_resolver.idp_certificates == [active.pem]

    audit = %{
      actor: @actor,
      cause: "tenant_admin_metadata_import",
      correlation_id: @correlation_id
    }

    assert {:ok, revision} =
             MetadataApply.apply_revision(
               @connection_id,
               rollover_candidate(staged.pem),
               %{
                 source_kind: :xml_import,
                 trigger: :manual_import,
                 outcome: :applied,
                 actor: audit.actor,
                 cause: audit.cause,
                 correlation_id: audit.correlation_id,
                 trust_summary: %{status: "applied", certificate_count: 1}
               },
               repo: Repo,
               audit: audit
             )

    assert revision.outcome == :applied
    updated_connection = Repo.get!(Connection, connection.id)
    assert updated_connection.active_metadata_revision_id == revision.id
    assert updated_connection.last_known_good_metadata_revision_id == revision.id

    assert {:ok, staged_resolver} =
             ConnectionResolver.resolve_connection(%{connection_id: @connection_id}, repo: Repo)

    assert staged_resolver.idp_certificates == [active.pem]

    staged_events = lifecycle_events()

    assert Enum.map(staged_events, &{&1.domain, &1.action}) == [
             {:certificate, :staged},
             {:metadata, :applied}
           ]

    assert Enum.all?(staged_events, &(&1.actor == audit.actor and &1.cause == audit.cause))
    assert Enum.at(staged_events, 1).correlation_id == @correlation_id
    assert_redacted(staged_events)

    before_failed_transition = trust_snapshot(connection.id)
    before_failed_events = lifecycle_events()

    assert {:error, %Relyra.Error{details: %{reason: :conflict}}} =
             CertificateInventory.activate_signing_certificate(
               Repo,
               @connection_id,
               staged.fingerprint_sha256,
               audit: %{
                 actor: "stale-admin@example.com",
                 cause: "stale_promotion",
                 correlation_id: @correlation_id
               },
               after_fetch: fn ->
                 connection = Repo.get!(Connection, connection.id)

                 connection
                 |> Changeset.change(updated_at: DateTime.utc_now())
                 |> Changeset.optimistic_lock(:lock_version)
                 |> Repo.update!()
               end
             )

    assert trust_snapshot(connection.id) == before_failed_transition
    assert lifecycle_events() == before_failed_events

    assert {:ok, _promoted} =
             CertificateInventory.activate_signing_certificate(
               Repo,
               @connection_id,
               staged.fingerprint_sha256,
               audit: %{
                 actor: @actor,
                 cause: "tenant_admin_activate_rollover",
                 correlation_id: @correlation_id
               }
             )

    promoted = certificates_for(connection.id)
    assert Enum.count(promoted, &(&1.lifecycle_state == :active)) == 2

    assert {:ok, _retired} =
             CertificateInventory.retire_signing_certificate(
               Repo,
               @connection_id,
               active.fingerprint_sha256,
               audit: %{
                 actor: @actor,
                 cause: "tenant_admin_retire_previous",
                 correlation_id: @correlation_id
               }
             )

    assert {:ok, replacement_resolver} =
             ConnectionResolver.resolve_connection(%{connection_id: @connection_id}, repo: Repo)

    assert replacement_resolver.idp_certificates == [staged.pem]

    assert {:ok, [_restored, _retired]} =
             CertificateInventory.rollback_signing_certificate(
               Repo,
               @connection_id,
               active.fingerprint_sha256,
               staged.fingerprint_sha256,
               audit: %{
                 actor: @actor,
                 cause: "tenant_admin_recover_previous",
                 correlation_id: @correlation_id
               }
             )

    recovered_connection = Repo.get!(Connection, connection.id)
    assert recovered_connection.active_metadata_revision_id == revision.id
    assert recovered_connection.last_known_good_metadata_revision_id == revision.id
    assert recovered_connection.active_metadata_revision_id != original_revision_id

    recovered_certificates = certificates_for(connection.id)

    assert Enum.find(
             recovered_certificates,
             &(&1.fingerprint_sha256 == active.fingerprint_sha256)
           ).lifecycle_state == :active

    assert Enum.find(
             recovered_certificates,
             &(&1.fingerprint_sha256 == staged.fingerprint_sha256)
           ).lifecycle_state == :retired

    assert {:ok, recovered_resolver} =
             ConnectionResolver.resolve_connection(%{connection_id: @connection_id}, repo: Repo)

    assert recovered_resolver.idp_certificates == [active.pem]

    events = lifecycle_events()

    assert Enum.map(events, &{&1.domain, &1.action}) == [
             {:certificate, :staged},
             {:metadata, :applied},
             {:certificate, :activated},
             {:certificate, :retired},
             {:certificate, :replaced}
           ]

    assert Enum.map(events, & &1.cause) == [
             "tenant_admin_metadata_import",
             "tenant_admin_metadata_import",
             "tenant_admin_activate_rollover",
             "tenant_admin_retire_previous",
             "tenant_admin_recover_previous"
           ]

    assert Enum.all?(events, &(&1.actor == @actor))
    assert Enum.all?(events, &(&1.connection_record_id == connection.id))
    assert Enum.all?(Enum.drop(events, 1), &(&1.correlation_id == @correlation_id))
    assert Repo.get!(Connection, connection.id).organization_id == "northstar"
    assert_redacted(events)
  end

  defp rollover_candidate(pem) do
    certificate_body =
      pem
      |> String.replace("-----BEGIN CERTIFICATE-----", "")
      |> String.replace("-----END CERTIFICATE-----", "")
      |> String.replace(~r/\s+/, "")

    Import.build_candidate(%{
      entity_id: "https://idp.northstar.example.com",
      sso_services: [
        %{
          binding: "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect",
          location: "https://idp.northstar.example.com/sso"
        }
      ],
      certificates: [certificate_body]
    })
    |> Map.from_struct()
  end

  defp certificates_for(connection_id) do
    Repo.all(
      from(certificate in Certificate,
        where: certificate.connection_record_id == ^connection_id and certificate.role == :signing
      )
    )
  end

  defp trust_snapshot(connection_id) do
    connection = Repo.get!(Connection, connection_id)

    {connection.lock_version, connection.updated_at, connection.active_metadata_revision_id,
     connection.last_known_good_metadata_revision_id,
     certificates_for(connection_id)
     |> Enum.map(&{&1.fingerprint_sha256, &1.lifecycle_state})
     |> Enum.sort()}
  end

  defp lifecycle_events do
    Repo.all(
      from(event in AuditEvent,
        where:
          event.connection_record_id == ^@connection_record_id and
            event.actor == ^@actor and
            event.cause in [
              "tenant_admin_metadata_import",
              "tenant_admin_activate_rollover",
              "tenant_admin_retire_previous",
              "tenant_admin_recover_previous"
            ],
        order_by: [asc: event.inserted_at, asc: event.id]
      )
    )
  end

  defp assert_redacted(events) do
    serialized = inspect(events)
    refute serialized =~ "<EntityDescriptor"
    refute serialized =~ "BEGIN CERTIFICATE"
    refute serialized =~ "PRIVATE KEY"
  end
end
