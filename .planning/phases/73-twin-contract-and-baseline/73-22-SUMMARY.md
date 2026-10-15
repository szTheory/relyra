---
phase: 73-twin-contract-and-baseline
plan: 22
subsystem: adoption-evidence
tags: [single-flight, persistent-term, global-lock, governed-inputs, tdd]
requires:
  - phase: 73-twin-contract-and-baseline
    provides: Plan 73-20's truthful open security verdict and Plan 73-21's closed active lifecycle identity
provides:
  - Caller-independent owner/source/cache-namespace single-flight discovery
  - Capture-time canonical governed-input inventory with exact pure snapshot binding
  - Barrier-controlled concurrency and adversarial inventory mutation regressions
affects: [73-23, phase-73-reverification, EVID-01, EVID-02]
plan_head_before: 1bb421787568787890046c9c672aa5836df0ad16
actuals:
  tokens: 3483
  tasks: 2
  commits: 5
tech-stack:
  added: []
  patterns: [content-addressed single-flight, inside-lock cache recheck, capture-authority equality, validate-before-reduce]
key-files:
  created: [.planning/phases/73-twin-contract-and-baseline/73-22-SUMMARY.md]
  modified: [test/support/adoption_evidence.ex, test/adoption/evidence_contract_test.exs]
key-decisions:
  - "Keep the cache ResourceId caller-independent and content-addressed while placing self() only in OTP's LockRequesterId slot."
  - "Capture one sorted governed-input authority and reject candidate omission, substitution, non-normalized paths, duplicates, or reordering before workflow reduction."
patterns-established:
  - "Test-controlled discovery uses a unique cache namespace without replacing the default fresh-process ExUnit registration authority."
  - "Pure snapshot validation checks both governed-input lists independently, then requires exact equality before any workflow coverage credit."
requirements-completed: [EVID-01, EVID-02]
coverage:
  - id: D1
    description: "Simultaneous cold misses for one owner/source/cache namespace execute discovery exactly once and return identical complete snapshots."
    requirement: EVID-01
    verification:
      - kind: integration
        ref: "test/adoption/evidence_contract_test.exs#simultaneous cold misses discover each owner once per cache identity"
        status: pass
    human_judgment: false
  - id: D2
    description: "Governed inputs remain exactly bound to the complete normalized capture inventory before workflow ownership is evaluated."
    requirement: EVID-02
    verification:
      - kind: integration
        ref: "test/adoption/evidence_contract_test.exs#governed inputs stay bound to the complete normalized capture inventory"
        status: pass
    human_judgment: false
duration: 14min
completed: 2026-09-11
status: complete
---

# Phase 73 Plan 22: Single-Flight and Governed Inventory Summary

**Adoption evidence now serializes identical cold owner discoveries through one caller-independent resource and rejects any snapshot whose governed inputs diverge from its complete normalized capture authority.**

## Performance

- **Duration:** 14 min
- **Started:** 2026-09-11T15:32:48Z
- **Completed:** 2026-09-11T15:46:38Z
- **Tasks:** 2
- **Files modified:** 2 implementation/test files plus this summary

## Accomplishments

- Added cache-namespace and discovery-function seams while preserving the legacy pure fixture override and default fresh-process registered ExUnit metadata authority.
- Keyed registration caching by namespace, absolute owner path, and exact SHA-256 source bytes, with a separate caller-independent lock resource and an inside-lock cache recheck.
- Captured every fixed and tracked Phase 73 plan/summary input once in unique lexical order and exposed the same list as the authoritative `governed_input_inventory`.
- Rejected governed-input omission, substitution, parent escape, absolute paths, duplicates, and reordering before workflow parsing can credit coverage.
- Added deterministic barrier-controlled and isolated-repository regressions for both repaired trust boundaries.

## Task Commits

1. **Task 1 RED: simultaneous cold-miss regression** — `0657f0e` (test)
2. **Task 1 GREEN: caller-independent single-flight discovery** — `7e5e33f` (feat)
3. **Task 2 RED: governed inventory mutation regressions** — `d365a3e` (test)
4. **Task 2 GREEN: complete canonical inventory binding** — `d007b70` (feat)
5. **REFACTOR: centralized discovery option validation** — `72760f6` (refactor)

**Plan metadata:** pending final metadata commit

## Files Created/Modified

- `test/support/adoption_evidence.ex` — namespaced content-addressed discovery cache, caller-independent lock resource, canonical inventory capture, and exact pure validation.
- `test/adoption/evidence_contract_test.exs` — synchronized concurrent-miss proof and isolated omission/substitution/path/order mutation corpus.
- `.planning/phases/73-twin-contract-and-baseline/73-22-SUMMARY.md` — execution evidence and Plan 73-23 handoff.

## Decisions Made

- The OTP lock identifier remains a two-tuple: the complete content-addressed resource occupies `ResourceId`, while the calling process appears only as `LockRequesterId`.
- Injected discovery is test control only. Production-like repository capture still defaults to compiling owners in a fresh BEAM and reading registered ExUnit metadata.
- Validation never sorts or repairs candidate snapshot lists. Capture canonicalizes once; validation proves the supplied order and exact equality.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected normalized-tag argument order during GREEN**

- **Found during:** Task 1 GREEN verification
- **Issue:** The first implementation piped discovered tags into an owner-first normalization helper in reverse argument order, causing the focused test to raise before reaching the single-flight assertion.
- **Fix:** Called the normalization helper with the owner identity first and the discovered tag list second.
- **Files modified:** `test/support/adoption_evidence.ex`
- **Verification:** Task 1 focused selector passed with 1 test and 0 failures; the tracer rerun and legacy fresh-process selector also passed.
- **Committed in:** `7e5e33f`

**2. [Rule 1 - Bug] Reconciled generated sequential tracking prose**

- **Found during:** Plan close-out
- **Issue:** The SDK advanced the numeric plan cursor and plan counts but retained stale prose saying two plans remained, Plan 73-22 was next, and only 21 plans were complete.
- **Fix:** Aligned STATE and ROADMAP narration with 22 completed plans and Plan 73-23 as the sole remaining gap-closure plan.
- **Files modified:** `.planning/STATE.md`, `.planning/ROADMAP.md`
- **Verification:** Tracking text now agrees on Plan 23 of 23, 22 completed plans, and Plan 73-23 as the next action.
- **Committed in:** final metadata commit

---

**Total deviations:** 2 auto-fixed bugs.
**Impact on plan:** The code correction was required for the planned normalization boundary and the tracking correction restores execution-state truth; scope, runtime SAML behavior, public API, defaults, dependencies, workflow, remote state, and SemVer remain unchanged.

## TDD Gate Compliance

- **Task 1 RED:** `0657f0e`; one selected test failed on the expected zero callback count, and `/tmp/relyra-73-22-task1-red.json` received `RED_EVIDENCE_OK`.
- **Task 1 GREEN:** `7e5e33f`; the focused selector passed 1 test with exactly one discovery per shared owner identity and separate discovery for a distinct namespace.
- **Tracer feedback gate:** the exact Task 1 verification reran after commit and passed; the existing default fresh-process selector also passed 3 tests.
- **Task 2 RED:** `d365a3e`; one selected test failed because the snapshot lacked `governed_input_inventory`, and `/tmp/relyra-73-22-task2-red.json` received `RED_EVIDENCE_OK`.
- **Task 2 GREEN:** `d007b70`; the focused mutation matrix passed 1 test with all required rejection classes.
- **REFACTOR:** `72760f6`; the complete adoption contract remained green with 48 tests and 0 failures before final scoped reruns.

## Automated Evidence

- Plan-level Task 1 selector: 1 test, 0 failures, non-zero selection confirmed.
- Plan-level Task 2 selector: 1 test, 0 failures, non-zero selection confirmed.
- Existing default fresh-process authority selector: 3 tests, 0 failures.
- Complete adoption evidence contract: 48 tests, 0 failures.
- `mix format --check-formatted` and `git diff --check`: passed.
- Extra `mix ci.evidence` observation: 103 tests selected, 1 governance failure from pre-existing Plan 73-20/21/22 plan-schema diagnostics; Plan 73-23 owns the mandatory-lane reconciliation and no owned source/test assertion failed.

## Issues Encountered

- The extra full mandatory evidence run remains red in `test/governance/milestone_scope_test.exs`, outside this plan's owned files. The failure reports active-plan scope/verification grammar in Plans 73-20 through 73-22 and is handed to Plan 73-23; both exact 73-22 verification commands pass.

## Known Stubs

None.

## Threat Review

- T-73-84 is mitigated by the caller-independent lock resource, inside-lock recheck, completed-result publication, and synchronized cold-miss regression.
- T-73-85 and T-73-86 are mitigated by separate canonical authority capture plus exact normalization, uniqueness, ordering, and equality validation before workflow reduction.
- No unplanned network endpoint, auth path, schema boundary, runtime file-access authority, dependency, public API, default, security posture, or remote state was introduced.

## User Setup Required

None.

## Next Phase Readiness

- Plan 73-23 can now rerun the repaired focused selectors, reconcile the unchanged mandatory evidence lane, and update the final Phase 73 security verdict.
- No blocker remains in the Plan 73-22 implementation or its exact verification contract.

## Self-Check: PASSED

- Both owned implementation/test files exist.
- All five TDD commits resolve from the persisted plan ledger base `1bb421787568787890046c9c672aa5836df0ad16`.
- Both plan-level focused selectors pass with non-zero test selection.
- No tracked file was deleted by this plan.

---
*Phase: 73-twin-contract-and-baseline*
*Completed: 2026-09-11*
