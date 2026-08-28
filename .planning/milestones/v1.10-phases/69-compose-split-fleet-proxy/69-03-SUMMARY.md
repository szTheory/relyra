---
phase: 69-compose-split-fleet-proxy
plan: 03
subsystem: docker-fleet-verification-and-ci
tags: [docker-compose, traefik, playwright, github-actions, branch-protection]
dependency_graph:
  requires: [69-01-solo-compose-runtime-policy, 69-02-shared-fleet-proxy]
  provides: [hermetic-fleet-e2e, required-fleet-ci-gate, rulestead-main-canary]
  affects: [release-please, branch-protection, phase-69-verification]
tech_stack:
  added: [traefik/whoami:v1.12.0]
  patterns: [hermetic-required-gate, moving-upstream-scheduled-canary, semantic-liveview-browser-contract]
key_files:
  created:
    - scripts/test_fleet_proxy_e2e.sh
    - .github/workflows/fleet-proxy-e2e.yml
    - test/browser/fleet_proxy.spec.mjs
    - test/release/fleet_proxy_ci_integrity_test.exs
  modified:
    - scripts/setup_branch_protection.sh
    - demo/ledger_loop/lib/ledger_loop_web/endpoint.ex
    - demo/ledger_loop/priv/static/assets/js/app.js
decisions:
  - "The hermetic sibling is the required merge proof; moving Rulestead main is a scheduled non-required canary."
  - "Browser verification uses semantic LiveView and native input-affordance assertions rather than pixel snapshots."
requirements-completed: [FLEET-01, FLEET-02, FLEET-03]
coverage:
  - id: D1
    description: "One hermetic command proves solo health/ports/persistence, shared proxy idempotency, sibling coexistence, and isolated shutdown."
    requirement: FLEET-01
    verification:
      - kind: e2e
        ref: "npm run demo:fleet-proxy"
        status: pass
    human_judgment: false
  - id: D2
    description: "Chromium proves a real LiveView WebSocket roundtrip and usable public endpoint URLs at both supported origins."
    requirement: FLEET-03
    verification:
      - kind: automated_ui
        ref: "test/browser/fleet_proxy.spec.mjs#setup LiveView stays connected and exposes usable public URLs"
        status: pass
    human_judgment: false
  - id: D3
    description: "The unfiltered fleet-proxy-e2e job is synchronized across branch protection, release automation, and planning-only PR handling."
    requirement: FLEET-02
    verification:
      - kind: integration
        ref: "test/release/fleet_proxy_ci_integrity_test.exs#all required-check consumers stay synchronized"
        status: pass
      - kind: other
        ref: "actionlint .github/workflows/fleet-proxy-e2e.yml"
        status: pass
    human_judgment: false
  - id: D4
    description: "A daily Rulestead main canary monitors real cross-project proxy coexistence without coupling pull requests to upstream movement."
    requirement: FLEET-02
    verification:
      - kind: integration
        ref: "test/release/fleet_proxy_ci_integrity_test.exs#required fleet workflow cannot be skipped and retains its scheduled canary"
        status: pass
      - kind: other
        ref: "bash -n scripts/test_rulestead_proxy_canary.sh"
        status: pass
    human_judgment: false
metrics:
  duration: 17m
  completed_date: 2026-08-26
  tasks_completed: 2
  tasks_total: 2
status: complete
---

# Phase 69 Plan 03: Automated Fleet Verification Summary

Converted every remaining Phase 69 Docker/browser receipt into a deterministic required gate and added a separate moving-upstream canary for recurring fleet value.

## Tasks Completed

1. **Build the hermetic fleet lifecycle and LiveView browser proof**
   - Added a pinned `traefik/whoami:v1.12.0` sibling, lifecycle harness, and semantic Playwright coverage for solo and fleet origins.
   - Proved app/database health, loopback-only ingress, absent database publication, named-volume persistence, proxy idempotency, concurrent routes, and sibling survival after Relyra shutdown.
   - The tracer exposed a real missing client seam: the demo rendered LiveView HTML but loaded no Phoenix/LiveView browser client. Added dependency-served vendor assets and the standard CSRF-backed `LiveSocket` connection without changing visual design.
   - Commit: `3dfb014`

2. **Enforce the gate in CI and preserve a real-project canary**
   - Added the unfiltered `fleet-proxy-e2e` PR/main job and the scheduled/manual Rulestead main canary.
   - Synchronized branch protection, Release Please checks/automerge, and planning-only PR handling with the exact new context.
   - Added a static ExUnit drift guard and validated changed workflows with `actionlint` and `yamllint`.
   - Commit: `f06034a`

## Verification

- `npm run demo:fleet-proxy` passed: two Playwright origins, two solo boots, persistent volume sentinel, stable proxy container identity, concurrent routes, and isolated Relyra shutdown.
- `mix test test/release/fleet_proxy_ci_integrity_test.exs --warnings-as-errors` passed with 3 tests.
- `actionlint` and `yamllint` passed for the changed workflows; both canary scripts passed `bash -n`.
- The local Rulestead canary dry run reached the actual upstream Docker build, then Docker Desktop exhausted its local image-cache disk before backend startup. The scheduled canary remains intentionally non-required; the hermetic required proof is independent and passed.
- The full repository command reached the dependency audit after `mix qa`, the full warning-as-error suite, and all preceding security suites passed, then stopped on newly reported advisories for the pre-existing `mint 1.8.0` and `req 0.5.18` lockfile entries. That dependency upgrade is recorded as a project blocker outside this Docker-only phase rather than hidden or folded into its scope.

## Deviations from Plan

### [Rule 2 - Missing Critical] Connect the existing demo LiveView client

- **Found during:** Task 1 browser tracer.
- **Issue:** `/setup/sso` rendered LiveView markup but never loaded Phoenix/LiveView client scripts, so no WebSocket opened and `phx-click` was inert.
- **Fix:** Serve the pinned dependency clients under explicit vendor paths and connect `LiveSocket` with the page CSRF token.
- **Files:** `demo/ledger_loop/lib/ledger_loop_web/endpoint.ex`, root layout, and `priv/static/assets/js/app.js`.
- **Verification:** The same Playwright test observed `/live/websocket` and completed a server-side step transition at both public origins.

**Total deviations:** 1 auto-fixed missing-critical defect. **Impact:** restored behavior the original Phase 69 truth already required; no visual, public API, protocol, or Relyra security-library change.

## Known Stubs

None.

## Self-Check: PASSED

- Both task commits exist and all declared key files are present.
- Coverage metadata classifies every deliverable with non-empty passing automation and `human_judgment: false`.
- No root `lib/`, public API, protocol, algorithm policy, key handling, or Hex package surface changed.
