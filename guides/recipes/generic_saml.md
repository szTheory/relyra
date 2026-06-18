# Generic SAML + Relyra

This is the canonical fallback runbook for IdPs that do not have a shipped Relyra
preset or that need custom operator mapping on top of a vendor admin surface.
Use it only after the local testing fixtures proof in
[Getting Started](../getting_started.md) is green.

Relyra's first-class batteries-included support covers **Okta, Microsoft Entra ID,
Google Workspace, and ADFS** (each has a shipped preset module and verified runbook).
ADFS also has a dedicated runbook at [guides/recipes/adfs.md](adfs.md). All other IdPs
use this generic/custom-SAML path.

## Overview

Use this guide when you already know which IdP you are integrating, but the repo
does not ship a first-class preset for it. The goal is not to make you fluent in
SAML theory. The goal is to help you translate your IdP's admin labels into the
exact Relyra seams that matter for a safe first login.

The safe Day-1 order stays the same:

1. Prove the local trust path with `Relyra.Testing`.
2. Publish your SP metadata from Relyra's real runtime fields.
3. Import or transcribe the IdP metadata Relyra actually consumes.
4. Verify NameID and claim choices before treating the provider as complete.
5. Enable signed requests or encrypted assertions only when the IdP requires them.

Receipt:

- One successful SP-initiated login after the local testing fixtures proof already passed.

## Relyra owns / IdP owns / Host owns

## Relyra owns

- Strict ACS validation, XML parsing, signature verification, and replay checks.
- The SP metadata shape published from `sp_entity_id`, `acs_url`,
  `sign_authn_requests`, and the configured SP certificates.
- Metadata import/apply flow that extracts IdP entity ID, SSO URL, and signing
  certificates from metadata when you use the built-in import path.

## IdP owns

- The IdP admin console labels and the exact vocabulary used for entity IDs,
  ACS URLs, NameID, and claims.
- The active IdP signing certificates and any requirement for signed requests or
  encrypted assertions.
- Claim release policy, NameID source selection, and any org-specific access
  control around the app.

## Host owns

- Phoenix routes, sessions, downstream authorization, and tenant/domain logic.
- The canonical values your app publishes as `sp_entity_id` and `acs_url`.
- Secret management for SP private keys and deployment-specific certificate files.

## SP metadata field reference

Use Relyra's field names as the source of truth, then translate them into your
IdP's labels:

| Relyra seam | What it means | Where it shows up |
| --- | --- | --- |
| `sp_entity_id` | The service provider identifier your IdP will treat as the audience / relying-party identifier | `entityID` on the SP metadata root and the IdP field often labeled `Entity ID`, `Audience URI`, or `Identifier` |
| `acs_url` | The browser POST target for SAML responses | `AssertionConsumerService Location` in SP metadata and the IdP field often labeled `ACS URL`, `Reply URL`, or `Single sign-on URL` |
| `sign_authn_requests` | Whether Relyra signs redirect-binding AuthnRequests | `AuthnRequestsSigned="true"` on the SP metadata and a signing `KeyDescriptor use="signing"` when enabled |
| SP signing cert | The public cert paired with the private key used for signed AuthnRequests | `<md:KeyDescriptor use="signing">` when signing is enabled |
| SP encryption cert | The public cert the IdP should use when it encrypts assertions for your SP | Always published as `<md:KeyDescriptor use="encryption">` |
| Encryption algorithms | The only XML-Enc algorithms the SP advertises as acceptable | `aes256-gcm`, `aes128-gcm`, and `rsa-oaep-mgf1p` inside the encryption `KeyDescriptor` |
| AuthnRequest NameID policy | The NameID format the SP asks for on outbound AuthnRequests | `NameIDPolicy Format="..."`; defaults to `urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified` unless you override it |

Operator notes:

- `AuthnRequestsSigned` is not decorative. In Relyra it follows
  `sign_authn_requests: true`, and `start_login/3` will sign the redirect query only
  when that toggle is on.
- Relyra does not publish private key material in metadata. Only the public signing
  and encryption certificates belong there.
- If your IdP asks which encryption algorithms the SP supports, use the metadata that
  Relyra emits instead of guessing from a generic SAML checklist.

## IdP metadata import checklist

When you import or transcribe IdP metadata into Relyra, make sure you can point to
 these exact values:

- `idp_entity_id`: the IdP's entity identifier from metadata.
- `idp_sso_url`: the SingleSignOnService location Relyra will redirect to.
- IdP signing certificates: the certificate set Relyra trusts for response and
  assertion signatures.
- Metadata source: the XML file or URL you imported from, so later refresh and
  rotation work stays staged and reviewable.
- Feature expectations implied by the metadata or by operator policy: signed
  requests required, encrypted assertions expected, or a particular binding choice.

What Relyra's metadata import path actually consumes today:

- `Relyra.Metadata.Import` extracts the IdP entity ID.
- It chooses the SSO service Relyra will use, preferring HTTP-Redirect, then
  HTTP-POST, then the first remaining SSO service in document order.
- It normalizes every signing certificate into PEM plus a SHA-256 fingerprint for
  staged trust review.
- `Relyra.Ecto.MetadataApply` applies the imported candidate and co-commits the
  metadata audit row inside the same transaction.

If your IdP admin UI does not expose metadata import cleanly, you can still use the
same checklist manually. Do not treat "it looks close enough" as a substitute for
matching entity ID, ACS URL, SSO URL, and certificate trust exactly.

## Vendor decoder tables

These tables are translation help, not preset-backed support claims. Vendor labels
drift. Validate the exact field names in your tenant and treat this section as a
decoder ring for the core Relyra seams above.

### Labels reviewed for this guide

- Runbook authored against operator-facing vendor terminology current in May 2026.
- If your admin surface uses different labels, map the concept back to the Relyra
  seam first, then update the local operator notes.

Seven IdP families named in README (Ping, OneLogin, Shibboleth, Keycloak, IBM Security
Verify, CyberArk, Oracle) — decoder rows below; Shibboleth-specific notes follow the
table.

| Vendor | SP entity / audience label | ACS / reply label | Login URL / SSO label | Signing cert label | Common claim labels | Typical NameID default | Footgun to watch |
| --- | --- | --- | --- | --- | --- | --- | --- |
| IBM Security Verify | `Service provider entity ID` | `Assertion consumer service URL` | `SSO URL` or `Single sign-on service URL` | `Signing certificate` | email, givenName, surname, groups | Often unspecified or email-style | IBM screens can expose several profile/claim layers; verify the effective NameID, not just the mapping editor |
| CyberArk | `Entity ID` or `Audience` | `ACS URL` | `Identity Provider SSO URL` | `Signing certificate` | email, first name, last name, groups | Often email-style | CyberArk app templates can hide claim release defaults behind a separate attribute screen |
| Oracle Access Manager | `SP Entity ID` | `Assertion Consumer Service URL` | `Single Sign-On URL` | `Signing certificate` | mail, givenname, sn, groups/memberOf | Often unspecified | Oracle deployments often have multiple partner profiles; make sure the runtime partner matches the exported metadata |
| PingFederate | `Partner's Entity ID` | `Assertion Consumer Service URL` | `SSO Service URL` or `IdP SSO endpoint` | `Signing certificate` | mail, givenName, sn, memberOf | Often persistent or unspecified | Ping lets admins mix profile data and adapter contracts; verify which source actually feeds NameID. README lists this family as **Ping** — same IdP class; admin UI says PingFederate. |
| CA SiteMinder | `SP Entity ID` | `Assertion Consumer Service URL` | `SSO URL` | `Signing certificate` | mail, givenName, sn, groups | Often unspecified | SiteMinder deployments frequently inherit older policy defaults; reject SHA-1 or lax signing expectations instead of matching them. README lists seven SAML families (Okta, Entra, Google Workspace, ADFS, Ping, CyberArk, Shibboleth); this decoder row documents SiteMinder as an additional admin-UI label — not an eighth README family. |
| Keycloak | `Client ID` or `Entity ID` | `Client authentication / ACS URL` or `Valid redirect URIs` (map to ACS) | `Sign-in URL` or `Master SAML Processing URL` | `Signing certificate` or realm keys export | email, given_name, family_name, groups | Often persistent or email-style | Keycloak realm vs client SAML settings split — verify ACS URL on the client, not just realm metadata |
| OneLogin | `Audience (Entity ID)` | `ACS (Consumer) URL` | `SAML 2.0 Endpoint (HTTP)` | `X.509 Certificate` | Email, First Name, Last Name, Member Of | Often email-style | OneLogin connector vs custom SAML app templates use different label sets — match the connector you created |

For **Shibboleth** (README seventh family), see [Shibboleth-specific notes](#shibboleth-specific-notes) below — no separate decoder row because metadata-exchange-first deployments vary widely.

Common claim decoder:

| Relyra concept | Common attribute names to look for |
| --- | --- |
| Email | `email`, `mail`, `emailAddress`, `user.email` |
| Given name | `givenName`, `firstName`, `given_name` |
| Surname | `sn`, `surname`, `lastName`, `family_name` |
| Groups | `groups`, `memberOf`, `roles` |

## ADFS-specific notes

If you are integrating ADFS, prefer the specialized runbook at
[guides/recipes/adfs.md](adfs.md). Keep the generic path only when you are
translating a custom ADFS deployment and still need the broader decoder-table
guidance from this file.

Why ADFS differs from the default generic path:

- ADFS commonly requires signed AuthnRequests.
- Relyra's ADFS preset uses `signed_request_encoding: :adfs_lower` for
  redirect-query interop.
- The ADFS admin surface talks about relying-party trust settings rather than the
  lighter generic vocabulary used by other vendors.

## Shibboleth-specific notes

Shibboleth frequently appears in environments where operators are comfortable with
metadata exchange but less strict about the runtime expectations that follow from it.
Keep these points explicit:

- If the IdP expects `AuthnRequestsSigned`, turn on `sign_authn_requests` and verify
  the SP metadata advertises the signing `KeyDescriptor` plus
  `AuthnRequestsSigned="true"`.
- Do not assume IdP-initiated flows are harmless convenience paths. Relyra's safe
  posture is still SP-initiated first.
- If the federation demands encrypted assertions, publish the SP encryption cert and
  confirm the IdP is using an algorithm Relyra actually advertises and accepts.

## NameID format decision guide

Choose NameID as an application identity decision, not as an admin-console default:

- `persistent` is the safest anchor when the IdP can issue a stable opaque user
  identifier that survives email changes.
- Email-style NameID is convenient when your app already treats email as the user
  anchor, but it is brittle if addresses can be renamed or recycled.
- `transient` is poor for local account anchoring because it is intentionally not
  stable across sessions.
- `unspecified` means "verify what the IdP actually emits." It is acceptable only if
  you inspect the resulting NameID and confirm it matches your host app's identity
  assumptions.

If you change NameID format after users already exist, treat it as a migration of
your identity anchor, not as a harmless cleanup.

When you are ready to turn those verified NameID or attribute choices into local
lookup, linking, or JIT policy, continue with
[guides/identity_mapping_and_provisioning.md](../identity_mapping_and_provisioning.md).

## When to enable signing and encryption

Treat both of these as trust-boundary requirements, not tuning knobs:

- Enable signed AuthnRequests when the IdP requires them or when the provider's
  relying-party policy explicitly expects signed requests.
- Keep signed assertions and signed responses aligned with the IdP's runtime
  behavior. Relyra's strict path assumes signatures are part of the trust contract,
  not an optional nice-to-have.
- Publish and use the SP encryption certificate when the IdP sends
  `EncryptedAssertion` or requires encrypted assertions as policy.
- Do not enable encryption unless you are ready to manage the separate SP
  encryption certificate lifecycle alongside the signing key lifecycle.

Observable triggers:

- Metadata or admin UI says the IdP requires signed requests.
- The IdP begins sending `EncryptedAssertion`.
- The IdP's security baseline requires separate encryption material for the SP.

## Wire the host app

Your connection struct (from a preset or custom mapping) is not enough on its
own. Before a real IdP login works, wire that struct into the host application
seams the installer created:

1. **Resolve the connection** — `Relyra.start_login/3` and
   `Relyra.consume_response/3` call your configured `ConnectionResolver`. On a
   single-node dev path, register the struct where your resolver returns it (see
   [Getting Started §2](../getting_started.md#2-scaffold) and the install
   generator output). For production, persist the connection and switch to
   [ConnectionResolver.Ecto](../production_ecto_path.md#4-wire-connectionresolver-ecto).

3. **Use the production ACS route** — After
   [Getting Started §3](../getting_started.md#3-prove-local-login-with-relyratesting)
   passes with `Relyra.Testing`, switch from the stub ACS to the installer's
   `saml_routes()` / `ACSController` path so POSTbacks hit
   `Relyra.consume_response/3`.

3. **Map verified attributes** — Implement `Relyra.UserMapper` to turn the
   verified login result into your host user model ([Identity
   mapping](../identity_mapping_and_provisioning.md)).

Receipt before the minimum-safe checklist: a browser or integration test hits
your ACS URL, the resolver returns the connection, and `consume_response/3`
completes without a typed rejection.

## Minimum-safe checklist

- Trust only configured IdP certificates. Do not accept document-provided `KeyInfo`
  as a trust source.
- Keep replay protection enabled in production. ETS is a development story, not the
  cluster-safe production default.
- Keep signed assertions and signed responses enabled unless a provider-specific
  contract proves otherwise.
- Do not weaken algorithm posture to match a legacy IdP casually. Relyra rejects
  SHA-1 by default and blocks CBC content encryption by default.
- Treat SP signing certificates and SP encryption certificates as separate concerns,
  even if one operator currently manages both.
- Keep IdP-initiated login off unless your host app explicitly owns that behavior.

## Debugging flow

Use a fixed order so you do not debug three moving parts at once:

1. `Relyra.Testing` proof: make sure the local trust path already succeeds.
2. Metadata values: verify `sp_entity_id`, `acs_url`, `idp_entity_id`, and
   `idp_sso_url` exactly.
3. Signing certificates: confirm the active IdP signing certs in Relyra match the
   IdP's current metadata or export.
4. NameID and claims: inspect what the IdP is actually releasing before changing app
   mapping code.
5. Signed requests: if the IdP expects `AuthnRequestsSigned`, verify
   `sign_authn_requests`, the signing cert, and the redirect-query path.
6. Encrypted assertions: only after the earlier steps pass, verify that the IdP is
   encrypting to the SP certificate Relyra publishes and that the runtime path is
   intentionally using `EncryptedAssertion`.
7. Rotation drift: if something used to work, compare current metadata, certificate
   fingerprints, and recent metadata apply history before changing toggles.

Useful safe surfaces:

- Connection fields such as `sp_entity_id`, `acs_url`, `idp_entity_id`, and
  `idp_sso_url`.
- Metadata revision and certificate fingerprints from the staged import/apply flow.
- Diagnostic exports that intentionally exclude PEM bodies and private keys.

## Certificate rotation

Treat IdP signing-certificate rotation and SP certificate rotation as separate trust
paths.

For IdP signing-certificate rotation:

1. Refresh or import the new IdP metadata into Relyra.
2. Review the staged candidate: entity ID, SSO URL, and certificate fingerprints.
3. Apply the revision so the trust mutation and audit row land in the same
   transaction.
4. Verify overlap before removing the old cert if the IdP is still in a transition
   window.

For SP signing or encryption certificate rotation:

1. Update the configured public certificate and matching private-key material in the
   host environment.
2. Re-publish SP metadata so the IdP sees the new signing or encryption certificate.
3. Coordinate with the IdP operator if they pin the SP certificate manually instead
   of consuming metadata updates.

Do not describe rotation as "swap the cert and try again." Relyra already has a
staged metadata/apply model so operators can review the next trust state before it
becomes active.
