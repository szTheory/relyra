---
phase: 78-ci-efficiency-and-reliability
plan: 03
subsystem: testing
tags: [mix, elixir, exunit, ci]

# Dependency graph
requires:
  - phase: 78-ci-efficiency-and-reliability
    provides: Measured CI topology and retained security, consumer, and standalone binary gates
provides:
  - Fresh-process test execution for every ci.docs and ci.verify suite
  - AST-based exact command inventory and mutation contracts for ci.security and standalone GATE-02
affects: [78-04, 78-07]

# Actuals (#2632)
actuals:
  tokens: 3754
  tasks: 2
  commits: 1

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Parse Mix aliases as Elixir AST and compare exact test command inventories.
    - Expand nested aliases before checking independent test process boundaries.
    - Require positive, zero-failure ExUnit summaries in summary parser contracts.

key-files:
  created: []
  modified:
    - mix.exs
    - test/security/ci_gate_integrity_test.exs

key-decisions:
  - "Run docs and verification suites with cmd mix test so every declared test selection gets a fresh Mix process."
  - "Protect the exact security command and selector inventory while keeping standalone GATE-02 unconditional and blocking."

patterns-established:
  - "Nested Mix aliases are flattened in contract fixtures before checking process isolation and selector inheritance."
  - "Workflow YAML contracts assert the exact named standalone gate, command, and absence of disabling conditions."

requirements-completed: [PIPE-02, PIPE-03]

coverage:
  - id: D1
    description: "ci.docs and the nested ci.verify path run every selected suite in independent Mix processes, with positive execution summaries."
    requirement: PIPE-02
    verification:
      - kind: unit
        ref: "test/security/ci_gate_integrity_test.exs — 9 tests, 0 failures; exact docs/verify inventories and bare-task/inherited-selector mutations"
        status: pass
      - kind: integration
        ref: "mix ci.verify — 9 positive summaries: 4, 1, 1, 2, 1, 37, 4, 8, and 59 tests; 0 failures in each process"
        status: pass
      - kind: integration
        ref: "mix ci.docs — exited 0; its eight suites also reported positive summaries in the nested ci.verify run"
        status: pass
    human_judgment: false
  - id: D2
    description: "Security suites retain separate fresh processes and selectors, and standalone GATE-02 remains an independent blocking workflow step."
    requirement: PIPE-03
    verification:
      - kind: unit
        ref: "test/security/ci_gate_integrity_test.exs — suite collapse/drop, bare test, selector change, disabled/missing standalone gate, and zero-summary mutations"
        status: pass
      - kind: integration
        ref: "mix ci.security — exit 0; all 13 ExUnit processes selected tests and reported 0 failures"
        status: pass
      - kind: integration
        ref: "mix test --only gate02_c14n --warnings-as-errors — 3 tests, 0 failures (977 excluded)"
        status: pass
    human_judgment: false

# Metrics
duration: 21m
completed: 2026-09-28
status: complete
---

# Phase 78 Plan 03: Independent Mix Test Gates

**Docs, verification, and security suites now have AST-checked independent Mix processes, with the standalone GATE-02 workflow gate protected against disabling or removal.**

## Performance

- **Duration:** About 21 minutes
- **Completed:** 2026-09-28T01:14:43Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Converted both remaining bare `ci.docs` tests and the `ci.verify` test command to independent `cmd mix test` processes, preserving test selections and warning flags.
- Extended the AST-based integrity owner to check exact docs, verify, and security command inventories; nested aliases; positive ExUnit summaries; and mutation fixtures for deduplication, selector inheritance, dropped or collapsed suites, and hollow results.
- Added a parsed workflow contract requiring the exact standalone GATE-02 step and rejecting a missing or disabled gate.

## Task Commits

1. **Tasks 1–2: Make docs, verification, and security test process boundaries explicit** — `37a2200` (`ci(test)`)

**Plan metadata:** pending state update commit.

## Files Created/Modified

- `mix.exs` — runs the selected docs and verification tests in fresh OS processes.
- `test/security/ci_gate_integrity_test.exs` — protects exact command inventories, selectors, positive summaries, and standalone GATE-02.

## Decisions Made

- Kept the security suite inventory exact, including the existing shared corpus command, instead of assuming one file per process.
- Validated standalone GATE-02 from parsed workflow YAML, including its exact command and unconditional blocking behavior.

## Deviations from Plan

None. The test matcher was adjusted during execution to distinguish `cmd test -f` file checks from Mix test commands; the final focused owner passed.

## Issues Encountered

- The initial commit hook could not resolve Elixir because the user-owned `.tool-versions` declares Node only. Re-running the commit with explicit Elixir 1.19.5 / OTP 28 environment values passed the hook; the user-owned file was left untouched.
- `mix ci.security` exited 0 and all suites passed, but the local MixAudit advisory cache refresh printed a permission error while updating its `FETCH_HEAD`. The task continued and reported no vulnerabilities; hosted CI has its normal checkout/cache permissions.

## User Setup Required

None.

## Next Plan Readiness

Plan 78-04 can proceed. It owns workflow permission scope, concurrency isolation, and verified action pins; this plan changed no workflow files.

---
*Phase: 78-ci-efficiency-and-reliability*
*Completed: 2026-09-28*

## Governance Provenance Reconciliation

The original implementation is preserved in `37a2200` (`ci(test)`). This follow-up records the completed plan under its plan-scoped history identity so the Phase 73 governance replay can verify the exact implementation boundary.
