# Phase 34: ValidationPipeline Wiring + ENC-01 Complete - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-05-25
**Phase:** 34-validationpipeline-wiring-enc-01-complete
**Mode:** assumptions
**Calibration:** minimal_decisive (vendor_philosophy: opinionated)
**Areas analyzed:** Pipeline Integration, Error Taxonomy, SP Encryption Certificate + Metadata KeyDescriptor, EncryptedAttribute Scope, Adversarial Corpus + FakeIdP

## Pre-flight: roadmap resolution fix

Phase 34 initially failed to resolve (`init.phase-op` → `phase_found: false`). Root cause: the
GSD resolver requires each phase to appear in the main `.planning/ROADMAP.md` in BOTH the summary
checklist AND a `### Phase N:` detail section; this project kept detail sections only in
`.planning/milestones/v1.3-ROADMAP.md`. Phases 32-33 resolved via directory presence; phases 34-37
had neither. **Resolution (user-approved):** mirrored the verbatim `### Phase 34`-`37` detail
sections into the main ROADMAP.md (commit `6de59a7`). Phase 34 then resolved cleanly.

## Assumptions Presented

### Pipeline Integration
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `:decrypt_assertion` is a new pre-stage in `ValidationPipeline.do_run/4`, not in `Signature.do_verify/4` (do_run owns raw bytes + re-parse) | Confident | `validation_pipeline.ex:62-76,81-82`; `xml_enc.ex:11`; `pure_beam.ex:39,257` |
| No-op path is byte-identical when zero `EncryptedAssertion` elements present | Confident | `validation_pipeline.ex:66`; `pure_beam.ex:466`; `adversarial_crypto_test.exs` |

### Error Taxonomy
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `:ambiguous_assertion` is a new typed `%Error{}` (not opaque `:decryption_failed`); guard runs pre-crypto | Confident | `error.ex:15-18`; `pure_beam.ex:551`; `validation_pipeline.ex:121,166` |

### SP Encryption Certificate + Metadata KeyDescriptor (ENC-02)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Extend `build_sp_metadata/2` (emits no KeyDescriptor today) with net-new `:sp_encryption_cert_pem` + `:sp_signing_cert_pem` config seams; encryption descriptor reads the PUBLIC cert | Likely | `metadata.ex:4-19`; repo grep (no existing cert/KeyDescriptor config); `33-CONTEXT.md` D-01 |
| Signing KeyDescriptor emitted unconditionally in Phase 34; Phase 35 adds toggle gating | Likely | `v1.3-ROADMAP.md` Phase 34 SC#4 vs Phase 35 SC#4; `REQUIREMENTS.md:21` |

### EncryptedAttribute Scope
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| DEFER — Phase 34 wires EncryptedAssertion only (despite REQUIREMENTS.md:12 + thread recommending both) | Decisive (defer) | `v1.3-ROADMAP.md` Phase 34 SC#1-5 (all assertion-level); `validation_pipeline.ex:199`; `encrypted-assertions-investigation.md:51` |

### Adversarial Corpus + FakeIdP
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| 7 ENC-01 fixtures in a new `test/security/` file, own `cmd mix test` subprocess; read-before-verify drives end-to-end through ValidationPipeline | Confident | `mix.exs:152-173` (hollow-gate rule 159-167); `xml_enc_test.exs:4-5`; `adversarial_crypto_test.exs` |
| FakeIdP gains an `encrypt`/`encrypted_response` helper (OAEP + AES-256-GCM); promote recipe from `xml_enc_test.exs:39-56` | Confident | `fake_idp.ex:64-75,88-93`; `xml_enc_test.exs:28-56` |

## Corrections Made

No corrections — all assumptions confirmed by the user ("Yes, proceed"), including the deliberate
deferral of EncryptedAttribute (the one item where the recommendation contradicts the literal
ENC-01 requirement text; user accepted the defer with the milestone-audit tradeoff noted).

## External Research

None performed. The analyzer flagged two SAML/XML-Enc spec-confirmation points (EncryptedAssertion
nesting within Response; KeyDescriptor child ordering / EncryptionMethod advertisement) as
planner-level reading against the spec text, not gaps requiring a web-research agent. Captured as
planner spec-confirmation tasks in CONTEXT.md canonical_refs.
