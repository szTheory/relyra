defmodule Relyra.Repo.Migrations.ExtendRelyraMetadataSourcesWithAutoRefresh do
  use Ecto.Migration

  def change do
    alter table(:relyra_metadata_sources) do
      add :auto_refresh_enabled, :boolean, default: false, null: false
      add :refresh_cadence, :string, default: "daily", null: false
      add :next_refresh_at, :utc_datetime_usec
      add :require_signed_metadata, :boolean, default: true, null: false
      add :metadata_trust_fingerprints, {:array, :string}, default: [], null: false
      add :legacy_unsigned_metadata_policy, :map
      add :last_known_metadata_signing_certs, {:array, :string}, default: [], null: false
      add :consecutive_failure_count, :integer, default: 0, null: false
      add :first_failure_at, :utc_datetime_usec
      add :last_success_at, :utc_datetime_usec
      add :last_failure_error_code, :string
      add :last_validity_warning_for, :utc_datetime_usec
      add :auto_suspended_until, :utc_datetime_usec
      add :auto_suspended_reason, :string
    end

    # Partial index per D-12. The predicate is restricted to `auto_refresh_enabled = true`
    # rather than the broader `auto_refresh_enabled = true AND (auto_suspended_until IS NULL
    # OR auto_suspended_until <= now())` from PLAN/RESEARCH because Postgres requires
    # partial-index predicates to use IMMUTABLE functions only — `now()` is STABLE, not
    # IMMUTABLE, so it cannot appear in the WHERE clause of CREATE INDEX. The runtime due-row
    # query (RESEARCH Pattern 5) still applies the suspension/time filter at query time,
    # which is the canonical Postgres idiom for time-based partial indexes; the index keeps
    # scheduler-tick work O(enabled-source-count), preserving D-12's intent.
    create index(:relyra_metadata_sources, [:next_refresh_at],
             name: :relyra_metadata_sources_due_idx,
             where: "auto_refresh_enabled = true")
  end
end
