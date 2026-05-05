defmodule Relyra.Ecto.MigrationConstraintsTest do
  use Relyra.TestSupport.MigrationCase, async: false

  alias Relyra.Ecto.{
    AttributeMapping,
    AuditEvent,
    Certificate,
    Connection,
    GroupMapping,
    MappingRevision,
    MetadataRevision,
    MetadataSource
  }

  test "migrations create the canonical tables and unique public id constraint" do
    connection_id = "01JT6YXBK1Q3DNEJQY23WJ6TB2"

    assert {:ok, _record} =
             %Connection{}
             |> Connection.draft_changeset(%{connection_id: connection_id})
             |> Repo.insert()

    assert {:error, changeset} =
             %Connection{}
             |> Connection.draft_changeset(%{connection_id: connection_id})
             |> Repo.insert()

    assert %{connection_id: ["has already been taken"]} =
             Ecto.Changeset.traverse_errors(changeset, fn {message, _opts} -> message end)
  end

  test "certificate rows enforce foreign keys and cascade on parent delete" do
    {:ok, connection} =
      %Connection{}
      |> Connection.draft_changeset(%{
        connection_id: "01JT6YZ6M5WGYAZE4D4G9QYAK6",
        certificates: [
          %{
            fingerprint_sha256: "abc123",
            pem: "-----BEGIN CERTIFICATE-----\nMIIB\n-----END CERTIFICATE-----",
            source: "manual"
          }
        ]
      })
      |> Repo.insert()

    connection = Repo.preload(connection, :certificates)
    assert [%Certificate{}] = connection.certificates

    assert Enum.all?(
             connection.certificates,
             &(&1.role == :signing and &1.lifecycle_state == :active)
           )

    assert {:error, changeset} =
             %Certificate{}
             |> Certificate.changeset(%{
               connection_record_id: Ecto.UUID.generate(),
               fingerprint_sha256: "def456",
               pem: "-----BEGIN CERTIFICATE-----\nMIIC\n-----END CERTIFICATE-----",
               source: "manual"
             })
             |> Repo.insert()

    assert %{connection_record_id: ["does not exist"]} =
             Ecto.Changeset.traverse_errors(changeset, fn {message, _opts} -> message end)

    assert {:ok, _deleted} = Repo.delete(connection)
    assert Repo.aggregate(Certificate, :count, :id) == 0
  end

  test "metadata tables enforce single registered source and revision pointer constraints" do
    {:ok, connection} =
      %Connection{}
      |> Connection.draft_changeset(%{connection_id: "01JT70A2NXJH1M2Y9GQY4MH8B1"})
      |> Repo.insert()

    assert {:ok, source} =
             %MetadataSource{}
             |> MetadataSource.changeset(%{
               connection_record_id: connection.id,
               url: "https://idp.example.com/metadata",
               kind: :remote_url,
               registered_by: "operator@example.com",
               registered_reason: "initial onboarding",
               last_outcome: :registered
             })
             |> Repo.insert()

    assert {:error, duplicate_source_changeset} =
             %MetadataSource{}
             |> MetadataSource.changeset(%{
               connection_record_id: connection.id,
               url: "https://idp-backup.example.com/metadata",
               kind: :remote_url,
               registered_by: "operator@example.com",
               registered_reason: "duplicate"
             })
             |> Repo.insert()

    assert %{connection_record_id: ["has already been taken"]} =
             Ecto.Changeset.traverse_errors(duplicate_source_changeset, fn {message, _opts} ->
               message
             end)

    assert {:ok, revision} =
             %MetadataRevision{}
             |> MetadataRevision.changeset(%{
               connection_record_id: connection.id,
               metadata_source_id: source.id,
               source_kind: :remote_url,
               trigger: :manual_import,
               outcome: :applied,
               trust_summary: %{certificate_count: 1}
             })
             |> Repo.insert()

    assert {:ok, _updated_connection} =
             connection
             |> Ecto.Changeset.change(%{
               active_metadata_revision_id: revision.id,
               last_known_good_metadata_revision_id: revision.id
             })
             |> Repo.update()

    persisted = Repo.get!(Connection, connection.id)
    assert persisted.active_metadata_revision_id == revision.id
    assert persisted.last_known_good_metadata_revision_id == revision.id
  end

  test "mapping and audit migrations create canonical tables with connection ownership and append-only posture" do
    tables =
      Repo.query!(
        """
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = 'public'
          AND tablename IN (
            'relyra_attribute_mappings',
            'relyra_group_mappings',
            'relyra_mapping_revisions',
            'relyra_audit_events'
          )
        ORDER BY tablename
        """,
        []
      )
      |> Map.fetch!(:rows)
      |> Enum.map(&List.first/1)

    assert tables == [
             "relyra_attribute_mappings",
             "relyra_audit_events",
             "relyra_group_mappings",
             "relyra_mapping_revisions"
           ]

    append_only_columns =
      Repo.query!(
        """
        SELECT table_name, is_nullable
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name IN ('relyra_mapping_revisions', 'relyra_audit_events')
          AND column_name = 'updated_at'
        ORDER BY table_name
        """,
        []
      ).rows

    assert append_only_columns == []

    position_defaults =
      Repo.query!(
        """
        SELECT table_name, column_default
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name IN ('relyra_attribute_mappings', 'relyra_group_mappings')
          AND column_name = 'position'
        ORDER BY table_name
        """,
        []
      ).rows

    assert [
             ["relyra_attribute_mappings", default_one],
             ["relyra_group_mappings", default_two]
           ] = position_defaults

    assert default_one =~ "0"
    assert default_two =~ "0"
  end

  test "attribute mappings enforce foreign keys and one target per connection" do
    {:ok, connection} =
      %Connection{}
      |> Connection.draft_changeset(%{})
      |> Repo.insert()

    assert {:ok, mapping} =
             %AttributeMapping{}
             |> AttributeMapping.changeset(%{
               connection_record_id: connection.id,
               source_attribute: "mail",
               target_field: :email,
               multivalue_strategy: :first
             })
             |> Repo.insert()

    assert mapping.connection_record_id == connection.id

    assert_raise Ecto.ConstraintError, fn ->
      %AttributeMapping{}
      |> AttributeMapping.changeset(%{
        connection_record_id: connection.id,
        source_attribute: "upn",
        target_field: :email,
        multivalue_strategy: :all
      })
      |> Repo.insert()
    end

    assert {:error, changeset} =
             %AttributeMapping{}
             |> AttributeMapping.changeset(%{
               connection_record_id: Ecto.UUID.generate(),
               source_attribute: "mail",
               target_field: :display_name,
               multivalue_strategy: :first
             })
             |> Repo.insert()

    assert %{connection_record_id: ["does not exist"]} =
             Ecto.Changeset.traverse_errors(changeset, fn {message, _opts} -> message end)
  end

  test "group mappings enforce foreign keys and exact-match uniqueness per connection" do
    {:ok, connection} =
      %Connection{}
      |> Connection.draft_changeset(%{})
      |> Repo.insert()

    assert {:ok, mapping} =
             %GroupMapping{}
             |> GroupMapping.changeset(%{
               connection_record_id: connection.id,
               source_attribute: "groups",
               source_value: "admins",
               role_target: :role,
               role_value: "admin"
             })
             |> Repo.insert()

    assert mapping.connection_record_id == connection.id

    assert_raise Ecto.ConstraintError, fn ->
      %GroupMapping{}
      |> GroupMapping.changeset(%{
        connection_record_id: connection.id,
        source_attribute: "groups",
        source_value: "admins",
        role_target: :role,
        role_value: "admin"
      })
      |> Repo.insert()
    end

    assert {:error, changeset} =
             %GroupMapping{}
             |> GroupMapping.changeset(%{
               connection_record_id: Ecto.UUID.generate(),
               source_attribute: "groups",
               source_value: "operators",
               role_target: :role,
               role_value: "operator"
             })
             |> Repo.insert()

    assert %{connection_record_id: ["does not exist"]} =
             Ecto.Changeset.traverse_errors(changeset, fn {message, _opts} -> message end)
  end

  test "mapping and audit ledgers require a real connection record id" do
    invalid_connection_id = Ecto.UUID.generate()

    assert {:error, mapping_revision_changeset} =
             %MappingRevision{}
             |> MappingRevision.changeset(%{
               connection_record_id: invalid_connection_id,
               actor: "ops@example.com",
               action: :created,
               cause: "initial_seed",
               before_snapshot: %{},
               after_snapshot: %{attribute_mappings: [%{target_field: :email}]},
               diff_summary: %{changed_fields: ["attribute_mappings"]}
             })
             |> Repo.insert()

    assert %{connection_record_id: ["does not exist"]} =
             Ecto.Changeset.traverse_errors(mapping_revision_changeset, fn {message, _opts} ->
               message
             end)

    assert {:error, audit_event_changeset} =
             %AuditEvent{}
             |> AuditEvent.changeset(%{
               connection_record_id: invalid_connection_id,
               domain: :mapping,
               action: :replaced,
               actor: "ops@example.com",
               cause: "manual_sync",
               before_summary: %{},
               after_summary: %{mapping_count: 2},
               diff_summary: %{changed_fields: ["group_mappings"]}
             })
             |> Repo.insert()

    assert %{connection_record_id: ["does not exist"]} =
             Ecto.Changeset.traverse_errors(audit_event_changeset, fn {message, _opts} ->
               message
             end)
  end
end
