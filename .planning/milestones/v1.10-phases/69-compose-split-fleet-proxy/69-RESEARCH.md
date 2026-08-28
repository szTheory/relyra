# Phase 69: Compose split & fleet proxy - Research

**Researched:** 2026-08-16  
**Domain:** Docker Compose overlays, shared Traefik Docker-provider routing, and Phoenix runtime endpoint configuration  
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Compose file split (core restructure)
- **D-01:** Three files. `docker-compose.yml` stays the **base** (keep `name: relyra-demo`): `demo_app` keeps its Phase-68 `build:`/entrypoint/named-volumes/healthcheck but **loses its `ports:`**; `db` **loses its `ports:`** entirely. Keycloak/playwright services unchanged.
- **D-02:** **New `docker-compose.override.yml`** (Compose auto-loads it — the solo path): publishes **only** `127.0.0.1:${PORT:-4000}:4000` for `demo_app`. Bind to `127.0.0.1`, never `0.0.0.0`. Does **not** publish `db`. (No proxy config here, so the proxy is never a hard dependency of the contributor path.)
- **D-03:** **New `docker-compose.proxy.yml`** (explicit `-f` — the fleet path): adds `demo_app` Traefik labels (`Host(\`relyra.localhost\`)`, `loadbalancer.server.port=4000`, `entrypoints=web`), joins `default` + external `proxy` network, sets the proxy-host endpoint env (D-05). **No host ports.** Follows the `rulestead/docker-compose.proxy.yml` template (env + labels + `relyra-*` router/service names).

### Drop the published Postgres port (FLEET-01)
- **D-04:** Remove `db`'s `${PGPORT:-5432}:5432` from the base and do **not** re-add it in override. Postgres is reachable only as service `db` on the internal network in **both** paths. This is the machine-wide `:5432` collision fix. (A commented power-user opt-in line is acceptable; default = unpublished.)

### Phoenix endpoint url/check_origin plumbing (FLEET-03)
- **D-05:** Make the endpoint host/scheme/port **env-driven in `config/runtime.exs`** in a block that applies in **dev** (the demo runs `MIX_ENV=dev` in Docker — the current `url`/`https` block is `:prod`-gated and does not apply): read `PHX_HOST` (default `localhost`), `PHX_SCHEME` (default `http`), `PHX_PORT` (default = `PORT`). `proxy.yml` sets `PHX_HOST=relyra.localhost`, `PHX_SCHEME=http`, `PHX_PORT=80`. Keep `config.exs` `url: [host: "localhost"]` as the fallback.
- **D-06:** **check_origin = env-driven allowlist** (user-confirmed). Replace the current `dev.exs` `check_origin: false` with a value driven from an env list (e.g. `DEMO_CHECK_ORIGINS`) defaulting to `["//localhost", "//relyra.localhost", "//*.relyra.localhost"]`; `proxy.yml` can override. This is what lets the operator-UI **LiveView websocket** connect in proxy mode while being explicit rather than wide-open.

### FakeIdP recipient is host-independent — no fixture/realm changes here
- **D-07:** Do **NOT** touch `demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex` or any realm file in Phase 69. The seeded "Enabled" connection's `acs_url` is a **fabricated fixed value** (`https://ledgerloop.example.com/sso/acs`), and `fake_idp_controller.ex` uses that *same* value for both `destination` and `recipient` — so FakeIdP recipient/Destination verification is **host-independent** and already passes at `localhost` or `relyra.localhost`. Phase 69's FLEET-03 burden therefore reduces to (a) `check_origin` accepting the proxy host (D-06) and (b) `url` reflecting the proxy host for displayed/generated absolute URLs (D-05). The real proxy-host ACS round-trip with a real IdP is **Phase 70 (Keycloak)**.

### Keycloak / phase boundary
- **D-08:** `proxy.yml` routes **only** `demo_app` in Phase 69. Keycloak Traefik labels + `KC_HOSTNAME`/`KC_PROXY_HEADERS=xforwarded` + realm URL fixes are **Phase 70** (roadmap 70 scope note: "Touches the keycloak service/env in `docker-compose.proxy.yml`"). Phase 69 leaves keycloak as-is (its own profile/host port).

### Shared Traefik proxy — match the maintainer's newest convention verbatim
- **D-09:** **New `docker/traefik/compose.yml`** matching `scoria/docker/traefik/compose.yml` verbatim: `name: dev_proxy` (underscore — scoria's actual file, **not** "dev-proxy"), `image: traefik:v3.7.1` (v3.7+ required — older Traefik can't talk to Docker 29.x API), command flags `--providers.docker=true --providers.docker.exposedbydefault=false --entrypoints.web.address=:80 --api.dashboard=true --api.insecure=true`, ports `127.0.0.1:80:80` + `127.0.0.1:8080:8080`, socket mounted `:ro`, external `proxy` network.
- **D-10:** The **`make proxy` target is Phase 71** (no `Makefile` in Phase 69 scope). Phase 69's SC2 is verified via the raw equivalent: `docker network create proxy` (idempotent) + `docker compose -f docker/traefik/compose.yml up -d` (user-confirmed: raw commands now, wrapper in 71).

### Env hooks / defaults (no .env.example yet)
- **D-11:** Phase 69 creates **no** `.env.example` (Phase 71). All proxy/host config carries inline Compose defaults so both paths work with zero env file: `${PORT:-4000}`, `${RELYRA_HOST:-relyra.localhost}` (a.k.a. the `PHX_HOST` override hook), external network name defaulted (`${DEMO_PROXY_NETWORK:-proxy}`). Single relyra checkout assumed (no hashed per-checkout hostnames).

### Naming / collision-avoidance
- **D-12:** Base keeps `name: relyra-demo`. All Traefik **router + service names prefixed `relyra-`** (global Traefik namespace across all sibling libs) to avoid silent cross-project collisions. Use a static prefix (no host-slug hashing, per the locked "single checkout at a time" decision).

### the agent's Discretion
- Exact `relyra-*` router/service label suffixes (e.g. `relyra-demo_app` vs `relyra-local-app`), the precise env var names for the check_origin list, and whether to keep a commented power-user Postgres-port opt-in — left to planner/executor provided D-01..D-12 hold.
- Whether the dev-applicable `runtime.exs` block is unconditional or `config_env() != :test` gated (pick whichever keeps `mix test` clean) — executor's call.

### Deferred Ideas (OUT OF SCOPE)
- **Keycloak behind the proxy** (labels, `KC_HOSTNAME`, `KC_PROXY_HEADERS`, realm URL fixes) — Phase 70.
- **`Makefile` / `make proxy` target / URL banner / `scripts/demo` delegation** — Phase 71.
- **`.env.example`** — Phase 71.
- **Docs (`guides/docker_dev_dx.md`, README routing)** — Phase 72.
- **TLS via mkcert, hashed per-checkout hostnames, dnsmasq for Safari/curl `*.localhost`** — milestone-level deferred (see REQUIREMENTS "Future Requirements").
- **Re-seeding the FakeIdP connection `acs_url` to the proxy host** — unnecessary (host-independent); the real proxy-host ACS work belongs to the Keycloak path in Phase 70.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FLEET-01 | Solo `docker compose up` on localhost without a published Postgres port. | Base/automatic override split, unprofiled core services, loopback-only app port, internal-only `db`. |
| FLEET-02 | Opt-in external-network Traefik routing at `relyra.localhost`, with no solo proxy dependency. | Explicit `-f` fleet command, external `proxy` network, isolated Traefik project, unique `relyra-*` labels. |
| FLEET-03 | Correct Phoenix public URL and origin checks in solo and proxy modes. | Dev-applicable runtime endpoint configuration plus explicit origin allowlist. |
</phase_requirements>

## Project Constraints (from AGENTS.md)

- Keep this milestone to demo, Docker, and docs; do not change `lib/`, public APIs, behaviour callbacks, protocol surface, or `mix.exs` Hex whitelist. [VERIFIED: AGENTS.md]
- Preserve all six SAML security invariants and do not bypass the named crypto, XML, policy, audit, or behaviour seams. [VERIFIED: AGENTS.md]
- Before a push, `mix qa`, `mix test --warnings-as-errors`, `mix ci.security`, and `mix format --check-formatted` must pass; never weaken the adversarial XML corpus. [VERIFIED: AGENTS.md]
- Use conventional commits and the stipulated co-author trailer; do not hand-edit `CHANGELOG.md` or manually publish to Hex. [VERIFIED: AGENTS.md]

## Summary

Implement a strict three-file Compose topology: a base service graph with no published app or database ports, an auto-loaded loopback-only solo override, and an explicitly selected fleet overlay. Docker Compose applies later files after the base and supports an externally managed network for services shared across Compose projects. [CITED: https://docs.docker.com/compose/how-tos/multiple-compose-files/merge/] [CITED: https://docs.docker.com/compose/how-tos/networking/]

The existing base assigns both `db` and `demo_app` to the `core` profile. Services with a `profiles` attribute are skipped by bare `docker compose up`, so FLEET-01 requires removing that attribute from these two solo-core services; retain optional profiles on Keycloak and Playwright. [VERIFIED: docker-compose.yml] [CITED: https://docs.docker.com/compose/how-tos/profiles/]

The fleet overlay should attach only `demo_app` to `proxy`, keep it attached to the project default network for `db`, and configure the proxy-facing Phoenix URL at runtime. Traefik needs explicit router-to-service labels, a port label, and the Docker network label so a service without a host-published port is deterministically reachable from the shared proxy. [CITED: https://doc.traefik.io/traefik/v2.10/providers/docker/] [CITED: https://doc.traefik.io/traefik/v2.10/routing/providers/docker/]

**Primary recommendation:** Remove `core` profiles from `db`/`demo_app`; preserve the Phase-68 graph in the base; expose port 4000 only through the automatic solo override; and use `docker compose -f docker-compose.yml -f docker-compose.proxy.yml --profile core up` only after correcting the profile command to omit `--profile core` once services are unprofiled. [VERIFIED: docker-compose.yml] [CITED: https://docs.docker.com/compose/how-tos/profiles/]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Solo app access | CDN / Static | API / Backend | Compose publishes only the app's container port to loopback; Bandit continues to serve Phoenix. [VERIFIED: docker-compose.yml] |
| Database isolation | Database / Storage | API / Backend | PostgreSQL remains reachable by `db:5432` on the project network only. [CITED: https://docs.docker.com/compose/how-tos/networking/] |
| Fleet hostname routing | CDN / Static | API / Backend | Traefik owns Host-based ingress and forwards to the app's private port. [CITED: https://doc.traefik.io/traefik/v2.10/providers/docker/] |
| Public URL and WebSocket origin policy | API / Backend | Browser / Client | Phoenix generates public URLs and validates socket origins; the browser supplies the Origin header. [CITED: https://hexdocs.pm/phoenix/1.7.14/Phoenix.Endpoint.html] |

## Standard Stack

### Core

| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| Docker Compose | v5.1.3 installed | Merge base, solo override, and explicit fleet overlay. | Native project orchestration and currently available locally. [VERIFIED: `docker compose version`] |
| Traefik | `v3.7.1` locked | Shared local Docker-provider reverse proxy. | Exact maintained sibling convention mandated by D-09. [VERIFIED: `/Users/jon/projects/scoria/docker/traefik/compose.yml`] |
| Phoenix Endpoint | existing Phoenix dependency | Generate the public URL and enforce LiveView origin policy. | Existing demo endpoint; runtime `url` values and origin patterns are supported. [VERIFIED: `demo/ledger_loop/mix.exs`] [CITED: https://hexdocs.pm/phoenix/1.7.14/Phoenix.Endpoint.html] |

### Supporting

| Component | Purpose | When to Use |
|-----------|---------|-------------|
| Docker external network | Share only Traefik-routed services across sibling projects. | Fleet overlay and proxy project only. [CITED: https://docs.docker.com/compose/how-tos/networking/] |
| `docker compose config` | Render and inspect merged configuration. | Every Compose-overlay validation step. [CITED: https://docs.docker.com/compose/how-tos/multiple-compose-files/merge/] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Shared Traefik network | Unique host ports per demo | Cannot meet concurrent `*.localhost` fleet routing without port coordination. [ASSUMED] |
| Explicit origin allowlist | `check_origin: false` | The latter permits CSWSH when sockets trust session cookies; Phoenix documents it only for controlled development. [CITED: https://hexdocs.pm/phoenix/1.7.14/Phoenix.Endpoint.html] |

**Installation / startup:**

```bash
docker network create proxy 2>/dev/null || true
docker compose -f docker/traefik/compose.yml up -d
docker compose -f docker-compose.yml -f docker-compose.proxy.yml up -d
```

No package-manager dependencies are installed in this phase; the Package Legitimacy Audit is not applicable. The pinned Traefik image is a locked project decision, not a newly selected package. [VERIFIED: 69-CONTEXT.md]

## Architecture Patterns

### System Architecture Diagram

```text
Solo browser
  http://localhost:${PORT} ──> loopback port 4000 ──> demo_app:4000 ──> db:5432

Fleet browser
  http://${RELYRA_HOST} ──> Traefik :80 on external `proxy`
                              │ Host() router + relyra-* service label
                              └──────────────────────────────> demo_app:4000
                                                              └> db:5432 (default network only)

Traefik dashboard: 127.0.0.1:8080
Keycloak / realm routing: unchanged; Phase 70 owns it.
```

### Recommended Project Structure

```text
docker-compose.yml                 # common base: no host ports for db/demo_app
docker-compose.override.yml        # auto-loaded solo loopback app port only
docker-compose.proxy.yml           # explicit fleet network, labels, Phoenix public-host env
docker/traefik/compose.yml          # independent shared proxy project
demo/ledger_loop/config/runtime.exs # dev-capable public endpoint URL / origins
demo/ledger_loop/config/config.exs  # localhost fallback only
demo/ledger_loop/config/dev.exs     # replace false check_origin with safe default
```

### Pattern 1: Base + exclusive entry overlays

**What:** Place portable service definitions in the base. The automatic override supplies the sole solo port mapping; the explicitly named proxy overlay supplies fleet labels and no `ports:` key. [CITED: https://docs.docker.com/compose/how-tos/multiple-compose-files/merge/]

**When to use:** Always in this phase; do not include proxy configuration in the automatic override. [VERIFIED: 69-CONTEXT.md]

**Example:**

```yaml
# docker-compose.override.yml
services:
  demo_app:
    ports:
      - "127.0.0.1:${PORT:-4000}:4000"
```

```yaml
# docker-compose.proxy.yml
services:
  demo_app:
    environment:
      PHX_HOST: ${RELYRA_HOST:-relyra.localhost}
      PHX_SCHEME: http
      PHX_PORT: "80"
    labels:
      traefik.enable: "true"
      traefik.docker.network: ${DEMO_PROXY_NETWORK:-proxy}
      traefik.http.routers.relyra-demo.rule: Host(`${RELYRA_HOST:-relyra.localhost}`)
      traefik.http.routers.relyra-demo.entrypoints: web
      traefik.http.routers.relyra-demo.service: relyra-demo
      traefik.http.services.relyra-demo.loadbalancer.server.port: "4000"
    networks: [default, proxy]
networks:
  proxy:
    external: true
    name: ${DEMO_PROXY_NETWORK:-proxy}
```

The exact suffix may differ, but both router and service identifiers must begin `relyra-`. [VERIFIED: 69-CONTEXT.md]

### Pattern 2: Runtime public-endpoint configuration

**What:** Parse string environment values in `runtime.exs`, then configure `url: [host: ..., scheme: ..., port: ...]` in a block that runs for dev containers. Phoenix allows these URL values to change at runtime and explicitly calls out a configured scheme for reverse-proxy deployments. [CITED: https://hexdocs.pm/phoenix/1.7.14/Phoenix.Endpoint.html]

**Example:**

```elixir
if config_env() != :test do
  port = System.get_env("PORT", "4000")

  config :ledger_loop, LedgerLoopWeb.Endpoint,
    url: [
      host: System.get_env("PHX_HOST", "localhost"),
      scheme: System.get_env("PHX_SCHEME", "http"),
      port: String.to_integer(System.get_env("PHX_PORT", port))
    ],
    check_origin:
      System.get_env("DEMO_CHECK_ORIGINS", "//localhost,//relyra.localhost,//*.relyra.localhost")
      |> String.split(",", trim: true)
end
```

Keep the default host in `config.exs`; the runtime block overrides only in non-test execution. [VERIFIED: `demo/ledger_loop/config/config.exs`] [VERIFIED: 69-CONTEXT.md]

### Anti-Patterns to Avoid

- **Keeping `profiles: ["core"]` on solo services:** Bare `docker compose up` skips profiled services. Remove it from `db` and `demo_app`. [CITED: https://docs.docker.com/compose/how-tos/profiles/]
- **Using `docker compose up` with the automatic override in fleet mode:** It leaks the solo host port into fleet mode. Use explicit `-f docker-compose.yml -f docker-compose.proxy.yml`. [CITED: https://docs.docker.com/compose/how-tos/multiple-compose-files/merge/]
- **Attaching `db` to `proxy`:** It expands database reachability without being needed for routing. [CITED: https://docs.docker.com/compose/how-tos/networking/]
- **Leaving `check_origin: false`:** Replace it with the explicit default plus optional environment additions. [CITED: https://hexdocs.pm/phoenix/1.7.14/Phoenix.Endpoint.html]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Fleet hostname routing | Custom hostname dispatcher or port allocator | Traefik Docker provider with Host labels | Docker discovery and routing are its supplied responsibility. [CITED: https://doc.traefik.io/traefik/v2.10/providers/docker/] |
| Inter-project network lifecycle | Shell-created project-specific bridge management | Docker `external: true` network plus documented `docker network create proxy` | Compose preserves the network outside a project's lifecycle. [CITED: https://docs.docker.com/reference/compose-file/networks/] |
| WebSocket origin matcher | Custom Endpoint/plug origin check | Phoenix `check_origin` explicit list with wildcard | Phoenix already implements origin parsing and wildcard matching. [CITED: https://hexdocs.pm/phoenix/1.7.14/Phoenix.Endpoint.html] |

**Key insight:** Keep the only shared resource intentionally small: Traefik ingress plus the external network. App databases and normal service discovery remain in each Compose project's default network. [CITED: https://docs.docker.com/compose/how-tos/networking/]

## Common Pitfalls

### Pitfall 1: Fleet overlay accidentally includes solo ports

**What goes wrong:** An explicit `-f` invocation must list both base and proxy overlay; adding the auto-loaded override or putting ports in the base creates a host-port collision. [CITED: https://docs.docker.com/compose/how-tos/multiple-compose-files/merge/]

**How to avoid:** Put no `ports:` on base `demo_app`; put the only port mapping in `docker-compose.override.yml`; validate rendered solo and fleet configs separately. [VERIFIED: 69-CONTEXT.md]

### Pitfall 2: External network missing

**What goes wrong:** Compose fails rather than creates an `external: true` network. [CITED: https://docs.docker.com/reference/compose-file/networks/]

**How to avoid:** Start the independent proxy path with an idempotent `docker network create proxy` before fleet `up`; Phase 71 later wraps this as `make proxy`. [VERIFIED: 69-CONTEXT.md]

### Pitfall 3: Traefik routes to the wrong network or port

**What goes wrong:** Docker-provider port detection can be ambiguous, and a container on multiple networks needs a selected reachable network. [CITED: https://doc.traefik.io/traefik/v2.10/providers/docker/]

**How to avoid:** Set all of `traefik.docker.network`, explicit router `.service`, and `loadbalancer.server.port=4000`; prefix names `relyra-`. [VERIFIED: 69-CONTEXT.md]

### Pitfall 4: Runtime config placed only in the production branch

**What goes wrong:** Docker runs the demo with `MIX_ENV=dev`, so the existing prod-only URL configuration does not affect the proxy path. [VERIFIED: docker-compose.yml] [VERIFIED: `demo/ledger_loop/config/runtime.exs`]

**How to avoid:** Add a dev-applicable runtime block, optionally exclude `:test`, and preserve `config.exs` as the fallback. [VERIFIED: 69-CONTEXT.md]

### Pitfall 5: Scope creep into Keycloak or FakeIdP fixtures

**What goes wrong:** Changing realm URLs, Keycloak proxy settings, or fixed FakeIdP assertions violates the Phase 69/70 boundary. [VERIFIED: 69-CONTEXT.md]

**How to avoid:** Route only `demo_app`; retain Keycloak and fixture files untouched. The currently seeded FakeIdP uses the same fixed ACS URL as assertion Destination and Recipient. [VERIFIED: `demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex`] [VERIFIED: `demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_controller.ex`]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| One base Compose file publishes app and Postgres ports | Base + auto solo override + explicit proxy overlay | Phase 69 | Separates zero-setup solo access from opt-in fleet ingress. [VERIFIED: docker-compose.yml] [VERIFIED: 69-CONTEXT.md] |
| `check_origin: false` | Explicit, environment-driven allowlist | Phase 69 | Allows known proxy origins without broad socket-origin bypass. [VERIFIED: `demo/ledger_loop/config/dev.exs`] [CITED: https://hexdocs.pm/phoenix/1.7.14/Phoenix.Endpoint.html] |

**Deprecated/outdated:** `KC_PROXY=edge` is out of scope and is not to be introduced; Phase 70 owns the required `KC_PROXY_HEADERS=xforwarded` configuration. [VERIFIED: .planning/STATE.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Unique host ports could substitute for Traefik fleet routing. | Alternatives Considered | Low; it is not selected and does not fulfill the locked hostname experience. |

## Open Questions (RESOLVED)

1. **RESOLVED — Plan 69-01 Task 1 removes the core-profile contradiction.**
   - What we know: Current `db` and `demo_app` have `profiles: ["core"]`, while FLEET-01 requires bare `docker compose up`. [VERIFIED: docker-compose.yml] [CITED: https://docs.docker.com/compose/how-tos/profiles/]
   - Resolution: Plan 69-01 Task 1 removes `profiles` from exactly `db` and `demo_app`; Keycloak retains profile `keycloak` and Playwright retains profile `browser`. This makes bare `docker compose up` select the two core services while preserving the optional profiles. [HIGH confidence]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Docker daemon | Compose, network, and Traefik receipts | ✓ | Docker Engine 29.5.2 | — [VERIFIED: `docker --version`; `docker info`] |
| Docker Compose | Overlay rendering and lifecycle | ✓ | v5.1.3 | — [VERIFIED: `docker compose version`] |
| External `proxy` network | Fleet routing | ✓ | — | Recreate idempotently if absent. [VERIFIED: `docker network inspect proxy`] |
| Elixir/OTP | Formatting and demo-config checks | ✓ | OTP 28 | — [VERIFIED: `mix --version`] |

**Missing dependencies with no fallback:** None. [VERIFIED: environment audit]

**Missing dependencies with fallback:** None. [VERIFIED: environment audit]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit / Mix (existing) [VERIFIED: `mix.exs`] |
| Config file | `mix.exs`; demo config is under `demo/ledger_loop/config/` [VERIFIED: repository] |
| Quick run command | `docker compose config` and `docker compose -f docker-compose.yml -f docker-compose.proxy.yml config` [CITED: https://docs.docker.com/compose/how-tos/multiple-compose-files/merge/] |
| Full suite command | `mix qa && mix test --warnings-as-errors && mix ci.security && mix format --check-formatted` [VERIFIED: AGENTS.md] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FLEET-01 | Solo rendered config maps only loopback app port and no db port; bare up selects app/db. | config + runtime smoke | `docker compose config`; `docker compose up --dry-run` | ❌ Wave 0 manual receipt |
| FLEET-02 | Fleet rendered config has no app/db host ports, joins `proxy`, and has unique labels. | config + runtime smoke | `docker compose -f docker-compose.yml -f docker-compose.proxy.yml config`; `curl -I http://relyra.localhost` | ❌ Wave 0 manual receipt |
| FLEET-03 | Both public hosts establish a LiveView WebSocket and correct endpoint URL. | browser/manual integration | Browser receipt for localhost and `relyra.localhost` | ❌ Wave 0 manual receipt |

### Sampling Rate

- **Per task commit:** Render the relevant Compose configuration and run `mix format --check-formatted demo/ledger_loop/config/*.exs`. [VERIFIED: AGENTS.md]
- **Per wave merge:** Run project gates required by AGENTS.md. [VERIFIED: AGENTS.md]
- **Phase gate:** Run both solo/fleet Docker receipts in a browser; then full suite green. [VERIFIED: requirements]

### Wave 0 Gaps

- [ ] No automated Docker/browser fleet test exists; use documented manual receipts rather than adding test-only app changes outside scope. [VERIFIED: repository scan]
- [ ] Add static rendered-config assertions to plan verification, not a new test framework. [VERIFIED: phase scope]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | No authentication flow implementation changes. [VERIFIED: phase scope] |
| V3 Session Management | Indirectly | Explicit `check_origin` prevents broad WebSocket origin acceptance for cookie-backed LiveView sessions. [CITED: https://hexdocs.pm/phoenix/1.7.14/Phoenix.Endpoint.html] |
| V4 Access Control | Indirectly | Bind published dev ports to `127.0.0.1`; do not publish PostgreSQL. [VERIFIED: 69-CONTEXT.md] |
| V5 Input Validation | No | No new request parser or input boundary. [VERIFIED: phase scope] |
| V6 Cryptography | No | No crypto, keys, or signature path changes. [VERIFIED: phase scope] |

### Known Threat Patterns for Docker/Phoenix proxying

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Remote LAN access to local dev app/dashboard | Information disclosure | Bind all published host ports to loopback only. [VERIFIED: 69-CONTEXT.md] |
| Cross-Site WebSocket Hijacking | Spoofing | Replace `check_origin: false` with explicit allowed origins/wildcards. [CITED: https://hexdocs.pm/phoenix/1.7.14/Phoenix.Endpoint.html] |
| Database exposure/collision | Information disclosure / DoS | Remove `db` host port; use default-network `db:5432`. [VERIFIED: 69-CONTEXT.md] |
| Cross-project route hijack | Tampering | Disable exposed-by-default and use globally unique `relyra-*` router/service names. [VERIFIED: `/Users/jon/projects/scoria/docker/traefik/compose.yml`] [VERIFIED: 69-CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- [Docker Compose profiles](https://docs.docker.com/compose/how-tos/profiles/) — bare-up profile behavior.
- [Docker Compose networking](https://docs.docker.com/compose/how-tos/networking/) and [network reference](https://docs.docker.com/reference/compose-file/networks/) — external-network lifecycle and dual-network pattern.
- [Docker Compose merge](https://docs.docker.com/compose/how-tos/multiple-compose-files/merge/) — ordered overlays and rendered-config validation.
- [Traefik Docker provider](https://doc.traefik.io/traefik/v2.10/providers/docker/) and [routing labels](https://doc.traefik.io/traefik/v2.10/routing/providers/docker/) — labels, selected network, and target port.
- [Phoenix.Endpoint](https://hexdocs.pm/phoenix/1.7.14/Phoenix.Endpoint.html) — runtime URL values and `check_origin` list/wildcards.
- Current repository, Phase 68 artifacts, and sibling `scoria`/`rulestead` templates — exact project constraints and implementation seams. [VERIFIED: local files]

### Secondary (MEDIUM confidence)

- None.

### Tertiary (LOW confidence)

- None; the only assumed comparison is isolated in A1.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — locked sibling template, installed Docker/Compose audit, and official documentation. [VERIFIED: environment audit]
- Architecture: HIGH — locked Context decisions plus Compose/Traefik/Phoenix primary documentation. [VERIFIED: 69-CONTEXT.md]
- Pitfalls: HIGH — one profile conflict observed in the current file and remaining pitfalls derived from official documentation. [VERIFIED: docker-compose.yml]

**Research date:** 2026-08-16  
**Valid until:** 2026-09-15
