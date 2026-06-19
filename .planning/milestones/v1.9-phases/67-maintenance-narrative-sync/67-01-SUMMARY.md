---
phase: 67-maintenance-narrative-sync
plan: "01"
subsystem: documentation
tags: [maintenance, documentation, public-testing, provider-taxonomy, generated-docs]

requires:
  - phase: 64-public-testing-api-package-boundary
    provides: Public `Relyra.Testing` package boundary and fixture API truth
  - phase: 65-documentation-truth
    provides: Adopter-facing public testing narrative
  - phase: 66-demo-fakeidp-disposition
    provides: Retained demo-local FakeIdP disposition
provides:
  - MAINT-01 narrative drift cleanup for public testing and provider taxonomy copy
  - Regenerated Batteries Included proof artifact from source generator wording
affects: [README, JTBD gap map, generic SAML recipe, Batteries proof]

tech-stack:
  added: []
  patterns:
    - Source-generated documentation is edited at the generator first and regenerated with `mix relyra.batteries_included`
    - Public local proof wording uses `Relyra.Testing`; scoped FakeIdP wording remains demo-local only

key-files:
  created:
    - .planning/phases/67-maintenance-narrative-sync/67-01-SUMMARY.md
  modified:
    - README.md
    - docs/jtbd_gap_map.md
    - guides/recipes/generic_saml.md
    - lib/mix/tasks/relyra.batteries_included.ex
    - BATTERIES_INCLUDED.md

key-decisions:
  - "Kept Phase 67 Plan 01 to narrow narrative cleanup; no public API, protocol, parser, replay, audit, crypto, release, tag, or Hex command changes were made."
  - "Preserved scoped LedgerLoop FakeIdP language in `guides/fake_idp_demo.md` and updated only stale unscoped maintainer/adopter wording."

patterns-established:
  - "Generated proof artifacts must be regenerated from their Mix task source after wording changes."

requirements-completed: [MAINT-01]

duration: 4min
completed: 2026-06-19
status: complete
---

# Phase 67 Plan 01: Maintenance Narrative Sync Summary

**Public testing and provider taxonomy copy now matches the shipped `Relyra.Testing` and four-first-class-provider reality.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-19T14:22:04Z
- **Completed:** 2026-06-19T14:25:57Z
- **Tasks:** 2 completed
- **Files modified:** 6

## Accomplishments

- Replaced the remaining README generic-SAML "local TestSupport proof" wording with local `Relyra.Testing` proof wording.
- Refreshed the maintainer JTBD gap map to name public `Relyra.Testing` fixtures and remove the stale FakeIdP cleanup item now resolved by demo-local retention docs.
- Corrected the SiteMinder decoder note so it no longer misstates README's four first-class presets plus seven generic runbook families.
- Updated the Batteries Included generator sentence and regenerated `BATTERIES_INCLUDED.md` through `mix relyra.batteries_included`.

## Task Commits

| Task | Name | Commit | Files |
| --- | --- | --- | --- |
| 67-01-01 | Sync public testing and provider narrative drift | `27098a7` | `README.md`, `docs/jtbd_gap_map.md`, `guides/recipes/generic_saml.md` |
| 67-01-02 | Regenerate Batteries proof from source wording | `7b97c2f` | `lib/mix/tasks/relyra.batteries_included.ex`, `BATTERIES_INCLUDED.md` |

## Files Created/Modified

- `README.md` - Generic SAML runbook handoff now points to local `Relyra.Testing` proof.
- `docs/jtbd_gap_map.md` - Refresh date, Phoenix adopter local-proof wording, and optional-polish status updated for Phase 67 truth.
- `guides/recipes/generic_saml.md` - SiteMinder row no longer describes the README provider-family taxonomy incorrectly.
- `lib/mix/tasks/relyra.batteries_included.ex` - Generated intro sentence now names public testing fixture proof instead of a private test-support seam.
- `BATTERIES_INCLUDED.md` - Regenerated artifact matching the updated generator.
- `.planning/phases/67-maintenance-narrative-sync/67-01-SUMMARY.md` - Plan completion record.

## Decisions Made

- Followed the plan's narrow maintenance boundary and made wording-only changes.
- Did not edit `guides/jtbd_user_flows.md` because Scene 3 already lists Okta, Microsoft Entra ID, Google Workspace, and ADFS.
- Did not edit `guides/fake_idp_demo.md` because its FakeIdP language is explicitly scoped to demo-local test support.

## Verification

| Command | Outcome |
| --- | --- |
| `bash -lc 'if rg -n "local TestSupport proof|prove the path locally with.*FakeIdP|Case study FakeIdP reference cleanup|README lists seven SAML families" README.md docs/jtbd_gap_map.md guides/recipes/generic_saml.md; then exit 1; else exit 0; fi'` | PASS |
| `mix test test/docs/testing_api_drift_test.exs --warnings-as-errors` | PASS - 2 tests, 0 failures |
| `bash -lc 'if rg -n "test-support seam" lib/mix/tasks/relyra.batteries_included.ex BATTERIES_INCLUDED.md; then exit 1; else exit 0; fi'` | PASS |
| `mix relyra.batteries_included --check` | PASS |
| `mix test test/mix/tasks/relyra_batteries_included_test.exs --warnings-as-errors` | PASS - 4 tests, 0 failures |
| `mix ci.docs` | PASS |
| `mix format --check-formatted` | PASS |
| `mix qa` | PASS - 765 tests, 0 failures, 10 excluded |

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None in plan scope. The worktree had unrelated planning/CVE changes before or alongside this run; they were left unstaged and unchanged by these commits.

## Known Stubs

None. Stub scan of the created/modified plan files found only the existing `invalid != []` option parser guard in `lib/mix/tasks/relyra.batteries_included.ex`, which is not a placeholder or unwired UI/data stub.

## Threat Flags

None. This plan changed documentation wording plus an existing generated-docs Mix task sentence; it introduced no network endpoint, auth path, file access pattern, schema change, key material handling, or trust-boundary behavior.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

MAINT-01 narrative drift for Plan 67-01 is complete. Phase 67 can proceed to the CVE, CI/release, Phase 29, and seed-disposition plans without reopening public API or security-surface work.

## Self-Check: PASSED

- Found all owned modified files on disk: `README.md`, `docs/jtbd_gap_map.md`, `guides/recipes/generic_saml.md`, `lib/mix/tasks/relyra.batteries_included.ex`, and `BATTERIES_INCLUDED.md`.
- Found task commits `27098a7` and `7b97c2f` in git history.
- Verified `BATTERIES_INCLUDED.md` matches the generator with `mix relyra.batteries_included --check`.
- Verified no out-of-scope owned files remained unstaged after task commits.

---
*Phase: 67-maintenance-narrative-sync*
*Completed: 2026-06-19*
