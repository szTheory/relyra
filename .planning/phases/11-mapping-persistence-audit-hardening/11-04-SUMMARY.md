# Phase 11 Plan 11-04: Mapping command + runtime hydration Summary

Implemented an explicit audited mapping command surface and completed the persisted-`mapping_config` runtime path so resolved connections and the default mapper prefer normalized persisted rules when present while preserving legacy fallback behavior when absent.

## Outcomes

- Added `Relyra.Ecto.MappingCommands` with separate `replace_attribute_mappings/3` and `replace_group_mappings/3` flows.
- Mapping writes now bump the parent connection lock, replace live rows transactionally, write a `Relyra.Ecto.MappingRevision`, and append a `domain: :mapping` audit event in the same transaction.
- `Relyra.Ecto.ConnectionLoader` now loads persisted mapping rows and preserves deterministic row ordering through the snapshot boundary.
- `Relyra.Ecto.ConnectionSnapshot` now emits plain `mapping_config` maps with normalized `attribute_rules` and `group_rules`, and fails closed on malformed persisted mapping rows.
- `Relyra.UserMapper.DefaultAttribute` now consumes persisted `mapping_config` first and falls back to the prior hardcoded mapping only when persisted config is absent.

## Verification

- `mix test test/relyra/ecto/mapping_commands_test.exs --warnings-as-errors`
- `mix test test/relyra/ecto/ecto_connection_resolver_test.exs test/relyra/connection_snapshot_test.exs test/relyra/user_mapper/default_attribute_test.exs test/relyra/ecto/mapping_commands_test.exs --warnings-as-errors`

Both commands passed on 2026-05-05.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Binary UUID handling for dynamic mapping table queries**
- **Found during:** Task 1 verification
- **Issue:** Dynamic queries against mapping tables bound `connection_record_id` and inserted row ids as plain UUID strings, which PostgreSQL rejected for `:binary_id` columns.
- **Fix:** Cast query parameters as `:binary_id` and dump UUIDs before `insert_all/3` seeding and replacement writes.
- **Files modified:** `lib/relyra/ecto/mapping_commands.ex`, `lib/relyra/ecto/connection_loader.ex`, `test/relyra/ecto/mapping_commands_test.exs`, `test/relyra/ecto/ecto_connection_resolver_test.exs`
- **Verification:** Scoped mapping command test and full 11-04 scoped suite

**2. [Rule 1 - Bug] Snapshot hydration treated absent mapping associations as invalid**
- **Found during:** Task 2 verification
- **Issue:** Snapshot hydration failed closed when `attribute_mappings` or `group_mappings` were absent rather than treating them as “no persisted mappings”, which broke fallback behavior.
- **Fix:** Normalize `nil` and not-loaded associations to empty rule lists before building `mapping_config`.
- **Files modified:** `lib/relyra/ecto/connection_snapshot.ex`
- **Verification:** Scoped connection snapshot and resolver tests in the full 11-04 suite

**Total deviations:** 2 auto-fixed.

## Known Stubs

None.

## Self-Check: PASSED
