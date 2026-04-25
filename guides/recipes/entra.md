# Microsoft Entra ID + Relyra

> Tested against: Microsoft Entra admin center, April 2026

## 1. Create the enterprise app

- Add a new enterprise application.
- Open **Single sign-on** and choose **SAML**.
- Set **Identifier (Entity ID)** to your Relyra `sp_entity_id`.
- Set **Reply URL (Assertion Consumer Service URL)** to your ACS URL.

## 2. Configure Relyra

Use the Entra preset so the NameID and label hints match what the UI expects:

```elixir
connection = Relyra.Provider.apply_defaults(:entra, [
  sp_entity_id: "https://sp.example.com/metadata",
  acs_url: "https://sp.example.com/saml/acs",
  idp_sso_url: "https://login.microsoftonline.com/.../saml2",
  idp_certificates: ["-----BEGIN CERTIFICATE-----..." ]
])
```

## 3. Common issues

| Symptom | Fix |
| --- | --- |
| Email claim is missing | Keep the preset NameID format and map claims explicitly. |
| Audience mismatch | Entra expects the exact Entity ID string. |
| Response rejected | Confirm the certificate is the active signing cert. |
