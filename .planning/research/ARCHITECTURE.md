# Architecture Research: v1.7 Adoption Evidence Demo

**Project:** Relyra v1.7 — Adoption Evidence Demo
**Researched:** 2026-06-12
**Confidence:** HIGH

## Architectural Stance

Build a single conventional Phoenix app at `demo/ledger_loop`. Keep Relyra as a library dependency. Keep all product-specific customer setup, tenant lifecycle, user mapping, and session policy in the host app.

This is the least surprising shape for Phoenix adopters: contexts own app logic, routes expose workflows, Ecto stores durable state, and the library plugs into explicit seams.

## Bounded Contexts

### `LedgerLoop.Organizations`

Owns tenants and memberships.

Minimum schemas:

- `organizations`
- `users`
- `memberships`

### `LedgerLoop.Accounts`

Owns demo users and session-facing identity.

Minimum behavior:

- Lookup user by SAML identity anchor.
- Create/link demo users when seeded or explicitly allowed.
- Expose current user/current organization for LiveView scopes.

### `LedgerLoop.SSO`

Owns host-specific SSO setup and Relyra integration.

Minimum schemas/tables:

- `saml_identities`: organization, user, connection, anchor type/value.
- `relyra_request_intents`: relay state, request ID, intent, consumed timestamp, expiry.
- `relyra_replay_keys`: replay key, inserted timestamp, metadata.
- Optional `demo_saml_sessions` if showing SLO/session linkage.

Minimum modules:

- `LedgerLoop.Relyra.ConnectionResolver`
- `LedgerLoop.Relyra.RequestStore`
- `LedgerLoop.Relyra.ReplayStore`
- `LedgerLoop.Relyra.UserMapper`
- `LedgerLoop.Relyra.SessionAdapter`
- `LedgerLoop.Relyra.ScopeProvider`

### `LedgerLoop.DemoData`

Owns deterministic reset and seed scenarios:

- Northstar happy-path connection.
- Draft/missing-metadata connection.
- Staged certificate rollover scenario.
- Invalid audience/support trace scenario.
- Optional Keycloak connection.

## Relyra Integration

Use existing Relyra APIs and avoid copying internals:

- Run Relyra's shipped migrations from dependency path; do not copy them into demo app migrations.
- Use `Relyra.Ecto.Connections`, `MetadataApply`, `CertificateInventory`, and `MappingCommands` where possible for trust data.
- Mount SAML routes under `/saml`.
- Mount LiveAdmin under `/relyra/admin` with `repo:` and `scope_provider:`.

## Store Contracts

The demo should use thin wrapper modules with fixed table names:

- `LedgerLoop.Relyra.RequestStore` delegates to `Relyra.RequestStore.Ecto` with `repo: LedgerLoop.Repo, table: "relyra_request_intents"`.
- `LedgerLoop.Relyra.ReplayStore` delegates to `Relyra.ReplayStore.Ecto` with `repo: LedgerLoop.Repo, table: "relyra_replay_keys"`.

Never derive Ecto table names from request params or connection IDs.

## Session Handling

The host app owns session establishment. If the mounted ACS path needs to mutate Phoenix session, use a narrow request-scoped plug/adapter pattern. Do not store `Plug.Conn` or pass it to async work.

If the demo shows SLO linkage, persist session index mapping explicitly. Relyra does not own the host session system.

## FakeIdP Boundary

Provide a dev/test-only local IdP route:

```text
/dev/idp/:connection_id/sso
```

This route may wrap `Relyra.TestSupport.FakeIdP` only outside production. It should parse only enough of Relyra's emitted AuthnRequest to mirror `InResponseTo`, then sign through the real test XMLDSig signer and auto-submit a browser POST to ACS.

## Keycloak Boundary

Keycloak stays optional:

- Compose profile.
- Dedicated CI job/tag.
- Browser-visible ACS using localhost port.
- Readiness checks before browser E2E.

The existing ConnTest Keycloak lane remains lower-level interop evidence; v1.7 adds browser-launched app proof only after core demo is stable.

## UI Architecture

Host demo pages own:

- Workspace home.
- Tenant SSO setup task list.
- Setup receipt.
- Login receipt.
- Support scenario pages.

Relyra LiveAdmin owns:

- Operator trust-state workflows.
- Metadata/cert/mapping/audit/trace surfaces.

Use function components, attrs/slots, URL-driven state, and scoped context calls. Avoid stuffing business rules into LiveViews.

## Roadmap Implication

Build order should be:

1. Scaffold runnable demo app and package boundary.
2. Add Ecto/Relyra store integration and deterministic seeds.
3. Add host setup + mounted LiveAdmin workflow.
4. Add FakeIdP in-browser login proof.
5. Add Docker/script/CI/browser receipts.
6. Add optional Keycloak proof and docs polish.

This order proves the foundation before the UI and optional external IdP layers.
