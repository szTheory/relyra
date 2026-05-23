---
phase: 28
slug: real-c14n-parser-foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-23
---

# Phase 28 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `28-RESEARCH.md` § Validation Architecture. Security-critical phase:
> C14N byte-divergence silently defeats the downstream crypto check, so the
> golden-byte differential gate is the load-bearing oracle.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in; Elixir 1.19.5 / OTP 28) |
| **Config file** | none separate — `test/test_helper.exs`; security corpus tests tagged `:security_corpus` / `:gate02_c14n` |
| **Quick run command** | `mix test test/security/xml/corpus_security_test.exs --only gate02_c14n` |
| **Full suite command** | `mix ci.security` (pure-Elixir: corpus + gate02 + sobelow/deps.audit/hex.audit) |
| **Estimated runtime** | quick ~few seconds; `mix ci.security` ~tens of seconds |

---

## Sampling Rate

- **After every task commit:** `mix test test/security/xml/corpus_security_test.exs --only gate02_c14n` (golden-byte + fail-closed — fast)
- **After every plan wave:** `mix ci.security` (full pure-Elixir security lane) green
- **Before `/gsd:verify-work`:** `mix ci.security` + downstream suites (`ValidationPipeline` / `Signature` / `AutoRefresh` / `seam_contract`) all green
- **Max feedback latency:** quick gate within a few seconds of each commit

---

## Per-Task Verification Map

> Task IDs are filled in after planning (the plans assign `{28}-{plan}-{task}` IDs).
> Each row ties a phase success criterion to its automated proof and the source/oracle.

| Behavior (success criterion) | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|------------------------------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| `saxy` real dep; seam parses into a tree, not regex (SC#1) | 1 | SIGV-03 | T-parser-differential | single trust path; `parser_path_guard` confines saxy to `lib/relyra/security/xml/` | unit + dep-presence | `mix deps.get && mix compile --warnings-as-errors && mix test test/security/xml/ --only security_corpus` | ❌ W0 | ⬜ pending |
| `canonicalize/2` == independent reference byte-for-byte (SC#2) | — | SIGV-03 | T-c14n-divergence | byte-exact exc-C14N; no silent digest defeat | golden-byte equality | `mix test test/security/xml/corpus_security_test.exs --only gate02_c14n` (NEW positive assertion) | ❌ W0 | ⬜ pending |
| Differential/incomplete inputs still fail closed (`:canonicalization_failed`) | — | SIGV-03 | T-c14n-divergence | fail-closed on incomplete bind | fail-closed gate | `mix test test/security/xml/corpus_security_test.exs --only gate02_c14n` (existing `c14n-00x` rows) | ✅ | ⬜ pending |
| Existing hardened guards hold; v1.0 corpus green (SC#3) | — | SIGV-03 | T-xxe / T-xsw / T-keyinfo / T-dos | DOCTYPE/ENTITY/size/KeyInfo/dup-ID/single-node guards intact | corpus regression | `mix test test/security/xml/corpus_security_test.exs test/relyra/security/xml/corpus_gate_test.exs --only security_corpus` | ✅ | ⬜ pending |
| Verified node bound to exact canonicalized element (SC#4) | — | SIGV-03 | T-xsw | no node/canonicalization differential | unit (node-binding) | `mix test test/security/xml/...` (NEW: handle node ≡ canonicalized node) | ❌ W0 | ⬜ pending |
| `parsed_doc` flat-key contract preserved additively (D-08) | — | SIGV-03 | T-parser-differential | downstream readers unbroken | contract/regression | run existing `ValidationPipeline` / `Signature` / `AutoRefresh` suites unchanged | ✅ | ⬜ pending |
| seam `@callback` arity unchanged (D-07) | — | SIGV-03 | — | rollback adapter compatibility | contract | `seam_contract_test` (existing) | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

### Layers, oracle, and pitfall coverage

| Layer | "Correct" means | Reference oracle | Pitfalls covered |
|-------|-----------------|------------------|------------------|
| **L1 Golden-byte equality** | `canonicalize/2` output == committed golden bytes, byte-for-byte (incl. no trailing newline) | `lxml` (pinned) cross-checked with `xmlsec1`, committed out-of-band (D-12) | 1–8 (each pitfall ⇒ ≥1 golden fixture variant) |
| **L2 Fail-closed differential** | incomplete/differential inputs ⇒ `{:error, :canonicalization_failed}` | existing `c14n-00x` manifest rows (expected_error_type) | 9 (calling convention / fail-closed) |
| **L3 Corpus regression** | every v1.0 fixture's `expected_error_type` unchanged on the saxy path | `priv/security_corpus.json` + `test/fixtures/.../manifest.json` | guard portability (DOCTYPE/ENTITY/size/KeyInfo/dup-ID/single-node) |
| **L4 Backward-compat contract** | downstream `parsed_doc` readers + seam contract test still green | existing `ValidationPipeline`/`Signature`/`AutoRefresh`/`seam_contract` tests | D-07, D-08 |
| **L5 (recommended) round-trip / property** | idempotence `canonicalize(canonicalize(x)) == canonicalize(x)`; reordering insignificant attrs/ns yields identical bytes | self-check + oracle base case | reinforces 1, 2, 8 |

---

## Wave 0 Requirements

- [ ] `mix.exs` — add `{:saxy, "~> 1.6"}` (non-optional) + `mix deps.get` — **gated by A1 `checkpoint:human-verify`** confirming `{:saxy, "~> 1.6"}` resolves to `github.com/qcam/saxy` before fetch (trust-path dependency)
- [ ] `lib/relyra/security/xml/saxy_tree.ex` (or similar) — new `Saxy.Handler` tree builder + in-scope namespace stack (under `parser_path_guard` allowed root)
- [ ] `lib/relyra/security/xml/c14n.ex` (or similar) — new exclusive-C14N engine
- [ ] `test/fixtures/security/xml/parser_differential_and_c14n/*.input.xml` + `*.c14n` + `PROVENANCE.md` — at least one golden (SAML assertion with ancestor-declared namespace); per-pitfall variants where useful
- [ ] GATE-02 byte-equality assertion in `test/security/xml/corpus_security_test.exs` (NEW positive path; keep existing fail-closed rows)
- [ ] Node-binding unit test (SC#4: handle node ≡ canonicalized node)
- [ ] (Recommended) idempotence/property test for C14N

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Golden-byte minting provenance | SIGV-03 | Golden bytes are minted out-of-band (D-12) with `lxml` + `xmlsec1`; `mix ci.security` stays pure-Elixir (no native toolchain). The mint step is human/CI-external, not part of the test lane. | Run pinned `lxml etree.tostring(method="c14n", exclusive=True, inclusive_ns_prefixes=[...])`, cross-check with `xmlsec1 --c14n-exc`, commit input + canonical bytes (no trailing newline) + `PROVENANCE.md` recording tool + libxml2 versions, exact command, and any PrefixList. |
| saxy package legitimacy (A1) | SIGV-03 | slopcheck/ctx7 were unavailable during research; saxy is `[ASSUMED]` despite strong signals. Trust-path dependency — confirm before `mix deps.get`. | `checkpoint:human-verify` task: confirm `{:saxy, "~> 1.6"}` resolves to `github.com/qcam/saxy` (MIT, ~8.5M downloads). |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < ~5s for the quick gate
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
