defmodule Relyra.Repo.Migrations.AddSignAuthnRequestsToRelyraConnections do
  use Ecto.Migration

  def change do
    alter table(:relyra_connections) do
      add :sign_authn_requests, :boolean, default: false, null: false
    end
  end
end
