# Roadmap: Relyra

## Milestones

- ✅ **v0.1 — SP-initiated SSO, verified end-to-end** (shipped 2026-04-25). See `.planning/milestones/v0.1-ROADMAP.md`.
- ✅ **v0.2 — Enterprise configuration** (shipped 2026-05-06). See `.planning/milestones/v0.2-ROADMAP.md`.
- ✅ **v0.3 — LiveView admin** (shipped 2026-05-06). See `.planning/milestones/v0.3-ROADMAP.md`.
- ✅ **v0.4 — IdP-initiated SSO** (shipped 2026-05-06). See `.planning/milestones/v0.4-ROADMAP.md`.
- ✅ **v0.5 — Operational maturity** (shipped 2026-05-07). See `.planning/milestones/v0.5-ROADMAP.md`.
- ✅ **v0.6 — Operational maturity carryover + SLO** (shipped 2026-05-08). See `.planning/milestones/v0.6-ROADMAP.md`.
- 📋 **v1.0 — External security review + conformance + docs polish** (planning started 2026-05-08).

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

<details open>
<summary>📋 v1.0 — External security review + conformance + docs polish (Phases 25-27) — ACTIVE</summary>

- [x] **Phase 25: Conformance and CVE Regression Fixtures** - Ensure protocol behavior strictly adheres to SAML conformance profiles and is immune to historical vulnerabilities.
- [ ] **Phase 26: Security Audit Preparation and Remediation** - Ready the codebase and documentation for a third-party security review and address findings.
- [ ] **Phase 27: Adopter Onboarding Polish and Case Studies** - Deliver a frictionless Day-1 experience for adopters through refined documentation and real-world examples.

## Phase Details

### Phase 25: Conformance and CVE Regression Fixtures
**Goal**: Ensure protocol behavior strictly adheres to SAML conformance profiles and is immune to historical vulnerabilities.
**Depends on**: Phase 24
**Requirements**: CONF-01, CVE-REG-01
**Success Criteria** (what must be TRUE):
  1. Kantara/Liberty conformance tests for the SP role execute and pass.
  2. Regression test suite includes fixtures for known historical SAML CVEs (e.g., XML Signature Wrapping, XXE, ruby-saml CVE-2024-45409).
  3. Conformance status and regression coverage are documented.
**Plans**: 3 plans

Plans:
- [x] 25-01-PLAN.md — Replace PureBeam placeholder seam behavior with deterministic signed-node and canonicalization semantics, then add the shared manifest-loader contract for Phase 25 corpora
- [x] 25-02-PLAN.md — Build the executable SP conformance manifest/lane and extend the pinned security corpus with XSW, XXE, and CVE-2024-45409 regressions
- [x] 25-03-PLAN.md — Generate `CONFORMANCE.md` from manifest state and wire the conformance lane plus drift check into Mix CI aliases

### Phase 26: Security Audit Preparation and Remediation
**Goal**: Ready the codebase and documentation for a third-party security review and address findings.
**Depends on**: Phase 25
**Requirements**: SEC-REVIEW-01
**Success Criteria** (what must be TRUE):
  1. Architecture and security boundary documentation is finalized for auditors.
  2. Any identified high-severity findings are remediated and verified.
  3. System strict-defaults and bypass auditing are validated by external review.
**Plans**: TBD

### Phase 27: Adopter Onboarding Polish and Case Studies
**Goal**: Deliver a frictionless Day-1 experience for adopters through refined documentation and real-world examples.
**Depends on**: Phase 26
**Requirements**: DOCS-01
**Success Criteria** (what must be TRUE):
  1. Getting Started guide and provider-specific runbooks are complete and verified.
  2. Adopter case studies are documented, showing real-world configuration examples.
  3. "Batteries included" promise is demonstrably achieved in the documentation.
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
| 26. Security Audit Preparation and Remediation | v1.0 | 0/3 | Not started | - |
| 27. Adopter Onboarding Polish and Case Studies | v1.0 | 0/3 | Not started | - |
