# Microsoft Entra ID + Relyra

> Tested against: Microsoft Entra admin center, April 2026

This runbook is for the shipped `:entra` preset only. Finish the local
`FakeIdP` proof first, then use this document to land one real-provider login in
Microsoft Entra ID.

## Tested against

- Microsoft Entra admin center SAML setup flow
- `Relyra.Provider.Entra`
- `Relyra.Provider.apply_defaults(:entra, ...)`

## Relyra owns

- Safe preset defaults for signed assertions and signed responses
- A default persistent NameID posture
- Operator hints that use Entra's exact field names
- Footgun checks for non-persistent NameID values and casual IdP-initiated use

## IdP owns

- The Enterprise Application and SAML setup inside Entra
- `Identifier (Entity ID)`, `Reply URL (Assertion Consumer Service URL)`, and
  certificate export values
- Entra attribute and claim mapping behavior

## Host owns

- Phoenix routes, session handling, and downstream authorization semantics
- The canonical ACS URL and entity ID values published by the host app
- Deployment, domain, and secret-management concerns

## 1. Create the enterprise application

In Microsoft Entra ID:

- Add a new **Enterprise Application**
- Open **Single sign-on**
- Choose **SAML**
- Set **Identifier (Entity ID)** to your `sp_entity_id`
- Set **Reply URL (Assertion Consumer Service URL)** to your ACS URL
- Copy the **Login URL**
- Export the **Certificate (Base64)** from the **SAML Signing Certificate**
  area

Keep Entra's field names intact in operator notes so support and debugging stay
aligned with the preset hints.

## 2. Configure Relyra

Use the preset so the NameID and algorithm defaults stay constrained:

```elixir
connection =
  Relyra.Provider.apply_defaults(:entra, [
    sp_entity_id: "https://sp.example.com/metadata",
    acs_url: "https://sp.example.com/saml/acs",
    idp_sso_url: "https://login.microsoftonline.com/.../saml2",
    idp_certificates: ["-----BEGIN CERTIFICATE-----..."]
  ])
```

Key defaults applied by the preset:

- `allow_idp_initiated?: false`
- `require_signed_assertions?: true`
- `require_signed_response?: true`
- `name_id_format: "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent"`
- `algorithm_policy.signing: :rsa_sha256`

## 3. Proof of success

Use one hard receipt:

- A successful SP-initiated login returns from Entra to the ACS route.
- `Identifier (Entity ID)` and `sp_entity_id` match exactly.
- The exported **Certificate (Base64)** is the same certificate Relyra trusts.

Proof receipt:

- One successful real-provider login after the local `FakeIdP` proof already
  passed.

## 4. Common failures

| Symptom | Why it happens | Fix |
| --- | --- | --- |
| Email claim is missing or unstable | The NameID or claim mapping drifted away from the preset's safest posture | Keep the preset's persistent NameID default and map claims explicitly in Entra. |
| Audience mismatch | `Identifier (Entity ID)` and `sp_entity_id` are not identical | Make the strings match exactly. |
| Response rejected | The wrong signing certificate was copied or rotation was incomplete | Re-export the active **Certificate (Base64)** and update the connection. |
| IdP-initiated flow behaves unexpectedly | Entra can expose login paths the preset does not assume by default | Keep `allow_idp_initiated?` disabled unless your app intentionally supports it. |

## 5. Day-2 notes

- Revisit claims mapping whenever tenant identity attributes change.
- Re-check the signing certificate during rollover windows.
- Fold metadata, certificate lifecycle, audit review, telemetry, scheduled
  refresh, and diagnostic exports into the host app's production follow-on
  checklist.

## Related docs

- [Getting Started](../getting_started.md)
- [Documentation overview](../overview.md)
- [Troubleshooting](../troubleshooting.md)
- [Incident playbook — evidence surfaces](../operations/incident_playbook.md#evidence-surfaces)

## Related case studies

- [Phoenix SaaS tenant onboarding](../case_studies/phoenix_saas_tenant_onboarding.md)
- [Operator-managed rollout](../case_studies/operator_managed_rollout.md)
