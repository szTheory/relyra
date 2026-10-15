---
phase: 73-twin-contract-and-baseline
plan: 21
subsystem: governance-testing
tags: [lifecycle-state, fail-closed, exunit, tdd, deterministic-evidence]
requires:
  - phase: 73-twin-contract-and-baseline
    provides: Plan 73-20's truthful open security verdict and recorded ready_for_verification lane failure
provides:
  - Exact three-value active STATE lifecycle enum including ready_for_verification
  - Real-repository and isolated full-identity lifecycle regressions
  - Explicit STATE path, field-cardinality, and invalid-value diagnostics
affects: [73-22, 73-23, phase-73-reverification, ci.evidence]
plan_head_before: c7b0a389f76028d35288deb742c259a15385d240
actuals:
  tokens: 1498
  tasks: 2
  commits: 4
tech-stack:
  added: []
  patterns: [closed lifecycle enum, one-property isolated mutations, explicit structural diagnostics]
key-files:
  created: [.planning/phases/73-twin-contract-and-baseline/73-21-SUMMARY.md]
  modified: [test/governance/milestone_scope_test.exs]
key-decisions:
  - "Treat executing, in_progress, and ready_for_verification as the only active governance lifecycle states."
  - "Preserve the serialized live STATE while proving ready_for_verification through a checked-in identity fixture that changes only the lifecycle field."
  - "Restrict frontmatter whitespace after field colons to horizontal whitespace so empty status values cannot consume the next line."
patterns-established:
  - "Lifecycle mutations copy the checked-in governance identity into unique temporary repositories and change one STATE property at a time."
  - "Fail-closed diagnostics retain the singular-and-active contract while naming the exact STATE path and observed field values."
requirements-completed: [EVID-02, QUAL-01, PIPE-01, GOV-01, GOV-02]
coverage:
  - id: D1
    description: "ready_for_verification reaches the complete v1.11 Phase 73 governance identity and canonical plan frontier without invalidating the live serialized state."
    requirement: EVID-02
    verification:
      - kind: integration
        ref: "test/governance/milestone_scope_test.exs#ready_for_verification reaches the complete active governance identity"
        status: pass
    human_judgment: false
  - id: D2
    description: "Only executing, in_progress, and ready_for_verification gain lifecycle authority; terminal, inactive, empty, duplicate, unknown, quoted, and malformed controls fail closed."
    requirement: GOV-01
    verification:
      - kind: unit
        ref: "test/governance/milestone_scope_test.exs#lifecycle authority accepts only the three exact active STATE values"
        status: pass
    human_judgment: false
  - id: D3
    description: "Invalid lifecycle diagnostics identify .planning/STATE.md and expose exact singular-field observations without changing downstream governance validation."
    requirement: GOV-02
    verification:
      - kind: unit
        ref: "mix test test/governance/milestone_scope_test.exs --only plan_73_21_task_2 --warnings-as-errors"
        status: pass
    human_judgment: false
duration: 10min
completed: 2026-09-11
status: complete
---

# Phase 73 Plan 21: Closed Active Lifecycle Identity Summary

**Phase 73 governance now accepts the legitimate ready-for-verification lifecycle through an exact three-state enum while adversarial controls keep malformed and terminal states fail closed.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-09-11T15:16:53Z
- **Completed:** 2026-09-11T15:27:46Z
- **Tasks:** 2
- **Files modified:** 1 test contract plus this summary

## Accomplishments

- Added an independently selectable tracer that proves a ready-for-verification copy of the checked-in v1.11 identity reaches Phase 73's exact six-requirement set, canonical directory, and non-empty plan frontier.
- Expanded the private lifecycle allowlist to exactly `executing`, `in_progress`, and `ready_for_verification`, carrying the validated status through the returned identity.
- Added isolated one-property controls for completed, blocked, paused, not-started, unknown, empty, whitespace-only, missing, duplicated, quoted-lookalike, and malformed statuses with explicit path/value diagnostics.

## Task Commits

Each TDD gate was committed atomically:

1. **Task 1 RED: Trace checked-in ready state through the active governance identity** — `bf082af` (test)
2. **Task 1 GREEN: Accept ready state in the governance identity** — `f42f376` (feat)
3. **Task 2 RED: Add the closed lifecycle mutation corpus** — `1c1ba85` (test)
4. **Task 2 GREEN: Keep lifecycle authority fail closed** — `03fcfed` (feat)

**Plan metadata:** pending final metadata commit

## Files Created/Modified

- `test/governance/milestone_scope_test.exs` — exact active-state allowlist, returned status, focused tracer, adversarial lifecycle mutations, and explicit diagnostics.
- `.planning/phases/73-twin-contract-and-baseline/73-21-SUMMARY.md` — execution evidence and Plan 73-23 handoff.

## Decisions Made

- Lifecycle authority remains a closed exact enum; no arbitrary non-empty status is accepted.
- The serialized executor's live `executing` state remains untouched. The ready-state tracer uses the existing checked-in governance fixture and changes only its STATE status before traversing the full identity chain.
- YAML-like frontmatter parsing accepts spaces and tabs after the colon but never newline whitespace, preventing an empty status from borrowing `stopped_at` as its value.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Kept the real-repository tracer compatible with serialized execution state**

- **Found during:** Task 1
- **Issue:** The plan described `File.cwd!/0` as still carrying `ready_for_verification`, but the serialized GSD close-out for Plan 73-20 had legitimately restored checked-in STATE to `executing`. Rewriting STATE would violate the task's planning-file prohibition.
- **Fix:** Validated the live repository end to end in its exact current active state, then copied the checked-in governance identity into the established isolated fixture and changed only `status` to prove `ready_for_verification` through the same full path.
- **Files modified:** `test/governance/milestone_scope_test.exs`
- **Verification:** `plan_73_21_task_1` selected 1 test and passed with 0 failures.
- **Committed in:** `bf082af`, `f42f376`

**2. [Rule 1 - Bug] Prevented empty status from consuming the next frontmatter line**

- **Found during:** Task 2 GREEN verification
- **Issue:** `\s*` after the STATE field colon matched newlines, so an empty `status:` was rejected but reported `stopped_at` as the observed status value.
- **Fix:** Restricted post-colon whitespace to spaces/tabs and retained explicit empty-string versus missing-field diagnostics.
- **Files modified:** `test/governance/milestone_scope_test.exs`
- **Verification:** `plan_73_21_task_2` selected 1 table-driven test and passed all active and adversarial cases with 0 failures.
- **Committed in:** `03fcfed`

---

**Total deviations:** 2 auto-fixed bugs.
**Impact on plan:** Both fixes preserve the exact intended lifecycle authority. No planning file, baseline row/sample, approval grammar, workflow, product/runtime code, public API/default, security seam, remote state, or SemVer posture changed.

## Issues Encountered

- A non-required full-file regression run reached known out-of-scope active-plan document-policy failures in Plans 73-20 and 73-21. The plan's two exact focused selectors remain green and non-zero; Plan 73-23 owns repeated mandatory-lane closure after both Wave 17 repairs. No unrelated plan document was modified.
- One verification shell used zsh's reserved lowercase `path` variable and lost `PATH` inside that process. The command made no file or commit changes and passed when rerun with a task-specific variable name.

## TDD Gate Compliance

- Task 1 RED failed on the named ready-state assertion and was accepted as `RED_EVIDENCE_OK`; Task 1 GREEN then passed the exact non-zero selector.
- Task 2 RED failed on the named explicit-diagnostic assertion and was accepted as `RED_EVIDENCE_OK`; Task 2 GREEN then passed the exact non-zero selector.
- Git history contains both `test(73-21)` commits before their corresponding `feat(73-21)` commits. No refactor commit was needed.

## Known Stubs

None. Empty values in the new table are intentional adversarial STATE fixtures, not runtime or UI stubs.

## Threat Review

- T-73-81 is mitigated by exact `ready_for_verification` membership and the focused full-identity tracer.
- T-73-82 is mitigated by the closed three-value enum and terminal/inactive/empty/duplicate/unknown/malformed mutation corpus.
- T-73-83 is mitigated by retained singular fields and unchanged downstream project, roadmap, requirements, directory, and frontier agreement.
- No new network endpoint, authentication path, file-access authority, schema boundary, runtime/public API, default, dependency, workflow, remote state, or SemVer surface was introduced.

## User Setup Required

None.

## Next Phase Readiness

- Plan 73-22 can independently repair caller-independent single-flight discovery and governed-input inventory.
- Plan 73-23 can rerun both focused Plan 73-21 selectors and the repeated mandatory evidence/security lanes before reconciling the security verdict.

## Self-Check: PASSED

The modified governance contract, summary, and all four TDD commits exist. Both exact focused selectors passed with one selected test each, coverage metadata classified all three deliverables as automated and passed, the measured commit ledger reports four commits, and diff/format checks passed.

---
*Phase: 73-twin-contract-and-baseline*
*Completed: 2026-09-11*
