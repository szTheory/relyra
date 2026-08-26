---
gsd_state_version: 1.0
milestone: v1.10
milestone_name: Phases
current_phase: 70
current_phase_name: keycloak-behind-the-proxy
status: executing
stopped_at: Completed 70-01-PLAN.md
last_updated: "2026-08-26T16:39:21.339Z"
last_activity: 2026-08-26
last_activity_desc: Phase 70 execution started
progress:
  total_phases: 3
  completed_phases: 2
  total_plans: 10
  completed_plans: 6
  percent: 60
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-06-19)

**Core value:** Every SAML login ends in a verified trust path or a typed rejection — never a silent compromise. Trust mutations are durable, attributable, and reviewable.
**Current focus:** Phase 70 — keycloak-behind-the-proxy

## Current Position

Phase: 70 (keycloak-behind-the-proxy) — EXECUTING
Plan: 2 of 5
Status: Ready to execute
Last activity: 2026-08-26 — Phase 70 execution started

## Performance Metrics

- Last shipped milestone: v1.9 Loose Ends & Adoption Honesty (Phases 64-67, 15/15 requirements, archived 2026-06-19)
- Highest shipped phase: 67
- Current milestone: v1.10 Docker DX & Fleet Proxy (Phases 68-72)
- Previous milestone: v1.8 Brand System & Identity (Phases 58-63)
- v1.9 phase progress: 4/4 phases complete, 13/13 plans complete
- v1.9 audit status: `tech_debt` for non-blocking validation metadata cleanup; 15/15 requirements satisfied
- Phase 64 Plan 01 completed in 8min (2 tasks, 5 files)
- Phase 64 Plan 02 completed in 8min (2 tasks, 5 files)
- Phase 64 Plan 03 completed in 5min (2 tasks, 4 files)
- Phase 64 Plan 04 completed in 3min (2 tasks, 2 files)
- Phase 66 Plan 01 completed in 9min (3 tasks, 1 file)
- Phase 66 Plan 02 completed in 8min (1 task, 4 planning files; decision checkpoint)
- Phase 66 Plan 04 completed in 3min (2 tasks, 3 files; retained FakeIdP documentation; SEED-003 resolved)
- Phase 67 completed 2026-06-19 (4/4 plans; MAINT-01..MAINT-03 verified; CVE backfill and seed cleanup reconciled)

**Per-Plan Metrics:**

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 69-compose-split-fleet-proxy P01 | 24m | 2 tasks | 4 files |
| Phase 69 P02 | 42m | 2 tasks | 2 files |
| Phase 69 P03 | 17m | 2 tasks | 21 files |
| Phase 70 P01 | 9min | 1 tasks | 10 files |

## Accumulated Context

### Decisions

- v1.10 is demo + docker + docs ONLY — zero changes to lib/ security seams, public API, behaviour callbacks, protocol surface, or the Hex package whitelist (`mix.exs` package.files). Nothing new ships in the tarball.
- v1.10 locked decisions: simple `relyra.localhost` hostname (static `COMPOSE_PROJECT_NAME=relyra`, single checkout at a time, `RELYRA_HOST` override hook retained); scheme `http` (no mkcert); shared Traefik proxy on external `proxy` network per the `scoria` sibling-lib convention; Keycloak fully behind the proxy.
- v1.10 dependency chain: 68 (caching) → 69 (compose/proxy) → 70 (keycloak, needs proxy) → 71 (launcher, wraps the compose files) → 72 (docs, describes the finished surface).
- v1.10 phase→category map: 68=DKR-01..04, 69=FLEET-01..03, 70=KC-01, 71=DX-01..02, 72=DOC-01..02.
- v1.10 risks to respect: `*.localhost` is browser-only (never rely on it for curl/BEAM/psql); prefix Traefik router/service names `relyra-*`; bind host ports to `127.0.0.1`; keep proxy config out of the auto-loaded `docker-compose.override.yml`; use `KC_PROXY_HEADERS=xforwarded` (not deprecated `KC_PROXY=edge`).
- Brand voice source of truth for v1.10 docs: `brandbook/notes/decision-log.md` Canonical Lock Set (newest; supersedes `prompts/relyra-brand-book.md`).
- Demand-gated protocol scope is unchanged and still paused: AUTHN-POST-01, KMS-01, SIGNED-META-01.
- v1.9 resolved SEED-002, SEED-003, and narrow maintenance sync as bounded adoption-honesty cleanup; SEED-001 is historical v1.7 work, not a future candidate.
- [Phase ?]: curl added to Dockerfile.dev apk list to preserve existing demo_app healthcheck probe after removing inline apk install block
- [Phase ?]: Named volumes attach at nested demo paths — NOT generic /app/deps or /app/_build — ensuring macOS host artifacts never enter the Linux container (DKR-02, D-04)
- [Phase ?]: config :phoenix_live_reload backend: :fs_poll added as separate top-level block in dev.exs, NOT inside Endpoint live_reload: keyword which silently ignores backend: (DKR-04, D-10 corrected, Pitfall 1)
- [Phase ?]: Solo Compose auto-loads a loopback-only demo_app ingress while PostgreSQL remains internal.
- [Phase ?]: Phoenix public URL and LiveView origins derive from explicit runtime environment values outside test.
- [Phase ?]: Shared ingress remains neutral: dev_proxy on external proxy network; Relyra owns only relyra-local-demo labels.
- [Phase ?]: Fleet mode uses explicit base-plus-proxy Compose files, excluding the automatic solo port overlay.
- [Phase ?]: Keycloak trace proof uses the three persisted verifier steps; workspace return and LoginReceipt separately prove host mapping and session establishment.

### Blockers/Concerns

- The milestone-wide invariant (no `lib/`/API/protocol/Hex-whitelist change) is the primary guardrail; every phase plan must keep repo gates (`mix qa`, `mix ci.security`, `mix format --check-formatted`, `mix test --warnings-as-errors`) green by not touching `lib/`.
- Repository QA dependency audit currently fails on pre-existing mint 1.8.0 and req 0.5.18 advisories; upgrade in a dedicated security dependency change before push.

## Deferred Items

| Category | Item | Status |
|----------|------|--------|
| demand_gated | AUTHN-POST-01 | save-for-demand |
| demand_gated | KMS-01 | save-for-demand |
| demand_gated | SIGNED-META-01 | save-for-demand |
| verification | Phase 53 human-needed UI testing (demo Setup/Operator UX click-through) | deferred; run `/gsd:verify-work 53` |
| v1.10_future | TLS via mkcert for `*.relyra.localhost` | deferred; http suffices on localhost |
| v1.10_future | Hashed per-checkout instance hostnames (scoria-style) | deferred; simple `relyra.localhost` chosen |
| v1.10_future | Production multi-stage `mix release` Dockerfile | deferred; dev/demo DX only |
| brand_future | BRAND-F01 — animated/motion brand assets | deferred to future milestone |
| brand_future | BRAND-F02 — full 19-icon icon library | deferred to future milestone |
| Phase 68 P01 | 128 | 3 tasks | 3 files |
| Phase 68 P02 | 2m 26s | 2 tasks | 2 files |

## Session Continuity

**Stopped at:** Completed 70-01-PLAN.md
**Resume file:** None

Last session: 2026-08-26T16:39:21.332Z
Resume at: `/gsd-next`

## Operator Next Steps

- Merge PR #41 (demo Docker dev boot fixes) so Phase 68's code lands on main
- Plan the next phase with `/gsd-plan-phase 69` (or `/gsd-discuss-phase 69` first)
