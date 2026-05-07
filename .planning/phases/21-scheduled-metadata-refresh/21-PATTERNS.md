# Phase 21: Scheduled metadata refresh - Pattern Map

**Mapped:** 2026-05-06
**Files analyzed:** 14 (7 new modules + 1 new mix task + 1 new optional ref handler + 1 new migration + 4 extended files)
**Analogs found:** 14 / 14 (every new file has at least one role-match analog inside the existing tree)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/relyra/metadata/scheduler.ex` (NEW) | service / coordinator | batch fan-out + correlation_id | `lib/relyra/ecto/bulk_actions.ex` | role-match (sequential per-batch + correlation_id; same shape) |
| `lib/relyra/metadata/auto_refresh.ex` (NEW) | service / wrapper | request-response (fetch → verify → parse → apply) | `lib/relyra/metadata/refresh.ex` | exact (this is the wrap target — D-05) |
| `lib/relyra/metadata/cadence.ex` (NEW) | utility (pure) | transform | `lib/relyra/security/algorithm_policy.ex` | role-match (pure-function policy module + module attr table) |
| `lib/relyra/metadata/failure_classifier.ex` (NEW) | utility (pure) | transform | `lib/relyra/security/algorithm_policy.ex` | role-match (per-input → struct/map classification with default fall-through) |
| `lib/relyra/metadata/backoff.ex` (NEW) | utility (pure) | transform | `lib/relyra/security/algorithm_policy.ex` | role-match (pure tier-table function) |
| `lib/relyra/metadata/drift_detector.ex` (NEW) | utility (pure) | transform | `lib/relyra/metadata/import.ex` (fingerprint compute at lines 87-94, 125-126) | role-match (fingerprint MapSet diff over candidate vs persisted state) |
| `lib/relyra/optional_deps/oban.ex` (NEW) | gateway / config | adapter probe | `lib/relyra/live_admin.ex` (LiveView gateway) | exact (canonical optional-deps gateway shape) |
| `lib/relyra/workers/metadata_refresh.ex` (NEW) | worker / adapter | event-driven (Oban job) | `lib/relyra/replay_store.ex` lines 65-88 (optional-adapter dispatch) + `lib/relyra/live_admin.ex` (gate-on-loaded module body) | role-match (gated-on-`Code.ensure_loaded?` body, single dispatch entry) |
| `lib/relyra/security/xml/corpus_gate.ex` (NEW) | service (security) | transform / refusal gate | `lib/relyra/security/xml.ex` (behaviour) + `test/security/xml/corpus_security_test.exs` (manifest reader) | partial (extract test-side manifest reader to runtime; per RESEARCH Q3) |
| `lib/relyra/telemetry/handlers/log_alerts.ex` (NEW; ~50 LOC) | reference handler (docs/examples surface) | event-driven (telemetry attach) | `lib/relyra/log.ex` (Logger wrapper + redaction) | role-match (small, redaction-aware logger) |
| `lib/mix/tasks/relyra.refresh_due.ex` (NEW) | mix task | request-response | `lib/mix/tasks/relyra.install.ex` | role-match (`use Mix.Task` + `OptionParser.parse` + `Mix.Task.run("app.start")`) |
| `lib/mix/tasks/relyra.metadata.pin.ex` (NEW; per D-22 recommendation) | mix task | request-response | `lib/mix/tasks/relyra.install.ex` | role-match (same `use Mix.Task` shell, calls into a domain function) |
| `priv/repo/migrations/<ts>_extend_metadata_source_for_auto_refresh.exs` (NEW) | migration | schema change | `priv/repo/migrations/20260506232319_add_allow_idp_initiated_to_relyra_connections.exs` | role-match (single `alter table` + adds boolean defaults; Phase 21 also adds a partial `create index ... where:`) |
| `lib/relyra/ecto/metadata_source.ex` (EXTENDED) | model / schema | CRUD | self (current schema is the analog) | exact (extend existing changeset/2 + add `auto_refresh_changeset/2` + `health_state_changeset/2` per RESEARCH) |
| `lib/relyra/ecto/metadata_apply.ex` (EXTENDED) | service / transactional apply seam | CRUD (transactional) | self (`record_attempt/3` + `apply_revision/4`) | exact (D-28: extend the same transaction with the health-state changeset; do NOT add a new audit-writer seam) |
| `lib/relyra/security/signature.ex` (EXTENDED) | service (security primitive) | transform | self (`verify/4` already rejects document-`KeyInfo` at lines 56-62) | exact (extend caller path or add a thin `verify_metadata_root/4` shim that reuses `do_verify`) |
| `lib/relyra/telemetry.ex` (EXTENDED) | catalog | n/a (doc-only) | self (existing `### metadata.refresh` section at lines 59-63) | exact (mirror catalog section + reuse `Telemetry.span/3`) |
| `lib/relyra/live_admin/connections_live.ex` (EXTENDED) | LiveView controller | request-response | self (`handle_event/3` audit pattern at lines 65, 110, 142, 166, 192, 419) | exact (audit_context helper at lines 594-596 is the pinning point) |
| `lib/relyra/live_admin/connection_metadata_live.ex` (EXTENDED) | LiveView controller | event-driven (start_async) | self (`refresh_metadata` handler + `start_async(:metadata_refresh, ...)` at lines 66-114) | exact (this is the explicit "Resume now" template per CONTEXT.md) |

## Pattern Assignments

### `lib/relyra/metadata/scheduler.ex` (service / coordinator, batch fan-out)

**Analog:** `lib/relyra/ecto/bulk_actions.ex` (entire file is 29 lines — copy the shape verbatim)

**Correlation-id + sequential fan-out** (lines 14-28):
```elixir
def run(repo, ids, action_fun, opts) do
  audit = Keyword.get(opts, :audit, %{})
  correlation_id = Map.get(audit, :correlation_id) || Ecto.UUID.generate()

  opts_with_audit = Keyword.put(opts, :audit, Map.put(audit, :correlation_id, correlation_id))
  opts_with_repo = Keyword.put_new(opts_with_audit, :repo, repo)

  results =
    Enum.map(ids, fn id -> {id, action_fun.(id, opts_with_repo)} end)
    |> Map.new()

  {:ok, results}
end
```

**Phase-21 delta:** `Scheduler.run_due(repo, opts)` does NOT receive `ids` — it queries the partial index for due rows, then loops sequentially through `Relyra.Metadata.AutoRefresh.refresh/2` (which itself wraps `Relyra.Metadata.Refresh.refresh/2`). The `correlation_id` line and the sequential `Enum.map` shape are copied verbatim. Add the `:skipped` telemetry event from D-07 when the due-query returns `[]`. Keep the cadence helper (`next_refresh_at/2`, `backoff_until/2`) inside this module per RESEARCH Pattern 2 — the resolver carries the **1-hour hard floor** (D-14) and the **±15% jitter** (D-12), each baked into a `defp apply_jitter/2`.

---

### `lib/relyra/metadata/auto_refresh.ex` (service / wrapper)

**Analog:** `lib/relyra/metadata/refresh.ex` (this is the wrap target — D-05)

**Imports + alias pattern** (lines 1-10):
```elixir
defmodule Relyra.Metadata.Refresh do
  @moduledoc false

  alias Relyra.Ecto.{Connection, MetadataApply, MetadataSource}
  alias Relyra.Error
  alias Relyra.Log
  alias Relyra.Metadata.{Import, Parser}
  alias Relyra.Telemetry

  @ecto_repo Ecto.Repo
```

**Telemetry-spanned `do_refresh` shape** (lines 28-30, span body returns `{result, metadata}`):
```elixir
Telemetry.span([:metadata, :refresh], metadata, fn ->
  do_refresh(connection, source, req, repo, opts, metadata)
end)
```

**Failure-recording pattern** (lines 99-125):
```elixir
defp record_refresh_failure(connection, source, repo, xml, error, outcome, opts) do
  _ = MetadataApply.record_attempt(
        connection.connection_id,
        %{
          metadata_source_id: source.id,
          source_kind: :remote_url,
          trigger: :manual_refresh,
          actor: Keyword.get(opts, :actor, "unknown"),
          cause: Keyword.get(opts, :cause, Atom.to_string(error.type)),
          outcome: outcome,
          ...
          trust_summary: %{status: "failed", error_code: error.type}
        },
        repo: repo
      )
  update_source(repo, source, outcome)
  Log.error("metadata refresh failed", connection_id: connection.connection_id, ...)
end
```

**Phase-21 deltas:**
1. Telemetry namespace becomes `[:metadata, :auto_refresh]` (which `Telemetry.span/3` will prepend `[:relyra, :saml]` to → `[:relyra, :saml, :metadata, :auto_refresh, :start | :stop | :exception]` per D-23). The existing `[:metadata, :refresh]` event is **untouched**.
2. `trigger: :manual_refresh` becomes `trigger: :scheduled_refresh`.
3. Insert (a) trust-anchor fingerprint check, (b) XMLDSig metadata-root verify (via `Relyra.Security.Signature.verify`), (c) post-parse pre-apply `Relyra.Security.XML.CorpusGate.check/1`, (d) `Relyra.Metadata.DriftDetector.diff/2` BEFORE delegating into the existing `Refresh.refresh/2` machinery. RESEARCH Pitfall 4 (XXE-before-verify) requires verify to run BEFORE `Parser.parse`.
4. `record_attempt/3` call gains health-state attrs computed via `FailureClassifier.classify/1` + `Backoff.backoff_until/2` — these flow into the **same transaction** per D-28 (see MetadataApply extension below).

---

### `lib/relyra/metadata/cadence.ex` / `failure_classifier.ex` / `backoff.ex` (utility, pure)

**Analog:** `lib/relyra/security/algorithm_policy.ex` (module-attr policy table + per-input clauses + default fall-through)

**Module-attribute policy table** (lines 6-14):
```elixir
@sha1_signature_methods MapSet.new([
                          "http://www.w3.org/2000/09/xmldsig#rsa-sha1",
                          ...
                        ])
@sha1_digest_methods MapSet.new([
                       "http://www.w3.org/2000/09/xmldsig#sha1",
                       ...
                     ])
```

**Default-via-helper struct constructor** (lines 29-47):
```elixir
@spec default() :: t()
def default do
  %__MODULE__{
    allowed_signature_methods: [...],
    allowed_digest_methods: [...],
    legacy_sha1: nil
  }
end
```

**Phase-21 deltas:**
- `cadence.ex`: copy the module-attr table shape (`@cadence_seconds %{hourly: 3_600, ...}` + `@hard_floor_seconds 3600` per RESEARCH Pattern 2). Public API: `next_refresh_at(cadence, base \\ DateTime.utc_now())` returning a jittered `DateTime.t()`. NO Ecto, NO I/O.
- `failure_classifier.ex`: per RESEARCH Pattern 3, one function-head per error code returning a 3-key map (`%{transient?, counts_toward_suspend?, alert_immediately?}`); fall-through clause `def classify(_other), do: unknown()`. Copy the "private constructor helper" shape from `AlgorithmPolicy.default/0`.
- `backoff.ex`: per RESEARCH Pattern 4, `@backoff_tiers_seconds [3_600, 21_600, 86_400]` + `backoff_until/2` returning a jittered `DateTime.t()`. ±10% jitter (D-25). Identical shape discipline to the cadence module — same `apply_jitter/2` helper can be co-located in `cadence.ex` and called from `backoff.ex`, OR each module owns its own copy if the planner prefers single-purpose modules.

---

### `lib/relyra/metadata/drift_detector.ex` (utility, pure)

**Analog:** `lib/relyra/metadata/import.ex` lines 85-94, 125-126 (fingerprint compute + per-cert facts)

**Fingerprint computation** (lines 87-94, 125-126):
```elixir
fingerprint_sha256 = sha256(pem)
case parse_certificate_facts(pem) do
  {:ok, facts} ->
    Map.merge(facts, %{pem: pem, fingerprint_sha256: fingerprint_sha256})
  ...
end
...
defp sha256(value) do
  :crypto.hash(:sha256, value) |> Base.encode16(case: :lower)
end
```

**Phase-21 delta:** Drift detector compares ONLY fingerprints (RESEARCH Pitfall 7 — never compare PEMs; whitespace re-fires false positives). Public API: `diff(candidate, source) :: {:ok, :no_drift} | {:drift, %{entity_id_changed?: bool, new_signing_certs: [fp], reason: :entity_id_drift | :new_signing_cert}}`. The `last_known_metadata_signing_certs` field on `MetadataSource` is already declared as `{:array, :string}` per RESEARCH Example A. Use `MapSet.difference(MapSet.new(candidate_fps), MapSet.new(source.last_known_metadata_signing_certs))`.

---

### `lib/relyra/optional_deps/oban.ex` (gateway, optional-deps)

**Analog:** `lib/relyra/live_admin.ex` (entire file is 34 lines — canonical gateway shape)

**Available?/ensure_available! gateway** (lines 1-34):
```elixir
defmodule Relyra.LiveAdmin do
  @moduledoc "Optional LiveView admin surface helpers."

  @live_view_modules [Phoenix.LiveView, Phoenix.LiveView.Router]

  @spec available?() :: boolean()
  def available? do
    Enum.all?(@live_view_modules, &Code.ensure_loaded?/1)
  end

  @spec ensure_available!() :: :ok
  def ensure_available! do
    if available?() do
      :ok
    else
      raise ArgumentError, missing_dependency_message()
    end
  end

  @spec missing_dependency_message() :: String.t()
  def missing_dependency_message do
    """
    [Relyra] Live admin requires Phoenix LiveView.
    Add the optional dependency to the host application:
        {:phoenix_live_view, "~> 1.1"}
    ...
    """
  end
end
```

**Phase-21 deltas:**
- Replace `[Phoenix.LiveView, Phoenix.LiveView.Router]` with `[Oban, Oban.Worker, Oban.Job, Oban.Plugins.Cron]`.
- Add `@compile {:no_warn_undefined, [Oban, Oban.Worker, Oban.Job, Oban.Plugins.Cron]}` (RESEARCH Pattern 1 + Pitfall 5 — without this, the `mix compile --no-optional-deps --warnings-as-errors` lane breaks).
- Replace `raise ArgumentError, ...` with `{:error, Relyra.Error.new(:optional_dependency_missing, ...)}` because Phase 21 callers expect the `{:ok, _} | {:error, %Relyra.Error{}}` discipline (RESEARCH Pattern 1 second example). The `available?/0` spec is identical.
- Module-name attribute `@oban_modules` mirrors the `@live_view_modules` style for line-by-line consistency.

---

### `lib/relyra/workers/metadata_refresh.ex` (worker / adapter, optional)

**Analog A:** `lib/relyra/replay_store.ex` lines 61-88 (optional-adapter dispatch with `Code.ensure_loaded?` + `function_exported?`)

**Adapter dispatch** (lines 65-84):
```elixir
defp dispatch_replay_store(adapter, operation, args)
     when is_atom(adapter) and is_atom(operation) and is_list(args) do
  if Code.ensure_loaded?(adapter) and function_exported?(adapter, operation, length(args)) do
    try do
      case apply(adapter, operation, args) do
        :ok -> :ok
        {:error, %Error{} = error} -> {:error, error}
        other -> {:error, invalid_adapter_result(adapter, operation, other)}
      end
    rescue
      exception ->
        {:error, adapter_dispatch_error(adapter, operation, Exception.message(exception))}
    ...
```

**Analog B:** `lib/relyra/live_admin/connection_metadata_live.ex` lines 1, 273-277 (`if Code.ensure_loaded?(...) do ... else ... end` module-body gate — the canonical "compile two bodies" shape):
```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Relyra.LiveAdmin.ConnectionMetadataLive do
    @moduledoc false
    use Phoenix.LiveView
    ...
  end
else
  defmodule Relyra.LiveAdmin.ConnectionMetadataLive do
    @moduledoc false
  end
end
```

**Phase-21 delta:** The worker must compile EITHER WAY (Pitfall 5). Use the inside-the-module branch shape from RESEARCH Pattern 1 (`if Code.ensure_loaded?(Oban.Worker) do use Oban.Worker, ... else def perform(_), do: ensure_available!() end`) so the module name `Relyra.Workers.MetadataRefresh` is always defined and `@compile {:no_warn_undefined, [Oban, Oban.Worker, Oban.Job]}` silences the absent-Oban compile warnings. `unique:` keys per D-03: `[period: :infinity, states: [:available, :scheduled, :executing], keys: [:source_id]]`. `max_attempts: 1` because Phase-21 owns its own backoff (RESEARCH "Don't Hand-Roll" row 3).

---

### `lib/relyra/security/xml/corpus_gate.ex` (service, security)

**Analog A:** `lib/relyra/security/xml.ex` (the existing security XML behaviour module — 30 lines):
```elixir
defmodule Relyra.Security.XML do
  @moduledoc "Hardened XML seam contract for trust-sensitive SAML handling."
  alias Relyra.Error

  @type xml_error_type ::
          :doctype_forbidden
          | :entity_expansion_forbidden
          | ...
          | :signature_wrapping_suspected
          | :canonicalization_failed
          | :untrusted_certificate
          | :unsigned_or_partial_signature
  ...
end
```

**Analog B:** `test/security/xml/corpus_security_test.exs` lines 1-15 (manifest reader — extract the read+parse helper to runtime per RESEARCH Q3):
```elixir
@manifest_path "test/fixtures/security/xml/manifest.json"

@tag :security_corpus
test "manifest.json fixtures map to expected_error_type for each class" do
  manifest()
  |> Enum.each(fn fixture ->
    assert {:error, %Error{type: type}} = evaluate_fixture(fixture)
    assert type == String.to_atom(fixture["expected_error_type"])
  end)
end
```

**Phase-21 delta:** Move `test/fixtures/security/xml/manifest.json` to `priv/security_corpus.json` (RESEARCH Q3 recommendation — extract). New `Relyra.Security.XML.CorpusGate.check/1` loads via `Application.app_dir(:relyra, "priv/security_corpus.json")` and returns `{:ok, :corpus_clean} | {:error, %Error{type: :corpus_violation, details: %{matched_fixture_id: id}}}`. The error type `:corpus_violation` is the typed `auto_suspended_reason` per D-21. Test corpus reader keeps pointing at the same manifest at the new path.

---

### `lib/relyra/telemetry/handlers/log_alerts.ex` (reference handler, ~50 LOC, docs/examples surface)

**Analog:** `lib/relyra/log.ex` (entire 60 lines — Logger wrapper + `@sensitive_keys` redaction list)

**Redaction-aware logger** (lines 1-44):
```elixir
defmodule Relyra.Log do
  @moduledoc false
  require Logger

  @sensitive_keys [:xml, :response_xml, :assertion_xml, ..., :certificate_pem, :pem]

  def info(message, metadata \\ []), do: Logger.info(format_message(message, metadata))
  def error(message, metadata \\ []), do: Logger.error(format_message(message, metadata))
  ...
  defp redact_value(key, _value) when key in @sensitive_keys, do: "[REDACTED]"
```

**Phase-21 delta:** New `Relyra.Telemetry.Handlers.LogAlerts.attach/0` calls `:telemetry.attach_many/4` to all five `[:relyra, :saml, :metadata, :auto_refresh, :*]` events and emits one `Logger.info` / `Logger.warning` / `Logger.error` line per event with redaction via `Relyra.Log` (do NOT re-implement redaction). Per D-30, this module ships in Relyra but is **NOT default-attached** — adopters call `LogAlerts.attach()` from their `Application.start/2`. RESEARCH Q4 + D-30 location: `lib/relyra/telemetry/handlers/log_alerts.ex` is fine; the README example demonstrates the attach call.

---

### `lib/mix/tasks/relyra.refresh_due.ex` and `lib/mix/tasks/relyra.metadata.pin.ex` (mix tasks)

**Analog:** `lib/mix/tasks/relyra.install.ex` (header + run callback, lines 1-22)

**Mix task header + arg parsing** (lines 1-21):
```elixir
defmodule Mix.Tasks.Relyra.Install do
  @moduledoc false
  use Mix.Task

  @shortdoc "Scaffold the minimal Relyra integration surface"

  @impl true
  def run(args) do
    {opts, _argv, _invalid} =
      OptionParser.parse(args,
        switches: [
          module: :string,
          ...
          force: :boolean
        ],
        aliases: [m: :module]
      )
    ...
```

**Phase-21 deltas:**
- `relyra.refresh_due.ex` per RESEARCH Example D: `Mix.Task.run("app.start")` then `OptionParser.parse(args, strict: [repo: :string])` then `Relyra.Metadata.Scheduler.run_due(repo, [])`. Replace the `@moduledoc false` with the documented moduledoc per the brief ("documented in moduledoc + idiomatic Mix.Task callback") so the task shows up under `mix help`.
- `relyra.metadata.pin.ex` (D-22 recommendation): `mix relyra.metadata.pin <source_id> --fingerprint <hex> [--repo MyApp.Repo]`. Internally calls one of the new public surface helpers on `Relyra.Metadata` that wraps `MetadataSource.auto_refresh_changeset/2` (RESEARCH Q1 — share one underlying changeset between LiveView and Mix task). Same `Mix.Task.run("app.start")` boot.

---

### `priv/repo/migrations/<ts>_extend_metadata_source_for_auto_refresh.exs` (migration)

**Analog:** `priv/repo/migrations/20260506232319_add_allow_idp_initiated_to_relyra_connections.exs`

**Single alter table + boolean default** (entire file, 9 lines):
```elixir
defmodule Relyra.Repo.Migrations.AddAllowIdpInitiatedToRelyraConnections do
  use Ecto.Migration

  def change do
    alter table(:relyra_connections) do
      add :allow_idp_initiated, :boolean, default: false, null: false
    end
  end
end
```

**Phase-21 delta:** Single `alter table(:relyra_metadata_sources)` adding all 13 fields per CONTEXT.md schema-additions table + RESEARCH Example B (which adds `last_validity_warning_for` per Pitfall 2 / RESEARCH Q2 = 14 columns total). All `null: false` defaults match the pattern. Then add the partial index per RESEARCH Pattern 5:
```elixir
create index(:relyra_metadata_sources, [:next_refresh_at],
         name: :relyra_metadata_sources_due_idx,
         where: "auto_refresh_enabled = true AND (auto_suspended_until IS NULL OR auto_suspended_until <= now())")
```
**Do NOT add `lock_version`** to MetadataSource (RESEARCH Example B note — row-level transaction in `record_attempt/3` already serializes writes).

---

### `lib/relyra/ecto/metadata_source.ex` (EXTENDED schema)

**Analog (self):** existing schema lines 1-65

**Existing schema shape with `Code.ensure_loaded?(Ecto.Schema)` gate** (lines 1-8, 16-31):
```elixir
if Code.ensure_loaded?(Ecto.Schema) do
  defmodule Relyra.Ecto.MetadataSource do
    @moduledoc false
    use Ecto.Schema
    import Ecto.Changeset
    alias Relyra.Ecto.Connection

    @primary_key {:id, :binary_id, autogenerate: true}
    @foreign_key_type :binary_id
    @kind_values [:remote_url]
    @outcome_values [:registered, :fetch_failed, :fetched, :applied, :parse_failed, :validation_failed, :apply_failed]

    schema "relyra_metadata_sources" do
      field :url, :string
      field :kind, Ecto.Enum, values: @kind_values
      ...
      belongs_to :connection, Connection,
        foreign_key: :connection_record_id,
        references: :id,
        type: :binary_id
      timestamps(type: :utc_datetime_usec)
    end
```

**Existing changeset** (lines 36-52):
```elixir
def changeset(source, attrs) do
  source
  |> cast(attrs, [:connection_record_id, :url, :kind, :registered_by, ...])
  |> validate_required([:connection_record_id, :url, :kind, :registered_by, :registered_reason])
  |> validate_change(:url, &validate_https_url/2)
  |> unique_constraint(:connection_record_id)
  |> foreign_key_constraint(:connection_record_id)
end
```

**Phase-21 deltas (per RESEARCH Example A):**
- Add 14 fields (the 13 from CONTEXT.md + `last_validity_warning_for` from Pitfall 2 / Q2). Use module attrs `@cadence_values [:hourly, :every_6h, :daily, :weekly]` and `@suspended_reason_values [...]` (mirroring `@kind_values` / `@outcome_values` shape).
- Split changesets into three: `changeset/2` (existing, unchanged), `auto_refresh_changeset/2` (operator-facing — opt-in fields), `health_state_changeset/2` (called ONLY from `MetadataApply.record_attempt/3` + `apply_revision/4` per D-28). RESEARCH Example A `validate_fingerprints_when_enabled/1` enforces D-09 great-error: cannot enable auto-refresh without at least one pinned fingerprint.

---

### `lib/relyra/ecto/metadata_apply.ex` (EXTENDED — D-28 single-transaction discipline)

**Analog (self):** `record_attempt/3` lines 63-89, `apply_revision/4` lines 9-52, transactional `transact/2` helper at lines 248-254

**Existing record_attempt shape** (lines 67-80):
```elixir
def record_attempt(connection_id, revision_attrs, opts)
    when is_binary(connection_id) and is_map(revision_attrs) and is_list(opts) do
  with {:ok, repo} <- fetch_repo(opts, :record_attempt),
       :ok <- ensure_optional_dependency!(:record_attempt, repo),
       {:ok, connection} <- fetch_connection(repo, connection_id, :record_attempt) do
    attrs =
      revision_attrs
      |> Map.put(:connection_record_id, connection.id)
      |> Map.put_new(:trust_summary, %{status: "attempt_recorded"})
      |> Map.update(:details, %{}, &redact_large_binaries/1)

    insert_revision(repo, attrs)
  end
end
```

**Existing transact helper** (lines 248-254):
```elixir
defp transact(repo, fun) do
  if function_exported?(repo, :transact, 1) do
    repo.transact(fun)
  else
    repo.transaction(fun)
  end
end
```

**Phase-21 deltas (D-28 is THE load-bearing discipline):**
- Wrap `record_attempt/3`'s `insert_revision/2` call in a `transact/2` block (match `apply_revision/4`'s pattern).
- Inside the transaction, after `insert_revision/2` succeeds, also apply `MetadataSource.health_state_changeset/2` and `repo.update/1` it. Health-state attrs are computed from `revision_attrs[:outcome]` + `FailureClassifier.classify/1` + `Backoff.backoff_until/2` (or, for success, reset counters per RESEARCH Pitfall 6).
- `apply_revision/4`'s success branch (lines 26-43) similarly co-commits the success-path health-state update (`consecutive_failure_count: 0`, `last_success_at: DateTime.utc_now()`, `auto_suspended_until: nil`, etc.).
- DO NOT add a new audit-writer seam — `AuditWriter.append_event` is called once per attempt as today; the health-state update is a sibling write inside the SAME transaction.

---

### `lib/relyra/security/signature.ex` (EXTENDED for metadata root)

**Analog (self):** existing `verify/4` — the trust primitive Phase 21 reuses

**Document-KeyInfo rejection** (lines 56-62):
```elixir
Map.get(parsed_doc, :key_info_trust) == true ->
  {:error,
   Error.new(
     :untrusted_certificate,
     "Document-provided KeyInfo cannot be used as a trust source",
     Map.put(details, :reason, :document_keyinfo_forbidden)
   )}
```

**Verify shell** (lines 8-34):
```elixir
@spec verify(map(), map(), [binary()], keyword()) :: {:ok, SignedNode.t()} | {:error, Error.t()}
def verify(parsed_doc, connection, cert_chain, opts \\ [])
def verify(parsed_doc, connection, cert_chain, opts)
    when is_map(parsed_doc) and is_map(connection) and is_list(cert_chain) and is_list(opts) do
  metadata = %{
    connection_id: Map.get(connection, :connection_id) || Map.get(connection, :id),
    flow: :sp_initiated
  }
  Relyra.Telemetry.span([:signature, :verify], metadata, fn ->
    result = do_verify(parsed_doc, connection, cert_chain, opts)
    case result do
      {:ok, signed_node} -> {{:ok, signed_node}, Map.merge(metadata, %{outcome: :ok, ...})}
      {:error, %Error{} = error} -> {{:error, error}, Map.merge(metadata, %{outcome: :error, error_code: error.type})}
    end
  end)
end
```

**Phase-21 delta (D-16):** The existing `verify/4` already enforces the trust posture. For metadata-root verification, the caller (`AutoRefresh`) needs a parsed-just-enough `parsed_doc` shape that exposes `:signed_candidates` rooted at `<EntityDescriptor>` / `<EntitiesDescriptor>` instead of `<Response>`/`<Assertion>`. Extension options:
1. Reuse `verify/4` as-is and have `AutoRefresh` build a metadata-root-shaped `parsed_doc` map (preferred; zero churn in `signature.ex`).
2. Add a thin `verify_metadata_root/4` shim that swaps `flow: :sp_initiated` for `flow: :metadata_refresh` in the telemetry metadata and otherwise calls `do_verify/4` verbatim.

Either shape preserves PROJECT.md's "no parser differentials" — one verifier path. **Trust anchor (D-17):** the `cert_chain` argument receives the operator-pinned PEMs resolved from `MetadataSource.metadata_trust_fingerprints` (NOT the IdP's assertion certs — D-17 explicit rejection).

---

### `lib/relyra/telemetry.ex` (EXTENDED catalog)

**Analog (self):** existing `### metadata.refresh` doc block + `Telemetry.span/3` emission helper

**Existing metadata.refresh catalog entry** (lines 59-63):
```elixir
### metadata.refresh
Emitted when an operator-triggered metadata refresh starts or stops.
- Namespace: `[:relyra, :saml, :metadata, :refresh]`
- Measurements: `[:duration_ms]`
- Metadata: `[:connection_id, :metadata_source_id, :source_kind, :trigger, :outcome, :error_code, :certificate_count]`
```

**span/3 emission (lines 78-106)** — already handles `{result, stop_metadata}` return shape; reuse verbatim.

**Phase-21 delta:** Add a new doc section `### metadata.auto_refresh` listing the `:start | :stop | :exception | :degraded | :suspended | :recovered | :validity_warning | :skipped` events (D-23, D-24, D-07) and document the metadata payload (`correlation_id, source_id, error_code, transient?, counts_toward_suspend?` per D-27 + RESEARCH A4). NO code changes — the `span/3` helper is already namespace-agnostic; callers pass `[:metadata, :auto_refresh]` and `Telemetry.span/3` prepends `[:relyra, :saml]` automatically (line 79).

---

### `lib/relyra/live_admin/connections_live.ex` (EXTENDED, micro-badge)

**Analog (self):** `audit_context/2` helper at lines 594-596 + bulk-action handler at lines 106-131

**audit_context helper** (lines 594-596):
```elixir
defp audit_context(%Scope{} = scope, cause) do
  %{actor: scope.actor, cause: cause}
end
```

**Existing bulk-action handler with cause naming** (line 110):
```elixir
audit = audit_context(scope, "live_admin_bulk_#{action}")
```

**Phase-21 deltas (D-29):**
- The micro-badge surface lives inside the `Relyra.LiveAdmin.Components.ConnectionList` component (lines 19-35 of `connection_list.ex` show the per-row `<li>` block where the existing `connection.status` text lives — append a sibling badge `:if={connection.auto_refresh_health in [:degraded, :suspended]}` rendering with amber/red inline styles consistent with the existing `font-size: 12px; color: #666;` line).
- The `Query.list_connections/2` call at line 41-42 already returns connections; extend the query to preload (or join) the latest `MetadataSource` health fields so `connection.auto_refresh_health` is available to the component without N+1.
- No new `handle_event/3` here; the "Resume now" button lives on the metadata page (next section).

---

### `lib/relyra/live_admin/connection_metadata_live.ex` (EXTENDED, "Resume now")

**Analog (self):** `refresh_metadata` handler + `start_async(:metadata_refresh, ...)` at lines 66-114

**Existing event handler that opens a start_async** (lines 66-85):
```elixir
def handle_event("refresh_metadata", _params, socket) do
  opts =
    [
      repo: socket.assigns.relyra_admin_repo,
      actor: socket.assigns.admin_scope.actor,
      cause: "live_admin_metadata_refresh"
    ]
    |> maybe_put_req(socket.assigns.relyra_admin_req)

  connection_id = socket.assigns.connection_id

  socket =
    socket
    |> assign(:refresh_status, :loading)
    |> start_async(:metadata_refresh, fn ->
      Metadata.refresh(connection_id, opts)
    end)

  {:noreply, socket}
end
```

**Existing handle_async pattern** (lines 88-114):
```elixir
def handle_async(:metadata_refresh, {:ok, {:ok, _result}}, socket) do
  socket = socket |> assign(:refresh_status, :idle) |> put_flash(:info, "Metadata refresh completed.") |> reload_detail()
  {:noreply, socket}
end

def handle_async(:metadata_refresh, {:ok, {:error, error}}, socket) do
  socket = socket |> assign(:refresh_status, :idle) |> put_flash(:error, error.message)
  {:noreply, socket}
end
```

**Phase-21 deltas (D-29 + D-35 + RESEARCH Pitfall 3):**
- Add `handle_event("resume_auto_refresh", _params, socket)` that mirrors the `refresh_metadata` shape but with `cause: "live_admin_auto_refresh_resume"` (RESEARCH A3 — exact string), and dispatches a one-shot probe via `Relyra.Metadata.Scheduler.run_due(repo, source_ids: [source_id], audit: audit)` (or a dedicated `Scheduler.resume_now/3`).
- Per Pitfall 3, the audit row + clearing `auto_suspended_until` + Oban job insert all happen inside ONE transaction via `MetadataApply.record_attempt/3` (outcome `:resume_requested`). The job dispatch itself is outside the transaction; Oban's `unique:` constraint absorbs concurrent ticks.
- Use `start_async(:auto_refresh_resume, fn -> ... end)` with the same disabled-button-while-loading pattern as `refresh_metadata` at line 162 of the existing render.
- The "Auto-refresh health" card is a new render section above the existing revision table (line 171) showing schedule preset, `last_success_at`, `consecutive_failure_count`, current state, `last_failure_error_code`, and the "Resume now" button (only when `assigns.metadata_source.auto_suspended_until != nil`).

---

## Shared Patterns

### Pattern: `Code.ensure_loaded?` module-body gate (compile two bodies)

**Source:** `lib/relyra/live_admin/connection_metadata_live.ex` lines 1, 273-277; `lib/relyra/ecto/metadata_source.ex` lines 1, 66-70
**Apply to:** `optional_deps/oban.ex`, `workers/metadata_refresh.ex`, every new schema module (none in Phase 21 beyond extensions), and any LiveView component touching the new health card

```elixir
if Code.ensure_loaded?(Ecto.Schema) do
  defmodule Relyra.Ecto.MetadataSource do
    @moduledoc false
    use Ecto.Schema
    ...
  end
else
  defmodule Relyra.Ecto.MetadataSource do
    @moduledoc false
  end
end
```

### Pattern: `{:ok, _} | {:error, %Relyra.Error{}}` return contract

**Source:** `lib/relyra/error.ex` (the `Relyra.Error` struct), used uniformly across `lib/relyra/metadata/refresh.ex:11-12`, `lib/relyra/ecto/metadata_apply.ex:9-10`, `lib/relyra/security/signature.ex:8-9`
**Apply to:** Every public function in `Scheduler`, `AutoRefresh`, `OptionalDeps.Oban`, `CorpusGate`, `DriftDetector`. NO exceptions for control flow.

```elixir
@spec refresh(binary(), keyword()) :: {:ok, struct()} | {:error, Error.t()}
```

### Pattern: Audit context dictionary `%{actor:, cause:, correlation_id:}`

**Source:** `lib/relyra/live_admin/connections_live.ex:594-596` + `lib/relyra/ecto/bulk_actions.ex:14-19`
**Apply to:** Every operator-action call that flows through `MetadataApply.record_attempt/3`. The `cause` strings follow the `live_admin_<action>` convention (lines 65, 110, 142, 166, 192). Phase 21's Resume-now cause is `"live_admin_auto_refresh_resume"` (A3).

### Pattern: `Telemetry.span/3` with `{result, stop_metadata}` return

**Source:** `lib/relyra/telemetry.ex:78-106` (existing helper) + `lib/relyra/metadata/refresh.ex:28-30` (call site) + `lib/relyra/security/signature.ex:18-33` (call site)
**Apply to:** Every new emission in `AutoRefresh` and `Scheduler`. The helper auto-prepends `[:relyra, :saml]`, so callers pass `[:metadata, :auto_refresh]`.

```elixir
Telemetry.span([:metadata, :auto_refresh], metadata, fn ->
  result = do_work(...)
  case result do
    {:ok, val} -> {{:ok, val}, Map.merge(metadata, %{outcome: :ok})}
    {:error, %Error{} = err} -> {{:error, err}, Map.merge(metadata, %{outcome: :error, error_code: err.type})}
  end
end)
```

### Pattern: SHA-256 fingerprint compute (never re-implement)

**Source:** `lib/relyra/metadata/import.ex:125-126`
```elixir
defp sha256(value) do
  :crypto.hash(:sha256, value) |> Base.encode16(case: :lower)
end
```
**Apply to:** `DriftDetector` (cert-fp diff), `metadata.pin` Mix task (display fingerprint preview), trust-anchor pinning UX. RESEARCH "Don't Hand-Roll" row 5.

### Pattern: Single audit-writer seam (D-35)

**Source:** `lib/relyra/ecto/metadata_apply.ex:340-356` (the only `AuditWriter.append_event` call in the metadata domain)
**Apply to:** Phase 21 introduces ZERO new `AuditWriter.append_event` call sites. All counter / state mutations co-commit inside `record_attempt/3` and `apply_revision/4`'s existing `transact/2` block (D-28).

### Pattern: Escape-hatch struct shape `%{allow_until:, reason:, audit:}`

**Source:** `lib/relyra/security/algorithm_policy.ex:18-21` (`legacy_sha1_override` type)
```elixir
@type legacy_sha1_override :: %{
        reason: String.t(),
        expires_at: DateTime.t()
      }
```
**Apply to:** `legacy_unsigned_metadata_policy` field on `MetadataSource` (D-19). Same shape: `%{reason: String.t(), allow_until: Date.t(), audit: boolean()}`. Time-boxed + audited + surfaced in `RiskPanel` UX.

---

## No Analog Found

**None.** Every new file in Phase 21 has at least one role-match analog already in the tree. RESEARCH §"Don't Hand-Roll" (line 565) confirms: "Phase 21 introduces zero new 'build it from scratch' subsystems."

---

## Metadata

**Analog search scope:**
- `lib/relyra/metadata/` (refresh, parser, import, candidate, source_registry)
- `lib/relyra/ecto/` (bulk_actions, metadata_source, metadata_apply, audit_writer, connection, connection/runtime_policy, certificate, certificate_inventory)
- `lib/relyra/security/` (signature, algorithm_policy, xml, xml/pure_beam)
- `lib/relyra/live_admin/` (connections_live, connection_metadata_live, components/connection_list, components/risk_panel)
- `lib/relyra/` top-level (live_admin, replay_store, connection_resolver, telemetry, log)
- `lib/mix/tasks/` (relyra.install, hex.audit)
- `priv/repo/migrations/` (single-column add precedent)
- `test/security/xml/corpus_security_test.exs` + `test/fixtures/security/xml/manifest.json`

**Files scanned (read in full or with targeted ranges):** 19

**Pattern extraction date:** 2026-05-06

## PATTERN MAPPING COMPLETE
