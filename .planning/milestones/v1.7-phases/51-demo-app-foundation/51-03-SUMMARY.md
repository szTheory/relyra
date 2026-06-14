---
phase: 51-demo-app-foundation
plan: 03
subsystem: health-readiness
tags: [healthz, readyz, phoenix-router, exunit]

requires:
  - phase: 51-02
    provides: host-owned route seams and Relyra route mounts
provides:
  - Lightweight /healthz and /readyz probe endpoints
  - Readiness decision helper with deterministic test overrides
  - Route and readiness Wave 0 tests for DEMO-04 and DEMO-05
affects: [phase-51, docker-readiness, route-regression]

tech-stack:
  added: []
  patterns:
    - Non-browser Phoenix health pipeline
    - Deterministic readiness override via application env for tests

key-files:
  created:
    - demo/ledger_loop/lib/ledger_loop/health.ex
    - demo/ledger_loop/lib/ledger_loop_web/controllers/health_controller.ex
    - demo/ledger_loop/test/ledger_loop_web/controllers/health_controller_test.exs
    - demo/ledger_loop/test/ledger_loop_web/router_test.exs
  modified:
    - demo/ledger_loop/lib/ledger_loop_web/router.ex

key-decisions:
  - "Readiness checks database availability with SELECT 1 by default and never requires Phase 52 seed data."
  - "Health probes use a dedicated :health pipeline with only accepts/json, outside browser session/CSRF plugs."

patterns-established:
  - "Docker/CI probes return only booted, ready, or unavailable text."
  - "Router tests assert both Relyra route mounts and health pipeline placement."

requirements-completed: [DEMO-04, DEMO-05]

duration: 5 min
completed: 2026-06-12
---

# Phase 51 Plan 03: Health, Readiness, And Route Tests Summary

**Lightweight Phoenix health/readiness probes with automated route mount coverage for SAML and LiveAdmin seams**

## Performance

- **Duration:** 5 min
- **Started:** 2026-06-12T15:55:35Z
- **Completed:** 2026-06-12T15:59:59Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added `/healthz` and `/readyz` under a non-browser `:health` pipeline.
- Implemented `LedgerLoop.Health.ready?/0` with deterministic `:force_ready` and `:force_unavailable` overrides plus a default database `SELECT 1` check.
- Added route tests proving `/saml`, `/relyra/admin`, `/healthz`, and `/readyz` route registration.
- Added health controller tests covering `booted`, `ready`, and `unavailable` responses.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add non-browser health and readiness probes** - `801cc07` (`feat`)
2. **Task 2: Create Wave 0 route and readiness tests** - `992c237` (`test`)

**Plan metadata:** this summary is committed in the follow-up `docs(51-03)` metadata commit.

## Files Created/Modified

- `demo/ledger_loop/lib/ledger_loop/health.ex` - Readiness helper using application env overrides or `LedgerLoop.Repo.query("SELECT 1", [], timeout: 1000)`.
- `demo/ledger_loop/lib/ledger_loop_web/controllers/health_controller.ex` - Text-only `/healthz` and `/readyz` responses.
- `demo/ledger_loop/lib/ledger_loop_web/router.ex` - Adds the lightweight `:health` pipeline and probe routes.
- `demo/ledger_loop/test/ledger_loop_web/router_test.exs` - Route mount and health pipeline regression tests.
- `demo/ledger_loop/test/ledger_loop_web/controllers/health_controller_test.exs` - Probe response tests.

## Decisions Made

- Returned only `booted`, `ready`, and `unavailable` from probe endpoints to avoid leaking database errors or future SAML/demo state.
- Used source-level assertions for health pipeline placement because Phoenix route metadata does not expose pipeline names.

## Deviations from Plan

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed
**Impact on plan:** No scope changes.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Verification

- `cd demo/ledger_loop && mix compile --warnings-as-errors`
- `grep -n "pipeline :health\\|pipe_through(:health)\\|get(\"/healthz\"\\|get(\"/readyz\"" demo/ledger_loop/lib/ledger_loop_web/router.ex`
- `cd demo/ledger_loop && mix test test/ledger_loop_web/router_test.exs test/ledger_loop_web/controllers/health_controller_test.exs --warnings-as-errors` -> `5 tests, 0 failures`
- `cd demo/ledger_loop && mix test --warnings-as-errors` -> `10 tests, 0 failures`

## Self-Check: PASSED

- Key files exist on disk.
- `git log --oneline --all --grep="51-03"` returns both task commits.
- All task acceptance criteria and plan-level verification commands passed.

## Next Phase Readiness

Ready for Plan 51-04 to replace generated starter content with LedgerLoop workspace and route affordance pages.

---
*Phase: 51-demo-app-foundation*
*Completed: 2026-06-12*
