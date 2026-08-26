---
phase: 69
slug: compose-split-fleet-proxy
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-16
updated: 2026-08-26
---

# Phase 69 — Validation Strategy

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Docker Compose lifecycle assertions, curl, Playwright/Chromium, ExUnit, actionlint |
| **Hermetic E2E** | `npm run demo:fleet-proxy` |
| **CI integrity** | `mix test test/release/fleet_proxy_ci_integrity_test.exs --warnings-as-errors` |
| **Full repository gates** | `mix qa && mix test --warnings-as-errors && mix ci.security && mix format --check-formatted` |
| **Required status context** | `fleet-proxy-e2e` |
| **Moving upstream monitor** | Daily `rulestead-main-canary` at 06:17 UTC; non-required |

## Automated Verification Map

| Behavior | Requirement | Test Type | Automated Evidence | Status |
|----------|-------------|-----------|--------------------|--------|
| Solo health, loopback ingress, no db publication, and persistent named volumes | FLEET-01 | integration | `scripts/test_fleet_proxy_e2e.sh` solo lifecycle | ✅ green |
| Explicit public URL/origin policy at localhost | FLEET-03 | automated UI | `fleet_proxy.spec.mjs` at `http://localhost:4000` | ✅ green |
| Neutral proxy starts idempotently with stable container identity | FLEET-02 | integration | shared proxy ID/dashboard assertions | ✅ green |
| Relyra and pinned sibling route concurrently without host-port contention | FLEET-02 | E2E | Host-route curl assertions through Traefik | ✅ green |
| Stopping Relyra preserves sibling, proxy, and external network | FLEET-02 | E2E | post-shutdown route/container/network assertions | ✅ green |
| Fleet LiveView WebSocket, public URLs, selection, and horizontal access | FLEET-03 | automated UI | `fleet_proxy.spec.mjs` at `http://relyra.localhost` | ✅ green |
| Required-check synchronization and unfiltered workflow trigger | FLEET-01..03 | integration/meta | `fleet_proxy_ci_integrity_test.exs`, actionlint, yamllint | ✅ green |
| Real Rulestead main coexistence drift | FLEET-02 | scheduled canary | `scripts/test_rulestead_proxy_canary.sh` | recurring monitor |

## Sampling and Failure Evidence

- The hermetic suite runs for every pull request, push to `main`, schedule, and manual dispatch. It has no path filters, so branch protection cannot leave it pending because of a skipped workflow.
- Playwright uses one worker, host-resolver rules, semantic DOM/LiveView assertions, and trace-on-first-retry.
- The shell harness captures Compose status, container logs, Traefik logs, sibling logs, and network inspection before cleanup on failure.
- The real Rulestead main canary is deliberately separate from branch protection because upstream movement is not hermetic.

## Manual-Only Verifications

None for Phase 69. Visual identity is unchanged, and every relevant interaction/layout claim is expressed as a semantic browser assertion rather than subjective screenshot approval.

## Validation Sign-Off

- [x] Every FLEET-01..03 runtime truth has deterministic integration or browser coverage.
- [x] Required workflow is unfiltered and enforced by exact context name.
- [x] Required-check consumers are protected by a static drift test.
- [x] Diagnostics are retained for CI failures.
- [x] Human UAT is not required for Phase 69 completion.
