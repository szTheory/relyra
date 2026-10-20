# Stack Research

**Domain:** Elixir/Phoenix SAML testing helpers and demo maintenance
**Researched:** 2026-06-15
**Confidence:** HIGH

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Elixir | `~> 1.19` in `mix.exs` | Public test helper implementation | Current package baseline. Keep helpers pure Elixir where possible so the Hex artifact remains usable without mandatory Phoenix deps. |
| OTP `:public_key` / `:crypto` | OTP matrix from CI | RSA key generation, test certificate generation, XMLDSig signing | Already used by `Relyra.TestSupport.XmldsigSigner`; no new crypto dependency and no external toolchain. |
| Relyra XML/SAML internals | repo-local | Build responses through the same parser/c14n/signing primitives where practical | Preserves the existing verifier/signature alignment guarantee and avoids a divergent second test signer. |
| ExUnit | bundled with Elixir | Consumer-facing test usage pattern | `ExUnit.CaseTemplate` is the idiomatic way to ship reusable `use`-style helpers while allowing options to pass through to `use ExUnit.Case`. |
| Phoenix.ConnTest | Phoenix 1.8.x optional dependency | Optional host-side controller/endpoint posting helpers | Phoenix docs recommend endpoint testing through `build_conn/0`, `post/3`, and case templates. This should be optional, not required for the core fixture builder. |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Plug.Conn / Plug.Test | Plug `~> 1.16` from Relyra deps | Low-level conn helpers if a Phoenix convenience layer is shipped | Use only in Phoenix/Plug integration helpers, not in core XML fixture generation. |
| Oban.Testing pattern | Oban 2.23 docs | Design precedent for a public test helper module shipped by a production library | Use as precedent: explicit `use ...Testing` ergonomics, small surface, helpful assertions, and test-only semantics. Do not add Oban as a dependency. |
| Existing demo FakeIdP signer | `demo/ledger_loop/lib/ledger_loop/fake_idp/signer.ex` | Demo-local browser proof | Keep demo app proof independent from private `Relyra.TestSupport` so path-dep prod builds stay honest. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| `mix qa` | Final package-level gate | Required before main push. |
| `mix ci.security` | Crypto/security corpus gate | Any public testing fixture that signs or tampers SAML must not weaken this lane. |
| `mix ci.integration` | TestSupport/adoption proof lane | Will need updates if docs move from `Relyra.TestSupport` to `Relyra.Testing`. |
| `mix verify.release_parity <version>` | Package contents truth gate | Existing parity code hard-fails on `test_support`; v1.9 should extend parity to prove the new public testing module ships and private test_support still does not. |
| `cd demo/ledger_loop && mix test` / `scripts/demo test` | Demo flow gate | Needed to verify the current FakeIdP routes/tests are really wired. |

## Installation

No new runtime or test dependencies are recommended.

```elixir
# Existing app dependency remains enough for adopters.
{:relyra, "~> 1.8"}
```

If a Phoenix helper layer is shipped, it should rely on the adopter already having Phoenix/Plug in their application, not force Phoenix into non-Phoenix Relyra consumers.

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Ship `Relyra.Testing` under `lib/relyra/testing*` | Ship existing `lib/relyra/test_support/*` wholesale | Avoid wholesale shipping. Current modules include repo-internal stores, migrations, conformance fixtures, persistent test key behavior, and private security corpus assumptions. |
| Core fixture API plus optional Phoenix helper | Phoenix-only macro mirroring current `Relyra.TestSupport` | Only mirror the macro if phase planning proves the optional dependency boundary remains clean. |
| Ephemeral per-call or explicit fixture key material | Persistent global FakeIdP key | Use persistent key only for private suite internals. Public helpers should make key provenance explicit and keep default material test-scoped. |
| Public positive and named negative fixtures | Publish full adversarial crypto corpus | Full corpus stays private. Public helpers can expose representative rejection fixtures without teaching every bypass pattern. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Shipping `Relyra.TestSupport` as-is | It mixes adopter macros with internal repo fixtures, Ecto test repo, conformance helpers, and private security corpus plumbing. | Curated `Relyra.Testing` modules with a deliberately small public contract. |
| Static default signing keys in docs or helpers | Known keys copied into production configs become a trust-boundary footgun. | Ephemeral keys by default; make returned cert chain explicit for the test connection only. |
| A testing helper that bypasses `Relyra.consume_response/3` | It proves the wrong thing and can mask a broken verifier path. | Helpers should produce signed SAML inputs and optional POST helpers that still enter the real ACS/consume path. |
| Making Phoenix mandatory for core fixtures | Relyra's Phoenix dependency is optional; non-Phoenix users still need core SAML helpers. | Split core XML fixture generation from Phoenix ergonomics. |
| Relaxing `mix verify.release_parity` to allow all `test_support` paths | Reopens TD-02 and ships private internals. | Keep `test_support` excluded; add allowlisted `testing` modules. |

## Stack Patterns by Variant

**If the helper is core-only:**
- Provide functions that return `%{response_xml: ..., saml_response: ..., cert_chain: ..., connection_opts: ...}`.
- Because consumers can post through Phoenix, Plug, Wallaby, browser tests, or direct `consume_response/3` without Relyra depending on their stack.

**If Phoenix ergonomics are included:**
- Use an ExUnit case-template or macro that imports Phoenix.ConnTest only in the consumer's test module and dispatches through the configured endpoint.
- Because Phoenix's own testing docs model endpoint tests around `@endpoint`, `build_conn/0`, and dispatch helpers.

**If demo FakeIdP remains:**
- Keep it demo-local and verify it uses its own signer.
- Because the demo app intentionally compiles Relyra as a prod path dependency where private `test_support` modules are absent.

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| Relyra `@version` 1.8.1 | Elixir `~> 1.19` | Current repo truth from `mix.exs`; PROJECT constraints may be older and should not drive new API design. |
| Phoenix.ConnTest 1.8.8 docs | Phoenix `~> 1.8` optional dep | Endpoint tests use `@endpoint`, `build_conn/0`, `post/3`, and helper composition. |
| ExUnit.CaseTemplate 1.20.1 docs | Elixir 1.20 docs, compatible pattern | `using/2` supports options passed through `use MyCase, ...`; useful if `Relyra.Testing.PhoenixCase` ships. |
| Oban.Testing 2.23 docs | Design precedent only | Public test helpers can reduce boilerplate and validate common pitfalls without becoming production code. |

## Sources

- `mix.exs` - current package paths, optional deps, release parity exclusions.
- `lib/relyra/test_support*.ex` - private helper behavior and prod guards.
- `demo/ledger_loop/lib/ledger_loop_web/router.ex` - current FakeIdP routes exist.
- `demo/ledger_loop/lib/ledger_loop_web/controllers/fake_idp_controller.ex` - demo FakeIdP flow and guards.
- `https://phoenix.hexdocs.pm/Phoenix.ConnTest.html` - endpoint testing and helper composition.
- `https://phoenix.hexdocs.pm/testing.html` - Phoenix case-template setup pattern.
- `https://ex-unit.hexdocs.pm/ExUnit.CaseTemplate.html` - reusable case-template API.
- `https://oban.hexdocs.pm/testing_workers.html` - public test helper precedent and pitfall-oriented helper behavior.

---
*Stack research for: Relyra v1.9 public testing API and demo maintenance*
*Researched: 2026-06-15*
