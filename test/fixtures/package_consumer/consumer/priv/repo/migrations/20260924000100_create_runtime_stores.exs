defmodule PackageConsumer.Repo.Migrations.CreateRuntimeStores do
  use Ecto.Migration

  def change do
    create table(:package_consumer_request_intents, primary_key: false) do
      add :relay_state, :text, null: false
      add :request_id, :text, null: false
      add :intent, :map, null: false
      add :consumed_at, :utc_datetime_usec
      add :expires_at, :utc_datetime_usec, null: false
    end

    create unique_index(:package_consumer_request_intents, [:relay_state])

    create unique_index(:package_consumer_request_intents, [:relay_state, :request_id])

    create index(:package_consumer_request_intents, [:expires_at])

    create table(:package_consumer_replay_keys, primary_key: false) do
      add :replay_key, :text, null: false
      add :inserted_at, :utc_datetime_usec, null: false
      add :metadata, :map, null: false
    end

    create unique_index(:package_consumer_replay_keys, [:replay_key])
  end
end
