---
phase: 11-mapping-persistence-audit-hardening
plan: 11-02
requirement: CFG-05
status: completed
---

# Phase 11 Plan 11-02 Summary

Implemented the canonical persistence DDL for live mapping rows and append-only audit ledgers, then verified the Phase 11 contracts at both the changeset and database layers.

## Files Changed

- `priv/repo/migrations/20260505190000_create_relyra_mapping_and_audit_tables.exs`
- `test/relyra/ecto/attribute_mapping_schema_test.exs`
- `test/relyra/ecto/group_mapping_schema_test.exs`
- `test/relyra/ecto/mapping_revision_schema_test.exs`
- `test/relyra/ecto/audit_event_schema_test.exs`
- `test/relyra/ecto/migration_constraints_test.exs`

## What Landed

- Added four new tables: `relyra_attribute_mappings`, `relyra_group_mappings`, `relyra_mapping_revisions`, and `relyra_audit_events`.
- Kept attribute and group mappings on separate live tables with connection-scoped uniqueness.
- Added `position` columns plus lookup indexes for live mapping rows.
- Kept revision and audit ledgers append-only with `utc_datetime_usec` timestamps and no `updated_at`.
- Expanded schema tests to prove bounded enum usage, exact-match mapping scope, lack of regex/script/expression fields, and bounded normalized map payloads.
- Expanded migration constraints coverage to prove canonical table creation, FK ownership, uniqueness, and real-connection requirements for both ledgers.

## Verification

- `mix test test/relyra/ecto/migration_constraints_test.exs --warnings-as-errors`
- `mix test test/relyra/ecto/attribute_mapping_schema_test.exs test/relyra/ecto/group_mapping_schema_test.exs test/relyra/ecto/mapping_revision_schema_test.exs test/relyra/ecto/audit_event_schema_test.exs test/relyra/ecto/migration_constraints_test.exs --warnings-as-errors`

Both commands passed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test Data] Replaced invalid fixture connection ids in migration tests**
- **Found during:** Task 2 verification
- **Issue:** Two new connection fixtures failed the existing ULID-shaped `connection_id` validator, which obscured the intended mapping constraint checks.
- **Fix:** Switched those tests to rely on the existing generated `connection_id` path from `Connection.draft_changeset/2`.
- **Files modified:** `test/relyra/ecto/migration_constraints_test.exs`
- **Verification:** Re-ran both plan verification commands successfully.

**Total deviations:** 1 auto-fixed.

## Notes

- `relyra_connections` was left unchanged; no mapping blobs or audit payload columns were added to the parent table.
