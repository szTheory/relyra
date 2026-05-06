---
phase: 08-resolver-adapter-snapshotting
plan: 08-03
subsystem: request-time-consumers
tags: [phoenix, metadata, login, validation, runtime-purity]
requires:
  - phase: 08-02
    provides: persisted runtime snapshots and typed resolver outcomes
provides:
  - login and metadata flow coverage against the canonical resolver snapshot
  - runtime certificate precedence favoring `idp_certificates`
  - shared fake resolver fixture proving one request-time boundary
affects: [phoenix-consumers, protocol-validation]
tech-stack:
  patterns:
    - shared request-time resolver fixture across Phoenix consumers
    - canonical runtime certificate precedence in protocol validation
key-files:
  created:
    - .planning/phases/08-resolver-adapter-snapshotting/08-03-SUMMARY.md
    - test/phoenix/metadata_controller_test.exs
  modified:
    - lib/relyra/protocol/validation_pipeline.ex
    - test/phoenix/login_controller_test.exs
    - test/support/fake_connection_resolver.ex
key-decisions:
  - "Prefer `idp_certificates` before `cert_chain` in runtime validation consumers so the canonical snapshot contract is exercised end-to-end."
  - "Use one shared fake resolver fixture for login and metadata flows to prevent request-time snapshot drift."
  - "Keep typed resolver failures visible at the controller boundary instead of collapsing them into opaque errors."
requirements-completed: [CFG-02]
duration: inline verification
completed: 2026-05-05
---

# Phase 08 Plan 03: Login, Metadata, and Boundary Purity Summary

Plan 08-03 closed the phase by wiring the canonical runtime snapshot through request-time consumers. Login, metadata, and protocol validation now agree on the same resolver output shape and certificate precedence rules.

## Performance

- **Duration:** inline verification
- **Completed:** 2026-05-05
- **Tasks:** 3
- **Files modified:** 4 primary consumer artifacts

## Accomplishments

- Updated `Relyra.Protocol.ValidationPipeline` so runtime certificate lookup prefers `idp_certificates` and uses `cert_chain` only as compatibility fallback.
- Replaced the inline login test resolver with the shared `Relyra.TestSupport.FakeConnectionResolver`, which emits `%Relyra.Connection{}` and canonical certificate data.
- Added `test/phoenix/metadata_controller_test.exs` to prove the metadata route resolves the same canonical runtime snapshot and preserves typed resolver failures.
- Tightened login and metadata controller assertions so `connection_unavailable` remains visible at the HTTP boundary instead of being flattened into generic controller failures.

## Verification Results

- `mix format --check-formatted`
- `mix compile --warnings-as-errors`
- `mix test test/phoenix/login_controller_test.exs test/phoenix/metadata_controller_test.exs --warnings-as-errors`
- `mix test test/relyra/ecto/ecto_connection_resolver_test.exs test/phoenix/login_controller_test.exs test/phoenix/metadata_controller_test.exs --warnings-as-errors`

All passed during phase execution verification.

## Deviations from Plan

- Metadata-path coverage uses the shared fake resolver fixture rather than the persisted Ecto resolver directly; the cross-flow verification suite compensates by running the persisted resolver tests alongside both controller suites.

## Issues Encountered

- The phase implementation already existed in the working tree when execution began, so this run verified the slice in place and backfilled the execution summary afterward.

## Self-Check

PASSED
