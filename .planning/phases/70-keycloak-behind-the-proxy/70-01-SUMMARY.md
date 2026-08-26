---
phase: 70-keycloak-behind-the-proxy
plan: "01"
subsystem: demo-infrastructure
tags: [keycloak, saml, traefik, docker-compose, playwright, phoenix]
requires:
  - phase: 69-compose-split-fleet-proxy
    provides: shared Traefik proxy, external proxy network, and proxy-host Phoenix runtime configuration
provides:
  - Optional Keycloak profile routed only through the shared Traefik edge
  - Audited descriptor-derived Keycloak signing trust and Sarah identity provisioning
  - Hermetic browser tracer for a signed scoped ACS, canonical verifier trace, workspace return, and durable receipt
affects: [70-02, 70-03, 70-04, 70-05, 71-launcher-dx]
tech-stack:
  added: []
  patterns: [profile-scoped one-shot provisioning, host-side Playwright proof, redacted Ecto verification]
key-files:
  created:
    - demo/ledger_loop/lib/ledger_loop/demo/keycloak_provisioner.ex
    - demo/ledger_loop/lib/mix/tasks/ledger_loop.provision_keycloak.ex
  modified:
    - docker-compose.yml
    - docker-compose.proxy.yml
    - scripts/test_keycloak_proxy_e2e.sh
    - demo/ledger_loop/test/browser/keycloak.spec.ts
key-decisions:
  - "The canonical Login Trace proves only protocol validation, signature verification, and replay checking; workspace return and LoginReceipt prove host mapping and session establishment separately."
  - "Keycloak remains an optional profile and reaches browsers only through Traefik; no Relyra library, public API, or security seam changed."
patterns-established:
  - "Provision real IdP demo trust from a container-local descriptor through Relyra's existing audited metadata and certificate seams."
  - "Use browser proof plus redacted container-side count/key assertions for a truthful end-to-end receipt."
requirements-completed: [KC-01]
coverage:
  - id: D1
    description: "Proxy-only Keycloak topology, descriptor-derived audited trust, and enabled Keycloak connection."
    requirement: KC-01
    verification:
      - kind: integration
        ref: "bash -n scripts/test_keycloak_proxy_e2e.sh && KEYCLOAK_PROXY_STATIC_ONLY=1 bash scripts/test_keycloak_proxy_e2e.sh"
        status: pass
    human_judgment: false
  - id: D2
    description: "Genuine Keycloak signed ACS reaches the public workspace and writes one durable LoginReceipt."
    requirement: KC-01
    verification:
      - kind: automated_ui
        ref: "demo/ledger_loop/test/browser/keycloak.spec.ts#Keycloak signs Sarah into LedgerLoop through the public scoped ACS"
        status: pass
      - kind: integration
        ref: "docker compose exec demo_app redacted receipt/trace assertion"
        status: pass
    human_judgment: false
  - id: D3
    description: "Canonical successful Login Trace contains exactly validation, signature verification, and replay checking."
    requirement: KC-01
    verification:
      - kind: integration
        ref: "docker compose exec demo_app redacted receipt/trace assertion"
        status: pass
    human_judgment: false
duration: 9min
completed: 2026-08-26
status: complete
---

# Phase 70 Plan 01: Keycloak Proxy Login Tracer Summary

**Optional Keycloak SAML profile routed through Traefik with descriptor-derived audited trust and a genuine signed browser login proof.**

## Performance

- **Duration:** 9 min continuation
- **Completed:** 2026-08-26T16:38:33Z
- **Tasks:** 1/1 (TDD RED and GREEN)
- **Files modified:** 10 production/demo files, plus RED test harness files

## Accomplishments

- Added a proxy-only Keycloak profile with its public identity fixed to `keycloak.relyra.localhost`; management stays private and Traefik targets only port 8080.
- Added an idempotent, profile-scoped provisioner that imports Keycloak descriptor trust through existing audited Relyra Ecto seams, activates signing trust, creates Sarah's host identity, and enables last.
- Added a hermetic Playwright tracer that observes the scoped ACS 302 and workspace return, then confirms one LoginReceipt and exactly the canonical `response.validate`, `signature.verify`, and `replay.check` keys through redacted container-side evidence.

## Task Commits

1. **Task 1 RED: Failing Keycloak proxy login tracer** — `98fa6cf` (test)
2. **Task 1 GREEN: Run one genuine signed Keycloak login through every Phase 70 layer** — `600f4c9` (feat)

## Files Created/Modified

- `docker-compose.yml` and `docker-compose.proxy.yml` — profile-scoped Keycloak, private health management port, Traefik routing, and one-shot provisioner.
- `docker/keycloak/realm-demo-app.json` — stable public metadata/ACS contract and non-admin Sarah persona.
- `demo/ledger_loop/lib/ledger_loop/demo/keycloak_provisioner.ex` — descriptor-to-audited-trust orchestration.
- `demo/ledger_loop/lib/mix/tasks/ledger_loop.provision_keycloak.ex` — bounded Keycloak profile bootstrap command.
- `scripts/test_keycloak_proxy_e2e.sh` and `demo/ledger_loop/test/browser/keycloak.spec.ts` — static graph, browser, receipt, and canonical trace proof.

## Decisions Made

- Preserved the v1.10 demo/Docker/docs-only boundary: no `lib/relyra/**`, public API, parser, crypto, replay, or behaviour seam changed.
- Kept response decoding, host mapping, and session establishment out of the canonical audit row; the lifecycle truth is three verifier steps, while workspace return and the LoginReceipt provide separate evidence.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected stale six-step trace expectation**
- **Found during:** Task 1
- **Issue:** The original harness demanded six trace steps although the persisted telemetry lifecycle records only validation, signature verification, and replay checking for this flow.
- **Fix:** Asserted the exact three canonical keys and one durable receipt; retained the Playwright workspace assertion as the separate host-mapping proof.
- **Files modified:** `scripts/test_keycloak_proxy_e2e.sh`
- **Verification:** Playwright passed and the redacted query reported one receipt with all and only the three expected keys.
- **Committed in:** `600f4c9`

**Total deviations:** 1 auto-fixed (Rule 1)
**Impact on plan:** The corrected contract preserves the locked demo-only scope and matches the telemetry lifecycle without weakening verification.

## Known Stubs

None.

## Issues Encountered

The execution runtime truncated the long wrapper lifecycle output. The same hermetic compose lifecycle was then run explicitly: provisioner exited 0, Playwright passed, and the redacted receipt/trace assertion passed.

## User Setup Required

None — the optional profile is fully local and uses test-only Keycloak credentials.

## Next Phase Readiness

Plans 70-02 through 70-05 can extend the profile's idempotency, diagnostic, UI, and regression coverage without changing the proven public topology or telemetry contract.

## Self-Check: PASSED

- RED commit `98fa6cf` and GREEN commit `600f4c9` exist.
- The Keycloak provisioner, Mix task, compose profile, browser test, and hermetic harness exist.
