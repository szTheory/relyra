---
phase: 34-validationpipeline-wiring-enc-01-complete
verified: 2026-05-25T22:35:00Z
status: passed
score: 5/5 must-haves verified
overrides_applied: 0
warnings:
  - id: WR-ENC-ATTR
    severity: warning
    concern: "REQUIREMENTS.md ENC-01 text includes '(and EncryptedAttribute)' but no EncryptedAttribute decryption exists in lib/ or test/. The phase goal + all 5 success criteria cover EncryptedAssertion only; the parenthetical is unverified scope. ENC-01 is marked Complete in REQUIREMENTS.md traceability."
    breaks_success_criterion: false
    recommendation: "Confirm EncryptedAttribute is intentionally out of Phase 34 scope, or open a follow-up. Not covered by any later milestone phase."
  - id: WR-01-02
    severity: warning
    concern: "Parser differential (CLAUDE.md invariant #2): locate_encrypted_assertion/1 (validation_pipeline.ex:215-222) is a regex over the raw binary running alongside the tree-walk detect_encrypted/1. A comment/CDATA carrying the literal text <EncryptedAssertion>...</EncryptedAssertion> causes the regex to count 2 while the tree sees 1 -> false :ambiguous reject. Fail-closed (availability defect, NOT an auth bypass). WR-02: the closing-prefix backreference (?:\\1:)? is optional so the documented prefix-match is not enforced (fail-closed)."
    breaks_success_criterion: false
    recommendation: "Splice using the byte span the tree already bound rather than re-scanning with a regex (single source of truth). Advisory per phase brief."
  - id: WR-03
    severity: warning
    concern: "metadata.ex:32,41 interpolates entityID (issuer) and Location (acs_url) into XML attribute values without escaping. A '\"' or '<' in resolver-supplied connection data breaks well-formedness / injects siblings. Cert bodies are base64-of-DER (safe). Latent XML-injection defect; does not affect SC#4 (descriptor presence/ordering/body)."
    breaks_success_criterion: false
    recommendation: "Escape interpolated attribute values (or build via Saxy.encode!)."
  - id: WR-04
    severity: info
    concern: "fake_idp.ex / xmldsig_signer.ex live under lib/relyra/test_support/ and compile into :prod. Phase 34 expanded the prod-loadable surface with live RSA-OAEP/AES-GCM encryption + an encrypted-Response forger. Guarded at runtime by ensure_not_prod!/0 but the code is loadable in a release."
    breaks_success_criterion: false
    recommendation: "Move lib/relyra/test_support/ to test/support/ for compile-time exclusion. Pre-existing placement; this phase widened it."
deferred: []
---

# Phase 34: ValidationPipeline Wiring + ENC-01 Complete Verification Report

**Phase Goal:** An SP configured against an encryption-enabled IdP can successfully log in; a malformed, tampered, or policy-violating encrypted assertion is rejected before any identity field is read.
**Verified:** 2026-05-25T22:35:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

The phase goal is achieved in the codebase. The decrypt-then-verify ordering is real (decrypted bytes pass `parse_safely/2` AND `Signature.verify/4` before any identity field is read), the single opaque `:decryption_failed` atom holds (no padding oracle), and cleartext+encrypted ambiguity is rejected before any crypto runs. Both deviations (PureBeam encrypted-only tolerance, XmldsigSigner `:assertion_namespace` opt) were verified NOT to weaken the cleartext trust path. All checks were run against the live codebase, not taken from SUMMARY claims.

### Observable Truths

| # | Truth (Success Criterion) | Status | Evidence |
|---|---------------------------|--------|----------|
| 1 | Valid EncryptedAssertion completes login: decrypt -> re-parse via parse_safely/2 -> Signature.do_verify/4 succeeds BEFORE any identity field is read | VERIFIED | validation_pipeline.ex:76 runs `decrypt_assertion/4` between parse and validations; :135-136 splice + re-parse via `PureBeam.parse_safely`; :228 `Signature.verify` inside `do_run_validations`; identity read in `login_result/5` (:327-350) reached ONLY after the full `with` chain (:225-253). Positive-control test (xml_enc_adversarial_test.exs:106-116) passes: genuine `FakeIdP.encrypted_response()` -> `{:ok, login_result}` with `name_id == "user@example.com"`. Live run: 9 tests, 0 failures. |
| 2 | Cleartext + encrypted -> :ambiguous_assertion BEFORE any crypto | VERIFIED | `detect_encrypted/1` (validation_pipeline.ex:165-176) returns `:ambiguous` when a cleartext `Assertion` is present alongside `EncryptedAssertion`; the `:ambiguous` arm (:119-125) returns the typed error WITHOUT calling `XMLEnc.decrypt`. Fixture 5 (xml_enc_adversarial_test.exs:179-192) + decrypt_assertion_test.exs:164-182 use would-fail-decrypt ciphertext and still get `:ambiguous_assertion`, proving ordering. Live run green. |
| 3 | Non-encrypted paths structurally unchanged — :decrypt_assertion is a strict no-op | VERIFIED | `:none` arm (validation_pipeline.ex:116-117) returns the original parsed_doc with NO re-parse and NO XMLEnc call. Proven dependency-free: decrypt_assertion_test.exs RaiseIfInvoked resolver (:39-41, :143-162) — an unencrypted signed Response runs with that resolver and does NOT raise. `do_run_validations/6` byte-unchanged. PureBeam `encrypted_only?/1` (:262-265) is false whenever a cleartext Assertion exists, so `build_cleartext_parsed_doc/1` runs FULL strict gates. Live full suite: 626 tests, 0 failures (includes frozen Phase-29 corpus). |
| 4 | SP metadata publishes <KeyDescriptor use="encryption"> + distinct <KeyDescriptor use="signing"> | VERIFIED | metadata.ex:34-40 emits both descriptors (signing first, encryption second), both before `<md:AssertionConsumerService>` (:41); base64-of-DER bodies via `cert_body/1` (:51-66); PUBLIC certs only (`:sp_signing_cert_pem`/`:sp_encryption_cert_pem`, no `:sp_private_key_pem`); xmlenc# accept-list URIs (:10-14). metadata_test.exs asserts presence, ordering (offset compare :37-42), no PEM armor (:55-60), distinct certs, aes256-gcm URI. Live run: included in 17/0. |
| 5 | All 7 ENC-01 fixtures wired into mix ci.security, each returns correct typed error | VERIFIED | xml_enc_adversarial_test.exs: 7 named fixtures + positive control + 1 bonus = 9 tests, all pinning exact `%Error{type:}` (:134, :145, :162, :174, :189, :201, :217-225, :244). Wired as own line in mix.exs:174. Meta-gate ci_gate_integrity_test.exs:41 registers it; 4/0 confirms non-hollow. Live `mix ci.security` exits 0; corpus 9/0. |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/relyra/protocol/validation_pipeline.ex` | :decrypt_assertion pre-stage + detector + :ambiguous_assertion | VERIFIED | Substantive (394 lines); `decrypt_assertion/4`, `detect_encrypted/1`, `find_first`/`find_all`/`collect_nodes`, `locate_encrypted_assertion/1`; three-tuple contract preserved; `do_run_validations/6` unchanged. Wired into `do_run/4`. |
| `lib/relyra/security/xml/pure_beam.ex` | encrypted-only parse tolerance (deviation) | VERIFIED | `encrypted_only?/1` + `build_pre_decrypt_parsed_doc/1` (:262-282) added; cleartext path renamed to `build_cleartext_parsed_doc/1` with IDENTICAL strict gates. No identity field surfaced pre-decrypt. Trust path NOT weakened (encrypted_only? false when cleartext Assertion present). |
| `lib/relyra/protocol/metadata.ex` | both KeyDescriptors | VERIFIED | `build_sp_metadata/2` emits both; nil-safe `cert_body/1`. |
| `lib/relyra/test_support/fake_idp.ex` | encrypt/2,3 + encrypted_response/2 + enc_algorithm_uris/0 | VERIFIED | Canonical OAEP+GCM generator with adversarial opts (tag_length, content_uri, key_transport_uri, cipher_value_b64, key_padding). |
| `lib/relyra/test_support/xmldsig_signer.ex` | :assertion_namespace opt (deviation) | VERIFIED | Defaults `false` (:238); cleartext signer path byte-identical (626/0 confirms). |
| `test/security/xml_enc_adversarial_test.exs` | positive + 7 + bonus, exact pins | VERIFIED | 337 lines, 9 tests, exact `%Error{type:}` pins, `refute_identity_leak/1` guard. |
| `mix.exs` | ci.security corpus line | VERIFIED | Own `cmd mix test ... --warnings-as-errors` line at :174. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| validation_pipeline do_run/4 | XMLEnc.decrypt/3 | resolver MODULE + connection in opts | WIRED | :130-133 passes module via `Keyword.get(opts, :key_resolver, ...)`, threads connection. |
| pre-stage | PureBeam.parse_safely/2 | re-parse recomposed binary (one parse path) | WIRED | :136 re-parses spliced binary through the SAME seam. |
| detector | parse_tree (SaxyTree.Node) | prefix-agnostic find_first/find_all by local name | WIRED | :115, :165-176 walk the tree; no second parser. |
| corpus | ValidationPipeline.run/4 | end-to-end pipeline run | WIRED | All 9 tests drive `ValidationPipeline.run(...)`. |
| mix.exs ci.security | corpus subprocess line | own cmd mix test line (hollow-gate) | WIRED | :174; meta-gate enforces non-hollow. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| login_result (success path) | name_id / attributes | re-parsed decrypted plaintext (build_cleartext_parsed_doc -> assertion_fields) after Signature.verify | Yes — positive control asserts real NameID "user@example.com" | FLOWING |
| XMLEnc.decrypt/3 | plaintext | RSA-OAEP unwrap + AES-GCM (real :crypto) | Yes — round-trip byte-identity proven (fake_idp_encrypt_test.exs) | FLOWING |
| metadata X509Certificate body | base64-of-DER | :public_key.pem_decode of configured PEM | Yes — test asserts no PEM armor, real base64 | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| ENC-01 corpus end-to-end | `mix test test/security/xml_enc_adversarial_test.exs --warnings-as-errors` | 9 tests, 0 failures | PASS |
| Unit pre-stage guards | `mix test test/relyra/protocol/decrypt_assertion_test.exs ...` | included in 17/0 | PASS |
| Metadata SC#4 | `mix test test/relyra/protocol/metadata_test.exs ...` | included in 17/0 | PASS |
| Round-trip generator | `mix test test/relyra/test_support/fake_idp_encrypt_test.exs ...` | included in 17/0 | PASS |
| Hollow-gate meta-check | `mix test test/security/ci_gate_integrity_test.exs --warnings-as-errors` | 4 tests, 0 failures | PASS |
| Full security gate | `mix ci.security` | exit 0 | PASS |
| No regressions (SC#3) | `mix test --warnings-as-errors` | 626 tests, 0 failures | PASS |
| Format | `mix format --check-formatted` | exit 0 | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| ENC-01 | 34-02, 34-03, 34-04 | Decrypt EncryptedAssertion (RSA-OAEP + AES-GCM); decrypted bytes pass parse_safely/2 + do_verify/4 before identity read; opaque :decryption_failed | SATISFIED (EncryptedAssertion) | SC#1/#2/#3/#5 verified; XMLEnc returns only `{:ok, _} \| :decryption_failed` (xml_enc.ex). NOTE: requirement text also says "(and EncryptedAttribute)" — NOT implemented (see WR-ENC-ATTR). Not part of any phase success criterion. |
| ENC-02 | 34-01 | SP metadata publishes KeyDescriptor use="encryption" | SATISFIED | SC#4 verified in metadata.ex + metadata_test.exs. |

No orphaned requirements: both ENC-01 and ENC-02 are declared in plan frontmatter and mapped to Phase 34 in REQUIREMENTS.md.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| validation_pipeline.ex | 215-222 | regex locator alongside tree detector (parser differential) | Warning | Fail-closed false-reject on comment/CDATA-embedded EncryptedAssertion text; not an auth bypass; does not break any SC (positive control is clean). |
| metadata.ex | 32,41 | unescaped attribute interpolation | Warning | Latent XML-injection on resolver-supplied data; does not affect SC#4. |
| test_support/*.ex | — | test crypto compiled into :prod | Info | Runtime-guarded; pre-existing placement widened by this phase. |
| phase-modified lib files | — | TBD/FIXME/XXX/TODO/HACK debt markers | None | Scanned all 5 modified lib files — zero debt markers. |

### Human Verification Required

None. All five success criteria are programmatically verifiable and were confirmed by live test runs (the positive control + 7 named fixtures + bonus, the unit pre-stage guards, the metadata SC#4 assertions, the hollow-gate meta-check, the full security gate, and the full regression suite). No visual/UX/real-time/external-service behavior is in scope for this phase.

### Gaps Summary

No phase-blocking gaps. All 5 success criteria are VERIFIED against the live codebase with passing tests and traced source evidence. The decrypt-then-verify ordering, the opaque single-atom failure mode, and the pre-crypto ambiguity reject all hold. Both plan deviations (PureBeam encrypted-only tolerance in 34-03; XmldsigSigner `:assertion_namespace` opt in 34-04) were independently verified NOT to weaken the cleartext trust path — `encrypted_only?/1` is false whenever a cleartext Assertion is present (so full strict gates run), and `:assertion_namespace` defaults off (so the cleartext signer is byte-identical). The 626/0 full-suite pass — including the permanently-frozen Phase-29 adversarial crypto corpus — corroborates SC#3.

Four advisory items are carried in frontmatter `warnings` (none breaks a success criterion): WR-ENC-ATTR (the ENC-01 requirement text's `EncryptedAttribute` clause is unimplemented while ENC-01 is marked Complete — a requirement-traceability mismatch worth an explicit scope confirmation or follow-up), plus the three code-review findings WR-01/02 (regex parser-differential, fail-closed), WR-03 (unescaped metadata attributes), and WR-04 (test crypto in the prod artifact).

---

_Verified: 2026-05-25T22:35:00Z_
_Verifier: Claude (gsd-verifier)_
