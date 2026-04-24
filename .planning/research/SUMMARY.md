# Research Synthesis — Relyra

**Project:** Relyra (Elixir/Phoenix SAML 2.0 Service Provider library)  
**Synthesized:** 2026-04-24  
**Inputs:** `STACK.md`, `FEATURES.md`, `ARCHITECTURE.md`, `PITFALLS.md`

## 1) Decision Snapshot

Relyra has enough research signal to proceed directly into `REQUIREMENTS.md` and then `ROADMAP.md`.

- **Scope confidence:** High for v0.1-v0.3 boundaries and public API seams.
- **Primary unresolved item:** XML security ADR outcome (pure BEAM vs NIF vs hybrid).
- **Recommended immediate path:** Treat XML ADR as Phase 1 gate, then execute the remaining v0.1 work against a fixed seam (`Relyra.Security.XML` behaviour).

## 2) Stack and Pin Recommendations

The stack is converged and ready to lock into requirements/roadmap:

- **Language/runtime:** Elixir `~> 1.18`; OTP floor `27` (27/28 CI matrix).
- **Runtime deps:** `phoenix ~> 1.8`, `plug ~> 1.18`, `telemetry ~> 1.3`, `nimble_options ~> 1.1`, `x509 ~> 0.9`.
- **Optional deps:** `phoenix_live_view ~> 1.1`, `ecto ~> 3.13`, `ecto_sql ~> 3.13`, `phoenix_ecto ~> 4.7`, `oban ~> 2.21`, `opentelemetry_api ~> 1.5`.
- **Dev/test deps:** `credo ~> 1.7`, `dialyxir ~> 1.4`, `ex_doc ~> 0.40`, `mix_audit ~> 2.1`, `sobelow ~> 0.14`, `boundary ~> 0.10`, `stream_data ~> 1.3`, `mox ~> 1.2`, `bypass ~> 2.1`.
- **Do not depend on:** `esaml`, `samly`, `ex_saml` as implementation dependencies.

## 3) Feature Boundary (Must-Have vs Deferred)

### v0.1 (must deliver)

- SP-initiated SSO end-to-end (`start_login` + ACS `consume_response`).
- Hardened XML path, strict signature verification, signed-node consumption, replay defense.
- Protocol validation (`Issuer`, `Audience`, `Recipient`, `Destination`, `InResponseTo`, time windows, status checks).
- Five extension behaviours:
  - `Relyra.ConnectionResolver`
  - `Relyra.SessionAdapter`
  - `Relyra.UserMapper`
  - `Relyra.RequestStore`
  - `Relyra.ReplayStore`
- Phoenix router macro `saml_routes/2`.
- Typed `%Relyra.Error{}` taxonomy.
- Telemetry catalog + redacted logging discipline.
- Provider recipes (Okta/Entra/GWS) + Keycloak dev container.
- Minimal `mix relyra.install`.
- Security-focused CI lanes + permanent CVE fixture corpus.
- `Relyra.TestSupport` for adopter testing.

### Deferred by design

- **v0.2:** Ecto schemas, metadata import/export/refresh, cert rollover, mapping persistence.
- **v0.3:** Optional mountable LiveView admin.
- **v0.4:** IdP-initiated SSO (opt-in, default off).
- **v0.5:** SLO (partial-by-provider).
- **v1.0:** External security review, conformance, migration tooling, encrypted assertions.

### Explicit anti-features

- No hosted broker/SaaS, no OIDC/OAuth in Relyra, no SCIM ownership, no generic auth framework.
- No relaxed signature policy by default, no raw RelayState redirect model, no security-marketing claims.

## 4) Architecture and Boundary Decisions

Module and dependency strategy are stable:

- Keep protocol core isolated from Phoenix/Ecto/LiveView.
- Enforce boundaries with `boundary` compiler.
- Keep optional-deps behind `Relyra.OptionalDeps.*` gateways.
- Make `Relyra.Security.XML` the seam that isolates the ADR outcome.
- Preserve strict validation ordering in one canonical pipeline.

Resulting build path is clear:

1. XML ADR + seam lock.
2. Protocol core.
3. Behaviours + default adapters.
4. Phoenix runtime wiring.
5. Observability/logging contracts.
6. Provider/test corpus/docs/install/release discipline.

## 5) Security Pitfalls to Treat as Non-Negotiable

The following are release blockers for v0.1:

- Parse-before-safety (XXE class).
- Signature wrapping and signed-node mismatch.
- Parser differentials.
- Missing `InResponseTo` + replay binding.
- Trusting document `KeyInfo`.
- Duplicate XML IDs.
- Audience/Issuer/Recipient/Destination validation gaps.
- RelayState open redirects.
- Production ETS replay stores in clustered deployments.
- Raw assertion/response leakage in logs.

Operational policy from research:

- Every security fix must add a permanent fixture in `test/fixtures/security/`.
- CI must include dedicated security lanes (`deps.audit`, `hex.audit`, sobelow, adversarial fixtures).

## 6) Open Decision Gates (carry into REQUIREMENTS)

These remain unresolved and must be explicitly tracked as gated requirements:

1. **XML ADR outcome:** pure BEAM vs NIF-over-xmlsec vs hybrid.
2. **Canonicalization acceptance bar:** fixture corpus threshold required before shipping.
3. **If NIF path chosen:** precompiled target matrix and supply-chain verification policy.
4. **Keycloak image pin at execution time:** revalidate current stable tag before final CI pin.
5. **Domain verification (`relyra.dev`) and final naming due diligence.**

## 7) What This Enables Next

This synthesis is sufficient to generate:

- `REQUIREMENTS.md` with testable v0.1 requirements and explicit decision gates.
- `ROADMAP.md` with dependency-correct phase ordering starting with XML ADR.
- `STATE.md` with the current project position and next command routing.

