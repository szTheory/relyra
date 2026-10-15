---
phase: 73-twin-contract-and-baseline
plan: 08
subsystem: governance
tags: [elixir, exunit, remote-command-grammar, provenance, symlink-defense]
requires:
  - phase: 73-twin-contract-and-baseline
    provides: executable evidence ownership and closed governance lifecycle from Plans 73-06 and 73-07
provides:
  - Closed single-operation grammar for reversible remote GitHub approval batches
  - Repository-root-aware baseline provenance with component-by-component symlink rejection
  - Git-index membership and shared executable-owner validation for every finding reference
affects: [74-clean-room-package-consumer, 77-craftsmanship, 78-ci-quality, 79-release-readiness]
actuals:
  tokens: 8191
  tasks: 2
  commits: 4
tech-stack:
  added: []
  patterns: [parse-before-authorize remote commands, lstat root-to-leaf provenance, non-shell git index checks]
key-files:
  created: []
  modified: [test/governance/milestone_scope_test.exs, .planning/phases/73-twin-contract-and-baseline/73-BASELINE.md]
key-decisions:
  - "Authorize remote batches only after each field is fully consumed by one closed operation grammar and parsed targets agree."
  - "Accept baseline paths only when every root-relative component is non-symlink, the leaf is regular, and git tracks the lexical repository path."
  - "Delegate baseline command evidence to the same executable non-zero owner validator used by adoption evidence."
patterns-established:
  - "Remote approval: lexical composition rejection precedes command grammar, then target and state comparison."
  - "Baseline provenance: lexical containment, cumulative lstat, regular leaf, and git-index membership all fail closed."
requirements-completed: [QUAL-01, PIPE-01, GOV-01]
coverage:
  - id: D1
    description: "Remote approval accepts one reversible same-target operation per field and rejects appended shell or second remote operations."
    requirement: GOV-01
    verification:
      - kind: integration
        ref: "mix test test/governance/milestone_scope_test.exs --only plan_73_08_task_1 --warnings-as-errors (1 test, 0 failures)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Every baseline finding resolves to a tracked regular path reached through non-symlink components or an executable non-zero command owner."
    requirement: QUAL-01
    verification:
      - kind: integration
        ref: "mix test test/governance/milestone_scope_test.exs --only plan_73_08_task_2 --warnings-as-errors (1 test, 0 failures)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The dated ten-finding, seven-category quality inventory and nine-surface CI before-snapshot remain mandatory evidence without becoming remediation or optimization claims."
    requirement: PIPE-01
    verification:
      - kind: integration
        ref: "mix ci.evidence (53 tests, 0 failures)"
        status: pass
    human_judgment: false
duration: 15min
completed: 2026-09-09
status: complete
---

# Phase 73 Plan 08: Remote Grammar and Baseline Provenance Summary

**Closed remote-operation authorization and root-to-leaf tracked provenance make the dated quality and CI baseline reproducible without changing its inventory-only boundary**

## Performance

- **Duration:** 15 min
- **Started:** 2026-09-10T01:30:18Z
- **Completed:** 2026-09-10T01:45:18Z
- **Tasks:** 2
- **Files modified:** 2 implementation/contract files

## Accomplishments

- Replaced substring-based remote authorization with full-string grammars for owner-controlled script writes, exact API reads/writes, captured-state rollback, and check-set read-back.
- Rejected newline composition, semicolons, boolean operators, pipes, backticks, substitutions, extra tokens, wrong methods, and mismatched targets before authorization comparison.
- Required baseline path evidence to remain lexically beneath the repository root, pass cumulative `File.lstat/1` checks without any symlink component, end at a regular file, and match the git index through a non-shell process call.
- Routed command-shaped evidence through `Relyra.AdoptionEvidence.validate_automated_command!/2` and replaced hollow baseline evidence tokens with truthful tracked sources while preserving every finding and CI snapshot fact.

## Task Commits

1. **Task 1 RED: Define remote operation grammar controls** — `1d5ba34` (test)
2. **Task 1 GREEN: Parse exact remote operations** — `2aa249e` (fix)
3. **Task 2 RED: Define baseline provenance controls** — `f50207f` (test)
4. **Task 2 GREEN: Require real baseline provenance** — `49548cd` (fix)

## Files Created/Modified

- `test/governance/milestone_scope_test.exs` — Closed remote command parser, parsed target comparison, repository-root provenance validator, and isolated symlink/index adversaries.
- `.planning/phases/73-twin-contract-and-baseline/73-BASELINE.md` — Finding evidence cells now point to tracked source files or shared executable owners without changing inventory facts, severities, routing, or dated sample language.

## Decisions Made

- Remote command grammar is field-specific: mutation permits the owner script or exact desired-state API write, preflight permits an exact API read, rollback requires `captured-current.json`, and read-back requires an exact check-set assertion.
- Repository containment is lexical and component-aware. Canonical target resolution, `File.regular?/1`, or git-index presence alone cannot certify a path reached through a symlink.
- Baseline command evidence uses the existing adoption-evidence validator; generic `rg`, `git`, or script-shaped prose is not a separate evidence class.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Kept existing mismatch controls inside the new grammar**

- **Found during:** Task 2 mandatory `mix ci.evidence` integration run
- **Issue:** Two pre-existing target-mismatch controls removed required read-back or rollback grammar fields, so the new parser correctly reported grammar failure before the older assertions could reach target comparison.
- **Fix:** Made both controls syntactically valid operations with only the branch changed, preserving their intended target-mismatch coverage under parse-before-compare semantics.
- **Files modified:** `test/governance/milestone_scope_test.exs`
- **Verification:** `mix ci.evidence` passes all 53 currently committed contract tests.
- **Committed in:** `49548cd`

**2. [Rule 1 - Bug] Reconciled SDK closeout progress and decision formatting**

- **Found during:** Sequential state and roadmap updates
- **Issue:** `state.update-progress` could not parse the YAML progress block and reset the completed phase-plan progress to 0 percent, while `state.add-decision` duplicated the phase prefix and retained stale activity text.
- **Fix:** Restored disk-backed 8/8 and 100 percent progress, normalized the three decision entries, recorded Plan 08 activity, and routed the next step to Phase 73 verification. The SDK-touched user-owned `.planning/state.json` was restored to its exact pre-execution content and left unstaged.
- **Files modified:** `.planning/STATE.md`
- **Verification:** STATE reports 8/8 plans, 100 percent, Plan 08 activity, and the Phase 73 verification next step; the user-owned JSON mirror matches its preserved pre-execution SHA-1.
- **Committed in:** Final metadata commit

---

**Total deviations:** 2 auto-fixed (2 Rule 1).
**Impact on plan:** The adjustments preserve prior adversarial intent, strengthen the ordered grammar/target contract, and keep planning state truthful without expanding runtime, API, security posture, workflow, or remote scope.

## Automated Evidence

- Task 1 selector — 1 test, 0 failures; no CR-09 selector selected.
- Task 1 tracer feedback rerun — 1 test, 0 failures.
- Task 2 selector — 1 test, 0 failures; includes the intermediate-directory symlink/index control and no CR-08 selector.
- Mandatory `mix ci.evidence` integration — 53 tests, 0 failures.
- `mix format --check-formatted` — passed repository-wide.
- `git diff --check` — passed for the complete Plan 73-08 task diff.

The plan text expected 52 contract tests, but the unchanged current repository total is 53 (18 adoption plus 35 governance tests). Plan 73-08 extended two existing tests in place and neither added nor removed a test definition.

## Issues Encountered

- The first Task 1 commit attempt was blocked because the preserved user-owned `.tool-versions` does not select Elixir. The commit was rerun normally with the plan-mandated explicit Elixir 1.19.5/OTP 28.4.1 environment; hooks remained enabled.
- The known incomplete-phase documentation vocabulary failure remains deferred to Phase 77 and was not run as a completion gate or modified by this plan.

## Known Stubs

None. Placeholder values and empty command strings in the modified governance file are deliberate fail-closed adversarial fixtures, not incomplete runtime or UI behavior.

## Threat Review

The contract closes command-composition and repository-provenance trust-boundary bypasses using inert strings and isolated temporary repositories. No network endpoint, runtime authentication path, application file-access path, schema, dependency, public API, default, SAML security posture, workflow topology, or remote GitHub state changed.

## TDD Gate Compliance

- Task 1 RED `1d5ba34` precedes GREEN `2aa249e`.
- Task 2 RED `f50207f` precedes GREEN `49548cd`.

## User Setup Required

None. No external service or remote mutation was used.

## Next Phase Readiness

- Phase 73 now has an executable owner chain, closed governance lifecycle, exact remote authorization grammar, and real baseline provenance under the mandatory evidence lane.
- Phase 74 can consume the baseline’s package-boundary finding; Phases 77–79 retain the documented craftsmanship, CI optimization, and approved remote-repair work.

## Self-Check: PASSED

Both modified contract files, this summary, and all four RED/GREEN task commits were found. Fresh focused selectors, tracer feedback, combined evidence, formatting, and diff-hygiene verification produced the results recorded above.

---
*Phase: 73-twin-contract-and-baseline*
*Completed: 2026-09-09*
