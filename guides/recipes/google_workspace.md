# Google Workspace + Relyra

> Tested against: Google Workspace admin console, April 2026

## 1. Create the SAML app

- Create a new custom SAML app.
- Set the **ACS URL** to your Relyra ACS endpoint.
- Set the app's audience / entity ID to your Relyra `sp_entity_id`.
- Upload the IdP certificate if you are using a custom signing chain.

## 2. Configure Relyra

```elixir
connection = Relyra.Provider.apply_defaults(:google_workspace, [
  sp_entity_id: "https://sp.example.com/metadata",
  acs_url: "https://sp.example.com/saml/acs",
  idp_sso_url: "https://accounts.google.com/o/saml2/idp?idpid=...",
  idp_certificates: ["-----BEGIN CERTIFICATE-----..." ]
])
```

## 3. Common issues

| Symptom | Fix |
| --- | --- |
| NameID is unstable | Map the primary email to the NameID field. |
| Login redirects to the wrong place | Re-check ACS URL and audience. |
| Signed response rejected | Verify the cert chain you uploaded is current. |
