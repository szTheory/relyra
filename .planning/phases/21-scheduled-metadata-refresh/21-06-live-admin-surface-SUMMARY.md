---
phase: 21-scheduled-metadata-refresh
plan: 06
subsystem: live_admin
tags: [phoenix, liveview, ux, audit, single-transaction, brand-voice, exunit]

requires:
  - phase: 21-scheduled-metadata-refresh
    plan: 01
    provides: Relyra.Ecto.MetadataSource auto-refresh column set (auto_refresh_enabled, refresh_cadence, consecutive_failure_count, auto_suspended_until, auto_suspended_reason, last_failure_error_code, last_validity_warning_for, metadata_trust_fingerprints, legacy_unsigned_metadata_policy) consumed by both the badge derivation and the health card summary
  - phase: 21-scheduled-metadata-refresh
    plan: 04
    provides: Relyra.Ecto.MetadataApply.resume_auto_refresh/3 — the single-transaction Resume-now seam (D-28) that co-commits the suspend-clear health write AND the operator-intent audit row with cause "live_admin_auto_refresh_resume" inside ONE transact/2 block
  - phase: 21-scheduled-metadata-refresh
    plan: 05
    provides: Relyra.Metadata.Scheduler.run_due/2 with :source_ids opt — the half-open probe path the LiveView dispatches via start_async after the resume transaction commits

provides:
  - Relyra.LiveAdmin.Query.list_connections/2 — extended to enrich every connection summary with :auto_refresh_health ∈ {nil, :healthy, :degraded, :suspended}; N+1-safe via single MetadataSource preload keyed by connection_record_id
  - Relyra.LiveAdmin.Query.get_metadata_revisions/3 — extended to return a structured :auto_refresh_health summary (cadence, last_success_at, fingerprint list, suspended_until/reason, legacy_unsigned_metadata_policy, etc.) consumed by the health card render block
  - Relyra.LiveAdmin.Components.ConnectionList — per-row "Auto-refresh degraded" / "Auto-refresh suspended" micro-badge with brand-approved copy ONLY (D-29)
  - Relyra.LiveAdmin.ConnectionMetadataLive — handle_event("resume_auto_refresh", ...) + three handle_async(:auto_refresh_resume, ...) clauses + an "Auto-refresh health" render section above the existing "Revision History" block; embeds the existing RiskPanel for legacy_unsigned_metadata_policy (D-19)
affects: [21-07-mix-tasks-telemetry-docs]

tech-stack:
  added: []  # no new runtime dependencies; reuses Phoenix.LiveView, Phoenix.Component, the existing optional-deps gate
  patterns:
    - "Phase-21 D-29 health derivation as a pure function — `derive_auto_refresh_health/2` in `Relyra.LiveAdmin.Query` returns nil / :healthy / :degraded / :suspended from a `MetadataSource` struct + `now`. Same derivation feeds both the per-row micro-badge (via `connection_summary/3`) and the metadata-page health card (via `build_auto_refresh_health_summary/1`). Future surfaces that need this enum should reuse the helper rather than recompute the cond branches — keeps the badge-vs-card health view unified."
    - "N+1-safe preload for the connection list health badge: list_connections/2 fetches connection rows, then a single `MetadataSource where: connection_record_id in ^ids` query, then maps source-by-id into the per-row summary. Future per-row surfaces that need additional MetadataSource-derived signals should extend the same preload (do NOT re-query inside `connection_summary/3`)."
    - "LiveView Resume-now path enforces single-transaction discipline (D-28) by routing exclusively through `Relyra.Ecto.MetadataApply.resume_auto_refresh/3` (Plan 04 Task 3). The LiveView carries NO parallel `repo.update` helper (B3 invariant — grep-enforced: `clear_suspend_for_resume` returns 0 matches across `lib/`). After the transaction commits, the LiveView dispatches a scoped half-open probe via `start_async(:auto_refresh_resume, fn -> Scheduler.run_due(repo, source_ids: [source.id]) end)` — same shape as the existing `:metadata_refresh` start_async at lines 80-114. The Oban worker's `unique:` constraint absorbs concurrent scheduler ticks (Pitfall 3)."
    - "Brand-voice invariant grep-enforcement at the test layer. Every operator-facing surface (`connection_list.ex`, `connection_metadata_live.ex`) is asserted to never render any of `polling`, `cron job`, `blocked`, `retry`, `circuit breaker`, `MaxBackoff`. The grep is run against the rendered HTML across all four health states (nil / :healthy / :degraded / :suspended), so it catches drift in either the source or the data feeding the render. Pattern reusable for any future operator-facing component that must obey the brand book."
    - "Map.get/2-guarded render accesses for cross-test compatibility. Pre-existing `Relyra.LiveAdminMetadataTest` builds a minimal `detail: %{metadata_source: nil}` assigns map. Production data through `Query.get_metadata_revisions/3` always carries `:auto_refresh_health`. To keep both paths green, the render block uses `Map.get(@detail, :auto_refresh_health)` rather than `@detail.auto_refresh_health` — Rule 1 deviation. This pattern is reusable wherever a render block needs to be tolerant of partial test fixtures while production data carries the full schema."

key-files:
  created: []
  modified:
    - lib/relyra/live_admin/query.ex   # 282 → 352 LOC. Adds :auto_refresh_health to connection_summary, derive_auto_refresh_health/2, build_auto_refresh_health_summary/1, MetadataSource preload, get_metadata_revisions :auto_refresh_health passthrough.
    - lib/relyra/live_admin/components/connection_list.ex   # 49 → 58 LOC. Adds amber/red micro-badge inside the per-row li.
    - lib/relyra/live_admin/connection_metadata_live.ex   # 278 → 476 LOC. Adds handle_event("resume_auto_refresh", ...), three handle_async(:auto_refresh_resume, ...) clauses, the "Auto-refresh health" render section embedding RiskPanel for legacy_unsigned_metadata_policy, and the :resume_status / :refresh_status mount initialization.
    - test/relyra/live_admin/connections_live_test.exs   # Wave-0 :pending stub (21 LOC) → 238 LOC of green tests. 11 tests across 2 describe blocks (6 query-level health-derivation scenarios + 5 component-level render scenarios).
    - test/relyra/live_admin/connection_metadata_live_test.exs   # Wave-0 :pending stub (21 LOC) → 476 LOC of green tests. 15 tests across 5 describe blocks (7 health-card render scenarios + 1 brand-voice invariant + 3 handle_event("resume_auto_refresh", ...) scenarios + 3 handle_async(:auto_refresh_resume, ...) scenarios + 1 B3 invariant assertion).

key-decisions:
  - "Rule 1 deviation: guard render-block access to `auto_refresh_health` with `Map.get/2`. The pre-existing `Relyra.LiveAdminMetadataTest` render fixture passes `detail: %{metadata_source: nil}` without an `:auto_refresh_health` key — the literal `@detail.auto_refresh_health` form raises `KeyError` and breaks two pre-existing tests. The fix is to use `Map.get(@detail, :auto_refresh_health)` everywhere in the new render section. Production data through `Query.get_metadata_revisions/3` always includes the key (production-safe); the guard is purely for test-fixture flexibility. This change preserves the LV's tolerance to partial assigns and keeps all pre-existing render tests green."
  - "Past `auto_suspended_until` is NOT `:suspended` (cool-off has elapsed). The PLAN's badge spec literally says `:suspended` when `auto_suspended_until > now()` — implies a past timestamp falls through. Decided to make this an explicit test scenario (`auto_suspended_until` in the past + non-zero `consecutive_failure_count` should render `:degraded`, not `:suspended`) so a future scheduler tick that clears the suspend without resetting the counter still surfaces the right operator signal. The derivation table now has 5 documented scenarios covering nil / disabled / past-cool-off / current-cool-off / clean-healthy."
  - "LiveStream test fixture shape: production `mount/3` calls `stream_configure/3` + `stream/2` which the LV runtime drives via `Phoenix.LiveView.Diff`. The unit-test fixture for `render_component(ConnectionMetadataLive, assigns)` MUST construct a real `Phoenix.LiveView.LiveStream` struct (with `name`, `dom_id`, `ref`, `inserts`, `deletes`, `reset?`) AND wrap it in a `streams` map carrying `:__ref__`, `:__changed__` (MapSet), and `:__configured__`. This is the minimal shape the production diff machinery accepts. Pattern reusable for any future LV unit test that bypasses the full LV process loop."
  - "Test-only `Phoenix.Component.assign/3` import for `:resume_status` mutation. The `handle_async` tests construct a `%Phoenix.LiveView.Socket{}` then need to flip `:resume_status` to `:loading` before calling the handler. Used `Phoenix.Component.assign(socket, :resume_status, :loading)` rather than direct map mutation so the `:__changed__` tracking stays consistent with what the LV runtime would do. This avoids `KeyError :__changed__ not found` errors in the diff machinery on subsequent renders."
  - "Three discrete `handle_async(:auto_refresh_resume, ...)` clauses (success / error / exit) instead of one matching multi-head. Mirrors the existing `:metadata_refresh` shape verbatim — operators get the same UX they already know. The success branch additionally calls `reload_detail/1` so the health card refreshes; the error and exit branches do NOT (the cached card is fine, only the flash needs updating)."

requirements-completed: []  # CFG-08 is multi-plan; this plan delivers the operator-facing surface but does NOT close CFG-08 — that ships in Phase 21 W5 (Plan 21-07) which adds the Mix tasks, telemetry catalog, README recipes, and Oban CI smoke lane.

duration: ~10min
completed: 2026-05-07
---

# Phase 21 Plan 06: Live Admin Surface Summary

**Lands the operator-facing surface for the scheduled-refresh feature: a per-row "Auto-refresh degraded" / "Auto-refresh suspended" micro-badge on the connection list (D-29), an "Auto-refresh health" compact card on the connection metadata page showing schedule, last success, consecutive failures, last error, validity warning, pinned fingerprints, and the legacy-escape-hatch RiskPanel (D-29 + D-19), and a "Resume now" button that delegates to `Relyra.Ecto.MetadataApply.resume_auto_refresh/3` (Plan 04 — D-28 single-transaction co-commit) followed by an immediate `start_async`-dispatched half-open probe via `Relyra.Metadata.Scheduler.run_due/2` scoped to the source via `:source_ids` (Plan 05 — D-25). Brand-voice invariant grep-enforced — no "polling" / "cron job" / "blocked" / "retry" / "circuit breaker" anywhere in either rendered HTML or the source.**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-05-07T03:09:14Z (UTC) — pre-Task-1 read-throughs
- **Completed:** 2026-05-07T03:19:21Z (UTC) — Task 2 commit `35a4cc7`
- **Tasks:** 2 / 2
- **Files modified:** 5 (3 production modules + 2 test files)

## Accomplishments

### Task 1: `auto_refresh_health` on the connection list (`67da767`)

- `Relyra.LiveAdmin.Query.list_connections/2` now enriches every connection summary with `:auto_refresh_health ∈ {nil, :healthy, :degraded, :suspended}`. The derivation lives in the new private helper `derive_auto_refresh_health/2`:
  - `nil` — no `MetadataSource` registered, OR `auto_refresh_enabled: false` (do not render badge — the operator opted out)
  - `:suspended` — `auto_suspended_until > now()` (cool-off active; red badge)
  - `:degraded` — `consecutive_failure_count >= 1` AND no active cool-off (amber badge — covers both the "1-4 consecutive failures" and the "post-cool-off, counter not yet reset" scenarios)
  - `:healthy` — enabled with no failures and no active cool-off (do not render badge)
- `Relyra.LiveAdmin.Query.get_metadata_revisions/3` returns a structured `:auto_refresh_health` summary (cadence, next_refresh_at, last_success_at, consecutive_failure_count, last_failure_error_code, last_validity_warning_for, auto_suspended_until/reason, legacy_unsigned_metadata_policy, metadata_trust_fingerprints, state) — the metadata-page health card consumes this verbatim.
- N+1-safe preload: `MetadataSource where: connection_record_id in ^ids` runs in ONE query, then a `Map.new` keyed by `connection_record_id` feeds the per-row derivation. No round-trip per row.
- `Relyra.LiveAdmin.Components.ConnectionList.connection_list/1` renders the amber "Auto-refresh degraded" / red "Auto-refresh suspended" badge inside the per-row `<li>`. Brand-voice invariant grep-enforced.
- 11 tests in `test/relyra/live_admin/connections_live_test.exs` across 2 describe blocks: 6 query-level health-derivation scenarios (nil source, disabled source, degraded, suspended, healthy, past-cool-off-elapsed) + 5 component-level render scenarios (degraded badge present, suspended badge present, healthy → no badge, nil → no badge, brand-voice invariant across all four states).

### Task 2: Auto-refresh health card + Resume now button (`35a4cc7`)

- `Relyra.LiveAdmin.ConnectionMetadataLive.handle_event("resume_auto_refresh", _params, socket)` delegates to `Relyra.Ecto.MetadataApply.resume_auto_refresh(repo, source, %{actor: actor})` — the single-transaction seam from Plan 04 Task 3 that co-commits the suspend-clear health write AND the operator-intent audit row inside ONE `transact/2` block. Audit cause is the LOCKED `"live_admin_auto_refresh_resume"`. After the transaction commits, the LiveView dispatches an immediate half-open probe via `start_async(:auto_refresh_resume, fn -> Scheduler.run_due(repo, source_ids: [source.id], audit: %{actor: actor, cause: "live_admin_auto_refresh_resume"}) end)`. Same `start_async` shape as `:metadata_refresh` at lines 80-114 of the file — operators get the same disabled-while-loading UX they already know.
- The handler is a no-op with an info flash when the source is not currently suspended; an error flash when no metadata source is registered; otherwise dispatches the seam.
- Three new `handle_async(:auto_refresh_resume, ...)` clauses (success / error / exit) flip `:resume_status` back to `:idle` and surface the appropriate flash. Success branch additionally calls `reload_detail/1` so the health card refreshes.
- `mount/3` initializes both `:refresh_status` and `:resume_status` to `:idle` (Rule 3 — needed so the buttons render correctly on first mount).
- Render block adds an "Auto-refresh health" compact card immediately above the existing "Revision History" section. The card is hidden when there is no `auto_refresh_health` summary (no metadata source registered). When present, it renders:
  - Per-state banner ("Auto-refresh suspended" red banner with reason + until-time, OR "Auto-refresh degraded" amber banner with consecutive failure count)
  - A two-column dl with Schedule, Last success, Consecutive failures, Last error, Validity warning (when set), Metadata trust fingerprints (or "(none pinned)")
  - The existing `Relyra.LiveAdmin.Components.RiskPanel` embedded when `legacy_unsigned_metadata_policy` is set (D-19 surface)
  - The "Resume now" button ONLY when state == :suspended; disabled while `@resume_status == :loading` with the button label flipping to "Resuming..."
- The LiveView carries NO parallel `repo.update` helper (B3 invariant — `grep -rE "clear_suspend_for_resume" lib/` returns 0 matches; the resume audit + state-clear MUST flow through `MetadataApply.resume_auto_refresh/3` only).
- 15 tests in `test/relyra/live_admin/connection_metadata_live_test.exs` across 5 describe blocks: 7 health-card render scenarios, 1 brand-voice invariant test (4 health states × 5 banned terms), 3 `handle_event("resume_auto_refresh", ...)` scenarios (incl. the end-to-end single-transaction co-commit assertion against `AuditEvent` and `MetadataSource` rows), 3 `handle_async(:auto_refresh_resume, ...)` scenarios, 1 B3 invariant assertion (no `clear_suspend_for_resume` anywhere in `lib/`).

## Task Commits

1. **Task 1: surface auto_refresh_health on the connection list (D-29)** — `67da767` (feat)
2. **Task 2: add Auto-refresh health card + Resume now to ConnectionMetadataLive** — `35a4cc7` (feat)

**Plan metadata commit:** to follow this SUMMARY.md (docs commit per protocol).

## Files Created/Modified

### Modified

- `lib/relyra/live_admin/query.ex` — 282 → 352 LOC (+70). Adds `:auto_refresh_health` to the `connection_summary/3` shape, the `derive_auto_refresh_health/2` private helper, the `build_auto_refresh_health_summary/1` private helper, the single-query `MetadataSource` preload inside `list_connections/2`, and the `:auto_refresh_health` passthrough in `get_metadata_revisions/3`.
- `lib/relyra/live_admin/components/connection_list.ex` — 49 → 58 LOC (+9). Adds two `:if`-gated `<div>` micro-badges inside the per-row `<li>` (one for `:degraded`, one for `:suspended`) using `Map.get(connection, :auto_refresh_health)` so the existing test fixtures that don't pass the key still render cleanly.
- `lib/relyra/live_admin/connection_metadata_live.ex` — 278 → 476 LOC (+198). Adds the alias for `RiskPanel`, the `handle_event("resume_auto_refresh", ...)` clause (the single-transaction seam dispatch), the three `handle_async(:auto_refresh_resume, ...)` clauses (success / error / exit), the `:refresh_status` + `:resume_status` mount initialization, and the "Auto-refresh health" compact card render section above the existing "Revision History" block.
- `test/relyra/live_admin/connections_live_test.exs` — Wave-0 `:pending` stub (21 LOC, 1 flunking test) → 238 LOC of green tests; 11 tests across 2 describe blocks.
- `test/relyra/live_admin/connection_metadata_live_test.exs` — Wave-0 `:pending` stub (21 LOC, 1 flunking test) → 476 LOC of green tests; 15 tests across 5 describe blocks.

## Decisions Made

1. **Rule 1 deviation: `Map.get/2`-guarded render-block accesses for cross-test compatibility.** The pre-existing `Relyra.LiveAdminMetadataTest` render fixture passes `detail: %{metadata_source: nil}` without an `:auto_refresh_health` key — the literal `@detail.auto_refresh_health` form raises `KeyError` and breaks two pre-existing render tests (`render/1 displays xml mode`, `render/1 displays url mode`). Switched the new render section to use `Map.get(@detail, :auto_refresh_health)` everywhere. Production data through `Query.get_metadata_revisions/3` always carries the key; the guard is purely for test-fixture flexibility. All pre-existing render tests are green again.
2. **Past `auto_suspended_until` falls through to `:degraded`, NOT `:suspended`.** The PLAN's badge spec says `:suspended` when `auto_suspended_until > now()`. Made this an explicit test scenario: a past `auto_suspended_until` + non-zero `consecutive_failure_count` should render `:degraded` (cool-off has elapsed; the failure counter still warrants operator attention). Documented as the 5th derivation case so a future scheduler tick that clears the cool-off without resetting the counter still surfaces the right signal.
3. **`Phoenix.LiveView.LiveStream` test-fixture shape.** The LV's `reload_detail/1` calls `stream(:metadata_revisions, items, reset: true)` which routes through `Phoenix.LiveView.update_stream/3` — that path expects the `streams` assign to be a map containing `:__ref__`, `:__changed__` (MapSet), `:__configured__`, AND a real `%Phoenix.LiveView.LiveStream{}` struct keyed by stream name. The test helper `streams_assign/0` constructs this minimal-but-complete shape so `render_component/2` and `handle_async/3` paths both work. Pattern reusable for any future LV unit test that bypasses the full LV process loop.
4. **Test-only `Phoenix.Component.assign/3` for `:resume_status` mutation in the `handle_async` tests.** Used `Phoenix.Component.assign(socket, :resume_status, :loading)` rather than direct map mutation so the `:__changed__` tracking stays consistent with what the LV runtime would do. Avoids the `KeyError :__changed__ not found` error in the diff machinery on the subsequent render call inside `reload_detail/1`.
5. **Three discrete `handle_async(:auto_refresh_resume, ...)` clauses, mirroring `:metadata_refresh`.** Same shape as the existing `:metadata_refresh` chain — operators get the same UX they already know. Only the success branch reloads the detail (the cached card is fine on error/exit; only the flash needs updating). The grep acceptance criterion `≥ 3` is met exactly.

## Patterns Established

1. **Phase-21 D-29 health derivation as a pure function reused across surfaces.** `derive_auto_refresh_health/2` in `Relyra.LiveAdmin.Query` returns the four-case enum from a `MetadataSource` struct + `now`. Both the per-row badge (`connection_summary/3`) and the metadata-page health card (`build_auto_refresh_health_summary/1`) consume it. Future surfaces that need the health enum should reuse the helper rather than recompute the cond branches — keeps the operator's mental model unified (the same enum drives the same color in both views).
2. **N+1-safe preload for per-row admin signals.** `list_connections/2` does (a) one `Connection` query, (b) one `MetadataSource where: connection_record_id in ^ids` query, (c) a `Map.new` keyed by `connection_record_id` to feed the per-row summary. Future per-row signals (Phase 22+) that need `MetadataSource` fields should extend this preload — do NOT re-query inside `connection_summary/3`.
3. **LiveView Resume-now path enforces single-transaction discipline (D-28).** The LiveView delegates exclusively to `Relyra.Ecto.MetadataApply.resume_auto_refresh/3` (Plan 04 Task 3); no parallel `repo.update`-based clear helper exists (B3 invariant — grep-enforced). After the transaction commits, the LiveView dispatches an immediate scoped half-open probe via `start_async(:auto_refresh_resume, fn -> Scheduler.run_due(repo, source_ids: [source.id]) end)`. The Oban worker's `unique:` constraint absorbs concurrent scheduler ticks (Pitfall 3). Future LiveView surfaces that need to mutate audit-relevant state MUST follow the same shape: delegate to a `transact/2`-wrapped `MetadataApply` seam, dispatch downstream side-effects via `start_async` only after the transaction commits.
4. **Brand-voice invariant grep-enforcement at the test layer.** Every new operator-facing surface asserts the rendered HTML never contains `polling`, `cron job`, `blocked`, `retry`, `circuit breaker`, or `MaxBackoff`. The grep is run across all four health states so it catches drift in both the source and the data feeding the render. Pattern reusable for any future operator-facing component governed by the brand book.
5. **`Map.get/2`-guarded render accesses for cross-test compatibility.** When extending an existing LV render block with a new schema-derived assign, use `Map.get(@detail, :new_key)` rather than `@detail.new_key` so pre-existing test fixtures with partial assigns keep working. Production data through the schema-bound query always carries the key; the guard is purely for test-fixture flexibility.

## Verification

- `mix test test/relyra/live_admin/connections_live_test.exs --warnings-as-errors` — **11 tests, 0 failures** (Wave-0 stub fully replaced).
- `mix test test/relyra/live_admin/connection_metadata_live_test.exs --warnings-as-errors` — **15 tests, 0 failures** (Wave-0 stub fully replaced).
- `mix test --warnings-as-errors --exclude pending --exclude integration` — **325 tests, 1 failure (14 excluded)**. The single failure is the pre-existing `Relyra.Phoenix.ACSControllerTest` `:name_id` `KeyError` documented in `.planning/phases/21-scheduled-metadata-refresh/deferred-items.md` (predates Phase 21).
- `mix compile --warnings-as-errors` — green (98 files compiled).
- `mix compile --no-optional-deps --warnings-as-errors` — green (98 files compiled; the `if Code.ensure_loaded?(Phoenix.LiveView)` gate keeps the no-LV lane green per engineering-DNA §3 invariant).
- `mix format --check-formatted lib/relyra/live_admin/query.ex lib/relyra/live_admin/components/connection_list.ex lib/relyra/live_admin/connection_metadata_live.ex test/relyra/live_admin/connections_live_test.exs test/relyra/live_admin/connection_metadata_live_test.exs` — green on all 5 modified files.
- Brand-voice grep invariant: `grep -riE '(polling|cron job|blocked|retry|circuit breaker|maxbackoff)' lib/relyra/live_admin/components/connection_list.ex lib/relyra/live_admin/connection_metadata_live.ex` — 0 matches.

## Acceptance Criteria (Per-Task)

### Task 1 — wired

- `grep -c "auto_refresh_health" lib/relyra/live_admin/query.ex` = 10 (≥ 3) ✓
- `grep -c "derive_auto_refresh_health" lib/relyra/live_admin/query.ex` = 5 (≥ 2) ✓
- `grep -c "build_auto_refresh_health_summary" lib/relyra/live_admin/query.ex` = 3 (≥ 2) ✓
- `grep -cE ":degraded|:suspended|:healthy" lib/relyra/live_admin/query.ex` = 3 (≥ 3) ✓
- `grep -c "Auto-refresh degraded" lib/relyra/live_admin/components/connection_list.ex` = 1 (≥ 1) ✓
- `grep -c "Auto-refresh suspended" lib/relyra/live_admin/components/connection_list.ex` = 1 (≥ 1) ✓
- `grep -ciE "(polling|cron job|blocked|retry|circuit breaker)" lib/relyra/live_admin/components/connection_list.ex` = 0 ✓
- `mix test test/relyra/live_admin/connections_live_test.exs --warnings-as-errors` — green ✓
- `mix compile --no-optional-deps --warnings-as-errors` — green ✓
- `mix compile --warnings-as-errors` — green ✓

### Task 2 — wired

- `grep -c "handle_event(\"resume_auto_refresh\"" lib/relyra/live_admin/connection_metadata_live.ex` = 1 (≥ 1) ✓
- `grep -c "handle_async(:auto_refresh_resume" lib/relyra/live_admin/connection_metadata_live.ex` = 3 (≥ 3) ✓
- `grep -c "live_admin_auto_refresh_resume" lib/relyra/live_admin/connection_metadata_live.ex` = 2 (≥ 1) ✓
- `grep -cE "MetadataApply\.resume_auto_refresh|Relyra\.Ecto\.MetadataApply\.resume_auto_refresh" lib/relyra/live_admin/connection_metadata_live.ex` = 2 (≥ 1) ✓
- `grep -rE "clear_suspend_for_resume" lib/` = 0 matches ✓ (B3 invariant)
- `grep -cE "Scheduler\.run_due|Relyra\.Metadata\.Scheduler\.run_due" lib/relyra/live_admin/connection_metadata_live.ex` = 2 (≥ 1) ✓
- `grep -c "Auto-refresh health" lib/relyra/live_admin/connection_metadata_live.ex` = 1 (≥ 1) ✓
- `grep -c "Resume now" lib/relyra/live_admin/connection_metadata_live.ex` = 3 (≥ 1) ✓
- `grep -cE "Auto-refresh suspended|Auto-refresh degraded" lib/relyra/live_admin/connection_metadata_live.ex` = 2 (≥ 2) ✓
- `grep -ciE "(polling|cron job|blocked|retry|circuit breaker|maxbackoff)" lib/relyra/live_admin/connection_metadata_live.ex` = 0 ✓
- `grep -c "RiskPanel" lib/relyra/live_admin/connection_metadata_live.ex` = 2 (≥ 1) ✓
- `grep -c "if Code.ensure_loaded?(Phoenix.LiveView) do" lib/relyra/live_admin/connection_metadata_live.ex` = 1 (≥ 1) ✓
- `mix test test/relyra/live_admin/connection_metadata_live_test.exs --warnings-as-errors` — green ✓
- `mix compile --warnings-as-errors` — green ✓
- `mix compile --no-optional-deps --warnings-as-errors` — green ✓

## Pre-existing Out-of-Scope Issues (Deferred — same baseline as 21-01..21-05)

- `Relyra.Phoenix.ACSControllerTest` — `POST /:connection_id/acs success` trips a `KeyError :name_id` inside `FakeUserMapper.map_attributes/3`. Pre-existing on the Phase-21 parent commit `0842687`; documented in `.planning/phases/21-scheduled-metadata-refresh/deferred-items.md`. Not caused by Plan 21-06.
- Pre-existing `mix format` drift in `lib/relyra/live_admin/connections_live.ex` from a Phase 20 commit — untouched by Plan 21-06 (this plan modifies `query.ex` and `connection_metadata_live.ex` but not `connections_live.ex`).

## User Setup Required

None — the operator-facing surface is purely additive on top of the existing `Relyra.LiveAdmin` mount points. Hosts that already mount `Relyra.LiveAdmin.ConnectionsLive` and `Relyra.LiveAdmin.ConnectionMetadataLive` will see:

1. The amber/red micro-badge appear next to a connection's display name when the source is in `:degraded` / `:suspended` state.
2. The "Auto-refresh health" card render above "Revision History" on the metadata page when a `MetadataSource` is registered.
3. The "Resume now" button render inside the card when the source is currently auto-suspended.

No new routes, no new mount points, no new templates. The badge and card are hidden when irrelevant.

## Next Plan Readiness

- **Plan 21-07 (`mix-tasks-telemetry-docs`, Wave 5) can proceed.** It will add `mix relyra.refresh_due` (calls `Scheduler.run_due/2` from a Mix-task wrapper), `mix relyra.metadata.pin` (uses `TrustAnchor.fingerprint/1` from Plan 03), the telemetry catalog entries for the new `[:relyra, :saml, :metadata, :auto_refresh, ...]` events, the `Relyra.Telemetry.Handlers.LogAlerts` reference handler (consumes the D-24 events the Plan 04 transact block emits), the README recipes (Oban Cron one-liner + k8s CronJob YAML + fly.io schedule), and the Oban CI smoke lane. CFG-08 closes when 21-07 ships.
- **The operator-facing surface is feature-complete for v0.5.** The badge + health card + Resume-now button are the three D-29 surfaces; tooltip on the badge, badges on per-org rollups, and a global health dashboard are explicit non-goals (D-29) and will be considered for v0.6 if adopter feedback demands them.
- **No blockers.** Both compile lanes green; full suite is at the same pre-existing-failure baseline as Plans 21-01..21-05.

## Threat Flags

None — no new security surface introduced beyond the locked threat register entries (T-21-35 through T-21-40) which are all `mitigate` per the plan's threat model and implemented as documented:

- T-21-35 (Repudiation: Resume-now without audit) — every Resume-now click writes the LOCKED `cause: "live_admin_auto_refresh_resume"` audit row through `MetadataApply.resume_auto_refresh/3`'s single-transaction seam (D-35) ✓
- T-21-36 (Tampering: concurrent Resume-now + scheduler tick) — the audit row + state-clear co-commit via `transact/2` (Plan 04); the subsequent Oban probe is deduplicated by the `unique:` constraint (Plan 05) ✓
- T-21-37 (Elevation of Privilege: non-admin operator triggering Resume now) — the LiveView is mounted under the existing `Relyra.LiveAdmin.Scope` + `on_mount` boundary; Phase 21 inherits the existing admin-scope check ✓
- T-21-38 (Information Disclosure: rendered fingerprints / cert details in HTML) — fingerprints are public values; cert PEMs are NOT rendered; the `legacy_unsigned_metadata_policy` map renders inside the existing `RiskPanel` which uses `Jason.encode!(_, pretty: true)` (same posture as v0.3 risk panels) ✓
- T-21-39 (Denial of Service: rapid Resume-now clicking) — the button is `disabled` while `@resume_status == :loading` (matches the `:metadata_refresh` button's disabled-while-loading pattern); subsequent clicks are no-ops via the disabled attr ✓
- T-21-40 (Tampering: brand-voice drift in operator copy) — grep-enforced acceptance criteria reject any usage of `polling` / `cron job` / `blocked` / `retry` / `circuit breaker` / `MaxBackoff` in either the connection list component or the connection metadata LiveView ✓

## Self-Check: PASSED

Plan-21-06 file existence and commit-hash verification:

- `lib/relyra/live_admin/query.ex` — FOUND
- `lib/relyra/live_admin/components/connection_list.ex` — FOUND
- `lib/relyra/live_admin/connection_metadata_live.ex` — FOUND
- `test/relyra/live_admin/connections_live_test.exs` — FOUND (modified; `:pending` tag removed; 11 tests)
- `test/relyra/live_admin/connection_metadata_live_test.exs` — FOUND (modified; `:pending` tag removed; 15 tests)
- Commit `67da767` (Task 1: surface auto_refresh_health on the connection list) — FOUND
- Commit `35a4cc7` (Task 2: Auto-refresh health card + Resume now to ConnectionMetadataLive) — FOUND

---

*Phase: 21-scheduled-metadata-refresh*
*Plan: 06 live-admin-surface*
*Completed: 2026-05-07*
