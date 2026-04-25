# Phase 6: Delivery Hardening and Adoption Surface

**Goal**: Finalize the adoption surface with provider presets, local dev environment, security corpus, and installer.

## Plans

### 06-01: Provider Presets and Recipes
- Implement `Relyra.Provider` preset logic.
- Add structured presets for: Okta, Microsoft Entra ID, Google Workspace.
- Presets include: Label translations (e.g. "Audience URI" -> `sp_entity_id`), default signing/algorithm policies, and guide links.
- Create `guides/recipes/` markdown files for each provider.

### 06-02: Keycloak Dev Container
- Add `test/fixtures/idp/keycloak/` with `docker-compose.yml`.
- Include seed realm `relyra-dev.json` with pre-configured SP client and test users.
- Add `guides/getting_started.md` with "Local SSO Dev" section using the container.

### 06-03: Security Regression Corpus
- Finalize `test/fixtures/security/` with named CVE fixtures (XXE, XSW, SHA-1, etc.).
- Implement `ci.security` task that replays the corpus.
- Ensure every security fix from previous phases has a permanent fixture.

### 06-04: Installer and TestSupport DX
- Implement `mix relyra.install` task using Igniter pattern.
- Generate behaviour skeletons and config stubs.
- Implement `Relyra.TestSupport` with `setup_saml_connection/1`, `post_saml_response/3`, and `assert_saml_*` helpers.
- Implement `Relyra.TestSupport.FakeIdP` for local unit testing without Docker.

## Success Criteria
1. Provider presets are operational and drive error/admin labels.
2. `mix ci.security` suite is green and covers known-CVE fixtures.
3. `mix relyra.install` generates a byte-identical "golden tree" in tests.
4. Adopters can write a full SSO integration test in < 10 lines of code using `TestSupport`.
5. `SECURITY.md` and `README.md` (scope-first) are finalized.

## Routing
- Start with 06-01 execution.
