---
phase: 11-mapping-persistence-audit-hardening
plan: 11-03
subsystem: ecto-persistence-audit
tags: [audit, ecto, metadata, certificates, connections]
requires: ["11-01", "11-02"]
provides: ["shared-audit-writer", "audited-connection-mutations", "audited-metadata-apply", "audited-certificate-transitions"]
affects:
  - lib/relyra/ecto/audit_writer.ex
  - lib/relyra/ecto/connections.ex
  - lib/relyra/ecto/metadata_apply.ex
  - lib/relyra/ecto/certificate_inventory.ex
  - test/relyra/ecto/audit_hardening_test.exs
  - test/relyra/ecto/connection_record_test.exs
  - test/relyra/ecto/metadata_apply_test.exs
  - test/relyra/ecto/certificate_inventory_transition_test.exs
tech_stack:
  - Elixir
  - Ecto
patterns:
  - Repo.transact audited write boundary
  - append-only audit ledger
  - bounded normalized summaries
key_files:
  created:
    - lib/relyra/ecto/audit_writer.ex
    - test/relyra/ecto/audit_hardening_test.exs
  modified:
    - lib/relyra/ecto/connections.ex
    - lib/relyra/ecto/metadata_apply.ex
    - lib/relyra/ecto/certificate_inventory.ex
    - test/relyra/ecto/connection_record_test.exs
    - test/relyra/ecto/metadata_apply_test.exs
    - test/relyra/ecto/certificate_inventory_transition_test.exs
decisions:
  - "Audit rows are appended only from explicit Ecto orchestration modules, never from ambient process state."
  - "Connection, metadata, and certificate trust mutations persist bounded before/after/diff summaries in the same transaction as the state write."
  - "Metadata revisions remain the metadata provenance ledger while audit events provide the cross-domain review surface."
metrics:
  completed_at: 2026-05-05
  verification_commands: 3
---

# Phase 11 Plan 03: Mapping Persistence Audit Hardening Summary

Shared audited trust-mutation boundary for connection, metadata, and certificate writes with rollback-safe append-only audit rows.

## Outcome

Implemented `Relyra.Ecto.AuditWriter` and wired it into the existing connection, metadata, and certificate persistence flows so successful trust mutations append explicit attributable audit rows inside the same transaction as the state change.

## Delivered

- Added `Relyra.Ecto.AuditWriter.append_event/2` with explicit required attribution, bounded normalization, and redaction of sensitive or oversized values.
- Wrapped `Relyra.Ecto.Connections` create/update/enable/disable writes in audited transactional boundaries.
- Extended `Relyra.Ecto.MetadataApply` to emit metadata-domain audit rows while preserving `Relyra.Ecto.MetadataRevision` as the metadata provenance ledger.
- Extended `Relyra.Ecto.CertificateInventory` to emit certificate-domain audit rows for staged, activated, retired, and rollback transitions.
- Added regression coverage for audit writer behavior, audited success paths, rollback safety, and optimistic-lock conflict safety.

## Verification

- `mix test test/relyra/ecto/audit_hardening_test.exs --warnings-as-errors`
- `mix test test/relyra/ecto/audit_hardening_test.exs test/relyra/ecto/connection_record_test.exs test/relyra/ecto/metadata_apply_test.exs test/relyra/ecto/certificate_inventory_transition_test.exs --warnings-as-errors`
- `mix compile --warnings-as-errors`

## Acceptance Evidence

- Connection lifecycle writes now emit one `:connection` audit row per successful create/update/enable/disable mutation.
- Metadata apply emits one `:certificate/:staged` row and one `:metadata/:applied` row on success.
- Certificate activate/retire/rollback transitions emit one `:certificate` audit row per successful state change.
- Invalid audited connection writes, failed metadata apply operations, and certificate lock conflicts leave zero orphan audit rows.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/11-mapping-persistence-audit-hardening/11-03-SUMMARY.md`
- Verified code and tests exist for all scoped plan files
- Verification commands passed in the current workspace
