defmodule Relyra.Ecto.AuditHardeningTest do
  use Relyra.TestSupport.MigrationCase, async: false

  alias Relyra.Ecto.{AuditEvent, AuditWriter, Connection}

  @repo Relyra.TestSupport.EctoTestRepo

  test "append_event redacts sensitive payloads and stores bounded summaries" do
    connection = insert_connection!("01JT9AUDITHARDENING000001")

    assert {:ok, event} =
             AuditWriter.append_event(@repo, %{
               connection_record_id: connection.id,
               domain: :connection,
               action: :updated,
               actor: "ops@example.com",
               cause: "rotation",
               correlation_id: "corr-123",
               subject_ref: "connection:rotation",
               before_view: %{status: :draft, xml: "<xml>secret</xml>"},
               after_view: %{
                 status: :enabled,
                 certificate_pem:
                   "-----BEGIN CERTIFICATE-----\nSECRET\n-----END CERTIFICATE-----",
                 oversized: String.duplicate("x", 900)
               },
               diff_summary: %{changed_fields: [:status, :pem]},
               metadata: %{pem: "-----BEGIN CERTIFICATE-----\nMETA\n-----END CERTIFICATE-----"}
             })

    assert event.actor == "ops@example.com"
    assert event.cause == "rotation"
    assert event.before_summary.xml == "[REDACTED]"
    assert event.after_summary.certificate_pem == "[REDACTED]"
    assert event.after_summary.oversized == "[REDACTED]"
    assert event.diff_summary.context.subject_ref == "connection:rotation"
    assert event.diff_summary.context.metadata.pem == "[REDACTED]"
  end

  test "append_event requires explicit attribution and ignores ambient process state" do
    connection = insert_connection!("01JT9AUDITHARDENING000002")
    Process.put(:audit_actor, "ambient@example.com")
    Process.put(:audit_cause, "ambient")

    assert {:error, %Relyra.Error{details: details}} =
             AuditWriter.append_event(@repo, %{
               connection_record_id: connection.id,
               domain: :connection,
               action: :created,
               before_view: %{},
               after_view: %{status: :draft},
               diff_summary: %{changed_fields: [:status]}
             })

    assert :actor in details.missing
    assert :cause in details.missing
    assert @repo.aggregate(AuditEvent, :count) == 0
  after
    Process.delete(:audit_actor)
    Process.delete(:audit_cause)
  end

  defp insert_connection!(connection_id) do
    now = DateTime.utc_now()

    %Connection{
      id: Ecto.UUID.generate(),
      connection_id: connection_id,
      display_name: "Audit hardening",
      organization_id: "org_audit",
      status: :draft,
      inserted_at: now,
      updated_at: now
    }
    |> @repo.insert!()
  end
end
