# Phase 68: Build caching & correctness - Context

**Gathered:** 2026-06-19 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

A developer iterates on the `demo/ledger_loop` Phoenix app **in Docker as fast as native** —
small source/style edits reload instantly and never trigger a dependency re-fetch or recompile.

**In scope (DKR-01..04):** `demo/ledger_loop/Dockerfile.dev`, `demo/ledger_loop/docker-entrypoint.sh`,
a repo-root `.dockerignore`, a **minimal named-volume overlay** added to the existing
`docker-compose.yml`, and `demo/ledger_loop/config/dev.exs`.

**Explicitly NOT this phase (deferred to later v1.10 phases):**
- The base/override/proxy compose split + dropping the published Postgres port → **Phase 69**.
- The shared Traefik proxy + `*.localhost` routing → **Phase 69**.
- Keycloak hostname / `KC_PROXY_HEADERS` / realm URL work → **Phase 70**.
- `Makefile` launcher, URL banner, `scripts/demo` delegation → **Phase 71**.
- `guides/docker_dev_dx.md` and README routing → **Phase 72**.

**Milestone-wide invariant:** demo + docker + docs ONLY. Zero changes to `lib/` security seams,
public API, behaviour callbacks, protocol surface, or the Hex package whitelist (`mix.exs`
`package.files`). Repo gates (`mix qa`, `mix ci.security`, `mix format --check-formatted`,
`mix test --warnings-as-errors`) must stay green — guaranteed here by not touching `lib/`.
</domain>

<decisions>
## Implementation Decisions

### Path-dep build-caching split (central DKR-01 decision)
- **D-01:** `Dockerfile.dev` compiles only the **Hex deps tree** at image-build time — `COPY demo/ledger_loop/mix.exs demo/ledger_loop/mix.lock` first, then `mix deps.get` + `mix deps.compile`. The `relyra` path dep is **left to compile at entrypoint/runtime** from the bind-mounted parent source. The Dockerfile does **NOT** `COPY . .` and does **NOT** attempt to compile `relyra` at build time.
  - Evidence: `demo/ledger_loop/mix.exs` declares `{:relyra, path: "../.."}`; `mix.lock` has 36 Hex entries and contains no `relyra` (a path dep is never in the lock and cannot be fetched by `deps.get`). North-star line 58 ("do not `COPY . .`").

### Where the dependency cache persists
- **D-02:** Two-tier cache. (a) BuildKit **cache mounts** (`/root/.hex`, `/root/.cache/rebar3`) speed the download/build step during image builds but do not persist into the running container. (b) The compiled artifacts the running container uses — `deps/` and `_build/` — live in **named volumes** mounted over the bind mount; they are NOT served from the image layer (the bind mount `.:/app` would otherwise shadow them, and `_build` must be writable because `relyra` compiles at runtime).
- **D-03:** `Dockerfile.dev` header is `# syntax=docker/dockerfile:1.7`; system packages installed: `inotify-tools bash postgresql-client build-base git openssl`. Build requires BuildKit (`DOCKER_BUILDKIT=1` / Compose v2 default) for the cache mounts.

### Exact named-volume mount paths (nested working dir)
- **D-04:** Volumes attach at the **nested demo paths**, not repo-root paths:
  - `relyra_deps:/app/demo/ledger_loop/deps`
  - `relyra_build:/app/demo/ledger_loop/_build`
  - `relyra_hex:/root/.hex`
  - `relyra_mix:/root/.mix`
  - Evidence: `docker-compose.yml:22` `working_dir: /app/demo/ledger_loop`. The north-star's generic `/app/deps` (line 44) is **underspecified** — using it would mask the wrong directory and reintroduce arch breakage.
- **D-05:** Phase 68 adds these volumes as a **minimal overlay on the existing `docker-compose.yml`** `demo_app` service (switch `image:` → `build:` from `Dockerfile.dev`, drop the inline `command:` install block, add `volumes:` + top-level `volumes:` keys). Do **NOT** perform the Phase-69 base/override/proxy split or touch the published Postgres port here.

### Toolchain pin
- **D-06:** **Keep** the existing pin `hexpm/elixir:1.15.7-erlang-26.1.2-alpine-3.18.4` — move it from the inline `image:` to `FROM` in `Dockerfile.dev`. Do **NOT** bump to the repo CI matrix (Elixir 1.19.5 / OTP 27&28).
  - Evidence: `demo/ledger_loop/mix.exs` requires only `elixir: "~> 1.15"`; the 1.15.7 image is the proven running baseline (`docker-compose.yml:18`); a bump forces a full recompile + dep-resolution-drift risk for zero phase-68 benefit. Reversal (one-line `FROM` bump) is cheap if a dep ever fails to build.

### `.dockerignore` placement
- **D-07:** A **single repo-root `.dockerignore`** (not a demo-dir file, not both). Excludes at least: `_build/`, `deps/` (root and `demo/ledger_loop/`), `node_modules/`, `.git/`, `.planning/`, `priv/static/assets/`, `docker-compose*.yml`, `*.tar`, and OS cruft (`.DS_Store`, `erl_crash.dump`).
  - Evidence: the build context spans the repo root (path dep at `../..`); Docker resolves `.dockerignore` relative to the context root, so a `demo/ledger_loop/.dockerignore` would be silently inert.

### Entrypoint: lock-hash gate + ecto idempotency (includes a north-star correction)
- **D-08:** `demo/ledger_loop/docker-entrypoint.sh` flow:
  1. `mix local.hex --force --if-missing` / `mix local.rebar --force --if-missing`
  2. Compute `sha256sum mix.lock`, compare to `_build/.docker/mix.lock.sha`. If changed (or stamp absent): `mix deps.get && mix deps.compile`, then rewrite the stamp. (`relyra` compiles implicitly on the first `mix` invocation that touches it.)
  3. `mix ecto.create --quiet || true`
  4. **`mix ledger_loop.relyra.migrate` BEFORE `mix ecto.migrate`** — then run the demo's idempotent seeds.
  5. `exec "$@"`.
- **D-09:** Compose sets `command: mix phx.server`; the entrypoint `exec "$@"`s it so the server is PID 1 (clean signals) and Compose owns the command.
  - Evidence / **correction:** the demo's `ecto.setup` alias (`demo/ledger_loop/mix.exs`) runs `ecto.create` → `ledger_loop.relyra.migrate` (custom task at `demo/ledger_loop/lib/mix/tasks/ledger_loop.relyra.migrate.ex`) → `ecto.migrate` → seeds. The north-star's literal `ecto.migrate`-only text would skip relyra's audit/connection tables and 500 every SAML/admin path. Seeds are idempotent (`seeds.exs` → `LedgerLoop.Demo.Reset.reset!()`), so safe to re-run on every `up`.

### `:fs_poll` live reload
- **D-10:** Set `phoenix_live_reload` to `backend: :fs_poll, backend_opts: [interval: 500]` **unconditionally** in `demo/ledger_loop/config/dev.exs`, merged into the existing `live_reload:` keyword (today `web_console_logger: true` + `patterns: [...]`, no `backend:`). No env gate.
  - Evidence: default FS-event backend does not fire across the macOS→Docker bind mount; demo has no esbuild/tailwind watchers (`watchers: []`), so live reload is the entire asset story. Native `mix phx.server` outside Docker is functionally unaffected (polls instead of inotify; minor idle CPU only). Env-gating is a trivial follow-up if native polling ever proves annoying.

### Claude's Discretion
- Exact wording of cache-mount `--mount=type=cache,...` IDs, the precise `inotify-tools` vs `bash`
  package list ordering, and shell style in `docker-entrypoint.sh` are left to the planner/executor
  provided D-01..D-10 hold.
- Confirm during execution that `phoenix_live_reload ~> 1.2` accepts `backend: :fs_poll` with
  `backend_opts: [interval: ...]` (well-established public API; quick check, not blocking research).

### Folded Todos
None — `todo.match-phase 68` returned 0 matches.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `/Users/jon/.claude/plans/does-this-not-have-cozy-lighthouse.md` — approved design north-star (Section A "Fast, cached, correct container build" is the phase-68 spec; note its `/app/deps` paths are generic — use the nested paths in D-04, and its bare `ecto.migrate` is corrected by D-08).
- `.planning/REQUIREMENTS.md` — DKR-01..04 acceptance criteria + Out-of-Scope exclusions.
- `.planning/ROADMAP.md` — Phase 68 goal, success criteria, and scope note (and the 68→69→70→71→72 boundary).
- `docker-compose.yml` (repo root) — the existing `demo_app`/`db`/`keycloak`/`playwright` services being modified.
- `demo/ledger_loop/mix.exs` — `{:relyra, path: "../.."}` path dep + `ecto.setup` alias chain.
- `demo/ledger_loop/lib/mix/tasks/ledger_loop.relyra.migrate.ex` — the custom migrate task the entrypoint must run before `ecto.migrate`.
- `demo/ledger_loop/config/dev.exs` — current `live_reload:` keyword to extend with `:fs_poll`.
- `scripts/demo` (repo root) — current launcher; NOT modified in phase 68 (Phase 71), but referenced for behavior parity.
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- A working (if naive) `docker-compose.yml` at the repo root with `demo_app`, `db`, `keycloak`,
  `playwright` services on Compose `profiles` (`core`, `keycloak`, `browser`) and healthchecks.
- `demo/ledger_loop` is a complete Phoenix 1.8.7 app with Bandit, Ecto/Postgres, LiveView,
  `phoenix_live_reload ~> 1.2`, and a `ledger_loop.relyra.migrate` mix task + idempotent
  `LedgerLoop.Demo.Reset.reset!()` seed path.
- `demo/ledger_loop/.gitignore` already enumerates the artifact dirs to exclude (`/_build/`,
  `/deps/`, `erl_crash.dump`, `*.tar`) — a basis for the repo-root `.dockerignore`.

### Established Patterns
- **Path dependency:** the demo compiles the parent `relyra` lib via `{:relyra, path: "../.."}`,
  forcing the Docker build context / bind mount to span the whole repo root and forcing relyra to
  compile at runtime (not at image-build).
- **Bind-mount dev:** current setup bind-mounts `.:/app` with `working_dir: /app/demo/ledger_loop`
  and runs deps/setup inline on every `up` (the slow path being replaced).
- **Idempotent seeds:** `seeds.exs` calls `LedgerLoop.Demo.Reset.reset!()`, so re-running on every
  boot is safe (a reset, not an append).

### Integration Points
- Compose `demo_app` service: `image:` → `build:` (Dockerfile.dev), drop inline `command:`, add
  `volumes:` (D-04) + entrypoint; top-level `volumes:` keys declared.
- `config/dev.exs` `live_reload:` keyword extended with `backend: :fs_poll`.
- The entrypoint depends on `db` being healthy (existing `depends_on: { db: { condition: service_healthy }}`).
</code_context>

<specifics>
## Specific Ideas

- Stamp file: `sha256(mix.lock)` written to `_build/.docker/mix.lock.sha` (inside the `relyra_build`
  volume), gating dependency re-resolution.
- `:fs_poll` interval pinned at `500` ms (north-star line 62).
- Named-volume prefix `relyra_*` to avoid cross-project collisions when sibling lib demos coexist
  (anticipating Phase 69 fleet coexistence; harmless here).
</specifics>

<deferred>
## Deferred Ideas

- **Env-gated `:fs_poll`** (e.g. only when `RELYRA_DOCKER` set) — deferred; unconditional chosen
  for simplicity. Trivial follow-up if native-`mix` polling CPU ever proves annoying.
- **Compose base/override/proxy split + drop published Postgres port** — Phase 69.
- **Toolchain bump to repo CI matrix (1.19.5/OTP28)** — not pursued; revisit only if a dep fails
  to build under 1.15.7/OTP26.
- TLS via mkcert, hashed per-checkout hostnames, production multi-stage release Dockerfile — all
  milestone-level deferred (see REQUIREMENTS.md "Future Requirements").

### Reviewed Todos (not folded)
None — `todo.match-phase 68` returned 0 matches.
</deferred>
