# Phase 72: Documentation - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-08-27
**Phase:** 72-documentation
**Mode:** assumptions
**Areas analyzed:** Guide Journey and Topology, Commands/URL Map/Troubleshooting, Cache Model and
Recovery Guidance, Receipts/Honesty/Documentation Routing

## Assumptions Presented

### Guide Journey and Topology

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| `guides/docker_dev_dx.md` makes the Solo FakeIdP path the complete zero-to-login journey, with Fleet plus optional Keycloak as the second real-IdP path. | Confident | `.planning/phases/71-launcher-dx-banner/71-CONTEXT.md`, `Makefile`, `docker-compose.proxy.yml`, `demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_html/login.html.heex` |

### Commands, URL Map, and Troubleshooting

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Make is the primary Docker interface; `scripts/demo` is compatibility context; documentation preserves the browser-versus-service-DNS boundary. | Confident | `Makefile`, `scripts/demo`, `test/docs/demo_guide_drift_test.exs`, `docker-compose.override.yml`, `docker-compose.proxy.yml`, `docker/traefik/compose.yml` |

### Cache Model and Recovery Guidance

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| The guide explains bind-mounted source, named Linux artifact volumes, the lock-hash gate, and graduated recovery through doctor/down/reset/nuke. | Confident | `demo/ledger_loop/Dockerfile.dev`, `demo/ledger_loop/docker-entrypoint.sh`, `Makefile`, `/Users/jon/projects/scoria/docs/docker_dev_dx.md` |

### Receipts, Honesty, and Documentation Routing

| Assumption | Confidence | Evidence |
|------------|------------|----------|
| Proof lines distinguish Relyra verification from LedgerLoop's host-owned mapping/session receipt; all three routers point to the guide/Fleet path while Local Mix remains valid. | Confident | `demo/ledger_loop/lib/ledger_loop/relyra/session_adapter.ex`, `.planning/phases/70-keycloak-behind-the-proxy/70-CONTEXT.md`, `demo/ledger_loop/README.md`, `guides/demo.md`, `README.md`, `brandbook/notes/decision-log.md` |

## Corrections Made

No corrections — all assumptions confirmed.
