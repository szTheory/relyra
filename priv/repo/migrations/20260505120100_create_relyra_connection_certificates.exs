defmodule Relyra.Repo.Migrations.CreateRelyraConnectionCertificates do
  use Ecto.Migration

  def change do
    create table(:relyra_connection_certificates, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :connection_record_id, references(:relyra_connections, type: :binary_id, on_delete: :delete_all),
        null: false

      add :fingerprint_sha256, :string, null: false
      add :pem, :text, null: false
      add :source, :string, null: false
      add :not_before, :utc_datetime_usec
      add :not_after, :utc_datetime_usec
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create index(:relyra_connection_certificates, [:connection_record_id])

    create unique_index(
             :relyra_connection_certificates,
             [:connection_record_id, :fingerprint_sha256]
           )
  end
end
