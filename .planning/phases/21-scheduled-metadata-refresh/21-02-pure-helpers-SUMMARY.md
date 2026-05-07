---
phase: 21-scheduled-metadata-refresh
plan: 02
subsystem: metadata
tags: [pure-function, exunit, property-test, jitter, backoff, classifier, cadence]

requires:
  - phase: 21-scheduled-metadata-refresh
    plan: 01
    provides: Wave-0 stub test files at test/relyra/metadata/{cadence,backoff,failure_classifier}_test.exs (with @moduletag :pending) that this plan replaces in place; and the @cadence_values / @suspended_reason_values enum tables on Relyra.Ecto.MetadataSource which downstream waves will pair with these helpers
provides:
  - Relyra.Metadata.Cadence — pure cadence resolver; LOCKED 4-preset enum; ±15% jitter (D-12); 1h hard floor baked in via @hard_floor_seconds 3_600 (D-14)
  - Relyra.Metadata.Backoff — pure exponential backoff schedule; LOCKED 1h → 6h → 24h tiers (D-25); ±10% jitter; @suspend_threshold 5 module-attribute
  - Relyra.Metadata.FailureClassifier — pure D-27 classifier; one function-head per Phase-21 error code; total via _other catch-all that returns suspicious; 3-flag map shape matches telemetry payload keys (RESEARCH A4)
affects: [21-04-audit-seam-extension, 21-05-scheduler-wrapper-worker, 21-07-mix-tasks-telemetry-docs]

tech-stack:
  added: []  # no new dependencies; pure Elixir (Enum, MapSet, DateTime, Map, :crypto unused — these helpers don't even hash anything)
  patterns:
    - "Module-attribute LOCKED policy table (analog: lib/relyra/security/algorithm_policy.ex @sha1_signature_methods) — compile-time constants for the cadence enum, the backoff tier schedule, the suspend threshold, and the InCommon hard floor; future code paths cannot mutate these values"
    - "One function-head per documented input + default _other clause (analog: AlgorithmPolicy.enforce_signature_method/2 default fall-through) — keeps the classifier total and surfaces drift between docs and code at compile time when a new error code is referenced elsewhere without a clause here"
    - "Deterministic-with-jitter purity: Enum.random/1 is the only nondeterminism source; tests assert bounded envelopes over 200 samples per tier rather than exact values, mirroring AWS Builder's Library jitter discipline"

key-files:
  created:
    - lib/relyra/metadata/cadence.ex
    - lib/relyra/metadata/backoff.ex
    - lib/relyra/metadata/failure_classifier.ex
  modified:
    - test/relyra/metadata/cadence_test.exs        # Wave-0 stub replaced with 5 describe blocks / 7 tests
    - test/relyra/metadata/backoff_test.exs        # Wave-0 stub replaced with 3 describe blocks / 8 tests
    - test/relyra/metadata/failure_classifier_test.exs  # Wave-0 stub replaced with 4 describe blocks / 15 tests

key-decisions:
  - "Co-located @doc false `apply_jitter/2` on Cadence (public for test access) vs private `apply_jitter/2` inside Backoff. The plan offered either shape; I chose to keep both modules single-purpose and self-contained — Cadence's helper is documented as @doc false (test-only access per threat-model T-21-10) and Backoff has its own private copy. Rationale: each module owns its own constants (ratio, tiers) so neither imports the other; deletion of one in the future does not require unwinding a shared helper."
  - "Module-attribute @cadence_values keys derivation via `Map.keys(@cadence_seconds)` (compile-time, single source of truth) rather than declaring two parallel constants. Means a future preset addition only needs editing one map; cadence_values/0 stays in sync automatically."
  - "Backoff.tier_seconds/1 is total at every non-negative integer (returns 1h floor below threshold, 24h cap above the last tier). Defensive-rather-than-fail-clausing keeps the helper composable inside a transactional record_attempt/3 (Wave 2 / Plan 04) where a FunctionClauseError mid-transaction would be a much louder failure mode than the documented 1h floor."

requirements-completed: [CFG-08]  # CFG-08 is multi-plan; this plan delivers the pure-function helpers Waves 2-5 will consume. Mark complete only after Phase 21 W5 ships.

duration: ~5min
completed: 2026-05-07
---

# Phase 21 Plan 02: Pure Helpers Summary

**Three pure deterministic-with-jitter helpers (Cadence, Backoff, FailureClassifier) ship the LOCKED constants Phase 21's Wave-2/3/5 wrappers, schedulers, and audit-writer-seam will all consume — module-attribute policy tables, no Ecto/Repo/Req/telemetry/Logger references, 200-sample envelope tests + table-driven exhaustiveness tests.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-05-07T02:13:30Z (UTC) — first edit / Task 1 start
- **Completed:** 2026-05-07T02:18:22Z (UTC) — Task 2 commit `f8620bf`
- **Tasks:** 2 / 2
- **Files created or modified:** 6 (3 production modules + 3 test files; the 3 test files were Wave-0 stubs from Plan 01 and are replaced in place)

## Accomplishments

- **`Relyra.Metadata.Cadence`** (60 LOC): pure cadence resolver. `cadence_values/0`, `cadence_seconds/1`, `next_refresh_at/2` (default-arg base = `DateTime.utc_now()`). `@hard_floor_seconds 3_600` and `@cadence_seconds %{hourly: 3_600, every_6h: 21_600, daily: 86_400, weekly: 604_800}` are compile-time constants. `next_refresh_at/2` uses `max(interval, @hard_floor_seconds)` so even a future preset more aggressive than `:hourly` cannot bypass the InCommon ≤1/hour ceiling (D-14, T-21-07). `apply_jitter/2` is `@doc false` for test-access (T-21-10).
- **`Relyra.Metadata.Backoff`** (49 LOC): pure backoff schedule. `suspend_threshold/0`, `tier_seconds/1`, `backoff_until/2` (default-arg base = `DateTime.utc_now()`). `@backoff_tiers_seconds [3_600, 21_600, 86_400]` and `@suspend_threshold 5` are compile-time constants. `tier_seconds/1` is total at every non-negative integer: returns 1h floor below threshold (defensive), 24h cap above the last tier (T-21-09). ±10% jitter via private `apply_jitter/2`.
- **`Relyra.Metadata.FailureClassifier`** (59 LOC): pure D-27 classifier. One `def classify(:atom)` clause per documented Phase-21 error code (5 transient + 8 suspicious = 13 codes), plus a `def classify(_other)` catch-all returning the suspicious shape so an unclassified failure never silently suppresses an alert (T-21-08). Three-flag map shape `%{transient?, counts_toward_suspend?, alert_immediately?}` matches the telemetry payload keys per RESEARCH A4.
- **30 ExUnit tests** total across the three files (15 cadence/backoff + 15 classifier). Property-style jitter-envelope tests use 200 random samples per tier (200 × 6 envelopes = 1,200 random draws checked per run). Exhaustiveness invariant guards against documented-vs-implemented drift in the classifier.
- **Both compile lanes green** (`mix compile --warnings-as-errors` and `mix compile --no-optional-deps --warnings-as-errors`).
- **All three test files dropped `@moduletag :pending`** — the `mix test --exclude pending` count of passing tests is up by 30 (15 cadence/backoff + 15 classifier).

## Task Commits

1. **Task 1: Implement cadence + backoff pure helpers with property-style jitter envelope tests** — `7cfbf02` (feat)
2. **Task 2: Implement failure_classifier with one function-head per error code and a table test** — `f8620bf` (feat)

**Plan metadata commit:** to follow this SUMMARY.md (docs commit per protocol)

## Files Created/Modified

### Created
- `lib/relyra/metadata/cadence.ex` — pure cadence resolver; 60 LOC
- `lib/relyra/metadata/backoff.ex` — pure backoff schedule; 49 LOC
- `lib/relyra/metadata/failure_classifier.ex` — pure D-27 classifier; 59 LOC

### Modified (Wave-0 stubs replaced in place)
- `test/relyra/metadata/cadence_test.exs` — 5 tests across 2 describes (cadence_values + cadence_seconds; next_refresh_at envelope + floor + default base + FunctionClauseError)
- `test/relyra/metadata/backoff_test.exs` — 8 tests across 3 describes (suspend_threshold; tier_seconds at threshold/cap/below; jitter envelope at tiers 1/2/3 cap)
- `test/relyra/metadata/failure_classifier_test.exs` — 15 tests across 4 describes (5 transient × table-driven; 8 suspicious × table-driven; 1 unknown-default; 1 exhaustiveness invariant)

## LOCKED Constants Exposed (the source-of-truth references for downstream waves)

| Module                              | Constant                       | Value                                          | Owner D-#       |
|-------------------------------------|--------------------------------|------------------------------------------------|-----------------|
| `Relyra.Metadata.Cadence`           | `@hard_floor_seconds`          | `3_600`                                        | D-14            |
| `Relyra.Metadata.Cadence`           | `@cadence_seconds`             | `%{hourly: 3_600, every_6h: 21_600, daily: 86_400, weekly: 604_800}` | D-10 |
| `Relyra.Metadata.Backoff`           | `@backoff_tiers_seconds`       | `[3_600, 21_600, 86_400]`                      | D-25            |
| `Relyra.Metadata.Backoff`           | `@suspend_threshold`           | `5`                                            | D-25            |
| `Relyra.Metadata.FailureClassifier` | (no module attrs; clauses are the source of truth) | 5 transient + 8 suspicious atoms + `_other` default | D-27 |

## Test Counts

| File                                                  | Tests | Type                                                                 |
|-------------------------------------------------------|-------|----------------------------------------------------------------------|
| `test/relyra/metadata/cadence_test.exs`               | 7     | unit + property (200 jitter samples × 2 presets)                     |
| `test/relyra/metadata/backoff_test.exs`               | 8     | unit + property (200 jitter samples × 3 tiers)                       |
| `test/relyra/metadata/failure_classifier_test.exs`    | 15    | table-driven (13 documented codes) + unknown default + exhaustiveness |
| **Total**                                             | **30** | All green; all `@moduletag :pending` removed                          |

## Decisions Made

- **Co-located `@doc false` `apply_jitter/2` on `Cadence` (test-accessible) vs private `apply_jitter/2` inside `Backoff`.** The plan offered either shape ("each module owns its own copy if the planner prefers single-purpose modules"). I picked single-purpose modules so neither helper imports the other; deletion of one in the future does not require unwinding a shared helper. T-21-10 says Cadence's `apply_jitter/2` is "public for testability" — `@doc false` matches that intent (visible to tests, hidden from `mix docs`). Backoff's `apply_jitter/2` is fully private because no test currently needs to call it directly (the envelope tests assert via `backoff_until/2`).
- **Module-attribute `@cadence_values` derived at compile time via `Map.keys(@cadence_seconds)`** rather than two parallel constants. A future preset addition edits one map and stays in sync automatically.
- **`Backoff.tier_seconds/1` is total at every non-negative integer** (returns 1h floor below threshold, 24h cap above the last tier). Defensive over fail-clause: this helper will be called from inside the Wave-2 `record_attempt/3` transaction (Plan 04) where a `FunctionClauseError` mid-transaction is a much louder failure mode than the documented 1h floor. The defensive 1h floor for `consecutive_failures < @suspend_threshold` is exercised by an explicit test so the behavior is intentional, not accidental.
- **Default-argument heads use the standard Elixir multi-clause shape** (`def f(arg, default \\ ...)` followed by the actual clause). This is why `grep -c "def next_refresh_at"` reports `2` (one for the default-arg head + one for the clause); the plan's literal `returns 1` grep is overly literal — multi-clause function heads are idiomatic Elixir, not a duplication.

## Deviations from Plan

### Notes (no behavioral deviations)

**1. `[Note - Acceptance grep wording]` Plan-stated `grep -c "def next_refresh_at" ... returns 1`; actual count is 2 because Elixir requires a separate function-head for default arguments**

- **Found during:** Task 1 acceptance verification.
- **Issue:** The plan's literal grep `grep -c "def next_refresh_at" lib/relyra/metadata/cadence.ex returns 1` and `grep -c "def backoff_until" lib/relyra/metadata/backoff.ex returns 1` are off by one. Elixir's default-argument syntax `def f(arg, default \\ ...)` requires one bodyless function-head plus the actual clause — this is the canonical idiom shown in the PLAN's own action snippet (`def next_refresh_at(cadence, base \\ DateTime.utc_now())` followed by `def next_refresh_at(cadence, %DateTime{} = base) when ... do`).
- **Resolution:** The semantic acceptance criterion (one public `next_refresh_at` / one public `backoff_until` arity-2 function each) is met. The literal grep count of 2 is the correct Elixir shape, not an extra function. Documented here so the verifier evaluates by behavior rather than by literal grep count.
- **Files modified:** none (no source change needed; it was the plan's grep that was overly literal).

**Total deviations:** 0 behavioral deviations. 1 acceptance-grep wording note (matches the same kind of issue documented in 21-01-SUMMARY).

## Issues Encountered

- **`mix format --check-formatted` flagged a single blank-line in `cadence_test.exs`** (block-of-multiple-statements idiom expects a trailing blank line before a comment). Fixed via `mix format` before the Task 1 commit; both compile lanes and full plan-file format check are green.
- **`mix deps.get` was needed at the start** because the worktree was newly created — not a deviation, just first-time setup.

## Pre-existing Out-of-Scope Issues (Deferred — same as 21-01)

The full suite (`mix test --warnings-as-errors`) is **243 tests, 1 failure (13 excluded)**. The single failure is the same pre-existing `Relyra.Phoenix.ACSControllerTest` `POST /:connection_id/acs success` `KeyError :name_id` already logged in `.planning/phases/21-scheduled-metadata-refresh/deferred-items.md` and called out in `21-01-schema-extension-SUMMARY.md`. Reproduced on the parent commit `0842687` BEFORE Phase 21 work started; not caused by Plan 21-02 (which only added pure helpers with no side effects). Per the SCOPE BOUNDARY rule, not fixed in this plan.

## User Setup Required

None — no external service configuration required. Pure helpers; no migration, no env var, no dependency.

## Next Plan Readiness

- **Plan 21-03 (`trust-boundary-helpers`) is unblocked.** It runs in the same wave (Wave 1) and depends on the same Wave-0 stub-test infrastructure — independent of this plan's three modules.
- **Plan 21-04 (`audit-seam-extension`, Wave 2)** can now consume `Relyra.Metadata.FailureClassifier.classify/1` inside `MetadataApply.record_attempt/3`'s transaction (D-28 / Pitfall 3), and `Relyra.Metadata.Backoff.backoff_until/2` for the `auto_suspended_until` write.
- **Plan 21-05 (`scheduler-wrapper-worker`, Wave 3)** can consume `Relyra.Metadata.Cadence.next_refresh_at/2` for the per-source `next_refresh_at` write inside `Relyra.Metadata.AutoRefresh.refresh/2`'s success branch.
- **Plan 21-07 (`mix-tasks-telemetry-docs`, Wave 5)** can document the FailureClassifier flag triple in the `### metadata.auto_refresh` telemetry catalog section (D-23 / RESEARCH A4 — flag names match telemetry payload keys).
- **No blockers.** Both compile lanes green; full suite is at the same pre-existing-failure baseline as before this plan.

## Self-Check: PASSED

Plan-21-02 file existence and commit-hash verification (run before SUMMARY commit):

- `lib/relyra/metadata/cadence.ex` — FOUND
- `lib/relyra/metadata/backoff.ex` — FOUND
- `lib/relyra/metadata/failure_classifier.ex` — FOUND
- `test/relyra/metadata/cadence_test.exs` — FOUND (modified; `:pending` tag removed)
- `test/relyra/metadata/backoff_test.exs` — FOUND (modified; `:pending` tag removed)
- `test/relyra/metadata/failure_classifier_test.exs` — FOUND (modified; `:pending` tag removed)
- Commit `7cfbf02` (Task 1: cadence + backoff) — FOUND
- Commit `f8620bf` (Task 2: failure_classifier) — FOUND

---
*Phase: 21-scheduled-metadata-refresh*
*Plan: 02 pure-helpers*
*Completed: 2026-05-07*
