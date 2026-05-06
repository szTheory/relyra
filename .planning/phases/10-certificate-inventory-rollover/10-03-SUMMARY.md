# 10-03 Summary

Status: completed

Hardened rollover lifecycle transitions and added an explicit connection-level conflict contract.

- Added `lock_version` support to `Relyra.Ecto.Connection` and the `20260505183000_harden_relyra_certificate_lifecycle_invariants.exs` migration.
- Tightened `Relyra.Ecto.CertificateInventory` transition rules so only legal lifecycle edges succeed, rollback is atomic, and stale parent-row writes normalize to typed `:conflict` errors.
- Preserved active-only runtime hydration while richer staged and retired inventory rows exist.
- Added transition-matrix and concurrency regressions, including a deterministic stale-write test using independent DB connections.
- Updated test support so sync tests can opt out of shared-owner sandbox mode when true DB concurrency is required.

Verification:

- `mix test test/relyra/ecto/certificate_inventory_transition_test.exs test/relyra/ecto/certificate_inventory_concurrency_test.exs test/relyra/ecto/ecto_connection_resolver_test.exs test/relyra/connection_snapshot_test.exs --warnings-as-errors`
- `mix compile --warnings-as-errors`
