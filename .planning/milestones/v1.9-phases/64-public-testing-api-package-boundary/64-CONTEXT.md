# Phase 64: Public Testing API & Package Boundary - Context

**Gathered:** 2026-06-15 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 64 ships a deliberately small public `Relyra.Testing` surface for Hex adopters while preserving the existing private `Relyra.TestSupport` boundary. Scope is limited to test-only fixture generation, representative typed rejection fixtures, real verifier/ACS-path proof, optional Phoenix convenience, and package/parity gates. It does not ship a production IdP, hosted broker, full public adversarial corpus, or any relaxation of parser, signature, digest, replay, or trust-source rules.
</domain>

<decisions>
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
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/PROJECT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `mix.exs`
- `lib/mix/tasks/verify.release_parity.ex`
- `test/mix/tasks/verify_release_parity_test.exs`
- `lib/relyra.ex`
- `lib/relyra/phoenix/controllers/acs_controller.ex`
- `lib/relyra/security/signature.ex`
- `lib/relyra/security/xml/pure_beam.ex`
- `lib/relyra/security/xml/c14n.ex`
- `lib/relyra/test_support.ex`
- `lib/relyra/test_support/fake_idp.ex`
- `lib/relyra/test_support/xmldsig_signer.ex`
- `test/test_support_demo_test.exs`
- `test/protocol/consume_response_pipeline_test.exs`
- `test/security/xml/adversarial_crypto_test.exs`
- `demo/ledger_loop/lib/ledger_loop/fake_idp/signer.ex`
- `README.md`
- `guides/getting_started.md`
- `guides/overview.md`
- `guides/jtbd_user_flows.md`
- `guides/case_studies/phoenix_saas_tenant_onboarding.md`
- `BATTERIES_INCLUDED.md`
- `brandbook/notes/decision-log.md`
- `prompts/elixir-saml-lib-deep-research.md`
- `prompts/elixir-opensource-libs-best-practices-deep-research.md`
- `prompts/elixir-plug-ecto-phoenix-system-design-best-practices-deep-research.md`
- `prompts/phoenix-best-practices-deep-research.md`
- `prompts/relyra-engineering-dna-from-prior-libs.md`
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/relyra/test_support/xmldsig_signer.ex` already implements the real-signing technique: emit XML, parse through Relyra's Saxy tree, canonicalize the referenced assertion and `SignedInfo` through the same C14N engine, compute `DigestValue`, and sign with `:public_key.sign`.
- `lib/relyra/test_support/fake_idp.ex` provides response-building defaults, signed success, encrypted-response internals, and negative/tamper patterns. Its private breadth should be curated, not published wholesale.
- `demo/ledger_loop/lib/ledger_loop/fake_idp/signer.ex` is a production-compiled example of re-homing the signing technique without depending on `Relyra.TestSupport`.
- `test/protocol/consume_response_pipeline_test.exs` has direct `consume_response/3` patterns with explicit test request/replay/resolver seams.
- `lib/mix/tasks/verify.release_parity.ex` and its tests already encode the `test_support` package-boundary hard fail.

### Established Patterns
- Public Relyra entry points return typed `{:ok, _} | {:error, %Relyra.Error{}}`; public testing helpers should teach that same shape.
- `mix.exs` uses an explicit `lib/**/*.ex` whitelist that rejects `test_support` for production compile and package files. Phase 64 should add `testing*` within that existing mechanism, not replace it.
- Existing security gates preserve the Phase 30 anti-hollow invariant by running each security suite in a separate `cmd mix test` process. Do not collapse those aliases while adding new security coverage.
- Brand and docs voice should remain calm, exact, and operator-friendly. Avoid magic, "SAML is easy", or production-IdP implications.

### Integration Points
- Core fixture outputs feed `Relyra.consume_response/3` directly using returned `request_intent`, `connection`, relay state, request store, replay store, and cert chain options.
- Phoenix helper outputs feed `Relyra.Phoenix.Controllers.ACSController.create/2` through normal POST params: `SAMLResponse` and `RelayState`.
- Package proof connects to `mix.exs` `package_lib_files/0`, `Mix.Tasks.Verify.ReleaseParity.filter_package_paths/1`, and `paths_contain_test_support?/1`.
- Phase 65 docs should replace adopter-facing `Relyra.TestSupport` guidance with the new `Relyra.Testing` public API while preserving repo-internal test support references where explicitly labeled internal.
</code_context>

<specifics>
## Specific Ideas

Example core shape for planner consideration:

```elixir
fixture =
  Relyra.Testing.signed_success(
    connection_id: "acme",
    sp_entity_id: "https://app.example.com/saml/metadata",
    acs_url: "https://app.example.com/saml/acs",
    name_id: "alice@example.com"
  )

assert {:ok, result} =
         Relyra.consume_response(
           fixture.response_xml,
           fixture.request_intent,
           Relyra.Testing.consume_opts(fixture)
         )
```

Example negative shape:

```elixir
fixture =
  Relyra.Testing.wrong_audience(
    expected_audience: "https://app.example.com/saml/metadata",
    actual_audience: "https://evil.example.com/saml/metadata"
  )

assert {:error, %Relyra.Error{type: :audience_mismatch}} =
         Relyra.consume_response(
           fixture.response_xml,
           fixture.request_intent,
           Relyra.Testing.consume_opts(fixture)
         )
```

Suggested public microcopy for Phase 65:

> This helper creates test-only SAML input and a matching test certificate. It is not an IdP, broker, or production trust source.
</specifics>

<deferred>
## Deferred Ideas

- Separate `relyra_testing` package: defer unless the testing surface grows beyond fixture generation and optional ACS helpers.
- Public browser FakeIdP/mini-IdP: defer; Phase 66 owns the LedgerLoop demo browser-login story.
- Broad public adversarial corpus: explicitly out of scope for v1.9.
- Auth bypass helpers such as direct `sign_in`/session assignment: out of scope for Relyra's public SAML testing story.

### Reviewed Todos (not folded)
None — no matching pending todos were found for Phase 64.
</deferred>
