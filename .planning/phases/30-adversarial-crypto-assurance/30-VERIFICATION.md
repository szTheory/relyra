---
phase: 30-adversarial-crypto-assurance
verified: 2026-05-24T19:18:00Z
status: passed
score: 9/9 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: none
  note: initial verification
---

# Phase 30: Adversarial Crypto Assurance — Verification Report

**Phase Goal:** Make `FakeIdP` perform real cryptographic XMLDSig signing and add the permanent adversarial corpus (forged-sig / tampered-content / wrong-key / digest-mismatch / c14n-differential REJECTED + positive control), wired into the conformance manifest and the `ci.security` gate, green under `mix ci.security`.
**Verified:** 2026-05-24T19:18:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| #   | Truth | Status | Evidence |
| --- | ----- | ------ | -------- |
| 1 | ASSUR-02: `FakeIdP.sign` delegates to the genuine signer (real DigestValue + SignatureValue), not structure-only | ✓ VERIFIED | `fake_idp.ex:71` — `%{response_xml: signed_xml} = Relyra.TestSupport.XmldsigSigner.sign_response(xml)`; no `:public_key.sign`/`:crypto.hash` in the file; positive-control test decodes a real signature and verifies `{:ok, %SignedNode{}}`. |
| 2 | ASSUR-02: `FakeIdP.self_signed_cert_pem/0` exists | ✓ VERIFIED | `fake_idp.ex:85` — `defdelegate self_signed_cert_pem(), to: Relyra.TestSupport.XmldsigSigner`. |
| 3 | FakeIdP `response_xml` carries `<CanonicalizationMethod>` as first SignedInfo child, no whitespace-collapse, SAML namespaces kept | ✓ VERIFIED | `fake_idp.ex:138` (`<CanonicalizationMethod Algorithm=".../xml-exc-c14n#"/>` first child); no `String.replace(~r/\s+/)`; `xmlns="urn:oasis:...:assertion"` on Issuer (:122) and Assertion (:124). |
| 4 | ASSUR-01: adversarial suite exists with positive control + all named attack categories reaching typed errors via the FROZEN Phase-29 verify path | ✓ VERIFIED | `adversarial_crypto_test.exs` — positive (`FakeIdP.sign` end-to-end, :58), forged-sig→`:invalid_signature` (:90), wrong-key→`:invalid_signature` (:100), tampered-content→`:digest_mismatch` (:110), ECDSA→`:unsupported_signature_algorithm` (:124), c14n-differential→`:digest_mismatch` (:175). Runs: 6 tests, 0 failures. |
| 5 | Frozen verifier `lib/relyra/security/*` UNCHANGED this phase | ✓ VERIFIED | `git diff 10a78bb..HEAD -- lib/relyra/security/` is empty (0 lines). D-10 scope fence held. |
| 6 | ASSUR-01: c14n-differential REJECTION row in `priv/security_corpus.json`, CONFORMANCE.md in sync | ✓ VERIFIED | Row `c14n-differential-rejection-002` present, `expected_error_type: canonicalization_failed`, full provenance/requirement_ids `[CVE-REG-01, ASSUR-01]`/family/source_ref; `mix relyra.conformance --check` → "matches generated manifest state". |
| 7 | ASSUR-01 success #4: adversarial suite named in `ci.security` AND genuinely gates (no hollow gate) | ✓ VERIFIED | `mix.exs:172` names the suite as `cmd mix test ... --only adversarial_crypto`; EVERY security suite line uses `cmd mix test` (no bare `test`); meta-gate `ci_gate_integrity_test.exs` exists, is self-gated, passes 4/4. PROBE: injecting `assert false` made `mix ci.security` exit 1 (suite `6 tests, 1 failure`, alias `** (exit) 2`) — failing one assertion fails the gate. |
| 8 | `mix ci.security` green end-to-end | ✓ VERIFIED | Exit 0; each suite ran as its own process with non-zero count (conformance 6, meta-gate 4, strict_default 4, escape_hatch 1, security_corpus 9, gate02_c14n 3, adversarial_crypto 6). hex.audit unavailable continues by design (expected, not a failure). |
| 9 | Full `mix test --warnings-as-errors` green (no regression) | ✓ VERIFIED | 557 tests, 0 failures (baseline 553 + 4 meta-gate tests). |

**Score:** 9/9 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `lib/relyra/test_support/fake_idp.ex` | sign/2 delegation + self_signed_cert_pem/0 + CanonicalizationMethod | ✓ VERIFIED | Delegation at :71, defdelegate at :85, CanonicalizationMethod at :138; no bespoke crypto. |
| `test/security/xml/adversarial_crypto_test.exs` | @moduletag :adversarial_crypto suite, 6 assertions, FakeIdP-driven positive control | ✓ VERIFIED | 198 lines, `@moduletag :adversarial_crypto` (:36), 6 assertions each pinning exact `%Error{type}`/`%SignedNode{}`. |
| `priv/security_corpus.json` | c14n-differential-rejection-002 row | ✓ VERIFIED | Present with canonicalization_failed + full provenance (see WR-04 caveat below). |
| `CONFORMANCE.md` | regenerated, fixtures pinned 8, drift gate green | ✓ VERIFIED | `fixtures pinned: 8`, new row in CVE-REG-01 table, `--check` passes. |
| `mix.exs` | ci.security names adversarial suite as cmd mix test | ✓ VERIFIED | Line :172; all security suites converted to `cmd mix test`; compile --warnings-as-errors first step. |
| `test/security/ci_gate_integrity_test.exs` | anti-hollow meta-gate, self-gated | ✓ VERIFIED | AST-parses mix.exs, asserts each gated suite is `cmd mix test`, exists, and tag is token-exact; passes 4/4. |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| `fake_idp.ex` sign/2 | `XmldsigSigner.sign_response/1` | delegation (D-01) | ✓ WIRED | `fake_idp.ex:71`, exercised by positive control returning `{:ok, %SignedNode{}}`. |
| adversarial positive control | `FakeIdP.sign` / `self_signed_cert_pem/0` | end-to-end real-signing (ASSUR-02) | ✓ WIRED | `adversarial_crypto_test.exs:58-63`. |
| adversarial negatives | `Signature.verify/4` | `PureBeam.parse_safely → verify` (frozen) | ✓ WIRED | All 5 negatives parse then verify; typed atoms produced by frozen verifier (22 refs in lib/relyra/security/). |
| `security_corpus.json` row | corpus evaluator | parser_differential_and_c14n routing | ✓ WIRED | Class routes to canonicalize-only, asserts canonicalization_failed (correct per Pitfall 1). |
| `security_corpus.json` | `CONFORMANCE.md` | relyra.conformance regen + drift gate | ✓ WIRED | `--check` exits 0. |
| `mix.exs` ci.security | adversarial suite | `cmd mix test --only adversarial_crypto` | ✓ WIRED | Probe proved a failing assertion fails the alias. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Adversarial suite passes | `mix test test/security/xml/adversarial_crypto_test.exs --only adversarial_crypto` | 6 tests, 0 failures | ✓ PASS |
| Meta-gate passes | `mix test test/security/ci_gate_integrity_test.exs` | 4 tests, 0 failures | ✓ PASS |
| Conformance no drift | `mix relyra.conformance --check` | "matches generated manifest state" | ✓ PASS |
| Full gate green | `mix ci.security` | exit 0; all suites ran with non-zero counts | ✓ PASS |
| Gate genuinely gates | inject `assert false` into adversarial suite → `mix ci.security` | exit 1; suite `6 tests, 1 failure`; alias `** (exit) 2`; probe reverted, tree clean | ✓ PASS |
| Full suite no regression | `mix test --warnings-as-errors` | 557 tests, 0 failures | ✓ PASS |
| Frozen verifier unchanged | `git diff 10a78bb..HEAD -- lib/relyra/security/` | 0 lines | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| ASSUR-01 | 30-02, 30-03, 30-04 | Permanent adversarial corpus (5 categories + positive control), wired into corpus_gate + conformance manifest, green under ci.security | ✓ SATISFIED | adversarial_crypto_test.exs (6 assertions), corpus row, CONFORMANCE.md sync, ci.security gates it (probe-proven). |
| ASSUR-02 | 30-01, 30-02 | FakeIdP performs real cryptographic XMLDSig signing | ✓ SATISFIED | sign/2 delegates to genuine signer; positive control verifies a real FakeIdP-signed Response end-to-end. |

No orphaned requirements. Both Phase-30 requirement IDs (ASSUR-01, ASSUR-02) are claimed by plans and satisfied in the codebase.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| — | — | No TBD/FIXME/XXX in any phase-modified file | — | None |
| — | — | No TODO/HACK/PLACEHOLDER/stub patterns in phase files | — | None |

No blocker or warning anti-patterns. All assertions pin exact typed errors (never bare `{:error, _}`); the c14n-differential case carries a landed-mutation guard so a no-op mutation surfaces as a `{:ok}` failure.

### Notable Caveats (informational — do not block the goal)

The code review (30-REVIEW.md) raised 5 WARNING-level findings concentrated in the
anti-hollow machinery. Verification confirms 4 of the 5 were FIXED post-review
(commits `07f4727`, `b4554ef`), and the 5th is an assurance-depth caveat, not a
goal failure:

- **WR-01/WR-05 (meta-gate parser brittleness)** — FIXED. `ci_gate_integrity_test.exs:50`
  now uses `Code.string_to_quoted!` AST parsing (no byte/bracket scanning, no string anchoring).
- **WR-02 (substring tag match)** — FIXED. `:142` now anchors on a whole-atom boundary
  (`~r/@(module)?tag\s+:#{tag}\b/`).
- **WR-03 (meta-gate coverage gap)** — FIXED. `corpus_gate_test.exs` added to `@gated_suites` (:37).
- **IN-02 (FakeIdP.metadata calling ensure_keypair!)** — FIXED (commit `b4554ef`); `metadata/0` now only `ensure_not_prod!()`.
- **WR-04 (corpus row `c14n-differential-rejection-002` is a functional duplicate of
  `c14n-differential-001`)** — NOT changed, and acceptable. The row routes through the
  canonicalize-only evaluator branch and fails closed with `:canonicalization_failed`
  regardless of XML content, so it does not discriminate a genuine C14N differential at the
  JSON-corpus layer. This is by design (Pitfall 1: the JSON evaluator never reaches
  `Signature.verify/4`). The GOAL's "c14n-differential REJECTED ... wired into the
  conformance manifest" leg is satisfied by this row's presence + provenance + drift-gate
  sync, AND the genuine c14n-differential CRYPTO proof (`:digest_mismatch` over a real
  C14N-preserved post-sign mutation) lives in the adversarial suite (`adversarial_crypto_test.exs:175`),
  which is the load-bearing assertion. Recommend (optional, future) either removing the
  redundant JSON row or routing a single bound candidate handle through `canonicalize` so the
  JSON-layer row gains discriminating power. This does not affect Phase-30 goal achievement.

### Human Verification Required

None. All success criteria are programmatically verifiable and were verified:
real signing (positive control round-trips a genuine signature), every rejection
category reaches its exact typed error, the conformance drift gate is byte-exact,
and the ci.security gate was proven to genuinely gate via a destructive-then-reverted
probe. No visual/UX/external-service surface in this phase.

### Gaps Summary

No gaps. All 9 must-haves verified against the codebase (not SUMMARY claims):

1. FakeIdP signs for real via delegation to the single genuine signer (no second signer / no bespoke crypto).
2. `self_signed_cert_pem/0` exposed.
3. The adversarial suite exists with the positive control + all named attack categories, each pinning an exact typed error, driving through the FROZEN Phase-29 verify path.
4. The frozen verifier `lib/relyra/security/*` is byte-for-byte unchanged this phase (D-10).
5. The c14n-differential rejection row is in the corpus and CONFORMANCE.md is in sync.
6. The adversarial suite is named in `ci.security` AND genuinely gates — the previously-hollow gate (mix `test`-task dedup) was fixed by converting every security suite to `cmd mix test`, backed by a self-gating anti-hollow meta-gate. A destructive probe proved a single failing adversarial assertion fails `mix ci.security`.
7. `mix ci.security` is green end-to-end and `mix test --warnings-as-errors` is green (557 tests, 0 failures, no regression).

The single open review item (WR-04) is an assurance-depth refinement of a redundant
JSON-corpus row, explicitly redundant by routing design; the genuine c14n-differential
crypto proof is asserted in the gated adversarial suite. It does not block the phase goal.

---

_Verified: 2026-05-24T19:18:00Z_
_Verifier: Claude (gsd-verifier)_
