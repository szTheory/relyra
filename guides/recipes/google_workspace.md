# Google Workspace + Relyra

> Tested against: Google Workspace admin console, April 2026

This is the authoritative runbook for the shipped `:google_workspace` preset.
Use it after the local testing fixtures proof so your first hosted-provider exercise is
limited to one Google Workspace path.

## Tested against

- Google Workspace custom SAML app flow
- `Relyra.Provider.GoogleWorkspace`
- `Relyra.Provider.apply_defaults(:google_workspace, ...)`

## Relyra owns

- Safe default assertion/response signing requirements
- Email-style NameID defaults for the preset
- A narrow support claim for the shipped Google Workspace path only

## IdP owns

- The Google Workspace custom SAML app configuration
- `ACS URL`, `SSO URL`, and certificate values from the admin console
- NameID and attribute mapping inside Google Workspace

## Host owns

- The Phoenix ACS route, sessions, and downstream authorization
- Published entity ID, domain, and deployment-specific wiring
- Any application-specific tenant or authorization logic

## 1. Create the custom SAML app

In Google Workspace, create a new custom SAML app and populate the service
provider details:

- **ACS URL**: your ACS endpoint
- **ACS URL** also serves as the label Relyra uses for `sp_entity_id` in this
  preset's operator hints
- **SSO URL**: copy from Google Workspace's IdP details
- **Certificate**: export the current signing certificate
- **Name ID format**: keep an email-style principal unless you have a clear
  reason to deviate

## 2. Configure Relyra

```elixir
connection =
  Relyra.Provider.apply_defaults(:google_workspace, [
    sp_entity_id: "https://sp.example.com/metadata",
    acs_url: "https://sp.example.com/saml/acs",
    idp_sso_url: "https://accounts.google.com/o/saml2/idp?idpid=...",
    idp_certificates: ["-----BEGIN CERTIFICATE-----..."]
  ])
```

Key defaults applied by the preset:

- `allow_idp_initiated?: false`
- `require_signed_assertions?: true`
- `require_signed_response?: true`
- `name_id_format: "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"`
- `algorithm_policy.signing: :rsa_sha256`

## Wire the host app

The Google Workspace preset in §2 gives you a `connection` struct. Before a
real Google Workspace login works, wire that struct into the host application
seams the installer created:

1. **Resolve the connection** — `Relyra.start_login/3` and
   `Relyra.consume_response/3` call your configured `ConnectionResolver`. On a
   single-node dev path, register the struct where your resolver returns it (see
   [Getting Started §2](../getting_started.md#2-scaffold) and the install
   generator output). For production, persist the connection and switch to
   [ConnectionResolver.Ecto](../production_ecto_path.md#4-wire-connectionresolver-ecto).

2. **Use the production ACS route** — After
   [Getting Started §3](../getting_started.md#3-prove-local-login-with-relyratesting)
   passes with `Relyra.Testing`, switch from the stub ACS to the installer's
   `saml_routes()` / `ACSController` path so POSTbacks hit
   `Relyra.consume_response/3`.

3. **Map verified attributes** — Implement `Relyra.UserMapper` to turn the
   verified login result into your host user model ([Identity
   mapping](../identity_mapping_and_provisioning.md)).

Receipt before §3: a browser or integration test hits your ACS URL, the resolver
returns the Google Workspace connection, and `consume_response/3` completes
without a typed rejection.

## 3. Proof of success

Use one concrete receipt:

- A successful login returns through the configured ACS route.
- The configured certificate matches the active certificate exported from Google
  Workspace.
- The NameID maps to a stable email-style principal in the host app.

Proof receipt:

- One successful Google Workspace login after the local testing fixtures proof already
  passed.

## 4. Common failures

| Symptom | Why it happens | Fix |
| --- | --- | --- |
| NameID is unstable | Google Workspace is not returning a stable email-style principal | Map the primary email to NameID and keep the preset default format. |
| Login redirects to the wrong place | ACS or entity configuration drifted | Re-check the ACS endpoint and entity ID values exposed by the host app. |
| Signed response rejected | The configured certificate is stale or wrong | Re-export the active certificate and update `idp_certificates`. |

## 5. Day-2 notes

- Re-check the certificate during rotation or tenant policy changes.
- Keep metadata, auditability, telemetry, scheduled refresh, and diagnostics in
  the production follow-on plan after the first login works.
- Treat any move beyond the shipped preset path as custom/generic SAML, not
  first-class Google Workspace support.

## Related docs

- [Getting Started](../getting_started.md)
- [Documentation overview](../overview.md)
- [Troubleshooting](../troubleshooting.md)
- [Incident playbook — evidence surfaces](../operations/incident_playbook.md#evidence-surfaces)

## Related case studies

- [Phoenix SaaS tenant onboarding](../case_studies/phoenix_saas_tenant_onboarding.md)
- [Operator-managed rollout](../case_studies/operator_managed_rollout.md)
