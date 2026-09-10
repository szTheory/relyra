---
phase: 73-twin-contract-and-baseline
plan: 07
subsystem: governance
tags: [elixir, exunit, task-vocabulary, approval-checkpoints, completed-plan-diffs]
requires:
  - phase: 73-twin-contract-and-baseline
    provides: fail-closed task risk, exclusion, and provenance foundations from Plan 73-05
provides:
  - Closed exact task-type vocabulary with authorization limited to decision checkpoints
  - Exact positive approval decisions and closed plan-scope values
  - Completed-plan validation with deterministic commit or before/after diff provenance
  - Changed-surface risk routed through the same plan-local ordered checkpoint contract
affects: [73-08, 74-clean-room-package-consumer, 75-saas-twin-domain-realism, 76-lifecycle-and-recovery-journeys, 77-craftsmanship, 78-ci-quality, 79-release-readiness]
actuals:
  tokens: 4988
  tasks: 2
  commits: 5
tech-stack:
  added: []
  patterns: [closed task classifier, exact positive authorization grammar, additive diff-derived risk, schema-aware historical validation]
key-files:
  created: []
  modified: [test/governance/milestone_scope_test.exs]
key-decisions:
  - "Validate task type before every authorization, risk, verification, and feature-neutrality branch; only exact decision checkpoints are authorization-only."
  - "Treat summary-owned task commits or explicit deterministic before/after inputs as additive changed-surface evidence, never as a PLAN exemption."
  - "Apply the current exact schema to plans carrying the exclusion contract while retaining deterministic legacy-schema checks for Plans 73-01 through 73-03."
patterns-established:
  - "Authorization grammar: one exact checkpoint:decision task with one exact approval_class value from the closed class set."
  - "Repository governance: structural PLAN validation always runs; completed-plan provenance can only add risky classes."
requirements-completed: [GOV-01, GOV-02]
coverage:
  - id: D1
    description: "Unknown task types, negated decisions, and contradictory scope values fail before authorization or implementation exemptions."
    requirement: GOV-01
    verification:
      - kind: integration
        ref: "mix test test/governance/milestone_scope_test.exs --only plan_73_07_task_1 --warnings-as-errors (3 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Completed plans remain governed and diff-derived risky surfaces require the same prior plan-local checkpoint as declared task intent."
    requirement: GOV-01
    verification:
      - kind: integration
        ref: "mix test test/governance/milestone_scope_test.exs --only plan_73_07_task_2 --warnings-as-errors (3 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Every validated implementation-bearing task type remains subject to demand-gated capability exclusion."
    requirement: GOV-02
    verification:
      - kind: integration
        ref: "test/governance/milestone_scope_test.exs#task-region demand-gated smuggling fails regardless of nearby prose"
        status: pass
    human_judgment: false
duration: 11min
completed: 2026-09-09
status: complete
---

# Phase 73 Plan 07: Closed Governance Lifecycle Summary

**Closed task, decision, and scope vocabularies now govern both active intent and completed-plan diffs through one ordered plan-local approval path**

## Performance

- **Duration:** 11 min
- **Started:** 2026-09-10T01:11:41Z
- **Completed:** 2026-09-10T01:22:33Z
- **Tasks:** 2
- **Files modified:** 1 implementation file

## Accomplishments

- Replaced checkpoint-prefix exemptions with a closed five-value task classifier and made exact `checkpoint:decision` the only authorization-only task type.
- Replaced substring authorization and negative-scope parsing with one exact positive decision and exact `unchanged`/`mutation` scope values.
- Added repository-level validation that never drops a PLAN because its SUMMARY exists, resolves summary task commits or supplied before/after evidence, and unions changed-surface classes into checkpoint ordering.
- Applied feature-neutral scanning to every validated implementation-bearing task while rejecting unknown types before any exemption branch.

## Task Commits

1. **Task 1 RED: Assign closed governance regressions** — `3304c24` (test)
2. **Task 1 GREEN: Close task authorization vocabulary** — `bf2ec09` (fix)
3. **Task 2 RED: Define completed-plan governance** — `81db38e` (test)
4. **Task 2 GREEN: Enforce completed-plan diffs** — `e6d733b` (fix)
5. **Task 2 correctness follow-up: Validate completed plan history** — `4247fe2` (fix)

## Files Created/Modified

- `test/governance/milestone_scope_test.exs` — Closed task/scope/decision classifiers, universal implementation-task scanning, completed-summary provenance resolution, and diff-to-checkpoint aggregation.

## Decisions Made

- Unknown task types produce an ordered type violation and are excluded from all later classifier branches, so checkpoint-shaped spelling grants no authority.
- A completed plan uses task-commit diffs when available or explicit deterministic before/after inputs in isolated tests; absent or malformed provenance is a stable violation in addition to structural PLAN findings.
- Plans 73-01 through 73-03 retain their original schema but still receive type, deterministic-verification, manual-acceptance, and checkpoint-order checks; plans carrying the exact exclusion region receive the full current contract.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserved validation of pre-contract completed plans**

- **Found during:** Task 2 repository-wide verification
- **Issue:** Routing every Phase 73 PLAN through the new exact schema correctly removed the SUMMARY exemption but falsely rejected Plans 73-01 through 73-03, which predate mandatory risk metadata and the exact exclusion region.
- **Fix:** Added schema-aware legacy validation that continues checking closed task types, executable evidence, manual acceptance, and checkpoint ordering without pretending historical files used the later schema.
- **Files modified:** `test/governance/milestone_scope_test.exs`
- **Verification:** Both Plan 73-07 selectors pass; repository validation reports only Plan 73-08's intentionally unassigned RED selector before its execution.
- **Committed in:** `4247fe2`

**2. [Rule 1 - Bug] Corrected contradictory SDK closeout state**

- **Found during:** Sequential state update
- **Issue:** `state.advance-plan` recorded 7/8 plans, but `state.update-progress` could not parse the YAML progress block, reset progress to 0 percent, and retained Plan 06 activity prose.
- **Fix:** Restored disk-backed 88 percent progress, recorded Plan 07 as the latest activity, and narrowed the operator next step to Plan 73-08.
- **Files modified:** `.planning/STATE.md`
- **Verification:** STATE reports 7 completed plans, 88 percent, Plan 07 activity, and the Plan 73-08 next step.
- **Committed in:** Final metadata commit

---

**Total deviations:** 2 auto-fixed (Rule 1).
**Impact on plan:** Completed plans are no longer exempt, historical plan syntax remains deterministically governed without modifying prior immutable PLAN artifacts, and sequential planning state truthfully reflects disk state.

## Automated Evidence

- `mix test test/governance/milestone_scope_test.exs --only plan_73_07_task_1 --warnings-as-errors` — 3 tests, 0 failures.
- `mix test test/governance/milestone_scope_test.exs --only plan_73_07_task_2 --warnings-as-errors` — 3 tests, 0 failures.
- `mix format --check-formatted` — passed.
- `git diff --check` — passed.
- Full-file execution remains intentionally RED only for Plan 73-08's appended-command/provenance cases and its not-yet-assigned selector; Plan 73-08 owns the combined evidence gate.

## Issues Encountered

- The repository contract initially exposed historical schema drift once the completed-plan bypass was removed. The Rule 1 fix keeps every plan under validation while applying the exact current schema only where its structural marker exists.
- The user-owned `.tool-versions`, `.planning/state.json`, `.planning/milestone.lock`, and `.gsd/` state were preserved; verification and hooks used explicit Elixir 1.19.5/OTP 28.4.1 values.

## Known Stubs

None. Empty, placeholder, and omitted-command strings in the modified test file are deliberate adversarial fixture values and do not represent incomplete runtime or UI behavior.

## Threat Review

T-73-28 through T-73-31 are covered by isolated tests for unknown task types, exact positive authorization, exact scope parsing, completed-plan provenance, changed-surface checkpoint routing, and universal demand-gated scanning. No runtime endpoint, authentication path, file-access trust boundary, schema, dependency, public API, default, security posture, SemVer-major release, or remote GitHub state changed.

## User Setup Required

None. No remote operation or external service was used.

## Next Phase Readiness

- Plan 73-08 can assign and close the two remaining remote-command and provenance RED cases, then run the combined mandatory evidence gate.
- Downstream plans inherit one plan-local approval path for active tasks and deterministic completed-plan diffs.

## Self-Check: PASSED

The summary, modified governance contract, and all five RED/GREEN/correctness commits exist. Fresh focused selectors, formatting, diff hygiene, owned-tag, and bypass scans produced the results recorded above.

---
*Phase: 73-twin-contract-and-baseline*
*Completed: 2026-09-09*
