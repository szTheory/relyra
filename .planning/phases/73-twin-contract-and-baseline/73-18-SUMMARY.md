---
phase: 73-twin-contract-and-baseline
plan: 18
subsystem: adoption-evidence
tags: [workflow-paths, lexical-provenance, git-index, symlink-defense, ci-evidence, tdd]
requires:
  - phase: 73-twin-contract-and-baseline
    provides: immutable owner snapshots and bounded mandatory evidence from Plan 73-17
provides:
  - Closed workflow path grammar limited to relative literals, single-segment stars, and whole double-star segments
  - Component-wise non-symlink owner provenance with regular-leaf and exact Git-index identity checks
  - Adversarial controls for unsupported filters, invalid siblings, path escapes, symlinks, and untracked owners
affects: [phase-73-reverification, 73-19-security-reconciliation, 74-clean-room-package-consumer]
plan_head_before: f2487cace86d53ffa27c8129acc0990d084737e1
actuals:
  tokens: 4361
  tasks: 2
  commits: 5
tech-stack:
  added: []
  patterns: [validate-before-match, lexical-path-identity, component-wise-lstat, exact-git-tracking]
key-files:
  created: [.planning/phases/73-twin-contract-and-baseline/73-18-SUMMARY.md]
  modified: [test/support/adoption_evidence.ex, test/adoption/evidence_contract_test.exs]
key-decisions:
  - "Reject every workflow path construct outside the repository's literal, single-star, and whole-double-star subset instead of approximating GitHub's broader matcher."
  - "Treat the declared lexical owner path as authoritative only after component-wise lstat and exact git ls-files identity succeed before test discovery."
patterns-established:
  - "Every ordered workflow filter is grammar-validated before any governed-input comparison or policy reduction."
  - "Repository evidence paths cross into discovery only after normalized-relative, non-symlink, regular-file, and Git-tracked provenance gates."
requirements-completed: [EVID-01, EVID-02]
coverage:
  - id: D1
    description: "Checked-in prompts/** remains valid while unsupported or malformed workflow syntax fails closed before governed-path matching."
    requirement: EVID-02
    verification:
      - kind: integration
        ref: "plan_73_18_task_1 (3 tests, 0 failures) and ci.evidence (99 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Every credited owner is the exact tracked, normalized, non-symlink lexical repository file named by the ledger."
    requirement: EVID-01
    verification:
      - kind: integration
        ref: "plan_73_18_task_2 (2 tests, 0 failures) and ci.evidence (99 tests, 0 failures)"
        status: pass
    human_judgment: false
duration: 12min
completed: 2026-09-11
status: complete
---

# Phase 73 Plan 18: Closed Evidence Boundaries Summary

**Mandatory evidence now accepts only the checked-in workflow-pattern subset and binds every owner to its exact tracked, regular, component-wise non-symlink lexical repository path before discovery.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-09-11T04:19:13Z
- **Completed:** 2026-09-11T04:30:50Z
- **Tasks:** 2
- **Files modified:** 2 test-support/test files plus this summary

## Accomplishments

- Replaced permissive workflow glob interpretation with a closed grammar covering relative literal segments, single stars within a segment, and whole `**` segments including optional-directory semantics.
- Validated every ordered `paths-ignore` entry before matching, so an adjacent valid `prompts/**` entry cannot mask unsupported syntax.
- Required normalized relative owner names, component-wise `File.lstat/1`, non-symlink traversal, regular leaves, and exact `git ls-files --error-unmatch` identity before registered-test discovery.
- Added isolated Git controls proving intermediate and leaf symlinks, inside and outside targets, lexical escapes, absolute paths, and untracked regular files cannot receive evidence credit.
- Preserved the checked-in `prompts/**` workflow contract and normal tracked owner controls through the mandatory 99-test evidence lane.

## Task Commits

Each TDD gate and implementation step was committed atomically:

1. **Task 1 RED: closed workflow grammar regressions** — `9c1f993` (test)
2. **Task 1 GREEN: closed workflow path parser** — `eb81ae5` (feat)
3. **Task 2 RED: lexical owner provenance regressions** — `1835f51` (test)
4. **Task 2 GREEN: tracked non-symlink owner gates** — `06c2c0e` (feat)
5. **Rule 1 verification reconciliation: legacy path assertion precedence** — `3340653` (test)

**Plan metadata:** pending final metadata commit

## Files Created/Modified

- `test/support/adoption_evidence.ex` — closed path grammar, ordered validation, normalized lexical path checks, component `lstat`, regular-leaf enforcement, and exact Git tracking.
- `test/adoption/evidence_contract_test.exs` — decisive workflow metacharacter and sibling controls plus isolated Git owner-provenance adversaries.
- `.planning/phases/73-twin-contract-and-baseline/73-18-SUMMARY.md` — execution evidence and Plan 73-19 handoff.

## Decisions Made

- The workflow validator rejects unsupported GitHub matcher constructs rather than implementing a second approximate matcher whose semantics could diverge.
- The literal ledger owner name remains the authority; resolved target contents or realpaths cannot substitute for its exact tracked lexical identity.
- Provenance completes before the Plan 73-17 registered-test snapshot seam, preventing rejected targets from compiling or registering tests.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Reconciled legacy assertions with grammar-first rejection**

- **Found during:** Overall `mix ci.evidence` verification
- **Issue:** Two existing assertions expected unsupported question-mark and character-class filters to reach governed-input or positive-path policy diagnostics, contradicting the new requirement that every item fail at the closed grammar boundary first.
- **Fix:** Retained governed-input checks for supported star forms and changed unsupported-form assertions to require event-specific unsupported-pattern diagnostics.
- **Files modified:** `test/adoption/evidence_contract_test.exs`
- **Commit:** `3340653`

**2. [Rule 1 - Bug] Corrected generated sequential progress state**

- **Found during:** Plan close-out
- **Issue:** The state updater advanced to Plan 73-19 but emitted `percent: 0`, retained stale Plan 73-17/18 activity and next-step prose, and left the roadmap's narrative counts at 17 complete with two pending.
- **Fix:** Reconciled progress to 18/19 (94%), recorded Plan 73-18 completion, pointed the operator next step at the sole remaining Plan 73-19, and aligned the roadmap narrative counts.
- **Files modified:** `.planning/STATE.md`, `.planning/ROADMAP.md`
- **Committed in:** final metadata commit

---

**Total deviations:** 2 auto-fixed bugs (one verification expectation and one generated-state reconciliation).
**Impact on plan:** Test expectation reconciliation only; implementation scope, public API, defaults, security posture, SemVer, workflows, and remote GitHub state remain unchanged.

## TDD Gate Compliance

- **Task 1 RED:** `9c1f993`; the focused selector intentionally reported 2 failures across 3 selected tests because unsupported path syntax and invalid siblings were still accepted. `tdd-red-evidence` accepted `/tmp/relyra-73-18-task1-red.json`.
- **Task 1 GREEN:** `eb81ae5`; the focused selector passed 3 tests, including the checked-in and pure-snapshot `prompts/**` controls.
- **Tracer feedback gate:** the Task 1 focused selector was rerun end-to-end and passed before expansion.
- **Task 2 RED:** `1835f51`; the focused selector intentionally reported 1 failure across 2 selected tests because an intermediate symlink reached discovery. `tdd-red-evidence` accepted `/tmp/relyra-73-18-task2-red.json`.
- **Task 2 GREEN:** `06c2c0e`; the focused selector passed 2 tests with tracked regular positive controls and all specified provenance rejections.
- **REFACTOR:** no separate refactor was needed; the closed helpers remained localized and all gates stayed green.

## Automated Evidence

- Task 1 focused selector: 3 tests, 0 failures.
- Task 2 focused selector: 2 tests, 0 failures.
- Mandatory `mix ci.evidence`: 99 tests, 0 failures.
- `mix format --check-formatted` and `git diff --check`: passed.

## Issues Encountered

- The first RED commit hook could not select Elixir because the user's untracked `.tool-versions` is outside this plan. The commit was retried with the plan's explicit ASDF versions; the user file remained untouched and unstaged.
- Mandatory-lane verification exposed two pre-existing assertions whose diagnostic precedence was superseded by the plan's grammar-first contract. They were reconciled in the separate Rule 1 commit above.

## Known Stubs

None.

## Threat Review

- T-73-70 is mitigated by validating a closed literal/star grammar before any workflow filter can participate in governed-input matching.
- T-73-71 is mitigated by component-wise `lstat` rejection of intermediate and leaf symlinks before discovery.
- T-73-72 is mitigated by normalized relative containment, a regular lexical leaf, and exact Git-index identity.
- No additional network endpoint, authentication path, file-access authority, schema boundary, runtime/public API, dependency, SAML trust seam, credential use, SemVer, workflow topology, or remote GitHub state was introduced.

## User Setup Required

None.

## Next Phase Readiness

- Plan 73-19 can reconcile the current review threats and seal Phase 73 security status against these closed mandatory-owner boundaries.
- Phase 74 clean-room package-consumer work remains dependent on Phase 73 verification closure.
- The pre-existing Phase 77 documentation-vocabulary failure remains out of scope and unchanged.

## Self-Check: PASSED

Both modified test files, this summary, and all five implementation/TDD commits were found. Task 1 and Task 2 focused selectors, the mandatory `mix ci.evidence` lane, formatting, and diff checks produced the results recorded above.

---
*Phase: 73-twin-contract-and-baseline*
*Completed: 2026-09-11*
