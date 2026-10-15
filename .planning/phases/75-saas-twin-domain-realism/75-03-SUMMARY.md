---
phase: 75-saas-twin-domain-realism
plan: 03
subsystem: testing
tags: [ledgerloop, audit, login-trace, redaction, deterministic-reset]
requires:
  - phase: 75-02
    provides: Fixed trust chronology and tenant-owned scenario catalog
provides:
  - Five-stage synthetic support incident linked to the six diagnostic trace steps
  - Full fixture-owned reset equality and unrelated sentinel preservation contracts
affects: [phase-76, ledgerloop, twin-fixtures]
actuals:
  tokens: 6100
  tasks: 2
  commits: 1
tech-stack:
  added: []
  patterns: [fixed timestamp synthetic audit rows, whole fixture-set reset snapshots]
key-files:
  created:
    - demo/ledger_loop/test/twin/incident_timeline_test.exs
    - demo/ledger_loop/test/twin/reset_test.exs
  modified:
    - demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex
    - demo/ledger_loop/lib/ledger_loop/demo/reset.ex
    - demo/ledger_loop/test/ledger_loop/demo/reset_test.exs
key-decisions:
  - "Support incident stages and diagnostic traces share a stable stored correlation; the existing exporter hashes it and allow-lists step fields."
  - "Repeated reset equality covers every fixture-owned host and Relyra row while explicit unrelated sentinels remain unchanged."
requirements-completed: [TWIN-04, TWIN-05]
coverage:
  - id: D1
    description: "The existing support route leads to one ordered symptom, diagnosis, remediation, retry, and recovery incident."
    requirement: TWIN-04
    verification:
      - kind: integration
        ref: "demo/ledger_loop/test/twin/incident_timeline_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Trace exports hash correlation and allow-list nested step fields while stored audit summaries remain bounded and synthetic."
    requirement: TWIN-04
    verification:
      - kind: integration
        ref: "demo/ledger_loop/test/twin/incident_timeline_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "Repeated reset reproduces every fixture-owned persisted row and preserves an unrelated tenant and connection."
    requirement: TWIN-05
    verification:
      - kind: integration
        ref: "demo/ledger_loop/test/twin/reset_test.exs"
        status: pass
    human_judgment: false
  - id: D4
    description: "All five mandatory twin evidence owners and existing LedgerLoop demo tests pass together."
    requirement: TWIN-05
    verification:
      - kind: integration
        ref: "mix ci.demo_app"
        status: pass
    human_judgment: false
duration: 7 min
completed: 2026-09-26
status: complete
---

# Phase 75 Plan 03: Support incident and deterministic reset

**LedgerLoop now shows one redacted symptom-to-recovery support incident and recreates its complete multi-tenant fixture set deterministically.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-09-26T01:22:15Z
- **Completed:** 2026-09-26T01:28:55Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added five fixed-time incident stages linked to the six preserved diagnostic trace steps through one stable correlation lineage.
- Reused the shared login trace exporter and proved stable correlation hashing plus allow-listed nested step data.
- Replaced wall-clock support seed writes with deterministic, fixture-owned audit rows while retaining opt-in visual evidence.
- Added full persisted-row comparison over every fixture-owned tenant and Relyra table, plus unrelated tenant/connection sentinels.
- Updated legacy reset evidence to preserve the six diagnostic-step contract alongside the incident timeline.

## Task Commits

1. **Task 1: Present a fixed symptom-to-recovery support timeline** — `95ef1f4` (feat)
2. **Task 2: Prove full reset determinism, scenario ownership and sentinel survival** — implemented with Task 1 in the same atomic fixture/reset contract commit.

**Plan metadata:** pending

## Files Created/Modified

- `demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex` — Fixed trace and incident event definitions.
- `demo/ledger_loop/lib/ledger_loop/demo/reset.ex` — Deterministic insert of synthetic audit history.
- `demo/ledger_loop/test/twin/incident_timeline_test.exs` — Route, chronology, correlation, export, and safe-summary assertions.
- `demo/ledger_loop/test/twin/reset_test.exs` — Full fixture snapshot repeatability and sentinel preservation.
- `demo/ledger_loop/test/ledger_loop/demo/reset_test.exs` — Preserved legacy diagnostic trace assertions.

## Decisions Made

- The stored incident stages and diagnostic trace rows share one stable synthetic correlation ID; only the existing export surface hashes it for display.
- Full-row snapshots are selected by the fixture catalog’s exact IDs, making unrelated local tenant and connection records explicit reset sentinels.

## Deviations from Plan

None - plan executed as written.

### Post-review hardening

- The incident test temporarily disables and restores `DEMO_TRACE_VISUAL_FIXTURE` around reset, so an opt-in visual audit row cannot contaminate the incident owner.
- **Verification:** the incident owner passed with `DEMO_TRACE_VISUAL_FIXTURE=1` and in the normal test environment; `mix ci.demo_app` passed (97 tests, 0 failures).

## Issues Encountered

- The incident owner needed an explicit `Ecto.Query` import because its Phoenix connection test template does not import query macros. The focused owner and full lane passed after adding it.
- Validation used Elixir 1.19.5/OTP 28 and a temporary writable Hex cache for the same environment constraints recorded by Plans 75-01 and 75-02.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- All Phase 75 fixture contracts are ready for the Phase 76 adopter journeys.

---
*Phase: 75-saas-twin-domain-realism*
*Completed: 2026-09-26*
