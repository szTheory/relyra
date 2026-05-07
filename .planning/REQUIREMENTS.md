# Requirements: Relyra v0.4

**Defined:** 2026-05-06
**Milestone:** v0.4 — IdP-initiated SSO
**Core Value:** Every SAML login ends in a verified trust path or a typed rejection — never a silent compromise.

## v0.4 Requirements

Committed scope for v0.4: IdP-initiated SSO and opaque RelayState handling, allowing adopters to serve environments requiring enterprise IdP dashboards and legacy workforce SAML flows.

### Protocol Surface

- [ ] **IDP-INIT-01**: User can initiate login from the IdP and rely on opaque RelayState handling.

## Deferred To Later Milestones

### Adoption And Operations (v0.5)

- **CFG-07**: User can run bulk operations across multiple connections. Deferred to v0.5 operational maturity.
- [x] **CFG-08**: User can enable scheduled metadata refresh automation with guardrails. **Complete** — Phase 21 shipped 2026-05-07.

### Protocol Surface (v0.6)

- **SLO-01**: User can complete standards-compliant Single Logout flows. Deferred to v0.6.

## Out Of Scope

| Feature | Reason |
|---------|--------|
| Login UI or branded sign-in experience | Host-app territory; Relyra remains a library, not the app's user-facing auth product. |
| Hosted admin service or broker runtime | Customer data and trust control stay inside the host application. |
| Bulk operations across many connections | Explicitly deferred to v0.5. |
| Scheduled metadata refresh automation | Explicitly deferred to v0.5. |
| Single Logout | Explicitly deferred to v0.6 per the active milestone arc. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| IDP-INIT-01 | Phase 19 | Complete |
| CFG-07 | Phase 20 | Complete |
| CFG-08 | Phase 21 | Complete (Phase 21 shipped 2026-05-07: schema + pure helpers + trust-boundary helpers + audit seam + telemetry + scheduler + wrapper + worker + live-admin-surface + mix-tasks-telemetry-docs) |

**Coverage:**
- v0.4 requirements: 1 total
- Mapped to phases: 1
- Unmapped: 0

---
*Requirements defined: 2026-05-06*
*Last updated: 2026-05-06 after milestone v0.4 completion*
