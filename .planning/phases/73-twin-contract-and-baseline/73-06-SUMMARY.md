---
phase: 73-twin-contract-and-baseline
plan: 06
subsystem: testing
tags: [elixir, exunit, command-validation, workflow-ownership, evidence-contract]
requires:
  - phase: 73-twin-contract-and-baseline
    provides: closed adoption ledger and mandatory evidence owner chain from Plans 01 and 04
provides:
  - Raw command validation that rejects shell control syntax before environment normalization
  - Effective non-zero ExUnit selection across include and exclusion filters
  - Module-scoped ExUnit tag ownership using tag keys and enabled values
  - Unconditional blocking Evidence contract ownership on required pull-request and main-push events
affects: [73-08-evidence-integration, 74-clean-room-package-consumer, 78-ci-quality]
actuals:
  tokens: 4770
  tasks: 2
  commits: 4
tech-stack:
  added: []
  patterns: [raw-before-normalized command validation, module-local AST traversal, effective selector filtering, closed workflow ownership]
key-files:
  created: []
  modified: [test/support/adoption_evidence.ex, test/adoption/evidence_contract_test.exs]
key-decisions:
  - "Model direct-test ownership as the set intersection of enabled include tags minus matching exclusion tags, and reject an empty effective set."
  - "Treat the Evidence contract as mandatory only when the exact jobs.security step has no condition and continue-on-error is absent or literal false."
patterns-established:
  - "Command ownership: reject raw shell syntax first, then normalize environment assignments and parse one Mix invocation."
  - "ExUnit ownership: accumulate module tags per defmodule and bind test tags only to the next executable test in declaration order."
requirements-completed: [EVID-01, EVID-02]
coverage:
  - id: D1
    description: "A direct evidence command proves a non-zero executable ExUnit owner without shell expansion, module leakage, or incidental tag-value matches."
    requirement: EVID-02
    verification:
      - kind: integration
        ref: "mix test test/adoption/evidence_contract_test.exs --only plan_73_06_task_1 --warnings-as-errors (4 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The exact Evidence contract step is unconditional and blocking for planning-relevant pull requests and main pushes."
    requirement: EVID-02
    verification:
      - kind: integration
        ref: "mix test test/adoption/evidence_contract_test.exs --only plan_73_06_task_2 --warnings-as-errors (1 test, 0 failures)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The closed EVID-01 ledger scope and all adoption evidence contract controls remain intact."
    requirement: EVID-01
    verification:
      - kind: integration
        ref: "mix test test/adoption/evidence_contract_test.exs --warnings-as-errors (18 tests, 0 failures)"
        status: pass
    human_judgment: false
duration: 9min
completed: 2026-09-09
status: complete
---

# Phase 73 Plan 06: Executable Evidence Ownership Summary

**Fail-closed raw command, effective ExUnit selector, and unconditional workflow ownership validation for the adoption evidence chain**

## Performance

- **Duration:** 9 min
- **Started:** 2026-09-10T00:57:18Z
- **Completed:** 2026-09-10T01:05:56Z
- **Tasks:** 2
- **Files modified:** 2 implementation/test files

## Accomplishments

- Rejected command substitution and shell control syntax on the original trimmed command before environment-prefix removal.
- Parsed spaced and equals forms of `--only` and `--exclude`, rejected malformed or duplicate filters, and required the composed selection to contain an executable test.
- Replaced file-global selector accumulation with per-module tag state, exact tag-key recognition, and next-test tag binding in stable declaration order.
- Required one exact `Evidence contract` step under `jobs.security` with no job/step condition, no expression-valued fallibility, and planning-relevant pull-request and main-push triggers.

## Task Commits

1. **Task 1 RED: Assign command and selector regression owners** — `08d6216` (test)
2. **Task 1 GREEN: Enforce executable evidence selectors** — `d74646b` (fix)
3. **Task 2 RED: Assign workflow ownership regression** — `ac798e6` (test)
4. **Task 2 GREEN: Require blocking evidence workflow ownership** — `39ad76c` (fix)

## Files Created/Modified

- `test/support/adoption_evidence.ex` — Raw command grammar, normalized include/exclusion parsing, module-scoped executable-test tag inspection, and closed workflow-owner predicate.
- `test/adoption/evidence_contract_test.exs` — Standalone Task 1/Task 2 selectors plus clean and adversarial command, filter, tag, condition, and fallibility controls.

## Decisions Made

- Direct-test filters compose over parsed executable-test tag maps; textual selector presence never counts as ownership.
- An Evidence contract condition is never sampled or interpreted: any job-level or step-level `if` makes the owner optional and therefore invalid.
- `continue-on-error` is blocking only when absent or the unquoted literal YAML boolean `false`; strings and expressions fail closed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected SDK closeout position and progress**

- **Found during:** State and roadmap updates
- **Issue:** `state.advance-plan` advanced from stale prose position 1 to 2 despite six on-disk summaries, while `state.update-progress` could not parse the YAML progress block and left progress at 0 percent.
- **Fix:** Reconciled STATE to the disk-backed 6/8 plan count and 75 percent, recorded Plan 06 as the latest activity, removed duplicated phase prefixes from SDK-added decisions, and retained the next gap-closure route.
- **Files modified:** `.planning/STATE.md`, `.planning/ROADMAP.md`
- **Verification:** ROADMAP and STATE both report 6/8 plans; the roadmap marks only Plans 01-06 complete.
- **Commit:** Final metadata commit

---

**Total deviations:** 1 auto-fixed (1 Rule 1).
**Impact on plan:** The correction restores truthful disk-backed planning state without changing runtime, workflow topology, public API, security posture, or remote state.

## Automated Evidence

- Task 1 selector — 4 tests, 0 failures.
- Task 2 selector — 1 test, 0 failures.
- Complete adoption evidence contract — 18 tests, 0 failures.
- `mix format --check-formatted` — passed for both modified files.
- `git diff --check` — passed for the complete Plan 73-06 code diff.

## Issues Encountered

- The first RED commit attempt was correctly blocked because the user-owned `.tool-versions` does not select Elixir. The file was preserved; all verification and normal commit hooks ran with the plan-mandated explicit Elixir 1.19.5/OTP 28.4.1 environment.

## Known Stubs

None. Empty values found by the stub scan are deliberate fail-closed assertions and validator guards, not runtime or UI placeholders.

## Threat Review

T-73-24 through T-73-26 are mitigated by the committed adversarial corpus. No network endpoint, runtime auth path, file-access trust boundary, schema, dependency, public API, default, SAML security posture, workflow topology, or remote GitHub state changed.

## TDD Gate Compliance

- Task 1 RED `08d6216` precedes GREEN `d74646b`.
- Task 2 RED `ac798e6` precedes GREEN `39ad76c`.

## User Setup Required

None. No external service or remote mutation is involved.

## Next Phase Readiness

- Plan 73-07 can repair the independent governance fail-open paths without relying on hollow adoption evidence ownership.
- Plan 73-08 can run the combined mandatory `mix ci.evidence` integration gate after both Wave 6 repairs are present.

## Self-Check: PASSED

Both modified contract files, this summary, and all four RED/GREEN task commits were found. Fresh focused, full-contract, formatting, and diff verification produced the results recorded above.

---
*Phase: 73-twin-contract-and-baseline*
*Completed: 2026-09-09*
