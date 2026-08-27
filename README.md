<p align="center"><img src="brandbook/assets/readme-banner.svg" alt="Relyra — Enterprise SAML, calmly verified." width="720"></p>

# Relyra

[![Hex.pm](https://img.shields.io/hexpm/v/relyra.svg)](https://hex.pm/packages/relyra)
[![Documentation](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/relyra)
[![CI](https://github.com/szTheory/relyra/actions/workflows/security-gates.yml/badge.svg)](https://github.com/szTheory/relyra/actions/workflows/security-gates.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Elixir](https://img.shields.io/badge/elixir-~>1.19-purple.svg)](https://hexdocs.pm/elixir/compatibility-and-deprecations.html)

Relyra is a strict-by-default **SAML 2.0 Service Provider library for Elixir and Phoenix**.
Requires Elixir **~> 1.19** (see [`mix.exs`](mix.exs)).
It is for teams that need enterprise SSO without becoming SAML experts.

Add the dependency:

```elixir
{:relyra, "~> 1.5"}
```

Published docs: [hexdocs.pm/relyra](https://hexdocs.pm/relyra) — [Getting Started](guides/getting_started.md) is the hexdocs home page; the [README](README.md) is the GitHub evaluator router.

## Quick Look

```elixir
connection =
  Relyra.Provider.apply_defaults(:okta, [
    sp_entity_id: "https://sp.example.com/metadata",
    acs_url: "https://sp.example.com/saml/acs",
    idp_sso_url: "https://example.okta.com/app/.../sso/saml",
    idp_certificates: ["-----BEGIN CERTIFICATE-----..."]
  ])
```

Presets fill safe defaults underneath — see the [Okta runbook](guides/recipes/okta.md) for the full receipt.

## Start Here

Use one Day-1 route:

1. Browse the [documentation overview](guides/overview.md) — Day-1, Day-2, and Reference sections.
2. Install the library and scaffold the host app with `mix relyra.install`.
3. Follow [Getting Started](guides/getting_started.md).
4. Prove a local sign-in with `Relyra.Testing.signed_success/1` and `Relyra.Testing.Phoenix.post_response/5` — see [Getting Started §3](guides/getting_started.md#3-prove-local-login-with-relyratesting).
5. Choose exactly one first-class provider runbook.
6. Return to the production follow-ons after the first provider is working.

The README is the router. The full onboarding narrative lives in
[guides/getting_started.md](guides/getting_started.md).

If you want the high-level map of what this library is helping you get done,
read [Jobs To Be Done And User Flows](guides/jtbd_user_flows.md) after Getting
Started.

## Evaluate The Docker Demo

The LedgerLoop demo is a source-checkout evaluator, not part of the Hex package or the
library's Day-1 installation path. After completing Getting Started, use the
[Docker developer guide](guides/docker_dev_dx.md) for the Make-first Solo/FakeIdP proof.
Fleet and optional Keycloak are follow-on evaluation routes; they do not replace the
deterministic Solo journey.

## Batteries Included Support

Relyra ships **4 first-class presets** plus a **generic SAML runbook** covering **7 IdP families**.

First-class batteries-included support (shipped preset module + verified runbook):

- Okta
- Microsoft Entra ID
- Google Workspace
- ADFS

In this repo, "batteries included" means the provider has a shipped preset module,
a repo-native runbook, provider-specific field vocabulary, and Day-1 guidance that
ends in a concrete receipt.

Use these runbooks only after you complete the local testing proof in Getting Started:

- [Okta runbook](guides/recipes/okta.md)
- [Microsoft Entra ID runbook](guides/recipes/entra.md)
- [Google Workspace runbook](guides/recipes/google_workspace.md)
- [ADFS runbook](guides/recipes/adfs.md)

## Custom SAML And Generic Runbook Providers

- **Generic SAML runbook:** Supported for IdP families without a first-class preset.
  The operator runbook at [guides/recipes/generic_saml.md](guides/recipes/generic_saml.md)
  covers **Ping, OneLogin, Shibboleth, Keycloak, IBM Security Verify, CyberArk, and
  Oracle Access Manager** with vendor decoder tables and field-mapping guidance. Use it
  after the local `Relyra.Testing` proof and before you start translating your provider's
  admin vocabulary.
- **Custom SAML:** Supported when you bring your own IdP-specific field mapping and
  operator verification beyond the generic runbook tables.
- **Not yet shipped:** Any provider without a shipped preset module and verified
  runbook is not first-class batteries-included support.

Relyra does not claim batteries-included support beyond the four first-class presets
and the generic SAML runbook families named above.

## What Ships In The Library

- Strict SP-initiated login and ACS validation.
- Hardened XML, signature, and protocol checks.
- Provider presets for Okta, Microsoft Entra ID, Google Workspace, and ADFS, plus a
  generic SAML runbook for seven additional IdP families.
- `Relyra.Testing` and `Relyra.Testing.Phoenix` for local proof.
- `mix relyra.install` for minimal host-app scaffolding.
- Optional LiveAdmin, metadata lifecycle, certificate lifecycle, telemetry,
  audit seams, scheduled refresh, and diagnostic surfaces for later-stage
  operator workflows.

## What Does Not Ship

- OIDC or OAuth flows.
- A hosted broker runtime.
- SCIM lifecycle ownership.
- First-class batteries-included support for providers beyond the four shipped presets
  and the generic SAML runbook families.

## Day-2 And Operator Guides

These surfaces matter after Day-1, but they should not compete with onboarding:

- [Getting Started](guides/getting_started.md) for the canonical Day-1 path.
- [Production Ecto path](guides/production_ecto_path.md) — cluster-safe stores and migrations.
- [Incident playbook — evidence surfaces](guides/operations/incident_playbook.md#evidence-surfaces) — login trace, telemetry, and audit triage.
- [Troubleshooting](guides/troubleshooting.md) — SAML error atom decoder.
- [Logout recipe](guides/recipes/logout.md) — SLO strategy and session boundaries.
- [Identity Mapping And Provisioning](guides/identity_mapping_and_provisioning.md)
  for the host-owned decision about local account anchors, login-time JIT, and
  the `Relyra.UserMapper` seam after the first provider works.
- [Jobs To Be Done And User Flows](guides/jtbd_user_flows.md) for the
  implementation-level mental model of the adoption and operations journey.
- [Security policy](SECURITY.md) for supported algorithms, disclosure, and
  release posture.
- [Security review packet](SECURITY_REVIEW.md) for auditors and release review.
- [Security boundary](docs/security_boundary.md) for reviewer-oriented architecture notes.
- [LedgerLoop demo app](guides/demo.md) — a runnable reference app, not part of the Hex package,
  showing Relyra embedded in a Phoenix SaaS host with Ecto-backed stores and browser-visible receipts.
- [Docker developer guide](guides/docker_dev_dx.md) — Make-first Solo evaluation, with Fleet and
  optional Keycloak follow-ons for local operator proof.

LiveAdmin is optional. Metadata refresh, certificate rollover, audit review,
telemetry wiring, and diagnostic bundles belong after the first successful
provider login, not before it.
