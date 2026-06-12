# Requirements: Relyra v1.7 Adoption Evidence Demo

**Defined:** 2026-06-12
**Core Value:** Every SAML login ends in a verified trust path or a typed rejection — never a silent compromise.

## v1.7 Requirements

### Demo App Foundation

- [x] **DEMO-01**: Evaluator can boot a conventional Phoenix app at `demo/ledger_loop` that depends on the local Relyra package via path dependency.
- [x] **DEMO-02**: Demo app is excluded from the Hex package while remaining runnable from the repository.
- [x] **DEMO-03**: Demo app exposes a usable LedgerLoop workspace as its first screen with tenant status and links to setup, login, admin, and support flows.
- [x] **DEMO-04**: Demo app mounts Relyra SAML routes under a clear host-owned route scope.
- [x] **DEMO-05**: Demo app exposes health/readiness endpoints suitable for local Docker and CI orchestration.

### Data And Stores

- [ ] **DATA-01**: Demo reset creates deterministic LedgerLoop / Northstar Health tenants, users, groups, memberships, SAML identities, mappings, cert states, audit rows, and trace/failure scenarios.
- [ ] **DATA-02**: Demo seeds at least one enabled happy-path connection, one draft/missing-metadata connection, one staged-certificate scenario, and one failure/support scenario.
- [ ] **ECTO-01**: Demo runs Relyra's shipped Ecto migrations from the dependency path instead of copying migration files.
- [ ] **ECTO-02**: Demo happy path uses Ecto-backed connection resolution, request store, and replay store.
- [ ] **ECTO-03**: Demo provides host-owned wrapper modules for Relyra request/replay stores with fixed table names and no request-param-derived storage targets.
- [ ] **ECTO-04**: Demo user mapping and session establishment remain host-owned and demonstrate the boundary between verified principal and product authorization.

### Setup And Operator UX

- [ ] **FLOW-01**: Customer/admin setup page shows copyable SP settings, provider vocabulary, IdP metadata/manual intake, mapping preview, test-login action, and enablement receipt.
- [ ] **FLOW-02**: Setup UX uses a task-list/checklist pattern suitable for nonlinear SAML setup across multiple systems and people.
- [ ] **FLOW-03**: Login/setup receipts state what was verified, mapped, replay-checked, and handed to the host app without exposing raw XML, PEM, or secrets.
- [ ] **ADMIN-01**: Demo mounts Relyra LiveAdmin for operator trust-state workflows using a proper repo and scope provider.
- [ ] **ADMIN-02**: Demo links support scenarios to LiveAdmin trace/diagnostic surfaces without confusing login trace evidence with trust-mutation audit rows.
- [ ] **UX-01**: Demo UI follows Relyra's calm/operator brand: accessible status text, clear microcopy, light/dark/system support, and no color-only risk indicators.

### Identity Provider Proof

- [ ] **IDP-01**: Default local proof completes an in-browser SAML login through a dev/test-only FakeIdP route using genuine Relyra test signing.
- [ ] **IDP-02**: FakeIdP proof is clearly labeled as local test support and cannot be presented as a production IdP.
- [ ] **IDP-03**: Optional Keycloak profile completes a browser-visible external IdP happy path against the launched Phoenix demo app.
- [ ] **IDP-04**: Keycloak proof preserves configured-certificate trust and never treats document `KeyInfo` as a trust source.

### Docker, CI, And Browser Evidence

- [ ] **DX-01**: Root `scripts/demo` supports `doctor`, `up`, `reset`, `test`, `urls`, and `down`.
- [ ] **DX-02**: Compose setup uses project-name isolation, env-driven ports, profiles for `core`/`keycloak`/`browser`, no fixed `container_name`, and healthchecks/readiness probes.
- [ ] **DX-03**: `doctor` detects common local blockers and prints exact environment overrides or remediation steps.
- [ ] **CI-01**: Focused `mix ci.demo_app` lane compiles, migrates, seeds, and proves local FakeIdP + Ecto store behavior without weakening `mix ci.security`.
- [ ] **E2E-01**: Browser proof covers setup checklist/receipt, LiveAdmin seeded connection visibility, end-user login receipt, and support trace handoff.
- [ ] **E2E-02**: Optional Keycloak browser proof is isolated from required deterministic demo proof until burn-in justifies promotion.

### Documentation

- [ ] **DOCS-01**: README or Getting Started links to the runnable demo as evaluator evidence without replacing the normal Hex installation path.
- [ ] **DOCS-02**: Demo guide documents boot/reset/test/urls, seeded credentials, key routes, and Docker environment overrides.
- [ ] **DOCS-03**: Demo guide explains the host-app boundary: Relyra verifies SAML trust; LedgerLoop owns tenant workflow, user mapping, sessions, and authorization.

## Future Requirements

### Productization Candidates

- **PORTAL-01**: Extract reusable customer-admin setup components into Relyra core only after v1.7 evidence proves stable boundaries across host apps.
- **CI-KEYCLOAK-01**: Promote Keycloak browser proof to required branch protection only after repeated stress/burn-in runs demonstrate acceptable stability.
- **SCREENSHOT-01**: Add curated screenshots or short clips to docs only after the demo UI settles.

### Demand-Gated Protocol Candidates

- **AUTHN-POST-01**: HTTP-POST binding signed AuthnRequests.
- **KMS-01**: KMS/HSM-native assertion decryption key unwrapping.
- **SIGNED-META-01**: Signed SP metadata and federation extensions.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Hosted SSO broker runtime | Relyra is a Phoenix library; customer data and control stay in host applications. |
| Customer self-service portal in Relyra core | Premature before the demo proves reusable host/app boundaries. |
| Production IdP | `Relyra.TestSupport.FakeIdP` is dev/test support only. |
| New protocol surface | v1.7 is adoption evidence, not AUTHN-POST/KMS/SIGNED-META. |
| New provider presets | Provider additions require named demand, preset code, runbook, vocabulary, and proof. |
| Public API shape changes | `start_login/3`, `consume_response/3`, and published behaviours stay stable unless explicitly escalated. |
| Security posture relaxation | Demo must preserve configured-cert trust, one parse path, crypto verification, replay, and audit invariants. |
| SCIM lifecycle ownership | Relyra focuses on SAML login-time identity and mapping, not lifecycle provisioning. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DEMO-01 | Phase 51 | Complete |
| DEMO-02 | Phase 51 | Complete |
| DEMO-03 | Phase 51 | Complete |
| DEMO-04 | Phase 51 | Complete |
| DEMO-05 | Phase 51 | Complete |
| DATA-01 | Phase 52 | Pending |
| DATA-02 | Phase 52 | Pending |
| ECTO-01 | Phase 52 | Pending |
| ECTO-02 | Phase 52 | Pending |
| ECTO-03 | Phase 52 | Pending |
| ECTO-04 | Phase 52 | Pending |
| FLOW-01 | Phase 53 | Pending |
| FLOW-02 | Phase 53 | Pending |
| FLOW-03 | Phase 53 | Pending |
| ADMIN-01 | Phase 53 | Pending |
| ADMIN-02 | Phase 53 | Pending |
| UX-01 | Phase 53 | Pending |
| IDP-01 | Phase 54 | Pending |
| IDP-02 | Phase 54 | Pending |
| E2E-01 | Phase 54 | Pending |
| DX-01 | Phase 55 | Pending |
| DX-02 | Phase 55 | Pending |
| DX-03 | Phase 55 | Pending |
| CI-01 | Phase 55 | Pending |
| IDP-03 | Phase 55 | Pending |
| IDP-04 | Phase 55 | Pending |
| E2E-02 | Phase 55 | Pending |
| DOCS-01 | Phase 56 | Pending |
| DOCS-02 | Phase 56 | Pending |
| DOCS-03 | Phase 56 | Pending |

**Coverage:**
- v1.7 requirements: 30 total
- Mapped to phases: 30
- Unmapped: 0

---
*Requirements defined: 2026-06-12*
*Last updated: 2026-06-12 after v1.7 new-milestone research synthesis*
