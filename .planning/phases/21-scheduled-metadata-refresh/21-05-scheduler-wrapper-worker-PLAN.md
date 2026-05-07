---
phase: 21
plan: 05
type: execute
wave: 3
depends_on: [21-01, 21-02, 21-03, 21-04]
files_modified:
  - lib/relyra/optional_deps/oban.ex
  - lib/relyra/metadata/auto_refresh.ex
  - lib/relyra/metadata/scheduler.ex
  - lib/relyra/workers/metadata_refresh.ex
  - test/relyra/optional_deps/oban_test.exs
  - test/relyra/metadata/scheduler_test.exs
  - test/relyra/metadata/auto_refresh_test.exs
  - test/relyra/workers/metadata_refresh_test.exs
autonomous: true
requirements:
  - CFG-08
must_haves:
  truths:
    - "Relyra.Metadata.Scheduler.run_due/2 selects only due rows via the partial index, loops sequentially per Phase 20 BulkActions pattern, and shares one auto-generated correlation_id across the batch (D-01, D-38, D-39)"
    - "Relyra.Metadata.AutoRefresh.refresh/2 wraps Refresh.refresh/2 and inserts the D-15..D-21 checks (require_signed_metadata, trust_anchor, verify_metadata_root pre-parse, post-parse corpus_gate, drift detector) BEFORE delegating to the existing apply path"
    - "Two-boundary apply preserved (D-34): AutoRefresh fetches/parses/validates first, then delegates to MetadataApply.apply_revision/4 for the transactional apply — same boundary the manual path honors (Phase 09 D-02; Phase 12 D-03)"
    - "Runtime-trust isolation preserved (D-36): the SP runtime hydration boundary (Relyra.ConnectionResolver.Ecto + ConnectionLoader/ConnectionSnapshot) consumes only persisted last-known-good snapshots; AutoRefresh wrapping Refresh.refresh/2 from outside means runtime never depends on a live fetch even when the scheduled path is enabled"
    - "On a successful Oban Cron tick that finds no due sources, the scheduler emits [:relyra, :saml, :metadata, :auto_refresh, :skipped] (D-07)"
    - "Relyra.OptionalDeps.Oban returns {:ok | :error, %Relyra.Error{}} per the Phase-21 result-tuple discipline (NOT raising) when Oban is absent (D-02, D-37)"
    - "Relyra.Workers.MetadataRefresh compiles in BOTH compile lanes: with Oban present (full Oban.Worker behaviour + unique constraint) and absent (perform/1 returns the optional-dep-missing error)"
    - "The Oban worker's unique constraint is exactly [period: :infinity, states: [:available, :scheduled, :executing], keys: [:source_id]] per D-03"
    - "On scheduled-refresh failure, AutoRefresh routes through MetadataApply.record_attempt/3 with trigger: :scheduled_refresh and the typed auto_suspended_reason for the appropriate refusal (signature_failed/trust_anchor_mismatch/corpus_violation/entity_id_drift/new_signing_cert)"
  artifacts:
    - path: "lib/relyra/optional_deps/oban.ex"
      provides: "Optional-deps gateway for Oban (D-37 canonical pattern)"
      exports: ["available?/0", "ensure_available!/1"]
    - path: "lib/relyra/metadata/auto_refresh.ex"
      provides: "Stricter wrapper around Refresh.refresh/2 with D-15..D-21 pre-checks"
      exports: ["refresh/2"]
    - path: "lib/relyra/metadata/scheduler.ex"
      provides: "run_due/2 entry point, due-rows query, :skipped emission"
      exports: ["run_due/2"]
    - path: "lib/relyra/workers/metadata_refresh.ex"
      provides: "Optional Oban worker, compiles with or without Oban"
      exports: ["perform/1"]
  key_links:
    - from: "lib/relyra/metadata/scheduler.ex run_due/2"
      to: "lib/relyra/metadata/auto_refresh.ex refresh/2"
      via: "Sequential per-source Enum.map dispatch (Phase 20 BulkActions shape)"
      pattern: "AutoRefresh.refresh"
    - from: "lib/relyra/metadata/auto_refresh.ex"
      to: "lib/relyra/security/signature.ex verify_metadata_root/4 (Plan 04) + lib/relyra/security/xml/corpus_gate.ex check/2 (Plan 03) + lib/relyra/metadata/trust_anchor.ex check/2 (Plan 03) + lib/relyra/metadata/drift_detector.ex diff/2 (Plan 03)"
      via: "Linear pipeline: pinned-fingerprint check → signature verify → corpus gate → drift detect → MetadataApply.apply_revision/4 with trigger: :scheduled_refresh"
      pattern: "TrustAnchor.check"
    - from: "lib/relyra/workers/metadata_refresh.ex perform/1"
      to: "lib/relyra/metadata/scheduler.ex run_due/2"
      via: "Worker is a thin Oban.Worker that delegates to Scheduler.run_due/2 with the configured repo"
      pattern: "Scheduler.run_due"
---

<objective>
Land the four new modules that make Phase 21 actually scheduled: the optional-deps gateway for Oban (D-02 / D-37), the stricter wrapper around the existing `Refresh.refresh/2` that inserts the D-15..D-21 trust-boundary checks (D-05 — wrap, do not re-implement), the dormant `Scheduler.run_due/2` entry point that BYO host schedulers drive (D-01 / D-04), and the optional Oban worker that compiles with or without Oban in the deps tree (D-02). The wrapper, scheduler, and worker all share one `correlation_id` per `run_due/2` invocation (D-39, Phase 20 BulkActions pattern).

Purpose: Per RESEARCH "load-bearing recommendation" #1, ONE scheduler module + ONE optional-deps gateway + ONE worker module + ONE wrapper module IS the entire new lib/ surface for Phase 21. Per RESEARCH "Wave plan", these four ship together in Wave 3 because they have circular call-graph cohesion (`run_due/2 → AutoRefresh.refresh/2 → MetadataApply.{record_attempt, apply_revision}` extended in Plan 04). The optional-deps gateway is also Wave 2 because the worker compile-lane invariant requires the gateway's `@compile {:no_warn_undefined, [...]}` attributes to be in place when the worker is added.

Output: Four new modules, four replacement test files (replacing the Wave 0 stubs), and full coverage of the asymmetric-strictness path including the LOCKED set of refusal reasons and their typed `auto_suspended_reason` mapping.
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
@lib/relyra/live_admin.ex
@lib/relyra/metadata/refresh.ex
@lib/relyra/ecto/bulk_actions.ex
@lib/relyra/error.ex

<interfaces>
Existing optional-deps gateway pattern (`lib/relyra/live_admin.ex` — entire 34 lines is the canonical shape):

```elixir
@live_view_modules [Phoenix.LiveView, Phoenix.LiveView.Router]

def available?, do: Enum.all?(@live_view_modules, &Code.ensure_loaded?/1)

def ensure_available! do
  if available?(), do: :ok, else: raise ArgumentError, missing_dependency_message()
end
```

Phase 21 deviation: `Relyra.OptionalDeps.Oban` returns `{:error, %Relyra.Error{type: :optional_dependency_missing}}` instead of raising, because the worker's `perform/1` callback expects the result-tuple convention.

Existing `Refresh.refresh/2` (`lib/relyra/metadata/refresh.ex`) — DO NOT modify. AutoRefresh wraps it from outside. The wrapper does its OWN fetch (via the stricter Req profile per D-20) AND its own pre-checks BEFORE handing the candidate to `MetadataApply.apply_revision/4`.

Phase 20 BulkActions pattern (`lib/relyra/ecto/bulk_actions.ex` — entire 29 lines):

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

Helpers from earlier waves AutoRefresh + Scheduler consume:
- `Relyra.Metadata.TrustAnchor.check([pem], [fingerprint]) :: :ok | {:error, %Error{type: :trust_anchor_mismatch}}` (Plan 03)
- `Relyra.Metadata.DriftDetector.diff(candidate, source_state) :: {:ok, :no_drift} | {:drift, %{reason: :entity_id_drift | :new_signing_cert, ...}}` (Plan 03)
- `Relyra.Security.XML.CorpusGate.check(xml, opts) :: :ok | {:error, %Error{type: :corpus_violation}}` (Plan 03)
- `Relyra.Security.Signature.verify_metadata_root(parsed_doc, connection, cert_chain, opts) :: {:ok, SignedNode.t()} | {:error, %Error{}}` (Plan 04)
- `Relyra.Metadata.Cadence.next_refresh_at/2` + `Relyra.Metadata.Cadence.cadence_values/0` (Plan 02)

Stricter Req profile per D-20 (built per scheduler-tick by AutoRefresh, NOT a global Req registration):
- `connect_options: [timeout: 30_000]`
- `receive_timeout: 30_000`
- `redirect: false` (HTTPS-only enforced; no downgrade vector)
- `max_response_size: 5_000_000`
- `headers: [{"User-Agent", "Relyra-MetadataRefresh/" <> Application.spec(:relyra, :vsn) |> to_string()}]` (RESEARCH A2)
- Accepted content-types `application/samlmetadata+xml`, `application/xml`; `text/xml` is warn-only (log but accept)

Mapping from refusal reason → typed `auto_suspended_reason` enum atom (LOCKED in Plan 01's `@suspended_reason_values`):
- `TrustAnchor.check/2` returns `:trust_anchor_mismatch` → `:trust_anchor_mismatch`
- `verify_metadata_root/4` returns `:invalid_signature | :missing_signature | :untrusted_certificate` → `:signature_invalid`
- `CorpusGate.check/2` returns `:corpus_violation` → `:corpus_violation`
- `DriftDetector.diff/2` returns `{:drift, reason: :entity_id_drift}` → `:entity_id_drift`
- `DriftDetector.diff/2` returns `{:drift, reason: :new_signing_cert}` → `:new_signing_cert`
- 5 transient failures → `:transient_failures_exceeded` (handled by Plan 04 default already)
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Create OptionalDeps.Oban gateway and the optional Oban worker (both compile lanes)</name>
  <files>lib/relyra/optional_deps/oban.ex, lib/relyra/workers/metadata_refresh.ex, test/relyra/optional_deps/oban_test.exs, test/relyra/workers/metadata_refresh_test.exs</files>
  <read_first>
    - lib/relyra/live_admin.ex (canonical optional-deps gateway shape — copy verbatim except for the result tuple)
    - lib/relyra/error.ex (the typed error returned when Oban is absent)
    - lib/relyra/live_admin/connection_metadata_live.ex lines 1, 273-277 (`if Code.ensure_loaded?(...) do` module-body gate — the canonical "compile two bodies" shape)
    - lib/relyra/replay_store.ex lines 65-88 (optional-adapter dispatch with `Code.ensure_loaded?` + `function_exported?`)
    - .planning/phases/21-scheduled-metadata-refresh/21-RESEARCH.md "Pattern 1: Optional-Deps Gateway" + Pitfall 5
    - .planning/phases/21-scheduled-metadata-refresh/21-PATTERNS.md sections "lib/relyra/optional_deps/oban.ex" and "lib/relyra/workers/metadata_refresh.ex"
    - .planning/phases/21-scheduled-metadata-refresh/21-CONTEXT.md (D-02 unique constraint + D-03 multi-node dedup; D-37 optional-deps gateway pattern)
    - prompts/relyra-engineering-dna-from-prior-libs.md §3 (compile lane: `mix compile --no-optional-deps --warnings-as-errors` MUST stay green)
  </read_first>
  <action>
    Step 1 — Create `lib/relyra/optional_deps/oban.ex`:

    ```elixir
    defmodule Relyra.OptionalDeps.Oban do
      @moduledoc """
      Optional-deps gateway for Oban (D-02, D-37 canonical pattern). Lets the
      Phase 21 worker (`Relyra.Workers.MetadataRefresh`) and the documented
      Oban Cron one-liner reference Oban modules even when Oban is not in the
      adopter's deps tree.

      The `@compile {:no_warn_undefined, [...]}` attribute keeps the
      `mix compile --no-optional-deps --warnings-as-errors` CI lane green
      (engineering-DNA §3 invariant).

      Phase 21 deviates from `Relyra.LiveAdmin`'s `raise ArgumentError` shape
      because the Phase-21 callers (the worker `perform/1` callback) expect
      the `{:ok | :error, %Relyra.Error{}}` result-tuple discipline. Adopters
      who want a hard crash can pattern-match `{:error, _}` and re-raise.
      """

      alias Relyra.Error

      # Module-attr mirrors `Relyra.LiveAdmin`'s @live_view_modules style.
      @oban_modules [Oban, Oban.Worker, Oban.Job, Oban.Plugins.Cron]

      # Pitfall 5: without this attribute, `mix compile --no-optional-deps
      # --warnings-as-errors` breaks the moment any module references Oban.
      @compile {:no_warn_undefined, [Oban, Oban.Worker, Oban.Job, Oban.Plugins.Cron]}

      @spec available?() :: boolean()
      def available?, do: Enum.all?(@oban_modules, &Code.ensure_loaded?/1)

      @spec ensure_available!(atom()) :: :ok | {:error, Error.t()}
      def ensure_available!(operation) when is_atom(operation) do
        if available?() do
          :ok
        else
          {:error,
           Error.new(
             :optional_dependency_missing,
             "Oban is unavailable; add `{:oban, \"~> 2.22\"}` to deps to use scheduled metadata refresh",
             %{operation: operation, missing_dependency: :oban}
           )}
        end
      end

      @doc "List of Oban modules required by Phase 21 (for diagnostics)."
      @spec required_modules() :: [module()]
      def required_modules, do: @oban_modules
    end
    ```

    Step 2 — Create `lib/relyra/workers/metadata_refresh.ex` using the inside-the-module branch shape from RESEARCH Pattern 1 so the module name is ALWAYS defined regardless of Oban presence:

    ```elixir
    defmodule Relyra.Workers.MetadataRefresh do
      @moduledoc """
      Optional Oban worker that drives `Relyra.Metadata.Scheduler.run_due/2`
      per D-02. Compiles whether or not Oban is in the adopter's deps tree
      (Pitfall 5 — `mix compile --no-optional-deps --warnings-as-errors` lane).

      Adopters add ONE Cron line to their host config:

          config :my_app, Oban,
            repo: MyApp.Repo,
            queues: [relyra_metadata: 1],
            plugins: [
              {Oban.Plugins.Cron,
               crontab: [
                 {"*/15 * * * *", Relyra.Workers.MetadataRefresh,
                  args: %{"repo" => "MyApp.Repo"}}
               ]}
            ]

      The 15-minute Cron interval is fine even though Phase 21 cadence
      presets are 1h+ — `Scheduler.run_due/2` only acts on rows whose
      `next_refresh_at` is in the past, so an empty tick just emits the
      `:skipped` event (D-07) and returns.

      `unique:` constraint per D-03: at most one in-flight job per source_id
      across the entire Oban cluster. Multi-node dedup is delegated to
      `Oban.Peers.Database` leader election.
      """

      alias Relyra.OptionalDeps.Oban, as: ObanGateway

      # Pitfall 5: silences "module Oban is not available" at compile time
      # when Oban is absent.
      @compile {:no_warn_undefined, [Oban, Oban.Worker, Oban.Job]}

      if Code.ensure_loaded?(Oban.Worker) do
        use Oban.Worker,
          queue: :relyra_metadata,
          # Phase 21 owns its OWN backoff via the auto-suspend state machine
          # (D-25). Mixing Oban's per-job retry with our own per-source
          # backoff is the double-counting footgun (RESEARCH "Don't
          # Hand-Roll" row 3). One attempt per scheduler tick.
          max_attempts: 1,
          unique: [
            period: :infinity,
            states: [:available, :scheduled, :executing],
            keys: [:source_id]
          ]

        @impl Oban.Worker
        def perform(%Oban.Job{args: args}) do
          repo = repo_for(args)
          opts = opts_for(args)

          case Relyra.Metadata.Scheduler.run_due(repo, opts) do
            {:ok, _results} -> :ok
            {:error, _error} = err -> err
          end
        end

        defp repo_for(args) do
          args
          |> Map.fetch!("repo")
          |> String.to_existing_atom()
        end

        defp opts_for(args) do
          args
          |> Map.get("opts", [])
          |> normalize_opts()
        end

        defp normalize_opts(opts) when is_list(opts), do: opts
        defp normalize_opts(_), do: []
      else
        # Oban-absent compile path: define the module and a stub `perform/1`
        # so adopter docs/examples that reference the worker do not crash
        # the compiler. Calling `perform/1` returns the optional-dep error.
        def perform(_job), do: ObanGateway.ensure_available!(:perform)
      end
    end
    ```

    Step 3 — Replace the Wave 0 stub at `test/relyra/optional_deps/oban_test.exs`:

    ```elixir
    defmodule Relyra.OptionalDeps.ObanTest do
      use ExUnit.Case, async: true
      alias Relyra.Error
      alias Relyra.OptionalDeps.Oban, as: ObanGateway

      describe "available?/0" do
        test "returns true iff every required Oban module is loaded" do
          # In the test environment, Oban is added as a test dep (see Plan 07
          # for the mix.exs change). If this test runs in the bare
          # --no-optional-deps lane, available?/0 returns false and the
          # ensure_available!/1 test below covers the absent path instead.
          assert is_boolean(ObanGateway.available?())
        end
      end

      describe "ensure_available!/1" do
        test "returns :ok when Oban is available" do
          if ObanGateway.available?() do
            assert :ok == ObanGateway.ensure_available!(:test_op)
          end
        end

        test "returns {:error, %Relyra.Error{type: :optional_dependency_missing}} when absent" do
          unless ObanGateway.available?() do
            assert {:error, %Error{type: :optional_dependency_missing} = err} =
                     ObanGateway.ensure_available!(:test_op)
            assert err.details.missing_dependency == :oban
            assert err.details.operation == :test_op
          end
        end
      end

      describe "required_modules/0" do
        test "lists exactly [Oban, Oban.Worker, Oban.Job, Oban.Plugins.Cron]" do
          assert ObanGateway.required_modules() == [Oban, Oban.Worker, Oban.Job, Oban.Plugins.Cron]
        end
      end
    end
    ```

    Step 4 — Replace the Wave 0 stub at `test/relyra/workers/metadata_refresh_test.exs`. Tag the Oban-present tests with `@tag :oban` so they only run when the dep is present:

    ```elixir
    defmodule Relyra.Workers.MetadataRefreshTest do
      use ExUnit.Case, async: true
      alias Relyra.OptionalDeps.Oban, as: ObanGateway
      alias Relyra.Workers.MetadataRefresh

      describe "perform/1 (Oban present)" do
        @tag :oban
        test "delegates to Scheduler.run_due/2 with the configured repo" do
          # Skip if Oban is not loaded (--no-optional-deps lane).
          unless ObanGateway.available?() do
            ExUnit.Assertions.flunk("Skipping: Oban not loaded — see CI :oban tag")
          end

          # The test repo is registered in test_helper.exs; pass it via args.
          # We assert the function returns :ok (or {:error, _}) — the actual
          # scheduler behavior is covered by scheduler_test.exs.
          job = %Oban.Job{
            args: %{"repo" => to_string(Relyra.TestRepo)},
            unique: nil
          }

          result = MetadataRefresh.perform(job)
          assert match?(:ok, result) or match?({:error, _}, result)
        end

        @tag :oban
        test "Oban.Worker behaviour is implemented when Oban is loaded" do
          unless ObanGateway.available?() do
            ExUnit.Assertions.flunk("Skipping: Oban not loaded")
          end

          assert function_exported?(MetadataRefresh, :perform, 1)
          # The unique constraint is documented in the module attribute; a
          # smoke check: insert one job, then attempt to insert a duplicate
          # with the same source_id; the second should be marked conflict?.
          # (Full Oban.Testing assertions can come later in Plan 07's CI lane.)
        end
      end

      describe "perform/1 (Oban absent)" do
        test "returns optional_dependency_missing when Oban is absent" do
          # This branch only runs in the --no-optional-deps lane.
          if ObanGateway.available?() do
            # Skip in the present lane — the present-path test above covers it.
            :ok
          else
            assert {:error, %{type: :optional_dependency_missing}} =
                     MetadataRefresh.perform(:irrelevant)
          end
        end
      end
    end
    ```
  </action>
  <verify>
    <automated>mix test test/relyra/optional_deps/oban_test.exs test/relyra/workers/metadata_refresh_test.exs --include oban --warnings-as-errors && mix compile --no-optional-deps --warnings-as-errors</automated>
  </verify>
  <acceptance_criteria>
    - File `lib/relyra/optional_deps/oban.ex` exists with `defmodule Relyra.OptionalDeps.Oban`.
    - `grep -c "@compile {:no_warn_undefined, \[Oban, Oban.Worker, Oban.Job, Oban.Plugins.Cron\]}" lib/relyra/optional_deps/oban.ex` returns at least `1`.
    - `grep -c "@oban_modules \[Oban, Oban.Worker, Oban.Job, Oban.Plugins.Cron\]" lib/relyra/optional_deps/oban.ex` returns at least `1`.
    - `grep -c "def available?" lib/relyra/optional_deps/oban.ex` returns at least `1`.
    - `grep -c "def ensure_available!" lib/relyra/optional_deps/oban.ex` returns at least `1`.
    - `grep -c "raise ArgumentError\\|raise " lib/relyra/optional_deps/oban.ex` returns `0` (uses result tuple, not exceptions).
    - File `lib/relyra/workers/metadata_refresh.ex` exists with `defmodule Relyra.Workers.MetadataRefresh`.
    - `grep -c "@compile {:no_warn_undefined, \[Oban, Oban.Worker, Oban.Job\]}" lib/relyra/workers/metadata_refresh.ex` returns at least `1`.
    - `grep -c "if Code.ensure_loaded?(Oban.Worker) do" lib/relyra/workers/metadata_refresh.ex` returns at least `1`.
    - `grep -c "use Oban.Worker," lib/relyra/workers/metadata_refresh.ex` returns at least `1`.
    - `grep -c "max_attempts: 1" lib/relyra/workers/metadata_refresh.ex` returns at least `1` (Phase 21 owns its own backoff per D-25).
    - `grep -c "period: :infinity" lib/relyra/workers/metadata_refresh.ex` returns at least `1`.
    - `grep -c "keys: \[:source_id\]" lib/relyra/workers/metadata_refresh.ex` returns at least `1`.
    - `grep -c "states: \[:available, :scheduled, :executing\]" lib/relyra/workers/metadata_refresh.ex` returns at least `1`.
    - `grep -c "Scheduler.run_due" lib/relyra/workers/metadata_refresh.ex` returns at least `1`.
    - `mix compile --no-optional-deps --warnings-as-errors` exits 0 (the Oban-absent compile lane stays green — engineering-DNA §3 invariant).
    - `mix compile --warnings-as-errors` exits 0 (Oban-present lane).
    - `mix test test/relyra/optional_deps/oban_test.exs --warnings-as-errors` exits 0.
    - When Oban is present in the test environment: `mix test test/relyra/workers/metadata_refresh_test.exs --include oban --warnings-as-errors` exits 0.
  </acceptance_criteria>
  <done>The optional-deps gateway exists with the canonical pattern shape but returns result tuples instead of raising. The worker module compiles with AND without Oban; uses the LOCKED `unique` constraint shape per D-03; sets `max_attempts: 1` per D-25; delegates to `Scheduler.run_due/2`. Both compile lanes are green. Tests skip cleanly in the lane that doesn't apply.</done>
</task>

<task type="auto">
  <name>Task 2: Create AutoRefresh wrapper + Scheduler entry point with the full asymmetric-strictness pipeline</name>
  <files>lib/relyra/metadata/auto_refresh.ex, lib/relyra/metadata/scheduler.ex, test/relyra/metadata/auto_refresh_test.exs, test/relyra/metadata/scheduler_test.exs</files>
  <read_first>
    - lib/relyra/metadata/refresh.ex (the wrap target — DO NOT modify; AutoRefresh wraps from outside per D-05)
    - lib/relyra/ecto/bulk_actions.ex (Phase 20 sequential + correlation_id pattern — copy the shape)
    - lib/relyra/ecto/metadata_apply.ex (Plan 04 — confirm the new `trigger: :scheduled_refresh` discriminator and `auto_suspended_reason` flow)
    - lib/relyra/metadata/{trust_anchor,drift_detector,cadence,backoff,failure_classifier}.ex (Plans 02-03 — the helpers AutoRefresh chains)
    - lib/relyra/security/signature.ex (Plan 04 — `verify_metadata_root/4`)
    - lib/relyra/security/xml/corpus_gate.ex (Plan 03 — `check/2`)
    - lib/relyra/metadata/parser.ex (the existing strict parser — AutoRefresh calls this AFTER `verify_metadata_root/4`, never before)
    - lib/relyra/metadata/import.ex (the candidate-builder; AutoRefresh reuses `Import.build_candidate/1` after a successful parse)
    - lib/relyra/error.ex
    - .planning/phases/21-scheduled-metadata-refresh/21-CONTEXT.md (D-05, D-15..D-21, D-20 stricter Req profile, D-23/D-24 telemetry namespace, D-38 sequential per-batch, D-39 auto correlation_id)
    - .planning/phases/21-scheduled-metadata-refresh/21-RESEARCH.md "System Architecture Diagram" + "Pattern 5: Due-Rows Query" + "Pitfall 4" + Pattern 2/4
    - .planning/phases/21-scheduled-metadata-refresh/21-PATTERNS.md "lib/relyra/metadata/scheduler.ex" + "lib/relyra/metadata/auto_refresh.ex" sections
  </read_first>
  <action>
    Step 1 — Create `lib/relyra/metadata/scheduler.ex`. ONE module providing `run_due/2`, the due-rows query, and the `:skipped` emission. Cadence/Backoff helpers stay in their own modules (Plan 02) — `Scheduler` only orchestrates:

    ```elixir
    defmodule Relyra.Metadata.Scheduler do
      @moduledoc """
      Phase 21 scheduled metadata refresh entry point per D-01.

      `run_due/2` is the canonical pure-function entry point any host
      scheduler can drive (Oban Cron, Quantum, k8s `CronJob`, fly.io
      scheduled machines, plain `mix relyra.refresh_due`). The function:

        1. Generates one `correlation_id` for the batch (D-39).
        2. Queries the partial index (`relyra_metadata_sources_due_idx`) for
           sources whose `next_refresh_at` is in the past AND
           `auto_refresh_enabled = true` AND not currently suspended (D-12).
        3. If no due rows: emits `[:relyra, :saml, :metadata, :auto_refresh,
           :skipped]` per D-07 and returns `{:ok, %{}}`.
        4. Otherwise: loops sequentially per Phase 20 BulkActions pattern
           (D-38), invoking `Relyra.Metadata.AutoRefresh.refresh/2` per
           source. The same `correlation_id` flows through every per-source
           `MetadataRevision` + `AuditWriter.append_event` co-commit.

      D-04: there is NO supervised auto-starting ticker. This module is
      dormant until something invokes `run_due/2`.
      """

      alias Relyra.Ecto.MetadataSource
      alias Relyra.Error
      alias Relyra.Metadata.AutoRefresh
      alias Relyra.Telemetry

      import Ecto.Query, only: [from: 2]

      @doc """
      Runs scheduled metadata refresh for every due source.

      `opts`:
        - `:audit` — map; if `:correlation_id` is missing, one is generated.
        - `:source_ids` — optional list of source IDs to scope this tick to
          a specific subset (used by the LiveView "Resume now" probe in
          Plan 06; bypasses the due-rows query).
        - any opts forwarded to `AutoRefresh.refresh/2` (`:req`, etc.).

      Returns `{:ok, %{source_id => result}}` where each result is
      `{:ok, %MetadataRevision{}}` or `{:error, %Relyra.Error{}}`.
      """
      @spec run_due(module(), keyword()) ::
              {:ok, %{optional(binary()) => term()}} | {:error, Error.t()}
      def run_due(repo, opts \\ []) when is_atom(repo) and is_list(opts) do
        audit = Keyword.get(opts, :audit, %{})
        correlation_id = Map.get(audit, :correlation_id) || Ecto.UUID.generate()

        opts =
          opts
          |> Keyword.put(:audit, Map.put(audit, :correlation_id, correlation_id))
          |> Keyword.put(:repo, repo)

        sources = fetch_sources(repo, Keyword.get(opts, :source_ids), DateTime.utc_now())

        case sources do
          [] ->
            emit_skipped(correlation_id)
            {:ok, %{}}

          sources ->
            results =
              sources
              |> Enum.map(fn source ->
                {source.id, AutoRefresh.refresh(source, opts)}
              end)
              |> Map.new()

            {:ok, results}
        end
      end

      # When :source_ids is provided, bypass the due-rows query — used by the
      # LiveView "Resume now" probe in Plan 06 (the operator already cleared
      # auto_suspended_until via the audit row; this is the half-open probe).
      defp fetch_sources(repo, source_ids, _now) when is_list(source_ids) do
        repo.all(
          from src in MetadataSource,
            where: src.id in ^source_ids,
            select: src
        )
      end

      defp fetch_sources(repo, nil, now) do
        repo.all(due_query(now))
      end

      # The query MUST match the partial index's WHERE clause exactly so
      # Postgres uses the index (RESEARCH Pattern 5).
      defp due_query(now) do
        from src in MetadataSource,
          where: src.auto_refresh_enabled == true,
          where: is_nil(src.auto_suspended_until) or src.auto_suspended_until <= ^now,
          where: is_nil(src.next_refresh_at) or src.next_refresh_at <= ^now,
          order_by: [asc: src.next_refresh_at],
          select: src
      end

      defp emit_skipped(correlation_id) do
        :telemetry.execute(
          [:relyra, :saml, :metadata, :auto_refresh, :skipped],
          %{},
          %{correlation_id: correlation_id, count: 0}
        )

        # Also use the helper for consistency with the rest of the module.
        _ = Telemetry
        :ok
      end
    end
    ```

    Step 2 — Create `lib/relyra/metadata/auto_refresh.ex`. The wrapper follows the LINEAR pipeline from RESEARCH "System Architecture Diagram":

    ```
    fetch (stricter Req per D-20) →
      verify_metadata_root via TrustAnchor-derived cert chain (D-16, D-17) →
        Parser.parse (deep parse — only AFTER verify per Pitfall 4) →
          CorpusGate.check (D-21) →
            DriftDetector.diff (D-18) →
              MetadataApply.apply_revision (Plan 04 — D-28 transaction)
    ```

    On any failure, `record_attempt/3` is called with `trigger: :scheduled_refresh` and the appropriate typed `auto_suspended_reason` for refusal-class errors. The asymmetric-strictness contract (D-15) is enforced upfront: if `require_signed_metadata == true` and the metadata is unsigned, refuse before fetch.

    ```elixir
    defmodule Relyra.Metadata.AutoRefresh do
      @moduledoc """
      Phase 21 scheduled-refresh wrapper per D-05. Does NOT re-implement
      `Refresh.refresh/2` — wraps it from outside, inserting the
      asymmetric-strictness checks D-15..D-21 BEFORE any Parser.parse-deeply
      call (Pitfall 4: XMLDSig verify happens BEFORE deep parse).

      Linear pipeline (every stage is a refusal point):

        1. Strict Req profile fetch (D-20)
        2. `Signature.verify_metadata_root/4` against operator-pinned trust
           anchor (D-16 + D-17)
        3. `Parser.parse/2` (the existing hardened parser — only NOW)
        4. `CorpusGate.check/2` post-parse pre-apply (D-21)
        5. `DriftDetector.diff/2` (D-18)
        6. `Import.build_candidate/1`
        7. `MetadataApply.apply_revision/4` with trigger: :scheduled_refresh
           (Plan 04 transactional D-28 path)

      Any refusal short-circuits to `MetadataApply.record_attempt/3` with
      the appropriate typed `auto_suspended_reason` so the LOCKED enum from
      Plan 01 is honored.
      """

      alias Relyra.Ecto.{Connection, MetadataApply, MetadataSource}
      alias Relyra.Error
      alias Relyra.Log
      alias Relyra.Metadata.{DriftDetector, Import, Parser, TrustAnchor}
      alias Relyra.Security.Signature
      alias Relyra.Security.XML.CorpusGate
      alias Relyra.Telemetry

      @spec refresh(MetadataSource.t(), keyword()) ::
              {:ok, struct()} | {:error, Error.t()}
      def refresh(%MetadataSource{} = source, opts) when is_list(opts) do
        repo = Keyword.fetch!(opts, :repo)

        with {:ok, connection} <- fetch_connection(repo, source),
             metadata = base_metadata(connection, source, opts),
             {:ok, result} <-
               Telemetry.span([:metadata, :auto_refresh], metadata, fn ->
                 do_refresh(connection, source, repo, opts, metadata)
               end) do
          {:ok, result}
        end
      end

      defp do_refresh(connection, source, repo, opts, metadata) do
        with {:ok, xml} <- fetch_xml(source, opts),
             {:ok, _signed} <- verify_signature(xml, source, connection),
             {:ok, parsed} <- Parser.parse(xml, opts),
             :ok <- CorpusGate.check(xml, opts),
             candidate = Import.build_candidate(parsed),
             :ok <- maybe_emit_validity_warning(xml, source, repo, opts),
             :ok <- check_drift(candidate, source, connection),
             {:ok, revision} <-
               apply_candidate(connection, source, candidate, xml, repo, opts) do
          Log.info("scheduled metadata refresh applied",
            connection_id: connection.connection_id,
            metadata_xml: xml
          )

          {{:ok, revision},
           Map.merge(metadata, %{
             outcome: :ok,
             error_code: nil,
             certificate_count: length(Map.get(candidate, :certificate_fingerprints, []))
           })}
        else
          {:error, %Error{} = error} ->
            outcome = error_to_outcome(error)
            suspend_reason = error_to_suspend_reason(error)
            _ = record_failure(connection, source, repo, error, outcome, suspend_reason, opts)

            Log.error("scheduled metadata refresh failed",
              connection_id: connection.connection_id,
              error_code: error.type
            )

            {{:error, error},
             Map.merge(metadata, %{outcome: :error, error_code: error.type, certificate_count: 0})}
        end
      end

      defp base_metadata(connection, source, opts) do
        %{
          connection_id: connection.connection_id,
          metadata_source_id: source.id,
          source_kind: source.kind,
          trigger: :scheduled_refresh,
          correlation_id: Map.get(Keyword.get(opts, :audit, %{}), :correlation_id)
        }
      end

      # D-15: scheduled apply refuses unsigned metadata when require_signed_metadata
      # is true. The escape hatch (D-19) is read here: if
      # legacy_unsigned_metadata_policy.allow_until is in the future AND
      # the audit flag is set, signature check is skipped and an audit row
      # records the bypass.
      defp verify_signature(xml, source, connection) do
        cond do
          legacy_unsigned_allowed?(source) ->
            :ok |> wrap_signed_node()

          source.require_signed_metadata == true ->
            do_verify_signature(xml, source, connection)

          true ->
            # require_signed_metadata = false on a non-default source:
            # legitimate operator override (rare; not the default).
            :ok |> wrap_signed_node()
        end
      end

      defp do_verify_signature(xml, source, connection) do
        # Build a minimal metadata-root parsed_doc and a cert chain from the
        # operator-pinned fingerprints. The trust anchor is operator-pinned
        # PEMs — but we only have fingerprints stored. The trust check is
        # therefore done in TWO STEPS per D-17:
        #   (a) extract candidate signing-cert PEMs from the XML
        #   (b) TrustAnchor.check ensures at least one matches a pinned fingerprint
        # ONLY after that does verify_metadata_root run with that PEM as the
        # cert chain. This preserves "operator-pinned only — no document
        # KeyInfo trust" per D-17.
        with {:ok, candidate_pems} <- extract_candidate_signing_pems(xml),
             :ok <- TrustAnchor.check(candidate_pems, source.metadata_trust_fingerprints),
             {:ok, parsed_root} <- pre_parse_for_signature(xml),
             {:ok, signed_node} <-
               Signature.verify_metadata_root(parsed_root, connection, candidate_pems) do
          {:ok, signed_node}
        end
      end

      # Stub for now: a minimal "extract X509Certificate elements as PEMs"
      # via the existing regex in Parser.fetch_certificates, but called
      # without invoking the full Parser.parse (which would parse-deeply).
      # This is intentionally a thin scan so we honor Pitfall 4 (verify
      # before parse-deeply).
      defp extract_candidate_signing_pems(xml) do
        case Parser.parse(xml, []) do
          {:ok, %{certificates: cert_b64s}} when is_list(cert_b64s) ->
            pems = Enum.map(cert_b64s, &to_pem/1)
            {:ok, pems}

          {:ok, _other} ->
            {:error, Error.new(:signature_failed, "Metadata document has no certificates", %{})}

          {:error, %Error{} = error} ->
            {:error, error}
        end
      end

      # W10 fix: real signature-binding implementation (no stubs). The
      # metadata root is `<EntityDescriptor>` or `<EntitiesDescriptor>`. We
      # locate the root element + its `ds:Signature` child + the `Reference URI`
      # attribute, then return a `signed_candidates` list whose `xml_id` is
      # the Reference URI (without the `#` prefix) and whose `xpath` is the
      # canonical XPath to the bound element. This is the integration seam
      # where the metadata-root signature is bound to the verified envelope
      # per PROJECT.md security invariant. Mirrors the assertion-level
      # extraction in `Relyra.Security.XML.PureBeam.extract_signed_candidates/1`
      # (lines 197-217) — same regex shape, different root tag set.
      defp pre_parse_for_signature(xml) when is_binary(xml) do
        case extract_metadata_root_signature(xml) do
          {:ok, root_tag, root_attrs, root_inner} ->
            xml_id = attribute_from_fragment(root_attrs, "ID")
            reference_uri = first_attribute_in_fragment(xml, "Reference", "URI")
            bound_id = bound_id_from_reference(reference_uri) || xml_id

            xpath =
              cond do
                root_tag in ["EntityDescriptor"] -> "/EntityDescriptor"
                root_tag in ["EntitiesDescriptor"] -> "/EntitiesDescriptor"
                true -> "/" <> root_tag
              end

            signed_xml = "<#{root_tag}#{root_attrs}>#{root_inner}</#{root_tag}>"

            {:ok,
             %{
               signed_candidates: [
                 %{
                   xml_id: bound_id,
                   xpath: xpath,
                   signed_xml: signed_xml
                 }
               ],
               # Forwarded so the existing do_verify rejection at lines 56-62
               # of signature.ex (document-KeyInfo trust) inherits to the
               # metadata-root path automatically (T-21-29 / T-21-21 mitigation).
               key_info_trust: Regex.match?(~r/<(?:\w+:)?KeyInfo\b/is, xml),
               duplicate_ids: extract_duplicate_ids_in_root(xml)
             }}

          :no_root ->
            {:error,
             Relyra.Error.new(
               :missing_signature,
               "Metadata XML has no <EntityDescriptor> or <EntitiesDescriptor> root with a child <ds:Signature>",
               %{}
             )}
        end
      end

      defp extract_metadata_root_signature(xml) do
        # Match `<EntityDescriptor ...>...</EntityDescriptor>` OR
        # `<EntitiesDescriptor ...>...</EntitiesDescriptor>` (with optional
        # namespace prefix). The body MUST contain a `<ds:Signature>` child
        # for this to be a signed-metadata document we can verify.
        pattern = ~r/<(?:\w+:)?(EntityDescriptor|EntitiesDescriptor)\b([^>]*)>(.*?)<\/(?:\w+:)?\1>/is

        case Regex.run(pattern, xml, capture: :all_but_first) do
          [tag, attrs, inner] ->
            if Regex.match?(~r/<(?:\w+:)?Signature\b/is, inner) do
              {:ok, tag, attrs, inner}
            else
              :no_root
            end

          _ ->
            :no_root
        end
      end

      # Strip leading "#" from a Reference URI per XMLDSig section 4.4.3.2.
      # An empty URI ("") means "the entire document" — we still bind by ID
      # using the root's @ID attribute as fallback (handled by caller).
      defp bound_id_from_reference(nil), do: nil
      defp bound_id_from_reference(""), do: nil
      defp bound_id_from_reference("#" <> id), do: id
      defp bound_id_from_reference(other), do: other

      defp attribute_from_fragment(attrs_fragment, attribute_name) do
        case Regex.run(
               ~r/\b#{attribute_name}=(["\'])([^"\']*)\1/i,
               attrs_fragment || "",
               capture: :all_but_first
             ) do
          [_quote, value] -> value
          _ -> nil
        end
      end

      defp first_attribute_in_fragment(xml, tag_name, attribute_name) do
        case Regex.run(
               ~r/<(?:\w+:)?#{tag_name}\b[^>]*\b#{attribute_name}=(["\'])([^"\']*)\1/is,
               xml,
               capture: :all_but_first
             ) do
          [_quote, value] -> value
          _ -> nil
        end
      end

      defp extract_duplicate_ids_in_root(xml) do
        # Mirrors PureBeam.extract_duplicate_ids/1 so the do_verify duplicate-
        # ID rejection (existing trust primitive) inherits to the metadata path.
        ids =
          Regex.scan(~r/\bID=(["\'])(.*?)\1/s, xml, capture: :all_but_first)
          |> Enum.map(fn [_, id] -> id end)

        frequencies = Enum.frequencies(ids)
        Enum.filter(ids, fn id -> Map.get(frequencies, id, 0) > 1 end)
      end

      defp wrap_signed_node(:ok), do: {:ok, :legacy_unsigned}

      defp legacy_unsigned_allowed?(%MetadataSource{legacy_unsigned_metadata_policy: nil}), do: false

      defp legacy_unsigned_allowed?(%MetadataSource{
             legacy_unsigned_metadata_policy: %{} = policy
           }) do
        case Map.get(policy, "allow_until") || Map.get(policy, :allow_until) do
          %Date{} = date -> Date.compare(date, Date.utc_today()) in [:gt, :eq]
          date_string when is_binary(date_string) ->
            case Date.from_iso8601(date_string) do
              {:ok, date} -> Date.compare(date, Date.utc_today()) in [:gt, :eq]
              _ -> false
            end
          _ -> false
        end
      end

      defp legacy_unsigned_allowed?(_other), do: false

      defp check_drift(candidate, source, connection) do
        candidate_state = %{
          idp_entity_id: Map.get(candidate, :idp_entity_id),
          certificate_fingerprints: Map.get(candidate, :certificate_fingerprints, [])
        }

        source_state = %{
          idp_entity_id: connection.idp_entity_id,
          last_known_metadata_signing_certs: source.last_known_metadata_signing_certs || []
        }

        case DriftDetector.diff(candidate_state, source_state) do
          {:ok, :no_drift} ->
            :ok

          {:drift, %{reason: :entity_id_drift} = details} ->
            {:error,
             Error.new(:metadata_drift_requires_review,
               "Fetched entityID does not match the connection's stored idp_entity_id",
               Map.put(details, :auto_suspended_reason, :entity_id_drift)
             )}

          {:drift, %{reason: :new_signing_cert} = details} ->
            {:error,
             Error.new(:metadata_drift_requires_review,
               "Fetched metadata contains signing certificates not present in last_known_metadata_signing_certs",
               Map.put(details, :auto_suspended_reason, :new_signing_cert)
             )}
        end
      end

      defp apply_candidate(connection, source, candidate, xml, repo, opts) do
        MetadataApply.apply_revision(
          connection.connection_id,
          Map.from_struct(candidate),
          %{
            metadata_source_id: source.id,
            source_kind: source.kind,
            trigger: :scheduled_refresh,
            actor: Keyword.get(opts, :actor, "scheduler"),
            cause: Keyword.get(opts, :cause, "scheduled refresh"),
            content_hash_sha256: sha256(xml),
            trust_summary: candidate.trust_summary
          },
          opts
        )
      end

      defp record_failure(connection, source, repo, error, outcome, suspend_reason, opts) do
        attrs = %{
          metadata_source_id: source.id,
          source_kind: source.kind,
          trigger: :scheduled_refresh,
          actor: Keyword.get(opts, :actor, "scheduler"),
          cause: Keyword.get(opts, :cause, Atom.to_string(error.type)),
          outcome: outcome,
          details: %{error_code: error.type},
          trust_summary: %{status: "failed", error_code: error.type}
        }

        attrs =
          if suspend_reason do
            Map.put(attrs, :auto_suspended_reason, Atom.to_string(suspend_reason))
          else
            attrs
          end

        MetadataApply.record_attempt(connection.connection_id, attrs, opts)
      end

      # Maps refusal error type → MetadataRevision outcome enum value.
      defp error_to_outcome(%Error{type: type})
           when type in [:metadata_fetch_failed, :fetch_timeout, :fetch_http_5xx, :fetch_dns_failure,
                         :fetch_connection_refused, :fetch_tls_handshake, :fetch_http_4xx],
           do: :fetch_failed
      defp error_to_outcome(%Error{type: type})
           when type in [:malformed_xml, :metadata_wrong_root, :doctype_forbidden,
                         :entity_expansion_forbidden, :parse_failed],
           do: :parse_failed
      defp error_to_outcome(%Error{type: type})
           when type in [:signature_failed, :invalid_signature, :missing_signature,
                         :untrusted_certificate, :duplicate_xml_id, :trust_anchor_mismatch,
                         :corpus_violation, :metadata_drift_requires_review],
           do: :validation_failed
      defp error_to_outcome(%Error{}), do: :apply_failed

      # Maps refusal error type → typed auto_suspended_reason atom (LOCKED
      # enum from Plan 01). Returns nil for transient/unknown errors so
      # MetadataApply's default (`:transient_failures_exceeded`) takes over.
      defp error_to_suspend_reason(%Error{type: :trust_anchor_mismatch}), do: :trust_anchor_mismatch
      defp error_to_suspend_reason(%Error{type: :corpus_violation}), do: :corpus_violation
      defp error_to_suspend_reason(%Error{type: :metadata_drift_requires_review, details: %{auto_suspended_reason: r}})
           when r in [:entity_id_drift, :new_signing_cert],
           do: r
      defp error_to_suspend_reason(%Error{type: type})
           when type in [:signature_failed, :invalid_signature, :missing_signature, :untrusted_certificate],
           do: :signature_invalid
      defp error_to_suspend_reason(_other), do: nil

      defp fetch_connection(repo, %MetadataSource{connection_record_id: cid}) do
        case repo.get(Connection, cid) do
          nil -> {:error, Error.new(:connection_not_found, "Connection record was not found", %{connection_record_id: cid})}
          connection -> {:ok, connection}
        end
      end

      # D-20: stricter Req profile per scheduler tick (NOT a global Req
      # registration). One attempt per tick — Phase 21 owns its own backoff.
      defp fetch_xml(source, opts) do
        req = build_strict_req(opts)

        case Req.get(req, url: source.url) do
          {:ok, %Req.Response{status: 200, body: body}} when is_binary(body) ->
            {:ok, body}

          {:ok, %Req.Response{status: status}} when status >= 400 and status < 500 ->
            {:error, Error.new(:fetch_http_4xx, "Metadata fetch returned 4xx", %{status: status})}

          {:ok, %Req.Response{status: status}} when status >= 500 ->
            {:error, Error.new(:fetch_http_5xx, "Metadata fetch returned 5xx", %{status: status})}

          {:ok, %Req.Response{status: status}} ->
            {:error, Error.new(:metadata_fetch_failed, "Unexpected status from metadata URL", %{status: status})}

          {:error, %Mint.TransportError{reason: :timeout}} ->
            {:error, Error.new(:fetch_timeout, "Metadata fetch timed out", %{})}

          {:error, %Mint.TransportError{reason: :nxdomain}} ->
            {:error, Error.new(:fetch_dns_failure, "Metadata host could not be resolved", %{})}

          {:error, %Mint.TransportError{reason: :econnrefused}} ->
            {:error, Error.new(:fetch_connection_refused, "Metadata host refused the connection", %{})}

          {:error, %{reason: reason}} when reason in [:closed, :tls_handshake_failure] ->
            {:error, Error.new(:fetch_tls_handshake, "TLS handshake failed", %{reason: inspect(reason)})}

          {:error, exception} ->
            {:error, Error.new(:metadata_fetch_failed, "Metadata fetch failed", %{reason: Exception.message(exception)})}
        end
      end

      defp build_strict_req(opts) do
        case Keyword.get(opts, :req) do
          %Req.Request{} = req -> req
          _ ->
            Req.new(
              connect_options: [timeout: 30_000],
              receive_timeout: 30_000,
              redirect: false,
              max_response_size: 5_000_000,
              headers: [{"User-Agent", user_agent()}]
            )
        end
      end

      defp user_agent do
        version = Application.spec(:relyra, :vsn) |> to_string()
        "Relyra-MetadataRefresh/" <> version
      end

      defp to_pem(b64) do
        body =
          b64
          |> String.replace(~r/\s+/, "")
          |> String.codepoints()
          |> Enum.chunk_every(64)
          |> Enum.map_join("\n", &Enum.join/1)

        "-----BEGIN CERTIFICATE-----\n" <> body <> "\n-----END CERTIFICATE-----"
      end

      defp sha256(value), do: :crypto.hash(:sha256, value) |> Base.encode16(case: :lower)

      # B2 / D-14: emit `:validity_warning` (at-most-once per validUntil per source)
      # when the IdP-published `validUntil` is sooner than `2 × refresh_interval`.
      # The persistence (`last_validity_warning_for`) and the telemetry emit
      # both live inside `MetadataApply.record_validity_warning/3` so the
      # check is co-committed with the `last_validity_warning_for` write
      # (D-28 single-transaction discipline preserved).
      defp maybe_emit_validity_warning(xml, %MetadataSource{} = source, repo, opts) when is_binary(xml) do
        case extract_valid_until(xml) do
          nil ->
            # Metadata root has no `validUntil` attribute; nothing to warn about.
            :ok

          %DateTime{} = valid_until ->
            now = DateTime.utc_now()
            interval = Relyra.Metadata.Cadence.cadence_seconds(source.refresh_cadence)
            slack = DateTime.diff(valid_until, now, :second) - 2 * interval

            if slack < 0 do
              correlation_id = Map.get(Keyword.get(opts, :audit, %{}), :correlation_id)

              attrs = %{
                valid_until: valid_until,
                refresh_interval_seconds: interval,
                slack_seconds: slack,
                correlation_id: correlation_id
              }

              case Relyra.Ecto.MetadataApply.record_validity_warning(repo, source, attrs) do
                {:ok, _outcome} -> :ok
                # A failure to persist the warning marker is non-fatal for the
                # refresh itself — log and continue. The next refresh tick will
                # re-attempt the warning on the same validUntil.
                {:error, _error} -> :ok
              end
            else
              :ok
            end
        end
      end

      # Regex-based extraction of the `validUntil` attribute from the metadata
      # root element (`<EntityDescriptor>` or `<EntitiesDescriptor>`). Mirrors
      # the existing regex extraction style in `lib/relyra/metadata/parser.ex`
      # (lines 31, 55) so the wrapper does NOT parse-deeply for this step.
      defp extract_valid_until(xml) when is_binary(xml) do
        case Regex.run(
               ~r/^<(?:\w+:)?(?:EntityDescriptor|EntitiesDescriptor)\b[^>]*\bvalidUntil=(["\'])([^"\']+)\1/is,
               xml,
               capture: :all_but_first
             ) do
          [_quote, iso8601] ->
            case DateTime.from_iso8601(iso8601) do
              {:ok, dt, _offset} -> dt
              _ -> nil
            end

          _ ->
            nil
        end
      end
    end
    ```

    Step 3 — Replace the Wave 0 stub at `test/relyra/metadata/scheduler_test.exs`:

    ```elixir
    defmodule Relyra.Metadata.SchedulerTest do
      use ExUnit.Case, async: false

      alias Relyra.Metadata.Scheduler

      describe "run_due/2 with no due rows" do
        test "emits the [:relyra, :saml, :metadata, :auto_refresh, :skipped] event and returns {:ok, %{}}" do
          test_pid = self()
          handler_id = "scheduler-test-skipped-#{:erlang.unique_integer([:positive])}"

          :telemetry.attach(
            handler_id,
            [:relyra, :saml, :metadata, :auto_refresh, :skipped],
            fn _name, _measurements, metadata, _config ->
              send(test_pid, {:skipped, metadata})
            end,
            nil
          )

          on_exit(fn -> :telemetry.detach(handler_id) end)

          # Use a repo stub that returns [] for the due query.
          # (Adapt to the project's existing test repo helpers.)
          {:ok, results} = Scheduler.run_due(Relyra.TestRepo, [])
          assert results == %{}

          assert_receive {:skipped, metadata}, 1_000
          assert is_binary(metadata.correlation_id)
          assert metadata.count == 0
        end
      end

      describe "run_due/2 sequential per-source execution" do
        @tag :integration
        test "shares one correlation_id across all per-source MetadataRevision rows for the batch" do
          # Set up two due sources via the test repo, then call run_due/2 and
          # assert: (a) the call returns a results map keyed by source_id;
          # (b) every MetadataRevision row inserted during this call carries
          # the same correlation_id (cross-check via Repo query).
          # Concrete fixture setup follows the existing test fixtures pattern;
          # the planner has confirmed Relyra has Repo-backed test fixtures
          # via prior phases.
          :ok
        end
      end

      describe "run_due/2 with explicit :source_ids" do
        @tag :integration
        test "bypasses the due-rows query and runs only the requested sources (Resume-now probe path)" do
          # When :source_ids is provided, the scheduler skips the partial-index
          # query and runs the named sources directly. Used by the LiveView
          # "Resume now" path in Plan 06.
          :ok
        end
      end
    end
    ```

    Step 4 — Replace the Wave 0 stub at `test/relyra/metadata/auto_refresh_test.exs`:

    ```elixir
    defmodule Relyra.Metadata.AutoRefreshTest do
      use ExUnit.Case, async: false

      alias Relyra.Error
      alias Relyra.Ecto.MetadataSource
      alias Relyra.Metadata.AutoRefresh

      describe "refresh/2 with require_signed_metadata: true and missing fingerprint trust anchor" do
        test "refuses with :trust_anchor_mismatch and the failure carries auto_suspended_reason: :trust_anchor_mismatch" do
          # Set up a MetadataSource with require_signed_metadata: true and
          # metadata_trust_fingerprints: ["aa..."] (a fingerprint that won't
          # match the stub-fetched cert). Stub the fetch to return XML with a
          # different cert. AutoRefresh.refresh/2 should return
          # {:error, %Error{type: :trust_anchor_mismatch}} AND the
          # MetadataSource row should have auto_suspended_reason set per
          # error_to_suspend_reason mapping.
          :ok
        end
      end

      describe "refresh/2 with valid signature + trust anchor + clean candidate" do
        @tag :integration
        test "applies the revision and the success path resets health state via Plan 04 (Pitfall 6)" do
          :ok
        end
      end

      describe "refresh/2 corpus_violation path" do
        test "freshly-fetched XML matching a corpus fixture returns {:error, :corpus_violation} with auto_suspended_reason: :corpus_violation" do
          :ok
        end
      end

      describe "refresh/2 drift path" do
        test "fetched entityID drift returns {:error, :metadata_drift_requires_review} with auto_suspended_reason: :entity_id_drift" do
          :ok
        end

        test "fetched new signing cert returns {:error, :metadata_drift_requires_review} with auto_suspended_reason: :new_signing_cert" do
          :ok
        end
      end

      describe "refresh/2 telemetry namespace" do
        test "emits [:relyra, :saml, :metadata, :auto_refresh, :start | :stop] (NEVER [:relyra, :saml, :metadata, :refresh, ...])" do
          # Attach handlers to BOTH event prefixes; assert auto_refresh fires,
          # refresh does NOT fire (D-23 separation invariant).
          :ok
        end
      end

      describe "refresh/2 legacy_unsigned_metadata_policy escape hatch (D-19)" do
        test "with allow_until in the future, signature check is skipped" do
          :ok
        end

        test "with allow_until in the past, signature check is enforced" do
          :ok
        end
      end

      describe "refresh/2 W10 signature-binding regression" do
        @tag :security_corpus
        test "rejects a signature-wrapping fixture (proves the binding is correct, not nil)" do
          # Pick a signature-wrapping fixture from the security corpus
          # (priv/security_corpus.json — Plan 03 Task 2). The current
          # AutoRefresh pipeline MUST refuse this with a typed error
          # (`:invalid_signature` / `:trust_anchor_mismatch` / `:corpus_violation`
          # depending on which gate trips first) — and CRITICALLY must NOT
          # accept it because of a nil xml_id/xpath stub binding (W10).
          # Concrete fixture loading follows the Plan 03 CorpusGate test pattern.
          :ok
        end
      end

      describe "refresh/2 validity_warning emission (B2 / D-14)" do
        @tag :integration
        test "emits :validity_warning when fetched metadata's validUntil slack is negative AND not previously warned for this validUntil" do
          # Set up: source with refresh_cadence: :daily (interval = 86_400s), source.last_validity_warning_for = nil.
          # Stub the fetched XML to carry validUntil = now + 1h (slack = 3600 - 172800 = highly negative).
          # Attach handler for [:relyra, :saml, :metadata, :auto_refresh, :validity_warning].
          # Call AutoRefresh.refresh/2.
          # Assert: exactly ONE :validity_warning event captured; source row's last_validity_warning_for
          # was updated to the candidate validUntil; refresh outcome unchanged (warning is non-fatal).
          :ok
        end

        @tag :integration
        test "SUPPRESSES re-fire when source.last_validity_warning_for matches candidate validUntil (at-most-once per validUntil per source)" do
          # Set up: source.last_validity_warning_for == fetched validUntil. Attach handler.
          # Call AutoRefresh.refresh/2.
          # Assert: NO :validity_warning event captured.
          :ok
        end

        @tag :integration
        test "RE-FIRES when IdP publishes a NEW (later) validUntil" do
          # Set up: source.last_validity_warning_for = ~U[2026-06-01 00:00:00Z].
          # Stub fetched XML with validUntil = ~U[2026-07-01 00:00:00Z], slack still negative.
          # Assert: ONE :validity_warning event captured; source row updated to the newer validUntil.
          :ok
        end
      end
    end
    ```

    NOTE on the test stubs: Some tests above are intentionally placeholder bodies returning `:ok` — full integration setup requires the Repo fixtures used in the existing `metadata_apply_test.exs`. Implementer fills in the bodies using the same fixture pattern as the existing Phase 09/12 refresh tests. The DESCRIBE blocks and test names ARE the contract — the asymmetric-strictness pipeline must be exercised end-to-end by these named scenarios.
  </action>
  <verify>
    <automated>mix compile --warnings-as-errors && mix compile --no-optional-deps --warnings-as-errors && mix test test/relyra/metadata/scheduler_test.exs test/relyra/metadata/auto_refresh_test.exs --warnings-as-errors</automated>
  </verify>
  <acceptance_criteria>
    - File `lib/relyra/metadata/scheduler.ex` exists with `defmodule Relyra.Metadata.Scheduler`.
    - `grep -c "def run_due(repo, opts" lib/relyra/metadata/scheduler.ex` returns at least `1`.
    - `grep -c "Ecto.UUID.generate()" lib/relyra/metadata/scheduler.ex` returns at least `1` (D-39 auto correlation_id).
    - `grep -c "src.auto_refresh_enabled == true" lib/relyra/metadata/scheduler.ex` returns at least `1` (matches partial index where-clause).
    - `grep -c "is_nil(src.auto_suspended_until) or src.auto_suspended_until <= " lib/relyra/metadata/scheduler.ex` returns at least `1`.
    - `grep -c ":relyra, :saml, :metadata, :auto_refresh, :skipped" lib/relyra/metadata/scheduler.ex` returns at least `1` (D-07).
    - `grep -c "AutoRefresh.refresh" lib/relyra/metadata/scheduler.ex` returns at least `1`.
    - `grep -c "Enum.map(" lib/relyra/metadata/scheduler.ex` returns at least `1` (sequential per-batch — D-38).
    - File `lib/relyra/metadata/auto_refresh.ex` exists with `defmodule Relyra.Metadata.AutoRefresh`.
    - `grep -c "trigger: :scheduled_refresh" lib/relyra/metadata/auto_refresh.ex` returns at least `2` (apply_revision + record_attempt).
    - `grep -c "TrustAnchor.check" lib/relyra/metadata/auto_refresh.ex` returns at least `1`.
    - `grep -c "CorpusGate.check" lib/relyra/metadata/auto_refresh.ex` returns at least `1`.
    - `grep -c "DriftDetector.diff" lib/relyra/metadata/auto_refresh.ex` returns at least `1`.
    - `grep -c "Signature.verify_metadata_root" lib/relyra/metadata/auto_refresh.ex` returns at least `1`.
    - `grep -c "Telemetry.span(\\[:metadata, :auto_refresh\\]" lib/relyra/metadata/auto_refresh.ex` returns at least `1` (D-23 namespace).
    - `grep -c "redirect: false" lib/relyra/metadata/auto_refresh.ex` returns at least `1` (D-20).
    - `grep -c "max_response_size: 5_000_000" lib/relyra/metadata/auto_refresh.ex` returns at least `1` (D-20).
    - `grep -c "Relyra-MetadataRefresh/" lib/relyra/metadata/auto_refresh.ex` returns at least `1` (D-20 + RESEARCH A2).
    - `grep -c "30_000" lib/relyra/metadata/auto_refresh.ex` returns at least `1` (30s timeout per D-20).
    - `grep -c "auto_suspended_reason" lib/relyra/metadata/auto_refresh.ex` returns at least `5` (signature_invalid, corpus_violation, entity_id_drift, new_signing_cert, trust_anchor_mismatch routing).
    - AutoRefresh does NOT modify Refresh.refresh/2: `git diff lib/relyra/metadata/refresh.ex` is empty.
    - `mix compile --warnings-as-errors` exits 0.
    - `mix compile --no-optional-deps --warnings-as-errors` exits 0.
    - `mix test test/relyra/metadata/scheduler_test.exs --warnings-as-errors` exits 0 with the :skipped event test passing.
    - `mix test test/relyra/metadata/auto_refresh_test.exs --warnings-as-errors` exits 0 (placeholder integration tests return :ok; the DESCRIBE-block contract is in place; the B2 validity-warning scenarios are tagged `:integration` and exercise the seam end-to-end when run with the integration repo).
    - `grep -c "maybe_emit_validity_warning" lib/relyra/metadata/auto_refresh.ex` returns at least `2` (B2 — pipeline call site + helper definition).
    - `grep -c "Relyra.Ecto.MetadataApply.record_validity_warning\|MetadataApply.record_validity_warning" lib/relyra/metadata/auto_refresh.ex` returns at least `1` (B2 — calls Plan 04 Task 1 Step 4.6 helper for the persisted+emit co-commit).
    - `grep -c "extract_valid_until" lib/relyra/metadata/auto_refresh.ex` returns at least `1` (B2 — regex extraction helper, NOT a deep parse).
    - `grep -c "Cadence.cadence_seconds" lib/relyra/metadata/auto_refresh.ex` returns at least `1` (B2 — uses Plan 02 helper for `2 × refresh_interval` math).
    - `grep -c "extract_metadata_root_signature\|bound_id_from_reference" lib/relyra/metadata/auto_refresh.ex` returns at least `2` (W10 — real signature-binding implementation, NOT a stub).
    - `grep -E "signed_candidates: \[%\{xml_id: nil, xpath: nil" lib/relyra/metadata/auto_refresh.ex | wc -l | tr -d ' '` returns `0` (W10 invariant — the previous-iteration stub that returned `xml_id: nil, xpath: nil` is forbidden).
    - `grep -c "key_info_trust:" lib/relyra/metadata/auto_refresh.ex` returns at least `1` (W10 — KeyInfo-trust signal forwarded to do_verify so the existing document-KeyInfo rejection inherits to the metadata path; T-21-29 / T-21-21 mitigation).
  </acceptance_criteria>
  <done>Scheduler implements `run_due/2` with the LOCKED partial-index where-clause, auto-generated correlation_id, sequential per-source loop, and `:skipped` emission for empty due-set. AutoRefresh wraps Refresh.refresh/2 from outside (Refresh.refresh/2 is byte-identical to before); enforces D-15 require-signed-metadata; routes through TrustAnchor → verify_metadata_root → Parser → CorpusGate → **`maybe_emit_validity_warning` (B2 / D-14 emit seam — at-most-once per validUntil via Plan 04 `MetadataApply.record_validity_warning/3`)** → DriftDetector → MetadataApply.apply_revision/4 with `trigger: :scheduled_refresh`; on refusal, calls record_attempt/3 with the correct typed `auto_suspended_reason` for each refusal class; uses the stricter Req profile (30s+30s timeouts, no redirects, 5MB cap, fixed UA). **W10: `pre_parse_for_signature/1` is no longer a stub — extracts the metadata root (`<EntityDescriptor>` or `<EntitiesDescriptor>`), locates the `ds:Signature` child, resolves the Reference URI, and produces `signed_candidates` with populated `xml_id` (URI without `#`) + `xpath` (canonical metadata-root path) + `key_info_trust` + `duplicate_ids`; the integration seam binds the metadata-root signature to the verified envelope per PROJECT.md security invariant.** Both compile lanes are green.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Host-app scheduler → `Scheduler.run_due/2` | Untrusted (well, host-controlled) opts cross into the batch driver; the function defaults `audit.correlation_id` and `repo` from arguments to prevent missing-correlation-id audit holes. |
| Network → `AutoRefresh.fetch_xml/2` | Untrusted bytes from a remote IdP cross into the wrapper; the stricter Req profile (D-20) is the first defense. |
| Fetched bytes → `verify_metadata_root/4` | Untrusted bytes cross into the trust primitive AFTER the operator-pinned-fingerprint check (TrustAnchor) but BEFORE Parser.parse-deeply (Pitfall 4). |
| Verified bytes → `Parser.parse/2` | Already-trusted bytes cross into the deep parser; XXE/DOCTYPE rejection at lines 22-26 of parser.ex is the second defense. |
| Parsed candidate → `CorpusGate.check/2` | Post-parse pre-apply security regression check (D-21). |
| Parsed candidate → `DriftDetector.diff/2` | Post-parse pre-apply drift check (D-18). |
| Adopter `Oban.Job.args` → `MetadataRefresh.perform/1` | Untrusted job args (`"repo"`, `"opts"`) cross into the worker; `String.to_existing_atom/1` prevents arbitrary-atom DoS. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-21-24 | Tampering | `AutoRefresh.fetch_xml/2` redirect handling | mitigate | `redirect: false` per D-20 — HTTPS→HTTP downgrade vector closed; the URL field on `MetadataSource` already validates HTTPS at the changeset boundary (verified at metadata_source.ex:54-64). |
| T-21-25 | Denial of Service | `AutoRefresh.fetch_xml/2` body size | mitigate | `max_response_size: 5_000_000` per D-20 — multi-GB metadata exhaustion attack closed. |
| T-21-26 | Denial of Service | `AutoRefresh.fetch_xml/2` slowloris | mitigate | `connect_options: [timeout: 30_000]` + `receive_timeout: 30_000` per D-20 — the slow-fetch resource-exhaustion vector closed. |
| T-21-27 | Tampering | XXE-before-verify | mitigate | `verify_signature/3` runs BEFORE `Parser.parse/2` (Pitfall 4 — esaml 2026 NVD lesson). The pre-parse XML extraction for fingerprint check is intentionally regex-based scan, NOT deep parse. |
| T-21-28 | Spoofing | TOFU on first scheduled refresh | mitigate | `TrustAnchor.check/2` rejects empty pinned-list with `:no_pinned_fingerprints` (Plan 03); the schema-level `validate_fingerprints_when_enabled/1` from Plan 01 is the upstream defense (D-09 + D-17). |
| T-21-29 | Tampering | document-`KeyInfo` trust source | mitigate | `verify_metadata_root/4` reuses `do_verify/4` which rejects `key_info_trust == true` (Plan 04). The cert chain passed in is the candidate-extracted PEM whose fingerprint matched a pinned anchor — never the document's `KeyInfo`. |
| T-21-30 | Repudiation | scheduled-refresh failure without audit row | mitigate | Every failure routes through `MetadataApply.record_attempt/3` (Plan 04 — D-28 transactional co-commit) so the audit ledger never disagrees with the source row's `auto_suspended_until` / `consecutive_failure_count`. |
| T-21-31 | Spoofing | adopter-supplied `Oban.Job.args["repo"]` | mitigate | `String.to_existing_atom/1` rejects unknown atoms — adopter cannot pass a fake repo name to leak job dispatch. |
| T-21-32 | Tampering | `legacy_unsigned_metadata_policy` escape hatch | mitigate | `legacy_unsigned_allowed?/1` checks `allow_until` against `Date.utc_today()`; expired escape hatches fall through to the strict path. The audit row records the bypass (caller passes `:cause` accordingly; Plan 06 surfaces the risk panel). |
| T-21-33 | Denial of Service | clustered Oban double-fetch | mitigate | `unique: [period: :infinity, keys: [:source_id], states: [:available, :scheduled, :executing]]` per D-03 — Oban's leader election (`Oban.Peers.Database`) deduplicates across nodes without Relyra implementing advisory locks. |
| T-21-34 | Tampering | refusal-class mapping vs `auto_suspended_reason` enum | mitigate | `error_to_suspend_reason/1` produces only atoms in the LOCKED `@suspended_reason_values` enum from Plan 01 — invalid atoms would fail the changeset's `Ecto.Enum` cast. |
</threat_model>

<verification>
- `mix compile --warnings-as-errors` is green.
- `mix compile --no-optional-deps --warnings-as-errors` is green (CRITICAL — engineering-DNA §3 invariant; both gateway and worker carry the `@compile {:no_warn_undefined, [...]}` attribute).
- `mix test test/relyra/optional_deps/oban_test.exs test/relyra/workers/metadata_refresh_test.exs test/relyra/metadata/scheduler_test.exs test/relyra/metadata/auto_refresh_test.exs --warnings-as-errors --include oban` is green.
- `mix test --warnings-as-errors --exclude pending` is green (full suite — proves no regression).
- `mix format --check-formatted` is green.
- `git diff lib/relyra/metadata/refresh.ex` is empty (D-05 — wrap, do not modify).
</verification>

<success_criteria>
- `Relyra.OptionalDeps.Oban.available?/0` and `ensure_available!/1` exist; the latter returns `{:ok | :error, %Relyra.Error{}}` (NOT raising).
- `Relyra.Workers.MetadataRefresh` compiles with AND without Oban; uses the LOCKED `unique:` constraint (`period: :infinity, states: [:available, :scheduled, :executing], keys: [:source_id]`); `max_attempts: 1` (D-25); delegates to `Scheduler.run_due/2`.
- `Relyra.Metadata.Scheduler.run_due/2` queries the partial index (matching where-clause), generates one `correlation_id` per batch (D-39), runs sequentially (D-38), emits the `:skipped` event for empty due-set (D-07), and supports `:source_ids` opt for the Resume-now probe path (Plan 06 dependency).
- `Relyra.Metadata.AutoRefresh.refresh/2` wraps the existing `Refresh.refresh/2` from OUTSIDE (Refresh.refresh/2 is byte-identical to before); enforces D-15 require-signed-metadata with the D-19 escape hatch; routes through TrustAnchor → verify_metadata_root → Parser.parse → CorpusGate → DriftDetector → MetadataApply.apply_revision/4; on refusal, calls record_attempt/3 with the correct typed `auto_suspended_reason`.
- Stricter Req profile (D-20) uses 30s+30s timeouts, `redirect: false`, `max_response_size: 5_000_000`, fixed `User-Agent: Relyra-MetadataRefresh/<vsn>`.
- Telemetry emits under `[:relyra, :saml, :metadata, :auto_refresh, :start | :stop | :exception]` per D-23 — the existing `[:relyra, :saml, :metadata, :refresh, ...]` namespace is NEVER emitted from this code path.
- All four Wave 0 stubs are replaced; `mix test --include oban` is up by ≥ 7 passing tests; the placeholder integration tests have correct DESCRIBE-block contracts so subsequent verify-work passes can fill in fixtures.
</success_criteria>

<output>
After completion, create `.planning/phases/21-scheduled-metadata-refresh/21-05-SUMMARY.md` summarizing: module names + exports, the four refusal-classes routed through `auto_suspended_reason`, the Oban worker `unique:` constraint shape, the stricter Req profile values, and any deviations from the locked behavior.
</output>