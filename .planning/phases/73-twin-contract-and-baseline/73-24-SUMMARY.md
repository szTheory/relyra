---
phase: 73-twin-contract-and-baseline
plan: 24
subsystem: security-governance
tags: [repository-authority, mix-argv, exunit-filters, github-actions, deterministic-evidence]
requires:
  - phase: 73-twin-contract-and-baseline
    provides: Plan 73-23 closeout artifacts and the current-review chronology that exposed later fail-open counterexamples
provides:
  - Current open security and Nyquist records for CR-01 through CR-06 and WR-01
  - Repository-root authority for both governed snapshot inventories and dependency-free jobs.security ownership
  - Closed Mix test argv consumption with real ExUnit include union and override semantics
affects: [phase-73-gap-closure, ci.evidence, security-closeout, plan-73-25, plan-73-26]
plan_head_before: 942165e6bbcbb2aa2a02382fbdf55c78524059c6
actuals:
  tokens: 15119
  tasks: 3
  commits: 6
tech-stack:
  added: []
  patterns: [external repository authority, closed argv consumption, executable zero-test counterexamples, include-overrides-exclude selection]
key-files:
  created: [.planning/phases/73-twin-contract-and-baseline/73-24-SUMMARY.md]
  modified: [.planning/phases/73-twin-contract-and-baseline/73-SECURITY.md, .planning/phases/73-twin-contract-and-baseline/73-VALIDATION.md, test/support/adoption_evidence.ex, test/adoption/evidence_contract_test.exs, test/governance/milestone_scope_test.exs]
key-decisions:
  - "Treat the repository root supplied outside a candidate snapshot as the sole authority for both governed-input fields."
  - "Require jobs.security to have no direct needs declaration, because a skipped dependency can suppress the entire mandatory evidence job."
  - "Accept only normalized .exs owners, exactly one --warnings-as-errors switch, and distinct --only/--exclude filters; reject every other Mix test token."
  - "Model includes as alternatives that override matching exclusions, matching the real ExUnit command behavior exercised by isolated fixtures."
patterns-established:
  - "Candidate snapshots are shape-checked and then independently compared with a repository-derived authority before workflow reduction."
  - "Accepted deterministic test commands are fully consumed by one parser and demonstrated against real Mix execution."
requirements-completed: [EVID-01, EVID-02, QUAL-01, PIPE-01, GOV-01, GOV-02]
coverage:
  - id: D1
    description: "The six current blocker findings and include-semantics warning are registered open after historical seals and before later repair evidence."
    requirement: GOV-02
    verification:
      - kind: integration
        ref: "test/governance/milestone_scope_test.exs#current review findings are registered open before repair evidence"
        status: pass
    human_judgment: false
  - id: D2
    description: "Both supplied governed-input fields must independently equal the inventory recomputed from the separately supplied repository root."
    requirement: EVID-01
    verification:
      - kind: integration
        ref: "test/adoption/evidence_contract_test.exs#repository authority rejects twin-field inventory forgery before workflow reduction"
        status: pass
    human_judgment: false
  - id: D3
    description: "The mandatory security owner rejects scalar, list, duplicate, and skipped-prerequisite dependency declarations."
    requirement: PIPE-01
    verification:
      - kind: integration
        ref: "test/adoption/evidence_contract_test.exs#security owner rejects every direct dependency shape including skipped prerequisites"
        status: pass
    human_judgment: false
  - id: D4
    description: "Closed Mix argv rejects stale zero-test success and unmodeled tokens while matching real ExUnit include union and override behavior."
    requirement: EVID-02
    verification:
      - kind: integration
        ref: "mix ci.evidence — 109 tests, 0 failures"
        status: pass
    human_judgment: false
duration: 37min
completed: 2026-09-11
status: complete
---

# Phase 73 Plan 24: Evidence Authority Closure Summary

**Externally rooted snapshot authority, dependency-free security-job ownership, and a fully consumed Mix argv grammar now close the current deterministic-evidence bypasses while preserving an explicit open-review chronology.**

## Performance

- **Duration:** 37 min
- **Started:** 2026-09-11T20:41:43Z
- **Completed:** 2026-09-11T21:18:25Z
- **Tasks:** 3
- **Files modified:** 5 implementation, test, and report files plus this summary

## Accomplishments

- Reopened the stale security and validation dispositions after the later review, registering T-73-91 through T-73-97 and preserving the historical audit rows before any repair evidence.
- Replaced caller-controlled twin-field authority with independent repository-root recomputation and rejected all direct `jobs.security.needs` shapes before mandatory-step reduction.
- Replaced the open Mix filter collector with one closed argv consumer and matched real ExUnit include alternatives and include-overrides-exclude behavior.
- Reproduced the `--stale` second-run `No stale tests` exit-zero counterexample in an isolated real Mix project and proved the validator rejects it.

## Task Commits

Each TDD task was committed as a verified RED/GREEN pair:

1. **Task 1 RED: Pin current-review open-state chronology** — `05ef0f7` (test)
2. **Task 1 GREEN: Reopen current evidence blockers** — `cdec03b` (feat)
3. **Task 2 RED: Add repository-authority and dependency controls** — `d92145d` (test)
4. **Task 2 GREEN: Bind ownership to repository execution** — `af3f86c` (feat)
5. **Task 3 RED: Reproduce closed-argv and filter-semantics failures** — `90d2980` (test)
6. **Task 3 GREEN: Close Mix test argv and align ExUnit selection** — `51a7d05` (feat)

**Plan metadata:** `a539b26` (docs), followed by this post-boundary tracking correction

## Post-Boundary Correction

- `2a74edf` (`perf`) batches governed-input Git tracking into one exact inventory comparison after the first post-boundary run exposed redundant per-file subprocess cost. It preserves component-wise path provenance and is intentionally separate from the six pre-summary authoritative task commits.

## Files Created/Modified

- `.planning/phases/73-twin-contract-and-baseline/73-SECURITY.md` — current issues-found state, seven review rows, updated counts, and immutable correction audit.
- `.planning/phases/73-twin-contract-and-baseline/73-VALIDATION.md` — current gaps-found/Nyquist-false state with blocked requirement rows and seven named counterexamples.
- `test/support/adoption_evidence.ex` — explicit-root snapshot validation, authoritative inventory comparison, dependency-free security ownership, closed argv parsing, and ExUnit-aligned selection.
- `test/adoption/evidence_contract_test.exs` — twin-field forgery, dependency-shape, unsupported-token, real stale-mode, and real include-semantics fixtures.
- `test/governance/milestone_scope_test.exs` — permanent open-before-repair chronology contract.
- `.planning/phases/73-twin-contract-and-baseline/73-24-SUMMARY.md` — measured execution record and downstream handoff.

## Decisions Made

- Repository-derived inventory is authoritative independently for `governed_input_inventory` and `governed_inputs`; equality between two mutable candidate fields is only an internal consistency check.
- A direct `needs` declaration on `jobs.security` is always invalid, including duplicate and block-list YAML forms, because the contract does not model dependency execution semantics.
- Direct test commands have a deliberately small closed language: normalized repository-relative `.exs` owners, exactly one warnings-as-errors switch, and only split or equals `--only`/`--exclude` filters.
- With includes present, any include match selects the test and overrides exclusions; without includes, matching exclusions remove the test.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated two historical hollow-selection fixtures for ExUnit override semantics**

- **Found during:** Task 3 mandatory `mix ci.evidence` verification
- **Issue:** Two older negative tests appended `--exclude evidence_contract` to a command that already included `--only evidence_contract`; after the planned semantics correction, the explicit include correctly overrides that exclusion, so those fixtures no longer represented an empty selection.
- **Fix:** Replaced the include with the exclusion in each hollow fixture, retaining a genuine zero-effective-test negative control.
- **Files modified:** `test/adoption/evidence_contract_test.exs`
- **Verification:** Focused historical selectors passed 7 tests; the complete `mix ci.evidence` lane passed 109 tests.
- **Committed in:** `51a7d05`

**2. [Rule 1 - Bug] Reconciled the SDK's stale sequential cursor and progress prose**

- **Found during:** Plan closeout
- **Issue:** The SDK correctly counted 24 completed summaries but advanced a stale numeric cursor from Plan 1 to Plan 2, retained zero-percent progress, and left ROADMAP prose at 23 complete with three remaining plans.
- **Fix:** Aligned STATE, state JSON, and ROADMAP with 24/26 complete, 92 percent, and Plan 73-25 as the next executable gap-closure plan.
- **Files modified:** `.planning/STATE.md`, `.planning/state.json`, `.planning/ROADMAP.md`
- **Verification:** Tracking artifacts now agree on 24 completed plans, two remaining plans, and the Plan 73-25 frontier.
- **Committed in:** final metadata commit

**3. [Rule 1 - Performance bug] Batched repeated governed-input tracking checks**

- **Found during:** Post-boundary `mix ci.evidence` verification
- **Issue:** The new mandatory repository-authority recomputation reused a per-file Git tracking probe, causing the existing 25-iteration pure-snapshot regression to exceed its 60-second test timeout.
- **Fix:** Retained component-wise regular/non-symlink provenance validation while comparing the complete sorted inventory with one Git index query per recomputation.
- **Files modified:** `test/support/adoption_evidence.ex`
- **Verification:** The formerly timing-out selector passed in 2.1 seconds; the subsequent evidence run completed in 22.8 seconds without a timeout.
- **Committed in:** `2a74edf`

---

**Total deviations:** 3 auto-fixed bugs.
**Impact on plan:** The correction preserves the intended negative coverage under the newly required ExUnit precedence; no product runtime, public API, default, dependency, workflow, remote state, or SemVer behavior changed.

## TDD Gate Compliance

- **Task 1 RED:** `05ef0f7`; the named chronology test failed on the stale verified security disposition, and `/tmp/relyra-73-24-task1-red.json` received `RED_EVIDENCE_OK`.
- **Task 1 GREEN:** `cdec03b`; the exact selector passed 1 test, and the tracer feedback rerun passed end to end.
- **Task 2 RED:** `d92145d`; both named controls failed because twin-field forgery and direct security dependencies were accepted, and `/tmp/relyra-73-24-task2-red.json` received `RED_EVIDENCE_OK`.
- **Task 2 GREEN:** `af3f86c`; the focused selector passed 2 tests and the complete adoption contract passed 50 tests.
- **Task 3 RED:** `90d2980`; all three named controls failed on the planned closedness/selection behavior, and `/tmp/relyra-73-24-task3-red.json` received `RED_EVIDENCE_OK`.
- **Task 3 GREEN:** `51a7d05`; the focused selector passed 3 tests and the mandatory evidence lane passed 109 tests.
- **REFACTOR/PERFORMANCE:** `2a74edf`; post-boundary batching preserved exact tracking authority and restored the bounded repeated-validation regression.

## Automated Evidence

- `plan_73_24_task_1`: 1 test, 0 failures; tracer feedback rerun passed.
- `plan_73_24_task_2`: 2 tests, 0 failures.
- Complete adoption evidence contract after Task 2: 50 tests, 0 failures.
- `plan_73_24_task_3`: 3 tests, 0 failures, including real isolated Mix commands.
- Historical selector regression group: 7 tests, 0 failures.
- Pre-summary `mix ci.evidence`: 109 tests, 0 failures.
- Post-summary `mix ci.evidence`: repository authority, summary provenance, and 108 other tests passed; the sole expected frontier failure is Plan 73-25's not-yet-implemented `plan_73_25_task_1` owner.
- `mix format --check-formatted` and `git diff --check`: passed.

## Issues Encountered

- The first full Task 3 evidence run exposed two historical negative fixtures whose include-plus-exclude construction was invalid under the corrected ExUnit precedence. Their empty-selection intent was restored within Task 3 and the complete lane then passed.
- The first post-boundary run also exposed redundant per-file Git subprocess cost and the SDK's invalid `ready_to_execute` governance lifecycle. Batching restored the bounded test, and STATE remains in the allowed `executing` lifecycle while pointing to Plan 73-25.
- Once this summary made Plan 73-25 the active frontier, the final evidence run correctly rejected its not-yet-implemented selector. All Plan 73-24 controls and the other 108 evidence tests passed; Plan 73-25 owns that next RED/GREEN boundary.

## Known Stubs

None. The realized diff contains no implementation placeholder, TODO/FIXME, skipped test, empty-rendering value, or unwired data source.

## Threat Review

- T-73-91 through T-73-97 remain explicitly registered for the current review chronology; Plans 73-24 through 73-26 provide the ordered repair and later reconciliation evidence.
- Repository authority is supplied outside the mutable snapshot, both candidate fields are checked independently, and workflow reduction cannot hide an omitted governed path.
- A skipped dependency cannot suppress the mandatory evidence owner because every direct `jobs.security.needs` occurrence is rejected before step reduction.
- Unmodeled Mix selection modes cannot create a green zero-test owner because every argv token must be consumed by the closed grammar.
- This plan introduces no new network endpoint, authentication path, schema boundary, production file access, dependency, public API, default, security posture, remote state, or SemVer change.

## User Setup Required

None.

## Next Phase Readiness

- Plans 73-25 and 73-26 can build on the rooted evidence contract and closed command model while the current reports truthfully remain open.
- The Plan 73-24 implementation boundary is positive and deterministic at 109 tests. The tracked summary intentionally activates Plan 73-25, whose absent task selector is now the sole mandatory-lane failure and next execution target.

## Self-Check: PASSED

All six modified implementation/report artifacts, all six pre-summary authoritative task commits, and post-boundary performance correction `2a74edf` exist. The persisted ledger records base `942165e6bbcbb2aa2a02382fbdf55c78524059c6` and measured six commits before the summary boundary; coverage metadata names passing deterministic evidence for every Plan 73-24 deliverable.

---
*Phase: 73-twin-contract-and-baseline*
*Completed: 2026-09-11*
