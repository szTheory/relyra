# Getting Started

## Testing against a real IdP

Relyra ships `Relyra.TestSupport.FakeIdP` for unit and integration tests.
It signs real SAML responses with real keys, so it is the default first
choice for local development.

For a manual smoke test against a hosted IdP, use one of these:

- [Mock SAML](https://mocksaml.com) for quick checks without setup.
- A local Keycloak instance if you want to exercise a real admin UI.
  We do not vendor a Keycloak realm in the core library.

If you are integrating with Okta, Microsoft Entra ID, or Google Workspace,
start with the provider recipes in `guides/recipes/`.
