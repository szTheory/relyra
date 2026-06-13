defmodule LedgerLoop.Repo.Migrations.CreateRelyraRuntimeStoreTables do
  use Ecto.Migration

  def change do
    create table(:ledger_loop_relyra_request_intents, primary_key: false) do
      add :relay_state, :string, null: false
      add :request_id, :string, null: false
      add :intent, :map, null: false
      add :consumed_at, :utc_datetime_usec
      add :expires_at, :utc_datetime_usec, null: false
    end

    create unique_index(:ledger_loop_relyra_request_intents, [:relay_state])
    create unique_index(:ledger_loop_relyra_request_intents, [:relay_state, :request_id])
    create index(:ledger_loop_relyra_request_intents, [:expires_at])

    create table(:ledger_loop_relyra_replay_keys, primary_key: false) do
      add :replay_key, :string, null: false
      add :inserted_at, :utc_datetime_usec, null: false
      add :metadata, :map, null: false
    end

    create unique_index(:ledger_loop_relyra_replay_keys, [:replay_key])
  end
end
