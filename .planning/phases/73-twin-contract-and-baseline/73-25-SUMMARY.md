---
phase: 73-twin-contract-and-baseline
plan: 25
subsystem: security-governance
tags: [closed-grammar, acceptance-ownership, git-provenance, merge-rejection, deterministic-evidence]
requires:
  - phase: 73-twin-contract-and-baseline
    provides: Plan 73-24 repository authority, closed Mix argv, and current open-review chronology
provides:
  - Total fail-closed parsing for every task and acceptance owner in the canonical tasks region
  - Completion-boundary changed-surface classification without weakening task-commit equality
  - Explicit rejection of multi-parent commits before changed-path reduction
affects: [phase-73-gap-closure, ci.evidence, security-closeout, plan-73-26]
plan_head_before: 866f9f6513a2b652446ed8137d82ccba3a67b50b
actuals:
  tokens: 6531
  tasks: 2
  commits: 4
tech-stack:
  added: []
  patterns: [linear closed-tag consumption, task-local acceptance cardinality, boundary-delta aggregation, parent-topology validation]
key-files:
  created: [.planning/phases/73-twin-contract-and-baseline/73-25-SUMMARY.md]
  modified: [test/governance/milestone_scope_test.exs, .planning/STATE.md, .planning/state.json, .planning/ROADMAP.md]
key-decisions:
  - "Consume the singular tasks region linearly and reject structural residue before applying semantic governance policy."
  - "Keep the completion boundary outside Task Commits equality while classifying its complete parent delta with all other reviewed changes."
  - "Require exactly one parent for every reviewed commit so merge topology cannot collapse to an empty trusted surface."
  - "Extract SUMMARY claims only from numbered commit rows, including deviation and refactor rows but excluding free-form metadata hashes."
patterns-established:
  - "Syntax and ownership cardinality are validated before type, risk, approval, verification, or exclusion reduction."
  - "Repository provenance validates topology before resolving changed paths or content."
requirements-completed: [EVID-01, EVID-02, QUAL-01, PIPE-01, GOV-01, GOV-02]
coverage:
  - id: D1
    description: "Every task-shaped construct and acceptance owner in the singular canonical tasks region is parsed exactly once or rejects before semantic governance."
    requirement: GOV-01
    verification:
      - kind: integration
        ref: "test/governance/milestone_scope_test.exs --only plan_73_25_task_1 — 3 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D2
    description: "Completion-boundary deltas reach approval classification and multi-parent commits reject before path reduction."
    requirement: EVID-02
    verification:
      - kind: integration
        ref: "test/governance/milestone_scope_test.exs --only plan_73_25_task_2 — 2 tests, 0 failures"
        status: pass
      - kind: integration
        ref: "mix ci.evidence — 114 tests, 0 failures"
        status: pass
    human_judgment: false
duration: 16min
completed: 2026-09-11
status: complete
---

# Phase 73 Plan 25: Task and Provenance Closure Summary

**A total task/acceptance grammar and topology-aware Git provenance now prevent malformed plan constructs, SUMMARY-boundary changes, or merge commits from disappearing before approval classification.**

## Performance

- **Duration:** 16 min
- **Started:** 2026-09-11T21:27:46Z
- **Completed:** 2026-09-11T21:43:28Z
- **Tasks:** 2
- **Files modified:** 1 governance test file, 3 project-tracking files, and this summary

## Accomplishments

- Replaced permissive task selection with one singular, non-empty, linearly consumed task-region grammar that rejects malformed, nested, unmatched, unterminated, attribute-free, and residual task syntax.
- Bound every balanced `acceptance_criteria` occurrence to exactly one parsed implementation task and rejected detached, duplicated, empty, nested, and unmatched ownership shapes before semantic reduction.
- Added the completion boundary's full parent delta to changed-surface classification while preserving pre-boundary-only SUMMARY and manifest task-commit equality.
- Rejected every reviewed zero-parent or multi-parent commit explicitly before path extraction, with deterministic real two-parent merge fixtures.
- Preserved all tracked Phase 73 plan forms and the existing linear-history, descendant, SUMMARY, manifest, public-interface, and mandatory evidence controls.

## Task Commits

Each task was committed as a verified RED/GREEN pair:

1. **Task 1 RED: Closed task grammar controls** — `4a34412` (test)
2. **Task 1 GREEN: Total task and acceptance parsing** — `f867d15` (feat)
3. **Task 2 RED: Boundary and merge provenance controls** — `7e3d15b` (test)
4. **Task 2 GREEN: Boundary classification and merge rejection** — `9d6b951` (feat)

## Files Created/Modified

- `test/governance/milestone_scope_test.exs` — closed task-region parsing, acceptance ownership cardinality, completion-boundary aggregation, parent-count validation, and adversarial Markdown/Git fixtures.
- `.planning/phases/73-twin-contract-and-baseline/73-25-SUMMARY.md` — measured execution record and Plan 73-26 handoff.

## Decisions Made

- Task syntax is one structural input: the parser consumes the entire canonical region before any task can participate in type, risk, approval, verification, exclusion, or feature-neutrality policy.
- Acceptance ownership is positional and task-local; a section must be balanced, non-nested, non-empty, and wholly contained by exactly one implementation-bearing task.
- Completion boundaries remain excluded from task-commit bookkeeping but not from security classification; their changed content joins the same aggregate provenance surface.
- Reviewed commit topology is linear by contract. Any parent count other than one fails explicitly before `diff-tree` can reduce the commit to paths.
- Numbered SUMMARY commit rows are authoritative claims, including deviation/refactor rows. Narrative metadata hashes are not task claims.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Restricted SUMMARY commit extraction to numbered commit rows**

- **Found during:** Task 2 full governance regression
- **Issue:** The prior section-wide backtick scan interpreted Plan 73-24's narrative metadata hash as a task commit, causing a false provenance mismatch. A first narrow form that accepted only labels beginning with `Task` then omitted legitimate numbered deviation and refactor commits in older summaries.
- **Fix:** Accepted hashes only from numbered bold commit rows, regardless of row label, while excluding unnumbered narrative metadata.
- **Files modified:** `test/governance/milestone_scope_test.exs`
- **Verification:** The focused Task 2 selector passed 2 tests, the complete governance file passed 61 tests, and `mix ci.evidence` passed 114 tests.
- **Committed in:** `9d6b951`

**2. [Rule 1 - Bug] Reconciled the SDK's zero-percent progress output**

- **Found during:** Plan closeout
- **Issue:** The SDK correctly advanced to Plan 73-26 and counted 25 completed summaries, but `state.update-progress` could not find a legacy body progress line and reset frontmatter/state JSON progress to zero. It also left descriptive position prose at Plan 73-24/25 and duplicated the phase prefix on newly recorded decisions.
- **Fix:** Aligned STATE, state JSON, and ROADMAP with 25/26 complete, 96 percent, and Plan 73-26 as the sole remaining frontier; normalized the two decision entries.
- **Files modified:** `.planning/STATE.md`, `.planning/state.json`, `.planning/ROADMAP.md`
- **Verification:** Tracking artifacts agree on 25 completed plans, one remaining plan, and the Plan 73-26 frontier.
- **Committed in:** final metadata commit

---

**Total deviations:** 2 auto-fixed bugs.
**Impact on plan:** The correction restores exact task-commit equality for existing summaries without rewriting executed artifacts or changing runtime, public API, defaults, security posture, dependencies, workflow, remote state, or SemVer behavior.

## TDD Gate Compliance

- **Task 1 RED:** `4a34412`; three named controls failed on malformed task syntax, invalid acceptance ownership, and tracked-plan preservation, and `/tmp/relyra-73-25-task1-red.json` received `RED_EVIDENCE_OK`.
- **Task 1 GREEN:** `f867d15`; the focused selector passed 3 tests, and the tracer feedback gate reran the complete slice successfully before expansion.
- **Task 2 RED:** `7e3d15b`; both named controls failed because the completion boundary was absent from classification and a real two-parent merge reduced to an accepted empty delta, and `/tmp/relyra-73-25-task2-red.json` received `RED_EVIDENCE_OK`.
- **Task 2 GREEN:** `9d6b951`; the focused selector passed 2 tests, the complete governance file passed 61 tests, and the mandatory evidence lane passed 114 tests.
- **REFACTOR:** No separate refactor commit was necessary; the GREEN implementations remained focused and readable after formatting.

## Automated Evidence

- `plan_73_25_task_1`: 3 tests, 0 failures; tracer feedback rerun passed end to end.
- `plan_73_25_task_2`: 2 tests, 0 failures.
- Complete `test/governance/milestone_scope_test.exs`: 61 tests, 0 failures.
- Pre-summary `mix ci.evidence`: 114 tests, 0 failures.
- `mix format --check-formatted` and `git diff --check`: passed.

## Issues Encountered

- The complete governance regression exposed the pre-existing ambiguity between numbered task-commit entries and unnumbered metadata hashes inside SUMMARY Task Commits sections. The parser now follows the numbered-row structure already used by tracked summaries.
- The untracked user-owned `.tool-versions` selects Node only, so every Mix command and commit hook ran under explicitly selected Elixir 1.19.5/OTP 28.4.1 without modifying that file.

## Known Stubs

None. The realized diff contains no implementation placeholder, TODO/FIXME, skipped test, empty-rendering value, or unwired data source. Existing `placeholder` strings are negative governance fixture data and validation vocabulary, not incomplete implementation.

## Threat Review

- T-73-94 is mitigated by singular region extraction, linear task consumption, closed attributes, and task-local acceptance cardinality before semantic reduction.
- T-73-95 is mitigated by deriving and aggregating the completion boundary's complete parent delta independently of task-commit equality.
- T-73-96 is mitigated by exact parent-count validation before changed-path extraction and explicit full-identity diagnostics for merges.
- This plan introduces no new network endpoint, authentication path, schema boundary, production file access, dependency, public API, default, security posture, remote state, or SemVer change.

## User Setup Required

None.

## Next Phase Readiness

- Plan 73-26 can reconcile security and Nyquist disposition from the passing Task 1, Task 2, governance-file, and mandatory evidence results.
- The tracked implementation boundary is deterministic at 114 evidence-contract tests and leaves all runtime/security architecture seams unchanged.

## Self-Check: PASSED

The modified governance owner, this summary, and all four authoritative RED/GREEN task commits exist. The persisted ledger records base `866f9f6513a2b652446ed8137d82ccba3a67b50b` and measures exactly four pre-summary task commits; coverage metadata names passing deterministic evidence for both Plan 73-25 deliverables.

---
*Phase: 73-twin-contract-and-baseline*
*Completed: 2026-09-11*
