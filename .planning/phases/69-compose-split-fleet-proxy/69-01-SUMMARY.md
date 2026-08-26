---
phase: 69-compose-split-fleet-proxy
plan: 01
subsystem: docker-compose-and-demo-runtime
tags: [docker-compose, phoenix, liveview, origin-policy, fleet]
dependency_graph:
  requires: [phase-68-build-caching-correctness]
  provides: [solo-compose-ingress, runtime-public-endpoint-policy]
  affects: [69-02-fleet-overlay, phase-70-keycloak-proxy]
tech_stack:
  added: []
  patterns: [base-plus-auto-override, explicit-origin-allowlist, runtime-public-url]
key_files:
  created: [docker-compose.override.yml]
  modified: [docker-compose.yml, demo/ledger_loop/config/runtime.exs, demo/ledger_loop/config/dev.exs]
decisions:
  - "Solo Compose auto-loads a loopback-only demo_app ingress while PostgreSQL remains internal."
  - "Phoenix public URL and LiveView origins derive from explicit runtime environment values outside test."
metrics:
  duration: 24m
  completed_date: 2026-08-26
status: complete
---

# Phase 69 Plan 01: Compose Split Fleet Proxy Summary

Split the zero-setup Compose path from its loopback-only ingress and added an explicit runtime Phoenix URL/origin seam for the later fleet overlay.

## Tasks Completed

1. **Prove the bare-up solo path through the split Compose graph**
   - Removed the `core` profile and base host ports from `db` and `demo_app`.
   - Added the auto-loaded solo override with the sole `127.0.0.1:${PORT:-4000}:4000` app mapping.
   - Verified a real `docker compose up -d --wait` receipt: both services were healthy, loopback HTTP succeeded, and `docker port relyra-demo-db-1` had no binding.
   - Commit: `d1be9bc`

2. **Enforce one runtime URL/origin policy for solo and fleet hosts**
   - Added non-test `PHX_HOST`, `PHX_SCHEME`, `PHX_PORT`, and `DEMO_CHECK_ORIGINS` endpoint configuration.
   - Replaced the development-wide `check_origin: false` bypass while retaining the container-facing `http` bind and Phase 68 reload polling configuration.
   - Commit: `b77c2e1`

## Verification

- `docker compose config --format json` confirmed unprofiled `db`/`demo_app`, no database host port, one loopback app mapping, and unchanged Keycloak/Playwright profiles.
- `docker compose up -d --wait`, loopback `curl`, health inspection, database-port inspection, and `docker compose down` all passed.
- `mix format --check-formatted config/runtime.exs config/dev.exs` passed from `demo/ledger_loop`.
- Runtime assertions passed for the fleet host (`relyra.localhost`, `http`, port `80`), default solo values, and a replacement comma-separated origin list.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

- All four declared production files exist.
- Both task commits exist in git history.
- No Phase 69 change touched `lib/`, fixtures, realm files, Makefiles, environment examples, or documentation.
