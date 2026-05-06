defmodule Relyra.Repo.Migrations.AddMetadataRevisionPointersToRelyraConnections do
  use Ecto.Migration

  def change do
    alter table(:relyra_connections) do
      add :active_metadata_revision_id, :binary_id
      add :last_known_good_metadata_revision_id, :binary_id
    end

    create index(:relyra_connections, [:active_metadata_revision_id])
    create index(:relyra_connections, [:last_known_good_metadata_revision_id])
  end
end
