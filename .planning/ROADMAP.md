# Roadmap: Relyra

## Milestones

- ✅ **v0.1 — SP-initiated SSO, verified end-to-end** (shipped 2026-04-25). See `.planning/milestones/v0.1-ROADMAP.md`.
- ✅ **v0.2 — Enterprise configuration** (shipped 2026-05-06). See `.planning/milestones/v0.2-ROADMAP.md`.
- ✅ **v0.3 — LiveView admin** (shipped 2026-05-06). See `.planning/milestones/v0.3-ROADMAP.md`.
- ✅ **v0.4 — IdP-initiated SSO** (shipped 2026-05-06). See `.planning/milestones/v0.4-ROADMAP.md`.
- ✅ **v0.5 — Operational maturity** (shipped 2026-05-07). See `.planning/milestones/v0.5-ROADMAP.md`.
- ✅ **v0.6 — Operational maturity carryover + SLO** (shipped 2026-05-08). See `.planning/milestones/v0.6-ROADMAP.md`.
- ✅ **v1.0 — External security review + conformance + docs polish** (shipped 2026-05-08). See `.planning/milestones/v1.0-ROADMAP.md`.
- ✅ **v1.1 — Verify the Trust Path** (shipped 2026-05-25). See `.planning/milestones/v1.1-ROADMAP.md`.
- 🔄 **v1.3 — Advanced Federation** (in progress). See `.planning/milestones/v1.3-ROADMAP.md`.

## Phases

<details>
<summary>✅ v0.1 — SP-initiated SSO (Phases 1-6) — SHIPPED 2026-04-25</summary>

See `.planning/milestones/v0.1-ROADMAP.md`.

</details>

<details>
<summary>✅ v0.2 — Enterprise configuration (Phases 7-14) — SHIPPED 2026-05-06</summary>

See `.planning/milestones/v0.2-ROADMAP.md`.

</details>

<details>
<summary>✅ v0.3 — LiveView admin (Phases 15-18) — SHIPPED 2026-05-06</summary>

See `.planning/milestones/v0.3-ROADMAP.md`.

</details>

<details>
<summary>✅ v0.4 — IdP-initiated SSO (Phase 19) — SHIPPED 2026-05-06</summary>

See `.planning/milestones/v0.4-ROADMAP.md`.

</details>

<details>
<summary>✅ v0.5 — Operational maturity (Phases 20-21.2) — SHIPPED 2026-05-07</summary>

See `.planning/milestones/v0.5-ROADMAP.md`.

</details>

<details>
<summary>✅ v0.6 — Operational maturity carryover + SLO (Phases 22-24) — SHIPPED 2026-05-08</summary>

See `.planning/milestones/v0.6-ROADMAP.md`.

</details>

<details>
<summary>✅ v1.0 — External security review + conformance + docs polish (Phases 25-27) — SHIPPED 2026-05-08</summary>

See `.planning/milestones/v1.0-ROADMAP.md`.

</details>

<details>
<summary>✅ v1.1 — Verify the Trust Path (Phases 28-31) — SHIPPED 2026-05-25</summary>

See `.planning/milestones/v1.1-ROADMAP.md`.

</details>

<details open>
<summary>🔄 v1.3 — Advanced Federation (Phases 32-37) — IN PROGRESS</summary>

- [ ] **Phase 32: AlgorithmPolicy Extension + Schema Migrations** — Extend AlgorithmPolicy with key-transport and content-encryption algorithm fields; add cert `party`/`use` columns and connection `sign_authn_requests` field via safe additive migrations.
  **Plans:** 2 plans

  - [x] 32-01-PLAN.md — AlgorithmPolicy struct extension + enforce_key_transport_algorithm/2 + enforce_content_encryption_algorithm/3 (ENC-03)
  - [x] 32-02-PLAN.md — Cert party/use migration + Connection sign_authn_requests migration + Ecto schema fields (ENC-04, AUTHN-02)
- [ ] **Phase 33: KeyResolver Behaviour + XMLEnc Crypto Core** — Introduce the `KeyResolver` behaviour and `KeyResolver.Default` PEM-from-config implementation; build `Relyra.Security.XMLEnc` with RSA-OAEP + AES-GCM decryption behind the AlgorithmPolicy gate.
  **Plans:** 2 plans

  - [x] 33-01-PLAN.md — KeyResolver behaviour + dispatch function + KeyResolver.Default PEM-from-config + key_resolver_test.exs (ENC-04)
  - [x] 33-02-PLAN.md — XMLEnc.decrypt/3 RSA-OAEP + AES-GCM + 4-case security corpus + ci.security registration (ENC-04)
- [ ] **Phase 34: ValidationPipeline Wiring + ENC-01 Complete** — Wire the decrypt-then-reparse step into `ValidationPipeline`; add ambiguity guard; publish SP encryption `KeyDescriptor`; add the 7-fixture ENC-01 adversarial corpus to `mix ci.security`.
- [ ] **Phase 35: Signed AuthnRequests + ADFS Preset** — Implement redirect-binding query signing; add `sign_authn_requests` connection toggle; publish signing metadata fields; ship ADFS preset and runbook; add 5-fixture AUTHN-01 adversarial corpus.
- [ ] **Phase 36: Generic SAML Runbook** — Publish `guides/recipes/generic_saml.md` covering SP/IdP metadata fields, decoder tables for non-preset IdPs, minimum-safe checklist, debugging flow, and certificate rotation.
- [ ] **Phase 37: Identity Mapping and Provisioning Guide** — Publish `guides/identity_mapping_and_provisioning.md` covering three mapping patterns, JIT decision tree, `UserMapper` behaviour documentation, and SCIM non-goal statement.

See `.planning/milestones/v1.3-ROADMAP.md` for full phase details.

### Phase 34: ValidationPipeline Wiring + ENC-01 Complete

**Goal**: An SP configured against an encryption-enabled IdP can successfully log in; a malformed, tampered, or policy-violating encrypted assertion is rejected before any identity field is read.
**Depends on**: Phase 33 (XMLEnc.decrypt/3 must exist).
**Requirements**: ENC-01, ENC-02
**Success Criteria** (what must be TRUE):

  1. A response containing a valid `EncryptedAssertion` completes login successfully: the plaintext is decrypted, re-parsed through `PureBeam.parse_safely/2`, and then `Signature.do_verify/4` succeeds before any identity field (NameID, attributes) is accessible.
  2. A response containing both a cleartext assertion and an encrypted assertion is rejected with `:ambiguous_assertion` before any crypto operation runs.
  3. Non-encrypted response paths are structurally unchanged — the `:decrypt_assertion` pipeline step is a strict no-op when no encrypted assertion is present.
  4. SP metadata endpoint publishes `<KeyDescriptor use="encryption">` containing the SP encryption certificate; `<KeyDescriptor use="signing">` is present and distinct from the encryption entry.
  5. All 7 ENC-01 adversarial corpus fixtures (wrong-key, truncated tag, PKCS1v1.5, CBC, cleartext-injection, malformed ciphertext, read-before-verify attempt) are wired into `mix ci.security` and each returns the correct typed error.

**Plans**: 4 plans
Plans:
**Wave 1**

- [x] 34-01-PLAN.md — ENC-02: emit SP signing + encryption KeyDescriptors in metadata (Wave 1)
- [x] 34-02-PLAN.md — ENC-01: FakeIdP.encrypt/encrypted_response canonical encrypted-assertion generator (Wave 1)
- [ ] 34-03-PLAN.md — ENC-01: :decrypt_assertion pre-stage in ValidationPipeline.do_run/4 (decrypt → reparse → verify; ambiguity guard) (Wave 1)

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 34-04-PLAN.md — ENC-01: 7-fixture pipeline-level adversarial corpus + mix ci.security wiring (Wave 2, depends on 34-02 + 34-03)

**UI hint**: no

### Phase 35: Signed AuthnRequests + ADFS Preset

**Goal**: An SP targeting an ADFS or locked-down Shibboleth IdP that requires `WantAuthnRequestsSigned` can complete login; the redirect-binding signature is byte-exact and verified against a committed golden output.
**Depends on**: Phase 32 (needs `AlgorithmPolicy.signing_digest_atom/1`; can run in parallel with Phases 33-34).
**Requirements**: AUTHN-01, AUTHN-02, AUTHN-03, AUTHN-04
**Success Criteria** (what must be TRUE):

  1. A connection with `sign_authn_requests: true` produces a redirect URL whose `SAMLRequest`, `RelayState`, and `SigAlg` query parameters are signed verbatim in that spec-canonical order; the `Signature` parameter base64-encodes the raw RSA-SHA256 output over the pre-assembled query-string binary.
  2. The bit-for-bit golden output corpus fixture and an ADFS-style `+`-encoded variant both pass in `mix ci.security`; re-serialization of the query string before signing causes the corpus fixture to fail (validates the raw-octet invariant).
  3. A connection with `sign_authn_requests: false` (the default) produces an unsigned redirect URL; no existing Okta, Google, or non-ADFS tests regress.
  4. SP metadata for a signing-enabled connection emits `AuthnRequestsSigned="true"` and a `<KeyDescriptor use="signing">` element; SP metadata for a non-signing connection omits both.
  5. The ADFS provider preset defaults to `sign_authn_requests: true`; `guides/providers/adfs.md` covers claim rules, PowerShell `Set-ADFSRelyingPartyTrust` commands, SHA-1 vs SHA-256 redirect binding interop notes, and the `WantAuthnRequestsSigned` flag.

**Plans**: TBD

### Phase 36: Generic SAML Runbook

**Goal**: An operator integrating a non-preset IdP (IBM Security Verify, CyberArk, Oracle Access Manager, PingFederate, CA SiteMinder, ADFS custom, or Shibboleth) has one authoritative runbook that gets them through setup without reading the SAML spec.
**Depends on**: Nothing (pure documentation; no code dependency; can run in parallel with any phase after Phase 32).
**Requirements**: DOCS-02
**Success Criteria** (what must be TRUE):

  1. `guides/recipes/generic_saml.md` is published and covers: SP metadata field reference with plain-English descriptions, IdP metadata import checklist, attribute/claim decoder tables for IBM Security Verify, CyberArk, Oracle Access Manager, PingFederate, and CA SiteMinder.
  2. The guide includes ADFS-specific and Shibboleth-specific subsections, a NameID format decision guide, and sections on when to enable signing and encryption.
  3. A minimum-safe security settings checklist, a step-by-step debugging flow, and a certificate rotation procedure are included, written at the operator level (no SAML spec knowledge assumed).

**Plans**: TBD

### Phase 37: Identity Mapping and Provisioning Guide

**Goal**: An operator implementing JIT provisioning or attribute-to-user mapping has one authoritative guide covering the three canonical patterns and an explicit decision tree — and knows exactly where Relyra's responsibility ends and their application's begins.
**Depends on**: Nothing (pure documentation; no code dependency; can run in parallel with any phase).
**Requirements**: DOCS-03
**Success Criteria** (what must be TRUE):

  1. `guides/identity_mapping_and_provisioning.md` is published and covers all three mapping patterns: NameID-as-local-identifier, attribute-as-local-identifier, and JIT create-or-update.
  2. A JIT decision tree helps operators choose between patterns based on their identity model; the `UserMapper` behaviour is fully documented with at least one complete implementation example per pattern.
  3. The guide explicitly states the SCIM lifecycle non-goal, warns about JIT+SCIM simultaneous-use conflicts, and explains anchor stability guidance (what breaks when NameID format changes between logins).

**Plans**: TBD

</details>

## Progress

| Phase | Milestone | Plans | Status | Completed |
|-------|-----------|-------|--------|-----------|
| 01. XML security ADR + guardrails | v0.1 | 3/3 | Complete | 2026-04-25 |
| 02. Protocol + signature core | v0.1 | 5/5 | Complete | 2026-04-25 |
| 03. Behaviour contracts + stores | v0.1 | 3/3 | Complete | 2026-04-25 |
| 05. Observability + enforcement | v0.1 | 1/1 | Complete | 2026-04-25 |
| 06. Delivery hardening + adoption surface | v0.1 | 1/1 | Complete | 2026-04-25 |
| 07. Schema + connection aggregate | v0.2 | 3/3 | Complete | 2026-05-05 |
| 08. Resolver adapter + snapshotting | v0.2 | 3/3 | Complete | 2026-05-05 |
| 09. Metadata import/export + refresh | v0.2 | 4/4 | Complete | 2026-05-06 |
| 10. Certificate inventory + rollover | v0.2 | 3/3 | Complete | 2026-05-06 |
| 11. Mapping persistence + audit hardening | v0.2 | 4/4 | Complete | 2026-05-06 |
| 12. Metadata refresh trust-state repair | v0.2 | 3/3 | Complete | 2026-05-06 |
| 13. Certificate rollover validation + verification | v0.2 | 3/3 | Complete | 2026-05-06 |
| 14. Mapping/audit milestone verification | v0.2 | 2/2 | Complete | 2026-05-06 |
| 15. Admin shell + connection lifecycle | v0.3 | 3/3 | Complete | 2026-05-06 |
| 16. Metadata management UI | v0.3 | 3/3 | Complete | 2026-05-06 |
| 17. Certificate inventory + staged rollover UI | v0.3 | 2/2 | Complete | 2026-05-06 |
| 18. Mapping editor + audit timeline hardening | v0.3 | 2/2 | Complete | 2026-05-06 |
| 19. IdP-initiated SSO | v0.4 | 3/3 | Complete | 2026-05-06 |
| 20. Bulk operations across connections | v0.5 | 2/2 | Complete | 2026-05-06 |
| 21. Scheduled metadata refresh | v0.5 | 7/7 | Complete | 2026-05-07 |
| 22. Certificate expiry alerts | v0.6 | 1/1 | Complete | 2026-05-07 |
| 23. Diagnostic bundles | v0.6 | 2/2 | Complete | 2026-05-07 |
| 24. Single Logout Protocol | v0.6 | 3/3 | Complete | 2026-05-07 |
| 25. Conformance and CVE Regression Fixtures | v1.0 | 3/3 | Complete | 2026-05-07 |
| 26. Security Audit Preparation and Remediation | v1.0 | 3/3 | Complete | 2026-05-08 |
| 27. Adopter Onboarding Polish and Case Studies | v1.0 | 3/3 | Complete | 2026-05-08 |
| 28. Real C14N parser foundation | v1.1 | 4/4 | Complete | 2026-05-24 |
| 29. Cryptographic XMLDSig verification | v1.1 | 5/5 | Complete | 2026-05-24 |
| 30. Adversarial crypto assurance | v1.1 | 4/4 | Complete | 2026-05-24 |
| 31. Disclosure and docs honesty | v1.1 | 2/2 | Complete | 2026-05-24 |
| 32. AlgorithmPolicy Extension + Schema Migrations | v1.3 | 2/2 | Complete   | 2026-05-25 |
| 33. KeyResolver Behaviour + XMLEnc Crypto Core | v1.3 | 2/2 | Complete   | 2026-05-25 |
| 34. ValidationPipeline Wiring + ENC-01 Complete | v1.3 | 2/4 | In Progress|  |
| 35. Signed AuthnRequests + ADFS Preset | v1.3 | 0/TBD | Not started | - |
| 36. Generic SAML Runbook | v1.3 | 0/TBD | Not started | - |
| 37. Identity Mapping and Provisioning Guide | v1.3 | 0/TBD | Not started | - |

---
