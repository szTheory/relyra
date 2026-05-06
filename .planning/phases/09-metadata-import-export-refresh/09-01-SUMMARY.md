# Plan 09-01 Summary

## Outcome

Implemented the Phase 09 persistence foundation without changing the Phase 08 runtime read path.

## Delivered

- Added `active_metadata_revision_id` and `last_known_good_metadata_revision_id` to `Relyra.Ecto.Connection`.
- Added `Relyra.Ecto.MetadataSource` and `Relyra.Ecto.MetadataRevision` schemas.
- Added metadata source/revision migrations plus connection pointer indexes and FK constraints.
- Added Wave 0 schema and migration coverage for metadata source/revision validation and single-source-per-connection enforcement.

## Verification

- `mix test test/relyra/ecto/metadata_revision_schema_test.exs test/relyra/ecto/metadata_source_schema_test.exs test/relyra/ecto/migration_constraints_test.exs --warnings-as-errors`

## Notes

- The pointer migration is sequenced before the revision-table migration by filename, so the foreign-key constraints are attached in the later migration after `relyra_metadata_revisions` exists.
