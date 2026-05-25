---
phase: 33
slug: key-resolver-behaviour-xmlenc-crypto-core
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-25
audited: 2026-05-25
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
| KeyResolver behaviour | 01 | 1 | ENC-04a | — | `KeyResolver.resolve/2` dispatches to configured adapter | unit | `mix test test/relyra/key_resolver_test.exs --warnings-as-errors` | ✅ | ✅ green |
| KeyResolver.Default nil config | 01 | 1 | ENC-04b | — | Returns `{:error, :key_not_configured}` when config nil | unit | `mix test test/relyra/key_resolver_test.exs --warnings-as-errors` | ✅ | ✅ green |
| KeyResolver.Default with config | 01 | 1 | ENC-04c | — | Returns `{:ok, pem}` when config is set | unit | `mix test test/relyra/key_resolver_test.exs --warnings-as-errors` | ✅ | ✅ green |
| XMLEnc PKCS1v1.5 block | 02 | 2 | ENC-04d | T-33-01 | RSA-PKCS1v1.5 key transport returns `:decryption_failed` | security corpus | `mix test test/security/xml_enc_test.exs --warnings-as-errors` | ✅ | ✅ green |
| XMLEnc AES-CBC block | 02 | 2 | ENC-04e | T-33-02 | AES-CBC content encryption returns `:decryption_failed` | security corpus | `mix test test/security/xml_enc_test.exs --warnings-as-errors` | ✅ | ✅ green |
| XMLEnc truncated GCM tag | 02 | 2 | ENC-04f | T-33-03 | Truncated GCM auth tag (< 16 bytes) returns `:decryption_failed` | security corpus | `mix test test/security/xml_enc_test.exs --warnings-as-errors` | ✅ | ✅ green |
| XMLEnc malformed ciphertext | 02 | 2 | ENC-04g | T-33-04 | Malformed ciphertext returns `:decryption_failed` | security corpus | `mix test test/security/xml_enc_test.exs --warnings-as-errors` | ✅ | ✅ green |
| DiagnosticBundle key exclusion | 02 | 2 | ENC-04h | T-33-05 | SP private key not surfaced in diagnostic bundle | unit/assertion | `mix test test/relyra/diagnostic/allow_list_test.exs --warnings-as-errors` | ✅ | ✅ green |
| ci.security meta-gate | 02 | 2 | ENC-04d–g | — | `ci_gate_integrity_test.exs` verifies `xml_enc_test.exs` is gated | meta | `mix test test/security/ci_gate_integrity_test.exs --warnings-as-errors` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/security/xml_enc_test.exs` — 5-case corpus (ENC-04d through ENC-04g + valid happy path): RSA-PKCS1v1.5, AES-CBC, truncated GCM auth tag, malformed ciphertext — all return `:decryption_failed`; valid RSA-OAEP + AES-256-GCM returns `{:ok, plaintext}`
- [x] `test/relyra/key_resolver_test.exs` — dispatch + default impl (ENC-04a through ENC-04c), 7 tests
- [x] `mix.exs` `ci.security` alias — contains `cmd mix test test/security/xml_enc_test.exs --warnings-as-errors`
- [x] `test/security/ci_gate_integrity_test.exs` — contains `{"test/security/xml_enc_test.exs", nil}` in `@gated_suites`

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** ✅ signed off 2026-05-25

---

## Validation Audit 2026-05-25

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
| Total requirements audited | 9 |
| All COVERED | 9 |

**Audit notes:** All implementation files present at audit time. Test runs:
- `test/relyra/key_resolver_test.exs` → 7 tests, 0 failures ✅
- `test/security/xml_enc_test.exs` → 5 tests, 0 failures ✅ (4 adversarial cases + 1 happy-path bonus test)
- `test/relyra/diagnostic/allow_list_test.exs` → 7 tests, 0 failures ✅
- `test/security/ci_gate_integrity_test.exs` → 4 tests, 0 failures ✅

No gaps — gsd-nyquist-auditor not spawned (all requirements COVERED at audit time).
