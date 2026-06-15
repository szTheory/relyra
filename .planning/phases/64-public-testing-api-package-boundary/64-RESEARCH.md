# Phase 64: Public Testing API & Package Boundary - Research

**Researched:** 2026-06-15  
**Domain:** Elixir library public testing API, XMLDSig fixture generation, Hex package boundary  
**Confidence:** HIGH for package/verification seams, MEDIUM for final public struct naming

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
## Implementation Decisions

### Public API Shape
- **D-01:** Ship a public, data-first `Relyra.Testing` namespace under `lib/relyra/testing*`; keep `Relyra.TestSupport.*` private and excluded from production compilation and Hex package files.
- **D-02:** The canonical API is plain functions plus explicit structs/data, not a macro-first `use Relyra.Testing` interface.
- **D-03:** The public core should expose a narrow fixture surface such as `signed_success/1`, `wrong_audience/1`, `tampered_digest/1`, `invalid_signature/1`, `consume_opts/2`, and `post_params/2`.
- **D-04:** Public fixture values must carry the data adopters need for both direct verifier tests and ACS-post tests: `response_xml`, `encoded_response`, `cert_chain` or `idp_certificates`, `connection`, `request_intent`, `relay_state`, and expected outcome.

### Security And Trust Boundary
- **D-05:** Public success fixtures must be genuinely signed through the same C14N/signing technique used by the verifier path. No structure-only or unsigned success fixture may be accepted as a public helper output.
- **D-06:** Public helpers must prove outputs through `Relyra.consume_response/3` or the real Phoenix ACS path. Do not provide helpers that directly assign sessions, mock authenticated users, bypass `Signature.verify/4`, or trust document `KeyInfo`.
- **D-07:** Public negative fixtures are representative only: wrong audience, post-signing digest/content tamper, and invalid signature or wrong-key cases. The permanent adversarial crypto corpus, encryption adversarial machinery, keypair persistence internals, and parser/C14N internals remain private.
- **D-08:** Public copy and module names should avoid `FakeIdP` as the adopter-facing frame. Use "testing fixture", "signed test response", "matching test certificate", and "real verifier path"; explicitly say the helpers are test-only and are not an IdP, broker, or production trust source.

### Phoenix And Optional Dependencies
- **D-09:** Core fixture generation must remain Phoenix-free. If Phoenix convenience ships, place it in a separate optional layer such as `Relyra.Testing.Phoenix`.
- **D-10:** Optional Phoenix helpers may wrap `post_params/2` into `Phoenix.ConnTest`/endpoint dispatch, but they must still hit a real ACS route or `consume_response/3`; they must not become the only public testing path.
- **D-11:** Phase tests should include optional-dependency/compile coverage so Phoenix remains optional for core `Relyra.Testing` fixture use.

### Package And Verification Gates
- **D-12:** Package/parity tests must prove `lib/relyra/testing*` is included in package files and `lib/relyra/test_support*` remains excluded.
- **D-13:** Local package checks should continue using the explicit `mix.exs` file whitelist as the enforcement point; `verify.release_parity` should continue hard-failing on `test_support` paths.
- **D-14:** Security verification for this phase must pin exact `%Relyra.Error{type: ...}` outcomes for public negative fixtures and show public success fixtures traverse the real parse/signature/digest/validation pipeline.

### the agent's Discretion
The planner may choose exact struct/module names inside the locked public shape, but should optimize for least surprise, stable Hex API, and copy-pasteable adopter tests. Prefer explicit returned fixture data over hidden global Application env or broad imports.

### Deferred Ideas (OUT OF SCOPE)
## Deferred Ideas

- Separate `relyra_testing` package: defer unless the testing surface grows beyond fixture generation and optional ACS helpers.
- Public browser FakeIdP/mini-IdP: defer; Phase 66 owns the LedgerLoop demo browser-login story.
- Broad public adversarial corpus: explicitly out of scope for v1.9.
- Auth bypass helpers such as direct `sign_in`/session assignment: out of scope for Relyra's public SAML testing story.

### Reviewed Todos (not folded)
None — no matching pending todos were found for Phase 64.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TEST-01 | Hex adopters can use public `Relyra.Testing`; private `Relyra.TestSupport` remains excluded. | Use `lib/relyra/testing*` plus existing `mix.exs` whitelist and `verify.release_parity` guards. [VERIFIED: codebase grep] |
| TEST-02 | Generate genuine signed success fixture with matching test cert chain and no production trust mutation. | Promote a curated signer that computes digest/signature through Relyra's Saxy/C14N path and returns certs in fixture data. [VERIFIED: codebase grep] |
| TEST-03 | Generate representative typed rejection fixtures without private adversarial corpus. | Reuse wrong audience, post-signing tamper, and wrong-key/invalid-signature patterns; keep encryption/adversarial corpus private. [VERIFIED: codebase grep] |
| TEST-04 | Helpers exercise real ACS or `consume_response/3`, never direct session assignment or verifier bypass. | `consume_response/3` enters `ValidationPipeline.run/4`, which calls `Signature.verify/4`; Phoenix ACS decodes POST then calls `consume_response`. [VERIFIED: codebase grep] |
| TEST-05 | Optional Phoenix helper does not make Phoenix mandatory for core fixture use. | Keep core API Phoenix-free; add compile probe/gate for Phoenix-free fixture use. Current dependency compile has existing optional-dependency risk. [VERIFIED: local command] |
| PKG-01 | Package/release parity proves `testing*` ships and `test_support*` stays excluded. | Existing package files and release parity task already reject `test_support`; extend tests to assert `testing*` inclusion. [VERIFIED: local command] |
</phase_requirements>

## Summary

Phase 64 should add a small public `Relyra.Testing` API that returns explicit fixture structs/maps, not macros or hidden global configuration. [VERIFIED: CONTEXT.md] The implementation should curate the existing `Relyra.TestSupport.XmldsigSigner` technique into production-compiled `lib/relyra/testing*` code: build XML, parse it with Relyra's Saxy tree, canonicalize with the same C14N engine the verifier uses, compute `DigestValue`, sign `SignedInfo`, and return the matching test certificate as data. [VERIFIED: codebase grep]

The package boundary is already enforced in the right place: `mix.exs` compiles/packages an explicit `lib/**/*` file list that rejects paths containing `test_support`, and `Mix.Tasks.Verify.ReleaseParity` hard-fails if a published tarball contains `test_support`. [VERIFIED: codebase grep] The planner should extend this mechanism to include `lib/relyra/testing*` and add local package-build assertions, not introduce a second package filtering system. [VERIFIED: local command]

**Primary recommendation:** Implement `Relyra.Testing` as Phoenix-free fixture generation plus optional `Relyra.Testing.Phoenix` convenience, with tests that prove every public fixture reaches `Relyra.consume_response/3` or ACS and that package files include `testing*` while excluding `test_support*`. [VERIFIED: codebase grep]

## Project Constraints (from AGENTS.md)

- Do not implement outside the active PLAN.md scope; Phase 64 currently has context but no plan. [VERIFIED: AGENTS.md]
- Escalate before public API shape changes to published entry points or behaviour callback signatures. `Relyra.Testing` is a new public API, so final signatures need careful review. [VERIFIED: AGENTS.md]
- Never relax signature source, one-parse-path, pre-parse guard, crypto-required, audit co-commit, or replay-protection invariants. [VERIFIED: AGENTS.md]
- Do not bypass `lib/relyra/security/signature.ex`, `lib/relyra/security/xml/pure_beam.ex`, `lib/relyra/security/xml/c14n.ex`, algorithm policy, audit writer, or behaviour seams. [VERIFIED: AGENTS.md]
- Keep `mix test --warnings-as-errors`, `mix ci.security`, and `mix format --check-formatted` green; new security-relevant code needs security-gate coverage. [VERIFIED: AGENTS.md]
- Do not run `mix hex.publish`; Release Please owns publishing. [VERIFIED: AGENTS.md]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Public signed fixture generation | Library API | Crypto/XML internals | `Relyra.Testing` owns public data shape; it must reuse Relyra parser/C14N/signature primitives rather than external XMLDSig code. [VERIFIED: codebase grep] |
| Public negative fixtures | Library API | Validation pipeline | Helpers generate inputs; `consume_response/3`/ACS remains responsible for typed rejection. [VERIFIED: codebase grep] |
| Direct verification helper options | Library API | Behaviour adapters | `consume_opts/2` should configure request/replay/resolver seams for tests without global trust mutation. [VERIFIED: codebase grep] |
| Phoenix ACS convenience | Optional Phoenix layer | Library API | Phoenix helpers may dispatch POST params but core fixtures must not depend on Phoenix. [VERIFIED: CONTEXT.md] |
| Package inclusion/exclusion | Build/package config | Release parity task | `mix.exs` owns package files; release parity verifies published artifact drift and `test_support` leaks. [VERIFIED: codebase grep] |
| Security proof | Test suite | CI aliases | Tests must prove digest/signature verification and exact typed errors through real pipeline. [VERIFIED: codebase grep] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Elixir/Mix | 1.19.5 local; project requires `~> 1.19` | Compile paths, package metadata, tests | Existing project runtime and build tool. [VERIFIED: local command] |
| Hex | 2.4.2 local | Package build/fetch/parity checks | Hex package docs define `:files` package inclusion and local `mix hex.build`. [CITED: https://hex.pm/docs/publish] |
| `saxy` | locked 1.6.0 | XML parse path | Existing one-parse-path parser used by `PureBeam` and signer. [VERIFIED: local command] |
| Erlang `:public_key` / `:crypto` | OTP 28 local | RSA key/cert/signature/digest primitives | Existing signer/verifier uses BEAM crypto; no new crypto package needed. [VERIFIED: codebase grep] |
| Relyra Saxy/C14N modules | local | Canonicalization and parsed signed candidates | Prevents signer/verifier differentials by reusing the verifier's parser/C14N path. [VERIFIED: codebase grep] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `plug` | locked 1.19.2 | POST params/conn foundation | Already required by project; core `post_params/2` can stay plain maps and not call Plug. [VERIFIED: local command] |
| `phoenix` | locked 1.8.7, latest observed 1.8.8 | Optional ACS dispatch helper | Use only inside `Relyra.Testing.Phoenix` or tests that require Phoenix. [VERIFIED: local command] |
| ExUnit | Elixir stdlib | Public API and security proof tests | Existing test framework; no extra package required. [VERIFIED: codebase grep] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Curated `Relyra.Testing` | Publish all `Relyra.TestSupport` | Rejected: leaks private adversarial/encryption/test internals and violates package boundary. [VERIFIED: CONTEXT.md] |
| Plain data functions | `use Relyra.Testing` macro | Rejected by locked decision; macros hide options and make API larger. [VERIFIED: CONTEXT.md] |
| In-package public API | Separate `relyra_testing` package | Deferred until testing surface grows. [VERIFIED: CONTEXT.md] |
| Real verifier path | Direct session/current_user helper | Rejected: bypasses SAML verification and contradicts TEST-04. [VERIFIED: CONTEXT.md] |

**Installation:** No new external packages are recommended for Phase 64. [VERIFIED: codebase grep]

```bash
# none
```

**Version verification:** Existing stack was checked with `elixir --version`, `mix --version`, `mix hex --version`, `mix hex.info phoenix plug saxy telemetry`, and `mix.lock` grep. [VERIFIED: local command]

## Package Legitimacy Audit

No new external packages are recommended or installed in this phase, so the package legitimacy gate has no package candidates. [VERIFIED: codebase grep]

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| none | — | — | — | — | not applicable | No install |

**Packages removed due to slopcheck [SLOP] verdict:** none  
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```text
Adopter test
  |
  v
Relyra.Testing.signed_success/1 or negative fixture helper
  |
  v
Phoenix-free fixture struct/map
  |-- response_xml
  |-- encoded_response + relay_state + post_params
  |-- connection/idp_certificates
  |-- request_intent
  |-- expected {:ok, _} or {:error, %Relyra.Error{type: ...}}
  |
  +--> Direct path: Relyra.consume_response(response_xml, request_intent, consume_opts)
  |         |
  |         v
  |    ValidationPipeline.run/4 -> PureBeam.parse_safely/2 -> Signature.verify/4
  |         |
  |         v
  |    typed {:ok, login_result} or {:error, %Relyra.Error{}}
  |
  +--> Optional Phoenix path: Relyra.Testing.Phoenix.post_response(...)
            |
            v
       Phoenix.ConnTest.dispatch -> ACSController.create/2
            |
            v
       Binding.decode_post -> Relyra.consume_response/2 -> same verifier path
```

### Recommended Project Structure

```text
lib/
├── relyra/testing.ex                 # public Phoenix-free facade
├── relyra/testing/fixture.ex         # explicit public fixture struct
├── relyra/testing/signer.ex          # curated genuine XMLDSig signer
├── relyra/testing/adapters.ex        # tiny public test stores/resolver, if needed
└── relyra/testing/phoenix.ex         # optional Phoenix convenience only

test/
├── relyra/testing_test.exs           # public direct consume_response proof
├── relyra/testing_phoenix_test.exs   # optional ACS proof
├── security/testing_fixture_crypto_test.exs
└── mix/tasks/verify_release_parity_test.exs
```

### Pattern 1: Data-First Fixture

**What:** Return a struct/map with all protocol inputs, trust material, and expected outcome. [VERIFIED: CONTEXT.md]  
**When to use:** Every public fixture helper. [VERIFIED: CONTEXT.md]

**Example:**

```elixir
# Source: Phase 64 CONTEXT.md + local consume_response patterns.
fixture =
  Relyra.Testing.signed_success(
    connection_id: "conn-123",
    sp_entity_id: "https://sp.example.com/metadata",
    acs_url: "https://sp.example.com/saml/acs",
    name_id: "alice@example.com"
  )

assert {:ok, result} =
         Relyra.consume_response(
           fixture.response_xml,
           fixture.request_intent,
           Relyra.Testing.consume_opts(fixture)
         )
```

### Pattern 2: Curated Real Signer, Not Private TestSupport Re-export

**What:** Move/copy only the minimal genuine signing recipe into public `Relyra.Testing`, preserving the parser/C14N/signature alignment. [VERIFIED: codebase grep]  
**When to use:** `signed_success/1`, `tampered_digest/1`, and signing variants that must traverse crypto before failing later validation. [VERIFIED: codebase grep]

**Example:**

```elixir
# Source: lib/relyra/test_support/xmldsig_signer.ex
{:ok, placeholder_tree} = Relyra.Security.XML.SaxyTree.parse(placeholder_xml)
assertion_node = find_by_local_and_id(placeholder_tree, "Assertion", assertion_id)
{:ok, %{canonical_xml: ref_bytes}} = Relyra.Security.XML.PureBeam.canonicalize(%{node: assertion_node})
digest_value = :sha256 |> :crypto.hash(ref_bytes) |> Base.encode64()
```

The exact implementation should reuse existing local helpers where possible, but the public module must not depend on `Relyra.TestSupport.*`, because `test_support` is excluded from production/package files. [VERIFIED: codebase grep]

### Pattern 3: Optional Phoenix Wrapper

**What:** Keep `post_params/2` in core as a plain `%{"SAMLResponse" => ..., "RelayState" => ...}` builder; make Phoenix dispatch a separate convenience. [VERIFIED: CONTEXT.md]  
**When to use:** Host apps that already depend on Phoenix and want ACS route tests. [CITED: https://phoenix.hexdocs.pm/Phoenix.ConnTest.html]

**Example:**

```elixir
# Source: Phoenix.ConnTest official docs + existing Relyra.TestSupport.post_saml_response/3.
def post_response(conn, endpoint, path, fixture, opts \\ []) do
  params = Relyra.Testing.post_params(fixture, opts)
  Phoenix.ConnTest.dispatch(conn, endpoint, :post, path, params)
end
```

### Anti-Patterns to Avoid

- **Publishing `Relyra.TestSupport` wholesale:** It includes macros, session helpers, encryption/adversarial helpers, persistent-term key internals, and repo-private fixture machinery. [VERIFIED: codebase grep]
- **Structure-only success fixtures:** Existing security posture requires real `DigestValue` recompute and `:public_key.verify`. [VERIFIED: AGENTS.md]
- **Trusting document `KeyInfo`:** `Signature.do_verify/4` rejects `key_info_trust`; public fixture docs must teach configured/returned cert trust only. [VERIFIED: codebase grep]
- **Phoenix in core fixture generation:** Violates TEST-05 and makes the smallest adopter use case harder. [VERIFIED: CONTEXT.md]
- **Global production trust mutation:** Fixture certs should be returned in data and threaded through `connection`, `idp_certificates`, `cert_chain`, or opts. [VERIFIED: codebase grep]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| XML parsing | Regex field extraction or alternate XML parser | `Relyra.Security.XML.PureBeam` / `SaxyTree` | Preserves one parse path and avoids parser differentials. [VERIFIED: AGENTS.md] |
| XML canonicalization | Custom fixture-only C14N | `Relyra.Security.XML.C14N` / `PureBeam.canonicalize/1` | Signer and verifier must see byte-identical canonical material. [VERIFIED: codebase grep] |
| XMLDSig verification proof | Stubbed success/session assignment | `Relyra.consume_response/3` or ACS path | TEST-04 requires real verifier path. [VERIFIED: CONTEXT.md] |
| Package filtering | New allow/block list | Existing `package_lib_files/0` and `verify.release_parity` | Existing mechanism already gates `test_support` leaks. [VERIFIED: codebase grep] |
| Phoenix test dispatch | Custom fake conn runner | `Phoenix.ConnTest.dispatch/5` in optional helper | Phoenix docs identify ConnTest as the endpoint/controller test helper. [CITED: https://phoenix.hexdocs.pm/Phoenix.ConnTest.html] |

**Key insight:** The hard part is not generating XML; it is generating XML that succeeds or fails for the same cryptographic reason production inputs do. The public API should package the existing verifier-aligned signing method without exposing private adversarial machinery. [VERIFIED: codebase grep]

## Common Pitfalls

### Pitfall 1: Re-exporting Private TestSupport

**What goes wrong:** Hex adopters call modules that are intentionally absent from package files. [VERIFIED: codebase grep]  
**Why it happens:** Existing docs mention `Relyra.TestSupport` for local proof. [VERIFIED: codebase grep]  
**How to avoid:** Public modules must live under `lib/relyra/testing*` and must not alias `Relyra.TestSupport.*`. [VERIFIED: CONTEXT.md]  
**Warning signs:** `rg "Relyra.TestSupport" lib/relyra/testing*` returns anything. [VERIFIED: codebase grep]

### Pitfall 2: Signed Success That Does Not Prove Crypto

**What goes wrong:** A helper returns XML that reaches success without digest/signature verification, recreating the bypass class Phase 29/30 fixed. [VERIFIED: AGENTS.md]  
**Why it happens:** Fixture builders are tempted to fill `Signature` shape without a real signature. [VERIFIED: codebase grep]  
**How to avoid:** Public success tests must assert telemetry or exact path evidence that `Signature.verify/4` accepted a real candidate, and negative tamper fixtures must pin exact `%Relyra.Error{type: ...}`. [VERIFIED: codebase grep]  
**Warning signs:** Tests assert only `{:ok, _}` or `{:error, _}` without digest/signature-specific controls. [VERIFIED: codebase grep]

### Pitfall 3: Optional Dependency Blindness

**What goes wrong:** A module under `lib/relyra/testing/phoenix.ex` references Phoenix at compile time and breaks non-Phoenix consumers. [VERIFIED: local command]  
**Why it happens:** Hex optional dependencies are not production dependencies automatically included for all consumers; official Hex docs say only production dependencies are included in package dependency metadata. [CITED: https://hex.pm/docs/publish]  
**How to avoid:** Keep core helpers Phoenix-free, isolate Phoenix convenience, and add a Phoenix-free consumer compile gate. [VERIFIED: CONTEXT.md]  
**Warning signs:** Throwaway path-dependency compile without Phoenix currently fails on existing optional Ecto/Phoenix modules, so the planner must define a scoped compile gate for core testing or account for the larger optional-dependency issue. [VERIFIED: local command]

### Pitfall 4: Package Build Proof That Checks Source Tree Only

**What goes wrong:** Tests pass because files exist locally, but the Hex tarball omits `testing*` or leaks `test_support*`. [VERIFIED: codebase grep]  
**Why it happens:** Source existence is not package inclusion. [CITED: https://hex.pm/docs/publish]  
**How to avoid:** Use `mix hex.build --unpack` or pure package file-list tests against `package_lib_files/0`/release parity helpers. [CITED: https://hex.hexdocs.pm/Mix.Tasks.Hex.Publish.html]  
**Warning signs:** No assertion inspects unpacked package paths or `package.files`. [VERIFIED: codebase grep]

## Code Examples

### Public Fixture Shape

```elixir
# Source: Phase 64 CONTEXT.md
defmodule Relyra.Testing.Fixture do
  @moduledoc "Test-only SAML fixture data for Relyra verifier tests."

  defstruct [
    :response_xml,
    :encoded_response,
    :cert_chain,
    :idp_certificates,
    :connection,
    :request_intent,
    :relay_state,
    :expected
  ]
end
```

### Plain POST Params

```elixir
# Source: existing Relyra.TestSupport.post_saml_response/3 pattern.
def post_params(%Relyra.Testing.Fixture{} = fixture, opts \\ []) do
  saml_key = Keyword.get(opts, :saml_response_key, "SAMLResponse")
  relay_key = Keyword.get(opts, :relay_state_key, "RelayState")

  %{saml_key => fixture.encoded_response}
  |> Map.put(relay_key, fixture.relay_state)
  |> Enum.reject(fn {_key, value} -> value in [nil, ""] end)
  |> Map.new()
end
```

### Direct Verification Proof

```elixir
# Source: test/protocol/consume_response_pipeline_test.exs
fixture = Relyra.Testing.tampered_digest()

assert {:error, %Relyra.Error{type: :digest_mismatch}} =
         Relyra.consume_response(
           fixture.response_xml,
           fixture.request_intent,
           Relyra.Testing.consume_opts(fixture)
         )
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Structure-only signature fixtures | Genuine `DigestValue` and `SignatureValue` over verifier-canonicalized nodes | Phase 29/30 history in code comments | Public helpers must generate real signed fixtures. [VERIFIED: codebase grep] |
| Public docs pointing to `Relyra.TestSupport` | New `Relyra.Testing` public API | Phase 64/65 plan | Phase 64 builds API; Phase 65 updates docs. [VERIFIED: REQUIREMENTS.md] |
| Package path existence checked informally | `verify.release_parity` hard-fails `test_support` in published tarball | Existing code | Extend with `testing*` inclusion proof. [VERIFIED: codebase grep] |

**Deprecated/outdated:**
- Adopter-facing `FakeIdP`/`Relyra.TestSupport` guidance: still present in README/guides and should be replaced in Phase 65 after Phase 64 lands. [VERIFIED: codebase grep]
- Direct session assignment helpers as SAML proof: not acceptable for this public API because it bypasses verification. [VERIFIED: CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Final public struct/module names can be chosen by the planner within the locked shape. [ASSUMED] | Architecture Patterns | Naming churn or public API review delay. |
| A2 | A curated signer can be copied/moved without changing verifier semantics. [ASSUMED] | Architecture Patterns | Implementation may need more refactor isolation than planned. |
| A3 | Phoenix-free core compile coverage can be scoped to `Relyra.Testing` even though current full dependency compile without optional deps fails on broader Ecto/Phoenix modules. [ASSUMED] | Common Pitfalls / Validation | TEST-05 may reveal a larger optional-dependency packaging issue. |

## Open Questions

1. **Should `Relyra.Testing.Fixture` be a public struct or documented map?**
   - What we know: CONTEXT.md requires explicit data. [VERIFIED: CONTEXT.md]
   - What's unclear: Exact public type/name is discretionary. [ASSUMED]
   - Recommendation: Use a public struct for stable docs/specs and pattern matching; avoid exposing signer internals.

2. **How far should TEST-05 go?**
   - What we know: Core testing helpers must not make Phoenix mandatory. [VERIFIED: CONTEXT.md]
   - What's unclear: A throwaway non-Phoenix path-dependency compile currently fails because existing `lib/relyra/ecto*` and `lib/relyra/phoenix*` modules reference optional deps. [VERIFIED: local command]
   - Recommendation: Planner should include a scoped compile test proving `Relyra.Testing` itself has no Phoenix dependency, and optionally file/defer the broader package optional-dependency issue if outside Phase 64.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Elixir | compile/test | yes | 1.19.5 | none |
| Erlang/OTP | crypto/public_key | yes | OTP 28 | none |
| Mix | build/test/package | yes | 1.19.5 | none |
| Hex | local package build | yes | 2.4.2 | inspect `package.files` in Mix project |
| Git | release parity task | yes | 2.41.0 | none for release parity |
| Context7 CLI | docs lookup | no | — | official HexDocs/WebFetch used |

**Missing dependencies with no fallback:** none for planning. [VERIFIED: local command]  
**Missing dependencies with fallback:** Context7 CLI missing; official HexDocs were used. [VERIFIED: local command]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit via Mix 1.19.5 [VERIFIED: local command] |
| Config file | `mix.exs` aliases; standard ExUnit project layout [VERIFIED: codebase grep] |
| Quick run command | `mix test test/relyra/testing_test.exs test/mix/tasks/verify_release_parity_test.exs --warnings-as-errors` [ASSUMED] |
| Full suite command | `mix qa && mix ci.security` [VERIFIED: AGENTS.md] |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| TEST-01 | `Relyra.Testing` public module compiles from `lib/relyra/testing*`; no `Relyra.TestSupport` dependency | unit/package | `mix test test/relyra/testing_test.exs --warnings-as-errors` | no, Wave 0 |
| TEST-02 | `signed_success/1` produces real signed XML accepted by `consume_response/3` with returned certs | integration/security | `mix test test/relyra/testing_test.exs --warnings-as-errors` | no, Wave 0 |
| TEST-03 | `wrong_audience/1`, `tampered_digest/1`, `invalid_signature/1` pin exact error types | integration/security | `mix test test/security/testing_fixture_crypto_test.exs --warnings-as-errors` | no, Wave 0 |
| TEST-04 | Helpers exercise real verifier or ACS path, not session assignment | integration | `mix test test/relyra/testing_test.exs test/relyra/testing_phoenix_test.exs --warnings-as-errors` | no, Wave 0 |
| TEST-05 | Core fixture generation remains Phoenix-free; optional Phoenix helper isolated | compile/integration | `mix test test/relyra/testing_optional_dependency_test.exs --warnings-as-errors` | no, Wave 0 |
| PKG-01 | Package includes `lib/relyra/testing*` and excludes `lib/relyra/test_support*` | package | `mix test test/mix/tasks/verify_release_parity_test.exs --warnings-as-errors` | existing file needs extension |

### Sampling Rate

- **Per task commit:** focused new test file plus `mix format --check-formatted`.
- **Per wave merge:** `mix test --warnings-as-errors` plus `mix ci.security` if signer/security code changed.
- **Phase gate:** `mix qa`, `mix ci.security`, and package build/parity checks before `$gsd-verify-work`.

### Wave 0 Gaps

- [ ] `test/relyra/testing_test.exs` — covers TEST-01, TEST-02, TEST-04.
- [ ] `test/security/testing_fixture_crypto_test.exs` — covers TEST-02, TEST-03, TEST-04.
- [ ] `test/relyra/testing_phoenix_test.exs` — covers TEST-05 optional ACS wrapper if shipped.
- [ ] `test/relyra/testing_optional_dependency_test.exs` — covers Phoenix-free core dependency boundary.
- [ ] Extend `test/mix/tasks/verify_release_parity_test.exs` — covers PKG-01 inclusion/exclusion.

**Validation evidence gathered during research:**
- `mix test test/mix/tasks/verify_release_parity_test.exs --warnings-as-errors` passed: 17 tests, 0 failures, 1 excluded. [VERIFIED: local command]
- `mix test test/protocol/consume_response_pipeline_test.exs --warnings-as-errors` passed: 12 tests, 0 failures. [VERIFIED: local command]
- `mix test test/test_support_demo_test.exs --warnings-as-errors` passed on rerun: 2 tests, 0 failures. [VERIFIED: local command]
- `mix hex.build --unpack -o /tmp/relyra_phase64_pkg_check` exited 0; current package contains no `lib/relyra/test_support*` and no `lib/relyra/testing*` yet. [VERIFIED: local command]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes | Public helpers must drive SAML auth through `consume_response/3` or ACS. [VERIFIED: CONTEXT.md] |
| V3 Session Management | limited | Do not provide session assignment helpers; ACS path may use host session adapter. [VERIFIED: CONTEXT.md] |
| V4 Access Control | limited | Not changing app authorization; avoid trust/global config mutation. [VERIFIED: CONTEXT.md] |
| V5 Input Validation | yes | Existing `PureBeam.parse_safely/2` byte guards and validation pipeline. [VERIFIED: codebase grep] |
| V6 Cryptography | yes | Existing `:public_key.verify`, digest recompute, configured cert chain only. [VERIFIED: codebase grep] |

### Known Threat Patterns for Relyra Testing API

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Structure-only signed success accepted | Spoofing/Tampering | Generate real `DigestValue` and `SignatureValue`; prove through `Signature.verify/4`. [VERIFIED: codebase grep] |
| Document `KeyInfo` trusted as cert source | Spoofing | Return cert chain in fixture and configure connection/opts; never trust document key material. [VERIFIED: AGENTS.md] |
| Parser/canonicalization differential | Tampering | Use Relyra Saxy/C14N path for signer and verifier. [VERIFIED: codebase grep] |
| Private adversarial corpus disclosure | Information disclosure | Publish representative negative fixtures only. [VERIFIED: CONTEXT.md] |
| Global trust mutation from helper | Elevation of privilege | Return explicit `connection`/`consume_opts`; no Application env mutation. [VERIFIED: CONTEXT.md] |
| Optional Phoenix helper becoming mandatory | Denial of service/adoption breakage | Core fixture generation has no Phoenix calls; Phoenix dispatch lives separately. [VERIFIED: CONTEXT.md] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/64-public-testing-api-package-boundary/64-CONTEXT.md` — locked Phase 64 decisions.
- `.planning/REQUIREMENTS.md` — TEST-01..TEST-05 and PKG-01.
- `.planning/STATE.md` — milestone state and public testing concern.
- `AGENTS.md` — project security invariants and testing requirements.
- `mix.exs` — compile paths, dependencies, package file list, CI aliases.
- `lib/mix/tasks/verify.release_parity.ex` and `test/mix/tasks/verify_release_parity_test.exs` — package boundary enforcement.
- `lib/relyra/test_support/xmldsig_signer.ex`, `lib/relyra/test_support/fake_idp.ex` — existing genuine signer and private fixture breadth.
- `lib/relyra.ex`, `lib/relyra/protocol/validation_pipeline.ex`, `lib/relyra/security/signature.ex`, `lib/relyra/security/xml/pure_beam.ex` — real verification path.
- Local commands: `mix test ...`, `mix hex.build --unpack`, `mix hex.info`, `elixir --version`, `mix --version`.

### Secondary (MEDIUM confidence)

- Hex publishing docs: https://hex.pm/docs/publish — package `:files`, production dependency behavior, publish/package behavior.
- Hex task docs: https://hex.hexdocs.pm/Mix.Tasks.Hex.Publish.html — `:files` and `:exclude_patterns`.
- Mix deps docs: https://mix.hexdocs.pm/Mix.Tasks.Deps.html — dependency options including `:only`.
- Phoenix.ConnTest docs: https://phoenix.hexdocs.pm/Phoenix.ConnTest.html — endpoint/controller testing and dispatch pattern.
- Elixir Code docs: https://hexdocs.pm/elixir/Code.html — `Code.ensure_loaded?/1` behavior for optional module checks.

### Tertiary (LOW confidence)

- None used as authoritative sources.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — verified from `mix.exs`, `mix.lock`, `mix hex.info`, local tool versions, and official docs.
- Architecture: HIGH — mapped from locked context and current verifier/package seams.
- Pitfalls: HIGH for security/package pitfalls; MEDIUM for optional dependency compile scope because current broader package already has optional-dependency compile failures in a no-Phoenix/no-Ecto throwaway consumer.

**Research date:** 2026-06-15  
**Valid until:** 2026-07-15 for local architecture; 2026-06-22 for package/dependency version details.
