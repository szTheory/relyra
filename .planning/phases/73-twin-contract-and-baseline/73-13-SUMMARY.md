---
phase: 73-twin-contract-and-baseline
plan: 13
subsystem: testing
tags: [elixir, exunit, github-authorization, git-provenance, branch-protection]
requires:
  - phase: 73-twin-contract-and-baseline
    provides: closed remote-batch grammar, indexed script provenance, completed-plan Git history, and mandatory evidence ownership through Plans 73-01 to 73-12
provides:
  - Complete branch-protection state authorization with exact safe invariants
  - Non-executing indexed script identity bound to a tracked static result artifact
  - Git-authoritative ordered completed-plan commits with optional manifest equality audits
affects: [73-phase-verification, 74-clean-room-package-consumer, 79-github-hygiene]
actuals:
  tokens: 7968
  tasks: 3
  commits: 6
tech-stack:
  added: []
  patterns: [closed complete-state normalization, static mutation-result binding, Git-first provenance with document equality audits]
key-files:
  created: []
  modified: [test/governance/milestone_scope_test.exs]
key-decisions:
  - "Normalize and retain every accepted branch-protection control, treating non-declared controls as exact safe invariants shared by mutation and rollback authorization."
  - "Authorize script batches from indexed executable identity plus a separately tracked static JSON result, never by launching plan-selected code."
  - "Always derive completed-plan commits from ordered exact-scope Git history; manifests and SUMMARY hashes may only audit that derived set for exact equality."
patterns-established:
  - "Closed security payload grammars validate every accepted value rather than discarding permitted fields after key-shape checks."
  - "Planning documents cross-check trusted Git provenance but never select or reduce the governed commit frontier."
requirements-completed: [QUAL-01, PIPE-01, GOV-01, GOV-02]
coverage:
  - id: D1
    description: "Mutation and rollback payloads authorize only complete branch-protection state with required checks and all nine other accepted controls fixed to safe invariants."
    requirement: GOV-01
    verification:
      - kind: integration
        ref: "mix test test/governance/milestone_scope_test.exs --only plan_73_13_task_1 --warnings-as-errors (2 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Script-backed remote authorization launches no plan-selected code and binds indexed script identity to one tracked normalized static result."
    requirement: GOV-01
    verification:
      - kind: integration
        ref: "mix test test/governance/milestone_scope_test.exs --only plan_73_13_task_2 --warnings-as-errors (2 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Every exact-scope implementation commit before the unique completion boundary remains governed, with manifest and SUMMARY data restricted to exact equality audits."
    requirement: GOV-02
    verification:
      - kind: integration
        ref: "mix test test/governance/milestone_scope_test.exs --only plan_73_13_task_3 --warnings-as-errors (2 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D4
    description: "The dated baseline and CI snapshot retain their inventory-only semantics while the complete mandatory Phase 73 evidence lane passes unchanged."
    requirement: QUAL-01
    verification:
      - kind: integration
        ref: "mix ci.evidence (82 tests, 0 failures)"
        status: pass
    human_judgment: false
duration: 19min
completed: 2026-09-10
status: complete
---

# Phase 73 Plan 13: Complete Governance Authority Summary

**Complete protection-state checks, non-executing static script results, and Git-first commit provenance close the remaining governance authority defects**

## Performance

- **Duration:** 19 min
- **Started:** 2026-09-10T21:05:18Z
- **Completed:** 2026-09-10T21:24:22Z
- **Tasks:** 3
- **Files modified:** 1 implementation/test file

## Accomplishments

- Retained and authorized the complete accepted branch-protection state, with strict ordered checks plus exact safe values for administrator enforcement, reviews, restrictions, force pushes, deletions, branch creation, conversation resolution, locking, and fork syncing.
- Removed the plan-selected script process boundary and required one tracked regular non-symlink static result whose complete normalized state equals the declared desired state, while preserving executable index mode and working-tree object equality.
- Made the complete ordered exact-scope Git commit set authoritative before optional manifest and SUMMARY equality audits, including fail-closed controls for omission, addition, reordering, duplication, ambiguity, unreachable hashes, and boundary inclusion.
- Preserved the dated quality baseline and CI inventory as non-remediating Phase 73 evidence, with no product, workflow topology, remote GitHub, or published security-surface change.

## Task Commits

1. **Task 1 RED: Expose incomplete branch-protection authorization** — `8b879f8` (test)
2. **Task 1 GREEN: Authorize complete protection state** — `07c88c2` (fix)
3. **Task 2 RED: Expose ambient plan-selected script execution** — `2535ef9` (test)
4. **Task 2 GREEN: Bind indexed scripts to static results without execution** — `b63485d` (fix)
5. **Task 3 RED: Expose manifest-selected completed-plan provenance** — `aee77e9` (test)
6. **Task 3 GREEN: Make Git's ordered exact-scope set authoritative** — `48d99a1` (fix)

## Files Created/Modified

- `test/governance/milestone_scope_test.exs` — Complete protection-state normalization, static script-result provenance, Git-first manifest auditing, and focused adversarial fixtures.

## Decisions Made

- The branch-protection normalizer returns one complete internal state; invariant failures name the exact field, and authorization compares that state to a complete expected state derived from declared strictness and checks.
- A script mutation's `mutation_result_source` is required only for the script grammar and forbidden for direct API payload operations, preserving two closed and distinct operation forms.
- Manifest hashes are resolved independently and compared in order to the Git-derived set; even an invalid or incomplete manifest cannot change the set returned for governance inspection.

## Deviations from Plan

None - plan executed exactly as written.

## Automated Evidence

- Task 1 selector — 2 tests, 0 failures.
- Task 2 selector — 2 tests, 0 failures.
- Task 3 selector — 2 tests, 0 failures.
- Complete governance contract — 50 tests, 0 failures.
- Mandatory `mix ci.evidence` lane — 82 tests, 0 failures.
- `mix format --check-formatted` and `git diff --check` — passed.

## Issues Encountered

- The Task 1 test helper initially accumulated prior one-field mutations across loop iterations; resetting each adversary from the clean payload isolated every field as intended before the GREEN commit.
- The repository's user-owned `.tool-versions` remains intentionally untouched, so every test and commit hook used explicit Elixir 1.19.5/OTP 28.4.1 versions.

## Known Stubs

None. Placeholder strings, empty values, and malformed objects in the modified file are intentional fail-closed adversarial fixtures. All remaining `System.cmd/3` calls execute fixed Git argv for isolated provenance checks; none launches plan-selected mutation code.

## Threat Review

T-73-55 through T-73-59 are mitigated by complete field retention, exact invariant validation, removal of ambient script execution, static result provenance, Git-derived commit authority, and independent document equality audits. No security-relevant surface outside the plan's threat model was introduced, and no remote access or mutation occurred.

## TDD Gate Compliance

- Task 1 RED `8b879f8` preceded GREEN `07c88c2`.
- Task 2 RED `2535ef9` preceded GREEN `b63485d`.
- Task 3 RED `aee77e9` preceded GREEN `48d99a1`.

## User Setup Required

None.

## Next Phase Readiness

- Phase 73 may be re-verified with all five code-review authority defects closed by Plans 73-12 and 73-13.
- Phase 74 clean-room package-consumer planning may begin after the phase verifier confirms the complete Phase 73 contract.

## Self-Check: PASSED

The modified governance contract, this summary, and all six RED/GREEN task commits were found. Fresh focused selectors, the complete governance contract, mandatory evidence lane, formatting, and diff verification produced the results recorded above.

---
*Phase: 73-twin-contract-and-baseline*
*Completed: 2026-09-10*
