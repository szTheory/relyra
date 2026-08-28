---
phase: 64-public-testing-api-package-boundary
plan: 04
subsystem: testing
tags: [elixir, hex, package-boundary, public-api, release-parity]

requires:
  - phase: 64-public-testing-api-package-boundary
    provides: Public `Relyra.Testing` files from Plans 64-01 through 64-03
provides:
  - Release parity unit coverage for public testing file inclusion
  - Package config proof that `lib/relyra/testing*` ships and `lib/relyra/test_support*` stays excluded
  - Local unpacked Hex package artifact proof for the same package boundary
affects: [phase-65-documentation-truth, package-parity, public-testing-api]

tech-stack:
  added: []
  patterns:
    - Package-boundary tests inspect both package config and unpacked local Hex artifacts
    - Public testing file assertions reuse existing release parity filtering instead of adding a second filter

key-files:
  created:
    - .planning/phases/64-public-testing-api-package-boundary/64-04-SUMMARY.md
  modified:
    - test/mix/tasks/verify_release_parity_test.exs

key-decisions:
  - "Package proof stays on the existing `mix.exs` package whitelist and `ReleaseParity.filter_package_paths/1` model."
  - "The artifact-level proof intentionally builds and unpacks a local Hex package, even though it is slower than unit-only checks."

patterns-established:
  - "Package boundary tests assert `lib/relyra/testing*` inclusion and `lib/relyra/test_support*` exclusion from unpacked package files."

requirements-completed: [TEST-01, PKG-01]

duration: 3min
completed: 2026-06-16
---

# Phase 64 Plan 04: Package Parity Proof Summary

**Release parity tests now prove public `Relyra.Testing` files ship while private `Relyra.TestSupport` files remain outside package artifacts.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-06-16T02:47:27Z
- **Completed:** 2026-06-16T02:49:37Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Extended release parity unit tests so `ReleaseParity.filter_package_paths/1` keeps all five public testing files and excludes representative private test support paths.
- Added a package config test proving `Mix.Project.config()[:package][:files]` includes `lib/relyra/testing.ex`, `fixture.ex`, `signer.ex`, `adapters.ex`, and `phoenix.ex` while containing no `test_support` path.
- Added a local package artifact test that runs `mix hex.build --unpack` into an ExUnit temp directory, inspects unpacked files, and proves the packaged artifact includes public testing files with no `lib/relyra/test_support*` leak.

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend release parity unit tests for public testing files** - `d75bcc7` (test)
2. **Task 2: Add local unpacked package proof** - `6ca2616` (test)

## Files Created/Modified

- `test/mix/tasks/verify_release_parity_test.exs` - Adds public testing path constants, filter/package config assertions, and local unpacked Hex package proof.
- `.planning/phases/64-public-testing-api-package-boundary/64-04-SUMMARY.md` - Execution summary and verification record.

## Decisions Made

- Kept package filtering unchanged because the existing `package_lib_files/0` and `ReleaseParity.filter_package_paths/1` mechanisms already include `testing*` and exclude `test_support*`.
- Retained the slower local package build/unpack test because package-boundary evidence must inspect artifact contents, not only source-tree paths or `package.files` configuration.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first Task 1 test run failed because the expected list preserved declaration order while `ReleaseParity.filter_package_paths/1` returns sorted paths. The test expectation was corrected to compare against `Enum.sort(@public_testing_paths)`; no production filtering change was needed.

## Verification

- `mix test test/mix/tasks/verify_release_parity_test.exs --warnings-as-errors` - PASS, 20 tests, 0 failures, 1 excluded integration canary.
- `mix format --check-formatted test/mix/tasks/verify_release_parity_test.exs` - PASS.
- `rg -n "lib/relyra/testing\\.ex|lib/relyra/testing/fixture\\.ex|lib/relyra/testing/signer\\.ex|lib/relyra/testing/adapters\\.ex|lib/relyra/testing/phoenix\\.ex|Enum\\.any\\?\\(package_files, &String\\.contains\\?\\(&1, \\\"test_support\\\"\\)\\)" test/mix/tasks/verify_release_parity_test.exs` - PASS, required source assertions present.
- `rg -n "System\\.cmd\\(\\\"mix\\\", \\[\\\"hex\\.build\\\", \\\"--unpack\\\", \\\"-o\\\", tmp\\]|lib/relyra/test_support|@public_testing_paths|unpacked_paths" test/mix/tasks/verify_release_parity_test.exs` - PASS, local package artifact proof and exclusion assertion present.
- `mix hex.build --unpack -o /tmp/relyra_phase64_pkg_check` plus packaged file-list inspection - PASS: unpacked package contains `lib/relyra/testing.ex`, `lib/relyra/testing/adapters.ex`, `lib/relyra/testing/fixture.ex`, `lib/relyra/testing/phoenix.ex`, and `lib/relyra/testing/signer.ex`; no `lib/relyra/test_support*` files are present.

## Known Stubs

None. Stub scan only matched existing empty-list JSON assertions in release parity tests; these are expected test fixtures, not placeholder behavior.

## Threat Flags

None - the package-boundary information-disclosure surface was covered by the plan threat model.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 65 can update adopter-facing documentation knowing the Hex package boundary is now tested at the filter, package config, and local unpacked artifact levels.

## Self-Check: PASSED

- Modified file exists: `test/mix/tasks/verify_release_parity_test.exs`.
- Summary file exists: `.planning/phases/64-public-testing-api-package-boundary/64-04-SUMMARY.md`.
- Task commits exist: `d75bcc7`, `6ca2616`.
- No accidental file deletions were detected in task commits.
- Local package artifact proof inspected unpacked package contents, not source-tree existence alone.

---
*Phase: 64-public-testing-api-package-boundary*
*Completed: 2026-06-16*
