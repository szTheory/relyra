# Requirements: Relyra v1.6 — Adoption Truth

**Defined:** 2026-05-27
**Status:** Active
**Core Value:** Every SAML login ends in a verified trust path or a typed rejection — never a silent compromise. Trust mutations are durable, attributable, and reviewable.

**Milestone goal:** Close the gap between codebase strength and adopter-facing documentation so a Phoenix SaaS team can go from install to verified browser login to production Ecto deployment without doc drift — no new SAML protocol surface area.

## v1.6 Requirements

Requirements for this milestone. Each maps to one roadmap phase.

### Onboarding Truth

- [ ] **ADOPT-01**: `guides/getting_started.md` promotes the `TestSupport` macro pattern (`setup_saml_connection/2`, `post_saml_response/2` from `test/test_support_demo_test.exs`) as the primary path to first verified browser login, replacing or demoting the low-level FakeIdP PEM/signing snippet that leaves adopters between "scaffold compiles" and "login works."

- [ ] **ADOPT-02**: A new **"Production Ecto path"** section (in Getting Started or a linked guide) documents: running Relyra migrations, wiring `Relyra.ConnectionResolver.Ecto`, swapping RequestStore/ReplayStore from ETS to Ecto adapters, and the production replay-store warning (`ETS` warns in prod). An adopter can follow it without reading source.

### Operator Completeness

- [ ] **ADOPT-03**: `guides/operations/incident_playbook.md` tool table includes the login-trace LiveView route (`/relyra/admin/connections/:id/trace`) and `mix relyra.trace` with when-to-use guidance aligned to the six Triage→Diagnose scenarios.

### Conformance & Planning Honesty

- [ ] **ADOPT-04**: `CONFORMANCE.md` gains a **"Scope boundary & diminishing returns"** section recording the v0.x→v1.5 shipping arc and explicit out-of-scope boundary (HTTP-Artifact, ECP, Attribute Query, SCIM-in-core, more presets-without-generic-path, standalone demo app). `priv/conformance/sp_manifest.json` updates `sp-encrypted-assertions-deferred` to reflect ENC-01 shipped (Phase 34) — not deferred.

- [ ] **ADOPT-05**: `docs/jtbd_gap_map.md` refreshed to v1.5 reality — incident playbook, generic SAML runbook, login trace, encrypted assertions, and SLO are marked shipped; stale "missing" rows removed.

### Preset Taxonomy Honesty

- [ ] **ADOPT-06**: README, Getting Started, and `guides/recipes/generic_saml.md` agree on preset taxonomy: either add Keycloak and OneLogin decoder-table rows (if README claims them) or narrow README/Getting Started claims to match the seven-family generic runbook. No over-promised IdP coverage.

## Future Requirements

Deferred to future milestones. Tracked but not in current roadmap.

### Demand-Gated (post-v1.6 pause default)

- **AUTHN-POST-01**: HTTP-POST binding signed AuthnRequests — `.planning/threads/signed-authn-requests-investigation.md`
- **KMS-01**: KMS-native `KeyResolver` adapters — `.planning/threads/encrypted-assertions-investigation.md`
- **SIGNED-META-01**: Signed SP metadata + federation extensions — `.planning/threads/signed-sp-metadata-investigation.md`
- **CVE ID backfill** into `docs/advisories/2026-001-...` — pending async GitHub assignment

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| New protocol features (POST AuthnRequests, ECP, HTTP-Artifact, Attribute Query) | v1.6 is doc-only; demand-gated per done-enough line. |
| New IdP presets as first-class modules | Generic SAML runbook covers additional families. |
| KMS-native KeyResolver adapters | Demand-gated; compliance-pull not ergonomics-pull. |
| Signed SP metadata (`EntityDescriptor`) | Demand-gated; investigation stub only. |
| Full standalone demo app | Library, not application. |
| SCIM lifecycle ownership | PROJECT.md Out of Scope. |
| Public API shape changes | Escalation required; not in v1.6 charter. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| ADOPT-01 | 47 | Pending |
| ADOPT-02 | 47 | Pending |
| ADOPT-03 | 48 | Pending |
| ADOPT-04 | 49 | Pending |
| ADOPT-05 | 49 | Pending |
| ADOPT-06 | 49 | Pending |

**Coverage:**

- v1.6 requirements: 6 total
- Mapped to phases: 6/6 ✓
- Unmapped: 0

**Phase ↔ Requirement summary:**

| Phase | Name | Requirements | Count |
|-------|------|--------------|-------|
| 47 | Onboarding truth — Getting Started & production Ecto path | ADOPT-01, ADOPT-02 | 2 |
| 48 | Operator completeness — incident playbook trace tools | ADOPT-03 | 1 |
| 49 | Adoption honesty — CONFORMANCE, jtbd map, preset taxonomy | ADOPT-04, ADOPT-05, ADOPT-06 | 3 |

---
*Requirements defined: 2026-05-27*
*Last updated: 2026-05-27 after milestone v1.6 roadmap creation*
