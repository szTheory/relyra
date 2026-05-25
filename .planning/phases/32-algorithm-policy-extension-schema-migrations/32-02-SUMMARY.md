---
phase: 32
plan: 02
subsystem: ecto-schema
tags: [migration, ecto, schema, certificate, connection, party, use, sign_authn_requests]
dependency_graph:
  requires: []
  provides: [relyra_connection_certificates.party, relyra_connection_certificates.use, relyra_connections.sign_authn_requests, Certificate.party, Certificate.use, Connection.sign_authn_requests]
  affects: [lib/relyra/ecto/certificate.ex, lib/relyra/ecto/connection.ex]
tech_stack:
  added: []
  patterns: [Ecto.Enum for enum-like string columns, up/down migration for non-nullable cert columns, change migration for reversible boolean connection fields]
key_files:
  created:
    - priv/repo/migrations/20260525100000_add_party_and_use_to_relyra_connection_certificates.exs
    - priv/repo/migrations/20260525100001_add_sign_authn_requests_to_relyra_connections.exs
  modified:
    - lib/relyra/ecto/certificate.ex
    - lib/relyra/ecto/connection.ex
decisions:
  - "up/down migration pattern used for cert columns because null: false with static default is applied atomically by Postgres 11+ on ADD COLUMN — no execute UPDATE backfill needed"
  - "change migration used for sign_authn_requests because it is fully reversible"
  - "No defaults on Ecto.Enum fields :party and :use — DB column defaults handle existing rows; nil is safe during staged deploy"
  - "sign_authn_requests added to both draft_changeset and update_changeset per plan D-11 requirement that Phase 35 needs to update it on existing connections"
metrics:
  duration: 28m
  completed: "2026-05-25T14:03:22Z"
  tasks: 2
  files: 4
---

# Phase 32 Plan 02: Schema Migrations (party/use + sign_authn_requests) Summary

Two safe additive database migrations and corresponding Ecto schema field declarations: `party`/`use` columns on `relyra_connection_certificates` (ENC-04 schema half) and `sign_authn_requests` boolean on `relyra_connections` (AUTHN-02 schema half).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create cert migration and extend Certificate schema | bf830c8 | priv/repo/migrations/20260525100000_add_party_and_use_to_relyra_connection_certificates.exs, lib/relyra/ecto/certificate.ex |
| 2 | Create connection migration and extend Connection schema | ed07372 | priv/repo/migrations/20260525100001_add_sign_authn_requests_to_relyra_connections.exs, lib/relyra/ecto/connection.ex |

## What Was Built

### Migration: cert party + use columns (20260525100000)

`up/down` migration adding two string columns to `relyra_connection_certificates`:
- `party :string, null: false, default: "idp"` — Postgres applies DEFAULT atomically for existing rows (no backfill UPDATE needed for static defaults)
- `use :string, null: false, default: "signing"` — same pattern
- `down` removes `:use` then `:party` in reverse order

### Migration: sign_authn_requests (20260525100001)

`change` migration adding one boolean column to `relyra_connections`:
- `sign_authn_requests :boolean, null: false, default: false` — fully reversible; Postgres DEFAULT false covers all existing rows atomically

### Certificate schema (lib/relyra/ecto/certificate.ex)

Added after the `:metadata` field, before `belongs_to`:
- `field :party, Ecto.Enum, values: [:idp, :sp]` — no Ecto default (DB column default handles existing rows; nil is safe during staged deploy)
- `field :use, Ecto.Enum, values: [:signing, :encryption]` — same pattern

Both `:party` and `:use` added to `changeset/2` cast list alongside existing fields. Invalid enum values produce a changeset error (not a DB error) per T-32-05 mitigation.

### Connection schema (lib/relyra/ecto/connection.ex)

Added immediately after `field :allow_idp_initiated, :boolean, default: false` at top level (not inside RuntimePolicy):
- `field :sign_authn_requests, :boolean, default: false`

Added `:sign_authn_requests` to both `draft_changeset/2` and `update_changeset/2` cast lists, after `:allow_idp_initiated` in each. Boolean type in Ecto rejects non-boolean values per T-32-06 mitigation; default: false means unset connections are safe (signing disabled by default).

## Verification Results

- `mix test test/relyra/ecto/ --warnings-as-errors`: 101 tests, 0 failures (both tasks)
- `mix test --warnings-as-errors`: 557 tests, 0 failures (full suite after Task 2)
- `mix format --check-formatted`: clean on all 4 modified files
- `connection_snapshot.ex:117-120` unmodified — `active_signing_certificate?/1` checks only `:role` and `:lifecycle_state`; adding `:party`/`:use` does not affect this filter
- `mix ci.security`: all individual security suites pass (6+4+4+9+3 = 26 tests, 0 failures when run individually); `escape_hatch_audit_test.exs` encounters a transient DBConnection pool exhaustion error when run via `mix ci.security` in the parallel worktree environment (both agents compete for the same test DB at bootstrap time — confirmed to pass when run in isolation: 1 test, 0 failures)

## Deviations from Plan

None — plan executed exactly as written. The `escape_hatch_audit_test.exs` DBConnection timeout is a pre-existing parallel-agent DB collision issue in the worktree environment, not a regression introduced by this plan.

## Known Stubs

None — all fields are wired to actual DB columns with correct defaults. No placeholder values.

## Threat Flags

None — fields and migrations are purely additive and stay within the trust boundary described in the plan's `<threat_model>`. Ecto.Enum validation (T-32-05) and `:boolean` type enforcement (T-32-06) are in place.

## Self-Check: PASSED
