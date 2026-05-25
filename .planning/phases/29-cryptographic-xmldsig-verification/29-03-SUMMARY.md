---
phase: 29-cryptographic-xmldsig-verification
plan: 03
subsystem: security/signature
tags: [xmldsig, crypto, public_key, auth-bypass-fix, fail-closed, SIGV-01, SIGV-02]
requires:
  - "29-01 (mixed-content C14N document-order fix — byte-exact canonical bytes)"
  - "29-02 (D-02 crypto inputs on candidate map; AlgorithmPolicy.digest_atom_for_signature_method/1; C14N document-order walk + anti-XSW prune-on-content)"
provides:
  - "Real cryptographic XMLDSig verification in the [candidate] arm of verified_signed_node (the published-hex auth-bypass site, D-01)"
  - "cert_chain threaded do_verify/4 → verify_algorithms_and_candidates/4 → verified_signed_node/5 → the arm"
  - "Signature.public_key_from_cert_chain/1 — fail-closed PEM→RSA pubkey extractor (@doc false, reusable)"
  - ":digest_mismatch and :unsupported_signature_algorithm in the xml_error_type union (D-08)"
  - "Genuine in-test XMLDSig signer (genuine_signed_doc/0) — the canonical shape Plan 04 promotes for D-11"
affects:
  - "verify/4 (sp_initiated) and verify_metadata_root/4 (metadata_refresh) — both delegate to do_verify/4, so the crypto covers both (primes SIGV-04 for Plan 05)"
  - "Every end-to-end flow that fed structure-only signatures now fails closed (deferred triage → Plan 04)"
tech-stack:
  added: []
  patterns:
    - "OTP-bundled crypto only: :public_key.verify/4, :public_key.pkix_decode_cert/2, :crypto.hash/2, :crypto.hash_equals/2, Base.decode64/2 (no new deps — ADR-0001 pure-BEAM)"
    - "Fail-closed try/rescue around every crypto/decode call; length-guard before :crypto.hash_equals (Pitfalls 3,4)"
    - "Gates-before-crypto: all pre-existing trust gates run in do_verify/4 BEFORE the arm's crypto"
    - "SignedInfo → bare C14N.serialize (D-03); referenced element → PureBeam.canonicalize transform chain (D-05) — different C14N entry points (Pattern 3)"
key-files:
  created:
    - "test/relyra/security/signature_crypto_test.exs (crypto negative controls + genuine positive smoke + in-test signer)"
    - ".planning/phases/29-cryptographic-xmldsig-verification/deferred-items.md (existing-test triage → Plan 04)"
  modified:
    - "lib/relyra/security/signature.ex (crypto wiring + cert_chain threading + PEM→pubkey helper)"
    - "lib/relyra/security/xml.ex (two new error atoms)"
    - "test/security/signed_node_binding_test.exs (triaged the one structure-only {:ok} test to fail-closed)"
decisions:
  - "public_key_from_cert_chain/1 is @doc false public (not private) so Plan 04 + future callers can reuse the fail-closed extractor without re-deriving it; the wrapped arity adds the typed %Relyra.Error{} (details merged)."
  - "Used pkix_test_root_cert/2 (OTP-bundled) for in-process cert generation in the smoke — no openssl dependency, no committed key material."
  - "Triaged the single structure-only {:ok} test in signed_node_binding_test.exs in-scope (Rule 1/3): it is in Plan 03's mandated green lane; the fuller test/protocol/ + conformance + ACS triage stays deferred to Plan 04 (logged in deferred-items.md)."
metrics:
  duration: "~24m"
  completed: "2026-05-24"
  tasks: 2
  files_created: 2
  files_modified: 3
---

# Phase 29 Plan 03: Cryptographic XMLDSig verification Summary

Real `:public_key.verify` of the canonicalized `SignedInfo` against the configured `cert_chain`
RSA key, plus a constant-time `DigestValue` recompute over the canonicalized referenced element,
wired into the `[candidate]` arm of `verified_signed_node` — closing the published-hex SAML
authentication bypass behind the existing `Relyra.Security.Signature` trust gates.

## What Was Built

The `[candidate]` arm of `verified_signed_node` (signature.ex) previously returned
`{:ok, %SignedNode{}}` with **zero crypto** for any single selected candidate — the confirmed
auth-bypass (D-01). It now performs genuine cryptographic verification **between** selecting the
single candidate and building `%SignedNode{}`, reading the D-02 crypto inputs
(`:signed_info_node`, `:signature_value_b64`, `:digest_value_b64`, `:node`) off the RAW candidate
map. `%SignedNode{}` is built only when **both** the signature math and the digest recompute pass;
otherwise a typed `%Relyra.Error{}` names the failed check.

`cert_chain` is now threaded `do_verify/4` → `verify_algorithms_and_candidates/4` →
`verified_signed_node/5` → the arm (mandatory arity bumps; callers updated) so the crypto can read
the configured trust key. Because both `verify/4` and `verify_metadata_root/4` delegate to
`do_verify/4`, the crypto covers SIGV-01/02 here and primes SIGV-04 for Plan 05.

### Crypto step order (all fail CLOSED, typed; nothing raises)
1. **Required-field guards** — missing `SignedInfo`/`SignatureValue`/`DigestValue`/`:node` → typed reject.
2. **Digest-atom + ECDSA gate (D-06/D-07)** — `AlgorithmPolicy.digest_atom_for_signature_method/1`; ECDSA/unknown → `:unsupported_signature_algorithm` **before any verify** (Pitfall 5).
3. **Trust-source key (D-04)** — `public_key_from_cert_chain/1`: `pem_decode` → `pkix_decode_cert(der, :otp)` → `element(8)` SPKI → `:RSAPublicKey`; `try/rescue` maps every malformed PEM/DER to `:untrusted_certificate`, never raises (Pitfall 3).
4. **Signature math (D-03)** — `C14N.serialize(SignedInfo, prefix_list: …)` (PrefixList read from the SignedInfo's own `InclusiveNamespaces`, empty otherwise — Open Q2) → `Base.decode64(SignatureValue)` (`:error` → `:invalid_signature`) → `safe_verify` wrapping `:public_key.verify` (`rescue _ -> false`); `false` → `:invalid_signature`.
5. **Digest check (D-05)** — `PureBeam.canonicalize(candidate)` over the bound `:node` → `:crypto.hash(digest_atom, ref_bytes)` → `Base.decode64(DigestValue)` (`:error` → `:digest_mismatch`) → **length-guard** `byte_size(recomputed) == byte_size(declared)` BEFORE `:crypto.hash_equals/2` (Pitfall 4); mismatch → `:digest_mismatch`.

### New error vocabulary
`:digest_mismatch` and `:unsupported_signature_algorithm` added to the `xml_error_type` union in
`xml.ex` (D-08; `Relyra.Error` already accepts any atom type).

### Genuine positive smoke (Wave-2 gate — proves the wiring reaches the crypto)
`signature_crypto_test.exs` ships an in-test genuine XMLDSig signer (`genuine_signed_doc/0`): an
RSA-2048 keypair + self-signed cert PEM (via OTP `pkix_test_root_cert/2`), a referenced Assertion
node, the REAL `DigestValue` computed over `PureBeam.canonicalize` of that node (the SAME engine
the verifier uses), a `SignedInfo` embedding it, and `:public_key.sign` over `C14N.serialize` of
the SignedInfo (the SAME engine — D-12). It asserts `{:ok, %SignedNode{}}`, proving the path
reaches `:public_key.verify` + the digest recompute. This is the canonical shape Plan 04 promotes
into the reusable D-11 signer.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| RED | Failing crypto controls + genuine positive smoke | `4c3c218` | test/relyra/security/signature_crypto_test.exs |
| 1+2 (GREEN) | Two error atoms + PEM→pubkey helper + cert_chain threading + crypto in the arm + binding-test triage | `2e45689` | lib/relyra/security/signature.ex, lib/relyra/security/xml.ex, test/security/signed_node_binding_test.exs |

(Task 1 — atoms + helper — and Task 2 — threading + crypto — were satisfied by one GREEN
implementation because the helper is exercised end-to-end through `Signature.verify/4`; the RED
test commit covers both behaviors.)

## Verification Results

- `mix test test/relyra/security/signature_crypto_test.exs --warnings-as-errors` → **14/0**
- `mix test test/relyra/security/signature_crypto_test.exs test/security/signed_node_binding_test.exs --warnings-as-errors` → **19/0**
- `mix test test/relyra/security/ test/security/ --warnings-as-errors` (broader security regression) → **161/0**
- `mix test test/relyra/security/xml/ test/security/xml/ --warnings-as-errors` (C14N golden lane — 887-byte + mixed-content goldens stay byte-exact) → **102/0**
- `mix compile --warnings-as-errors` → clean (exit 0)
- No negative-control test crashes — every malformed input yields a typed `%Relyra.Error{}`.

## Acceptance Criteria

- [x] `cert_chain` threaded from `do_verify/4` to the arm (arities bumped; callers updated) — definite
- [x] arm reads `:signed_info_node`/`:signature_value_b64`/`:digest_value_b64`/`:node` off the RAW candidate map (not a select_candidate handle)
- [x] arm contains `:public_key.verify(`, `:crypto.hash(`, and `byte_size(...) == byte_size(...)` immediately before `:crypto.hash_equals(`
- [x] `safe_verify`-style `try/rescue _ -> false` around `:public_key.verify`
- [x] `prefix_list` read from the SignedInfo's own `InclusiveNamespaces` (empty derived, not hardcoded)
- [x] forged SignatureValue → `:invalid_signature`; non-base64 → `:invalid_signature`
- [x] truncated DigestValue → `:digest_mismatch` and the test returns (no `ArgumentError`)
- [x] ECDSA → `:unsupported_signature_algorithm`; malformed cert → `:untrusted_certificate`
- [x] genuine candidate → `{:ok, %Relyra.Security.SignedNode{}}` (positive smoke)
- [x] `signed_node_binding_test.exs` green (gate rejections unchanged; structure-only positive triaged)
- [x] both new error atoms in the `xml_error_type` union
- [x] all pre-existing trust gates still reject BEFORE crypto (no regression)

## Threat Register Outcomes

| Threat ID | Disposition | Realized mitigation |
|-----------|-------------|---------------------|
| T-29-07 (forged SignatureValue) | mitigated | `:public_key.verify` false → `:invalid_signature` (negative control green) |
| T-29-08 (content tampering / wrong digest) | mitigated | digest recompute + constant-time compare → `:digest_mismatch` (wrong/truncated/non-base64 digest controls green; full NameID-tamper proof → Plan 04) |
| T-29-09 (wrong-key / attacker KeyInfo) | mitigated | key from configured cert_chain only; `key_info_trust == true` rejected before crypto (regression green) |
| T-29-10 (XSW) | mitigated | digest recompute consumes the EXACT bound `:node` via the Phase-28 anti-XSW canonicalize path |
| T-29-11 (algorithm downgrade / ECDSA fail-open) | mitigated | digest-atom gate → `:unsupported_signature_algorithm` BEFORE verify (control green) |
| T-29-12 (timing side-channel) | mitigated | `:crypto.hash_equals/2` constant-time, length-guarded |
| T-29-13 (malformed PEM/key/digest crash) | mitigated | try/rescue → typed error; hash_equals length guard; verify `rescue _ -> false` (no crash on any malformed control) |
| T-29-SC (package installs) | accepted | No installs — OTP `:public_key`/`:crypto` bundled |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug / Rule 3 - Blocking] Triaged the one structure-only `{:ok}` test in `signed_node_binding_test.exs`**
- **Found during:** Task 2 (the binding test is in Plan 03's mandated green lane).
- **Issue:** `test/security/signed_node_binding_test.exs:63-72` fed a single structure-only candidate (no crypto inputs, fake `"pem-cert-chain"`) and asserted `{:ok, %SignedNode{}}`. Once real crypto is wired, that candidate correctly fails closed (`:missing_signature` — no SignedInfo) — the exact bypass being closed. The Plan 03 acceptance criterion requires this file green.
- **Fix:** Converted that single test to assert the new fail-closed behavior (`:missing_signature` with `reason: :missing_signature_input`), documenting that the genuine `{:ok}` positive now lives in `signature_crypto_test.exs` and the fuller pipeline triage is Plan 04. The four gate-rejection tests are unchanged and stay green.
- **Files modified:** `test/security/signed_node_binding_test.exs`
- **Commit:** `2e45689`

## Deferred Issues (out of scope — Plan 04)

Wiring real crypto into the bypass site correctly fails-closed **every** end-to-end flow that
previously fed structure-only signatures and asserted `{:ok}` login (or a post-signature error).
Full-suite blast radius: `mix test --warnings-as-errors` = **521 tests, 10 failures**, all the same
class. These are the bypass closing, NOT regressions, and the plan explicitly defers the
existing-test triage to Plan 04 (which owns the reusable D-11 signer). All Plan-03 lanes are 100%
green. Logged in `deferred-items.md` with the exact file:line list:
`consume_response_pipeline_test.exs` (7), `sp_conformance_test.exs:30`,
`acs_controller_test.exs:52`, `telemetry_test.exs:152`.

## Notes for Plan 04 / Plan 05

- Promote `genuine_signed_doc/0` (signature_crypto_test.exs) into the reusable D-11 signer — it
  canonicalizes with the SAME C14N engine the verifier uses, so the bytes match (D-12).
- `public_key_from_cert_chain/1` is `@doc false` public — reuse it; do not re-derive the extractor.
- SIGV-04 (Plan 05): `verify_metadata_root/4` already inherits this crypto via `do_verify/4`; the
  metadata-root `parsed_doc` must surface the same tree-bound D-02 fields (the regex pre-parse gap
  in `auto_refresh.ex` noted in RESEARCH Pitfall 2 / Open Q1).
- Assumption A1 (configured cert leaf-selection): the helper uses the FIRST PEM only and fails
  closed on it; chain-walk is deferred. The positive smoke uses a single self-signed cert, so it
  does not yet prove multi-cert leaf-selection — visibility flagged in Task 1 acceptance.

## Self-Check: PASSED

All key files exist on disk; both per-task commits (`4c3c218` RED, `2e45689` GREEN) are present in
git history.
