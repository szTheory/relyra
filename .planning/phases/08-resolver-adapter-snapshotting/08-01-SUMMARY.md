---
phase: 08-resolver-adapter-snapshotting
plan: 08-01
subsystem: resolver-contract
tags: [resolver, runtime-snapshot, diagnostics, compatibility]
requires:
  - phase: 08-01
    provides: canonical runtime resolver contract and bounded error taxonomy
provides:
  - public resolver contract pinned to `%Relyra.Connection{}`
  - canonical `idp_certificates` runtime field with compatibility `cert_chain`
  - bounded resolver diagnostic taxonomy for default and invalid adapters
affects: [phase-08-foundation, phoenix-request-tests]
tech-stack:
  patterns:
    - thin public behaviour returning runtime structs, not persistence maps
    - precise resolver detail fields under a small top-level error taxonomy
key-files:
  created:
    - .planning/phases/08-resolver-adapter-snapshotting/08-01-SUMMARY.md
  modified:
    - lib/relyra/connection_resolver.ex
    - lib/relyra/connection_resolver/default.ex
    - test/relyra/connection_test.exs
    - test/phoenix/login_controller_test.exs
    - test/support/fake_connection_resolver.ex
key-decisions:
  - "Normalize resolver success values into `%Relyra.Connection{}` at the public seam so downstream runtime consumers never finish hydration themselves."
  - "Treat `idp_certificates` as the canonical trust field and keep `cert_chain` only as explicit compatibility glue."
  - "Collapse resolver misconfiguration and invalid-adapter behavior into stable top-level types with safe `details.reason` metadata."
requirements-completed: [CFG-02]
duration: inline verification
completed: 2026-05-05
---

# Phase 08 Plan 01: Resolver Contract and Diagnostics Summary

Plan 08-01 locked the public resolver seam before the persisted adapter work: callers now receive a normalized `%Relyra.Connection{}` runtime snapshot, certificate naming is canonicalized around `idp_certificates`, and resolver failures stay inside a small typed taxonomy with structured safe details.

## Performance

- **Duration:** inline verification
- **Completed:** 2026-05-05
- **Tasks:** 2
- **Files modified:** 5 primary resolver/test artifacts

## Accomplishments

- Updated `Relyra.ConnectionResolver` to document and enforce `%Relyra.Connection{}` as the public return type, including map-to-struct normalization for compatibility adapters.
- Added canonical certificate normalization so resolver outputs always expose `idp_certificates`, with `cert_chain` populated only as migration glue.
- Reworked resolver error handling so adapter absence, invalid tuples, and dispatch failures map into bounded `:resolver_misconfigured` or `:resolver_failed` results with explicit `details.reason`.
- Aligned the default resolver and fake Phoenix resolver fixture with the new taxonomy and canonical runtime snapshot contract.
- Expanded resolver-focused tests to assert the public struct shape, canonical certificate field, and structured failure details.

## Verification Results

- `mix format --check-formatted`
- `mix compile --warnings-as-errors`
- `mix test test/relyra/connection_test.exs test/phoenix/login_controller_test.exs --warnings-as-errors`

All passed during phase execution verification.

## Deviations from Plan

- The public wrapper still accepts legacy map-returning adapters, but it normalizes them into the canonical runtime struct at the boundary rather than exposing raw maps to callers.

## Issues Encountered

- The phase implementation already existed in the working tree when execution began, so this run verified the slice in place and backfilled the execution summary afterward.

## Self-Check

PASSED
