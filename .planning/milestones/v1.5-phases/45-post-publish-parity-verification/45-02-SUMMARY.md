---
phase: 45-post-publish-parity-verification
plan: 02
subsystem: testing
tags: [hex, release, parity, shell-script]

requires:
  - phase: 45-01
    provides: mix verify.release_parity task
provides:
  - verify-parity.sh milestone-close gate
  - PARITY-RESULT.md auditable PASS evidence for relyra 1.4.0
affects:
  - v1.5 milestone completion

tech-stack:
  added: []
  patterns:
    - Shell wrapper propagates mix task exit codes 0/2/1
    - PARITY-RESULT verdict derived from live run, never hand-written PASS

key-files:
  created:
    - .planning/phases/45-post-publish-parity-verification/verify-parity.sh
    - .planning/phases/45-post-publish-parity-verification/PARITY-RESULT.md
  modified: []

key-decisions:
  - "Verdict PASS requires parity exit 0, test_support count 0, hex.audit exit 0, ci.release exit 0"
  - "Hex API URL packages/relyra/releases/{version} (not hexpm path)"
  - "Script cleans up mix hex.build unpack artifacts after local checksum probe"

patterns-established:
  - "Milestone-close parity gate: verify-parity.sh → PARITY-RESULT.md → exit code"

requirements-completed: [PUB-04]

duration: 8min
completed: 2026-05-27
---

# Phase 45 Plan 02 Summary

**Live parity verification for relyra 1.4.0 vs git tag v1.4.0 passes with auditable PARITY-RESULT.md and executable milestone gate script.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-05-27T17:32:00Z
- **Completed:** 2026-05-27T17:40:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Created executable `verify-parity.sh` with git fetch, parity task, metadata collection, and derived verdict
- Ran live verification: path-set parity PASS, zero test_support paths, hex.audit and ci.release green
- Committed `PARITY-RESULT.md` with Hex API checksum and explicit **PASS**

## Task Commits

1. **Task 1: Create verify-parity.sh wrapper** - `227a3c2` (feat)
2. **Task 2: Run live verification and write PARITY-RESULT.md** - `82c664a` (docs)

## Files Created/Modified

- `verify-parity.sh` - Milestone-close runnable gate (ROADMAP SC#1)
- `PARITY-RESULT.md` - Auditable parity evidence (ROADMAP SC#2–4)

## Self-Check: PASSED

- ./verify-parity.sh: exit 0
- PARITY-RESULT.md contains **PASS**, test_support, Hex API sections
- mix test --warnings-as-errors: 718/0
