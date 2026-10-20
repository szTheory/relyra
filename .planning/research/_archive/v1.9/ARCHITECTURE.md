# Architecture Research

**Domain:** Public SAML testing API plus demo/adoption maintenance
**Researched:** 2026-06-15
**Confidence:** HIGH

## Standard Architecture

### System Overview

```text
Consumer tests
  |
  | use/import
  v
Relyra.Testing public API
  |
  | builds signed/invalid SAML fixtures, returns cert chain and params
  v
Relyra verifier entrypoints
  |
  | consume_response/3 or Phoenix ACS route
  v
Existing security seams
  - pre-parse guards
  - saxy parse path
  - exclusive C14N
  - DigestValue recompute
  - :public_key.verify against configured certs

Optional Phoenix layer
  |
  | posts returned params through host endpoint
  v
Host Phoenix test/router pipeline

LedgerLoop demo
  |
  | browser flow only, demo-local signer
  v
Relyra ACS route mounted in demo app
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| `Relyra.Testing` | Public core fixture generation and small assertions | Functions under `lib/relyra/testing.ex` and possibly `lib/relyra/testing/*.ex`. |
| `Relyra.Testing.Fixture` or equivalent | Opaque return struct/map carrying XML, Base64 SAMLResponse, RelayState, cert chain, and expected result metadata | Prefer explicit values over global config mutation. |
| `Relyra.Testing.Phoenix` or case template | Optional helper that posts fixtures through Phoenix endpoint/ACS | Thin layer over `Phoenix.ConnTest.dispatch` or `post/3`; should load only when Phoenix is available. |
| Private `Relyra.TestSupport` | Repo-only internal test infrastructure | Keep under `lib/relyra/test_support` and excluded from package/prod compilation. |
| Demo `LedgerLoop.FakeIdP` | Browser-visible demo harness | Stays demo-local and independent of private TestSupport. |
| Release parity gate | Package boundary proof | Extend current `test_support` exclusion with `testing` inclusion checks. |

## Recommended Project Structure

```text
lib/relyra/
  testing.ex              # public core API, no Phoenix dependency
  testing/
    fixture.ex            # optional public struct for fixture outputs
    signer.ex             # curated public signer wrapper or extracted safe subset
    phoenix.ex            # optional Phoenix helpers if phase design accepts

lib/relyra/test_support/  # remains private/excluded
  fake_idp.ex
  xmldsig_signer.ex
  ...

test/relyra/testing/
  testing_test.exs
  phoenix_test.exs
  package_boundary_test.exs

guides/
  getting_started.md
  overview.md
  jtbd_user_flows.md

demo/ledger_loop/
  lib/ledger_loop_web/controllers/fake_idp_controller.ex
  test/ledger_loop_web/...
```

### Structure Rationale

- **`lib/relyra/testing.ex`:** Public Hex-shipped modules must not live under `test_support`, because existing package filters and release parity tests deliberately exclude that path.
- **`testing/phoenix.ex`:** Phoenix is optional. A separate module lets consumers use core fixtures without Phoenix and lets docs clearly mark Phoenix-specific helpers.
- **Private `test_support`:** Keeps internal Ecto repos, migration fixtures, conformance fixtures, and adversarial corpus helpers out of the public contract.
- **Demo-local signer:** The demo compiles Relyra as a prod path dependency. Its browser harness must not rely on private test-support modules.

## Architectural Patterns

### Pattern 1: Core Fixture Builder

**What:** Generate signed and selected invalid SAML responses as data.

**When to use:** Always. This is the stable public contract.

**Trade-offs:** Slightly more verbose for Phoenix users, but avoids optional dependency leakage.

```elixir
fixture = Relyra.Testing.signed_response(subject: "sarah@example.com")

assert %{
         response_xml: _xml,
         saml_response: _base64,
         cert_chain: [_pem],
         connection: _connection_opts
       } = fixture
```

### Pattern 2: Thin Phoenix Posting Helper

**What:** A helper that accepts a `Plug.Conn`, endpoint, ACS path or connection_id, and a public fixture, then posts `SAMLResponse`/`RelayState`.

**When to use:** If phase design confirms clean Phoenix optional dependency handling.

**Trade-offs:** Good adopter ergonomics, but must not turn Phoenix into a core requirement.

```elixir
conn =
  conn
  |> Relyra.Testing.Phoenix.post_saml_response(endpoint: MyAppWeb.Endpoint, fixture: fixture)
```

### Pattern 3: Public Representative Negatives, Private Corpus

**What:** Expose named invalid fixtures for common adopter paths while keeping the permanent adversarial corpus internal.

**When to use:** Public helpers that need rejection-path coverage.

**Trade-offs:** Good adopter coverage without making bypass research part of the public API.

## Data Flow

### Request Flow

```text
Test creates fixture
  -> fixture returns XML/Base64/cert chain
  -> host config uses returned cert chain for that test connection
  -> host posts SAMLResponse to ACS or calls consume_response/3
  -> Relyra verifies digest/signature through existing crypto gate
  -> test asserts accepted user or typed rejection/trace
```

### State Management

```text
No global production state mutation
  -> fixture owns keypair/cert
  -> test owns connection config
  -> replay/request stores remain host-provided
```

### Key Data Flows

1. **Happy path fixture:** ephemeral keypair -> self-signed test cert -> signed assertion -> Base64 SAMLResponse -> host test connection trusts returned cert -> real consume/ACS path accepts.
2. **Wrong audience fixture:** signed assertion with mismatched Audience -> real crypto passes -> protocol validation rejects with typed error.
3. **Tampered digest fixture:** signed assertion mutated after signing -> crypto/digest validation rejects.
4. **Demo FakeIdP browser flow:** browser hits `/fake_idp/login` -> posts to `/fake_idp/sso` -> self-submitting form posts to `/saml/:connection_id/acs` -> real Relyra verifier handles it.

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| Local adopter tests | Core fixture builder is enough. |
| Large application test suites | Avoid persistent global keys; allow callers to reuse explicit fixture context inside a test module if needed. |
| Browser/demo tests | Keep flow deterministic and bounded; avoid unbounded inflate or network calls. |

### Scaling Priorities

1. **First bottleneck:** RSA key generation per fixture can slow large suites. Mitigate with explicit caller-controlled fixture context only if needed, not a hidden global key.
2. **Second bottleneck:** Phoenix helper ambiguity around ACS paths. Mitigate by requiring explicit endpoint and path/connection_id options.

## Anti-Patterns

### Anti-Pattern 1: Publish Private TestSupport

**What people do:** Move `lib/relyra/test_support` into package files.

**Why it's wrong:** It exposes private stores, migrations, conformance helpers, and security-corpus assumptions.

**Do this instead:** Extract a curated public module under `lib/relyra/testing*`.

### Anti-Pattern 2: Test Helper Bypasses Verification

**What people do:** Directly assign `current_user` or call session adapter without a signed response.

**Why it's wrong:** It proves host session wiring, not SAML trust verification.

**Do this instead:** Generate signed XML and route through ACS or `consume_response/3`.

### Anti-Pattern 3: Phoenix Dependency Leak

**What people do:** Make public core helper compile-time depend on `Phoenix.ConnTest`.

**Why it's wrong:** Relyra's Phoenix dependency is optional.

**Do this instead:** Keep core pure; isolate Phoenix helpers.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| Hex package | Explicit package file allowlist | Add public `testing` paths without allowing `test_support`. |
| Phoenix host app | Optional ConnTest helper | Follow `@endpoint`/case-template pattern from Phoenix docs. |
| Demo LedgerLoop | Demo-local FakeIdP routes | Verify route and browser tests, then document or prune. |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| Public Testing -> Signature verifier | Signed XML only | No bypass around `Relyra.Security.Signature.do_verify/4`. |
| Public Testing -> package filters | Allowlisted files | `package_lib_files/0` must include `testing` but exclude `test_support`. |
| Public Testing -> private corpus | Selected fixture recipes only | No wholesale public export of adversarial corpus internals. |
| Demo -> Relyra | Mounted public routes | Demo cannot call private `Relyra.TestSupport` in prod path-dep mode. |

## Sources

- `mix.exs`
- `lib/relyra/test_support.ex`
- `lib/relyra/test_support/fake_idp.ex`
- `lib/relyra/test_support/xmldsig_signer.ex`
- `demo/ledger_loop/lib/ledger_loop/fake_idp/signer.ex`
- `demo/ledger_loop/lib/ledger_loop_web/router.ex`
- `https://phoenix.hexdocs.pm/Phoenix.ConnTest.html`
- `https://phoenix.hexdocs.pm/testing.html`
- `https://ex-unit.hexdocs.pm/ExUnit.CaseTemplate.html`

---
*Architecture research for: Relyra v1.9 public testing API and demo cleanup*
*Researched: 2026-06-15*
