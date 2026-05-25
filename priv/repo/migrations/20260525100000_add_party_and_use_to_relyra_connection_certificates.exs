defmodule Relyra.Repo.Migrations.AddPartyAndUseToRelyraConnectionCertificates do
  use Ecto.Migration

  def up do
    alter table(:relyra_connection_certificates) do
      add :party, :string, null: false, default: "idp"
      add :use, :string, null: false, default: "signing"
    end
  end

  def down do
    alter table(:relyra_connection_certificates) do
      remove :use
      remove :party
    end
  end
end
