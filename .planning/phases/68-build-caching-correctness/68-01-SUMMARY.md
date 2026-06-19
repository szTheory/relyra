---
phase: 68-build-caching-correctness
plan: "01"
subsystem: demo-docker
status: complete
tags: [docker, buildkit, entrypoint, caching, demo]
dependency_graph:
  requires: []
  provides: [Dockerfile.dev, docker-entrypoint.sh, .dockerignore]
  affects: [demo/ledger_loop]
tech_stack:
  added: []
  patterns: [COPY-before-source dep layer, BuildKit cache mounts, lock-hash entrypoint gate]
key_files:
  created:
    - demo/ledger_loop/Dockerfile.dev
    - demo/ledger_loop/docker-entrypoint.sh
    - .dockerignore
  modified: []
decisions:
  - id: D-CURL-APK
    summary: "Added `curl` to the D-03 apk list (not in original spec) to preserve the existing demo_app healthcheck probe after removing the inline install block"
metrics:
  duration: "2m 8s"
  completed_date: "2026-06-19"
  tasks_completed: 3
  tasks_total: 3
  files_created: 3
  files_modified: 0
---

# Phase 68 Plan 01: Container Build Caching & Entrypoint Summary

**One-liner:** Cached dev image with COPY-before-source dep layer + BuildKit cache mounts + lock-hash boot gate for the `demo/ledger_loop` Phoenix app.

## What Was Built

Three files that together deliver the DKR-01/DKR-03 build-caching and entrypoint-correctness contract for the `demo/ledger_loop` Phoenix app:

1. **`demo/ledger_loop/Dockerfile.dev`** — A cached dev image. The `# syntax=docker/dockerfile:1.7` header enables BuildKit. The base is pinned to `hexpm/elixir:1.15.7-erlang-26.1.2-alpine-3.18.4` (D-06). The D-03 apk package set is installed, plus `curl` (see deviations). `mix.exs`+`mix.lock` are copied before any source, then `mix deps.get`+`mix deps.compile` run inside two BuildKit cache mounts (`relyra-hex` → `/root/.hex`, `relyra-rebar3` → `/root/.cache/rebar3`). The dep layer is only invalidated by lock changes, not source edits (DKR-01). No `COPY . .`, no build-time relyra compile (D-01). The entrypoint script is copied and chmod'd.

2. **`demo/ledger_loop/docker-entrypoint.sh`** — Boot gate with `set -euo pipefail`. Steps: `local.hex/rebar --if-missing` → lock-hash gate (sha256sum of `mix.lock` vs `_build/.docker/mix.lock.sha` stamp inside the `relyra_build` named volume) → `ecto.create --quiet || true` → `mix ledger_loop.relyra.migrate` (relyra audit/connection/replay tables) → `mix ecto.migrate` (demo app tables) → `mix run priv/repo/seeds.exs` (idempotent `Reset.reset!()`) → `exec "$@"` (PID 1 handoff, D-09). The ecto ordering exactly matches the demo's `ecto.setup` alias (DKR-03/Pitfall 5).

3. **`.dockerignore`** (repo root) — Excludes `.git/` and `.planning/` (security, T-68-01/D-07), root-level and demo-nested `_build/`/`deps/`, `node_modules/`, `priv/static/assets/`, `docker-compose*.yml`, `*.tar`, and OS cruft.

## Tasks

| # | Name | Commit | Files |
|---|------|--------|-------|
| 1 | Write Dockerfile.dev (cached dep layer, pinned base) | ba263d0 | demo/ledger_loop/Dockerfile.dev |
| 2 | Write docker-entrypoint.sh (lock-hash gate + ecto ordering) | 60765ad | demo/ledger_loop/docker-entrypoint.sh |
| 3 | Write repo-root .dockerignore (build-context exclusions) | d088f34 | .dockerignore |

## Deviations from Plan

### Minor Deviation — curl in apk list

**Type:** [Rule 2 - Missing critical functionality — pre-existing healthcheck preservation]
**Found during:** Task 1
**Reason:** The plan (task action) explicitly directed adding `curl` to the D-03 apk list with the note: "added `curl` to the apk list to preserve the existing `demo_app` healthcheck probe after removing the inline install command." The existing `docker-compose.yml` healthcheck is `curl -f http://localhost:4000/ || exit 1`; the `hexpm/elixir:...-alpine` base does not bundle curl; without it the container goes `unhealthy` after Plan 02 removes the inline `apk add ... curl` install block, and the `playwright` service (which `depends_on: demo_app: service_healthy`) never starts.
**Fix:** Added `curl` to the `apk add --no-cache` line, with a comment explaining the deviation.
**Files modified:** `demo/ledger_loop/Dockerfile.dev`

No other deviations. Plan executed exactly as specified for Tasks 2 and 3.

## Success Criteria Verification

- [x] `demo/ledger_loop/Dockerfile.dev`: 1.7 syntax header, pinned FROM, D-03 apk list + curl, COPY-before-source mix-files layer, two BuildKit cache mounts, COPY+chmod+ENTRYPOINT for entrypoint script. No `COPY . .`, no build-time relyra compile.
- [x] `demo/ledger_loop/docker-entrypoint.sh`: executable, valid bash (`bash -n` exits 0), `local.hex/rebar --if-missing`, lock-hash gate at `_build/.docker/mix.lock.sha`, ecto.create → ledger_loop.relyra.migrate → ecto.migrate → seeds in order, ends with `exec "$@"`.
- [x] `.dockerignore` (repo root): excludes `.git/`, `.planning/`, `_build/`, `deps/` (root + demo), `node_modules/`, `priv/static/assets/`, `docker-compose*.yml`, `*.tar`, OS cruft.
- [x] Milestone invariant: `git diff --stat` shows NO `lib/` or `test/` path.
- [ ] DKR-01 build receipt: requires Plan 02 compose wiring to run `docker compose --profile core build` (manual receipt, see VALIDATION.md). Equivalent direct check: `DOCKER_BUILDKIT=1 docker build -f demo/ledger_loop/Dockerfile.dev -t relyra-demo-dev .` from repo root.

## Threat Surface Scan

All threat mitigations from the threat register are in place:

| Threat | Mitigation | Status |
|--------|-----------|--------|
| T-68-01 (Info Disclosure — build context leaks) | `.git/` and `.planning/` in `.dockerignore` | Applied in Task 3 |
| T-68-02 (Tampering — base image provenance) | FROM pinned to exact `hexpm/elixir:1.15.7-erlang-26.1.2-alpine-3.18.4` | Applied in Task 1 |
| T-68-03 (Tampering — apk installs) | Dev-only image; packages audited in RESEARCH; accepted | N/A — accepted in threat register |
| T-68-04 (Info Disclosure — dev secrets in layers) | No `COPY . .`, no secrets COPYed at build time | Applied in Task 1 |

No new threat surface introduced beyond what the threat register covers.

## Known Stubs

None. All three files are fully wired for their intended purpose. The DKR-01 build receipt cannot be run automatically in this context (requires Docker) — this is a known manual verification step, not a stub.

## Self-Check: PASSED

- `demo/ledger_loop/Dockerfile.dev` — FOUND (commit ba263d0)
- `demo/ledger_loop/docker-entrypoint.sh` — FOUND (commit 60765ad)
- `.dockerignore` — FOUND (commit d088f34)
- Milestone invariant: no `lib/` or `test/` paths modified
- All three task commits verified in git log
