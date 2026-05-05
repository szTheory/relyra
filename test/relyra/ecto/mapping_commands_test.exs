defmodule Relyra.Ecto.MappingCommandsTest do
  use Relyra.TestSupport.MigrationCase, async: false

  import Ecto.Query

  alias Relyra.Ecto.{AuditEvent, Connection, MappingCommands, MappingRevision}

  @repo Relyra.TestSupport.EctoTestRepo
  @attribute_table "relyra_attribute_mappings"
  @group_table "relyra_group_mappings"

  test "replace_attribute_mappings writes live rows plus revision and audit history" do
    connection = insert_connection!("01JV2B4ENQDJ6D44AH0R0R5XA1")

    assert {:ok, result} =
             MappingCommands.replace_attribute_mappings(
               connection.connection_id,
               [
                 %{
                   source_attribute: "preferred_email",
                   target_field: :email,
                   multivalue_strategy: :first
                 },
                 %{
                   source_attribute: "display_names",
                   target_field: :display_name,
                   multivalue_strategy: :all
                 }
               ],
               repo: @repo,
               audit: %{actor: "ops@example.com", cause: "manual_mapping_update"}
             )

    assert result.mapping_type == :attribute
    assert result.action == :created

    assert attribute_rows(connection.id) == [
             %{
               position: 0,
               source_attribute: "preferred_email",
               target_field: "email",
               multivalue_strategy: "first"
             },
             %{
               position: 1,
               source_attribute: "display_names",
               target_field: "display_name",
               multivalue_strategy: "all"
             }
           ]

    revision = @repo.get!(MappingRevision, result.revision_id)
    assert revision.action == :created

    assert revision.before_snapshot == %{
             "attribute_rules" => [],
             "group_rules" => []
           }

    assert revision.after_snapshot == %{
             "attribute_rules" => [
               %{
                 "source_attribute" => "preferred_email",
                 "target_field" => "email",
                 "multivalue_strategy" => "first"
               },
               %{
                 "source_attribute" => "display_names",
                 "target_field" => "display_name",
                 "multivalue_strategy" => "all"
               }
             ],
             "group_rules" => []
           }

    assert revision.diff_summary["changed_fields"] == ["attribute_mappings"]
    assert revision.diff_summary["after_count"] == 2

    [event] = @repo.all(AuditEvent)
    assert event.domain == :mapping
    assert event.action == :created
    assert event.actor == "ops@example.com"
    assert event.cause == "manual_mapping_update"
    assert event.diff_summary["mapping_revision_id"] == revision.id

    persisted = @repo.get!(Connection, connection.id)
    assert persisted.lock_version == connection.lock_version + 1
  end

  test "replace_group_mappings replaces existing rows and preserves exact-match semantics only" do
    connection = insert_connection!("01JV2B4ENQDJ6D44AH0R0R5XA2")

    assert {:ok, _result} =
             MappingCommands.replace_group_mappings(
               connection.connection_id,
               [
                 %{
                   source_attribute: "groups",
                   source_value: "admins",
                   role_target: :role,
                   role_value: "admin"
                 }
               ],
               repo: @repo,
               audit: %{actor: "ops@example.com", cause: "seed_group_mapping"}
             )

    assert {:ok, result} =
             MappingCommands.replace_group_mappings(
               connection.connection_id,
               [
                 %{
                   source_attribute: "groups",
                   source_value: "developers",
                   role_target: :role,
                   role_value: "developer"
                 }
               ],
               repo: @repo,
               audit: %{actor: "ops@example.com", cause: "replace_group_mapping"}
             )

    assert result.action == :replaced

    assert group_rows(connection.id) == [
             %{
               position: 0,
               source_attribute: "groups",
               source_value: "developers",
               role_target: "role",
               role_value: "developer"
             }
           ]

    latest_revision =
      MappingRevision
      |> order_by([revision], desc: revision.inserted_at)
      |> limit(1)
      |> @repo.one()

    assert latest_revision.action == :replaced
    assert latest_revision.before_snapshot["group_rules"] == [
             %{
               "source_attribute" => "groups",
               "source_value" => "admins",
               "role_target" => "role",
               "role_value" => "admin"
             }
           ]

    assert latest_revision.after_snapshot["group_rules"] == [
             %{
               "source_attribute" => "groups",
               "source_value" => "developers",
               "role_target" => "role",
               "role_value" => "developer"
             }
           ]
  end

  test "mapping commands reject regex, script, and expression-style semantics" do
    connection = insert_connection!("01JV2B4ENQDJ6D44AH0R0R5XA3")

    assert {:error, %Relyra.Error{type: :invalid_connection_record, details: details}} =
             MappingCommands.replace_attribute_mappings(
               connection.connection_id,
               [
                 %{
                   source_attribute: "mail",
                   target_field: :email,
                   multivalue_strategy: :first,
                   regex: ".*"
                 }
               ],
               repo: @repo,
               audit: %{actor: "ops@example.com", cause: "bad_mapping"}
             )

    assert details.reason == :unsupported_mapping_keys
    assert "regex" in details.unsupported_keys
    assert attribute_rows(connection.id) == []

    assert {:error, %Relyra.Error{details: group_details}} =
             MappingCommands.replace_group_mappings(
               connection.connection_id,
               [
                 %{
                   source_attribute: "groups",
                   source_value: "admins",
                   role_target: :role,
                   role_value: "admin",
                   expression: "groups.contains('admins')"
                 }
               ],
               repo: @repo,
               audit: %{actor: "ops@example.com", cause: "bad_group_mapping"}
             )

    assert group_details.reason == :unsupported_mapping_keys
    assert "expression" in group_details.unsupported_keys
    assert group_rows(connection.id) == []
    assert @repo.aggregate(MappingRevision, :count) == 0
    assert @repo.aggregate(AuditEvent, :count) == 0
  end

  test "mapping commands require explicit repo and audit context" do
    assert {:error, %Relyra.Error{type: :adapter_not_configured}} =
             MappingCommands.replace_attribute_mappings("01JV2B4ENQDJ6D44AH0R0R5XA4", [])

    assert {:error, %Relyra.Error{type: :invalid_connection_record, details: details}} =
             MappingCommands.replace_group_mappings(
               "01JV2B4ENQDJ6D44AH0R0R5XA5",
               [],
               repo: @repo
             )

    assert details.reason == ":missing_audit_context"
  end

  defp insert_connection!(connection_id) do
    now = DateTime.utc_now()

    %Connection{
      id: Ecto.UUID.generate(),
      connection_id: connection_id,
      display_name: "Mapping test",
      organization_id: "org_mapping",
      status: :draft,
      lock_version: 1,
      inserted_at: now,
      updated_at: now
    }
    |> @repo.insert!()
  end

  defp attribute_rows(connection_record_id) do
    @repo.all(
      from row in @attribute_table,
        where: field(row, :connection_record_id) == type(^connection_record_id, :binary_id),
        order_by: [asc: field(row, :position)],
        select: %{
          position: field(row, :position),
          source_attribute: field(row, :source_attribute),
          target_field: field(row, :target_field),
          multivalue_strategy: field(row, :multivalue_strategy)
        }
    )
  end

  defp group_rows(connection_record_id) do
    @repo.all(
      from row in @group_table,
        where: field(row, :connection_record_id) == type(^connection_record_id, :binary_id),
        order_by: [asc: field(row, :position)],
        select: %{
          position: field(row, :position),
          source_attribute: field(row, :source_attribute),
          source_value: field(row, :source_value),
          role_target: field(row, :role_target),
          role_value: field(row, :role_value)
        }
    )
  end
end
