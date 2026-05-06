defmodule Relyra.Repo.Migrations.CreateRelyraMetadataSources do
  use Ecto.Migration

  def change do
    create table(:relyra_metadata_sources, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :connection_record_id, references(:relyra_connections, type: :binary_id, on_delete: :delete_all),
        null: false

      add :url, :text, null: false
      add :kind, :string, null: false
      add :registered_by, :string, null: false
      add :registered_reason, :string, null: false
      add :last_fetched_at, :utc_datetime_usec
      add :last_outcome, :string
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:relyra_metadata_sources, [:connection_record_id])
  end
end
