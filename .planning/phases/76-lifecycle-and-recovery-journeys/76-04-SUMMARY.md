---
phase: 76-lifecycle-and-recovery-journeys
plan: 04
subsystem: auth
tags: [phoenix, ecto, audit, playwright, incident-recovery]
requires:
  - phase: 76-lifecycle-and-recovery-journeys
    provides: Signed ACS journey driver, tenant-scoped login trace query, and audited trust lifecycle seams
provides:
  - Real support-incident login failure, scoped diagnosis, audited trust repair, and verified retry
  - Safe status-only artifact and owner/recovery summary for the required trace visual browser lane
affects: [76-lifecycle-and-recovery-journeys]
actuals:
  tokens: 5304
  tasks: 2
  commits: 2
tech-stack:
  added: []
  patterns:
    - Incident recovery uses independent login correlation IDs and ties attempts to the seeded timeline by owning connection and explicit remediation cause
    - Browser process status is written through a fixed-schema allowlisted artifact outside the temporary Playwright output directory
key-files:
  created:
    - demo/ledger_loop/test/twin/incident_recovery_test.exs
    - scripts/test_trace_visual_status_contract.sh
  modified:
    - demo/ledger_loop/test/browser/trace_visual.spec.ts
    - scripts/test_trace_visual_e2e.sh
    - .github/workflows/demo-app-e2e.yml
key-decisions:
  - Repair and retry attempts retain independent hashed trace correlations; the seeded incident linkage uses its owning connection and explicit audited remediation cause.
  - The browser artifact stores only schema version, owner, pass/fail status, and recovery command; the job summary repeats the owner role and recovery command.
requirements-completed: [JOUR-06]
coverage:
  - id: D1
    description: A real support ACS failure is scoped and exported safely, trust is repaired with audited metadata/certificate operations, and a fresh signed retry creates the correct Northstar receipt.
    requirement: JOUR-06
    verification:
      - kind: integration
        ref: "demo/ledger_loop/test/twin/incident_recovery_test.exs#a scoped support incident moves from real failed login through audited repair to verified retry"
        status: pass
      - kind: integration
        ref: "demo/ledger_loop/test/twin/incident_timeline_test.exs#support route, incident stages, trace, and safe exported correlation share one fixture"
        status: pass
      - kind: integration
        ref: "mix ci.demo_app (106 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D2
    description: The supported browser trace journey displays its owned typed failure and the mandatory browser workflow retains only safe status with seven-day retention, a named owner, and recovery command.
    requirement: JOUR-06
    verification:
      - kind: automated_ui
        ref: "npm run demo:trace-visual (1 Playwright test passed)"
        status: pass
      - kind: integration
        ref: "bash scripts/test_trace_visual_status_contract.sh (pass/fail status and workflow metadata contract passed)"
        status: pass
    human_judgment: false
duration: 13 min
completed: 2026-09-26
status: complete
---

# Phase 76 Plan 04: Incident Recovery and Safe Browser Status Summary

**The support incident now reaches a verified login after audited trust repair, and browser failures retain a bounded owner-controlled status signal.**

## Performance

- **Duration:** 13 min
- **Started:** 2026-09-26T14:13:20Z
- **Completed:** 2026-09-26T14:26:35Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added a real signed ACS attempt against the support connection's nonmatching active trust anchor. The ACS returns `:invalid_signature`, creates no receipt, and produces a scoped failed login trace.
- Repaired trust through audited `MetadataApply` and `CertificateInventory` transitions, then proved a fresh signed login verifies and creates Sarah's connection-specific Northstar receipt.
- Bound the seeded support timeline and remediation audits to the owning support connection and explicit causes, while preserving the distinct per-attempt correlation IDs and checking their exported hashes and allowlisted fields.
- Extended the browser trace journey to assert the owned support failure row. The harness writes only a fixed-schema pass/fail artifact and preserves the Playwright exit code; the mandatory workflow uploads that one file for seven days and names the `demo-app-e2e` owner and recovery command.
- Added a deterministic contract owner that simulates both passing and failing Playwright commands and checks the workflow's artifact path, retention, owner, and recovery summary.

## Task Commits

1. **Task 1: Diagnose the seeded support failure and prove a repaired login; Task 2: Give the deterministic browser journey safe failure ownership** — `3ee08ff` (recovery, browser, and workflow implementation).
2. **Task 2: Assert safe trace status workflow contract** — `2135521` (pass/fail harness and workflow metadata assertions).

## Files Created/Modified

- `demo/ledger_loop/test/twin/incident_recovery_test.exs` — real failure, scoped trace diagnosis, audited repair, retry, and redaction assertions.
- `demo/ledger_loop/test/browser/trace_visual.spec.ts` — asserts the typed cause belongs to the seeded support trace row.
- `scripts/test_trace_visual_e2e.sh` — safely writes pass/fail status outside Playwright output and returns the original test exit status.
- `scripts/test_trace_visual_status_contract.sh` — verifies status output for exit codes 0 and 23 and checks workflow artifact ownership metadata.
- `.github/workflows/demo-app-e2e.yml` — mandatory contract check, status-only upload with seven-day retention, and owner/recovery job summary.

## Decisions Made

- Keep incident timeline, trust repair, and retry linked by connection ownership and explicit remediation causes; each login attempt retains its own hashable correlation.
- Restrict browser artifacts to four fixed fields and leave Playwright attachments disabled.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Add automated failure-path evidence for the browser status contract**

- **Found during:** Task 2 (browser artifact and workflow ownership)
- **Issue:** A successful browser run proved the pass status but did not exercise the failure trap, original exit-code preservation, or fixed workflow artifact metadata.
- **Fix:** Added a deterministic shell contract owner that runs the harness against a controlled `npx` stand-in for success and failure, then verifies workflow upload path, seven-day retention, owner, and recovery command. The plan's source scope was updated to include this owner before the metadata close-out.
- **Files modified:** `scripts/test_trace_visual_status_contract.sh`, `.github/workflows/demo-app-e2e.yml`, `.planning/phases/76-lifecycle-and-recovery-journeys/76-04-PLAN.md`
- **Verification:** `bash scripts/test_trace_visual_status_contract.sh` passed for both statuses; the same command is a mandatory step in `demo-app-e2e`.
- **Committed in:** `3ee08ff`, `2135521`.

---

**Total deviations:** 1 auto-fixed (1 Rule 2 missing critical proof)
**Impact on plan:** Failure-artifact behavior and retention/ownership settings now have deterministic coverage in the mandatory browser workflow.

## Issues Encountered

- Chromium could not register its macOS Mach port in the default sandbox. The required browser run passed when retried with elevated process access; the status contract was independently exercised for both pass and failure.
- `mix ci.demo_app` exited successfully with 106 tests and 0 failures. Hex printed existing dependency advisory notices during dependency resolution; those were not changed by this phase.

## User Setup Required

None — no external service configuration is required.

## Next Phase Readiness

Plan 76-04 is complete. Plan 76-05 can close the scheduled canary and mandatory evidence contract automation.

---
*Phase: 76-lifecycle-and-recovery-journeys*
*Completed: 2026-09-26*

## Self-Check: PASSED

- Summary artifact classifies both deliverables as fully automated.
- Implementation commits `3ee08ff` and `2135521` exist.
- Recovery, browser, and status-contract owners all passed in the current execution.
