defmodule LedgerLoop.Twin.CertificateHistoryTest do
  use LedgerLoop.DataCase, async: false

  alias LedgerLoop.Demo.{Fixtures, Reset}
  alias LedgerLoop.Repo
  alias Relyra.Ecto.{AuditEvent, Certificate, Connection, MetadataRevision, MetadataSource}

  setup do
    Reset.reset!()
    :ok
  end

  test "trust history is fixed-time, connection-owned, and separates readiness, lifecycle, validity, and health" do
    connection = Repo.get!(Connection, Fixtures.trust_scenario_connection_id())
    assert connection.status == :enabled

    source = Repo.get_by!(MetadataSource, connection_record_id: connection.id)

    revisions =
      Repo.all(
        from(revision in MetadataRevision,
          where: revision.connection_record_id == ^connection.id,
          order_by: [asc: revision.inserted_at, asc: revision.id]
        )
      )

    assert Enum.map(revisions, & &1.outcome) == [:registered, :applied, :fetch_failed, :applied]
    assert Enum.all?(revisions, &(&1.metadata_source_id == source.id))

    assert Enum.map(revisions, & &1.inserted_at) == [
             ~U[2026-06-12 12:05:00.000000Z],
             ~U[2026-06-12 12:10:00.000000Z],
             ~U[2026-06-12 12:20:00.000000Z],
             ~U[2026-06-12 12:30:00.000000Z]
           ]

    assert source.last_outcome == :applied
    assert source.last_success_at == ~U[2026-06-12 12:30:00.000000Z]
    assert source.last_failure_error_code == nil
    assert source.consecutive_failure_count == 0
    assert source.first_failure_at == nil

    active_revision = Repo.get!(MetadataRevision, connection.active_metadata_revision_id)

    last_good_revision =
      Repo.get!(MetadataRevision, connection.last_known_good_metadata_revision_id)

    assert active_revision.outcome == :applied
    assert last_good_revision.outcome == :applied
    assert active_revision.id == List.last(revisions).id

    certificates =
      Repo.all(from(cert in Certificate, where: cert.connection_record_id == ^connection.id))

    assert Enum.map(certificates, & &1.lifecycle_state) |> Enum.sort() == [
             :active,
             :next,
             :retired
           ]

    active_cert = Enum.find(certificates, &(&1.lifecycle_state == :active))
    as_of = Fixtures.trust_scenario_as_of()
    assert DateTime.compare(active_cert.not_after, as_of) == :gt
    assert DateTime.diff(active_cert.not_after, as_of, :day) < 30

    audits =
      Repo.all(
        from(event in AuditEvent,
          where: event.connection_record_id == ^connection.id and event.domain == :metadata,
          order_by: [asc: event.inserted_at]
        )
      )

    assert Enum.map(audits, & &1.diff_summary["event"]) == ["degraded", "recovered"]

    assert Enum.map(audits, & &1.inserted_at) == [
             ~U[2026-06-12 12:20:00.000000Z],
             ~U[2026-06-12 12:30:00.000000Z]
           ]

    assert Enum.all?(audits, &(&1.connection_record_id == connection.id))

    for row <- revisions ++ audits do
      encoded = inspect(row)
      refute encoded =~ "<EntityDescriptor"
      refute encoded =~ "BEGIN CERTIFICATE"
      refute encoded =~ "PRIVATE KEY"
    end
  end
end
