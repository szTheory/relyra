---
phase: 28
slug: real-c14n-parser-foundation
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-23
validated: 2026-05-24
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
| `saxy` real dep; seam parses into a tree, not regex (SC#1) | 1 | SIGV-03 | T-parser-differential | single trust path; `parser_path_guard` confines saxy to `lib/relyra/security/xml/` | unit + dep-presence | `mix test test/relyra/security/xml/saxy_tree_test.exs test/relyra/security/xml/pure_beam_test.exs` (saxy 1.6.0 pinned in `mix.lock`) | ✅ | ✅ green |
| `canonicalize/2` == independent reference byte-for-byte (SC#2) | — | SIGV-03 | T-c14n-divergence | byte-exact exc-C14N; no silent digest defeat | golden-byte equality | `mix test test/security/xml/corpus_security_test.exs --only gate02_c14n` (positive byte-equality vs 887-byte libxml2 golden) | ✅ | ✅ green |
| Differential/incomplete inputs still fail closed (`:canonicalization_failed`) | — | SIGV-03 | T-c14n-divergence | fail-closed on incomplete bind | fail-closed gate | `mix test test/security/xml/corpus_security_test.exs --only gate02_c14n` (existing `c14n-00x` rows) | ✅ | ✅ green |
| Existing hardened guards hold; v1.0 corpus green (SC#3) | — | SIGV-03 | T-xxe / T-xsw / T-keyinfo / T-dos | DOCTYPE/ENTITY/size/KeyInfo/dup-ID/single-node guards intact | corpus regression | `mix test test/security/xml/corpus_security_test.exs test/relyra/security/xml/corpus_gate_test.exs --only security_corpus` | ✅ | ✅ green |
| Verified node bound to exact canonicalized element (SC#4) | — | SIGV-03 | T-xsw | no node/canonicalization differential | unit (node-binding) | `mix test test/relyra/security/xml/pure_beam_test.exs test/security/xml/corpus_security_test.exs --only gate02_c14n` (handle `:node` ≡ canonicalized `<Assertion>` in `parsed_doc[:parse_tree]`, D-10) | ✅ | ✅ green |
| `parsed_doc` flat-key contract preserved additively (D-08) | — | SIGV-03 | T-parser-differential | downstream readers unbroken | contract/regression | `mix test test/protocol/consume_response_pipeline_test.exs test/relyra/security/signature_test.exs test/relyra/metadata/auto_refresh_test.exs` (existing readers unchanged) | ✅ | ✅ green |
| seam `@callback` arity unchanged (D-07) | — | SIGV-03 | — | rollback adapter compatibility | contract | `mix test test/security/xml/seam_contract_test.exs` | ✅ | ✅ green |

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

> **All delivered during execution (Plans 01–04).** See per-plan SUMMARY files.

- [x] `mix.exs` — `{:saxy, "~> 1.6"}` (non-optional) added; `mix deps.get` pinned **saxy 1.6.0** in `mix.lock` (checksum `02cb4e9b…317ee`). A1 supply-chain gate (T-28-SC) pre-approved + verified (Plan 01).
- [x] `lib/relyra/security/xml/saxy_tree.ex` — `Saxy.Handler` tree builder + in-scope namespace stack, under `parser_path_guard` allowed root (Plan 01; 16 tests).
- [x] `lib/relyra/security/xml/c14n.ex` — exclusive-C14N 1.0 engine (`serialize/2` + `canonicalize_reference/4` + transform allowlist) (Plan 02; 30 tests).
- [x] `test/fixtures/security/xml/parser_differential_and_c14n/assertion_inherited_ns.{input.xml,c14n}` + `PROVENANCE.md` — golden (SAML assertion with ancestor-declared used+unused namespaces), 887 bytes, no trailing newline (Plan 04).
- [x] GATE-02 byte-equality assertion in `test/security/xml/corpus_security_test.exs` (positive path added; existing fail-closed `c14n-00x` rows preserved) (Plan 04).
- [x] Node-binding unit test (SC#4: handle `:node` ≡ canonicalized `<Assertion>`, D-10) (Plans 03 + 04).
- [x] Idempotence/property test for C14N (L5: `canonicalize(canonicalize(x)) == canonicalize(x)`) — covered in c14n core suite (Plan 02).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions | Disposition |
|----------|-------------|------------|-------------------|-------------|
| Golden-byte minting provenance | SIGV-03 | Golden bytes are minted out-of-band (D-12) with `lxml` + `xmlsec1`; `mix ci.security` stays pure-Elixir (no native toolchain). The mint step is human/CI-external, not part of the test lane. | Run pinned `lxml etree.tostring(method="c14n", exclusive=True, inclusive_ns_prefixes=[...])`, cross-check with `xmlsec1 --c14n-exc`, commit input + canonical bytes (no trailing newline) + `PROVENANCE.md` recording tool + libxml2 versions, exact command, and any PrefixList. | ✅ **SATISFIED (Plan 04).** Minted in Docker (`python:3.12-slim`, 2026-05-23): lxml 6.1.1 / libxml2 2.14.6 cross-checked byte-identical against `xmllint --exc-c14n` (system libxml2 2.9.14); xmlsec1 1.2.41 recorded. `PROVENANCE.md` committed; sha256 `5d6d15c4…ad7ea`. Byte-equality is now **automated** in CI (reads committed `.c14n`); only the mint step is out-of-band. |
| saxy package legitimacy (A1 / T-28-SC) | SIGV-03 | slopcheck/ctx7 were unavailable during research; saxy was `[ASSUMED]` despite strong signals. Trust-path dependency — confirm before `mix deps.get`. | `checkpoint:human-verify` task: confirm `{:saxy, "~> 1.6"}` resolves to `github.com/qcam/saxy` (MIT, ~8.5M downloads). | ✅ **SATISFIED (Plan 01).** User pre-approved; orchestrator-verified hex.pm shows saxy 1.6.0 (2024-10-22), MIT, 8,548,165 downloads → `github.com/qcam/saxy` (genuine, not a typosquat). Pinned saxy 1.6.0 (checksum `02cb4e9b…317ee`) in `mix.lock`. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (all delivered Plans 01–04)
- [x] No watch-mode flags
- [x] Feedback latency < ~5s for the quick gate (gate02_c14n ~0.06s)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** ✅ validated 2026-05-24 — all 7 success criteria automated and green.

---

## Validation Audit 2026-05-24

State A audit of the executed phase. VALIDATION.md was authored at planning time (rows `⬜ pending`,
Wave 0 files `❌ W0`); this audit reconciled it against the 4 executed plans and re-ran every suite
named in the Per-Task Verification Map to confirm green — not trusting SUMMARY claims.

| Metric | Count |
|--------|-------|
| Success criteria audited | 7 |
| COVERED (automated + green) | 7 |
| PARTIAL | 0 |
| MISSING (gaps) | 0 |
| Tests generated this audit | 0 |
| Escalated | 0 |

Re-run evidence (all `mix test`, 0 failures):

| Suite | Result |
|-------|--------|
| `saxy_tree` + `c14n` + `c14n_transform` + `pure_beam` + `corpus_gate` (batch) | 77/0 |
| `corpus_security_test --only gate02_c14n` (golden byte-equality + node-binding) | 2/0 |
| `corpus_security_test --only security_corpus` (regression + fail-closed) | 6/0 |
| `seam_contract_test` (D-07) | 3/0 |
| `consume_response_pipeline` + `idp_initiated` (D-08 primary reader) | 16/0 |
| `signature_test` + `auto_refresh_test` (D-08 downstream readers) | 17/0 |

**Result: Phase 28 is Nyquist-compliant.** Every success criterion has automated verification; no
gaps required test generation. Both Manual-Only verifications satisfied. No new test files written
(implementation already shipped its tests during execution); no auditor spawn needed.
