---
phase: 34
slug: validationpipeline-wiring-enc-01-complete
status: planned
nyquist_compliant: true
wave_0_complete: true
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
| **Config file** | `test/test_helper.exs`; security suites wired via `mix.exs` `ci.security` alias (152-181) |
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

> Populated after planning. Each Success Criterion maps to plan/task automated verification below.
> Run `/gsd:validate-phase 34` after execution to fill the `Status` column against live test files.

| Success Criterion | Requirement | Plan/Task | Threat Ref | Secure Behavior | Test Type | Automated Command | Status |
|-------------------|-------------|-----------|------------|-----------------|-----------|-------------------|--------|
| SC#1 valid EncryptedAssertion → login | ENC-01 | 34-04 T1 (pipeline) + 34-03 (wiring) | T-34-07 / T-34-12 (decrypt-then-verify) | plaintext decrypted, re-parsed via `parse_safely/2`, `do_verify/4` succeeds before any identity field read | unit/e2e | `mix test test/security/xml_enc_adversarial_test.exs --warnings-as-errors` | ⬜ pending |
| SC#2 cleartext+encrypted → `:ambiguous_assertion` before crypto | ENC-01 | 34-03 T2 + 34-04 T1 (fixture 5) | T-34-08 / T-34-14 (CVE-2026-2092) | `{:error, %Error{type: :ambiguous_assertion}}` returned BEFORE `XMLEnc.decrypt/3` invoked | unit | `mix test test/relyra/protocol/ --warnings-as-errors` | ⬜ pending |
| SC#3 non-encrypted path byte-identical no-op | ENC-01 | 34-03 T1/T2 (D-02 branch) | regression | frozen Phase-29 corpus + signed-Response tests unchanged | regression | `mix test --warnings-as-errors` | ⬜ pending |
| SC#4 metadata emits distinct signing + encryption KeyDescriptors | ENC-02 | 34-01 T1/T2 | T-34-01/02/03 | metadata XML contains `<KeyDescriptor use="signing">` and `<KeyDescriptor use="encryption">`, distinct, schema-ordered | unit | `mix test test/relyra/protocol/metadata_test.exs --warnings-as-errors` | ⬜ pending |
| SC#5 all 7 ENC-01 fixtures wired into `ci.security`, each typed error correct | ENC-01 | 34-04 T1/T2 | T-34-13 / T-34-15 (corpus + hollow-gate) | 7 fixtures each assert exact `%Error{type:}`; suite is its own `cmd mix test` line; meta-gate confirms non-hollow | corpus | `mix ci.security` | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

**Read-before-verify guard (strongest auth-bypass test):** the read-before-verify fixture (34-04 T1,
fixture 7) drives end-to-end through `ValidationPipeline` / `Relyra.consume_response/3` and asserts NO
identity field (NameID, attributes) is returned AND a typed verification error fires — proving the
decrypt-then-verify ordering invariant (CVE-2025-54419 class).

---

## Wave 0 Requirements — COVERED BY PLANS

- [x] `test/security/xml_enc_adversarial_test.exs` — new pipeline-level ENC-01 corpus (7 fixtures) → **Plan 34-04 Task 1**, wired into `mix.exs` `ci.security` as its own `cmd mix test ... --warnings-as-errors` line → **Plan 34-04 Task 2**
- [x] `FakeIdP.encrypt`/`encrypted_response` helper — canonical OAEP+AES-256-GCM `<EncryptedAssertion>` generator → **Plan 34-02 Task 1** (round-trip smoke test Task 2); prerequisite for the corpus (depends_on in 34-04)
- [x] metadata test extension — assert both KeyDescriptors, ordering, X509Certificate body → **Plan 34-01 Task 2**
- [x] `mix.exs` `ci.security` corpus line + `ci_gate_integrity_test.exs` confirmation → **Plan 34-04 Task 2**

*Existing ExUnit + `ci.security` infrastructure covers all other phase requirements — no framework install needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real encryption-enabled IdP interop (end-to-end live login) | ENC-01 | Requires a live IdP configured to encrypt assertions; out of CI scope | Configure SP `:sp_encryption_cert_pem` + `:sp_private_key_pem` against a real encrypting IdP; confirm login succeeds |

*All adversarial/security behaviors have automated verification via the ENC-01 corpus; only live-IdP interop is manual.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies (every task in 34-01..34-04 carries an `<automated>` command)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (FakeIdP encrypt, corpus, metadata test, ci.security wiring all planned)
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved (planning complete 2026-05-25)
