---
phase: 7
slug: schema-connection-aggregate
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-05
---

# Phase 7 — Validation Strategy

> Per-phase validation contract for execution feedback sampling.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit with Ecto SQL integration for Phase 07 |
| **Config file** | `config/test.exs` |
| **Quick run command** | `mix test test/relyra/connection_test.exs --warnings-as-errors` |
| **Full suite command** | `mix qa` |
| **Estimated runtime** | < 30 seconds for per-task smoke commands |

---

## Sampling Rate

- **After every task commit:** Run the most relevant Phase 07-focused ecto test file plus `mix format --check-formatted`
- **After every plan wave:** Run `mix test --warnings-as-errors`
- **Before `/gsd-verify-work`:** `mix qa` must be green
- **Max feedback latency:** < 30 seconds for per-task smoke commands

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 07-01-T01 | 07-01 | 1 | CFG-01 | TM-07-01-MIGRATION-BLINDNESS | Repo harness exists before migration work is trusted | smoke | `mix test test/relyra/connection_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 07-01-T02 | 07-01 | 1 | CFG-01 | TM-07-01-MIGRATION-BLINDNESS | Validation contract exists with fast smoke and wave-end commands | doc/smoke | `mix test test/relyra/connection_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 07-02-T01 | 07-02 | 2 | CFG-01 | TM-07-02-PUBLIC-ID-DRIFT | Aggregate schemas keep internal PK and public `connection_id` distinct | unit | `mix test test/relyra/ecto/connection_schema_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 07-02-T02 | 07-02 | 2 | CFG-01 | TM-07-02-REPLACE-IN-PLACE-TRUST | Migrations create the canonical connection and certificate tables correctly | integration | `mix test test/relyra/ecto/migration_constraints_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 07-02-T03 | 07-02 | 2 | CFG-01 | TM-07-02-REPLACE-IN-PLACE-TRUST | Constraint and schema tests prove DB and changeset shape without readiness logic | integration/unit | `mix test test/relyra/ecto/migration_constraints_test.exs test/relyra/ecto/certificate_schema_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 07-03-T01 | 07-03 | 3 | CFG-01 | TM-07-03-DRAFT-RESOLVES-SILENTLY | Minimal persistence API supports create/update/disable without resolver coupling | integration | `mix test test/relyra/ecto/connection_record_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 07-03-T02 | 07-03 | 3 | CFG-01 | TM-07-03-RUNTIME-ID-MISMATCH | Runtime-readiness and `connection_id` contract stay explicit and non-lossy | unit | `mix test test/relyra/connection_test.exs --warnings-as-errors` | ✅ | ✅ green |
| 07-03-T03 | 07-03 | 3 | CFG-01 | TM-07-03-DRAFT-RESOLVES-SILENTLY | Invalid or incomplete config is rejected before runtime use | integration/unit | `mix test test/relyra/ecto/runtime_readiness_test.exs --warnings-as-errors` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `config/test.exs` — test-only Ecto SQL config for the Phase 07 Repo harness
- [x] `test/support/ecto_test_repo.ex` — minimal Repo for migration and schema integration tests
- [x] `test/support/migration_case.ex` — deterministic migration setup/teardown helper
- [x] `test/relyra/ecto/migration_constraints_test.exs` — real Repo verification of tables, indexes, FKs, and uniqueness

Wave 0 is complete only when all four artifacts exist and the migration
constraint test runs green.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Host-app migration adoption ergonomics | CFG-01 | The repo can prove canonical migrations and tests, but adopter copy/adaptation flow is not fully automatable in Phase 07 | Review the migration filenames, comments, and table naming for host-app clarity before phase closeout |

---

## Validation Sign-Off

- [x] All planned tasks have an automated verification target
- [x] Wave 0 covers migration reality, not just fake-repo unit tests
- [x] Create/update/disable workflow is exercised through the minimal persistence API
- [x] Runtime-readiness gate blocks incomplete or disabled rows
- [x] `nyquist_compliant: true` set in frontmatter for the planning package

**Approval:** complete
