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
- ✅ **v1.3 — Advanced Federation** (shipped 2026-05-27). See `.planning/milestones/v1.3-ROADMAP.md`.
- 🚧 **v1.4 — Full SLO + Ops Polish** (current). See `.planning/milestones/v1.4-ROADMAP.md`.

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

<details>
<summary>✅ v1.3 — Advanced Federation (Phases 32-37) — SHIPPED 2026-05-27</summary>

- [x] **Phase 32: AlgorithmPolicy Extension + Schema Migrations** — Extend AlgorithmPolicy with key-transport and content-encryption algorithm fields; add cert `party`/`use` columns and connection `sign_authn_requests` field via safe additive migrations. (completed 2026-05-25)
  **Plans:** 2 plans

  - [x] 32-01-PLAN.md — AlgorithmPolicy struct extension + enforce_key_transport_algorithm/2 + enforce_content_encryption_algorithm/3 (ENC-03)
  - [x] 32-02-PLAN.md — Cert party/use migration + Connection sign_authn_requests migration + Ecto schema fields (ENC-04, AUTHN-02)
- [x] **Phase 33: KeyResolver Behaviour + XMLEnc Crypto Core** — Introduce the `KeyResolver` behaviour and `KeyResolver.Default` PEM-from-config implementation; build `Relyra.Security.XMLEnc` with RSA-OAEP + AES-GCM decryption behind the AlgorithmPolicy gate. (completed 2026-05-25)
  **Plans:** 2 plans

  - [x] 33-01-PLAN.md — KeyResolver behaviour + dispatch function + KeyResolver.Default PEM-from-config + key_resolver_test.exs (ENC-04)
  - [x] 33-02-PLAN.md — XMLEnc.decrypt/3 RSA-OAEP + AES-GCM + 4-case security corpus + ci.security registration (ENC-04)
- [x] **Phase 34: ValidationPipeline Wiring + ENC-01 Complete** — Wire the decrypt-then-reparse step into `ValidationPipeline`; add ambiguity guard; publish SP encryption `KeyDescriptor`; add the 7-fixture ENC-01 adversarial corpus to `mix ci.security`. (completed 2026-05-25)
- [x] **Phase 35: Signed AuthnRequests + ADFS Preset** — Implement redirect-binding query signing; add `sign_authn_requests` connection toggle; publish signing metadata fields; ship ADFS preset and runbook; add 5-fixture AUTHN-01 adversarial corpus. (completed 2026-05-26)
- [x] **Phase 36: Generic SAML Runbook** — Publish `guides/recipes/generic_saml.md` covering SP/IdP metadata fields, decoder tables for non-preset IdPs, minimum-safe checklist, debugging flow, and certificate rotation. (completed 2026-05-26)
- [x] **Phase 37: Identity Mapping and Provisioning Guide** — Publish `guides/identity_mapping_and_provisioning.md` covering three mapping patterns, JIT decision tree, `UserMapper` behaviour documentation, and SCIM non-goal statement. (completed 2026-05-26)

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
- [x] 34-03-PLAN.md — ENC-01: :decrypt_assertion pre-stage in ValidationPipeline.do_run/4 (decrypt → reparse → verify; ambiguity guard) (Wave 1)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 34-04-PLAN.md — ENC-01: 7-fixture pipeline-level adversarial corpus + mix ci.security wiring (Wave 2, depends on 34-02 + 34-03)

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
  5. The ADFS provider preset defaults to `sign_authn_requests: true`; `guides/recipes/adfs.md` covers claim rules, PowerShell `Set-ADFSRelyingPartyTrust` commands, SHA-1 vs SHA-256 redirect binding interop notes, and the `WantAuthnRequestsSigned` flag.

**Plans**: 9 plans
Plans:
**Wave 0**

- [x] 35-01-PLAN.md — outbound signing digest gate + `Signature.sign_redirect_query/3` + deterministic signing PEM

**Wave 1**

- [x] 35-02-PLAN.md — raw-DEFLATE redirect binding + signed query assembly + ADFS lowercase encoding
- [x] 35-03-PLAN.md — persisted `signed_request_encoding` schema/runtime field + migration
- [x] 35-04-PLAN.md — `:adfs` provider preset registration + defaults

**Wave 2**

- [x] 35-05-PLAN.md — `start_login/3` signed redirect flow + controller verbatim append + `idp_sso_url` collision guard
- [x] 35-06-PLAN.md — metadata gating for `AuthnRequestsSigned` and signing `KeyDescriptor`

**Wave 3**

- [x] 35-07-PLAN.md — AUTHN-01 golden corpus + committed redirect fixtures + provenance
- [x] 35-08-PLAN.md — `mix ci.security` wiring + meta-gate registration
- [x] 35-09-PLAN.md — ADFS operator runbook + `ci.docs` presence guard

### Phase 36: Generic SAML Runbook

**Goal**: An operator integrating a non-preset IdP (IBM Security Verify, CyberArk, Oracle Access Manager, PingFederate, CA SiteMinder, ADFS custom, or Shibboleth) has one authoritative runbook that gets them through setup without reading the SAML spec.
**Depends on**: Nothing (pure documentation; no code dependency; can run in parallel with any phase after Phase 32).
**Requirements**: DOCS-02
**Success Criteria** (what must be TRUE):

  1. `guides/recipes/generic_saml.md` is published and covers: SP metadata field reference with plain-English descriptions, IdP metadata import checklist, attribute/claim decoder tables for IBM Security Verify, CyberArk, Oracle Access Manager, PingFederate, and CA SiteMinder.
  2. The guide includes ADFS-specific and Shibboleth-specific subsections, a NameID format decision guide, and sections on when to enable signing and encryption.
  3. A minimum-safe security settings checklist, a step-by-step debugging flow, and a certificate rotation procedure are included, written at the operator level (no SAML spec knowledge assumed).

**Plans**: 2 plans
Plans:

**Wave 1**

- [x] 36-01-PLAN.md — canonical generic/custom-SAML routing + core runbook skeleton

**Wave 2**

- [x] 36-02-PLAN.md — vendor decoder tables + operator-safety spine + ci.docs gate

### Phase 37: Identity Mapping and Provisioning Guide

**Goal**: An operator implementing JIT provisioning or attribute-to-user mapping has one authoritative guide covering the three canonical patterns and an explicit decision tree — and knows exactly where Relyra's responsibility ends and their application's begins.
**Depends on**: Nothing (pure documentation; no code dependency; can run in parallel with any phase).
**Requirements**: DOCS-03
**Success Criteria** (what must be TRUE):

  1. `guides/identity_mapping_and_provisioning.md` is published and covers all three mapping patterns: NameID-as-local-identifier, attribute-as-local-identifier, and JIT create-or-update.
  2. A JIT decision tree helps operators choose between patterns based on their identity model; the `UserMapper` behaviour is fully documented with at least one complete implementation example per pattern.
  3. The guide explicitly states the SCIM lifecycle non-goal, warns about JIT+SCIM simultaneous-use conflicts, and explains anchor stability guidance (what breaks when NameID format changes between logins).

**Plans**: 2 plans
Plans:

**Wave 1**

- [x] 37-01-PLAN.md — core identity mapping guide + `UserMapper` seam wording

**Wave 2**

- [x] 37-02-PLAN.md — docs publication, routing, and docs CI gate

</details>

<details open>
<summary>🚧 v1.4 — Full SLO + Ops Polish (Phases 38-40.1) — CURRENT</summary>

- [x] **Phase 38: Single Logout (SLO) Core & Security** — SP and IdP initiated logout flows, strict signature verification, replay protection, and `SessionAdapter` extensibility for indexing. (completed 2026-05-27 — 4/4 plans done; VERIFICATION.md deferred to Phase 40.1)
- [x] **Phase 39: Logout Strategy & Operational Guidance** — Explicit operator documentation (`guides/recipes/logout.md`) detailing SLO enablement, 3rd-party cookie caveats, and absolute timeouts. (completed 2026-05-27 — VERIFICATION.md deferred to Phase 40.1)
- [x] **Phase 40: Operational Polish & Error Taxonomy** — Error Atom Decoder, automated drift-check, and comprehensive Incident Response Playbook (`guides/operations/incident_playbook.md`). (completed 2026-05-27)
- [ ] **Phase 40.1: Close v1.4 milestone audit gaps (INSERTED)** — Fix `logout.md` SessionAdapter signature drift, resolve `index_session/4` policy, generate 38/39 VERIFICATIONs retroactively, fix 38-04 SUMMARY name drift.

### Phase 38: Single Logout (SLO) Core & Security

**Goal**: Users and Identity Providers can securely terminate sessions across the federation via verified SAML Single Logout flows.
**Depends on**: Phase 37
**Requirements**: SLO-01
**Success Criteria** (what must be TRUE):

  1. `Relyra.SessionAdapter` is successfully extended with `index_session/4` and `terminate_by_session_index/4` to decouple Relyra from the host app's session implementation.
  2. SP-initiated and IdP-initiated logout flows reliably parse, generate, and process `LogoutRequest` and `LogoutResponse` for HTTP-Redirect and HTTP-POST bindings.
  3. All logout messages enforce strict XMLDSig signature verification before any session is terminated.
  4. Strict replay protection prevents the re-use of previously submitted logout messages.

**Plans**: 4 plans
Plans:

**Wave 1**

- [x] 38-01-PLAN.md — SessionAdapter contracts & HTTP-Redirect signature verification

**Wave 2**

- [x] 38-02-PLAN.md — LogoutRequest and LogoutResponse protocol models

**Wave 3**

- [ ] 38-03-PLAN.md — Strict Logout Validation Pipeline

**Wave 4**

- [ ] 38-04-PLAN.md — Relyra facade integration and end-to-end security tests

### Phase 39: Logout Strategy & Operational Guidance

**Goal**: Operators understand when to deploy SLO and how to mitigate browser-level cookie constraints.
**Depends on**: Phase 38
**Requirements**: DOCS-04
**Success Criteria** (what must be TRUE):

  1. `guides/recipes/logout.md` is published and details explicit guidance on SLO tradeoffs and modern 3rd-party cookie blocking (Safari ITP, Firefox ETP, Chrome Privacy Sandbox).
  2. The guide provides concrete strategies for configuring host-application absolute-timeout fallbacks when SLO silently fails over the front channel.

**Plans**: 1 plan
Plans:

**Wave 1**

- [x] 39-01-PLAN.md — SLO strategy, ITP/ETP caveats, and operational fallbacks

### Phase 40: Operational Polish & Error Taxonomy

**Goal**: Operators can instantly decode cryptic SAML failures and have a clear playbook for incident response.
**Depends on**: Phase 39
**Requirements**: DOCS-05, DOCS-06
**Success Criteria** (what must be TRUE):

  1. `guides/troubleshooting.md` is published, acting as an Error Atom Decoder.
  2. An automated drift-check test enforces that every `:error_type` in `Relyra.Error` has a corresponding documented entry in the troubleshooting guide.
  3. `guides/operations/incident_playbook.md` is published, outlining end-to-end response workflows that stitch together Relyra telemetry, audit trails, the LiveView admin UI, and Mix tasks.

**Plans**: 2 plans
Plans:

**Wave 1**

- [x] 40-01-PLAN.md — DOCS-06: Error Atom Decoder (guides/troubleshooting.md) + bidirectional drift-check test + ci.docs wiring

**Wave 2** *(depends on 40-01 for mix.exs anchor)*

- [x] 40-02-PLAN.md — DOCS-05: Incident Response Playbook (guides/operations/incident_playbook.md) + ci.docs presence guard

**UI hint**: yes

### Phase 40.1: Close v1.4 milestone audit gaps (INSERTED)

**Goal:** Close the four findings raised by the v1.4 milestone audit (`.planning/v1.4-MILESTONE-AUDIT.md`): (1) rewrite `guides/recipes/logout.md:107,121` SessionAdapter code example to match the actual 4-arg callback signature; (2) resolve `SessionAdapter.index_session/4` policy — either wire `consume_response/3` to call it, or document host-owned linkage; (3) fix `38-04-SUMMARY.md` `consume_logout_response/3` → `consume_logout/3` nomenclature drift; (4) generate `38-VERIFICATION.md` and `39-VERIFICATION.md` retroactively.
**Depends on:** Phase 40
**Requirements:** SLO-01 (re-verify), DOCS-04 (re-verify)
**Plans:** 5 plans

Plans:

**Wave 1** *(four parallel plans — all touch only `.planning/`, `test/docs/`, `mix.exs`)*

- [ ] 40.1-01-PLAN.md — Retroactive `38-VERIFICATION.md` from existing Phase 38 evidence (D-07/D-08/D-09/D-10; SLO-01 re-verify)
- [ ] 40.1-02-PLAN.md — Retroactive `39-VERIFICATION.md` from existing Phase 39 evidence (D-07/D-08/D-09/D-10; DOCS-04 re-verify)
- [ ] 40.1-03-PLAN.md — New `test/docs/logout_recipe_drift_test.exs` skip-tagged + `mix.exs` `ci.docs` wiring (D-05/D-06)
- [ ] 40.1-04-PLAN.md — Cosmetic `38-04-SUMMARY.md:4` `consume_logout_response/3` → `consume_logout/3` typo fix (D-11)

**Wave 2** *(depends on 40.1-03 — flips drift gate live in same commit as doc rewrite)*

- [ ] 40.1-05-PLAN.md — `guides/recipes/logout.md` rewrite (D-02/D-03/D-04 — canonical SessionAdapter signatures, host-linkage subsection) + unskip drift test from Plan 03

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
| 34. ValidationPipeline Wiring + ENC-01 Complete | v1.3 | 4/4 | Complete    | 2026-05-25 |
| 35. Signed AuthnRequests + ADFS Preset | v1.3 | 9/9 | Complete | 2026-05-26 |
| 36. Generic SAML Runbook | v1.3 | 2/2 | Complete    | 2026-05-26 |
| 37. Identity Mapping and Provisioning Guide | v1.3 | 2/2 | Complete    | 2026-05-26 |
| 38. Single Logout (SLO) Core & Security | v1.4 | 4/4 | Complete (verification deferred) | 2026-05-27 |
| 39. Logout Strategy & Operational Guidance | v1.4 | 1/1 | Complete (verification deferred) | 2026-05-27 |
| 40. Operational Polish & Error Taxonomy | v1.4 | 2/2 | Complete    | 2026-05-27 |
| 40.1. Close v1.4 audit gaps (INSERTED) | v1.4 | 0/5 | Planned |  |

---
