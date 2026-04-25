# Okta + Relyra

> Tested against: Okta SAML app UI, April 2026

## 1. Create the SAML app

- In Okta, create a SAML 2.0 app integration.
- Set **Audience URI (SP Entity ID)** to your Relyra `sp_entity_id`.
- Set **Single sign-on URL** to your ACS URL.
- Download the active **X.509 Certificate**.

## 2. Configure Relyra

Use the Okta preset to get safe defaults:

```elixir
connection = Relyra.Provider.apply_defaults(:okta, [
  sp_entity_id: "https://sp.example.com/metadata",
  acs_url: "https://sp.example.com/saml/acs",
  idp_sso_url: "https://example.okta.com/app/.../sso/saml",
  idp_certificates: ["-----BEGIN CERTIFICATE-----..." ]
])
```

## 3. Common issues

| Symptom | Fix |
| --- | --- |
| Audience mismatch | Make sure **Audience URI (SP Entity ID)** matches exactly. |
| Login works in dev but not prod | Keep SHA-256 signing enabled. |
| IdP-initiated login is flaky | Prefer SP-initiated flow first. |
