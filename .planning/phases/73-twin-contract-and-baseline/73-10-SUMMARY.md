---
phase: 73-twin-contract-and-baseline
plan: 10
subsystem: testing
tags: [elixir, exunit, governance, git-provenance, fail-closed]
requires:
  - phase: 73-twin-contract-and-baseline
    provides: closed plan vocabulary, changed-surface classification, and executable evidence ownership from Plans 03 through 09
provides:
  - Non-vacuous v1.11 governance identity joined across PROJECT, ROADMAP, REQUIREMENTS, and STATE
  - Immutable path-based legacy dispatch for completed Plans 73-01 through 73-03 only
  - Git-derived completed-plan commit provenance with SUMMARY hashes as an exact audit cross-check
affects: [73-11-remote-authorization, 74-clean-room-package-consumer, 79-adopter-ready-closeout]
actuals:
  tokens: 9250
  tasks: 2
  commits: 5
tech-stack:
  added: []
  patterns: [closed repository identity parsing, executable-frontier discovery, exact conventional-commit scopes, ancestry-bound diff classification]
key-files:
  created: []
  modified: [test/governance/milestone_scope_test.exs]
key-decisions:
  - "Governance begins only after PROJECT, ROADMAP, REQUIREMENTS, and STATE establish one agreeing active v1.11 identity with a real current-phase directory and plan frontier."
  - "Only exact completed paths 73-01 through 73-03 use the legacy schema; every other plan receives the current contract regardless of removable document content."
  - "Completed-plan changes come from reachable exact-scope Git commits before the unique SUMMARY-add boundary; SUMMARY hashes are equality-checked but never authoritative."
patterns-established:
  - "Repository governance reviews completed plans plus the first incomplete current-phase plan, matching the executable frontier without borrowing future selectors."
  - "Git commands use argv-only System.cmd calls rooted at the validated repository and classify every trusted commit diff exactly once."
requirements-completed: [GOV-01, GOV-02]
coverage:
  - id: D1
    description: "Active v1.11 governance discovery fails closed on empty, malformed, duplicate, missing, or cross-source-inconsistent repository identity."
    requirement: GOV-01
    verification:
      - kind: integration
        ref: "mix test test/governance/milestone_scope_test.exs --only plan_73_10_task_1 --warnings-as-errors (2 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Schema dispatch is path-derived, preserving only three immutable completed legacy plans and rejecting weakened current plans."
    requirement: GOV-02
    verification:
      - kind: integration
        ref: "mix test test/governance/milestone_scope_test.exs --only plan_73_10_task_1 --warnings-as-errors (2 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Completed-plan governed surfaces derive from the complete reachable exact-scope commit set and reject incomplete or ambiguous SUMMARY provenance."
    requirement: GOV-01
    verification:
      - kind: integration
        ref: "mix test test/governance/milestone_scope_test.exs --only plan_73_10_task_2 --warnings-as-errors (3 tests, 0 failures)"
        status: pass
    human_judgment: false
duration: 18min
completed: 2026-09-10
status: complete
---

# Phase 73 Plan 10: Trusted Governance Identity and Git Provenance Summary

**Closed v1.11 repository identity, immutable schema dispatch, and ancestry-bound completed-plan change classification**

## Performance

- **Duration:** 18 min
- **Started:** 2026-09-10T14:53:04Z
- **Completed:** 2026-09-10T15:11:00Z
- **Tasks:** 2
- **Files modified:** 1 implementation/test file

## Accomplishments

- Replaced regex-only incomplete-phase discovery with four closed parsers that cross-check the active milestone, current execution phase, phase requirements, directory identity, and non-empty plan frontier.
- Removed content-controlled schema downgrade: only exact completed Plan 73-01, 73-02, and 73-03 paths receive legacy validation.
- Replaced SUMMARY-selected changed surfaces with exact Conventional Commit scope discovery, unique completion-boundary ancestry, reachability checks, and complete diff classification.
- Made SUMMARY Task Commits a strict audit cross-check that rejects omissions, additions, duplicates, unresolved hashes, and ordering ambiguity without changing the trusted review set.

## Task Commits

1. **Task 1 RED: Define trusted discovery and schema controls** — `c6e90e8` (test)
2. **Task 1 GREEN: Bind governance to repository identity** — `3833a36` (fix)
3. **Task 2 RED: Define completed-plan provenance adversaries** — `603561a` (test)
4. **Task 2 GREEN: Derive completed-plan surfaces from Git** — `2be446d` (fix)
5. **Task 2 compatibility: Scope governance to the executable frontier** — `65e85cc` (fix)

## Files Created/Modified

- `test/governance/milestone_scope_test.exs` — Closed repository parsers, trusted schema dispatcher, isolated Git provenance fixtures, complete commit/diff resolver, and standalone Plan 73-10 selectors.

## Decisions Made

- STATE supplies milestone version, current phase, and active execution status; PROJECT and ROADMAP supply the canonical milestone name, avoiding reliance on the SDK-maintained descriptive `milestone_name` field.
- The current execution set is every completed current-phase plan plus the first incomplete plan in lexical plan order. Later incomplete plans cannot break the present gate using selectors they do not yet own.
- A phase manifest is authoritative only when it contains the expected per-plan mapping and a valid commit list; malformed present metadata fails closed instead of silently falling back.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Restricted active governance to the executable plan frontier**

- **Found during:** Overall governance contract verification
- **Issue:** Scanning every future incomplete plan made the current Plan 73-10 gate depend on Plan 73-11's deliberately not-yet-created selector.
- **Fix:** Validate every completed plan plus the first incomplete plan, preserving non-vacuity and ordering while preventing future work from impersonating current execution state.
- **Files modified:** `test/governance/milestone_scope_test.exs`
- **Verification:** Full 40-test governance contract and 65-test mandatory evidence lane passed.
- **Committed in:** `65e85cc`

**2. [Rule 1 - Bug] Reconciled SDK progress and next-step prose**

- **Found during:** State and roadmap updates
- **Issue:** `state.update-progress` could not parse the YAML progress block, while `state.advance-plan` set the percentage to zero and left last-activity/next-step prose on Plan 73-09/73-10.
- **Fix:** Reconciled STATE to 10/11 plans and 91 percent, recorded Plan 73-10 as the latest activity, and routed the operator to Plan 73-11.
- **Files modified:** `.planning/STATE.md`
- **Verification:** ROADMAP reports 10/11 and the on-disk summary count is 10.
- **Committed in:** Final metadata commit

---

**Total deviations:** 2 auto-fixed Rule 1 bugs.
**Impact on plan:** The adjustment strengthens plan-local concurrency and execution ordering without changing public API, runtime behavior, defaults, SAML security posture, dependencies, or remote state.

## Automated Evidence

- Task 1 selector — 2 tests, 0 failures.
- Task 2 selector — 3 tests, 0 failures.
- Complete governance contract — 40 tests, 0 failures.
- `mix ci.evidence` — 65 tests, 0 failures.
- `mix format --check-formatted` — passed.
- `git diff --check` — passed.

## Issues Encountered

- Normal commit hooks required explicit Elixir 1.19.5/OTP 28.4.1 environment selection because the user-owned `.tool-versions` selects Node only. The file was preserved.

## Known Stubs

None. Empty values, placeholder strings, and missing paths in the modified test file are deliberate fail-closed adversarial fixtures.

## Threat Review

T-73-41 through T-73-44 are mitigated by closed source parsers, immutable path dispatch, reachable ancestry-bound Git provenance, and independent SUMMARY equality checks. T-73-45 remains accepted because parsing is bounded to tracked planning files and isolated small Git fixtures. No runtime network endpoint, auth path, file-access surface, schema, dependency, public API, default, security posture, or remote GitHub state changed.

## TDD Gate Compliance

- Task 1 RED `c6e90e8` preceded GREEN `3833a36`.
- Task 2 RED `603561a` preceded GREEN `2be446d`.
- Both RED runs failed on missing behavior before implementation, and both focused selectors are green.

## User Setup Required

None.

## Next Phase Readiness

- Plan 73-11 can now bind remote payload contents to declared desired/current state while inheriting a non-vacuous current execution frontier.
- The mandatory evidence lane is green with all Plan 73-10 selectors executable and non-zero.

## Self-Check: PASSED

The modified governance contract, this summary, and all five RED/GREEN/compatibility commits were found. Fresh focused selectors, the full governance contract, the mandatory evidence lane, formatting, and diff verification produced the results recorded above.

---
*Phase: 73-twin-contract-and-baseline*
*Completed: 2026-09-10*
