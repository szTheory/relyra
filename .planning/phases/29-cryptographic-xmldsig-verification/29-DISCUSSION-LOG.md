# Phase 29: Cryptographic XMLDSig verification - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-24
**Phase:** 29-cryptographic-xmldsig-verification
**Mode:** assumptions
**Calibration:** minimal_decisive (`config.json` → `preferences.vendor_philosophy: opinionated`)
**Areas analyzed:** Crypto verification wiring & algorithm scope; Mixed-content C14N fix sequencing; Positive-control fixture strategy

## Assumptions Presented

### Crypto verification wiring & data plumbing
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Rewrite `verified_signed_node/4` `[candidate]` arm to do real signature math; gates stay before crypto | Confident | `signature.ex:159-185` returns `{:ok}` with zero crypto (the bypass site) |
| pure_beam surfaces `DigestValue` + `SignatureValue` + `SignedInfo` node per candidate | Confident | candidates carry only `:node`/`:signature_node`/`:transforms_node` (`28-03-SUMMARY`); grep finds no SignatureValue/DigestValue extraction |
| Signature check = `C14N.serialize/2`(SignedInfo) → `:public_key.verify/4` | Confident | `c14n.ex:80,130`; SignedInfo has no enveloped transform |
| Trust source = pubkey from configured `cert_chain` PEM via pkix_decode; never KeyInfo | Confident | `certificate_facts.ex:26-47`; existing `key_info_trust` rejection `signature.ex:113-119` |
| Digest check = recompute over existing `canonicalize/2` path, constant-time compare | Confident | `canonicalize/2` already wires `canonicalize_reference/4` (`28-03-SUMMARY`) |
| URI→digest-atom mapping in AlgorithmPolicy | Confident | `algorithm_policy.ex:30-47` owns the allowlist |
| RSA verified now; ECDSA fails CLOSED (`:unsupported_signature_algorithm`) | Confident | RFC 6931 r‖s vs Erlang DER mismatch; real IdPs sign RSA |
| Error taxonomy: invalid_signature / digest_mismatch / untrusted_certificate / unsupported_signature_algorithm / canonicalization_failed | Confident | `error.ex:7` accepts any atom type |

### Mixed-content C14N fix sequencing
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Fold Option-a fix (ordered `content` walk) INTO Phase 29, before positive control | Confident | `c14n.ex:262-263` emits text before children → real-IdP whitespace mis-canonicalizes → `:digest_mismatch`; `28-04-SUMMARY` lines 121-130 |

### Positive-control fixture strategy
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Phase 29 builds own minimal real signer from FakeIdP's existing keypair; FakeIdP wholesale signing + corpus stay Phase 30 | Likely | `fake_idp.ex:68-73,110-136` non-cryptographic (no DigestValue/SignatureValue); keypair exists `fake_idp.ex:85-95`; ROADMAP assigns ASSUR-02 to Phase 30 |
| SIGV-04 proven by same `do_verify` primitive + TrustAnchor pinning assertion | Likely | `verify_metadata_root/4` delegates verbatim to `do_verify/4` (`signature.ex:76`) |

## Corrections Made

No corrections — user selected "Yes, proceed"; all assumptions confirmed as locked decisions.

## External Research

Two topics were flagged by the analyzer (`:public_key.verify/4` arg shape across the OTP matrix; ECDSA `r‖s`-vs-DER encoding). Both are stable, well-established facts; resolved inline from knowledge rather than via a research-agent spawn:
- **`:public_key.verify/4`** = `:public_key.verify(SignedInfoBytes, :sha256, SignatureValueBytes, PubKey)`; PubKey from `:public_key.pkix_decode_cert/2` → `SubjectPublicKeyInfo`. Stable across OTP 26/27/28. → Folded into CONTEXT `<specifics>`.
- **ECDSA encoding** = XMLDSig (RFC 6931) raw fixed-width `r‖s` vs Erlang's DER `Ecdsa-Sig-Value`. → Basis for D-07 (ECDSA fail-closed; converter deferred). Folded into CONTEXT `<specifics>` + `<deferred>`.
