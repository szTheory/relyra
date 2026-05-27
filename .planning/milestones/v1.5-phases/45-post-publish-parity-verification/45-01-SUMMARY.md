---
phase: 45-post-publish-parity-verification
plan: 01
subsystem: testing
tags: [hex, release, parity, mix-task]

requires: []
provides:
  - mix verify.release_parity task with Relyra package.files scope
  - Unit tests for pure parity functions without live Hex in CI
affects:
  - 45-02 verify-parity.sh wrapper and PARITY-RESULT.md

tech-stack:
  added: []
  patterns:
    - scrypath DNA path-set parity with Relyra package.files scope
    - Recursive dotfile-aware Hex unpack listing
    - test_support hard-fail before path diff

key-files:
  created:
    - lib/mix/tasks/verify.release_parity.ex
    - test/mix/tasks/verify_release_parity_test.exs
  modified:
    - test/test_helper.exs

key-decisions:
  - "Use File.ls recursive walk instead of Path.wildcard for Hex unpack — glob skips dotfiles like .formatter.exs"
  - "filter_package_paths/1 excludes test_support paths; assert_no_test_support!/1 halts with exit 2 on raw hex paths"
  - "Tag format v{version} (not scrypath-v prefix); env vars RELYRA_RELEASE_VERIFY_*"

patterns-established:
  - "Path-set parity gate: MapSet diff between git ls-tree and hex.package fetch unpack"
  - "Defense-in-depth test_support scan on published paths before diff"

requirements-completed: [PUB-04]

duration: 12min
completed: 2026-05-27
---

# Phase 45 Plan 01 Summary

**Release parity Mix task compares git tag vX.Y.Z paths to Hex tarball over full package.files scope with test_support hard-fail and unit-tested pure functions.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-05-27T17:20:00Z
- **Completed:** 2026-05-27T17:32:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Implemented `Mix.Tasks.Verify.ReleaseParity` with compute/2, parse_version!/1, retry_until!/4, render_json/4, filter_package_paths/1, assert_no_test_support!/1
- Fixed dotfile collection bug (Path.wildcard missed `.formatter.exs`; recursive File.ls walk resolves it)
- Live `mix verify.release_parity 1.4.0` exits 0 against published Hex 1.4.0

## Task Commits

1. **Task 1: Implement Mix.Tasks.Verify.ReleaseParity** - `7ca46c4` (feat)
2. **Task 2: Unit tests for verify.release_parity** - `9cd8197` (test)

## Files Created/Modified

- `lib/mix/tasks/verify.release_parity.ex` - PUB-04 core parity task
- `test/mix/tasks/verify_release_parity_test.exs` - Pure function unit tests
- `test/test_helper.exs` - Exclude :integration tag from default runs

## Self-Check: PASSED

- mix test test/mix/tasks/verify_release_parity_test.exs --warnings-as-errors: 17/0 (1 excluded)
- mix test --warnings-as-errors: 718/0
- mix verify.release_parity 1.4.0: exit 0
