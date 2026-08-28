---
phase: 71-launcher-dx-banner
plan: "02"
subsystem: developer-experience
tags: [make, docker, diagnostics, playwright, ci]
requires:
  - phase: 71-launcher-dx-banner
    plan: "01"
    provides: canonical Make surface and runtime fixture seam
provides:
  - global Traefik-labelled fleet inventory with explicit error and empty states
  - grouped doctor for Docker, Compose, ports, and proxy network
  - idempotent proxy lifecycle and portable browser opener fallback
affects: [phase-72-documentation, fleet-proxy, keycloak-demo]
tech-stack:
  added: []
  patterns: [PATH-isolated CLI fixtures, independent diagnostic status accumulation]
key-files:
  created: []
  modified: [Makefile, test/docs/demo_guide_drift_test.exs, CLAUDE.md]
key-decisions:
  - "Fleet normalizes missing fields and sorts bytewise by project then container name without project filtering."
  - "Doctor continues all checks, makes port 5432 explicitly diagnostic, and exits nonzero only for blocking/unavailable launcher checks."
patterns-established:
  - "Host-specific opener and port states are simulated in CI; they never require workstation UAT."
requirements-completed: [DX-02]
coverage:
  - id: D1
    description: "Fleet distinguishes Docker error, empty, partial, one, and many states with stable complete output."
    requirement: DX-02
    verification:
      - kind: integration
        ref: "test/docs/demo_guide_drift_test.exs#fleet distinguishes error, empty, partial, and populated Docker states"
        status: pass
      - kind: e2e
        ref: "npm run demo:fleet-proxy"
        status: pass
    human_judgment: false
  - id: D2
    description: "Doctor, proxy, and browser opening provide independent truthful status and exact recovery commands."
    requirement: DX-02
    verification:
      - kind: integration
        ref: "test/docs/demo_guide_drift_test.exs#doctor reports every dependency, port, and network state without suppression"
        status: pass
      - kind: integration
        ref: "test/docs/demo_guide_drift_test.exs#open selects a supported opener and otherwise keeps a copy-pasteable URL"
        status: pass
      - kind: e2e
        ref: "npm run demo:keycloak-proxy"
        status: pass
    human_judgment: false
duration: 20min
completed: 2026-08-27
status: complete
---

# Phase 71 Plan 02: Fleet and Doctor Summary

**The launcher now discovers every Traefik-routed demo and diagnoses Docker, host-port, proxy-network, and browser-opener states with deterministic recovery output.**

## Accomplishments

- Added global label-based fleet discovery with separate query-error and successful-empty results.
- Added missing-field retention, bytewise project/name sorting, and untruncated output.
- Added grouped independent doctor checks for Docker, Compose, ports 4000/5432/8080, and the configured proxy network.
- Added idempotent proxy startup plus `open`/`xdg-open` selection and a copy-pasteable fallback.
- Proved every host-specific state using fake executables rather than live workstation UAT.

## Task Commits

1. **Fleet, doctor, proxy, opener, and automated acceptance** — `80dc15d`

## Issues Encountered

- The first Keycloak E2E run reached Keycloak with a transient truncated Redirect-binding request and timed out on the invalid-request page. Redacted diagnostics confirmed no Phase 71 code path was involved; a clean isolated rerun passed in 2.1 seconds with one receipt and the canonical three trace steps.

## Verification

- Focused launcher contract: 15 tests, 0 failures.
- Fleet proxy lifecycle/browser lane: passed all solo, persistence, sibling, proxy, and Chromium assertions.
- Keycloak proxy lane: clean rerun passed 1/1 Chromium test with one durable receipt.
- `mix qa` and `mix ci.security`: passed.

## Self-Check: PASSED

Fleet, doctor, proxy, and opener contracts are present; commit `80dc15d` exists; all coverage entries are automated and passing.
