# Roadmap: Relyra

## Overview

Relyra v0.1 ships as a strict-by-default SAML SP library for Phoenix teams, starting with a locked XML security architecture decision and then layering protocol correctness, extension seams, runtime integration, and operator-grade observability/docs so enterprise SSO can be deployed safely without custom forked glue.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

- [ ] **Phase 1: XML Security ADR and Guardrails** - Lock parser/signature architecture and non-negotiable trust invariants.
- [ ] **Phase 2: Protocol and Signature Core** - Implement SP-initiated flow with strict verification and protocol validation.
- [ ] **Phase 3: Behaviour Contracts and Stores** - Ship extension behaviours and production-safe request/replay adapter defaults.
- [ ] **Phase 4: Phoenix Runtime Integration** - Expose router macro, ACS/login endpoints, and typed runtime error flow.
- [ ] **Phase 5: Observability and Enforcement** - Add telemetry catalog, redacted logging, and compile-time safety checks.
- [ ] **Phase 6: Delivery Hardening and Adoption Surface** - Finalize provider guides, installer, TestSupport, CI/release discipline, and docs.

## Phase Details

### Phase 1: XML Security ADR and Guardrails
**Goal**: Decide and lock the XML security implementation strategy with an explicit seam and acceptance bar before protocol code lands.
**Decision Record**: .planning/phases/01-xml-security-adr-and-guardrails/01-ADR.md
**Policy Lock**: GATE-03 matrix + checksum policy is defined in ADR 0001 and required before any NIF/hybrid release path.
**Depends on**: Nothing (first phase)
**Requirements**: [SEC-01, GATE-01, GATE-02, GATE-03]
**Success Criteria** (what must be TRUE):
  1. XML strategy decision is documented as an ADR with clear rationale and tradeoffs.
  2. `Relyra.Security.XML` seam contract is frozen for downstream phases.
  3. Baseline hardened parse path and adversarial seed fixtures are in place.
**Plans**: 3 plans

Plans:
- [ ] 01-01: Finalize XML ADR with pure-BEAM/NIF/hybrid evaluation and decision record.
- [ ] 01-02: Implement hardened XML seam contract and baseline adapter scaffolding.
- [ ] 01-03: Establish canonicalization/security acceptance criteria and seed fixture corpus.

### Phase 2: Protocol and Signature Core
**Goal**: Deliver strict SP-initiated protocol core that only accepts verified trust paths.
**Depends on**: Phase 1
**Requirements**: [SEC-02, SEC-03, SEC-04, SEC-05, SEC-07, PROT-01, PROT-02, PROT-03, PROT-05]
**Success Criteria** (what must be TRUE):
  1. SP-initiated login protocol flow works end-to-end in pure core logic.
  2. Signature verification is bound to consumed signed nodes with wrapping/ID defenses.
  3. Issuer/audience/recipient/destination/status/time validations return typed failures.
**Plans**: 3 plans

Plans:
- [ ] 02-01: Implement AuthnRequest and binding encode/decode primitives.
- [ ] 02-02: Implement signature verification, signed-node selection, and algorithm policy.
- [ ] 02-03: Implement response/assertion validation pipeline with typed protocol errors.

### Phase 3: Behaviour Contracts and Stores
**Goal**: Ship stable extension contracts and safe defaults for request intent and replay controls.
**Depends on**: Phase 2
**Requirements**: [SEC-06, PROT-04, EXT-01, EXT-02, EXT-03, EXT-04, EXT-05]
**Success Criteria** (what must be TRUE):
  1. All five public behaviours exist with stable callback contracts.
  2. Request/replay stores support atomic semantics and production-safe adapter defaults.
  3. Multi-tenant resolver and adapter integration paths are usable without protocol-core coupling.
**Plans**: 3 plans

Plans:
- [ ] 03-01: Define and publish behaviour contracts plus static/default adapter scaffolding.
- [ ] 03-02: Implement ETS and Ecto request/replay adapters with production guardrails.
- [ ] 03-03: Integrate InResponseTo and replay semantics through core consume flow.

### Phase 4: Phoenix Runtime Integration
**Goal**: Provide ergonomic Phoenix integration surface with strict typed failure routing.
**Depends on**: Phase 3
**Requirements**: [PHX-01, PHX-02, PHX-03]
**Success Criteria** (what must be TRUE):
  1. Host apps can mount SAML routes with `saml_routes/2`.
  2. Metadata/login/ACS runtime paths are wired and operational.
  3. Runtime failures are surfaced via typed `%Relyra.Error{}` through configured error hooks.
**Plans**: 2 plans

Plans:
- [ ] 04-01: Implement router macro and endpoint/controller scaffolding.
- [ ] 04-02: Wire ACS/login session and error callback runtime flow.

### Phase 5: Observability and Enforcement
**Goal**: Make validation outcomes explainable and guardrail violations impossible to miss.
**Depends on**: Phase 4
**Requirements**: [SEC-08, OBS-01, OBS-02, OBS-04]
**Success Criteria** (what must be TRUE):
  1. Telemetry events and metadata are documented and emitted from critical validation/runtime paths.
  2. Logging is redacted by default and never exposes raw assertion payloads.
  3. Boundary and custom static checks prevent known architecture/safety regressions.
**Plans**: 2 plans

Plans:
- [ ] 05-01: Implement telemetry catalog/events and stable typed error/metadata contracts.
- [ ] 05-02: Implement redaction, custom Credo checks, and architecture enforcement checks.

### Phase 6: Delivery Hardening and Adoption Surface
**Goal**: Complete the shippable v0.1 adoption surface with docs, install path, fixtures, and release discipline.
**Depends on**: Phase 5
**Requirements**: [SEC-09, PHX-04, OBS-03, OBS-05, GATE-04]
**Success Criteria** (what must be TRUE):
  1. Provider guides + Keycloak integration path are complete and validated.
  2. Installer and TestSupport provide practical first-run and test-run experiences.
  3. Security/release CI and docs (`README`, `SECURITY.md`, conventions) support safe OSS operation.
**Plans**: 4 plans

Plans:
- [ ] 06-01: Ship provider recipes and Keycloak integration fixtures.
- [ ] 06-02: Implement `mix relyra.install` with golden-diff path-gated verification.
- [ ] 06-03: Ship TestSupport/FakeIdP and complete adversarial corpus automation.
- [ ] 06-04: Finalize CI/release/security/documentation hardening for v0.1.

## Progress

**Execution Order:**  
Phases execute in numeric order: 1 -> 2 -> 3 -> 4 -> 5 -> 6

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. XML Security ADR and Guardrails | 0/3 | Not started | - |
| 2. Protocol and Signature Core | 0/3 | Not started | - |
| 3. Behaviour Contracts and Stores | 0/3 | Not started | - |
| 4. Phoenix Runtime Integration | 0/2 | Not started | - |
| 5. Observability and Enforcement | 0/2 | Not started | - |
| 6. Delivery Hardening and Adoption Surface | 0/4 | Not started | - |

