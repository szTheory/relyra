---
phase: 14
slug: mapping-audit-milestone-verification
status: ready_for_verify
nyquist_compliant: true
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

> Filled by `gsd-planner`. Each plan task in `14-01-PLAN.md` and `14-02-PLAN.md` has an entry below with a grep-verifiable or Mix-verifiable automated command. The Manual Sign-Off task (14-01-T05) has its automated command set to the `rg -nF` verifier for the literal `Manual approval status: approved.` line per D-11 — manual review records its outcome in the artifact, and the artifact is grep-verified.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 14-01-T01 | 14-01 | 1 | CFG-05 | TM-14-01-01 / TM-14-01-03 | Verification packet step 1 (`mix compile --warnings-as-errors`) executes serially and emits the literal `compile succeeded with no warnings` result for transcription into the Automated Evidence Packet table | mix-compile | `mix compile --warnings-as-errors` | ✅ existing | ⬜ pending |
| 14-01-T02 | 14-01 | 1 | CFG-05 | TM-14-01-01 / TM-14-01-03 | Verification packet step 2 (focused 13-file mapping/audit serial command, single Mix invocation, `--warnings-as-errors`) executes serially after step 1 returns and emits `nn tests, 0 failures` for transcription | mix-test (focused) | `mix test test/relyra/ecto/mapping_commands_test.exs test/relyra/ecto/audit_hardening_test.exs test/relyra/ecto/attribute_mapping_schema_test.exs test/relyra/ecto/group_mapping_schema_test.exs test/relyra/ecto/mapping_revision_schema_test.exs test/relyra/ecto/audit_event_schema_test.exs test/relyra/ecto/migration_constraints_test.exs test/relyra/connection_snapshot_test.exs test/relyra/user_mapper/default_attribute_test.exs test/relyra/ecto/ecto_connection_resolver_test.exs test/relyra/ecto/connection_record_test.exs test/relyra/ecto/metadata_apply_test.exs test/relyra/ecto/certificate_inventory_transition_test.exs --warnings-as-errors` | ✅ existing | ⬜ pending |
| 14-01-T03 | 14-01 | 1 | CFG-05 | TM-14-01-01 / TM-14-01-03 | Verification packet step 3 (`mix test --warnings-as-errors`) executes serially after step 2 returns and emits `nn tests, 0 failures` for transcription | mix-test (full) | `mix test --warnings-as-errors` | ✅ existing | ⬜ pending |
| 14-01-T04 | 14-01 | 1 | CFG-05 | TM-14-01-01 / TM-14-01-04 | `11-VERIFICATION.md` exists with the 6 locked sections in fixed order, names CFG-05 explicitly, embeds the 4 D-07 row labels verbatim, records the exact 3 D-06 commands with ISO-8601 UTC timestamps and observed `nn tests, 0 failures` counts, and declares `Execution mode: serial only.` — and no historical audit artifact has been mutated | grep (artifact-shape) | `test -f .planning/phases/11-mapping-persistence-audit-hardening/11-VERIFICATION.md && rg -nF -- '# Phase 11 Verification' .planning/phases/11-mapping-persistence-audit-hardening/11-VERIFICATION.md && rg -nF -- 'Requirement: \`CFG-05\` - User can persist attribute/group mapping configuration and review a durable audit history of trust changes.' .planning/phases/11-mapping-persistence-audit-hardening/11-VERIFICATION.md && rg -nF -- '\| CFG-05 behavior \| Proof source \| Evidence \|' .planning/phases/11-mapping-persistence-audit-hardening/11-VERIFICATION.md && rg -nF -- '\| Mapping persistence (live rows + revision ledger) \|' .planning/phases/11-mapping-persistence-audit-hardening/11-VERIFICATION.md && rg -nF -- '\| Cross-domain audit hardening (same-transaction capture) \|' .planning/phases/11-mapping-persistence-audit-hardening/11-VERIFICATION.md && rg -nF -- '\| Audited mapping mutation surface \|' .planning/phases/11-mapping-persistence-audit-hardening/11-VERIFICATION.md && rg -nF -- '\| Runtime mapping_config hydration \|' .planning/phases/11-mapping-persistence-audit-hardening/11-VERIFICATION.md && rg -nF -- 'Execution mode: serial only.' .planning/phases/11-mapping-persistence-audit-hardening/11-VERIFICATION.md && rg -nF -- 'mix compile --warnings-as-errors' .planning/phases/11-mapping-persistence-audit-hardening/11-VERIFICATION.md && rg -nF -- 'mix test --warnings-as-errors' .planning/phases/11-mapping-persistence-audit-hardening/11-VERIFICATION.md && rg -nE -- '\`[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z\`' .planning/phases/11-mapping-persistence-audit-hardening/11-VERIFICATION.md && rg -nE -- '\`[0-9]+ tests, 0 failures\`' .planning/phases/11-mapping-persistence-audit-hardening/11-VERIFICATION.md` | ✅ created by this task | ⬜ pending |
| 14-01-T05 | 14-01 | 1 | CFG-05 | TM-14-01-02 | Two D-10 manual semantics prompts present verbatim, operator prose recorded, terminator `Manual approval status: approved.` written as final non-blank line; per D-11 the gate cannot be repurposed as a functional re-test | grep (manual sign-off) | `rg -nF -- '## Manual Sign-Off' .planning/phases/11-mapping-persistence-audit-hardening/11-VERIFICATION.md && rg -nF -- 'Manual approval status: approved.' .planning/phases/11-mapping-persistence-audit-hardening/11-VERIFICATION.md` | ✅ artifact from T04 | ⬜ pending |
| 14-02-T01 | 14-02 | 2 | CFG-05 | TM-14-02-01 / TM-14-02-02 / TM-14-02-03 | REQUIREMENTS.md flips CFG-05 to satisfied at all three anchors (checkbox `[x]`, traceability row `Complete`, footer stamp `after Phase 14 execution`), preconditioned on `11-VERIFICATION.md` containing `Manual approval status: approved.` | grep (live-truth) | `rg -nF -- 'Manual approval status: approved.' .planning/phases/11-mapping-persistence-audit-hardening/11-VERIFICATION.md && rg -nF -- '- [x] **CFG-05**: User can persist attribute/group mapping configuration and review a durable audit history of trust changes.' .planning/REQUIREMENTS.md && rg -nF -- '\| CFG-05 \| Phase 14 \| Complete \|' .planning/REQUIREMENTS.md && rg -nF -- '*Last updated: 2026-05-06 after Phase 14 execution*' .planning/REQUIREMENTS.md` | ✅ existing | ⬜ pending |
| 14-02-T02 | 14-02 | 2 | CFG-05 | TM-14-02-01 / TM-14-02-02 / TM-14-02-03 | ROADMAP.md Phase 14 detail block extended with `- Status: complete (verified after Phase 14 execution).` (byte-aligned with Phase 13 verifier), `- Plans: 2 plans.`, and the 2-entry `- Plan list:` with `[x]` checkboxes; no other phase block, summary table, or historical artifact mutated | grep (live-truth) | `rg -nF -- '**Phase 14: Mapping/audit milestone verification**' .planning/ROADMAP.md && rg -nF -- '- Status: complete (verified after Phase 14 execution).' .planning/ROADMAP.md && rg -nF -- '- Plans: 2 plans.' .planning/ROADMAP.md && rg -nF -- '- [x] \`14-01-PLAN.md\` — create \`11-VERIFICATION.md\` from the locked serial packet and blocking manual sign-off gate.' .planning/ROADMAP.md && rg -nF -- '- [x] \`14-02-PLAN.md\` — update live milestone truth in \`REQUIREMENTS.md\`, \`ROADMAP.md\`, and \`STATE.md\` after CFG-05 verification closure.' .planning/ROADMAP.md` | ✅ existing | ⬜ pending |
| 14-02-T03 | 14-02 | 2 | CFG-05 | TM-14-02-01 / TM-14-02-02 / TM-14-02-03 | STATE.md frontmatter advances by exactly +1 phase and +2 plans (`completed_phases: 7`, `total_plans: 25`, `completed_plans: 25`), body shows the byte-aligned `Phase: 14 (mapping-audit-milestone-verification) — COMPLETE` and `**Current focus:** Phase 14 — mapping-audit-milestone-verification (complete)` markers, resume-file pointer repointed at `11-VERIFICATION.md`; old `CONTEXT GATHERED` / `Plan: 0 of 0` / `14-CONTEXT.md` strings absent | grep (live-truth) | `rg -nF -- 'total_plans: 25' .planning/STATE.md && rg -nF -- 'completed_plans: 25' .planning/STATE.md && rg -nF -- 'completed_phases: 7' .planning/STATE.md && rg -nF -- '**Current focus:** Phase 14 — mapping-audit-milestone-verification (complete)' .planning/STATE.md && rg -nF -- 'Phase: 14 (mapping-audit-milestone-verification) — COMPLETE' .planning/STATE.md && rg -nF -- 'Plan: 2 of 2' .planning/STATE.md && rg -nF -- 'Resume file: .planning/phases/11-mapping-persistence-audit-hardening/11-VERIFICATION.md' .planning/STATE.md` | ✅ existing | ⬜ pending |

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

- [x] All tasks have `<automated>` verify or existing Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all previously missing references (none missing — see Wave 0 Requirements)
- [x] No watch-mode flags
- [x] Feedback latency < 60 seconds
- [x] `nyquist_compliant: true` set in frontmatter (planner sets this after filling Per-Task Verification Map)

**Approval:** ready_for_verify
