---
phase: 21-scheduled-metadata-refresh
plan: 07
subsystem: operations
tags: [telemetry, mix-tasks, optional-deps, oban, docs, brand-voice, ci, exunit]

requires:
  - phase: 21-scheduled-metadata-refresh
    plan: 01
    provides: Relyra.Ecto.MetadataSource auto_refresh_changeset/2 — the operator-facing changeset (D-09 great-error refusing to enable auto-refresh without pinned fingerprints) that pin_trust_fingerprint/3 delegates to
  - phase: 21-scheduled-metadata-refresh
    plan: 05
    provides: Relyra.Metadata.Scheduler.run_due/2 — the dormant scheduler entry point the new `mix relyra.refresh_due` task drives; Relyra.Workers.MetadataRefresh — the optional Oban worker the README "Oban Cron one-liner" recipe references
  - phase: 21-scheduled-metadata-refresh
    plan: 06
    provides: completed live-admin surface so the new README LogAlerts attach example and the deferred-to-v0.6 fingerprint UX context are accurate

provides:
  - "Relyra.Telemetry @moduledoc — extended with the documented `### metadata.auto_refresh` event catalog covering all 8 Phase-21 events (start/stop/exception + degraded/suspended/recovered + validity_warning + skipped) per D-23/D-24/D-07/D-30. Existing `### metadata.refresh` block byte-identical (D-23 separation invariant)."
  - "Relyra.Telemetry.Handlers.LogAlerts — opt-in reference handler (~75 LOC). attach/0 + detach/0 register/de-register `:relyra_auto_refresh_log_alerts` via `:telemetry.attach_many/4`; level-per-event mapping (info/warning/error/debug); drops 5 sensitive keys (`:xml`, `:metadata_xml`, `:certificate_pem`, `:pem`, `:private_key`) before Logger formatting. NOT default-attached (D-30) — adopters call `attach/0` from `Application.start/2`."
  - "Relyra.Metadata.pin_trust_fingerprint/3 — shared underlying helper for trust-anchor pinning. Looks up Connection + MetadataSource and runs the operator-facing `auto_refresh_changeset/2` (which carries the Plan-01 D-09 great-error). Standard `{:ok, _} | {:error, %Relyra.Error{}}` contract."
  - "Mix.Tasks.Relyra.RefreshDue — `mix relyra.refresh_due --repo MyApp.Repo`. Public moduledoc (visible under `mix help`); calls `Mix.Task.run(\"app.start\")`; rejects unknown repo atoms via `String.to_existing_atom/1` (T-21-31)."
  - "Mix.Tasks.Relyra.Metadata.Pin — `mix relyra.metadata.pin <connection_id> --fingerprint <hex> --repo MyApp.Repo`. Supports `--fingerprint :keep` for the D-17 multi-valued rotation window. Lower-cases supplied fingerprints. Delegates to the shared helper so the (deferred-to-v0.6) admin LiveView form and the CLI cannot drift."
  - "mix.exs — `{:oban, \"~> 2.22\", optional: true}` declared (resolves to 2.22.1 in mix.lock); new `ci.oban_smoke` alias chains both compile lanes + the Oban-present worker/gateway tests; alias added to preferred_envs."
  - "README.md \"Operations: Scheduled metadata refresh\" section — the four LOCKED scheduler recipes (Oban Cron + system cron + k8s CronJob YAML + fly.io [[machines.schedule]] TOML) per D-06, plus the fingerprint pin recipe and the LogAlerts attach example. Brand-voice grep clean (W11)."
affects: []

tech-stack:
  added:
    - "{:oban, \"~> 2.22\", optional: true} — declared in Relyra's mix.exs so the worker compile/test path becomes exercisable in CI; adopter still pins their own version. Resolved to 2.22.1 in mix.lock."
  patterns:
    - "Documented telemetry-event catalog: every `[:relyra, :saml, :metadata, :auto_refresh, ...]` event added to `Relyra.Telemetry`'s `@moduledoc` with measurements + metadata payload. The existing `### metadata.refresh` block is byte-identical so adopters with manual-refresh listeners are not destabilized (D-23 invariant). Future telemetry-emitting subsystems should follow the same shape: extend the catalog moduledoc rather than scatter event docs."
    - "Opt-in reference telemetry handler (D-30): `Relyra.Telemetry.Handlers.LogAlerts` ships in lib/ but is NOT auto-attached anywhere. The pattern is — provide a small reusable handler so adopters get something working with one `attach/0` call, but never couple Relyra to vendor paging. Future reference handlers MUST follow the same shape (no Application.start/2 attach)."
    - "Mix-task public moduledoc convention: tasks that are operator-facing (`relyra.refresh_due`, `relyra.metadata.pin`) use a real `@moduledoc` (NOT `@moduledoc false`) so they appear under `mix help`. Internal-only tasks (e.g. `relyra.install`'s scaffold helpers) keep `@moduledoc false`. Both new tasks call `Mix.Task.run(\"app.start\")` to boot the host repo before invoking domain code."
    - "Shared-changeset UX-symmetry pattern (D-22 + RESEARCH Q1): the Mix task and the (forthcoming v0.6) admin LiveView form both delegate to `Relyra.Metadata.pin_trust_fingerprint/3`, which itself runs `MetadataSource.auto_refresh_changeset/2`. Two surfaces, one underlying changeset → the audit trail and validation rules cannot drift. Future operator-facing pairs (CLI + LiveView form, IaC + UI, etc.) should follow the same shape."
    - "Defensive wildcard fallthrough for typed cross-lane returns: the new Mix task uses `case ... do {:ok, _} -> ...; other -> ... end` rather than an explicit `{:error, _}` clause because Elixir 1.19's set-theoretic typer can see through the present-Ecto branch of `Scheduler.run_due/2` (which only returns `{:ok, _}`) and would flag the explicit error clause as unreachable. The wildcard preserves correctness for the Ecto-absent stub branch without violating the typer. Pattern reusable wherever a function call straddles two `Code.ensure_loaded?`-gated compile lanes whose return types differ."
    - "ci.oban_smoke as the optional-deps regression gate: the alias chains `compile --no-optional-deps --warnings-as-errors` (engineering-DNA §3 invariant) FIRST so a regression in the gateway's `@compile {:no_warn_undefined, [...]}` posture is caught before the Oban-present compile + test runs. Future optional-dep gateways that expose a worker / dispatcher should ship a sibling `ci.<dep>_smoke` alias following this shape."

key-files:
  created:
    - lib/relyra/telemetry/handlers/log_alerts.ex
    - lib/mix/tasks/relyra.refresh_due.ex
    - lib/mix/tasks/relyra.metadata.pin.ex
  modified:
    - lib/relyra/telemetry.ex                                  # @moduledoc extended with `### metadata.auto_refresh` block; existing `### metadata.refresh` byte-identical (D-23 invariant)
    - lib/relyra/metadata.ex                                   # added pin_trust_fingerprint/3 + format_changeset_errors/1; existing 3 public functions unchanged
    - lib/relyra/workers/metadata_refresh.ex                   # Rule 3: switched `{:error, _} = err -> err` to defensive wildcard `other -> other` (Elixir 1.19 typer narrowed Scheduler.run_due/2 to `{:ok, _}` only after Oban became a real dep)
    - mix.exs                                                  # added `{:oban, "~> 2.22", optional: true}`, `ci.oban_smoke` alias, alias added to preferred_envs
    - mix.lock                                                 # Oban 2.22.1 resolved
    - README.md                                                # new "Operations: Scheduled metadata refresh" section with the four LOCKED recipes + pin recipe + LogAlerts attach example
    - test/relyra/telemetry/handlers/log_alerts_test.exs       # Wave-0 stub replaced; 13 tests across 4 describe blocks (attach/detach idempotence + level-per-event + redaction + D-30 not-auto-attached)
    - test/mix/tasks/relyra_refresh_due_test.exs               # Wave-0 stub replaced; 2 argument-validation tests (--repo required + repo atom must be loaded)
    - test/mix/tasks/relyra_metadata_pin_test.exs              # Wave-0 stub replaced; 4 argument-validation tests (connection_id required + --fingerprint required + --repo required + repo atom must be loaded)
    - test/relyra/workers/metadata_refresh_test.exs            # Rule 3 fix: switched to MigrationCase (sandbox checkout needed once Oban is real); apply/3 used in absent-lane test to bypass typer narrowing

key-decisions:
  - "Rule 3 deviation: defensive wildcard fallthrough in `Mix.Tasks.Relyra.RefreshDue.run/1`. Elixir 1.19 set-theoretic typing narrows `Relyra.Metadata.Scheduler.run_due/2`'s return type to `{:ok, _}` (only) when compiled in the present-Ecto lane — the Ecto-absent stub's `{:error, _}` is invisible to the typer at the call site. An explicit `{:error, _} -> ...` clause is flagged as unreachable. Switched to `case ... do {:ok, _} -> ...; other -> ... end` so the typer is satisfied AND the absent-Ecto error path still surfaces a `Mix.raise`."
  - "Rule 3 deviation: defensive wildcard fallthrough in `Relyra.Workers.MetadataRefresh.perform/1`. Same root cause as the Mix-task fix above. Plan 21-05 wrote `{:error, _} = err -> err`; Plan 21-07 changed it to `other -> other` because the addition of `{:oban, \"~> 2.22\", optional: true}` to mix.exs made the typer aware that `Scheduler.run_due/2`'s present-Ecto body only returns `{:ok, _}`. Pre-21-07 the typer didn't see this because Oban wasn't loaded so `Workers.MetadataRefresh` was the Oban-absent stub body, which has no Scheduler call site."
  - "Rule 3 deviation: `test/relyra/workers/metadata_refresh_test.exs` switched from `ExUnit.Case, async: true` to `Relyra.TestSupport.MigrationCase, async: false`. Plan 21-05's test was written assuming Oban was NOT loaded in CI (so `ObanGateway.available?()` returned `false` and the test took the `unless` branch and short-circuited to `:ok`). Plan 21-07 added Oban as a real dep, so `available?()` is now `true`, the test actually invokes `Scheduler.run_due/2`, and the lack of an `Ecto.Adapters.SQL.Sandbox` checkout raises an OwnershipError. MigrationCase performs the checkout per test."
  - "Rule 3 deviation: `apply/3` indirection in the Oban-absent test scenario. Plan 21-05 wrote `MetadataRefresh.perform(:irrelevant)`; the present-lane `perform/1` typespec is `Oban.Job`-only. Once Oban is loaded the present-lane signature wins compilation, and a literal `:irrelevant` atom argument is flagged by the typer. `apply(MetadataRefresh, :perform, [:irrelevant])` bypasses static dispatch type-checking. Both lanes now compile."
  - "Test scope decision: Mix-task happy-path scenarios (`:integration`-tagged) are NOT exercised in this plan's test suite. The validation matrix in `21-VALIDATION.md` already classifies Mix-task wiring + the four LOCKED README recipes as MANUAL-ONLY verifications (require a configured host repo + DB + a real adopter project). The argument-validation flow IS exercised — every Mix.raise great-error string is asserted from a clean ExUnit.Case. This matches the same-shape Plan 05 scheduler tests (unit-level invariants asserted; full integration deferred to manual)."
  - "Defense-in-depth choice: `pin_trust_fingerprint/3` delegates to `auto_refresh_changeset/2` (the operator-facing changeset) rather than `health_state_changeset/2`. The operator-facing changeset enforces the D-09 great-error (cannot enable auto-refresh without at least one pinned fingerprint) AND its cast whitelist excludes health-state columns — so the Mix task cannot mutate health state through the operator path (D-28 invariant preserved). Future operator-facing helpers MUST follow the same shape (operator-facing changeset, NOT health-state changeset)."

requirements-completed:
  - CFG-08

duration: ~9min
completed: 2026-05-07
---

# Phase 21 Plan 07: Mix Tasks + Telemetry Catalog + Operations Docs Summary

**Lands the operations + observability + adoption surface for Phase 21 — closing CFG-08. Adds the documented `[:relyra, :saml, :metadata, :auto_refresh, ...]` telemetry catalog (D-23/D-24/D-07/D-30), the opt-in reference `Relyra.Telemetry.Handlers.LogAlerts` handler (D-30 — NOT default-attached), two operator Mix tasks (`mix relyra.refresh_due` + `mix relyra.metadata.pin`) sharing one underlying changeset (D-22 + RESEARCH Q1), the optional Oban dep declaration in `mix.exs`, the `ci.oban_smoke` alias for the Oban-present compile/test lane, and the README "Operations: Scheduled metadata refresh" section with the four LOCKED scheduler recipes (Oban Cron + system cron + k8s CronJob YAML + fly.io scheduled machines TOML — D-06). Brand-voice grep clean (W11) across the telemetry catalog, LogAlerts handler, both Mix tasks, and the README operations section.**

## Performance

- **Duration:** ~9 min
- **Started:** 2026-05-07T03:26:40Z (UTC) — pre-Task-1 read-throughs
- **Completed:** 2026-05-07T03:35:53Z (UTC) — Task 3 commit `f4bf983`
- **Tasks:** 3 / 3
- **Files created or modified:** 10 (3 new lib/ files + 4 modified lib/ + mix.exs + mix.lock + README + 4 modified test files; the 3 LogAlerts/Mix-task test files were Wave-0 stubs from Plan 01 and are replaced in place; the worker test was modified for the Rule-3 sandbox fix)

## Accomplishments

### Task 1: Telemetry catalog + LogAlerts reference handler (`06ca068`)

- **`Relyra.Telemetry` `@moduledoc` extended** with a new `### metadata.auto_refresh` doc block listing all 8 Phase-21 events:
  - Span events (start / stop / exception) — D-23
  - State-transition events (degraded / suspended / recovered) — D-24
  - Validity-warning event — D-14
  - Empty-tick `:skipped` event — D-07
- The existing `### metadata.refresh` block is byte-identical to before (D-23 separation invariant — manual-path operator-action audit listeners stay untouched).
- **`Relyra.Telemetry.Handlers.LogAlerts`** (~75 LOC after format) — opt-in reference handler:
  - `attach/0` calls `:telemetry.attach_many/4` with the canonical handler id `:relyra_auto_refresh_log_alerts` over all 8 documented events.
  - `detach/0` removes the handler.
  - `handle_event/4` dispatches to a level-per-event Logger call (info / warning / error / debug); the `:stop` clause is level-aware (`:ok` outcome → info, error outcome → warning).
  - Drops sensitive keys (`:xml`, `:metadata_xml`, `:certificate_pem`, `:pem`, `:private_key`) before the Logger formatter sees them — same posture as `Relyra.Log`.
  - Per D-30: NOT default-attached anywhere in `lib/`. Grep-proven: no runtime `LogAlerts.attach()` outside the module itself; the only references in `lib/` are inside `@moduledoc` strings.
- **13 tests** in `test/relyra/telemetry/handlers/log_alerts_test.exs` across 4 describe blocks: attach/detach idempotence (2), level-per-event mapping (8 — one per event type), redaction (1), D-30 not-auto-attached invariant (1).

### Task 2: `pin_trust_fingerprint/3` + the two Mix tasks (`aa25260`)

- **`Relyra.Metadata.pin_trust_fingerprint/3`** (added inside the existing `Relyra.Metadata` public-API module): the shared underlying helper. Looks up Connection by `connection_id` then MetadataSource by `connection_record_id`; runs `Relyra.Ecto.MetadataSource.auto_refresh_changeset/2` (the operator-facing changeset, NOT `health_state_changeset/2` — D-28); standard `{:ok, _} | {:error, %Relyra.Error{}}` contract; emits typed errors `:connection_not_found`, `:metadata_source_not_found`, `:invalid_metadata_source`. The shared underlying changeset means the Mix task and the (forthcoming v0.6) admin LiveView fingerprint form cannot drift.
- **`Mix.Tasks.Relyra.RefreshDue`** (`lib/mix/tasks/relyra.refresh_due.ex`) — `mix relyra.refresh_due --repo MyApp.Repo`:
  - Public `@moduledoc` (visible under `mix help`).
  - Calls `Mix.Task.run("app.start")` to boot the host repo.
  - Rejects unknown repo atoms via `String.to_existing_atom/1` (T-21-31 mitigation).
  - Wraps `Relyra.Metadata.Scheduler.run_due/2`; uses defensive wildcard fallthrough (`other -> ...`) for the Ecto-absent stub branch (Rule 3 deviation — see Decisions Made).
- **`Mix.Tasks.Relyra.Metadata.Pin`** (`lib/mix/tasks/relyra.metadata.pin.ex`) — `mix relyra.metadata.pin <connection_id> --fingerprint <hex> --repo MyApp.Repo`:
  - Public `@moduledoc` with the `openssl` fingerprint-compute recipe inline (operator MUST verify out-of-band — D-17).
  - Supports `--fingerprint :keep` for D-17 multi-valued rotation window (multiple `--fingerprint <hex>` flags per invocation).
  - Lower-cases supplied fingerprints for normalization.
  - Documents that the pin REPLACES the array (operator must supply every desired fingerprint to extend).
  - Delegates to `Relyra.Metadata.pin_trust_fingerprint/3`.
- **6 tests** across the two Mix-task test files: argument validation (`--repo`/connection_id/`--fingerprint` required), unknown-repo-atom rejection. Happy-path scenarios are deferred to manual integration validation per `21-VALIDATION.md`.

### Task 3: Optional Oban dep + ci.oban_smoke alias + README operations (`f4bf983`)

- **`mix.exs`**:
  - Added `{:oban, "~> 2.22", optional: true}` (resolves to Oban 2.22.1 in `mix.lock`).
  - New `ci.oban_smoke` alias chains: `compile --no-optional-deps --warnings-as-errors` (engineering-DNA §3 invariant) → `compile --warnings-as-errors` → `test --include oban --warnings-as-errors test/relyra/optional_deps/oban_test.exs test/relyra/workers/metadata_refresh_test.exs`.
  - Added `ci.oban_smoke` to `preferred_envs` so it runs in `:test`.
- **Worker delegate fix** (Rule 3 deviation, `lib/relyra/workers/metadata_refresh.ex`): with Oban now actually loaded, Elixir 1.19's typer narrowed `Scheduler.run_due/2`'s return type to `{:ok, _}` only — Plan 21-05's `{:error, _} = err -> err` clause was flagged as unreachable. Switched to a defensive `other -> other` wildcard.
- **Worker test fixture fix** (Rule 3 deviation, `test/relyra/workers/metadata_refresh_test.exs`): switched from `ExUnit.Case, async: true` to `Relyra.TestSupport.MigrationCase, async: false` because the present-lane delegate test now actually invokes `Scheduler.run_due/2` and needs a Sandbox checkout. The Oban-absent test uses `apply/3` to invoke `perform(:irrelevant)` so the present-lane Oban.Job-typed signature doesn't reject the atom argument at compile time.
- **README** — new `## Operations: Scheduled metadata refresh` section ships:
  - Option 1: Oban Cron one-liner with the LOCKED `Oban.Plugins.Cron` config snippet
  - Option 2: Mix task driven by system cron with the `* * * * *` crontab line
  - Option 3: Kubernetes `kind: CronJob` YAML
  - Option 4: fly.io `[[machines.schedule]]` TOML
  - Pinning a metadata trust fingerprint (with the `openssl` recipe + `mix relyra.metadata.pin` invocation)
  - Telemetry events (with the `LogAlerts.attach/0` opt-in example)
- **Brand-voice grep invariant (W11)** — clean across all surfaces: zero `polling | cron job | blocked | retry | circuit breaker | maxbackoff` matches in mix tasks, telemetry catalog, LogAlerts handler, or outside fenced code blocks in the README operations section. Literal `cron` / `crontab` / `Cron` only appears inside fenced code blocks where it documents the host's own scheduling vocabulary (Oban Cron, system crontab, k8s `kind: CronJob`, fly.io `[[machines.schedule]]`) — never as a description of Relyra's own behavior.
- **`mix ci.oban_smoke` exits 0** (8 tests, 0 failures across both compile lanes + the Oban-present worker + gateway).

## Task Commits

1. **Task 1: telemetry catalog + LogAlerts handler** — `06ca068` (feat)
2. **Task 2: pin_trust_fingerprint/3 + two Mix tasks** — `aa25260` (feat)
3. **Task 3: Oban dep + ci.oban_smoke + README operations** — `f4bf983` (feat)

**Plan metadata commit:** to follow this SUMMARY.md (docs commit per protocol).

## Files Created/Modified

### Created

- `lib/relyra/telemetry/handlers/log_alerts.ex` — opt-in reference handler (~75 LOC after format).
- `lib/mix/tasks/relyra.refresh_due.ex` — public Mix task wrapping `Scheduler.run_due/2`.
- `lib/mix/tasks/relyra.metadata.pin.ex` — public Mix task wrapping `Metadata.pin_trust_fingerprint/3`.

### Modified

- `lib/relyra/telemetry.ex` — `@moduledoc` extended with `### metadata.auto_refresh` block; existing `### metadata.refresh` byte-identical (D-23).
- `lib/relyra/metadata.ex` — added `pin_trust_fingerprint/3` + private `format_changeset_errors/1`; existing 3 public functions byte-identical.
- `lib/relyra/workers/metadata_refresh.ex` — Rule 3: switched `{:error, _} = err -> err` to defensive wildcard `other -> other`.
- `mix.exs` — added `{:oban, "~> 2.22", optional: true}`, `ci.oban_smoke` alias, alias added to `preferred_envs`.
- `mix.lock` — Oban 2.22.1 resolved.
- `README.md` — new `## Operations: Scheduled metadata refresh` section ABOVE the existing `## Security` section.
- `test/relyra/telemetry/handlers/log_alerts_test.exs` — Wave-0 `:pending` stub (20 LOC, 1 flunk) → 209 LOC of green tests; 13 tests across 4 describe blocks.
- `test/mix/tasks/relyra_refresh_due_test.exs` — Wave-0 `:pending` stub → 28 LOC of green tests; 2 tests in 1 describe block.
- `test/mix/tasks/relyra_metadata_pin_test.exs` — Wave-0 `:pending` stub → 50 LOC of green tests; 4 tests in 1 describe block.
- `test/relyra/workers/metadata_refresh_test.exs` — Rule 3 sandbox fix: switched to `MigrationCase`; absent-lane test uses `apply/3` to bypass the typer narrowing.

## Decisions Made

1. **Rule 3 deviation: defensive wildcard fallthrough in `Mix.Tasks.Relyra.RefreshDue.run/1`.** Elixir 1.19's set-theoretic typing narrows `Relyra.Metadata.Scheduler.run_due/2`'s return type to `{:ok, _}` (only) when compiled in the present-Ecto lane — the Ecto-absent stub's `{:error, _}` is invisible to the typer at the call site. An explicit `{:error, _} -> ...` clause is flagged as unreachable. Switched to `case ... do {:ok, _} -> ...; other -> ... end` so the typer is satisfied AND the absent-Ecto error path still surfaces a `Mix.raise`.
2. **Rule 3 deviation: defensive wildcard fallthrough in `Relyra.Workers.MetadataRefresh.perform/1`.** Same root cause. Plan 21-05 wrote `{:error, _} = err -> err`; Plan 21-07 changed to `other -> other` because adding `{:oban, "~> 2.22", optional: true}` to `mix.exs` made the typer aware of `Scheduler.run_due/2`'s narrowed return type. Pre-21-07 the typer didn't see this because Oban wasn't loaded so `Workers.MetadataRefresh` was the Oban-absent stub body (no Scheduler call site).
3. **Rule 3 deviation: switched `metadata_refresh_test.exs` from async ExUnit.Case to MigrationCase.** Plan 21-05's test was written assuming Oban was NOT loaded in CI (`ObanGateway.available?()` returned `false`, test took the `unless` short-circuit to `:ok`). Plan 21-07 added Oban as a real dep so `available?()` is now `true`, the test actually invokes `Scheduler.run_due/2`, and the lack of a Sandbox checkout raises `Ecto.Adapters.SQL.Sandbox.OwnershipError`. `Relyra.TestSupport.MigrationCase` performs the checkout per test.
4. **Rule 3 deviation: `apply/3` indirection in the Oban-absent test scenario.** Plan 21-05 wrote `MetadataRefresh.perform(:irrelevant)`; the present-lane `perform/1` typespec is `Oban.Job`-only. Once Oban is loaded the present-lane signature wins compilation, and a literal `:irrelevant` atom argument is flagged by the typer. `apply(MetadataRefresh, :perform, [:irrelevant])` bypasses static dispatch type-checking. Both lanes now compile.
5. **Test scope decision: Mix-task happy-path scenarios are NOT exercised in this plan's automated suite.** The validation matrix in `21-VALIDATION.md` classifies Mix-task wiring + the four LOCKED README recipes as MANUAL-ONLY verifications. The argument-validation flow IS exercised — every `Mix.raise` great-error string is asserted (`--repo` required, connection_id required, `--fingerprint` required, unknown-repo-atom rejection). Same shape as Plan 21-05's scheduler unit tests (unit-level invariants asserted; full integration deferred).
6. **Defense-in-depth choice: `pin_trust_fingerprint/3` delegates to `auto_refresh_changeset/2`, NOT `health_state_changeset/2`.** The operator-facing changeset enforces the D-09 great-error (cannot enable auto-refresh without at least one pinned fingerprint) AND its cast whitelist excludes health-state columns — so the Mix task cannot mutate health state through the operator path (D-28 invariant preserved). Future operator-facing helpers MUST follow the same shape.

## Patterns Established

1. **Documented telemetry-event catalog inside `Relyra.Telemetry` `@moduledoc`.** Every `[:relyra, :saml, ...]` event is documented with its measurements + metadata payload in the central catalog. Future telemetry-emitting subsystems should extend the catalog rather than scatter event docs across the emitting modules. The existing convention (`### feature.event_name`) is preserved exactly — the new `### metadata.auto_refresh` block follows the same shape as `### metadata.refresh` and `### metadata.import`.
2. **Opt-in reference telemetry handler (D-30 shape).** `Relyra.Telemetry.Handlers.LogAlerts` ships in `lib/` but is NOT auto-attached anywhere — adopters opt in via `Application.start/2`. Future reference handlers (e.g. metrics emitters, span exporters) should follow the same shape: small, redaction-aware, attach-on-demand, no vendor coupling. The grep invariant (no `LogAlerts.attach()` outside the module itself in `lib/`) is the regression gate.
3. **Mix-task public moduledoc convention.** Operator-facing tasks use a real `@moduledoc` (visible under `mix help`); internal-only tasks use `@moduledoc false`. Both new tasks call `Mix.Task.run("app.start")` to boot the host repo before invoking domain code. Future operator-facing tasks should follow the same shape.
4. **Shared-changeset UX-symmetry pattern (D-22 + RESEARCH Q1).** Mix task + admin LiveView form (deferred to v0.6) both delegate to `Relyra.Metadata.pin_trust_fingerprint/3`, which itself runs `MetadataSource.auto_refresh_changeset/2`. Two surfaces, one underlying changeset → audit trail and validation rules cannot drift. Future operator-facing pairs (CLI + LiveView form, IaC + UI) should share one underlying domain-API helper.
5. **Defensive wildcard fallthrough for typed cross-lane returns.** When a function call straddles two `Code.ensure_loaded?`-gated compile lanes whose return types differ, use `case ... do {:ok, _} -> ...; other -> ... end` rather than an explicit `{:error, _}` clause. Elixir 1.19's set-theoretic typer can see through the present-dep branch and would flag the explicit error clause as unreachable. The wildcard preserves correctness for the absent-dep stub branch without violating the typer.
6. **`ci.<dep>_smoke` alias as the optional-deps regression gate.** The alias chains `compile --no-optional-deps --warnings-as-errors` FIRST so a regression in the gateway's `@compile {:no_warn_undefined, [...]}` posture is caught before the present-dep compile + tests run. Future optional-dep gateways that expose a worker / dispatcher should ship a sibling alias following this shape (e.g. `ci.oban_smoke`, future `ci.<x>_smoke`).
7. **Brand-voice grep invariant at the file layer.** Every operator-facing surface (mix tasks, telemetry catalog, LogAlerts handler, README operations section) is grep-asserted against the LOCKED forbidden token set: `polling | cron job | blocked | retry | circuit breaker | maxbackoff`. The literal `cron` / `crontab` / `Cron` is permitted ONLY inside fenced code blocks where it documents the host's own scheduling vocabulary, never Relyra's behavior. Pattern reusable for any future operator-facing surface governed by the brand book.

## Verification

- `mix compile --warnings-as-errors` — green (101 files compiled).
- `mix compile --no-optional-deps --warnings-as-errors` — green (101 files compiled; both lanes verified).
- `mix deps.get` — green; Oban 2.22.1 resolved cleanly.
- `mix ci.oban_smoke` — green (8 tests, 0 failures across both compile lanes + Oban-present worker + gateway tests).
- `mix test test/relyra/telemetry/handlers/log_alerts_test.exs --warnings-as-errors` — **13 tests, 0 failures**.
- `mix test test/mix/tasks/relyra_refresh_due_test.exs test/mix/tasks/relyra_metadata_pin_test.exs --warnings-as-errors` — **6 tests, 0 failures**.
- `mix test --warnings-as-errors --exclude pending --exclude integration` — **344 tests, 1 failure (11 excluded)**. The single failure is the pre-existing `Relyra.Phoenix.ACSControllerTest` `:name_id` `KeyError` documented in `.planning/phases/21-scheduled-metadata-refresh/deferred-items.md` (predates Phase 21 — same baseline as Plans 21-01..21-06).
- `mix help relyra.refresh_due` — prints the moduledoc; task publicly listed.
- `mix help relyra.metadata.pin` — prints the moduledoc; task publicly listed.
- `mix format` clean on every file touched by this plan.
- Brand-voice grep invariant (W11): `grep -ciE "(circuit breaker|maxbackoff)" README.md lib/relyra/telemetry.ex lib/relyra/telemetry/handlers/log_alerts.ex lib/mix/tasks/relyra.refresh_due.ex lib/mix/tasks/relyra.metadata.pin.ex` returns 0. Outside fenced code blocks in the README operations section, `polling | cron job | blocked | retry` returns 0.

## Acceptance Criteria (Per-Task)

### Task 1 — wired

- `grep -c "### metadata.auto_refresh" lib/relyra/telemetry.ex` = 1 (≥ 1) ✓
- `grep -c "### metadata.refresh" lib/relyra/telemetry.ex` = 1 (exactly 1 — D-23 invariant) ✓
- `grep -cE ":(start|stop|exception|degraded|suspended|recovered|validity_warning|skipped)" lib/relyra/telemetry.ex` = 14 (≥ 8) ✓
- `lib/relyra/telemetry/handlers/log_alerts.ex` exists with `defmodule Relyra.Telemetry.Handlers.LogAlerts` ✓
- `wc -l lib/relyra/telemetry/handlers/log_alerts.ex | awk '{print $1}'` = 75 (≤ 80; ~50 LOC target with format expansion) ✓
- `grep -c "def attach" lib/relyra/telemetry/handlers/log_alerts.ex` = 1 (≥ 1) ✓
- `grep -c "def detach" lib/relyra/telemetry/handlers/log_alerts.ex` = 1 (≥ 1) ✓
- `grep -c ":telemetry.attach_many" lib/relyra/telemetry/handlers/log_alerts.ex` = 1 (≥ 1) ✓
- `grep -c "@handler_id :relyra_auto_refresh_log_alerts" lib/relyra/telemetry/handlers/log_alerts.ex` = 1 (≥ 1) ✓
- `grep -rn "LogAlerts.attach" lib/ | grep -v "lib/relyra/telemetry/handlers/log_alerts.ex"` returns only `lib/relyra/telemetry.ex:108` (inside `@moduledoc`, NOT runtime code) — D-30 invariant satisfied ✓
- `mix test test/relyra/telemetry/handlers/log_alerts_test.exs --warnings-as-errors` — green (13 tests) ✓
- `mix compile --warnings-as-errors` — green ✓
- `mix compile --no-optional-deps --warnings-as-errors` — green ✓
- W11: `grep -ciE "(polling|cron job|blocked|retry|circuit breaker|maxbackoff)" lib/relyra/telemetry.ex lib/relyra/telemetry/handlers/log_alerts.ex` = 0 ✓

### Task 2 — wired

- `grep -c "def pin_trust_fingerprint" lib/relyra/metadata.ex` = 3 (≥ 1; default-args clause + 2 implementation heads) ✓
- `grep -c "MetadataSource.auto_refresh_changeset" lib/relyra/metadata.ex` = 1 (≥ 1) ✓
- `grep -c "def import_xml\|def register_source\|def refresh\|def pin_trust_fingerprint" lib/relyra/metadata.ex` = 12 (≥ 4 — 3 existing × 3-clause + 4th × 3-clause) ✓
- `lib/mix/tasks/relyra.refresh_due.ex` exists with `defmodule Mix.Tasks.Relyra.RefreshDue` ✓
- `grep -c "@shortdoc " lib/mix/tasks/relyra.refresh_due.ex` = 1 (≥ 1) ✓
- `grep -c "@moduledoc " lib/mix/tasks/relyra.refresh_due.ex` = 1 (≥ 1; non-`false`) ✓
- `grep -c "@moduledoc false" lib/mix/tasks/relyra.refresh_due.ex` = 0 ✓
- `grep -c 'Mix.Task.run("app.start")' lib/mix/tasks/relyra.refresh_due.ex` = 1 (≥ 1) ✓
- `grep -c "Relyra.Metadata.Scheduler.run_due" lib/mix/tasks/relyra.refresh_due.ex` = 1 (≥ 1) ✓
- `lib/mix/tasks/relyra.metadata.pin.ex` exists with `defmodule Mix.Tasks.Relyra.Metadata.Pin` ✓
- `grep -c "Relyra.Metadata.pin_trust_fingerprint" lib/mix/tasks/relyra.metadata.pin.ex` = 1 (≥ 1) ✓
- `grep -c "strict: \[fingerprint: :keep" lib/mix/tasks/relyra.metadata.pin.ex` = 1 (≥ 1; D-17 rotation) ✓
- `mix help relyra.refresh_due` exits 0 and prints the moduledoc ✓
- `mix help relyra.metadata.pin` exits 0 and prints the moduledoc ✓
- `mix test test/mix/tasks/relyra_refresh_due_test.exs test/mix/tasks/relyra_metadata_pin_test.exs --warnings-as-errors` — green (6 tests) ✓
- `mix compile --warnings-as-errors` — green ✓
- `mix compile --no-optional-deps --warnings-as-errors` — green ✓
- W11: `grep -ciE "(polling|cron job|blocked|retry|circuit breaker|maxbackoff)" lib/mix/tasks/relyra.refresh_due.ex lib/mix/tasks/relyra.metadata.pin.ex` = 0 ✓

### Task 3 — wired

- `grep -c "{:oban, \"~> 2.22\", optional: true}" mix.exs` = 1 (≥ 1) ✓
- `grep -c "ci.oban_smoke" mix.exs` = 2 (≥ 1; preferred_envs entry + alias key) ✓
- `grep -c "compile --no-optional-deps --warnings-as-errors" mix.exs` = 1 (≥ 1; inside ci.oban_smoke) ✓
- `grep -c "## Operations" README.md` = 1 (≥ 1; new top-level section) ✓
- `grep -c "relyra.refresh_due" README.md` = 3 (≥ 2; mix-task option + k8s CronJob + fly.io machine) ✓
- `grep -c "Oban.Plugins.Cron" README.md` = 1 (≥ 1; D-06 Oban Cron one-liner) ✓
- `grep -c "kind: CronJob" README.md` = 1 (≥ 1; D-06 k8s recipe) ✓
- `grep -c "machines.schedule" README.md` = 1 (≥ 1; D-06 fly.io recipe) ✓
- `grep -c "mix relyra.metadata.pin" README.md` = 1 (≥ 1; fingerprint pin recipe — D-22) ✓
- `grep -c ":relyra, :saml, :metadata, :auto_refresh" README.md` = 1 (≥ 1) ✓
- W11 (README operations, outside fenced code blocks): `polling|cron job|blocked|retry|circuit breaker|maxbackoff` = 0 ✓
- W11 (README anywhere): `circuit breaker|MaxBackoff` = 0 ✓
- `mix deps.get` — green; Oban 2.22.1 resolved ✓
- `mix compile --warnings-as-errors` — green ✓
- `mix compile --no-optional-deps --warnings-as-errors` — green (engineering-DNA §3 invariant preserved with Oban added) ✓
- `mix ci.oban_smoke` — green (8 tests, 0 failures) ✓
- `mix help relyra.refresh_due` — task listed ✓
- `mix help relyra.metadata.pin` — task listed ✓

## Pre-existing Out-of-Scope Issues (Deferred — same baseline as 21-01..21-06)

- `Relyra.Phoenix.ACSControllerTest` — `POST /:connection_id/acs success` trips a `KeyError :name_id` inside `FakeUserMapper.map_attributes/3`. Pre-existing on the Phase-21 parent commit `0842687`; documented in `.planning/phases/21-scheduled-metadata-refresh/deferred-items.md`. Not caused by Plan 21-07.
- Pre-existing `mix format` drift in `lib/relyra/live_admin/connections_live.ex` from a Phase 20 commit — untouched by Plan 21-07.

## User Setup Required

Adopters who want to use scheduled metadata refresh follow one of the four LOCKED README recipes:

1. **Oban Cron (recommended):** add `{:oban, "~> 2.22"}` to host deps, configure `Oban.Plugins.Cron` with the crontab line pointing at `Relyra.Workers.MetadataRefresh`.
2. **System cron + Mix task:** schedule `mix relyra.refresh_due --repo MyApp.Repo` via the host's `/etc/crontab` or equivalent.
3. **Kubernetes `kind: CronJob`:** apply the YAML snippet from the README.
4. **fly.io `[[machines.schedule]]`:** add the TOML snippet to `fly.toml`.

After choosing a scheduler, adopters MUST:

1. Pin a SHA-256 fingerprint per source via `mix relyra.metadata.pin <connection_id> --fingerprint <hex> --repo MyApp.Repo` (or wait for the v0.6 admin LiveView fingerprint form).
2. Enable auto-refresh on the source via the operator-facing `auto_refresh_changeset/2` (the schema-level great-error from Plan 01 prevents enabling without a pinned fingerprint — D-09).
3. Optionally attach the reference log handler in `Application.start/2`: `:ok = Relyra.Telemetry.Handlers.LogAlerts.attach()`.

## Next Plan Readiness

- **Phase 21 is COMPLETE.** All 7 plans have shipped. CFG-08 closes with this plan.
- **The next phase begins the next milestone arc.** Per `.planning/MILESTONE-ARC.md`, v0.5 ("Operational maturity") concludes with Phase 21; v0.6 ("Adoption polish") begins with the deferred admin-LiveView fingerprint UX, the diff-preview UX, and any v0.6 features the milestone arc enumerates.
- **No blockers.** Both compile lanes green; full suite at the same pre-existing-failure baseline as Plans 21-01..21-06.

## Threat Flags

None — no new security surface introduced beyond the locked threat register entries (T-21-41 through T-21-47) which are all `mitigate` per the plan's threat model and implemented as documented:

- T-21-41 (Spoofing: Pin --fingerprint argument) — task moduledoc + README recipe explain the out-of-band `openssl x509 ... | dgst -sha256` computation; the schema gate `validate_fingerprints_when_enabled/1` (Plan 01) and the runtime trust check `TrustAnchor.check/2` (Plan 03) are the runtime defenses ✓
- T-21-42 (Tampering: Pin REPLACES the array) — task `@moduledoc` explicitly documents that pinning REPLACES (not appends); `auto_refresh_changeset/2`'s cast whitelist excludes health-state columns so no other field can be sneaked in ✓
- T-21-43 (DoS: RefreshDue looping forever) — task is a one-shot tick; does NOT start a supervised ticker (D-04). Adopter's host scheduler controls cadence ✓
- T-21-44 (Information Disclosure: LogAlerts redaction) — `redact/1` drops `:xml`, `:metadata_xml`, `:certificate_pem`, `:pem`, `:private_key` before Logger sees the payload — same posture as `Relyra.Log` ✓
- T-21-45 (Repudiation: LogAlerts auto-attach at boot) — D-30: handler is NOT default-attached anywhere in `lib/`; adopter explicitly calls `attach/0`. Grep-enforced ✓
- T-21-46 (Tampering: mix.exs Oban dep change) — `@compile {:no_warn_undefined, [...]}` attributes from Plan 21-05 keep the `--no-optional-deps` lane green; `ci.oban_smoke` is the regression gate; verified passing ✓
- T-21-47 (Information Disclosure: README recipes leaking adopter secrets) — all recipes use placeholders (`MyApp.Repo`, `connection_id`, `<sha256_hex>`); README does not document any adopter-specific URL, fingerprint, or repo name ✓

## Self-Check: PASSED

Plan-21-07 file existence and commit-hash verification:

- `lib/relyra/telemetry/handlers/log_alerts.ex` — FOUND
- `lib/mix/tasks/relyra.refresh_due.ex` — FOUND
- `lib/mix/tasks/relyra.metadata.pin.ex` — FOUND
- `lib/relyra/telemetry.ex` — FOUND (modified)
- `lib/relyra/metadata.ex` — FOUND (modified — `pin_trust_fingerprint/3` + helper added)
- `lib/relyra/workers/metadata_refresh.ex` — FOUND (modified — Rule 3 wildcard fallthrough)
- `mix.exs` — FOUND (modified — Oban dep + ci.oban_smoke)
- `mix.lock` — FOUND (modified — Oban 2.22.1 resolved)
- `README.md` — FOUND (modified — Operations section)
- `test/relyra/telemetry/handlers/log_alerts_test.exs` — FOUND (modified; `:pending` tag removed; 13 tests)
- `test/mix/tasks/relyra_refresh_due_test.exs` — FOUND (modified; `:pending` tag removed; 2 tests)
- `test/mix/tasks/relyra_metadata_pin_test.exs` — FOUND (modified; `:pending` tag removed; 4 tests)
- `test/relyra/workers/metadata_refresh_test.exs` — FOUND (modified — Rule 3 sandbox/apply fix)
- Commit `06ca068` (Task 1: telemetry catalog + LogAlerts) — FOUND
- Commit `aa25260` (Task 2: pin_trust_fingerprint + Mix tasks) — FOUND
- Commit `f4bf983` (Task 3: Oban dep + ci.oban_smoke + README) — FOUND

---

*Phase: 21-scheduled-metadata-refresh*
*Plan: 07 mix-tasks-telemetry-docs*
*Completed: 2026-05-07*
