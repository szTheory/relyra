---
phase: 07-schema-connection-aggregate
plan: 07-03
subsystem: persistence-workflow
tags: [ecto, persistence-api, readiness, runtime-contract]
requires:
  - phase: 07-02
    provides: aggregate schemas, migrations, and constraint coverage
provides:
  - minimal host-Repo persistence API for create, update, enable, and disable
  - explicit draft-vs-runtime-ready validation split
  - runtime connection contract carrying public connection_id separately from DB identity
affects: [phase-07-completion, phase-08-resolver-readiness]
tech-stack:
  added: [Ecto-backed persistence adapter]
  patterns:
    - opts[:repo]-driven adapter boundary
    - typed validation errors through Relyra.Error
    - runtime struct remains storage-agnostic
key-files:
  created:
    - .planning/phases/07-schema-connection-aggregate/07-03-SUMMARY.md
    - lib/relyra/ecto/connections.ex
    - test/relyra/ecto/connection_record_test.exs
    - test/relyra/ecto/runtime_readiness_test.exs
    - test/relyra/connection_test.exs
  modified:
    - lib/relyra/ecto/connection.ex
    - lib/relyra/connection.ex
key-decisions:
  - "Expose only a minimal internal persistence API in Phase 07 and require callers to pass `opts[:repo]`."
  - "Keep draft persistence separate from publish/runtime-ready validation so incomplete rows can exist safely."
  - "Add `connection_id` to `%Relyra.Connection{}` now so runtime identity does not collapse into the internal PK later."
requirements-completed: [CFG-01]
duration: inline verification
completed: 2026-05-05
---

# Phase 07 Plan 03: Persistence Workflow and Runtime Contract Summary

Phase 07 now proves the record workflow end-to-end without leaking Ecto structs into runtime code: callers can create, update, enable, and disable connection records through an internal persistence adapter, and runtime-readiness remains a separate explicit gate.

## Performance

- **Duration:** inline verification
- **Completed:** 2026-05-05
- **Tasks:** 3
- **Files modified:** 7 primary persistence and test artifacts

## Accomplishments

- Added `Relyra.Ecto.Connections` with `create/2`, `update/3`, `enable/2`, and `disable/2` operations that require `opts[:repo]` and return typed `Relyra.Error` failures.
- Split aggregate validation between draft persistence and runtime/publish readiness in `Relyra.Ecto.Connection`, including enabled status, required runtime fields, and certificate inventory checks.
- Updated `%Relyra.Connection{}` so the runtime contract carries `connection_id` independently from the internal persistence id.
- Added integration and unit tests for the persistence workflow, runtime-readiness rejection paths, and the public-vs-internal identity contract.

## Verification Results

- `mix format --check-formatted`
- `mix compile --warnings-as-errors`
- `mix test test/relyra/ecto/connection_record_test.exs test/relyra/ecto/runtime_readiness_test.exs test/relyra/connection_test.exs --warnings-as-errors`

All passed during phase execution verification.

## Deviations from Plan

- None material. Resolver hydration, metadata refresh, and rollover semantics remain out of scope as planned.

## Issues Encountered

- The phase implementation already existed in the working tree when execution began, so this run verified behavior in place and recorded the execution artifact afterward.

## Self-Check

PASSED
