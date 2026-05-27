---
phase: 35-signed-authnrequests-adfs-preset
plan: 03
subsystem: persistence
tags: [ecto, connection, runtime]
requires:
  - phase: 32-02
    provides: sign_authn_requests connection field
provides:
  - persisted signed_request_encoding field
  - runtime propagation of outbound encoding choice
affects: [schema, runtime]
key-files:
  created:
    - priv/repo/migrations/20260526120943_add_signed_request_encoding_to_relyra_connections.exs
  modified:
    - lib/relyra/connection.ex
    - lib/relyra/ecto/connection.ex
    - lib/relyra/ecto/connection_snapshot.ex
    - test/relyra/ecto/connection_test.exs
    - test/relyra/connection_snapshot_test.exs
requirements-completed: [AUTHN-02]
completed: 2026-05-26
---

# Phase 35 Plan 03 Summary

Persisted the redirect-signing encoding choice and threaded it into runtime snapshots.

## Accomplishments

- Added the `signed_request_encoding` schema field and migration.
- Validated accepted enum values (`:rfc3986_upper`, `:adfs_lower`) in connection changesets.
- Propagated the field into the runtime connection struct so later plans could drive signing behavior from persisted configuration.

