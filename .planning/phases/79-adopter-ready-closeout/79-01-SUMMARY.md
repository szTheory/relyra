---
phase: 79-adopter-ready-closeout
plan: 01
subsystem: infra
tags: [github, python, ci, inventory, readiness]
requires:
  - phase: 78-ci-efficiency-and-reliability
    provides: CI ownership and source-bound clean-state receipt contract
provides:
  - Read-only local Git and GitHub inventory collector with bounded, source-provenanced JSON output
  - Deterministic fixture coverage for pagination, exact lane ownership, redaction, and fail-closed evidence
  - Live Phase 79 repository inventory with explicit unknown readiness and separate canary evidence
affects: [phase-79-plan-02, closeout, github-readiness]
actuals:
  tokens: 49548
  tasks: 3
  commits: 6
  plan_head_before: 550543d6908755bf1e14c235981a19ffde0baedd
tech-stack:
  added: []
  patterns: [standard-library Python CLI, paginated GitHub GET collection, exact mandatory workflow ownership]
key-files:
  created:
    - scripts/collect_phase79_inventory.py
    - .planning/phases/79-adopter-ready-closeout/79-INVENTORY.json
    - .planning/phases/79-adopter-ready-closeout/79-INVENTORY.md
  modified:
    - test/governance/milestone_scope_test.exs
key-decisions:
  - "Keep readiness unknown unless every mandatory lane and expected protection context has current-main evidence."
  - "Bind mandatory lanes to security-gates.yml; release workflows and scheduled canaries cannot substitute."
  - "Preserve unknown-owner local paths and report cleanup candidates without deleting them."
patterns-established:
  - "Paginated GitHub sources retain page, access, completeness, and captured-SHA provenance."
  - "Canary check runs are listed separately from deterministic mandatory lanes."
requirements-completed: [REPO-01, REPO-02, REPO-03]
coverage:
  - id: D1
    description: Read-only inventory collector gathers local state and bounded GitHub evidence.
    requirement: REPO-01
    verification:
      - kind: unit
        ref: test/governance/milestone_scope_test.exs#Phase 79 fixture collector emits timestamped, source-bound inventory
        status: pass
    human_judgment: false
  - id: D2
    description: Mandatory lane evidence is paginated, source-bound, and cannot be satisfied by canary or release workflows.
    requirement: REPO-03
    verification:
      - kind: integration
        ref: mix ci.evidence
        status: pass
    human_judgment: false
  - id: D3
    description: Current local and GitHub inventory is recorded with unknown readiness retained for missing evidence.
    requirement: REPO-02
    verification:
      - kind: other
        ref: python3 scripts/collect_phase79_inventory.py --verify .planning/phases/79-adopter-ready-closeout/79-INVENTORY.json
        status: pass
    human_judgment: false
duration: 48min
completed: 2026-09-30
status: complete
---

# Phase 79 Plan 01: Adopter-Ready Closeout Summary

**Read-only closeout inventory with source-bound CI lane evidence, ownership-aware local path reporting, and fail-closed unknown readiness.**

## Performance

- **Duration:** 48 min
- **Started:** 2026-09-29T23:20:20Z
- **Completed:** 2026-09-30T00:08:11Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Added a standard-library collector that gathers local Git state and fully paginated GitHub reads, revalidates the main SHA, redacts remote fields, and writes an atomic bounded JSON receipt.
- Added deterministic fixtures for timestamp and source provenance, pagination, malformed or partial evidence, current-SHA lane checks, protection contexts, canary separation, and release/canary non-substitution.
- Recorded the live inventory in JSON and Markdown. Every GitHub source completed with access allowed, but current-main readiness remains unknown because the mandatory lanes and both live-required security contexts have no evidence for the observed SHA.
- Preserved the maintainer-owned `.tool-versions`, unknown-owner paths, pre-existing planning edits, and all registered local state without cleanup.

## Task Commits

Each planned task was committed atomically. Three follow-up task-scoped fixes address issues found during exact verification and live collection.

1. **Task 1: Read-only closeout collector and fixture contract** - `1231fcb` (`feat`)
2. **Task 2: Fail-closed evidence contracts** - `0b39570` (`fix`)
3. **Task 1 follow-up: Complete pagination and lane binding** - `968a26b` (`fix`)
4. **Task 1 follow-up: Canonical mandatory lane ownership** - `4092b73` (`fix`)
5. **Task 1 follow-up: Preserve check-run canary evidence separately** - `96a7961` (`fix`)
6. **Task 3: Current inventory and ownership report** - `9f71d84` (`docs`)

## Files Created/Modified

- `scripts/collect_phase79_inventory.py` - Read-only GitHub/local collector, pagination handling, provenance validation, exact mandatory workflow ownership, and separate canary evidence.
- `test/governance/milestone_scope_test.exs` - Collector fixture contracts, including later-page checks and rejection of release/canary substitution.
- `.planning/phases/79-adopter-ready-closeout/79-INVENTORY.json` - Current machine-readable observation.
- `.planning/phases/79-adopter-ready-closeout/79-INVENTORY.md` - Human-readable inventory and evidence gaps.

## Decisions Made

- Kept readiness `unknown`: all nine mandatory lanes are absent for main SHA `c786a9890f2f99f0dd98f89a1d9713db7c486837`; two live-required security contexts also lack SHA-bound evidence.
- Kept the live branch-protection discrepancy visible: live requires two security contexts, while expected protection also includes `fleet-proxy-e2e`.
- Used only `.github/workflows/security-gates.yml` as owner for mandatory lanes so similarly named release workflow steps cannot substitute.
- Kept the 33 successful `rulestead-main-canary` check observations separate from deterministic lane results.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Bound lane status to complete check-run pagination and canonical owners**
- **Found during:** Task 3 live collection.
- **Issue:** Classification refetched only the first check-run page, and broad workflow matching allowed unrelated release or canary workflow files to become lane owners.
- **Fix:** Use every paginated current-SHA check run, restrict mandatory lane ownership to the canonical security-gates workflow, and add fixtures proving later-page evidence is retained while release and canary runs cannot satisfy a missing lane.
- **Files modified:** `scripts/collect_phase79_inventory.py`, `test/governance/milestone_scope_test.exs`.
- **Verification:** `mix ci.evidence` passed (153 tests, 0 failures).
- **Committed in:** `968a26b`, `4092b73`.

**2. [Rule 1 - Bug] Preserve scheduled canary check evidence and bound ignored path reporting**
- **Found during:** Task 3 live collection.
- **Issue:** Canary extraction read workflow runs only even though the observed scheduled canary evidence was present as check runs; ignored temporary outputs expanded into many file paths.
- **Fix:** Retain canary check records separately with safe status/SHA/time fields and collapse generated root candidates to bounded paths. Added a fixture asserting check-run canary provenance.
- **Files modified:** `scripts/collect_phase79_inventory.py`, `test/governance/milestone_scope_test.exs`.
- **Verification:** `mix ci.evidence` passed (153 tests, 0 failures); the refreshed live receipt verified successfully.
- **Committed in:** `4092b73`, `96a7961`.

**3. [Rule 1 - Bug] Resolve Phase 79 governance contract coverage within declared tests**
- **Found during:** Task 1 exact verification.
- **Issue:** The lifecycle test's existing branches covered `{"79", "planning"}` but not the actual `{"79", "executing"}` identity; its `case` therefore failed to match. This actual state predates task commits: baseline `550543d` already recorded `current_phase: 79` and `status: executing` in `.planning/STATE.md`.
- **Fix:** Added the explicit executing-phase branch and narrowly scoped Phase 79 demand-gated exclusion and Python inventory-verifier assertions in the declared governance test file. Other plans and commands retain the default rejection behavior.
- **Files modified:** `test/governance/milestone_scope_test.exs`.
- **Verification:** `mix test test/governance/milestone_scope_test.exs --warnings-as-errors` passed (85 tests, 0 failures).
- **Committed in:** `0b39570`.

**Total deviations:** 3 auto-fixed (Rule 1 bugs). **Impact:** Each correction was directly required for source-bound, fail-closed inventory behavior or its deterministic governance contract. No plan or governance artifact was weakened.

## Issues Encountered

- The pre-commit formatter rejected the first follow-up commit because the new fixture needed Mix formatting. Formatted the declared test file, reran `mix ci.evidence`, and committed with the formatter hook passing.
- The live observation reports unknown readiness; this is the expected fail-closed outcome for missing evidence and an observed context mismatch, not a collector verification failure.

## User Setup Required

None.

## Next Phase Readiness

Plan 79-02 can use the receipt as current read-only evidence. Any remote changes remain unapproved. Resolve the absent current-main mandatory evidence and branch-protection context mismatch through the project's exact approval boundary before claiming main readiness.

## Self-Check: PASSED

- All four plan deliverables and this summary exist.
- The inventory verifier passed and reported `unknown` readiness for the captured main SHA.
- All six task-scoped commits are present after the plan's recorded base commit.

---
*Phase: 79-adopter-ready-closeout*
*Completed: 2026-09-30*
