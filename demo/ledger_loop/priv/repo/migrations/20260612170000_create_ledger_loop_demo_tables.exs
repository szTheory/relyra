defmodule LedgerLoop.Repo.Migrations.CreateLedgerLoopDemoTables do
  use Ecto.Migration

  def change do
    create table(:ledger_loop_tenants, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :slug, :string, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:ledger_loop_tenants, [:slug])

    create table(:ledger_loop_users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string, null: false
      add :name, :string, null: false

      add :tenant_id, references(:ledger_loop_tenants, type: :binary_id, on_delete: :delete_all),
        null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:ledger_loop_users, [:email])

    create table(:ledger_loop_groups, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :key, :string, null: false

      add :tenant_id, references(:ledger_loop_tenants, type: :binary_id, on_delete: :delete_all),
        null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:ledger_loop_groups, [:tenant_id, :key])

    create table(:ledger_loop_memberships, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :user_id, references(:ledger_loop_users, type: :binary_id, on_delete: :delete_all),
        null: false

      add :group_id, references(:ledger_loop_groups, type: :binary_id, on_delete: :delete_all),
        null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:ledger_loop_memberships, [:user_id, :group_id])

    create table(:ledger_loop_saml_identities, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :user_id, references(:ledger_loop_users, type: :binary_id, on_delete: :delete_all),
        null: false

      add :subject, :string, null: false
      add :issuer, :string, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:ledger_loop_saml_identities, [:issuer, :subject])
    create unique_index(:ledger_loop_saml_identities, [:user_id, :issuer])

    create table(:ledger_loop_login_receipts, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :user_id, references(:ledger_loop_users, type: :binary_id, on_delete: :delete_all),
        null: false

      add :scenario_key, :string, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:ledger_loop_login_receipts, [:user_id, :scenario_key])
  end
end
