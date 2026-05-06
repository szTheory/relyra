defmodule Relyra.Repo.Migrations.AddCertificateLifecycleToRelyraConnectionCertificates do
  use Ecto.Migration

  def up do
    alter table(:relyra_connection_certificates) do
      add :role, :string, null: false, default: "signing"
      add :lifecycle_state, :string, null: false, default: "active"
      add :staged_at, :utc_datetime_usec
      add :activated_at, :utc_datetime_usec
      add :retired_at, :utc_datetime_usec
    end

    execute("""
    UPDATE relyra_connection_certificates
    SET activated_at = COALESCE(activated_at, inserted_at)
    WHERE lifecycle_state = 'active'
    """)
  end

  def down do
    alter table(:relyra_connection_certificates) do
      remove :retired_at
      remove :activated_at
      remove :staged_at
      remove :lifecycle_state
      remove :role
    end
  end
end
