# Phase 55: docker-ci-and-optional-keycloak-proof - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-12
**Phase:** 55-docker-ci-and-optional-keycloak-proof
**Mode:** assumptions
**Areas analyzed:** Docker Compose Orchestration, Demo CLI and Diagnostics, CI Isolation & FakeIdP Priority

## Assumptions Presented

### Docker Compose Orchestration
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| A new top-level `docker-compose.yml` will consolidate the demo app, Keycloak, and browser testing using Compose profiles, replacing or wrapping `docker/keycloak/docker-compose.yml`. | Likely | `ROADMAP.md` demands profiles; `demo/ledger_loop/mix.exs` exists; `docker/keycloak/docker-compose.yml` exists. |

### Demo CLI and Diagnostics
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `scripts/demo` will be implemented as a standalone Bash script rather than an Elixir Mix task or Makefile. | Likely | `ROADMAP.md` specifies `scripts/demo doctor`; existing `scripts/` folder uses Bash. |

### CI Isolation & FakeIdP Priority
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `mix ci.demo_app` will be added as a standalone alias in `mix.exs`, and Keycloak will remain strictly opt-in for baseline CI runs. | Confident | `ROADMAP.md` isolates Keycloak from deterministic proof; `mix.exs` existing gates. |

## Corrections Made

No corrections — all assumptions confirmed.
