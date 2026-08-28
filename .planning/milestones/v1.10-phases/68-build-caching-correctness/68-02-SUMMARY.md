---
phase: 68-build-caching-correctness
plan: "02"
subsystem: demo-docker
status: complete
tags: [docker, compose, named-volumes, live-reload, fs-poll, demo]
dependency_graph:
  requires: [68-01]
  provides: [docker-compose.yml overlay, dev.exs fs_poll block]
  affects: [demo/ledger_loop]
tech_stack:
  added: []
  patterns: [named-volume bind-mount masking, top-level phoenix_live_reload app-env config]
key_files:
  created: []
  modified:
    - docker-compose.yml
    - demo/ledger_loop/config/dev.exs
decisions:
  - id: D-04-APPLIED
    summary: "Named volumes attach at nested demo paths (/app/demo/ledger_loop/deps and /app/demo/ledger_loop/_build) — NOT generic /app/deps or /app/_build — so macOS-compiled artifacts never enter the Linux container"
  - id: D-10-CORRECTED-APPLIED
    summary: "config :phoenix_live_reload backend: :fs_poll added as a SEPARATE top-level block in dev.exs, NOT inside the Endpoint live_reload: keyword (which silently ignores backend:)"
requirements-completed: [DKR-02, DKR-03, DKR-04]
metrics:
  duration: "2m 26s"
  completed_date: "2026-06-19"
  tasks_completed: 2
  tasks_total: 2
  files_created: 0
  files_modified: 2
---

# Phase 68 Plan 02: Docker Compose Wiring & Live Reload Summary

**One-liner:** Minimal docker-compose.yml overlay wiring Plan-01 Dockerfile.dev + four named volumes at the correct nested demo paths + top-level `:fs_poll` live-reload config for cross-mount file watching.

## What Was Built

Two file modifications that together deliver DKR-02, DKR-03, and DKR-04:

1. **`docker-compose.yml`** (`demo_app` service overlay + top-level `volumes:` block):
   - Replaced `image: hexpm/elixir:...` with `build: {context: ., dockerfile: demo/ledger_loop/Dockerfile.dev}` (wires Plan-01 Dockerfile)
   - Removed the 6-line inline `sh -c "apk add ... && mix deps.get && ... && mix phx.server"` command block
   - Added `command: mix phx.server` (entrypoint `exec "$@"`s this as PID 1, D-09)
   - Extended `volumes:` with four `relyra_*` named volumes at the NESTED demo paths (D-04, DKR-02, Pitfall 3): `relyra_deps:/app/demo/ledger_loop/deps`, `relyra_build:/app/demo/ledger_loop/_build`, `relyra_hex:/root/.hex`, `relyra_mix:/root/.mix`
   - Added top-level `volumes:` block declaring all four keys (DKR-03 — `relyra_build` persists the lock-hash stamp across `down`/`up`)
   - All existing `ports`, `environment`, `healthcheck`, `depends_on`, `working_dir`, `db`, `keycloak`, `playwright` services left exactly unchanged (D-05)

2. **`demo/ledger_loop/config/dev.exs`** (new top-level application-env block):
   - Added `config :phoenix_live_reload, backend: :fs_poll, backend_opts: [interval: 500]` as a separate top-level block (DKR-04, D-10 corrected per Pitfall 1)
   - Placed immediately after the existing Endpoint `live_reload:` block for readability
   - The existing `config :ledger_loop, LedgerLoopWeb.Endpoint, live_reload: [web_console_logger: true, patterns: [...]]` block left completely unchanged — its `patterns` still select which files trigger reload
   - `mix format --check-formatted` passes

## Tasks

| # | Name | Commit | Files |
|---|------|--------|-------|
| 1 | Overlay docker-compose.yml demo_app — build + named volumes + command | eee4f36 | docker-compose.yml |
| 2 | Add top-level config :phoenix_live_reload :fs_poll block to dev.exs | b31b3cd | demo/ledger_loop/config/dev.exs |

## Deviations from Plan

None — plan executed exactly as specified.

The two file modifications are precisely what the plan called for: a minimal overlay on the existing `docker-compose.yml` (no rewrite, no Phase-69 proxy split, no port changes) and a single new top-level `config :phoenix_live_reload` block in `dev.exs` (correctly separated from the Endpoint keyword per the D-10 correction in RESEARCH Pitfall 1).

## Success Criteria Verification

- [x] `docker-compose.yml` `demo_app` builds from `demo/ledger_loop/Dockerfile.dev` (context `.`)
- [x] `command: mix phx.server` set (entrypoint `exec "$@"`s it as PID 1)
- [x] Four `relyra_*` named volumes mounted at nested demo paths (`/app/demo/ledger_loop/deps`, `/app/demo/ledger_loop/_build`, `/root/.hex`, `/root/.mix`)
- [x] Top-level `volumes:` block declares all four keys
- [x] No generic `/app/deps` or `/app/_build` volume paths (would mask wrong directory, Pitfall 3)
- [x] `apk add` inline install block removed
- [x] `"${PGPORT:-5432}:5432"` port line unchanged (D-05)
- [x] `db`, `keycloak`, `playwright` services untouched
- [x] `docker compose config` exits 0 (valid YAML)
- [x] `config :phoenix_live_reload, backend: :fs_poll, backend_opts: [interval: 500]` — single top-level block
- [x] `backend: :fs_poll` is NOT inside the Endpoint `live_reload:` keyword (Pitfall 1 avoided)
- [x] Existing `live_reload: [web_console_logger: true, patterns: [...]]` block unchanged
- [x] `mix format --check-formatted config/dev.exs` exits 0
- [x] Milestone invariant: `git diff --stat` shows NO `lib/` or `test/` path (only `docker-compose.yml` and `demo/ledger_loop/config/dev.exs`)
- [ ] DKR-02 receipt: container boots, no NIF/arch error (manual Docker verification required)
- [ ] DKR-03 receipt: re-`up` skips `deps.get` unless `mix.lock` changed (manual Docker verification required)
- [ ] DKR-04 receipt: `.heex` edit live-reloads ~500ms (manual Docker verification required)

The three manual Docker receipts require a running Docker environment; they are documented in VALIDATION.md.

## Threat Surface Scan

All mitigations from the plan's threat register are in place:

| Threat | Mitigation | Status |
|--------|-----------|--------|
| T-68-05 (Tampering — host-compiled artifacts in container) | Named volumes at exact nested paths `/app/demo/ledger_loop/deps` and `/app/demo/ledger_loop/_build` (D-04) | Applied in Task 1 |
| T-68-06 (Info Disclosure — dev secrets in compose env) | `environment:` block left unchanged; pre-existing, dev-only (D-05) | No change, accepted |
| T-68-07 (DoS — `:fs_poll` idle CPU) | 500ms polling; negligible on dev hardware; accepted (D-10) | Applied in Task 2 |

No new threat surface introduced beyond what the threat register covers.

## Known Stubs

None. Both files are fully wired for their intended purpose. The three manual Docker receipts (DKR-02, DKR-03, DKR-04) are verification steps, not code stubs.

## Self-Check: PASSED

- `docker-compose.yml` modified — FOUND (commit eee4f36)
- `demo/ledger_loop/config/dev.exs` modified — FOUND (commit b31b3cd)
- Milestone invariant: no `lib/` or `test/` paths modified — VERIFIED
- `docker compose config` exits 0 — VERIFIED
- All automated acceptance criteria for both tasks — VERIFIED
- `mix format --check-formatted config/dev.exs` — VERIFIED
