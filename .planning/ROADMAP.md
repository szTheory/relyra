# Roadmap: Relyra

## Milestones

- ✅ **v0.1 — SP-initiated SSO, verified end-to-end** (shipped 2026-04-25). See `.planning/milestones/v0.1-ROADMAP.md`.
- ✅ **v0.2 — Enterprise configuration** (shipped 2026-05-06). See `.planning/milestones/v0.2-ROADMAP.md`.
- ✅ **v0.3 — LiveView admin** (shipped 2026-05-06). See `.planning/milestones/v0.3-ROADMAP.md`.
- ✅ **v0.4 — IdP-initiated SSO** (shipped 2026-05-06). See `.planning/milestones/v0.4-ROADMAP.md`.
- ✅ **v0.5 — Operational maturity** (shipped 2026-05-07). See `.planning/milestones/v0.5-ROADMAP.md`.
- ✅ **v0.6 — Operational maturity carryover + SLO** (shipped 2026-05-08). See `.planning/milestones/v0.6-ROADMAP.md`.
- ✅ **v1.0 — External security review + conformance + docs polish** (shipped 2026-05-08). See `.planning/milestones/v1.0-ROADMAP.md`.
- ✅ **v1.1 — Verify the Trust Path** (shipped 2026-05-25). See `.planning/milestones/v1.1-ROADMAP.md`.
- ✅ **v1.3 — Advanced Federation** (shipped 2026-05-27). See `.planning/milestones/v1.3-ROADMAP.md`.
- ✅ **v1.4 — Full SLO + Ops Polish** (shipped 2026-05-27). See `.planning/milestones/v1.4-ROADMAP.md`.
- ✅ **v1.5 — Publish, Prove, Polish** (shipped 2026-05-27). See `.planning/milestones/v1.5-ROADMAP.md`.
- 🔄 **v1.6 — Adoption Truth** — Phases 47-49 shipped 2026-05-27; Phases 49.1-49.2 gap closure in progress.

## Phases

<details>
<summary>✅ v0.1 — SP-initiated SSO (Phases 1-6) — SHIPPED 2026-04-25</summary>

See `.planning/milestones/v0.1-ROADMAP.md`.

</details>

<details>
<summary>✅ v0.2 — Enterprise configuration (Phases 7-14) — SHIPPED 2026-05-06</summary>

See `.planning/milestones/v0.2-ROADMAP.md`.

</details>

<details>
<summary>✅ v0.3 — LiveView admin (Phases 15-18) — SHIPPED 2026-05-06</summary>

See `.planning/milestones/v0.3-ROADMAP.md`.

</details>

<details>
<summary>✅ v0.4 — IdP-initiated SSO (Phase 19) — SHIPPED 2026-05-06</summary>

See `.planning/milestones/v0.4-ROADMAP.md`.

</details>

<details>
<summary>✅ v0.5 — Operational maturity (Phases 20-21.2) — SHIPPED 2026-05-07</summary>

See `.planning/milestones/v0.5-ROADMAP.md`.

</details>

<details>
<summary>✅ v0.6 — Operational maturity carryover + SLO (Phases 22-24) — SHIPPED 2026-05-08</summary>

See `.planning/milestones/v0.6-ROADMAP.md`.

</details>

<details>
<summary>✅ v1.0 — External security review + conformance + docs polish (Phases 25-27) — SHIPPED 2026-05-08</summary>

See `.planning/milestones/v1.0-ROADMAP.md`.

</details>

<details>
<summary>✅ v1.1 — Verify the Trust Path (Phases 28-31) — SHIPPED 2026-05-25</summary>

See `.planning/milestones/v1.1-ROADMAP.md`.

</details>

<details>
<summary>✅ v1.3 — Advanced Federation (Phases 32-37) — SHIPPED 2026-05-27</summary>

See `.planning/milestones/v1.3-ROADMAP.md`.

</details>

<details>
<summary>✅ v1.4 — Full SLO + Ops Polish (Phases 38-40.1) — SHIPPED 2026-05-27</summary>

See `.planning/milestones/v1.4-ROADMAP.md`.

</details>

<details>
<summary>✅ v1.5 — Publish, Prove, Polish (Phases 41-46) — SHIPPED 2026-05-27</summary>

- [x] Phase 41: Pre-publish hygiene — Tech-debt sweep & security hardening (5/5 plans) — completed 2026-05-27
- [x] Phase 42: Stepwise login-trace LiveView (4/4 plans) — completed 2026-05-27
- [x] Phase 43: Hex publish prep — version bump & CHANGELOG backfill (1/1 plan) — completed 2026-05-27
- [x] Phase 44: Release-please pipeline diagnosis & v1.4.0 Hex publish (3/3 plans) — completed 2026-05-27
- [x] Phase 45: Post-publish parity verification (2/2 plans) — completed 2026-05-27
- [x] Phase 46: Adopter DX & ergonomics (3/3 plans) — completed 2026-05-27

See `.planning/milestones/v1.5-ROADMAP.md`.

</details>

### 🔄 v1.6 — Adoption Truth (Phases 47-49 shipped; gap closure 49.1-49.2)

**Milestone Goal:** Close the gap between codebase strength and adopter-facing documentation — onboarding, production Ecto path, ops trace tools, CONFORMANCE honesty, planning-doc refresh, preset taxonomy alignment. **No new SAML protocol surface area.** Full assessment: `.planning/threads/v1-6-milestone-assessment-2026-05-27.md`.

**Phase numbering:** v1.5 ended at Phase 46; v1.6 continues at Phase **47**. Gap closure phases **49.1** and **49.2** inserted after Phase 49 per `.planning/v1.6-MILESTONE-AUDIT.md`.

**Summary checklist:**

- [x] **Phase 47: Onboarding truth — Getting Started & production Ecto path** — TestSupport macro pattern for first browser login; production Ecto path section. (completed 2026-05-27)
- [x] **Phase 48: Operator completeness — incident playbook trace tools** — Login-trace LiveView route + `mix relyra.trace` in incident playbook tool table; Day-2 cross-links. (completed 2026-05-27)
- [x] **Phase 49: Adoption honesty — CONFORMANCE, jtbd map, preset taxonomy** — Scope boundary section, ENC manifest fix, jtbd_gap_map refresh, README/runbook taxonomy alignment. (completed 2026-05-27)
- [x] **Phase 49.1: Close v1.6 audit doc handoff gaps (INSERTED)** — Ecto path → Day-2 ops forward links; README/jtbd_user_flows cross-link alignment. (completed 2026-05-27)
- [ ] **Phase 49.2: v1.6 Nyquist retro + editorial polish (INSERTED)** — Retroactive Phase 47 VALIDATION.md; optional editorial skim per audit.

## Phase Details (v1.6)

### Phase 47: Onboarding truth — Getting Started & production Ecto path

**Goal:** A new adopter follows Getting Started from install to first verified browser login using the `TestSupport` macro pattern, then can find a single authoritative production Ecto deployment path without reading source.
**Depends on:** Nothing (entry phase for v1.6).
**Requirements:** ADOPT-01, ADOPT-02
**Success Criteria** (what must be TRUE):

1. `guides/getting_started.md` links to and explains `setup_saml_connection/2` and `post_saml_response/2` (from `test/test_support_demo_test.exs`) as the recommended first-login path; the low-level FakeIdP PEM/signing walkthrough is demoted or moved to an appendix.
2. A **"Production Ecto path"** section exists (in Getting Started or a linked guide wired into `guides/overview.md` Day-2) covering migrations, `ConnectionResolver.Ecto`, ETS→Ecto RequestStore/ReplayStore swap, and the production replay-store warning.
3. `mix ci.docs` stays green after doc changes (presence guards + any new drift tests follow Phase 30 `cmd mix test` pattern if added).

**Plans:** 3/3 plans complete

### Phase 48: Operator completeness — incident playbook trace tools

**Goal:** An operator running the incident playbook knows when to open the login-trace LiveView or run `mix relyra.trace` without discovering those tools only from source or v1.5 release notes.
**Depends on:** Phase 47 (onboarding docs should reference trace for Day-2 debugging; soft dependency).
**Requirements:** ADOPT-03
**Success Criteria** (what must be TRUE):

1. `guides/operations/incident_playbook.md` tool/surface table includes `/relyra/admin/connections/:id/trace` and `mix relyra.trace --connection ID --last N` with when-to-use notes tied to at least two of the six playbook scenarios.
2. Cross-links from Getting Started Day-2 or `guides/overview.md` point to the updated playbook section.
3. `mix ci.docs` stays green.

**Plans:** 2/2 plans complete

### Phase 49: Adoption honesty — CONFORMANCE, jtbd map, preset taxonomy

**Goal:** External-facing honesty catches up to shipped code — CONFORMANCE records the done-enough boundary, the conformance manifest reflects ENC-01, internal planning docs stop claiming missing features, and preset taxonomy is consistent across README, Getting Started, and the generic SAML runbook.
**Depends on:** Phases 47-48 (soft — can run in parallel if doc authors coordinate).
**Requirements:** ADOPT-04, ADOPT-05, ADOPT-06
**Success Criteria** (what must be TRUE):

1. `CONFORMANCE.md` contains a **"Scope boundary & diminishing returns"** section with explicit out-of-scope list; `priv/conformance/sp_manifest.json` no longer marks encrypted assertions as deferred when ENC-01 is shipped.
2. `docs/jtbd_gap_map.md` reflects v1.5 shipped state (incident playbook, generic runbook, login trace, ENC, SLO) with no stale "missing" rows for shipped features.
3. README, Getting Started §4 (or equivalent), and `guides/recipes/generic_saml.md` agree on preset taxonomy — Keycloak/OneLogin either appear in the decoder table or are removed from over-broad README claims.
4. `mix ci.conformance` (or equivalent manifest gate) stays green with the updated ENC row.

**Plans:** 3/3 plans complete

### Phase 49.1: Close v1.6 audit doc handoff gaps (INSERTED)

**Goal:** Close the integration and E2E flow gaps identified in `.planning/v1.6-MILESTONE-AUDIT.md` — adopters following `production_ecto_path.md` should forward-navigate to Day-2 ops without backtracking via Getting Started §5 or overview.
**Depends on:** Phase 49
**Requirements:** ADOPT-01, ADOPT-02, ADOPT-03 (integration polish — requirements satisfied; handoff incomplete)
**Gap Closure:** Closes gaps from audit
**Success Criteria** (what must be TRUE):

1. `guides/production_ecto_path.md` ends with a **Related Day-2 guides** footer linking to incident playbook `#evidence-surfaces`, troubleshooting, and overview.
2. README step 3 promotes TestSupport (aligned with Getting Started §3); `guides/jtbd_user_flows.md` Related docs includes `production_ecto_path.md` and incident playbook links.
3. Getting Started §5 incident playbook link uses `#evidence-surfaces` anchor (parity with overview Day-2).
4. `mix ci.docs` stays green.

**Plans:** 4/4 plans complete

### Phase 49.2: v1.6 Nyquist retro + editorial polish (INSERTED)

**Goal:** Bring Nyquist compliance to full for v1.6 and address optional editorial tech debt from the milestone audit.
**Depends on:** Phase 49.1 (soft — can run after handoff lands)
**Requirements:** None (process + editorial polish)
**Gap Closure:** Closes gaps from audit
**Success Criteria** (what must be TRUE):

1. Phase 47 has retroactive `47-VALIDATION.md` (Nyquist parity with Phases 48-49).
2. Optional editorial skim completed or explicitly waived in VERIFICATION: playbook Scenarios 3–6 Diagnose prose; `jtbd_gap_map` persona tone; SiteMinder decoder row note.
3. `mix ci.docs` stays green if doc edits land.

**Plans:** 0/3 plans

## Progress

**Execution Order (v1.6):**
Phases execute in numeric order: 47 → 48 → 49 → 49.1 → 49.2. Phase 48 may overlap Phase 49 after Phase 47 lands.

**Execution Order (v1.5, shipped):**
Phases execute in numeric order: 41 → 42 → 43 → 44 → 45 → 46. Trace LiveView (Phase 42) now precedes publish prep (Phase 43), so the trace UI ships in the v1.4.0 Hex tarball by construction — no separate coordination required.

| Phase | Milestone | Plans | Status | Completed |
|-------|-----------|-------|--------|-----------|
| 01. XML security ADR + guardrails | v0.1 | 3/3 | Complete | 2026-04-25 |
| 02. Protocol + signature core | v0.1 | 5/5 | Complete | 2026-04-25 |
| 03. Behaviour contracts + stores | v0.1 | 3/3 | Complete | 2026-04-25 |
| 05. Observability + enforcement | v0.1 | 1/1 | Complete | 2026-04-25 |
| 06. Delivery hardening + adoption surface | v0.1 | 1/1 | Complete | 2026-04-25 |
| 07. Schema + connection aggregate | v0.2 | 3/3 | Complete | 2026-05-05 |
| 08. Resolver adapter + snapshotting | v0.2 | 3/3 | Complete | 2026-05-05 |
| 09. Metadata import/export + refresh | v0.2 | 4/4 | Complete | 2026-05-06 |
| 10. Certificate inventory + rollover | v0.2 | 3/3 | Complete | 2026-05-06 |
| 11. Mapping persistence + audit hardening | v0.2 | 4/4 | Complete | 2026-05-06 |
| 12. Metadata refresh trust-state repair | v0.2 | 3/3 | Complete | 2026-05-06 |
| 13. Certificate rollover validation + verification | v0.2 | 3/3 | Complete | 2026-05-06 |
| 14. Mapping/audit milestone verification | v0.2 | 2/2 | Complete | 2026-05-06 |
| 15. Admin shell + connection lifecycle | v0.3 | 3/3 | Complete | 2026-05-06 |
| 16. Metadata management UI | v0.3 | 3/3 | Complete | 2026-05-06 |
| 17. Certificate inventory + staged rollover UI | v0.3 | 2/2 | Complete | 2026-05-06 |
| 18. Mapping editor + audit timeline hardening | v0.3 | 2/2 | Complete | 2026-05-06 |
| 19. IdP-initiated SSO | v0.4 | 3/3 | Complete | 2026-05-06 |
| 20. Bulk operations across connections | v0.5 | 2/2 | Complete | 2026-05-06 |
| 21. Scheduled metadata refresh | v0.5 | 7/7 | Complete | 2026-05-07 |
| 22. Certificate expiry alerts | v0.6 | 1/1 | Complete | 2026-05-07 |
| 23. Diagnostic bundles | v0.6 | 2/2 | Complete | 2026-05-07 |
| 24. Single Logout Protocol | v0.6 | 3/3 | Complete | 2026-05-07 |
| 25. Conformance and CVE Regression Fixtures | v1.0 | 3/3 | Complete | 2026-05-07 |
| 26. Security Audit Preparation and Remediation | v1.0 | 3/3 | Complete | 2026-05-08 |
| 27. Adopter Onboarding Polish and Case Studies | v1.0 | 3/3 | Complete | 2026-05-08 |
| 28. Real C14N parser foundation | v1.1 | 4/4 | Complete | 2026-05-24 |
| 29. Cryptographic XMLDSig verification | v1.1 | 5/5 | Complete | 2026-05-24 |
| 30. Adversarial crypto assurance | v1.1 | 4/4 | Complete | 2026-05-24 |
| 31. Disclosure and docs honesty | v1.1 | 2/2 | Complete | 2026-05-24 |
| 32. AlgorithmPolicy Extension + Schema Migrations | v1.3 | 2/2 | Complete | 2026-05-25 |
| 33. KeyResolver Behaviour + XMLEnc Crypto Core | v1.3 | 2/2 | Complete | 2026-05-25 |
| 34. ValidationPipeline Wiring + ENC-01 Complete | v1.3 | 4/4 | Complete | 2026-05-25 |
| 35. Signed AuthnRequests + ADFS Preset | v1.3 | 9/9 | Complete | 2026-05-26 |
| 36. Generic SAML Runbook | v1.3 | 2/2 | Complete | 2026-05-26 |
| 37. Identity Mapping and Provisioning Guide | v1.3 | 2/2 | Complete | 2026-05-26 |
| 38. Single Logout (SLO) Core & Security | v1.4 | 4/4 | Complete | 2026-05-27 |
| 39. Logout Strategy & Operational Guidance | v1.4 | 1/1 | Complete | 2026-05-27 |
| 40. Operational Polish & Error Taxonomy | v1.4 | 2/2 | Complete | 2026-05-27 |
| 40.1. Close v1.4 audit gaps (INSERTED) | v1.4 | 5/5 | Complete | 2026-05-27 |
| 41. Pre-publish hygiene — Tech-debt sweep & security hardening | v1.5 | 5/5 | Complete    | 2026-05-27 |
| 42. Stepwise login-trace LiveView | v1.5 | 4/4 | Complete    | 2026-05-27 |
| 43. Hex publish prep — version bump & CHANGELOG backfill | v1.5 | 1/1 | Complete    | 2026-05-27 |
| 44. Release-please pipeline diagnosis & v1.4.0 Hex publish | v1.5 | 3/3 | Complete    | 2026-05-27 |
| 45. Post-publish parity verification | v1.5 | 2/2 | Complete    | 2026-05-27 |
| 46. Adopter DX & ergonomics | v1.5 | 3/3 | Complete    | 2026-05-27 |
| 47. Onboarding truth — Getting Started & production Ecto path | v1.6 | 3/3 | Complete    | 2026-05-27 |
| 48. Operator completeness — incident playbook trace tools | v1.6 | 2/2 | Complete    | 2026-05-27 |
| 49. Adoption honesty — CONFORMANCE, jtbd map, preset taxonomy | v1.6 | 3/3 | Complete    | 2026-05-27 |
| 49.1. Close v1.6 audit doc handoff gaps (INSERTED) | v1.6 | 4/4 | Complete    | 2026-05-27 |
| 49.2. v1.6 Nyquist retro + editorial polish (INSERTED) | v1.6 | 0/3 | Pending | — |

---
