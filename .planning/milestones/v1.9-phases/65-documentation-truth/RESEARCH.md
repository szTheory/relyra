# Phase 65: Documentation Truth - Research

## Overview

The goal of Phase 65 is to update all adopter-facing documentation to match the new public testing API (`Relyra.Testing` and `Relyra.Testing.Phoenix`) introduced in Phase 64, fully replacing references to the private `Relyra.TestSupport` module and "FakeIdP" terminology.

## Current State & Required Changes

### 1. Adopter Guides and README
**Files to update:**
- `README.md`
- `guides/getting_started.md`
- `guides/overview.md`
- `guides/jtbd_user_flows.md`
- `guides/recipes/generic_saml.md`
- `guides/recipes/okta.md`
- `guides/recipes/entra.md`
- `guides/recipes/google_workspace.md`
- `guides/recipes/adfs.md`
- `guides/case_studies/phoenix_saas_tenant_onboarding.md`

**Changes needed:**
- Remove all instances of `use Relyra.TestSupport, endpoint: ...`.
- Replace macro calls like `setup_saml_connection/2`, `build_saml_response/0`, `sign_saml_response/1`, `post_saml_response/2`, `assert_saml_login/2` with the new data-first API:
  - Generate fixture: `fixture = Relyra.Testing.signed_success(opts)`
  - Post response: `conn = Relyra.Testing.Phoenix.post_response(conn, MyAppWeb.TestRouter, "/saml/acs", fixture)`
- Eradicate the term "FakeIdP" from all these guides.
- Add an ExDoc admonition (`> #### Info` or `> #### Note`) in `guides/getting_started.md` directly under the testing snippet, explaining that `Relyra.Testing.signed_success/1` generates ephemeral RSA keys dynamically, so no dummy cert configuration is required for local testing.

### 2. BATTERIES_INCLUDED.md and Generation Task
**Files to update:**
- `BATTERIES_INCLUDED.md`
- `lib/mix/tasks/relyra.batteries_included.ex`

**Changes needed:**
- Update `lib/mix/tasks/relyra.batteries_included.ex` to change `@demo_test` from `"test/test_support_demo_test.exs"` to `"test/testing_demo_test.exs"`.
- Update the claim table to reflect the new testing API:
  - Replace "local-first proof starts with FakeIdP" with "local-first proof starts with explicit testing fixtures".
  - Replace seam `Relyra.TestSupport` + `Relyra.TestSupport.FakeIdP` with `Relyra.Testing` + `Relyra.Testing.Phoenix`.
- Run the mix task to regenerate `BATTERIES_INCLUDED.md`.

### 3. Installer Sweeps
**Files to check/update:**
- `lib/mix/tasks/relyra.install.ex` and related templates or output strings.

**Changes needed:**
- Ensure any generated comments or terminal output strings mentioning `Relyra.TestSupport` or `FakeIdP` are updated to point to `Relyra.Testing`.

### 4. Test Forking and Isolation
**Files to create/update:**
- `test/test_support_demo_test.exs` (existing)
- `test/testing_demo_test.exs` (new)
- `test/docs/testing_api_drift_test.exs` (new)

**Changes needed:**
- Fork `test/test_support_demo_test.exs` into `test/testing_demo_test.exs`. The new file will use `Relyra.Testing` APIs, demonstrating exactly what is written in `guides/getting_started.md`.
- Keep `test/test_support_demo_test.exs` but rename it or mark it as an internal integration test (e.g., `test/internal/test_support_integration_test.exs`), ensuring the old macro testing engine still has end-to-end CI coverage.
- Create `test/docs/testing_api_drift_test.exs` to mirror the code blocks in `guides/getting_started.md` (similar to existing `troubleshooting_drift_test.exs`).

### 5. Exclusions (Deferred to Phase 66)
**Files to leave alone:**
- `demo/ledger_loop/lib/ledger_loop/fake_idp/*` and related FakeIdP demo controllers. These are explicitly deferred to Phase 66.

## Verification
- Run `mix test` to ensure `testing_api_drift_test.exs` and `testing_demo_test.exs` pass.
- Run `mix ci.docs` to ensure documentation changes don't introduce broken links.
- Run `mix relyra.batteries_included --check` to ensure the generated documentation is in sync.
- Search the codebase using `grep_search` for `TestSupport` and `FakeIdP` to ensure they are completely removed from the targeted adopter guides.