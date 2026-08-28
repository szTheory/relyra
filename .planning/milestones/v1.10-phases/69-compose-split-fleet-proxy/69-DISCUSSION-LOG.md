# Phase 69: Compose split & fleet proxy - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-19
**Phase:** 69-compose-split-fleet-proxy
**Mode:** assumptions
**Areas analyzed:** Compose split, Postgres port, Endpoint url/check_origin (FLEET-03), FakeIdP host-independence, Keycloak boundary, Shared Traefik proxy

## Assumptions Presented

### Compose split
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| 3 files: base loses ports, new auto-loaded override (solo 127.0.0.1:PORT:4000), new explicit proxy.yml (labels + proxy net, no ports) | Confident | rulestead/docker-compose.{override,proxy}.yml; roadmap 69 scope note |

### Postgres port
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Drop db ports entirely (base + override); reach via service `db` only | Confident | FLEET-01; docker-compose.yml `${PGPORT:-5432}:5432` |

### Endpoint url/check_origin (FLEET-03)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Env-driven url (PHX_HOST/SCHEME/PORT) + check_origin in runtime.exs dev-applicable block | Likely | runtime.exs prod-gated block; config.exs url host; rulestead proxy.yml env |

### FakeIdP host-independence
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Don't touch fixtures/realm; seeded acs_url + FakeIdP signer are self-consistent → recipient match host-independent | Confident | fixtures.ex:59; fake_idp_controller.ex:33-34,79 |

### Keycloak boundary
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| proxy.yml routes only demo_app; Keycloak labels/env/realm = Phase 70 | Confident | roadmap Phase 70 scope note |

### Shared Traefik proxy
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| docker/traefik/compose.yml = scoria verbatim (name dev_proxy, traefik:v3.7.1, 127.0.0.1 binds, proxy external); make proxy target deferred to 71 | Confident | scoria/docker/traefik/compose.yml; roadmap 69 scope (no Makefile) |

## Corrections Made

No corrections — both open choices were confirmed in line with the recommendation:

### check_origin strictness
- **Original assumption:** env-driven allowlist (`//localhost`, `//relyra.localhost`, `//*.relyra.localhost`).
- **User decision:** Env-driven allowlist (confirmed over keeping `check_origin: false`).
- **Reason:** matches north-star "correct" intent; explicit rather than wide-open.

### `make proxy` vs Phase 71 Makefile boundary
- **Original assumption:** ship proxy compose + network plumbing now; `make proxy` wrapper in Phase 71; verify Phase 69 via raw commands.
- **User decision:** Raw commands now, `make proxy` in 71 (confirmed over pulling a minimal Makefile into 69).
- **Reason:** keeps phase boundaries clean.

## External Research

None — codebase + sibling-repo conventions (scoria/rulestead/sigra) provided sufficient evidence.
