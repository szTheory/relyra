# Phase 41 Research: Pre-publish hygiene — Tech-debt sweep & security hardening

**Researched:** 2026-05-27  
**Phase:** 41  
**Status:** complete

## RESEARCH COMPLETE

## Summary

Phase 41 closes five warning-level items before v1.4.0 publish. Implementation is straightforward for TD-01, TD-02, TD-04, and TD-05; TD-03 requires retiring `locate_encrypted_assertion/1`'s regex without breaking ENC-01 decrypt-then-reparse semantics.

## TD-01: Metadata attribute escaping

**Current state:** `lib/relyra/protocol/metadata.ex` interpolates `issuer`, `acs_url`, and `authn_requests_attr` directly into attribute values (`entityID="#{issuer}"`, `Location="#{acs_url}"`).

**Reference:** `lib/relyra/security/xml/c14n.ex` private `escape_attr/1` implements XML 1.0 attribute escaping (`&`, `<`, `"`, tab, LF, CR). It is private to C14N.

**Recommendation:** Add `Relyra.Security.XML.escape_attribute/1` (or `Relyra.Protocol.Metadata` private `escape_attr/1` mirroring C14N rules) and route every dynamic attribute interpolation through it. Do not call private `C14n.escape_attr/1` — keeps metadata decoupled from C14N internals (CONTEXT D-11).

**Test:** New `test/security/metadata_attribute_injection_test.exs` with adversarial `entityID` / `Location` values; register in `mix.exs` `ci.security` as its own `cmd mix test` line and add row to `@gated_suites` in `ci_gate_integrity_test.exs`.

## TD-02: test_support production exclusion

**Current state:**
- `lib/relyra/test_support/` contains `fake_idp.ex`, `xmldsig_signer.ex`.
- `package.files` includes `"lib"` wholesale → test_support ships in Hex tarball.
- `elixirc_paths(:prod)` is `["lib"]` → modules compile in prod builds.

**Recommendation (dual layer):**
1. **`package.files`:** Replace bare `"lib"` with an explicit file list (glob `lib/**/*.ex` and friends) that **excludes** any path matching `test_support`.
2. **`elixirc_paths(:prod)`:** Return explicit compile roots under `lib/` that omit `lib/relyra/test_support` (e.g. glob `lib/relyra/*` dirs excluding `test_support`, or a small helper that lists compile paths). Dev/test keep `["lib", "test/support"]` as today.

**Verify locally:** `MIX_ENV=prod mix hex.build` then `tar -tzf relyra-*.tar.gz | grep test_support` must return empty (document command in plan for Phase 45 parity).

## TD-03: Parse-tree-bound encrypted assertion bytes

**Current state:**
- `detect_encrypted/1` walks `parse_tree` (correct).
- `locate_encrypted_assertion/1` uses regex on raw `response_payload` to extract bytes for `XMLEnc.decrypt/3` and `String.replace/3` (violates one-trust-path for *location*).

**Constraint:** Decryption needs **wire-format** EncryptedAssertion element bytes. `C14n.serialize/2` may normalize infoset and break XML-Enc ciphertext boundaries — do not use C14N output as decrypt input without proof.

**Recommended approach:** Extend `SaxyTree` parse state to track **byte spans** on each element during the existing single `Saxy.parse_string/3` pass:
- Thread `source :: binary` and `pos :: non_neg_integer` through handler state.
- On `:start_element`, record `start_byte` from current pos; on `:end_element`, record `end_byte` and store `{start_byte, end_byte}` on the `Node` (new optional fields, default nil for backward compat).
- `locate_encrypted_assertion/2` becomes `locate_encrypted_assertion(response_payload, %Node{})` → `binary_part(response_payload, start, end - start)` when span present; if span missing, return `:ambiguous` (fail closed).

**Preserve:** `detect_encrypted` ambiguity rules (cleartext+encrypted, multiple EncryptedAssertion), opaque `:decryption_failed`, single `parse_safely/2` reparse after decrypt. Keep existing tests in `decrypt_assertion_test.exs` and `xml_enc_adversarial_test.exs` green.

**Delete:** Regex in `locate_encrypted_assertion/1` entirely.

## TD-04: Doc drift

**Targets (from CONTEXT):**
- `README.md` — provider count
- `.planning/milestones/v1.3-REQUIREMENTS.md` — EncryptedAttribute in ENC-01
- `.planning/research/FEATURES.md`, `SUMMARY.md` — historical EncryptedAttribute claims → mark historical or correct
- `.planning/PROJECT.md` if "8 presets" remains
- Active `REQUIREMENTS.md` TD-04 line is the requirement itself (already correct framing)

**Copy standard:** "4 first-class presets + a generic SAML runbook covering 7 IdP families" with named families per CONTEXT D-09.

## TD-05: Formatting

Run `mix format` on `test/security/xml/adversarial_crypto_test.exs` (lines 188–200 region called out in audit). Verify `mix format --check-formatted` and `mix test test/security/xml/adversarial_crypto_test.exs --only adversarial_crypto` — no assertion changes.

## Plan structure recommendation

| Plan | Requirements | Wave | Depends on |
|------|--------------|------|------------|
| 41-01 | TD-01 | 1 | — |
| 41-02 | TD-02 | 1 | — |
| 41-03 | TD-03 | 2 | 41-01, 41-02 (optional; no file conflict — can wave 1 if desired) |
| 41-04 | TD-04 | 3 | — |
| 41-05 | TD-05 | 3 | — |

41-03 touches `saxy_tree.ex` + `validation_pipeline.ex`; safe to run parallel with 41-01/02 (no shared files). Use wave 1: 01+02+03 parallel; wave 2: 04+05 parallel for faster milestone.

## Risks

| Risk | Mitigation |
|------|------------|
| Byte-span tracking drifts on Saxy upgrades | Unit test: span slice equals regex locator output on golden ENC fixtures before deleting regex |
| package.files glob too loose | Tarball grep gate in plan + Phase 45 |
| Format-only diff hides semantic change | TD-05 plan limits diff to adversarial_crypto_test.exs; run `--only adversarial_crypto` |
