---
phase: 43-hex-publish-prep-version-bump-changelog-backfill
plan: 01
subsystem: infra
tags: [hex, release-please, changelog, semver, mix]

requires:
  - phase: 41-pre-publish-hygiene-tech-debt-sweep-security-hardening
    provides: Clean prod tarball (test_support excluded) ready for 1.4.0 publish
  - phase: 42-stepwise-login-trace-liveview
    provides: Login trace UI/CLI shipped in tree before version bump
provides:
  - mix.exs @version 1.4.0 and release-please manifest baseline
  - getting_started.md install pin ~> 1.4
  - Hand-written CHANGELOG [1.4.0] and [1.3.0] milestone sections
affects:
  - 44-release-please-diagnosis-hex-publish
  - 45-post-publish-parity

tech-stack:
  added: []
  patterns:
    - "Single atomic release-prep commit touching exactly four version/changelog files"
    - "Single-jump 1.2.0 → 1.4.0 with [1.3.0] as historical archaeology only"

key-files:
  created: []
  modified:
    - mix.exs
    - .release-please-manifest.json
    - guides/getting_started.md
    - CHANGELOG.md

key-decisions:
  - "No git tag v1.4.0 or mix hex.publish — deferred to Phase 44 per D-02"
  - "One commit packages all four release-prep files per D-09"

patterns-established:
  - "Keep-a-Changelog narrative sections for milestone backfill (not release-please commit dumps)"

requirements-completed: [PUB-01, PUB-02]

duration: 8min
completed: 2026-05-27
---

# Phase 43 Plan 01 Summary

**Version sources bumped to 1.4.0 with hand-written CHANGELOG backfill for v1.3/v1.4 milestones — Phase 44-ready, no tag or Hex publish**

## Performance

- **Duration:** 8 min
- **Started:** 2026-05-27T20:15:00Z
- **Completed:** 2026-05-27T20:23:00Z
- **Tasks:** 5
- **Files modified:** 4

## Accomplishments

- `mix.exs` and `.release-please-manifest.json` aligned at `@version "1.4.0"`
- `guides/getting_started.md` install pin updated from `~> 0.1.0` to `~> 1.4`
- `[1.4.0]` CHANGELOG section with single-jump rationale, SLO/trace/TD milestone bullets
- `[1.3.0]` historical section for Advanced Federation (ENC-01, AUTHN-01, DOCS-02/03)
- All gates green: release hardening, `mix ci.release`, full suite 712/0

## Task Commits

Plan specified one atomic release-prep commit (D-09):

1. **All tasks: release-prep batch** - `efdc21c` (chore(release))

**Plan metadata:** pending docs commit

## Files Created/Modified

- `mix.exs` - @version 1.4.0
- `.release-please-manifest.json` - release-please baseline 1.4.0
- `guides/getting_started.md` - canonical install pin ~> 1.4
- `CHANGELOG.md` - [1.4.0] and [1.3.0] sections above [1.2.0]; [Unreleased] preserved

## Decisions Made

None - followed plan as specified. Tag and Hex publish explicitly deferred to Phase 44.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 44 can run release-please automation against coherent 1.4.0 version sources
- `git tag -l v1.4.0` empty (confirmed)
- No manual `mix hex.publish` executed

## Self-Check: PASSED

- Version coherence greps: all pass
- `mix test test/release/release_hardening_test.exs --warnings-as-errors`: 4/0
- `mix ci.release`: exit 0
- `mix test --warnings-as-errors`: 712/0
- `git tag -l v1.4.0`: empty
- Commit `efdc21c` contains exactly the four release-prep files

---
*Phase: 43-hex-publish-prep-version-bump-changelog-backfill*
*Completed: 2026-05-27*
