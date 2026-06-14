---
phase: 52-ecto-stores-and-deterministic-seed-story
plan: 03
subsystem: demo
tags: [demo, seeds, ecto, relyra_connections, test_fixtures]

# Dependency graph
requires:
  - phase: 52-ecto-stores-and-deterministic-seed-story
    provides: [LedgerLoop.Demo.Reset schema cleanup]
provides:
  - Seeded Relyra connection scenarios, certificates, mappings, and redaction-safe audit rows
  - Workspace shell display of seeded connection scenarios
affects: [53-admin-ui-and-browser-proof]

# Tech tracking
tech-stack:
  added: []
  patterns: [Deterministic seeding, redaction-safe trace audit logs]

key-files:
  created: []
  modified: 
    - demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex
    - demo/ledger_loop/lib/ledger_loop/demo/reset.ex
    - demo/ledger_loop/lib/ledger_loop_web/controllers/page_controller.ex
    - demo/ledger_loop/lib/ledger_loop_web/controllers/page_html/home.html.heex
    - demo/ledger_loop/test/ledger_loop/demo/connection_scenarios_test.exs

key-decisions:
  - "Added connection, certificate, mapping, and audit schemas to Relyra.Demo.Fixtures to support the seeded scenarios"
  - "Queried active connection scenarios directly from Relyra.Ecto.Connection via LedgerLoop.Repo for display in the workspace shell"

patterns-established:
  - "Pattern 1: Seeded scenarios define a clear set of static data that aligns tightly with Ecto requirements and test fixture structures"

requirements-completed: [DATA-01, DATA-02]

# Metrics
duration: 10min
completed: 2026-05-23
---

# Phase 52 Plan 03: Seed Relyra Connection Scenarios Summary

**Seeded deterministic Relyra connection scenarios with redaction-safe traces and rendered their statuses in the workspace shell.**

## Performance

- **Duration:** 10m
- **Started:** 2026-05-23T12:00:00Z
- **Completed:** 2026-05-23T12:10:00Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Seeded four Relyra connection scenarios: enabled, draft/missing-metadata, staged-certificate, and failure/support
- Verified redaction-safe audit/trace logs containing exact step traces without exposing private keys, certs, or test-IdP tokens
- Updated LedgerLoop workspace to inspect seeded scenario statuses via Ecto query

## Task Commits

Each task was committed atomically:

1. **Task 1: Seed Relyra connection scenarios, audits, and login traces** - `4a7bff0` (test), `44ba192` (style)
2. **Task 2: Render seeded scenario status in the workspace shell** - `6ac5b8b` (feat)

**Plan metadata:** `pending` (docs: complete plan)

## Files Created/Modified
- `demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex` - Added scenario fixtures
- `demo/ledger_loop/lib/ledger_loop/demo/reset.ex` - Inserted fixtures via Ecto upon demo reset
- `demo/ledger_loop/lib/ledger_loop_web/controllers/page_controller.ex` - Handled Ecto query for scenario display
- `demo/ledger_loop/lib/ledger_loop_web/controllers/page_html/home.html.heex` - Rendered the queried scenarios
- `demo/ledger_loop/test/ledger_loop/demo/connection_scenarios_test.exs` - Validated seeded data and redaction constraints
- `demo/ledger_loop/test/ledger_loop_web/controllers/page_controller_test.exs` - Updated assertions

## Decisions Made
- Scenarios were rendered by directly querying `Relyra.Ecto.Connection` in the PageController and displaying the name and status cleanly in the template.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## Next Phase Readiness
- Ready for Phase 53 Admin UI and browser proof workflow, leveraging the seeded test scenarios.
