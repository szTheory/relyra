---
phase: 51-demo-app-foundation
plan: 04
subsystem: workspace-content
tags: [phoenix-templates, route-affordances, demo-workspace, ui]

requires:
  - phase: 51-02
    provides: host-owned route seams and Relyra route mounts
  - phase: 51-03
    provides: health/readiness probe endpoints
provides:
  - LedgerLoop workspace first screen at /
  - Setup, login, and support route affordance pages
  - Visible host/Relyra route ownership and health/readiness state copy
affects: [phase-51, demo-ui, route-regression]

tech-stack:
  added: []
  patterns:
    - Plain Phoenix controller/template route affordance pages
    - Explicit text status labels for health and readiness

key-files:
  created:
    - demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_html.ex
    - demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_html/setup.html.heex
    - demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_html/login.html.heex
    - demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_html/support.html.heex
  modified:
    - demo/ledger_loop/lib/ledger_loop_web/controllers/page_controller.ex
    - demo/ledger_loop/lib/ledger_loop_web/controllers/page_html/home.html.heex
    - demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_controller.ex
    - demo/ledger_loop/test/ledger_loop_web/controllers/page_controller_test.exs

key-decisions:
  - "The / workspace displays route ownership, demo health, demo readiness, and all Phase 51 affordance links without implementing Phase 52-55 behavior."
  - "Route affordance pages render stable host-owned placeholders that state future phase ownership boundaries."

patterns-established:
  - "Phase placeholder routes render HTML templates instead of sending text responses so future phases can replace content without route churn."
  - "Generated Phoenix starter tests are updated as part of replacing starter UI content."

requirements-completed: [DEMO-03, DEMO-04, DEMO-05]

duration: 8 min
completed: 2026-06-12
---

# Phase 51 Plan 04: Workspace Content Summary

**LedgerLoop workspace and route affordance pages with explicit host/Relyra ownership boundaries**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-12T16:00:36Z
- **Completed:** 2026-06-12T16:04:01Z
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments

- Replaced the generated Phoenix home page with the actual `LedgerLoop Workspace` first screen.
- Added visible tenant/status, setup, login, admin, support, mounted route, health, and readiness labels required by the UI spec.
- Added stable setup, login, and support affordance pages with Phase 52-55 ownership boundaries.
- Updated the generated page controller test to assert the LedgerLoop workspace content instead of Phoenix starter copy.

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement LedgerLoop workspace content** - `8f5c518` (`feat`)
2. **Task 2: Implement setup, login, and support route affordance content** - `0797ea9` (`feat`)

**Auto-fix:** `3b44189` (`test`) updates stale generated page assertions after the starter page was replaced.

**Plan metadata:** this summary is committed in the follow-up `docs(51-04)` metadata commit.

## Files Created/Modified

- `demo/ledger_loop/lib/ledger_loop_web/controllers/page_controller.ex` - Supplies boot/readiness status assigns to the workspace template.
- `demo/ledger_loop/lib/ledger_loop_web/controllers/page_html/home.html.heex` - Renders the LedgerLoop workspace, required route affordances, route scope evidence, and health/readiness references.
- `demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_controller.ex` - Renders setup, login, and support templates.
- `demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_html.ex` - Phoenix template module for route affordance pages.
- `demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_html/setup.html.heex` - Host-owned setup placeholder with Phase 53 and Phase 52 boundaries.
- `demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_html/login.html.heex` - Login placeholder stating Relyra verifies SAML trust and Phase 54/55 ownership.
- `demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_html/support.html.heex` - Host-owned support placeholder with Phase 53 and Phase 52 boundaries.
- `demo/ledger_loop/test/ledger_loop_web/controllers/page_controller_test.exs` - Regression assertions for workspace labels.

## Decisions Made

- Kept route affordance pages inert in Phase 51: they do not initiate SAML, seed tenant data, configure stores, create audit rows, or call IdP proof helpers.
- Used explicit text labels for `Demo health` and `Demo readiness`, with `/healthz` and `/readyz` route references, so status is not color-only.

## Deviations from Plan

- The generated Phoenix page controller test still expected starter copy after the workspace replacement. This was fixed under Rule 1 by updating the test assertions to the new LedgerLoop first-screen labels.

---

**Total deviations:** 1 auto-fixed
**Impact on plan:** No scope changes; the fix aligned stale generated tests with the implemented Phase 51 workspace.

## Issues Encountered

None beyond the stale generated test expectation.

## User Setup Required

None - no external service configuration required.

## Verification

- `cd demo/ledger_loop && mix compile --warnings-as-errors`
- `grep -R "LedgerLoop Workspace\\|Northstar Health SSO status\\|Open SSO Setup\\|Start Test Login\\|Open Relyra Admin\\|Open Support Scenario\\|Mounted SAML routes: /saml\\|Mounted operator routes: /relyra/admin\\|Demo health\\|Demo readiness" demo/ledger_loop/lib/ledger_loop_web/controllers/page_html`
- `grep -R "host-owned\\|Relyra verifies SAML trust\\|Phase 52\\|Phase 53\\|Phase 54" demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_html`
- `cd demo/ledger_loop && mix test --warnings-as-errors` -> `10 tests, 0 failures`

## Self-Check: PASSED

- Key files exist on disk.
- `git log --oneline --all --grep="51-04"` returns the task and auto-fix commits.
- All task acceptance criteria and plan-level verification commands passed.

## Next Phase Readiness

Ready for Plan 51-05 to apply the LedgerLoop visual system and responsive polish.

---
*Phase: 51-demo-app-foundation*
*Completed: 2026-06-12*
