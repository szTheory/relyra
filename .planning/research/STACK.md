# Stack Research: v1.7 Adoption Evidence Demo

**Project:** Relyra v1.7 — Adoption Evidence Demo
**Researched:** 2026-06-12
**Confidence:** HIGH

## Recommendation

Build `demo/ledger_loop` as a normal Phoenix app inside the repository, with Relyra as a path dependency:

```elixir
{:relyra, path: "../.."}
```

Do not make an umbrella, do not add a sidecar SSO broker, and do not promote the demo's customer setup pages into Relyra core. The milestone is evidence infrastructure: it should prove the library in the kind of Phoenix SaaS host app an adopter would actually own.

## Phoenix / Elixir Baseline

- Phoenix 1.8.x app, generated as a conventional web app.
- Ecto/PostgreSQL for demo data and all production-like Relyra stores.
- LiveView for setup/admin/status screens where interactivity matters.
- Relyra mounted through its existing Phoenix router macros and LiveAdmin router.
- Playwright for browser receipts.
- Docker Compose for local app + Postgres, with optional profiles for Keycloak and browser helpers.

This matches the existing project constraints: Phoenix-native, Ecto optionality as first-class, no sidecar services required for the library itself, and no protocol core coupling to Phoenix/Ecto.

## Layout

Recommended tree:

```text
demo/ledger_loop/
  mix.exs
  config/
  lib/ledger_loop/
    accounts/
    organizations/
    sso/
    demo_data/
    relyra/
      connection_resolver.ex
      request_store.ex
      replay_store.ex
      user_mapper.ex
      session_adapter.ex
  lib/ledger_loop_web/
  priv/repo/migrations/
  priv/repo/seeds.exs
  compose.yaml
```

Root-level `scripts/demo` should orchestrate the demo from the repository root, because evaluators should not need to remember whether a command starts in the root or in `demo/ledger_loop`.

## Docker And Local DX

Use Compose profiles:

- `core`: Phoenix demo + Postgres
- `keycloak`: external IdP proof
- `browser`: Playwright runner if useful

Defaults should be environment-driven:

```sh
COMPOSE_PROJECT_NAME=${COMPOSE_PROJECT_NAME:-relyra_ledger_loop}
DEMO_WEB_PORT=${DEMO_WEB_PORT:-4100}
DEMO_DB_PORT=${DEMO_DB_PORT:-15432}
DEMO_KEYCLOAK_PORT=${DEMO_KEYCLOAK_PORT:-18080}
```

Do not use fixed `container_name`; Compose project names are the resource isolation primitive. Docker documents project-name precedence and profiles, and those map directly to this repo's need to run multiple OSS demos without port/container collisions.

## Health And Readiness

- Postgres: `pg_isready`.
- Phoenix: `/healthz` for server + Repo reachability; `/readyz` after migrations/seeds if needed.
- Keycloak: health endpoint plus a higher-level SSO form readiness probe. The repo already learned that descriptor/port readiness is not enough for stable SAML browser proof.

## CI Shape

- `mix ci.demo_app`: required, no browser, no Keycloak. Compile demo, migrate, seed, prove Ecto stores and local FakeIdP flow.
- `demo-browser`: focused browser E2E for the core demo.
- `demo-keycloak`: optional workflow/profile until burn-in proves it belongs in required branch protection.

Do not weaken or fold these into `mix ci.security`. That lane's hollow-gate invariant is security-critical.

## Sources

- Repo-local: `.planning/threads/adoption-evidence-demo-roadmap-2026-06-12.md`, `guides/production_ecto_path.md`, `guides/jtbd_user_flows.md`, prompts research.
- Official/current docs checked: Phoenix contexts, Phoenix LiveView changelog/docs, Docker Compose project names/profiles/services, Keycloak health/container docs, Playwright Docker/CI docs.
