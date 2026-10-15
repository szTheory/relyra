---
phase: 75-saas-twin-domain-realism
plan: 01
subsystem: database
tags: [ledgerloop, ecto, tenants, fixtures, user-mapping]
requires: []
provides:
  - Tenant-owned Northstar and Harborline fixture catalog
  - Scoped deterministic reset and mapped principal/provider contracts
affects: [phase-76, ledgerloop, twin-fixtures]
actuals:
  tokens: 5700
  tasks: 2
  commits: 1
tech-stack:
  added: []
  patterns: [closed fixture-owned ID sets, tenant-scoped principal mapping]
key-files:
  created:
    - demo/ledger_loop/test/twin/organization_test.exs
    - demo/ledger_loop/test/twin/provider_test.exs
  modified:
    - demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex
    - demo/ledger_loop/lib/ledger_loop/demo/reset.ex
    - demo/ledger_loop/test/ledger_loop/demo/connection_scenarios_test.exs
key-decisions:
  - "Tenant identity owns each named principal; Northstar and Harborline are equal fixture scenarios."
  - "Reset deletes only fixture-catalog tenant and connection IDs, preserving optional adopter connections."
requirements-completed: [TWIN-01, TWIN-02, TWIN-05]
coverage:
  - id: D1
    description: "Northstar and Harborline users map to their own tenant and declared group authorization outcome."
    requirement: TWIN-01
    verification:
      - kind: integration
        ref: "demo/ledger_loop/test/twin/organization_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Named connections carry their tenant ownership and distinct provider, issuer, and readiness facts."
    requirement: TWIN-02
    verification:
      - kind: integration
        ref: "demo/ledger_loop/test/twin/provider_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "The full LedgerLoop demo app suite verifies existing Northstar behavior and tenant fixture compatibility."
    requirement: TWIN-05
    verification:
      - kind: integration
        ref: "mix ci.demo_app"
        status: pass
    human_judgment: false
duration: 8 min
completed: 2026-09-26
status: complete
---

# Phase 75 Plan 01: Tenant-owned adopters and providers

**Northstar and Harborline now have isolated tenant-linked identities, group expectations, and provider-owned Relyra connections.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-09-26T01:09:00Z
- **Completed:** 2026-09-26T01:17:45Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added Harborline tenant, administrator, operations user, groups, memberships, SAML identities, and Google Workspace connection alongside Northstar.
- Made `Fixtures.tenants/0` the canonical tenant catalog while retaining `tenant/0` compatibility.
- Scoped reset deletion to fixture-owned tenant and connection IDs, preserving optional or unrelated connections.
- Added mapper and provider ownership contracts and updated the legacy scenario count to derive from the fixture catalog.

## Task Commits

1. **Task 1: Map one second-tenant principal through the complete fixture and reset path** — `557ec82` (feat)
2. **Task 2: Complete named people, roles, authorization and provider variation** — implemented with Task 1 in the same atomic fixture/test commit.

**Plan metadata:** pending

## Files Created/Modified

- `demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex` — Tenant-first fixture rows and provider scenario.
- `demo/ledger_loop/lib/ledger_loop/demo/reset.ex` — Closed-set scoped reset.
- `demo/ledger_loop/test/twin/organization_test.exs` — Tenant, group, and authorization mapping proof.
- `demo/ledger_loop/test/twin/provider_test.exs` — Connection ownership and provider/readiness proof.
- `demo/ledger_loop/test/ledger_loop/demo/connection_scenarios_test.exs` — Catalog-derived scenario count.

## Decisions Made

- Kept Northstar as the existing FakeIdP adopter scenario and modeled Harborline as a second tenant with a distinct issuer/subject and Google Workspace preset.
- Used fixture-owned connection record IDs for deletion after the full suite exposed a same-tenant optional Keycloak connection that must survive reset.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserve non-fixture connection rows during tenant reset**
- **Found during:** Task 2
- **Issue:** Deleting every connection with a fixture tenant slug removed the optional Keycloak connection and collided with its reserved public ID.
- **Fix:** Assigned Harborline a distinct scenario ID and changed reset selection to the exact connection IDs in `Fixtures.relyra_connections/0`.
- **Files modified:** `demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex`, `demo/ledger_loop/lib/ledger_loop/demo/reset.ex`
- **Verification:** `mix ci.demo_app` passed (93 tests, 0 failures), including optional Keycloak and host route tests.
- **Committed in:** `557ec82`

**Total deviations:** 1 auto-fixed (1 bug). **Impact:** Required to preserve the existing optional adopter setup and keep reset within its fixture-owned scope.

## Issues Encountered

- The checkout’s `.tool-versions` does not select Elixir. Validation used installed Elixir 1.19.5/OTP 28 explicitly. Hex required a writable cache, so `HEX_HOME` was redirected to `/private/tmp`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for Plan 75-02 to attach a deterministic metadata/certificate history to these fixture-owned scenarios.

---
*Phase: 75-saas-twin-domain-realism*
*Completed: 2026-09-26*
