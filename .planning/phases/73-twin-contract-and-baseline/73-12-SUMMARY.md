---
phase: 73-twin-contract-and-baseline
plan: 12
subsystem: testing
tags: [elixir, exunit, mix-aliases, github-actions, evidence-contract, git-provenance]
requires:
  - phase: 73-twin-contract-and-baseline
    provides: literal six-persona evidence ledger, executable owner parser, and mandatory Evidence contract workflow from Plans 73-01 through 73-11
provides:
  - Actual ci.evidence alias validation with positive effective selection for every declared owner
  - Fail-closed positive workflow path policy for pull requests and main pushes
  - Complete tracked governed-input discovery across fixed evidence sources and all Phase 73 plans and summaries
affects: [73-13-gap-closure, 74-clean-room-package-consumer, 78-ci-quality]
actuals:
  tokens: 5397
  tasks: 2
  commits: 5
tech-stack:
  added: []
  patterns: [single parsed alias command, per-owner effective ExUnit selection, git-index-derived planning frontier, disjoint ignore-filter proof]
key-files:
  created: []
  modified: [test/support/adoption_evidence.ex, test/adoption/evidence_contract_test.exs]
key-decisions:
  - "Resolve each evidence lane once from actual Mix project configuration and require every command owner to retain a positive effective ExUnit selection."
  - "Reject every positive paths filter on the mandatory Evidence contract workflow and allow paths-ignore only when disjoint from the complete tracked governed-input set."
patterns-established:
  - "Repository evidence validation preserves row-scoped source diagnostics before binding rows to one semantically parsed alias result."
  - "Mandatory workflow inputs combine a fixed non-empty source set with git-tracked Phase 73 PLAN and SUMMARY discovery."
requirements-completed: [EVID-01, EVID-02]
coverage:
  - id: D1
    description: "The real ci.evidence alias is parsed through the shared supported-command seam and every owner retains a non-empty selection after include and exclude filters."
    requirement: EVID-02
    verification:
      - kind: integration
        ref: "mix test test/adoption/evidence_contract_test.exs --only plan_73_12_task_1 --warnings-as-errors (3 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Pull-request and main-push workflow triggers reject positive paths and cannot ignore any fixed evidence source or tracked Phase 73 planning artifact."
    requirement: EVID-02
    verification:
      - kind: integration
        ref: "mix test test/adoption/evidence_contract_test.exs --only plan_73_12_task_2 --warnings-as-errors (3 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The literal six-persona ledger and planned/external-canary non-closing states remain intact under the hardened owner chain."
    requirement: EVID-01
    verification:
      - kind: ci
        ref: "mix ci.evidence (76 tests, 0 failures)"
        status: pass
    human_judgment: false
duration: 16min
completed: 2026-09-10
status: complete
---

# Phase 73 Plan 12: Complete Evidence Owner and Trigger Contract Summary

**Actual Mix alias semantics and a git-derived governed-input frontier now prevent empty evidence ownership and restrictive mandatory-workflow triggers**

## Performance

- **Duration:** 16 min
- **Started:** 2026-09-10T20:46:12Z
- **Completed:** 2026-09-10T21:02:14Z
- **Tasks:** 2
- **Files modified:** 2 implementation/test files

## Accomplishments

- Replaced repository-level substring ownership with the same anchored command parser, actual Mix alias resolver, filter parser, and fresh-process ExUnit registration seam used by automated verification commands.
- Required every test path in `ci.evidence`, and every exact ledger owner/selector pair, to retain a positive effective selection after all ordered include and exclude filters.
- Rejected every non-empty positive `paths` configuration for both mandatory workflow events and proved allowed ignore patterns disjoint from fixed evidence inputs plus every tracked Phase 73 PLAN and SUMMARY.
- Preserved the single literal ledger, all six personas, existing/planned states, evidence kinds, and external-canary non-closing semantics from D-01 through D-04.

## Task Commits

1. **Task 1 RED: Reproduce hollow alias ownership** — `897d96f` (test)
2. **Task 1 GREEN: Validate effective alias ownership** — `0884c44` (fix)
3. **Task 2 RED: Reproduce restrictive evidence triggers** — `8a251a5` (test)
4. **Task 2 GREEN: Enforce complete evidence triggers** — `385e3dc` (fix)
5. **Task 2 hardening: Preserve diagnostics and runtime** — `d407b5f` (fix)

## Files Created/Modified

- `test/support/adoption_evidence.ex` — Shared semantic alias result, per-owner effective counts, fail-closed workflow policy, and tracked governed-input discovery.
- `test/adoption/evidence_contract_test.exs` — Standalone Plan 73-12 selectors, hollow alias and restrictive trigger adversaries, and indexed repository fixtures.

## Decisions Made

- Lane commands are normalized once per repository validation, while source ownership retains its earlier row-scoped diagnostic boundary.
- Positive workflow path lists are categorically rejected because no finite allowlist can remain complete as governed evidence evolves.
- Phase planning inputs come from `git ls-files`; fixed source inputs are also required to be regular, repository-contained, and tracked before ignore patterns are evaluated.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserved established diagnostics and avoided adversarial timeout**

- **Found during:** Task 2 full-contract verification
- **Issue:** Precomputing the alias result before source validation replaced established row-scoped selector diagnostics, and workflow-negative fixtures spent enough time in fresh owner probes to hit ExUnit's 60-second timeout.
- **Fix:** Restored deduplicated source validation before alias binding, retained legacy zero-selection wording with effective-selection detail, and validated workflow triggers before expensive owner inspection.
- **Files modified:** `test/support/adoption_evidence.ex`, `test/adoption/evidence_contract_test.exs`
- **Verification:** Full adoption evidence contract passed 32 tests; mandatory `mix ci.evidence` passed 76 tests.
- **Committed in:** `d407b5f`

---

**Total deviations:** 1 auto-fixed Rule 1 bug.
**Impact on plan:** The fix preserves compatibility and deterministic runtime without changing the new fail-closed policy or expanding scope.

## Automated Evidence

- Task 1 selector — 3 tests, 0 failures.
- Task 2 selector — 3 tests, 0 failures.
- Complete adoption evidence contract — 32 tests, 0 failures.
- `mix ci.evidence` — 76 tests, 0 failures across adoption and governance owners.
- `mix format --check-formatted` — passed for both modified files.
- `git diff --check` — passed.

## Issues Encountered

- The first RED commit attempt was correctly blocked by the format hook because the user-owned `.tool-versions` selects no Elixir version. The file was preserved and every commit hook ran with the plan-mandated Elixir 1.19.5/OTP 28.4.1 environment.
- The first complete paths-ignore property run timed out before workflow validation was moved ahead of fresh owner probes; this became the Rule 1 runtime fix above.

## Known Stubs

None. Empty strings, empty collections, and malformed filters in the modified tests and validators are intentional fail-closed assertions or adversarial fixtures.

## Threat Review

T-73-51 through T-73-54 are mitigated by exact alias parsing, independent effective owner counts, categorical positive-filter rejection, and complete tracked governed-input evaluation. The only file/process access added is the plan-declared private test validator's local Git index inspection and isolated ExUnit registration probe. No network endpoint, auth path, runtime schema, dependency, public API, default, SAML security seam, workflow topology, package surface, or remote GitHub state changed.

## TDD Gate Compliance

- Task 1 RED `897d96f` preceded GREEN `0884c44`; all three focused regressions failed before implementation and passed afterward.
- Task 2 RED `8a251a5` preceded GREEN `385e3dc`; the restrictive positive-filter regression failed before implementation and the complete focused selector passed afterward.

## User Setup Required

None.

## Next Phase Readiness

- Plan 73-13 may execute against a non-hollow mandatory evidence owner and complete governed trigger frontier.
- Phase verification should be rerun after Plan 73-13; no Plan 73-12 blocker remains.

## Self-Check: PASSED

Both modified contract files, this summary, and all five RED/GREEN/hardening commits were found. Fresh focused, full-contract, mandatory-lane, formatting, and diff verification produced the results recorded above.

---
*Phase: 73-twin-contract-and-baseline*
*Completed: 2026-09-10*
