# Phase 11 Verification

## Scope

This artifact closes `CFG-05` milestone verification for Phase 11 by recording the compact serial evidence packet defined in Phase 14 and preserving the blocking manual approval gate for the two remaining mapping/audit semantics checks.

## Requirement Traceability

Requirement: `CFG-05` - User can persist attribute/group mapping configuration and review a durable audit history of trust changes.

| CFG-05 behavior | Proof source | Evidence |
| --- | --- | --- |
| Mapping persistence (live rows + revision ledger) | `mix test test/relyra/ecto/mapping_commands_test.exs test/relyra/ecto/audit_hardening_test.exs test/relyra/ecto/attribute_mapping_schema_test.exs test/relyra/ecto/group_mapping_schema_test.exs test/relyra/ecto/mapping_revision_schema_test.exs test/relyra/ecto/audit_event_schema_test.exs test/relyra/ecto/migration_constraints_test.exs test/relyra/connection_snapshot_test.exs test/relyra/user_mapper/default_attribute_test.exs test/relyra/ecto/ecto_connection_resolver_test.exs test/relyra/ecto/connection_record_test.exs test/relyra/ecto/metadata_apply_test.exs test/relyra/ecto/certificate_inventory_transition_test.exs --warnings-as-errors`; `.planning/phases/11-mapping-persistence-audit-hardening/11-01-SUMMARY.md`; `.planning/phases/11-mapping-persistence-audit-hardening/11-02-SUMMARY.md`; `.planning/phases/11-mapping-persistence-audit-hardening/11-04-SUMMARY.md` | Focused serial mapping/audit packet passed with `62 tests, 0 failures`. `attribute_mapping_schema_test.exs`, `group_mapping_schema_test.exs`, and `mapping_revision_schema_test.exs` prove attribute and group rules persist as live rows alongside an append-only revision ledger so operator-authored mappings survive restart and stay diffable across edits. |
| Cross-domain audit hardening (same-transaction capture) | `mix test test/relyra/ecto/mapping_commands_test.exs test/relyra/ecto/audit_hardening_test.exs test/relyra/ecto/attribute_mapping_schema_test.exs test/relyra/ecto/group_mapping_schema_test.exs test/relyra/ecto/mapping_revision_schema_test.exs test/relyra/ecto/audit_event_schema_test.exs test/relyra/ecto/migration_constraints_test.exs test/relyra/connection_snapshot_test.exs test/relyra/user_mapper/default_attribute_test.exs test/relyra/ecto/ecto_connection_resolver_test.exs test/relyra/ecto/connection_record_test.exs test/relyra/ecto/metadata_apply_test.exs test/relyra/ecto/certificate_inventory_transition_test.exs --warnings-as-errors`; `.planning/phases/11-mapping-persistence-audit-hardening/11-03-SUMMARY.md` | Focused serial mapping/audit packet passed with `62 tests, 0 failures`. `audit_hardening_test.exs`, `connection_record_test.exs`, `metadata_apply_test.exs`, and `certificate_inventory_transition_test.exs` prove connection, metadata, and certificate mutations write redaction-safe audit events inside the same transaction as the underlying change so the trust timeline cannot drift from the data it describes. |
| Audited mapping mutation surface | `mix test test/relyra/ecto/mapping_commands_test.exs test/relyra/ecto/audit_hardening_test.exs test/relyra/ecto/attribute_mapping_schema_test.exs test/relyra/ecto/group_mapping_schema_test.exs test/relyra/ecto/mapping_revision_schema_test.exs test/relyra/ecto/audit_event_schema_test.exs test/relyra/ecto/migration_constraints_test.exs test/relyra/connection_snapshot_test.exs test/relyra/user_mapper/default_attribute_test.exs test/relyra/ecto/ecto_connection_resolver_test.exs test/relyra/ecto/connection_record_test.exs test/relyra/ecto/metadata_apply_test.exs test/relyra/ecto/certificate_inventory_transition_test.exs --warnings-as-errors`; `.planning/phases/11-mapping-persistence-audit-hardening/11-01-SUMMARY.md`; `.planning/phases/11-mapping-persistence-audit-hardening/11-04-SUMMARY.md` | Focused serial mapping/audit packet passed with `62 tests, 0 failures`. `mapping_commands_test.exs` and `migration_constraints_test.exs` prove the public mapping mutation surface co-commits a revision ledger row plus an audit event row with each accepted change and rejects oversized or malformed payloads at the schema boundary. |
| Runtime mapping_config hydration | `mix test test/relyra/ecto/mapping_commands_test.exs test/relyra/ecto/audit_hardening_test.exs test/relyra/ecto/attribute_mapping_schema_test.exs test/relyra/ecto/group_mapping_schema_test.exs test/relyra/ecto/mapping_revision_schema_test.exs test/relyra/ecto/audit_event_schema_test.exs test/relyra/ecto/migration_constraints_test.exs test/relyra/connection_snapshot_test.exs test/relyra/user_mapper/default_attribute_test.exs test/relyra/ecto/ecto_connection_resolver_test.exs test/relyra/ecto/connection_record_test.exs test/relyra/ecto/metadata_apply_test.exs test/relyra/ecto/certificate_inventory_transition_test.exs --warnings-as-errors`; `mix test --warnings-as-errors`; `.planning/phases/11-mapping-persistence-audit-hardening/11-04-SUMMARY.md` | Focused serial mapping/audit packet passed with `62 tests, 0 failures`; full serial suite passed with `168 tests, 0 failures`. `connection_snapshot_test.exs`, `ecto_connection_resolver_test.exs`, and `user_mapper/default_attribute_test.exs` prove resolved connections expose plain `attribute_rules` / `group_rules` with deterministic ordering and persisted-rules-first hydration so host-app `Relyra.UserMapper` consumers see stable values without leaking Ecto rows. |

## Phase-Audit Gap Closed

Milestone audit gap being closed: `.planning/v0.2-MILESTONE-AUDIT.md` left `CFG-05` orphaned because Phase 11 had no `11-VERIFICATION.md`, and the focused mapping/audit suite passing `19 tests, 0 failures` at audit time was not enough to close milestone-level traceability.

Closure evidence:
- This file now exists as the missing Phase 11 verification artifact.
- The focused serial mapping/audit packet now passes against the current repo state.
- The full serial suite now passes after the focused mapping/audit packet.
- The remaining human approval gate is isolated to the two semantics judgments defined in Phase 14.

## Automated Evidence Packet

Execution mode: serial only. These commands were run one after the other and were not parallelized, matching the mapping/audit validation contract and the milestone-audit warning that parallel Mix evidence is invalid for this phase.

| Order | Executed at (UTC) | Exact command | Status | Result |
| --- | --- | --- | --- | --- |
| 1 | `2026-05-06T08:38:12Z` | `mix compile --warnings-as-errors` | passed | `compile succeeded with no warnings` |
| 2 | `2026-05-06T08:38:35Z` | `mix test test/relyra/ecto/mapping_commands_test.exs test/relyra/ecto/audit_hardening_test.exs test/relyra/ecto/attribute_mapping_schema_test.exs test/relyra/ecto/group_mapping_schema_test.exs test/relyra/ecto/mapping_revision_schema_test.exs test/relyra/ecto/audit_event_schema_test.exs test/relyra/ecto/migration_constraints_test.exs test/relyra/connection_snapshot_test.exs test/relyra/user_mapper/default_attribute_test.exs test/relyra/ecto/ecto_connection_resolver_test.exs test/relyra/ecto/connection_record_test.exs test/relyra/ecto/metadata_apply_test.exs test/relyra/ecto/certificate_inventory_transition_test.exs --warnings-as-errors` | passed | `62 tests, 0 failures` |
| 3 | `2026-05-06T08:38:50Z` | `mix test --warnings-as-errors` | passed | `168 tests, 0 failures` |

Serial execution note: order `1` completed successfully before order `2` started, and order `2` completed successfully before order `3` started. No parallel Mix commands were used for this verification packet.

## Evidence Map

### Mapping persistence (live rows + revision ledger)

- `test/relyra/ecto/attribute_mapping_schema_test.exs` and `test/relyra/ecto/group_mapping_schema_test.exs` prove operator-authored attribute and group rules persist as live, ordered rows scoped to a connection.
- `test/relyra/ecto/mapping_revision_schema_test.exs` proves every accepted mapping change captures an append-only revision ledger entry so prior states stay diffable.
- `lib/relyra/ecto/attribute_mapping.ex`, `lib/relyra/ecto/group_mapping.ex`, and `lib/relyra/ecto/mapping_revision.ex` carry the schema contracts; `.planning/phases/11-mapping-persistence-audit-hardening/11-01-SUMMARY.md`, `11-02-SUMMARY.md`, and `11-04-SUMMARY.md` record the persistence and revision shape.

### Cross-domain audit hardening (same-transaction capture)

- `test/relyra/ecto/audit_hardening_test.exs`, `test/relyra/ecto/connection_record_test.exs`, `test/relyra/ecto/metadata_apply_test.exs`, and `test/relyra/ecto/certificate_inventory_transition_test.exs` prove connection, metadata, and certificate mutations co-commit redaction-safe audit events inside the same transaction as the underlying change.
- `lib/relyra/ecto/audit_writer.ex` and `lib/relyra/ecto/audit_event.ex` carry the writer and event-shape contracts; `.planning/phases/11-mapping-persistence-audit-hardening/11-03-SUMMARY.md` records the cross-domain audit hardening that closes the same-transaction gap.

### Audited mapping mutation surface

- `test/relyra/ecto/mapping_commands_test.exs` proves the public mapping mutation surface co-commits a revision ledger row plus an audit event row with each accepted change and refuses partial outcomes.
- `test/relyra/ecto/migration_constraints_test.exs` proves oversized or malformed payloads are rejected at the schema boundary; `lib/relyra/ecto/mapping_commands.ex` carries the command contract; `.planning/phases/11-mapping-persistence-audit-hardening/11-01-SUMMARY.md` and `11-04-SUMMARY.md` record the bounded-payload mutation surface.

### Runtime mapping_config hydration

- `test/relyra/connection_snapshot_test.exs`, `test/relyra/ecto/ecto_connection_resolver_test.exs`, and `test/relyra/user_mapper/default_attribute_test.exs` prove resolved connections expose plain `attribute_rules` / `group_rules` with deterministic ordering and persisted-rules-first hydration so host-app `Relyra.UserMapper` consumers see stable values without leaking Ecto rows.
- `lib/relyra/ecto/connection_snapshot.ex` and `lib/relyra/user_mapper/default_attribute.ex` carry the runtime contract; `.planning/phases/11-mapping-persistence-audit-hardening/11-04-SUMMARY.md` records the persistence-agnostic hydration shape.
- `mix test --warnings-as-errors` confirms the focused mapping/audit guarantees remain compatible with the broader runtime, snapshot, and Phoenix coverage.

## Manual Sign-Off

The automated packet is complete. The remaining approval gate is limited to the two semantics checks Phase 14 locked:

1. Confirm cross-domain audit rows read like a calm trust timeline — actor, cause, before/after view, redaction-safe payloads — so an operator can answer "who changed what, why" without leaking XML/PEM/key material.

2. Confirm the runtime mapping_config contract stays persistence-agnostic — plain attribute_rules / group_rules, deterministic ordering, persisted-rules-first with fallback — so host-app Relyra.UserMapper consumers see stable values.

Human review instructions:
- For check 1, review `lib/relyra/ecto/audit_writer.ex`, `lib/relyra/ecto/audit_event.ex`, `test/relyra/ecto/audit_hardening_test.exs`, `test/relyra/ecto/connection_record_test.exs`, `test/relyra/ecto/metadata_apply_test.exs`, and `test/relyra/ecto/certificate_inventory_transition_test.exs` and confirm representative audit rows expose actor, cause, before/after view, and redaction-safe payloads — an operator can answer "who changed what, why" from a row sample without seeing raw XML, PEM, or key material.
- For check 2, review `lib/relyra/ecto/connection_snapshot.ex`, `lib/relyra/user_mapper/default_attribute.ex`, `test/relyra/connection_snapshot_test.exs`, `test/relyra/ecto/ecto_connection_resolver_test.exs`, and `test/relyra/user_mapper/default_attribute_test.exs` and confirm `mapping_config` exposes plain `attribute_rules` / `group_rules` with deterministic ordering and persisted-rules-first fallback — Ecto rows do not leak into runtime consumers.
- If approved, record concise approval prose below without expanding the scope beyond these semantics checks.

Human review result:
- Approval pending.
