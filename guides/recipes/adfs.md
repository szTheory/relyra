# Active Directory Federation Services + Relyra

> Tested against: Microsoft Learn AD FS Windows Server 2025 docs verified on May 26, 2026

This is the authoritative Day-1 runbook for the `:adfs` preset. Use it when the IdP requires
signed AuthnRequests or when you need the ADFS lowercase percent-encoding interop path.

## Overview

The ADFS preset turns on the strict settings this path needs:

- `sign_authn_requests: true`
- `signed_request_encoding: :adfs_lower`
- `require_signed_assertions?: true`
- `require_signed_response?: true`
- `algorithm_policy.signing: :rsa_sha256`

ADFS often rejects unsigned AuthnRequests once the relying-party trust is configured to require
them, so keep the preset defaults unless you are deliberately debugging an integration problem.

## SP-side config

Configure the SP signing key in application config and use the preset when building the
connection:

```elixir
config :relyra,
  sp_signing_key_pem: File.read!("priv/certs/sp-signing-key.pem")

connection =
  Relyra.Provider.apply_defaults(:adfs, [
    sp_entity_id: "https://sp.example.com/metadata",
    acs_url: "https://sp.example.com/saml/acs",
    idp_sso_url: "https://adfs.example.com/adfs/ls/",
    idp_certificates: ["-----BEGIN CERTIFICATE-----..."]
  ])
```

Operator-owned values:

- `sp_entity_id`: ADFS calls this the relying party trust identifier.
- `acs_url`: ADFS uses this for the SAML assertion consumer endpoint.
- `idp_sso_url`: usually `https://<adfs-host>/adfs/ls/`.
- `idp_certificates`: load the active token-signing certificate.

## ADFS-side PowerShell

Use the relying-party trust cmdlet parameters verified from Microsoft Learn on May 26, 2026:
`-SignedSamlRequestsRequired`, `-RequestSigningCertificate`, `-SignatureAlgorithm`, and
`-SamlResponseSignature`.

```powershell
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 "C:\path\to\sp-signing.cer"

Set-AdfsRelyingPartyTrust `
  -TargetName "Relyra App" `
  -SignedSamlRequestsRequired $true `
  -RequestSigningCertificate @($cert) `
  -SignatureAlgorithm "https://www.w3.org/2001/04/xmldsig-more#rsa-sha256" `
  -SamlResponseSignature "MessageAndAssertion"
```

Important naming mismatch:

- SAML metadata advertises `AuthnRequestsSigned="true"`.
- PowerShell uses `-SignedSamlRequestsRequired $true`.

These represent the same trust expectation from opposite sides.

## Claim rules

Minimum claim set to start with:

- Name ID
- Email address
- Given name
- Surname
- Display name

Keep the anchor stable. If you change the NameID format or source later, your application may
see a different local identifier for the same user.

## Interop notes

- ADFS can be sensitive to percent-encoded hex casing in redirect queries. The `:adfs` preset
  sets `signed_request_encoding: :adfs_lower` for this reason.
- Relyra signs outbound redirect queries with RSA-SHA256. Do not downgrade to SHA-1.
- `-SignatureAlgorithm` governs what ADFS expects for the outbound AuthnRequest signature. It is
  independent from how Relyra verifies inbound response signatures.
- The redirect signature covers the raw query octets before `&Signature=` is appended. Any
  re-encoding step between the SP core and the browser breaks the signature.

## Troubleshooting

| Symptom | Why it happens | Fix |
| --- | --- | --- |
| ADFS rejects every login immediately | The relying party trust requires signed requests but the SP is sending unsigned bytes | Keep `sign_authn_requests: true` and confirm the signing PEM is configured. |
| Signature mismatch on the IdP side | A proxy or controller rewrote the redirect query | Preserve the query bytes verbatim and avoid any `URI.encode_query` rewrite on the signed path. |
| ADFS accepts metadata but rejects runtime requests | `AuthnRequestsSigned` and the actual redirect behavior drifted apart | Re-export metadata after toggling signing and keep the connection toggle aligned with the trust policy. |
| Login fails after cert rotation | The request-signing certificate in ADFS no longer matches the SP signing key | Update the exported SP signing certificate and rerun `Set-AdfsRelyingPartyTrust`. |

## Provenance

Microsoft Learn sources verified on May 26, 2026:

- `Set-AdfsRelyingPartyTrust (Windows Server 2025)` for parameter names and accepted
  `-SignatureAlgorithm` values.
- `Create a Non-Claims Aware Relying Party Trust` for the relying-party trust creation path.

## Related docs

- [Getting Started](../getting_started.md)
- [Documentation overview](../overview.md)
- [Troubleshooting](../troubleshooting.md)
- [Incident playbook — evidence surfaces](../operations/incident_playbook.md#evidence-surfaces)
