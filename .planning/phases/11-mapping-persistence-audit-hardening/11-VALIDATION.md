---
phase: 11
slug: mapping-persistence-audit-hardening
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-05
---

# Phase 11 — Validation Strategy

> Per-phase validation contract for execution feedback sampling.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix on Elixir `1.19.5` |
| **Config file** | `mix.exs`, `test/test_helper.exs`, and `config/test.exs` |
| **Quick run command** | `mix test test/relyra/ecto/mapping_commands_test.exs test/relyra/connection_snapshot_test.exs test/relyra/user_mapper/default_attribute_test.exs --warnings-as-errors` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Estimated runtime** | < 60 seconds for the phase-focused smoke commands |

---

## Sampling Rate

- **After every task commit:** Run the task-specific test command plus `mix format --check-formatted`
- **After every plan wave:** Run `mix compile --warnings-as-errors`
- **Before `$gsd-verify-work`:** `mix test --warnings-as-errors` must be green
- **Max feedback latency:** < 60 seconds for the phase-focused smoke commands

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 11-01-T01 | 11-01 | 1 | CFG-05 | T-11-01-01 / T-11-01-02 / T-11-01-03 | Parent connection writes cannot become a hidden mapping mutation surface, and runtime gains only a plain `mapping_config` slot | integration | `mix test test/relyra/ecto/connection_record_test.exs --warnings-as-errors` | ✅ existing | ✅ green |
| 11-01-T02 | 11-01 | 1 | CFG-05 | T-11-01-02 / T-11-01-03 | Separate live mapping rows and append-only ledgers expose only bounded validated fields inside the exact-match scope | unit/schema | `mix test test/relyra/ecto/attribute_mapping_schema_test.exs test/relyra/ecto/group_mapping_schema_test.exs test/relyra/ecto/mapping_revision_schema_test.exs test/relyra/ecto/audit_event_schema_test.exs --warnings-as-errors` | ✅ same task | ✅ green |
| 11-02-T01 | 11-02 | 2 | CFG-05 | T-11-02-01 / T-11-02-02 | Mapping and audit tables enforce FK, ownership, and uniqueness constraints without storing JSON/blob config on `relyra_connections` | integration | `mix test test/relyra/ecto/migration_constraints_test.exs --warnings-as-errors` | ✅ existing | ✅ green |
| 11-02-T02 | 11-02 | 2 | CFG-05 | T-11-02-01 / T-11-02-02 / T-11-02-03 | Schema and Repo tests prove the bounded exact-match semantics, append-only ledgers, and redaction-safe normalized audit payload shape | unit/integration | `mix test test/relyra/ecto/attribute_mapping_schema_test.exs test/relyra/ecto/group_mapping_schema_test.exs test/relyra/ecto/mapping_revision_schema_test.exs test/relyra/ecto/audit_event_schema_test.exs test/relyra/ecto/migration_constraints_test.exs --warnings-as-errors` | ✅ from 11-01 + this task | ✅ green |
| 11-03-T01 | 11-03 | 3 | CFG-05 | T-11-03-01 / T-11-03-03 | Audit append helpers require explicit attribution, centralized write-boundary usage, and redaction of oversized or sensitive payload material | unit/integration | `mix test test/relyra/ecto/audit_hardening_test.exs --warnings-as-errors` | ✅ same task | ✅ green |
| 11-03-T02 | 11-03 | 3 | CFG-05 | T-11-03-01 / T-11-03-02 / T-11-03-04 | Connection, metadata, and certificate trust mutations write durable audit rows in the same transaction while keeping metadata provenance separate and staying on explicit orchestration surfaces | integration | `mix test test/relyra/ecto/audit_hardening_test.exs test/relyra/ecto/connection_record_test.exs test/relyra/ecto/metadata_apply_test.exs test/relyra/ecto/certificate_inventory_transition_test.exs --warnings-as-errors` | ✅ from T01 + existing | ✅ green |
| 11-04-T01 | 11-04 | 4 | CFG-05 | T-11-04-01 / T-11-04-02 / T-11-04-04 | Mapping mutations occur only through dedicated audited commands with typed actions, deterministic multivalue semantics, and no advanced transform surface | integration | `mix test test/relyra/ecto/mapping_commands_test.exs --warnings-as-errors` | ✅ same task | ✅ green |
| 11-04-T02 | 11-04 | 4 | CFG-05 | T-11-04-03 / T-11-04-04 | Resolved runtime connections hydrate only plain `mapping_config` values, and the default mapper consumes exact persisted rules before fallback behavior | integration | `mix test test/relyra/ecto/ecto_connection_resolver_test.exs test/relyra/connection_snapshot_test.exs test/relyra/user_mapper/default_attribute_test.exs test/relyra/ecto/mapping_commands_test.exs --warnings-as-errors` | ✅ from T01 + this task | ✅ green |
| 11-04-T03 | 11-04 | 4 | CFG-05 | T-11-04-03 / T-11-04-04 | Runtime mapping contract stays persistence-agnostic: `mapping_config` is the only runtime mapping surface, ordering is deterministic, and host-app mappers see stable plain values | unit/integration | `mix test test/relyra/connection_snapshot_test.exs test/relyra/user_mapper/default_attribute_test.exs test/relyra/ecto/ecto_connection_resolver_test.exs --warnings-as-errors` | ✅ existing | ✅ green |
| 11-04-T04 | 11-04 | 4 | CFG-05 | T-11-03-01 / T-11-03-02 / T-11-04-04 | Cross-domain audit rows remain attributable, bounded, reviewable, and redaction-safe across connection, metadata, certificate, and mapping mutations | integration | `mix test test/relyra/ecto/audit_hardening_test.exs test/relyra/ecto/connection_record_test.exs test/relyra/ecto/metadata_apply_test.exs test/relyra/ecto/certificate_inventory_transition_test.exs test/relyra/ecto/mapping_commands_test.exs --warnings-as-errors` | ✅ existing | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Task-Local Nyquist Ordering

- `11-01-T02` creates the four schema contract tests before running the schema verification command.
- `11-03-T01` creates `test/relyra/ecto/audit_hardening_test.exs` before running the audit helper verification command.
- `11-04-T01` creates `test/relyra/ecto/mapping_commands_test.exs` before running the mapping command verification command.
- `11-04-T02` may rely on `test/relyra/ecto/mapping_commands_test.exs` because Plan `11-04` Task 1 owns that artifact earlier in the same plan.

No task-level verification command depends on a test file first created by a later task or later wave.

---

## Validation Sign-Off

- [x] Phase 11 has task-level automated verification targets spanning schema, migration, audit, snapshot, and mapper behavior
- [x] Task-local Nyquist ordering names every newly introduced test artifact before its first verification use
- [x] Sampling continuity covers each wave without relying on logs or telemetry as proof
- [x] Cross-domain audit reviewability and runtime mapping ergonomics now have executable verification coverage
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** complete
