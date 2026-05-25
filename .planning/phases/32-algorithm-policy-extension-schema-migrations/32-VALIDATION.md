---
phase: 32
slug: algorithm-policy-extension-schema-migrations
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-25
---

# Phase 32 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in Elixir) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/relyra/security/algorithm_policy_test.exs --warnings-as-errors` |
| **Full suite command** | `mix test --warnings-as-errors` |
| **Estimated runtime** | ~30 seconds (full), ~5 seconds (quick) |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/relyra/security/algorithm_policy_test.exs --warnings-as-errors`
- **After every plan wave:** Run `mix test --warnings-as-errors && mix ci.security`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 32-T1 | 01 | 1 | ENC-03 | PKCS1v1.5 hard-reject | `enforce_key_transport_algorithm/2` rejects `rsa-1_5` URI with no escape hatch | unit | `mix test test/relyra/security/algorithm_policy_test.exs --warnings-as-errors` | ✅ extend existing | ⬜ pending |
| 32-T2 | 01 | 1 | ENC-03 | AES-CBC default reject | `enforce_content_encryption_algorithm/2` rejects AES-CBC URIs by default | unit | `mix test test/relyra/security/algorithm_policy_test.exs --warnings-as-errors` | ✅ extend existing | ⬜ pending |
| 32-T3 | 01 | 1 | ENC-03 | AES-CBC escape hatch | `enforce_content_encryption_algorithm/2` allows AES-CBC when `legacy_aes_cbc` hatch active and not expired | unit | `mix test test/relyra/security/algorithm_policy_test.exs --warnings-as-errors` | ✅ extend existing | ⬜ pending |
| 32-T4 | 01 | 1 | ENC-03 | Auth tag truncation guard | `enforce_content_encryption_algorithm/2` returns `:decryption_failed` for auth_tag < 16 bytes, before calling `:crypto` | unit | `mix test test/relyra/security/algorithm_policy_test.exs --warnings-as-errors` | ✅ extend existing | ⬜ pending |
| 32-T5 | 01 | 1 | ENC-03 | Strict default proof | New enforce functions covered in `strict_default_proof_test.exs` | unit | `mix test test/security/strict_default_proof_test.exs --warnings-as-errors` | ✅ extend existing | ⬜ pending |
| 32-T6 | 02 | 2 | ENC-04/AUTHN-02 | Migration + schema | `party`/`use` on cert schema, `sign_authn_requests` on connection schema; all existing rows receive safe defaults | integration | `mix test test/relyra/ecto/ --warnings-as-errors` | ✅ extend existing | ⬜ pending |
| 32-T7 | 02 | 2 | ENC-04/AUTHN-02 | Snapshot regression | Existing cert rollover, snapshot, and expiry tests still pass | regression | `mix ci.verify` | ✅ existing | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*None — existing test infrastructure covers all phase requirements. New `describe` blocks are added to `test/relyra/security/algorithm_policy_test.exs` within existing tasks. No new test file creation needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Migration applied against real Postgres without data loss | ENC-04 / AUTHN-02 | Requires running database | Run `mix ecto.migrate` against a test DB and verify `SELECT party, use FROM relyra_connection_certificates LIMIT 5` shows `idp`/`signing` defaults; verify `\d relyra_connections` shows `sign_authn_requests` boolean column |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
