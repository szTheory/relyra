---
phase: 68
slug: build-caching-correctness
status: validated
nyquist_compliant: true
wave_0_complete: true
updated: 2026-08-27
---

# Phase 68 — Validation Strategy

Phase 68 is no longer classified as manual-only. Runtime Docker and browser
behaviour is exercised by the owned, disposable-workspace harness below; no
human completion gate is required.

## Automated Harness

| Property | Value |
|---|---|
| Harness | `scripts/test_phase68_build_caching_e2e.sh` |
| Command | `PHASE68_PORT=41868 bash scripts/test_phase68_build_caching_e2e.sh` |
| Isolation | `mktemp` workspace, unique Compose project and volumes, cleanup trap |
| Assertions | BuildKit dependency-vertex cache, nested volume masking, lock-hash branches and Ecto re-up, bind-mounted template reload in Chromium |

The harness copies the checkout while excluding artifacts, injects a host-only
`deps` sentinel into that copy, and never reuses the developer's Compose
project, source tree, or volumes.

## Requirement Map

| Task ID | Requirement | Test type | Command | Status |
|---|---|---|---|---|
| 68-01 | DKR-01 — source-only rebuild retains the dependency layer | Integration | `PHASE68_PORT=41868 bash scripts/test_phase68_build_caching_e2e.sh` | validated: BuildKit reported the exact `mix deps.get` vertex as `CACHED` after a `.heex` edit |
| 68-02 | DKR-02 — nested named volumes hide host artifacts | Integration | `PHASE68_PORT=41868 bash scripts/test_phase68_build_caching_e2e.sh` | validated: healthy container, host sentinel absent, and both nested targets inspected as `volume` mounts |
| 68-01/02 | DKR-03 — unchanged lock skips work; changed content re-runs it; bootstrap remains idempotent | Integration | `PHASE68_PORT=41868 bash scripts/test_phase68_build_caching_e2e.sh` | validated: unchanged content emitted the skip branch; changed content emitted the resolve branch; repeated Compose boots remained healthy |
| 68-02 | DKR-04 — bind-mounted template reloads in Chromium without restart/deps work | Browser integration | `PHASE68_PORT=41868 bash scripts/test_phase68_build_caching_e2e.sh` | validated: Chromium observed a bind-mounted template marker through Phoenix live reload without a container restart |

## Validation Audit 2026-08-27

| Requirement | Evidence observed | Result |
|---|---|---|
| DKR-01 | Two isolated BuildKit builds around a source-only template edit; dependency RUN vertex was `CACHED`. | validated |
| DKR-02 | Isolated `up --wait` booted healthy; injected host `deps` sentinel was invisible in the app; Docker inspected `deps` and `_build` as named volumes. | validated |
| DKR-03 | Initial boot persisted `_build/.docker/mix.lock.sha`; the unchanged re-up emitted the skip message and a content change to `mix.lock` emitted the resolve message. | validated |
| DKR-04 | Chromium subscribed from the configured `localhost` origin and observed a sequence of bind-mounted template markers through Phoenix live reload without a container restart. | validated |

## Validation Audit Summary

| Result | Count |
|---|---|
| Gaps found | 4 |
| Resolved | 4 |
| Escalated | 0 |

The full isolated Docker/Chromium harness passed on 2026-08-27. Log assertions
now read from the active container with a bounded settle window, the live-reload
probe uses the configured Phoenix origin, and cleanup removes every harness-owned
container, volume, network, workspace, and temporary image.
