---
phase: 70-keycloak-behind-the-proxy
plan: "03"
subsystem: keycloak-proxy-e2e
tags: [docker-compose, keycloak, traefik, saml, diagnostics]
dependency_graph:
  requires: [70-01-keycloak-proxy-topology, 70-02-keycloak-provisioner]
  provides: [split-horizon-contract-checks, fresh-realm-lifecycle, redacted-layered-diagnostics]
  affects: [70-04-browser-proof, 70-05-phase-verification, phase-71-launcher]
tech_stack:
  added: []
  patterns: [dual-render-compose-contract, harness-owned-compose-project, redacted-layer-diagnostics]
key_files:
  created: []
  modified:
    - docker/keycloak/realm-demo-app.json
    - scripts/test_keycloak_proxy_e2e.sh
key_decisions:
  - "The realm web origin is explicit and derives from RELYRA_HOST, matching every public SAML endpoint."
  - "Each E2E run owns a reserved Compose project and removes only that project's volumes before Keycloak import."
  - "Failure artifacts contain only own-stack state, filtered logs, audit action names, and an explicit failing layer."
requirements_completed: [KC-01]
coverage:
  - id: D1
    description: "Static checks render both the default and overridden public-host contracts, rejecting direct Keycloak exposure and stale realm URLs."
    requirement: KC-01
    verification:
      - kind: integration
        ref: "KEYCLOAK_PROXY_STATIC_ONLY=1 bash scripts/test_keycloak_proxy_e2e.sh"
        status: pass
    human_judgment: false
  - id: D2
    description: "The harness redacts sensitive diagnostics and reports a forced Keycloak readiness failure by its named layer."
    requirement: KC-01
    verification:
      - kind: integration
        ref: "KEYCLOAK_PROXY_DIAGNOSTICS_SELF_TEST=1 bash scripts/test_keycloak_proxy_e2e.sh"
        status: pass
      - kind: integration
        ref: "KEYCLOAK_PROXY_FORCE_FAILURE=keycloak_readiness bash scripts/test_keycloak_proxy_e2e.sh 2>&1 | rg 'layer=keycloak_readiness'"
        status: pass
    human_judgment: false
metrics:
  duration: 6m
  completed_date: 2026-08-26
  tasks_completed: 2
  tasks_total: 2
status: complete
---

# Phase 70 Plan 03: Keycloak Proxy Contract Summary

**Keycloak's public SAML contract is now dual-rendered from one host input, fresh for every proof run, and diagnosable without retaining credential or assertion material.**

## Accomplishments

- Added default and `RELYRA_HOST=phase70.example.local` Compose/realm checks for proxy-only Keycloak networking, fixed hostname forwarding, private port `8080`, internal readiness `9000`, and exact public ACS/metadata values.
- Replaced the realm's permissive `webOrigins: ["+"]` value with the same explicit public origin used by its entity ID, metadata, redirect, and ACS fields.
- Made the E2E harness use a reserved, unique Compose project; it refuses an active standard Relyra stack and removes only harness-owned volumes before startup so stale realm imports cannot satisfy the proof.
- Added named failure layers, redacted own-stack diagnostics, a sensitive-data redaction self-test, and a deterministic forced-layer mode.

## Task Commits

1. **Task 1: Enforce the default and overridden split-horizon contract**
   - `8158ab1` `test(70-03): add failing Keycloak public-origin contract`
   - `959a1b1` `feat(70-03): verify Keycloak split-horizon renders`
2. **Task 2: Recreate realm state and classify lifecycle failures safely**
   - `0260a83` `test(70-03): add failing Keycloak diagnostics contract`
   - `00aa415` `feat(70-03): harden Keycloak proof lifecycle diagnostics`

## Verification

- Passed `bash -n scripts/test_keycloak_proxy_e2e.sh`.
- Passed `KEYCLOAK_PROXY_STATIC_ONLY=1 bash scripts/test_keycloak_proxy_e2e.sh` for default and override render paths without starting containers.
- Passed `KEYCLOAK_PROXY_DIAGNOSTICS_SELF_TEST=1 bash scripts/test_keycloak_proxy_e2e.sh`.
- Confirmed `KEYCLOAK_PROXY_FORCE_FAILURE=keycloak_readiness bash scripts/test_keycloak_proxy_e2e.sh 2>&1 | rg 'layer=keycloak_readiness'` emits the named redacted layer.
- Passed `npm run demo:keycloak-proxy`: a fresh harness-owned Keycloak realm provisioned, the public signed ACS Playwright journey passed, the durable receipt and canonical trace steps were confirmed, and only the harness stack was removed.

## Deviations from Plan

None - plan executed as written.

## Known Stubs

None.

## Self-Check: PASSED

- Both modified key files exist and all four RED/GREEN task commits are present.
- No `lib/relyra/**`, public API, protocol, crypto, or Hex package boundary changed.
- The explicitly listed unrelated staged and untracked files remain outside every Plan 70-03 commit.
