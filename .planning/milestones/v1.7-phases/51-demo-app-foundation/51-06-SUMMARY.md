---
phase: 51-demo-app-foundation
plan: 06
subsystem: packaging
tags: [hex-package, package-boundary, demo-exclusion, verification-script]

requires:
  - phase: 51-01
    provides: repo-local demo app with local Relyra path dependency
provides:
  - Executable package-exclusion proof script
  - Verification that demo/ledger_loop remains runnable from the repo
  - Verification that unpacked Hex package contents exclude demo paths
affects: [phase-51, packaging, release]

tech-stack:
  added: []
  patterns:
    - Package boundary proof through mix hex.build --unpack
    - Root package whitelist preserved as the source of Hex inclusion truth

key-files:
  created:
    - scripts/check_demo_package_exclusion.sh
  modified: []

key-decisions:
  - "Preserved the existing root mix.exs package files whitelist; no demo paths or wildcards were added."
  - "Recorded the whitelist/package proof as an empty verification commit because Task 2 required no source changes."

patterns-established:
  - "Repository-local demo artifacts are verified by unpacking the Hex package rather than relying on ignore-file assumptions."
  - "Demo app runnability and package exclusion are checked together so the repo-local proof cannot drift into release contents."

requirements-completed: [DEMO-01, DEMO-02]

duration: 7 min
completed: 2026-06-12
---

# Phase 51 Plan 06: Package Boundary Proof Summary

**Executable Hex unpack check proves LedgerLoop stays repo-local while the publishable Relyra package excludes demo paths**

## Performance

- **Duration:** 7 min
- **Started:** 2026-06-12T15:52:42Z
- **Completed:** 2026-06-12T15:55:35Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Added `scripts/check_demo_package_exclusion.sh` as an executable package-boundary proof.
- Verified the script builds and unpacks the Hex package under `/tmp/relyra-package-check` and fails on any `*/demo/*` path.
- Verified `demo/ledger_loop` still compiles against the local `{:relyra, path: "../.."}` dependency while the root package whitelist excludes demo paths.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add package exclusion check script** - `d6c42c6` (`test`)
2. **Task 2: Preserve root whitelist and prove repo-local runnability** - `9df306f` (`test`, empty verification commit)

**Plan metadata:** this summary is committed in the follow-up `docs(51-06)` metadata commit.

## Files Created/Modified

- `scripts/check_demo_package_exclusion.sh` - Repo-root script that verifies `demo/ledger_loop/mix.exs`, checks the local path dependency, unpacks the Hex package, and fails if unpacked contents include `demo/`.

## Decisions Made

- Did not modify root `mix.exs`; the existing `package/0` whitelist already excludes `demo`, `demo/ledger_loop`, `"."`, `"*"`, and wildcard package expansion.
- Did not add root demo orchestration or CI aliases; those remain Phase 55 scope.

## Deviations from Plan

None - plan executed exactly as written.

---

**Total deviations:** 0 auto-fixed
**Impact on plan:** No scope changes.

## Issues Encountered

- Root `mix test --warnings-as-errors` emitted an existing grouped-clause warning from `test/support/keycloak_adoption.ex`, which is in unrelated dirty worktree changes, but the command exited 0 with `739 tests, 0 failures`.

## User Setup Required

None - no external service configuration required.

## Verification

- `test -x scripts/check_demo_package_exclusion.sh`
- `grep -q "mix hex.build --unpack --output /tmp/relyra-package-check" scripts/check_demo_package_exclusion.sh`
- `grep -q "find /tmp/relyra-package-check" scripts/check_demo_package_exclusion.sh`
- `grep -q "demo package exclusion: ok" scripts/check_demo_package_exclusion.sh`
- `! rg -n "hex\\.publish|scripts/demo|ci\\.demo_app" scripts/check_demo_package_exclusion.sh`
- `! grep -nE '"demo"|demo/ledger_loop|"[.]"|"[*]"' mix.exs`
- `scripts/check_demo_package_exclusion.sh` -> `demo package exclusion: ok`
- `cd demo/ledger_loop && mix compile --warnings-as-errors`
- `mix format --check-formatted`
- `mix test --warnings-as-errors` -> `739 tests, 0 failures (10 excluded)`

## Self-Check: PASSED

- Key file exists on disk and is executable.
- `git log --oneline --all --grep="51-06"` returns both task commits.
- All task acceptance criteria and plan-level verification commands passed.

## Next Phase Readiness

Ready for Wave 3 health/readiness probes, route tests, and workspace content plans.

---
*Phase: 51-demo-app-foundation*
*Completed: 2026-06-12*
