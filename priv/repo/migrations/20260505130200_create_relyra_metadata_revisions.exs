defmodule Relyra.Repo.Migrations.CreateRelyraMetadataRevisions do
  use Ecto.Migration

  def change do
    create table(:relyra_metadata_revisions, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :connection_record_id, references(:relyra_connections, type: :binary_id, on_delete: :delete_all),
        null: false

      add :metadata_source_id, references(:relyra_metadata_sources, type: :binary_id, on_delete: :nilify_all)
      add :source_kind, :string, null: false
      add :trigger, :string, null: false
      add :outcome, :string, null: false
      add :content_hash_sha256, :string
      add :effective_idp_entity_id, :text
      add :effective_idp_sso_url, :text
      add :certificate_fingerprints, {:array, :string}, null: false, default: []
      add :trust_summary, :map, null: false, default: %{}
      add :actor, :string
      add :cause, :string
      add :details, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create index(:relyra_metadata_revisions, [:connection_record_id, :inserted_at])
    create index(:relyra_metadata_revisions, [:metadata_source_id])

    execute(
      """
      ALTER TABLE relyra_connections
      ADD CONSTRAINT relyra_connections_active_metadata_revision_id_fkey
      FOREIGN KEY (active_metadata_revision_id)
      REFERENCES relyra_metadata_revisions(id)
      ON DELETE SET NULL
      """,
      """
      ALTER TABLE relyra_connections
      DROP CONSTRAINT IF EXISTS relyra_connections_active_metadata_revision_id_fkey
      """
    )

    execute(
      """
      ALTER TABLE relyra_connections
      ADD CONSTRAINT relyra_connections_last_known_good_metadata_revision_id_fkey
      FOREIGN KEY (last_known_good_metadata_revision_id)
      REFERENCES relyra_metadata_revisions(id)
      ON DELETE SET NULL
      """,
      """
      ALTER TABLE relyra_connections
      DROP CONSTRAINT IF EXISTS relyra_connections_last_known_good_metadata_revision_id_fkey
      """
    )
  end
end
