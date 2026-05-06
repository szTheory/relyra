---
phase: 11-mapping-persistence-audit-hardening
plan: 11-01
subsystem: mapping-persistence
tags: [ecto, mappings, audit, schemas]
requires: [CFG-05]
provides:
  - runtime mapping_config contract on resolved connections
  - aggregate associations for mapping and audit persistence surfaces
  - attribute/group live-row schemas
  - mapping revision and audit event append-only ledger schemas
affects:
  - lib/relyra/connection.ex
  - lib/relyra/ecto/connection.ex
  - lib/relyra/ecto/attribute_mapping.ex
  - lib/relyra/ecto/group_mapping.ex
  - lib/relyra/ecto/mapping_revision.ex
  - lib/relyra/ecto/audit_event.ex
  - test/relyra/ecto/attribute_mapping_schema_test.exs
  - test/relyra/ecto/group_mapping_schema_test.exs
  - test/relyra/ecto/mapping_revision_schema_test.exs
  - test/relyra/ecto/audit_event_schema_test.exs
decisions:
  - Keep runtime mapping state as a plain mapping_config field on Relyra.Connection.
  - Reject attribute_mappings and group_mappings in generic parent connection writes.
  - Bound mapping and audit payload semantics with Ecto.Enum fields and oversized-map guards.
completed_at: 2026-05-05
---

# Phase 11 Plan 01: Mapping persistence contracts summary

Added the runtime mapping slot, aggregate association boundaries, separate live mapping schemas, and separate append-only mapping/audit ledgers required for CFG-05.

## What Changed

- `Relyra.Connection` now exposes `:mapping_config` as a plain runtime field and keeps Ecto rows out of the runtime struct contract. See [lib/relyra/connection.ex](/Users/jon/projects/relyra/lib/relyra/connection.ex:5).
- `Relyra.Ecto.Connection` now owns `:attribute_mappings`, `:group_mappings`, `:mapping_revisions`, and `:audit_events`, and both draft/update changesets reject direct mapping association writes. See [lib/relyra/ecto/connection.ex](/Users/jon/projects/relyra/lib/relyra/ecto/connection.ex:28) and [lib/relyra/ecto/connection.ex](/Users/jon/projects/relyra/lib/relyra/ecto/connection.ex:216).
- Added bounded live-row schemas for attribute mappings and group mappings. See [lib/relyra/ecto/attribute_mapping.ex](/Users/jon/projects/relyra/lib/relyra/ecto/attribute_mapping.ex:16) and [lib/relyra/ecto/group_mapping.ex](/Users/jon/projects/relyra/lib/relyra/ecto/group_mapping.ex:15).
- Added append-only mapping revision and audit event ledgers with explicit attribution fields and bounded map validation. See [lib/relyra/ecto/mapping_revision.ex](/Users/jon/projects/relyra/lib/relyra/ecto/mapping_revision.ex:18) and [lib/relyra/ecto/audit_event.ex](/Users/jon/projects/relyra/lib/relyra/ecto/audit_event.ex:31).
- Added schema contract tests for each new persistence surface. See [test/relyra/ecto/attribute_mapping_schema_test.exs](/Users/jon/projects/relyra/test/relyra/ecto/attribute_mapping_schema_test.exs:1), [test/relyra/ecto/group_mapping_schema_test.exs](/Users/jon/projects/relyra/test/relyra/ecto/group_mapping_schema_test.exs:1), [test/relyra/ecto/mapping_revision_schema_test.exs](/Users/jon/projects/relyra/test/relyra/ecto/mapping_revision_schema_test.exs:1), and [test/relyra/ecto/audit_event_schema_test.exs](/Users/jon/projects/relyra/test/relyra/ecto/audit_event_schema_test.exs:1).

## Verification

- `mix format lib/relyra/connection.ex lib/relyra/ecto/connection.ex lib/relyra/ecto/attribute_mapping.ex lib/relyra/ecto/group_mapping.ex lib/relyra/ecto/mapping_revision.ex lib/relyra/ecto/audit_event.ex test/relyra/ecto/attribute_mapping_schema_test.exs test/relyra/ecto/group_mapping_schema_test.exs test/relyra/ecto/mapping_revision_schema_test.exs test/relyra/ecto/audit_event_schema_test.exs`
- `mix test test/relyra/ecto/connection_record_test.exs --warnings-as-errors`
- `mix test test/relyra/ecto/attribute_mapping_schema_test.exs test/relyra/ecto/group_mapping_schema_test.exs test/relyra/ecto/mapping_revision_schema_test.exs test/relyra/ecto/audit_event_schema_test.exs --warnings-as-errors`
- `mix run -e '...'` to confirm both `draft_changeset/2` and `update_changeset/2` reject `attribute_mappings` and `group_mappings`.
- `rg -n ":mapping_config|has_many :attribute_mappings|has_many :group_mappings|has_many :mapping_revisions|has_many :audit_events|dedicated mapping persistence commands" lib/relyra/connection.ex lib/relyra/ecto/connection.ex`

## Deviations from Plan

None in implementation.

Verification note: a parallel rerun of the schema suite collided on `schema_migrations` creation in the test database, so the final verification was rerun serially. This was a test harness concurrency issue, not a code failure.

## Commit Status

No commit was created.

Creating a commit is unsafe in the current dirty tree because [lib/relyra/ecto/connection.ex](/Users/jon/projects/relyra/lib/relyra/ecto/connection.ex:1) and the new schema/test files are currently untracked relative to `HEAD`. Committing that file would necessarily capture pre-existing working-tree content that is not attributable solely to this plan execution.

## Known Stubs

None.

## Self-Check

PASSED
