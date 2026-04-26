# Requirements: Relyra

**Defined:** 2026-04-25
**Core Value:** Every SAML login ends in a verified trust path or a typed rejection - never a silent compromise.

## v0.2 Requirements

Committed scope for the next milestone: enterprise configuration.

### Enterprise Configuration

- [ ] **CFG-01**: Ship Ecto schemas and migrations for connection/certificate/mapping/audit domain.
- [ ] **CFG-02**: Support metadata import/export and controlled metadata refresh.
- [ ] **CFG-03**: Support certificate rollover lifecycle with expiry signaling and staged trust.
- [ ] **CFG-04**: Persist attribute/group mapping configuration with auditability.

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

---
*Requirements defined: 2026-04-25*
