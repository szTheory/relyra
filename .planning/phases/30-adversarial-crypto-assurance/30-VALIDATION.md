---
phase: 30
slug: adversarial-crypto-assurance
status: planned
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-24
---

# Phase 30 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source analysis: `30-RESEARCH.md` → `## Validation Architecture`.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (bundled, Elixir 1.19.5 / OTP 28) |
| **Config file** | none — standard `mix test`; aliases in `mix.exs:130-186` |
| **Quick run command** | `mix test test/security/xml/adversarial_crypto_test.exs --only adversarial_crypto --warnings-as-errors` |
| **Full suite command** | `mix ci.security` |
| **Estimated runtime** | new suite ~1–3s; `mix ci.security` ~30–60s (corpus + conformance + audits) |

---

## Sampling Rate

- **After every task commit:** `mix test test/security/xml/adversarial_crypto_test.exs --only adversarial_crypto --warnings-as-errors` (new suite) + `mix test test/security/xml/corpus_security_test.exs --only security_corpus --warnings-as-errors` (when the JSON corpus row changed)
- **After every plan wave:** `mix relyra.conformance --check` (drift) + `mix test --only security_corpus --only gate02_c14n --only adversarial_crypto --warnings-as-errors`
- **Before `/gsd:verify-work`:** `mix ci.security` green (full alias) AND `mix test --warnings-as-errors` (full suite — no regression to the existing baseline; new suite raises the count, never lowers it)
- **Max feedback latency:** ~3 seconds (quick run)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 30-01-T1 | 30-01 | 1 | ASSUR-02 | T-30-02 | FakeIdP SignedInfo gains <CanonicalizationMethod>, drops whitespace-collapse, keeps SAML ns (D-02) | compile/shape | `mix compile --warnings-as-errors` | ❌ W0 (modify fake_idp.ex) | ⬜ pending |
| 30-01-T2 | 30-01 | 1 | ASSUR-02 | T-30-01, T-30-03 | FakeIdP.sign delegates to XmldsigSigner.sign_response/1 (real DigestValue+SignatureValue); self_signed_cert_pem/0 exposed; demo test green | integration | `mix compile --warnings-as-errors && mix test test/test_support_demo_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| 30-02-T1 | 30-02 | 2 | ASSUR-01, ASSUR-02 | T-30-06, T-30-07, T-30-08, T-30-09 | positive control {:ok, %SignedNode{}} via FakeIdP.sign; forged/wrong-key → :invalid_signature; tampered → :digest_mismatch; ECDSA → :unsupported_signature_algorithm | unit+integration | `mix test test/security/xml/adversarial_crypto_test.exs --only adversarial_crypto --warnings-as-errors` | ❌ W0 (new suite) | ⬜ pending |
| 30-02-T2 | 30-02 | 2 | ASSUR-01 | T-30-05, T-30-10 | C14N-PRESERVED post-sign mutation (added attribute) → :digest_mismatch (NEW, D-06); no WR-03 fix | unit | `mix test test/security/xml/adversarial_crypto_test.exs --only adversarial_crypto --warnings-as-errors` | ❌ W0 — NEW (D-06) | ⬜ pending |
| 30-03-T1 | 30-03 | 1 | ASSUR-01 | T-30-11, T-30-13 | JSON corpus row asserts :canonicalization_failed (NOT :digest_mismatch); full provenance | corpus | `mix test test/security/xml/corpus_security_test.exs --only security_corpus --warnings-as-errors` | ❌ W0 — NEW row (D-09) | ⬜ pending |
| 30-03-T2 | 30-03 | 1 | ASSUR-01 | T-30-12 | CONFORMANCE.md regenerated; drift gate green | drift | `mix relyra.conformance --check` | ❌ W0 (regen) | ⬜ pending |
| 30-04-T1 | 30-04 | 3 | ASSUR-01 | T-30-14 | :adversarial_crypto suite named in ci.security with --warnings-as-errors (D-08) | gate-wiring | `grep -v '^#' mix.exs \| grep -c 'adversarial_crypto_test.exs --only adversarial_crypto --warnings-as-errors'` (==1) | ❌ W0 (alias edit) | ⬜ pending |
| 30-04-T2 | 30-04 | 3 | ASSUR-01 | T-30-15, T-30-16, T-30-17 | mix ci.security green end-to-end (suite executes, non-zero count); full mix test no regression | gate | `mix ci.security && mix test --warnings-as-errors` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] New adversarial crypto-verify suite file `test/security/xml/adversarial_crypto_test.exs` (Plan 02) — covers ASSUR-01 (5 categories + positive control + ECDSA carry-over)
- [ ] `FakeIdP.sign` promotion: delegate to `XmldsigSigner.sign_response/1`, add `<CanonicalizationMethod>`, drop whitespace-collapse (Plan 01, D-02) — ASSUR-02
- [ ] `FakeIdP.self_signed_cert_pem/0` delegate (Plan 01, D-03)
- [ ] NEW `priv/security_corpus.json` row (`canonicalization_failed` class, Plan 03, D-09) + `CONFORMANCE.md` regen
- [ ] `ci.security` alias edit naming the new suite (Plan 04, D-08)
- [ ] Framework install: none — ExUnit bundled

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| — | — | — | All phase behaviors have automated verification (`mix ci.security`). |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 3s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** planner — 2026-05-24
