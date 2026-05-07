---
phase: 21
plan: 01
type: execute
wave: 0
depends_on: []
files_modified:
  - priv/repo/migrations/20260507000001_extend_relyra_metadata_sources_with_auto_refresh.exs
  - lib/relyra/ecto/metadata_source.ex
  - test/relyra/ecto/metadata_source_test.exs
  - test/relyra/metadata/scheduler_test.exs
  - test/relyra/metadata/auto_refresh_test.exs
  - test/relyra/metadata/cadence_test.exs
  - test/relyra/metadata/failure_classifier_test.exs
  - test/relyra/metadata/backoff_test.exs
  - test/relyra/metadata/drift_detector_test.exs
  - test/relyra/metadata/trust_anchor_test.exs
  - test/relyra/security/xml/corpus_gate_test.exs
  - test/relyra/optional_deps/oban_test.exs
  - test/relyra/workers/metadata_refresh_test.exs
  - test/relyra/telemetry/handlers/log_alerts_test.exs
  - test/relyra/security/signature_test.exs
  - test/relyra/live_admin/connections_live_test.exs
  - test/relyra/live_admin/connection_metadata_live_test.exs
  - test/mix/tasks/relyra_refresh_due_test.exs
  - test/mix/tasks/relyra_metadata_pin_test.exs
autonomous: true
requirements:
  - CFG-08
must_haves:
  truths:
    - "Existing metadata source rows backfill cleanly with auto-refresh disabled and signed metadata required"
    - "The relyra_metadata_sources_due_idx partial index makes the due-row query a single index scan"
    - "Operator cannot enable auto-refresh on a source without first pinning at least one SHA-256 trust fingerprint"
    - "All Wave 0 test stub files exist so subsequent waves can fill them with green tests rather than create them from scratch"
    - "Schema enums (refresh_cadence, auto_suspended_reason) are typed so an invalid preset rejects at the changeset boundary"
  artifacts:
    - path: "priv/repo/migrations/20260507000001_extend_relyra_metadata_sources_with_auto_refresh.exs"
      provides: "Single consolidated migration adding 14 columns + 1 partial index to relyra_metadata_sources"
      contains: "create index(:relyra_metadata_sources, [:next_refresh_at]"
    - path: "lib/relyra/ecto/metadata_source.ex"
      provides: "Extended schema with auto_refresh fields + auto_refresh_changeset/2 + health_state_changeset/2"
      exports: ["changeset/2", "auto_refresh_changeset/2", "health_state_changeset/2"]
    - path: "test/relyra/ecto/metadata_source_test.exs"
      provides: "Coverage for new changeset paths including the great-error when fingerprints unset (D-09)"
  key_links:
    - from: "lib/relyra/ecto/metadata_source.ex"
      to: "priv/repo/migrations/20260507000001_extend_relyra_metadata_sources_with_auto_refresh.exs"
      via: "Ecto.Enum field declarations match column types added in the migration"
      pattern: "field :refresh_cadence, Ecto.Enum"
    - from: "test/relyra/ecto/metadata_source_test.exs"
      to: "lib/relyra/ecto/metadata_source.ex"
      via: "Tests assert auto_refresh_changeset/2 returns errors when enabling without fingerprints"
      pattern: "auto_refresh_changeset"
---

<objective>
Land the schema foundation Phase 21 needs: one consolidated migration adding the 14 auto-refresh fields and the partial index to `relyra_metadata_sources`; extend `Relyra.Ecto.MetadataSource` with `auto_refresh_changeset/2` (operator-facing) and `health_state_changeset/2` (D-28 — called only from `MetadataApply`); and create empty test stub files for every Wave 0 module Phase 21 will introduce so later waves drop tests in rather than create files from scratch.

Purpose: Per RESEARCH "Wave plan", the schema must land before pure-function helpers, the wrapper, the worker, or the LiveView extensions can compile against the new fields. The Wave 0 test stub files give every later wave a place to write tests with `<automated>` verify commands that point at file paths existing from day one.

Output: Migration file, extended schema module, schema test coverage, and 13 stub test files (each with at least a `defmodule` shell and one pending `@tag :pending` test) covering Phase 21's new modules.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/21-scheduled-metadata-refresh/21-CONTEXT.md
@.planning/phases/21-scheduled-metadata-refresh/21-RESEARCH.md
@.planning/phases/21-scheduled-metadata-refresh/21-PATTERNS.md
@.planning/phases/21-scheduled-metadata-refresh/21-VALIDATION.md
@lib/relyra/ecto/metadata_source.ex
@priv/repo/migrations/20260506232319_add_allow_idp_initiated_to_relyra_connections.exs

<interfaces>
Existing schema (`lib/relyra/ecto/metadata_source.ex`) — DO NOT remove or rename:

```elixir
@kind_values [:remote_url]
@outcome_values [:registered, :fetch_failed, :fetched, :applied, :parse_failed, :validation_failed, :apply_failed]

schema "relyra_metadata_sources" do
  field :url, :string
  field :kind, Ecto.Enum, values: @kind_values
  field :registered_by, :string
  field :registered_reason, :string
  field :last_fetched_at, :utc_datetime_usec
  field :last_outcome, Ecto.Enum, values: @outcome_values
  field :metadata, :map, default: %{}
  belongs_to :connection, Connection, foreign_key: :connection_record_id, references: :id, type: :binary_id
  timestamps(type: :utc_datetime_usec)
end

def changeset(source, attrs)  # cast/validate existing fields, unique_constraint(:connection_record_id)
```

Phase-21 fields to add (LOCKED set per CONTEXT.md schema-additions table + RESEARCH Q2):

| Field | Type | Default | null:false |
|---|---|---|---|
| auto_refresh_enabled | boolean | false | yes |
| refresh_cadence | Ecto.Enum [:hourly, :every_6h, :daily, :weekly] (string column) | "daily" | yes |
| next_refresh_at | utc_datetime_usec | nil | no |
| require_signed_metadata | boolean | true | yes |
| metadata_trust_fingerprints | {:array, :string} | [] | yes |
| legacy_unsigned_metadata_policy | :map | nil | no |
| last_known_metadata_signing_certs | {:array, :string} | [] | yes |
| consecutive_failure_count | :integer | 0 | yes |
| first_failure_at | utc_datetime_usec | nil | no |
| last_success_at | utc_datetime_usec | nil | no |
| last_failure_error_code | :string | nil | no |
| last_validity_warning_for | utc_datetime_usec | nil | no |
| auto_suspended_until | utc_datetime_usec | nil | no |
| auto_suspended_reason | Ecto.Enum [:entity_id_drift, :new_signing_cert, :signature_invalid, :corpus_violation, :transient_failures_exceeded, :trust_anchor_mismatch] (string column) | nil | no |

Suspended-reason enum atoms (LOCKED per CONTEXT.md D-18/D-25):
`[:entity_id_drift, :new_signing_cert, :signature_invalid, :corpus_violation, :transient_failures_exceeded, :trust_anchor_mismatch]`

Cadence enum atoms (LOCKED per CONTEXT.md D-10): `[:hourly, :every_6h, :daily, :weekly]`
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Write the consolidated migration extending relyra_metadata_sources</name>
  <files>priv/repo/migrations/20260507000001_extend_relyra_metadata_sources_with_auto_refresh.exs</files>
  <read_first>
    - priv/repo/migrations/20260506232319_add_allow_idp_initiated_to_relyra_connections.exs (single-column add precedent — copy header + alter-table shape verbatim)
    - .planning/phases/21-scheduled-metadata-refresh/21-CONTEXT.md (Schema Additions table — LOCKED field set; D-12 partial index specification)
    - .planning/phases/21-scheduled-metadata-refresh/21-RESEARCH.md "Example B: Migration" section (the canonical migration body with 14 add statements + create index)
    - .planning/phases/21-scheduled-metadata-refresh/21-PATTERNS.md "priv/repo/migrations/<ts>_extend_metadata_source_for_auto_refresh.exs" section
    - lib/relyra/ecto/metadata_source.ex (current schema — confirm column names not already used)
  </read_first>
  <action>
    Create `priv/repo/migrations/20260507000001_extend_relyra_metadata_sources_with_auto_refresh.exs` with module name `Relyra.Repo.Migrations.ExtendRelyraMetadataSourcesWithAutoRefresh`. Use `use Ecto.Migration` and a `def change do` block.

    Inside `alter table(:relyra_metadata_sources) do`, add the 14 columns from the LOCKED table above with these EXACT names, types, and null-false posture (per RESEARCH Example B verbatim — implements D-08, D-10, D-11, D-12, D-15, D-17, D-18, D-19, D-25, D-26, D-29, plus D-14/Q2 for `last_validity_warning_for`):

    ```elixir
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
    ```

    Outside the `alter table` (still inside `def change`), add the partial index per D-12 — this MUST be the exact name and where-clause RESEARCH Pattern 5 specifies, because the LiveView Query module and Scheduler.run_due/2 will rely on it being a single-index-scan operation:

    ```elixir
    create index(:relyra_metadata_sources, [:next_refresh_at],
             name: :relyra_metadata_sources_due_idx,
             where: "auto_refresh_enabled = true AND (auto_suspended_until IS NULL OR auto_suspended_until <= now())")
    ```

    DO NOT add a `lock_version` column — RESEARCH Example B note + PATTERNS section explicitly say `MetadataSource` does not need it (row-level transaction in `record_attempt/3` already serializes writes; `relyra_metadata_sources` does not currently carry one). Adding it now would force a follow-up migration to remove it.

    DO NOT split into multiple migrations — RESEARCH Assumption A1 says single migration is the established Relyra pattern.
  </action>
  <verify>
    <automated>mix ecto.migrate && mix ecto.rollback && mix ecto.migrate</automated>
  </verify>
  <acceptance_criteria>
    - File `priv/repo/migrations/20260507000001_extend_relyra_metadata_sources_with_auto_refresh.exs` exists.
    - `grep -c '^    add :' priv/repo/migrations/20260507000001_extend_relyra_metadata_sources_with_auto_refresh.exs` returns exactly `14`.
    - `grep -c "name: :relyra_metadata_sources_due_idx" priv/repo/migrations/20260507000001_extend_relyra_metadata_sources_with_auto_refresh.exs` returns `1`.
    - `grep -c "auto_refresh_enabled = true AND (auto_suspended_until IS NULL OR auto_suspended_until <= now())" priv/repo/migrations/20260507000001_extend_relyra_metadata_sources_with_auto_refresh.exs` returns `1`.
    - `grep -c "lock_version" priv/repo/migrations/20260507000001_extend_relyra_metadata_sources_with_auto_refresh.exs` returns `0`.
    - `mix ecto.migrate` exits 0; `mix ecto.rollback` exits 0; `mix ecto.migrate` exits 0 (round-trip safe).
    - After migration, `psql -c "\\d relyra_metadata_sources"` (or the equivalent `mix ecto.dump`) shows all 14 new columns and the `relyra_metadata_sources_due_idx` partial index.
  </acceptance_criteria>
  <done>Migration file applies cleanly, rolls back cleanly, re-applies cleanly. All 14 columns and the partial index exist on `relyra_metadata_sources`. No `lock_version` column added. No multiple-migration split.</done>
</task>

<task type="auto">
  <name>Task 2: Extend Relyra.Ecto.MetadataSource with auto-refresh fields and three changesets</name>
  <files>lib/relyra/ecto/metadata_source.ex</files>
  <read_first>
    - lib/relyra/ecto/metadata_source.ex (current schema — preserve EVERY existing field, alias, and the `if Code.ensure_loaded?(Ecto.Schema) do` gate verbatim)
    - .planning/phases/21-scheduled-metadata-refresh/21-RESEARCH.md "Example A: MetadataSource schema extension (changeset)" section (the canonical changeset shapes)
    - .planning/phases/21-scheduled-metadata-refresh/21-PATTERNS.md "lib/relyra/ecto/metadata_source.ex (EXTENDED schema)" section
    - lib/relyra/security/algorithm_policy.ex (analog for module-attr enum tables — `@sha1_signature_methods` shape at lines 6-14)
    - .planning/phases/21-scheduled-metadata-refresh/21-CONTEXT.md (D-09 great-error requirement: cannot enable without pinned fingerprints; D-28 single-transaction discipline)
  </read_first>
  <action>
    Edit `lib/relyra/ecto/metadata_source.ex`. Preserve the existing `if Code.ensure_loaded?(Ecto.Schema) do ... else ... end` gate, the existing `@primary_key`, `@foreign_key_type`, `@kind_values`, `@outcome_values`, the existing `schema "relyra_metadata_sources" do` block contents, the existing `changeset/2`, and the existing `validate_https_url/2` helper.

    Add two new module attributes immediately after `@outcome_values`:
    ```elixir
    @cadence_values [:hourly, :every_6h, :daily, :weekly]
    @suspended_reason_values [
      :entity_id_drift,
      :new_signing_cert,
      :signature_invalid,
      :corpus_violation,
      :transient_failures_exceeded,
      :trust_anchor_mismatch
    ]
    ```

    Inside the `schema "relyra_metadata_sources" do` block, AFTER the existing `field :metadata, :map, default: %{}` line and BEFORE the `belongs_to :connection, Connection, ...` line, add the 14 new field declarations EXACTLY in this order (matching the migration column order):

    ```elixir
    field :auto_refresh_enabled, :boolean, default: false
    field :refresh_cadence, Ecto.Enum, values: @cadence_values, default: :daily
    field :next_refresh_at, :utc_datetime_usec
    field :require_signed_metadata, :boolean, default: true
    field :metadata_trust_fingerprints, {:array, :string}, default: []
    field :legacy_unsigned_metadata_policy, :map
    field :last_known_metadata_signing_certs, {:array, :string}, default: []
    field :consecutive_failure_count, :integer, default: 0
    field :first_failure_at, :utc_datetime_usec
    field :last_success_at, :utc_datetime_usec
    field :last_failure_error_code, :string
    field :last_validity_warning_for, :utc_datetime_usec
    field :auto_suspended_until, :utc_datetime_usec
    field :auto_suspended_reason, Ecto.Enum, values: @suspended_reason_values
    ```

    Add `auto_refresh_changeset/2` (operator-facing — used by both LiveView and the planned `mix relyra.metadata.pin` Mix task per D-22 recommendation; implements D-09 great-error):

    ```elixir
    @spec auto_refresh_changeset(t(), map()) :: Ecto.Changeset.t()
    def auto_refresh_changeset(source, attrs) do
      source
      |> cast(attrs, [
        :auto_refresh_enabled,
        :refresh_cadence,
        :next_refresh_at,
        :require_signed_metadata,
        :metadata_trust_fingerprints,
        :legacy_unsigned_metadata_policy
      ])
      |> validate_required([:auto_refresh_enabled, :refresh_cadence])
      |> validate_fingerprints_when_enabled()
    end

    defp validate_fingerprints_when_enabled(changeset) do
      enabled? = get_field(changeset, :auto_refresh_enabled)
      fingerprints = get_field(changeset, :metadata_trust_fingerprints) || []

      if enabled? == true and fingerprints == [] do
        add_error(
          changeset,
          :metadata_trust_fingerprints,
          "is required when auto_refresh_enabled is true; pin at least one SHA-256 fingerprint via the admin LiveView (or `mix relyra.metadata.pin`) before enabling auto-refresh"
        )
      else
        changeset
      end
    end
    ```

    Add `health_state_changeset/2` (D-28 — DOC IT clearly that this is called ONLY from `Relyra.Ecto.MetadataApply.record_attempt/3` and `apply_revision/4`, NEVER from the LiveView or any user-facing path; future Phase 21 plans will add the only call sites):

    ```elixir
    @doc """
    Health-state changeset called ONLY from `Relyra.Ecto.MetadataApply.record_attempt/3`
    and `apply_revision/4` per D-28 (single audit-writer seam — no parallel audit/health
    writer). Never call from LiveView, Mix tasks, or any user-facing path.
    """
    @spec health_state_changeset(t(), map()) :: Ecto.Changeset.t()
    def health_state_changeset(source, attrs) do
      source
      |> cast(attrs, [
        :consecutive_failure_count,
        :first_failure_at,
        :last_success_at,
        :last_failure_error_code,
        :last_validity_warning_for,
        :auto_suspended_until,
        :auto_suspended_reason,
        :next_refresh_at,
        :last_known_metadata_signing_certs
      ])
    end
    ```

    Do NOT modify the existing `changeset/2`. Do NOT remove `validate_https_url/2`. Do NOT change the `else` branch of the top-level `if Code.ensure_loaded?(Ecto.Schema)`.
  </action>
  <verify>
    <automated>mix compile --warnings-as-errors && mix compile --no-optional-deps --warnings-as-errors</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "@cadence_values \[:hourly, :every_6h, :daily, :weekly\]" lib/relyra/ecto/metadata_source.ex` returns `1`.
    - `grep -c "@suspended_reason_values" lib/relyra/ecto/metadata_source.ex` returns at least `1`.
    - `grep -c "field :auto_refresh_enabled, :boolean, default: false" lib/relyra/ecto/metadata_source.ex` returns `1`.
    - `grep -c "field :refresh_cadence, Ecto.Enum" lib/relyra/ecto/metadata_source.ex` returns `1`.
    - `grep -c "field :auto_suspended_reason, Ecto.Enum" lib/relyra/ecto/metadata_source.ex` returns `1`.
    - `grep -c "def auto_refresh_changeset" lib/relyra/ecto/metadata_source.ex` returns `1`.
    - `grep -c "def health_state_changeset" lib/relyra/ecto/metadata_source.ex` returns `1`.
    - `grep -c "def changeset(source, attrs)" lib/relyra/ecto/metadata_source.ex` returns `1` (the existing changeset is preserved).
    - `grep -cE "field :(auto_refresh_enabled|refresh_cadence|next_refresh_at|require_signed_metadata|metadata_trust_fingerprints|legacy_unsigned_metadata_policy|last_known_metadata_signing_certs|consecutive_failure_count|first_failure_at|last_success_at|last_failure_error_code|last_validity_warning_for|auto_suspended_until|auto_suspended_reason)" lib/relyra/ecto/metadata_source.ex` returns `14`.
    - `mix compile --warnings-as-errors` exits 0.
    - `mix compile --no-optional-deps --warnings-as-errors` exits 0 (existing `Ecto.Schema` gate keeps the no-Ecto compile path green).
  </acceptance_criteria>
  <done>Schema declares all 14 new fields with correct types and defaults; `auto_refresh_changeset/2` rejects enabling auto-refresh without fingerprints with the great-error message (D-09); `health_state_changeset/2` exists and is documented as `MetadataApply`-only (D-28); the existing `changeset/2` is untouched. Both compile lanes stay green.</done>
</task>

<task type="auto">
  <name>Task 3: Test extended MetadataSource changesets and create the Wave 0 test stub files</name>
  <files>test/relyra/ecto/metadata_source_test.exs, test/relyra/metadata/scheduler_test.exs, test/relyra/metadata/auto_refresh_test.exs, test/relyra/metadata/cadence_test.exs, test/relyra/metadata/failure_classifier_test.exs, test/relyra/metadata/backoff_test.exs, test/relyra/metadata/drift_detector_test.exs, test/relyra/metadata/trust_anchor_test.exs, test/relyra/security/xml/corpus_gate_test.exs, test/relyra/optional_deps/oban_test.exs, test/relyra/workers/metadata_refresh_test.exs, test/relyra/telemetry/handlers/log_alerts_test.exs</files>
  <read_first>
    - lib/relyra/ecto/metadata_source.ex (the file just edited in Task 2 — confirm changeset signatures)
    - .planning/phases/21-scheduled-metadata-refresh/21-VALIDATION.md "Wave 0 Requirements" section (the LOCKED list of test stub files Phase 21 expects)
    - test/relyra/ecto/ (existing tests — pick any one to mirror its `use ExUnit.Case` shape and module-naming convention)
  </read_first>
  <action>
    First, write meaningful tests in `test/relyra/ecto/metadata_source_test.exs` (this file may already exist — extend it rather than overwrite). Add (or create the file with) ExUnit tests covering the new changeset paths:

    1. `test "auto_refresh_changeset/2 accepts cadence preset and trust fingerprints"` — given `auto_refresh_enabled: true, refresh_cadence: :hourly, metadata_trust_fingerprints: ["abc..."]`, `changeset.valid?` is `true`.
    2. `test "auto_refresh_changeset/2 rejects enabling without pinned fingerprints (D-09 great-error)"` — given `auto_refresh_enabled: true, refresh_cadence: :daily, metadata_trust_fingerprints: []`, the changeset has the error `metadata_trust_fingerprints: {"is required when auto_refresh_enabled is true; pin at least one SHA-256 fingerprint via the admin LiveView (or `mix relyra.metadata.pin`) before enabling auto-refresh", _}`.
    3. `test "auto_refresh_changeset/2 rejects unknown cadence preset"` — given `refresh_cadence: :every_5min`, the changeset is invalid (`Ecto.Enum` rejects).
    4. `test "auto_refresh_changeset/2 allows enabling=false with empty fingerprints"` — given `auto_refresh_enabled: false, refresh_cadence: :daily, metadata_trust_fingerprints: []`, valid.
    5. `test "health_state_changeset/2 casts the documented health fields"` — given a map of the 9 cast fields, all are reflected in `changeset.changes`.
    6. `test "existing changeset/2 still works unchanged"` — smoke test that the existing path (registering a source with a URL) still produces a valid changeset (covers D-32 invariant: don't break manual import).

    Then, for EACH of the 11 stub files listed below that does NOT already exist, create a minimal stub:

    ```elixir
    defmodule Relyra.{ModulePath}Test do
      use ExUnit.Case, async: true

      @moduletag :pending

      @tag :pending
      test "Wave 0 stub: replaced by Wave {N} task in Phase 21" do
        # This stub exists so PLAN files can reference an automated verify
        # command pointing at this file from day one. The corresponding
        # production module will be created in a later wave (see
        # .planning/phases/21-scheduled-metadata-refresh/21-VALIDATION.md
        # Per-Task Verification Map for the wave assignment).
        flunk("Wave 0 stub — implement in the wave that introduces the production module")
      end
    end
    ```

    Stub files to create (skip any that already exist; `:pending`-tagged tests are excluded from the default suite via `config/test.exs` ExUnit `exclude: [:pending]` if not already present — if not present, ALSO add `ExUnit.configure(exclude: [:pending])` to `test/test_helper.exs` so Wave 0 stubs do not break `mix test`):

    | File | Module name |
    |------|-------------|
    | `test/relyra/metadata/scheduler_test.exs` | `Relyra.Metadata.SchedulerTest` |
    | `test/relyra/metadata/auto_refresh_test.exs` | `Relyra.Metadata.AutoRefreshTest` |
    | `test/relyra/metadata/cadence_test.exs` | `Relyra.Metadata.CadenceTest` |
    | `test/relyra/metadata/failure_classifier_test.exs` | `Relyra.Metadata.FailureClassifierTest` |
    | `test/relyra/metadata/backoff_test.exs` | `Relyra.Metadata.BackoffTest` |
    | `test/relyra/metadata/drift_detector_test.exs` | `Relyra.Metadata.DriftDetectorTest` |
    | `test/relyra/metadata/trust_anchor_test.exs` | `Relyra.Metadata.TrustAnchorTest` |
    | `test/relyra/security/xml/corpus_gate_test.exs` | `Relyra.Security.XML.CorpusGateTest` |
    | `test/relyra/optional_deps/oban_test.exs` | `Relyra.OptionalDeps.ObanTest` |
    | `test/relyra/workers/metadata_refresh_test.exs` | `Relyra.Workers.MetadataRefreshTest` |
    | `test/relyra/telemetry/handlers/log_alerts_test.exs` | `Relyra.Telemetry.Handlers.LogAlertsTest` |
    | `test/relyra/security/signature_test.exs` | `Relyra.Security.SignatureTest` (extends if exists; else stub) |
    | `test/relyra/live_admin/connections_live_test.exs` | `Relyra.LiveAdmin.ConnectionsLiveTest` (extends if exists; else stub) |
    | `test/relyra/live_admin/connection_metadata_live_test.exs` | `Relyra.LiveAdmin.ConnectionMetadataLiveTest` (extends if exists; else stub) |
    | `test/mix/tasks/relyra_refresh_due_test.exs` | `Mix.Tasks.Relyra.RefreshDueTest` |
    | `test/mix/tasks/relyra_metadata_pin_test.exs` | `Mix.Tasks.Relyra.Metadata.PinTest` |

    Mark the suite-level `ExUnit.configure` in `test/test_helper.exs` to add `:pending` to the default exclude list IF AND ONLY IF it is not already there. Do NOT remove existing exclude tags. If the helper already excludes `:pending`, leave it untouched.
  </action>
  <verify>
    <automated>mix test test/relyra/ecto/metadata_source_test.exs --warnings-as-errors && mix test --exclude pending --warnings-as-errors</automated>
  </verify>
  <acceptance_criteria>
    - File `test/relyra/ecto/metadata_source_test.exs` exists and contains all 6 tests listed above (verify with `grep -c '^  test "' test/relyra/ecto/metadata_source_test.exs` returning `>= 6`).
    - All 16 stub-or-real test files exist (`for f in test/relyra/metadata/{scheduler,auto_refresh,cadence,failure_classifier,backoff,drift_detector,trust_anchor}_test.exs test/relyra/security/xml/corpus_gate_test.exs test/relyra/optional_deps/oban_test.exs test/relyra/workers/metadata_refresh_test.exs test/relyra/telemetry/handlers/log_alerts_test.exs test/relyra/security/signature_test.exs test/relyra/live_admin/connections_live_test.exs test/relyra/live_admin/connection_metadata_live_test.exs test/mix/tasks/relyra_refresh_due_test.exs test/mix/tasks/relyra_metadata_pin_test.exs; do test -f "$f" || echo MISSING $f; done` produces no MISSING output).
    - Each stub file contains `@moduletag :pending` (verify with `grep -l '@moduletag :pending' test/relyra/{metadata,security/xml,optional_deps,workers,telemetry/handlers}/*.exs | wc -l` returns `>= 11`).
    - `mix test test/relyra/ecto/metadata_source_test.exs --warnings-as-errors` exits 0 with at least 6 tests passing.
    - `mix test --exclude pending --warnings-as-errors` exits 0 (Wave 0 stubs do not break the suite).
    - `test/test_helper.exs` excludes `:pending` (`grep -c ':pending' test/test_helper.exs` returns `>= 1`).
  </acceptance_criteria>
  <done>Schema test file covers all six changeset behaviors including the great-error message exactly as specified in D-09. All 16 Wave 0 stub-or-real test files exist; new stub files are excluded from the default suite via `:pending`. `mix test --exclude pending` is green. Later waves can drop production tests into the existing files rather than create them.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| LiveView form → `auto_refresh_changeset/2` | Operator-supplied `metadata_trust_fingerprints` cross from untrusted UI input into the trust schema; the changeset is the validation point. |
| `MetadataApply.record_attempt/3` → `health_state_changeset/2` | Health/counter state mutations cross from internal Phase-21 logic into the audit-writer transaction; the changeset is the cast allowlist (no other field can sneak in). |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-21-01 | Tampering | `auto_refresh_changeset/2` | mitigate | Whitelist cast fields exclude `consecutive_failure_count`, `auto_suspended_until`, etc. — operator cannot mutate health state through the operator-facing changeset (D-28 enforced at the cast boundary). |
| T-21-02 | Spoofing | `auto_refresh_changeset/2` (D-09) | mitigate | Reject `auto_refresh_enabled: true` with empty `metadata_trust_fingerprints` via `validate_fingerprints_when_enabled/1` — prevents enabling auto-refresh on a source with no operator-pinned trust anchor (TOFU-rejection precondition; D-17). |
| T-21-03 | Tampering | migration | mitigate | `null: false` defaults on every required column ensure existing rows backfill safely; new rows cannot be inserted with NULL `auto_refresh_enabled`/`require_signed_metadata` (which would break the asymmetric strictness contract). |
| T-21-04 | Elevation of Privilege | `refresh_cadence` enum | mitigate | `Ecto.Enum` rejects any value outside `[:hourly, :every_6h, :daily, :weekly]` at the changeset boundary — closes the cron-string DDoS-the-IdP footgun (D-10) at the type system level. |
| T-21-05 | Denial of Service | `relyra_metadata_sources_due_idx` partial index | mitigate | Partial index makes `Scheduler.run_due/2`'s due-row query a single-index-scan operation (D-12) instead of a full-table scan; protects against scheduler-tick latency growth as adopters add many connections. |
| T-21-06 | Information Disclosure | `legacy_unsigned_metadata_policy` (`:map`) | accept | Field is a JSON-encoded map; existing audit-writer redaction (`AuditWriter` lines 8-22) handles redacting any embedded sensitive value. No new exposure surface. Documented as time-boxed + audited per D-19; later waves wire the audit. |
</threat_model>

<verification>
- `mix ecto.migrate && mix ecto.rollback && mix ecto.migrate` is green (round-trip safe migration).
- `mix compile --warnings-as-errors` is green.
- `mix compile --no-optional-deps --warnings-as-errors` is green (existing `Ecto.Schema` gate preserved).
- `mix test test/relyra/ecto/metadata_source_test.exs --warnings-as-errors` is green with at least 6 tests passing.
- `mix test --exclude pending --warnings-as-errors` is green (Wave 0 stubs do not regress the existing suite).
- `mix format --check-formatted` is green.
</verification>

<success_criteria>
- All 14 LOCKED schema fields (per CONTEXT.md table + D-14/Q2 `last_validity_warning_for`) exist on `relyra_metadata_sources` with correct types, defaults, and null-false posture.
- `relyra_metadata_sources_due_idx` partial index exists with the EXACT where-clause `auto_refresh_enabled = true AND (auto_suspended_until IS NULL OR auto_suspended_until <= now())`.
- `Relyra.Ecto.MetadataSource` exports `changeset/2` (unchanged), `auto_refresh_changeset/2` (new, operator-facing), `health_state_changeset/2` (new, MetadataApply-internal per D-28).
- The great-error string for `validate_fingerprints_when_enabled` matches D-09 exactly (mentions both admin LiveView and Mix task per the D-22 recommendation).
- 11 Wave 0 stub test files exist so all later-wave plans can reference `<automated>mix test test/...</automated>` paths from day one.
- `mix test --exclude pending --warnings-as-errors` is green (no test stub flunks leak into the default suite).
- `mix compile --no-optional-deps --warnings-as-errors` stays green (CI lane invariant per engineering DNA §3).
</success_criteria>

<output>
After completion, create `.planning/phases/21-scheduled-metadata-refresh/21-01-SUMMARY.md` summarizing: migration filename + columns added, schema module changes (added field count + new changeset functions), test file additions and stub file count, and any deviations from the plan.
</output>