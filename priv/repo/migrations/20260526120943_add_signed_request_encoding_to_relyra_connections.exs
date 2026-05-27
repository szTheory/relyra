defmodule Relyra.Repo.Migrations.AddSignedRequestEncodingToRelyraConnections do
  use Ecto.Migration

  def change do
    alter table(:relyra_connections) do
      add :signed_request_encoding, :string, null: true
    end
  end
end
