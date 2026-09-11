---
phase: 73-twin-contract-and-baseline
plan: 20
subsystem: security-governance
tags: [security-register, review-chronology, deterministic-evidence, asvs-l1]
requires:
  - phase: 73-twin-contract-and-baseline
    provides: Plan 73-19's evidence-bound security reconciliation and the later review/verifier findings that superseded its seal
provides:
  - Truthful open ASVS L1 register before implementation repair begins
  - Reopened Critical T-73-67 and registered medium T-73-76 with deterministic closure requirements
  - Immutable red-lane chronology with pending sign-off through Plans 73-21 to 73-23
affects: [73-21, 73-22, 73-23, phase-73-reverification]
plan_head_before: b3cbcaf48186239f494c61aab0c770916476760e
actuals:
  tokens: 1727
  tasks: 2
  commits: 2
tech-stack:
  added: []
  patterns: [open-before-repair security disposition, threshold-aware threat accounting, immutable correction chronology]
key-files:
  created: [.planning/phases/73-twin-contract-and-baseline/73-20-SUMMARY.md]
  modified: [.planning/phases/73-twin-contract-and-baseline/73-SECURITY.md]
key-decisions:
  - "A later Critical review and red mandatory lane invalidate the prior verified seal until current deterministic evidence closes the defects."
  - "Keep threats_open threshold-aware: T-73-67 is the sole blocking threat while T-73-12 and T-73-76 remain visible lower-severity follow-ups."
patterns-established:
  - "Security history is append-only: superseded closure remains in the audit trail while current aggregate state follows the latest evidence."
  - "Authorization prose cannot preserve or restore closure when current source and a mandatory evidence lane contradict it."
requirements-completed: [EVID-02, QUAL-01, PIPE-01, GOV-01, GOV-02]
coverage:
  - id: D1
    description: "T-73-67 is reopened at Critical/mitigate with the caller-specific lock defect and missing simultaneous-miss proof bound to the later review."
    requirement: EVID-02
    verification:
      - kind: other
        ref: "73-20 Task 1 structural acceptance command"
        status: pass
    human_judgment: false
  - id: D2
    description: "T-73-76 preserves the review Warning as an open medium/mitigate snapshot-inventory threat covering all five required mutation classes."
    requirement: QUAL-01
    verification:
      - kind: other
        ref: "73-20 Task 2 threat-row and arithmetic acceptance command"
        status: pass
    human_judgment: false
  - id: D3
    description: "The security audit records the checked-in ready_for_verification lane at 99 tests and 5 failures, with verified sign-off pending Plans 73-21 through 73-23."
    requirement: PIPE-01
    verification:
      - kind: other
        ref: "73-20 plan-level audit/sign-off verification commands"
        status: pass
    human_judgment: false
duration: 3min
completed: 2026-09-11
status: complete
---

# Phase 73 Plan 20: Open Security Verdict Correction Summary

**Phase 73 now records the later Critical single-flight defect, snapshot-integrity Warning, and red mandatory lane as open evidence before any implementation repair begins.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-09-11T15:05:52Z
- **Completed:** 2026-09-11T15:09:14Z
- **Tasks:** 2
- **Files modified:** 1 security report plus this summary

## Accomplishments

- Reopened T-73-67 at Critical/mitigate and replaced its superseded closure claim with the caller-specific `registered_test_tags!/2` lock defect and required simultaneous-miss regression.
- Registered T-73-76 at medium/mitigate with exact normalized `governed_inputs` inventory requirements and omission, substitution, parent-escape, absolute-path, and reorder controls.
- Appended the later review and exact `ready_for_verification` 99-test/5-failure result while setting aggregate status, threat arithmetic, sign-off, and approval to their truthful pending state.

## Task Commits

Each task was committed atomically:

1. **Task 1: Trace the later Critical review into an open security verdict** — `15d7d39` (docs)
2. **Task 2: Register snapshot integrity and the red final lifecycle lane** — `c394b10` (docs)

**Plan metadata:** pending final metadata commit

## Files Created/Modified

- `.planning/phases/73-twin-contract-and-baseline/73-SECURITY.md` — open threats, threshold-aware counts, append-only correction history, and pending sign-off.
- `.planning/phases/73-twin-contract-and-baseline/73-20-SUMMARY.md` — execution evidence and handoff to deterministic repairs.

## Decisions Made

- The 2026-09-11T05:04:38Z review supersedes Plan 73-19's earlier seal because current source still uses a caller-specific lock and the mandatory lane is red.
- `threats_open: 1` counts only open threats at or above the configured high threshold; T-73-12 and T-73-76 remain explicit open medium follow-ups.
- Plans 73-21, 73-22, and 73-23 are the only named closure path; no checkpoint, authorization prose, baseline reinterpretation, or historical green run substitutes for their deterministic evidence.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Reconciled generated next-plan tracking state**

- **Found during:** Plan close-out
- **Issue:** The SDK counted 20 completed summaries but advanced the stale `Plan: 1 of 23` cursor to `Plan: 2 of 23`; its roadmap narrative also retained `19 complete` after checking Plan 73-20.
- **Fix:** Corrected the current position to Plan 21, aligned the activity and operator handoff with the open security verdict, and reconciled the roadmap narrative to 20 complete.
- **Files modified:** `.planning/STATE.md`, `.planning/ROADMAP.md`
- **Verification:** Tracking assertions confirm Plan 21, 20/23 progress, Plans 73-21/22 readiness, and the Plan 73-20 completion marker.
- **Committed in:** final metadata commit

---

**Total deviations:** 1 auto-fixed bug.
**Impact on plan:** Planning-state accuracy only; security evidence, implementation, public API, defaults, baseline samples, workflows, remote state, and SemVer remain unchanged.

## Issues Encountered

None.

## Known Stubs

None.

## Threat Review

- Plan threats T-73-78 through T-73-80 are mitigated by the open aggregate, immutable red-lane audit row, and explicit T-73-76 registration.
- The plan adds no network endpoint, authentication path, schema boundary, file-access authority, runtime/public API, default, security control, dependency, baseline sample, workflow, remote GitHub state, or SemVer change.
- T-73-67 remains the one blocking Critical; T-73-12 and T-73-76 remain visible non-blocking medium follow-ups until deterministic closure evidence exists.

## User Setup Required

None.

## Next Phase Readiness

- Plan 73-21 may repair the checked-in `ready_for_verification` lifecycle identity now that the prior security seal is invalidated.
- Plan 73-22 may repair caller-independent single-flight discovery and exact normalized governed-input inventory independently after this serialized open-state commit.
- Plan 73-23 remains responsible for focused/repeated mandatory evidence and final security reconciliation; the current report intentionally remains `issues_found`.

## Self-Check: PASSED

Both plan files and both task commits were found. Coverage metadata classified all three deliverables as automated and passed; the final structural, arithmetic, chronology, sign-off, scope, stub, and diff checks passed.

---
*Phase: 73-twin-contract-and-baseline*
*Completed: 2026-09-11*
