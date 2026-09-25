---
phase: 74-clean-room-package-consumer
plan: 03
subsystem: testing
tags: [hex, installer, package-consumer, compatibility]
requires: [74-01, 74-02]
provides:
  - Controlled missing-public-file negative control against an isolated artifact copy.
  - Exact generated-file hash and installer receipt goldens for a fresh consumer.
  - Prior scaffold preservation, callback compatibility and explicit force behavior checks.
affects: [74-04]
requirements-completed: []
actuals:
  tasks: 3
  commits: 1
tech-stack:
  added: [installer contract profile, generated tree golden]
  patterns: [isolated package mutation, deterministic installer receipt, frozen adopter scaffold]
key-files:
  created:
    - test/fixtures/package_consumer/golden/fresh_files.sha256
    - test/fixtures/package_consumer/golden/fresh_receipt.txt
    - test/fixtures/package_consumer/prior_scaffold/config/config.exs
    - test/fixtures/package_consumer/prior_scaffold/lib/package_consumer/relyra/connections.ex
    - test/fixtures/package_consumer/prior_scaffold/lib/package_consumer/relyra/user_mapper.ex
    - test/fixtures/package_consumer/prior_scaffold/lib/package_consumer_web/router.ex
  modified:
    - scripts/check_clean_room_consumer.sh
    - test/fixtures/package_consumer/consumer/smoke/signed_acs.exs
requirements-addressed: [PKG-02, PKG-03, PKG-06]
completed: 2026-09-25
status: complete
---

# Phase 74 Plan 03: Installer Contract Summary

The `contracts` profile now runs an isolated omission control, exact fresh-install file and receipt checks, and a prior-scaffold compatibility check. The omission control removes only `lib/relyra/testing.ex` from a copy of the unpacked artifact, compiles a clean-room consumer against that copy, and accepts only the exact missing-file marker after confirming the public module is unavailable, private support is unavailable, and checkout paths are absent.

Fresh installation is compared against a sorted path/hash manifest and exact installer receipt, including one router insertion. The frozen prior scaffold contains adopter-edited resolver and mapper callbacks, preserved configuration, and an already-injected route. An ordinary installer rerun preserves all four files byte-for-byte; warnings-as-errors compilation and signed ACS use the preserved callbacks and router to produce the expected receipt and redirect. A separate forced copy proves only resolver/mapper outputs are overwritten and match the fresh generated hashes.

## Task Commits

1. **Tasks 1–3: Add omission, fresh-golden and prior-scaffold contracts** — `97d0b26`

## Verification

- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 scripts/check_clean_room_consumer.sh --profile contracts` — passed all omission, fresh and prior cases.
- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 scripts/check_clean_room_consumer.sh --profile full` — passed signed ACS, artifact provenance, support exclusion, migrations, persistent adapters, race and rerun checks.
- Bash syntax validation — passed.
- `mix format --check-formatted` for the modified Elixir smoke and fixtures — passed after formatting the prior config fixture.
- `git diff --check` — passed.

## Deviations

- Plan 74-03's callback contract needed the existing signed ACS smoke to select the prior scaffold resolver and mapper when the prior profile runs. Added an environment-controlled choice that leaves the ordinary full profile using its original proof adapters.
- The first prior fixture run showed its router did not represent an already-installed scaffold. Added the shipped route marker to the frozen fixture so the ordinary rerun verifies the installer's `already present` path.
- Commit `97d0b26` reverted interim PKG-02 and PKG-04 requirement checkmarks while Phase 74 was still active. The requirements remain pending until the complete phase closes; Phase 74 closeout owns their final transition.

## Next Plan

Proceed to Plan 74-04, which owns the remaining package-profile and phase-level closure checks.

## Self-Check: PASSED

- All declared Plan 74-03 artifacts exist.
- Task implementation commit `97d0b26` is reachable in Git history.
- The full contracts profile and full consumer profile passed.
