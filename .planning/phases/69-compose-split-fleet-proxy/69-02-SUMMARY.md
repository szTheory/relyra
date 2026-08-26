---
phase: 69-compose-split-fleet-proxy
plan: 02
subsystem: docker-fleet-proxy
tags: [docker-compose, traefik, fleet, phoenix, proxy]
dependency_graph:
  requires: [69-01-solo-compose-runtime-policy]
  provides: [neutral-shared-traefik, relyra-fleet-overlay]
  affects: [phase-70-keycloak-proxy, phase-71-launcher-dx, phase-72-documentation]
tech_stack:
  added: [traefik:v3.7.1]
  patterns: [external-network, explicit-router-service-binding, loopback-only-ingress]
key_files:
  created: [docker/traefik/compose.yml, docker-compose.proxy.yml]
  modified: []
decisions:
  - "Shared ingress remains neutral: the long-lived project is dev_proxy on external proxy network."
  - "Relyra joins the fleet only through static relyra-local-demo router and service labels."
metrics:
  duration: 42m
  completed_date: 2026-08-26
status: complete
coverage:
  - id: D1
    description: "The neutral shared Traefik proxy starts idempotently on the external proxy network with loopback-only ingress."
    requirement: FLEET-02
    verification:
      - kind: integration
        ref: "scripts/test_fleet_proxy_e2e.sh#shared proxy idempotency"
        status: pass
    human_judgment: false
  - id: D2
    description: "Relyra and a pinned sibling route concurrently, and stopping Relyra leaves the sibling, proxy, and external network operational."
    requirement: FLEET-02
    verification:
      - kind: e2e
        ref: "scripts/test_fleet_proxy_e2e.sh#fleet sibling coexistence and lifecycle isolation"
        status: pass
      - kind: automated_ui
        ref: "test/browser/fleet_proxy.spec.mjs#fleet LiveView public-origin contract"
        status: pass
    human_judgment: false
---

# Phase 69 Plan 02: Compose Split Fleet Proxy Summary

Added a reusable local Traefik fleet ingress and a no-host-port Relyra overlay that routes the unchanged LedgerLoop demo through `relyra.localhost`.

## Tasks Completed

1. **Create the neutral shared Traefik project**
   - Copied the maintained Scoria proxy convention verbatim: `dev_proxy`, pinned `traefik:v3.7.1`, loopback-only web/dashboard ports, read-only Docker socket, and external `proxy` network.
   - Verified rendered JSON and ran the idempotent network/proxy startup twice; the dashboard responded at `http://127.0.0.1:8080/dashboard/`.
   - Commit: `ea30f04`

2. **Route the Relyra participant through the shared proxy with no host ports**
   - Added proxy-host endpoint environment values, explicit namespaced Traefik labels, and app-only dual-network membership.
   - Verified rendered default and override configurations; Relyra and Rulestead routes coexisted, and stopping Relyra left the sibling route, `dev_proxy`, and external network alive.
   - Commit: `4af92f2`

## Verification

- Independent proxy and base+overlay JSON assertions passed, covering image pin, loopback publications, socket mode, external network, absent app/database host ports, app-only proxy membership, labels, and environment values.
- `docker compose -f docker/traefik/compose.yml up -d` reused the long-lived proxy and network on repeated runs.
- `docker compose -f docker-compose.yml -f docker-compose.proxy.yml up -d --wait` passed; an explicit `Host: relyra.localhost` request returned the LedgerLoop UI after startup convergence.
- Relyra and the maintained Rulestead sibling ran concurrently on `proxy`; both Host routes worked, and Rulestead remained reachable after the Relyra stack stopped.
- `mix qa`, `mix test --warnings-as-errors`, `mix ci.security`, and `mix format --check-formatted` passed.

## Decisions Made

- Shared ingress uses the neutral `dev_proxy` project identity; Relyra owns only its `relyra-local-demo` participant labels.
- Fleet mode requires explicit base-plus-proxy Compose files, intentionally excluding the automatic solo port overlay.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

- Both declared Compose files exist and both task commits are present in git history.
- No plan change touched `lib/`, fixtures, realm files, Keycloak configuration, Makefiles, environment examples, or documentation.
