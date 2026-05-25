---
phase: 33
slug: key-resolver-behaviour-xmlenc-crypto-core
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-25
---

# Phase 33 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (OTP 28 stdlib) |
| **Config file** | `test/test_helper.exs` (existing) |
| **Quick run command** | `mix test --warnings-as-errors` |
| **Full suite command** | `mix ci.security` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test --warnings-as-errors`
- **After every plan wave:** Run `mix ci.security`
- **Before `/gsd:verify-work`:** Full `mix ci.security` must be green
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| KeyResolver behaviour | 01 | 1 | ENC-04a | — | `KeyResolver.resolve/2` dispatches to configured adapter | unit | `mix test test/relyra/key_resolver_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| KeyResolver.Default nil config | 01 | 1 | ENC-04b | — | Returns `{:error, :key_not_configured}` when config nil | unit | `mix test test/relyra/key_resolver_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| KeyResolver.Default with config | 01 | 1 | ENC-04c | — | Returns `{:ok, pem}` when config is set | unit | `mix test test/relyra/key_resolver_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| XMLEnc PKCS1v1.5 block | 02 | 2 | ENC-04d | T-33-01 | RSA-PKCS1v1.5 key transport returns `:decryption_failed` | security corpus | `mix test test/security/xml_enc_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| XMLEnc AES-CBC block | 02 | 2 | ENC-04e | T-33-02 | AES-CBC content encryption returns `:decryption_failed` | security corpus | `mix test test/security/xml_enc_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| XMLEnc truncated GCM tag | 02 | 2 | ENC-04f | T-33-03 | Truncated GCM auth tag (< 16 bytes) returns `:decryption_failed` | security corpus | `mix test test/security/xml_enc_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| XMLEnc malformed ciphertext | 02 | 2 | ENC-04g | T-33-04 | Malformed ciphertext returns `:decryption_failed` | security corpus | `mix test test/security/xml_enc_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| DiagnosticBundle key exclusion | 02 | 2 | ENC-04h | T-33-05 | SP private key not surfaced in diagnostic bundle | unit/assertion | `mix test test/relyra/diagnostic/allow_list_test.exs --warnings-as-errors` | ✅ (verify no new paths leak) | ⬜ pending |
| ci.security meta-gate | 02 | 2 | ENC-04d–g | — | `ci_gate_integrity_test.exs` verifies `xml_enc_test.exs` is gated | meta | `mix test test/security/ci_gate_integrity_test.exs --warnings-as-errors` | ✅ (add new suite entry) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/security/xml_enc_test.exs` — 4-case corpus (ENC-04d through ENC-04g): RSA-PKCS1v1.5, AES-CBC, truncated GCM auth tag, malformed ciphertext — all must return `:decryption_failed`
- [ ] `test/relyra/key_resolver_test.exs` — dispatch + default impl (ENC-04a through ENC-04c)
- [ ] `mix.exs` `ci.security` alias — add `cmd mix test test/security/xml_enc_test.exs --warnings-as-errors`
- [ ] `test/security/ci_gate_integrity_test.exs` — add `{"test/security/xml_enc_test.exs", nil}` to `@gated_suites`

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
