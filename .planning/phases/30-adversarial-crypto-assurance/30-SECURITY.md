---
phase: 30
slug: adversarial-crypto-assurance
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-24
---

# Phase 30 — Adversarial Crypto Assurance: Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

**Status:** SECURED · **Threats Closed:** 18/18 · **ASVS Level:** L1 (config default) · **Block-on:** high (config default)
**Verified:** 2026-05-24 · **Baseline ref:** `10a78bb` (last pre-execution planning commit) .. `HEAD`

All threat dispositions are independently verified against the actual implementation
(file:line / grep / executed test), NOT against SUMMARY self-reports. 17 `mitigate` +
1 `accept`, all confirmed present.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| FakeIdP emitted bytes → verifier | The signed Response bytes must canonicalize identically for signer and verifier; divergence is the assurance-regression risk | Signed SAML `<Response>` (RSA-SHA256 `ds:SignatureValue` + SHA-256 `ds:DigestValue`) |
| test-support → production compilation | FakeIdP / XmldsigSigner must never compile or run in `:prod` | Private RSA-2048 keypair, self-signed trust cert |
| genuine signed bytes → mutated input → verifier | Each adversarial recipe crosses this; the verifier must reject everything except the genuine input | Forged / wrong-key / tampered / c14n-mutated `<Response>` |
| chosen C14N mutation → recomputed digest | The mutation must be C14N-PRESERVED or the rejection case falsely passes `{:ok}` | Exclusive-C14N canonical bytes of the `<Assertion>` subtree |
| JSON manifest row → evaluator routing | The asserted error type must match the route the class takes (canonicalize-only, not verify) | `priv/security_corpus.json` row → `parser_differential_and_c14n` branch |
| priv/security_corpus.json → CONFORMANCE.md | The generated doc must stay in sync with the manifest or the drift gate fails | Conformance manifest rows + CVE-REG-01 regression table |
| test suite → CI gate | A crypto proof only gates if the `ci.security` alias actually runs it | `--only adversarial_crypto` suite execution inside `mix ci.security` |
| ci.security ordering → conformance drift | `ci.conformance` must run first; a stale CONFORMANCE.md aborts the whole lane | Drift-check result (pass/fail) gating downstream suites |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation / Evidence | Status |
|-----------|----------|-----------|-------------|------------------------|--------|
| T-30-01 | Tampering | FakeIdP canonicalizer differential (T-29-15 false-positive) | mitigate | Single signing path. `lib/relyra/test_support/fake_idp.ex:71` delegates to `XmldsigSigner.sign_response/1`; `grep -v '^#' fake_idp.ex \| grep -cE 'public_key\.sign\|crypto\.hash'` = **0** (no bespoke second signer). | closed |
| T-30-02 | Spoofing | Missing `<CanonicalizationMethod>` → malformed SignedInfo | mitigate | `fake_idp.ex:138` `<CanonicalizationMethod Algorithm=".../xml-exc-c14n#"/>` is the FIRST child of `<SignedInfo>` (:137), before `<SignatureMethod>` (:139); whitespace-collapse `String.replace(~r/\s+/," ")` removed (grep = none). | closed |
| T-30-03 | Elevation | Signing code compiles/runs in `:prod` | mitigate | `@prod_build` (fake_idp.ex:11) + `ensure_not_prod!/0` on every entry point: metadata :35, build_response :49, sign :68, keypair :89. Delegate `xmldsig_signer.ex` mirrors the guard (:40, :96/:163/:206, raise :369-370), so `self_signed_cert_pem/0` also fails closed in prod. | closed |
| T-30-04 | Tampering | Scope creep into frozen production crypto | mitigate | D-10 scope fence. `git diff --quiet 10a78bb..HEAD -- lib/relyra/security/signature.ex lib/relyra/security/xml/pure_beam.ex` → both UNCHANGED (byte-identical to baseline). No `lib/relyra/security/` file in the phase diff. | closed |
| T-30-05 | Tampering | C14N-no-op tamper false-negative ({:ok} despite mutation) | mitigate | C14N-PRESERVED mutation. `adversarial_crypto_test.exs:154-178` adds non-namespace `Foo="bar"` to `<Assertion>` apex; asserts EXACT `{:error, %Error{type: :digest_mismatch}}` (:175); landed-mutation guard (:170-171). Signer default `@default_assertion_id "assertion-1"` (xmldsig_signer.ex:58) emits a bare `<Assertion ID="assertion-1">` (:240) so the `String.replace` lands. Run: 6/6 green. | closed |
| T-30-06 | Spoofing | Forged / wrong-key signature acceptance | mitigate | forged-sig (same-length random base64) `adversarial_crypto_test.exs:78-93` → `:invalid_signature`; wrong-key (throwaway cert) :95-103 → `:invalid_signature`. Both exact-typed. | closed |
| T-30-07 | Tampering | Content tamper (NameID swap) acceptance | mitigate | tamper_name_id recipe `adversarial_crypto_test.exs:105-113` (`XmldsigSigner.signed_response(tamper_name_id: "attacker@evil.example.com")`) → exact `:digest_mismatch`. | closed |
| T-30-08 | Spoofing | Algorithm-substitution sample outside the gate | mitigate | ECDSA carry-over `adversarial_crypto_test.exs:115-127` sets `signature_method: @ecdsa_sha256`, asserts exact `:unsupported_signature_algorithm` (fail-closed in the gated suite). | closed |
| T-30-09 | Tampering | Divergent-signer false-positive in positive control | mitigate | Positive control `adversarial_crypto_test.exs:56-67` drives `FakeIdP.sign(FakeIdP.build_response())` + `FakeIdP.self_signed_cert_pem()` → `{:ok, %SignedNode{}}` with `signature_method == rsa-sha256`. Genuine signature only. | closed |
| T-30-10 | Tampering | Scope creep into frozen crypto / WR-03 fix | mitigate | No edit to frozen crypto (see T-30-04); test module docstring + comments confirm no XSW-shaped input is built (:29-30, :150-151); no `signed_candidates/1` / `signature.ex` edit. | closed |
| T-30-11 | Tampering | C14N-differential routing false-positive (Pitfall 1, HIGHEST RISK) | mitigate | `priv/security_corpus.json` row `c14n-differential-rejection-002` asserts `expected_error_type: "canonicalization_failed"` (NOT digest_mismatch), class `parser_differential_and_c14n`, XML has no `<DigestValue>` (incomplete canonicalization handle → fail-closed). JSON validates. | closed |
| T-30-12 | Tampering | Conformance drift undetected | mitigate | `CONFORMANCE.md:11` "fixtures pinned: 8"; new row in CVE-REG-01 table (:45). EXECUTED `mix relyra.conformance --check` → "matches generated manifest state" (exit 0, no drift). Corpus count 7→8. | closed |
| T-30-13 | Spoofing | Corpus row missing provenance/requirement_ids/family/source_ref | mitigate | New row carries all four: `family` (signature_wrapping), `requirement_ids` [CVE-REG-01, ASSUR-01], `provenance` (non-empty map), `source_ref`. Enforced for every row by `corpus_security_test.exs:126-141`. Suite run: 7/7 green. | closed |
| T-30-14 | Tampering | Suite-outside-the-gate (Pitfall 2) — crypto regression ships green | mitigate | `mix.exs:172` names `cmd mix test test/security/xml/adversarial_crypto_test.exs --only adversarial_crypto --warnings-as-errors`. Anti-hollow meta-gate `ci_gate_integrity_test.exs` (AST-parses mix.exs) asserts the suite is present (:100-108), runs as `cmd mix test` not bare `test` (:110-132), and its `--only` tag exists (:134-147); `@gated_suites` includes the adversarial suite (:39). Meta-gate self-gated (mix.exs:167). Run: 4/4 green. Independent PROBE (30-VERIFICATION.md:31): `assert false` → `mix ci.security` exit 1. | closed |
| T-30-15 | Tampering | Green-by-skip — red assertion silenced or weakened | mitigate | No `@tag :skip`/`:pending`/`--exclude` in the adversarial suite (grep = none). 5 exact `%Error{type:}` pins + `%SignedNode{}`; only `{:error, _}` occurrence is in a doc comment (:24). No weakened assertion. Suite green for the right reason (6/6). | closed |
| T-30-16 | Tampering | Conformance drift aborts the gate at step 1 | mitigate | `mix.exs:154` `ci.conformance` runs BEFORE every named test line; `ci.conformance` runs `relyra.conformance --check` (:150). Ordering correct → drift check first. `--check` passes (see T-30-12). | closed |
| T-30-17 | Elevation | Scope creep into frozen crypto to "make the gate pass" | mitigate | No file under `lib/relyra/security/` modified to make the gate pass (see T-30-04 git diff). Verify path frozen; only `mix.exs` aliases + test wiring changed. | closed |
| T-30-SC | Tampering | Supply-chain via npm/pip/cargo installs | accept | No package installs this phase. `git diff --quiet 10a78bb..HEAD -- mix.lock` → UNCHANGED; no new dep tuples in mix.exs (only alias edits). OTP `:public_key`/`:crypto`/`:json` + already-vendored Jason only. See Accepted Risks Log. | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-30-01 | T-30-SC | Supply-chain via npm/pip/cargo installs: no package installs in this phase; `mix.lock` byte-unchanged since baseline `10a78bb`; only OTP stdlib (`:public_key`/`:crypto`/`:json`) + already-vendored Jason used; only alias/test/corpus/CI files changed. No new attack surface. | szTheory | 2026-05-24 |

*Accepted risks do not resurface in future audit runs.*

---

## Scope Fence (D-10) — Independent Confirmation

`git diff --quiet 10a78bb..HEAD` on each frozen file:
- `lib/relyra/security/signature.ex` — UNCHANGED
- `lib/relyra/security/xml/pure_beam.ex` — UNCHANGED
- `lib/relyra/test_support/xmldsig_signer.ex` (Phase-29 genuine signer, reused via delegation) — UNCHANGED

No file under `lib/relyra/security/` appears in the phase diff. The frozen verify path is exercised, never modified.

---

## Unregistered Flags

None. All four SUMMARYs report empty `## Threat Flags` / `## Known Stubs`
(30-01, 30-02, 30-03 explicit "None"; 30-04 no new surface). No new attack
surface appeared during implementation without a threat mapping.

---

## Executed Verification (this audit)

- `mix relyra.conformance --check` → exit 0, "matches generated manifest state" (T-30-12/16).
- `mix test test/security/xml/adversarial_crypto_test.exs --only adversarial_crypto --warnings-as-errors` → 6 tests, 0 failures (T-30-05/06/07/08/09/15).
- `mix test test/security/ci_gate_integrity_test.exs --warnings-as-errors` → 4 tests, 0 failures (T-30-14).
- `mix test test/security/xml/corpus_security_test.exs --only security_corpus --warnings-as-errors` → 7 tests, 0 failures (T-30-11/13).
- `git diff --name-only 10a78bb..HEAD` + per-file `git diff --quiet` → frozen crypto unchanged (T-30-04/10/17), mix.lock unchanged (T-30-SC).

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-24 | 18 | 18 | 0 | gsd-security-auditor (read-only; no implementation file modified) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-24

---
*Phase: 30-adversarial-crypto-assurance*
*Auditor: gsd-security-auditor (read-only; no implementation file modified)*
