# Phase 65: documentation-truth - Context

**Gathered:** 2026-06-16 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 65 focuses entirely on updating adopter-facing documentation to match the public testing API (`Relyra.Testing`) introduced in Phase 64. It replaces all references to the private `Relyra.TestSupport` and "FakeIdP" with the new public surface.
</domain>

<decisions>
## Implementation Decisions

### Adopter Testing Narrative (Getting Started & Recipes)
- **D-01:** Replace `use Relyra.TestSupport` and macro references (`setup_saml_connection/2`, `sign_saml_response/2`) with explicit calls to `Relyra.Testing.signed_success/1` and `Relyra.Testing.Phoenix.post_response/5` in `README.md`, `guides/getting_started.md`, and `guides/recipes/*.md`.
- **D-02:** Remove the term "FakeIdP" completely from adopter-facing guides.

### Validation of Doc Examples (Test Drift Protection)
- **D-03:** Create a dedicated `test/docs/testing_api_drift_test.exs` file. This aligns with existing project convention (`troubleshooting_drift_test.exs`). It will meticulously mirror the exact `Plug.Conn` pipeline and `Relyra.Testing` assertions presented in the `guides/getting_started.md` file.

### Repo-Internal References & Documentation
- **D-04:** Update references to `Relyra.TestSupport` in `BATTERIES_INCLUDED.md`, case studies, and `jtbd_user_flows.md` to reference `Relyra.Testing` where appropriate.
- **D-05:** Leave the heavy use of "FakeIdP" inside `demo/ledger_loop/README.md` untouched or only lightly annotated, as Phase 66 explicitly owns "Demo FakeIdP Disposition".

### Explicit Cert Trust & Scoping
- **D-06:** Use an ExDoc admonition block (`> #### Info` or `> #### Note`) immediately following the testing code snippet in `guides/getting_started.md`. The block will explicitly state that `Relyra.Testing.signed_success/1` generates ephemeral RSA keys on the fly to satisfy Relyra's strict cryptographic verification pipeline, meaning the developer does not need to configure dummy certificates for their test environment.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md`
- `.planning/phases/64-public-testing-api-package-boundary/64-CONTEXT.md`
- `lib/relyra/testing.ex`
- `lib/relyra/testing/phoenix.ex`
- `README.md`
- `guides/getting_started.md`
- `guides/overview.md`
- `guides/recipes/generic_saml.md`
- `BATTERIES_INCLUDED.md`
- `guides/jtbd_user_flows.md`
- `guides/case_studies/phoenix_saas_tenant_onboarding.md`
- `test/test_support_demo_test.exs`
- `test/docs/testing_api_drift_test.exs` (to be created)
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The established pattern for doc drift testing exists in `test/docs/troubleshooting_drift_test.exs` and `test/docs/logout_recipe_drift_test.exs`, which should be followed for `testing_api_drift_test.exs`.
- The new `lib/relyra/testing.ex` provides the data-first fixture API that replaces the macros.

### Established Patterns
- ExDoc admonitions (`> #### Info`) are the idiomatic Elixir/HexDocs way to call out important technical details without breaking the flow of a tutorial.
- Drift tests provide a functional shadow of documentation code blocks, ensuring they don't break as the API evolves.

### Integration Points
- `guides/getting_started.md` is the primary entry point for Hex adopters. Changes here dictate the initial developer experience.
- The `test/docs/` directory is where we hook into the CI pipeline to ensure doc snippets remain accurate.
</code_context>

<specifics>
## Specific Ideas

- Ensure that any `post_response` examples explicitly show how to extract the `response_xml` and `cert_chain` from the returned fixture.
</specifics>

<deferred>
## Deferred Ideas

- Overhauling the `demo/ledger_loop/` references to FakeIdP (deferred to Phase 66).
</deferred>
