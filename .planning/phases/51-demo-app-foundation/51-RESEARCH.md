# Phase 51: Demo App Foundation - Research

**Researched:** 2026-06-12
**Domain:** Phoenix 1.8 host app scaffold, Relyra route mounting, Hex package boundary
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
[CITED: .planning/phases/51-demo-app-foundation/51-CONTEXT.md]

### Demo App Boundary
- **D-01:** Create only the conventional Phoenix app foundation at `demo/ledger_loop`, with Relyra loaded from the repository as a path dependency and with enough routing/UI to prove the app boots as a host application.
- **D-02:** Keep seeded data, durable Relyra store proof, browser FakeIdP proof, optional Keycloak proof, Docker orchestration, and demo guide polish out of Phase 51 except for explicit placeholders or route affordances needed by the first-screen shell.

### UX And Route Shape
- **D-03:** Build the first screen as the actual `LedgerLoop Workspace`, not a marketing landing page.
- **D-04:** The first screen must expose tenant/status information and reachable setup, login, Relyra admin, and support affordances, following the approved Phase 51 UI contract.
- **D-05:** Mount Relyra SAML routes under the host-owned `/saml` scope and make that route ownership visible in the workspace UI.
- **D-06:** Mount the operator admin route scope at `/relyra/admin`, using Relyra LiveAdmin's router macro and a host-owned scope provider/repo configuration.
- **D-07:** Add health/readiness endpoints suitable for Docker or CI polling, with text-distinguishable booted/ready/unavailable states in the UI.

### Existing Assets To Reuse
- **D-08:** Use existing adoption fixtures, installer parity tests, and LiveAdmin browser support as implementation references, but do not copy test-only modules wholesale into the demo app.
- **D-09:** Treat `Relyra.TestSupport` and `examples/quickstart.exs` as later-phase proof references only. Phase 51 should not depend on `MIX_ENV=test` or test-only FakeIdP modules to boot the demo foundation.

### Packaging And Repo Integration
- **D-10:** Keep `demo/ledger_loop` repo-local and excluded from Hex through the existing explicit `mix.exs` package whitelist model, not through fragile ignore-file assumptions.
- **D-11:** Make demo package exclusion inspectable during planning/execution so Phase 51 can prove the demo remains runnable from the repo while absent from package contents.

### Store And Login Proof Sequencing
- **D-12:** Expose the later integration points for Ecto connection/request/replay stores and local browser login proof, but leave actual durable login behavior to Phase 52 and browser SAML proof to Phase 54.
- **D-13:** Preserve the v1.7 requirement that the eventual demo happy path uses Ecto connection, request, and replay stores. Existing adoption fixtures prove useful patterns but currently still use ETS for request/replay in parts of the path, so the demo must not inherit that as its final happy-path posture.

### the agent's Discretion
- Planner may choose the exact Phoenix scaffold command and app module names, provided the app lands under `demo/ledger_loop`, compiles as a normal Phoenix app, and uses Relyra via local path dependency.
- Planner may choose whether Phase 51 route destinations are simple controllers, LiveViews, or placeholders, as long as the first screen exposes all required affordances and later phases can replace placeholders without route churn.
- Planner may choose the exact health/readiness response body shape, provided Docker/CI can distinguish booted from unavailable state and the UI uses explicit status text.

### Deferred Ideas (OUT OF SCOPE)
- Deterministic LedgerLoop / Northstar Health seeds, cert states, audit rows, and trace scenarios remain Phase 52.
- Ecto request/replay store wrappers and happy-path persistence proof remain Phase 52.
- Customer/admin SSO setup UX, receipts, support handoff, and full UX polish remain Phase 53.
- In-browser FakeIdP login proof remains Phase 54.
- Docker scripts, Compose profiles, CI demo lane, browser E2E, and optional Keycloak proof remain Phase 55.
- README and demo guide entrypoints remain Phase 56.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DEMO-01 | Evaluator can boot a conventional Phoenix app at `demo/ledger_loop` that depends on the local Relyra package via path dependency. | Use `mix phx.new demo/ledger_loop --app ledger_loop --module LedgerLoop --database postgres --no-assets --no-dashboard --no-mailer --no-gettext --no-agents-md --no-install`, then add `{:relyra, path: "../.."}`. [VERIFIED: local `mix phx.new` probe] [CITED: https://phoenix.hexdocs.pm/Mix.Tasks.Phx.New.html] [CITED: `mix help deps`] |
| DEMO-02 | Demo app is excluded from the Hex package while remaining runnable from the repository. | Root `mix.exs` uses explicit `package.files`; Hex docs say `:files` controls included package paths and `mix hex.build --unpack` inspects contents. [VERIFIED: codebase grep] [CITED: `mix help hex.publish`] |
| DEMO-03 | Demo app exposes a usable LedgerLoop workspace as its first screen with tenant status and links to setup, login, admin, and support flows. | Implement the approved UI-SPEC with plain Phoenix controllers/templates/function components and no Tailwind/shadcn/React. [CITED: .planning/phases/51-demo-app-foundation/51-UI-SPEC.md] |
| DEMO-04 | Demo app mounts Relyra SAML routes under a clear host-owned route scope. | Use Phoenix router `scope "/saml", LedgerLoopWeb` and call `saml_routes()` inside that scope; Phoenix scopes group routes under path prefixes. [VERIFIED: codebase grep] [CITED: https://phoenix.hexdocs.pm/routing.html] |
| DEMO-05 | Demo app exposes health/readiness endpoints suitable for local Docker and CI orchestration. | Add lightweight `/healthz` and `/readyz` host-owned routes with explicit text/status; Phoenix endpoints route all requests through the router in generated apps. [CITED: https://phoenix.hexdocs.pm/Phoenix.Endpoint.html] [ASSUMED] |
</phase_requirements>

## Summary

Phase 51 should create a normal Phoenix 1.8 app under `demo/ledger_loop`, not an umbrella, broker, or test fixture. [VERIFIED: local `mix phx.new` probe] The default Phoenix 1.8.7 scaffold includes Tailwind/daisyUI assets, so the planner should use `--no-assets` and implement the Phase 51 UI with app-local static CSS and HEEx templates to honor the UI-SPEC. [VERIFIED: local `mix phx.new` probe] [CITED: .planning/phases/51-demo-app-foundation/51-UI-SPEC.md]

Relyra should be integrated exactly like an adopter-owned host app: local path dependency, SAML routes mounted inside a host `/saml` router scope, LiveAdmin mounted at `/relyra/admin` with a demo-owned repo and scope provider, and placeholder setup/login/support destinations that can be replaced in later phases without route churn. [VERIFIED: codebase grep] Packaging exclusion should be proven by the existing root package whitelist plus `mix hex.build --unpack`, not by `.gitignore` or `.hexignore` assumptions. [VERIFIED: codebase grep] [CITED: `mix help hex.publish`]

**Primary recommendation:** Use the Phoenix 1.8.7 local generator with `--no-assets`, add `{:relyra, path: "../.."}`, keep all LedgerLoop pages host-owned, mount Relyra only through `Relyra.Phoenix.Router.saml_routes/1` and `Relyra.LiveAdmin.Router.relyra_admin_routes/2`, and add package-content tests that assert `demo/` is absent from `mix hex.build --unpack`. [VERIFIED: local `mix phx.new` probe] [VERIFIED: codebase grep]

## Project Constraints (from AGENTS.md)

- Do not implement outside active PLAN.md scope; this research is pre-plan only. [CITED: AGENTS.md]
- Do not change public API shapes for `Relyra.start_login/3`, `consume_response/3`, or published behaviours without escalation. [CITED: AGENTS.md]
- Never relax configured-certificate trust, one XML parse path, raw-binary pre-parse guards, cryptographic verification, audit co-commit, or production replay protection. [CITED: AGENTS.md]
- Use `lib/relyra/security/signature.ex`, `lib/relyra/security/xml/pure_beam.ex`, `lib/relyra/security/xml/c14n.ex`, `lib/relyra/security/algorithm_policy.ex`, `lib/relyra/ecto/audit_writer.ex`, and `lib/relyra/behaviours/` as hard architecture seams. [CITED: AGENTS.md]
- Keep `mix test --warnings-as-errors`, `mix ci.security`, and `mix format --check-formatted` green; do not weaken adversarial XML crypto tests. [CITED: AGENTS.md]
- Do not run `mix hex.publish`; Release Please owns publishing. [CITED: AGENTS.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Phoenix app boot | Frontend Server / SSR | API / Backend | Generated Phoenix endpoint/router/application own boot and request handling. [CITED: https://phoenix.hexdocs.pm/Phoenix.Endpoint.html] |
| LedgerLoop workspace first screen | Frontend Server / SSR | Browser / Client | HEEx/templates render the first screen; browser only navigates links and reads status text. [CITED: .planning/phases/51-demo-app-foundation/51-UI-SPEC.md] |
| SAML route mount | API / Backend | Frontend Server / SSR | Relyra controllers process metadata/login/ACS under host router scope. [VERIFIED: codebase grep] |
| Operator admin mount | Frontend Server / SSR | Database / Storage | LiveAdmin is LiveView UI backed by host repo/scope provider. [VERIFIED: codebase grep] |
| Health/readiness probes | API / Backend | Database / Storage | `/healthz` proves app process boot; `/readyz` may check repo or placeholder readiness. [ASSUMED] |
| Hex package exclusion | Build / Packaging | — | Root `mix.exs package.files` determines package inclusion. [VERIFIED: codebase grep] [CITED: `mix help hex.publish`] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phoenix` | generator local `1.8.7`; latest Hex `1.8.8` published 2026-06-10 | Web framework and generator | Official generator creates the conventional host app and endpoint/router structure. [VERIFIED: Hex registry] [CITED: https://phoenix.hexdocs.pm/Mix.Tasks.Phx.New.html] |
| `phoenix_ecto` | latest Hex `4.7.0` published 2025-11-07 | Phoenix/Ecto integration | Generated Phoenix PostgreSQL apps include it for repo integration. [VERIFIED: Hex registry] [VERIFIED: local `mix phx.new` probe] |
| `ecto_sql` | latest Hex `3.14.0` published 2026-05-19; generator constraint `~> 3.13` | SQL repo/migrations | Needed for conventional Phoenix app database and later Relyra Ecto stores. [VERIFIED: Hex registry] |
| `postgrex` | latest stable Hex `0.22.2` published 2026-05-12 | PostgreSQL adapter | Phoenix generator uses PostgreSQL by default when database is not changed. [VERIFIED: Hex registry] [CITED: https://phoenix.hexdocs.pm/Mix.Tasks.Phx.New.html] |
| `phoenix_live_view` | generator constraint `~> 1.1.0`; latest compatible `1.1.32` published 2026-06-12; latest `1.2.1` published 2026-06-12 | LiveView runtime for mounted LiveAdmin | Relyra LiveAdmin router requires Phoenix LiveView to be available. [VERIFIED: Hex registry] [VERIFIED: codebase grep] |
| `bandit` | latest Hex `1.12.0` published 2026-06-06; generator constraint `~> 1.5` | HTTP adapter | Phoenix 1.8 defaults to Bandit as HTTP adapter. [VERIFIED: Hex registry] [CITED: https://phoenix.hexdocs.pm/Mix.Tasks.Phx.New.html] |
| `relyra` | local path `../..` | SAML SP library under evaluation | Mix supports path dependencies; Phase 51 requires repository-local Relyra. [CITED: `mix help deps`] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `phoenix_html` | latest Hex `4.3.0` published 2025-09-28 | HTML/template helpers | Keep generated Phoenix HTML stack. [VERIFIED: Hex registry] |
| `phoenix_live_reload` | latest Hex `1.6.2` published 2025-12-08 | Dev-only live reload | Generated dev dependency only. [VERIFIED: Hex registry] |
| `lazy_html` | latest Hex `0.1.11` published 2026-04-02 | HTML assertions in tests | Generated test dependency; useful for first-screen assertions. [VERIFIED: Hex registry] |
| `telemetry_metrics` | latest Hex `1.1.0` published 2025-01-24 | Phoenix telemetry metrics | Keep generated telemetry support unless planner deliberately trims it. [VERIFIED: Hex registry] |
| `telemetry_poller` | latest Hex `1.3.0` published 2025-07-09 | Periodic telemetry | Keep generated telemetry support unless planner deliberately trims it. [VERIFIED: Hex registry] |
| `jason` | latest stable Hex `1.4.5` published 2026-05-05 | JSON encoding | Generated Phoenix dependency. [VERIFIED: Hex registry] |
| `dns_cluster` | latest Hex `0.2.0` published 2025-03-04 | DNS clustering helper | Generated dependency; harmless foundation for later Docker deployment. [VERIFIED: Hex registry] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Conventional Phoenix app | Umbrella app | Umbrella adds app boundary complexity without Phase 51 benefit. [ASSUMED] |
| `--no-assets` scaffold | Default Phoenix assets with Tailwind/daisyUI | Default scaffold violates UI-SPEC prohibition on Tailwind and component registries in Phase 51. [VERIFIED: local `mix phx.new` probe] [CITED: .planning/phases/51-demo-app-foundation/51-UI-SPEC.md] |
| Host-owned `/saml` scope | Relyra-owned top-level macro without host scope | Phase requires visibly host-owned route scope; Phoenix scopes are the standard path prefix mechanism. [CITED: https://phoenix.hexdocs.pm/routing.html] |

**Installation:**

```bash
mix phx.new demo/ledger_loop --app ledger_loop --module LedgerLoop --database postgres --no-assets --no-dashboard --no-mailer --no-gettext --no-agents-md --no-install
cd demo/ledger_loop
# Add to deps:
# {:relyra, path: "../.."}
mix deps.get
```

**Version verification:** Ran `mix phx.new --version`, `mix phx.new ... --no-assets --no-install`, and `mix hex.info` for recommended Hex packages on 2026-06-12. [VERIFIED: local command output]

## Package Legitimacy Audit

> `slopcheck` is npm-oriented. Running it against Hex package names produced npm false positives and tried to install npm lookalikes; those accidental npm changes were removed. Treat Hex registry + official Phoenix generator output as the authoritative ecosystem check for this Elixir phase. [VERIFIED: local command output]

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| `phoenix` | Hex | latest 2026-06-10 | 290,962/week | github.com/phoenixframework/phoenix | npm-only check found npm `phoenix`, not authoritative | Approved [VERIFIED: Hex registry] |
| `phoenix_ecto` | Hex | latest 2025-11-07 | 215,445/week | github.com/phoenixframework/phoenix_ecto | npm false `[SLOP]` | Approved [VERIFIED: Hex registry] |
| `ecto_sql` | Hex | latest 2026-05-19 | 268,224/week | github.com/elixir-ecto/ecto_sql | npm false `[SLOP]` | Approved [VERIFIED: Hex registry] |
| `postgrex` | Hex | latest 2026-05-12 | 254,300/week | github.com/elixir-ecto/postgrex | npm false `[SLOP]` | Approved [VERIFIED: Hex registry] |
| `phoenix_live_view` | Hex | latest 2026-06-12 | 221,691/week | github.com/phoenixframework/phoenix_live_view | npm-only check found npm package, not authoritative | Approved [VERIFIED: Hex registry] |
| `bandit` | Hex | latest 2026-06-06 | 181,504/week | github.com/mtrudel/bandit | npm-only check found npm `bandit`, not authoritative | Approved [VERIFIED: Hex registry] |
| `relyra` | path | repository-local | n/a | current repo | n/a | Approved [CITED: .planning/REQUIREMENTS.md] |

**Packages removed due to slopcheck [SLOP] verdict:** none; npm verdicts were cross-ecosystem false positives for Hex packages. [VERIFIED: local command output]
**Packages flagged as suspicious [SUS]:** none for Hex registry checks. [VERIFIED: Hex registry]

## Architecture Patterns

### System Architecture Diagram

```text
Evaluator browser
  |
  v
LedgerLoopWeb.Endpoint
  |
  v
LedgerLoopWeb.Router
  |-- GET / ----------------------> WorkspaceController/HEEx
  |                                  |-- status panels
  |                                  |-- setup/login/admin/support links
  |
  |-- GET /healthz ----------------> HealthController.health -> "booted"
  |-- GET /readyz -----------------> HealthController.ready -> "ready" or "unavailable"
  |
  |-- scope /saml -----------------> Relyra.Phoenix.Router.saml_routes()
  |                                  |-- /:connection_id/metadata
  |                                  |-- /:connection_id/login
  |                                  |-- /:connection_id/acs
  |
  |-- /relyra/admin --------------> Relyra.LiveAdmin.Router.relyra_admin_routes()
                                     |-- repo: LedgerLoop.Repo
                                     |-- scope_provider: LedgerLoop.Relyra.AdminScope
```

### Recommended Project Structure

```text
demo/ledger_loop/
├── mix.exs
├── config/
├── lib/
│   ├── ledger_loop/
│   │   ├── application.ex
│   │   ├── repo.ex
│   │   └── relyra/
│   │       └── admin_scope.ex
│   └── ledger_loop_web/
│       ├── controllers/
│       │   ├── health_controller.ex
│       │   ├── page_controller.ex
│       │   └── placeholder_controller.ex
│       ├── components/
│       └── router.ex
├── priv/
│   ├── repo/
│   └── static/assets/css/app.css
└── test/
    └── ledger_loop_web/
```

### Pattern 1: Host-Owned SAML Scope

**What:** Prefix all Relyra SAML routes with a Phoenix host scope. [CITED: https://phoenix.hexdocs.pm/routing.html]
**When to use:** Always for Phase 51 DEMO-04. [CITED: .planning/REQUIREMENTS.md]
**Example:**

```elixir
# Source: lib/relyra/phoenix/router.ex + Phoenix routing docs
scope "/saml", LedgerLoopWeb do
  pipe_through(:browser)
  saml_routes()
end
```

### Pattern 2: Mounted LiveAdmin With Host Scope Provider

**What:** Mount Relyra LiveAdmin through its router macro, passing a host repo and scope provider. [VERIFIED: codebase grep]
**When to use:** Phase 51 must mount `/relyra/admin`; later phases can deepen data. [CITED: .planning/phases/51-demo-app-foundation/51-CONTEXT.md]
**Example:**

```elixir
# Source: lib/relyra/live_admin/router.ex and test/support/live_admin_test_support.ex
relyra_admin_routes("/relyra/admin",
  repo: LedgerLoop.Repo,
  scope_provider: LedgerLoop.Relyra.AdminScope
)
```

### Pattern 3: Package Boundary Test

**What:** Build and unpack the Hex package, then assert no `demo/` paths. [CITED: `mix help hex.publish`]
**When to use:** Required for DEMO-02. [CITED: .planning/REQUIREMENTS.md]
**Example:**

```bash
mix hex.build --unpack --output /tmp/relyra-package-check
test -z "$(find /tmp/relyra-package-check -path '*/demo/*' -print -quit)"
```

### Anti-Patterns to Avoid

- **Default Phoenix assets without review:** The default generator adds Tailwind/daisyUI, which Phase 51 forbids. [VERIFIED: local `mix phx.new` probe] [CITED: .planning/phases/51-demo-app-foundation/51-UI-SPEC.md]
- **Copying test support into the demo:** `Relyra.TestSupport` is explicitly later-phase proof reference only. [CITED: .planning/phases/51-demo-app-foundation/51-CONTEXT.md]
- **Mounting SAML at root:** Root-level `saml_routes()` hides host route ownership and conflicts with D-05. [CITED: .planning/phases/51-demo-app-foundation/51-CONTEXT.md]
- **Adding `demo/` to root package files:** Root package whitelist is the authoritative Hex boundary. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Phoenix project skeleton | Custom Mix app by hand | `mix phx.new ... --no-assets` | Generator creates endpoint/router/test conventions and current dependency set. [VERIFIED: local `mix phx.new` probe] |
| SAML route registration | Custom metadata/login/ACS routes | `Relyra.Phoenix.Router.saml_routes()` | Relyra owns ACS/metadata controller wiring and CSRF skip semantics. [VERIFIED: codebase grep] |
| Operator trust cockpit | Demo-local admin UI | `Relyra.LiveAdmin.Router.relyra_admin_routes/2` | Existing LiveAdmin owns connection workflows and trace surfaces. [VERIFIED: codebase grep] |
| Package filtering | `.gitignore`/manual tar cleanup | `package.files` whitelist + `mix hex.build --unpack` | Hex package config controls package contents. [CITED: `mix help hex.publish`] |
| Health endpoints | External polling script only | Phoenix controller/route endpoints | Docker/CI need HTTP-distinguishable boot/readiness states. [ASSUMED] |

**Key insight:** Phase 51 is foundation evidence, so the highest-risk mistake is inventing demo-only infrastructure where Relyra already has stable Phoenix seams. [ASSUMED]

## Common Pitfalls

### Pitfall 1: Scaffold Pulls In Forbidden Frontend Stack
**What goes wrong:** Default `mix phx.new` creates Tailwind/daisyUI files. [VERIFIED: local `mix phx.new` probe]
**Why it happens:** Phoenix 1.8 default generator includes asset tooling unless `--no-assets` is passed. [VERIFIED: local `mix phx.new` probe]
**How to avoid:** Generate with `--no-assets`; keep CSS in `priv/static/assets/css/app.css` or app-local equivalent. [VERIFIED: local `mix phx.new` probe]
**Warning signs:** `assets/vendor/daisyui.js`, `tailwind`, `esbuild`, or `heroicons` appears in `demo/ledger_loop/mix.exs`. [VERIFIED: local `mix phx.new` probe]

### Pitfall 2: Package Exclusion Assumed But Not Proved
**What goes wrong:** Demo files accidentally enter Hex tarball. [ASSUMED]
**Why it happens:** Planners rely on ignore files instead of root `package.files`. [CITED: .planning/phases/51-demo-app-foundation/51-CONTEXT.md]
**How to avoid:** Keep root `package.files` explicit and test unpacked package contents. [VERIFIED: codebase grep] [CITED: `mix help hex.publish`]
**Warning signs:** Any root `mix.exs` edit adds `"demo"` or wildcard package paths. [VERIFIED: codebase grep]

### Pitfall 3: Phase 51 Creeps Into Phase 52-55 Proof
**What goes wrong:** Planner tries to seed the full Northstar story, durable request/replay proof, FakeIdP browser login, Docker scripts, or docs. [CITED: .planning/phases/51-demo-app-foundation/51-CONTEXT.md]
**Why it happens:** The first screen needs links to later flows, which can tempt implementation of those flows. [ASSUMED]
**How to avoid:** Add stable placeholder routes/pages with explicit future-phase text and tests that verify route reachability, not final behavior. [ASSUMED]
**Warning signs:** `Relyra.TestSupport.FakeIdP`, Keycloak config, or request/replay Ecto wrappers become required for boot. [CITED: .planning/phases/51-demo-app-foundation/51-CONTEXT.md]

### Pitfall 4: Admin Scope Provider Blocks First Boot
**What goes wrong:** `/relyra/admin` redirects or errors because no admin scope can resolve. [ASSUMED]
**Why it happens:** LiveAdmin expects a scope provider; test support resolves from session. [VERIFIED: codebase grep]
**How to avoid:** Create a minimal demo-owned scope provider/session affordance for Phase 51 and keep it visibly demo-local. [ASSUMED]
**Warning signs:** LiveAdmin on_mount returns unauthenticated halt for all evaluator paths. [VERIFIED: codebase grep]

## Code Examples

### Local Path Dependency

```elixir
# Source: `mix help deps`
defp deps do
  [
    {:relyra, path: "../.."}
  ]
end
```

### Workspace Route Skeleton

```elixir
# Source: Phoenix routing docs + Phase 51 UI-SPEC
scope "/", LedgerLoopWeb do
  pipe_through(:browser)

  get("/", PageController, :home)
  get("/setup/sso", PlaceholderController, :setup)
  get("/login/test", PlaceholderController, :login)
  get("/support/scenario", PlaceholderController, :support)
  get("/healthz", HealthController, :health)
  get("/readyz", HealthController, :ready)
end
```

### Health Controller Shape

```elixir
# Source: Phoenix controller conventions inferred from generated scaffold [ASSUMED]
def health(conn, _params), do: text(conn, "booted")

def ready(conn, _params) do
  case LedgerLoop.Health.ready?() do
    true -> text(conn, "ready")
    false -> conn |> put_status(:service_unavailable) |> text("unavailable")
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Phoenix 1.7 default asset styling | Phoenix 1.8 generator includes Tailwind/daisyUI by default | Phoenix 1.8 release, 2025-08-05 | Phase 51 should use `--no-assets` to satisfy UI-SPEC. [CITED: https://www.phoenixframework.org/blog/phoenix-1-8-released] [VERIFIED: local `mix phx.new` probe] |
| Router helpers-first route references | Verified routes and explicit scopes | Phoenix 1.7+ era [ASSUMED] | Keep paths explicit for evaluator route visibility. [ASSUMED] |
| Implicit package defaults | Explicit package `:files` whitelist | Existing Relyra root `mix.exs` | Demo exclusion is inspectable. [VERIFIED: codebase grep] |

**Deprecated/outdated:**
- Using `.hexignore` as the primary package boundary: root `package.files` is the Relyra project convention and Hex-supported mechanism. [VERIFIED: codebase grep] [CITED: `mix help hex.publish`]
- Copying `test/fixtures/demo_host` as a demo app: it is a minimal test fixture, not the runnable LedgerLoop product shell. [VERIFIED: codebase grep] [CITED: .planning/phases/51-demo-app-foundation/51-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `/healthz` should prove app process boot and `/readyz` may check repo/demo readiness. | Phase Requirements, Architecture Map, Don't Hand-Roll | Planner may choose too much or too little readiness behavior; keep Phase 51 lightweight. |
| A2 | A conventional app is better than umbrella for this demo foundation. | Standard Stack | If team wants umbrella later, route/module paths would churn. |
| A3 | Stable placeholders are enough for setup/login/support in Phase 51. | Common Pitfalls | If evaluator proof requires real flows now, Phase 51 scope is underplanned. |
| A4 | Minimal demo-owned admin scope provider should make `/relyra/admin` reachable. | Common Pitfalls | LiveAdmin may require more host session setup than planned. |
| A5 | Health controller code shape follows standard Phoenix controller conventions. | Code Examples | Exact generated controller imports may differ; planner should verify in scaffold. |

## Open Questions (RESOLVED)

1. **Should `/readyz` require database reachability in Phase 51?**
   - What we know: Phase 51 requires Docker/CI-distinguishable ready/unavailable states. [CITED: .planning/REQUIREMENTS.md]
   - What's unclear: Whether readiness should already query `LedgerLoop.Repo` before Phase 52 seeds/migrations deepen data. [ASSUMED]
   - Recommendation: Make `/healthz` app-only and `/readyz` check repo availability if the generated app includes Ecto; do not require seeded data until Phase 52. [ASSUMED]
   - **RESOLVED:** `/readyz` checks repository availability in Phase 51 without requiring Phase 52 seed data.

2. **Should root CI get a new demo compile alias in Phase 51?**
   - What we know: Phase 55 owns focused `mix ci.demo_app`. [CITED: .planning/ROADMAP.md]
   - What's unclear: Whether Phase 51 should add a root helper alias for planning ergonomics. [ASSUMED]
   - Recommendation: Keep Phase 51 verification commands local to `demo/ledger_loop` plus root package exclusion tests; defer root CI alias to Phase 55. [ASSUMED]
   - **RESOLVED:** Root `mix ci.demo_app` remains deferred to Phase 55; Phase 51 uses local demo commands and package exclusion checks.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | Phoenix/Relyra compile | yes | 1.19.5 | none |
| Erlang/OTP | Phoenix/Relyra runtime | yes | 28 | none |
| Mix | scaffold/deps/test | yes | 1.19.5 | none |
| Phoenix installer | app generation | yes | 1.8.7 | install/update `phx_new` archive |
| Hex | dependency/package checks | yes | 2.4.2 | none |
| PostgreSQL client | readiness/debug | yes | `psql` 14.17 | generated app can still compile without local DB |
| Docker | later orchestration awareness | yes | 29.5.2 | Phase 51 should not require Docker |
| Context7 CLI | docs lookup | no | — | Official HexDocs/web and local `mix help` used |
| slopcheck | package legitimacy gate | yes, but npm-only behavior | no `--json` support | Hex registry checks used as authoritative ecosystem check |

**Missing dependencies with no fallback:** none for research. [VERIFIED: local command output]

**Missing dependencies with fallback:** Context7 CLI missing; official HexDocs and local `mix help` were used. [VERIFIED: local command output]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix; generated Phoenix app includes ConnCase/DataCase. [VERIFIED: local `mix phx.new` probe] |
| Config file | root `config/test.exs`; generated demo will add `demo/ledger_loop/config/test.exs`. [VERIFIED: codebase grep] [VERIFIED: local `mix phx.new` probe] |
| Quick run command | `cd demo/ledger_loop && mix test test/ledger_loop_web/controllers/page_controller_test.exs test/ledger_loop_web/controllers/health_controller_test.exs` [ASSUMED] |
| Full suite command | `cd demo/ledger_loop && mix test --warnings-as-errors` plus root `mix test --warnings-as-errors` for Relyra regressions. [CITED: AGENTS.md] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| DEMO-01 | App compiles/boots with local path Relyra dependency | integration | `cd demo/ledger_loop && mix deps.get && mix compile --warnings-as-errors` | no, Wave 0 |
| DEMO-02 | Root Hex package excludes `demo/` | integration | `mix hex.build --unpack --output /tmp/relyra-package-check && ! find /tmp/relyra-package-check -path '*/demo/*' -print -quit` | no, Wave 0 |
| DEMO-03 | First screen shows workspace status and four affordances | controller/HTML | `cd demo/ledger_loop && mix test test/ledger_loop_web/controllers/page_controller_test.exs --warnings-as-errors` | no, Wave 0 |
| DEMO-04 | `/saml` and `/relyra/admin` routes are mounted | unit/router | `cd demo/ledger_loop && mix test test/ledger_loop_web/router_test.exs --warnings-as-errors` | no, Wave 0 |
| DEMO-05 | `/healthz` and `/readyz` distinguish states | controller | `cd demo/ledger_loop && mix test test/ledger_loop_web/controllers/health_controller_test.exs --warnings-as-errors` | no, Wave 0 |

### Sampling Rate

- **Per task commit:** `cd demo/ledger_loop && mix test --warnings-as-errors` for demo edits. [ASSUMED]
- **Per wave merge:** root `mix test --warnings-as-errors` plus demo full suite. [CITED: AGENTS.md]
- **Phase gate:** `mix format --check-formatted`, root `mix test --warnings-as-errors`, demo `mix test --warnings-as-errors`, and package exclusion check. [CITED: AGENTS.md] [ASSUMED]

### Wave 0 Gaps

- [ ] `demo/ledger_loop/test/ledger_loop_web/router_test.exs` — covers DEMO-04.
- [ ] `demo/ledger_loop/test/ledger_loop_web/controllers/health_controller_test.exs` — covers DEMO-05.
- [ ] `demo/ledger_loop/test/ledger_loop_web/controllers/page_controller_test.exs` — covers DEMO-03.
- [ ] Root package exclusion test or script — covers DEMO-02.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes, route surface only | Mount Relyra SAML routes; no Phase 51 login proof. [VERIFIED: codebase grep] |
| V3 Session Management | yes, admin access only | Demo-owned session/scope provider; do not change Relyra session adapter APIs. [CITED: AGENTS.md] |
| V4 Access Control | yes | Host-owned admin scope provider for LiveAdmin; no public API change. [VERIFIED: codebase grep] |
| V5 Input Validation | yes | Phoenix params/controllers; no raw SAML XML handling in demo pages. [CITED: AGENTS.md] |
| V6 Cryptography | yes, invariant preservation | Do not modify signature verification, KeyInfo trust, XML parse path, or algorithm policy. [CITED: AGENTS.md] |

### Known Threat Patterns for Phoenix/Relyra Demo

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Treating document `KeyInfo` as trust source | Spoofing | Keep Relyra configured-cert verification path untouched. [CITED: AGENTS.md] |
| Adding a second XML parser in demo | Tampering | Demo must not parse SAML responses outside Relyra. [CITED: AGENTS.md] |
| Presenting test-only FakeIdP as production | Spoofing | Phase 51 should not depend on FakeIdP; later phases label it dev/test-only. [CITED: .planning/phases/51-demo-app-foundation/51-CONTEXT.md] |
| CSRF mishandling on ACS | Tampering | Use Relyra router macro and pipeline instead of custom ACS routes. [VERIFIED: codebase grep] |
| Raw XML/PEM/secrets on workspace | Information Disclosure | UI-SPEC forbids exposing raw XML, PEM, secrets, assertions, or request params. [CITED: .planning/phases/51-demo-app-foundation/51-UI-SPEC.md] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/51-demo-app-foundation/51-CONTEXT.md` - locked Phase 51 decisions.
- `.planning/phases/51-demo-app-foundation/51-UI-SPEC.md` - approved UI contract.
- `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` - requirement/phase scope.
- `AGENTS.md` - project security and workflow constraints.
- `mix.exs` - root package whitelist and optional dependency posture.
- `lib/relyra/phoenix/router.ex` - SAML route macro.
- `lib/relyra/live_admin/router.ex` - LiveAdmin route macro.
- `test/support/live_admin_test_support.ex` - scope provider/router pattern.
- Phoenix HexDocs `Mix.Tasks.Phx.New` - https://phoenix.hexdocs.pm/Mix.Tasks.Phx.New.html
- Phoenix routing guide - https://phoenix.hexdocs.pm/routing.html
- Phoenix endpoint docs - https://phoenix.hexdocs.pm/Phoenix.Endpoint.html
- Local `mix help deps`, `mix help hex.publish`, `mix phx.new` probes, and `mix hex.info` outputs.

### Secondary (MEDIUM confidence)

- Phoenix 1.8 release post - https://www.phoenixframework.org/blog/phoenix-1-8-released
- Hex `mix hex.build` source/docs snippet - https://github.com/hexpm/hex/blob/main/lib/mix/tasks/hex.build.ex

### Tertiary (LOW confidence)

- General health/readiness split guidance is inferred from Docker/CI conventions and phase requirements; no project-specific implementation exists yet. [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - verified against local Phoenix generator, Hex registry, and Relyra code seams.
- Architecture: HIGH - constrained by CONTEXT.md decisions and existing router/admin macros.
- Pitfalls: MEDIUM - package/frontend pitfalls are verified; readiness/admin-scope depth needs implementation validation.

**Research date:** 2026-06-12
**Valid until:** 2026-07-12 for Phoenix/Relyra scaffold guidance; re-check Hex versions before implementation because Phoenix and LiveView released updates during the research window.
