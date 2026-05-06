---
phase: 19-idp-initiated-sso
plan: 01
status: complete
verified: 2026-05-06T19:00:00Z
---

## 19-01 Summary: Data Model Update

I updated the data model to persist the `allow_idp_initiated` connection-level setting, defaulting to `false` for a fail-closed posture.

### Key Changes
- Created migration `priv/repo/migrations/20260506232319_add_allow_idp_initiated_to_relyra_connections.exs`.
- Updated `Relyra.Ecto.Connection` schema to include the `allow_idp_initiated` boolean field.
- Updated `draft_changeset/2` and `update_changeset/2` to permit modification of this field.
- Verified field persistence and default behavior with new tests in `test/relyra/ecto/connection_test.exs`.

### Verification Results
- `mix test test/relyra/ecto/connection_test.exs` passed.
