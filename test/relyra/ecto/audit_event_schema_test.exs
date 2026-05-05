defmodule Relyra.Ecto.AuditEventSchemaTest do
  use ExUnit.Case, async: true

  alias Relyra.Ecto.AuditEvent

  @valid_attrs %{
    connection_record_id: Ecto.UUID.generate(),
    domain: :mapping,
    action: :replaced,
    actor: "ops@example.com",
    cause: "manual_sync",
    before_summary: %{},
    after_summary: %{mapping_count: 2},
    diff_summary: %{changed_fields: ["group_mappings"]}
  }

  test "audit event changeset rejects missing required trust history fields" do
    changeset = AuditEvent.changeset(%AuditEvent{}, %{})

    refute changeset.valid?

    errors = Ecto.Changeset.traverse_errors(changeset, fn {message, _opts} -> message end)

    assert "can't be blank" in errors.connection_record_id
    assert "can't be blank" in errors.domain
    assert "can't be blank" in errors.action
    assert "can't be blank" in errors.actor
    assert "can't be blank" in errors.cause
    assert "can't be blank" in errors.after_summary
    assert "can't be blank" in errors.diff_summary
  end

  test "audit event stays append-only and bounded to normalized maps" do
    assert :updated_at not in AuditEvent.__schema__(:fields)
    assert :inserted_at in AuditEvent.__schema__(:fields)

    valid_changeset = AuditEvent.changeset(%AuditEvent{}, @valid_attrs)

    assert valid_changeset.valid?

    invalid_changeset =
      AuditEvent.changeset(%AuditEvent{}, %{
        connection_record_id: Ecto.UUID.generate(),
        domain: :logs,
        action: :streamed,
        actor: "ops@example.com",
        cause: "manual_sync",
        before_summary: %{},
        after_summary: %{payload: String.duplicate("x", 513)},
        diff_summary: %{changed_fields: ["raw_xml"]}
      })

    refute invalid_changeset.valid?

    errors = Ecto.Changeset.traverse_errors(invalid_changeset, fn {message, _opts} -> message end)

    assert "is invalid" in errors.domain
    assert "is invalid" in errors.action
    assert "contains oversized values" in errors.after_summary
  end

  test "audit event allows an empty before summary for create-style trust changes" do
    changeset =
      AuditEvent.changeset(%AuditEvent{}, %{
        @valid_attrs
        | domain: :connection,
          action: :created,
          cause: "bootstrap",
          after_summary: %{status: :draft},
          diff_summary: %{changed_fields: ["status"]}
      })

    assert changeset.valid?
  end

  test "audit event supports the cross-domain trust ledger surface" do
    assert Enum.all?([:connection, :metadata, :certificate, :mapping], fn domain ->
             AuditEvent.changeset(%AuditEvent{}, Map.put(@valid_attrs, :domain, domain)).valid?
           end)
  end

  test "audit event schema avoids raw XML, PEM, or telemetry-only storage fields" do
    fields = AuditEvent.__schema__(:fields)

    assert :before_summary in fields
    assert :after_summary in fields
    assert :diff_summary in fields
    refute :raw_xml in fields
    refute :pem in fields
    refute :telemetry_payload in fields
  end
end
