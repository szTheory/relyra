# Roadmap: Relyra

## Milestones

- ✅ **v0.1 — SP-initiated SSO, verified end-to-end** (shipped 2026-04-25). See `.planning/milestones/v0.1-ROADMAP.md`.
- ✅ **v0.2 — Enterprise configuration** (shipped 2026-05-06). See `.planning/milestones/v0.2-ROADMAP.md`.
- ✅ **v0.3 — LiveView admin** (shipped 2026-05-06). See `.planning/milestones/v0.3-ROADMAP.md`.
- 📋 **v0.4 — IdP-initiated SSO** (planning ready 2026-05-06).

## Phases

<details>
<summary>✅ v0.1 — SP-initiated SSO (Phases 1-6) — SHIPPED 2026-04-25</summary>

See `.planning/milestones/v0.1-ROADMAP.md`.

</details>

<details>
<summary>✅ v0.2 — Enterprise configuration (Phases 7-14) — SHIPPED 2026-05-06</summary>

- [x] Phase 07: Schema + connection aggregate (3/3 plans) — verified 2026-05-05 — CFG-01
- [x] Phase 08: Resolver adapter + snapshotting (3/3 plans) — verified 2026-05-05 — CFG-02
- [x] Phase 09: Metadata import/export + refresh (4/4 plans) — verified via Phase 12 (2026-05-06) — CFG-03
- [x] Phase 10: Certificate inventory + rollover (3/3 plans) — verified via Phase 13 (2026-05-06) — CFG-04
- [x] Phase 11: Mapping persistence + audit hardening (4/4 plans) — verified via Phase 14 (2026-05-06) — CFG-05
- [x] Phase 12: Metadata refresh trust-state repair (3/3 plans, closure) — produced 09-VERIFICATION.md — 2026-05-06
- [x] Phase 13: Certificate rollover validation + verification (3/3 plans, closure) — produced 10-VERIFICATION.md — 2026-05-06
- [x] Phase 14: Mapping/audit milestone verification (2/2 plans, closure) — produced 11-VERIFICATION.md — 2026-05-06

See `.planning/milestones/v0.2-ROADMAP.md` for full phase details, decisions, deferred items, and tech debt.

</details>

<details>
<summary>✅ v0.3 — LiveView admin (Phases 15-18) — SHIPPED 2026-05-06</summary>

- [x] Phase 15: Admin shell + connection lifecycle (3/3 plans) — verified 2026-05-06
- [x] Phase 16: Metadata management UI (3/3 plans) — verified 2026-05-06
- [x] Phase 17: Certificate inventory + staged rollover UI (2/2 plans) — verified 2026-05-06
- [x] Phase 18: Mapping editor + audit timeline hardening (2/2 plans) — verified 2026-05-06

See `.planning/milestones/v0.3-ROADMAP.md` for full phase details, decisions, deferred items, and tech debt.

</details>

### 📋 v0.4 — IdP-initiated SSO (Planning)

- [x] **Phase 19: IdP-initiated SSO** - Implement unsolicited assertion support with security guardrails and opaque RelayState handling. Verified 2026-05-06.

## Phase Details

### Phase 19: IdP-initiated SSO
**Goal**: Adopters can accept SAML logins initiated from the IdP dashboard without compromising security or losing RelayState context.
**Depends on**: Phase 18
**Requirements**: IDP-INIT-01
**Success Criteria** (what must be TRUE):
1. Connection can explicitly opt-in to IdP-initiated flows via `allow_idp_initiated` flag.
2. Validation pipeline correctly handles responses missing `InResponseTo` only when allowed.
3. System extracts and surfaces RelayState to the host application in a normalized `LoginResult` struct.
4. XML parser handles optional `InResponseTo` attribute.
**Plans**: 3 plans
- [x] 19-01-PLAN.md — Data model update
- [x] 19-02-PLAN.md — Safe redirect utility
- [x] 19-03-PLAN.md — ACS pipeline update
**UI hint**: no

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
| 09. Metadata import/export + refresh | v0.2 | 4/4 | Complete (closure 12) | 2026-05-06 |
| 10. Certificate inventory + rollover | v0.2 | 3/3 | Complete (closure 13) | 2026-05-06 |
| 11. Mapping persistence + audit hardening | v0.2 | 4/4 | Complete (closure 14) | 2026-05-06 |
| 12. Metadata refresh trust-state repair | v0.2 | 3/3 | Complete (closure phase) | 2026-05-06 |
| 13. Certificate rollover validation + verification | v0.2 | 3/3 | Complete (closure phase) | 2026-05-06 |
| 14. Mapping/audit milestone verification | v0.2 | 2/2 | Complete (closure phase) | 2026-05-06 |
| 15. Admin shell + connection lifecycle | v0.3 | 3/3 | Complete | 2026-05-06 |
| 16. Metadata management UI | v0.3 | 3/3 | Complete | 2026-05-06 |
| 17. Certificate inventory + staged rollover UI | v0.3 | 2/2 | Complete | 2026-05-06 |
| 18. Mapping editor + audit timeline hardening | v0.3 | 2/2 | Complete | 2026-05-06 |