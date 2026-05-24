# Phase 30: Adversarial crypto assurance - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-24
**Phase:** 30-adversarial-crypto-assurance
**Mode:** assumptions
**Areas analyzed:** FakeIdP real-signing (promotion); Adversarial corpus architecture; CI/conformance wiring; c14n-differential fixture construction; Phase 29 follow-up scope

## Assumptions Presented

### FakeIdP real-signing — promote XmldsigSigner via delegation
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `FakeIdP.sign/2` delegates to `XmldsigSigner.sign_response/1` (promote, not rewrite); expose trust cert | Confident | `xmldsig_signer.ex:29-32, 104-127, 208`; Phase 29 D-12; `29-04-SUMMARY.md:171`; reuses `FakeIdP.keypair()` |
| Reconcile FakeIdP XML shape (add `<CanonicalizationMethod>`, drop `\s+`-collapse) so signed bytes match verifier recompute | Confident | `fake_idp.ex:128-134` vs `xmldsig_signer.ex:252-254` |

### Adversarial corpus architecture — new crypto-verify suite, FakeIdP-driven
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| 4 crypto categories live in a NEW test module (not JSON corpus); each mints from genuine signer + drives full `parse_safely → verify/4` | Confident | `corpus_security_test.exs:161-194` (parse-layer only); trust cert is runtime `:persistent_term` `fake_idp.ex:85-95`; recipes proven `signature_crypto_test.exs:202-255` |
| Construction recipes: wrong-key / tampered-digest-mismatch / forged-sig / positive control all exist in `signature_crypto_test.exs` | Confident | `:215-224` (throwaway cert), `xmldsig_signer.ex:317-328` (tamper), `:81-90` (forged), `:203-213` (positive) |

### CI + conformance wiring
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| New suite must be named in the `ci.security` alias with a tag (crypto proofs currently OUTSIDE the gate) | Confident | `mix.exs:152-169` (runs corpus + gate02_c14n, not `signature_crypto_test.exs`) |
| c14n-differential JSON row needs full provenance + `CONFORMANCE.md` regen; `ci.conformance --check` fails on drift | Confident | `corpus_security_test.exs:126-141`; `relyra.conformance.ex:51-101, 156-165`; `mix.exs:148-153` |

### c14n-differential fixture construction
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Build as post-signing canonically-significant tamper → `:digest_mismatch`; mutation must be one C14N PRESERVES; NO new Docker golden | Likely | `signature.ex:346-374`; `xmldsig_signer.ex:317-328`; PROVENANCE pitfall catalog; REJECTION asserts only `{:error,_}` so Phase 28 D-12 golden discipline does not apply |

### Phase 29 follow-up scope
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| WR-02..WR-05 stay OUT of scope; note WR-03 if corpus brushes it | Likely | `29-code-review-followups.md:11-42` (deferred; none re-open bypass); ROADMAP Phase 30 success criteria name only the 5 categories + wiring |

## Corrections Made

No corrections — all assumptions confirmed ("Yes, proceed").

## External Research

None performed. The codebase fully supplied the evidence: `XmldsigSigner` implements every construction primitive, `signature_crypto_test.exs` already demonstrates all five recipes + positive control passing through the real verify path, the `ci.security`/conformance wiring is explicit in `mix.exs` and `relyra.conformance.ex`, and the c14n-differential REJECTION case needs no libxml2-minted golden.
