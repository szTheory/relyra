---
phase: 27-adopter-onboarding-polish-and-case-studies
plan: 03
subsystem: docs
tags: [docs, proof, ci, mix-task, onboarding]
requires:
  - phase: 27-adopter-onboarding-polish-and-case-studies
    provides: canonical onboarding spine, authoritative provider runbooks, and case studies
provides:
  - drift-checkable batteries-included proof artifact
  - human-facing proof journey guide with explicit receipts
  - focused docs CI lane covering the install path, FakeIdP proof, and artifact drift check
affects: [guides, mix-tasks, test-suite, ci, onboarding]
tech-stack:
  added: [mix-task]
  patterns: [generated-proof-artifact, receipt-driven-guide, narrow-ci-lane]
key-files:
  created:
    - BATTERIES_INCLUDED.md
    - guides/batteries_included.md
    - lib/mix/tasks/relyra.batteries_included.ex
    - test/mix/tasks/relyra_batteries_included_test.exs
  modified:
    - mix.exs
    - test/mix/relyra_install_test.exs
    - test/test_support_demo_test.exs
key-decisions:
  - "The batteries-included claim is backed by a generated artifact plus a human guide, not prose alone."
  - "The focused docs proof lane stays narrow and runs through `mix ci.docs`."
  - "Provider scope remains limited to Okta, Microsoft Entra ID, and Google Workspace in both the guide and the generated artifact."
patterns-established:
  - "Generated docs use `--output` / `--check` drift detection."
  - "Day-1 proof starts local-first with FakeIdP before any hosted IdP branch."
requirements-completed: [DOCS-01]
duration: 44min
completed: 2026-05-08
---

# Phase 27 Plan 03: Batteries Included Proof Summary

**A generated batteries-included artifact, a human-facing proof journey, and a narrow CI lane that keeps the Day-1 adoption claim executable.**

## Performance

- **Duration:** 44 min
- **Started:** 2026-05-08T15:11:00Z
- **Completed:** 2026-05-08T15:55:00Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added `mix relyra.batteries_included` with deterministic `--output` and `--check` support, plus a checked-in `BATTERIES_INCLUDED.md` artifact.
- Added `guides/batteries_included.md` as the human-facing proof journey that walks install, local FakeIdP proof, one provider branch, and operator follow-ons with explicit receipts.
- Strengthened the install and FakeIdP demo tests and wired a narrow `mix ci.docs` alias into `ci.verify`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add the drift-checkable batteries-included evidence artifact** - `0b1ffc9` (feat)
2. **Task 2: Write the human-facing proof guide and strengthen the local-first proof lane** - `0cfd0de` (docs)

## Files Created/Modified

- `lib/mix/tasks/relyra.batteries_included.ex` - Generator/checker for `BATTERIES_INCLUDED.md`.
- `test/mix/tasks/relyra_batteries_included_test.exs` - Output and drift-check tests for the new Mix task.
- `BATTERIES_INCLUDED.md` - Generated claim-to-proof map for the batteries-included posture.
- `guides/batteries_included.md` - Human-facing proof journey with explicit receipts.
- `test/mix/relyra_install_test.exs` - Installer receipt coverage for the blessed scaffold path.
- `test/test_support_demo_test.exs` - Local FakeIdP-first receipt coverage.
- `mix.exs` - `ci.docs` alias plus `ci.verify` integration.

## Decisions Made

- The batteries-included claim is proved with both a generated artifact and a narrative guide so the repo has human and machine-verifiable truth surfaces.
- `ci.docs` stays intentionally narrow: it checks the guide/artifact files, runs the focused task/install/demo tests, and drift-checks the generated artifact.
- The generated artifact preserves the canonical provider scope order: Okta, Microsoft Entra ID, Google Workspace.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Parallel proof commands briefly contended on the Mix build directory and test migration setup. Re-running those commands sequentially resolved the issue; no repository changes were required.

## User Setup Required

None - all receipts run inside the repository.

## Verification

- `mix test test/mix/tasks/relyra_batteries_included_test.exs --warnings-as-errors`
- `mix relyra.batteries_included --check`
- `mix test test/mix/relyra_install_test.exs test/test_support_demo_test.exs --warnings-as-errors`
- `mix ci.docs`

## Next Phase Readiness

- Phase 27 now has a complete Day-1 narrative, provider branch, case studies, and executable proof lane.
- The milestone can treat adopter onboarding as backed by checked-in receipts rather than soft documentation claims.

## Self-Check: PASSED

- Found task commit `0b1ffc9`
- Found task commit `0cfd0de`
- `BATTERIES_INCLUDED.md` drift-checks cleanly
- `mix ci.docs` passes

---
*Phase: 27-adopter-onboarding-polish-and-case-studies*
*Completed: 2026-05-08*
