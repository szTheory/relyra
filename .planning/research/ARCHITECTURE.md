# Architecture Research — Relyra

**Domain:** Security-first SAML 2.0 Service Provider library for Elixir/Phoenix
**Researched:** 2026-04-24
**Confidence:** HIGH (module tree, boundary DAG, behaviour contracts, optional-deps, validation pipeline, telemetry catalog, build order are all cross-verified against sibling-repo DNA + deep research + OWASP/OASIS invariants). MEDIUM on §10 deployment-surface-analysis for XMLDSig options — final numbers land in the Phase 1 ADR.

> **Intended readers:** `/gsd-roadmapper` (phase structure); phase-plan authors for v0.1 (module references); `boundary` config author; `NoSignatureSkipInPublicAPI` Credo author; `Relyra.Telemetry` catalog author; XML-security-ADR author.
>
> This document is prescriptive. Every section has been written so that a downstream consumer can paste it into a file, `@behaviour`, or `@spec` without further interpretation. Where tradeoffs exist, the recommendation is loud; where the ADR is the decision, §10 lays out deployment surface without pre-deciding.

---

## 0. How this document maps to the rest of v0.1 planning

| This section | Consumed by | What it unlocks |
|---|---|---|
| §1 Module tree | `PATTERNS.md` references per phase; `ex_doc` `groups_for_modules:` in `mix.exs` | Namespace is locked; every phase plan can cite `Relyra.X.Y` without re-inventing |
| §2 `boundary` DAG | `lib/relyra/boundary.ex` + per-module `boundary/3` calls; CI `mix compile --warnings-as-errors` under `:boundary` | Protocol-core leak detection at compile time |
| §3 Data flow (SP-initiated login) | Phase 2 (Protocol Core) + Phase 4 (Phoenix Runtime) + Phase 5 (Telemetry) acceptance criteria | End-to-end story for docs (§"Test connection" brand-book §14.3) and for validation-trace UI |
| §4 Build order DAG | ROADMAP.md phase sequence | Phase ordering + dependency rationale |
| §5 Behaviour contracts | Phase 3 acceptance criteria; generated behaviour skeletons in `mix relyra.install` | Extension-seam API freeze for v0.1 |
| §6 Optional-deps gateways | Phase 3 + Phase 8 (`TestSupport`) code | Ecto/LiveView/Oban/OTel isolation from protocol core |
| §7 Validation ordering pipeline | `NoSignatureSkipInPublicAPI` Credo check (Phase 7); `Relyra.Pipeline` internal module | Mechanical enforcement of the ordering rule |
| §8 Telemetry span catalog | `Relyra.Telemetry` module (Phase 5) + observability docs | Single source of truth for event names/measurements/metadata |
| §9 `saml_routes/2` expansion | Phase 4 router-macro implementation + docs | Generated-route contract |
| §10 XMLDSig deployment surface | Phase 1 ADR input | ADR cannot be written without this table |

---

## 1. Module tree (v0.1 namespace)

**Legend:**
- **public** = full `@moduledoc` (part of the public API surface, counted for SemVer).
- **priv** = `@moduledoc false` (internal; API may change without a minor bump).
- Modules marked **(v0.2+)** / **(v0.3+)** are listed so the v0.1 namespace never has to be retroactively rearranged — they are reserved, not implemented.

### 1.1 Root + value types

| Module | State | Purpose |
|---|---|---|
| `Relyra` | **public** | Public root. Reflection (`version/0`), orchestration delegates (`start_login/3`, `consume_response/3`, `build_sp_metadata/2`), error-type re-exports. **Only module end-users call directly.** |
| `Relyra.Error` | **public** | `defexception` with `:type` (atom from ~30-atom taxonomy), `:message` (String.t()), `:details` (map). Pattern-matchable; stable SemVer contract. |
| `Relyra.Connection` | **public** | Value struct: `%Relyra.Connection{id, organization_id, sp_entity_id, sp_acs_url, idp_entity_id, idp_sso_url, idp_certificates, name_id_format, algorithm_policy, allow_idp_initiated?, require_signed_assertions?, require_signed_response?, clock_skew_seconds, provider_preset, display_name}`. No behaviour, no persistence — **the resolved trust relationship**, produced by `ConnectionResolver`. |
| `Relyra.Principal` | **public** | Value struct: `%Relyra.Principal{name_id, name_id_format, session_index, attributes, authn_instant, authn_context_class_ref, connection_id}`. Consumed by `UserMapper` + `SessionAdapter`. `fetch_attribute/2` helper. |
| `Relyra.LoginResult` | **public** | Value struct: `%Relyra.LoginResult{principal, connection, mapped_user, relay_state, validation_trace}`. Return value of `consume_response/3`. |

### 1.2 Protocol Core (pure SAML — no Phoenix/Ecto/LiveView dependencies allowed)

| Module | State | Purpose |
|---|---|---|
| `Relyra.Protocol` | **priv** | Internal umbrella / doc-only module. |
| `Relyra.Protocol.AuthnRequest` | **priv** | Build `<samlp:AuthnRequest>` XML + ID generation (`secure_random/1` 128-bit). |
| `Relyra.Protocol.Response` | **priv** | Parse + validate top-level `<samlp:Response>`. |
| `Relyra.Protocol.Assertion` | **priv** | Parse + validate `<saml:Assertion>` (Subject, Conditions, AuthnStatement, AttributeStatement). |
| `Relyra.Protocol.Metadata` | **priv** (v0.1 limited — generate only; full parse lands with v0.2 metadata import) | Generate SP metadata XML. |
| `Relyra.Protocol.Logout` | **priv** (v0.5 stub in v0.1) | Reserved namespace for SLO — module exists but `@moduledoc "SLO support lands in v0.5."` in v0.1. |
| `Relyra.Protocol.Binding.Redirect` | **priv** | HTTP-Redirect binding: `deflate + base64 + urlencode + Signature param`. Encode + decode. |
| `Relyra.Protocol.Binding.POST` | **priv** | HTTP-POST binding: `base64 + form-encoded`. Encode + decode. |
| `Relyra.Protocol.Conditions` | **priv** | Time window + Audience + OneTimeUse validation (pure functions). |
| `Relyra.Protocol.SubjectConfirmation` | **priv** | Bearer method + Recipient + InResponseTo + NotOnOrAfter validation. |

### 1.3 Security (the isolation seam for the XML ADR)

| Module | State | Purpose |
|---|---|---|
| `Relyra.Security` | **priv** | Umbrella. |
| `Relyra.Security.XML` | **public-behaviour + priv default** | **The XML adapter seam.** Defines `@behaviour Relyra.Security.XML` with `parse_safely/2`, `canonicalize/2`, `select_signed_node/2`. Ships two adapters in v0.1 depending on ADR outcome — see §10. **This is the one module whose behaviour contract MUST freeze in Phase 1 so Phase 2 can proceed regardless of implementation choice.** |
| `Relyra.Security.XML.Sweet` | **priv** | Pure-BEAM adapter via `sweet_xml`/`xmerl` (DTD disabled, entity expansion disabled, size-limited). |
| `Relyra.Security.XML.Xmlsec` | **priv** (conditional on ADR) | NIF adapter over `xmlsec1`. Compiled only if `xmerl_xmlsec` dep is present (optional-deps pattern). |
| `Relyra.Security.Signature` | **priv** | XMLDSig verification. Accepts verified-node + configured IdP certs + `AlgorithmPolicy`. Returns `{:ok, verified_node_ref} \| {:error, Relyra.Error.t()}`. **Never reads `KeyInfo` from the document.** |
| `Relyra.Security.AlgorithmPolicy` | **public** | `%Relyra.Security.AlgorithmPolicy{allowed_signature_algorithms, allowed_digest_algorithms, reject_sha1?, legacy_allow_sha1_until, legacy_reason}`. Value struct + `allows?/2` predicate. Public because operators configure it. |
| `Relyra.Security.Encryption` | **priv** (v1.0 — stubbed in v0.1) | Reserved for EncryptedAssertion decryption; v0.1 returns `{:error, %Relyra.Error{type: :encryption_not_supported}}`. |
| `Relyra.Security.RelayState` | **priv** | Opaque-handle generator + verifier (`rs_...` → `{return_to, tenant_id, request_id, expires_at}`). Signed/sealed token via `:crypto` HMAC. |

### 1.4 Public behaviours + default adapters

| Module | State | Purpose |
|---|---|---|
| `Relyra.ConnectionResolver` | **public behaviour** | `@callback resolve(Plug.Conn.t()) :: {:ok, Connection.t()} \| {:error, Error.t()}`. Optional `reload/1`. |
| `Relyra.ConnectionResolver.Static` | **priv default** | Reads from `Application.get_env(:relyra, :connections)`. Keyed by connection id from path param. |
| `Relyra.RequestStore` | **public behaviour** | `put/3`, `pop/1`. |
| `Relyra.RequestStore.ETS` | **priv default** | Dev / single-node. Loud warning if `Mix.env() == :prod`. |
| `Relyra.RequestStore.Ecto` | **priv default (v0.2-capable — schema lives in `Relyra.Ecto.RequestStoreEntry` from v0.2 onward; v0.1 ships the module with an `EEX` migration and requires Ecto optional-dep)** | Prod default. |
| `Relyra.ReplayStore` | **public behaviour** | `put_new/2`. |
| `Relyra.ReplayStore.ETS` | **priv default** | Dev. Loud prod warning. |
| `Relyra.ReplayStore.Ecto` | **priv default** | Prod default. Partial unique index on `(response_id, connection_id)` + TTL column. |
| `Relyra.SessionAdapter` | **public behaviour** | `sign_in/3`. |
| `Relyra.SessionAdapter.Passthrough` | **priv default** | Puts principal into `conn.assigns[:relyra_principal]` and returns `{:ok, conn}`. Dev/test only; docstring names host-app responsibility loudly. |
| `Relyra.UserMapper` | **public behaviour** | `map/2`. |
| `Relyra.UserMapper.DefaultAttribute` | **priv default** | Maps NameID + `email` + `given_name` + `family_name` + `groups` attribute into a bare map; returns `{:ok, %{...}}`. Not tied to any schema. |

### 1.5 Phoenix / Plug Runtime

| Module | State | Purpose |
|---|---|---|
| `Relyra.Phoenix` | **priv** | Umbrella. |
| `Relyra.Phoenix.Router` | **public** | Exports `saml_routes/2` macro. **The only public Phoenix surface.** |
| `Relyra.Phoenix.Controllers.LoginController` | **priv** | `GET /login` + `POST /login` (start_login). |
| `Relyra.Phoenix.Controllers.ACSController` | **priv** | `POST /acs` (consume_response). |
| `Relyra.Phoenix.Controllers.MetadataController` | **priv** | `GET /metadata` (SP metadata XML). |
| `Relyra.Phoenix.Controllers.LogoutController` | **priv** (v0.5 stub — routes exist but 501) | Reserved. |
| `Relyra.Phoenix.Pipeline` | **priv** | Internal `Plug` that dispatches into `Relyra.start_login/3` / `Relyra.consume_response/3` and handles error→`on_error` fallback. |

### 1.6 Ecto (optional, v0.2-capable — v0.1 provides the bare RequestStore.Ecto + ReplayStore.Ecto schemas)

| Module | State | Purpose |
|---|---|---|
| `Relyra.Ecto` | **priv** | Umbrella. Guarded by `Relyra.OptionalDeps.Ecto`. |
| `Relyra.Ecto.RequestStoreEntry` | **priv** | Schema for request-store rows. v0.1 minimal. |
| `Relyra.Ecto.ReplayStoreEntry` | **priv** | Schema for replay-store rows. v0.1 minimal. |
| `Relyra.Ecto.Connection` | **(v0.2)** reserved | Full connection schema. |
| `Relyra.Ecto.Certificate` | **(v0.2)** reserved | Certificate inventory. |
| `Relyra.Ecto.Migrations` | **priv** | Generator-emitted migrations (v0.1 ships the two store tables only). |

### 1.7 LiveAdmin (v0.3 — reserved namespace in v0.1)

| Module | State | Purpose |
|---|---|---|
| `Relyra.LiveAdmin` | **(v0.3+)** | Reserved. `@moduledoc "The mountable LiveView admin ships in v0.3."` |
| `Relyra.LiveAdmin.Router` | **(v0.3+)** | Reserved. |

### 1.8 TestSupport

| Module | State | Purpose |
|---|---|---|
| `Relyra.TestSupport` | **public** | Public helpers: `setup_saml_connection/1`, `start_saml_login/2`, `post_saml_response/3`, `assert_saml_signed_in/2`. |
| `Relyra.TestSupport.FakeIdP` | **public** (testing surface is a supported contract) | In-process fake IdP. `{Relyra.TestSupport.FakeIdP, port: 4040, signing_key: :dev}`. v0.1 ships with one signing keypair + success + failure fixtures. |
| `Relyra.TestSupport.Fixtures` | **priv** | Loads + signs canned response XML. |

### 1.9 Optional-deps gateway

| Module | State | Purpose |
|---|---|---|
| `Relyra.OptionalDeps.Ecto` | **priv** | `available?/0` + thin shims over `Ecto`, `Ecto.Repo`, `Ecto.Changeset`. |
| `Relyra.OptionalDeps.LiveView` | **priv** | `available?/0` + shims. Gates `Relyra.LiveAdmin` at compile time. |
| `Relyra.OptionalDeps.Oban` | **priv** | `available?/0` + shims. v0.2+ metadata-refresh jobs. |
| `Relyra.OptionalDeps.OpenTelemetry` | **priv** | `available?/0` + shims. `:telemetry` is hard-required; OTel is opt-in. |

### 1.10 Cross-cutting

| Module | State | Purpose |
|---|---|---|
| `Relyra.Telemetry` | **public** | **Single source of truth for event catalog.** `events/0` returns the full list of `[:relyra, :saml, ...]` event names. `@moduledoc` enumerates measurements + metadata per event. Also exports `span/3` helper wrapping `:telemetry.span/3` with relyra metadata conventions. |
| `Relyra.Audit` | **priv** | Audit event emitter. Writes to telemetry + structured-redacted logger. When `Relyra.OptionalDeps.Ecto.available?()` and an `audit_log` repo is configured, also inserts a row. |
| `Relyra.Log` | **priv** | Redacted-logging helpers. Forbids raw assertion/response XML via custom Credo check `NoRawAssertionInLog`. |
| `Relyra.Version` | **priv** | Reads `@version` (mix.exs single source of truth) — used by metadata generation + telemetry metadata. |
| `Relyra.Install` | **priv** | `mix relyra.install` task implementation. v0.1 minimal: config stub + behaviour skeletons + dev fake-IdP cert. |
| `Relyra.Install.Feature` | **priv** | Walker behaviour for install-feature modules (sigra pattern). |
| `Relyra.Install.Runner` | **priv** | Runs feature walkers; outputs golden-diff-stable stdout. |
| `Relyra.Install.Features.Config` | **priv** | Generates `config/relyra.exs`. |
| `Relyra.Install.Features.Behaviours` | **priv** | Generates skeleton `lib/my_app/sso/{connection_resolver,session_adapter,user_mapper}.ex`. |
| `Relyra.Install.Features.DevCert` | **priv** | Generates dev fake-IdP certificate into `priv/relyra/dev/`. |

### 1.11 ExDoc `groups_for_modules:` (locks the public surface visually)

```elixir
groups_for_modules: [
  Core: [Relyra, Relyra.Error, Relyra.Connection, Relyra.Principal, Relyra.LoginResult],
  Behaviours: [
    Relyra.ConnectionResolver, Relyra.RequestStore, Relyra.ReplayStore,
    Relyra.SessionAdapter, Relyra.UserMapper
  ],
  Security: [Relyra.Security.AlgorithmPolicy, Relyra.Security.XML],
  Phoenix: [Relyra.Phoenix.Router],
  Testing: [Relyra.TestSupport, Relyra.TestSupport.FakeIdP],
  Observability: [Relyra.Telemetry]
]
```

Everything else is `@moduledoc false` and does not appear in docs.

---

## 2. `boundary` compiler configuration (the DAG)

**Principle:** Protocol Core is a **dependency leaf**. Phoenix Runtime depends on Protocol Core via the public orchestration module only. Ecto is a leaf consumed via behaviours. LiveAdmin depends on Phoenix + Ecto. Telemetry/Audit are cross-cutting (depended-on, not depending).

### 2.1 The allowed-dep DAG (textual)

```
                    ┌──────────────────────────┐
                    │   Relyra (root public)   │
                    └─────────┬────────────────┘
                              │ delegates only
         ┌────────────────────┼────────────────────────┐
         ▼                    ▼                        ▼
┌────────────────┐   ┌────────────────────┐   ┌──────────────────┐
│  Behaviours    │   │  Protocol Core +   │   │  Phoenix Runtime │
│  (5 modules)   │◀──│  Security.XML seam │   │  (router macro,  │
│                │   │  (no Phoenix, no   │   │   controllers)   │
└──────┬─────────┘   │   Ecto)            │   └─────┬────────────┘
       │             └──────┬─────────────┘         │
       │                    │ depends on            │ depends on
       │                    ▼                       ▼
       │            ┌────────────────┐      ┌──────────────────┐
       │            │ Security       │      │  Behaviours      │
       │            │ (XML, Sig,     │      │  (resolved at    │
       │            │  AlgPolicy,    │      │   runtime via    │
       │            │  RelayState)   │      │   :application)  │
       │            └────────────────┘      └──────────────────┘
       │
       └───── implemented by ────▶  ┌────────────────────────┐
                                    │  Default adapters:     │
                                    │  - ConnectionResolver  │
                                    │    .Static             │
                                    │  - RequestStore.ETS    │
                                    │  - RequestStore.Ecto   │
                                    │    (depends on Ecto    │
                                    │     via OptionalDeps)  │
                                    │  - ReplayStore.*       │
                                    │  - SessionAdapter.     │
                                    │    Passthrough         │
                                    │  - UserMapper.         │
                                    │    DefaultAttribute    │
                                    └────────────────────────┘

Cross-cutting (NO module depends on them "upward"; they sit alongside):
  Relyra.Telemetry   ──emitted by──▶  Protocol Core + Phoenix Runtime + Behaviours
  Relyra.Audit       ──emitted by──▶  Phoenix Runtime + Behaviours
  Relyra.Log         ──emitted by──▶  everywhere
  Relyra.OptionalDeps.*  ──called by──▶ LiveAdmin, Ecto adapters, Oban/OTel integrations
```

### 2.2 The `boundary/3` calls (paste into modules)

```elixir
# lib/relyra.ex
defmodule Relyra do
  use Boundary,
    deps: [
      Relyra.Error, Relyra.Connection, Relyra.Principal, Relyra.LoginResult,
      Relyra.Protocol, Relyra.Security, Relyra.Telemetry, Relyra.Audit, Relyra.Log
    ],
    exports: [Error, Connection, Principal, LoginResult]
end

# lib/relyra/protocol.ex  (umbrella + explicit: the whole Protocol tree lives here)
defmodule Relyra.Protocol do
  use Boundary,
    deps: [Relyra.Error, Relyra.Security, Relyra.Log],
    # Protocol core NEVER depends on these:
    check: [in: true, out: true],
    type: :strict
end

# lib/relyra/security.ex
defmodule Relyra.Security do
  use Boundary,
    deps: [Relyra.Error, Relyra.Log],
    exports: [XML, Signature, AlgorithmPolicy, RelayState],
    type: :strict
end

# lib/relyra/behaviours.ex  (umbrella module for the 5 behaviours)
defmodule Relyra.Behaviours do
  use Boundary,
    deps: [Relyra.Error, Relyra.Connection, Relyra.Principal],
    exports: [
      Relyra.ConnectionResolver, Relyra.RequestStore, Relyra.ReplayStore,
      Relyra.SessionAdapter, Relyra.UserMapper
    ]
end

# lib/relyra/phoenix.ex
defmodule Relyra.Phoenix do
  use Boundary,
    deps: [
      Relyra, Relyra.Error, Relyra.Connection, Relyra.LoginResult,
      Relyra.Behaviours, Relyra.Protocol, Relyra.Security,
      Relyra.Telemetry, Relyra.Audit, Relyra.Log,
      Plug, Phoenix.Controller, Phoenix.Router
    ],
    exports: [Router],
    type: :strict
end

# lib/relyra/ecto.ex
defmodule Relyra.Ecto do
  use Boundary,
    deps: [
      Relyra.OptionalDeps.Ecto, Relyra.Error,
      Relyra.Behaviours
    ],
    # Ecto is a leaf — it implements the store behaviours; nothing depends on it
    # directly outside of Behaviours-based dispatch at runtime.
    exports: [RequestStoreEntry, ReplayStoreEntry]
end

# lib/relyra/live_admin.ex   (v0.3+ stub in v0.1)
defmodule Relyra.LiveAdmin do
  use Boundary,
    deps: [
      Relyra.OptionalDeps.LiveView, Relyra.OptionalDeps.Ecto,
      Relyra.Phoenix, Relyra.Ecto, Relyra.Behaviours,
      Relyra.Telemetry, Relyra.Audit
    ]
end

# lib/relyra/telemetry.ex
defmodule Relyra.Telemetry do
  use Boundary, deps: [:telemetry]
end

# lib/relyra/audit.ex
defmodule Relyra.Audit do
  use Boundary, deps: [Relyra.Telemetry, Relyra.Log, Relyra.OptionalDeps.Ecto]
end

# lib/relyra/log.ex
defmodule Relyra.Log do
  use Boundary, deps: [:logger]
end

# lib/relyra/optional_deps.ex  (umbrella for the 4 gateways)
defmodule Relyra.OptionalDeps do
  use Boundary, exports: [Ecto, LiveView, Oban, OpenTelemetry]
end

# lib/relyra/test_support.ex
defmodule Relyra.TestSupport do
  use Boundary,
    deps: [
      Relyra, Relyra.Connection, Relyra.Error, Relyra.Principal,
      Relyra.Protocol, Relyra.Security, Relyra.Behaviours
    ],
    # Test support is a testing-time seam; it depends on everything but
    # nothing else depends on it.
    check: [in: true]
end
```

### 2.3 The hard rules `boundary` enforces

| Rule | Mechanical check |
|---|---|
| Protocol Core never imports Phoenix / Plug / Ecto / LiveView | `Relyra.Protocol` `use Boundary, type: :strict` with no Phoenix/Plug/Ecto deps listed |
| Security never imports Phoenix / Plug / Ecto / LiveView | same pattern |
| Ecto adapters are invisible to Protocol Core | `Relyra.Ecto` not listed in `Relyra.Protocol` deps |
| LiveAdmin requires both Phoenix + Ecto + LiveView | listed explicitly; compile-time guarded via `OptionalDeps` |
| `Relyra` (root) delegates only — no business logic | enforced by code-review + short module body (no other rule to encode mechanically beyond `exports: []` meaning "nothing from here is imported by other relyra modules") |
| Default adapters consume their behaviour + optional deps only | per-module boundary config in Phase 3 |

**Failure mode:** `mix compile --warnings-as-errors` under `:boundary` fails with `Relyra.Protocol.Response depends on Ecto.Query which is not in allowed deps`. This is the primary defense against the protocol core quietly growing a database dependency.

---

## 3. Data flow: v0.1 SP-initiated login (full trace with telemetry + errors)

### 3.1 Outbound (`POST /sso/:connection_id/login` → 302 to IdP)

```
[1] Browser
       │ POST /sso/:cid/login  (CSRF token, optional return_to form param)
       ▼
[2] Phoenix Router
       │ (generated by saml_routes/2 macro)
       │ pipe_through :browser (session, protect_from_forgery, put_secure_browser_headers)
       ▼
[3] Relyra.Phoenix.Controllers.LoginController.create/2
       │ [:relyra, :saml, :login, :start]
       │   measurements: %{system_time: ...}
       │   metadata:     %{connection_id: cid, flow: :sp_initiated}
       ▼
[4] Relyra.start_login/3   (public orchestration)
       ▼
[5] ConnectionResolver.resolve(conn)
       │ returns {:ok, %Connection{}} or {:error, %Relyra.Error{type: :unknown_connection}}
       │ ❌ ERROR POINT: :unknown_connection
       ▼
[6] Relyra.Protocol.AuthnRequest.build/2(connection, opts)
       │ [:relyra, :saml, :authn_request, :stop]
       │   measurements: %{duration: ..., xml_bytes: ...}
       │   metadata:     %{connection_id, request_id, binding: :redirect}
       │ ❌ ERROR POINT: :authn_request_build_failed (shouldn't happen; programmer error)
       ▼
[7] Relyra.Security.RelayState.mint/2(return_to, connection)
       │ produces opaque "rs_..." handle
       │ binding: {return_to, tenant_id, expires_at, nonce}
       │ stored via RequestStore (below) as part of the request-record map
       ▼
[8] RequestStore.put(request_id, %{connection_id, return_to, relay_state, sp_entity_id, ts}, expires_at)
       │ [:relyra, :saml, :request_store, :put, :stop]
       │   measurements: %{duration_ms: ...}
       │   metadata:     %{adapter: RequestStore.Ecto \| .ETS}
       │ ❌ ERROR POINT: :request_store_unavailable
       ▼
[9] Relyra.Protocol.Binding.Redirect.encode(authn_request_xml, relay_state, opts)
       │ deflate → base64 → urlencode → append Signature param (if signing AuthnRequest; v0.1 optional)
       │ [:relyra, :saml, :binding, :encode, :stop]
       │   measurements: %{duration_ms, bytes}
       │   metadata:     %{binding: :redirect}
       ▼
[10] Phoenix.Controller.redirect(conn, external: idp_sso_url_with_params)
       │ [:relyra, :saml, :login, :stop]
       │   measurements: %{duration_ms: ...}
       │   metadata:     %{connection_id, outcome: :redirected}
       ▼
[11] 302 Location: https://idp.example.com/sso?SAMLRequest=...&RelayState=rs_...
```

**Error-sink:** any `{:error, %Relyra.Error{}}` from [5]–[9] flows back up `start_login/3` to `LoginController.create/2`, which calls `on_error` controller (per `saml_routes/2` options) with the typed error. The `[:relyra, :saml, :login, :stop]` event fires with `outcome: :error, error_type: <atom>`.

### 3.2 Inbound (`POST /sso/:connection_id/acs` → established session + redirect to return_to)

```
[1] Browser (via IdP form POST)
       │ POST /sso/:cid/acs
       │ body: SAMLResponse=<base64>, RelayState=rs_...
       ▼
[2] Phoenix Router → ACSController.create/2
       │ [:relyra, :saml, :response, :received]
       │   measurements: %{system_time}
       │   metadata:     %{connection_id, base64_bytes: byte_size(b64)}
       │ ⚠️  SIZE GATE (pre-decode): reject if base64_bytes > max_saml_response_bytes (default 512KB)
       │     ❌ ERROR: :response_too_large
       ▼
[3] Relyra.consume_response/3
       ▼
[4] ConnectionResolver.resolve(conn)
       │ ❌ ERROR: :unknown_connection
       ▼
[5] Relyra.Protocol.Binding.POST.decode(raw_b64)
       │ [:relyra, :saml, :response, :decode, :stop]
       │   measurements: %{duration_ms, decoded_bytes}
       │   metadata:     %{binding: :post}
       │ ⚠️  SIZE GATE (post-decode, pre-parse): reject if decoded_bytes > max_decoded_bytes (default 2MB)
       │     ❌ ERROR: :malformed_base64 | :decoded_payload_too_large
       ▼
[6] Relyra.Security.XML.parse_safely(decoded_bytes, opts)
       │ ⚠️  DTDs DISABLED, external entities DISABLED, network fetches DISABLED,
       │     xinclude DISABLED, max_entity_expansion = 0, max_attribute_count enforced
       │ [:relyra, :saml, :xml, :parse, :stop]
       │   measurements: %{duration_ms, xml_bytes, element_count}
       │   metadata:     %{xml_adapter: :sweet | :xmlsec | :hybrid}
       │ ❌ ERROR: :doctype_forbidden | :entity_expansion_forbidden |
       │           :external_reference_forbidden | :malformed_xml |
       │           :duplicate_xml_id | :schema_invalid
       ▼
[7] Relyra.Protocol.Response.extract_issuer(parsed_doc)
       │ matches against connection.idp_entity_id
       │ ❌ ERROR: :issuer_mismatch | :unknown_idp
       ▼
[8] Relyra.Security.Signature.verify(parsed_doc, connection.idp_certificates, algorithm_policy)
       │ ⚠️  CANONICALIZATION happens here (exc-c14n per connection config)
       │ ⚠️  Signed-node REFERENCE is recorded (opaque ref) — THIS is what gets passed forward
       │ ⚠️  NEVER reads KeyInfo from the document — verifies against `connection.idp_certificates`
       │ ⚠️  Rejects duplicate XML IDs before verification
       │ [:relyra, :saml, :signature, :verify, :stop]
       │   measurements: %{duration_ms}
       │   metadata:     %{signature_algorithm, digest_algorithm,
       │                   certificate_fingerprint_prefix, outcome}
       │ ❌ ERROR: :missing_signature | :invalid_signature | :untrusted_certificate |
       │           :deprecated_algorithm | :signature_wrapping_suspected |
       │           :duplicate_xml_id
       ▼
[9] Relyra.Protocol.Response.select_signed_assertion(verified_node_ref, parsed_doc)
       │ ⚠️  INVARIANT: the assertion consumed MUST be inside (or equal to) the verified node.
       │     If response is signed: signed_node is <samlp:Response>; child <saml:Assertion> is in-scope.
       │     If assertion is signed: signed_node is <saml:Assertion>; we use that assertion only.
       │     Multiple assertions: reject unless configured explicitly.
       │ ❌ ERROR: :signature_wrapping_suspected | :no_assertion_in_signed_node |
       │           :ambiguous_assertion_selection
       ▼
[10] Relyra.Protocol.Response.validate_status(assertion_container)
       │ ❌ ERROR: :unsupported_status | :idp_error_response
       ▼
[11] Relyra.Protocol.Response.validate_destination(assertion_container, connection.sp_acs_url)
       │ ❌ ERROR: :destination_mismatch
       ▼
[12] Relyra.Protocol.Assertion.validate_audience(assertion, connection.sp_entity_id)
       │ ❌ ERROR: :invalid_audience
       ▼
[13] Relyra.Protocol.SubjectConfirmation.validate(assertion, connection.sp_acs_url, now)
       │   — checks Bearer method, Recipient, NotOnOrAfter, NotBefore
       │ ❌ ERROR: :recipient_mismatch | :assertion_expired | :assertion_not_yet_valid |
       │           :clock_skew_exceeded | :missing_subject_confirmation
       ▼
[14] RequestStore.pop(assertion.in_response_to)
       │ atomic consume — returns the request record + relay_state
       │ ❌ ERROR: :in_response_to_missing | :in_response_to_mismatch |
       │           :request_store_unavailable
       │ [:relyra, :saml, :request_store, :pop, :stop]
       │   measurements: %{duration_ms}
       │   metadata:     %{outcome}
       ▼
[15] ReplayStore.put_new(assertion.id, expires_at)
       │ atomic "already seen?" check
       │ ❌ ERROR: :replayed_assertion | :replay_store_unavailable
       │ [:relyra, :saml, :replay, :check, :stop]
       │   measurements: %{duration_ms}
       │   metadata:     %{outcome: :new | :already_seen}
       ▼
[16] Relyra.Protocol.Assertion.extract_principal(assertion)
       │ returns %Relyra.Principal{...}
       │ [:relyra, :saml, :response, :validate, :stop]
       │   measurements: %{duration_ms, attribute_count}
       │   metadata:     %{connection_id, outcome: :ok}
       ▼
[17] UserMapper.map(principal, connection)
       │ [:relyra, :saml, :user, :map, :stop]
       │   metadata:     %{connection_id, outcome}
       │ ❌ ERROR: :missing_name_id | :missing_required_attribute | :ambiguous_user |
       │           :domain_not_allowed | :group_mapping_failed | :user_mapper_error (wrapped)
       ▼
[18] Relyra.Security.RelayState.verify(relay_state_handle)
       │ from RequestStore.pop record in [14]
       │ ❌ ERROR: :relay_state_rejected | :relay_state_expired
       ▼
[19] SessionAdapter.sign_in(conn, principal, user: mapped_user, connection: connection)
       │ [:relyra, :saml, :session, :establish, :stop]
       │   measurements: %{duration_ms}
       │   metadata:     %{connection_id, outcome}
       │ ❌ ERROR: :session_adapter_error (wrapped — host-app responsibility)
       ▼
[20] Phoenix.Controller.redirect(conn, to: return_to_from_relay_state)
       │ [:relyra, :saml, :login, :stop]
       │   measurements: %{duration_ms_total}
       │   metadata:     %{connection_id, outcome: :ok, flow: :sp_initiated}
       ▼
[21] 302 Location: return_to (opaque-RelayState resolved)
```

### 3.3 The security invariant enforcement points (for the Credo check)

| Invariant | Enforced at step | How |
|---|---|---|
| DTDs / external entities disabled | [6] | `Relyra.Security.XML.parse_safely/2` internal options; CI fuzz-fixture verifies rejection |
| Size limits pre-decode | [2] | router-level Plug with `max_saml_response_bytes` |
| Size limits post-decode | [5] | `Relyra.Protocol.Binding.POST.decode/1` returns `:decoded_payload_too_large` |
| Canonicalization happens before signature verify | [8] | inside `Relyra.Security.Signature.verify/3`; exc-c14n per config |
| Consume-only-verified-signed-node | [9] | `select_signed_assertion/2` takes `verified_node_ref` as required first arg; there is no code path that reads an assertion without this ref |
| Trust source = `connection.idp_certificates`, never `KeyInfo` | [8] | `Relyra.Security.Signature.verify/3` signature contains `idp_certificates` as a required arg; `KeyInfo` is only used to DISAMBIGUATE among the configured list |
| Duplicate XML IDs rejected | [6] + [8] | parser rejects in [6]; signature check verifies referenced ID is unique in [8] |
| Algorithm policy enforcement | [8] | `%Relyra.Security.AlgorithmPolicy{}` value struct passed into verify; SHA-1 rejected unless `legacy_allow_sha1_until` in force + audit event fired |
| Replay defense atomic | [15] | `ReplayStore.put_new/2` semantics: `:ok \| {:error, :already_seen}` |
| InResponseTo bound to SP-initiated intent | [14] | `RequestStore.pop/1` atomic; no request → `:in_response_to_missing` |
| RelayState opaque | [7] mint / [18] verify | `Relyra.Security.RelayState` — never a raw URL |

### 3.4 Error-type coverage

Every `❌ ERROR` annotation above resolves to a distinct atom in the `Relyra.Error` taxonomy. v0.1 taxonomy: **~34 atoms** (per deep research §"Error taxonomy" ≈ 30, with four additions: `:decoded_payload_too_large`, `:no_assertion_in_signed_node`, `:ambiguous_assertion_selection`, `:relay_state_expired`).

### 3.5 Where the validation-trace UI data comes from

Every step above emits a trace entry into the `%Relyra.LoginResult{validation_trace: [...]}` list (on success) OR into the `%Relyra.Error{details: %{trace: [...]}}` map (on failure). That list IS the validation-trace UI in brand book §14.3. Labels MUST use the exact verbs: **Received, Decoded, Parsed, Matched, Verified, Validated, Checked, Rejected, Mapped, Established** (brand book §20 — "Validation trace labels").

---

## 4. Build order DAG (phase dependency)

The proposed ordering is dependency-resolved and defensible. Validated below.

### 4.1 Phase dependency DAG

```
                                ┌──────────────────────────────┐
                                │  Phase 1: XML-security ADR   │
                                │  + Relyra.Security.XML seam  │
                                │  + hardened parse_safely/2   │
                                │  + Relyra.Error taxonomy     │
                                │   (this is the ADR phase)    │
                                └──────────────┬───────────────┘
                                               │
                                               ▼
                                ┌──────────────────────────────┐
                                │  Phase 2: Protocol Core      │
                                │  - AuthnRequest build        │
                                │  - Response + Assertion      │
                                │  - Conditions +              │
                                │    SubjectConfirmation       │
                                │  - Binding.Redirect/POST     │
                                │  - Signature.verify          │
                                │  - AlgorithmPolicy           │
                                │  - RelayState mint/verify    │
                                └──────────────┬───────────────┘
                                               │
                                               ▼
                                ┌──────────────────────────────┐
                                │  Phase 3: Behaviours +       │
                                │           Default Adapters   │
                                │  - ConnectionResolver.Static │
                                │  - RequestStore.ETS + .Ecto  │
                                │  - ReplayStore.ETS + .Ecto   │
                                │  - SessionAdapter.           │
                                │    Passthrough               │
                                │  - UserMapper.               │
                                │    DefaultAttribute          │
                                │  - OptionalDeps.Ecto shim    │
                                └──────────────┬───────────────┘
                                               │
                                               ▼
                                ┌──────────────────────────────┐
                                │  Phase 4: Phoenix Runtime    │
                                │  - Router macro              │
                                │    (saml_routes/2)           │
                                │  - LoginController           │
                                │  - ACSController             │
                                │  - MetadataController        │
                                │  - Pipeline + on_error       │
                                │    integration               │
                                └──────────────┬───────────────┘
                                               │
                                               ▼
                                ┌──────────────────────────────┐
                                │  Phase 5: Observability      │
                                │  - Relyra.Telemetry catalog  │
                                │  - Relyra.Audit events       │
                                │  - Relyra.Log redacted       │
                                │  - Debug bundle stub         │
                                └──────────────┬───────────────┘
                                               │
                                               ▼
                                ┌──────────────────────────────┐
                                │  Phase 6: Providers          │
                                │  - Okta / Entra / GWS        │
                                │    guides + presets          │
                                │  - Keycloak dev container    │
                                │  - Provider-fixture corpus   │
                                └──────────────┬───────────────┘
                                               │
                                               ▼
                                ┌──────────────────────────────┐
                                │  Phase 7: Install + CI       │
                                │  - mix relyra.install        │
                                │    (minimal)                 │
                                │  - Golden-diff fixture       │
                                │  - CI lanes: fast/integ/     │
                                │    security/installer-gate/  │
                                │    release                   │
                                └──────────────┬───────────────┘
                                               │
                                               ▼
                                ┌──────────────────────────────┐
                                │  Phase 8: TestSupport + Docs │
                                │  - Relyra.TestSupport        │
                                │  - FakeIdP                   │
                                │  - README scope-first        │
                                │  - SECURITY.md               │
                                │  - Getting Started guide     │
                                │  - Security model doc        │
                                └──────────────────────────────┘
```

### 4.2 Phase dependency rationale

| Phase | Depends on | Rationale |
|---|---|---|
| **1** XML ADR + seam + Error taxonomy | nothing | **Cannot be done wrong twice.** The ADR choice (pure-BEAM vs NIF vs hybrid) constrains deployment, CI, and correctness for the entire library. The behaviour seam must freeze here so Phase 2 can code against it. The Error taxonomy (atoms) must exist before Protocol Core can return typed errors. **This phase ends with: `Relyra.Security.XML` behaviour frozen + one working adapter + `Relyra.Error` taxonomy + adversarial corpus green (XXE, signature-wrapping shape, duplicate-ID, entity expansion).** |
| **2** Protocol Core | Phase 1 | Needs `parse_safely/2` + `Error` to return typed errors. Produces AuthnRequest, Response, Assertion, Signature, AlgorithmPolicy, RelayState, bindings. No Phoenix, no Ecto, no behaviours — pure functions with `{:ok, ...} \| {:error, %Relyra.Error{}}`. |
| **3** Behaviours + Default Adapters | Phase 2 | Behaviours reference `Relyra.Connection`, `Relyra.Principal`, `Relyra.Error` — all locked by Phase 2. ETS adapter ships for dev; Ecto adapter ships behind `OptionalDeps.Ecto`. `Static` ConnectionResolver lets Phase 4 boot without any database at all. |
| **4** Phoenix Runtime | Phase 3 | Router macro dispatches into `Relyra.start_login/3` / `Relyra.consume_response/3` which in turn call the behaviours. Can't write the macro before the behaviour contracts are frozen. |
| **5** Observability | Phase 4 | Every telemetry event needs its emission site to exist first. The catalog module can be stubbed earlier, but the actual `:telemetry.execute/3` calls land with Phase 4's controllers wiring them through. Redacted logging conventions must ship BEFORE v0.1 release (we cannot release a library that logs raw assertions). |
| **6** Providers | Phases 2 + 4 | Provider presets are data + guides. Guide copy-paste examples need the router macro + controllers working. Keycloak container needs the full ACS round-trip working. |
| **7** Install + CI | Phases 3, 4, 6 | `mix relyra.install` generates behaviour skeletons (Phase 3) + router example (Phase 4) + provider-preset config snippet (Phase 6). CI security-corpus lane runs against the Protocol Core (Phase 2) but the full lane needs integration fixtures from Phase 6. |
| **8** TestSupport + Docs | everything | FakeIdP tests against the full ACS flow. README cannot be written truthfully until the surface is real. SECURITY.md and Security model doc document the invariants, which must already be enforced in code. |

### 4.3 Validated — or propose a better one?

**This ordering holds.** The only serious re-ordering consideration is:

- **Option A (proposed):** 1→2→3→4→5→6→7→8
- **Option B (considered):** 1→2→3→4→5→7→6→8 — land install + CI before providers

**Rejected Option B** because:
1. The installer golden-diff fixture needs a stable generated config. Provider presets influence what the install task emits (e.g., per-provider defaults). Generating the install-golden fixture before providers land means regenerating it after Phase 6 — exactly the kind of churn the golden-diff discipline is meant to prevent.
2. CI security-corpus lane fires fixtures that include provider-specific XMLs (Okta IdP-signed response shape, Entra NameID format variants). Those fixtures need Phase 6.

**Option A (as written) is the right ordering.** The roadmapper should treat phase boundaries as strict gates; downstream phases MUST NOT land until upstream phases are green under `mix ci.fast` + `mix ci.security` + `mix ci.integration`.

### 4.4 Parallelizability within phases

- **Phase 1** is serial. One person doing the ADR.
- **Phase 2** has three parallelizable sub-tracks: (A) AuthnRequest + Response + Assertion + Conditions, (B) Binding.Redirect + POST, (C) Signature + AlgorithmPolicy + RelayState. Integration happens at end-of-phase.
- **Phase 3** has parallelizable adapters: RequestStore.{ETS, Ecto} || ReplayStore.{ETS, Ecto} || ConnectionResolver.Static || SessionAdapter.Passthrough || UserMapper.DefaultAttribute. Behaviours freeze first, then adapters.
- **Phase 6** has three parallelizable provider-recipe tracks (Okta || Entra || GWS).
- Every other phase is effectively serial.

---

## 5. Extension-seam contracts (the five behaviours)

### 5.1 `Relyra.ConnectionResolver`

```elixir
defmodule Relyra.ConnectionResolver do
  @moduledoc """
  Resolves the tenant↔IdP trust relationship for an inbound request.

  The resolver runs on every SAML request. Implementations MUST be fast
  (p99 < 5ms) and side-effect-free beyond reads.

  Multi-tenant host apps typically resolve from the `:connection_id` path
  parameter or a subdomain/header. The returned `%Relyra.Connection{}` is
  treated as source-of-truth for trust — any downstream mismatch with it
  produces a typed error.
  """

  alias Relyra.{Connection, Error}

  @callback resolve(Plug.Conn.t()) :: {:ok, Connection.t()} | {:error, Error.t()}

  @doc """
  Optional. Called by admin tooling and metadata-refresh jobs to nudge a
  resolver that caches. Implementations that resolve on every call can omit.
  """
  @callback reload(connection_id :: binary()) :: :ok | {:error, Error.t()}

  @optional_callbacks reload: 1
end
```

### 5.2 `Relyra.RequestStore`

```elixir
defmodule Relyra.RequestStore do
  @moduledoc """
  Persists pending SP-initiated AuthnRequest IDs and their associated relay
  record until the matching SAMLResponse arrives at the ACS.

  MUST be cluster-safe in production. Relyra ships:

  - `Relyra.RequestStore.ETS` — dev + single-node; prints a loud warning if
    `Mix.env() == :prod`.
  - `Relyra.RequestStore.Ecto` — production default.

  Atomicity contract: `pop/1` must atomically remove-and-return. If two
  concurrent callers both try to `pop/1` the same `request_id`, at most one
  may receive `{:ok, record}` — the other must receive
  `{:error, :not_found}`.
  """

  alias Relyra.Error

  @type record :: %{
          connection_id: binary(),
          relay_state: binary(),
          return_to: String.t() | nil,
          sp_entity_id: String.t(),
          issued_at: DateTime.t()
        }

  @callback put(request_id :: binary(), record(), expires_at :: DateTime.t()) ::
              :ok | {:error, :duplicate_id | :store_unavailable | Error.t()}

  @callback pop(request_id :: binary()) ::
              {:ok, record()} | {:error, :not_found | :expired | :store_unavailable | Error.t()}
end
```

### 5.3 `Relyra.ReplayStore`

```elixir
defmodule Relyra.ReplayStore do
  @moduledoc """
  Records consumed SAMLResponse / Assertion IDs to defeat replay.

  MUST be cluster-safe in production. Ships `Relyra.ReplayStore.ETS`
  (dev / single-node, loud prod warning) and `Relyra.ReplayStore.Ecto`
  (production default; partial unique index on (id, connection_id) +
  TTL sweeper).

  Atomicity contract: `put_new/2` is an atomic "insert if absent". If the
  id has been seen, the call MUST return `{:error, :already_seen}`. No
  other error shape may be interpreted as "already seen" — that atom is
  how the validation pipeline identifies replay.
  """

  alias Relyra.Error

  @callback put_new(id :: binary(), expires_at :: DateTime.t()) ::
              :ok | {:error, :already_seen | :store_unavailable | Error.t()}
end
```

### 5.4 `Relyra.SessionAdapter`

```elixir
defmodule Relyra.SessionAdapter do
  @moduledoc """
  Hand-off from Relyra's verified login to the host application's session
  machinery. The host app controls what "signed in" means — cookies,
  `Pow`, `sigra`, roll-your-own — Relyra never touches `Plug.Conn`'s
  session beyond what `sign_in/3` returns.

  Implementations SHOULD:
  - rotate the session ID
  - log a non-redacted session-established event in the host app's audit trail
  - issue any application cookies / tokens
  - return a modified `Plug.Conn`

  Implementations MUST NOT:
  - throw
  - persist raw SAML XML
  """

  alias Relyra.Principal

  @callback sign_in(conn :: Plug.Conn.t(), principal :: Principal.t(), opts :: keyword()) ::
              {:ok, Plug.Conn.t()} | {:error, term()}

  @doc """
  Optional. Used by the v0.5 SLO flow; omit in v0.1.
  """
  @callback sign_out(conn :: Plug.Conn.t(), opts :: keyword()) ::
              {:ok, Plug.Conn.t()} | {:error, term()}

  @optional_callbacks sign_out: 2
end
```

**`opts` keyword** passed by Relyra to `sign_in/3` (stable contract): `[user: mapped_user, connection: %Relyra.Connection{}, principal: %Relyra.Principal{}, login_result: %Relyra.LoginResult{}]`. Host apps pattern-match on what they need.

### 5.5 `Relyra.UserMapper`

```elixir
defmodule Relyra.UserMapper do
  @moduledoc """
  Maps a verified `Relyra.Principal` to a host-app user (or creates one
  under a JIT policy). Runs after all protocol + signature + replay
  checks — the principal here is trustworthy.

  Returning `{:ok, mapped}` means "proceed to SessionAdapter.sign_in/3".
  Returning `{:error, reason}` means "reject the login" — Relyra wraps
  `reason` in a `%Relyra.Error{type: :user_mapper_error}` unless `reason`
  is already a `%Relyra.Error{}`.

  `mapped` is whatever the host app wants to carry forward — a `%User{}`
  struct, an id, a tuple. Relyra does not inspect it.
  """

  alias Relyra.{Connection, Error, Principal}

  @callback map(principal :: Principal.t(), connection :: Connection.t()) ::
              {:ok, mapped :: term()} | {:error, Error.t() | term()}

  @doc """
  Optional. JIT-provisioning hook called when `map/2` returns
  `{:error, :user_not_found}` AND the connection's
  `jit_provisioning_policy` allows creation.
  """
  @callback provision(principal :: Principal.t(), connection :: Connection.t()) ::
              {:ok, mapped :: term()} | {:error, Error.t() | term()}

  @optional_callbacks provision: 2
end
```

---

## 6. Optional-deps gateway skeleton (mailglass pattern, ported to Relyra)

### 6.1 The four gateways

```elixir
defmodule Relyra.OptionalDeps.Ecto do
  @moduledoc false
  @compile {:no_warn_undefined, [Ecto, Ecto.Repo, Ecto.Changeset, Ecto.Query, Ecto.Schema]}

  @doc "Whether Ecto is loaded in the host application."
  @spec available?() :: boolean()
  def available?, do: Code.ensure_loaded?(Ecto.Repo)

  @doc """
  Fetch via a configured Ecto repo. Returns `{:error, :ecto_not_loaded}`
  if Ecto isn't available.
  """
  @spec get(module(), module(), term()) :: {:ok, term()} | {:error, term()}
  def get(repo, schema, id) do
    if available?() do
      case repo.get(schema, id) do
        nil -> {:error, :not_found}
        row -> {:ok, row}
      end
    else
      {:error, :ecto_not_loaded}
    end
  end

  @spec insert(module(), term()) :: {:ok, term()} | {:error, term()}
  def insert(repo, changeset_or_struct) do
    if available?() do
      repo.insert(changeset_or_struct)
    else
      {:error, :ecto_not_loaded}
    end
  end

  @spec transaction(module(), (-> term())) :: {:ok, term()} | {:error, term()}
  def transaction(repo, fun) do
    if available?(), do: repo.transaction(fun), else: {:error, :ecto_not_loaded}
  end
end

defmodule Relyra.OptionalDeps.LiveView do
  @moduledoc false
  @compile {:no_warn_undefined, [Phoenix.LiveView, Phoenix.LiveView.Router, Phoenix.LiveView.Socket]}

  @spec available?() :: boolean()
  def available?, do: Code.ensure_loaded?(Phoenix.LiveView)

  @doc "Compile-time check used by `Relyra.LiveAdmin` — evaluated at the host app's compile."
  defmacro compile_guard do
    quote do
      unless Code.ensure_loaded?(Phoenix.LiveView) do
        raise """
        Relyra.LiveAdmin requires :phoenix_live_view. Add to your deps:

            {:phoenix_live_view, "~> 1.1"}

        then rerun `mix deps.get` and `mix compile`.
        """
      end
    end
  end
end

defmodule Relyra.OptionalDeps.Oban do
  @moduledoc false
  @compile {:no_warn_undefined, [Oban, Oban.Worker, Oban.Job]}

  @spec available?() :: boolean()
  def available?, do: Code.ensure_loaded?(Oban)

  @spec schedule(term()) :: {:ok, term()} | {:error, term()}
  def schedule(%{__struct__: Oban.Job} = job) do
    if available?(), do: Oban.insert(job), else: {:error, :oban_not_loaded}
  end
  def schedule(_), do: {:error, :invalid_oban_job}
end

defmodule Relyra.OptionalDeps.OpenTelemetry do
  @moduledoc false
  @compile {:no_warn_undefined, [OpenTelemetry.Tracer, :opentelemetry_telemetry]}

  @spec available?() :: boolean()
  def available?, do: Code.ensure_loaded?(OpenTelemetry.Tracer)

  @spec with_span(binary(), map(), (-> term())) :: term()
  def with_span(name, attrs, fun) do
    if available?() do
      OpenTelemetry.Tracer.with_span(name, %{attributes: attrs}, fn _ctx -> fun.() end)
    else
      fun.()
    end
  end
end
```

### 6.2 The `mix.exs` entry

```elixir
defp elixirc_options do
  [
    no_warn_undefined: [
      # Ecto — optional storage + schemas
      Ecto, Ecto.Repo, Ecto.Changeset, Ecto.Query, Ecto.Schema,
      # Phoenix.LiveView — admin UI (v0.3+; reserved namespace in v0.1)
      Phoenix.LiveView, Phoenix.LiveView.Router, Phoenix.LiveView.Socket,
      # Oban — metadata-refresh jobs (v0.2+)
      Oban, Oban.Worker, Oban.Job,
      # OpenTelemetry — optional tracing
      OpenTelemetry.Tracer, :opentelemetry_telemetry
    ]
  ]
end

defp deps do
  [
    # Hard deps
    {:telemetry, "~> 1.3"},
    {:plug, "~> 1.16"},
    {:sweet_xml, "~> 0.7"},      # default XML adapter (may be conditional on ADR)

    # Optional — host app must bring these when using the relevant feature
    {:ecto_sql, "~> 3.13", optional: true},
    {:phoenix, "~> 1.8", optional: true},
    {:phoenix_live_view, "~> 1.1", optional: true},
    {:oban, "~> 2.18", optional: true},
    {:opentelemetry_api, "~> 1.3", optional: true},

    # dev/test
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
```

### 6.3 CI lane `ci.no_optional_deps`

```bash
mix compile --no-optional-deps --warnings-as-errors
```

This **must** be a separate CI lane. It catches the case where a downstream consumer omits `:ecto_sql` / `:phoenix_live_view` and Relyra still compiles cleanly. Any module that references an optional dep without going through `Relyra.OptionalDeps.*` fails this lane.

---

## 7. Validation ordering pipeline (for the Credo check)

### 7.1 The canonical order

The ordering comes from deep research §"Security invariants" + OWASP SAML guidance + brand book §14.3 trace labels. It **must never be inverted**. The violation conditions for `Credo.Check.Refactor.NoSignatureSkipInPublicAPI` are:

| # | Step | Module / function | Brand-book label |
|---|---|---|---|
| 1 | **Received** | `Relyra.Phoenix.Controllers.ACSController.create/2` | "Received SAMLResponse" |
| 2 | **Decoded** | `Relyra.Protocol.Binding.POST.decode/1` | "Decoded base64 payload" |
| 3 | **Parsed safely** | `Relyra.Security.XML.parse_safely/2` | "Parsed XML with external entities disabled" |
| 4 | **Matched** (Issuer) | `Relyra.Protocol.Response.validate_issuer/2` | "Matched IdP issuer" |
| 5 | **Verified** (Signature) | `Relyra.Security.Signature.verify/3` | "Verified assertion signature" |
| 6 | **Validated** (Audience) | `Relyra.Protocol.Assertion.validate_audience/2` | "Validated audience" |
| 7 | **Validated** (Recipient) | `Relyra.Protocol.SubjectConfirmation.validate_recipient/2` | "Validated recipient" |
| 8 | **Checked** (InResponseTo) | `Relyra.RequestStore.pop/1` | "Checked InResponseTo" |
| 9 | **Rejected** (Replay) | `Relyra.ReplayStore.put_new/2` | "Rejected replay" (or "Checked replay cache") |
| 10 | **Mapped** (Principal) | `Relyra.UserMapper.map/2` | "Mapped principal" |
| 11 | **Established** (Session) | `Relyra.SessionAdapter.sign_in/3` | "Established session" |

### 7.2 Formalization for the Credo check

```elixir
defmodule Relyra.Pipeline do
  @moduledoc false

  @doc """
  The canonical validation order. Any code in `lib/relyra/` that threads
  `Relyra.consume_response/3` logic MUST preserve this order.
  `Credo.Check.Refactor.NoSignatureSkipInPublicAPI` walks the AST of
  `Relyra` public functions and verifies that calls to these modules
  appear in this order in the same `with ... do` chain.
  """

  @steps [
    {:received,   {Relyra.Phoenix.Controllers.ACSController, :create, 2}},
    {:decoded,    {Relyra.Protocol.Binding.POST, :decode, 1}},
    {:parsed,     {Relyra.Security.XML, :parse_safely, 2}},
    {:matched,    {Relyra.Protocol.Response, :validate_issuer, 2}},
    {:verified,   {Relyra.Security.Signature, :verify, 3}},
    {:validated_audience,  {Relyra.Protocol.Assertion, :validate_audience, 2}},
    {:validated_recipient, {Relyra.Protocol.SubjectConfirmation, :validate_recipient, 2}},
    {:checked,    {Relyra.RequestStore, :pop, 1}},
    {:rejected,   {Relyra.ReplayStore, :put_new, 2}},
    {:mapped,     {Relyra.UserMapper, :map, 2}},
    {:established, {Relyra.SessionAdapter, :sign_in, 3}}
  ]

  def steps, do: @steps

  @doc """
  The forbidden inversions (non-exhaustive — Credo check also verifies
  each step N only fires after steps 1..N-1 have all been called in the
  same `with` chain).
  """
  def forbidden_pairs do
    [
      # Can never map before verify
      {{Relyra.UserMapper, :map, 2}, {Relyra.Security.Signature, :verify, 3}},
      # Can never read assertion attributes before signature verify
      {{Relyra.Protocol.Assertion, :extract_principal, 1},
       {Relyra.Security.Signature, :verify, 3}},
      # Can never put_new (replay check) before pop (InResponseTo)
      {{Relyra.ReplayStore, :put_new, 2}, {Relyra.RequestStore, :pop, 1}},
      # Can never sign_in before replay check
      {{Relyra.SessionAdapter, :sign_in, 3}, {Relyra.ReplayStore, :put_new, 2}},
      # Can never parse without entities disabled
      # (the check looks for :xmerl_scan.string/2 or :xmerl.file/2 calls
      #  outside of Relyra.Security.XML)
    ]
  end
end
```

### 7.3 The Credo check pseudo-code

```elixir
defmodule Credo.Check.Refactor.NoSignatureSkipInPublicAPI do
  @moduledoc """
  Enforces Relyra's canonical validation order per `Relyra.Pipeline.steps/0`.

  Fails when:
    - An AST walk of any `Relyra` public function finds a `with` chain
      that invokes step N without step N-1 in the chain.
    - Any non-`Relyra.Security.XML` module directly calls `:xmerl_scan.string/2`.
    - Any non-`Relyra.Security.Signature` module interprets the result of
      a signature check.
    - `Relyra.UserMapper.map/2` appears before `Relyra.Security.Signature.verify/3`
      in the same function body.
  """
  # ...implementation walks `Macro.prewalk/2` over public Relyra functions...
end
```

The check is authored in Phase 7 alongside `NoRawAssertionInLog` and `NoParseBeforeEntityDisable`.

---

## 8. Telemetry span catalog

**Source of truth:** `Relyra.Telemetry`. All events documented in one `@moduledoc` — contributors never add an event without a PR to this file.

### 8.1 Event namespace

All events are prefixed `[:relyra, :saml, ...]`. Span events use the standard `:telemetry.span/3` `[:start, :stop, :exception]` suffix convention.

### 8.2 Span catalog (measurements + metadata)

**Shared metadata keys** (on EVERY relyra event):
- `connection_id :: binary()` — present except for pre-resolution errors
- `organization_id :: binary() | nil` — derived from connection
- `provider_preset :: atom() | nil` — `:okta`, `:entra`, `:google_workspace`, `:keycloak`, `:generic`, etc.
- `flow :: :sp_initiated | :idp_initiated`
- `binding :: :redirect | :post | nil`

**Shared measurements** (on span `:stop` events):
- `duration :: native_time()` (per `:telemetry.span/3` convention; convert to ms in reporter)
- `system_time :: System.system_time()` (on `:start`)

#### 8.2.1 Login (overall span)

| Event | Measurements | Metadata additions |
|---|---|---|
| `[:relyra, :saml, :login, :start]` | `system_time` | `return_to` |
| `[:relyra, :saml, :login, :stop]` | `duration` | `outcome :: :ok \| :error`, `error_type :: atom() \| nil`, `error_step :: atom() \| nil` |
| `[:relyra, :saml, :login, :exception]` | `duration` | `kind, reason, stacktrace` |

#### 8.2.2 AuthnRequest (outbound)

| Event | Measurements | Metadata additions |
|---|---|---|
| `[:relyra, :saml, :authn_request, :start]` | `system_time` | — |
| `[:relyra, :saml, :authn_request, :stop]` | `duration`, `xml_bytes` | `request_id, algorithm :: :rsa_sha256 \| nil (if signed), signed? :: boolean()` |

#### 8.2.3 Response decode

| Event | Measurements | Metadata additions |
|---|---|---|
| `[:relyra, :saml, :response, :decode, :start]` | `system_time`, `base64_bytes` | — |
| `[:relyra, :saml, :response, :decode, :stop]` | `duration`, `decoded_bytes` | `outcome, error_type` |

#### 8.2.4 XML parse (the hardened seam)

| Event | Measurements | Metadata additions |
|---|---|---|
| `[:relyra, :saml, :xml, :parse, :start]` | `system_time`, `xml_bytes` | `adapter :: :sweet \| :xmlsec \| :hybrid` |
| `[:relyra, :saml, :xml, :parse, :stop]` | `duration`, `element_count` | `adapter, outcome, error_type` |

#### 8.2.5 Signature verify

| Event | Measurements | Metadata additions |
|---|---|---|
| `[:relyra, :saml, :signature, :verify, :start]` | `system_time` | `signature_algorithm, digest_algorithm` |
| `[:relyra, :saml, :signature, :verify, :stop]` | `duration` | `signature_algorithm, digest_algorithm, certificate_fingerprint_prefix, outcome, error_type` |

#### 8.2.6 Response/Assertion validation (aggregate span around steps 7, 10–13)

| Event | Measurements | Metadata additions |
|---|---|---|
| `[:relyra, :saml, :response, :validate, :start]` | `system_time` | — |
| `[:relyra, :saml, :response, :validate, :stop]` | `duration`, `attribute_count`, `assertion_count`, `clock_skew_seconds` | `outcome, error_type, error_step :: :issuer \| :destination \| :audience \| :recipient \| :conditions \| nil` |

#### 8.2.7 Request store (SP-initiated bind)

| Event | Measurements | Metadata additions |
|---|---|---|
| `[:relyra, :saml, :request_store, :put, :start]` | `system_time` | `adapter` |
| `[:relyra, :saml, :request_store, :put, :stop]` | `duration`, `request_store_latency_ms` | `adapter, outcome, error_type` |
| `[:relyra, :saml, :request_store, :pop, :start]` | `system_time` | `adapter` |
| `[:relyra, :saml, :request_store, :pop, :stop]` | `duration`, `request_store_latency_ms` | `adapter, outcome :: :ok \| :not_found \| :expired, error_type` |

#### 8.2.8 Replay check

| Event | Measurements | Metadata additions |
|---|---|---|
| `[:relyra, :saml, :replay, :check, :start]` | `system_time` | `adapter` |
| `[:relyra, :saml, :replay, :check, :stop]` | `duration`, `replay_store_latency_ms` | `adapter, outcome :: :new \| :already_seen, error_type` |

#### 8.2.9 User mapping

| Event | Measurements | Metadata additions |
|---|---|---|
| `[:relyra, :saml, :user, :map, :start]` | `system_time` | — |
| `[:relyra, :saml, :user, :map, :stop]` | `duration` | `outcome, error_type, jit_provisioned? :: boolean()` |

#### 8.2.10 Session establish

| Event | Measurements | Metadata additions |
|---|---|---|
| `[:relyra, :saml, :session, :establish, :start]` | `system_time` | — |
| `[:relyra, :saml, :session, :establish, :stop]` | `duration` | `outcome, error_type` |

#### 8.2.11 Binding encode (outbound redirect)

| Event | Measurements | Metadata additions |
|---|---|---|
| `[:relyra, :saml, :binding, :encode, :stop]` | `duration`, `encoded_bytes` | `binding :: :redirect \| :post` |

#### 8.2.12 Audit events (non-span; single-shot)

| Event | Measurements | Metadata additions |
|---|---|---|
| `[:relyra, :saml, :unsafe_option, :enabled]` | `system_time` | `option :: :allow_sha1 \| :idp_initiated \| ..., reason, until :: Date.t()` |
| `[:relyra, :saml, :relay_state, :rejected]` | `system_time` | `reason :: :invalid_hmac \| :expired \| :tampered` |
| `[:relyra, :saml, :certificate, :expiry, :check]` | `cert_days_remaining` | `certificate_fingerprint_prefix` |

### 8.3 Safe-to-log / never-log discipline

`Relyra.Log` enforces:

**Safe to log:** `connection_id`, `organization_id`, `idp_entity_id_hash`, `certificate_fingerprint_prefix` (first 8 hex chars of SHA-256), `request_id_hash`, `response_id_hash`, `assertion_id_hash`, validation step, error atom, duration, byte sizes.

**Never to log:** raw `SAMLResponse`, raw assertion XML, decrypted assertions, private keys, full certificates, full NameID/email (in high-cardinality metrics), `RelayState` payload. The `NoRawAssertionInLog` Credo check forbids `Logger.*` calls with `assertion_xml`, `response_xml`, `decoded_saml`, `raw_assertion` variables in scope.

### 8.4 OTel mapping

`Relyra.OptionalDeps.OpenTelemetry.with_span/3` wraps each `:telemetry.span/3` and maps metadata keys to OTel span attributes using the `saml.relyra.*` namespace (`saml.relyra.connection_id`, `saml.relyra.provider_preset`, `saml.relyra.error_type`, ...).

---

## 9. `saml_routes/2` macro expansion

### 9.1 Source invocation (host app)

```elixir
scope "/sso", MyAppWeb do
  pipe_through :browser

  saml_routes MyApp.SSO,
    connection_resolver: MyApp.SSO.ConnectionResolver,
    session_adapter:     MyAppWeb.SAMLSession,
    user_mapper:         MyApp.SSO.UserMapper,
    request_store:       MyApp.SSO.RequestStore,   # or Relyra.RequestStore.Ecto
    replay_store:        MyApp.SSO.ReplayStore,    # or Relyra.ReplayStore.Ecto
    on_error:            MyAppWeb.SAMLErrorController
end
```

### 9.2 Expansion (pseudo-code)

```elixir
defmodule Relyra.Phoenix.Router do
  defmacro saml_routes(sso_module, opts) do
    opts = Macro.expand(opts, __CALLER__)

    quote bind_quoted: [sso_module: sso_module, opts: opts] do
      # Register the SSO-module config so controllers can fetch adapters at runtime
      # (NOT compile time — resolves optional adapters per-request).
      @relyra_config Relyra.Phoenix.Router.__validate_opts__!(sso_module, opts)

      # v0.1 routes (SP-initiated only; logout = 501 stub; IdP-initiated = v0.4)
      scope "/" do
        # Metadata endpoint — returns SP metadata XML for the tenant.
        get   "/:connection_id/metadata",
              Relyra.Phoenix.Controllers.MetadataController, :show,
              assigns: %{relyra_config: @relyra_config}

        # Start login.
        get   "/:connection_id/login",
              Relyra.Phoenix.Controllers.LoginController, :new,
              assigns: %{relyra_config: @relyra_config}

        post  "/:connection_id/login",
              Relyra.Phoenix.Controllers.LoginController, :create,
              assigns: %{relyra_config: @relyra_config}

        # ACS — inbound assertion.
        # `protect_from_forgery` is SKIPPED for this route because SAML POST
        # cannot carry a CSRF token; the InResponseTo + RelayState binding
        # plus replay defense provide the equivalent guarantee.
        # Route is marked `@csrf_skip true` via a dedicated plug.
        post  "/:connection_id/acs",
              Relyra.Phoenix.Controllers.ACSController, :create,
              assigns: %{relyra_config: @relyra_config},
              private: %{relyra_skip_csrf: true}

        # Logout (v0.5) — stub that returns 501 until implementation lands.
        get   "/:connection_id/logout",
              Relyra.Phoenix.Controllers.LogoutController, :init,
              assigns: %{relyra_config: @relyra_config}
        post  "/:connection_id/logout",
              Relyra.Phoenix.Controllers.LogoutController, :init,
              assigns: %{relyra_config: @relyra_config}
        get   "/:connection_id/slo",
              Relyra.Phoenix.Controllers.LogoutController, :consume,
              assigns: %{relyra_config: @relyra_config}
        post  "/:connection_id/slo",
              Relyra.Phoenix.Controllers.LogoutController, :consume,
              assigns: %{relyra_config: @relyra_config}
      end
    end
  end

  def __validate_opts__!(sso_module, opts) do
    # Validates required keys, checks behaviours, returns a normalized map
    # stored in @relyra_config at compile time. Raises on missing required
    # adapters with a helpful message naming the missing behaviour.
    %Relyra.Phoenix.Config{
      sso_module:          sso_module,
      connection_resolver: Keyword.fetch!(opts, :connection_resolver),
      session_adapter:     Keyword.fetch!(opts, :session_adapter),
      user_mapper:         Keyword.get(opts, :user_mapper, Relyra.UserMapper.DefaultAttribute),
      request_store:       Keyword.get(opts, :request_store, Relyra.RequestStore.ETS),
      replay_store:        Keyword.get(opts, :replay_store,  Relyra.ReplayStore.ETS),
      on_error:            Keyword.fetch!(opts, :on_error)
    }
  end
end
```

### 9.3 CSRF note (brand-book UX + security)

SAML POST to ACS cannot carry a Phoenix CSRF token (the IdP generates the form). Relyra's ACS route sets `private: %{relyra_skip_csrf: true}` which a companion plug (`Relyra.Phoenix.Pipeline.SkipCSRF`) reads to suppress `protect_from_forgery`. The replacement guarantee (InResponseTo binding + signed assertion + replay defense + opaque RelayState) is documented in `guides/security/threat-model.md`.

---

## 10. XMLDSig deployment-surface analysis (Phase 1 ADR input)

This section feeds the Phase 1 ADR. It does **not** decide — it lists the consequences of each option so the ADR author can reason honestly.

### 10.1 The three options

| Option | What it is | Where signature verification happens |
|---|---|---|
| **A. Pure-BEAM** | `sweet_xml` / `xmerl` for parse + custom-Elixir XMLDSig + `:crypto` / `:public_key` for algorithm primitives | in Elixir — all correctness audit stays in-repo |
| **B. NIF over `xmlsec1`** | A Rust/C NIF (likely via `rustler_precompiled`) wrapping libxml2 + xmlsec1 | in native code — correctness delegated to a mature library |
| **C. Hybrid** | Pure-BEAM for AuthnRequest + Metadata parse; NIF for Response signature verification only | split — the security-hard path uses native; the rest stays Elixir |

### 10.2 Deployment-surface table

| Dimension | A. Pure-BEAM | B. NIF / xmlsec | C. Hybrid |
|---|---|---|---|
| **`mix.exs` deps** | `{:sweet_xml, "~> 0.7"}` + reuses stdlib `:crypto`, `:public_key`, `:xmerl`. No native deps. | `{:sweet_xml, "~> 0.7"}` + `{:xmerl_xmlsec, "~> 0.1"}` (hypothetical Rust-NIF wrapper, likely built with `rustler_precompiled` so Hex artifact ships binaries) + OS libs `libxml2-dev`, `libxmlsec1-dev` at source-build time. | Both sets of deps. Worst of both worlds for dep count; best of both for correctness. |
| **Cross-platform binary distribution** | None required — pure Elixir installs anywhere BEAM runs. | Requires `rustler_precompiled` targets for: `x86_64-unknown-linux-gnu`, `aarch64-unknown-linux-gnu`, `x86_64-unknown-linux-musl`, `aarch64-unknown-linux-musl`, `x86_64-apple-darwin`, `aarch64-apple-darwin`, `x86_64-pc-windows-msvc`. CI must publish these on each release. Fallback-to-source-build must also work (it will for users with toolchains). | Same NIF-precompile matrix as B, but smaller NIF surface means smaller binaries and fewer tests per target. |
| **Docker / Alpine / musl** | Works out of the box on any image. | On Alpine (musl) requires `musl`-linked precompiled binaries OR a build toolchain in the image (`apk add libxml2-dev libxmlsec1-dev gcc musl-dev rustup`). Per DNA doc §"Phoenix releases guide explicitly recommends Debian/Ubuntu-based images over Alpine", this is already a soft-deprecated deployment target, but teams will still use it. | Same issue as B, smaller blast radius. |
| **`mix test` on macOS arm64 (Jon's dev machine)** | Works, no additional setup. | Works IF `rustler_precompiled` ships the `aarch64-apple-darwin` artifact. If the artifact is missing, `mix deps.get` triggers a source build that needs `libxmlsec1` via Homebrew (`brew install libxmlsec1`). Documentable but a real onboarding tax. | Same as B. |
| **Hex release process** | Standard `mix hex.publish`. Post-publish parity verification (scrypath pattern) confirms tarball matches tag. | Two-step: (1) build NIF artifacts in a GHA matrix workflow, (2) attach them to a GitHub release so `rustler_precompiled` can fetch, (3) `mix hex.publish` includes the `.ex` Rustler wrapper but NOT the binaries themselves. The `checksum-Elixir.*.exs` file MUST be committed. **This is the single biggest release-process delta.** | Same two-step release process as B. |
| **CI cost** | ~1 lane (matrix of Elixir/OTP only). | ~7 lanes per release (one per precompile target) + 1 source-build-verification lane. Release time goes from minutes to ~30 min. | Same CI multiplier as B. |
| **Correctness confidence for XMLDSig** | **LOWEST.** Canonicalization + XMLDSig + signature-wrapping defense are security-hard to implement correctly. Signature-wrapping fixtures from `samlify` 2.10.0 CVE and `ruby-saml` CVE-2024-45409 parser-differential are the baseline bar. | **HIGHEST.** xmlsec1 is the de-facto reference for XMLDSig correctness; used by major SAML implementations. Bugs land in the upstream C library and are widely exercised. | **HIGH.** The security-critical path uses xmlsec1; the rest of the library stays in-Elixir where maintenance is easy. |
| **Supply-chain surface** | BEAM stdlib + sweet_xml (pure Elixir). Clean. | BEAM stdlib + sweet_xml + xmerl_xmlsec (Rust/C, with transitive libxml2 + libxmlsec1). Additional supply-chain audit burden — pinning NIF wrapper version + SBOM for native libs. | Same as B. |
| **Debuggability in prod** | Elixir stacktraces everywhere. LiveDashboard, `:recon`, all work. | NIF errors become `:badarg` or abort; native stack inaccessible from BEAM tools. Mitigation: thin wrapper returns `{:error, reason_atom}` never raises. | Hybrid — debug pure-BEAM paths in Elixir, accept reduced debuggability for the one security-critical native call. |
| **Audit-corpus coverage feasibility** | High — every fixture flows through Elixir code that's fully instrumentable. | High — xmlsec1 has its own test suite, we add fixtures that exercise the wrapper. Cross-referencing a BEAM bug vs a xmlsec1 bug is harder. | High — cleanest story for attacker corpus because the security path is the well-tested library. |
| **Parser-differential risk** | Moderate — `sweet_xml` wraps `xmerl`; canonicalization must use the same parsed DOM; **one** parser path. | Low — xmlsec1 parses + canonicalizes + verifies in one path using libxml2. | Low for Response path; the parse-then-ignore-then-reparse risk the brand specifically warns about doesn't apply because we keep one parser per document flow. |
| **Boundary (module) impact** | `Relyra.Security.XML.Sweet` is the only adapter in the tree. `Relyra.Security.XML` behaviour still exists; one impl. | `Relyra.Security.XML.Xmlsec` is the production adapter. `Relyra.Security.XML.Sweet` may still exist for non-security paths (metadata parse) or may be deleted in favor of xmlsec everywhere. | Both adapters live in-tree; `Relyra.Security.XML.Hybrid` routes to Sweet for metadata, Xmlsec for signature. This is the module-tree justification for keeping `Relyra.Security.XML` as a behaviour with multiple implementations. |

### 10.3 ADR input summary (for Phase 1 author)

The architecture in §1 is **agnostic** between the three — `Relyra.Security.XML` is a behaviour with multiple adapters, and no other module in the library reaches around it. The decision dimensions to weigh in the ADR are, in order:

1. **Correctness confidence on signature-wrapping + canonicalization** (weight: HIGH — this is the library's core value promise).
2. **Release-process complexity + CI cost** (weight: MEDIUM — the scrypath post-publish discipline works either way, but the multi-target NIF build is a real operational tax).
3. **Docker/Alpine compatibility for adopter deployments** (weight: MEDIUM).
4. **Debuggability + stacktrace quality in production** (weight: LOW-MEDIUM).

**Informal lean (not a decision):** **Option C (Hybrid)** maximizes correctness on the security-critical path while minimizing blast radius of NIF complexity. But the ADR author must verify a maintained Rust+xmlsec NIF wrapper exists (or scope the cost of authoring one) before picking C. If no such wrapper is maintained at 2026-04-24 quality, Option A is the only viable v0.1 choice, with a documented "v0.2 will re-evaluate against xmlsec once a maintained NIF is identified" — which itself is a good enough story because the `Relyra.Security.XML` seam allows swapping the adapter without API break.

---

## 11. Anti-patterns (architecture-specific)

### 11.1 Centralizing validation in a single `Relyra.Validate` GenServer
**Why wrong:** Serial bottleneck + violates "processes only for runtime concerns" (Phoenix/Elixir best-practices §2). **Do instead:** Pure-function pipeline inside `Relyra.Phoenix.Pipeline` + behaviour calls. No validation GenServers ever.

### 11.2 Letting Protocol Core import `Ecto.Query` "just for this one helper"
**Why wrong:** Breaks the `boundary` DAG. Collapses the entire v0.2/v0.3 optional-Ecto story. **Do instead:** Add a behaviour callback; let the Ecto adapter implement it.

### 11.3 Threading the full `%Plug.Conn{}` into the validation pipeline
**Why wrong:** Copies the whole socket / session into every step; creates test setup pain; couples Protocol Core to Plug. **Do instead:** Extract the data the pipeline needs into a `%Relyra.Input{}` struct at the Phoenix boundary. Protocol Core never sees `Plug.Conn`.

### 11.4 Reading `KeyInfo` from the SAMLResponse to pick a verification cert
**Why wrong:** Classic `ruby-saml` CVE-2024-45409 shape — the attacker controls `KeyInfo`, so they can substitute any signed document from the IdP. **Do instead:** `Relyra.Security.Signature.verify/3` takes `connection.idp_certificates` as a required arg. `KeyInfo` is used only to disambiguate among the configured list, never to add a new trust root.

### 11.5 Putting the `Relyra.LiveAdmin` router under a hard `phoenix_live_view` dep
**Why wrong:** Makes the core package install `phoenix_live_view` for every adopter, including headless API-only Phoenix apps. **Do instead:** `{:phoenix_live_view, optional: true}` + `Relyra.OptionalDeps.LiveView.compile_guard/0` in `Relyra.LiveAdmin`. Compile fails loudly with a helpful error if the adopter `use`s LiveAdmin without the dep.

### 11.6 Making `Relyra.TestSupport` a hard dep of production builds
**Why wrong:** Ships test fixtures + fake IdP into production release artifacts. **Do instead:** `elixirc_paths(:test), do: ["lib", "test/support"]` + `Relyra.TestSupport` only compiled in test env. `mix.exs` `package.files` whitelist excludes `test/`.

### 11.7 Using `Agent` / `GenServer` for the ETS request/replay store
**Why wrong:** Serializes every request through one process; throughput bottleneck. **Do instead:** Public-read/public-write ETS tables owned by a supervisor-child process that does nothing but own the table. `Relyra.RequestStore.ETS` reads/writes directly from any process.

---

## 12. Integration points

### 12.1 External services

| Service | Integration pattern | Notes |
|---|---|---|
| IdP (Okta/Entra/GWS/...) | HTTP (SP-initiated redirect + POST ACS); no outbound API — the host browser is the carrier | Metadata URL fetch lands with v0.2 (behind `Oban` optional-dep). |
| Postgres (host app's DB) | Ecto via host app's `Repo` — Relyra NEVER owns the connection | Adapter (`Relyra.RequestStore.Ecto`) takes `:repo` from config. |
| Keycloak (dev / CI) | Docker container in `docker-compose.test.yml` | Used by `mix ci.integration`; Phase 6 deliverable. |

### 12.2 Internal boundaries

| Boundary | Communication | Notes |
|---|---|---|
| Protocol Core ↔ Security | Direct module calls (pure functions) | `Relyra.Security.XML` is a behaviour — adapter resolved at compile time via `Application.compile_env/3`. |
| Protocol Core ↔ Phoenix Runtime | Only via `Relyra.start_login/3` and `Relyra.consume_response/3` | `boundary` enforces: Protocol Core can't import anything from `Relyra.Phoenix`. |
| Phoenix Runtime ↔ Behaviours | Runtime dispatch via `%Relyra.Phoenix.Config{}` stored in `@relyra_config` at macro-expansion time | Adapter modules resolved at request time, not compile time — allows host-app runtime reconfig. |
| Behaviours ↔ Default Adapters | `@behaviour Relyra.X` + generic dispatch | Adapter modules listed in Relyra docs; `@moduledoc false` on defaults to keep public API tight. |
| LiveAdmin ↔ Phoenix Runtime | `import Relyra.Phoenix.Router` + LiveAdmin-specific routes | v0.3 scope. |

---

## 13. Sources

- `/Users/jon/projects/relyra/prompts/elixir-saml-lib-deep-research.md` (HIGH — authoritative for security invariants, error taxonomy, behaviour skeletons, telemetry draft)
- `/Users/jon/projects/relyra/prompts/relyra-engineering-dna-from-prior-libs.md` (HIGH — §2.1–§2.14 convergent DNA, §3 divergent menu, §5 v0.1 skeleton, §6 SAML-specific gotchas)
- `/Users/jon/projects/relyra/prompts/relyra-brand-book.md` (HIGH — §14 admin UI trace labels, §20 validation-trace verbs, §21 module naming + API naming)
- `/Users/jon/projects/relyra/.planning/PROJECT.md` (HIGH — v0.1 scope, bootstrap-locked decisions)
- `/Users/jon/projects/relyra/prompts/RELYRA-GSD-IDEA.md` (HIGH — bounded contexts, technical direction)
- `/Users/jon/projects/relyra/prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md` (MEDIUM — BEAM mental model for process / state placement in §1-§4; informs §11 anti-patterns)
- OWASP SAML Security Cheat Sheet (MEDIUM — validation ordering, RelayState allowlisting, IdP-initiated risk)
- OASIS SAML 2.0 spec (MEDIUM — protocol terminology used in module names)
- `crewjam/saml` (Go) for the core-vs-middleware split pattern (LOW — referenced in deep research §"Go lessons")
- `ruby-saml` CVE-2024-45409 + `samlify < 2.10.0` NVD entry (HIGH for motivating the "never read KeyInfo from the document" invariant)
- `esaml` XXE NVD entry (2026) (HIGH for motivating "parse before safety is already dangerous")

---

*Architecture research for: security-first SAML 2.0 Service Provider library for Elixir/Phoenix*
*Researched: 2026-04-24*
*Downstream: `/gsd-roadmapper` (Phase structure in ROADMAP.md); Phase 1 ADR author (§10 deployment-surface table); `boundary` config author (§2.2); `NoSignatureSkipInPublicAPI` Credo author (§7.3); `Relyra.Telemetry` catalog author (§8.2).*
