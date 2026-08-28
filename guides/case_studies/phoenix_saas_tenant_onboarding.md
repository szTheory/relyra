# Phoenix SaaS Tenant Onboarding

## Scenario

A Phoenix SaaS app wants one safe Day-1 path for onboarding a new enterprise
tenant. The host team needs to scaffold Relyra, prove a local login with
local testing fixtures, then connect exactly one first-class provider before the tenant is
considered live.

## Exact wiring and config

- Run `mix relyra.install --module MyApp --repo MyApp.Repo`
- Mount the ACS route and any host-specific router seams the installer prints
- Prove the local path first with `Relyra.Testing`
- Pick one first-class provider runbook:
  [Okta](../recipes/okta.md), [Entra](../recipes/entra.md),
  [Google Workspace](../recipes/google_workspace.md), or
  [ADFS](../recipes/adfs.md)
- Keep any non-preset tenant requests under an explicitly labeled
  `custom/generic SAML` path

## Relyra owns

- The preset contract for Okta, Microsoft Entra ID, Google Workspace, and ADFS
- The local-first proof helpers in `Relyra.Testing`
- Strict protocol validation, trust-boundary enforcement, and typed rejection
  behavior

## Host owns

- Tenant provisioning workflow and authorization policy
- Router mounting, session management, and downstream account linking
- Deployment configuration, secrets, and domain ownership

## Failure and recovery

- Failure: the local testing fixtures proof fails before a real provider is involved
  Recovery: stop there and fix the host integration before touching provider
  admin work
- Failure: the provider login fails due to entity ID, ACS, or certificate drift
  Recovery: return to the chosen runbook and reconcile the exact vendor fields
- Failure: a tenant requests an unsupported provider and the team treats it like
  a shipped preset
  Recovery: relabel it as `custom/generic SAML` and scope the extra mapping and
  verification work explicitly

## Evidence

- Passing local proof based on `Relyra.Testing`
- One successful real-provider login for the tenant
- The selected runbook's receipt and host-side configuration notes
