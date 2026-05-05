defmodule Relyra.Repo.Migrations.CreateRelyraMappingAndAuditTables do
  use Ecto.Migration

  def change do
    create table(:relyra_attribute_mappings, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :connection_record_id, references(:relyra_connections, type: :binary_id, on_delete: :delete_all),
        null: false

      add :position, :integer, null: false, default: 0
      add :source_attribute, :string, null: false
      add :target_field, :string, null: false
      add :multivalue_strategy, :string, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:relyra_attribute_mappings, [:connection_record_id, :position])

    create unique_index(
             :relyra_attribute_mappings,
             [:connection_record_id, :target_field]
           )

    create table(:relyra_group_mappings, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :connection_record_id, references(:relyra_connections, type: :binary_id, on_delete: :delete_all),
        null: false

      add :position, :integer, null: false, default: 0
      add :source_attribute, :string, null: false
      add :source_value, :string, null: false
      add :role_target, :string, null: false
      add :role_value, :string, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:relyra_group_mappings, [:connection_record_id, :position])

    create unique_index(
             :relyra_group_mappings,
             [:connection_record_id, :source_attribute, :source_value, :role_value]
           )

    create table(:relyra_mapping_revisions, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :connection_record_id, references(:relyra_connections, type: :binary_id, on_delete: :delete_all),
        null: false

      add :actor, :string, null: false
      add :action, :string, null: false
      add :cause, :string, null: false
      add :correlation_id, :string
      add :before_snapshot, :map, null: false, default: %{}
      add :after_snapshot, :map, null: false, default: %{}
      add :diff_summary, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create index(:relyra_mapping_revisions, [:connection_record_id, :inserted_at])

    create table(:relyra_audit_events, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :connection_record_id, references(:relyra_connections, type: :binary_id, on_delete: :delete_all),
        null: false

      add :domain, :string, null: false
      add :action, :string, null: false
      add :actor, :string, null: false
      add :cause, :string, null: false
      add :correlation_id, :string
      add :before_summary, :map, null: false, default: %{}
      add :after_summary, :map, null: false, default: %{}
      add :diff_summary, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create index(:relyra_audit_events, [:connection_record_id, :inserted_at])
    create index(:relyra_audit_events, [:connection_record_id, :domain, :inserted_at])
  end
end
