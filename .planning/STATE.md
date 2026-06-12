---
gsd_state_version: 1.0
milestone: v1.7
milestone_name: Adoption Evidence Demo
status: planning
last_updated: "2026-06-12T21:40:54.601Z"
last_activity: 2026-06-12 -- Phase 52 execution complete
progress:
  total_phases: 6
  completed_phases: 2
  total_plans: 14
  completed_plans: 13
  percent: 33
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-06-12)

**Core value:** Every SAML login ends in a verified trust path or a typed rejection - never a silent compromise. Trust mutations are durable, attributable, and reviewable.
**Current focus:** Phase 53 — TBD

## Current Position

Phase: 53
Plan: Not started
Status: Ready to plan
Last activity: 2026-06-12 -- Phase 52 execution complete

Progress: [█████████░] 93%

## Performance Metrics

- Last shipped milestone: v1.6 Adoption Truth (Phases 47-49.2)
- Highest shipped phase: 50 (Adoption Evidence, 2026-05-29)
- Current milestone phases: 51-56
- Phase progress this milestone: 2/6 phases complete
- Plans complete in Phase 51: 6/6
- Plans complete in Phase 52: 6/6

## Accumulated Context

### Decisions

- v1.7 is adoption evidence infrastructure, not protocol expansion.
- Build a repo-local Phoenix app at `demo/ledger_loop` with Relyra as a path dependency and excluded from Hex packaging.
- Demo happy path must use Ecto connection, request, and replay stores; ETS is not acceptable for the v1.7 happy path.
- Customer/admin setup screens stay host-owned in LedgerLoop; Relyra LiveAdmin remains the operator trust cockpit.
- Local FakeIdP proof is default and dev/test-only; Keycloak is optional until burn-in justifies promotion.
- No hosted broker, production IdP, public API shape changes, default-tightening, or security relaxation.
- LedgerLoop.Relyra.UserMapper uses SAMLIdentity to find a deterministic user and fetches LedgerLoop tenant/groups.
- LedgerLoop.Relyra.SessionAdapter establishes a host session by writing a deterministic LoginReceipt row and verifying explicitly what Relyra verified vs what LedgerLoop owns.

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
| Phase 51 P01 | 7 min | 1 tasks | 39 files |
| Phase 51 P02 | 5 min | 1 tasks | 3 files |
| Phase 51 P06 | 7 min | 2 tasks | 1 files |
| Phase 51 P03 | 5 min | 2 tasks | 5 files |
| Phase 51 P04 | 8 min | 2 tasks | 8 files |
| Phase 51 P05 | 12 min | 2 tasks | 4 files |
| Phase 52 P05 | 10 min | 2 tasks | 4 files |

## Session Continuity

Resume here: continue planning Phase 53 with `/gsd:plan-phase 53` when ready.

Primary context:

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/phases/52-ecto-stores-and-deterministic-seed-story/52-CONTEXT.md`
- `.planning/phases/52-ecto-stores-and-deterministic-seed-story/52-RESEARCH.md`
- `.planning/phases/52-ecto-stores-and-deterministic-seed-story/52-VALIDATION.md`
- `.planning/phases/52-ecto-stores-and-deterministic-seed-story/52-PATTERNS.md`
- `.planning/phases/52-ecto-stores-and-deterministic-seed-story/52-01-PLAN.md`
- `.planning/phases/52-ecto-stores-and-deterministic-seed-story/52-02-PLAN.md`
- `.planning/phases/52-ecto-stores-and-deterministic-seed-story/52-03-PLAN.md`
- `.planning/phases/52-ecto-stores-and-deterministic-seed-story/52-04-PLAN.md`
- `.planning/phases/52-ecto-stores-and-deterministic-seed-story/52-05-PLAN.md`
- `.planning/phases/52-ecto-stores-and-deterministic-seed-story/52-06-PLAN.md`
- `.planning/phases/51-demo-app-foundation/51-CONTEXT.md`
- `.planning/phases/51-demo-app-foundation/51-01-SUMMARY.md`
- `.planning/phases/51-demo-app-foundation/51-02-SUMMARY.md`
- `.planning/phases/51-demo-app-foundation/51-03-SUMMARY.md`
- `.planning/phases/51-demo-app-foundation/51-04-SUMMARY.md`
- `.planning/phases/51-demo-app-foundation/51-05-SUMMARY.md`
- `.planning/phases/51-demo-app-foundation/51-06-SUMMARY.md`
- `.planning/phases/51-demo-app-foundation/51-UI-SPEC.md`
- `.planning/threads/adoption-evidence-demo-roadmap-2026-06-12.md`
- `.planning/seeds/SEED-001-adoption-evidence-demo.md`

e-demo.md`
