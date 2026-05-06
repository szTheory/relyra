defmodule Relyra.Repo.Migrations.HardenRelyraCertificateLifecycleInvariants do
  use Ecto.Migration

  def up do
    alter table(:relyra_connections) do
      add :lock_version, :integer, null: false, default: 1
    end

    create index(
             :relyra_connection_certificates,
             [:connection_record_id, :lifecycle_state],
             where: "role = 'signing' AND lifecycle_state = 'active'",
             name: :relyra_certificates_active_signing_idx
           )
  end

  def down do
    drop index(:relyra_connection_certificates, [:connection_record_id, :lifecycle_state],
           name: :relyra_certificates_active_signing_idx
         )

    alter table(:relyra_connections) do
      remove :lock_version
    end
  end
end
