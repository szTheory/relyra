---
phase: 51-demo-app-foundation
plan: 02
subsystem: routing
tags: [phoenix-router, saml-routes, live-admin, scope-provider]

requires:
  - phase: 51-01
    provides: demo/ledger_loop Phoenix scaffold
provides:
  - Host-owned setup, login, support, SAML, and LiveAdmin route seams
  - Demo-owned LiveAdmin scope provider
  - Compiled route table with Relyra handlers mounted under LedgerLoop paths
affects: [phase-51, demo-routing, live-admin, saml]

tech-stack:
  added: []
  patterns:
    - Host-owned Phoenix paths delegating to Relyra router macros
    - Session-backed LiveAdmin scope provider owned by the host app

key-files:
  created:
    - demo/ledger_loop/lib/ledger_loop/relyra/admin_scope.ex
    - demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_controller.ex
  modified:
    - demo/ledger_loop/lib/ledger_loop_web/router.ex

key-decisions:
  - "Mounted Relyra macros in non-aliased Phoenix scopes so generated handlers remain Relyra.* modules."
  - "Kept setup/login/support routes as text route seams; later phases own full templates and behavior."

patterns-established:
  - "LedgerLoop owns visible paths while Relyra owns SAML and LiveAdmin internals through existing macros."
  - "Admin access is mediated through LedgerLoop.Relyra.AdminScope and session keys, not demo-global bypasses."

requirements-completed: [DEMO-03, DEMO-04]

duration: 5 min
completed: 2026-06-12
---

# Phase 51 Plan 02: Mount Relyra Route Seams Summary

**LedgerLoop-owned Phoenix routes now mount Relyra SAML and LiveAdmin internals with a demo-owned admin scope provider**

## Performance

- **Duration:** 5 min
- **Started:** 2026-06-12T15:47:55Z
- **Completed:** 2026-06-12T15:52:42Z
- **Tasks:** 1
- **Files modified:** 3

## Accomplishments

- Added host-owned routes for `/`, `/setup/sso`, `/login/test`, and `/support/scenario`.
- Mounted Relyra SAML routes under `/saml` and LiveAdmin under `/relyra/admin`.
- Created `LedgerLoop.Relyra.AdminScope` implementing `Relyra.LiveAdmin.ScopeProvider` with session-key based authentication.

## Task Commits

Each task was committed atomically:

1. **Task 1: Mount host-owned Relyra route seams** - `226d133` (`feat`)

**Plan metadata:** this summary is committed in the follow-up `docs(51-02)` metadata commit.

## Files Created/Modified

- `demo/ledger_loop/lib/ledger_loop_web/router.ex` - Imports Relyra router macros and registers host-owned workspace, route affordance, SAML, and LiveAdmin paths.
- `demo/ledger_loop/lib/ledger_loop/relyra/admin_scope.ex` - Demo-owned LiveAdmin scope provider using `admin_actor`, `admin_actor_label`, and `admin_organization_id` session keys.
- `demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_controller.ex` - Compile-safe placeholder route seams for setup, login, and support destinations.

## Decisions Made

- Used non-aliased Phoenix scopes around Relyra macros. A `LedgerLoopWeb`-aliased scope rewrites macro-expanded controller/live module names to `LedgerLoopWeb.Relyra.*`, which fails warnings-as-errors.
- Kept route affordance actions as plain text responses so Phase 51-04 can own the full HEEx route-affordance content.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Mounted Relyra macros in non-aliased scopes**
- **Found during:** Task 1 (Mount host-owned Relyra route seams)
- **Issue:** Expanding `saml_routes()` and `relyra_admin_routes/2` inside a `LedgerLoopWeb`-aliased scope caused Phoenix verified-route warnings for nonexistent `LedgerLoopWeb.Relyra.*` modules.
- **Fix:** Kept the host-owned `/saml` and `/relyra/admin` paths but expanded the macros inside non-aliased scopes, using explicit host controller modules for LedgerLoop-owned routes.
- **Files modified:** `demo/ledger_loop/lib/ledger_loop_web/router.ex`
- **Verification:** `cd demo/ledger_loop && mix compile --warnings-as-errors`; `cd demo/ledger_loop && mix phx.routes`
- **Committed in:** `226d133`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Route behavior matches the phase goal and route table. The literal `scope "/saml", LedgerLoopWeb` source form was not used because it breaks macro expansion under warnings-as-errors.

## Issues Encountered

- Phoenix scope aliasing can rewrite macro-expanded Relyra modules when mounted inside an aliased host scope; fixed by non-aliased macro expansion.

## User Setup Required

None - no external service configuration required.

## Verification

- `cd demo/ledger_loop && mix compile --warnings-as-errors`
- `grep -n "scope \"/saml\"\\|saml_routes\\|relyra_admin_routes(" demo/ledger_loop/lib/ledger_loop_web/router.ex`
- `cd demo/ledger_loop && mix phx.routes`
- Route table includes:
  - `GET /setup/sso` -> `LedgerLoopWeb.RouteAffordanceController :setup`
  - `GET /login/test` -> `LedgerLoopWeb.RouteAffordanceController :login`
  - `GET /support/scenario` -> `LedgerLoopWeb.RouteAffordanceController :support`
  - `GET /relyra/admin` -> `Relyra.LiveAdmin.ConnectionsLive :index`
  - `GET /saml/:connection_id/metadata` -> `Relyra.Phoenix.Controllers.MetadataController :show`
  - `POST /saml/:connection_id/acs` -> `Relyra.Phoenix.Controllers.ACSController :create`

## Self-Check: PASSED

- Key files exist on disk.
- `git log --oneline --all --grep="51-02"` returns the task commit.
- All acceptance criteria passed except the literal aliased `/saml` source shape, which was documented as a blocking compile deviation.

## Next Phase Readiness

Ready for Plan 51-06 package-boundary proof and Wave 3 route/readiness/UI tests.

---
*Phase: 51-demo-app-foundation*
*Completed: 2026-06-12*
