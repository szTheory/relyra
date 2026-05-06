---
phase: 07-schema-connection-aggregate
plan: 07-02
subsystem: connection-aggregate-schema
tags: [ecto, schemas, migrations, constraints, certificates]
requires:
  - phase: 07-01
    provides: Ecto integration harness and validation contract
provides:
  - internal connection and certificate schemas with distinct public identity
  - canonical migrations for connection and certificate tables
  - real-Repo constraint and schema coverage
affects: [phase-07-foundation, phase-08-readiness]
tech-stack:
  added: [Ecto.Schema, Ecto.Enum, Ecto migration constraints]
  patterns:
    - internal binary primary key plus public immutable connection_id
    - additive child certificate inventory instead of blob-first trust material
    - real-Repo constraint checks rather than changeset-only inference
key-files:
  created:
    - .planning/phases/07-schema-connection-aggregate/07-02-SUMMARY.md
    - lib/relyra/ecto/connection.ex
    - lib/relyra/ecto/certificate.ex
    - lib/relyra/ecto/connection/runtime_policy.ex
    - priv/repo/migrations/20260505120000_create_relyra_connections.exs
    - priv/repo/migrations/20260505120100_create_relyra_connection_certificates.exs
    - test/relyra/ecto/migration_constraints_test.exs
    - test/relyra/ecto/connection_schema_test.exs
    - test/relyra/ecto/certificate_schema_test.exs
key-decisions:
  - "Keep `id` as an internal binary primary key while exposing immutable `connection_id` as the public route-safe identifier."
  - "Model certificates as child rows with fingerprint and provenance metadata so Phase 10 rollover can stay additive."
  - "Prove uniqueness, foreign keys, and cascade behavior against a real Repo instead of relying on changeset assumptions."
requirements-completed: [CFG-01]
duration: inline verification
completed: 2026-05-05
---

# Phase 07 Plan 02: Aggregate Schemas, Migrations, and Constraint Tests Summary

The persistence shape for Phase 07 is in place: connection records now have internal Ecto schemas, canonical migrations, and real-Repo tests that prove public identity, relational certificate storage, and core database constraints.

## Performance

- **Duration:** inline verification
- **Completed:** 2026-05-05
- **Tasks:** 3
- **Files modified:** 8 primary schema, migration, and test artifacts

## Accomplishments

- Added `Relyra.Ecto.Connection` with draft/enabled/disabled lifecycle state, ULID-shaped `connection_id`, runtime policy embed, and `has_many :certificates`.
- Added `Relyra.Ecto.Certificate` with certificate fingerprint, PEM, provenance fields, and FK-backed ownership by connection rows.
- Added canonical migrations for `relyra_connections` and `relyra_connection_certificates`, including uniqueness, indexes, and cascading delete behavior.
- Added schema and migration tests covering enable-time validation, uniqueness enforcement, foreign-key rejection, and child-row cleanup on parent delete.

## Verification Results

- `mix format --check-formatted`
- `mix compile --warnings-as-errors`
- `mix test test/relyra/ecto/migration_constraints_test.exs test/relyra/ecto/connection_schema_test.exs test/relyra/ecto/certificate_schema_test.exs --warnings-as-errors`

All passed during phase execution verification.

## Deviations from Plan

- None material. The slice delivered the schema, migration, and constraint scope without crossing into resolver hydration or workflow orchestration.

## Issues Encountered

- The certificate unique index name is longer than Postgres permits, so the database truncates the generated identifier at migration time. Constraint coverage still passes against the effective index.

## Self-Check

PASSED
