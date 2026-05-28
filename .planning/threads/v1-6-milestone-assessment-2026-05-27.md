# Investigation: Post-v1.5 Milestone Assessment — "Done enough? What's next?"

Status: COMPLETE — assessment 2026-05-27; v1.6 Adoption Truth shipped 2026-05-28 per user choice via `/gsd-new-milestone`
Last assessed: 2026-05-28 (superseded by `v1-7-milestone-assessment-2026-05-28.md` for routing)
Priority: HIGH (milestone routing decision)
Depends: v1.5 shipped (Phases 41-46, Hex 1.4.0 live)

## Trigger

Adopter-first milestone-next assessment at v1.5 close. v1.5 closed the publish-and-polish gap (Hex 1.4.0, login-trace LiveView, tech-debt sweep, adopter DX). The question is no longer "what protocol is missing" but "is the library done enough for its stated scope, and if not, what single wedge remains?"

## Done-% verdict

**~92–95% (band: near-done / diminishing returns soon)**

| Rubric | Score | Notes |
|--------|-------|-------|
| Core JTBD coverage | 95% | SP-initiated, IdP-initiated, encrypted assertions, redirect-signed AuthnRequests, SLO, multi-tenant config — all in code |
| Breadth vs category | 90% | 4 presets + generic runbook; matches/exceeds Elixir peers on security |
| Docs / onboarding | 85% | Excellent routing; gap between "scaffold compiles" and "browser login works" |
| Operator / diagnostic | 90% | LiveAdmin, trace, diagnostics, incident playbook — trace under-documented in ops table |
| Proof / CI honesty | 95% | Adversarial corpus permanent; minor CONFORMANCE manifest drift on ENC |

## Recommended default: Pause

**Rational next move:** Wait for external demand signal (GitHub issue, adopter request). All three demand-gated protocol candidates remain **save-for-demand** with zero adopter pull at v1.5 close.

Building AUTHN-POST / KMS / SIGNED-META without signal = coverage-gating, which PROJECT.md explicitly rejected at the v1.x done-enough line.

## Optional alternative: v1.6 "Adoption Truth & Operator Completeness"

If maintaining momentum without new protocol (~1 week, doc-only milestone):

1. Getting Started: link `test/test_support_demo_test.exs` pattern (`setup_saml_connection/2`, `post_saml_response/2`) instead of low-level FakeIdP snippet
2. New "Production Ecto path" section: migrations, `ConnectionResolver.Ecto`, ETS→Ecto store swap, prod replay store warning
3. Ops doc: add login trace route + `mix relyra.trace` to `guides/operations/incident_playbook.md` tool table
4. CONFORMANCE: add "Scope boundary & diminishing returns" section; fix `sp-encrypted-assertions-deferred` → pass in manifest (ENC-01 shipped Phase 34)
5. Refresh `docs/jtbd_gap_map.md` to v1.5 reality
6. Resolve README/Getting Started preset taxonomy; add Keycloak/OneLogin decoder rows OR narrow README claim

**Not in scope:** new protocol bindings, new presets, KMS.

## Demand-gated candidates (unchanged verdict: save-for-demand)

| ID | Verdict | Trigger | Investigation |
|----|---------|---------|---------------|
| AUTHN-POST-01 | Save-for-demand | IdP rejects redirect-signed AuthnRequests | `signed-authn-requests-investigation.md` (POST deferral valid; redirect shipped Phase 35) |
| KMS-01 | Save-for-demand | Enterprise blocked on SP key custody | `encrypted-assertions-investigation.md` (KMS extension guidance) |
| SIGNED-META-01 | Save-for-demand | InCommon / academic federation requirement | `signed-sp-metadata-investigation.md` (new stub; no plan count until triggered) |

Collective shipping estimate when triggered: ~2–3 weeks (unchanged from v1.5 assessment).

## Planning doc drift flagged

| Issue | Evidence |
|-------|----------|
| CONFORMANCE.md marks encrypted assertions **deferred** | ENC-01 shipped Phase 34; `priv/conformance/sp_manifest.json` stale |
| `docs/jtbd_gap_map.md` stale (2026-05-23) | Says no incident playbook, no generic runbook — all shipped v1.3/v1.4 |
| README claims 7 generic IdP families | Keycloak and OneLogin named but not in `generic_saml.md` decoder table |
| Getting Started vs README preset count | README: 4 first-class; Getting Started §4: 3 batteries-included + ADFS special |
| `.planning/REQUIREMENTS.md` missing | Active reqs in `.planning/milestones/v1.5-REQUIREMENTS.md` |
| SIGNED-META "pre-baked plan" claim | Only investigation stub exists until triggered |

## Graduation candidates (cross-phase patterns)

- **CONFORMANCE generator must track shipped features** — ENC-01 vs deferred row is a new graduation candidate
- **Adoption Truth != feature milestone** — doc-only wedge at done-enough line is a reusable pattern for demand-gated libs

## Explicitly NOT recommended

- More provider presets (generic runbook covers them)
- HTTP-Artifact, ECP, Attribute Query, SCIM-in-core
- Full standalone demo app
- Customer IT self-serve portal (host-app territory)

## Cross-references

- `.planning/threads/v1-5-polish-milestone-assessment-2026-05-27.md` — COMPLETE (v1.5 shipped)
- `.planning/threads/signed-authn-requests-investigation.md` — PARTIAL (redirect shipped)
- `.planning/threads/encrypted-assertions-investigation.md` — PARTIAL (ENC-01 shipped)
- `.planning/threads/signed-sp-metadata-investigation.md` — OPEN (stub only)
- `.planning/PROJECT.md` — Next Milestone Goals + Key Decisions
- `.planning/STATE.md` — Assessment 2026-05-27 post-v1.5 block

## Verdict

**Honest answer: nothing major is missing for the stated scope.** Pause is the rational default. Optional v1.6 Adoption Truth closes doc/onboarding asymmetry (code stronger than onboarding story; README slightly over-promises generic coverage) without adding SAML surface area.
