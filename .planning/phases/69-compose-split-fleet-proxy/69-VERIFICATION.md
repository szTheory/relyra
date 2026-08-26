---
phase: 69-compose-split-fleet-proxy
verified: 2026-08-26T14:50:52Z
status: passed
score: 8/8 must-haves verified
behavior_unverified: 0
overrides_applied: 0
verification_mode: automated
human_verification: []
---

# Phase 69: Compose Split & Fleet Proxy Verification Report

**Phase Goal:** The solo demo remains zero-setup at localhost with no PostgreSQL host collision, while an opt-in neutral Traefik proxy lets sibling demos coexist at distinct localhost hosts without lifecycle interference.

**Status:** passed — fresh Docker, route, lifecycle, and Chromium evidence covers every former human receipt.

## Goal Achievement

| # | Observable truth | Status | Independent evidence |
|---|------------------|--------|----------------------|
| 1 | Plain Compose starts healthy db/app services and serves the loopback UI. | ✓ VERIFIED | `npm run demo:fleet-proxy` completed `up -d --build --wait` and loopback `/setup/sso` curl. |
| 2 | PostgreSQL has no host binding and the app has only `127.0.0.1:4000`. | ✓ VERIFIED | Rendered JSON plus live `docker port` assertions. |
| 3 | Named Mix state survives non-destructive down/up. | ✓ VERIFIED | Sentinel created in `/root/.mix`, volume inspected after down, sentinel found after restart. |
| 4 | Shared `dev_proxy` startup is idempotent and dashboard-accessible. | ✓ VERIFIED | Repeated Compose up retained the same Traefik container ID; dashboard curl passed. |
| 5 | Relyra and a sibling route concurrently without port contention. | ✓ VERIFIED | Pinned `traefik/whoami:v1.12.0` sibling and Relyra Host routes both returned success through port 80. |
| 6 | Stopping Relyra preserves the sibling, proxy, and external network. | ✓ VERIFIED | Post-down sibling curl passed; proxy remained running; network inspection passed. |
| 7 | Phoenix public URL/origin policy supports real LiveView at both origins. | ✓ VERIFIED | Playwright observed `/live/websocket` and a server-rendered step transition at solo and fleet origins. |
| 8 | Existing readonly endpoint URLs remain correct, selectable, and horizontally accessible at narrow width. | ✓ VERIFIED | Playwright asserted exact Metadata/ACS values, readonly state, full selection, and native horizontal scrolling at 360px. |

## CI and Drift Enforcement

- `.github/workflows/fleet-proxy-e2e.yml` runs the exact `fleet-proxy-e2e` job for every PR without path filters, on `main`, schedule, and manual dispatch.
- Branch-protection setup, Release Please checks/automerge, and planning-only PR handling all require the two security matrix contexts plus `fleet-proxy-e2e`.
- `test/release/fleet_proxy_ci_integrity_test.exs` passed 3/3 and fails on workflow/filter/context/canary/fixture drift.
- `actionlint` and `yamllint` passed for the changed workflows.

## Browser Defect Found and Closed

The first automated browser run correctly failed because the demo rendered LiveView markup without loading a Phoenix/LiveView client. The demo now serves its pinned dependency clients from explicit vendor paths and connects `LiveSocket` with the CSRF token. The unchanged browser test then passed at both public origins, proving the fix rather than bypassing the assertion.

## Scheduled Real-Project Canary

The daily non-required canary checks out `szTheory/rulestead@main`, starts both projects against `dev_proxy`, tests Relyra plus Rulestead backend/frontend routes, stops only Relyra, and retests Rulestead. A local dry run reached the real upstream build but Docker Desktop exhausted its local image-cache disk before backend startup; this host-capacity event does not weaken or replace the passing hermetic required gate.

## Repository Health Note

The full repository verification command progressed through `mix qa`, the full warning-as-error suite, and the Phase 69/security test processes before the dependency audit rejected existing `mint 1.8.0` and `req 0.5.18` versions based on newly available advisories. Phase 69 introduces no Elixir dependency or root library change; the required upgrade is tracked in `STATE.md` as an automated security blocker before push, not as a human-verification item.

## Requirements Coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| FLEET-01 | ✓ SATISFIED | Automated solo health, port, HTTP, and persistence lifecycle. |
| FLEET-02 | ✓ SATISFIED | Automated proxy idempotency, concurrent sibling routes, isolated shutdown, and required CI gate. |
| FLEET-03 | ✓ SATISFIED | Automated LiveView WebSocket, public URL, origin, and readonly URL interaction coverage at both hosts. |

## Human Verification

None required. `69-UAT.md` records 3/3 automated passes with zero pending checkpoints.

---

_Verified: 2026-08-26T14:50:52Z_  
_Verifier: Codex using fresh Docker/Playwright/ExUnit evidence_
