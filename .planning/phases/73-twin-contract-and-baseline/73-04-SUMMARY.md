---
phase: 73-twin-contract-and-baseline
plan: 04
subsystem: testing
tags: [elixir, exunit, evidence-ownership, github-actions, governance]
requires:
  - phase: 73-twin-contract-and-baseline
    provides: literal evidence ledger, ci.evidence alias, mandatory security workflow, and plan governance parser from Plans 01-03
provides:
  - Closed-schema closure validation with whitespace-safe row diagnostics
  - Semantic non-zero ExUnit selector ownership and enabled blocking workflow validation
  - Task-local executable acceptance ownership for direct tests and fresh-process aliases
affects: [73-05-governance-gap-closure, 74-packaged-consumer, 78-ci-quality, 79-release-readiness]
actuals:
  tokens: 6019
  tasks: 2
  commits: 4
tech-stack:
  added: []
  patterns: [AST-based ExUnit ownership inspection, indentation-scoped workflow validation, task-local acceptance evidence]
key-files:
  created: [.planning/phases/73-twin-contract-and-baseline/73-04-SUMMARY.md]
  modified: [test/support/adoption_evidence.ex, test/adoption/evidence_contract_test.exs, test/governance/milestone_scope_test.exs, .planning/STATE.md, .planning/ROADMAP.md, .planning/WINDOWS.md]
key-decisions:
  - "Count an evidence selector only when parsed ExUnit source associates it with at least one test definition."
  - "Recognize workflow ownership only in the exact enabled, blocking Evidence contract step under jobs.security."
  - "Require every acceptance-bearing non-checkpoint task to own an allowed direct test or one-step fresh-process check alias independently."
patterns-established:
  - "Evidence owner chain: closed row -> semantic selected test -> fresh-process alias -> enabled blocking security step."
  - "Acceptance ownership: validate each task independently and preserve task-order diagnostics for every uncovered criterion."
requirements-completed: [EVID-02]
coverage:
  - id: D1
    description: "Closure evidence fails closed on malformed rows, inert selectors, and optional or misplaced workflow steps."
    requirement: EVID-02
    verification:
      - kind: integration
        ref: "test/adoption/evidence_contract_test.exs#closure and mandatory owner-chain adversarial controls"
        status: pass
      - kind: integration
        ref: "ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix ci.evidence (34 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Every acceptance-bearing task requires its own executable verification owner with a non-zero selected test set."
    requirement: EVID-02
    verification:
      - kind: integration
        ref: "test/governance/milestone_scope_test.exs#every acceptance-bearing task requires its own executable non-zero owner"
        status: pass
      - kind: integration
        ref: "ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix ci.evidence (34 tests)"
        status: pass
    human_judgment: false
duration: 12min
completed: 2026-09-09
status: complete
---

# Phase 73 Plan 04: Deterministic Evidence Owner Closure Summary

**Closed-schema evidence now reaches mandatory CI only through real selected ExUnit tests, while every acceptance-bearing task owns independent executable proof.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-09-09T20:47:08Z
- **Completed:** 2026-09-09T20:58:58Z
- **Tasks:** 2
- **Files modified:** 3 implementation files

## Accomplishments

- Hardened closure validation so every supplied row passes the same exact schema, vocabulary, persona, and trimmed-text checks as the canonical ledger before it can close a requirement.
- Replaced raw tag and workflow token searches with parsed ExUnit ownership and indentation-scoped validation of the exact enabled, blocking `Evidence contract` step under `jobs.security`.
- Replaced aggregate command-shaped acceptance with task-local validation of direct warnings-as-errors tests or a one-step fresh-process repository alias, including semantic non-zero test selection.
- Added adversarial controls for malformed rows, whitespace-only fields, comments and strings posing as tags, empty tagged modules, disabled/non-blocking/wrong-job workflow placement, generic Mix commands, shell echoes, zero-test selectors, and uncovered sibling tasks.

## Task Commits

1. **Task 1 RED: Expose hollow evidence owner paths** — `98e1445` (test)
2. **Task 1 GREEN: Prove mandatory evidence owner chain** — `df52a86` (feat)
3. **Task 2 RED: Expose task acceptance ownership bypasses** — `5e7ee3d` (test)
4. **Task 2 GREEN: Enforce task-local acceptance owners** — `093262c` (feat)

## Files Created/Modified

- `test/support/adoption_evidence.ex` — Closed-row validation, semantic ExUnit selection, structured security-step validation, and executable command ownership.
- `test/adoption/evidence_contract_test.exs` — Malformed closure, whitespace, inert-selector, and non-mandatory workflow controls.
- `test/governance/milestone_scope_test.exs` — Per-task acceptance parsing and invalid direct/alias command fixtures with stable task diagnostics.
- `.planning/STATE.md`, `.planning/ROADMAP.md`, and `.planning/WINDOWS.md` — Truthful 4/5 progress, execution continuity, and fixed deviation record.

## Decisions Made

- Used Elixir AST inspection for selector ownership so comments and string literals cannot count, while retaining the existing dependency-free test-support seam.
- Scoped workflow parsing by indentation to the existing `jobs.security.steps` hierarchy instead of introducing a second YAML dependency or changing workflow topology.
- Allowed multiple automated commands on a task when at least one is an executable owner, preserving ancillary checks while preventing one task from covering a sibling.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected contradictory SDK state progress**

- **Found during:** Plan closeout
- **Issue:** `state.advance-plan` advanced the stale execution-start position from Plan 1 to Plan 2, and `state.update-progress` could not recognize the YAML progress field, leaving four completed summaries at 0 percent.
- **Fix:** Aligned STATE with the disk-backed truth: Plan 4 of 5 complete, 80 percent progress, and Plan 73-05 as the operator next step.
- **Files modified:** `.planning/STATE.md`
- **Verification:** STATE reports 4 completed plans and ROADMAP reports 4/5 plans executed.
- **Committed in:** Final metadata commit

---

**Total deviations:** 1 auto-fixed (1 Rule 1)
**Impact on plan:** The correction restores truthful execution metadata without changing implementation scope.

## Issues Encountered

- The first RED commit attempt reached the existing pre-commit hook without an ASDF Elixir selection because the user-owned `.tool-versions` names only Node. The commit was retried with the plan-required Elixir 1.19.5 / OTP 28.4.1 environment; hooks passed and `.tool-versions` was not modified.

## Automated Evidence

- Task 1 focused verification — 13 selected tests, 0 failures.
- Task 1 tracer feedback re-run — 13 selected tests, 0 failures before expansion.
- Task 2 focused verification — 34 selected tests across both Phase 73 contract files, 0 failures.
- Plan-level `mix ci.evidence` — 34 selected tests, 0 failures.
- `mix format --check-formatted` and `git diff --check` — passed.

## Known Stubs

None. Empty values and placeholder-shaped strings in the modified tests are isolated negative controls that must fail validation; no runtime or user-visible data source changed.

## Threat Review

All plan threats T-73-13 through T-73-16 are mitigated by the passing adversarial controls. The changes remain test-only and introduce no network endpoint, authentication path, schema boundary, runtime file access, public API, default, algorithm policy, key handling, parser, audit, or replay surface.

## User Setup Required

None.

## Next Phase Readiness

Plan 73-05 can harden risk inference, remote batch structure, demand-gated exclusions, and baseline verification markers on top of a non-hollow deterministic owner contract. The archival vocabulary failure remains owned by Phase 77 as previously recorded.

## Self-Check: PASSED

All three implementation files, this summary, and all four TDD task commits were found. The plan-level evidence lane, formatting check, and whitespace check pass.

---
*Phase: 73-twin-contract-and-baseline*
*Completed: 2026-09-09*
