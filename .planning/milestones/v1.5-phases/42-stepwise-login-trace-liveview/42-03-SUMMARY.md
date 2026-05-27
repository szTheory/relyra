---
phase: 42-stepwise-login-trace-liveview
plan: 03
subsystem: ui
tags: [login-trace, liveview, live-admin, ui-contract, trace-01]

requires:
  - phase: 42-stepwise-login-trace-liveview
    provides: LoginTrace.Export and Query.get_login_traces/4 (42-02)
provides:
  - ConnectionTraceLive at /connections/:connection_id/trace
  - View Login Trace navigation from connection detail
  - Phase 15 UI contract coverage for trace page
affects:
  - 42-04 (mix relyra.trace CLI + security corpus)

tech-stack:
  added: []
  patterns:
    - "Trace LiveView loads redacted rows exclusively via Query.get_login_traces/4"
    - "Expandable login cards use details/summary with open default for contract tests"
    - "Six consume-path steps rendered in LoginTrace.Export canonical order"

key-files:
  created:
    - lib/relyra/live_admin/connection_trace_live.ex
  modified:
    - lib/relyra/live_admin/router.ex
    - lib/relyra/live_admin/components/connection_detail.ex
    - test/relyra/live_admin/phase15_ui_contract_test.exs

key-decisions:
  - "Trace assigns come from Query.get_login_traces/4 only — no raw after_summary in LiveView"
  - "Login cards use details open by default so step testids are visible without interaction"

patterns-established:
  - "data-testid login-trace-page, login-trace-row-{id}, login-trace-step-{name}"
  - "Empty state uses exact D-16 copy from phase context"

requirements-completed: [TRACE-01]

duration: 12min
completed: 2026-05-27
---

# Phase 42 Plan 03: Login Trace LiveView Summary

**ConnectionTraceLive mounts at /connections/:id/trace with expandable six-step login rows, navigation link, and Phase 15 UI contract tests**

## Performance

- **Duration:** 12 min
- **Started:** 2026-05-27T19:54:00Z
- **Completed:** 2026-05-27T20:06:00Z
- **Tasks:** 2
- **Files modified:** 4 (1 created, 3 modified)

## Accomplishments

- Registered `ConnectionTraceLive` route under existing `:relyra_admin` live_session
- Built trace page listing last 20 login attempts with expandable six-step rows (outcome, error_code, duration_ms)
- Added "View Login Trace" navigation card on connection detail
- Extended Phase 15 UI contract tests for trace route, step rows, empty state, and nav link

## Task Commits

Each task was committed atomically:

1. **Task 1: Register trace route and LiveView** - `6cc786e` (feat)
2. **Task 2: Extend Phase 15 UI contract tests** - `d05c36e` (test)

## Files Created/Modified

- `lib/relyra/live_admin/connection_trace_live.ex` - Trace LiveView with expandable login cards
- `lib/relyra/live_admin/router.ex` - `/connections/:connection_id/trace` route
- `lib/relyra/live_admin/components/connection_detail.ex` - View Login Trace link
- `test/relyra/live_admin/phase15_ui_contract_test.exs` - Trace page UI contract tests

## Decisions Made

- Trace data flows through `Query.get_login_traces/4` (which maps via `LoginTrace.Export`) — LiveView never reads raw audit `after_summary`
- Used `<details open>` so contract tests can assert step testids without simulating expand clicks

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] AuditWriter seed attrs missing required summaries in UI test**
- **Found during:** Task 2 (Phase 15 UI contract tests)
- **Issue:** `AuditWriter.append_event/2` requires non-empty `diff_summary` and `before_summary`; test seed omitted them
- **Fix:** Added `before_summary: %{}` and `diff_summary: %{"kind" => "login_trace"}` matching LoginTrace handler shape
- **Files modified:** `test/relyra/live_admin/phase15_ui_contract_test.exs`
- **Verification:** `mix test test/relyra/live_admin/phase15_ui_contract_test.exs --warnings-as-errors` — 6 tests, 0 failures
- **Committed in:** `d05c36e` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Test-only fix; no production code change. Required for valid audit row seeding.

## Issues Encountered

None beyond the audit seed validation noted above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 42-04 can wire `mix relyra.trace` CLI and `test/security/login_trace_test.exs` corpus
- TRACE-02 security gate remains for plan 42-04

## Self-Check: PASSED

- `mix test test/relyra/live_admin/phase15_ui_contract_test.exs --warnings-as-errors` — 6 tests, 0 failures
- `mix test test/relyra/live_admin/ --warnings-as-errors` — 32 tests, 0 failures

---
*Phase: 42-stepwise-login-trace-liveview*
*Completed: 2026-05-27*
