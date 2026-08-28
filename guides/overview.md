# Documentation Overview

Use this page to navigate Relyra docs by job instead of chasing footers.

## Day-1 — Install and prove

- [Getting Started](getting_started.md) — canonical install, scaffold, and first-login path
- [Batteries Included proof map](../BATTERIES_INCLUDED.md) — drift-checked claim-to-proof artifact

**Proof journey (in order):**

1. Run `mix relyra.install --module MyApp --repo MyApp.Repo` and confirm scaffold files land in the host app.
2. Prove local sign-in with `Relyra.Testing` data-first helpers and stub ACS router — see [Getting Started §3](getting_started.md#3-prove-local-login-with-relyratesting).
3. Pick exactly one first-class provider runbook and finish it end-to-end:
   - [Okta](recipes/okta.md)
   - [Microsoft Entra ID](recipes/entra.md)
   - [Google Workspace](recipes/google_workspace.md)
   - [ADFS](recipes/adfs.md)
   - [Generic SAML](recipes/generic_saml.md) — Ping, OneLogin, Shibboleth, Keycloak, and more

Receipt: host-side test passes with standard Phoenix `conn` assertions, then one hosted IdP login works with a concrete operator receipt.

## Day-2 — Operate in production

- [Production Ecto path](production_ecto_path.md) — migrations, Ecto adapters, and replay-store production wiring
- [Incident playbook — login trace & evidence surfaces](operations/incident_playbook.md#evidence-surfaces) — per-login step timeline (`mix relyra.trace` / LiveView) for Diagnose steps in SAML incidents
- [Identity mapping and provisioning](identity_mapping_and_provisioning.md)
- [Troubleshooting](troubleshooting.md)
- [Logout recipe](recipes/logout.md)
- [Operator-managed rollout](case_studies/operator_managed_rollout.md)
- [Phoenix SaaS tenant onboarding](case_studies/phoenix_saas_tenant_onboarding.md)

## Reference

- [BATTERIES_INCLUDED.md](../BATTERIES_INCLUDED.md) — drift-checked claim-to-proof map
- [SECURITY.md](../SECURITY.md)
- [Security review packet](../SECURITY_REVIEW.md)
- [Security boundary](../docs/security_boundary.md)
- [CONFORMANCE.md](../CONFORMANCE.md)
- [Jobs To Be Done And User Flows](jtbd_user_flows.md)
