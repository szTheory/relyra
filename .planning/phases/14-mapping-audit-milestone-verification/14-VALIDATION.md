---
phase: 14
slug: mapping-audit-milestone-verification
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-06
---

# Phase 14 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix on Elixir `1.19.5` |
| **Config file** | `mix.exs`, `test/test_helper.exs`, `config/test.exs` |
| **Quick run command** | `mix test test/relyra/ecto/mapping_commands_test.exs test/relyra/ecto/audit_hardening_test.exs test/relyra/ecto/attribute_mapping_schema_test.exs test/relyra/ecto/group_mapping_schema_test.exs test/relyra/ecto/mapping_revision_schema_test.exs test/relyra/ecto/audit_event_schema_test.exs test/relyra/ecto/migration_constraints_test.exs test/relyra/connection_snapshot_test.exs test/relyra/user_mapper/default_attribute_test.exs test/relyra/ecto/ecto_connection_resolver_test.exs test/relyra/ecto/connection_record_test.exs test/relyra/ecto/metadata_apply_test.exs test/relyra/ecto/certificate_inventory_transition_test.exs --warnings-as-errors` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Estimated runtime** | < 60 seconds for the focused mapping/audit packet; < 2 minutes for the full suite |

---

## Sampling Rate

- **After every task commit:** Run the focused mapping/audit command (Quick run command above).
- **After every plan wave:** Run `mix compile --warnings-as-errors` followed by the focused mapping/audit command, serially. Parallel Mix runs are forbidden — `schema_migrations` bootstrap races have already burned this codebase (`11-01-SUMMARY.md` "Deviations from Plan").
- **Before `/gsd-verify-work`:** `mix test --warnings-as-errors` must be green.
- **Max feedback latency:** < 60 seconds for the focused mapping/audit packet.

---

## Per-Task Verification Map

> Filled by `gsd-planner` during plan generation. Each plan task in `14-01-PLAN.md` and `14-02-PLAN.md` MUST have an entry below with a grep-verifiable or Mix-verifiable automated command.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| _to be filled by planner_ | | | | | | | | | |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

Wave 0 is already complete. Every test file in the D-06 packet exists in the current repo state, and `11-VALIDATION.md` is `wave_0_complete: true`. Phase 14 consumes that proof surface and produces the missing verification artifact + live-truth refresh around it.

- [x] `test/relyra/ecto/mapping_commands_test.exs` — typed mapping mutations + audit attribution
- [x] `test/relyra/ecto/audit_hardening_test.exs` — cross-domain same-transaction audit capture
- [x] `test/relyra/ecto/attribute_mapping_schema_test.exs`, `group_mapping_schema_test.exs`, `mapping_revision_schema_test.exs`, `audit_event_schema_test.exs` — bounded validated-field schemas
- [x] `test/relyra/ecto/migration_constraints_test.exs` — DDL FK, ownership, uniqueness, append-only ledger constraints
- [x] `test/relyra/connection_snapshot_test.exs`, `test/relyra/ecto/ecto_connection_resolver_test.exs`, `test/relyra/user_mapper/default_attribute_test.exs` — runtime `mapping_config` hydration + persistence-agnostic mapper
- [x] `test/relyra/ecto/connection_record_test.exs`, `test/relyra/ecto/metadata_apply_test.exs`, `test/relyra/ecto/certificate_inventory_transition_test.exs` — cross-domain trust-mutation audit capture

---

## Manual-Only Verifications

Manual sign-off is capped at exactly two narrow semantics judgments per `14-CONTEXT.md` D-10. Per D-11 these MUST NOT be used to re-prove functional correctness the automated packet already covers.

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Cross-domain audit rows read like a calm trust timeline — actor, cause, before/after view, redaction-safe payloads — so an operator can answer "who changed what, why" without leaking XML/PEM/key material. | CFG-05 | Tests assert structural redaction and required fields, but the qualitative judgment "this reads as reviewable trust narrative, not a row dump" is product-semantic per `11-CONTEXT.md`. | Review representative audit rows produced by `audit_hardening_test.exs`, `connection_record_test.exs`, `metadata_apply_test.exs`, `certificate_inventory_transition_test.exs`, plus `lib/relyra/ecto/audit_writer.ex` and `lib/relyra/ecto/audit_event.ex`. Confirm an operator can answer "who changed what, why" from a row sample without seeing raw XML, PEM, or key material. |
| Runtime `mapping_config` contract stays persistence-agnostic — plain `attribute_rules` / `group_rules`, deterministic ordering, persisted-rules-first with fallback — so host-app `Relyra.UserMapper` consumers see stable values. | CFG-05 | Tests prove ordering and field shape, but the API-stability judgment "host apps will not be surprised here" is product-contract semantic per `11-CONTEXT.md` D-04 / D-05. | Review `lib/relyra/ecto/connection_snapshot.ex`, `lib/relyra/user_mapper/default_attribute.ex`, plus `connection_snapshot_test.exs`, `ecto_connection_resolver_test.exs`, `user_mapper/default_attribute_test.exs`. Confirm host apps see plain `attribute_rules` / `group_rules`, deterministic ordering, and persisted-rules-first with fallback — no Ecto rows leaking into runtime consumers. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or existing Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all previously missing references (none missing — see Wave 0 Requirements)
- [ ] No watch-mode flags
- [ ] Feedback latency < 60 seconds
- [ ] `nyquist_compliant: true` set in frontmatter (planner sets this after filling Per-Task Verification Map)

**Approval:** pending
