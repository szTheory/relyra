---
phase: 73-twin-contract-and-baseline
plan: 32
subsystem: testing
tags: [exunit, git-provenance, ci-evidence, reconciliation]
requires:
  - phase: 73-twin-contract-and-baseline
    provides: Existing Phase 73 governance owner, mandatory evidence lane, and source-bound reconciliation contract
provides:
  - Bounded all-active-plan governance owner with 32-plan and 68-task proof inventory
  - Two positive Plan 73-32 selectors in the mandatory evidence lane
  - Fresh canonical proof and synchronized security and validation reports
affects: [phase-73-verification, governance-evidence]
actuals:
  tokens: 16949
  tasks: 2
  commits: 3
plan_head_before: 61208dc4e1a5312cd7e701d97685871847d9bac3
tech-stack:
  added: []
  patterns:
    - Root-scoped tracked-plan and HEAD snapshot reused only inside one governance invocation
key-files:
  created:
    - .planning/phases/73-twin-contract-and-baseline/73-32-SUMMARY.md
  modified:
    - test/governance/milestone_scope_test.exs
    - test/support/phase_73_reconciliation.ex
    - .planning/phases/73-twin-contract-and-baseline/73-RECONCILIATION-PROOF.json
    - .planning/phases/73-twin-contract-and-baseline/73-SECURITY.md
    - .planning/phases/73-twin-contract-and-baseline/73-VALIDATION.md
key-decisions:
  - Reused the existing active-plan governance test for the new task selector to avoid duplicating policy logic or repeating its Git walk in the mandatory lane.
  - Captured common HEAD and tracked-plan data once per repository-plan validation invocation while retaining each plan's boundary, ancestry, changed-file, SUMMARY, manifest, and descendant checks.
requirements-completed: [EVID-01, EVID-02, QUAL-01, PIPE-01, GOV-01, GOV-02]
coverage:
  - id: D1
    description: The active-plan governance owner and both new selectors prove the exact 32-plan, 68-task inventory and positive mandatory-lane selection.
    verification:
      - kind: integration
        ref: "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors"
        status: pass
      - kind: integration
        ref: "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D2
    description: The source-bound proof and both append-only reports agree and pass a fresh reconciliation replay with 17 focused selectors, three bounded evidence runs, and the unchanged 13-constituent security lane.
    verification:
      - kind: integration
        ref: "mix ci.phase73.reconciliation"
        status: pass
    human_judgment: false
duration: 54min
completed: 2026-09-24
status: complete
---

# Phase 73 Plan 32: Bounded Twin Evidence Reconciliation Summary

**The mandatory evidence lane now proves 32 tracked plans and 68 automated owners through 17 focused selectors, with three bounded evidence runs and a fresh 13-constituent security replay.**

## Performance

- **Duration:** 54 min
- **Started:** 2026-09-24T14:50:00Z
- **Completed:** 2026-09-24T15:44:29Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Reused the existing active-plan owner for `plan_73_32_task_1`; it still checks every active plan and now asserts the exact 68-owner inventory through `73-32-02`.
- Added a positive owner proving both new selectors are registered in the fresh-process `ci.evidence` alias and its unconditional `jobs.security` workflow step.
- Reduced the active-plan owner's full-lane runtime by reusing immutable, root-scoped tracked-plan and HEAD lookups within one invocation. The owner took 18.394 seconds under lane pressure; the standalone owner run took 28.9 seconds after the optimization.
- Captured proof `phase73-e76f4d404296add9` for 32 plans, 68 owners, 17 focused selectors, three equal successful 125-test evidence runs (50.986s, 52.467s, 58.389s), and all 13 pinned security constituents.
- Appended identical current proof blocks and current closure/owner records to both reports while retaining earlier report chronology, seven finding histories, 50/49/1 security totals, and visible medium T-73-12.

## Task Commits

1. **Task 1: Bound the active-plan owner and extend the evidence inventory** - `8062df9` (`test`)
2. **Task 1: Reuse shared governance provenance within an invocation** - `0e97b36` (`test`)
3. **Task 2: Capture current proof and refresh both reports** - `694c23f` (`docs`)

**Plan metadata:** committed separately after this summary was written.

## Files Created/Modified

- `test/governance/milestone_scope_test.exs` - Shared active-plan owner selector, exact current inventory checks, and mandatory-lane selector owner.
- `test/support/phase_73_reconciliation.ex` - 32-plan/68-owner/17-selector source-bound proof requirements.
- `.planning/phases/73-twin-contract-and-baseline/73-RECONCILIATION-PROOF.json` - Fresh passing evidence and security lane results.
- `.planning/phases/73-twin-contract-and-baseline/73-SECURITY.md` - Append-only current proof and seven current finding closures.
- `.planning/phases/73-twin-contract-and-baseline/73-VALIDATION.md` - Append-only current proof and exact 68-row automated owner map.

## Decisions Made

- Kept the governance module asynchronous because the active-plan owner stayed below its unchanged 60-second test bound under concurrent lane pressure.
- Limited snapshot reuse to one invocation and one repository root/HEAD. Per-plan approval, ancestry, changed-file, manifest, SUMMARY, and descendant checks remain active.

## Deviations from Plan

None - plan executed as written, including its conditional Git provenance snapshot after the first full-lane measurements exceeded the proof duration target.

## Issues Encountered

- The fresh worktree had no fetched Mix dependencies. `mix deps.get` fetched the locked dependencies; Hex cache persistence initially failed under the sandbox's default home, so the command was rerun with `HEX_HOME=/tmp/relyra-hex-cache`. No dependency files changed.
- Before the provenance snapshot, the full evidence lane measured 90.2 seconds and the focused active-plan owner measured 53.3 seconds. The final capture recorded three passing evidence runs below 60 seconds. A fresh independent reconciliation replay passed in 608.1 seconds.
- A separate standalone `mix ci.evidence` sample after the snapshot took 70.85 seconds (73.5 seconds in a slowest-test trace); later canonical capture and independent replay each recorded all three evidence runs below the strict 60-second proof limit.
- The commit hook could not infer the Elixir version from the worktree's Node-only `.tool-versions`; commits were retried with the project's pinned Elixir and Erlang environment, and the format hook passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 73-32 evidence and reports pass the independent current replay. The execute-phase orchestrator owns the independent phase verifier and shared lifecycle updates.

---
*Phase: 73-twin-contract-and-baseline*
*Completed: 2026-09-24*

## Self-Check: PASSED

All five plan artifacts and this summary exist. Task commits `8062df9`, `0e97b36`, `694c23f`, and summary commit `d7cabb0` are present in the worktree history.
