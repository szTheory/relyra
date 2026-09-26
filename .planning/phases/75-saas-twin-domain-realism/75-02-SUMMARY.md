---
phase: 75-saas-twin-domain-realism
plan: 02
subsystem: database
tags: [ecto, metadata, certificates, audit, fixtures]
requires:
  - phase: 75-01
    provides: Tenant-owned Northstar and Harborline scenarios and scoped reset
provides:
  - Fixed-time metadata, certificate-validity, and audit chronology
  - Recovered metadata-source health snapshot with applied revision pointers
affects: [phase-76, ledgerloop, twin-fixtures]
actuals:
  tokens: 4700
  tasks: 2
  commits: 1
tech-stack:
  added: []
  patterns: [fixed-clock trust chronology, synthetic history seeded separately from runtime audit writes]
key-files:
  created:
    - demo/ledger_loop/test/twin/certificate_history_test.exs
  modified:
    - demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex
    - demo/ledger_loop/lib/ledger_loop/demo/reset.ex
    - demo/ledger_loop/test/ledger_loop/demo/keycloak_provisioner_test.exs
key-decisions:
  - "Operational degradation and recovery use metadata revision/source health and audit evidence; certificate lifecycle remains active/next/retired."
  - "Synthetic fixed history is inserted as fixture reconstruction; runtime trust mutations remain on their existing audit transaction seam."
requirements-completed: [TWIN-03, TWIN-05]
coverage:
  - id: D1
    description: "One connection carries an ordered registered, applied, failed, and recovered metadata history."
    requirement: TWIN-03
    verification:
      - kind: integration
        ref: "demo/ledger_loop/test/twin/certificate_history_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Fixed-time active, staged, expiring, and retired certificate facts remain distinct from operational health."
    requirement: TWIN-03
    verification:
      - kind: integration
        ref: "demo/ledger_loop/test/twin/certificate_history_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "All demo adopter contracts pass with the expanded trust fixtures."
    requirement: TWIN-05
    verification:
      - kind: integration
        ref: "mix ci.demo_app"
        status: pass
    human_judgment: false
duration: 5 min
completed: 2026-09-26
status: complete
---

# Phase 75 Plan 02: Fixed trust history

**Northstar’s connection now exposes a deterministic metadata failure and recovery timeline alongside certificate lifecycle and expiry facts.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-09-26T01:17:45Z
- **Completed:** 2026-09-26T01:22:15Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added a fixed-time metadata source with registered, applied, failed, and recovered revisions.
- Linked the active and last-known-good connection pointers to the recovered applied revision.
- Added expiring active, staged next, and retired certificate rows with stable lifecycle times.
- Added bounded synthetic degraded/recovered audit records and a mandatory history contract.
- Updated the Keycloak negative test to compare against the fixture-owned revision set instead of assuming the entire database is empty.

## Task Commits

1. **Task 1: Seed and prove connection, revision and certificate chronology** — `7cc4d93` (feat)
2. **Task 2: Complete degraded and recovered health with audit evidence** — `7cc4d93` (feat; implemented with Task 1 in one atomic fixture/history commit)

**Plan metadata:** pending

## Files Created/Modified

- `demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex` — Fixed trust event and row catalog.
- `demo/ledger_loop/lib/ledger_loop/demo/reset.ex` — Dependency-ordered fixture reconstruction and pointer update.
- `demo/ledger_loop/test/twin/certificate_history_test.exs` — Chronology, ownership, pointer, validity, and safety proof.
- `demo/ledger_loop/test/ledger_loop/demo/keycloak_provisioner_test.exs` — Preserved the negative provisioning guarantee while recognizing unrelated named fixture history.

## Decisions Made

- Degraded and recovered are metadata-source operational health facts; certificate lifecycle is limited to its existing values.
- Historical fixtures are inserted directly as deterministic reconstruction rows. Runtime trust mutation continues through its existing audited persistence paths.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Scope existing Keycloak absence assertion to its fixture boundary**
- **Found during:** Task 2
- **Issue:** The negative Keycloak provisioning test asserted there were zero metadata revisions globally, conflicting with the newly required unrelated Northstar fixture history.
- **Fix:** Compare persisted revisions with the exact fixture-owned revision IDs, so failed Keycloak provisioning still cannot add a revision.
- **Files modified:** `demo/ledger_loop/test/ledger_loop/demo/keycloak_provisioner_test.exs`
- **Verification:** `mix ci.demo_app` passed (94 tests, 0 failures).
- **Committed in:** `7cc4d93`

**Total deviations:** 1 auto-fixed (1 compatibility assertion). **Impact:** Kept the existing Keycloak security guarantee while allowing independent trust history rows.

## Issues Encountered

- Datetime assertions needed explicit microsecond precision to match persisted UTC columns. The focused contract passed after normalizing expected timestamps.
- Validation used Elixir 1.19.5/OTP 28 explicitly and a temporary writable Hex cache because `.tool-versions` and `~/.hex` are outside this run’s selected environment/write boundary.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for Plan 75-03 to add the synthetic support incident timeline and prove repeated scoped reset.

---
*Phase: 75-saas-twin-domain-realism*
*Completed: 2026-09-26*
