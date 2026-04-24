# Relyra

## What This Is

Relyra is an open-source **SAML 2.0 Service Provider library for Elixir and Phoenix** — strict-by-default validation, multi-tenant enterprise SSO, provider presets (Okta, Microsoft Entra ID, Google Workspace, Ping, OneLogin, ADFS, Shibboleth, Keycloak), telemetry, audit events, and an optional mountable LiveView admin for the self-service configuration flow that makes enterprise SAML sales actually close. It is for Phoenix SaaS teams that need secure enterprise SSO without becoming SAML experts, and for the platform/auth/security/SRE engineers who will have to operate that SSO safely for years.

## Core Value

**Every SAML login ends in a verified trust path or a typed rejection — never a silent compromise.** Relyra consumes only the exact signed XML node it verified, against configured IdP certificates, with replay protection and protocol validation, and it explains every decision in a trace an operator can act on. If everything else fails, *that* invariant must hold.

Positioning tagline: **"Enterprise SAML, calmly verified."**

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

- [x] **XML strategy ADR locked (GATE-01/GATE-03)**: ADR 0001 now fixes pure-BEAM `saxy` as default, defines objective hybrid fallback trigger, and locks conditional checksum/matrix policy (Validated in Phase 01: XML Security ADR and Guardrails).
- [x] **Hardened XML seam contract (SEC-01)**: `Relyra.Security.XML` callback surface and typed `%Relyra.Error{}` baseline are frozen for downstream protocol work (Validated in Phase 01: XML Security ADR and Guardrails).
- [x] **Canonicalization acceptance gate contract (GATE-02)**: manifest-backed adversarial corpus and binary `gate02_c14n` CI lane are in place (Validated in Phase 01: XML Security ADR and Guardrails).

### Active

<!-- v0.1 "SP-initiated SSO, verified end-to-end" — the first Hex release. -->

- [ ] **SP-initiated SSO end-to-end**: `AuthnRequest` generation + ACS `consume_response/3` with strict signed assertion/response validation
- [ ] **Hardened XML path** (entities/DTDs disabled before parse; size limits before and after base64/inflate) — ADR-backed in Phase 1 (pure-BEAM vs NIF-over-xmlsec vs hybrid) before any protocol code lands
- [ ] **XMLDSig signature verification** against configured IdP certs (never `KeyInfo` from the document); verified signature bound to the exact consumed XML node; duplicate XML IDs rejected
- [ ] **Protocol validation**: Issuer / Audience / Recipient / Destination / `InResponseTo` / `NotBefore` / `NotOnOrAfter` / replay / status / tenant-connection match
- [ ] **Five public behaviours**: `Relyra.ConnectionResolver`, `Relyra.SessionAdapter`, `Relyra.UserMapper`, `Relyra.RequestStore`, `Relyra.ReplayStore` (default adapters `@moduledoc false`)
- [ ] **Phoenix router macro**: `saml_routes/2` with connection_resolver / session_adapter / on_error options
- [ ] **Store defaults shipping**: `Relyra.RequestStore.ETS` (dev; loud warning if `Mix.env == :prod`) + `Relyra.RequestStore.Ecto` (prod default); same pair for `ReplayStore`
- [ ] **Algorithm policy**: SHA-256+ default; SHA-1 rejected; time-boxed legacy escape hatch with mandatory audit + `reason` + expiry date
- [ ] **RelayState safety**: opaque server-side handle (`rs_...` → `{return_to, tenant_id, request_id, expires_at}`) — never a raw URL
- [ ] **Typed error contract**: `%Relyra.Error{type: atom(), message: String.t(), details: map()}` with ~30 stable atoms (`:invalid_signature`, `:signature_wrapping_suspected`, `:assertion_expired`, `:replayed_assertion`, `:invalid_audience`, `:recipient_mismatch`, `:deprecated_algorithm`, …)
- [ ] **Telemetry catalog**: `[:relyra, :saml, …]` event namespace, single-file catalog module, measurements + metadata documented
- [ ] **Provider guides (v0.1)**: Okta, Microsoft Entra ID, Google Workspace recipes + local Keycloak dev container (SimpleSAMLphp optional)
- [ ] **Minimal `mix relyra.install`**: config stub + behaviour skeletons + fake IdP cert for dev; no Ecto migrations yet (land with v0.2 schemas). Golden-diff installer test from day 1.
- [ ] **CI lanes**: `qa` / `ci.fast` / `ci.integration` (Keycloak) / `ci.security` (XXE + signature-wrapping + parser-differential + SHA-1 + unsigned-assertion + replay fixtures — every known SAML CVE becomes a permanent regression fixture) / installer-path-gate / `compile --no-optional-deps --warnings-as-errors` / release-please / post-publish parity verification
- [ ] **OSS release discipline**: Release Please + Keep-a-Changelog + tag-version guard (kiln pattern) + post-publish parity check + daily drift cron with rolling issue (scrypath pattern)
- [ ] **Scope-first README + security-first docs**: README "What v0.1 includes / does not include / Install / Quick start / Guides / Security"; `SECURITY.md` with private advisory workflow; Getting Started guide; Security model doc; `CONVENTIONS.md` (SAML validation ordering, request/replay store contracts, tenancy scoping, unsafe-option audit rules)
- [ ] **Custom Credo checks**: `NoRawAssertionInLog`, `NoParseBeforeEntityDisable`, `NoSignatureSkipInPublicAPI`
- [ ] **Hex package hygiene**: `@version` in `mix.exs` is single source of truth; `package.files` is an explicit whitelist (never `test/`, `.planning/`, `prompts/`); `boundary` compiler enforces protocol-core ↔ Phoenix/Ecto/LiveView isolation
- [ ] **Legal + naming due diligence**: confirm Hex `relyra` availability + `szTheory/relyra` GitHub org + `relyra.dev` domain / trademark scan (GSD research phase deliverable before `REQUIREMENTS.md` is locked in stone)

### Out of Scope

<!-- Explicit boundaries, with reasoning. -->

**Non-goals (all milestones):**

- **Identity Provider tooling beyond `Relyra.TestSupport.FakeIdP`** — Relyra is SP-only. FakeIdP is dev/CI only, not a product.
- **OIDC / OAuth** — lives in `lockspire`. Relyra is specifically SAML 2.0.
- **Generic auth framework** (session mgmt, password login, MFA) — lives in `sigra`. Relyra's `SessionAdapter` behaviour hands off to whatever the host app uses.
- **Hosted SSO broker / SaaS / open-core billing on login volume** — data lives in the host app's database. Never.
- **SCIM / user-lifecycle management** — separate integration. Relyra exposes JIT-provisioning + `UserMapper` hooks but does not own SCIM.
- **Cryptographic claims beyond strict defaults** — no "military-grade", "bulletproof", "unhackable" language. Ever. (Brand book §22.)

**Deferred past v0.1:**

- **Ecto schemas + migrations + metadata import/export + certificate rollover** — v0.2 "Enterprise config".
- **Mountable `Relyra.LiveAdmin` LiveView** — v0.3. Biggest adoption unlock per deep research, but ships as an optional module gated by `Relyra.OptionalDeps.LiveView` once Ecto schemas exist.
- **IdP-initiated SSO** — v0.4 behind per-connection `allow_idp_initiated?: false` default, with mandatory opaque server-side RelayState + replay + audit. Never the headline feature. (Deep research §"IdP-initiated SSO".)
- **Single Logout (SLO)** — v0.5. SLO across IdPs/bindings/back-channels is genuinely hard (Passport-SAML explicitly warns IdP-initiated SLO is not fully supported). Ship as advanced, testable, partial-by-provider, behind explicit opt-in. Never as a headline feature. (Deep research §"Over-promising SLO".)
- **Encrypted assertions, signed AuthnRequests, signed metadata, artifact binding, external security review, SAML Interop Lab / Kantara conformance, migration tools** (`mix relyra.migrate.samly`, `mix relyra.migrate.ex_saml`), multi-region reference architecture — v1.0 "Production conformance".

**Package shape (locked for v0.1):**

- **Single `relyra` package on Hex**, not sibling `relyra` + `relyra_admin`. LiveView admin compiled only when `phoenix_live_view` is available via `Relyra.OptionalDeps.LiveView`. Revisit potential split at v0.4/0.5.

## Context

**Ecosystem state (April 2026, per deep-research doc):** Elixir has two SAML SP libraries. `samly` (Plug/Phoenix SP, last Hex release Jan 29 2024, v1.4.0) depends on `esaml`, which has a 2026 NVD entry for XXE-before-signature-verification on OTP < 27 — a trust-gap signal that "mostly works" is not enough on the auth boundary. `ex_saml` (v1.0.2, April 16 2026) is a Samly-derived successor that already ships path/subdomain IdP resolution, pluggable storage, RelayState anti-replay, XML entity disabling, and SHA-1 rejection, but Hex adoption signals remain low. Relyra's opening is not "write a SAML library" but "become the trusted default for Elixir/Phoenix teams that need enterprise SSO without becoming SAML experts."

**Engineering DNA (per `prompts/relyra-engineering-dna-from-prior-libs.md`):** Every pattern below has already been paid for in one or more of ten sibling libs (`sigra`, `lockspire`, `mailglass`, `threadline`, `rulestead`, `chimeway`, `lattice_stripe`, `scrypath`, `accrue`, `kiln`). Confidence rule: 5-of-10 convergence → adopt without debate. The **closest single adjacency** is `sigra` (Phoenix auth lib with mountable LiveView admin, installer feature-walker, golden-diff discipline, `CONVENTIONS.md` pattern, auth-domain-language field guide). Port verbatim unless Relyra has a specific reason not to.

**Cross-ecosystem lessons (per deep research):** Ruby (`omniauth-saml` + `ruby-saml` CVE-2024-45409, parser differentials) → split framework integration from protocol core but own the security contract end-to-end. Node (`@node-saml/passport-saml` MultiSamlStrategy, Suomi.fi fork→merge cycle) → pluggable behaviours for storage/session/mapping. Python (`python3-saml` strict-mode defaults) → make security history visible in release notes. Spring / Sustainsys (`RelyingPartyRegistration`) → model the SP↔IdP relationship as a configurable registration object. Go (`crewjam/saml` core + middleware + test-only IdP) → extension points via behaviours, not forking.

**Brand voice (per `prompts/relyra-brand-book.md`):** Calm, exact, transparent, operator-friendly, open-source serious. The brand metaphor is the **verified trust path**, not padlocks or shields or hackers. Name is always **Relyra** (title case) — never `reLyra`, `ReLyra`, or `RELYRA`. Archetype is **The Steward**, not The Warrior. Never write "SAML is easy", "magic", "bulletproof", "military-grade", or "unhackable".

**Product principles (table stakes — locked):**

1. **Strict defaults, explicit escape hatches.** Unsigned assertions rejected. SHA-1 rejected. Replay cache required in production. Unsafe compatibility exists only behind audited, time-boxed overrides.
2. **Phoenix-native ergonomics.** Router macro, Plug pipeline, generators, `{:ok, _} | {:error, %Relyra.Error{}}`, Ecto schemas as an optional integration, telemetry, test helpers. No sidecar services.
3. **Verify the right thing.** Consume only the signed XML node that was verified. One hardened parser path. No parser differentials.
4. **Explainable by default.** Every SAML login produces a validation trace. Every unsafe option leaves an audit event. Error messages name the exact field that mismatched, the expected value, and what to fix in the IdP.
5. **Operable from day one.** Certificate expiry alerts, metadata refresh (v0.2+), structured-redacted logs, debug bundles, provider-specific runbooks.
6. **Multi-tenant first.** Per-organization SAML connections, dynamic IdP resolution via `Relyra.ConnectionResolver`, attribute/group mapping, JIT provisioning hooks.
7. **Sustainable OSS.** Visible security policy (`SECURITY.md` + private advisory workflow), CI matrix, permanent regression fixtures for every known SAML CVE, release automation, changelog discipline.

**Bounded contexts (per `boundary` compiler):** (1) Protocol Core — pure SAML, no Phoenix/Plug/Ecto/LiveView; (2) Trust & Metadata — cert inventory, metadata import/export/refresh, rollover; (3) Connection Management — tenant↔IdP config, provider presets, connection state, audit log; (4) Phoenix/Plug Runtime — router macro, ACS endpoint, session-adapter integration; (5) Identity Mapping & Provisioning — NameID/attribute → local user via host callbacks, JIT policy, group-role mapping; (6) Observability & Audit — telemetry, redacted logs, audit events, debug bundles.

**Prior-research canon** (authoritative; do not re-derive):

- `prompts/RELYRA-GSD-IDEA.md` — vision, constraints, non-goals, first-milestone intent.
- `prompts/elixir-saml-lib-deep-research.md` — April 2026 ecosystem map, personas/JTBD, OASIS-aware domain language, security invariants, cross-ecosystem lessons, footguns, architecture, MVP/v1/v2 scope, provider presets, testing strategy, telemetry catalog, error taxonomy.
- `prompts/relyra-brand-book.md` — naming, voice, tagline, visual direction, module/API naming principles, security language do/don't, documentation voice, admin UI copy, error microcopy.
- `prompts/relyra-engineering-dna-from-prior-libs.md` — ten-repo DNA synthesis + SAML-specific translation. §2 convergent DNA = adopt verbatim. §5 = v0.1 starter skeleton (`mix.exs`, `.formatter.exs`, CI shape, root files).
- Secondary: `elixir-opensource-libs-best-practices-deep-research.md`, `elixir-oss-lib-ci-cd-best-practices-deep-research.md`, `elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md`, `phoenix-best-practices-deep-research.md`, `phoenix-live-view-best-practices-deep-research.md`, `ecto-best-practices-deep-research.md`, `elixir-best-practices-deep-research.md`, `The 2026 Phoenix-Elixir ecosystem map for senior engineers.md`.

**Naming / hosting preconditions (verify in research phase):**

- Hex: `relyra` — availability to be confirmed.
- GitHub: `szTheory/relyra` (jon's GitHub org).
- Domain: `relyra.dev` or equivalent — to be confirmed.
- Keyboard-shop naming overlap exists (`ReLyra`) — brand standard is **Relyra title case only**.

## Constraints

- **Tech stack** — Elixir `~> 1.18`, OTP 26+/27+/28 matrix (per DNA §5). Phoenix 1.8.x, LiveView 1.1.x, Ecto 3.13.x, Plug current stable. Final version pins confirmed in research phase against sibling repos and April 2026 ecosystem map. **Why:** matches the sibling-repo baselines (`sigra`, `lattice_stripe`, `accrue`) and the 2026 Phoenix/Elixir ecosystem reality; lower Elixir pins pull in known OTP XML/crypto bugs.
- **XML security boundary** — one hardened parser path. No parser differentials. DTDs + external entities + network fetches disabled *before any parse at all*. Size limits pre- and post-base64/inflate. **Why:** the `esaml` 2026 NVD XXE entry happened before signature verification; the library that parses unsafely is compromised regardless of signature policy. This is the non-negotiable base invariant.
- **Signature trust source** — signatures verified against configured IdP certs only, never the document's `KeyInfo`. Verified signature bound to the exact node consumed. **Why:** `ruby-saml` CVE-2024-45409 shipped because the library trusted document-provided signature context and selected the wrong node.
- **Production replay store** — cluster-safe. ETS warns loudly if `Mix.env() == :prod`. **Why:** distributed Phoenix deployments with ETS-only replay are a silent bypass; single-node assumption is a footgun.
- **Performance / budget** — OSS. Zero hosted infra. Data lives in the host app's database. **Why:** open-source sustainability + product principle ("no SaaS lock-in, no hidden auth boundary").
- **Security** — `SECURITY.md` + private advisory workflow from day 1. Every security fix becomes a permanent regression fixture (XXE, signature wrapping, parser differential, SHA-1, unsigned assertion, replay). No unsafe defaults. No "disable signature validation to make the demo pass." **Why:** Relyra sits on the auth boundary; "mostly works" is the `samly`/`esaml` trust-gap that we exist to close.
- **Compatibility — legacy IdPs** — `legacy_algorithm_policy: [allow_sha1_until: ~D[...], reason: "...", audit: true]` exists but must be time-boxed, auditable, and surfaced in the admin UI (v0.3+) with a clear risk panel. **Why:** brand book §2 + §14.5 — unsafe compatibility is explicit, not silent.
- **OSS discipline** — conventional commits + Release Please + Keep-a-Changelog + `@version` single source of truth + `package.files` explicit whitelist + CI as specification + tag-version guard + post-publish parity verification + daily drift cron. **Why:** DNA §2 convergence is 5-of-10+; skipping re-pays costs already paid by sibling libs.
- **Brand** — always "Relyra" title case. Never `reLyra` (keyboard-shop overlap), `ReLyra`, `RELYRA`, or lyre/music/constellation/shield/padlock/key/flame/bird imagery. Never say "SAML is easy" or use magic/bulletproof/military-grade language. **Why:** brand book §22 do/don't summary is locked.
- **Runtime** — Claude Code (this session) + sibling-lib Claude-first tooling. `CLAUDE.md` + `AGENTS.md` dual entry points. GSD planning discipline (`.planning/` layout). **Why:** matches sibling-repo working model.

## Key Decisions

<!-- Decisions that constrain future work. Add throughout project lifecycle. -->

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| **XML security path = ADR in Phase 1** (not locked at bootstrap) | Single largest v0.1 correctness+deploy risk per deep research §"Tradeoffs". Requires explicit research deliverable with canonicalization choice, entity-disabling guarantees, signature-wrapping defenses, deployment story, and adversarial-corpus coverage of `ruby-saml` CVE-2024-45409 + `samlify` wrapping fixtures. Options stay live: pure-BEAM XMLDSig / NIF-over-xmlsec / hybrid. | ✓ Completed in Phase 01 (ADR 0001: pure-BEAM default with conditional hybrid fallback + checksum gate) |
| **v0.1 package shape = single `relyra` with optional LiveView admin gate** | DNA convergence (sigra/lattice_stripe/threadline/scrypath/lockspire/mailglass all single-package). One install command, zero admin-specific deps for the host app. Revisit a `relyra_admin` split at v0.4/0.5 (accrue pattern). | — Pending (validate at v0.4) |
| **Request/replay store default = ship both ETS + Ecto behind one behaviour each** | DNA: sigra sessions + threadline audit use Ecto-backed defaults; ETS-dev-only is the demo/single-node story. Ship `Relyra.RequestStore.ETS` (dev, loud prod-warning) and `Relyra.RequestStore.Ecto` (prod default). Behaviour is the contract. Same for `ReplayStore`. | — Pending (v0.1 ship) |
| **`mix relyra.install` scope at v0.1 = minimal** | Config stub + behaviour skeletons + dev fake-IdP cert. Golden-diff fixture from day 1 (sigra pattern). Full Ecto migrations + schemas land with v0.2 "Enterprise config." Keeps v0.1 surface honest and matches the "no Ecto hard-dep in v0.1" posture. | — Pending (v0.1 ship) |
| **v0.1 ↔ v0.2 scope line = idea-doc split** | v0.1: "SP-initiated SSO, verified end-to-end" + security corpus + three provider guides + Keycloak dev container. v0.2: Ecto schemas, metadata import/export, cert rollover. v0.3: LiveView admin. v0.4: IdP-initiated + opaque RelayState. v0.5: SLO. v1.0: external security review + conformance + migration tools. Driven by real first-adopter JTBD (deep research §"Personas and JTBD"). | — Pending (v1.0 audit) |
| **Strict defaults + footgun non-negotiables locked at bootstrap** (not re-debated in discuss-phase) | IdP-initiated off by default; SLO deferred to v0.5; SHA-1 rejected by default; unsafe compatibility audited + time-boxed; RelayState opaque by default; replay cache required in prod. Locked before any phase planning starts. | ✓ Good (brand + deep-research + idea-doc all agree) |
| **Runtime = Claude Code + GSD planning discipline; `CLAUDE.md`/`AGENTS.md` dual entry points** | Matches sibling-repo working model (sigra, rulestead, mailglass). `.planning/` layout is canonical truth; Hex/git is the product. | ✓ Good (proven pattern) |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions (especially the Phase 1 XML ADR outcome)
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid? (SLO? IdP-initiated? Sibling-package split?)
4. Update Context with current state (Hex adoption, security advisories, provider coverage, adopter feedback themes)

---
*Last updated: 2026-04-24 after Phase 01 completion (ADR lock, seam freeze, and security gate rollout).*
