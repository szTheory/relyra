# Requirements: Relyra

**Defined:** 2026-04-24  
**Core Value:** Every SAML login ends in a verified trust path or a typed rejection - never a silent compromise.

## v0.1 Requirements

Committed scope for the first public Hex release ("SP-initiated SSO, verified end-to-end").

### Security Invariants

- [x] **SEC-01**: Relyra parses inbound SAML with a single hardened XML path that rejects DTDs, external entities, external fetches, and oversized payloads before any trust decision.
- [x] **SEC-02**: Relyra verifies XML signatures only against configured IdP certificates and never trusts document-provided `KeyInfo` as a trust source.
- [x] **SEC-03**: Relyra consumes only the exact signed node it verified and rejects signature-wrapping indicators (including ambiguous signed-node selection).
- [x] **SEC-04**: Relyra rejects duplicate XML IDs during response validation.
- [x] **SEC-05**: Relyra enforces algorithm policy with SHA-256+ defaults and rejects SHA-1 unless a time-boxed legacy policy with reason and expiry is explicitly configured.
- [ ] **SEC-06**: Relyra enforces replay protection with atomic consumption semantics and rejects replayed assertions/responses.
- [x] **SEC-07**: Relyra uses opaque, server-side RelayState handles and never redirects from raw RelayState URLs.
- [ ] **SEC-08**: Relyra emits redacted logs and never logs raw assertions/responses or unredacted sensitive attributes.
- [ ] **SEC-09**: Relyra ships a permanent adversarial fixture corpus (XXE, signature wrapping, parser differential, replay, SHA-1, unsigned assertion classes) in CI.

### Protocol Core

- [x] **PROT-01**: Relyra generates SP-initiated `AuthnRequest` payloads with stable IDs and required protocol fields.
- [x] **PROT-02**: Relyra accepts ACS POSTed SAML responses and returns either `{:ok, login_result}` or `{:error, %Relyra.Error{}}` with no silent success path.
- [x] **PROT-03**: Relyra validates issuer, audience, recipient, destination, status, and tenant/connection binding constraints before establishing session.
- [ ] **PROT-04**: Relyra enforces `InResponseTo` request intent for SP-initiated flows and rejects missing/mismatched request bindings.
- [x] **PROT-05**: Relyra validates time conditions (`NotBefore`, `NotOnOrAfter`, SubjectConfirmation windows) with bounded configurable skew.

### Extension Behaviours and Stores

- [ ] **EXT-01**: Relyra exposes five public behaviours: `ConnectionResolver`, `SessionAdapter`, `UserMapper`, `RequestStore`, and `ReplayStore`.
- [ ] **EXT-02**: Relyra provides `RequestStore.ETS` and `ReplayStore.ETS` for development with loud production warnings.
- [ ] **EXT-03**: Relyra provides Ecto-backed request/replay adapters for production usage behind optional dependency guards.
- [ ] **EXT-04**: Relyra supports multi-tenant connection resolution through `ConnectionResolver` without Phoenix/Ecto coupling in protocol core.
- [ ] **EXT-05**: Relyra's default adapters remain internal (`@moduledoc false`) while behaviour contracts remain stable public API.

### Phoenix Runtime and Developer Experience

- [ ] **PHX-01**: Relyra provides `saml_routes/2` for Phoenix routing with configurable resolver/session/error hooks.
- [ ] **PHX-02**: Relyra exposes metadata and login/ACS endpoints required for SP-initiated integration.
- [ ] **PHX-03**: Relyra provides typed error callback integration for host apps via `on_error`.
- [ ] **PHX-04**: Relyra ships `mix relyra.install` that generates minimal integration scaffolding without forcing Ecto migrations in v0.1.

### Observability and Contract Clarity

- [ ] **OBS-01**: Relyra publishes a single telemetry catalog for `[:relyra, :saml, ...]` events with documented measurements and metadata.
- [ ] **OBS-02**: Relyra ships a stable `%Relyra.Error{type, message, details}` contract with actionable error atoms suitable for alerting.
- [ ] **OBS-03**: Relyra provides provider recipes for Okta, Entra, and Google Workspace plus a Keycloak-based local integration path.
- [ ] **OBS-04**: Relyra enforces architecture boundaries (`boundary` compiler) and no-optional-deps compilation to prevent coupling regressions.
- [ ] **OBS-05**: Relyra ships OSS release discipline (Release Please, changelog, security policy, post-publish parity verification).

## Decision Gates (Must Be Resolved During Execution)

These are required decisions, not optional nice-to-haves:

- [x] **GATE-01**: Select XML security implementation strategy (pure BEAM vs NIF-over-xmlsec vs hybrid) and lock the seam contract.
- [x] **GATE-02**: Define canonicalization acceptance threshold (fixture corpus and correctness bar required before release).
- [x] **GATE-03**: If NIF path is selected, lock supported precompiled target matrix and checksum verification policy.
- [ ] **GATE-04**: Verify release-time external prerequisites (domain/namespace diligence and Keycloak image pin freshness).

## v0.2+ Deferred Requirements

Tracked now, not part of v0.1 delivery.

### Enterprise Configuration (v0.2)

- **CFG-01**: Ship Ecto schemas and migrations for connection/certificate/mapping/audit domain.
- **CFG-02**: Support metadata import/export and controlled metadata refresh.
- **CFG-03**: Support certificate rollover lifecycle with expiry signaling and staged trust.
- **CFG-04**: Persist attribute/group mapping configuration with auditability.

### Live Admin (v0.3)

- **ADM-01**: Ship optional mountable LiveView admin module for self-service SAML configuration.
- **ADM-02**: Provide guided test-connection flow with validation trace rendering.
- **ADM-03**: Provide unsafe-option risk visibility and audit-first controls in admin UX.

### Advanced Protocol and Conformance (v0.4+)

- **ADV-01**: Add IdP-initiated support as explicit opt-in, default disabled.
- **ADV-02**: Add SLO support as explicit opt-in with provider caveat matrix.
- **ADV-03**: Add external security review and formal conformance work for v1.0.
- **ADV-04**: Add migration tooling for Samly/ex_saml adopters.

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

Each v0.1 requirement maps to exactly one planned phase.

| Requirement | Phase | Status |
|-------------|-------|--------|
| SEC-01 | Phase 1 | Completed (01-01/01-02/01-03) |
| SEC-02 | Phase 2 | Completed (02-04/02-05 gap closure) |
| SEC-03 | Phase 2 | Completed (02-04/02-05 gap closure) |
| SEC-04 | Phase 2 | Completed (02-04/02-05 gap closure) |
| SEC-05 | Phase 2 | Completed (02-04/02-05 gap closure) |
| SEC-06 | Phase 3 | Pending |
| SEC-07 | Phase 2 | Completed (02-01) |
| SEC-08 | Phase 5 | Pending |
| SEC-09 | Phase 6 | Pending |
| PROT-01 | Phase 2 | Completed (02-01) |
| PROT-02 | Phase 2 | Completed (02-04/02-05 gap closure) |
| PROT-03 | Phase 2 | Completed (02-04/02-05 gap closure) |
| PROT-04 | Phase 3 | Pending |
| PROT-05 | Phase 2 | Completed (02-04/02-05 gap closure) |
| EXT-01 | Phase 3 | Pending |
| EXT-02 | Phase 3 | Pending |
| EXT-03 | Phase 3 | Pending |
| EXT-04 | Phase 3 | Pending |
| EXT-05 | Phase 3 | Pending |
| PHX-01 | Phase 4 | Pending |
| PHX-02 | Phase 4 | Pending |
| PHX-03 | Phase 4 | Pending |
| PHX-04 | Phase 6 | Pending |
| OBS-01 | Phase 5 | Pending |
| OBS-02 | Phase 5 | Pending |
| OBS-03 | Phase 6 | Pending |
| OBS-04 | Phase 5 | Pending |
| OBS-05 | Phase 6 | Pending |
| GATE-01 | Phase 1 | Completed (01-ADR) |
| GATE-02 | Phase 1 | Completed (01-03) |
| GATE-03 | Phase 1 | Completed (01-ADR policy lock) |
| GATE-04 | Phase 6 | Pending |

**Coverage:**
- v0.1 requirements: 28 total
- Decision gates: 4 total
- Mapped to phases: 32
- Unmapped: 0

---
*Requirements defined: 2026-04-24*  
*Last updated: 2026-04-24 after research synthesis completion*

