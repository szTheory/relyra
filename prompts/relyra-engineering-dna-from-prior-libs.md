# Relyra Engineering DNA — Inherited from Prior Elixir/Phoenix Libs

> **Purpose:** Master context doc for a fresh LLM seeding a new GSD project for `relyra` (security-first SAML 2.0 Service Provider library for Elixir/Phoenix, per `prompts/elixir-saml-lib-deep-research.md` and `prompts/relyra-brand-book.md`). Every pattern here has already been paid for in another Jon repo — this file is the "don't re-derive" list.
>
> **Source corpus:** Ten prior Elixir/Phoenix OSS libs, all shipped or in-flight, all GSD-planned:
> - `accrue` — Stripe-native billing toolkit (sibling monorepo, v1.0+ on Hex, 42 phases)
> - `scrypath` — Ecto-native search indexing (v0.3.4 on Hex, 70 phases, richest planning discipline)
> - `lattice_stripe` — Production Stripe SDK (v1.1 on Hex, cleanest public-API contract pattern)
> - `sigra` — Phoenix auth library w/ mountable admin LiveViews (v0.2, 59 phases — **closest adjacency to relyra**)
> - `lockspire` — Embedded OAuth/OIDC server for Phoenix (discovery-stage, richest topical split)
> - `mailglass` — Phoenix-native email framework (v0.1-dev, optional-deps master)
> - `threadline` — Audit logging for Phoenix/Ecto (v0.2-dev, append-only-by-design pattern)
> - `rulestead` — Feature flags + experimentation (in-flight, DNA-doc gold standard)
> - `chimeway` — Notification framework (discovery-stage)
> - `kiln` — Docker-sandbox / AI code-gen platform (v0.1, strictest CI `mix check` alias)
>
> **How to read this doc:** §1 is confidence calibration. §2 is convergent DNA (port verbatim). §3 is the divergent menu. §4 translates everything to SAML primitives. §5 is the concrete v0.1 skeleton. §6 is the SAML-specific gotcha list. §7 is the opinionated GSD seed plan. §8 is the source map. §9 is the ranked TL;DR.

---

## 1. Provenance and confidence calibration

| Source project | Maturity | Strongest contribution to relyra |
|---|---|---|
| `sigra` | v0.2, 59 phases, production Phoenix auth | **Single closest adjacency.** Mountable LiveView admin pattern, router macro with `saml_routes`/`sigra_routes`-style DSL, feature-walker installer architecture (`Sigra.Install.Feature` behaviour + `Runner`), golden-diff installer tests under `test/fixtures/install_golden/{tree,STDOUT.txt}`, `test/example/` host app pattern, 3-folder guides split (`introduction/flows/recipes`), `CONVENTIONS.md` discipline layer with custom Credo checks, auth-domain language pattern |
| `lockspire` | richest topical split (17 prompts) | **Closest security-adjacent precedent.** Host-app integration seam doc pattern, security-posture-as-charter, threat-model authoring style, LiveView field guide with LLM-ready build rules, Ecto-in-production rules, telemetry-audit-and-introspection doc template, release-readiness-and-conformance checklist template |
| `rulestead` | in-flight, 10-section DNA template | **Master DNA doc skeleton** (this file follows it). Rule-precedence semantics for validation trees, multi-tenancy behaviour menu, host-app boundary patterns |
| `scrypath` | v0.3.4 on Hex, 70 phases | Post-publish verification trio (`verify.workspace_clean` + `verify.release_publish` + `verify.release_parity`), daily drift cron with rolling GitHub issue, doc-contract tests, milestone-audit YAML frontmatter template |
| `lattice_stripe` | v1.1 on Hex, downstream-consumed | Cleanest `api_stability.md` contract (public surface enumeration), pluggable-behaviour trio pattern (Transport / Json / RetryStrategy with `@moduledoc false` default adapter), upstream-spec drift monitor (`drift.yml` weekly), Dependabot auto-merge patch-only, PR-title semantic-commit gate, cheatsheet guide (`cheatsheet.cheatmd`) |
| `accrue` | v1.0+, multi-package monorepo | Sibling-package shape (decide: `relyra` alone vs `relyra` + `relyra_admin`), linked-versions release-please config, browser/UAT CI lanes (`*_admin_browser.yml`, `*_host_uat.yml`), phase-numbered CI gate chain |
| `mailglass` | DNA synthesized from all 4 above | **Optional-deps gateway pattern** (`OptionalDeps.{Oban,OpenTelemetry,...}` with `Code.ensure_loaded?/1` + module-level `@compile {:no_warn_undefined, ...}`). Multi-tenant scope pattern (`Mailglass.Tenancy` behaviour + `SingleTenant` default no-op). Idempotency-key partial unique index |
| `threadline` | v0.2-dev, audit platform | Three-layer separation (capture / semantics / exploration), PgBouncer-safe actor GUC bridge, `ActorRef` as a custom Ecto type, `verify.*` alias naming discipline, trigger-backed capture pattern |
| `chimeway` | discovery-stage | Notification explainability pattern (every event → traceable path), per-channel behaviour seam (mirrors relyra's per-provider-preset surface) |
| `kiln` | v0.1, Docker-sandbox OSS | Strictest `mix check` alias (format, compile, credo, dialyzer, test, sobelow, mix_audit in one gate). Tag-version check script (`script/verify_tag_version.sh`). Dialyzer PLT caching pinned at `priv/plts/dialyzer.plt` keyed on `mix.lock` |

**Confidence rules:**
- **5-of-10 or more convergence** → adopt without debate.
- **3-of-10 to 4-of-10** → adopt unless relyra has a specific reason not to.
- **2-of-10 with diverging reasoning** → menu choice; §3 explains the trade-off.
- **1-of-10** → only port if the precedent is the closest match (e.g., sigra's mountable LiveView admin is the single closest precedent for relyra's SAML connection admin UI).

---

## 2. Convergent DNA — port verbatim

These patterns appear in **5+ of 10** prior libs. Skipping any of them means re-paying a cost already paid.

### 2.1 Repo, package, and version metadata

- **Single source of truth for version:** `@version` module attribute at the top of `mix.exs`, referenced in `docs: [source_ref: "v#{@version}"]` and `release-please-manifest.json`. Never hand-edit version in two places.
- **Hex package whitelist files explicitly** in `mix.exs`:
  `files: ~w(lib priv guides .formatter.exs mix.exs README* LICENSE* CHANGELOG*)`.
  Never auto-include the whole repo. Never include `test/example/`, `.planning/`, `prompts/`, `_build/`, or generated static assets. Add a comment above the whitelist naming what is forbidden and why.
- **Hex package metadata table:** `name`, `description`, `licenses: ["MIT"]`, `links: %{"GitHub" => @source_url, "HexDocs" => ..., "Changelog" => ..., "Guides" => ...}`. The Changelog link is the most-used by adopters in practice.
- **`.formatter.exs`** is intentionally minimal: an `inputs:` glob plus the deps (`:phoenix`, `:ecto`, `:phoenix_live_view`, `:plug`) whose macros need formatting. No custom rules. Include `.formatter.exs` itself in `package.files` so `import_deps: [:relyra]` works downstream.
- **Project root files** (always present): `README.md`, `CHANGELOG.md` (Keep-a-Changelog format), `LICENSE` (MIT), `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `MAINTAINING.md` (release runbook — secrets, branch protection, recovery decision tree). `CLAUDE.md` and `AGENTS.md` as dual entry points for LLM coworkers.
- **Module namespacing:** root module (`Relyra`) is the public surface (reflection + orchestration + error types). Internal modules use `@moduledoc false` to lock the public API. Every module has a full `@moduledoc` (public) or `@moduledoc false` (internal) — no ambiguous middle state.
- **`CONVENTIONS.md`** (sigra pattern): codify the discipline layer — SAML validation ordering, request/replay store contracts, tenancy scoping, unsafe-option audit rules, testing conventions. Pair with custom Credo checks that enforce each convention mechanically.

### 2.2 CI/CD lane structure

Every project converges on this lane shape:

| Lane | Purpose | Blocks merge? |
|---|---|---|
| **Lint** | `mix format --check-formatted`, `mix compile --warnings-as-errors`, `mix credo --strict`, `mix docs --warnings-as-errors`, `mix hex.audit`, `mix compile --no-optional-deps --warnings-as-errors` | yes |
| **Test matrix** | `mix test --warnings-as-errors` across multiple Elixir/OTP cells (minimum: 1.17/26.x, 1.19/28.x). Postgres 15+ service container with healthcheck for any Ecto-touching path | yes |
| **Integration / golden** | Fresh `mix relyra.install` byte-identical golden diff, host-app smoke, real-IdP-container integration (Keycloak / SimpleSAMLphp) | yes for paths that touch it |
| **Installer path-gate** | Shell `git diff --name-only origin/${base}...HEAD \| grep -qE '^priv/templates/relyra\.install/\|^lib/relyra/install/'` — only run expensive fixture harness when installer surfaces change | yes (conditional) |
| **Security corpus** | Replay the known-CVE fixture set (XXE, signature-wrapping, parser-differential, SHA-1, unsigned assertion, replay). This is relyra-specific but the *shape* is kiln's `sobelow`/`mix_audit` lane | yes |
| **Release-please** | Auto-bump version + CHANGELOG on `main` | n/a (opens PR) |
| **Publish-Hex** | Triggers on tag from release-please merge | n/a (release-time only) |
| **Post-publish verify** | Polls Hex for tarball visibility, compiles a throwaway consumer app, checks HexDocs reachability, runs parity diff between git tag and Hex tarball | not for that PR — runs on publish + daily cron |

Specifics that every project shares:
- **Concurrency group** with `cancel-in-progress: true` to kill stale CI runs on force-push.
- **Path filters** to skip CI on `.md` / `.planning/` / `prompts/` / `guides/` only changes when nothing in `lib/` changed.
- **Caching layers** keyed by `mix.lock` hash: `deps/`, `_build/`, dialyzer PLT (split restore → build-if-miss → save at `priv/plts/dialyzer.plt`), `~/.hex` registry, Node npm cache for Playwright.
- **Postgres service container** in any job needing Ecto, with healthcheck `--health-interval=10s --health-timeout=5s`. Credentials via env vars.
- **Secrets** (`HEX_API_KEY`, `RELEASE_PLEASE_TOKEN`) only as GHA secrets. Never echoed, never in logs, never in the workflow file.
- **Least privilege:** `permissions: contents: read` at workflow top; jobs that need `id-token: write` or `pull-requests: write` opt in explicitly.
- **SHA-pinned third-party actions with trailing version comments** (sigra pattern): `uses: actions/checkout@de0fac2e...  # v6.0.2`. Dependabot `github-actions` ecosystem handles churn.
- **Job-id contract comment** at top of each workflow file: "Stable YAML `jobs:` keys relied on by docs, `act`, and branch protection." `name:` may evolve; `id:` is immutable.
- **Scripts-first CI surface** (accrue/sigra pattern): every non-trivial CI step is a `scripts/ci/*.sh` with `set -euo pipefail`, and both invocations (`GITHUB_WORKSPACE:-$(pwd)`) work. Locally reproducible by design. Never bury logic in inline YAML `run:` blocks longer than ~6 lines.

### 2.3 Mix aliases as a product surface

Every lib exposes a small, memorable alias set that contributors and CI cite verbatim:

```elixir
defp aliases do
  [
    qa: [
      "format --check-formatted",
      "compile --warnings-as-errors",
      "credo --strict",
      "dialyzer",
      "docs --warnings-as-errors"
    ],
    "ci.fast": ["qa", "test --warnings-as-errors"],
    "ci.integration": ["test --only integration --warnings-as-errors"],
    "verify.workspace_clean": ["run scripts/verify_workspace_clean.exs"],
    "verify.release_parity": ["run scripts/verify_release_parity.exs"]
  ]
end
```

Avoid folklore commands that exist only in chat or a single doc paragraph (threadline §1 "Verify is a product surface").

### 2.4 Dialyzer + Credo shift-left

- **Dialyzer** PLT cached at `priv/plts/dialyzer.plt`, keyed on `mix.lock`. Flags: `[:error_handling, :extra_return, :missing_return, :underspecs]`. `plt_add_apps: [:mix]`.
- **Credo strict mode** with custom checks for library-specific rules. Sigra has `NoLogSafe2InLib`, `NoUnscopedOrgQueryInLib`. Relyra should have custom checks for: "no raw assertion XML in logs," "no parsing before signature verification," "no unsafe defaults in public API."
- **`mix compile --no-optional-deps --warnings-as-errors`** as a separate CI lane — catches the case where a downstream app doesn't have your optional deps (ecto, phoenix_live_view, oban, opentelemetry, etc.) compiled.

### 2.5 `@spec`-heavy module structure

- `@spec` on **all** public functions; use rich types (`:ok` / `:error` tuples with typed error struct).
- Root module `@moduledoc` documents architecture + config pointers; delegating functions are small and typed.
- **Typed error struct** with a pattern-matchable `type` field (atom), not just strings. LatticeStripe, Lockspire, and Sigra all converge on this.
  ```elixir
  defmodule Relyra.Error do
    @type t :: %__MODULE__{
            type: atom(),
            message: String.t(),
            details: map()
          }
    defexception [:type, :message, :details]
  end
  ```

### 2.6 Optional-deps gateway pattern (mailglass master)

Relyra will want to integrate cleanly with `Ecto`, `Phoenix.LiveView`, `Oban` (metadata refresh job), `OpenTelemetry` — none of which should be hard requirements. Gate each behind an `OptionalDeps.*` module:

```elixir
defmodule Relyra.OptionalDeps.Oban do
  @compile {:no_warn_undefined, [Oban, Oban.Worker, Oban.Job]}

  def available?, do: Code.ensure_loaded?(Oban)

  def schedule_metadata_refresh(job) do
    if available?() do
      Oban.insert(job)
    else
      {:error, :oban_not_loaded}
    end
  end
end
```

Paired with `elixirc_options: [no_warn_undefined: [...]]` in `mix.exs` and `optional: true` in `deps/0`.

### 2.7 `.planning/` as canonical truth

- Sigra has 40+ planning docs (PROJECT.md, MILESTONES.md, phases/, milestones/).
- Kiln uses `D-*` numeric tags (D-27, D-34) for cross-referencing decisions.
- These are NOT in git (except refs); they're session/milestone working state that serializes to CHANGELOG, MAINTAINING.md, and `CONVENTIONS.md`.
- **Planning milestones (v1.x) are separate from Hex versions (0.x)** — sigra discipline avoids confusion.

### 2.8 Hex publish + release pipeline

- **Release Please** (`release-please-config.json` + manifest) drives conventional-commits → auto-semver → PR → publish on tag merge (sigra/lattice_stripe/mailglass pattern).
- **Tag-version check** blocks publish if `mix.exs` version ≠ git tag (kiln's `script/verify_tag_version.sh`).
- **CHANGELOG** is Keep-a-Changelog format, dated releases, SemVer headings, categories: Features / Bug Fixes / Security / Documentation / Deprecated.
- **Post-publish verification** (scrypath): poll Hex for tarball visibility, compile throwaway consumer, hit HexDocs, parity-diff git tag vs Hex tarball. Runs on publish + daily cron with a rolling GitHub issue for drift.

### 2.9 ExDoc as documentation-first

- `main: "getting-started"` or `"readme"` as entry point.
- `extras:` includes README, CHANGELOG, CONTRIBUTING, SECURITY, MAINTAINING, and a `guides/` tree (`introduction/`, `flows/`, `recipes/` — sigra's 3-folder split).
- `groups_for_extras:` organizes by domain (Introduction / Guides / Recipes / Maintainers / Security).
- `groups_for_modules:` organizes the public API (Core / Protocol / Integrations / Testing / Internals).
- `source_ref: "v#{@version}"` — critical for Hex docs to link to the correct tag on GitHub.
- `skip_undefined_reference_warnings_on:` — allowlist known stale doc refs (upgrade guides for old versions).
- `.cheatmd` one-page cheatsheets (lattice_stripe pattern) for high-value surfaces.
- Docs build under `--warnings-as-errors` in CI (every prior lib).

### 2.10 Four-layer testing

1. **Unit** — standard ExUnit, doctests where helpful.
2. **Integration** — Postgres-backed, tagged `:integration`, excluded from fast lane. For relyra: real-IdP containers (Keycloak, SimpleSAMLphp).
3. **Smoke / installer golden** — fresh `phx.new` + `mix relyra.install` → byte-identical golden diff under `test/fixtures/install_golden/{tree,STDOUT.txt}`. Sigra's strongest discipline.
4. **E2E / Playwright** — admin LiveView flows, test-login wizard, metadata upload, certificate rollover UI. Upload artifacts with branch-aware retention (14d main, 7d PR).

Support layer: `test/support/` with `TestCase`, `TestData`, `Mox` mocks for ports/behaviours, fixture tree. StreamData for property tests (scoped — relay-state round-trip, XML ID uniqueness, clock-skew boundaries).

### 2.11 Telemetry from day 1

- Emit events for every meaningful transition (protocol step, state change, config event).
- Document emitted events in a `Relyra.Telemetry` module with `@moduledoc` listing event names, measurements, metadata.
- Gate OpenTelemetry integration behind an optional-deps module (mailglass pattern).
- Sigra and lattice_stripe both declare a telemetry catalog in a single file — one source of truth for event names.

### 2.12 Error tuple conventions

- `{:ok, result}` / `{:error, %Relyra.Error{type: atom, ...}}` throughout.
- Bang variants (`consume_response!/3`) raise the error struct.
- Errors are documented in README or a dedicated guide with the full atom catalog (see deep-research doc §"Error taxonomy").

### 2.13 Boundary + supply-chain audit in mix.exs

- `boundary` compiler (mailglass) to enforce module cross-cutting rules — protocol core must not depend on Ecto/Phoenix.
- `mix_audit` dev-only.
- `hex.audit` in CI (lockspire).
- `sobelow` for any Plug/Phoenix-facing surface (kiln).
- **Relyra-specific:** a custom Credo check that refuses `Logger.` calls with raw-assertion or raw-response variables in scope.

### 2.14 README scope-first pattern

Every prior README leads with scope clarity (lockspire/lattice_stripe):

```
# Relyra
Brief description + value prop ("Enterprise SAML, calmly verified.")
## What v0.1 includes
- Feature A
- Feature B
## What v0.1 does not include
- Out-of-scope item
## Installation
Code example
## Quick Start
Copy-pasteable example
## Guides
- Link to getting-started
- Link to provider presets
- Link to security model
## Security
- Link to SECURITY.md
```

This sets buyer expectations and dramatically reduces "does it support X?" issues.

### 2.15 CI as specification

Sigra's CI is 900+ lines of explicit test seams, each job documented inline (`# WR-04: redirect stdout+stderr` references to planning docs). The workflow IS the contract. Kiln's CI doubles as a "how to run locally" reference. Relyra should follow the same discipline — contributors should be able to read `ci.yml` to understand the quality bar.

---

## 3. Divergent menu — pick per use case

Patterns that split 2-3 ways across prior libs. Relyra must choose.

### 3.1 Package shape

| Option | Precedent | Best when |
|---|---|---|
| **Single package** (`relyra` only, with optional internal admin behind compile-time config) | sigra, lattice_stripe, threadline, scrypath, lockspire, mailglass | v0.1 — API still stabilizing, admin UI is optional |
| **Sibling packages** (`relyra` + `relyra_admin`) | accrue (`accrue` + `accrue_admin`) | v1.0+ — admin LiveView has enough surface area that a separate versioning track is worth the release coordination cost |

**Recommendation:** single-package v0.1 with `Relyra.LiveAdmin` as an optional module compiled only when `phoenix_live_view` is available. Re-evaluate at v0.4/0.5.

### 3.2 Admin UI

| Option | Precedent | Best when |
|---|---|---|
| **Mountable LiveView admin in-tree** | sigra (closest precedent) | You want one install command and zero extra deps for the host app |
| **Headless library only; admin is a separate package/repo** | lockspire (operator-ux-liveview as a prompt but not bundled) | Admin evolves faster than the protocol core |
| **No admin UI — CLI tasks only** | lattice_stripe, scrypath | Core audience is backend engineers comfortable editing config files |

**Recommendation:** mountable LiveView admin (sigra pattern) is the single biggest differentiator per the deep-research doc. The brand book §14 is built around it. Ship it.

### 3.3 Release automation

| Option | Precedent | Best when |
|---|---|---|
| **Release Please** (conventional commits → auto-PR) | sigra, lattice_stripe, mailglass, accrue | Team has discipline around conventional-commit PR titles |
| **Manual tag → release.yml** | lockspire, kiln | Want full control over when a release PR lands |

**Recommendation:** Release Please from v0.1 — five of the ten prior libs converge on it, and relyra's security-advisory workflow benefits from audit-trail automation.

### 3.4 Request/Replay store default

| Option | Precedent | Best when |
|---|---|---|
| **Ecto-backed default with pluggable behaviour** | sigra sessions, threadline audit events | You already require Postgres for the admin UI — reuse the dep |
| **ETS default for dev; require user-provided store for prod** | loud warnings pattern | You want to stay repo-light for single-node demos |

**Recommendation:** both. Ship `Relyra.RequestStore.ETS` (dev-only, loud warning if used in prod config) and `Relyra.RequestStore.Ecto` (production default). Behaviour is the public contract. Same for `ReplayStore`.

### 3.5 XML security path

Not a DNA choice — this is **the** ADR for relyra. See §6.1. Call it out in the GSD `research` phase explicitly.

---

## 4. Translation to SAML primitives

How DNA patterns map to SAML-specific surfaces. Brief — the deep-research doc owns the detailed vocabulary.

| DNA pattern | SAML-primitive translation |
|---|---|
| Typed error struct | `Relyra.Error.t()` with `type: atom()` — atoms listed in deep-research §"Error taxonomy" (`:invalid_signature`, `:signature_wrapping_suspected`, `:assertion_expired`, `:replayed_assertion`, `:invalid_audience`, ~30 total) |
| Telemetry catalog | `[:relyra, :saml, :response, :validate, :stop]` event namespace per deep-research §"Telemetry and SRE design" |
| Optional-deps gateway | `Relyra.OptionalDeps.{Ecto, LiveView, Oban, OpenTelemetry}` — Ecto gates the default store, LiveView gates the admin UI, Oban gates metadata-refresh jobs |
| Pluggable-behaviour trio (lattice_stripe) | `Relyra.ConnectionResolver`, `Relyra.SessionAdapter`, `Relyra.UserMapper`, `Relyra.RequestStore`, `Relyra.ReplayStore` — five behaviours, with `@moduledoc false` default adapters |
| Installer golden-diff (sigra) | `mix relyra.install` emits migrations + config stubs; `test/fixtures/install_golden/tree` is the canonical snapshot |
| Mountable admin (sigra) | `use Relyra.LiveAdmin.Router` → connection table, connection detail wizard, test-login UI, certificate rollover timeline, audit log |
| `CONVENTIONS.md` (sigra) | Codifies: "never parse before entity disabling," "consume only the verified signed node," "unsafe options must audit," "replay store must be cluster-safe in production" |
| Custom Credo checks | `NoRawAssertionInLog`, `NoParseBeforeEntityDisable`, `NoSignatureSkipInPublicAPI` |
| CI security corpus lane | Known-CVE fixture suite (`test/fixtures/security/`): XXE, signature wrapping, parser differential, SHA-1, unsigned assertion, replay, missing InResponseTo, etc. Each fixture permanent after a security fix |
| Docs scope-first README | "What v0.1 includes: SP-initiated SSO, strict assertion validation, metadata import, Okta/Entra/Google presets. What v0.1 does not include: SLO, encrypted assertions, signed metadata, SCIM." |

---

## 5. v0.1 starter skeleton

### 5.1 `mix.exs` template

```elixir
defmodule Relyra.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/szTheory/relyra"

  def project do
    [
      app: :relyra,
      version: @version,
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: elixirc_options(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      name: "Relyra",
      description: "Security-first SAML 2.0 Service Provider for Elixir/Phoenix.",
      source_url: @source_url,
      homepage_url: @source_url,
      package: package(),
      docs: docs(),
      dialyzer: dialyzer(),
      preferred_cli_env: [
        "ci.fast": :test,
        "ci.integration": :test
      ]
    ]
  end

  def application, do: [extra_applications: [:logger, :crypto, :public_key, :ssl]]

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp elixirc_options do
    [
      no_warn_undefined: [
        # populated as optional deps are added
        {Ecto.Repo, :all, 1},
        {Phoenix.LiveView, :__using__, 1},
        Oban,
        Oban.Worker,
        Oban.Job,
        OpenTelemetry.Tracer
      ]
    ]
  end

  defp deps do
    [
      # protocol core
      {:sweet_xml, "~> 0.7"},          # or final XML choice — see §6.1 ADR
      # optional integrations
      {:ecto_sql, "~> 3.13", optional: true},
      {:phoenix_live_view, "~> 1.0", optional: true},
      {:oban, "~> 2.18", optional: true},
      {:opentelemetry_api, "~> 1.3", optional: true},
      {:telemetry, "~> 1.3"},
      # dev/test only
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false},
      {:stream_data, "~> 1.1", only: [:dev, :test]},
      {:mox, "~> 1.1", only: :test},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false},
      {:boundary, "~> 0.10", runtime: false}
    ]
  end

  defp aliases do
    [
      qa: [
        "format --check-formatted",
        "compile --warnings-as-errors",
        "credo --strict",
        "dialyzer",
        "docs --warnings-as-errors"
      ],
      "ci.fast": ["qa", "test --warnings-as-errors"],
      "ci.integration": ["test --only integration --warnings-as-errors"],
      "ci.security": ["sobelow --config", "deps.audit", "hex.audit"],
      "verify.workspace_clean": ["run scripts/verify_workspace_clean.exs"],
      "verify.release_parity": ["run scripts/verify_release_parity.exs"]
    ]
  end

  defp package do
    [
      name: "relyra",
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "HexDocs" => "https://hexdocs.pm/relyra",
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "Security" => "#{@source_url}/blob/main/SECURITY.md"
      },
      # NEVER auto-include the whole repo. Excluded: test/, .planning/, prompts/, _build/.
      files: ~w(lib priv/templates priv/guides guides .formatter.exs mix.exs
                README.md LICENSE CHANGELOG.md SECURITY.md)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      extras: [
        "README.md",
        "CHANGELOG.md",
        "CONTRIBUTING.md",
        "SECURITY.md",
        "guides/introduction/getting-started.md",
        "guides/flows/sp-initiated-login.md",
        "guides/recipes/okta.cheatmd",
        "guides/recipes/entra.cheatmd",
        "guides/recipes/google-workspace.cheatmd",
        "guides/security/threat-model.md",
        "guides/security/unsafe-options.md"
      ],
      groups_for_extras: [
        Introduction: ~r"guides/introduction/.*",
        Flows: ~r"guides/flows/.*",
        Recipes: ~r"guides/recipes/.*",
        Security: ~r"guides/security/.*",
        Maintainers: ["CONTRIBUTING.md", "MAINTAINING.md"]
      ],
      groups_for_modules: [
        Core: [Relyra, Relyra.Error],
        Protocol: [
          Relyra.Protocol.AuthnRequest,
          Relyra.Protocol.Response,
          Relyra.Protocol.Assertion,
          Relyra.Protocol.Metadata
        ],
        Security: [
          Relyra.Security.XML,
          Relyra.Security.Signature,
          Relyra.Security.AlgorithmPolicy
        ],
        Integrations: [
          Relyra.Phoenix.Router,
          Relyra.Ecto,
          Relyra.LiveAdmin
        ],
        Testing: [Relyra.TestSupport]
      ]
    ]
  end

  defp dialyzer do
    [
      plt_core_path: "priv/plts/core.plt",
      plt_local_path: "priv/plts/dialyzer.plt",
      plt_add_apps: [:mix, :ex_unit],
      flags: [:error_handling, :extra_return, :missing_return, :underspecs]
    ]
  end
end
```

### 5.2 `.formatter.exs`

```elixir
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  import_deps: [:phoenix, :ecto, :phoenix_live_view, :plug]
]
```

### 5.3 CI lane shape (`.github/workflows/ci.yml`)

Stable job IDs (never rename; evolve `name:` only):

```yaml
name: CI

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

jobs:
  lint:              # qa alias — format, compile, credo, dialyzer, docs
  test_fast:         # unit + doctests, no Ecto
  test_integration:  # Postgres + real-IdP container
  test_security_corpus:  # known-CVE fixture replay
  installer_golden:  # conditional on priv/templates path
  security_audit:    # sobelow + deps.audit + hex.audit
  compile_no_optional_deps:  # catches downstream breakage
```

Release lanes (separate file `.github/workflows/release.yml`):
- `release_please`: opens version-bump PR on main
- `publish_hex`: fires on tag, runs `verify_tag_version.sh`, then `mix hex.publish`
- `verify_post_publish`: polls Hex + HexDocs, parity-diffs tarball

### 5.4 Root files (create at `git init` time via `gsd-new-project`)

```
README.md            # scope-first; leads with "Enterprise SAML, calmly verified."
CHANGELOG.md         # Keep-a-Changelog format, 0.1.0-dev stub
LICENSE              # MIT
CONTRIBUTING.md      # dev setup (.tool-versions, Postgres), CI overview, release process
CODE_OF_CONDUCT.md   # Contributor Covenant 2.1
SECURITY.md          # private advisory process, disclosure, supported versions
MAINTAINING.md       # release runbook, secrets, branch protection, recovery
CLAUDE.md            # LLM entry point — architecture pointers, where .planning/ lives
AGENTS.md            # mirror of CLAUDE.md for agent tooling
CONVENTIONS.md       # the discipline layer (see §2.1, §4)
.tool-versions       # elixir + otp pins
.formatter.exs
.credo.exs           # strict mode + custom checks
mix.exs
```

---

## 6. SAML-specific gotchas

Beyond the generic DNA — things that specifically bite SAML SP libraries. The deep-research doc covers these in depth; this list is the short "don't forget" version.

### 6.1 XML security path — **the** v0.1 ADR

Deep-research §"Tradeoffs: Pure Elixir XMLDSig vs native XML security library" is unresolved. The GSD `research` phase must produce an ADR. Options:

- **Pure BEAM** (sweet_xml + custom XMLDSig): easier install, all-Elixir, but XMLDSig/canonicalization is security-hard and easy to ship subtle bugs.
- **NIF wrapper over xmlsec**: mature C library, correctness odds higher, but deployment friction (cross-platform builds, OS libs).
- **Hybrid**: pure BEAM for metadata, native for signature verification.

**Rule:** one hardened parser path, no parser differentials, adversarial corpus that includes the ruby-saml CVE-2024-45409 fixtures and the samlify signature-wrapping fixtures. ADR must address: canonicalization choice, entity-disabling guarantees, how to prevent signature-wrapping, deployment story.

### 6.2 Signature wrapping

Consume **only** the signed XML node that was verified. Never verify one node and read attributes from another. Bind the verified signature to the exact node consumed. Test fixtures must include the well-known wrapping patterns.

### 6.3 Parse-before-verify is already dangerous

The esaml XXE CVE (2024 NVD entry) parsed attacker-controlled SAML before signature verification without disabling entity expansion. Relyra: **disable DTDs, external entities, and network fetches before any parsing at all.** Enforce size limits before and after base64 decode/inflate. Custom Credo check forbids `parse_` calls without the hardened parser.

### 6.4 Replay cache must be cluster-safe in production

ETS is fine for single-node dev/demo, but distributed Phoenix deployments need a shared store. Ship a loud warning if config selects ETS with `Mix.env() == :prod`.

### 6.5 InResponseTo binding for SP-initiated

Store pending AuthnRequest IDs atomically. Consume atomically. Without this, the SP can't bind a response to its own login intent. IdP-initiated flows lack this by definition — that's why they need the RelayState allowlist + replay cache + audit trail instead.

### 6.6 RelayState open redirect

RelayState should be an **opaque server-side handle** by default (`rs_...` → `{return_to, tenant_id, request_id, expires_at}`), not a raw URL. Arbitrary URL RelayState becomes an open redirect and a login-confusion primitive.

### 6.7 SHA-1 deprecation with time-boxed legacy escape

Default: reject SHA-1. Escape hatch: `legacy_algorithm_policy: [allow_sha1_until: ~D[...], reason: "...", audit: true]`. Audit every use. UI surfaces this loudly (brand book §14.5).

### 6.8 Certificate rollover is a first-class UX flow

Enterprises rotate IdP signing certs. Support: multiple active certs per connection, metadata refresh (cron or Oban), expiry warnings at 30/14/7 days, admin diff view before accepting surprising issuer/entity changes.

### 6.9 Don't promise SLO

Single Logout across IdPs + bindings + back channels + multiple SPs + browser sessions is **hard**. Passport-SAML explicitly warns IdP-initiated SLO is not fully supported. Relyra: document SLO as advanced, testable, partial by provider. Ship it behind explicit opt-in, not as a headline feature.

### 6.10 NameID ≠ email

NameID can be transient, persistent, unspecified, emailAddress, or Windows-domain-qualified. Attribute mapping is explicit, never inferred. Document Entra's NameID options and Google Workspace's policy.

### 6.11 Attributes are not authorization

SAML attributes carry profile + group data, but OASIS notes that attribute-based authz requires prior agreement on names/values. Build group mapping; make it explicit and auditable.

---

## 7. Opinionated GSD seed plan

Rough milestone shape for `/gsd-roadmapper` to refine. Not locked — the GSD phases own the final answer.

### Milestone v0.1 — "SP-initiated SSO, verified end-to-end"

Must include:
- `Relyra.Protocol.AuthnRequest` generation
- `Relyra.Protocol.Response.consume/3` (ACS entry point)
- Hardened XML parse (ADR from §6.1)
- Strict signature validation (signed response OR signed assertion; SHA-256+)
- Issuer / Audience / Recipient / Destination / InResponseTo / NotBefore / NotOnOrAfter / replay checks
- `Relyra.ConnectionResolver`, `Relyra.SessionAdapter`, `Relyra.UserMapper`, `Relyra.RequestStore`, `Relyra.ReplayStore` behaviours
- `Relyra.Phoenix.Router.saml_routes/2` macro
- `Relyra.Error.t()` with full atom taxonomy from deep-research
- Telemetry events emitted
- `mix relyra.install` — minimal (config stub, no Ecto required in v0.1 if storage is user-provided)
- CI: fast + integration (Keycloak container) + security-corpus (XXE, wrapping, SHA-1, unsigned, replay fixtures)
- README scope-first; Getting Started guide; Okta recipe; Security model doc
- SECURITY.md with private advisory process

### Milestone v0.2 — "Enterprise config: Ecto schemas + metadata tooling"

- `Relyra.Ecto.Connection`, `Relyra.Ecto.Certificate` schemas
- Generated migrations via `mix relyra.install --ecto`
- Metadata import (URL fetch + XML upload)
- Metadata export (SP metadata generation)
- Certificate rollover (multiple active certs per connection)
- Attribute mapping config
- Entra + Google Workspace recipes
- Drift/conformance test corpus expanded

### Milestone v0.3 — "LiveView admin UI"

- `Relyra.LiveAdmin` mountable router (sigra pattern)
- Connection table + detail wizard (brand book §14)
- Test-connection wizard with validation trace UI
- Certificate expiry timeline
- Audit log view
- Playwright E2E

### Milestone v0.4 — "IdP-initiated SSO + RelayState safety"

- Opt-in per-connection `allow_idp_initiated?: false` default
- Server-side opaque RelayState (`rs_...` handle)
- Audit every IdP-initiated login
- Expanded security corpus

### Milestone v0.5 — "Single Logout (advanced)"

- SP-initiated logout
- LogoutRequest handling
- Provider-specific SLO caveats documented
- Behind explicit opt-in

### Milestone v1.0 — "Production conformance"

- External security review
- SAML Interop Lab / Kantara conformance run
- Migration guide from Samly and ExSaml (`mix relyra.migrate.samly`)
- Encrypted assertions
- Signed AuthnRequests
- Multi-region reference architecture
- Debug bundle generator

---

## 8. Source map — where to dig for each pattern

| Pattern | File(s) to read |
|---|---|
| `mix.exs` structure template | `/Users/jon/projects/sigra/mix.exs` |
| Optional-deps gateway | `/Users/jon/projects/mailglass/lib/mailglass/optional_deps.ex` |
| CI lane structure (full) | `/Users/jon/projects/sigra/.github/workflows/ci.yml` |
| CI `mix check` mega-alias | `/Users/jon/projects/kiln/.github/workflows/ci.yml` + `kiln/mix.exs` |
| Release Please config | `/Users/jon/projects/sigra/release-please-config.json` |
| Tag-version guard | `/Users/jon/projects/kiln/script/verify_tag_version.sh` |
| Post-publish verification | `/Users/jon/projects/scrypath/` (search `verify.release_parity`) |
| Installer golden-diff | `/Users/jon/projects/sigra/test/fixtures/install_golden/` |
| Feature-walker installer arch | `/Users/jon/projects/sigra/lib/sigra/install/` |
| `CONVENTIONS.md` discipline layer | `/Users/jon/projects/sigra/CONVENTIONS.md` |
| Doc-contract tests | `/Users/jon/projects/scrypath/test/docs_contract_test.exs` |
| Custom Credo checks | `/Users/jon/projects/sigra/.credo.exs` + `sigra/lib/credo_checks/` |
| Mountable LiveView admin | `/Users/jon/projects/sigra/lib/sigra_web/live/admin/` |
| Pluggable-behaviour trio | `/Users/jon/projects/lattice_stripe/lib/lattice_stripe/` (Transport / Json / RetryStrategy) |
| Scope-first README | `/Users/jon/projects/lockspire/README.md`, `/Users/jon/projects/lattice_stripe/README.md` |
| Threat-model doc template | `/Users/jon/projects/lockspire/prompts/lockspire-security-posture-and-threat-model.md` |
| Telemetry-audit doc template | `/Users/jon/projects/lockspire/prompts/lockspire-telemetry-audit-and-introspection.md` |
| Release-readiness checklist | `/Users/jon/projects/lockspire/prompts/lockspire-release-readiness-and-conformance.md` |
| Auth domain-language field guide | `/Users/jon/projects/sigra/prompts/Auth Domain Language — A Field Guide.md` |
| DNA doc gold standard | `/Users/jon/projects/rulestead/prompts/rulestead-engineering-dna-from-prior-libs.md` |
| Verify-workspace-clean script | `/Users/jon/projects/scrypath/` (search `verify_workspace_clean`) |

When the GSD phases generate relyra-specific versions of the topical docs (security posture, telemetry, release engineering, host integration), use the lockspire/rulestead/chimeway equivalents as templates — structure, not content.

---

## 9. Ranked TL;DR — top 10 not to re-derive

1. **`@version` in `mix.exs` is the single source of truth.** Everything else references it.
2. **`package.files` is an explicit whitelist** — never include `test/`, `.planning/`, `prompts/`.
3. **Warnings-as-errors everywhere** — compile, docs, test. Plus a `compile --no-optional-deps` CI lane.
4. **Optional-deps gateway pattern** (mailglass) for Ecto / LiveView / Oban / OpenTelemetry.
5. **Typed `Relyra.Error{}` struct with atom `type`** — pattern-matchable, documented, stable public contract.
6. **Telemetry from day 1** — event catalog in one module.
7. **Release Please + Keep-a-Changelog + tag-version guard + post-publish parity check.**
8. **Scope-first README** ("What v0.1 includes / does not include / Install / Quick start / Guides / Security").
9. **Mountable LiveView admin** (sigra pattern) is relyra's biggest adoption differentiator per the brand book — do not treat it as optional cleanup later.
10. **Security-corpus CI lane is mandatory, not nice-to-have.** XXE, signature wrapping, parser differential, SHA-1, unsigned assertion, replay fixtures. Every security fix adds a permanent fixture.
