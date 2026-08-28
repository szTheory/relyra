# Phase 71: Launcher DX & banner - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-08-26
**Phase:** 71-launcher-dx-banner
**Mode:** assumptions
**Areas analyzed:** Primary launcher and legacy delegation, Solo/fleet/reset topology, Banner and
route map, Fleet diagnostics and environment surface

## Assumptions Presented

### Primary Launcher and Legacy Delegation

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Add a repo-root Makefile as the canonical Docker interface while retaining all six `scripts/demo` verbs as thin Make delegations. | Confident | `.planning/ROADMAP.md`, `.planning/REQUIREMENTS.md`, `scripts/demo`, `test/docs/demo_guide_drift_test.exs` |

### Solo, Fleet, and Reset Topology

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Preserve bare Compose for solo mode and explicit base-plus-proxy files for fleet mode; keep Keycloak profile-gated. | Confident | `docker-compose.override.yml`, `docker-compose.proxy.yml`, `scripts/test_fleet_proxy_e2e.sh`, `scripts/test_keycloak_proxy_e2e.sh` |
| Keep `reset` and `reseed` as compatible aliases for the existing destructive demo-data refresh. | Likely | `scripts/demo`, `.planning/ROADMAP.md`, `/Users/jon/projects/scoria/Makefile` |

### Banner and Route Map Contract

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Derive displayed application paths from current router mounts without changing router/controller code or inventing endpoints. | Confident | `demo/ledger_loop/lib/ledger_loop_web/router.ex`, `demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_controller.ex`, `.planning/ROADMAP.md` |
| Always show the proxy URL plus a loopback fallback, labeling Keycloak/admin URLs as optional/fleet/browser-facing. | Likely | `docker-compose.override.yml`, `docker-compose.proxy.yml`, `docker/traefik/compose.yml`, fleet and Keycloak E2E scripts |

### Fleet Diagnostics and Environment Surface

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Discover the fleet through running containers with `traefik.enable=true`; check ports 4000/5432/8080 and the external proxy network with corrective diagnostics. | Confident | `.planning/REQUIREMENTS.md`, `scripts/demo`, `/Users/jon/projects/scoria/Makefile` |
| Add a commented `.env.example` for topology and optional credential overrides while preserving zero-config Compose defaults. | Likely | `.planning/phases/69-compose-split-fleet-proxy/69-CONTEXT.md`, `docker-compose.override.yml`, `docker-compose.proxy.yml` |

## Corrections Made

No corrections — all assumptions confirmed.
