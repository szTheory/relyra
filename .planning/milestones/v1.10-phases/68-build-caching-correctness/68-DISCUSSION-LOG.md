# Phase 68: Build caching & correctness - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-06-19
**Phase:** 68-build-caching-correctness
**Mode:** assumptions
**Areas analyzed:** Path-dep build-caching split, Dependency cache persistence, Named-volume paths, Toolchain pin, .dockerignore placement, Entrypoint lock-hash + ecto idempotency, :fs_poll live reload

## Assumptions Presented

### Path-dep build-caching split (DKR-01)
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Image build compiles only Hex deps; relyra path dep compiles at entrypoint; no `COPY . .` | Confident | `demo/ledger_loop/mix.exs` `{:relyra, path: "../.."}`; `mix.lock` 36 Hex entries, no relyra; north-star line 58 |

### Dependency cache persistence
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Two-tier: BuildKit cache mounts for download + named volumes for compiled deps/_build | Confident | bind mount `.:/app` shadows image layers; `_build` must be writable (relyra compiles at runtime); north-star lines 44, 60 |

### Named-volume mount paths
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Mount at nested paths `/app/demo/ledger_loop/{deps,_build}` + `/root/.hex`, `/root/.mix` | Confident | `docker-compose.yml:22` `working_dir: /app/demo/ledger_loop`; north-star `/app/deps` is underspecified |

### Toolchain pin
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Keep `hexpm/elixir:1.15.7-erlang-26.1.2-alpine-3.18.4`; do not bump to CI 1.19.5/OTP28 | Likely | `mix.exs` `~> 1.15`; proven baseline `docker-compose.yml:18`; bump = full recompile + drift risk, zero phase benefit |

### .dockerignore placement
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Single repo-root `.dockerignore` (demo-dir file would be inert) | Confident | context spans repo root (path dep `../..`); Docker resolves `.dockerignore` at context root |

### Entrypoint lock-hash + ecto idempotency
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| sha256(mix.lock) stamp gate; **`ledger_loop.relyra.migrate` BEFORE `ecto.migrate`**; idempotent seeds; `exec "$@"` with compose `command: mix phx.server` | Likely | `ecto.setup` alias chain in `mix.exs`; custom task `ledger_loop.relyra.migrate.ex`; `seeds.exs` → `Reset.reset!()`; north-star line 61 corrected |

### :fs_poll live reload
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| `backend: :fs_poll, backend_opts: [interval: 500]` unconditional in `config/dev.exs` | Likely | current `live_reload:` has no `backend:`; FS events dead across mount; `watchers: []`; native unaffected (polls) |

## Corrections Made

No corrections — all assumptions confirmed via "Yes, proceed".

The analysis itself surfaced one **correction to the north-star plan** (folded into D-08, not a user
correction): the entrypoint must run `mix ledger_loop.relyra.migrate` before `mix ecto.migrate`,
because relyra's own tables are installed by that custom task — the north-star's literal `ecto.migrate`
text alone would leave SAML/admin paths 500ing on missing tables.

## External Research

None performed — north-star plan + verified codebase were sufficient. (Open execution-time check:
`phoenix_live_reload ~> 1.2` `backend: :fs_poll` + `backend_opts` — well-established public API.)
