# Relyra — GSD new-project idea document

Use with: `/gsd-new-project --auto @prompts/RELYRA-GSD-IDEA.md` from the **relyra** repo root (`/Users/jon/projects/relyra`).

For **interactive** questioning plus Step 6 **four parallel researchers + synthesizer**, omit `--auto` and follow **`prompts/INTERACTIVE-GSD-NEW-PROJECT.md`** (first-message `@` list and Step 3/5/6 notes).

## One-line pitch

**Relyra** is an open-source **SAML 2.0 Service Provider library** for Elixir/Phoenix: strict-by-default validation, multi-tenant enterprise SSO, provider presets (Okta, Entra, Google Workspace, Ping, OneLogin, ADFS, Shibboleth, Keycloak), telemetry, audit events, and an optional mountable **LiveView admin** for the self-service configuration flow that makes enterprise SAML sales actually close.

## Tagline

**Enterprise SAML, calmly verified.**

## Problem

Elixir has `samly` (Plug/Phoenix SAML SP, last Hex release Jan 2024, known esaml XXE CVE) and a nascent `ex_saml` (Samly-derived, low adoption, April 2026). Neither has closed the **trust gap**: SAML sits on the authentication boundary, so "mostly works" is not enough. Phoenix SaaS teams selling into the enterprise need strict defaults, adversarial test corpora, certificate-rollover support, operator-grade debugging, a visible security-advisory process, and a self-service admin UI that lets customer IT admins configure SSO without a month of ticket ping-pong. Competing ecosystems (Ruby, Node, Python, Spring, Go) teach the lessons: split framework integration from protocol core, own the security contract end-to-end, treat SAML input as hostile before signature verification, reject parser differentials, allowlist RelayState, never default to IdP-initiated SSO, bake replay protection in. See `prompts/elixir-saml-lib-deep-research.md` for the full April 2026 ecosystem map.

## Product principles (table stakes)

- **Strict defaults, explicit escape hatches.** Unsigned assertions rejected. SHA-1 rejected. Replay cache required in production. Unsafe compatibility exists only behind audited, time-boxed overrides. (Brand pillar 2.)
- **Phoenix-native ergonomics.** Router macro, Plug pipeline, generators, `{:ok, _} | {:error, %Relyra.Error{}}` contract, Ecto schemas as an optional integration, telemetry, test helpers. No sidecar services. (Brand pillar 3.)
- **Verify the right thing.** Consume only the signed XML node that was verified. One hardened parser path. No parser differentials. (Brand pillar 1.)
- **Explainable by default.** Every SAML login produces a validation trace. Every unsafe option leaves an audit event. Error messages name the exact field that mismatched, the expected value, and what to fix in the IdP. (Brand pillar 5; brand book §14.3.)
- **Operable from day one.** Certificate expiry alerts, metadata refresh, structured-redacted logs, debug bundles, provider-specific runbooks. (Brand pillar 4.)
- **Multi-tenant first.** Per-organization SAML connections, dynamic IdP resolution via `Relyra.ConnectionResolver` behaviour, attribute/group mapping, JIT provisioning hooks.
- **Great adoption DX.** `mix relyra.install` generates config + migrations. Copy-pasteable Okta / Entra / Google Workspace recipes. Local Keycloak + SimpleSAMLphp containers for dev and CI.
- **Batteries included, optionally.** Mountable LiveView admin for the config/test-login/cert-rollover flow — the single biggest adoption unlock for B2B SaaS teams per the deep-research doc — but gated behind `Relyra.OptionalDeps.LiveView` so the core package stays small.
- **Sustainable OSS.** Visible security policy (SECURITY.md + private advisory workflow), CI matrix, permanent regression fixtures for every known SAML CVE, release automation, changelog discipline.

## Non-goals (initial milestones)

- **Not an Identity Provider.** Relyra is SP-only. IdP tooling ships only as `Relyra.TestSupport.FakeIdP` for dev/CI.
- **Not OIDC / OAuth.** That's `lockspire`'s territory. Relyra is specifically SAML 2.0.
- **Not a generic auth framework.** Session management, password login, MFA — those are `sigra`'s territory. Relyra's `Relyra.SessionAdapter` behaviour hands off to whatever the host app uses.
- **Not a hosted SSO broker.** No SaaS. No open-core billing on login volume. Data lives in the host app's database.
- **Not SCIM.** User-lifecycle management is a separate integration; Relyra exposes hooks (JIT provisioning, user-mapper behaviour) but does not own SCIM.
- **Not full Single Logout in v0.1.** SLO across IdPs, bindings, and back-channels is genuinely hard. Shipped behind explicit opt-in at v0.5+, documented as partial-by-provider. (Deep research §"Over-promising SLO".)
- **Not IdP-initiated SSO as the default path.** Supported behind per-connection opt-in with mandatory replay + opaque-RelayState controls, never as the headline feature. (Deep research §"IdP-initiated SSO".)

## Technical direction (high level)

- **Core public API shape** (stable from v0.1):
  ```elixir
  @spec start_login(Plug.Conn.t(), Relyra.Connection.t(), keyword()) ::
          {:ok, Plug.Conn.t()} | {:error, Relyra.Error.t()}
  @spec consume_response(Plug.Conn.t(), Relyra.Connection.t(), keyword()) ::
          {:ok, Relyra.LoginResult.t(), Plug.Conn.t()} | {:error, Relyra.Error.t()}
  ```
- **Phoenix router surface:**
  ```elixir
  scope "/sso", MyAppWeb do
    pipe_through :browser
    saml_routes MyApp.SSO,
      connection_resolver: MyApp.SSO.ConnectionResolver,
      session_adapter: MyAppWeb.SAMLSession,
      on_error: MyAppWeb.SAMLErrorController
  end
  ```
- **Behaviour seams** (five public behaviours — the pluggable-behaviour-trio pattern from `lattice_stripe`, extended): `Relyra.ConnectionResolver`, `Relyra.SessionAdapter`, `Relyra.UserMapper`, `Relyra.RequestStore`, `Relyra.ReplayStore`. Default adapters have `@moduledoc false`.
- **Bounded contexts** (protocol core stays isolated from Phoenix/Ecto via the `boundary` compiler):
  1. **Protocol Core** — pure SAML, no Phoenix/Plug/Ecto/LiveView. AuthnRequest generation, response decoding, hardened XML parse, XMLDSig verification, assertion decryption, protocol validation, metadata parse/generate.
  2. **Trust & Metadata** — IdP certificate inventory, metadata import/export, refresh, rollover.
  3. **Connection Management** — tenant-to-IdP config, provider presets, connection states, audit log.
  4. **Phoenix/Plug Runtime** — router macro, controllers, ACS endpoint, session-adapter integration.
  5. **Identity Mapping & Provisioning** — NameID/attribute → local user via host callbacks, JIT policy, group-role mapping.
  6. **Observability & Audit** — telemetry, redacted logs, audit events, debug bundles.
- **Error contract:** typed `%Relyra.Error{type: atom, message: String.t(), details: map}` with ~30 stable atoms (`:invalid_signature`, `:signature_wrapping_suspected`, `:assertion_expired`, `:replayed_assertion`, `:invalid_audience`, `:recipient_mismatch`, `:deprecated_algorithm`, ...). Full taxonomy in deep research §"Error taxonomy".
- **Security invariants** (non-negotiable defaults): DTDs/entities disabled before any parse; size limits pre- and post-decode; verify signature against configured IdP certs (never `KeyInfo` from the document); bind verified signature to the exact consumed XML node; reject duplicate XML IDs; reject SHA-1 unless opted in with audit; RelayState is an opaque server-side handle; replay cache required in production; request store required for SP-initiated.
- **XML security path ADR — unresolved and explicitly carved out for the GSD `research` phase.** Pure-BEAM XMLDSig vs NIF wrapper over xmlsec vs hybrid. See DNA doc §6.1.
- **Test strategy:** four layers — unit / integration (Postgres + Keycloak container) / installer-golden-diff (fresh `phx.new` + `mix relyra.install`, byte-identical snapshot) / Playwright E2E (admin LiveView). Plus a **security corpus lane** that replays XXE / signature-wrapping / parser-differential / SHA-1 / unsigned-assertion / replay fixtures. Every security fix adds a permanent fixture.
- **Telemetry from day 1.** Event namespace `[:relyra, :saml, ...]` documented in `Relyra.Telemetry`. Measurements include `duration_ms`, `xml_bytes`, `cert_days_remaining`, `replay_store_latency_ms`.
- **Package layout decision (v0.1):** single `relyra` package with optional LiveView admin gated by `Relyra.OptionalDeps.LiveView`. Revisit at v0.5 whether to split `relyra_admin` as a sibling (accrue pattern).

## OSS / engineering constraints

Ship with the same discipline as the sibling libraries (`sigra`, `lockspire`, `mailglass`, `threadline`, `rulestead`, `chimeway`, `lattice_stripe`, `scrypath`, `accrue`, `kiln`):

- **Named `mix qa` / `mix ci.fast` / `mix ci.integration` / `mix verify.*` entrypoints.** Stable CI job `id:` keys. Honest default `mix test` story (no silent exclusions).
- **`@version` in `mix.exs` as single source of truth.** `package.files` is an explicit whitelist (never `test/`, `.planning/`, `prompts/`).
- **Optional-deps gateway pattern** (`Relyra.OptionalDeps.{Ecto, LiveView, Oban, OpenTelemetry}` with `Code.ensure_loaded?/1` + module-level `@compile {:no_warn_undefined, ...}`).
- **Dialyzer strict flags** (`:error_handling, :extra_return, :missing_return, :underspecs`); PLT cached at `priv/plts/dialyzer.plt`. **Credo strict mode** with custom checks (`NoRawAssertionInLog`, `NoParseBeforeEntityDisable`, `NoSignatureSkipInPublicAPI`).
- **Release Please + Keep-a-Changelog + tag-version guard + post-publish parity verification** (scrypath pattern — workspace-clean, release-publish, release-parity; daily drift cron with rolling issue).
- **`compile --no-optional-deps --warnings-as-errors`** as a dedicated CI lane to catch downstream breakage.
- **Scope-first README** ("What v0.1 includes / does not include / Install / Quick start / Guides / Security").
- **Private security advisory workflow** via GitHub + documented disclosure process in SECURITY.md.
- **`CONVENTIONS.md` discipline layer** codifying SAML validation ordering, request/replay store contracts, tenancy scoping, unsafe-option audit rules.
- **Golden-diff installer tests** once `mix relyra.install` exists (sigra pattern — `test/fixtures/install_golden/{tree,STDOUT.txt}`).

Full synthesis: **`prompts/relyra-engineering-dna-from-prior-libs.md`**.

## Prior research (read during GSD research / planning)

1. **`prompts/elixir-saml-lib-deep-research.md`** — April 2026 ecosystem map, personas/JTBD, domain language (OASIS terminology + friendlier Phoenix vocabulary), security invariants, lessons from Ruby/Node/Python/Spring/Go SAML libs, footguns, recommended architecture, MVP/v1/v2 scope, provider presets, testing strategy, telemetry catalog.
2. **`prompts/relyra-brand-book.md`** — naming (Relyra title case; never reLyra), voice ("calm, exact, transparent, operator-friendly, open-source serious"), tagline, visual direction, module naming, API naming principles, security language do/don't, documentation voice, admin UI copy, error microcopy.
3. **`prompts/relyra-engineering-dna-from-prior-libs.md`** — OSS DNA from ten sibling libs + SAML-specific translation.
4. **`prompts/elixir-opensource-libs-best-practices-deep-research.md`** — generic reference: API design, telemetry, Hex publishing, release engineering.
5. **`prompts/elixir-oss-lib-ci-cd-best-practices-deep-research.md`** — GitHub Actions CI/CD template.
6. **`prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md`** — April 2026 system design reference (Bandit, Req, Ecto 3.13, Phoenix 1.8.5, LiveView 1.1).
7. **`prompts/phoenix-best-practices-deep-research.md`** / **`prompts/phoenix-live-view-best-practices-deep-research.md`** — Phoenix 1.8 + LiveView 1.1 patterns for the admin UI.
8. **`prompts/ecto-best-practices-deep-research.md`** — Ecto 3.13 reference for the optional storage layer.
9. **`prompts/elixir-best-practices-deep-research.md`** — idiomatic Elixir reference.
10. **`prompts/The 2026 Phoenix-Elixir ecosystem map for senior engineers.md`** — ecosystem positioning.

## Suggested first milestone (for roadmap seeding)

**Milestone v0.1 — "SP-initiated SSO, verified end-to-end"**

- Hex package **`relyra`** (confirm Hex availability in research phase). Elixir `~> 1.18`, OTP 26+/27+/28.
- **Core protocol:** AuthnRequest generation, ACS `consume_response/3`, hardened XML parse, XMLDSig verification (ADR resolved), Issuer/Audience/Recipient/Destination/InResponseTo/time/replay validation.
- **Behaviour seams:** `Relyra.ConnectionResolver`, `Relyra.SessionAdapter`, `Relyra.UserMapper`, `Relyra.RequestStore`, `Relyra.ReplayStore`.
- **Phoenix router macro** `saml_routes/2`.
- **Provider guides:** Okta, Microsoft Entra ID, Google Workspace (the three that matter for 80% of adopters). Local Keycloak dev container.
- **Error taxonomy** and typed `Relyra.Error{}`.
- **Telemetry catalog.**
- **CI:** fast + integration (Keycloak) + security corpus (XXE/wrapping/SHA-1/unsigned/replay fixtures) + installer path-gate + release lanes.
- **Docs:** scope-first README, Getting Started guide, Security model doc, SECURITY.md, CONTRIBUTING.md, MAINTAINING.md, CONVENTIONS.md.

**Subsequent milestones (not all in v0.1):** v0.2 Ecto schemas + metadata tooling + cert rollover; v0.3 mountable LiveView admin UI; v0.4 IdP-initiated SSO with opaque RelayState; v0.5 Single Logout; v1.0 external security review + conformance + migration tools. Full detail in `relyra-engineering-dna-from-prior-libs.md` §7.

## Open decisions for `/gsd-discuss-phase` / planning

- **XML security path ADR** (§6.1 of DNA doc): pure-BEAM XMLDSig vs NIF-over-xmlsec vs hybrid. Security-critical; requires explicit research-phase deliverable.
- **Package shape at v0.1:** single `relyra` with optional admin (recommendation) vs sibling `relyra` + `relyra_admin` (accrue pattern).
- **Minimum Phoenix / Ecto / PostgreSQL versions.**
- **Request/Replay store default:** ETS-dev + behaviour-required-in-prod vs Ecto-default + pluggable.
- **Multi-tenancy strategy:** `Relyra.ConnectionResolver` behaviour vs explicit `repo`/`prefix` option vs both (mailglass tenancy menu applies).
- **Installer scope:** does `mix relyra.install` generate the full Ecto schemas in v0.1, or hold until v0.2?

## GSD bootstrap commands (pick one)

- **In Cursor / Claude Code (slash workflow):** run from repo root with a clean session:

  ```text
  /gsd-new-project --auto @prompts/RELYRA-GSD-IDEA.md
  ```

  Then: `/gsd-plan-phase 1` (add `--text` in non-Claude CLIs if menus are unavailable).

- **Interactive (recommended for a new security-sensitive lib):** follow `prompts/INTERACTIVE-GSD-NEW-PROJECT.md` — paste block with all four primary `@` attachments, answer the focused questions about the §"Open decisions" list, pick Research-first for parallel `gsd-project-researcher` agents.

- **Terminal — one-shot init:** requires `git` in the repo root first (already done).

  ```bash
  cd /Users/jon/projects/relyra
  gsd-sdk init @prompts/RELYRA-GSD-IDEA.md
  ```

---

**Instruction to GSD (auto mode):** Treat this file as authoritative for **vision, constraints, non-goals, and first-milestone intent**. Pull detailed requirements from `elixir-saml-lib-deep-research.md` (domain + security + testing), the brand book (voice + naming + UI copy), and the DNA doc (engineering constraints + milestone shape). Use **research** phases to (1) validate `relyra` naming on Hex and `sztheory/relyra` on GitHub, (2) resolve the XML security path ADR, (3) audit the known SAML CVE corpus for regression fixtures, (4) confirm Phoenix 1.8 / Ecto 3.13 / LiveView 1.1 baselines against sibling repos before locking `REQUIREMENTS.md`.
