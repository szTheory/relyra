---
phase: 29
slug: cryptographic-xmldsig-verification
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-24
---

# Phase 29 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `29-RESEARCH.md` → **Validation Architecture**. The per-task map below is
> requirement-anchored; task-ID columns are reconciled to `*-PLAN.md` task IDs during planning.
> **Heart of this phase:** every check is proven by a *negative control* (rejection — the bypass
> is closed) AND a *positive control* (genuine sign → `{:ok}` — the verifier still works, i.e. it
> isn't an "always reject" stub).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5 / OTP 28; bundled — no install) |
| **Config file** | `test/test_helper.exs` (`ExUnit.start`); aliases in `mix.exs` (`mix qa`, `mix ci.fast`, `mix ci.security`) |
| **Quick run command** | `mix test test/relyra/security/signature_test.exs test/security/signed_node_binding_test.exs --warnings-as-errors` |
| **Full suite command** | `mix ci.security` + `mix test --warnings-as-errors` |
| **Estimated runtime** | quick lane <30s; full suite ~minutes |

---

## Sampling Rate

- **After every task commit:** `mix test test/relyra/security/signature_test.exs test/security/signed_node_binding_test.exs --warnings-as-errors` (crypto + gate-regression unit lane)
- **After every plan wave:** `mix test test/relyra/security/ test/security/ test/relyra/security/xml/ --warnings-as-errors` (security + C14N regression)
- **Before `/gsd:verify-work`:** `mix ci.security` green AND full `mix test --warnings-as-errors` green
- **Max feedback latency:** ~30 seconds (quick lane)

---

## Per-Task Verification Map

> Requirement-anchored (pre-planning). Plan/Wave/Task-ID columns are filled in when `*-PLAN.md`
> tasks exist; the (Req, Secure Behavior, Test Type, Command) tuple is the binding contract.

| Req | Control | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|-----|---------|-----------------|-----------|-------------------|-------------|--------|
| SIGV-01 | negative | Forged `SignatureValue` (well-formed) → `{:error, %Relyra.Error{type: :invalid_signature}}` | unit | `mix test test/relyra/security/signature_test.exs` | ❌ W0 | ⬜ pending |
| SIGV-01 | negative | Wrong-key (genuine sig, different cert) → `:invalid_signature` | unit | `mix test test/relyra/security/signature_test.exs` | ❌ W0 | ⬜ pending |
| SIGV-01 | **positive** | D-11 genuinely-signed node → `{:ok, %SignedNode{}}` | unit | `mix test test/relyra/security/signature_test.exs` | ❌ W0 (needs D-11 signer) | ⬜ pending |
| SIGV-02 | negative | Tampered `NameID` (otherwise-valid sig) → `:digest_mismatch` | unit | `mix test test/relyra/security/signature_test.exs` | ❌ W0 | ⬜ pending |
| SIGV-02 | negative | Truncated/malformed `DigestValue` → `:digest_mismatch` **(no crash — `:crypto.hash_equals/2` length-guard, Pitfall 4)** | unit | `mix test test/relyra/security/signature_test.exs` | ❌ W0 | ⬜ pending |
| SIGV-02 | **positive** | Mixed-content canonical bytes == committed golden (byte-exact, Option-a) | golden-oracle | `mix test test/security/xml/corpus_security_test.exs --only gate02_c14n` | ❌ W0 (new golden) | ⬜ pending |
| SIGV-04 | **positive** | Metadata-root genuine signature → `{:ok}` via same `do_verify` primitive | integration | `mix test test/relyra/security/signature_test.exs` | ❌ W0 (needs metadata pre-parse upgrade) | ⬜ pending |
| SIGV-04 | negative | Signature-VALID but wrong-fingerprint root → rejected (pinning as defense-in-depth, not pinning alone) | integration | `mix test test/relyra/metadata/auto_refresh_test.exs` | ⚠️ extend | ⬜ pending |
| D-07 | negative | ECDSA method fails CLOSED → `:unsupported_signature_algorithm` | unit | `mix test test/relyra/security/signature_test.exs` | ❌ W0 | ⬜ pending |
| D-01 | regression | Existing trust gates (cert_chain empty / `KeyInfo` trust / dup-ID / ambiguous) still reject **before** crypto | unit | `mix test test/security/signed_node_binding_test.exs --warnings-as-errors` | ✅ (stay green) | ⬜ pending |
| D-10 | regression | 887-byte exclusive-C14N golden still byte-exact under Option-a | golden-oracle | `mix test test/security/xml/corpus_security_test.exs --only gate02_c14n` | ✅ (stay green) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/relyra/security/signature_test.exs` — extend with crypto negative + positive controls (SIGV-01/02, D-07)
- [ ] D-11 genuine XMLDSig signer in `test/support/` (on `elixirc_paths(:test)`) — drives all positive controls; **must be promotable into `FakeIdP` in Phase 30 (no divergent second signer)**
- [ ] New mixed-content golden fixture under `test/fixtures/security/xml/parser_differential_and_c14n/` + `PROVENANCE.md` (Docker-minted lxml/xmllint, per Phase 28 D-12; CI never invokes native toolchain)
- [ ] `test/security/xml/corpus_security_test.exs` — add mixed-content `@tag :gate02_c14n` byte-equality assertion (887-byte golden stays green)
- [ ] `test/relyra/metadata/auto_refresh_test.exs` — SIGV-04 positive + signature-valid/wrong-fingerprint negative
- [ ] Framework install: none — ExUnit is bundled

*Hard precondition: D-09/D-10 mixed-content C14N "Option-a" fix must land before any pretty-printed positive control, or every realistic genuine fixture fails `:digest_mismatch`.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Mixed-content golden provenance | SIGV-02 | Golden bytes are minted out-of-band in Docker (lxml/xmllint); CI asserts equality only | Re-mint via documented Docker step in `PROVENANCE.md`; commit raw bytes; CI compares byte-for-byte |

*All other phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
