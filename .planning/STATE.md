---
gsd_state_version: 1.0
milestone: v1.7
milestone_name: Adoption Evidence Demo
status: planning
last_updated: "2026-06-12T14:43:05Z"
last_activity: 2026-06-12 - Phase 51 context gathered (assumptions mode)
progress:
  total_phases: 6
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-06-12)

**Core value:** Every SAML login ends in a verified trust path or a typed rejection - never a silent compromise. Trust mutations are durable, attributable, and reviewable.
**Current focus:** v1.7 Adoption Evidence Demo - a realistic runnable Phoenix SaaS demo app proving Relyra setup, strict login, Ecto stores, operator diagnosis, Docker DX, browser evidence, and host-app boundaries.

## Current Position

Phase: 51 of 56 (Demo App Foundation)
Plan: -
Status: Context gathered / ready to plan
Last activity: 2026-06-12 - Phase 51 context gathered (assumptions mode)

Progress: [----------] 0%

## Performance Metrics

- Last shipped milestone: v1.6 Adoption Truth (Phases 47-49.2)
- Highest shipped phase: 50 (Adoption Evidence, 2026-05-29)
- Current milestone phases: 51-56
- Plans complete this milestone: 0/0 until Phase 51 planning creates plan count

## Accumulated Context

### Decisions

- v1.7 is adoption evidence infrastructure, not protocol expansion.
- Build a repo-local Phoenix app at `demo/ledger_loop` with Relyra as a path dependency and excluded from Hex packaging.
- Demo happy path must use Ecto connection, request, and replay stores; ETS is not acceptable for the v1.7 happy path.
- Customer/admin setup screens stay host-owned in LedgerLoop; Relyra LiveAdmin remains the operator trust cockpit.
- Local FakeIdP proof is default and dev/test-only; Keycloak is optional until burn-in justifies promotion.
- No hosted broker, production IdP, public API shape changes, default-tightening, or security relaxation.

### Active Requirements

30 v1.7 requirements mapped across Phase 51-56 in `.planning/REQUIREMENTS.md` and `.planning/ROADMAP.md`.

### Blockers/Concerns

None currently. Keycloak browser proof is intentionally optional because startup/readiness and browser-form flake risk are known.

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| demand_gated | AUTHN-POST-01 | save-for-demand |
| demand_gated | KMS-01 | save-for-demand |
| demand_gated | SIGNED-META-01 | save-for-demand |
| maintenance | CVE ID backfill into `docs/advisories/2026-001-...` | pending async |

## Session Continuity

Resume here: plan Phase 51 with `$gsd-plan-phase 51`.

Primary context:

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/phases/51-demo-app-foundation/51-CONTEXT.md`
- `.planning/phases/51-demo-app-foundation/51-UI-SPEC.md`
- `.planning/threads/adoption-evidence-demo-roadmap-2026-06-12.md`
- `.planning/seeds/SEED-001-adoption-evidence-demo.md`
