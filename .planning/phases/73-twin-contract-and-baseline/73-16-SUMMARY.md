---
phase: 73-twin-contract-and-baseline
plan: 16
subsystem: security-governance
tags: [asvs, evidence-contract, threat-register, governance, exunit]
requires:
  - phase: 73-twin-contract-and-baseline
    provides: closed workflow event grammar from Plan 73-14 and declarative authorization plus exact-HEAD provenance from Plan 73-15
provides:
  - Evidence-bound CR-06 through CR-08 threat dispositions
  - Verified ASVS L1 aggregate verdict with zero open high-threshold threats
  - Preserved below-threshold T-73-12 follow-up and immutable audit history
affects: [phase-73-reverification, 74-clean-room-package-consumer, 77-quality-cleanup]
actuals:
  tokens: 2705
  tasks: 2
  commits: 3
tech-stack:
  added: []
  patterns: [evidence-before-disposition, threshold-explicit security aggregation]
key-files:
  created: [.planning/phases/73-twin-contract-and-baseline/73-16-SUMMARY.md]
  modified: [.planning/phases/73-twin-contract-and-baseline/73-16-PLAN.md, .planning/phases/73-twin-contract-and-baseline/73-SECURITY.md]
key-decisions:
  - "Close blocking threat rows only after their exact focused selectors and the mandatory ci.evidence lane pass."
  - "Define threats_open: 0 as zero open threats at or above the high blocking threshold while retaining lower-severity follow-ups."
patterns-established:
  - "Security closeout cites exact deterministic selectors and the mandatory owner lane in each affected threat row."
  - "Aggregate security status states its severity threshold explicitly and never erases below-threshold findings."
requirements-completed: [EVID-02, GOV-01, GOV-02]
coverage:
  - id: D1
    description: "CR-06 is closed by the unique push/pull-request event grammar and its mandatory evidence owner."
    requirement: EVID-02
    verification:
      - kind: integration
        ref: "test/adoption/evidence_contract_test.exs#plan_73_14_task_1 and plan_73_14_task_2 (3 tests each, 0 failures)"
        status: pass
      - kind: integration
        ref: "mix ci.evidence (91 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D2
    description: "CR-07 and CR-08 are closed by declarative-only remote authorization and exact-HEAD descendant review."
    requirement: GOV-01
    verification:
      - kind: integration
        ref: "test/governance/milestone_scope_test.exs#plan_73_15_task_1 (2 tests) and plan_73_15_task_2 (3 tests), 0 failures"
        status: pass
      - kind: integration
        ref: "mix ci.evidence (91 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The Phase 73 security report records no open high-threshold threats while retaining T-73-12 as a medium non-blocking follow-up."
    requirement: GOV-02
    verification:
      - kind: other
        ref: "test \"$(sed -n 's/^threats_open: //p' .planning/phases/73-twin-contract-and-baseline/73-SECURITY.md)\" = \"0\" and closed-row/status assertions"
        status: pass
      - kind: integration
        ref: "mix ci.security (all mandatory fresh-process suites passed)"
        status: pass
    human_judgment: false
duration: 21min
completed: 2026-09-10
status: complete
---

# Phase 73 Plan 16: Evidence-Bound Security Reconciliation Summary

**CR-06 through CR-08 now close only on focused deterministic proof, yielding a verified ASVS L1 report with zero open high-threshold threats and T-73-12 still visible.**

## Performance

- **Duration:** 21 min
- **Started:** 2026-09-11T01:04:10Z
- **Completed:** 2026-09-11T01:25:39Z
- **Tasks:** 2
- **Files modified:** 2 plan/report files plus this summary

## Accomplishments

- Bound T-73-51 closure to exact push/pull-request event-grammar selectors and the mandatory 91-test evidence lane.
- Closed T-73-52 and T-73-53 from declarative-only `gh api --input` authorization and exact-HEAD descendant classification, and superseded T-73-50 after removal of the script-backed surface.
- Restored `status: verified` and `threats_open: 0` with threshold-explicit approval prose, checked sign-off, and a dated audit row while preserving T-73-12.

## Task Commits

Each task was committed atomically:

1. **Task 1: Trace closed event semantics into the CR-06 threat disposition** — `9c69f90` (docs)
2. **Task 2: Reconcile governance threats and seal the blocking ASVS verdict** — `1c09271` (docs)

**Plan metadata:** pending final metadata commit

## Files Created/Modified

- `.planning/phases/73-twin-contract-and-baseline/73-16-PLAN.md` — Split conjunctive selector declarations into independently executable non-zero owners.
- `.planning/phases/73-twin-contract-and-baseline/73-SECURITY.md` — Evidence-bound T-73-50 through T-73-53 dispositions, aggregate status, audit trail, sign-off, and approval.
- `.planning/phases/73-twin-contract-and-baseline/73-16-SUMMARY.md` — Execution evidence and handoff for final Phase 73 re-verification.

## Decisions Made

- Blocking threat disposition follows focused selector success and then the combined mandatory lane; prose and prior authorization never substitute for executable evidence.
- `threats_open` counts open threats at or above the configured high blocking threshold, so a zero count coexists truthfully with the retained medium T-73-12 follow-up.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Split conjunctive selector declarations into independent owners**

- **Found during:** Task 1 mandatory-lane precondition
- **Issue:** Plan 73-16 combined two `--only` filters in each focused command. The repository's fail-closed owner validator interpreted the conjunction as an empty effective selection and `mix ci.evidence` failed 1 of 91 tests before any threat status changed.
- **Fix:** Split the Plan 73-14 and Plan 73-15 focused declarations into separate direct-test commands, each with a positive effective ExUnit selection.
- **Files modified:** `.planning/phases/73-twin-contract-and-baseline/73-16-PLAN.md`
- **Verification:** Individual selectors passed with 3, 3, 2, and 3 tests; three subsequent `mix ci.evidence` runs passed 91 tests after the correction.
- **Committed in:** `9c69f90`

**2. [Rule 1 - Bug] Corrected contradictory generated completion state**

- **Found during:** Plan close-out
- **Issue:** The state updater recorded 16/16 completed plans but emitted `percent: 0`, retained the prior activity description, and left roadmap prose saying one gap-closure plan remained.
- **Fix:** Corrected the progress percentage, latest activity description, and roadmap completion prose to agree with the authoritative 16/16 summary count while retaining the active `executing` lifecycle required until phase verification.
- **Files modified:** `.planning/STATE.md`, `.planning/ROADMAP.md`
- **Committed in:** final metadata commit

---

**Total deviations:** 2 auto-fixed issues (one Rule 3 blocking issue and one Rule 1 generated-state bug).
**Impact on plan:** The correction makes the planned evidence executable without changing the required proof, security posture, public API, runtime, dependencies, or remote state.

## Automated Evidence

- Plan 73-14 Task 1 selector: 3 tests, 0 failures.
- Plan 73-14 Task 2 selector: 3 tests, 0 failures.
- Plan 73-15 Task 1 selector: 2 tests, 0 failures.
- Plan 73-15 Task 2 selector: 3 tests, 0 failures.
- Mandatory `mix ci.evidence`: 91 tests, 0 failures after the plan-local declaration correction; repeated before each disposition stage and at plan-level closeout.
- `mix ci.security`: all fresh-process security suites passed; the existing non-blocking `hex.audit` runtime-unavailable behavior remained unchanged.
- `mix format --check-formatted` and `git diff --check`: passed.
- Aggregate report assertion: `threats_open: 0`, T-73-51 through T-73-53 closed, and `status: verified` present.

## Issues Encountered

- The first pre-edit `mix ci.evidence` run failed only on Plan 73-16's conjunctive selector declaration. No threat was closed before the corrected deterministic evidence passed.
- The previously approved repository-wide archival vocabulary-policy failure was not rerun or modified; it remains owned by Phase 77 and is unrelated to this report-only plan.

## Known Stubs

None. The remaining open T-73-12 row is an intentional, owned below-threshold follow-up rather than an incomplete Plan 73-16 deliverable.

## Threat Review

- T-73-51 retains high/mitigate and closes on the Plan 73-14 event-grammar selectors plus `mix ci.evidence`.
- T-73-52 and T-73-53 retain high/mitigate and close on the Plan 73-15 declarative-operation and exact-HEAD provenance selectors plus `mix ci.evidence`.
- T-73-50 closes because the script-backed authorization surface was removed; T-73-12 remains visible at medium severity.
- No network endpoint, auth path, file-access pattern, schema, dependency, runtime/public API, SAML security posture, credential use, or remote GitHub state was introduced or changed.

## User Setup Required

None.

## Next Phase Readiness

- Phase 73 has deterministic evidence for all blocking security findings and is ready for independent re-verification.
- Phase 74 clean-room package-consumer planning can begin after the Phase 73 verifier seals the phase.
- The pre-existing archival vocabulary-policy finding remains routed to Phase 77.

## Self-Check: PASSED

The modified plan and security report, this summary, and both task commits were found. All plan-level focused selectors, the mandatory evidence lane, security lane, aggregate report assertions, formatting, and diff checks produced the results recorded above.

---
*Phase: 73-twin-contract-and-baseline*
*Completed: 2026-09-10*
