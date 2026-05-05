defmodule Relyra.Ecto.MappingRevisionSchemaTest do
  use ExUnit.Case, async: true

  alias Relyra.Ecto.MappingRevision

  @valid_attrs %{
    connection_record_id: Ecto.UUID.generate(),
    actor: "ops@example.com",
    action: :replaced,
    cause: "manual_sync",
    before_snapshot: %{},
    after_snapshot: %{attribute_mappings: [%{target_field: :email}]},
    diff_summary: %{changed_fields: ["attribute_mappings"]}
  }

  test "mapping revision changeset rejects missing required provenance fields" do
    changeset = MappingRevision.changeset(%MappingRevision{}, %{})

    refute changeset.valid?

    errors = Ecto.Changeset.traverse_errors(changeset, fn {message, _opts} -> message end)

    assert "can't be blank" in errors.connection_record_id
    assert "can't be blank" in errors.actor
    assert "can't be blank" in errors.action
    assert "can't be blank" in errors.cause
    assert "can't be blank" in errors.after_snapshot
    assert "can't be blank" in errors.diff_summary
  end

  test "mapping revision stays append-only and rejects oversized payload maps" do
    assert :updated_at not in MappingRevision.__schema__(:fields)
    assert :inserted_at in MappingRevision.__schema__(:fields)

    oversized_changeset =
      MappingRevision.changeset(%MappingRevision{}, %{
        connection_record_id: Ecto.UUID.generate(),
        actor: "ops@example.com",
        action: :replaced,
        cause: "manual_sync",
        before_snapshot: %{},
        after_snapshot: %{config: String.duplicate("x", 513)},
        diff_summary: %{changed_fields: ["attribute_mappings"]}
      })

    refute oversized_changeset.valid?

    errors =
      Ecto.Changeset.traverse_errors(oversized_changeset, fn {message, _opts} -> message end)

    assert "contains oversized values" in errors.after_snapshot
  end

  test "mapping revision allows an empty before snapshot for first-write events" do
    changeset = MappingRevision.changeset(%MappingRevision{}, Map.put(@valid_attrs, :action, :created))

    assert changeset.valid?
  end

  test "mapping revision restricts actions to the bounded ledger vocabulary" do
    valid_actions = [:created, :replaced, :deleted]

    assert Enum.all?(valid_actions, fn action ->
             MappingRevision.changeset(%MappingRevision{}, Map.put(@valid_attrs, :action, action)).valid?
           end)

    invalid_changeset =
      MappingRevision.changeset(%MappingRevision{}, Map.put(@valid_attrs, :action, :streamed))

    refute invalid_changeset.valid?

    errors = Ecto.Changeset.traverse_errors(invalid_changeset, fn {message, _opts} -> message end)

    assert "is invalid" in errors.action
  end

  test "mapping revision schema stays bounded to normalized maps rather than raw payload fields" do
    fields = MappingRevision.__schema__(:fields)

    assert :before_snapshot in fields
    assert :after_snapshot in fields
    assert :diff_summary in fields
    refute :raw_xml in fields
    refute :pem in fields
    refute :telemetry_payload in fields
  end
end
