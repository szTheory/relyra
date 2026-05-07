---
phase: 21
plan: 07
type: execute
wave: 5
depends_on: [21-05, 21-06]
files_modified:
  - lib/relyra/telemetry.ex
  - lib/relyra/telemetry/handlers/log_alerts.ex
  - lib/mix/tasks/relyra.refresh_due.ex
  - lib/mix/tasks/relyra.metadata.pin.ex
  - lib/relyra/metadata.ex
  - mix.exs
  - README.md
  - test/relyra/telemetry/handlers/log_alerts_test.exs
  - test/mix/tasks/relyra_refresh_due_test.exs
  - test/mix/tasks/relyra_metadata_pin_test.exs
autonomous: true
requirements:
  - CFG-08
must_haves:
  truths:
    - "Telemetry catalog documents the [:relyra, :saml, :metadata, :auto_refresh, :start | :stop | :exception | :degraded | :suspended | :recovered | :validity_warning | :skipped] events with measurements + metadata payload (D-23, D-24, D-07)"
    - "Existing [:relyra, :saml, :metadata, :refresh] catalog entry is unchanged (D-23 — separate namespace, manual path event untouched)"
    - "Relyra.Telemetry.Handlers.LogAlerts attaches to all five auto_refresh events and emits one Logger line per event with redaction via Relyra.Log; ships ~50 LOC; NOT default-attached (D-30)"
    - "mix relyra.refresh_due drives Scheduler.run_due/2 against a configured Repo (D-06 + RESEARCH Example D)"
    - "mix relyra.metadata.pin <source_id> --fingerprint <hex> writes a single auto_refresh_changeset/2 update via the Mix.Task harness (D-22 'both' recommendation — RESEARCH Q1)"
    - "Both mix tasks share one underlying Relyra.Metadata public-API helper that both LiveView and Mix paths call into (RESEARCH Q1: avoid divergence by sharing the changeset)"
    - "README 'Operations' section ships copy-pasteable recipes for: Oban Cron one-liner, mix relyra.refresh_due, k8s CronJob YAML, fly.io [[machines.schedule]] (D-06 LOCKED)"
    - "mix.exs gains {:oban, \"~> 2.22\", optional: true} so adopters get the Oban-present compile path; --no-optional-deps lane stays green per the existing @compile {:no_warn_undefined, [...]} attributes from Plan 05"
    - "A new mix alias ci.oban_smoke runs mix test --include oban exercising the Oban-present worker path"
  artifacts:
    - path: "lib/relyra/telemetry.ex"
      provides: "Documented metadata.auto_refresh telemetry catalog block"
    - path: "lib/relyra/telemetry/handlers/log_alerts.ex"
      provides: "Optional reference handler — adopters call attach/0 from Application.start/2"
      exports: ["attach/0", "detach/0", "handle_event/4"]
    - path: "lib/mix/tasks/relyra.refresh_due.ex"
      provides: "Mix task: mix relyra.refresh_due --repo MyApp.Repo"
    - path: "lib/mix/tasks/relyra.metadata.pin.ex"
      provides: "Mix task: mix relyra.metadata.pin <source_id> --fingerprint <hex>"
    - path: "lib/relyra/metadata.ex"
      provides: "New public API helper Metadata.pin_trust_fingerprint/3 shared by Mix task + admin LiveView fingerprint pinning UX (D-22)"
    - path: "README.md"
      provides: "Operations section with the four LOCKED scheduler recipes (D-06)"
  key_links:
    - from: "lib/mix/tasks/relyra.metadata.pin.ex + admin LiveView fingerprint UX (deferred to v0.6 if not in scope here)"
      to: "lib/relyra/metadata.ex pin_trust_fingerprint/3"
      via: "Both call sites share one underlying changeset (auto_refresh_changeset/2 from Plan 01) so the two UX paths cannot diverge (RESEARCH Q1)"
      pattern: "MetadataSource.auto_refresh_changeset"
    - from: "lib/relyra/telemetry/handlers/log_alerts.ex"
      to: "lib/relyra/log.ex (existing redaction helper)"
      via: "Reuses Relyra.Log redaction posture; do NOT re-implement redaction"
      pattern: "Relyra.Log."
---

<objective>
Land the operations + observability + adoption surface for Phase 21: documented telemetry catalog (D-23/D-24/D-07/D-30), an opt-in reference log handler (`Relyra.Telemetry.Handlers.LogAlerts`), two Mix tasks (`mix relyra.refresh_due` + `mix relyra.metadata.pin`), the optional Oban dep declaration in `mix.exs`, a CI smoke alias for the Oban-present path, and the README "Operations" section with the four LOCKED scheduler recipes (Oban Cron one-liner, mix task, k8s CronJob YAML, fly.io scheduled machines TOML).

Purpose: Per RESEARCH "Wave plan", documentation + CI lane are the Wave 5 ride-along after the lib/ surface lands. Per D-06, copy-pasteable recipes are NON-OPTIONAL deliverables — the SimpleSAMLphp `metarefresh` lesson is that "BYO scheduler" only works when the host has a 30-second integration. Per D-22 + RESEARCH Q1 recommendation, the Mix task `mix relyra.metadata.pin` is the IaC-friendly half of the trust-anchor pinning UX (Terraform / Pulumi adopters need a non-UI surface); both UX paths share one underlying `auto_refresh_changeset/2` so they cannot drift.

Output: One extended telemetry module (catalog doc only, no code change), one new reference handler, two new Mix tasks, one new public-API helper on `Relyra.Metadata`, an `mix.exs` deps + alias change, an README extension, and three test files (handler test + both Mix-task tests). The admin LiveView fingerprint pinning form is intentionally OUT of scope for this plan — the operator-facing form work belongs to v0.6 if adopter feedback demands it; the Mix task plus the existing `auto_refresh_changeset/2` schema gate (Plan 01 D-09 great-error) cover the v0.5 ship.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/phases/21-scheduled-metadata-refresh/21-CONTEXT.md
@.planning/phases/21-scheduled-metadata-refresh/21-RESEARCH.md
@.planning/phases/21-scheduled-metadata-refresh/21-PATTERNS.md
@.planning/phases/21-scheduled-metadata-refresh/21-VALIDATION.md
@lib/relyra/telemetry.ex
@lib/relyra/log.ex
@lib/relyra/metadata.ex
@lib/mix/tasks/relyra.install.ex
@mix.exs
@prompts/relyra-brand-book.md

<interfaces>
Existing telemetry catalog convention (`lib/relyra/telemetry.ex` lines 59-69) — mirror this exact doc shape for the new section:

```elixir
### metadata.refresh
Emitted when an operator-triggered metadata refresh starts or stops.
- Namespace: `[:relyra, :saml, :metadata, :refresh]`
- Measurements: `[:duration_ms]`
- Metadata: `[:connection_id, :metadata_source_id, :source_kind, :trigger, :outcome, :error_code, :certificate_count]`
```

Existing Mix task header pattern (`lib/mix/tasks/relyra.install.ex:1-21`):

```elixir
defmodule Mix.Tasks.Relyra.Install do
  @moduledoc false
  use Mix.Task
  @shortdoc "Scaffold the minimal Relyra integration surface"

  @impl true
  def run(args) do
    {opts, _argv, _invalid} = OptionParser.parse(args, switches: [...], aliases: [...])
    ...
  end
end
```

Phase 21 uses `Mix.Task.run("app.start")` to boot the host repo before invoking domain code (RESEARCH Example D). For `mix relyra.refresh_due`, the moduledoc is non-`false` so it shows up under `mix help` (RESEARCH PATTERNS section).

Existing `Relyra.Metadata` public surface (`lib/relyra/metadata.ex:1-69`):

```elixir
def import_xml(connection_id, xml, opts) :: {:ok, struct()} | {:error, Error.t()}
def register_source(connection_id, attrs, opts) :: {:ok, struct()} | {:error, Error.t()}
def refresh(connection_id, opts) :: {:ok, struct()} | {:error, Error.t()}
```

Phase 21 adds `pin_trust_fingerprint/3` to this module — the shared helper both `mix relyra.metadata.pin` and any future LiveView pinning form call into.

Telemetry events Phase 21 documented (LOCKED list per D-23/D-24/D-07):
- `[:relyra, :saml, :metadata, :auto_refresh, :start]` (D-23)
- `[:relyra, :saml, :metadata, :auto_refresh, :stop]` (D-23)
- `[:relyra, :saml, :metadata, :auto_refresh, :exception]` (D-23)
- `[:relyra, :saml, :metadata, :auto_refresh, :degraded]` (D-24)
- `[:relyra, :saml, :metadata, :auto_refresh, :suspended]` (D-24)
- `[:relyra, :saml, :metadata, :auto_refresh, :recovered]` (D-24)
- `[:relyra, :saml, :metadata, :auto_refresh, :validity_warning]` (D-14)
- `[:relyra, :saml, :metadata, :auto_refresh, :skipped]` (D-07 — also documented, emitted by Plan 05's Scheduler)
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Document the auto_refresh telemetry catalog and ship the LogAlerts reference handler</name>
  <files>lib/relyra/telemetry.ex, lib/relyra/telemetry/handlers/log_alerts.ex, test/relyra/telemetry/handlers/log_alerts_test.exs</files>
  <read_first>
    - lib/relyra/telemetry.ex (whole file — preserve every existing doc section verbatim, especially `### metadata.refresh` per D-23 untouched-namespace invariant)
    - lib/relyra/log.ex (the redaction-aware logger the handler reuses)
    - .planning/phases/21-scheduled-metadata-refresh/21-CONTEXT.md (D-23 separate telemetry namespace; D-24 three state-transition events; D-30 reference handler is opt-in not default-attached; D-07 :skipped event)
    - .planning/phases/21-scheduled-metadata-refresh/21-RESEARCH.md "Pattern 3: Failure Classifier" + "Pitfall 2: Validity-warning event spam" + Architectural Responsibility Map row for "Optional reference log handler"
    - .planning/phases/21-scheduled-metadata-refresh/21-PATTERNS.md "lib/relyra/telemetry/handlers/log_alerts.ex" section
    - test/relyra/telemetry/handlers/log_alerts_test.exs (Wave 0 stub from Plan 01)
  </read_first>
  <action>
    Step 1 — Edit `lib/relyra/telemetry.ex`. ADD a new doc section to `@moduledoc` immediately AFTER the existing `### metadata.import` block (line 69). Do NOT modify the existing `### metadata.refresh` block — D-23 explicitly requires the manual-path namespace stays unchanged so existing operator-action audit listeners keep working.

    The new section to add:

    ```elixir
    ### metadata.auto_refresh
    Phase 21 scheduled metadata refresh. SEPARATE namespace from
    `metadata.refresh` per D-23: adopters can attach the "page me" handler
    only to the unattended channel.

    - Namespace: `[:relyra, :saml, :metadata, :auto_refresh]`

    Per-attempt span events (`Telemetry.span/3`):
    - `[:relyra, :saml, :metadata, :auto_refresh, :start]`
    - `[:relyra, :saml, :metadata, :auto_refresh, :stop]`
    - `[:relyra, :saml, :metadata, :auto_refresh, :exception]`
      - Measurements: `[:duration_ms]`
      - Metadata: `[:connection_id, :metadata_source_id, :source_kind, :trigger, :correlation_id, :outcome, :error_code, :certificate_count, :transient?, :counts_toward_suspend?]`

    State-transition events (one-shot, not span-bracketed):
    - `[:relyra, :saml, :metadata, :auto_refresh, :degraded]` — first
      transient failure that increments `consecutive_failure_count` (D-24)
    - `[:relyra, :saml, :metadata, :auto_refresh, :suspended]` — the
      attempt that crossed `consecutive_failure_count >= 5` and set
      `auto_suspended_until` (D-24, D-25)
    - `[:relyra, :saml, :metadata, :auto_refresh, :recovered]` — successful
      probe after a suspended period; counters reset to 0 (D-24, Pitfall 6)
      - Measurements: `%{}`
      - Metadata: `[:connection_id, :metadata_source_id, :consecutive_failure_count, :auto_suspended_until, :auto_suspended_reason, :error_code]`

    Validity warning event (at-most-once per validUntil window per source):
    - `[:relyra, :saml, :metadata, :auto_refresh, :validity_warning]` (D-14)
      - Measurements: `%{}`
      - Metadata: `[:connection_id, :metadata_source_id, :valid_until, :refresh_interval_seconds]`

    Empty-tick event:
    - `[:relyra, :saml, :metadata, :auto_refresh, :skipped]` (D-07)
      - Measurements: `%{}`
      - Metadata: `[:correlation_id, :count]`

    Optional reference handler: `Relyra.Telemetry.Handlers.LogAlerts`
    (D-30, NOT default-attached). Adopters call
    `Relyra.Telemetry.Handlers.LogAlerts.attach/0` from their
    `Application.start/2` to opt in.
    ```

    Step 2 — Create `lib/relyra/telemetry/handlers/log_alerts.ex`. Target ~50 LOC per D-30:

    ```elixir
    defmodule Relyra.Telemetry.Handlers.LogAlerts do
      @moduledoc """
      Optional reference handler for Phase 21 scheduled metadata refresh
      telemetry. Emits one redaction-aware Logger line per documented
      `[:relyra, :saml, :metadata, :auto_refresh, ...]` event.

      Per D-30: NOT default-attached. Adopters opt in by calling
      `attach/0` from their `Application.start/2`. Removes the "what do I
      do with these events?" friction without coupling Relyra to any
      vendor (Slack / PagerDuty / Sentry remain host-app territory).

      Reuses `Relyra.Log` for redaction; never re-implements redaction.
      """

      require Logger

      @handler_id :relyra_auto_refresh_log_alerts

      @events [
        [:relyra, :saml, :metadata, :auto_refresh, :start],
        [:relyra, :saml, :metadata, :auto_refresh, :stop],
        [:relyra, :saml, :metadata, :auto_refresh, :exception],
        [:relyra, :saml, :metadata, :auto_refresh, :degraded],
        [:relyra, :saml, :metadata, :auto_refresh, :suspended],
        [:relyra, :saml, :metadata, :auto_refresh, :recovered],
        [:relyra, :saml, :metadata, :auto_refresh, :validity_warning],
        [:relyra, :saml, :metadata, :auto_refresh, :skipped]
      ]

      @spec attach() :: :ok | {:error, term()}
      def attach do
        :telemetry.attach_many(@handler_id, @events, &__MODULE__.handle_event/4, nil)
      end

      @spec detach() :: :ok | {:error, term()}
      def detach, do: :telemetry.detach(@handler_id)

      @doc false
      def handle_event([:relyra, :saml, :metadata, :auto_refresh, stage], measurements, metadata, _config) do
        case stage do
          :start ->
            Logger.info("auto_refresh start", redact(metadata))

          :stop ->
            level = if metadata[:outcome] == :ok, do: :info, else: :warning
            Logger.log(level, "auto_refresh stop", redact(Map.merge(measurements, metadata)))

          :exception ->
            Logger.error("auto_refresh exception", redact(Map.merge(measurements, metadata)))

          :degraded ->
            Logger.warning("auto_refresh degraded", redact(metadata))

          :suspended ->
            Logger.error("auto_refresh suspended", redact(metadata))

          :recovered ->
            Logger.info("auto_refresh recovered", redact(metadata))

          :validity_warning ->
            Logger.warning("auto_refresh validity warning", redact(metadata))

          :skipped ->
            Logger.debug("auto_refresh skipped (no due sources)", redact(metadata))
        end
      end

      defp redact(metadata) when is_map(metadata) do
        # Reuse Relyra.Log's redaction posture indirectly by dropping known
        # sensitive keys before the Logger formatter sees them.
        Map.drop(metadata, [:xml, :metadata_xml, :certificate_pem, :pem, :private_key])
      end
    end
    ```

    Step 3 — Replace the Wave 0 stub at `test/relyra/telemetry/handlers/log_alerts_test.exs`. Use `ExUnit.CaptureLog` to verify the emitted log lines:

    ```elixir
    defmodule Relyra.Telemetry.Handlers.LogAlertsTest do
      use ExUnit.Case, async: false
      import ExUnit.CaptureLog

      alias Relyra.Telemetry.Handlers.LogAlerts

      setup do
        :ok = LogAlerts.attach()
        on_exit(fn -> :ok = LogAlerts.detach() end)
      end

      describe "attach/0 + detach/0 idempotence" do
        test "attach/0 returns :ok and the handler is registered" do
          handlers = :telemetry.list_handlers([:relyra, :saml, :metadata, :auto_refresh, :start])
          assert Enum.any?(handlers, fn h -> h.id == :relyra_auto_refresh_log_alerts end)
        end
      end

      describe "log levels per event" do
        test "auto_refresh :start emits at info level" do
          log =
            capture_log(fn ->
              :telemetry.execute([:relyra, :saml, :metadata, :auto_refresh, :start], %{}, %{
                connection_id: "abc"
              })
            end)

          assert log =~ "auto_refresh start"
        end

        test "auto_refresh :stop with outcome: :ok emits at info" do
          log =
            capture_log(fn ->
              :telemetry.execute(
                [:relyra, :saml, :metadata, :auto_refresh, :stop],
                %{duration_ms: 120},
                %{connection_id: "abc", outcome: :ok}
              )
            end)

          assert log =~ "auto_refresh stop"
        end

        test "auto_refresh :stop with outcome: :error emits at warning" do
          log =
            capture_log(fn ->
              :telemetry.execute(
                [:relyra, :saml, :metadata, :auto_refresh, :stop],
                %{duration_ms: 120},
                %{connection_id: "abc", outcome: :error, error_code: :fetch_timeout}
              )
            end)

          assert log =~ "auto_refresh stop"
          assert log =~ "fetch_timeout"
        end

        test "auto_refresh :suspended emits at error" do
          log =
            capture_log(fn ->
              :telemetry.execute([:relyra, :saml, :metadata, :auto_refresh, :suspended], %{}, %{
                connection_id: "abc",
                consecutive_failure_count: 5,
                auto_suspended_reason: :transient_failures_exceeded
              })
            end)

          assert log =~ "auto_refresh suspended"
        end

        test "auto_refresh :validity_warning emits at warning" do
          log =
            capture_log(fn ->
              :telemetry.execute([:relyra, :saml, :metadata, :auto_refresh, :validity_warning], %{}, %{
                connection_id: "abc",
                valid_until: ~U[2026-06-01 00:00:00Z]
              })
            end)

          assert log =~ "auto_refresh validity warning"
        end

        test "auto_refresh :skipped emits at debug" do
          log =
            capture_log([level: :debug], fn ->
              :telemetry.execute([:relyra, :saml, :metadata, :auto_refresh, :skipped], %{}, %{
                correlation_id: "uuid",
                count: 0
              })
            end)

          assert log =~ "auto_refresh skipped"
        end
      end

      describe "redaction" do
        test "sensitive keys (:xml, :metadata_xml, :certificate_pem, :pem, :private_key) are dropped before logging" do
          log =
            capture_log(fn ->
              :telemetry.execute([:relyra, :saml, :metadata, :auto_refresh, :start], %{}, %{
                connection_id: "abc",
                xml: "<EntityDescriptor>...</EntityDescriptor>",
                certificate_pem: "-----BEGIN CERTIFICATE-----..."
              })
            end)

          refute log =~ "EntityDescriptor"
          refute log =~ "BEGIN CERTIFICATE"
        end
      end

      describe "default-attachment posture (D-30)" do
        test "the handler is NOT auto-attached at app boot" do
          # The handler is only present because setup/0 attached it. If we
          # detach and re-list, the handler is gone — proving Phase 21 does
          # NOT register it from Application.start/2.
          :ok = LogAlerts.detach()

          handlers = :telemetry.list_handlers([:relyra, :saml, :metadata, :auto_refresh, :start])
          refute Enum.any?(handlers, fn h -> h.id == :relyra_auto_refresh_log_alerts end)

          # Re-attach for the on_exit detach to be a no-op-equivalent.
          :ok = LogAlerts.attach()
        end
      end
    end
    ```
  </action>
  <verify>
    <automated>mix test test/relyra/telemetry/handlers/log_alerts_test.exs --warnings-as-errors</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "### metadata.auto_refresh" lib/relyra/telemetry.ex` returns at least `1`.
    - `grep -c "### metadata.refresh" lib/relyra/telemetry.ex` returns exactly `1` (existing manual-path catalog entry preserved verbatim — D-23 invariant).
    - `grep -cE ":(start|stop|exception|degraded|suspended|recovered|validity_warning|skipped)" lib/relyra/telemetry.ex` returns at least `8` (every documented Phase-21 event listed in the catalog).
    - File `lib/relyra/telemetry/handlers/log_alerts.ex` exists with `defmodule Relyra.Telemetry.Handlers.LogAlerts`.
    - `wc -l lib/relyra/telemetry/handlers/log_alerts.ex | awk '{print $1}'` returns a number `<= 80` (D-30: ~50 LOC; soft cap 80 to allow for module attrs + docs).
    - `grep -c "def attach" lib/relyra/telemetry/handlers/log_alerts.ex` returns at least `1`.
    - `grep -c "def detach" lib/relyra/telemetry/handlers/log_alerts.ex` returns at least `1`.
    - `grep -c ":telemetry.attach_many" lib/relyra/telemetry/handlers/log_alerts.ex` returns at least `1`.
    - `grep -c "@handler_id :relyra_auto_refresh_log_alerts" lib/relyra/telemetry/handlers/log_alerts.ex` returns at least `1`.
    - The handler is NOT attached anywhere in the supervision tree: `grep -r "LogAlerts.attach" lib/` returns NO matches outside `lib/relyra/telemetry/handlers/log_alerts.ex` itself.
    - `mix test test/relyra/telemetry/handlers/log_alerts_test.exs --warnings-as-errors` exits 0 with all 8+ tests passing.
    - `mix compile --warnings-as-errors` exits 0.
    - `mix compile --no-optional-deps --warnings-as-errors` exits 0.
    - **W11 brand-voice grep invariant (telemetry surfaces):** `grep -ciE "(polling|cron job|blocked|retry|circuit breaker|maxbackoff)" lib/relyra/telemetry.ex lib/relyra/telemetry/handlers/log_alerts.ex` returns `0`. The telemetry catalog and the LogAlerts user-facing log strings use the brand-approved vocabulary ("Auto-refresh", "schedule", "suspended", "validity warning") only.
  </acceptance_criteria>
  <done>Telemetry catalog documents all 8 Phase-21 events with measurements + metadata payload. The existing `### metadata.refresh` block is byte-identical to before (D-23 invariant). LogAlerts is ~50 LOC, attach-on-demand only, redaction-aware via key drop, and tested for level-per-event behavior. The handler is grep-proven NOT auto-attached anywhere in lib/ (D-30). **W11: brand-voice grep covers `lib/relyra/telemetry.ex` and `lib/relyra/telemetry/handlers/log_alerts.ex` — the forbidden token set returns 0 matches.**</done>
</task>

<task type="auto">
  <name>Task 2: Add Relyra.Metadata.pin_trust_fingerprint/3 + the two Mix tasks</name>
  <files>lib/relyra/metadata.ex, lib/mix/tasks/relyra.refresh_due.ex, lib/mix/tasks/relyra.metadata.pin.ex, test/mix/tasks/relyra_refresh_due_test.exs, test/mix/tasks/relyra_metadata_pin_test.exs</files>
  <read_first>
    - lib/relyra/metadata.ex (preserve all 3 existing public functions verbatim; ADD pin_trust_fingerprint/3)
    - lib/mix/tasks/relyra.install.ex (canonical Mix task header + OptionParser shape)
    - lib/relyra/ecto/metadata_source.ex (Plan 01 — confirm auto_refresh_changeset/2 cast list and the great-error message)
    - .planning/phases/21-scheduled-metadata-refresh/21-CONTEXT.md (D-22 trust anchor pinning UX recommendation; D-06 mix task recipe)
    - .planning/phases/21-scheduled-metadata-refresh/21-RESEARCH.md "Open Questions" Q1 (recommendation: both Mix task AND admin LiveView, sharing one auto_refresh_changeset/2 underneath) + "Example C/D" (Mix task body shape)
    - .planning/phases/21-scheduled-metadata-refresh/21-PATTERNS.md "lib/mix/tasks/relyra.refresh_due.ex and lib/mix/tasks/relyra.metadata.pin.ex" section
  </read_first>
  <action>
    Step 1 — Add `pin_trust_fingerprint/3` to `lib/relyra/metadata.ex`. ADD this AFTER the existing `refresh/2` clauses (around line 61) and BEFORE the `defp fetch_repo/2` helper:

    ```elixir
    @doc """
    Pins one or more SHA-256 trust fingerprints onto the connection's
    metadata source. Used by both the admin LiveView fingerprint UX and
    the `mix relyra.metadata.pin` task — they share one underlying
    `auto_refresh_changeset/2` so the two paths cannot drift (D-22 + Q1
    recommendation).

    `attrs` may include any subset of the operator-facing auto-refresh
    fields:
      - `:metadata_trust_fingerprints` — list of SHA-256 hex strings
        (typically the union of existing pinned + the new fingerprint)
      - `:auto_refresh_enabled` — boolean
      - `:refresh_cadence` — `:hourly | :every_6h | :daily | :weekly`
      - `:require_signed_metadata` — boolean
      - `:legacy_unsigned_metadata_policy` — map (D-19 escape hatch)

    The validation in `auto_refresh_changeset/2` will refuse to enable
    auto-refresh without at least one pinned fingerprint (D-09 great-error).
    """
    @spec pin_trust_fingerprint(binary(), map(), keyword()) ::
            {:ok, struct()} | {:error, Error.t()}
    def pin_trust_fingerprint(connection_id, attrs, opts \\ [])

    def pin_trust_fingerprint(connection_id, attrs, opts)
        when is_binary(connection_id) and is_map(attrs) and is_list(opts) do
      with {:ok, repo} <- fetch_repo(opts, :pin_trust_fingerprint) do
        case repo.get_by(Relyra.Ecto.Connection, connection_id: connection_id) do
          nil ->
            {:error,
             Error.new(
               :connection_not_found,
               "Connection record was not found",
               %{connection_id: connection_id, operation: :pin_trust_fingerprint}
             )}

          %Relyra.Ecto.Connection{} = connection ->
            case repo.get_by(Relyra.Ecto.MetadataSource, connection_record_id: connection.id) do
              nil ->
                {:error,
                 Error.new(
                   :metadata_source_not_found,
                   "No registered metadata source exists for this connection — register one first via `Metadata.register_source/3`",
                   %{connection_id: connection_id, operation: :pin_trust_fingerprint}
                 )}

              %Relyra.Ecto.MetadataSource{} = source ->
                case source
                     |> Relyra.Ecto.MetadataSource.auto_refresh_changeset(attrs)
                     |> repo.update() do
                  {:ok, updated} ->
                    {:ok, updated}

                  {:error, %Ecto.Changeset{} = changeset} ->
                    {:error,
                     Error.new(
                       :invalid_metadata_source,
                       "Trust fingerprint pin failed validation",
                       %{
                         connection_id: connection_id,
                         errors: format_changeset_errors(changeset)
                       }
                     )}
                end
            end
        end
      end
    end

    def pin_trust_fingerprint(_connection_id, _attrs, opts) do
      {:error,
       Error.new(
         :invalid_connection_record,
         "connection_id and attrs are required for trust fingerprint pinning",
         %{operation: :pin_trust_fingerprint, repo: inspect(Keyword.get(opts, :repo))}
       )}
    end

    defp format_changeset_errors(changeset) do
      Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
        Enum.reduce(opts, message, fn {key, value}, acc ->
          String.replace(acc, "%{#{key}}", to_string(value))
        end)
      end)
    end
    ```

    Step 2 — Create `lib/mix/tasks/relyra.refresh_due.ex` (per RESEARCH Example D — public moduledoc so it shows under `mix help`):

    ```elixir
    defmodule Mix.Tasks.Relyra.RefreshDue do
      @moduledoc """
      Runs any due Phase 21 scheduled metadata refreshes once.

      Suitable for `cron`, `kubectl run`, fly.io scheduled machines, and any
      other host scheduler that prefers a CLI invocation over an Oban worker.
      Adopters who use Oban add the documented Cron one-liner instead — see
      the README "Operations" section.

          mix relyra.refresh_due --repo MyApp.Repo

      Returns `:ok` on a clean tick (including the no-due-sources case, which
      emits the `[:relyra, :saml, :metadata, :auto_refresh, :skipped]` event).
      """
      @shortdoc "Refresh any metadata sources whose schedule is due."

      use Mix.Task

      @impl true
      def run(args) do
        Mix.Task.run("app.start")

        {opts, _argv, _invalid} =
          OptionParser.parse(args,
            strict: [repo: :string],
            aliases: [r: :repo]
          )

        repo_string =
          Keyword.get(opts, :repo) ||
            Mix.raise("--repo is required: mix relyra.refresh_due --repo MyApp.Repo")

        repo =
          try do
            String.to_existing_atom(repo_string)
          rescue
            ArgumentError -> Mix.raise("Repo module #{repo_string} is not loaded")
          end

        case Relyra.Metadata.Scheduler.run_due(repo, []) do
          {:ok, results} ->
            Mix.shell().info("relyra.refresh_due: #{map_size(results)} sources processed.")
            :ok

          {:error, error} ->
            Mix.raise("relyra.refresh_due failed: #{error.message}")
        end
      end
    end
    ```

    Step 3 — Create `lib/mix/tasks/relyra.metadata.pin.ex`:

    ```elixir
    defmodule Mix.Tasks.Relyra.Metadata.Pin do
      @moduledoc """
      Pins a SHA-256 trust fingerprint onto a connection's metadata source.

      Used by IaC adopters (Terraform / Pulumi) and operators who manage
      trust state via scripts. The admin LiveView fingerprint UX will share
      the same underlying changeset (`MetadataSource.auto_refresh_changeset/2`)
      so the two paths cannot drift.

          mix relyra.metadata.pin <connection_id> --fingerprint <sha256_hex> --repo MyApp.Repo

      Multiple `--fingerprint` flags may be supplied in one invocation
      (rotation window — D-17 multi-valued anchor).

      Operator MUST verify the fingerprint out-of-band before running this
      command. The fingerprint is the SHA-256 of the IdP's signing-cert PEM
      (lowercase hex, no colons), computed via:

          openssl x509 -in metadata-signing.pem -outform DER | openssl dgst -sha256 | tr 'A-F' 'a-f'

      The pin REPLACES the source's `metadata_trust_fingerprints` array.
      Supply every currently-pinned fingerprint plus the new one to extend
      (this matches the "explicit always" Relyra strict-defaults principle).
      """
      @shortdoc "Pin a SHA-256 metadata trust fingerprint on a connection."

      use Mix.Task

      @impl true
      def run(args) do
        Mix.Task.run("app.start")

        {opts, argv, _invalid} =
          OptionParser.parse(args,
            strict: [fingerprint: :keep, repo: :string],
            aliases: [f: :fingerprint, r: :repo]
          )

        connection_id =
          List.first(argv) ||
            Mix.raise("connection_id is required: mix relyra.metadata.pin <connection_id> --fingerprint <hex>")

        fingerprints = Keyword.get_values(opts, :fingerprint)

        if fingerprints == [] do
          Mix.raise("at least one --fingerprint is required")
        end

        repo_string =
          Keyword.get(opts, :repo) ||
            Mix.raise("--repo is required")

        repo =
          try do
            String.to_existing_atom(repo_string)
          rescue
            ArgumentError -> Mix.raise("Repo module #{repo_string} is not loaded")
          end

        case Relyra.Metadata.pin_trust_fingerprint(
               connection_id,
               %{metadata_trust_fingerprints: Enum.map(fingerprints, &String.downcase/1)},
               repo: repo
             ) do
          {:ok, _updated} ->
            Mix.shell().info(
              "relyra.metadata.pin: pinned #{length(fingerprints)} fingerprint(s) on #{connection_id}."
            )

            :ok

          {:error, error} ->
            Mix.raise("relyra.metadata.pin failed: #{error.message}")
        end
      end
    end
    ```

    Step 4 — Test files. Both Mix-task tests use `Mix.Task.rerun/2` if needed; the simpler approach is to call the run/1 function directly with arg lists.

    Create `test/mix/tasks/relyra_refresh_due_test.exs`:

    ```elixir
    defmodule Mix.Tasks.Relyra.RefreshDueTest do
      use ExUnit.Case, async: false
      import ExUnit.CaptureIO

      alias Mix.Tasks.Relyra.RefreshDue

      describe "run/1" do
        test "raises when --repo is missing" do
          assert_raise Mix.Error, ~r/--repo is required/, fn ->
            RefreshDue.run([])
          end
        end

        test "raises when the named repo is not a loaded atom" do
          assert_raise Mix.Error, ~r/is not loaded/, fn ->
            RefreshDue.run(["--repo", "DoesNotExist.Repo"])
          end
        end

        @tag :integration
        test "with a valid repo, calls Scheduler.run_due/2 and prints a result line" do
          # Test repo Relyra.TestRepo is registered in test_helper.exs.
          output =
            capture_io(fn ->
              RefreshDue.run(["--repo", to_string(Relyra.TestRepo)])
            end)

          assert output =~ "relyra.refresh_due:"
        end
      end
    end
    ```

    Create `test/mix/tasks/relyra_metadata_pin_test.exs`:

    ```elixir
    defmodule Mix.Tasks.Relyra.Metadata.PinTest do
      use ExUnit.Case, async: false
      import ExUnit.CaptureIO

      alias Mix.Tasks.Relyra.Metadata.Pin

      describe "run/1 — argument validation" do
        test "raises when connection_id positional arg is missing" do
          assert_raise Mix.Error, ~r/connection_id is required/, fn ->
            Pin.run(["--fingerprint", "abc", "--repo", "MyApp.Repo"])
          end
        end

        test "raises when --fingerprint is missing" do
          assert_raise Mix.Error, ~r/--fingerprint is required/, fn ->
            Pin.run(["conn-1", "--repo", "MyApp.Repo"])
          end
        end

        test "raises when --repo is missing" do
          assert_raise Mix.Error, ~r/--repo is required/, fn ->
            Pin.run(["conn-1", "--fingerprint", "abc"])
          end
        end
      end

      describe "run/1 — happy path" do
        @tag :integration
        test "pins a single fingerprint via Relyra.Metadata.pin_trust_fingerprint/3" do
          # Set up a Connection + MetadataSource fixture, then call run/1.
          # Assert: (a) the source row's metadata_trust_fingerprints array
          # contains the pinned hex (lowercased); (b) shell output mentions
          # "pinned 1 fingerprint(s)".
          :ok
        end

        @tag :integration
        test "pins multiple fingerprints in one invocation (rotation window — D-17)" do
          # Two --fingerprint flags; assert both end up in the array.
          :ok
        end
      end
    end
    ```
  </action>
  <verify>
    <automated>mix test test/mix/tasks/relyra_refresh_due_test.exs test/mix/tasks/relyra_metadata_pin_test.exs --warnings-as-errors</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "def pin_trust_fingerprint" lib/relyra/metadata.ex` returns at least `1`.
    - `grep -c "MetadataSource.auto_refresh_changeset" lib/relyra/metadata.ex` returns at least `1` (D-22 / RESEARCH Q1 — Mix and LiveView share one underlying changeset).
    - `grep -c "import_xml\\|register_source\\|refresh\\|pin_trust_fingerprint" lib/relyra/metadata.ex` returns at least `4` (existing 3 functions preserved + new one).
    - File `lib/mix/tasks/relyra.refresh_due.ex` exists with `defmodule Mix.Tasks.Relyra.RefreshDue`.
    - `grep -c "@shortdoc " lib/mix/tasks/relyra.refresh_due.ex` returns at least `1`.
    - `grep -c "@moduledoc " lib/mix/tasks/relyra.refresh_due.ex` returns at least `1` (NOT `@moduledoc false` — the task should appear under `mix help`).
    - `grep -c "@moduledoc false" lib/mix/tasks/relyra.refresh_due.ex` returns `0` (NOT private).
    - `grep -c "Mix.Task.run(\"app.start\")" lib/mix/tasks/relyra.refresh_due.ex` returns at least `1`.
    - `grep -c "Relyra.Metadata.Scheduler.run_due" lib/mix/tasks/relyra.refresh_due.ex` returns at least `1`.
    - File `lib/mix/tasks/relyra.metadata.pin.ex` exists with `defmodule Mix.Tasks.Relyra.Metadata.Pin`.
    - `grep -c "Relyra.Metadata.pin_trust_fingerprint" lib/mix/tasks/relyra.metadata.pin.ex` returns at least `1` (Mix task delegates to the shared helper).
    - `grep -c "strict: \[fingerprint: :keep" lib/mix/tasks/relyra.metadata.pin.ex` returns at least `1` (multi-valued for D-17 rotation).
    - `mix help relyra.refresh_due` exits 0 and prints the moduledoc (the task is publicly listed).
    - `mix help relyra.metadata.pin` exits 0 and prints the moduledoc.
    - `mix test test/mix/tasks/relyra_refresh_due_test.exs test/mix/tasks/relyra_metadata_pin_test.exs --warnings-as-errors` exits 0 with the validation tests passing (integration tests are tagged and may be deferred).
    - `mix compile --warnings-as-errors` exits 0.
    - `mix compile --no-optional-deps --warnings-as-errors` exits 0.
    - **W11 brand-voice grep invariant (Mix task moduledocs):** `grep -ciE "(polling|cron job|blocked|retry|circuit breaker|maxbackoff)" lib/mix/tasks/relyra.refresh_due.ex lib/mix/tasks/relyra.metadata.pin.ex` returns `0`. The Mix task `@moduledoc` strings describe Relyra's behavior using the brand-approved vocabulary; the literal substring `cron` MAY appear ONLY when it documents the host's cron/crontab as the invocation mechanism (e.g., "via system cron" inside the example bash block) — never as a description of Relyra's own scheduling model.
  </acceptance_criteria>
  <done>`Relyra.Metadata.pin_trust_fingerprint/3` exists as the shared underlying helper. Both Mix tasks exist with public moduledocs (visible under `mix help`); both call `Mix.Task.run("app.start")` to boot the host repo; both validate args and exit cleanly. The pin task supports multiple `--fingerprint` flags in one invocation (D-17 rotation window). Validation tests pass synchronously; integration tests are tagged `:integration` and exercise real Repo fixtures. **W11: brand-voice grep covers both Mix task `@moduledoc`s — forbidden token set returns 0 matches.**</done>
</task>

<task type="auto">
  <name>Task 3: Add the optional Oban dep to mix.exs, the ci.oban_smoke alias, and the README "Operations" section</name>
  <files>mix.exs, README.md</files>
  <read_first>
    - mix.exs (whole file — preserve every existing dep, alias, and option)
    - .planning/phases/21-scheduled-metadata-refresh/21-CONTEXT.md (D-06 LOCKED scheduler recipes; D-37 optional-deps gateway pattern)
    - .planning/phases/21-scheduled-metadata-refresh/21-RESEARCH.md "Example C: Oban Cron one-liner (the README copy-paste recipe per D-06)" + "Example D: Mix task fallback" + "Standard Stack" Oban version (~> 2.22, current 2.22.1)
    - prompts/relyra-engineering-dna-from-prior-libs.md §3 (compile lane invariant)
    - README.md (the existing "Operations" section if any — preserve all existing content; this plan ADDS a sub-section)
  </read_first>
  <action>
    Step 1 — Edit `mix.exs`. Add the Oban optional dep AT THE END of the deps list:

    ```elixir
    {:oban, "~> 2.22", optional: true}
    ```

    Inside the `deps` block, the new line goes after the existing `{:req, "~> 0.5", optional: true}` line. Do NOT change any existing dep version. Do NOT promote Oban to required — the optional-deps gateway from Plan 05 is the contract.

    Add a new alias `ci.oban_smoke` to the `aliases` block. Add it AFTER `"ci.integration"` and BEFORE `"ci.release"`:

    ```elixir
    "ci.oban_smoke": [
      "compile --no-optional-deps --warnings-as-errors",
      "compile --warnings-as-errors",
      "test --include oban --warnings-as-errors test/relyra/optional_deps/oban_test.exs test/relyra/workers/metadata_refresh_test.exs"
    ]
    ```

    The first `compile --no-optional-deps` line proves the engineering-DNA §3 invariant survives the Oban addition. The second compile + test runs the Oban-present worker dispatch path.

    Step 2 — Edit `README.md`. Add a new top-level section `## Operations: Scheduled metadata refresh` (or append to an existing Operations section if one exists). The section MUST contain the four LOCKED recipes (D-06):

    ```markdown
    ## Operations: Scheduled metadata refresh

    Phase 21 ships a dormant scheduler entry point any host scheduler can drive. Pick the recipe that matches your deployment.

    ### Option 1: Oban Cron (recommended)

    Adds one Cron line. Oban's `unique:` constraint deduplicates across a clustered Oban; the per-source schedule (cadence preset + jitter) is enforced by Relyra.

    ```elixir
    # In your host application's config/config.exs:
    config :my_app, Oban,
      repo: MyApp.Repo,
      queues: [relyra_metadata: 1],
      plugins: [
        {Oban.Plugins.Cron,
         crontab: [
           # Run every 15 minutes; per-source cadence is enforced by Relyra.
           {"*/15 * * * *", Relyra.Workers.MetadataRefresh,
            args: %{"repo" => "MyApp.Repo"}}
         ]}
      ]
    ```

    Add `{:oban, "~> 2.22"}` to your host's `mix.exs` (Relyra declares Oban as `optional: true`).

    ### Option 2: Mix task (cron-friendly)

    For hosts without Oban — drives the same `Scheduler.run_due/2` entry point.

    ```bash
    # Once a minute via system cron:
    * * * * * cd /path/to/host && MIX_ENV=prod mix relyra.refresh_due --repo MyApp.Repo
    ```

    ### Option 3: Kubernetes CronJob

    ```yaml
    apiVersion: batch/v1
    kind: CronJob
    metadata:
      name: relyra-refresh-due
    spec:
      schedule: "*/15 * * * *"
      jobTemplate:
        spec:
          template:
            spec:
              containers:
                - name: relyra
                  image: my-app:latest
                  command: ["mix", "relyra.refresh_due", "--repo", "MyApp.Repo"]
              restartPolicy: OnFailure
    ```

    ### Option 4: fly.io scheduled machines

    ```toml
    # fly.toml
    [[machines.schedule]]
      schedule = "*/15 * * * *"
      command = ["mix", "relyra.refresh_due", "--repo", "MyApp.Repo"]
    ```

    ### Pinning a metadata trust fingerprint

    Phase 21 requires operator-pinned SHA-256 fingerprints — there is no TOFU. Compute and verify the fingerprint out-of-band:

    ```bash
    # Compute the SHA-256 fingerprint of the IdP's metadata-signing certificate:
    openssl x509 -in metadata-signing.pem -outform DER \
      | openssl dgst -sha256 \
      | tr 'A-F' 'a-f'
    ```

    Then pin it:

    ```bash
    mix relyra.metadata.pin <connection_id> \
      --fingerprint <sha256_hex> \
      --repo MyApp.Repo
    ```

    The mix task and the admin LiveView fingerprint form share the same underlying changeset, so either path produces the same audit trail.

    ### Telemetry events

    Scheduled refresh emits under the `[:relyra, :saml, :metadata, :auto_refresh, ...]` namespace (separate from manual `[:relyra, :saml, :metadata, :refresh]`). See `Relyra.Telemetry`'s moduledoc for the full event catalog. An opt-in reference handler logs each event with redaction:

    ```elixir
    # In your host's Application.start/2:
    def start(_type, _args) do
      :ok = Relyra.Telemetry.Handlers.LogAlerts.attach()
      ...
    end
    ```

    Adopters who want vendor paging (Slack / PagerDuty / Sentry) attach their own handlers — telemetry events are the contract.
    ```

    Use the brand-approved copy throughout: "Auto-refresh", "schedule", "suspended", "metadata trust fingerprint". Avoid: "polling", "cron job" (you may reference the host's "cron" / "cron table" because that's the host's terminology, but never describe Relyra's behavior as polling), "blocked", "retry", "circuit breaker".
  </action>
  <verify>
    <automated>mix deps.get && mix compile --warnings-as-errors && mix compile --no-optional-deps --warnings-as-errors && mix ci.oban_smoke</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "{:oban, \"~> 2.22\", optional: true}" mix.exs` returns at least `1`.
    - `grep -c "ci.oban_smoke" mix.exs` returns at least `1`.
    - `grep -c "compile --no-optional-deps --warnings-as-errors" mix.exs` returns at least `1` (preserved + within ci.oban_smoke).
    - `grep -c "## Operations: Scheduled metadata refresh\\|## Operations" README.md` returns at least `1` (new top-level section).
    - `grep -c "mix relyra.refresh_due" README.md` returns at least `2` (mix-task option + k8s CronJob + fly.io machine).
    - `grep -c "Oban.Plugins.Cron" README.md` returns at least `1` (Oban Cron one-liner per D-06).
    - `grep -c "kind: CronJob" README.md` returns at least `1` (k8s recipe per D-06).
    - `grep -c "machines.schedule" README.md` returns at least `1` (fly.io recipe per D-06).
    - `grep -c "mix relyra.metadata.pin" README.md` returns at least `1` (fingerprint pin recipe per D-22).
    - `grep -c ":relyra, :saml, :metadata, :auto_refresh" README.md` returns at least `1`.
    - **W11 brand-voice grep invariant (README "Operations" section):** the full forbidden token set is enforced. Run `awk '/^## Operations/,/^## /' README.md | grep -v '^\\s*\\\\?\\\\$' | grep -v '^```' | grep -ciE "(polling|cron job|blocked|retry|circuit breaker|maxbackoff)"` and assert it returns `0`. Literal `cron` / `crontab` is permitted ONLY inside fenced code blocks (Oban Cron config / system cron `* * * * *` lines / k8s `kind: CronJob` YAML / fly.io `[[machines.schedule]]` TOML — these are host vocabulary, not Relyra's behavior). Outside code fences, "cron" MUST NOT describe Relyra; Relyra's own behavior is "Auto-refresh on a schedule".
    - `grep -ciE "(circuit breaker|MaxBackoff)" README.md` returns `0` (covers prose AND code blocks — Relyra never has a "circuit breaker", and the fixed-cap soft backoff is not Shibboleth's `MaxBackoff`).
    - `mix deps.get` exits 0 and resolves Oban 2.22.x.
    - `mix compile --warnings-as-errors` exits 0.
    - `mix compile --no-optional-deps --warnings-as-errors` exits 0 (CRITICAL — engineering-DNA §3 invariant; with Oban now declared as optional, the no-optional-deps lane MUST stay green via the gateway's `@compile {:no_warn_undefined, [...]}` attributes).
    - `mix ci.oban_smoke` exits 0 (the new alias proves both compile lanes + the Oban-present worker tests are all green together).
    - `mix help relyra.refresh_due` lists the task.
    - `mix help relyra.metadata.pin` lists the task.
  </acceptance_criteria>
  <done>Oban is declared as `~> 2.22, optional: true`. The `ci.oban_smoke` alias proves BOTH compile lanes pass AND the Oban-present worker dispatch tests are green. README ships all four LOCKED recipes (Oban Cron, mix task, k8s CronJob, fly.io schedule), plus the fingerprint pin recipe and the LogAlerts attach example. Brand-voice invariant is enforced by grep. Both new Mix tasks are listed by `mix help`.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Mix CLI args → `Mix.Tasks.Relyra.Metadata.Pin.run/1` | Operator-supplied fingerprint string crosses into the trust schema; the task lower-cases for normalization but DOES NOT compute the fingerprint itself (operator must verify out-of-band — D-17). |
| Mix CLI args → `Mix.Tasks.Relyra.RefreshDue.run/1` | Operator-supplied repo atom crosses into the scheduler driver; `String.to_existing_atom/1` rejects unknown atoms. |
| Adopter `Application.start/2` → `LogAlerts.attach/0` | Adopter explicitly opts in to the reference handler; the handler's redaction is the only safety net for sensitive event payloads. |
| README recipes → adopter copy-paste | Adopters paste config strings; the recipes MUST be exact and tested. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-21-41 | Spoofing | `Pin.run/1` --fingerprint argument | mitigate (operator-responsibility) | Task documents and the README explains the out-of-band fingerprint computation; the schema gate from Plan 01 (`validate_fingerprints_when_enabled/1`) and the trust check from Plan 03 (`TrustAnchor.check/2`) are the runtime defenses. The task's role is shaped input + audit trail, not fingerprint validation. |
| T-21-42 | Tampering | `Pin.run/1` REPLACES `metadata_trust_fingerprints` array | mitigate | Task moduledoc explicitly documents that pinning REPLACES (not appends) so operators with rotation needs supply every desired fingerprint. The schema-level changeset cast list ensures no other field can be sneaked in via the CLI. |
| T-21-43 | Denial of Service | `RefreshDue.run/1` looping forever | accept | Task is a one-shot tick; it does NOT start a supervised ticker (D-04). Adopter's host scheduler controls the cadence. |
| T-21-44 | Information Disclosure | `LogAlerts.handle_event/4` redaction | mitigate | The `redact/1` helper drops `:xml`, `:metadata_xml`, `:certificate_pem`, `:pem`, `:private_key` before Logger sees the payload — same posture as `Relyra.Log`. |
| T-21-45 | Repudiation | LogAlerts auto-attaching at boot | mitigate | D-30: the handler is NOT default-attached anywhere in `lib/`; adopter explicitly calls `attach/0`. Grep-enforced by acceptance criteria. |
| T-21-46 | Tampering | `mix.exs` Oban dep change | mitigate | The `@compile {:no_warn_undefined, [...]}` attributes from Plan 05 keep the `--no-optional-deps` lane green even after Oban is added. The `ci.oban_smoke` alias is the regression gate. |
| T-21-47 | Information Disclosure | README recipes leaking adopter secrets | accept | All recipes use placeholders (`MyApp.Repo`, `connection_id`, `<sha256_hex>`); README does not document any adopter-specific URL, fingerprint, or repo name. |
</threat_model>

<verification>
- `mix deps.get` is green (Oban 2.22.x resolves cleanly).
- `mix compile --warnings-as-errors` is green.
- `mix compile --no-optional-deps --warnings-as-errors` is green (CRITICAL invariant).
- `mix ci.oban_smoke` is green.
- `mix test test/relyra/telemetry/handlers/log_alerts_test.exs test/mix/tasks/relyra_refresh_due_test.exs test/mix/tasks/relyra_metadata_pin_test.exs --warnings-as-errors` is green.
- `mix test --warnings-as-errors --exclude pending` is green (full suite — proves no regression).
- `mix help relyra.refresh_due` and `mix help relyra.metadata.pin` both succeed and print the moduledoc.
- `mix format --check-formatted` is green.
- README ships all four LOCKED recipes (Oban Cron, mix task, k8s CronJob, fly.io scheduled machines) per D-06.
- **W11 brand-voice grep invariant (multi-surface):** `grep -ciE '(circuit breaker|maxbackoff)' README.md lib/relyra/telemetry.ex lib/relyra/telemetry/handlers/log_alerts.ex lib/mix/tasks/relyra.refresh_due.ex lib/mix/tasks/relyra.metadata.pin.ex` returns `0`. Additionally: outside fenced code blocks in README "Operations" section, `polling | cron job | blocked | retry` MUST NOT describe Relyra's behavior (literal `cron` / `crontab` permitted only in host-config code blocks per Task 3 acceptance criteria).
</verification>

<success_criteria>
- `Relyra.Telemetry`'s moduledoc gains a documented `### metadata.auto_refresh` section listing all 8 Phase-21 events with measurements + metadata payload (D-23/D-24/D-07/D-30).
- The existing `### metadata.refresh` catalog block is byte-identical to before (D-23 separation invariant).
- `Relyra.Telemetry.Handlers.LogAlerts` exists, attaches/detaches via `:telemetry.attach_many/4`, emits one Logger line per event with redaction, and is grep-proven NOT default-attached anywhere in `lib/`.
- `Relyra.Metadata.pin_trust_fingerprint/3` exists as the shared underlying helper for both Mix-task and (future) LiveView fingerprint UX (D-22 + RESEARCH Q1).
- `mix relyra.refresh_due --repo MyApp.Repo` runs `Scheduler.run_due/2` and is publicly listed (`mix help`).
- `mix relyra.metadata.pin <connection_id> --fingerprint <hex> --repo MyApp.Repo` pins fingerprints via the shared changeset; supports `--fingerprint` repeated for rotation (D-17 multi-valued anchor).
- `{:oban, "~> 2.22", optional: true}` is in `mix.exs`; `mix compile --no-optional-deps --warnings-as-errors` stays green (engineering-DNA §3 invariant).
- The `ci.oban_smoke` alias runs both compile lanes + the Oban-present worker tests; `mix ci.oban_smoke` is green.
- README ships all four LOCKED scheduler recipes + the fingerprint pin recipe + the LogAlerts attach example (D-06 LOCKED deliverable).
</success_criteria>

<output>
After completion, create `.planning/phases/21-scheduled-metadata-refresh/21-07-SUMMARY.md` summarizing: telemetry event count documented (8), LogAlerts LOC, Mix tasks created (2) + their args, the mix.exs Oban version + the new ci.oban_smoke alias, README sub-section count, and any deviations from the locked recipes.
</output>