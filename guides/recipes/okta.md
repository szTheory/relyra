# Okta + Relyra

> Tested against: Okta SAML app UI, April 2026

This is the authoritative Day-1 runbook for the Okta preset. Start here only
after the local `FakeIdP` proof in [Getting Started](../getting_started.md) is
green.

## Tested against

- Okta SAML 2.0 app integration flow
- `Relyra.Provider.Okta`
- `Relyra.Provider.apply_defaults(:okta, ...)`

## Relyra owns

- Strict SP-initiated defaults for the Okta preset
- Signed assertion and signed response requirements
- Safe default `Name ID format` and SHA-256 algorithm policy
- Operator-facing footgun checks for SHA-1 signing and unnecessary
  IdP-initiated flows

## IdP owns

- The Okta application integration
- The exact `Audience URI (SP Entity ID)` and `Single sign-on URL` values
- The active signing certificate exported from the Okta admin surface
- Claim mapping and any org-specific access policy around the app

## Host owns

- Phoenix router wiring, session behavior, and downstream authorization
- The app's canonical ACS URL and service-provider entity ID
- Secret management, deployment, and domain ownership

## 1. Create the SAML app in Okta

In Okta, create a new **SAML 2.0** app integration and populate the vendor
fields Relyra expects:

- **Audience URI (SP Entity ID)**: your `sp_entity_id`
- **Single sign-on URL**: your ACS URL
- **Name ID format**: leave **Unspecified** unless you have a strong reason to
  change it
- **Signature Algorithm**: keep **RSA-SHA256**
- **X.509 Certificate**: download the active SHA-256 signing certificate

Okta vocabulary matters here because Relyra's preset hints and operator
messages use these exact labels.

## 2. Configure Relyra

Use the preset so the safe defaults stay aligned with the library's Okta
contract:

```elixir
connection =
  Relyra.Provider.apply_defaults(:okta, [
    sp_entity_id: "https://sp.example.com/metadata",
    acs_url: "https://sp.example.com/saml/acs",
    idp_sso_url: "https://example.okta.com/app/.../sso/saml",
    idp_certificates: ["-----BEGIN CERTIFICATE-----..."]
  ])
```

Key defaults applied by the preset:

- `allow_idp_initiated?: false`
- `require_signed_assertions?: true`
- `require_signed_response?: true`
- `name_id_format: "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified"`
- `algorithm_policy.signing: :rsa_sha256`

## Wire the host app

The preset in §2 gives you a `connection` struct. Before a real Okta login
works, wire that struct into the host application seams the installer created:

1. **Resolve the connection** — `Relyra.start_login/3` and
   `Relyra.consume_response/3` call your configured `ConnectionResolver`. On a
   single-node dev path, register the struct where your resolver returns it (see
   [Getting Started §2](../getting_started.md#2-scaffold) and the install
   generator output). For production, persist the connection and switch to
   [ConnectionResolver.Ecto](../production_ecto_path.md#4-wire-connectionresolver-ecto).

2. **Use the production ACS route** — After
   [Getting Started §3](../getting_started.md#3-prove-local-login-with-testsupport)
   passes with TestSupport, switch from the stub ACS to the installer's
   `saml_routes()` / `ACSController` path so POSTbacks hit
   `Relyra.consume_response/3`.

3. **Map verified attributes** — Implement `Relyra.UserMapper` to turn the
   verified login result into your host user model ([Identity
   mapping](../identity_mapping_and_provisioning.md)).

Receipt before §3: a browser or integration test hits your ACS URL, the resolver
returns the Okta connection, and `consume_response/3` completes without a typed
rejection.

## 3. Proof of success

Use one concrete receipt before treating the provider path as complete:

- A successful SP-initiated login returns to your host app through the ACS
  route you configured.
- The configured `sp_entity_id` exactly matches Okta's
  **Audience URI (SP Entity ID)**.
- The active signing certificate in Relyra matches the one exported from Okta.

Proof receipt:

- A real Okta login succeeds after the local `FakeIdP` proof already passed.

## 4. Common failures

| Symptom | Why it happens | Fix |
| --- | --- | --- |
| Audience mismatch | Okta's **Audience URI (SP Entity ID)** does not exactly match `sp_entity_id` | Make the values identical, including trailing slash behavior. |
| Signed response rejected | The wrong Okta certificate or a stale certificate is configured | Export the active **X.509 Certificate** again and update `idp_certificates`. |
| Login works in dev but not prod | Signing policy drifted to SHA-1 or another weak default | Keep **Signature Algorithm** on RSA-SHA256 and preserve the preset defaults. |
| IdP-initiated login is flaky | The preset is intentionally optimized for SP-initiated flows | Leave `allow_idp_initiated?` disabled unless you are explicitly supporting that flow. |

## 5. Day-2 notes

- Re-check the active signing certificate during rotation events.
- Treat any move toward IdP-initiated login as a deliberate product decision,
  not a convenience toggle.
- Keep metadata, audit review, telemetry, and diagnostic-bundle handling in the
  host application's production follow-on plan.

## Related docs

- [Getting Started](../getting_started.md)
- [Documentation overview](../overview.md)
- [Troubleshooting](../troubleshooting.md)
- [Incident playbook — evidence surfaces](../operations/incident_playbook.md#evidence-surfaces)

## Related case studies

- [Phoenix SaaS tenant onboarding](../case_studies/phoenix_saas_tenant_onboarding.md)
  at `guides/case_studies/phoenix_saas_tenant_onboarding.md`
- [Operator-managed rollout](../case_studies/operator_managed_rollout.md)
  at `guides/case_studies/operator_managed_rollout.md`
