# Documentation Overview

Use this page to navigate Relyra docs by job instead of chasing footers.

## Day-1 — Install and prove

- [Getting Started](getting_started.md) — canonical install, scaffold, and first-login path
- [Batteries Included](batteries_included.md) — proof journey stub (canonical artifact at [BATTERIES_INCLUDED.md](../BATTERIES_INCLUDED.md))

**Proof journey (in order):**

1. Run `mix relyra.install --module MyApp --repo MyApp.Repo` and confirm scaffold files land in the host app.
2. Prove local sign-in with the `Relyra.TestSupport` macro (`setup_saml_connection/2`, `post_saml_response/2`) and stub ACS router — see [Getting Started §3](getting_started.md#3-prove-local-login-with-testsupport).
3. Pick exactly one first-class provider runbook (Okta, Entra, Google Workspace, or ADFS) and finish it end-to-end.

Receipt: host-side test passes with `assert_saml_login/2`, then one hosted IdP login works with a concrete operator receipt.

## Day-2 — Operate in production

- [Production Ecto path](production_ecto_path.md) — migrations, Ecto adapters, and replay-store production wiring
- [Okta runbook](recipes/okta.md)
- [Microsoft Entra ID runbook](recipes/entra.md)
- [Google Workspace runbook](recipes/google_workspace.md)
- [ADFS runbook](recipes/adfs.md)
- [Generic SAML runbook](recipes/generic_saml.md) — Ping, OneLogin, Shibboleth, Keycloak, and more
- [Identity mapping and provisioning](identity_mapping_and_provisioning.md)
- [Troubleshooting](troubleshooting.md)
- [Logout recipe](recipes/logout.md)
- [Operator-managed rollout](case_studies/operator_managed_rollout.md)
- [Phoenix SaaS tenant onboarding](case_studies/phoenix_saas_tenant_onboarding.md)

## Reference

- [BATTERIES_INCLUDED.md](../BATTERIES_INCLUDED.md) — drift-checked claim-to-proof map
- [SECURITY.md](../SECURITY.md)
- [CONFORMANCE.md](../CONFORMANCE.md)
- [Jobs To Be Done And User Flows](jtbd_user_flows.md)
- [Incident playbook](operations/incident_playbook.md)
