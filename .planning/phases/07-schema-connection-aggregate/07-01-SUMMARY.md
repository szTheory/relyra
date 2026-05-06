---
phase: 07-schema-connection-aggregate
plan: 07-01
subsystem: ecto-test-harness
tags: [ecto, test-harness, migrations, validation]
requires:
  - phase: 07-01
    provides: test-only Repo wiring, migration helpers, and validation contract
provides:
  - test-only Postgres Repo configuration for Phase 07 integration tests
  - deterministic migration bootstrap and table reset helpers
  - a phase validation contract with per-task smoke commands
affects: [phase-07-foundation, requirement-tracking]
tech-stack:
  added: [Ecto.Adapters.SQL.Sandbox, Ecto.Migrator]
  patterns:
    - test-only host-shaped Repo instead of a library-owned production Repo
    - migration bootstrap via shared ExUnit case template
key-files:
  created:
    - .planning/phases/07-schema-connection-aggregate/07-01-SUMMARY.md
    - config/test.exs
    - test/support/ecto_test_repo.ex
    - test/support/migration_case.ex
  modified:
    - .formatter.exs
    - .planning/phases/07-schema-connection-aggregate/07-VALIDATION.md
key-decisions:
  - "Keep the Repo test-only and configured through `config/test.exs` so the library does not own a production Repo."
  - "Bootstrap migrations through a reusable case template that resets storage and truncates tables between integration tests."
  - "Publish the phase validation matrix up front so every later slice has a bounded smoke command."
requirements-completed: [CFG-01]
duration: inline verification
completed: 2026-05-05
---

# Phase 07 Plan 01: Ecto Test Harness and Validation Contract Summary

Phase 07 now has the Wave 0 infrastructure it needed before aggregate persistence could be trusted: a real Ecto SQL test Repo, deterministic migration helpers, and a validation contract that keeps later verification fast and explicit.

## Performance

- **Duration:** inline verification
- **Completed:** 2026-05-05
- **Tasks:** 2
- **Files modified:** 5 primary Phase 07 artifacts

## Accomplishments

- Added `config/test.exs` with test-only Postgres wiring, `Ecto.Adapters.SQL.Sandbox`, binary-id migration defaults, and environment-driven connection settings.
- Added `Relyra.TestSupport.EctoTestRepo` as a minimal host-shaped Repo for migration and integration tests.
- Added `Relyra.TestSupport.MigrationCase` to create/reset storage, run canonical migrations, and truncate Phase 07 tables between tests.
- Published `07-VALIDATION.md` with a per-task verification matrix, Wave 0 requirements, and sub-30-second smoke guidance for the phase.

## Verification Results

- `mix format --check-formatted`
- `mix compile --warnings-as-errors`
- `mix test test/relyra/connection_test.exs --warnings-as-errors`

All passed during phase execution verification.

## Deviations from Plan

- Existing optional Ecto dependencies were reused; no dependency churn was needed to land the test harness.

## Issues Encountered

- The phase implementation already existed in the working tree when execution began, so this run verified the harness in place and backfilled the execution summary artifact afterward.

## Self-Check

PASSED
