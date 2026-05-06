# Requirements: Relyra v0.3

**Defined:** 2026-05-06
**Milestone:** v0.3 — LiveView admin
**Core Value:** Every SAML login ends in a verified trust path or a typed rejection — never a silent compromise.

## v0.3 Requirements

Committed scope for v0.3: an optional LiveView admin surface that exposes the v0.2 trust-data capabilities without weakening the existing trust boundary.

### Admin Foundation

- [ ] **ADM-01**: Adopter can mount the optional Relyra LiveView admin surface with one router integration point while keeping authentication and authorization in the host app.
- [ ] **ADM-02**: Operator can create a new SAML connection from a provider preset or blank form and move it through draft, enabled, and disabled lifecycle states.

### Metadata Management

- [ ] **MDUI-01**: Operator can import metadata for a connection by pasting XML or registering a metadata URL.
- [ ] **MDUI-02**: Operator can review metadata import history, see the current last-known-good state, and trigger a manual refresh without implicit trust promotion.

### Certificate Operations

- [ ] **CERT-01**: Operator can view a connection's certificate inventory as active, next, and retired entries with expiry facts and staged-rollover context.
- [ ] **CERT-02**: Operator can promote the next signing certificate or retire the active one and receives typed conflict-safe feedback when the underlying trust state changed first.

### Mapping And Audit

- [ ] **MAP-01**: Operator can edit attribute and group mapping rules for a connection and review prior mapping revisions.
- [ ] **AUD-01**: Operator can browse the audit ledger with connection, actor, and event-type filters and see only redaction-safe event details.

### Risk Visibility

- [ ] **RISK-01**: Operator can see clear risk panels whenever a connection uses `legacy_algorithm_policy` or similar compatibility overrides that weaken strict defaults.
- [ ] **SAFE-01**: Operator never gets a partial admin-side trust mutation when the corresponding audit write fails; the action returns a typed failure instead.

## Deferred To Later Milestones

### Adoption And Operations

- **CFG-07**: User can run bulk operations across multiple connections. Deferred to v0.5 operational maturity.
- **CFG-08**: User can enable scheduled metadata refresh automation with guardrails. Deferred to v0.5 operational maturity.

### Protocol Surface

- **IDP-INIT-01**: User can initiate login from the IdP and rely on opaque RelayState handling. Deferred to v0.4.
- **SLO-01**: User can complete standards-compliant Single Logout flows. Deferred to v0.6.

## Out Of Scope

| Feature | Reason |
|---------|--------|
| Login UI or branded sign-in experience | Host-app territory; Relyra remains a library, not the app's user-facing auth product. |
| Hosted admin service or broker runtime | Customer data and trust control stay inside the host application. |
| Bulk operations across many connections | Explicitly deferred to v0.5 so v0.3 stays focused on single-connection self-service. |
| Scheduled metadata refresh automation | Explicitly deferred to v0.5 until the manual refresh UX ships and proves the operator flow. |
| IdP-initiated SSO | Explicitly deferred to v0.4 per the active milestone arc. |
| Single Logout | Explicitly deferred to v0.6 per the active milestone arc. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| ADM-01 | Phase 15 | Pending |
| ADM-02 | Phase 15 | Pending |
| MDUI-01 | Phase 16 | Pending |
| MDUI-02 | Phase 16 | Pending |
| CERT-01 | Phase 17 | Pending |
| CERT-02 | Phase 17 | Pending |
| MAP-01 | Phase 18 | Pending |
| AUD-01 | Phase 18 | Pending |
| RISK-01 | Phase 15 | Pending |
| SAFE-01 | Phase 18 | Pending |

**Coverage:**
- v0.3 requirements: 10 total
- Mapped to phases: 10
- Unmapped: 0

---
*Requirements defined: 2026-05-06*
*Last updated: 2026-05-06 after roadmap creation for v0.3*
