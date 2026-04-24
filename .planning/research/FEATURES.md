# Feature Research — Relyra

**Domain:** SAML 2.0 Service Provider library for Elixir/Phoenix
**Researched:** 2026-04-24
**Confidence:** HIGH (bootstrap-locked scope; cross-ecosystem and prior-lib DNA synthesis is extensive; ADR-level XML-security ambiguity is the only LOW item)
**Downstream consumer:** `REQUIREMENTS.md` for the v0.1 "SP-initiated SSO, verified end-to-end" milestone. Roadmapper uses the milestone column below to draw phase boundaries.

---

## 0. Reading guide

This file is **prescriptive**. Locked decisions (`PROJECT.md`, `RELYRA-GSD-IDEA.md`, brand book, deep-research doc, engineering DNA doc) are quoted and translated, not re-litigated. Every feature has:

- **Category** — Table Stakes / Differentiator / Anti-feature / Test-support
- **Milestone** — v0.1 / v0.2 / v0.3 / v0.4 / v0.5 / v1.0 / out-of-scope-forever
- **Complexity** — LOW (<1 phase), MED (1–2 phases), HIGH (≥3 phases or security-critical)
- **Depends on** — feature DAG edges
- **Persona priority** — which of the five personas most need it

**Personas** (from deep-research doc §"Personas and jobs-to-be-done"):

- **P1 — Phoenix SaaS engineer.** "Enterprise customer requires SAML. I need it working safely this week."
- **P2 — Platform/auth team.** "Maintainable multi-tenant enterprise SSO subsystem."
- **P3 — Customer IT admin.** "Configure my company's IdP without back-and-forth."
- **P4 — Security engineer.** "Prove this does not accept forged, replayed, expired, or misdirected assertions."
- **P5 — SRE/DevOps.** "Keep SSO reliable and diagnosable after launch."

---

## 1. Table Stakes — v0.1 MUST ship (adopters will leave if missing)

If any of these is missing at v0.1 publish, an adopter comparing Relyra to `samly` / `ex_saml` / cross-ecosystem libs will reject the library at the evaluation stage. These are **not negotiable**. They feed directly into `REQUIREMENTS.md` as v0.1 Requirements.

### 1.1 Protocol core — SP-initiated SSO end-to-end

| # | Feature | Milestone | Complexity | Depends on | Persona priority |
|---|---|---|---|---|---|
| TS-1 | `Relyra.Protocol.AuthnRequest` generation (ID, Issuer, ACS URL, binding, optional NameIDPolicy, optional RequestedAuthnContext, optional ForceAuthn/IsPassive) | v0.1 | MED | TS-5 (XML parse path ADR resolved) | P1 (critical), P2, P4 |
| TS-2 | HTTP-Redirect binding: deflate + base64 + URL-encode + optional `SigAlg`/`Signature` query params for signed AuthnRequests (v0.1 ships the **receive** side; v1.0 adds the sign-and-send side) | v0.1 | MED | TS-1 | P1 (critical), P4 |
| TS-3 | HTTP-POST binding: base64 form-encode receive; form-post send | v0.1 | MED | TS-1 | P1 (critical) |
| TS-4 | `Relyra.consume_response/3` — the ACS entry point. `{:ok, %LoginResult{}, Plug.Conn.t()} \| {:error, %Relyra.Error{}}` | v0.1 | HIGH | TS-1..TS-12 | P1 (critical), P4 (critical) |
| TS-5 | Hardened XML parse path — **DTDs + external entities + network fetches disabled before any parse**. Size limits before AND after base64/inflate. One parser path, no parser differentials. ADR-backed. | v0.1 | HIGH | — (prerequisite for everything) | P4 (critical), P1 |
| TS-6 | XMLDSig verification against configured IdP certs (never `KeyInfo` from the document). Verified signature bound to the **exact consumed XML node**. | v0.1 | HIGH | TS-5 | P4 (critical) |
| TS-7 | Signed-node exclusivity: read attributes only from the node that was covered by the verified signature. No "verify response, read from unsigned assertion" confusion. | v0.1 | HIGH | TS-6 | P4 (critical) |
| TS-8 | Duplicate XML ID rejection (`:duplicate_xml_id`) to defeat wrapping variants | v0.1 | MED | TS-5 | P4 (critical) |
| TS-9 | Strict algorithm policy: SHA-256+ default; RSA-SHA256/384/512 and ECDSA-SHA256/384/512 allowed; **SHA-1 rejected** (`:deprecated_algorithm`). Time-boxed `legacy_algorithm_policy: [allow_sha1_until: ~D[...], reason: "...", audit: true]` escape hatch. | v0.1 | MED | TS-6 | P4 (critical), P3 (sees it in UI v0.3) |
| TS-10 | Replay cache — atomic consume of response/assertion IDs. Cluster-safe store **required in production**. Loud warning if `Mix.env() == :prod` and ETS store selected. | v0.1 | MED | TS-19 (ReplayStore behaviour) | P2 (critical), P4 (critical), P5 |
| TS-11 | RelayState as opaque server-side handle: `rs_...` token → `{return_to, tenant_id, request_id, expires_at}` record. Never a raw URL. | v0.1 | MED | TS-20 (RequestStore behaviour) | P4 (critical), P1 |
| TS-12 | Tenant/connection binding — the validated assertion must be bound to the connection resolved for this ACS request (prevents "valid assertion for tenant A consumed at tenant B's ACS") | v0.1 | MED | TS-4, TS-18 | P2 (critical), P4 |

### 1.2 Protocol validation — every field that matters

| # | Feature | Milestone | Complexity | Depends on | Persona priority |
|---|---|---|---|---|---|
| TS-13 | Issuer validation (match configured IdP entity ID) — `:issuer_mismatch` | v0.1 | LOW | TS-6 | P4 (critical) |
| TS-14 | Audience validation (match configured SP entity ID) — `:invalid_audience` | v0.1 | LOW | TS-6 | P4 (critical), P3 (error message naming matters for admin) |
| TS-15 | Recipient validation (match current ACS URL) — `:recipient_mismatch` | v0.1 | LOW | TS-6 | P4 (critical) |
| TS-16 | Destination validation (match current ACS URL for response-level `Destination` attr) — `:destination_mismatch` | v0.1 | LOW | TS-6 | P4 (critical) |
| TS-17 | `InResponseTo` binding — required for SP-initiated flows. Atomic lookup-and-consume in RequestStore. `:in_response_to_missing` / `:in_response_to_mismatch` | v0.1 | MED | TS-20, TS-4 | P4 (critical), P1 |
| TS-18 | Time-conditions validation: `NotBefore`, `NotOnOrAfter`, `SubjectConfirmationData/NotOnOrAfter`, small configurable clock skew (default ~30s). `:assertion_expired`, `:assertion_not_yet_valid`, `:clock_skew_exceeded` | v0.1 | LOW | TS-6 | P4 (critical), P5 |
| TS-19 | Status code validation — only `urn:oasis:names:tc:SAML:2.0:status:Success` accepted; other statuses map to `:unsupported_status` with preserved sub-status for logging | v0.1 | LOW | TS-4 | P4, P1 |
| TS-20 | Bearer SubjectConfirmation validation — method is bearer, Recipient matches, NotOnOrAfter valid, InResponseTo matches (for SP-initiated) | v0.1 | LOW | TS-15, TS-17, TS-18 | P4 (critical) |

### 1.3 Public behaviours — the five extension points

| # | Feature | Milestone | Complexity | Depends on | Persona priority |
|---|---|---|---|---|---|
| TS-21 | `Relyra.ConnectionResolver` behaviour — `resolve(Plug.Conn.t()) :: {:ok, Connection.t()} \| {:error, Error.t()}`. **Multi-tenant first** — this is the behaviour that makes per-org SAML trivial. | v0.1 | LOW | — | P2 (critical), P1 |
| TS-22 | `Relyra.SessionAdapter` behaviour — `sign_in(conn, principal, opts) :: {:ok, conn} \| {:error, term()}`. Hands off to whatever the host app uses (sigra, `sigra` not required, custom UserAuth, Pow, etc.). | v0.1 | LOW | — | P1 (critical), P2 |
| TS-23 | `Relyra.UserMapper` behaviour — `map(Principal.t(), Connection.t()) :: {:ok, user_ref} \| {:error, term()}`. App callback converting SAML principal to local user. | v0.1 | LOW | — | P1 (critical), P2 |
| TS-24 | `Relyra.RequestStore` behaviour — `put/3`, `pop/1` for pending AuthnRequest IDs + relay state records. | v0.1 | LOW | — | P2 (critical), P4 |
| TS-25 | `Relyra.ReplayStore` behaviour — `put_new/2` atomic-or-fail for consumed assertion/response IDs. | v0.1 | LOW | — | P2 (critical), P4 |
| TS-26 | **Default adapters with `@moduledoc false`** — `Relyra.RequestStore.ETS` (dev, loud prod-warning) + `Relyra.RequestStore.Ecto` (prod default, compiles only if Ecto available); same pair for ReplayStore. Behaviour is the public contract; defaults are an implementation detail. | v0.1 | MED | TS-24, TS-25, TS-55 (OptionalDeps.Ecto) | P1 (dev story), P2 (prod story) |

### 1.4 Phoenix runtime — router macro + generated routes

| # | Feature | Milestone | Complexity | Depends on | Persona priority |
|---|---|---|---|---|---|
| TS-27 | `saml_routes/2` router macro with options: `connection_resolver`, `session_adapter`, `on_error`, `path_prefix` (default `/sso/:connection_id`) | v0.1 | MED | TS-21, TS-22 | P1 (critical) |
| TS-28 | Generated routes: `GET /metadata`, `GET /login`, `POST /login`, `POST /acs`, `GET /logout` (stub in v0.1), `POST /logout` (stub in v0.1). **SLO endpoints (`/slo`) NOT generated until v0.5.** | v0.1 | MED | TS-27 | P1 (critical), P3 (metadata URL) |
| TS-29 | SP metadata XML generation endpoint — exposes SP entity ID, ACS URL, SLO URL (if configured), SP signing/encryption certs, supported bindings, NameIDFormat. **This is what P3 copies into Okta/Entra/Google.** | v0.1 | MED | TS-27 | P3 (critical), P1 |
| TS-30 | Error controller contract — `on_error` callback receives `%Plug.Conn{}` + `%Relyra.Error{}`; default behaviour renders a safe, non-PII error page | v0.1 | LOW | TS-27 | P1 (critical), P3 (error UX) |

### 1.5 Typed error contract

| # | Feature | Milestone | Complexity | Depends on | Persona priority |
|---|---|---|---|---|---|
| TS-31 | `%Relyra.Error{type: atom(), message: String.t(), details: map()}` defexception | v0.1 | LOW | — | P1 (critical), P4, P5 |
| TS-32 | ~30 stable error atoms, organized into the eight categories from the deep-research doc: decode/input, XML safety, trust/signature, protocol, conditions, mapping, provisioning, operational. **Every atom is a committed public API** (SemVer-protected from v0.1). | v0.1 | MED | TS-31 | P4 (critical), P5 (alerting on error codes) |
| TS-33 | Error messages name **the exact field that mismatched**, the expected value, and what to fix in the IdP (brand book §15 "error voice"). Never "Invalid SAML." | v0.1 | MED | TS-31 | P3 (critical), P1 |
| TS-34 | `details` map contains safe debug values only — connection_id, tenant_id, IdP entity-ID hash, certificate fingerprint prefix, validation step, timing. **Never raw XML or PII.** | v0.1 | LOW | TS-31 | P4 (critical), P5 |

### 1.6 Observability — telemetry + redacted logs

| # | Feature | Milestone | Complexity | Depends on | Persona priority |
|---|---|---|---|---|---|
| TS-35 | `Relyra.Telemetry` single-file catalog module — `@moduledoc` lists every event, measurement, metadata field. One source of truth. | v0.1 | LOW | — | P5 (critical) |
| TS-36 | Event namespace `[:relyra, :saml, ...]` — emit `:start`/`:stop`/`:exception` triplets for `login`, `authn_request`, `response.decode`, `response.validate`, `signature.verify`, `replay.check`, `user.map`, `session.establish`, `logout`, `metadata.refresh` (v0.2), `certificate.expiry.check` (v0.2) | v0.1 | MED | TS-35, TS-4 | P5 (critical), P2 |
| TS-37 | Measurements: `duration_ms`, `xml_bytes`, `base64_bytes`, `inflated_bytes`, `assertion_count`, `attribute_count`, `request_store_latency_ms`, `replay_store_latency_ms` | v0.1 | LOW | TS-36 | P5 (critical) |
| TS-38 | Metadata: `connection_id`, `organization_id`, `provider_preset`, `flow` (`:sp_initiated`), `binding` (`:redirect`/`:post`), `outcome` (`:ok`/`:error`), `error_code`, `idp_entity_id_hash`, `signature_algorithm`, `digest_algorithm` | v0.1 | LOW | TS-36 | P5 (critical), P2 |
| TS-39 | Redacted structured logs — connection_id, tenant_id, IdP entity-ID hash, cert fingerprint prefix, validation step, error atom, timing, payload byte sizes, request-ID hash. **Never raw assertion/response XML, decrypted assertions, private keys, full certs, full NameID/email.** | v0.1 | MED | — | P4 (critical), P5 |
| TS-40 | Custom Credo check `NoRawAssertionInLog` — refuses `Logger.*` calls with raw-assertion or raw-response variables in scope | v0.1 | MED | TS-39 | P4 (critical maintainer invariant) |

### 1.7 Provider guides + Keycloak dev container

| # | Feature | Milestone | Complexity | Depends on | Persona priority |
|---|---|---|---|---|---|
| TS-41 | Okta recipe (`guides/recipes/okta.cheatmd`) — copy-paste Audience URI, ACS URL, SAML Response signed settings, Okta-label ↔ Relyra-key crosswalk ("Audience URI (SP Entity ID)" ↔ `sp_entity_id`) | v0.1 | LOW | TS-29 | P1 (critical), P3 (critical) |
| TS-42 | Microsoft Entra ID recipe — Reply URL / ACS URL, Identifier / Entity ID, certificate download, NameID format options, Entra-label ↔ Relyra-key crosswalk | v0.1 | LOW | TS-29 | P1 (critical), P3 (critical) |
| TS-43 | Google Workspace recipe — globally unique Entity ID, Start URL / RelayState considerations, "entire response signed" vs "assertion signed" choice mapping | v0.1 | LOW | TS-29 | P1 (critical), P3 (critical) |
| TS-44 | Local **Keycloak dev container** — `docker-compose.yml` + seed realm + test users + IdP metadata. Documented in the Getting Started guide. Also drives CI `ci.integration` lane. | v0.1 | MED | — | P1 (critical dev loop), P4 (critical for security corpus) |
| TS-45 | Optional SimpleSAMLphp container (deferred documentation; not a v0.1 blocker — Keycloak alone satisfies P1 and P4) | v0.2 | LOW | TS-44 | P4 |

### 1.8 Installer (minimal v0.1 surface)

| # | Feature | Milestone | Complexity | Depends on | Persona priority |
|---|---|---|---|---|---|
| TS-46 | `mix relyra.install` Mix task (Igniter-based per sigra pattern) — generates: `config/config.exs` stub, `lib/<app>/sso/` behaviour skeletons (ConnectionResolver, SessionAdapter, UserMapper), dev fake-IdP cert + key, router macro usage snippet printed to STDOUT. **No Ecto migrations in v0.1** (that ships with v0.2). | v0.1 | MED | TS-21, TS-22, TS-23 | P1 (critical) |
| TS-47 | Installer golden-diff test — `test/fixtures/install_golden/{tree,STDOUT.txt}` byte-identical snapshot; CI fails on unexpected diff. Sigra pattern, adopted verbatim. | v0.1 | MED | TS-46 | P1 (DX polish), maintainer discipline |
| TS-48 | Installer path-gate CI lane — expensive golden-diff harness runs only when `priv/templates/relyra.install/` or `lib/relyra/install/` paths change (per engineering-DNA §2.2) | v0.1 | LOW | TS-47 | — (CI health) |

### 1.9 OSS hygiene + security workflow

| # | Feature | Milestone | Complexity | Depends on | Persona priority |
|---|---|---|---|---|---|
| TS-49 | `SECURITY.md` with private advisory workflow (GitHub Security Advisories), supported-version matrix, disclosure SLA | v0.1 | LOW | — | P4 (critical), OSS maintainer |
| TS-50 | CI `ci.security` lane — replays the known-CVE fixture corpus (XXE, signature wrapping, parser differential, SHA-1, unsigned-assertion, replay, missing InResponseTo, oversize inflation). **Every security fix adds a permanent fixture**, never removed. | v0.1 | HIGH | TS-5, TS-6, TS-8, TS-10, TS-17 | P4 (critical), maintainer |
| TS-51 | Scope-first README — "What v0.1 includes / does not include / Install / Quick start / Guides / Security" (lockspire/lattice_stripe pattern) | v0.1 | LOW | — | P1 (critical at evaluation), P2, P4 |
| TS-52 | Keep-a-Changelog `CHANGELOG.md` with Security category called out separately | v0.1 | LOW | — | P4, adopters |
| TS-53 | Release Please + conventional commits + tag-version guard + post-publish parity check (scrypath + kiln pattern) | v0.1 | MED | — | — (OSS sustainability) |
| TS-54 | Custom Credo checks: `NoRawAssertionInLog` (TS-40), `NoParseBeforeEntityDisable`, `NoSignatureSkipInPublicAPI` — invariants enforced at compile time | v0.1 | MED | — | P4 (critical maintainer invariant) |
| TS-55 | `Relyra.OptionalDeps.{Ecto, LiveView, Oban, OpenTelemetry}` gateway modules (mailglass pattern) — `Code.ensure_loaded?/1` + `@compile {:no_warn_undefined, ...}` | v0.1 | LOW | — | Maintainer discipline; unblocks TS-26 and v0.3 admin |
| TS-56 | `boundary` compiler enforcing: Protocol Core ↔ Phoenix ↔ Ecto ↔ LiveView isolation (six bounded contexts from `PROJECT.md`) | v0.1 | MED | — | P4 (critical), maintainer |
| TS-57 | `CONVENTIONS.md` (sigra pattern) codifying SAML-specific rules: validation ordering, request/replay store contracts, tenancy scoping, unsafe-option audit rules, redaction rules | v0.1 | LOW | — | Maintainer, P4 |
| TS-58 | `compile --no-optional-deps --warnings-as-errors` CI lane — catches breakage when downstream lacks Ecto/LiveView/Oban | v0.1 | LOW | TS-55 | Maintainer, P1 |

### 1.10 Test-support — v0.1 TABLE STAKES (adopters cannot write tests otherwise)

Adopters writing their first ConnCase test need these immediately. If Relyra ships without `Relyra.TestSupport`, adopters will hand-roll fixtures and the library will be judged "incomplete." This is the lesson from Go's `crewjam/saml` (test-only IdP), Python's `python3-saml` test vectors, and Node's `@node-saml/passport-saml` example fixtures.

| # | Feature | Milestone | Complexity | Depends on | Persona priority |
|---|---|---|---|---|---|
| TS-59 | `Relyra.TestSupport.setup_saml_connection/1` — takes `:okta`/`:entra`/`:google_workspace`/`:keycloak`/`:generic` preset, returns a fully-formed `%Relyra.Connection{}` with fixture IdP cert, signed-response key, and canonical ACS/Entity ID. | v0.1 | MED | TS-41..TS-44 | P1 (critical) |
| TS-60 | `Relyra.TestSupport.post_saml_response/3` — `post_saml_response(conn, connection, fixture: :okta_success)`. Loads a canonical signed-response fixture, POSTs it to ACS. Variants: `:okta_success`, `:entra_success`, `:google_success`, `:expired_assertion`, `:wrong_audience`, `:wrong_recipient`, `:replayed`, `:wrapping_attack`, `:sha1_signed`, `:unsigned`. | v0.1 | HIGH | TS-59, TS-50 | P1 (critical), P4 (critical — these fixtures ARE the security corpus) |
| TS-61 | `Relyra.TestSupport.assert_saml_signed_in/2` — asserts that the conn has been signed in through the configured SessionAdapter and that a `%Relyra.Principal{}` is available; complements typical `assert redirected_to/2`. | v0.1 | LOW | TS-60, TS-22 | P1 (critical) |
| TS-62 | `Relyra.TestSupport.assert_saml_error/2` — asserts `{:error, %Relyra.Error{type: :invalid_audience}}` with actionable failure output | v0.1 | LOW | TS-60, TS-31 | P1 (critical), P4 |
| TS-63 | `Relyra.TestSupport.FakeIdP` — dev/CI-only minimal IdP that accepts an AuthnRequest and returns a signed SAMLResponse. Runs as a supervised child process in dev: `children = [{Relyra.TestSupport.FakeIdP, port: 4040, signing_key: :dev}]`. **Explicitly not a product** — `@moduledoc "FOR DEV AND CI ONLY. Not a SAML Identity Provider."` | v0.1 | HIGH | TS-1, TS-6, TS-46 | P1 (critical dev loop), P4 (corpus generation) |
| TS-64 | `Relyra.TestSupport.FakeIdP` operations: `start_sso/2` (handles AuthnRequest, returns signed Response), `sign_response/2` (helper for building adversarial fixtures), `rotate_cert/1` (rollover drill), `sign_with_sha1/2` (for legacy-compat tests), `emit_wrapping_variant/2` (security corpus generator) | v0.1 | HIGH | TS-63 | P1, P4 (critical) |
| TS-65 | Fixture directory `test/fixtures/saml/` — canonical signed responses from each provider (sanitized), adversarial payloads, metadata fixtures. Deep-research §"Security regression corpus" is the inventory. | v0.1 | MED | TS-60 | P4 (critical), P1 |
| TS-66 | `Relyra.TestSupport.ConnCase` / `SAMLCase` — `use Relyra.TestSupport.SAMLCase` imports `assert_saml_*` helpers, sets up a default connection, stubs RequestStore and ReplayStore via Mox | v0.1 | MED | TS-59..TS-62 | P1 (critical DX) |
| TS-67 | `Relyra.TestSupport.ResponseBuilder` — builder API for hand-crafting responses: `ResponseBuilder.new(connection) \|> add_assertion(attrs) \|> sign(cert) \|> to_base64()`. Essential for adopter-side edge-case tests. | v0.1 | MED | TS-6 | P1, P4 |

---

## 2. Differentiators — Why pick Relyra over `samly` / `ex_saml` / `ruby-saml` / `passport-saml` / `python3-saml` / `crewjam/saml` / Spring Security SAML / Sustainsys

**Table stakes are the ante.** Differentiators are why an adopter evaluating Elixir SAML libraries *in Q2 2026* picks Relyra. The deep-research doc's competitive synthesis and the brand book's voice guidance inform every item below. **Each differentiator names what Relyra does that competitors do not do, and when it ships.**

### 2.1 Differentiators that ship in v0.1 (ship these or the v0.1 release is not differentiated)

| # | Feature | Why it wins vs competitors | Milestone | Complexity | Depends on | Persona priority |
|---|---|---|---|---|---|---|
| D-1 | **Multi-tenant first via `ConnectionResolver` behaviour** — per-org IdP resolution is a first-class public behaviour, not a hack on top of a single-IdP design | `samly` requires config-file acrobatics for multi-IdP; `ex_saml` ships path/subdomain resolution but the behaviour isn't the primary extension seam; `ruby-saml` has no tenancy concept; `passport-saml` has `MultiSamlStrategy` but it's tacked on; `crewjam/saml` is single-SP; Spring's `RelyingPartyRegistrationRepository` is the closest precedent we're matching. Relyra ships this as **the primary abstraction**. | v0.1 | — (covered by TS-21) | P2 (critical differentiator) |
| D-2 | **Strict-by-default posture with a visible security history** — SHA-1 rejected, unsigned rejected, replay required in prod, RelayState opaque, entities disabled pre-parse — all shipped at v0.1 with a public security corpus in CI | `samly`/`esaml` shipped the 2026 XXE-before-signature CVE; `ruby-saml` had CVE-2024-45409 (parser-differential auth bypass) and later parser-differential issues; `samlify` < 2.10.0 shipped signature-wrapping. Relyra's differentiator: **every one of those becomes a permanent CI fixture and is named in the security docs.** | v0.1 | — (covered by TS-5, TS-6, TS-7, TS-8, TS-9, TS-10, TS-11, TS-50) | P4 (critical differentiator) |
| D-3 | **Phoenix-native ergonomics at the highest level of polish in the ecosystem** — `saml_routes/2` router macro, Plug pipeline integration, `{:ok, _} \| {:error, %Relyra.Error{}}`, telemetry from day one, Ecto optional, LiveView admin coming v0.3 | `samly` is Phoenix-aware but 2024-stale; `ex_saml` is closer but its admin UX story is underdeveloped; non-Elixir competitors obviously can't compete here. **The sigra-DNA router-macro shape is what Phoenix engineers expect in 2026.** | v0.1 | — (covered by TS-27, TS-28, TS-30, TS-31, TS-36) | P1 (critical differentiator) |
| D-4 | **Validation-trace taxonomy from day one** — every login produces a traceable sequence of validation steps (brand book §14.3 labels: Received → Decoded → Parsed → Matched → Verified → Validated → Checked → Rejected → Mapped → Established). Exposed via telemetry in v0.1; exposed in the UI in v0.3. | **No competitor ships this.** `python3-saml` has strict-mode logs; `passport-saml` has strategy-level hooks; none model the validation pipeline as a named, ordered, observable sequence that an operator can reason about. | v0.1 | TS-36, TS-38, brand book §14.3 label vocabulary | P5 (critical differentiator), P4, P3 (sees it in v0.3) |
| D-5 | **Typed error taxonomy (~30 stable atoms) as a SemVer-protected public API** | `samly`/`ex_saml` surface errors as tuples of varying shapes; `ruby-saml` raises specific exception classes but not a taxonomy; `python3-saml` has error strings; `passport-saml` surfaces errors via callback. Relyra: **each of the 30 atoms is documented, telemetry-tagged, dashboardable, and alertable from day one.** | v0.1 | — (covered by TS-31, TS-32, TS-33) | P5 (critical differentiator — alerting rules build against stable atoms), P4 |
| D-6 | **Provider presets with per-provider label translations** — in docs AND errors AND (from v0.3) UI. "Okta calls this 'Audience URI (SP Entity ID)'; Relyra calls it `sp_entity_id`" — everywhere that matters. | `samly` has provider guides; `ex_saml` also; `ruby-saml`'s `omniauth-saml` is generic. Relyra's differentiator: **the crosswalk is structured data** (a preset module) and it drives error messages, admin labels, and docs simultaneously. | v0.1 | — (covered by TS-41..TS-43) | P3 (critical differentiator), P1 |
| D-7 | **Custom Credo checks as compile-time invariants** — `NoRawAssertionInLog`, `NoParseBeforeEntityDisable`, `NoSignatureSkipInPublicAPI` enforce the security contract at PR-review time, not just at runtime | Unique to Relyra. `samly`/`ex_saml` don't ship Credo checks. Cross-ecosystem libs can't (no Credo). **Signals maintainer seriousness to P4.** | v0.1 | — (covered by TS-54) | P4 (strong differentiator for security-review-style evaluation) |
| D-8 | **Permanent CVE regression fixtures** — XXE, signature wrapping, parser differential, SHA-1, unsigned, replay, missing InResponseTo, oversize inflation, wrong-node consumption. Named fixtures, CI-gated, never removed. | Competitors have ad-hoc tests for their own fixed CVEs. Relyra: **cross-ecosystem CVE corpus**, i.e. learns from `ruby-saml` CVE-2024-45409, `samlify` signature-wrapping, `esaml` XXE — all ported to Elixir fixtures. | v0.1 | — (covered by TS-50) | P4 (critical differentiator) |
| D-9 | **`Relyra.TestSupport` with adversarial fixture library** from v0.1 — not just happy-path helpers but `post_saml_response(conn, connection, fixture: :wrapping_attack)` baked in | `crewjam/saml`'s test-only IdP is the closest precedent but it's rudimentary. `samly`/`ex_saml` adopters hand-roll fixtures. **Relyra ships the corpus as a public test-support surface.** | v0.1 | — (covered by TS-60, TS-65) | P1 (critical differentiator), P4 |
| D-10 | **Opaque server-side RelayState by default** — `rs_...` token with expiry, bound to tenant + request_id | `ex_saml` advertises relay-state anti-replay but as an option. `ruby-saml` / `passport-saml` / `python3-saml` treat RelayState as a string. Relyra: **never a raw URL, ever.** Documented prominently. | v0.1 | — (covered by TS-11, TS-20) | P4 (critical differentiator) |
| D-11 | **Scope-first README and explicit non-goals** — v0.1 README names what v0.1 does NOT include (SLO, IdP-initiated, encrypted assertions, SCIM, hosted broker). Adopter self-qualifies in 60 seconds. | `samly` and `ex_saml` READMEs bury scope in examples. Brand book §18 + engineering-DNA §2.14 pattern is specifically anti-surprise. | v0.1 | — (covered by TS-51) | P1 (critical at evaluation), P2 |
| D-12 | **Claude/LLM-friendly maintainability** — `CLAUDE.md` + `AGENTS.md` dual entry points, `CONVENTIONS.md` with compile-time-enforced invariants, `.planning/` discipline, DNA-doc-backed patterns. Adopters who contribute upstream get a clear map. | Unique to this family of libs. Signals long-term maintenance posture to P4 and platform teams considering adoption. | v0.1 | — (covered by TS-57) | Adopter-side maintainer (long-term durability concern), P2 |

### 2.2 Differentiators that ship in v0.2 — "Enterprise config: Ecto schemas + metadata tooling + certificate rollover"

| # | Feature | Why it wins | Milestone | Complexity | Depends on |
|---|---|---|---|---|---|
| D-13 | `Relyra.Ecto.Connection`, `Relyra.Ecto.Certificate`, `Relyra.Ecto.AttributeMapping`, `Relyra.Ecto.GroupMapping`, `Relyra.Ecto.LoginAttempt`, `Relyra.Ecto.AuditEvent` schemas + generated migrations (full schema inventory from deep-research §"Ecto schemas") | `samly`/`ex_saml` are bring-your-own-storage. Spring's `RelyingPartyRegistration` is in-memory by default. Relyra ships **prod-ready multi-tenant storage** with migration discipline. | v0.2 | HIGH | TS-55 (OptionalDeps.Ecto) |
| D-14 | Metadata import — URL fetch (with TLS validation + optional signed-metadata verification, per OWASP guidance), XML upload, manual field entry. Diff preview before accepting surprising issuer/entity changes. | Competitors support metadata import unevenly. Relyra: **diff-preview + metadata-signature-verification are first-class.** | v0.2 | MED | TS-5, D-13 |
| D-15 | Metadata export — SP metadata generated from connection config + SP certs. Already an endpoint at v0.1 (TS-29); v0.2 adds admin-UI-friendly previews. | — (parity feature, not a primary differentiator beyond v0.1 scope) | v0.2 | LOW | TS-29 |
| D-16 | **Certificate rollover** — multiple active IdP certs per connection (primary + next), staged promotion, 30/14/7-day expiry warnings via telemetry + audit event, admin-UI diff view (v0.3) | `samly`/`ex_saml` support multiple certs but rollover is a manual ops ritual. Spring supports refreshable repositories. Relyra: **named stages (primary/next/retired/expired) + telemetry alerts + audit trail.** | v0.2 | HIGH | D-13, TS-36 |
| D-17 | Metadata refresh job (via `Relyra.OptionalDeps.Oban`) — scheduled re-fetch, telemetry, failure alerts | Competitors leave this to the adopter. Relyra ships it as an optional feature that "just works" if Oban is present. | v0.2 | MED | TS-55, D-14 |
| D-18 | Attribute mapping config — `saml_attribute_name` → `local_field`, `required` flag, optional `transform` (e.g. lowercase, trim) | Differentiator because Relyra's mapping is a structured Ecto record (not a config closure), which means v0.3 admin UI can edit it without redeploy. | v0.2 | MED | D-13 |
| D-19 | Group mapping config — SAML group value → local role/group. Explicit, auditable (OASIS warning §"attributes are not authorization"). | — (parity feature, but executed well it unblocks P2's "group-driven role assignment" JTBD) | v0.2 | MED | D-13, D-18 |

### 2.3 Differentiators that ship in v0.3 — "Mountable LiveView admin" (per deep-research: the single biggest adoption unlock)

| # | Feature | Why it wins | Milestone | Complexity | Depends on |
|---|---|---|---|---|---|
| D-20 | **`Relyra.LiveAdmin` mountable router** — `use Relyra.LiveAdmin.Router` in host-app Phoenix router; admin mounted at `/admin/saml` (configurable). Sigra-pattern mountable LiveView. | **No Elixir SAML competitor ships this.** The Okta-admin-dashboards problem (P3) is completely unsolved in the Elixir ecosystem. Sustainsys and Spring require the adopter to build the UI. This is THE v0.3 differentiator. | v0.3 | HIGH | D-13, TS-55 (LiveView) |
| D-21 | **Connection wizard** (brand book §14 wizard flow) — 8 steps: Choose provider → SP details → Import IdP details → Security settings → Attribute mapping → Provisioning → Test connection → Enable. Draft/Testing/Enabled states. | Unique in the Elixir ecosystem. Directly addresses the P3 "configure without a month of ticket ping-pong" JTBD. | v0.3 | HIGH | D-20, D-14, D-18, D-19 |
| D-22 | **Test-connection UI with validation trace rendering** (brand book §14.3) — live display of "Received → Decoded → Parsed → Matched → Verified → Validated → Checked → Rejected → Mapped" with per-step status + field-level expected/received values on failure | **The validation-trace UX is the signature brand moment.** D-4 at v0.1 emits the data; D-22 renders it. | v0.3 | HIGH | D-20, D-4 (the taxonomy already exists by v0.1), TS-32 |
| D-23 | Attribute mapping editor with NameID / email / first/last/display-name / groups / custom-attributes preview from a real test-login payload | Directly addresses P3's "attribute preview" JTBD from deep-research. | v0.3 | MED | D-21, D-18 |
| D-24 | Certificate rollover UI — timeline view (current expires in 18 days / replacement imported from metadata / rollover mode: both trusted / next refresh in 6 hours), per brand book §14.4 | Unique; translates D-16 into an operable ritual. | v0.3 | MED | D-20, D-16 |
| D-25 | Audit log view — admin config changes, security setting changes, unsafe-option enablements, login-attempt outcomes by connection/time | — (parity feature, but visibly integrated with Relyra's event vocabulary) | v0.3 | MED | D-13 |
| D-26 | Unsafe-options panel with explicit risk language (brand book §14.5) — time-boxed SHA-1 allowances, IdP-initiated opt-ins (from v0.4), with risk/reason/audit display | Unique; directly implements the brand's "unsafe compatibility is visible, not silent" principle. | v0.3 | MED | D-20, TS-9 |
| D-27 | **Debug bundle generator** — redacted export containing `connection_config_redacted.json`, `validation_trace.json`, `certificate_fingerprints.txt`, `metadata_summary.txt`, `error.txt`. Never raw XML unless admin explicitly downloads with a "danger" confirmation. | Unique. Deep-research §"Debug bundle" is explicit about this. Solves P5's "diagnose without PII" JTBD. | v0.3 | MED | D-20, TS-34 |
| D-28 | Per-connection status badges (brand book §20) — Draft / Testing / Enabled / Disabled / Error / Certificate expiring / Metadata stale / Unsafe option enabled | Brand-defining polish. | v0.3 | LOW | D-21 |

### 2.4 Differentiators that ship in v0.4 — "IdP-initiated SSO with opaque RelayState"

| # | Feature | Why it wins | Milestone | Complexity | Depends on |
|---|---|---|---|---|---|
| D-29 | IdP-initiated SSO **behind per-connection `allow_idp_initiated?: false` default** — never the headline feature. Requires: opaque server-side RelayState, replay cache, explicit tenant/connection binding, mandatory audit event. | Competitors ship IdP-initiated loudly. Relyra ships it as an explicit opt-in with visible risk. This is a differentiator precisely because competitors' treatments are too casual. | v0.4 | HIGH | TS-10, TS-11, D-25, D-26 |
| D-30 | Extended security corpus — IdP-initiated unsafe-RelayState fixtures, unsolicited-response fixtures, tenant-binding-bypass fixtures | — (extension of TS-50) | v0.4 | MED | D-29, TS-50 |

### 2.5 Differentiators that ship in v0.5 — "Single Logout (SLO), partial-by-provider"

| # | Feature | Why it wins | Milestone | Complexity | Depends on |
|---|---|---|---|---|---|
| D-31 | SP-initiated logout — `LogoutRequest` generation, redirect + POST bindings | Parity feature. | v0.5 | HIGH | TS-1, D-13 |
| D-32 | IdP-initiated logout — `LogoutRequest` inbound, local session teardown via SessionAdapter | Parity feature, but **explicitly documented as "partial by provider"** — Passport-SAML itself warns IdP-initiated SLO is not fully supported. Relyra's differentiator: **provider-matrix documentation** naming what works where. | v0.5 | HIGH | D-31, TS-22 |
| D-33 | Provider SLO matrix — for each of Okta, Entra, Google Workspace, Keycloak, Ping, OneLogin, ADFS: what SLO works, what doesn't, known caveats | Unique. Competitors bury this. | v0.5 | MED | D-32 |
| D-34 | SLO behind explicit opt-in (`allow_slo?: false` default) | Same discipline pattern as D-29. | v0.5 | LOW | D-31 |

### 2.6 Differentiators that ship in v1.0 — "Production conformance"

| # | Feature | Why it wins | Milestone | Complexity | Depends on |
|---|---|---|---|---|---|
| D-35 | External security review (third-party audit) + published report | Sustainability-class differentiator. | v1.0 | HIGH (external effort) | v0.1-v0.5 stable surface |
| D-36 | SAML Interop Lab / Kantara conformance run + badge | Sustainability-class differentiator. | v1.0 | HIGH | v0.1-v0.5 stable surface |
| D-37 | `mix relyra.migrate.samly` — detects Samly config, outputs equivalent Relyra config, warns on unsafe defaults, migrates routes, migrates state store. **Migration is a growth lever.** | Unique: closes the "I'm on samly, how do I move?" question without a manual support thread. | v1.0 | HIGH | Stable v0.1 API |
| D-38 | `mix relyra.migrate.ex_saml` — equivalent for ex_saml adopters | Same lever, different upstream. | v1.0 | HIGH | Stable v0.1 API |
| D-39 | Encrypted assertions (XMLEnc) — opt-in per connection, SP decryption key management | Parity feature at this point; required for some enterprise IdP policies. | v1.0 | HIGH | TS-5, TS-6 |
| D-40 | Signed AuthnRequests (outbound signing) — opt-in per connection, key management | Parity feature; required by some Entra configurations. | v1.0 | MED | TS-2, D-13 |
| D-41 | Signed metadata (outbound metadata signing, inbound metadata-signature verification by default when available) | Parity feature. | v1.0 | MED | TS-29, D-14 |
| D-42 | Multi-region reference architecture docs — request-store replication, replay-cache replication, clock sync, metadata cache, session adapter expectations | Differentiator because this is precisely where the "mostly works" trust gap shows up in production. | v1.0 | MED | — (docs) |
| D-43 | Artifact binding (if adopter demand justifies) | — (likely skipped; noted for completeness) | v1.0 or dropped | HIGH | — |

### 2.7 Additional differentiators identified (beyond the prompt's explicit list)

These emerged from the cross-ecosystem synthesis:

| # | Feature | Why it wins | Milestone | Complexity |
|---|---|---|---|---|
| D-44 | **Reflection API** — `Relyra.reflect/0` returns a map of enabled features, bounded contexts compiled, optional deps detected, public API surface. Matches sigra/lattice_stripe reflection pattern and helps adopters debug "is Ecto compiled in?" | v0.1 | LOW |
| D-45 | **"What arrived" forensics panel** — on error, surface the parsed (not raw) fields that failed validation with safe representations (hashed NameID, prefix of cert fingerprint, truncated XML element names) | v0.3 | MED |
| D-46 | **Provider drift detection** — daily cron that re-parses upstream Okta/Entra/Google metadata fixtures and flags if they've added fields Relyra doesn't recognize (scrypath drift pattern applied to providers) | v1.0 | MED |
| D-47 | **Public `.cheatmd` one-page cheatsheets** for each provider (lattice_stripe pattern) — dense, greppable, printable | v0.1 | LOW (covered by D-6 execution) |
| D-48 | **Dashboard templates** — Grafana JSON + Prometheus alerting rules for the canonical telemetry events (login success rate, error breakdown, cert expiry, replay detections, IdP-init vs SP-init volume, unsafe options enabled). Deep-research §"Dashboards" is the inventory. | v0.2 | MED |
| D-49 | **Runbook-per-error-atom** — each of the ~30 error atoms has a docs page: what it means, typical cause, how to fix in each provider, what telemetry looks like, what to paste into a support ticket | v0.2 | MED |
| D-50 | **Fixture-vs-live provider-conformance nightly job** — optional CI lane that, if credentials are present, runs a real login against Okta/Entra/Google dev tenants and diffs canonical fixtures | v1.0 | MED |

---

## 3. Anti-Features — Deliberately NOT Built (each with WHY)

**Every item below is locked.** They will appear in `REQUIREMENTS.md` "Out of Scope." Adopters who need these go elsewhere — and Relyra's docs name where to go.

### 3.1 Bootstrap-locked anti-features (from `PROJECT.md` + `RELYRA-GSD-IDEA.md`)

| # | Anti-feature | Why NOT | Alternative / Where to go |
|---|---|---|---|
| A-1 | **Identity Provider tooling beyond `Relyra.TestSupport.FakeIdP`** | Relyra's scope is SP-only. Building a production IdP would blow up the attack surface, the test corpus, and the maintainer load. `FakeIdP` is dev/CI infrastructure, not a product — it carries a `@moduledoc "FOR DEV AND CI ONLY"` warning and lacks session management, user storage, MFA, admin UI, and every other IdP feature. | For an IdP, use Keycloak, Authentik, or a hosted IdP. Relyra's Keycloak dev container is the recommended local setup. |
| A-2 | **OIDC / OAuth support** | Relyra is specifically SAML 2.0. OIDC is a different protocol with different trust primitives, different threat model, different library shape. Conflating them produces a library that does neither well. | OIDC lives in `lockspire` (Jon's sibling embedded OAuth/OIDC server). If the adopter's IdP supports both, use both libraries side-by-side. |
| A-3 | **Generic auth framework** (session management, password login, MFA, user registration, password reset) | Auth-framework concerns live in `sigra`. Relyra's `SessionAdapter` behaviour is explicitly a hand-off — Relyra proves identity, the host app (via `sigra` or custom) establishes the session. Building sessions into Relyra would duplicate `sigra` and make Relyra un-adoptable in apps that already have auth. | Use `sigra` or the host app's existing auth. `SessionAdapter` is the seam. |
| A-4 | **Hosted SSO broker / SaaS / open-core billing on login volume** | Relyra is a library. Data lives in the host app's Postgres. No Relyra-operated infra sits on the auth boundary. Open-core billing on login volume creates a perverse incentive to make the library less useful at scale. (Brand book §22: no "zero-risk / bulletproof / military-grade" language; also no covert revenue hooks.) | If the adopter wants hosted SSO, use WorkOS, SSOReady, Stytch, or BoxyHQ. Relyra's docs acknowledge these exist. |
| A-5 | **SCIM (user-lifecycle management) ownership** | SCIM is a distinct protocol with its own spec and its own adversarial surface. Bundling it conflates "identity at login" with "identity over time" — the first is Relyra's business; the second is not. | Relyra exposes `UserMapper` + JIT-provisioning hooks so a host app or a companion SCIM library (e.g. a future sibling) can handle lifecycle cleanly. |
| A-6 | **Cryptographic claims beyond strict defaults** — no "military-grade," "bulletproof," "unhackable," "zero-risk," "perfect SAML," "complete SAML security" language, anywhere in docs, marketing, or UI | Brand book §22 is explicit. These claims are untestable, legally fraught, and lose the trust of P4 in 30 seconds. Relyra's posture: say what Relyra actually does (reject SHA-1, verify against configured certs, etc.) and let the work speak. | Use the "Safe defaults / Unsafe compatibility" framing instead. |
| A-7 | **IdP-initiated SSO as the default path** (SUPPORTED at v0.4, never the default) | Deep-research §"IdP-initiated SSO" + OWASP guidance: IdP-initiated flows lack SP-side login-intent, so they're inherently weaker. Defaulting to enabled would let an adopter accidentally ship the weaker flow without understanding the trade-off. | Enabled per-connection via `allow_idp_initiated?: true` only with audit + replay + opaque RelayState. Brand UI (v0.3) displays the risk panel. |
| A-8 | **Full Single Logout (SLO) as a v0.1 feature** (SUPPORTED at v0.5, "partial by provider") | SLO across IdPs + bindings + back-channels + multiple SPs is genuinely hard. Passport-SAML explicitly warns IdP-initiated SLO is not fully supported out of the box. Over-promising SLO in v0.1 would set up every adopter for a support ticket. | Ship at v0.5 behind explicit opt-in, documented as partial-by-provider. v0.1 generates a `/logout` stub that calls SessionAdapter local sign-out only. |
| A-9 | **"Disable signature validation to make the demo pass"** — **NEVER** | This is the footgun that created the `samly`/`esaml` 2026 XXE advisory, the `ruby-saml` CVE series, and every "it works in my demo" security incident in SAML history. Relyra v0.1 has no flag that skips signature validation. Full stop. | For local dev, use `Relyra.TestSupport.FakeIdP` which issues actual signed responses. |

### 3.2 Additional anti-features identified from cross-ecosystem lessons

| # | Anti-feature | Why NOT | Alternative / Where to go |
|---|---|---|---|
| A-10 | **Not a SAML tutorial pretending to be a library** (brand book §4 "What Relyra is not") | SAML libraries that try to teach the protocol via their own API surface produce bloated APIs where every config key comes with a paragraph. Relyra's docs teach what's needed to use the library safely; the library itself is a tight public API. | Use the SAML Core spec, OWASP SAML guidance, or the OASIS documents for protocol education. Relyra's docs link to them. |
| A-11 | **Not a "SAML blob toolkit" / XML-manipulation library** | Libraries that expose raw XML building blocks (`parse_this`, `sign_that`, `canonicalize_the_other`) force adopters onto the auth boundary — they have to compose security-critical primitives themselves. That's how `ruby-saml` parser-differential bugs happen. | Relyra's public API is verbs-over-nouns (`start_login`, `consume_response`, `generate_sp_metadata`, `import_metadata`, `refresh_metadata`, `rotate_certificate`). The raw XML primitives are `@moduledoc false`. |
| A-12 | **Not an unsigned-assertion acceptance mode at any level, ever** | Covered partly by A-9, but worth naming separately: there is no `require_signed_assertion: false` config option. If the IdP isn't signing assertions or responses, Relyra rejects the integration, period. | For legacy/broken IdPs, the adopter negotiates upstream. If they truly can't, Relyra is the wrong library. |
| A-13 | **Not a multi-protocol federation toolkit** (SAML + WS-Federation + OIDC + CAS in one lib) | `python3-saml` is SAML-only for good reason; mixing protocol families is how CVEs happen. | Adopter combines Relyra + `lockspire` (OIDC) + whatever else. |
| A-14 | **Not a protocol-version-juggling library** (SAML 1.0 / 1.1 support) | SAML 1.x is deprecated and carries its own security legacy. Supporting it means supporting attackers who can downgrade. | SAML 2.0 only. If adopter has a 1.x IdP, they upgrade or don't use Relyra. |
| A-15 | **Not a "works with any XML"-permissive parser** | See `ruby-saml` CVE-2024-45409 and parser-differential follow-ons. One hardened parser path. | No alternative — this is baked into TS-5 as a hard constraint. |
| A-16 | **Not a canonicalization choice menu** (Exc-C14N vs C14N vs C14N11) | Adopter-facing canonicalization choice is a footgun. Relyra picks the safe canonicalization (Exc-C14N for the ADR's expected outcome) and refuses others unless there's a hard spec requirement. | If a non-Exc-C14N requirement appears from a major provider, Relyra's maintainers add it internally with fixtures. Adopter config surface stays closed. |
| A-17 | **Not a "validate everything or nothing" toggle** | Some libraries have a `strict_mode: false` that relaxes multiple validations simultaneously. This conflates independent trust decisions (audience check vs signature check) and invites partial-trust bugs. | Each validation is independently configurable only through audited, time-boxed, per-connection overrides (e.g., legacy algorithm policy). No global "strict mode." |
| A-18 | **Not a logger that ever writes raw XML by default** | Raw assertion XML in logs has been a source of secondary PII exposure in the ecosystem. TS-39 is the opposite discipline. | Debug bundles (D-27, v0.3) allow explicit admin-gated raw XML export only with confirmation. |
| A-19 | **Not an IdP discovery / WAYF (Where Are You From) service** | WAYF is a federation-level concern (typically Shibboleth/InCommon). Relyra is single-app, multi-tenant, with tenant selection owned by the host app's UI. | Host app drives IdP selection (usually by organization slug/email domain) and passes the `Connection` to Relyra. |
| A-20 | **Not a hot-reload / runtime-patching of the XML security path** | The XML parser configuration is compile-time-fixed. Adopter cannot swap the parser or disable security features at runtime. | If the adopter's IdP needs something the hardened parser doesn't support, Relyra ships a new version with the added support. |
| A-21 | **Not a "SAML Shield" / "AuthKit" / "Jackson"-style generic SSO umbrella** | Brand book §0 research guardrails: Relyra stays specifically SAML-SP-for-Phoenix. Expanding scope dilutes the trust signal. | Relyra links to SSOReady, BoxyHQ Jackson, WorkOS for the multi-protocol umbrella use case. |

---

## 4. Feature Dependencies (DAG)

The critical path for v0.1. Anything upstream must land first.

```
TS-5 (Hardened XML parse path — ADR)
  ├─> TS-1 (AuthnRequest gen)
  ├─> TS-6 (XMLDSig verify)
  │     ├─> TS-7 (signed-node exclusivity)
  │     ├─> TS-8 (duplicate XML ID rejection)
  │     ├─> TS-9 (algorithm policy)
  │     ├─> TS-13..TS-20 (all protocol validation)
  │     └─> TS-4 (consume_response)
  └─> TS-29 (SP metadata gen)

TS-21..TS-25 (five behaviours) — flat, independent
  └─> TS-26 (default adapters — needs TS-55 OptionalDeps.Ecto)

TS-27 (saml_routes macro)
  ├─> needs TS-21, TS-22
  ├─> TS-28 (generated routes)
  ├─> TS-29 (metadata endpoint)
  └─> TS-30 (error controller)

TS-31 (Error struct)
  ├─> TS-32 (atom taxonomy)
  ├─> TS-33 (actionable messages)
  └─> TS-34 (safe details map)

TS-35 (Telemetry catalog)
  ├─> TS-36 (event emission) — needs TS-4 in place
  ├─> TS-37 (measurements)
  └─> TS-38 (metadata)

TS-55 (OptionalDeps gateway) — foundational
  ├─> TS-26 (Ecto store default)
  ├─> TS-56 (boundary compiler)
  └─> TS-58 (--no-optional-deps CI)

TS-50 (security corpus CI)
  ├─> needs TS-5, TS-6, TS-7, TS-8, TS-9, TS-10
  └─> uses TS-65 fixtures

TS-59..TS-67 (Relyra.TestSupport) — v0.1 table stakes
  TS-63 (FakeIdP) ─> TS-60 (post_saml_response)
  TS-59 (setup_saml_connection) ─> TS-60
  TS-65 (fixture dir) <─ TS-60, TS-50
  TS-67 (ResponseBuilder) ─> TS-50, TS-60

TS-41..TS-44 (provider guides + Keycloak container)
  ├─> needs TS-29 (SP metadata)
  ├─> TS-44 Keycloak ─> TS-50 security corpus
  └─> TS-59..TS-67 test-support references

TS-46 (mix relyra.install)
  ├─> needs TS-21..TS-23 (behaviours exist to skeleton)
  └─> TS-47 (golden-diff test) ─> TS-48 (path-gate CI)

v0.2:
  D-13 (Ecto schemas) depends on TS-55, TS-24, TS-25
  D-14 (metadata import) depends on TS-5, D-13
  D-16 (cert rollover) depends on D-13, TS-36
  D-17 (metadata refresh) depends on TS-55, D-14

v0.3:
  D-20 (LiveAdmin router) depends on D-13, TS-55 (LiveView)
  D-21 (connection wizard) depends on D-20, D-14, D-18, D-19
  D-22 (validation-trace UI) depends on D-20, D-4 (already at v0.1), TS-32
  D-23..D-28 (attribute editor / cert UI / audit / unsafe panel / debug bundle / status badges) depend on D-20

v0.4:
  D-29 (IdP-initiated) depends on TS-10, TS-11, D-25, D-26
  D-30 (extended corpus) depends on D-29, TS-50

v0.5:
  D-31 (SP-init logout) depends on TS-1, D-13
  D-32 (IdP-init logout) depends on D-31, TS-22
  D-33 (provider SLO matrix) depends on D-32
  D-34 (SLO opt-in gate) depends on D-31

v1.0:
  D-35..D-43 — all depend on v0.1-v0.5 stable surface
  D-37/D-38 (migration tools) depend on stable v0.1 public API (so not safely shippable before v1.0)
```

### Critical-path observations

1. **TS-5 (hardened XML parse path ADR) is THE v0.1 bottleneck.** It blocks TS-1, TS-6, TS-29, and transitively every protocol feature. The GSD Phase 1 research ADR must resolve it before any protocol code lands. Locked per `PROJECT.md` Key Decisions.
2. **TS-55 (OptionalDeps gateway) is foundational** — must land in the first week of v0.1 because TS-26, TS-56, TS-58, and the entire v0.3/v1.0 optional-feature strategy ride on it.
3. **TS-59..TS-67 (TestSupport)** can be built in parallel with TS-4..TS-12 if TS-63 (FakeIdP) is prioritized — FakeIdP is the fixture generator for TS-65 and the live-test driver for TS-44.
4. **D-13 (Ecto schemas) is the v0.2 keystone** — six Ecto schemas unblock metadata tooling, cert rollover, attribute mapping, and the entire v0.3 admin UI.
5. **D-20 (LiveAdmin router) is the v0.3 keystone** and depends on D-13 existing. This is why the milestone split puts Ecto before LiveView.
6. **D-4 (validation-trace taxonomy) ships at v0.1 as telemetry vocabulary** so that D-22 (validation-trace UI) at v0.3 is a rendering layer, not a new concept.

---

## 5. Per-Persona Feature Priorities (v0.1 heatmap)

Which of the five personas most needs which v0.1 feature. Use this to sequence phases so that each persona hits a "Relyra does my job" moment early.

**Legend:** `●●●` critical to evaluating/adopting Relyra in v0.1 | `●●` strongly wanted | `●` nice to have | `—` not the primary audience for this feature

| Feature cluster | P1 Phoenix SaaS eng | P2 Platform/auth | P3 Customer IT admin | P4 Security eng | P5 SRE |
|---|---|---|---|---|---|
| TS-1..TS-4 Protocol core (AuthnRequest, bindings, `consume_response`) | ●●● | ●● | — | ●●● | ● |
| TS-5 Hardened XML parse | ●● | ● | — | ●●● | ● |
| TS-6..TS-12 Signature, algorithms, replay, RelayState, tenant binding | ●● | ●●● | — | ●●● | ●● |
| TS-13..TS-20 Protocol validation (Issuer/Audience/Recipient/etc.) | ●● | ●● | ● (sees in error msgs) | ●●● | ●● |
| TS-21 ConnectionResolver | ●● | ●●● | — | ● | — |
| TS-22 SessionAdapter | ●●● | ●● | — | — | — |
| TS-23 UserMapper | ●●● | ●● | — | — | — |
| TS-24 RequestStore + TS-25 ReplayStore behaviours + TS-26 defaults | ●● | ●●● | — | ●● | ●●● |
| TS-27..TS-28 Router macro + generated routes | ●●● | ●● | ● (uses metadata URL) | — | — |
| TS-29 SP metadata endpoint | ●● | ●● | ●●● | — | — |
| TS-30 Error controller | ●●● | ● | ● | — | — |
| TS-31..TS-34 Typed error contract + safe details | ●●● | ●● | ●● (error msgs are visible) | ●●● | ●●● |
| TS-35..TS-38 Telemetry catalog | ● | ●● | — | ●● | ●●● |
| TS-39..TS-40 Redacted logs + Credo check | ●● | ●● | — | ●●● | ●● |
| TS-41..TS-43 Okta/Entra/Google recipes | ●●● | ● | ●●● | — | — |
| TS-44 Keycloak dev container | ●●● | ●● | — | ●● (corpus driver) | ● |
| TS-46..TS-48 Installer | ●●● | ● | — | — | — |
| TS-49 SECURITY.md | ● | ● | ● | ●●● | ● |
| TS-50 Security corpus CI | ● | ● | — | ●●● | — |
| TS-51 Scope-first README | ●●● | ●●● | ● | ●●● | — |
| TS-52 Keep-a-Changelog | ● | ● | — | ●● | ● |
| TS-53 Release Please + parity | — | ● | — | ●● (supply-chain signal) | — |
| TS-54 Custom Credo checks | — | ● | — | ●●● | — |
| TS-55..TS-58 OptionalDeps, boundary, CONVENTIONS, no-opt-deps CI | ●● | ●● | — | ●● | ● |
| TS-59..TS-62 TestSupport assertions | ●●● | ● | — | ● | — |
| TS-63..TS-64 FakeIdP | ●●● | ●● | — | ●●● | — |
| TS-65..TS-67 Fixture dir + SAMLCase + ResponseBuilder | ●●● | ● | — | ●● | — |

### What each persona needs MOST in v0.1

- **P1 (Phoenix SaaS eng) — critical path:** Router macro (TS-27), `consume_response` (TS-4), SessionAdapter/UserMapper behaviours (TS-22/TS-23), Okta+Entra+Google recipes (TS-41..TS-43), Keycloak dev container (TS-44), `mix relyra.install` (TS-46), TestSupport (TS-59..TS-67). **P1 ships production SAML in a week or Relyra fails.**
- **P2 (Platform/auth team) — critical path:** `ConnectionResolver` (TS-21) multi-tenancy, ReplayStore/RequestStore behaviours + Ecto defaults (TS-24..TS-26), scope-first README naming what's in/out (TS-51), telemetry catalog (TS-35..TS-38). **P2 evaluates Relyra as "is this maintainable for 3 years?"**
- **P3 (Customer IT admin) — critical path:** SP metadata endpoint (TS-29), Okta/Entra/Google recipes with label crosswalk (TS-41..TS-43), actionable error messages (TS-33) that say "In Okta, set Audience URI to X." **P3 is under-served at v0.1 — their primary adoption unlock is v0.3 LiveAdmin (D-20..D-28), which is why the deep-research doc calls the admin UI "the single biggest adoption unlock."**
- **P4 (Security engineer) — critical path:** Hardened XML parse (TS-5), XMLDSig + signed-node exclusivity + dup-ID rejection + algorithm policy + replay + RelayState (TS-6..TS-11), typed errors (TS-31..TS-34), security corpus CI (TS-50), SECURITY.md (TS-49), custom Credo checks (TS-54), redacted logs (TS-39..TS-40), TestSupport adversarial fixtures (TS-60 adversarial variants, TS-65). **P4 reads CI configs and fixture directories before reading the README.**
- **P5 (SRE/DevOps) — critical path:** Telemetry catalog (TS-35..TS-38), stable error atoms (TS-32 for alerting), structured redacted logs (TS-39), Ecto ReplayStore with measurable latency (TS-26 + TS-37). **P5 is under-served at v0.1 on dashboard templates** — D-48 (Grafana JSON + Prometheus rules) is deferred to v0.2 but is the P5 unlock.

### Persona-priority caveats

- P3 is **deliberately under-served in v0.1** because v0.1 is a library for P1/P2/P4. v0.3 LiveAdmin is the explicit P3 milestone. The v0.1 README must acknowledge this ("for customer IT admins: v0.3 brings the self-service admin UI").
- P5's v0.1 story is functional but not polished; D-48 (dashboards) + D-49 (runbook-per-error-atom) at v0.2 complete the P5 unlock.
- P4 is the **highest-scrutiny persona** at v0.1 — every security-critical feature (TS-5..TS-12, TS-50, TS-54) must be demonstrable to P4 at v0.1 launch.

---

## 6. Feature Prioritization Matrix (compressed view for roadmap sizing)

| Feature | User Value | Implementation Cost | Priority | Milestone |
|---|---|---|---|---|
| Protocol core (TS-1..TS-4) | HIGH | HIGH | P1 | v0.1 |
| Hardened XML + signature (TS-5..TS-9) | HIGH | HIGH | P1 | v0.1 |
| Replay + RelayState + tenant binding (TS-10..TS-12) | HIGH | MED | P1 | v0.1 |
| Protocol validation (TS-13..TS-20) | HIGH | MED | P1 | v0.1 |
| Five behaviours + default adapters (TS-21..TS-26) | HIGH | MED | P1 | v0.1 |
| Router macro + routes + metadata (TS-27..TS-30) | HIGH | MED | P1 | v0.1 |
| Typed errors (TS-31..TS-34) | HIGH | LOW | P1 | v0.1 |
| Telemetry catalog (TS-35..TS-38) | MED | LOW | P1 | v0.1 |
| Redacted logs + Credo (TS-39..TS-40) | MED | LOW | P1 | v0.1 |
| Provider guides + Keycloak (TS-41..TS-44) | HIGH | MED | P1 | v0.1 |
| Installer (TS-46..TS-48) | HIGH | MED | P1 | v0.1 |
| SECURITY.md + security corpus (TS-49..TS-50) | HIGH | HIGH | P1 | v0.1 |
| Scope-first README + OSS hygiene (TS-51..TS-58) | MED | LOW | P1 | v0.1 |
| TestSupport (TS-59..TS-67) | HIGH | HIGH | P1 | v0.1 |
| Differentiator polish v0.1 (D-1..D-12) | HIGH | MED | P1 | v0.1 (mostly covered by TS) |
| Reflection API (D-44) | MED | LOW | P2 | v0.1 |
| Provider cheatsheets (D-47) | MED | LOW | P1 | v0.1 (execution of D-6) |
| Ecto schemas (D-13) | HIGH | HIGH | P1 | v0.2 |
| Metadata import/export (D-14..D-15) | HIGH | MED | P1 | v0.2 |
| Cert rollover + metadata refresh (D-16..D-17) | HIGH | HIGH | P1 | v0.2 |
| Attribute/group mapping (D-18..D-19) | HIGH | MED | P1 | v0.2 |
| Dashboard templates (D-48) | MED | MED | P2 | v0.2 |
| Runbook per error atom (D-49) | MED | MED | P2 | v0.2 |
| LiveAdmin router (D-20) | HIGH | HIGH | P1 | v0.3 |
| Connection wizard (D-21) | HIGH | HIGH | P1 | v0.3 |
| Validation-trace UI (D-22) | HIGH | HIGH | P1 | v0.3 |
| Attribute editor (D-23) | HIGH | MED | P1 | v0.3 |
| Cert rollover UI (D-24) | HIGH | MED | P1 | v0.3 |
| Audit log view (D-25) | MED | MED | P2 | v0.3 |
| Unsafe options panel (D-26) | HIGH | MED | P1 | v0.3 |
| Debug bundle (D-27) | HIGH | MED | P1 | v0.3 |
| Status badges (D-28) | MED | LOW | P1 | v0.3 |
| Forensics panel (D-45) | MED | MED | P2 | v0.3 |
| IdP-initiated SSO (D-29) | MED (opt-in) | HIGH | P2 | v0.4 |
| Extended corpus (D-30) | HIGH | MED | P1 | v0.4 |
| SLO (D-31..D-34) | MED (opt-in) | HIGH | P2 | v0.5 |
| Security review + conformance (D-35..D-36) | HIGH | HIGH | P1 | v1.0 |
| Migration tools (D-37..D-38) | HIGH | HIGH | P1 | v1.0 |
| Encrypted assertions + signed AuthnReq + signed metadata (D-39..D-41) | HIGH (for some adopters) | HIGH | P1 | v1.0 |
| Multi-region docs (D-42) | MED | MED | P2 | v1.0 |
| Provider drift (D-46) | MED | MED | P2 | v1.0 |
| Fixture-vs-live nightly (D-50) | MED | MED | P3 | v1.0 |

**Priority key:** P1 = must have for that milestone | P2 = should have, add when possible | P3 = nice to have, future consideration

---

## 7. Competitor Feature Analysis

Compressed matrix showing how Relyra v0.1 compares to the six closest competitors on the table-stakes + differentiator surface. **Y** = ships it; **y** = ships partially or behind config; **—** = does not ship; **?** = unclear / undocumented.

| Feature | Relyra v0.1 | `samly` 1.4.0 | `ex_saml` 1.0.2 | `ruby-saml`+`omniauth-saml` | `passport-saml` | `python3-saml` | `crewjam/saml` |
|---|---|---|---|---|---|---|---|
| SP-initiated SSO | Y | Y | Y | Y | Y | Y | Y |
| IdP-initiated SSO (v0.4 opt-in for Relyra) | — (v0.4) | y | Y | Y | Y | Y | Y |
| Hardened XML pre-parse | **Y** | — (esaml XXE CVE 2026) | Y | y (parser-differential issues in 2025) | y | Y | Y |
| Signed-node exclusivity (exact node consumed) | **Y** | ? | ? | y (CVE-2024-45409 fixed) | y | y | y |
| Duplicate XML ID rejection | **Y** | ? | ? | y | y | Y | ? |
| SHA-1 rejected by default | **Y** | — | Y | y | y | Y | ? |
| Replay cache required in prod | **Y** | y | Y | y | y | y | y |
| Opaque server-side RelayState default | **Y** | — | y | — | — | — | — |
| `ConnectionResolver`-style multi-tenant first | **Y** (primary abstraction) | y (config-gymnastic) | Y (path/subdomain) | y (MultiStrategy) | y (MultiSamlStrategy) | — | — |
| Phoenix router macro | **Y** | y | Y | — | — | — | — |
| Typed error taxonomy (stable atoms) | **Y** (~30) | — (tuples) | — (tuples) | y (exception classes) | — (callback arg) | — (strings) | — |
| Telemetry catalog | **Y** | — | — | n/a (non-BEAM) | n/a | n/a | n/a |
| Validation-trace vocabulary | **Y** (v0.1 telemetry, v0.3 UI) | — | — | — | — | — | — |
| Public security corpus in CI | **Y** | — | ? | y (post-CVE) | y | Y | y |
| Custom lint checks for security invariants | **Y** (Credo) | — | — | — | — | — | — |
| `SECURITY.md` + private advisory workflow | **Y** | y | y | Y | Y | Y | Y |
| LiveView admin UI | — (v0.3) | — | — | n/a | n/a | n/a | n/a |
| Certificate rollover (multiple active certs) | — (v0.2) | y | y | y | y | y | y |
| Metadata import/export | — (v0.2) | y | y | y | y | Y | y |
| Migration tools from samly/ex_saml | — (v1.0) | n/a | y (from Samly) | n/a | n/a | n/a | n/a |
| External security review published | — (v1.0) | — | — | ? | ? | ? | ? |
| Kantara/Interop conformance | — (v1.0) | — | — | — | — | — | — |
| `mix install` or equivalent generator | **Y** | y | y | y | y | — | n/a |
| Adversarial test-support fixtures as public surface | **Y** | — | — | — | — | — | y (test-only IdP) |
| Opaque-RelayState + replay + audit on IdP-init (v0.4) | — (v0.4) | — | y (relay-state anti-replay) | — | — | — | — |
| Signed AuthnRequests (outbound sign) | — (v1.0) | y | y | y | y | y | y |
| Encrypted assertions | — (v1.0) | y | y | y | y | y | y |

### Competitive summary

- **Against `samly`:** Relyra v0.1 wins on strict-by-default, typed errors, validation trace, security corpus, custom Credo checks, TestSupport adversarial fixtures, and maintenance posture. `samly` last released January 2024 and carries the 2026 `esaml` XXE liability. **Relyra is unambiguously the safer choice for new adopters at v0.1 publish.**
- **Against `ex_saml`:** Closer competition. `ex_saml` already ships relay-state anti-replay, SHA-1 rejection, entity disabling, and path/subdomain multi-IdP. Relyra wins on: (1) validation-trace taxonomy + telemetry catalog, (2) typed error atoms as a SemVer contract, (3) custom Credo compile-time security invariants, (4) `Relyra.TestSupport` adversarial-fixture public surface, (5) LiveView admin at v0.3, (6) cross-ecosystem CVE corpus, (7) brand-book-driven error microcopy, (8) scope-first README, (9) explicit non-goals (IdP-init default off, SLO deferred, no SCIM), (10) provider-preset label crosswalk, (11) engineering-DNA backing from 10 sibling libs. **The opening is "the trusted default for teams that need enterprise SSO without becoming SAML experts."**
- **Against cross-ecosystem (Ruby/Node/Python/Go/Spring/Sustainsys):** Relyra is Phoenix-specific and can't compete on raw language-ecosystem reach. Competes on Phoenix-native polish (D-3), multi-tenant-first design (D-1), validation trace (D-4), and the v0.3 admin UI (D-20..D-28) which no other ecosystem has as a one-mount integration.

---

## 8. MVP Definition (reconciled with bootstrap-locked scope)

### v0.1 — "SP-initiated SSO, verified end-to-end" (MUST ship)

All items in §1 Table Stakes (TS-1..TS-67) plus v0.1-tagged differentiators (D-1..D-12, D-44, D-47).

### v0.2 — "Enterprise config" (add after v0.1 validates with first adopters)

- D-13 Ecto schemas + migrations (**unblocks v0.3**)
- D-14..D-15 Metadata import/export
- D-16..D-17 Certificate rollover + refresh
- D-18..D-19 Attribute/group mapping
- D-48 Dashboard templates
- D-49 Runbook per error atom
- TS-45 SimpleSAMLphp container docs

### v0.3 — "LiveView admin" (biggest single adoption unlock per deep-research)

- D-20 LiveAdmin router
- D-21 Connection wizard
- D-22 Validation-trace UI
- D-23 Attribute editor
- D-24 Cert rollover UI
- D-25 Audit log view
- D-26 Unsafe options panel
- D-27 Debug bundle
- D-28 Status badges
- D-45 Forensics panel

### v0.4 — "IdP-initiated SSO (opt-in)"

- D-29 IdP-initiated SSO behind `allow_idp_initiated?: false` default
- D-30 Extended security corpus

### v0.5 — "SLO (partial-by-provider)"

- D-31 SP-initiated logout
- D-32 IdP-initiated logout
- D-33 Provider SLO matrix
- D-34 Opt-in gate

### v1.0 — "Production conformance"

- D-35 External security review
- D-36 Kantara/Interop conformance
- D-37..D-38 Migration tools (samly + ex_saml)
- D-39..D-41 Encrypted assertions + signed AuthnRequests + signed metadata
- D-42 Multi-region docs
- D-46 Provider drift
- D-50 Fixture-vs-live nightly

### Out-of-scope forever

All A-1..A-21 anti-features. These are `REQUIREMENTS.md` "Out of Scope" entries with WHY.

---

## 9. Sources

- `/Users/jon/projects/relyra/.planning/PROJECT.md` — bootstrap-locked v0.1 scope, anti-features, product principles, bounded contexts, key decisions
- `/Users/jon/projects/relyra/prompts/RELYRA-GSD-IDEA.md` — vision, milestone intent, open-decision list
- `/Users/jon/projects/relyra/prompts/elixir-saml-lib-deep-research.md` — April 2026 ecosystem map, personas/JTBD, domain language, security invariants, error taxonomy, admin-UI wizard, telemetry catalog, MVP/v1/v2 scope, footguns, provider presets, testing strategy, cross-ecosystem lessons (Ruby CVE-2024-45409, Node fork pressure, Python strict mode, Spring `RelyingPartyRegistration`, Go `crewjam/saml` modular split)
- `/Users/jon/projects/relyra/prompts/relyra-brand-book.md` — validation-trace label vocabulary (§14.3), error voice (§15), unsafe-option UI (§14.5), provider-label crosswalks (§16 callouts), API naming principles (§21), security-claim do/don't (§22), scope language (§4 "What Relyra is not"), UI status badges (§20), documentation structure (§16)
- `/Users/jon/projects/relyra/prompts/relyra-engineering-dna-from-prior-libs.md` — §2 convergent DNA (port verbatim), §4 SAML-primitive translation, §5 v0.1 starter skeleton, §6 SAML-specific gotchas, §7 seed milestone plan, §9 ranked TL;DR
- NVD entries: `esaml` XXE 2026, `ruby-saml` CVE-2024-45409 + 2025 parser-differential, `samlify` < 2.10.0 signature wrapping (each becomes a permanent regression fixture in TS-50)
- OASIS SAML Core + Profiles specs (referenced through deep-research doc) — protocol terminology authority
- OWASP SAML Security Cheat Sheet (referenced through deep-research doc) — RelayState allowlisting, IdP-initiated guidance, schema validation, replay defense, protocol processing rules
- Competitor documentation:
  - `samly` Hex page + GitHub (last release Jan 29, 2024)
  - `ex_saml` Hex page + GitHub (v1.0.2, April 16, 2026)
  - `omniauth-saml` + `ruby-saml` READMEs and CVE histories
  - `@node-saml/passport-saml` README (multi-provider strategy, SLO caveats)
  - `python3-saml` README (strict mode, security history)
  - `crewjam/saml` README (core + middleware + test-IdP split)
  - Spring Security SAML (`RelyingPartyRegistration` pattern)
  - Sustainsys (ASP.NET Core authentication-options mapping)

---

*Feature research for: SAML 2.0 Service Provider library for Elixir/Phoenix*
*Researched: 2026-04-24*
*Confidence: HIGH — bootstrap scope is locked, cross-ecosystem synthesis is extensive, only the XML security path ADR (TS-5 implementation choice) carries LOW confidence and is explicitly carved out for GSD Phase 1 research*
