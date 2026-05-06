---
phase: 08-resolver-adapter-snapshotting
plan: 08-02
subsystem: persisted-resolver-pipeline
tags: [ecto, resolver, snapshot, hydration, fail-closed]
requires:
  - phase: 08-01
    provides: canonical runtime resolver contract and bounded diagnostics
provides:
  - thin built-in `Relyra.ConnectionResolver.Ecto` adapter
  - internal aggregate loader separated from runtime snapshot hydration
  - fail-closed persisted resolver tests for readiness and repo misconfiguration
affects: [ecto-boundary, runtime-snapshot-normalization]
tech-stack:
  added:
    - Relyra.ConnectionResolver.Ecto
    - Relyra.Ecto.ConnectionLoader
    - Relyra.Ecto.ConnectionSnapshot
  patterns:
    - persistence loading below the public resolver boundary
    - single aggregate-to-runtime normalization authority
key-files:
  created:
    - .planning/phases/08-resolver-adapter-snapshotting/08-02-SUMMARY.md
    - lib/relyra/connection_resolver/ecto.ex
    - lib/relyra/ecto/connection_loader.ex
    - lib/relyra/ecto/connection_snapshot.ex
    - test/relyra/ecto/ecto_connection_resolver_test.exs
    - test/relyra/connection_snapshot_test.exs
  modified: []
key-decisions:
  - "Keep the built-in Ecto resolver responsible only for request-context orchestration and public error mapping."
  - "Reuse aggregate readiness checks in the loader instead of duplicating runtime validity logic in controllers or adapters."
  - "Hydrate persisted records into a runtime snapshot through one module that owns provider defaults and canonical certificate mapping."
requirements-completed: [CFG-02]
duration: inline verification
completed: 2026-05-05
---

# Phase 08 Plan 02: Ecto Resolver, Loader, and Snapshot Hydrator Summary

Plan 08-02 delivered the persisted resolver boundary itself: a thin built-in Ecto adapter, a dedicated aggregate loader, and a single hydrator that turns runtime-ready persisted records into normalized `%Relyra.Connection{}` snapshots.

## Performance

- **Duration:** inline verification
- **Completed:** 2026-05-05
- **Tasks:** 3
- **Files modified:** 5 primary persisted-resolver artifacts

## Accomplishments

- Added `Relyra.ConnectionResolver.Ecto` to read `connection_id`, require `opts[:repo]`, delegate to internal helpers, and keep public error mapping thin.
- Added `Relyra.Ecto.ConnectionLoader` as the persistence-only boundary for `Repo.get_by/2`, certificate preloads, runtime-readiness reuse, and fail-closed classification for draft, disabled, missing-field, missing-certificate, and repo-misconfigured cases.
- Added `Relyra.Ecto.ConnectionSnapshot` as the single normalization authority for provider defaults, runtime policy expansion, and canonical `idp_certificates` plus compatibility `cert_chain`.
- Added persisted resolver integration tests covering success, not-found, draft, disabled, missing runtime fields, missing certificates, invalid certificates, and repo-missing behavior.
- Added snapshot tests covering provider default expansion, canonical certificate mapping, and typed hydration failure behavior.

## Verification Results

- `mix format --check-formatted`
- `mix compile --warnings-as-errors`
- `mix test test/relyra/ecto/ecto_connection_resolver_test.exs test/relyra/connection_snapshot_test.exs --warnings-as-errors`

All passed during phase execution verification.

## Deviations from Plan

- Redaction safety is primarily enforced by the loader and snapshot detail shapes rather than by a dedicated helper module; the resulting public details still remain bounded and payload-free.

## Issues Encountered

- The phase implementation already existed in the working tree when execution began, so this run verified the slice in place and backfilled the execution summary afterward.

## Self-Check

PASSED
