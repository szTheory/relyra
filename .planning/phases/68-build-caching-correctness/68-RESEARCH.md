# Phase 68: Build caching & correctness - Research

**Researched:** 2026-06-19
**Domain:** Docker dev-DX for an Elixir/Phoenix path-dep demo (BuildKit cache mounts, named-volume masking, container entrypoint idempotency, `:fs_poll` live reload across the macOS→Docker boundary)
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions (D-01..D-10 — DO NOT re-litigate)
- **D-01:** `Dockerfile.dev` compiles only the **Hex deps tree** at build time — `COPY mix.exs mix.lock` first, then `mix deps.get` + `mix deps.compile`. The `relyra` path dep compiles at entrypoint/runtime from the bind-mounted parent. No `COPY . .`, no build-time `relyra` compile.
- **D-02:** Two-tier cache. (a) BuildKit **cache mounts** (`/root/.hex`, `/root/.cache/rebar3`) speed the build-time download/compile but do **not** persist into the running container. (b) The running container's `deps/` and `_build/` live in **named volumes** mounted over the bind mount (`_build` must be writable because `relyra` compiles at runtime).
- **D-03:** `Dockerfile.dev` header `# syntax=docker/dockerfile:1.7`; system packages `inotify-tools bash postgresql-client build-base git openssl`. Build requires BuildKit.
- **D-04:** Named volumes attach at the **nested demo paths** (not repo-root paths):
  `relyra_deps:/app/demo/ledger_loop/deps`, `relyra_build:/app/demo/ledger_loop/_build`, `relyra_hex:/root/.hex`, `relyra_mix:/root/.mix`.
- **D-05:** Minimal overlay on the **existing** `docker-compose.yml` `demo_app` service (`image:`→`build:`, drop inline `command:` install block, add `volumes:` + top-level `volumes:`). No Phase-69 base/override/proxy split; do not touch the published Postgres port.
- **D-06:** **Keep** pin `hexpm/elixir:1.15.7-erlang-26.1.2-alpine-3.18.4` — move `image:` → `FROM`. No bump to CI matrix (1.19.5 / OTP 27&28).
- **D-07:** Single **repo-root** `.dockerignore` excluding `_build/`, `deps/` (root + `demo/ledger_loop/`), `node_modules/`, `.git/`, `.planning/`, `priv/static/assets/`, `docker-compose*.yml`, `*.tar`, OS cruft.
- **D-08:** Entrypoint flow: `local.hex`/`local.rebar` → lock-hash gate (`sha256sum mix.lock` vs `_build/.docker/mix.lock.sha`; if changed/absent → `deps.get && deps.compile` then rewrite stamp) → `ecto.create --quiet || true` → **`mix ledger_loop.relyra.migrate` BEFORE `mix ecto.migrate`** → idempotent seeds → `exec "$@"`.
- **D-09:** Compose `command: mix phx.server`; entrypoint `exec "$@"`s it (PID 1, clean signals).
- **D-10:** Set `phoenix_live_reload` to `backend: :fs_poll, backend_opts: [interval: 500]` unconditionally in `demo/ledger_loop/config/dev.exs`. **⚠️ See Pitfall 1 — the config KEY in D-10 is wrong; the values are right.**

### Claude's Discretion
- Exact cache-mount `--mount=type=cache,...` `id=` wording, `inotify-tools`/`bash` package ordering, and shell style in `docker-entrypoint.sh`.
- Confirm `phoenix_live_reload` accepts `backend: :fs_poll` + `backend_opts: [interval: ...]` (done — see below).

### Deferred Ideas (OUT OF SCOPE)
- Env-gated `:fs_poll`; compose base/override/proxy split + drop published Postgres port (Phase 69); toolchain bump (1.19.5/OTP28); TLS/mkcert/hashed hostnames/prod release Dockerfile.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DKR-01 | `Dockerfile.dev` copies `mix.exs`/`mix.lock` before source, fetches/compiles deps in a cached layer with BuildKit cache mounts; source edit never invalidates the dep layer. | Cache-mount syntax + COPY-layering verified (§Standard Stack, §Code Examples). Cache mounts confirmed NOT persisted into image/container (Docker docs). |
| DKR-02 | `deps/`/`_build/` backed by container-private named volumes that mask the bind mount; host macOS artifacts never shared in (no NIF/arch breakage). | Named-volume-over-bind-mount masking + empty-volume-init semantics verified (Docker volumes/bind-mounts docs). Nested-path masking confirmed (§Pitfall 3). |
| DKR-03 | Entrypoint re-runs `deps.get`/`deps.compile` only when `mix.lock` changed (hash stamp) and runs `ecto.create`/`ecto.migrate` idempotently. | Lock-hash stamp pattern + entrypoint ordering verified against `mix.exs` `ecto.setup` alias and the custom `ledger_loop.relyra.migrate` task (§Code Examples, §Pitfall 5). |
| DKR-04 | Editing a LiveView template/stylesheet live-reloads without container restart or dep re-fetch (`:fs_poll` across macOS→Docker mount). | `:fs_poll` is the documented workaround for the macOS→Docker inotify gap. **Config key corrected** (§Pitfall 1). Verified against `phoenix_live_reload` 1.6.2 README. |
</phase_requirements>

## Summary

This phase is **pure dev-tooling plumbing** with no `lib/` change. Every architectural choice is already locked in CONTEXT D-01..D-10; the research job was to pin the *external, executable facts* so the planner/executor get them right first try. The four mechanisms — BuildKit cache mounts, named-volume masking, a lock-hash entrypoint gate, and `:fs_poll` live reload — are all well-established and individually verified against authoritative sources (Docker docs, `phoenix_live_reload` 1.6.2 hexdocs, Alpine package index).

**One CONTEXT fact is wrong and must be flagged loudly:** D-10 (and the north-star, and the phase description) say to put `backend: :fs_poll, backend_opts: [interval: 500]` *inside the Endpoint's `live_reload:` keyword*. The authoritative `phoenix_live_reload` README places `backend`/`backend_opts` under the **top-level `config :phoenix_live_reload` application env**, NOT inside `config :app, Endpoint, live_reload: [...]`. Putting it in the wrong key silently no-ops (it stays on the default FS-event backend, which does NOT fire across the macOS→Docker bind mount — DKR-04 fails silently). See **Pitfall 1**. A second smaller correction: the demo's locked `phoenix_live_reload` is **1.6.2** (not the `~> 1.2` floor the phase brief cited); the `:fs_poll` API is unchanged, so the version drift is harmless to the config shape but worth recording.

Two other landmines: (a) `postgresql-client` is NOT a real package in Alpine 3.18 — it is a *virtual provide* of `postgresql15-client`; `apk add postgresql-client` resolves correctly via the provide, but the literal package page 404s (don't be alarmed). (b) Cache mounts silently no-op without BuildKit, so the entrypoint must never assume `/root/.hex` survives into the container — only the `relyra_hex`/`relyra_mix` named volumes do.

**Primary recommendation:** Implement D-01..D-09 exactly as locked. For D-10, **override the wording**: add a NEW top-level `config :phoenix_live_reload, backend: :fs_poll, backend_opts: [interval: 500]` block to `dev.exs` (do NOT merge it into the Endpoint's `live_reload:` keyword). Keep the existing Endpoint `live_reload: [web_console_logger:, patterns:]` block as-is.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Dep download/compile caching across builds | Image build (BuildKit cache mount) | — | Cache mounts live only at build time; they accelerate `deps.get`/`deps.compile` in the dep layer. |
| Persisted Linux-compiled `deps/`/`_build/` for the running container | Container runtime (named volumes) | — | Must survive `up`/`down`, must mask host artifacts, must be writable for runtime `relyra` compile. |
| Source/style editing | Host bind mount (`.:/app`) | — | Live editing; `_build`/`deps` subpaths are masked by volumes so host artifacts don't leak. |
| Dep re-resolution decision | Container entrypoint (lock-hash gate) | — | Runtime decision keyed on `mix.lock` content; cache mounts are gone by now. |
| DB create/migrate/seed idempotency | Container entrypoint | Compose `depends_on: service_healthy` | Entrypoint owns ordering; compose guarantees `db` is up first. |
| `.heex`/CSS live reload across macOS→Docker | `phoenix_live_reload` `:fs_poll` (app env) | — | inotify events don't cross the macOS bind mount; polling is the only working backend. |

## Standard Stack

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| Docker BuildKit | Dockerfile syntax `1.7` (`docker/dockerfile:1.7`) | `RUN --mount=type=cache` for Hex/rebar dirs | Default builder in Docker Desktop + Compose v2; the only way to get build-time package caches. [VERIFIED: docs.docker.com/build/cache] |
| Base image | `hexpm/elixir:1.15.7-erlang-26.1.2-alpine-3.18.4` | Pinned toolchain (D-06) | Proven running baseline; `mix.exs` needs only `~> 1.15`. [VERIFIED: docker-compose.yml:18 + mix.exs:8] |
| `phoenix_live_reload` | **1.6.2** (lock; declared `~> 1.2`) | `:fs_poll` live reload | Locked in `demo/ledger_loop/mix.lock`. [VERIFIED: mix.lock grep] |
| `file_system` | **1.1.1** (lock) | Backing FS watcher for live_reload | Transitive dep of `phoenix_live_reload`; `:fs_poll` uses it. [VERIFIED: mix.lock grep] |

### Supporting (Alpine 3.18 apk packages — D-03)
| Package | Verified name/version in Alpine 3.18 main | Purpose | Needed? |
|---------|-------------------------------------------|---------|---------|
| `build-base` | `build-base` 0.5-r3 (main) | gcc/make/musl-dev for NIF compilation | **Required** — NIFs in the dep tree (e.g. anything with native code) won't compile without it. [VERIFIED: pkgs.alpinelinux.org] |
| `inotify-tools` | `inotify-tools` 3.22.6.0-r2 (main) | inotify CLIs; the FS-event backend's native watcher | Installed for parity, but **not load-bearing for DKR-04** — `:fs_poll` polls and does not use inotify. Harmless to keep. [VERIFIED: pkgs.alpinelinux.org] |
| `postgresql-client` | **virtual provide** → `postgresql15-client` 15.13-r0 (main) | `pg_isready` + `psql` for entrypoint DB readiness/migrate | **Required** for any DB-readiness probe. `apk add postgresql-client` resolves via the provide. ⚠️ See Pitfall 4. [VERIFIED: pkgs.alpinelinux.org] |
| `bash` | `bash` (main) | entrypoint shell (if `#!/usr/bin/env bash`) | Optional — only if the entrypoint uses bashisms. POSIX `sh` (already present) also works. [ASSUMED present in main] |
| `git` | `git` (main) | some Hex deps fetch via git | Keep — cheap insurance for git-sourced deps. [ASSUMED] |
| `openssl` | `openssl` (main) | TLS for hex.pm fetches / crypto | Usually already in the hexpm image; harmless to list. [ASSUMED] |

**Installation (in `Dockerfile.dev`):**
```dockerfile
RUN apk add --no-cache inotify-tools bash postgresql-client build-base git openssl
```

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `:fs_poll` polling | inotify FS-event backend | inotify does NOT propagate across the macOS→Docker bind mount → live reload silently dead. Polling is the only working option. (D-10 correct in spirit.) |
| BuildKit cache mounts | `mix` named volumes for `/root/.hex` only | Volumes persist into the container but don't accelerate the *image build*; the two-tier split (D-02) is correct — keep both. |
| `postgresql-client` (virtual) | `postgresql15-client` (explicit) | Explicit name avoids the 404-but-works confusion, but the virtual name is more version-portable. Either works in 3.18. |

## Package Legitimacy Audit

> No language-package installs are added by this phase (no new Hex deps; `mix.exs` untouched). The only "packages" are OS apk packages, audited above against the Alpine 3.18 index.

| Package | Registry | Verdict | Disposition |
|---------|----------|---------|-------------|
| `inotify-tools` 3.22.6.0-r2 | Alpine 3.18 main | OK | Approved (parity only) |
| `build-base` 0.5-r3 | Alpine 3.18 main | OK | Approved (required for NIFs) |
| `postgresql15-client` 15.13-r0 (via `postgresql-client` provide) | Alpine 3.18 main | OK | Approved (required) |
| `bash` / `git` / `openssl` | Alpine 3.18 main | OK | Approved |

**Packages removed due to [SLOP]:** none. **Packages flagged [SUS]:** none.

## Architecture Patterns

### System Architecture Diagram

```
                 macOS host (ARM)                        Linux container (musl/Alpine 3.18)
┌──────────────────────────────────┐        ┌─────────────────────────────────────────────────┐
│ repo root  (bind mount source)   │        │  /app  ◀── bind mount (live source editing)       │
│   ./mix.exs ./mix.lock ./lib ...  │──.:/app─▶│   working_dir: /app/demo/ledger_loop            │
│   demo/ledger_loop/ (heex, css)  │        │                                                   │
└──────────────────────────────────┘        │   /app/demo/ledger_loop/deps   ◀── relyra_deps    │  named volumes
                                             │   /app/demo/ledger_loop/_build ◀── relyra_build   │  MASK the bind mount
   IMAGE BUILD (BuildKit, one-time/cached)   │   /root/.hex                   ◀── relyra_hex      │  at these subpaths
   ┌───────────────────────────────┐         │   /root/.mix                   ◀── relyra_mix      │  (host artifacts
   │ FROM hexpm/elixir:1.15.7-…     │         └─────────────────────────────────────────────────┘   never leak in)
   │ COPY mix.exs mix.lock  ◀───────┼─ dep layer cached unless lock changes
   │ RUN --mount=type=cache,        │                          │
   │   target=/root/.hex            │                          ▼
   │   target=/root/.cache/rebar3   │        docker-entrypoint.sh  (PID-launched, exec's command)
   │   mix deps.get && deps.compile │          1. local.hex/local.rebar --if-missing
   │ (NO COPY . .)                  │          2. sha256sum mix.lock vs _build/.docker/mix.lock.sha
   └───────────────────────────────┘             └─ changed/absent → deps.get && deps.compile → restamp
        cache mounts DO NOT persist               3. ecto.create --quiet || true
        into the container ──────────────▶        4. ledger_loop.relyra.migrate   (relyra tables)
                                                   5. ecto.migrate                 (demo tables)
                                                   6. seeds (idempotent Reset.reset!)
                                                   7. exec "$@"  →  mix phx.server  (PID 1)
                                                          │
                                  edit .heex/css  ──▶ :fs_poll (interval 500ms) ──▶ browser reload
```

### Recommended File Layout (this phase)
```
.dockerignore                              # NEW — repo root (D-07)
docker-compose.yml                         # MODIFY — demo_app overlay (D-05)
demo/ledger_loop/
├── Dockerfile.dev                         # NEW (D-01, D-03, D-06)
├── docker-entrypoint.sh                    # NEW (D-08, D-09) — chmod +x
└── config/dev.exs                          # MODIFY — add top-level :phoenix_live_reload block (D-10, corrected)
```

### Pattern 1: COPY-before-source dep-layer caching (DKR-01)
**What:** Copy only `mix.exs`+`mix.lock` before fetching deps so the dep layer is reused unless the lock changes.
**When:** Always, for path-dep + bind-mount dev images.
**Example:** see §Code Examples.

### Pattern 2: Two-tier cache split (DKR-01 + DKR-02)
**What:** BuildKit cache mounts accelerate the *build*; named volumes persist the *runtime* `deps/`/`_build/`. They are different mechanisms with different lifetimes.
**Key:** the entrypoint runs in the *container*, where cache mounts no longer exist — so the lock-hash gate must rely only on the named volumes (`relyra_build` holds the stamp; `relyra_hex`/`relyra_mix` hold the runtime hex/mix state).

### Anti-Patterns to Avoid
- **`COPY . .` in `Dockerfile.dev`:** bakes source into the image, defeats the bind mount, and would force a full rebuild on every source edit. D-01 forbids it. [VERIFIED: north-star line 58]
- **Putting `backend: :fs_poll` inside the Endpoint `live_reload:` keyword:** silently ignored → live reload stays dead. See Pitfall 1.
- **Relying on `/root/.hex` cache mount at runtime:** it doesn't exist in the container. Use the `relyra_hex` named volume.
- **Bare `mix ecto.migrate` without `ledger_loop.relyra.migrate` first:** skips relyra's audit/connection tables → 500s on every SAML/admin path. See Pitfall 5.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Live reload across mount boundary | A custom inotify/file-watch loop | `phoenix_live_reload` `:fs_poll` | Already a dep; polling backend is purpose-built for exactly the macOS→Docker case. |
| Persisting Linux-compiled artifacts | Copying `_build` in/out, rsync hooks | Docker named volumes masking the bind subpath | Native Docker masking is atomic and arch-correct. |
| Dep-cache across builds | Manual layer juggling / `.cache` COPYs | BuildKit `--mount=type=cache` | Build-time cache that survives `--no-cache`-free rebuilds without bloating layers. |
| DB readiness | `sleep 10` | `depends_on: service_healthy` (already present) + `pg_isready` if needed | Deterministic; the compose healthcheck already gates `demo_app` on `db`. |

**Key insight:** Every primitive this phase needs already exists in Docker/Phoenix — the work is wiring, not building.

## Common Pitfalls

### Pitfall 1: `:fs_poll` config in the WRONG key (CONTEXT D-10 is wrong) ⚠️ LOAD-BEARING
**What goes wrong:** D-10, the north-star (line 62), and the phase description all say to set `backend: :fs_poll, backend_opts: [interval: 500]` *inside* the Endpoint's `live_reload:` keyword (`config :ledger_loop, LedgerLoopWeb.Endpoint, live_reload: [..., backend: :fs_poll]`). The `phoenix_live_reload` README places `backend`/`backend_opts`/`dirs` under the **top-level application env** `config :phoenix_live_reload`. The Endpoint `live_reload:` keyword owns `interval`, `patterns`, `web_console_logger` — but NOT `backend`. Putting `backend:` in the Endpoint keyword is silently ignored; the watcher stays on the default FS-event backend, which does not fire across the macOS→Docker bind mount. **DKR-04 fails with zero error output.**
**Why it happens:** Two different `interval` keys (`live_reload: [interval:]` default 100ms vs `backend_opts: [interval:]`) make the two config locations easy to conflate.
**How to avoid:** Add a SEPARATE top-level block to `dev.exs`. Leave the existing Endpoint `live_reload: [web_console_logger:, patterns:]` block untouched (its `patterns` still drive *which* files trigger reload). Correct shape:
```elixir
# top-level — controls HOW files are watched (the backend)
config :phoenix_live_reload,
  backend: :fs_poll,
  backend_opts: [interval: 500]
```
**Warning signs:** edit a `.heex`, save, browser does not reload, and no log line about a reload — but `mix phx.server` works otherwise.
**Evidence:** [VERIFIED: phoenix-live-reload.hexdocs.pm/readme.html — backend/backend_opts shown under `config :phoenix_live_reload`, while `live_reload:` examples live under the Endpoint]. The values (`:fs_poll`, `interval: 500`) D-10 chose are correct; only the *key* is wrong.

### Pitfall 2: Cache mount silently no-ops without BuildKit
**What goes wrong:** If the image is built with the legacy builder (`DOCKER_BUILDKIT=0`, or some CI), `RUN --mount=type=cache,...` is ignored/errors and you lose the cache (or the build fails to parse the flag).
**How to avoid:** The `# syntax=docker/dockerfile:1.7` header + Compose v2 (BuildKit default) covers this locally. Note in docs that builds require BuildKit. [VERIFIED: docs.docker.com/build/cache — cache mounts are a BuildKit feature]
**Warning signs:** dep download is slow on every build despite the cache mount being present.

### Pitfall 3: Named volume must mask at the EXACT nested subpath (D-04)
**What goes wrong:** Using the north-star's generic `/app/deps` / `/app/_build` paths masks the *wrong* directory (repo-root `deps`, which is empty), leaving `/app/demo/ledger_loop/deps` served from the bind mount = the macOS-compiled artifacts leak in → NIF/arch breakage.
**Why it happens:** `working_dir` is `/app/demo/ledger_loop`, two levels below the bind-mount root.
**How to avoid:** Mount at `relyra_deps:/app/demo/ledger_loop/deps` and `relyra_build:/app/demo/ledger_loop/_build` exactly (D-04). A named volume mounted into a directory obscures whatever the bind mount placed there. Because the image has no `COPY . .`, there is nothing at that path in the image to copy into the volume → the volume initializes **empty** (correct: it must NOT inherit host artifacts). [VERIFIED: docs.docker.com/engine/storage/volumes — "empty volume mounted into a directory with existing files → files propagated into the volume"; here the image dir is empty so nothing propagates] [VERIFIED: bind-mounts doc — "pre-existing files are obscured by the mount"]
**Warning signs:** `(RuntimeError) ... .so: wrong ELF class` / NIF load failure on first `mix` run.

### Pitfall 4: `postgresql-client` is a virtual provide in Alpine 3.18 (not a real page)
**What goes wrong:** Browsing `pkgs.alpinelinux.org/package/v3.18/main/x86_64/postgresql-client` returns **404**, which can scare an executor into thinking the package name is wrong and "fixing" it.
**Reality:** In Alpine 3.18, `postgresql-client` exists only as a **virtual provide** of `postgresql15-client` (15.13-r0), which provides `cmd:pg_isready` and `cmd:psql`. `apk add postgresql-client` resolves correctly and installs the PG15 client — which matches the `postgres:15-alpine` server. [VERIFIED: pkgs.alpinelinux.org/package/v3.18/main/x86_64/postgresql15-client — Provides lists `postgresql-client`, `cmd:pg_isready`, `cmd:psql`]
**How to avoid:** Keep `postgresql-client` in the apk line (D-03 is correct). Optionally pin `postgresql15-client` for clarity. Do NOT "correct" it to `postgresql` (the server package).

### Pitfall 5: Entrypoint ecto ordering — relyra migrate BEFORE ecto.migrate (D-08)
**What goes wrong:** The north-star's literal `ecto.migrate`-only text skips `ledger_loop.relyra.migrate`, so relyra's audit/connection/replay tables are never created → every SAML/admin path 500s.
**How to avoid:** Match the demo's `ecto.setup` alias order exactly: `ecto.create` → `ledger_loop.relyra.migrate` → `ecto.migrate` → seeds. The custom task (`demo/ledger_loop/lib/mix/tasks/ledger_loop.relyra.migrate.ex`) calls `LedgerLoop.Relyra.Migrations.migrate_relyra!/1` and accepts `--quiet`. Seeds are idempotent (`seeds.exs` → `LedgerLoop.Demo.Reset.reset!()`), safe to re-run every `up`. [VERIFIED: mix.exs:70-75 ecto.setup alias + migrate task source]
**Warning signs:** `relation "relyra_..." does not exist` in the first request after `up`.

### Pitfall 6: Lock-hash stamp lives inside `relyra_build` — survives `up`, wiped by volume rm
**What goes wrong:** If the stamp `_build/.docker/mix.lock.sha` is written somewhere outside the `relyra_build` volume, it's lost on container recreate and deps re-resolve every `up` (DKR-03 regression). If it's *inside* `relyra_build`, it persists across `down`/`up` (good) but is correctly wiped by `docker volume rm relyra_build` / `make nuke` (forces a clean re-resolve, also good).
**How to avoid:** Write the stamp under `_build/.docker/` (inside the named volume, per D-08/Specifics). Ensure `mkdir -p _build/.docker` before writing. [VERIFIED: CONTEXT Specifics line 128]
**Warning signs:** `deps.get` runs on every boot even with an unchanged lock.

## Code Examples

### Dockerfile.dev (DKR-01) — cache-mount + COPY-layering
```dockerfile
# syntax=docker/dockerfile:1.7
# Source: docs.docker.com/build/cache/optimize + dockerfile reference (--mount=type=cache attrs)
FROM hexpm/elixir:1.15.7-erlang-26.1.2-alpine-3.18.4

RUN apk add --no-cache inotify-tools bash postgresql-client build-base git openssl

ENV MIX_ENV=dev
WORKDIR /app/demo/ledger_loop

# Dep layer: copy ONLY mix files first so this layer is reused unless the lock changes.
COPY demo/ledger_loop/mix.exs demo/ledger_loop/mix.lock ./

# BuildKit cache mounts: persist the Hex + rebar3 caches ACROSS builds.
# id= is optional (defaults to target); set it for clarity / cross-project isolation.
# sharing=locked serializes concurrent writers (safe default for a package cache).
RUN --mount=type=cache,id=relyra-hex,target=/root/.hex,sharing=locked \
    --mount=type=cache,id=relyra-rebar3,target=/root/.cache/rebar3,sharing=locked \
    mix local.hex --force && mix local.rebar --force && \
    mix deps.get && mix deps.compile

# NO `COPY . .` — source arrives via the bind mount; relyra path dep compiles at runtime.
COPY demo/ledger_loop/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
```
Notes: `--mount=type=cache` attrs verified — `id` (defaults to `target`), `target`/`dst`/`destination`, `sharing` (`shared`|`private`|`locked`, default `shared`), `ro`, `mode`, `uid`, `gid`. [VERIFIED: docs.docker.com/reference/dockerfile]. The COPY paths are repo-root-relative because the build context is the repo root (path dep at `../..`).

### docker-entrypoint.sh (DKR-03) — lock-hash gate + ecto ordering
```bash
#!/usr/bin/env bash
set -euo pipefail
# Source: CONTEXT D-08 + demo ecto.setup alias (mix.exs:70-75)

mix local.hex --force --if-missing
mix local.rebar --force --if-missing

STAMP="_build/.docker/mix.lock.sha"
CURRENT="$(sha256sum mix.lock | awk '{print $1}')"
mkdir -p "$(dirname "$STAMP")"
if [ ! -f "$STAMP" ] || [ "$(cat "$STAMP")" != "$CURRENT" ]; then
  mix deps.get
  mix deps.compile
  echo "$CURRENT" > "$STAMP"
fi
# relyra path dep compiles implicitly on the first mix task that touches it.

mix ecto.create --quiet || true
mix ledger_loop.relyra.migrate   # MUST precede ecto.migrate (relyra audit/connection tables)
mix ecto.migrate
mix run priv/repo/seeds.exs       # idempotent: Reset.reset!()

exec "$@"                          # compose sets: command: mix phx.server  → PID 1
```
Notes: uses `bash` (justifies the `bash` apk package). If you prefer to drop `bash`, switch to `#!/bin/sh` + POSIX (`set -eu`, `$(...)`, no `pipefail`). `sha256sum` is provided by coreutils/busybox in the hexpm image. The `relyra_build` volume holds `_build/.docker/mix.lock.sha`, so the stamp survives `down`/`up`.

### dev.exs change (DKR-04) — CORRECTED config key
```elixir
# ADD this NEW top-level block (NOT inside the Endpoint live_reload: keyword).
# Source: phoenix-live-reload.hexdocs.pm/readme.html (v1.6.2)
config :phoenix_live_reload,
  backend: :fs_poll,
  backend_opts: [interval: 500]

# LEAVE the existing Endpoint block unchanged — its `patterns` still select trigger files:
# config :ledger_loop, LedgerLoopWeb.Endpoint,
#   live_reload: [web_console_logger: true, patterns: [...]]
```

### docker-compose.yml overlay (DKR-02) — minimal (D-05)
```yaml
# demo_app service — replace inline image+command with build+volumes
  demo_app:
    build:
      context: .                       # repo root (path dep spans the whole repo)
      dockerfile: demo/ledger_loop/Dockerfile.dev
    profiles: ["core"]
    working_dir: /app/demo/ledger_loop
    command: mix phx.server            # entrypoint exec "$@"s this → PID 1
    volumes:
      - .:/app                          # bind mount (live source)
      - relyra_deps:/app/demo/ledger_loop/deps      # mask host deps  (D-04)
      - relyra_build:/app/demo/ledger_loop/_build   # mask host _build (D-04)
      - relyra_hex:/root/.hex
      - relyra_mix:/root/.mix
    depends_on:
      db: { condition: service_healthy }
    # ... existing ports / environment / healthcheck unchanged (per D-05) ...

volumes:        # top-level (D-04)
  relyra_deps:
  relyra_build:
  relyra_hex:
  relyra_mix:
```
Note: keep the existing `ports`/`environment`/`healthcheck` as-is — D-05 forbids the Phase-69 port/proxy changes here.

### .dockerignore (DKR-01, D-07) — repo root
```gitignore
.git/
.planning/
_build/
deps/
demo/ledger_loop/_build/
demo/ledger_loop/deps/
node_modules/
priv/static/assets/
docker-compose*.yml
*.tar
.DS_Store
erl_crash.dump
```
Note: MUST be at repo root — Docker resolves `.dockerignore` relative to the build context root (here `.`), so a `demo/ledger_loop/.dockerignore` would be **silently inert**. [VERIFIED: D-07 evidence + Docker build context semantics]

## Runtime State Inventory

> This phase creates new tooling; it renames nothing. The only runtime state introduced is Docker-managed.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | NEW named volumes `relyra_deps`, `relyra_build`, `relyra_hex`, `relyra_mix` (Docker-managed). No existing data renamed. | None — created on first `up`; wiped by `docker volume rm` / future `make nuke`. |
| Live service config | None — compose `demo_app` is the only edited service; `db`/`keycloak`/`playwright` untouched this phase. | None. |
| OS-registered state | None. | None. |
| Secrets/env vars | None changed. `MIX_ENV`, `PGHOST`, `PGUSER`, `PGPASSWORD` already in compose; no rename. | None. |
| Build artifacts | The lock-hash stamp `_build/.docker/mix.lock.sha` (inside `relyra_build`). Stale only if hand-edited. | Created/managed by entrypoint. |

**Nothing found** in OS-registered state, secrets, or live external service config — verified by scoping the diff to `Dockerfile.dev`, `docker-entrypoint.sh`, `.dockerignore`, the `demo_app` compose block, and `dev.exs`.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Docker + BuildKit | image build (cache mounts) | assumed ✓ (maintainer's Docker Desktop / Compose v2) | — | none — BuildKit is mandatory for cache mounts |
| `hexpm/elixir:1.15.7-erlang-26.1.2-alpine-3.18.4` | base image | pullable from Docker Hub | pinned | none — do not bump (D-06) |
| Alpine 3.18 apk packages | system deps | ✓ verified in index | see §Supporting | `postgresql15-client` explicit if `postgresql-client` ever fails |

**Missing dependencies with no fallback:** none blocking — all are standard and version-verified.
**Note:** Docker itself was not executed during research (research-only context). The verification steps below must be run by the executor on the maintainer's macOS host.

## Validation Architecture

> Lightweight per the phase brief — this is demo/docker tooling, not `lib/` code. No automated test suites; manual Docker verification of the four success criteria. No `mix` gate is affected (no `lib/` change), so `mix qa` / `mix ci.security` / `mix format` / `mix test --warnings-as-errors` stay green by construction.

### Manual Verification (run on macOS host)
| Criterion | Req | Manual check |
|-----------|-----|--------------|
| Source-only edit doesn't re-run deps | DKR-01 | `docker compose --profile core build` once; edit a `.ex`; rebuild → dep layer shows `CACHED`, no `deps.get`. |
| Named volumes mask bind mount, no NIF breakage | DKR-02 | `docker compose --profile core up`; container boots, no `wrong ELF class`/NIF errors; `docker compose exec demo_app ls deps` shows Linux-compiled deps, distinct from host `demo/ledger_loop/deps`. |
| Re-`up` re-resolves only when lock changed | DKR-03 | `up`, then `down`, then `up` again → second boot does NOT run `deps.get` (stamp unchanged). Touch `mix.lock` → next `up` re-resolves. `ecto.create`/`migrate`/seeds idempotent (no errors on re-`up`). |
| `.heex`/CSS live reload across mount | DKR-04 | `up`; open the app; edit a `.heex` template; browser reloads within ~500ms with no container restart and no `deps.get`. **Confirm the corrected `config :phoenix_live_reload` block is in place (Pitfall 1) — this is the #1 silent-failure risk.** |

### Wave 0 Gaps
None — no test infrastructure needed for docker tooling. The "tests" are the four manual receipts above.

## Security Domain

> `security_enforcement` applies to relyra's `lib/` crypto seams — **none are touched** this phase (milestone invariant). The relevant security note is operational, not crypto:

| Concern | Applies | Control |
|---------|---------|---------|
| Dev secret in compose env | Yes (already present) | `POSTGRES_PASSWORD: postgres` and `secret_key_base` are dev-only, pre-existing; not introduced or worsened here. No change. |
| Build context leaks (.git/.planning into image) | Yes | `.dockerignore` (D-07) excludes `.git/`, `.planning/`, `*.tar` — prevents secrets/planning docs entering the build context. [VERIFIED: D-07] |
| Host port exposure | Out of scope | Postgres port / `127.0.0.1` binding is Phase 69 — explicitly NOT this phase (D-05). |
| relyra crypto/parse/replay/audit seams | No | Zero `lib/` change — invariant holds by construction. |

No ASVS category is newly engaged: no auth, session, input-validation, or crypto code is added.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `bash`, `git`, `openssl` exist in Alpine 3.18 main (not individually page-verified; `build-base`/`inotify-tools`/`postgresql15-client` WERE verified). | Supporting stack | Low — all three are long-standing core Alpine packages; if absent, `apk add` errors loudly at build (not silent). Executor will see it immediately. |
| A2 | `sha256sum` is available in the hexpm Alpine image (busybox/coreutils). | Entrypoint | Low — busybox provides `sha256sum` on Alpine. If absent, swap to `sha256sum` from `coreutils` apk or `openssl dgst -sha256`. |
| A3 | Docker Desktop / Compose v2 with BuildKit-on-by-default is the maintainer's environment. | Environment | Medium — if a legacy builder is used, cache mounts no-op (Pitfall 2). Mitigated by `# syntax` header + doc note. |
| A4 | `openssl` likely already present in the hexpm base image (listing it is harmless idempotent). | Supporting stack | Low — redundant install is a no-op. |

## Open Questions

1. **Keep `bash` or go pure POSIX `sh`?**
   - Known: entrypoint logic is simple; `sh` suffices; D-03 lists `bash` and CONTEXT leaves shell style to executor discretion.
   - Recommendation: keep `bash` (already in the apk list, simpler `set -euo pipefail`); not worth optimizing out.

2. **Explicit `postgresql15-client` vs virtual `postgresql-client`?**
   - Known: both resolve in 3.18; virtual is more portable, explicit is less confusing (no 404 surprise).
   - Recommendation: keep `postgresql-client` (matches D-03 verbatim); add a one-line comment that it provides PG15 client, to forestall a "fix."

## Sources

### Primary (HIGH confidence)
- `phoenix-live-reload.hexdocs.pm/readme.html` (redirected from hexdocs.pm/phoenix_live_reload) — `:fs_poll` backend config under `config :phoenix_live_reload` (backend/backend_opts/interval/dirs). **Corrects D-10's config key.**
- `docs.docker.com/build/cache/optimize` — cache mounts NOT persisted in final image; build-time only.
- `docs.docker.com/reference/dockerfile` — full `--mount=type=cache` attribute list (id/target/sharing/ro/mode/uid/gid/from/source); `id` defaults to `target`; `sharing` default `shared`.
- `docs.docker.com/engine/storage/volumes` + `.../bind-mounts` — empty-volume-init copy semantics; bind/volume masking of pre-existing dir contents.
- `pkgs.alpinelinux.org` (v3.18 main) — `build-base` 0.5-r3, `inotify-tools` 3.22.6.0-r2, `postgresql15-client` 15.13-r0 (provides `postgresql-client`, `cmd:pg_isready`, `cmd:psql`).
- Repo files: `demo/ledger_loop/mix.exs` (ecto.setup alias, `~> 1.2` floor), `mix.lock` (`phoenix_live_reload` 1.6.2, `file_system` 1.1.1), `config/dev.exs` (existing live_reload block; no top-level `:phoenix_live_reload`), `docker-compose.yml`, `ledger_loop.relyra.migrate.ex`.

### Secondary (MEDIUM confidence)
- WebSearch (cross-checked with primary) — `:fs_poll` as the documented macOS→Docker bind-mount inotify workaround; Elixir BuildKit cache-mount pattern.
- `github.com/synrc/fs` issue #43, `docker/for-mac` issue #681 — macOS bind-mount inotify event propagation gap (motivates `:fs_poll`).

### Tertiary (LOW confidence)
- General Elixir-in-Docker blog posts (Medium/poeticoding) — corroborating named-volume-for-`deps`/`_build` pattern only; not relied on for specific syntax.

## Metadata

**Confidence breakdown:**
- Standard stack / apk names: HIGH — version-verified against Alpine index.
- BuildKit cache-mount syntax: HIGH — Docker reference + cache docs.
- Named-volume masking: HIGH — Docker storage docs + nested-path reasoning.
- `:fs_poll` config (CORRECTED key): HIGH — authoritative `phoenix_live_reload` 1.6.2 README; this is the single most important finding.
- Entrypoint ordering: HIGH — derived from the demo's own `ecto.setup` alias + migrate task source.

**Research date:** 2026-06-19
**Valid until:** 2026-07-19 (stable — pinned toolchain, mature Docker/Phoenix APIs).
