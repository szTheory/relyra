# Phase 69: Compose split & fleet proxy - Pattern Map

**Mapped:** 2026-08-25
**Files analyzed:** 7
**Analogs found:** 7 / 7

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `docker-compose.yml` | config | request-response / service networking | `docker-compose.yml` (current base graph) | exact extension |
| `docker-compose.override.yml` | config | request-response / host port publishing | `/Users/jon/projects/rulestead/docker-compose.override.yml` | exact role-flow |
| `docker-compose.proxy.yml` | config | request-response / event-driven service discovery | `/Users/jon/projects/rulestead/docker-compose.proxy.yml` | exact role-flow |
| `docker/traefik/compose.yml` | config | request-response / event-driven service discovery | `/Users/jon/projects/scoria/docker/traefik/compose.yml` | exact, mandated verbatim |
| `demo/ledger_loop/config/runtime.exs` | config | transform (environment to endpoint settings) | `demo/ledger_loop/config/runtime.exs` | exact extension |
| `demo/ledger_loop/config/config.exs` | config | transform (compile-time fallback) | `demo/ledger_loop/config/config.exs` | exact, retain fallback |
| `demo/ledger_loop/config/dev.exs` | config | transform (environment to origin allowlist) | `demo/ledger_loop/config/runtime.exs` + current `dev.exs` endpoint block | role-flow match |

`config/config.exs` is an integration point rather than an expected substantive edit: D-05 explicitly preserves its `localhost` fallback. The executor should avoid changing it unless a configuration-order check demonstrates that a narrowly scoped adjustment is required.

## Pattern Assignments

### `docker-compose.yml` (config, request-response / service networking)

**Analog:** current `docker-compose.yml`

**Base graph pattern** (lines 1-47): retain the project name, Phase-68 build/volume/healthcheck graph, and `db` dependency; remove the `profiles: ["core"]` entries so bare `docker compose up` selects `db` and `demo_app`. Remove both current `ports:` sections—those are respectively dropped (`db`) and moved to the automatic overlay (`demo_app`).

```yaml
name: relyra-demo

services:
  db:
    image: postgres:15-alpine
    profiles: ["core"]
    environment:
      POSTGRES_PASSWORD: postgres
    ports:
      - "${PGPORT:-5432}:5432"

  demo_app:
    build:
      context: .
      dockerfile: demo/ledger_loop/Dockerfile.dev
    profiles: ["core"]
    command: mix phx.server
    volumes:
      - .:/app
      - relyra_deps:/app/demo/ledger_loop/deps
      - relyra_build:/app/demo/ledger_loop/_build
    depends_on:
      db:
        condition: service_healthy
    ports:
      - "${PORT:-4000}:4000"
```

**Internal service-address pattern** (lines 73-88): preserve Playwright's internal request path; do not convert it to a browser/proxy hostname.

```yaml
  playwright:
    depends_on:
      demo_app:
        condition: service_healthy
    environment:
      - BASE_URL=http://demo_app:4000
```

**Boundary:** retain Keycloak and Playwright profiles/ports unchanged (lines 49-88). Phase 69 must not add Keycloak labels or proxy environment.

---

### `docker-compose.override.yml` (config, request-response / host port publishing)

**Analog:** `/Users/jon/projects/rulestead/docker-compose.override.yml`

**Automatic solo-overlay pattern** (lines 1-6): comments establish that plain Compose auto-loads this file, while the proxy command deliberately uses explicit `-f` files. Apply the same one-service overlay under `demo_app`, substituting the Phase 69 port variable.

```yaml
# Docker Compose loads this file automatically for the plain local demo path.
# Proxy mode uses explicit `-f` flags and intentionally skips these host ports.
services:
  backend:
    ports:
      - "127.0.0.1:${DEMO_BACKEND_PORT:-4000}:4000"
```

Use exactly one loopback-only mapping: `127.0.0.1:${PORT:-4000}:4000`. Do not declare `db`, proxy labels, or networks here.

---

### `docker-compose.proxy.yml` (config, request-response / event-driven service discovery)

**Analog:** `/Users/jon/projects/rulestead/docker-compose.proxy.yml`

**Proxy endpoint-environment pattern** (lines 1-9): keep environment settings in the overlay so base/solo behavior remains zero-setup. Use Relyra names/defaults: `PHX_HOST: ${RELYRA_HOST:-relyra.localhost}`, `PHX_SCHEME: http`, `PHX_PORT: "80"`, and a `DEMO_CHECK_ORIGINS` default that includes the required localhost and Relyra host patterns.

```yaml
services:
  backend:
    environment:
      PHX_HOST: ${DEMO_BACKEND_HOST:-rulestead.localhost}
      PHX_SCHEME: http
      PHX_PORT: ${DEMO_PROXY_HTTP_PORT:-80}
      DEMO_CHECK_ORIGINS: ${DEMO_CHECK_ORIGINS:-//rulestead.localhost,//*.rulestead.localhost}
```

**Traefik label and dual-network pattern** (lines 10-19): use list-form labels, explicit Docker network selection, router/service linkage, and an explicit backend port. All router and service names must use a static `relyra-` prefix. This overlay attaches only `demo_app` to `default` and `proxy`; never attach `db`.

```yaml
    labels:
      - "traefik.enable=true"
      - "traefik.docker.network=${DEMO_PROXY_NETWORK:-proxy}"
      - "traefik.http.routers.rulestead-${DEMO_HOST_SLUG:-local}-backend.rule=Host(`${DEMO_BACKEND_HOST:-rulestead.localhost}`)"
      - "traefik.http.routers.rulestead-${DEMO_HOST_SLUG:-local}-backend.entrypoints=web"
      - "traefik.http.routers.rulestead-${DEMO_HOST_SLUG:-local}-backend.service=rulestead-${DEMO_HOST_SLUG:-local}-backend"
      - "traefik.http.services.rulestead-${DEMO_HOST_SLUG:-local}-backend.loadbalancer.server.port=4000"
    networks:
      - default
      - proxy
```

**External-network declaration** (lines 43-46): copy the external network and configurable name exactly, using the mandated `DEMO_PROXY_NETWORK` hook.

```yaml
networks:
  proxy:
    external: true
    name: ${DEMO_PROXY_NETWORK:-proxy}
```

No `ports:` belongs in this file. Do not route Keycloak in this phase.

---

### `docker/traefik/compose.yml` (config, request-response / event-driven service discovery)

**Analog:** `/Users/jon/projects/scoria/docker/traefik/compose.yml`

**Full-file pattern (mandated verbatim)** (lines 14-39): create the standalone shared proxy project from this exact service, image pin, command list, loopback port bindings, read-only Docker socket mount, and external network. Preserve `name: dev_proxy` (underscore).

```yaml
name: dev_proxy

services:
  traefik:
    image: traefik:v3.7.1
    restart: unless-stopped
    command:
      - --providers.docker=true
      - --providers.docker.exposedbydefault=false
      - --entrypoints.web.address=:80
      - --api.dashboard=true
      - --api.insecure=true
    ports:
      - "127.0.0.1:80:80"
      - "127.0.0.1:8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - proxy

networks:
  proxy:
    external: true
```

---

### `demo/ledger_loop/config/runtime.exs` (config, transform)

**Analog:** current `demo/ledger_loop/config/runtime.exs`

**Runtime parsing pattern** (lines 19-24): read string environment variables at runtime and parse integer port values immediately before passing them to Phoenix. Place the new public endpoint block outside the current `:prod` branch (preferably `if config_env() != :test`) so the Docker `MIX_ENV=dev` process receives it.

```elixir
if System.get_env("PHX_SERVER") do
  config :ledger_loop, LedgerLoopWeb.Endpoint, server: true
end

config :ledger_loop, LedgerLoopWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT", "4000"))]
```

**Production endpoint convention to preserve** (lines 56-69): `url` is a Phoenix endpoint keyword list with host, port, and scheme. The new dev-capable block follows this shape but defaults to `localhost`, `http`, and the already-read `PORT`; it must not alter production database, secret, or HTTP-bind behavior.

```elixir
host = System.get_env("PHX_HOST") || "example.com"

config :ledger_loop, LedgerLoopWeb.Endpoint,
  url: [host: host, port: 443, scheme: "https"],
  http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}],
  secret_key_base: secret_key_base
```

**Origin-list transform:** use the research pattern in the same non-test block: obtain `DEMO_CHECK_ORIGINS` with default `//localhost,//relyra.localhost,//*.relyra.localhost`, then `String.split(",", trim: true)`. This makes the accepted origins visible/configurable without `check_origin: false`.

---

### `demo/ledger_loop/config/config.exs` (config, transform)

**Analog:** current `demo/ledger_loop/config/config.exs`

**Fallback endpoint pattern** (lines 14-23): preserve this compile-time default. The runtime block is the override mechanism; do not move proxy-specific environment parsing into this file.

```elixir
config :ledger_loop, LedgerLoopWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: LedgerLoopWeb.ErrorHTML, json: LedgerLoopWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: LedgerLoop.PubSub,
  live_view: [signing_salt: "Uo7fHsbv"]
```

**Configuration-order pattern** (lines 41-43): keep environment imports last, allowing `dev.exs` and runtime config to specialize the endpoint.

```elixir
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
```

---

### `demo/ledger_loop/config/dev.exs` (config, transform)

**Analog:** current `demo/ledger_loop/config/dev.exs`

**Development endpoint specialization** (lines 19-27): preserve HTTP binding, reload, debug, secret, and watcher settings. Remove `check_origin: false`; its explicit environment-derived allowlist belongs in the dev-applicable runtime endpoint configuration, where proxy and solo values share a single source of truth.

```elixir
config :ledger_loop, LedgerLoopWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {0, 0, 0, 0}],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "1E2JSI1+eKgEauIWXniOv9+E05Ses3L8mLv7Ux7YwO22vUILloECAPW73JGQkng5",
  watchers: []
```

The existing loopback bind is an application-side defense and must remain; it is compatible with Docker/Traefik because the container's HTTP service is reached over its own network namespace.

## Shared Patterns

### Solo-first Compose layering

**Sources:** `docker-compose.yml` lines 1-47; `/Users/jon/projects/rulestead/docker-compose.override.yml` lines 1-6
**Apply to:** base Compose file and `docker-compose.override.yml`

- Base contains the portable internal service graph and no `demo_app`/`db` host ports.
- The auto-loaded override owns the sole local app publication, bound to `127.0.0.1`.
- `db` remains reachable as `db:5432` only; internal consumers retain service-name URLs.

### Explicit Traefik discovery

**Source:** `/Users/jon/projects/rulestead/docker-compose.proxy.yml` lines 10-19, 43-46
**Apply to:** `docker-compose.proxy.yml`

Use all of: `traefik.enable`, selected `traefik.docker.network`, router Host rule, entrypoint, explicit router-service binding, explicit service backend port, and dual `default`/external-network membership. Router and service identifiers must be globally unique `relyra-*` names.

### Local-only exposure

**Sources:** `/Users/jon/projects/rulestead/docker-compose.override.yml` lines 4-6; `/Users/jon/projects/scoria/docker/traefik/compose.yml` lines 29-31
**Apply to:** all host port mappings

Every published port uses `127.0.0.1`; neither overlay may publish PostgreSQL. The Traefik dashboard is likewise loopback-only.

### Endpoint configuration precedence

**Sources:** `demo/ledger_loop/config/config.exs` lines 14-23, 41-43; `demo/ledger_loop/config/runtime.exs` lines 19-24, 56-69; `demo/ledger_loop/config/dev.exs` lines 19-27
**Apply to:** demo endpoint configuration

Keep compile-time `localhost` as a fallback, parse environment in `runtime.exs` for non-test execution, and retain dev-only operational settings in `dev.exs`. Replace the broad origin bypass with a concrete list derived from `DEMO_CHECK_ORIGINS`.

## No Analog Found

None. The overlays and proxy have direct, maintained sibling-project analogs; the endpoint changes extend the current demo configuration patterns.

## Metadata

**Analog search scope:** repository root Compose/configuration files; `/Users/jon/projects/rulestead` Compose overlays; `/Users/jon/projects/scoria/docker/traefik` proxy Compose project
**Files scanned:** 7 direct analog/target files
**Pattern extraction date:** 2026-08-25
