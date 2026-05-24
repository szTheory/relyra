---
phase: 29-cryptographic-xmldsig-verification
verified: 2026-05-24T17:30:00Z
status: passed
score: 4/4 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: none
  previous_score: n/a
gaps: []
deferred: []
---

# Phase 29: Cryptographic XMLDSig Verification — Verification Report

**Phase Goal:** A forged or tampered SAML signature is cryptographically rejected; only a genuinely-signed node from the configured IdP verifies. (Wire `:public_key.verify` of canonicalized SignedInfo against the configured IdP cert + DigestValue recompute/compare into `do_verify`, applied to both `verify/4` and `verify_metadata_root/4`; reject forged, tampered, and wrong-key inputs with typed errors.)
**Verified:** 2026-05-24T17:30:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
| --- | ----- | ------ | -------- |
| 1 | `do_verify` cryptographically checks canonicalized `SignedInfo` with `:public_key.verify` against the **configured** IdP cert public key (never document `KeyInfo`); forged/invalid `SignatureValue` → `{:error, %Relyra.Error{}}` | ✓ VERIFIED | `signature.ex:306-339` `verify_signature_math` calls `safe_verify` → `:public_key.verify` (397); key comes ONLY from configured `cert_chain` via `public_key_from_cert_chain/1` (287-300, `pkix_decode_cert` → SubjectPublicKeyInfo); document KeyInfo rejected BEFORE crypto at `do_verify` cond (115-121). Forged sig → `:invalid_signature` proven by crypto test (signature_crypto_test.exs:81-88) AND wrong-key test (215-223). Inversion check: grep for `{:ok, %SignedNode` found ZERO unguarded constructions — the only build site is behind `with :ok <- cryptographically_verify(...)` (177-187). |
| 2 | Reference `DigestValue` recomputed over canonicalized transformed referenced element + compared; tampered `NameID` rejected | ✓ VERIFIED | `signature.ex:346-374` `verify_reference_digest`: `PureBeam.canonicalize(candidate)` over bound `:node` → `:crypto.hash(digest_atom, ref_bytes)` (349) → length-guard `byte_size(recomputed) == byte_size(declared)` (351) BEFORE constant-time `:crypto.hash_equals` (352). Tampered-NameID → `:digest_mismatch` proven (signature_crypto_test.exs:226-234); C14N document-order precondition (Plan 01) proven by mixed-content golden (corpus_security_test.exs:93-103, gate02_c14n passes 3/0). |
| 3 | Wrong-key or digest-mismatch rejected with typed error; genuine positive control → `{:ok, %SignedNode{}}` | ✓ VERIFIED | Positive control: genuinely-signed Response → `{:ok, %SignedNode{}}` (signature_crypto_test.exs:181, 204-211 via `XmldsigSigner.signed_response`). Wrong-key → `:invalid_signature` (215-223). ECDSA → `:unsupported_signature_algorithm` before any verify (132-138; runtime spot-check confirmed). Truncated/wrong digest → `:digest_mismatch` no crash (102-126). Malformed cert → `:untrusted_certificate` (144-147). Plan 04 triage re-pointed `consume_response_pipeline_test.exs` + `sp_conformance_test.exs` at the genuine signer (no structure-only `{:ok}` survives). |
| 4 | `verify_metadata_root/4` uses same signature-math primitive on `EntityDescriptor`/`EntitiesDescriptor`, with operator-pinned `TrustAnchor` fingerprint pinning preserved as defense-in-depth (signature math, not pinning alone) | ✓ VERIFIED | `verify_metadata_root/4` (signature.ex:66-93) delegates to the SAME `do_verify/4`. Metadata-root tree-bound candidate (pure_beam.ex:149-236) carries `:node`/`:signed_info_node`/`:digest_value_b64`/`:signature_value_b64`. SIGV-04 positive → `{:ok, %SignedNode{}}` (auto_refresh_test.exs:215-239); tampered entityID → `:digest_mismatch` proving REAL crypto not pinning-alone (314-333); wrong-fingerprint rejected by pinning BEFORE math (282-312). CR-01 fix: `TrustAnchor.matching_pems/2` (trust_anchor.ex:50-84) returns ONLY pinned PEMs; `verify_against_pinned/3` (auto_refresh.ex:169-180) verifies against ONLY pinned cert(s). |

**Score:** 4/4 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `lib/relyra/security/signature.ex` | Crypto verify (sig math + digest recompute) wired into `[candidate]` arm; cert_chain threaded; PEM→pubkey helper; fail-closed try/rescue + length guard | ✓ VERIFIED | 420 lines. `cryptographically_verify/4` (205-233) wired BETWEEN `[candidate]` match and `%SignedNode{}` build (177-187). cert_chain threaded `do_verify/4`→`verify_algorithms_and_candidates/4`→`verified_signed_node/5`→arm. `safe_verify` rescues (396-400); `public_key_from_cert_chain` never raises (287-300). |
| `lib/relyra/security/algorithm_policy.ex` | `digest_atom_for_signature_method/1` RSA→atom, ECDSA/unknown fail-closed | ✓ VERIFIED | `digest_atom_for_signature_method/1` (87-99): ECDSA checked BEFORE rsa suffix (91); RSA-SHA256/384/512→atom; unknown/nil→`:unsupported_signature_algorithm`. Runtime spot-check confirmed all three paths. |
| `lib/relyra/security/xml.ex` | `:digest_mismatch` + `:unsupported_signature_algorithm` in error union | ✓ VERIFIED | Both atoms in `@type xml_error_type` (xml.ex:23-24). |
| `lib/relyra/security/xml/pure_beam.ex` | D-02 keys in signed_candidates + handle + metadata-root variant | ✓ VERIFIED | D-02 keys in assertion `signed_candidates` (375-377), `canonicalize` handle (543-545), and metadata-root candidate (230-232). `parse_metadata_root_safely/2` (85-110) routes via SaxyTree (no regex/second parser). |
| `lib/relyra/security/xml/saxy_tree.ex` + `c14n.ex` | Ordered `content` field + document-order C14N render | ✓ VERIFIED | gate02_c14n golden tests (887-byte + mixed-content) pass 3/0 byte-for-byte vs libxml2 oracle. No debt markers. |
| `lib/relyra/metadata/trust_anchor.ex` | `matching_pems/2` returns ONLY pinned PEMs; `fingerprint/1` hashes DER | ✓ VERIFIED | `matching_pems/2` (50-84) filters to pinned-only; `fingerprint/1` (117-122) hashes DER via `der_from_pem`, sentinel for junk. CR-01/CR-02 regression tests (trust_anchor_test.exs) directly exercise the prepend-attack and DER-vs-PEM cases. |
| `lib/relyra/metadata/auto_refresh.ex` | `do_verify_signature/3` verifies against ONLY pinned cert(s) | ✓ VERIFIED | `do_verify_signature/3` (145-162) uses `matching_pems` → `verify_against_pinned/3` (169-180) — verifies pinned PEMs only, never the document set; no fallback to unpinned cert. |
| `lib/relyra/test_support/xmldsig_signer.ex` | Genuine signer reusing FakeIdP keypair; verifier's C14N; prod-guarded; NameID-tamper knob | ✓ VERIFIED | `:public_key.sign` (279) over `C14N.serialize`-canonicalized SignedInfo; `PureBeam.canonicalize` for DigestValue (269); reuses `FakeIdP.keypair()` (NO second `generate_key` — only in moduledoc); prod-guarded (369-370); `maybe_tamper_name_id` (319-326). |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| `signature.ex` | configured cert_chain pubkey | `pkix_decode_cert(der, :otp)` → SubjectPublicKeyInfo | ✓ WIRED | signature.ex:287-300 |
| `do_verify/4` | `verified_signed_node` arm | cert_chain threaded through `verify_algorithms_and_candidates` | ✓ WIRED | signature.ex:135, 151, 161; arity bumped, callers updated |
| `signature.ex` | `C14N.serialize(SignedInfo)` + `PureBeam.canonicalize(node)` | `:public_key.verify` + `:crypto.hash_equals` | ✓ WIRED | signature.ex:315, 347, 397, 352 |
| `auto_refresh.ex` | `verify_metadata_root → do_verify → crypto` | tree-bound candidate w/ D-02 keys | ✓ WIRED | auto_refresh.ex:159-160, 169-180; pure_beam.ex:223-235 |
| `auto_refresh.ex` | `TrustAnchor` | pinning runs BEFORE verify_metadata_root | ✓ WIRED | auto_refresh.ex:156-160; wrong-fingerprint test (auto_refresh_test.exs:282-312) proves call order |
| `xmldsig_signer.ex` | verifier's C14N / canonicalize | sign with same engine, then `:public_key.sign` | ✓ WIRED | xmldsig_signer.ex:269, 276, 279 |
| triage tests | `XmldsigSigner` / typed rejection | structure-only `{:ok}` tests re-pointed | ✓ WIRED | consume_response_pipeline_test.exs:96,320,338; sp_conformance_test.exs:24,86,171 |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| `cryptographically_verify/4` | `public_key` | `public_key_from_cert_chain(cert_chain)` (configured operator cert, real ASN.1 decode) | Yes | ✓ FLOWING |
| `verify_reference_digest/4` | `ref_bytes` | `PureBeam.canonicalize(candidate)` over bound `:node` tree | Yes (real C14N bytes) | ✓ FLOWING |
| metadata-root candidate | `:node` / D-02 keys | `SaxyTree.parse` + tree walk (no regex) | Yes | ✓ FLOWING |
| `XmldsigSigner` | `DigestValue` / `SignatureValue` | real `:crypto.hash` + `:public_key.sign` over canonicalized bytes | Yes (genuine, not placeholder) | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| RSA-SHA256 → digest atom | `AlgorithmPolicy.digest_atom_for_signature_method(rsa-sha256)` | `{:ok, :sha256}` | ✓ PASS |
| ECDSA fail-closed | same fn, ecdsa-sha256 URI | `{:error, :unsupported_signature_algorithm}` | ✓ PASS |
| nil fail-closed | same fn, `nil` | `{:error, :unsupported_signature_algorithm}` | ✓ PASS |
| Full suite green | `mix test --warnings-as-errors` | 547 tests, 0 failures | ✓ PASS |
| Security CI | `mix ci.security` | exit 0 (Sobelow low-confidence info only) | ✓ PASS |
| Crypto + metadata tests | `mix test signature_crypto_test.exs auto_refresh_test.exs --warnings-as-errors` | 34 tests, 0 failures | ✓ PASS |
| C14N goldens | `mix test corpus_security_test.exs --only gate02_c14n` | 3 tests, 0 failures (887-byte + mixed-content byte-equal to libxml2) | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| SIGV-01 | 29-02, 29-03, 29-04 | Response/assertion XMLDSig cryptographically verified; `:public_key.verify` of canonicalized SignedInfo against configured cert (never KeyInfo); forged/invalid → typed error | ✓ SATISFIED | signature.ex crypto wiring + forged/wrong-key negatives + genuine positive; REQUIREMENTS.md:15 marked `[x]` |
| SIGV-02 | 29-01, 29-03, 29-04 | Reference DigestValue recomputed over canonicalized transformed element + compared; content tamper rejected even with well-formed SignatureValue | ✓ SATISFIED | verify_reference_digest + tampered-NameID negative + mixed-content C14N precondition; REQUIREMENTS.md:16 `[x]` |
| SIGV-04 | 29-05 | Metadata-root signatures cryptographically verified using same primitive (signature math, not pinning alone), preserving operator-pinned TrustAnchor as defense-in-depth | ✓ SATISFIED | verify_metadata_root → do_verify; SIGV-04 positive + tampered-entityID `:digest_mismatch` + wrong-fingerprint pinning reject; REQUIREMENTS.md:18 `[x]` |

**Orphaned requirements:** None. SIGV-01/02/04 are the only SIGV IDs mapped to Phase 29 (SIGV-03 is Phase 28, Complete). All declared plan requirement IDs are accounted for; no REQUIREMENTS.md ID maps to Phase 29 without a claiming plan.

### Code-Review Resolution (CR-01 / CR-02 / WR-01)

| Finding | Severity | Fix in code | Commit | Status |
| ------- | -------- | ----------- | ------ | ------ |
| CR-01 — metadata fail-open trust bypass | BLOCKER | `matching_pems/2` returns pinned-only (trust_anchor.ex:50-84); `verify_against_pinned/3` (auto_refresh.ex:169-180) never uses document set | `8910200` | ✓ FIXED + regression test (trust_anchor_test.exs:39-49 prepend attack) |
| CR-02 — fingerprint over PEM text vs DER | BLOCKER | `fingerprint/1` hashes DER (trust_anchor.ex:117-122); `import.ex:92` routed through it | `8910200` | ✓ FIXED + regression test (trust_anchor_test.exs:18-30 refutes PEM-text hash) |
| WR-01 — line-wrapped base64 rejected | WARNING | `decode_b64/1` uses `Base.decode64(..., ignore: :whitespace)` (signature.ex:389) | `ef44482` | ✓ FIXED + regression test (signature_crypto_test.exs:241-252) |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| (modified lib files) | — | TODO/FIXME/XXX/TBD/HACK/PLACEHOLDER | — | NONE — zero debt markers across all 9 phase-modified lib files |
| `auto_refresh_test.exs` | 140-211 | `assert true` placeholder tests | ℹ️ Info | Pre-existing Phase 21 `@tag :integration` scaffolding (drift/corpus/validity-warning paths), NOT Phase 29 SIGV coverage. Real coverage cited inline (scheduler_test, corpus_gate_test, metadata_apply_test). The four SIGV-04 crypto tests (214-334) are full real assertions. Not a Phase 29 gap. |

### Deferred Code-Review Items (tracked, none re-open the bypass)

WR-02 (SignedInfo prefix-list mis-selection), WR-03 (Reference/@URI not bound to consumed node), WR-04 (enveloped metadata signature prune without explicit transform), WR-05 (trust regex on pre-byte-guard raw XML), IN-01..03 — all tracked in `.planning/todos/pending/29-code-review-followups.md`. Confirmed interop/defense-in-depth only: WR-02/04 are fail-CLOSED (reject legitimate, never accept forged); WR-03 binds correctly for the single-ref/single-assertion case; WR-05's signature math still runs only after byte guards (only pinning, itself fail-closed, runs on capped 5MB raw input). None re-opens the closed auth bypass.

### Human Verification Required

None. All observable truths verified programmatically against the codebase with running tests, runtime spot-checks, real positive/negative crypto controls, and direct CR-01/CR-02 attack-shape regression tests. No visual, real-time, or external-service behavior requires human testing.

### Gaps Summary

No gaps. The phase goal is achieved in the codebase:

- Real `:public_key.verify` of the canonicalized SignedInfo against the configured cert_chain public key (never document KeyInfo) is wired into the single `do_verify` primitive, covering both `verify/4` and `verify_metadata_root/4`.
- Real DigestValue recompute via `:crypto.hash` over the canonicalized bound referenced node, compared with length-guarded constant-time `:crypto.hash_equals`.
- Forged, tampered, wrong-key, ECDSA, malformed-cert, and non-base64 inputs all fail CLOSED to typed `%Relyra.Error{}` with no crashes; a genuinely-signed positive control returns `{:ok, %SignedNode{}}`.
- The metadata path enforces operator-pinned TrustAnchor AND verifies the signature against ONLY the pinned cert(s) — the CR-01 fail-open bypass is closed and the CR-02 DER fingerprint is aligned across pin/drift/import.
- Honesty (DISC-01): SIGV-01/02/04 are genuinely satisfied and NOT overstated. The inversion check confirmed no `{:ok}` fall-through bypasses crypto; the Plan 04 triage re-pointed end-to-end login tests at the genuine signer so no structure-only `{:ok}` survives; CR-01/CR-02 have direct attack-shape regression tests.
- Full suite green (547/0, `--warnings-as-errors`); `mix ci.security` exit 0.

---

_Verified: 2026-05-24T17:30:00Z_
_Verifier: Claude (gsd-verifier)_
