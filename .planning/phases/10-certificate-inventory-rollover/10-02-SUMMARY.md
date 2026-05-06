# 10-02 Summary

Status: completed

Implemented the ownership boundary that keeps certificate inventory mutations out of generic connection updates.

- Removed certificate casting from `Relyra.Ecto.Connection.update_changeset/2`.
- Added explicit validation errors when `certificates` are supplied to update or publish flows.
- Preserved create-time certificate seeding through `draft_changeset/2`.
- Added schema and integration regressions proving `Connections.update/2` cannot mutate certificate inventory and does not delete existing rows.

Verification:

- `mix test test/relyra/ecto/connection_schema_test.exs test/relyra/ecto/connection_certificate_boundary_test.exs test/relyra/ecto/metadata_apply_test.exs test/relyra/ecto/ecto_connection_resolver_test.exs --warnings-as-errors`
