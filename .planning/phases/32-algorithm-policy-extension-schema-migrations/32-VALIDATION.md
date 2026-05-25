---
phase: 32
slug: algorithm-policy-extension-schema-migrations
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-25
audited: 2026-05-25
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
| 32-T1 | 01 | 1 | ENC-03 | PKCS1v1.5 hard-reject | `enforce_key_transport_algorithm/2` rejects `rsa-1_5` URI with no escape hatch | unit | `mix test test/relyra/security/algorithm_policy_test.exs --warnings-as-errors` | ✅ extend existing | ✅ green |
| 32-T2 | 01 | 1 | ENC-03 | AES-CBC default reject | `enforce_content_encryption_algorithm/3` rejects AES-CBC URIs by default | unit | `mix test test/relyra/security/algorithm_policy_test.exs --warnings-as-errors` | ✅ extend existing | ✅ green |
| 32-T3 | 01 | 1 | ENC-03 | AES-CBC escape hatch | `enforce_content_encryption_algorithm/3` allows AES-CBC when `legacy_aes_cbc` hatch active and not expired | unit | `mix test test/relyra/security/algorithm_policy_test.exs --warnings-as-errors` | ✅ extend existing | ✅ green |
| 32-T4 | 01 | 1 | ENC-03 | Auth tag truncation guard | `enforce_content_encryption_algorithm/3` returns `:decryption_failed` for auth_tag < 16 bytes, before calling `:crypto` | unit | `mix test test/relyra/security/algorithm_policy_test.exs --warnings-as-errors` | ✅ extend existing | ✅ green |
| 32-T5 | 01 | 1 | ENC-03 | Strict default proof | New enforce functions covered in `strict_default_proof_test.exs` | unit | `mix test test/security/strict_default_proof_test.exs --warnings-as-errors` | ✅ extend existing | ✅ green |
| 32-T6 | 02 | 2 | ENC-04/AUTHN-02 | Migration + schema | `party`/`use` Ecto.Enum accepts valid values/rejects invalid; `sign_authn_requests` cast by draft+update changesets; existing 101 ecto tests still pass | unit + integration | `mix test test/relyra/ecto/ --warnings-as-errors` | ✅ extended (audit 2026-05-25) | ✅ green |
| 32-T7 | 02 | 2 | ENC-04/AUTHN-02 | Snapshot regression | Existing cert rollover, snapshot, and expiry tests still pass | regression | `mix test --warnings-as-errors` | ✅ existing | ✅ green |

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

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** 2026-05-25 — all 7 tasks green, 0 escalations

---

## Validation Audit 2026-05-25

| Metric | Count |
|--------|-------|
| Gaps found | 3 |
| Resolved (automated) | 3 |
| Escalated to manual | 0 |

**Gaps filled by `gsd-nyquist-auditor`:**
- T6a: `certificate_schema_test.exs` — `:party` Ecto.Enum accepts `:idp`/`:sp`, rejects invalid atoms (T-32-05 proof)
- T6b: `certificate_schema_test.exs` — `:use` Ecto.Enum accepts `:signing`/`:encryption`, rejects invalid atoms (T-32-05 proof)
- T6c: `connection_schema_test.exs` — `:sign_authn_requests` cast by `draft_changeset` and `update_changeset`, defaults `false` (T-32-06 proof)

**Commit:** `2f26c08` — `test(phase-32): add Nyquist validation tests for party/use Ecto.Enum and sign_authn_requests`
