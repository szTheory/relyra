# Relyra

Relyra is a strict-by-default **SAML 2.0 Service Provider library for Elixir and Phoenix**.
It is for teams that need enterprise SSO without becoming SAML experts.

## Start Here

Use one Day-1 route:

1. Install the library and scaffold the host app with `mix relyra.install`.
2. Follow [Getting Started](guides/getting_started.md).
3. Prove a local sign-in with `Relyra.TestSupport.FakeIdP`.
4. Choose exactly one first-class provider runbook.
5. Return to the production follow-ons after the first provider is working.

The README is the router. The full onboarding narrative lives in
[guides/getting_started.md](guides/getting_started.md).

If you want the high-level map of what this library is helping you get done,
read [Jobs To Be Done And User Flows](guides/jtbd_user_flows.md) after Getting
Started.

## Batteries Included Support

First-class batteries-included support is limited to:

- Okta
- Microsoft Entra ID
- Google Workspace

In this repo, "batteries included" means the provider has a shipped preset module,
a repo-native runbook, provider-specific field vocabulary, and Day-1 guidance that
ends in a concrete receipt.

Use these runbooks only after you complete the local FakeIdP proof in Getting Started:

- [Okta runbook](guides/recipes/okta.md)
- [Microsoft Entra ID runbook](guides/recipes/entra.md)
- [Google Workspace runbook](guides/recipes/google_workspace.md)

## Custom SAML And Not-Yet-Shipped Providers

- **Custom SAML:** Supported as a generic integration path when you bring your own
  IdP-specific field mapping and operator verification. Start from the canonical
  onboarding flow, then adapt it to your provider's metadata and claim vocabulary.
- **Not yet shipped:** Any provider without a shipped preset module and verified
  runbook is not first-class batteries included support.

Relyra does not claim batteries-included support for providers outside Okta,
Microsoft Entra ID, and Google Workspace.

## What Ships In The Library

- Strict SP-initiated login and ACS validation.
- Hardened XML, signature, and protocol checks.
- Provider presets for Okta, Microsoft Entra ID, and Google Workspace.
- `Relyra.TestSupport` and `Relyra.TestSupport.FakeIdP` for local proof.
- `mix relyra.install` for minimal host-app scaffolding.
- Optional LiveAdmin, metadata lifecycle, certificate lifecycle, telemetry,
  audit seams, scheduled refresh, and diagnostic surfaces for later-stage
  operator workflows.

## What Does Not Ship

- OIDC or OAuth flows.
- A hosted broker runtime.
- SCIM lifecycle ownership.
- First-class batteries-included support for providers beyond Okta,
  Microsoft Entra ID, and Google Workspace.

## Day-2 And Operator Guides

These surfaces matter after Day-1, but they should not compete with onboarding:

- [Getting Started](guides/getting_started.md) for the canonical Day-1 path.
- [Identity Mapping And Provisioning](guides/identity_mapping_and_provisioning.md)
  for the host-owned decision about local account anchors, login-time JIT, and
  the `Relyra.UserMapper` seam after the first provider works.
- [Jobs To Be Done And User Flows](guides/jtbd_user_flows.md) for the
  implementation-level mental model of the adoption and operations journey.
- [Security policy](SECURITY.md) for supported algorithms, disclosure, and
  release posture.
- [Security review packet](SECURITY_REVIEW.md) for auditors and release review.

LiveAdmin is optional. Metadata refresh, certificate rollover, audit review,
telemetry wiring, and diagnostic bundles belong after the first successful
provider login, not before it.
