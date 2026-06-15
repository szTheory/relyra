# Phase 64: Public Testing API & Package Boundary - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-15T21:14:53Z
**Phase:** 64-public-testing-api-package-boundary
**Mode:** assumptions
**Areas analyzed:** Public API shape, security boundary, cross-ecosystem testing patterns, adopter DX, package gates

## Assumptions Presented

### Public Surface
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| `Relyra.Testing` should be a small public fixture API under `lib/relyra/testing*`, not a wholesale promotion of `Relyra.TestSupport`. | Likely | `mix.exs`; `.planning/REQUIREMENTS.md`; `.planning/ROADMAP.md`; `lib/relyra/test_support.ex` |

### Crypto Fixture Generation
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Public success fixtures should reuse the existing signer technique: emitted XML parsed through Relyra's own Saxy/C14N path, real `DigestValue`, real `SignatureValue`, and matching cert chain. | Confident | `lib/relyra/test_support/xmldsig_signer.ex`; `demo/ledger_loop/lib/ledger_loop/fake_idp/signer.ex`; `test/security/xml/adversarial_crypto_test.exs` |

### Verification Path
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Helpers must prove outputs through `Relyra.consume_response/3` or the real Phoenix ACS path, not direct session assignment. | Confident | `lib/relyra.ex`; `lib/relyra/phoenix/controllers/acs_controller.ex`; `guides/getting_started.md`; `test/test_support_demo_test.exs` |

### Negative Fixtures
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| v1.9 should expose only representative typed rejection builders: wrong audience plus crypto tamper/wrong-key or digest mismatch. The permanent adversarial corpus stays private. | Likely | `.planning/REQUIREMENTS.md`; `test/security/xml/adversarial_crypto_test.exs` |

### Phoenix Boundary
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phoenix convenience should be optional and layered over core fixture generation, not required by `Relyra.Testing`. | Likely | `mix.exs`; `.planning/REQUIREMENTS.md` TEST-05 |

### Package Guard
| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Phase tests should extend package/parity checks to require `lib/relyra/testing*` included and `lib/relyra/test_support*` excluded. | Confident | `mix.exs`; `lib/mix/tasks/verify.release_parity.ex`; `test/mix/tasks/verify_release_parity_test.exs` |

## Corrections Made

The user requested a deeper expert-lens discussion of every assumption before context capture. Four focused research tracks were run with subagents:

- Elixir/Phoenix idioms and public test-helper design.
- Security architecture and package-boundary analysis.
- Cross-ecosystem auth/SAML/test-helper lessons.
- Adopter DX, JTBD, docs, and brand voice.

All four tracks converged on the same recommendation: a narrow data-first `Relyra.Testing` facade, optional Phoenix sugar, no public `FakeIdP` framing, and package/security gates proving the boundary.

## External Research

- Elixir/Phoenix idiom pass considered official Elixir library guidance, Phoenix.ConnTest, Plug.Test, and Hex package publishing documentation.
- Cross-ecosystem pass considered Phoenix/Plug/Ecto test patterns, Spring Security SAML, Passport-SAML, Devise, and OmniAuth. Relevant lesson: request/fixture helpers are good; auth-bypass helpers are wrong for Relyra's SAML trust-boundary proof.
- Security pass confirmed Hex `package.files` is the right artifact boundary and that fixture outputs must continue through the real parse/signature/digest/validation pipeline.

## Final Recommendation Captured

Public `Relyra.Testing` should expose explicit, test-only fixture data for direct verifier and ACS-path tests:

- signed success
- wrong audience
- post-signing digest/content tamper
- invalid signature or wrong key
- consume options
- post params

Keep private:

- `Relyra.TestSupport.*`
- `XmldsigSigner` internals
- keypair persistence details
- encrypted/adversarial fixture machinery
- permanent adversarial corpus
- parser/C14N internals
- direct session/auth bypass helpers

No auto-resolved assumptions were used.
