# Phase 41: Pre-publish hygiene - Tech-debt sweep & security hardening - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md - this log preserves the analysis.

**Date:** 2026-05-27
**Phase:** 41-pre-publish-hygiene-tech-debt-sweep-security-hardening
**Mode:** assumptions
**Areas analyzed:** Metadata Attribute Escaping, Production Artifact Exclusion, Encrypted Assertion Trust Path, Docs And Gates

## Assumptions Presented

### Metadata Attribute Escaping

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| TD-01 is scoped to XML attribute positions emitted by `Relyra.Protocol.Metadata.build_sp_metadata/2`, especially `entityID`, `AuthnRequestsSigned`, `Location`, `use`, and `Algorithm`; certificate element text is not the WR-03 attribute-injection target. | Confident | `lib/relyra/protocol/metadata.ex`; `test/relyra/protocol/metadata_test.exs`; `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md` |

### Production Artifact Exclusion

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| TD-02 requires removing `Relyra.TestSupport` modules from the production package contents, not merely relying on runtime `Mix.env() == :prod` guards. | Confident | `mix.exs`; `lib/relyra/test_support.ex`; `lib/relyra/test_support/fake_idp.ex`; `lib/relyra/test_support/xmldsig_signer.ex`; `.planning/ROADMAP.md`; `.planning/REQUIREMENTS.md` |

### Encrypted Assertion Trust Path

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| TD-03 should preserve encrypted-assertion semantics while retiring the regex substring locator: no cleartext+encrypted ambiguity, no multi-`EncryptedAssertion` splice-first behavior, prefix-aware handling, opaque `:decryption_failed`, and reparse through `PureBeam.parse_safely/2` before validation. | Confident | `lib/relyra/protocol/validation_pipeline.ex`; `test/relyra/protocol/decrypt_assertion_test.exs`; `lib/relyra/security/xml/saxy_tree.ex`; `.planning/STATE.md` |

### Docs And Gates

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| TD-04/TD-05 are hygiene-only: update active adopter-facing docs and legacy planning/research drift, wire the new metadata security suite as its own `cmd mix test` step, and format `test/security/xml/adversarial_crypto_test.exs` without semantic changes. | Likely | `.planning/PROJECT.md`; `README.md`; `.planning/milestones/v1.3-REQUIREMENTS.md`; `.planning/research/FEATURES.md`; `mix.exs`; `test/security/ci_gate_integrity_test.exs`; `test/security/xml/adversarial_crypto_test.exs` |

## Corrections Made

No corrections - all assumptions were accepted via the workflow fallback. `request_user_input` was unavailable in Default mode, so the recommended "Yes, proceed" path was used.

## External Research

No external research was performed. Codebase and planning artifacts provided enough evidence for the assumptions.
