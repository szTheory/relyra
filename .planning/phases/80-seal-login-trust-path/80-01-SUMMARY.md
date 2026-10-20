---
phase: 80-seal-login-trust-path
plan: 01
status: complete
requirements: [BIND-01, BIND-02, BIND-03, BIND-04, BIND-05, BIND-06, BIND-07, BIND-08]
commit: 2782344
---

# Phase 80 Summary: Seal the login trust path

**Outcome:** the confirmed envelope-injection bypass is closed, along with the
related login seams S1–S4, S6–S11 and S20. `mix qa` (1062 tests, 0 failures),
`mix ci.security` (exit 0) and `mix format --check-formatted` all pass.

## What changed

- `pure_beam.ex`: binds exactly one direct-child `saml:Assertion` (namespace-URI
  matched), derives every assertion field from that bound node, binds the
  enveloped direct-child `ds:Signature` with a single Reference whose URI equals
  the assertion ID, and reads crypto inputs/methods from that Signature only.
  Duplicate IDs and rogue document-KeyInfo are rejected before binding.
- `signature.ex`: Reference digest hash from the bound DigestMethod; declared
  CanonicalizationMethod allowlisted to exclusive C14N.
- `validation_pipeline.ex`: real `bind_signed_node/2`, Assertion-Issuer check,
  bearer SubjectConfirmationData InResponseTo correlation.
- Test signers emit conformant enveloped signatures; new permanent
  `trust_binding` corpus gated in `ci.security`; new typed errors documented.

## Evidence

- `test/security/xml/trust_binding_test.exs` — 16 rows through the public API,
  each red before the fix and green after.
- Interop preserved: FakeIdP, `Relyra.Testing`, conformance, adversarial_crypto,
  corpus, and gate-integrity suites stay green.

## Deferred to Phase 81

Logout (POST + redirect), encrypted-assertion splice, and metadata extraction
(S13–S18) are untouched here; the logout path keeps its pre-Phase-80 signature
derivation via `legacy_signature_fields/1` until Phase 81 rebinds it.
