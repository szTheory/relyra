# Roadmap: Relyra

## Overview

Relyra v1.7 turns the existing adoption proof into a realistic runnable Phoenix SaaS demo. The milestone builds `demo/ledger_loop` as evaluator evidence: a seeded host app, production-like Ecto stores, customer/admin setup UX, mounted Relyra LiveAdmin, local FakeIdP browser proof, optional Keycloak proof, Docker/CI lanes, and concise docs. It does not add protocol surface, public API shape changes, hosted broker behavior, production IdP behavior, or security relaxation.

## Milestones

- Complete: **v0.1 - SP-initiated SSO, verified end-to-end** (shipped 2026-04-25). See `.planning/milestones/v0.1-ROADMAP.md`.
- Complete: **v0.2 - Enterprise configuration** (shipped 2026-05-06). See `.planning/milestones/v0.2-ROADMAP.md`.
- Complete: **v0.3 - LiveView admin** (shipped 2026-05-06). See `.planning/milestones/v0.3-ROADMAP.md`.
- Complete: **v0.4 - IdP-initiated SSO** (shipped 2026-05-06). See `.planning/milestones/v0.4-ROADMAP.md`.
- Complete: **v0.5 - Operational maturity** (shipped 2026-05-07). See `.planning/milestones/v0.5-ROADMAP.md`.
- Complete: **v0.6 - Operational maturity carryover + SLO** (shipped 2026-05-08). See `.planning/milestones/v0.6-ROADMAP.md`.
- Complete: **v1.0 - External security review + conformance + docs polish** (shipped 2026-05-08). See `.planning/milestones/v1.0-ROADMAP.md`.
- Complete: **v1.1 - Verify the Trust Path** (shipped 2026-05-25). See `.planning/milestones/v1.1-ROADMAP.md`.
- Complete: **v1.3 - Advanced Federation** (shipped 2026-05-27). See `.planning/milestones/v1.3-ROADMAP.md`.
- Complete: **v1.4 - Full SLO + Ops Polish** (shipped 2026-05-27). See `.planning/milestones/v1.4-ROADMAP.md`.
- Complete: **v1.5 - Publish, Prove, Polish** (shipped 2026-05-27). See `.planning/milestones/v1.5-ROADMAP.md`.
- Complete: **v1.6 - Adoption Truth** (shipped 2026-05-28). See `.planning/milestones/v1.6-ROADMAP.md`.
- Active: **v1.7 - Adoption Evidence Demo** (Phases 51-56).

## Phases

**Phase Numbering:**

- Integer phases are planned milestone work.
- Decimal phases are urgent insertions and execute between their surrounding integers.
- v1.7 continues after the highest shipped phase, Phase 50.

- [x] **Phase 51: Demo App Foundation** - Evaluators can boot a conventional LedgerLoop Phoenix app with Relyra mounted as a local path dependency. (completed 2026-06-12)
- [ ] **Phase 52: Ecto Stores And Deterministic Seed Story** - The demo proves durable Relyra stores and deterministic LedgerLoop / Northstar Health data.
- [x] **Phase 53: Setup And Operator UX** - Customer/admin setup, receipts, support handoffs, and mounted LiveAdmin are visible in a calm operator UI. (completed 2026-06-12)
- [x] **Phase 54: Local Browser Login Proof** - The default offline FakeIdP path completes strict in-browser SAML login with receipts and trace evidence. (completed 2026-06-13)
- [x] **Phase 55: Docker, CI, And Optional Keycloak Proof** - Demo commands, Compose profiles, focused CI, browser evidence, and optional Keycloak proof run without weakening security gates. (completed 2026-06-13)
- [x] **Phase 56: Documentation And Evidence Polish** - README and demo guide make the runnable app useful as evaluator evidence and adopter onboarding. (completed 2026-06-13)

## Phase Details

### Phase 51: Demo App Foundation

**Goal**: Evaluators can launch a conventional Phoenix app at `demo/ledger_loop` that visibly hosts Relyra inside a realistic LedgerLoop workspace.
**Depends on**: Phase 50 shipped adoption evidence
**Requirements**: DEMO-01, DEMO-02, DEMO-03, DEMO-04, DEMO-05
**Success Criteria** (what must be TRUE):

  1. Evaluator can boot `demo/ledger_loop` locally with Relyra loaded from the repository path.
  2. Evaluator can open the first screen and see a usable LedgerLoop workspace with tenant status and links to setup, login, admin, and support flows.
  3. Evaluator can confirm Relyra SAML routes are mounted under a clear host-owned route scope.
  4. Docker or CI orchestration can poll health/readiness endpoints and distinguish booted from unavailable demo state.
  5. Hex packaging excludes the demo app while repository-local demo commands still work.

**Plans**: 6 plans
Plans:
**Wave 1**

- [x] 51-01-PLAN.md — Scaffold LedgerLoop Phoenix app foundation

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 51-02-PLAN.md — Mount Relyra SAML/admin route seams
- [x] 51-06-PLAN.md — Prove repo-local runnability and Hex package exclusion

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 51-03-PLAN.md — Add non-browser health/readiness probes and route tests
- [x] 51-04-PLAN.md — Build LedgerLoop workspace and route affordance content

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 51-05-PLAN.md — Apply UI styling and workspace tests

**UI hint**: yes

### Phase 52: Ecto Stores And Deterministic Seed Story

**Goal**: Demo reset creates a reproducible Northstar Health story and the happy path uses production-like Ecto-backed Relyra stores.
**Depends on**: Phase 51
**Requirements**: DATA-01, DATA-02, ECTO-01, ECTO-02, ECTO-03, ECTO-04
**Success Criteria** (what must be TRUE):

  1. Evaluator can reset the demo and always receive the same tenants, users, groups, mappings, certificate states, audit rows, and support scenarios.
  2. Evaluator can inspect seeded enabled, draft, staged-certificate, and failure/support connection states.
  3. Demo setup runs Relyra's shipped Ecto migrations from the dependency path rather than copied migration files.
  4. A successful demo login writes and consumes Ecto-backed connection, request, and replay records with fixed host-owned table names.
  5. Login receipts show Relyra verified the principal while LedgerLoop owns user mapping, session establishment, and authorization.

**Plans**: 6 plans
Plans:
**Wave 1**

- [ ] 52-01-PLAN.md - Run Relyra shipped migrations from dependency path

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 52-02-PLAN.md - Create deterministic LedgerLoop host data reset
- [ ] 52-04-PLAN.md - Add fixed Ecto request and replay store wrappers

**Wave 3** *(blocked on Wave 2 host data completion)*

- [x] 52-03-PLAN.md - Seed inspectable Relyra connection scenarios

**Wave 4** *(blocked on seeded scenarios and fixed stores)*

- [x] 52-05-PLAN.md - Implement host-owned mapper and session receipt boundary

**Wave 5** *(blocked on host boundary completion)*

- [ ] 52-06-PLAN.md - Prove signed Ecto-backed non-browser login path

### Phase 53: Setup And Operator UX

**Goal**: Customer/admin setup and operator diagnosis are browser-visible without blurring host-app workflow, LiveAdmin trust workflows, login trace evidence, or audit rows.
**Depends on**: Phase 52
**Requirements**: FLOW-01, FLOW-02, FLOW-03, ADMIN-01, ADMIN-02, UX-01
**Success Criteria** (what must be TRUE):

  1. Customer/admin can use a nonlinear setup checklist with copyable SP settings, provider vocabulary, IdP intake, mapping preview, test login, and enablement receipt.
  2. Receipts state what was verified, mapped, replay-checked, and handed to LedgerLoop without exposing raw XML, PEM, or secrets.
  3. Operator can open mounted Relyra LiveAdmin with the correct repo and scope provider and see seeded trust-state workflows.
  4. Support scenarios link to trace and diagnostic surfaces while clearly separating runtime login trace evidence from trust-mutation audit rows.
  5. The demo UI uses accessible status text, precise microcopy, light/dark/system support, and no color-only risk indicators.

**Plans**: 3 plans
Plans:
**Wave 1**

- [x] 53-01-PLAN.md — Admin session mocking and support trace routing

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 53-02-PLAN.md — LiveView setup checklist and safe receipts

**Wave 3** *(gap closure)*

- [x] 53-03-PLAN.md — Fix Setup Checklist UI gaps by implementing functional SP settings, an IdP metadata intake form, mapping preview, and test login logic.

**UI hint**: yes

### Phase 54: Local Browser Login Proof

**Goal**: The default offline demo proof completes strict SAML login through browser-visible FakeIdP test support and produces actionable receipts.
**Depends on**: Phase 53
**Requirements**: IDP-01, IDP-02, E2E-01
**Success Criteria** (what must be TRUE):

  1. End user can complete an in-browser SAML login through a dev/test-only FakeIdP route using genuine Relyra test signing.
  2. The FakeIdP path is visibly labeled as local test support and cannot be mistaken for a production IdP.
  3. Browser proof covers setup checklist or receipt, seeded LiveAdmin connection visibility, end-user login receipt, and support trace handoff.
  4. Failed local proof paths surface typed rejection evidence rather than silent compromise or raw protocol leakage.

**Plans**: TBD
**UI hint**: yes

### Phase 55: Docker, CI, And Optional Keycloak Proof

**Goal**: The demo can be booted, reset, tested, and optionally proven against Keycloak through isolated Docker and CI lanes.
**Depends on**: Phase 54
**Requirements**: DX-01, DX-02, DX-03, CI-01, IDP-03, IDP-04, E2E-02
**Success Criteria** (what must be TRUE):

  1. Evaluator can run `scripts/demo doctor`, `up`, `reset`, `test`, `urls`, and `down` from the repository root.
  2. Compose uses project-name isolation, env-driven ports, healthchecks, and `core`/`keycloak`/`browser` profiles without fixed container names.
  3. `doctor` reports common blockers with exact environment overrides or remediation steps.
  4. `mix ci.demo_app` compiles, migrates, seeds, and proves local FakeIdP plus Ecto store behavior without weakening `mix ci.security`.
  5. Optional Keycloak proof completes browser-visible login against the launched Phoenix app while preserving configured-certificate trust and keeping Keycloak outside required deterministic proof.

**Plans**: 3 plans
Plans:
**Wave 1**
- [x] 55-01-PLAN.md — Consolidate Docker orchestrations into a top-level docker-compose.yml
- [x] 55-03-PLAN.md — Wire the Demo app into GitHub CI with a new isolated pipeline

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 55-02-PLAN.md — Provide a low-friction CLI wrapper for Demo lifecycle and Docker

### Phase 56: Documentation And Evidence Polish

**Goal**: Evaluators and adopters can understand, run, reset, test, and interpret the demo without replacing the normal Hex installation path.
**Depends on**: Phase 55
**Requirements**: DOCS-01, DOCS-02, DOCS-03
**Success Criteria** (what must be TRUE):

  1. README or Getting Started links to the runnable demo as evaluator evidence while preserving the normal Hex install path.
  2. Demo guide documents boot, reset, test, URL discovery, seeded credentials, key routes, Docker overrides, and optional Keycloak profile.
  3. Demo guide explains the host-app boundary: Relyra verifies SAML trust, while LedgerLoop owns tenant workflow, mapping, sessions, and authorization.
  4. Evidence notes make clear that v1.7 adds adoption proof only, not protocol expansion, production IdP behavior, hosted broker behavior, or security relaxation.

**Plans**: 3 plans
Plans:
**Wave 1**
- [x] 56-01-PLAN.md — Rewrite the demo README as the authoritative evaluator-first guide (verified surface, boundary table, scope honesty, D-12 content gate)

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 56-02-PLAN.md — Add the thin guides/demo.md hexdocs pointer and secondary README/Getting Started demo links without displacing the Hex install path

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 56-03-PLAN.md — Add and CI-wire the scripts/demo subcommand drift gate in the ci.docs lane

## Coverage

| Requirement | Phase |
|-------------|-------|
| DEMO-01 | Phase 51 |
| DEMO-02 | Phase 51 |
| DEMO-03 | Phase 51 |
| DEMO-04 | Phase 51 |
| DEMO-05 | Phase 51 |
| DATA-01 | Phase 52 |
| DATA-02 | Phase 52 |
| ECTO-01 | Phase 52 |
| ECTO-02 | Phase 52 |
| ECTO-03 | Phase 52 |
| ECTO-04 | Phase 52 |
| FLOW-01 | Phase 53 |
| FLOW-02 | Phase 53 |
| FLOW-03 | Phase 53 |
| ADMIN-01 | Phase 53 |
| ADMIN-02 | Phase 53 |
| UX-01 | Phase 53 |
| IDP-01 | Phase 54 |
| IDP-02 | Phase 54 |
| E2E-01 | Phase 54 |
| DX-01 | Phase 55 |
| DX-02 | Phase 55 |
| DX-03 | Phase 55 |
| CI-01 | Phase 55 |
| IDP-03 | Phase 55 |
| IDP-04 | Phase 55 |
| E2E-02 | Phase 55 |
| DOCS-01 | Phase 56 |
| DOCS-02 | Phase 56 |
| DOCS-03 | Phase 56 |

Coverage: 30/30 v1.7 requirements mapped. No orphaned requirements. No duplicated phase mappings.

## Progress

**Execution Order (v1.7):**
Phases execute in numeric order: 51 -> 52 -> 53 -> 54 -> 55 -> 56.

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 51. Demo App Foundation | 6/6 | Complete    | 2026-06-12 |
| 52. Ecto Stores And Deterministic Seed Story | 3/6 | In Progress|  |
| 53. Setup And Operator UX | 3/3 | Complete   | 2026-06-12 |
| 54. Local Browser Login Proof | 2/2 | Complete   | 2026-06-13 |
| 55. Docker, CI, And Optional Keycloak Proof | 3/3 | Complete   | 2026-06-13 |
| 56. Documentation And Evidence Polish | 3/3 | Complete    | 2026-06-13 |
