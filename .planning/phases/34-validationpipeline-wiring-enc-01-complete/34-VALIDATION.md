---
phase: 34
slug: validationpipeline-wiring-enc-01-complete
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-25
---

# Phase 34 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `34-RESEARCH.md` "## Validation Architecture" (5 Success Criteria + 7 ENC-01 fixtures).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5 / OTP 28) |
| **Config file** | `test/test_helper.exs`; security suites wired via `mix.exs` `ci.security` alias (152-173) |
| **Quick run command** | `mix test test/security/xml_enc_adversarial_test.exs --warnings-as-errors` |
| **Full suite command** | `mix test --warnings-as-errors && mix ci.security` |
| **Estimated runtime** | ~30s quick; ~90s full (`ci.security` runs each security suite as its own `cmd mix test` subprocess) |

---

## Sampling Rate

- **After every task commit:** Run the quick command (focused on the file/suite touched)
- **After every plan wave:** Run `mix test --warnings-as-errors`
- **Before `/gsd:verify-work`:** `mix test --warnings-as-errors && mix ci.security && mix format --check-formatted` must all be green
- **Max feedback latency:** ~30 seconds (quick); ~90 seconds (full security gate)

---

## Per-Task Verification Map

> Populated after planning produces task IDs. Seeded from the RESEARCH.md Validation Architecture
> (5 Success Criteria → verification approach). Run `/gsd:validate-phase 34` after execution to fill
> the `File Exists` / `Status` columns against the live test files.

| Success Criterion | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | Status |
|-------------------|-------------|------------|-----------------|-----------|-------------------|--------|
| SC#1 valid EncryptedAssertion → login | ENC-01 | decrypt-then-verify | plaintext decrypted, re-parsed via `parse_safely/2`, `do_verify/4` succeeds before any identity field read | unit/e2e | `mix test test/security/xml_enc_adversarial_test.exs` | ⬜ pending |
| SC#2 cleartext+encrypted → `:ambiguous_assertion` before crypto | ENC-01 | T-ambiguity (CVE-2026-2092) | `{:error, %Error{type: :ambiguous_assertion}}` returned BEFORE `XMLEnc.decrypt/3` invoked | unit | `mix test test/security/xml_enc_adversarial_test.exs` | ⬜ pending |
| SC#3 non-encrypted path byte-identical no-op | ENC-01 | regression | frozen Phase-29 corpus + signed-Response tests unchanged | regression | `mix test --warnings-as-errors` | ⬜ pending |
| SC#4 metadata emits distinct signing + encryption KeyDescriptors | ENC-02 | — | metadata XML contains `<KeyDescriptor use="signing">` and `<KeyDescriptor use="encryption">`, distinct certs | unit | `mix test test/relyra/protocol/metadata_test.exs` (or controller test) | ⬜ pending |
| SC#5 all 7 ENC-01 fixtures wired into `ci.security`, each typed error correct | ENC-01 | T-corpus | 7 fixtures (wrong-key, truncated-tag, PKCS1v1.5, CBC, cleartext-injection, malformed-ciphertext, read-before-verify) each assert exact `%Error{type:}`; suite is its own `cmd mix test` line | corpus | `mix ci.security` | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

**Read-before-verify guard (strongest auth-bypass test):** the read-before-verify fixture drives
end-to-end through `ValidationPipeline` and asserts NO identity field (NameID, attributes) is
returned AND a typed verification error fires — proving the decrypt-then-verify ordering invariant
(CVE-2025-54419 class).

---

## Wave 0 Requirements

- [ ] `test/security/xml_enc_adversarial_test.exs` — new pipeline-level ENC-01 corpus (7 fixtures), added to `mix.exs` `ci.security` as its own `cmd mix test ... --warnings-as-errors` line (hollow-gate rule)
- [ ] `FakeIdP.encrypt`/`encrypted_response` helper — canonical OAEP+AES-256-GCM `<EncryptedAssertion>` generator (promoted from `xml_enc_test.exs:28-56`)

*Existing ExUnit + `ci.security` infrastructure covers all other phase requirements — no framework install needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real encryption-enabled IdP interop (end-to-end live login) | ENC-01 | Requires a live IdP configured to encrypt assertions; out of CI scope | Configure SP `:sp_encryption_cert_pem` + `:sp_private_key_pem` against a real encrypting IdP; confirm login succeeds |

*All adversarial/security behaviors have automated verification via the ENC-01 corpus; only live-IdP interop is manual.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 90s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
