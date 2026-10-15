---
phase: 73-twin-contract-and-baseline
plan: 14
subsystem: testing
tags: [elixir, exunit, github-actions, evidence-contract, workflow-grammar]
requires:
  - phase: 73-twin-contract-and-baseline
    provides: literal evidence ledger, executable owner chain, and governed-path validation from Plans 73-01 through 73-12
provides:
  - Occurrence-preserving closed grammar for mandatory push and pull_request events
  - Exact positive-main push coverage without negation, additional branches, or branches-ignore
  - Unrestricted pull-request activity coverage with duplicate and unsupported key rejection
affects: [73-16-security-reconciliation, 74-clean-room-package-consumer, 78-ci-quality]
actuals:
  tokens: 3008
  tasks: 2
  commits: 4
tech-stack:
  added: []
  patterns: [occurrence-preserving YAML subset, closed event schemas, validation-before-reduction]
key-files:
  created: []
  modified: [test/support/adoption_evidence.ex, test/adoption/evidence_contract_test.exs]
key-decisions:
  - "Validate each required workflow event and every direct child-key occurrence before reducing branch or path semantics."
  - "Require push branches to equal the single literal main selector and forbid pull-request activity filters entirely."
patterns-established:
  - "Mandatory event cardinality and closed-key validation precede governed-path and evidence-owner evaluation."
  - "Bare and quoted YAML direct keys normalize to one semantic key for duplicate and unsupported-key checks."
requirements-completed: [EVID-01, EVID-02]
coverage:
  - id: D1
    description: "Push accepts exactly one positive main branch and rejects ordered negation, additions, branches-ignore, duplicates, and unsupported keys."
    requirement: EVID-02
    verification:
      - kind: integration
        ref: "mix test test/adoption/evidence_contract_test.exs --only plan_73_14_task_1 --warnings-as-errors (3 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Pull-request activity cannot be narrowed and every required event and direct child key is unique and closed."
    requirement: EVID-02
    verification:
      - kind: integration
        ref: "mix test test/adoption/evidence_contract_test.exs --only plan_73_14_task_2 --warnings-as-errors (3 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The unchanged six-persona ledger and real workflow-to-alias-to-owner chain pass through the hardened event contract."
    requirement: EVID-01
    verification:
      - kind: ci
        ref: "mix ci.evidence (88 tests, 0 failures)"
        status: pass
    human_judgment: false
duration: 10min
completed: 2026-09-10
status: complete
---

# Phase 73 Plan 14: Closed Mandatory Workflow Event Grammar Summary

**Occurrence-preserving push and pull-request validation now rejects every known CR-06 event-suppression path before mandatory evidence ownership can be credited.**

## Performance

- **Duration:** 10 min
- **Started:** 2026-09-10T23:44:43Z
- **Completed:** 2026-09-10T23:54:49Z
- **Tasks:** 2
- **Files modified:** 2 implementation/test files

## Accomplishments

- Replaced first-match event lookup with a shared `required_event_contract!/3` seam that preserves required-event and direct-child-key occurrences until cardinality and schema validation complete.
- Required push to declare one non-empty `branches` list equal to `[main]`, rejecting both negation orders, extra branches, branches-ignore, repeated keys, duplicate events, and unknown keys.
- Forbade pull-request `types` and every other unsupported activity/branch key while preserving both the checked-in prompts-only ignore and an unfiltered pull-request event as positive controls.
- Kept Plan 73-12 path semantics and the complete alias, owner-selection, job/step fallibility, and six-persona ledger chain intact.

## Task Commits

1. **Task 1 RED: Reproduce push suppression paths** — `e783724` (test)
2. **Task 1 GREEN: Close push event grammar** — `0e45ce1` (fix)
3. **Task 2 RED: Reproduce pull-request grammar gaps** — `1ad4ea1` (test)
4. **Task 2 GREEN: Close pull-request key grammar** — `c93723d` (fix)

## Files Created/Modified

- `test/support/adoption_evidence.ex` — Required-event cardinality, mapping shape, normalized direct-key occurrence validation, exact push branch contract, and existing governed-path handoff.
- `test/adoption/evidence_contract_test.exs` — Standalone Plan 73-14 selectors covering branch ordering, activity restrictions, malformed values, duplicates, unsupported keys, and real workflow controls.

## Decisions Made

- Event cardinality and direct-key closure run before path semantics so a valid sibling event or first duplicate cannot mask malformed grammar.
- Push branch semantics use exact list equality rather than ordered-pattern simulation because the mandatory owner permits only the positive literal `main`.
- Pull-request activity types are categorically forbidden so GitHub's complete default activity set remains covered without maintaining a partial allowlist.
- Quoted and bare direct YAML keys normalize before duplicate and closed-schema validation, and quoted allowed path keys retain the same downstream semantics.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected stale state position after SDK advancement**

- **Found during:** Plan closeout
- **Issue:** `state.advance-plan` incremented the stale phase-start position from Plan 1 to Plan 2 even though 14 summaries now exist.
- **Fix:** Retained the SDK-derived completed-plan count and corrected the current position and operator next step to the next incomplete Plan 15.
- **Files modified:** `.planning/STATE.md`, `.planning/ROADMAP.md`
- **Committed in:** Final metadata commit

---

**Total deviations:** 1 auto-fixed Rule 1 metadata bug.
**Impact on plan:** The correction keeps execution navigation consistent with the committed summary set and does not change implementation scope.

## Automated Evidence

- Task 1 RED selected 3 tests and failed on ordered-negation and duplicate/unsupported push fixtures before implementation.
- Task 1 GREEN and tracer feedback gate each passed 3 tests with 0 failures.
- Task 2 RED selected 3 tests and failed because a valid quoted unsupported key lacked exact key diagnostics.
- Task 2 GREEN passed 3 tests with 0 failures; the Task 1 selector remained 3/3 green.
- Complete adoption evidence contract passed 38 tests with 0 failures.
- Mandatory `mix ci.evidence` passed 88 tests with 0 failures.
- `mix format --check-formatted` and `git diff --check` passed.

## Issues Encountered

None.

## Known Stubs

None. Empty values and collections in the modified files are validation guards or intentional adversarial fixtures, not incomplete behavior.

## Threat Review

T-73-60 through T-73-62 are mitigated by occurrence-preserving event parsing, exact positive-main enforcement, unrestricted pull-request activity coverage, and duplicate/unsupported-key rejection before path and owner evaluation. No runtime endpoint, auth path, file-access boundary, schema, dependency, workflow topology, public API, SAML security posture, package surface, or remote GitHub state changed.

## TDD Gate Compliance

- Task 1 RED `e783724` preceded GREEN `0e45ce1`; the focused selector failed for the intended suppressible and duplicate push grammar before passing.
- Task 2 RED `1ad4ea1` preceded GREEN `c93723d`; the quoted-key diagnostic failed before semantic key normalization and passed afterward.

## User Setup Required

None.

## Next Phase Readiness

- CR-06 is closed with deterministic evidence in the existing mandatory lane.
- Plan 73-15 can address CR-07 and CR-08 independently; Plan 73-16 can then reconcile the Phase 73 security verdict.

## Self-Check: PASSED

Both modified contract files, this summary, and all four RED/GREEN commits were found. Fresh focused, full-contract, mandatory-lane, formatting, and diff verification produced the results recorded above.

---
*Phase: 73-twin-contract-and-baseline*
*Completed: 2026-09-10*
