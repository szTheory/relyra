---
phase: 13
slug: certificate-rollover-validation-verification
status: ready_for_verify
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-05
---

# Phase 13 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via Mix on Elixir `1.19.5` |
| **Config file** | `mix.exs`, `test/test_helper.exs`, and `config/test.exs` |
| **Quick run command** | `mix test test/relyra/ecto/certificate_inventory_expiry_test.exs test/relyra/ecto/certificate_inventory_transition_test.exs test/relyra/ecto/certificate_inventory_concurrency_test.exs test/relyra/ecto/ecto_connection_resolver_test.exs test/relyra/connection_snapshot_test.exs --warnings-as-errors` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Estimated runtime** | < 45 seconds for the focused rollover packet |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/relyra/ecto/certificate_inventory_expiry_test.exs test/relyra/ecto/certificate_inventory_transition_test.exs test/relyra/ecto/certificate_inventory_concurrency_test.exs test/relyra/ecto/ecto_connection_resolver_test.exs test/relyra/connection_snapshot_test.exs --warnings-as-errors`
- **After every plan wave:** Run `mix compile --warnings-as-errors`
- **Before `$gsd-verify-work`:** `mix test --warnings-as-errors` must be green
- **Max feedback latency:** < 45 seconds for the focused rollover packet

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 13-01-T01 | 13-01 | 1 | CFG-04 | TM-13-01-TRACEABILITY-DRIFT | Phase 10 validation truth matches the shipped rollover proof surface and no longer claims missing Wave 0 coverage | documentation + verification | `mix test test/relyra/ecto/certificate_inventory_expiry_test.exs test/relyra/ecto/certificate_inventory_transition_test.exs test/relyra/ecto/certificate_inventory_concurrency_test.exs test/relyra/ecto/ecto_connection_resolver_test.exs test/relyra/connection_snapshot_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 13-02-T01 | 13-02 | 2 | CFG-04 | TM-13-02-EVIDENCE-GAP | `10-VERIFICATION.md` records exact serial commands, current counts, and behavior-to-proof mapping for expiry, transition, rollback, conflict, and active-only runtime trust | integration | `mix compile --warnings-as-errors && mix test test/relyra/ecto/certificate_inventory_expiry_test.exs test/relyra/ecto/certificate_inventory_transition_test.exs test/relyra/ecto/certificate_inventory_concurrency_test.exs test/relyra/ecto/ecto_connection_resolver_test.exs test/relyra/connection_snapshot_test.exs --warnings-as-errors && mix test --warnings-as-errors` | ✅ | ⬜ pending |
| 13-03-T01 | 13-03 | 3 | CFG-04 | TM-13-03-ORPHANED-TRUTH | Live milestone truth surfaces stop reporting `CFG-04` as pending/orphaned once verification exists | documentation + traceability | `rg -n "CFG-04|Phase 13|ready_for_verify|verified|complete" .planning/REQUIREMENTS.md .planning/ROADMAP.md .planning/STATE.md .planning/phases/10-certificate-inventory-rollover/10-VERIFICATION.md` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠ flaky*

---

## Wave 0 Requirements

- [x] `test/relyra/ecto/certificate_inventory_expiry_test.exs` — expiry derivation and persistence for imported/staged certificates
- [x] `test/relyra/ecto/certificate_inventory_transition_test.exs` — invalid lifecycle transition coverage and typed errors
- [x] `test/relyra/ecto/certificate_inventory_concurrency_test.exs` — concurrent promotion/rollback conflict behavior
- [x] `test/relyra/ecto/ecto_connection_resolver_test.exs` and `test/relyra/connection_snapshot_test.exs` — resolver/runtime proof that only active signing certs hydrate into runtime trust

Wave 0 is already complete in the current repo state. Phase 13 consumes that proof surface and closes the stale verification metadata around it.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| The rollover API and typed conflict errors read as clear caller guidance for promote, retire, and rollback flows | CFG-04 | Automated tests prove correctness, but a human still needs to judge whether retry/refresh/abort expectations are obvious | Review `lib/relyra/ecto/certificate_inventory.ex`, the transition/concurrency tests, and the final `10-VERIFICATION.md` prose; confirm the action implied by conflict and invalid-transition failures is still least-surprise |
| Runtime trust still consumes only active signing certs while staged and retired rows remain durable inventory facts only | CFG-04 | The tests prove filtering, but the product semantics still need explicit human confirmation | Review `lib/relyra/ecto/connection_snapshot.ex`, `test/relyra/ecto/ecto_connection_resolver_test.exs`, `test/relyra/connection_snapshot_test.exs`, and the final `10-VERIFICATION.md` narrative; confirm staged/retired rows are described as inventory-only until promoted |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or existing Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all previously missing references
- [x] No watch-mode flags
- [x] Feedback latency < 45 seconds
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
