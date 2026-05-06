defmodule Relyra.Repo.Migrations.CreateRelyraConnections do
  use Ecto.Migration

  def change do
    create table(:relyra_connections, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :connection_id, :string, null: false
      add :display_name, :string
      add :organization_id, :string
      add :status, :string, null: false, default: "draft"
      add :provider_preset, :string
      add :sp_entity_id, :string
      add :acs_url, :string
      add :idp_entity_id, :string
      add :idp_sso_url, :string
      add :runtime_policy, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:relyra_connections, [:connection_id])
    create index(:relyra_connections, [:status])
  end
end
