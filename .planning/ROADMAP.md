# Roadmap: Relyra

## Overview

Relyra is a strict-by-default SAML 2.0 Service Provider library for Elixir/Phoenix. The v1.x arc is shipped through **v1.8 - Brand System & Identity** (Phases 58-63). The active milestone is **v1.9 - Loose Ends & Adoption Honesty**, a bounded maintenance/adoption milestone that resolves the public testing story, package/docs truth, LedgerLoop demo FakeIdP disposition, and narrow maintenance drift without reopening demand-gated protocol work.

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
- Complete: **v1.7 - Adoption Evidence Demo** (shipped 2026-06-13, Phases 51-57.1). See `.planning/milestones/v1.7-ROADMAP.md`.
- Complete: **v1.8 - Brand System & Identity** (shipped 2026-06-14, Phases 58-63, 16/16 requirements; non-protocol brand/design). See `.planning/milestones/v1.8-ROADMAP.md`.
- Active: **v1.9 - Loose Ends & Adoption Honesty** (started 2026-06-15, Phases 64-67).

## Active Milestone

**v1.9 - Loose Ends & Adoption Honesty**

**Goal:** Close adopter-facing loose ends after v1.8 by making the Hex testing story honest and useful, resolving the LedgerLoop demo FakeIdP WIP, and syncing narrow maintenance docs without reopening demand-gated protocol work.

**Scope boundaries:**

- In scope: public `Relyra.Testing` planning/implementation, package/docs truth, demo FakeIdP disposition, narrow maintenance sync.
- Out of scope: `AUTHN-POST-01`, `KMS-01`, `SIGNED-META-01`, full public adversarial corpus, production IdP or hosted broker behavior.

## Phases

| Phase | Name | Goal | Requirements | Status |
|-------|------|------|--------------|--------|
| 64 | Public Testing API & Package Boundary | Ship a curated public test-only helper surface while preserving private support boundaries and verifier invariants. | TEST-01, TEST-02, TEST-03, TEST-04, TEST-05, PKG-01 | In Progress (1/4 plans) |
| 65 | Documentation Truth | Rewrite adopter-facing docs around the public testing API and clearly mark private support internals as repo-only. | DOCS-01, DOCS-02, DOCS-03 | Pending |
| 66 | Demo FakeIdP Disposition | Verify, finish, document, or remove the LedgerLoop FakeIdP browser flow so the demo has one intentional login story. | DEMO-01, DEMO-02, DEMO-03 | Pending |
| 67 | Maintenance Narrative Sync | Close or explicitly defer the remaining narrative, seed, CVE, CI/release, and Phase 29 review loose ends. | MAINT-01, MAINT-02, MAINT-03 | Pending |

## Phase Details

### Phase 64: Public Testing API & Package Boundary

**Goal:** Ship a deliberately small `Relyra.Testing` public surface that Hex adopters can use without exposing private `Relyra.TestSupport` internals.

**Requirements:** TEST-01, TEST-02, TEST-03, TEST-04, TEST-05, PKG-01

**Plans:** 1/4 plans executed

Plans:
**Wave 1**

- [x] 64-01-PLAN.md — Phoenix-free `Relyra.Testing` core fixtures and signed success proof

**Wave 2** *(blocked on Wave 1 completion)*

- [ ] 64-02-PLAN.md — Representative negative fixtures and security CI gate
- [ ] 64-03-PLAN.md — Optional Phoenix helper and core dependency isolation

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 64-04-PLAN.md — Package parity proof for public testing files

**Success criteria:**

1. `lib/relyra/testing*` exists as the public API surface and is included in package files.
2. `lib/relyra/test_support*` remains excluded from production compilation and package files.
3. Public helpers generate genuine signed success fixtures with matching test cert chain and no global production trust mutation.
4. Public helpers generate representative typed rejection fixtures without publishing the private adversarial corpus.
5. Tests prove helper outputs exercise the real ACS or `consume_response/3` verification path, including digest/signature verification.
6. Optional Phoenix convenience helpers, if shipped, are isolated from core fixture generation and do not make Phoenix mandatory.

**Research flags:**

- Final API shape, fixture return type, key lifecycle, and optional Phoenix compile behavior need phase-level design before implementation.
- Any public API signature must be reviewed carefully before implementation.

### Phase 65: Documentation Truth

**Goal:** Make README, Getting Started, overview, recipes, and generated proof docs match the public package reality.

**Requirements:** DOCS-01, DOCS-02, DOCS-03

**Success criteria:**

1. Hex adopters are pointed at `Relyra.Testing`, not private `Relyra.TestSupport`, for local proof.
2. Docs clearly label helpers as test-only and avoid production IdP or hosted broker language.
3. Docs explain cert/key provenance and make test cert trust explicit and scoped.
4. Repo-internal references to `Relyra.TestSupport` are either moved out of adopter docs or labeled as internal test-suite examples.
5. Doc drift tests or presence checks cover the new public testing story.

### Phase 66: Demo FakeIdP Disposition

**Goal:** Resolve SEED-003 against current repo state instead of stale assumptions.

**Requirements:** DEMO-01, DEMO-02, DEMO-03

**Success criteria:**

1. Current `/fake_idp/login` and `/fake_idp/sso` routes, controller tests, and browser/demo lane status are verified.
2. The milestone makes an explicit retain-vs-remove decision for the demo FakeIdP browser flow.
3. If retained, the flow is documented as the canonical or clearly labeled local FakeIdP browser proof.
4. If removed, stale routes/controllers/templates/tests are deleted and route-affordance login remains canonical.
5. SEED-003 is resolved or reclassified with evidence.

### Phase 67: Maintenance Narrative Sync

**Goal:** Sweep the low-risk carry-forward items after the public API/docs/demo decisions are settled.

**Requirements:** MAINT-01, MAINT-02, MAINT-03

**Success criteria:**

1. `guides/jtbd_user_flows.md` Scene 3 and ADFS references are reviewed and updated if stale.
2. CVE ID backfill status is checked and recorded without manually publishing or retiring Hex packages.
3. CI/release guard notes are updated only where they are stale.
4. Phase 29 warning-level review items are closed, converted into explicit deferrals, or left with a documented reason.
5. SEED-001, SEED-002, and SEED-003 are cleaned up or reclassified so completed/stale ideas do not resurface incorrectly.

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| TEST-01 | Phase 64 | Pending |
| TEST-02 | Phase 64 | Pending |
| TEST-03 | Phase 64 | Pending |
| TEST-04 | Phase 64 | Pending |
| TEST-05 | Phase 64 | Pending |
| PKG-01 | Phase 64 | Pending |
| DOCS-01 | Phase 65 | Pending |
| DOCS-02 | Phase 65 | Pending |
| DOCS-03 | Phase 65 | Pending |
| DEMO-01 | Phase 66 | Pending |
| DEMO-02 | Phase 66 | Pending |
| DEMO-03 | Phase 66 | Pending |
| MAINT-01 | Phase 67 | Pending |
| MAINT-02 | Phase 67 | Pending |
| MAINT-03 | Phase 67 | Pending |

**Coverage:**

- v1.9 requirements: 15 total
- Mapped to phases: 15
- Unmapped: 0

## Next Up

**Phase 64: Public Testing API & Package Boundary** - design and implement the public test-only helper surface while preserving private package boundaries and verifier invariants.

`$gsd-discuss-phase 64`

Also available:

- `$gsd-plan-phase 64` - skip discussion and plan directly

---
*Roadmap updated: 2026-06-15 after v1.9 roadmap creation*
