# Requirements: Relyra

**Defined:** 2026-04-26
**Core Value:** Every SAML login ends in a verified trust path or a typed rejection - never a silent compromise.

## v0.2 Requirements

Committed scope for the next milestone: enterprise configuration.

### Enterprise Configuration

- [ ] **CFG-01**: User can create and maintain tenant-scoped SAML connection records backed by Ecto schemas and migrations.
- [ ] **CFG-02**: Relyra can resolve a persisted connection into a runtime snapshot for login and metadata flows.
- [ ] **CFG-03**: User can import and export metadata for a connection and trigger a controlled refresh with provenance.
- [ ] **CFG-04**: User can manage certificate inventory for a connection with expiry tracking and staged rollover.
- [ ] **CFG-05**: User can persist attribute/group mapping configuration and review a durable audit history of trust changes.

## v1 Requirements

Deferred to the next milestone cycle or later.

### Admin Surface

- **CFG-06**: User can manage enterprise configuration through an optional LiveView admin surface.
- **CFG-07**: User can run bulk operations across multiple connections.

### Automation

- **CFG-08**: User can enable scheduled metadata refresh automation with guardrails.

## Out of Scope

Explicit exclusions to prevent scope creep and trust-surface drift.

| Feature | Reason |
|---------|--------|
| Hosted SSO broker/SaaS runtime | Relyra is a library; customer data and control stay in host applications. |
| OIDC/OAuth in-core | Relyra is SAML-specific; OIDC/OAuth belongs to adjacent libraries. |
| Generic auth framework (passwords/MFA/session system) | Session establishment is delegated via `SessionAdapter`; host app owns auth domain. |
| Production IdP implementation | `Relyra.TestSupport.FakeIdP` is dev/CI support only, not a product IdP. |
| SCIM lifecycle ownership | Relyra focuses on login-time identity assertion and mapping, not full lifecycle provisioning. |
| Security-by-marketing claims (bulletproof/unhackable/military-grade) | Brand and security discipline require precise, falsifiable claims only. |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| CFG-01 | Phase 07 | Pending |
| CFG-02 | Phase 08 | Pending |
| CFG-03 | Phase 09 | Pending |
| CFG-04 | Phase 10 | Pending |
| CFG-05 | Phase 11 | Pending |

**Coverage:**
- v1 requirements: 5 total
- Mapped to phases: 5
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-26*
*Last updated: 2026-04-26 after v0.2 milestone start*
