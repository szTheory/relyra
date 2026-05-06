defmodule Relyra.Repo.Migrations.AddAllowIdpInitiatedToRelyraConnections do
  use Ecto.Migration

  def change do
    alter table(:relyra_connections) do
      add :allow_idp_initiated, :boolean, default: false, null: false
    end
  end
end
