# Phase 69: Compose split & fleet proxy - Context

**Gathered:** 2026-06-19 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

A solo `docker compose up` stays zero-setup at `localhost` (Postgres NOT published to a host
port), **and** an opt-in shared Traefik proxy lets multiple sibling lib demos run at
`*.localhost` simultaneously with no port contention.

**In scope (FLEET-01..03):** `docker-compose.yml` (base, split), **new** `docker-compose.override.yml`,
**new** `docker-compose.proxy.yml`, **new** `docker/traefik/compose.yml`, and the demo's
`config/runtime.exs` / `config/config.exs` for proxy-host endpoint `url`/`check_origin`.

**Explicitly NOT this phase:**
- Keycloak Traefik labels, `KC_HOSTNAME`/`KC_PROXY_HEADERS`, realm URL fixes → **Phase 70**.
- `Makefile` (incl. the `make proxy` target), URL banner, `scripts/demo` delegation → **Phase 71**.
- `.env.example`, `guides/docker_dev_dx.md`, README routing → **Phase 71/72**.
- Anything under `lib/` (security seams, public API, behaviours, protocol), Hex package whitelist.

**Milestone-wide invariant (v1.10):** demo + docker + docs ONLY. Repo gates (`mix qa`,
`mix ci.security`, `mix format --check-formatted`, `mix test --warnings-as-errors`) stay green —
guaranteed by not touching `lib/`.
</domain>

<decisions>
## Implementation Decisions

### Compose file split (core restructure)
- **D-01:** Three files. `docker-compose.yml` stays the **base** (keep `name: relyra-demo`):
  `demo_app` keeps its Phase-68 `build:`/entrypoint/named-volumes/healthcheck but **loses its
  `ports:`**; `db` **loses its `ports:`** entirely. Keycloak/playwright services unchanged.
- **D-02:** **New `docker-compose.override.yml`** (Compose auto-loads it — the solo path):
  publishes **only** `127.0.0.1:${PORT:-4000}:4000` for `demo_app`. Bind to `127.0.0.1`, never
  `0.0.0.0`. Does **not** publish `db`. (No proxy config here, so the proxy is never a hard
  dependency of the contributor path.)
- **D-03:** **New `docker-compose.proxy.yml`** (explicit `-f` — the fleet path): adds `demo_app`
  Traefik labels (`Host(\`relyra.localhost\`)`, `loadbalancer.server.port=4000`, `entrypoints=web`),
  joins `default` + external `proxy` network, sets the proxy-host endpoint env (D-05). **No host
  ports.** Follows the `rulestead/docker-compose.proxy.yml` template (env + labels + `relyra-*`
  router/service names).

### Drop the published Postgres port (FLEET-01)
- **D-04:** Remove `db`'s `${PGPORT:-5432}:5432` from the base and do **not** re-add it in override.
  Postgres is reachable only as service `db` on the internal network in **both** paths. This is the
  machine-wide `:5432` collision fix. (A commented power-user opt-in line is acceptable; default =
  unpublished.)

### Phoenix endpoint url/check_origin plumbing (FLEET-03)
- **D-05:** Make the endpoint host/scheme/port **env-driven in `config/runtime.exs`** in a block
  that applies in **dev** (the demo runs `MIX_ENV=dev` in Docker — the current `url`/`https` block
  is `:prod`-gated and does not apply): read `PHX_HOST` (default `localhost`), `PHX_SCHEME`
  (default `http`), `PHX_PORT` (default = `PORT`). `proxy.yml` sets `PHX_HOST=relyra.localhost`,
  `PHX_SCHEME=http`, `PHX_PORT=80`. Keep `config.exs` `url: [host: "localhost"]` as the fallback.
- **D-06:** **check_origin = env-driven allowlist** (user-confirmed). Replace the current
  `dev.exs` `check_origin: false` with a value driven from an env list (e.g. `DEMO_CHECK_ORIGINS`)
  defaulting to `["//localhost", "//relyra.localhost", "//*.relyra.localhost"]`; `proxy.yml` can
  override. This is what lets the operator-UI **LiveView websocket** connect in proxy mode while
  being explicit rather than wide-open.

### FakeIdP recipient is host-independent — no fixture/realm changes here
- **D-07:** Do **NOT** touch `demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex` or any realm file
  in Phase 69. The seeded "Enabled" connection's `acs_url` is a **fabricated fixed value**
  (`https://ledgerloop.example.com/sso/acs`), and `fake_idp_controller.ex` uses that *same* value
  for both `destination` and `recipient` — so FakeIdP recipient/Destination verification is
  **host-independent** and already passes at `localhost` or `relyra.localhost`. Phase 69's FLEET-03
  burden therefore reduces to (a) `check_origin` accepting the proxy host (D-06) and (b) `url`
  reflecting the proxy host for displayed/generated absolute URLs (D-05). The real proxy-host ACS
  round-trip with a real IdP is **Phase 70 (Keycloak)**.

### Keycloak / phase boundary
- **D-08:** `proxy.yml` routes **only** `demo_app` in Phase 69. Keycloak Traefik labels +
  `KC_HOSTNAME`/`KC_PROXY_HEADERS=xforwarded` + realm URL fixes are **Phase 70** (roadmap 70 scope
  note: "Touches the keycloak service/env in `docker-compose.proxy.yml`"). Phase 69 leaves keycloak
  as-is (its own profile/host port).

### Shared Traefik proxy — match the maintainer's newest convention verbatim
- **D-09:** **New `docker/traefik/compose.yml`** matching `scoria/docker/traefik/compose.yml`
  verbatim: `name: dev_proxy` (underscore — scoria's actual file, **not** "dev-proxy"),
  `image: traefik:v3.7.1` (v3.7+ required — older Traefik can't talk to Docker 29.x API),
  command flags `--providers.docker=true --providers.docker.exposedbydefault=false
  --entrypoints.web.address=:80 --api.dashboard=true --api.insecure=true`, ports
  `127.0.0.1:80:80` + `127.0.0.1:8080:8080`, socket mounted `:ro`, external `proxy` network.
- **D-10:** The **`make proxy` target is Phase 71** (no `Makefile` in Phase 69 scope). Phase 69's
  SC2 is verified via the raw equivalent: `docker network create proxy` (idempotent) +
  `docker compose -f docker/traefik/compose.yml up -d` (user-confirmed: raw commands now, wrapper
  in 71).

### Env hooks / defaults (no .env.example yet)
- **D-11:** Phase 69 creates **no** `.env.example` (Phase 71). All proxy/host config carries inline
  Compose defaults so both paths work with zero env file: `${PORT:-4000}`,
  `${RELYRA_HOST:-relyra.localhost}` (a.k.a. the `PHX_HOST` override hook), external network name
  defaulted (`${DEMO_PROXY_NETWORK:-proxy}`). Single relyra checkout assumed (no hashed per-checkout
  hostnames).

### Naming / collision-avoidance
- **D-12:** Base keeps `name: relyra-demo`. All Traefik **router + service names prefixed `relyra-`**
  (global Traefik namespace across all sibling libs) to avoid silent cross-project collisions. Use a
  static prefix (no host-slug hashing, per the locked "single checkout at a time" decision).

### Claude's Discretion
- Exact `relyra-*` router/service label suffixes (e.g. `relyra-demo_app` vs `relyra-local-app`),
  the precise env var names for the check_origin list, and whether to keep a commented
  power-user Postgres-port opt-in — left to planner/executor provided D-01..D-12 hold.
- Whether the dev-applicable `runtime.exs` block is unconditional or `config_env() != :test`
  gated (pick whichever keeps `mix test` clean) — executor's call.

### Folded Todos
None — `todo.match-phase 69` returned 0 matches.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `/Users/jon/.claude/plans/does-this-not-have-cozy-lighthouse.md` — approved design north-star.
  **Section B "Compose restructure (solo-first, proxy-optional)"** + **Section C "Phoenix endpoint
  config for proxy host"** are the Phase-69 spec. (Section D Keycloak = Phase 70.)
- `.planning/REQUIREMENTS.md` — FLEET-01..03 acceptance criteria.
- `.planning/ROADMAP.md` — Phase 69 goal, success criteria, scope note, and the 69→70→71→72 boundary.
- `.planning/phases/68-build-caching-correctness/68-CONTEXT.md` — the upstream Dockerfile.dev /
  named-volume / entrypoint / `:fs_poll` decisions Phase 69 builds on.
- `docker-compose.yml` (repo root) — the base being split (current `demo_app`/`db` `ports:` to move/drop).
- `/Users/jon/projects/scoria/docker/traefik/compose.yml` — verbatim template for `docker/traefik/compose.yml`.
- `/Users/jon/projects/rulestead/docker-compose.override.yml` + `docker-compose.proxy.yml` —
  closest Phoenix template for the override/proxy split (PHX_HOST env + Traefik labels + `relyra-*` prefix).
- `demo/ledger_loop/config/runtime.exs`, `config/config.exs`, `config/dev.exs` — endpoint
  `url`/`check_origin` to make env-driven.
- `demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_controller.ex` +
  `lib/ledger_loop/demo/fixtures.ex` — proof the FakeIdP recipient/Destination is host-independent
  (do NOT modify in Phase 69).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `docker-compose.yml` already has `demo_app` building from `Dockerfile.dev` with the Phase-68
  named volumes + healthcheck + `command: mix phx.server`; Phase 69 only splits ports out and
  adds overlays.
- `scoria`/`rulestead`/`sigra` sibling repos provide the exact proxy + override/proxy-split
  conventions to replicate (gold standard = scoria for the proxy, rulestead for the Phoenix split).
- `demo/ledger_loop/config/runtime.exs` already reads `PORT`; the `PHX_HOST`/`PHX_SCHEME` pattern
  is a natural extension (rulestead mirrors it).

### Established Patterns
- **Solo-first, proxy-optional:** auto-loaded `override.yml` for the contributor path; explicit
  `-f proxy.yml` for fleet — the proxy is never a hard dependency.
- **Split-horizon:** internal calls use service names (`db`, `demo_app:4000` — e.g. the playwright
  service's `BASE_URL=http://demo_app:4000`); `*.localhost` is **browser-only**.
- **Host-independent FakeIdP:** seeded `acs_url` + FakeIdP signer fabricate matching
  Destination/Recipient, so the demo login verifies at any host without re-seeding.

### Integration Points
- `demo_app` `ports:` → moves to `override.yml` (`127.0.0.1:${PORT:-4000}:4000`).
- `db` `ports:` → removed (FLEET-01).
- `proxy.yml` joins the external `proxy` network created by `docker/traefik/compose.yml`.
- `runtime.exs` endpoint `url`/`check_origin` ← `PHX_HOST`/`PHX_SCHEME`/`PHX_PORT`/`DEMO_CHECK_ORIGINS`
  env set by `proxy.yml`.
</code_context>

<specifics>
## Specific Ideas

- Traefik pin `traefik:v3.7.1`; proxy project `name: dev_proxy`; external network `proxy`;
  dashboard `127.0.0.1:8080`; all host ports bound to `127.0.0.1`.
- Default proxy host `relyra.localhost` (override hook `RELYRA_HOST`/`PHX_HOST`).
- check_origin default allowlist `["//localhost", "//relyra.localhost", "//*.relyra.localhost"]`.
- `make proxy` equivalent for Phase-69 verification: `docker network create proxy && docker compose -f docker/traefik/compose.yml up -d`.
</specifics>

<deferred>
## Deferred Ideas

- **Keycloak behind the proxy** (labels, `KC_HOSTNAME`, `KC_PROXY_HEADERS`, realm URL fixes) — Phase 70.
- **`Makefile` / `make proxy` target / URL banner / `scripts/demo` delegation** — Phase 71.
- **`.env.example`** — Phase 71.
- **Docs (`guides/docker_dev_dx.md`, README routing)** — Phase 72.
- **TLS via mkcert, hashed per-checkout hostnames, dnsmasq for Safari/curl `*.localhost`** —
  milestone-level deferred (see REQUIREMENTS "Future Requirements").
- **Re-seeding the FakeIdP connection `acs_url` to the proxy host** — unnecessary (host-independent);
  the real proxy-host ACS work belongs to the Keycloak path in Phase 70.

### Reviewed Todos (not folded)
None — `todo.match-phase 69` returned 0 matches.
</deferred>
