---
phase: 78-ci-efficiency-and-reliability
plan: 02
subsystem: ci
tags: [github-actions, elixir, exunit, act, postgres]

# Dependency graph
requires:
  - phase: 78-ci-efficiency-and-reliability
    provides: Lifecycle-aware ownership contract and a repaired fresh-run demo test setup
provides:
  - Comparable baseline and candidate security-matrix receipts across OTP 27 and 28
  - A measured decision to remove the duplicate Fast lane while retaining all required gates
  - Workflow mutation contracts for consumer isolation, locked installs, and unsafe cache reuse
affects: [78-03, 78-04, 78-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Store complete bounded run receipts beside cold/warm median and range summaries.
    - Derive workflow reuse decisions from positive execution receipts, not a cache hit.

key-files:
  created:
    - .planning/phases/78-ci-efficiency-and-reliability/78-CI-COST.json
    - scripts/measure_ci_cost.sh
  modified:
    - .github/workflows/security-gates.yml
    - test/adoption/package_consumer_ci_contract_test.exs
    - test/support/adoption_evidence.ex
    - .planning/phases/73-twin-contract-and-baseline/73-RECONCILIATION-PROOF.json
    - .planning/phases/73-twin-contract-and-baseline/73-SECURITY.md
    - .planning/phases/73-twin-contract-and-baseline/73-VALIDATION.md

key-decisions:
  - "Remove only the Fast lane: mix qa and mix ci.fast each selected the same 960 default tests on both OTP versions; the candidate reduced warm median matrix wall time by 4.83% and runner cost by 8.30%."
  - "Keep the existing setup-node npm policy and add no compiled cache because local ACT runs could not measure GitHub cache-service overhead."
  - "Report local ARM64 ACT timings as comparative evidence, not hosted x64 duration predictions."

requirements-completed: [PIPE-03, PIPE-05]

coverage:
  - id: D1
    description: "Three complete baseline and three complete candidate security-matrix observations record cold and warm costs, toolchain, runner identity, selected tests, and bounded raw receipts."
    requirement: PIPE-03
    verification:
      - kind: integration
        ref: ".planning/phases/78-ci-efficiency-and-reliability/78-CI-COST.json — six complete two-OTP observations and recomputed cold/warm medians and ranges"
        status: pass
      - kind: unit
        ref: "test/adoption/package_consumer_ci_contract_test.exs — complete receipt, revision, toolchain, decision, and malformed-report fixtures"
        status: pass
    human_judgment: false
  - id: D2
    description: "All three clean-room consumer profiles remain unconditional, perform locked dependency installation, and cannot be replaced by cached or cross-run consumer state."
    requirement: PIPE-05
    verification:
      - kind: unit
        ref: "test/adoption/package_consumer_ci_contract_test.exs — consumer profile ownership and cache/install mutation fixtures (9 tests)"
        status: pass
      - kind: integration
        ref: ".planning/phases/78-ci-efficiency-and-reliability/78-CI-COST.json — full, minimal, and contracts profiles passed in each matrix observation"
        status: pass
    human_judgment: false
  - id: D3
    description: "The measured workflow removes only the duplicate Fast lane while retaining QA, package consumers, all security/evidence/reconciliation lanes, browser smoke, and standalone GATE-02."
    requirement: PIPE-03
    verification:
      - kind: unit
        ref: "test/adoption/package_consumer_ci_contract_test.exs — measured workflow topology contract (9 tests)"
        status: pass
      - kind: integration
        ref: ".planning/phases/78-ci-efficiency-and-reliability/78-CI-COST.json — baseline and candidate gate receipts for OTP 27 and 28"
        status: pass
    human_judgment: false
  - id: D4
    description: "The Phase 73 canonical proof and both append-only reports match the changed governed workflow."
    requirement: PIPE-05
    verification:
      - kind: integration
        ref: "mix ci.phase73.reconciliation — 1 replay test, 0 failures against the refreshed proof"
        status: pass
      - kind: other
        ref: "MIX_ENV=test mix run -e 'Relyra.Phase73Reconciliation.validate_repository!(File.cwd!())'"
        status: pass
    human_judgment: false

# Metrics
duration: 8h
started: 2026-09-27T16:53:40Z
completed: 2026-09-28
status: complete
---

# Phase 78 Plan 02: Measured CI Topology Summary

**The security matrix now runs one default test pass per OTP after six complete comparisons proved that the former fast lane repeated QA’s 960 tests.**

## Performance

- **Duration:** About 8 hours
- **Started:** 2026-09-27T16:53:40Z
- **Completed:** 2026-09-28T00:51:09Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments

- Added a bounded CI cost collector and committed six complete two-OTP receipts: three current baseline runs and three candidate runs, each with one cold and two warm observations.
- Recorded wall-time and runner-cost medians/ranges with runner/toolchain/cache context, candidate identity, and excluded transient attempts in [78-CI-COST.json](./78-CI-COST.json).
- Confirmed QA and the Fast lane each selected 960 tests on OTP 27 and OTP 28. Removing the duplicate lane reduced warm median matrix wall time by 82,214 ms (4.83%) and warm median runner cost by 273,325 ms (8.30%).
- Kept all three unconditional clean-room consumer profiles and every other acceptance gate, added fail-closed workflow fixtures, and refreshed/replayed the Phase 73 proof for the governed workflow edit.

## Task Commits

1. **Task 1: Build the cost collector and capture the baseline proof** — `70f728b` (`test`)
2. **Task 2: Repair fresh-run demo metadata and record comparable costs** — `dd0e304` (`fix`), `fee1063` (`docs`), `72f8dbe` (`test`)
3. **Task 3: Apply the measured topology and refresh governed proof** — `0037e47` (`ci`)

## Files Created/Modified

- `scripts/measure_ci_cost.sh` — records command exit status, selected test counts, setup/step/job time, and runner metadata.
- `test/adoption/package_consumer_ci_contract_test.exs` — validates receipt comparability, cost decision math, unconditional consumer ownership, locked install, cache-only and duplicate/skipped-profile mutations.
- `.planning/phases/78-ci-efficiency-and-reliability/78-CI-COST.json` — full successful receipts, cold/warm statistics, candidate decision, and excluded-attempt receipts.
- `.github/workflows/security-gates.yml` — removes only `Fast lane`; leaves `Quality gate` and all other check names and commands intact.
- `73-RECONCILIATION-PROOF.json`, `73-SECURITY.md`, and `73-VALIDATION.md` — canonical proof `phase73-0ee0b9963cb5af5f` and matching append-only report blocks.
- `test/support/adoption_evidence.ex` and `.github/workflows/security-gates.yml` — loads nested LedgerLoop test metadata on fresh runners before QA.

## Decisions Made

- The baseline and candidate each ran all clean-room consumer profiles, QA, security, evidence, Phase 73 reconciliation, verification, integration, demo, admin UI, browser smoke, and standalone GATE-02 on OTP 27 and OTP 28.
- The candidate’s warm median runner cost fell 8.30%; its warm median matrix wall time fell 4.83%. The redundant default test execution is the supported topology change.
- Local ACT used an ARM64 Docker runner on Apple Silicon. The reported measurements compare the two topologies on that runner; they do not estimate hosted x64 time or GitHub cache-service latency.
- No compiled dependency cache was introduced. The existing locked Mix install and setup-node policy remain.

## Deviations from Plan

### Auto-fixed Issues

**1. Fresh-run demo metadata was missing from the test beam path**

- **Found during:** Task 2 baseline measurement.
- **Issue:** A fresh CI environment could not load nested `LedgerLoopWeb.ConnCase` metadata during QA.
- **Fix:** Added a test-only nested demo dependency/compile setup step and made the adoption evidence probe include the nested demo test beam directory.
- **Files modified:** `.github/workflows/security-gates.yml`, `test/support/adoption_evidence.ex`, `test/adoption/package_consumer_ci_contract_test.exs`.
- **Verification:** Subsequent complete baseline and candidate matrices passed QA and the demo lane on both OTP versions.
- **Committed in:** `dd0e304`; governed proof refreshed in `fee1063`.

### Measurement exclusions

- A candidate verification attempt hit a local database queue timeout; its fresh-database retry passed.
- One candidate contracts attempt stopped during artifact build, and a later OTP 28 integration canary hit its 120-second live Hex timeout. Both full attempts are retained as rejected raw receipts; only the later complete pass counts toward the three candidate observations.
- The first direct Phase 73 replay used the host’s default PostgreSQL socket and failed to create a test database (`"killed"`). The replay passed against an isolated task-owned PostgreSQL 16 container.

**Total deviations:** 1 auto-fixed source issue and 3 excluded attempts/replays (all recorded or explained above).
**Impact on plan:** The added demo setup was required to measure the fresh-run workflow successfully; cache policy and security-gate structure otherwise follow the measured plan.

## Verification

- `mix test test/adoption/package_consumer_ci_contract_test.exs --warnings-as-errors` — 7 tests, 0 failures after the measurement report; 9 tests, 0 failures after workflow fixtures.
- Six ACT matrix runs passed completely on `catthehacker/ubuntu:act-24.04`, Linux ARM64, Elixir 1.19.5, OTP 27 and OTP 28. Each consumer profile passed; selected counts included QA 960, security 66, evidence 146, Phase 73 reconciliation 1, verification 58, integration 9, admin UI 40, and standalone GATE-02 3.
- `mix ci.phase73.reconciliation` — 1 replay test, 0 failures against proof `phase73-0ee0b9963cb5af5f`.
- `MIX_ENV=test mix run -e 'Relyra.Phase73Reconciliation.validate_repository!(File.cwd!())'` — passed.
- `mix format --check-formatted` — passed in the Task 2 and Task 3 commit hooks.

## User Setup Required

None.

## Next Plan Readiness

Plan 78-03 can proceed. The matrix keeps its independent security commands and standalone GATE-02 owner; this plan changed only the redundant QA/fast scheduling choice.

---
*Phase: 78-ci-efficiency-and-reliability*
*Completed: 2026-09-28*

## Self-Check: PASSED

- All three tasks have committed production changes.
- The summary matches six passing complete observations and the current proof/workflow state.
- All reported deliverables have passing automated evidence; no human verification gate was added.
