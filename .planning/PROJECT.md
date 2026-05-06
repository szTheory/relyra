# Relyra

## What This Is

Relyra is an open-source **SAML 2.0 Service Provider library for Elixir and Phoenix** — strict-by-default validation, multi-tenant enterprise SSO, provider presets (Okta, Microsoft Entra ID, Google Workspace, Ping, OneLogin, ADFS, Shibboleth, Keycloak), telemetry, audit events, **and** durable enterprise configuration: persisted connection records, runtime snapshot resolution, metadata import/export with controlled refresh, certificate inventory with staged rollover, and persisted attribute/group mappings backed by a cross-domain audit ledger. It is for Phoenix SaaS teams that need secure enterprise SSO without becoming SAML experts, and for the platform/auth/security/SRE engineers who will have to operate that SSO safely for years.

## Core Value

**Every SAML login ends in a verified trust path or a typed rejection — never a silent compromise.** Relyra consumes only the exact signed XML node it verified, against configured IdP certificates, with replay protection and protocol validation, and it explains every decision in a trace an operator can act on. Trust mutations are durable, attributable, and reviewable: every connection / metadata / certificate / mapping change co-commits an audit row inside the same transaction as the data it describes. If everything else fails, *those* invariants must hold.

Positioning tagline: **"Enterprise SAML, calmly verified."**

## Current State

- **v0.1 shipped 2026-04-25** — strict SP core with hardened XML, protocol validation, behaviour-backed stores, Phoenix runtime, telemetry, adopter docs.
- **v0.2 shipped 2026-05-06** — durable enterprise configuration. 5/5 requirements verified, 168/168 serial tests green, cross-domain audit ledger live.
- **v0.3 shipped 2026-05-06** — LiveView admin surface. All capabilities from v0.2 are now exposed via a mountable interface. 10/10 requirements verified.
- Code state at v0.3 close: ~16,500 LOC across `lib/` and `test/` (Elixir).

## Current Milestone: v0.4 — IdP-initiated SSO

**Goal:** Ship IdP-initiated SSO and opaque RelayState handling to unlock deployments where SP-initiated flows are not possible, such as enterprise dashboards and legacy portals.

**Target features:**

- **IdP-initiated SSO** — accept unsolicited assertions with security guardrails against cross-site request forgery and unsolicited assertion replay.
- **Opaque RelayState** — map state between SP and IdP without relying on untrusted data in the response.

**Multi-milestone arc:** See `.planning/MILESTONE-ARC.md` for the v0.4 → v1.0 plan and rationale (north star, adoption-blocker priority, milestone slotting, judgment calls).

**Deferred to later milestones per arc:**

- **v0.5** — Operational maturity (CFG-07 bulk ops, CFG-08 scheduled refresh, debug bundles, expiry alerts, mapping templates).
- **v0.6** — SLO (Single Logout).
- **v1.0** — External security review + conformance + docs polish.

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

**v0.1:**
- ✓ XML strategy ADR locked (GATE-01/GATE-03) — v0.1
- ✓ Hardened XML seam contract (SEC-01) — v0.1
- ✓ Canonicalization acceptance gate contract (GATE-02) — v0.1
- ✓ SP-initiated protocol core (SEC-02/03/04/05/07, PROT-01/02/03/05) — v0.1
- ✓ Store-backed trust gates (SEC-06, PROT-04, EXT-01..05) — v0.1
- ✓ Phoenix runtime integration (PHX-01/02/03/04) — v0.1
- ✓ Observability and enforcement (OBS-01..05, SEC-08) — v0.1
- ✓ Phase 06 delivery hardening (provider presets, TestSupport/FakeIdP, installer scaffolding, release discipline, scope-first docs) — v0.1

**v0.2:**
- ✓ **CFG-01** — Tenant-scoped SAML connection records (Ecto schemas + migrations) — v0.2 (Phase 07; 5/5 truths verified 2026-05-05)
- ✓ **CFG-02** — Persisted connection → runtime snapshot resolution — v0.2 (Phase 08; 5/5 truths verified 2026-05-05)
- ✓ **CFG-03** — Metadata import/export + controlled refresh w/ provenance — v0.2 (Phase 09 verified via Phase 12; serial smoke 15/15, full suite 168/168)
- ✓ **CFG-04** — Certificate inventory w/ expiry tracking + staged rollover — v0.2 (Phase 10 verified via Phase 13; serial rollover 23/23, manual sign-off)
- ✓ **CFG-05** — Persisted attribute/group mapping + durable audit history — v0.2 (Phase 11 verified via Phase 14; serial mapping/audit 62/62, manual sign-off)

**v0.3:**
- ✓ **CFG-06** — LiveView admin surface exposing connections, metadata, certificates, and mapping configuration — v0.3 (Phases 15-18; 10/10 requirements verified 2026-05-06)

### Active

<!-- Carried forward; building toward these next. -->

- [ ] **IDP-INIT-01**: User can initiate login from the IdP and rely on opaque RelayState handling.

### Out of Scope

<!-- Explicit boundaries. Includes reasoning to prevent re-adding. -->

- **Hosted SSO broker / SaaS runtime** — Relyra is a library; customer data and control stay in host applications.
- **OIDC/OAuth in-core** — Relyra is SAML-specific; OIDC/OAuth belongs to adjacent libraries.
- **Generic auth framework (passwords/MFA/session system)** — session establishment is delegated via `SessionAdapter`; host app owns auth domain.
- **Production IdP implementation** — `Relyra.TestSupport.FakeIdP` is dev/CI support only, not a product IdP.
- **SCIM lifecycle ownership** — Relyra focuses on login-time identity assertion and mapping, not full lifecycle provisioning.
- **Security-by-marketing claims (bulletproof/unhackable/military-grade)** — brand and security discipline require precise, falsifiable claims only.
- **IdP-initiated SSO** — deferred to v0.4+; adopters that need it today can run v0.2 alongside an existing IdP-initiated solution. The default must remain SP-initiated for trust-context clarity.
- **SLO (Single Logout)** — deferred to v0.5; not required for the core SP value proposition.

## Context

**Ecosystem state (April 2026, per deep-research doc):** Elixir has two SAML SP libraries. `samly` (Plug/Phoenix SP, last Hex release Jan 29 2024, v1.4.0) depends on `esaml`, which has a 2026 NVD entry for XXE-before-signature-verification on OTP < 27 — a trust-gap signal that "mostly works" is not enough on the auth boundary. `ex_saml` (v1.0.2, April 16 2026) is a Samly-derived successor that already ships path/subdomain IdP resolution, pluggable storage, RelayState anti-replay, XML entity disabling, and SHA-1 rejection, but Hex adoption signals remain low. Relyra's opening was not "write a SAML library" but "become the trusted default for Elixir/Phoenix teams that need enterprise SSO without becoming SAML experts."

**State at v0.2 close:** the v0.1 trust core (hardened XML, strict protocol, behaviour-backed stores, Phoenix runtime, observability) is now backed by durable configuration: connection records persist, resolver hydration is canonical, metadata refresh is operator-triggered with last-known-good preservation, certificate rollover is staged with optimistic-locked transitions, and every trust mutation co-commits an audit row in the same transaction as the change. The library is usable end-to-end for multi-tenant Phoenix SaaS teams that want to manage SAML connections in their own database without an external admin UI. The next adoption ramp is the optional LiveView admin (v0.3).

**Engineering DNA (per `prompts/relyra-engineering-dna-from-prior-libs.md`):** Convergent patterns from ten sibling libs continue to apply. The v0.2 closure-phase pattern (12 → produces 09's verification, 13 → 10's, 14 → 11's) is a new addition worth carrying forward when an audit surfaces verification orphans without re-opening implementation.

**Cross-ecosystem lessons (per deep research):** The v0.2 audit ledger borrows the Spring/Sustainsys "configurable registration object" framing (per-connection trust state lives in one place) and Python `python3-saml`'s "make security history visible in release notes" discipline (every audit-relevant field is rendered as an audit row, not a log line).

**Brand voice (per `prompts/relyra-brand-book.md`):** Calm, exact, transparent, operator-friendly, open-source serious. The v0.2 audit ledger is the brand metaphor made concrete — the "verified trust path" is now a queryable timeline an operator can read like a logbook.

**Product principles (table stakes — locked):**

1. **Strict defaults, explicit escape hatches.** Unsigned assertions rejected. SHA-1 rejected. Replay cache required in production. Unsafe compatibility exists only behind audited, time-boxed overrides.
2. **Phoenix-native ergonomics.** Router macro, Plug pipeline, generators, `{:ok, _} | {:error, %Relyra.Error{}}`, Ecto schemas as a first-class integration (v0.2+), telemetry, test helpers. No sidecar services.
3. **Verify the right thing.** Consume only the signed XML node that was verified. One hardened parser path. No parser differentials.
4. **Explainable by default.** Every SAML login produces a validation trace. Every unsafe option leaves an audit event. Every trust mutation produces an audit row in the same transaction as the change. Error messages name the exact field that mismatched, the expected value, and what to fix in the IdP.
5. **Operable from day one.** Certificate expiry alerts, metadata refresh (v0.2+), staged rollover (v0.2+), structured-redacted logs, debug bundles, provider-specific runbooks.
6. **Multi-tenant first.** Per-organization SAML connections (durable from v0.2), dynamic IdP resolution via `Relyra.ConnectionResolver`, attribute/group mapping (durable from v0.2), JIT provisioning hooks.
7. **Sustainable OSS.** Visible security policy (`SECURITY.md` + private advisory workflow), CI matrix, permanent regression fixtures for every known SAML CVE, release automation, changelog discipline.

**Bounded contexts (per `boundary` compiler):** (1) Protocol Core — pure SAML, no Phoenix/Plug/Ecto/LiveView; (2) Trust & Metadata — cert inventory, metadata import/export/refresh, rollover (durable from v0.2); (3) Connection Management — tenant↔IdP config, provider presets, connection state, audit log (durable from v0.2); (4) Phoenix/Plug Runtime — router macro, ACS endpoint, session-adapter integration; (5) Identity Mapping & Provisioning — NameID/attribute → local user via host callbacks, JIT policy, group-role mapping (durable from v0.2); (6) Observability & Audit — telemetry, redacted logs, audit events (cross-domain hardened in v0.2), debug bundles.

**Prior-research canon** (authoritative; do not re-derive):

- `prompts/RELYRA-GSD-IDEA.md` — vision, constraints, non-goals, milestone intent.
- `prompts/elixir-saml-lib-deep-research.md` — April 2026 ecosystem map, personas/JTBD, OASIS-aware domain language, security invariants, cross-ecosystem lessons, footguns, architecture, MVP/v1/v2 scope, provider presets, testing strategy, telemetry catalog, error taxonomy.
- `prompts/relyra-brand-book.md` — naming, voice, tagline, visual direction, module/API naming principles, security language do/don't, documentation voice, admin UI copy, error microcopy.
- `prompts/relyra-engineering-dna-from-prior-libs.md` — ten-repo DNA synthesis + SAML-specific translation. §2 convergent DNA = adopt verbatim. §5 = v0.1 starter skeleton.
- Secondary: `elixir-opensource-libs-best-practices-deep-research.md`, `elixir-oss-lib-ci-cd-best-practices-deep-research.md`, `elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md`, `phoenix-best-practices-deep-research.md`, `phoenix-live-view-best-practices-deep-research.md`, `ecto-best-practices-deep-research.md`, `elixir-best-practices-deep-research.md`, `The 2026 Phoenix-Elixir ecosystem map for senior engineers.md`.

## Constraints

- **Tech stack** — Elixir `~> 1.18`, OTP 26+/27+/28 matrix. Phoenix 1.8.x, LiveView 1.1.x, Ecto 3.13.x, Plug current stable. Optional `Req` for HTTPS metadata fetches (added in v0.2). **Why:** matches sibling-repo baselines and the 2026 Phoenix/Elixir ecosystem reality; lower Elixir pins pull in known OTP XML/crypto bugs.
- **XML security boundary** — one hardened parser path. No parser differentials. DTDs + external entities + network fetches disabled *before any parse at all*. Size limits pre- and post-base64/inflate. **Why:** the `esaml` 2026 NVD XXE entry happened before signature verification; the library that parses unsafely is compromised regardless of signature policy. Non-negotiable base invariant.
- **Signature trust source** — signatures verified against configured IdP certs only, never the document's `KeyInfo`. Verified signature bound to the exact node consumed. **Why:** `ruby-saml` CVE-2024-45409 shipped because the library trusted document-provided signature context.
- **Production replay store** — cluster-safe. ETS warns loudly if `Mix.env() == :prod`. **Why:** distributed Phoenix deployments with ETS-only replay are a silent bypass.
- **Trust-mutation auditability (v0.2+)** — every connection / metadata / certificate / mapping mutation co-commits an audit row inside the same transaction as the change. Audit payloads are redaction-safe (no XML, PEM, or key material). **Why:** the trust timeline cannot drift from the data it describes; an operator must be able to answer "who changed what, why" from the audit ledger alone.
- **Performance / budget** — OSS. Zero hosted infra. Data lives in the host app's database. **Why:** OSS sustainability + no SaaS lock-in / no hidden auth boundary.
- **Security** — `SECURITY.md` + private advisory workflow from day 1. Every security fix becomes a permanent regression fixture. No unsafe defaults. No "disable signature validation to make the demo pass." **Why:** Relyra sits on the auth boundary.
- **Compatibility — legacy IdPs** — `legacy_algorithm_policy: [allow_sha1_until: ~D[...], reason: "...", audit: true]` exists but must be time-boxed, auditable, and surfaced in the admin UI (v0.3+) with a clear risk panel. **Why:** unsafe compatibility is explicit, not silent.
- **OSS discipline** — conventional commits + Release Please + Keep-a-Changelog + `@version` single source of truth + `package.files` explicit whitelist + CI as specification + tag-version guard + post-publish parity verification + daily drift cron. **Why:** sibling-lib convergence is 5-of-10+; skipping re-pays costs already paid.
- **Brand** — always "Relyra" title case. Never `reLyra`, `ReLyra`, `RELYRA`, or lyre/music/constellation/shield/padlock/key/flame/bird imagery. Never "SAML is easy", magic, bulletproof, military-grade. **Why:** brand book §22 do/don't summary is locked.
- **Runtime** — Claude Code + sibling-lib Claude-first tooling. `CLAUDE.md` + `AGENTS.md` dual entry points. GSD planning discipline (`.planning/` layout). **Why:** matches sibling-repo working model.

## Key Decisions

<!-- Decisions that constrain future work. Add throughout project lifecycle. -->

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| **XML security path = ADR in Phase 1** (not locked at bootstrap) | Single largest v0.1 correctness+deploy risk per deep research. Required explicit research deliverable with canonicalization choice, entity-disabling guarantees, signature-wrapping defenses, deployment story, and adversarial-corpus coverage of `ruby-saml` CVE-2024-45409 + `samlify` wrapping fixtures. | ✓ Good (Phase 01: pure-BEAM default with conditional hybrid fallback + checksum gate) |
| **v0.1 package shape = single `relyra` with optional LiveView admin gate** | DNA convergence (sigra/lattice_stripe/threadline/scrypath/lockspire/mailglass all single-package). One install command, zero admin-specific deps for the host app. | ✓ Good (still single-package after v0.2; revisit at v0.4/0.5) |
| **Request/replay store default = ship both ETS + Ecto behind one behaviour each** | DNA: sigra sessions + threadline audit use Ecto-backed defaults; ETS-dev-only is the demo/single-node story. | ✓ Good (shipped v0.1) |
| **`mix relyra.install` scope at v0.1 = minimal** | Config stub + behaviour skeletons + dev fake-IdP cert. Full Ecto migrations + schemas land with v0.2. | ✓ Good (v0.2 added enterprise-config migrations as planned) |
| **v0.1 ↔ v0.2 scope line = idea-doc split** | v0.1: SP-initiated SSO + security corpus + provider guides + Keycloak dev container. v0.2: Ecto schemas, metadata import/export, cert rollover. v0.3: LiveView admin. v0.4: IdP-initiated + opaque RelayState. v0.5: SLO. v1.0: external security review + conformance. | ✓ Good (v0.1 and v0.2 both shipped on intent) |
| **Strict defaults + footgun non-negotiables locked at bootstrap** | IdP-initiated off by default; SLO deferred to v0.5; SHA-1 rejected by default; unsafe compatibility audited + time-boxed; RelayState opaque by default; replay cache required in prod. | ✓ Good (held through v0.1 and v0.2) |
| **Runtime = Claude Code + GSD planning discipline; `CLAUDE.md`/`AGENTS.md` dual entry points** | Matches sibling-repo working model. `.planning/` layout is canonical truth; Hex/git is the product. | ✓ Good (proven through v0.2) |
| **v0.2: connection aggregate has internal binary PK + public `connection_id` join key; no Ecto rows above the resolver boundary** | Public ID is stable across persistence migrations; runtime consumers see only `%Relyra.Connection{}` value structs. Avoids the Spring/Sustainsys footgun where downstream code couples to ORM rows. | ✓ Good (verified Phase 08; integration check 2026-05-06) |
| **v0.2: `idp_certificates` is the canonical runtime certificate field; `cert_chain` is a compatibility mirror** | One canonical key on the snapshot; legacy callers still work; future code reads only `idp_certificates`. | ✓ Good (validation pipeline prefers `idp_certificates`; snapshot fills both) |
| **v0.2: metadata refresh is operator-triggered only; new signing certs stage as `:next`; runtime trust never shifts implicitly** | Implicit trust shifts on metadata fetch are a silent bypass class. Operator stages → reviews → promotes. | ✓ Good (verified Phase 09/10; staged-only behavior confirmed by integration check) |
| **v0.2: all four mutation modules co-commit audit rows via a single `Relyra.Ecto.AuditWriter.append_event` seam inside the same transaction** | The audit ledger cannot drift from the data it describes; one writer = one redaction policy = one shape. | ✓ Good (verified Phase 11; cross-domain audit hardening shipped via Plan 11-03) |
| **v0.2: closure-phase pattern (12 → 09's verification, 13 → 10's, 14 → 11's)** | When an audit surfaces verification orphans, prefer producing missing verification artifacts over re-opening implementation. Cleaner audit trail; smaller blast radius; manual sign-off captured per artifact. | ✓ Good (closed all three v0.2 audit gaps without regressions; pattern worth carrying forward) |
| **v0.2 tech debt accepted at close: `MappingCommands.append_audit/8` lacks explicit `repo.rollback/1`** | Modern Ecto's `transact/1` auto-rolls on `{:error, _}`; legacy adapter fallback uses `repo.transaction/1` where audit failure could commit mapping rows. Other three co-commit sites use the explicit pattern. | ⚠️ Revisit (track for v0.3 cleanup; not reproducible against current dep set) |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state (Hex adoption, security advisories, provider coverage, adopter feedback themes)

---
*Last updated: 2026-05-06 — v0.3 LiveView admin milestone started.*
