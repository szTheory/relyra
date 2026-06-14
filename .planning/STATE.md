---
gsd_state_version: 1.0
milestone: v1.7
milestone_name: Adoption Evidence Demo
status: executing
last_updated: "2026-06-14T00:56:44Z"
last_activity: 2026-06-14 -- Phase 57 Plan 02 complete (FakeIdP Signer — genuine SAML signing via relyra C14N)
progress:
  total_phases: 1
  completed_phases: 0
  total_plans: 3
  completed_plans: 2
  percent: 0
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-06-12)

**Core value:** Every SAML login ends in a verified trust path or a typed rejection - never a silent compromise. Trust mutations are durable, attributable, and reviewable.
**Current focus:** Phase 57 — demo-fakeidp-browser-login-proof

## Current Position

Phase: 57 (demo-fakeidp-browser-login-proof) — EXECUTING
Plan: 3 of 3
Status: Executing Phase 57 Plan 03
Last activity: 2026-06-14

## Performance Metrics

- Last shipped milestone: v1.6 Adoption Truth (Phases 47-49.2)
- Highest shipped phase: 50 (Adoption Evidence, 2026-05-29)
- Current milestone phases: 51-56
- Phase progress this milestone: 3/6 phases complete
- Plans complete in Phase 51: 6/6
- Plans complete in Phase 52: 6/6
- Plans complete in Phase 53: 3/3

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
- [Phase 57-01]: Fixture cert PEM sourced at compile time from Keypair.cert_pem/0 via module attribute to prevent fixture/signer cert drift (T-57-04)
- [Phase 57-01]: LoginTrace.attach placed after Supervisor.start_link (not as supervised child); {:error, :already_exists} ignored for idempotency
- [Phase 57-02]: Vendored 4-step XmldsigSigner technique in demo Signer — copies shape, calls relyra PUBLIC C14N (PureBeam.canonicalize + C14N.serialize); no Relyra.TestSupport runtime refs
- [Phase 57-02]: tamper/1 targets Assertion NameID (not Response-level Issuer) to land :digest_mismatch at the crypto gate, not :issuer_mismatch at protocol validation
- [Phase 57-02]: assertion_id generated per-call via System.unique_integer/1 (Pitfall 6 replay guard)
- [Phase ?]: Demo group in groups_for_extras uses a dedicated Demo entry rather than appending to Day-1 to keep the Day-1 spine uncluttered
- [Phase ?]: D-02c implemented: relative-link-outside-package CI gate converts silent disk-pass/hexdocs-404 gap into a CI failure
- [Phase ?]: D-05 runtime extraction in demo guide drift gate
- [Phase ?]: D-11 lane selection for demo guide drift gate

### Active Requirements

30 v1.7 requirements mapped across Phase 51-56 in `.planning/REQUIREMENTS.md` and `.planning/ROADMAP.md`.

### Blockers/Concerns

None currently. Keycloak browser proof is intentionally optional because startup/readiness and browser-form flake risk are known.

### Roadmap Evolution

- Phase 57 added (2026-06-13): Demo FakeIdP Browser-Login Proof — standalone MVP phase outside archived v1.7, finishing SEED-003 option (b) with a demo-local SAML signer. Parked WIP on branch `wip/demo-fake-idp`.

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| demand_gated | AUTHN-POST-01 | save-for-demand |
| demand_gated | KMS-01 | save-for-demand |
| demand_gated | SIGNED-META-01 | save-for-demand |
| maintenance | CVE ID backfill into `docs/advisories/2026-001-...` | pending async |
| verification | Phase 53 (`53-VERIFICATION.md`) human-needed UI testing — demo Setup/Operator UX click-through | deferred at v1.7 close; run `/gsd:verify-work 53` |

## Session Continuity

Resume here: execute Phase 57 Plan 03 (FakeIdP controller + browser flow) with `/gsd:execute-phase 57-03`.

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

## Operator Next Steps

- Start the next milestone with /gsd-new-milestone
