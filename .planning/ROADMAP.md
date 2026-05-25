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
  - [ ] 32-01-PLAN.md — AlgorithmPolicy struct extension + enforce_key_transport_algorithm/2 + enforce_content_encryption_algorithm/3 (ENC-03)
  - [ ] 32-02-PLAN.md — Cert party/use migration + Connection sign_authn_requests migration + Ecto schema fields (ENC-04, AUTHN-02)
- [ ] **Phase 33: KeyResolver Behaviour + XMLEnc Crypto Core** — Introduce the `KeyResolver` behaviour and `KeyResolver.Default` PEM-from-config implementation; build `Relyra.Security.XMLEnc` with RSA-OAEP + AES-GCM decryption behind the AlgorithmPolicy gate.
- [ ] **Phase 34: ValidationPipeline Wiring + ENC-01 Complete** — Wire the decrypt-then-reparse step into `ValidationPipeline`; add ambiguity guard; publish SP encryption `KeyDescriptor`; add the 7-fixture ENC-01 adversarial corpus to `mix ci.security`.
- [ ] **Phase 35: Signed AuthnRequests + ADFS Preset** — Implement redirect-binding query signing; add `sign_authn_requests` connection toggle; publish signing metadata fields; ship ADFS preset and runbook; add 5-fixture AUTHN-01 adversarial corpus.
- [ ] **Phase 36: Generic SAML Runbook** — Publish `guides/recipes/generic_saml.md` covering SP/IdP metadata fields, decoder tables for non-preset IdPs, minimum-safe checklist, debugging flow, and certificate rotation.
- [ ] **Phase 37: Identity Mapping and Provisioning Guide** — Publish `guides/identity_mapping_and_provisioning.md` covering three mapping patterns, JIT decision tree, `UserMapper` behaviour documentation, and SCIM non-goal statement.

See `.planning/milestones/v1.3-ROADMAP.md` for full phase details.

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
| 32. AlgorithmPolicy Extension + Schema Migrations | v1.3 | 0/2 | Not started | - |
| 33. KeyResolver Behaviour + XMLEnc Crypto Core | v1.3 | 0/TBD | Not started | - |
| 34. ValidationPipeline Wiring + ENC-01 Complete | v1.3 | 0/TBD | Not started | - |
| 35. Signed AuthnRequests + ADFS Preset | v1.3 | 0/TBD | Not started | - |
| 36. Generic SAML Runbook | v1.3 | 0/TBD | Not started | - |
| 37. Identity Mapping and Provisioning Guide | v1.3 | 0/TBD | Not started | - |

---
