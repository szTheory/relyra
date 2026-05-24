---
phase: 30
slug: adversarial-crypto-assurance
status: draft
nyquist_compliant: false
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
| **Quick run command** | `mix test <new_suite_path> --warnings-as-errors` |
| **Full suite command** | `mix ci.security` |
| **Estimated runtime** | new suite ~1–3s; `mix ci.security` ~30–60s (corpus + conformance + audits) |

---

## Sampling Rate

- **After every task commit:** `mix test <new_suite> --only adversarial_crypto --warnings-as-errors` (new suite) + `mix test test/security/xml/corpus_security_test.exs --only security_corpus --warnings-as-errors` (when the JSON corpus row changed)
- **After every plan wave:** `mix relyra.conformance --check` (drift) + `mix test --only security_corpus --only gate02_c14n --only adversarial_crypto --warnings-as-errors`
- **Before `/gsd:verify-work`:** `mix ci.security` green (full alias) AND `mix test --warnings-as-errors` (full suite — no regression to the existing baseline; new suite raises the count, never lowers it)
- **Max feedback latency:** ~3 seconds (quick run)

---

## Per-Task Verification Map

> Planner populates Task IDs / Plan / Wave once PLAN.md files exist. Requirement→behavior→command rows below are pre-derived from `30-RESEARCH.md` §Phase Requirements → Test Map.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | ASSUR-02 | T-30-real-signing | `FakeIdP.sign` emits real DigestValue+SignatureValue; positive control verifies `{:ok}` via FakeIdP cert | integration | `mix test <new_suite> --only adversarial_crypto` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | ASSUR-01 (forged-sig) | T-30-forged | same-length random SignatureValue → `:invalid_signature` | unit | `mix test <new_suite> --only adversarial_crypto` | ✅ recipe `signature_crypto_test.exs:81-90` | ⬜ pending |
| TBD | TBD | TBD | ASSUR-01 (wrong-key) | T-30-wrongkey | genuine doc vs throwaway cert → `:invalid_signature` | unit | `mix test <new_suite> --only adversarial_crypto` | ✅ `:215-224` | ⬜ pending |
| TBD | TBD | TBD | ASSUR-01 (tampered-content) | T-30-tamper | `tamper_name_id:` → `:digest_mismatch` | unit | `mix test <new_suite> --only adversarial_crypto` | ✅ `:226-235` | ⬜ pending |
| TBD | TBD | TBD | ASSUR-01 (c14n-differential digest) | T-30-c14n | C14N-PRESERVED post-sign mutation → `:digest_mismatch` | unit | `mix test <new_suite> --only adversarial_crypto` | ❌ W0 — NEW (D-06) | ⬜ pending |
| TBD | TBD | TBD | ASSUR-01 (positive control) | T-30-positive | genuine FakeIdP-signed → `{:ok, %SignedNode{}}` | integration | `mix test <new_suite> --only adversarial_crypto` | ✅ `:203-213` | ⬜ pending |
| TBD | TBD | TBD | ASSUR-01 (ECDSA fail-closed — 6th assertion) | T-30-ecdsa | unsupported alg → `:unsupported_signature_algorithm` | unit | `mix test <new_suite> --only adversarial_crypto` | ✅ `:131-141` — carry into gate | ⬜ pending |
| TBD | TBD | TBD | ASSUR-01 (c14n REJECTION row) | T-30-corpus | JSON corpus row asserts `:canonicalization_failed` + CONFORMANCE.md regen | corpus | `mix test test/security/xml/corpus_security_test.exs --only security_corpus` + `mix relyra.conformance --check` | ❌ W0 — NEW (D-09) | ⬜ pending |
| TBD | TBD | TBD | ASSUR-01 (gating) | T-30-gate | new suite named in `ci.security` | gate | `mix ci.security` | ❌ W0 — alias edit (D-08) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] New adversarial crypto-verify suite file (recommend `test/security/xml/adversarial_crypto_test.exs`, colocated with the corpus suites the alias names) — covers ASSUR-01 (5 categories + positive control + ECDSA carry-over)
- [ ] `FakeIdP.sign` promotion: delegate to `XmldsigSigner.sign_response/1`, add `<CanonicalizationMethod>`, drop whitespace-collapse (D-02) — ASSUR-02
- [ ] `FakeIdP.self_signed_cert_pem/0` delegate (D-03)
- [ ] NEW `priv/security_corpus.json` row (`canonicalization_failed` class, D-09) + `CONFORMANCE.md` regen
- [ ] `ci.security` alias edit naming the new suite (D-08)
- [ ] Framework install: none — ExUnit bundled

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| — | — | — | All phase behaviors have automated verification (`mix ci.security`). |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 3s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
