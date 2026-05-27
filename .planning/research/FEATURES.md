# Feature Research

**Domain:** SAML 2.0 SP Library — v1.3 Advanced Federation (Elixir/Phoenix)
**Researched:** 2026-05-25
**Confidence:** HIGH (encryption/signing spec behavior), MEDIUM (IdP-specific quirks), HIGH (security rationale)

---

## Scope Clarification: EncryptedAssertion vs EncryptedAttribute

> **Historical — superseded by v1.3 ship scope:** v1.3 shipped `EncryptedAssertion`
> decryption only. The `EncryptedAttribute` discussion below informed early research but
> is not part of the verified ENC-01 delivery.

These are two distinct XML-Enc targets that are frequently conflated.

**`EncryptedAssertion`** wraps the entire `<saml:Assertion>` element. The entire assertion blob —
including NameID, AttributeStatement, AuthnStatement, Conditions, and any Signature — is replaced
by a single `<saml:EncryptedAssertion>` node. This is assertion-level encryption. All major
enterprise IdPs (Entra ID, Okta, Shibboleth, ADFS) support this. It is the primary target for
v1.3 (ENC-01).

**`EncryptedAttribute`** wraps individual `<saml:Attribute>` elements inside an unencrypted
assertion. Attribute-level encryption is a distinct operation: the assertion itself is signed and
parseable in the clear; only specific attributes are opaque. Support is patchy — Elastic Search
decrypts both but treats missing `EncryptedAttribute` decryption as non-fatal (processes plaintext
attributes instead). Shibboleth SP3 supports it; Okta does not widely document it. The
investigation thread recommends handling both in v1.3 since the pipeline is shared ("same
pipeline; smaller effort than a separate milestone").

**For v1.3 research, both targets were considered**; **shipped scope is
`EncryptedAssertion` only** (see `.planning/milestones/v1.3-REQUIREMENTS.md` ENC-01).

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features enterprise adopters assume exist when they learn Relyra advertises "encrypted
assertions" or "signed requests."

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **EncryptedAssertion decryption: RSA-OAEP + AES-GCM** | Every major IdP that can encrypt uses OAEP key transport + GCM (or CBC) content encryption. An SP that cannot decrypt is simply unusable with those IdPs. | HIGH | Requires KeyResolver behaviour, OAEP via `:public_key.decrypt_private/3`, AES-GCM via `:crypto.crypto_one_time_aead/6`. Both are in Erlang stdlib — no native deps needed. |
| **SP decryption cert in SP metadata (`KeyDescriptor use="encryption"`)** | IdPs read SP metadata to learn *which* public key to encrypt to. If the SP metadata has no encryption KeyDescriptor, IdPs cannot encrypt: Entra ID raises `AADB2C90164` (key descriptor missing error). This is not optional. | LOW | Metadata endpoint already exists. Extend to publish `use="encryption"` block when a decryption cert is configured. |
| **Decrypt-then-reparse through the hardened saxy seam** | Decrypting an assertion produces raw XML bytes. Those bytes must be re-parsed via the same hardened path (DTD/entity disabled, size-limited, single parse path) — never read fields from a decrypted-but-unverified buffer. Post-decrypt XSW4 attacks can be applied to decrypted content; re-parsing through the secure seam catches them. | MEDIUM | Pipeline gate: `decrypt_assertion/3` → `PureBeam.parse_safely/2` → existing `do_verify` path. Never shortcut this. |
| **Opaque `:decryption_failed` error for all decryption failures** | Padding oracle attacks (Jager–Somorovsky 2011 AES-CBC, Compass Security 2021 SAML variant) require distinguishing decryption error types. A single opaque error atom closes the oracle. Libraries that leak error detail (wrong padding vs wrong key vs bad ciphertext) are exploitable. | LOW | Single atom `:decryption_failed` for everything. No sub-codes in public API. |
| **Signed AuthnRequests for HTTP-Redirect binding** | ADFS requires signed AuthnRequests in most installations and it is notoriously difficult to disable. Shibboleth IdP enforces it when SP metadata has `AuthnRequestsSigned="true"`. Entra ID supports it (opt-in, RSA-SHA256 only). Any SP targeting these IdPs without signed requests gets a hard rejection. | HIGH | Sign the raw query-string octets `SAMLRequest=...&RelayState=...&SigAlg=...`. Never re-serialize. This is the critical footgun. |
| **`AuthnRequestsSigned="true"` in SP metadata when signing is enabled** | IdPs read the SP's `SPSSODescriptor` to decide whether to enforce signing on inbound requests. Shibboleth reads this and enforces it. Entra reads `Require Verification certificates`. Publishing the flag aligns the SP's declared intent with its actual behavior. | LOW | `sign_authn_requests: true` on the connection should publish the flag in SP metadata. |
| **Per-connection `sign_authn_requests` toggle (default: false)** | Signing is not universally required. Okta, Google Workspace, and most SaaS IdPs do not require it. Making it a per-connection opt-in avoids breaking existing connections. ADFS and Shibboleth presets can enable it by default. | LOW | Additive. Backward-compatible. No existing connection is affected. |
| **SP signing cert in SP metadata (`KeyDescriptor use="signing"`) when signing is enabled** | Entra ID and Shibboleth verify the signature against the public key published in SP metadata. If the key is absent from metadata, verification fails. | LOW | Same metadata-extension point as the encryption KeyDescriptor. Publish when `sign_authn_requests: true`. |

### Differentiators (Competitive Advantage)

These go beyond table stakes and directly express Relyra's "strict-by-default, explainable by
default" positioning.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **AES-CBC and RSA-PKCS1v1.5 rejection via AlgorithmPolicy** | Legacy encryption defaults are exploitable. AES-CBC is subject to Jager–Somorovsky padding oracle. RSA-PKCS1v1.5 is subject to Bleichenbacher. Rejecting them by default and requiring explicit time-boxed escape hatches (same pattern as SHA-1) is the correct security posture — no other Elixir SAML library does this. | LOW | Extend existing `AlgorithmPolicy`. Add `unsupported_key_transport_algorithm` and `unsupported_content_encryption_algorithm` error atoms. Same escape-hatch override API as SHA-1. |
| **`EncryptedAttribute` handled alongside `EncryptedAssertion`** | Attribute-level encryption is in the SAML spec and shipped by Shibboleth IdP. Most SP libraries handle only `EncryptedAssertion`. Handling both with the same pipeline is a completeness signal to enterprise evaluators from academia and federated-research environments. | LOW | Same decrypt pipeline, different attachment point. Marginal effort. |
| **Adversarial corpus for all encryption attack scenarios** | Production-safe confidence that the padding oracle is closed, XSW4 is caught post-decrypt, and algorithm policy rejects known-bad modes. This is a documented, citable claim for security-conscious evaluators. | MEDIUM | Six corpus fixtures (see investigation thread). Wired into `mix ci.security`. |
| **ADFS provider preset with `sign_authn_requests: true` default** | ADFS is the last major enterprise IdP without a Relyra preset. The primary reason it could not ship earlier was the absence of signed AuthnRequest support. Shipping the preset alongside the feature makes the feature immediately usable for the largest Windows-shop audience. | MEDIUM | Preset pattern is already established. Needs ADFS-specific claim-rule decoder table, NameID format guidance (Unspecified → email transform), and the `WantAuthnRequestsSigned` toggle. |
| **SP signing key injected at runtime (`sp_signing_key:` config), never stored in Ecto schema** | Keeps private key material off the database schema and diagnostic surfaces that are hardened around public material only. Libraries that store private keys in DB rows (or worse, log them) are a latent breach path. | LOW | Runtime config only. Same discipline as existing `idp_certificates` design (public material only in DB). |
| **KeyResolver behaviour for decryption key (PEM default + KMS extension point)** | PEM config covers >95% of adopters. KMS stub as a documented extension point covers enterprise teams that cannot store private keys in filesystem config. The behaviour boundary means v1.4+ can add a real KMS adapter without changing the pipeline. | MEDIUM | New behaviour, analogous to existing `ReplayStore`. PEM default ships in v1.3; KMS stub is a documented extension point. |
| **Footgun warning in dev when connection config targets a signing-required IdP but `sign_authn_requests: false`** | ADFS silently rejects unsigned requests with a generic error. A dev-mode warning that "this IdP preset (`adfs`) typically requires signed AuthnRequests" saves hours of debugging. | LOW | Check `provider_preset: :adfs` + `sign_authn_requests: false` at connection validation time. Warning in dev, no-op in prod. |
| **Generic SAML runbook as first-class peer of preset runbooks** | The existing runbooks (okta.md, entra_id.md, google_workspace.md) cover named presets. Teams connecting non-preset IdPs (IBM Security Verify, CyberArk, CA SiteMinder, custom Shibboleth deployments, Oracle Access Manager) have no guide. A generic runbook with field-name decoder tables closes this gap for the long tail. | LOW | Documentation. High adopter value, low implementation cost. |
| **Identity mapping guide with explicit SCIM non-goal and JIT decision tree** | The single most confusing day-2 question after SSO works: "How do I get attributes into my user record, and should I use JIT or SCIM?" A structured guide with a decision tree prevents adopters from implementing broken patterns (e.g., using email as the stable NameID anchor when it changes, or enabling JIT and SCIM simultaneously). | LOW | Documentation. Relyra's `UserMapper` behaviour already implements JIT; the guide explains when to use it. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| **Accepting AES-CBC for EncryptedAssertion** | Legacy IdPs and some Shibboleth installations default to AES-128-CBC. Teams want "it just works." | AES-CBC in XML-Enc is subject to the Jager–Somorovsky 2011 padding oracle (XMLENC spec updated in response). Any SP that accepts it without opaque error handling is potentially exploitable. Compass Security demonstrated a practical SAML variant in 2021. | Use the `legacy_algorithm_policy` escape hatch with a mandatory expiry date, reason string, and audit log — same as SHA-1. Never accept by default. |
| **Accepting RSA-PKCS1v1.5 for key transport** | Older SP metadata defaults (pre-2012 era) advertise RSA-1_5. Teams using unmaintained IdP configs encounter it. | Bleichenbacher attack on RSA-PKCS1v1.5 is well-understood and practical in adaptive chosen-ciphertext scenarios. The SAML XML-Enc profile explicitly recommends RSA-OAEP (rsa-oaep-mgf1p URI). | Reject by default. Same escape-hatch pattern as AES-CBC. Operator must explicitly acknowledge the risk, set an expiry, and a reason string. |
| **Reading NameID or attributes from decrypted bytes before re-parsing** | Slightly faster path; avoids the re-parse overhead. | Post-decrypt XSW4: an attacker who can influence the ciphertext can cause the decrypted bytes to contain a structurally valid but semantically crafted assertion that passes signature checks on the envelope but carries a different identity. Re-parsing through the hardened seam is the mitigation. | Always re-parse. The overhead is negligible compared to the RSA decrypt operation. |
| **Storing the SP private decryption key in the Ecto connection schema** | Convenience — operators want all connection config in one place in the database. | Private key material in a database schema is exposed to every DB read, backup, diagnostic bundle, audit log, and query trace. The hardened diagnostic bundle already explicitly excludes PEM and key material. Putting the private key in the schema would require re-auditing all those surfaces. | Runtime config via `sp_signing_key:` application config or environment variable. `KeyResolver` behaviour for KMS integration. |
| **Simultaneous cleartext + encrypted assertion** | Some badly-configured IdPs or proxies emit both. Teams want the library to "gracefully" use whichever works. | Accepting both creates an ambiguity vector: an attacker who can inject a cleartext assertion alongside a legitimate encrypted one could manipulate processing. The spec does not endorse dual-assertion responses for the same subject. | Hard-reject with `:ambiguous_assertion`. Operator must fix the IdP configuration. |
| **HTTP-POST binding signed AuthnRequests in v1.3** | POST binding is used in some enterprise environments where redirect binding is blocked. | POST binding signed AuthnRequests require enveloped XML signature, which means a new C14N + document-signature code path that does not yet exist. The marginal demand does not justify the scope expansion in v1.3. | Defer to v1.4 if real demand materializes. HTTP-Redirect binding covers ADFS, Shibboleth, and Entra. |
| **`EncryptedID` (NameID encryption) as a distinct feature** | Some IdPs encrypt the NameID separately as `EncryptedID` inside the Subject element. | `EncryptedID` uses the same XML-Enc primitive as `EncryptedAttribute`. Handling it is a small extension once the decrypt pipeline is in place. It is not a "feature" to advertise separately — it is a corner case to handle correctly inside the attribute/NameID mapping code. | Handle silently as part of the decrypt pipeline. Document in the encrypted-assertions runbook section, not as a standalone feature. |

---

## IdP Compatibility Matrix

What each major IdP requires, supports, and defaults to.

### EncryptedAssertion

| IdP | Supports Encryption | Default | Algorithm | SP Metadata Requirement | Notes |
|-----|--------------------|---------|-----------|-----------------------|-------|
| **Microsoft Entra ID** | Yes | Off (opt-in) | AES-256 for content | Upload SP cert in admin portal; OR set `keyCredentials` + `tokenEncryptionKeyId` via Graph API | Entra ID P1/P2 feature (not free tier). Uses AES-256 (not AES-128). Does not use `KeyDescriptor` from SP metadata — cert is uploaded manually to the app registration. |
| **Okta** | Yes | Off (opt-in) | Operator-selectable (AES-128-CBC default, AES-256-GCM available) | Upload SP public cert in app "Advanced Settings" → Assertion Encryption field | Default is still AES-CBC in many Okta app templates. Operator must select AES-256-GCM explicitly. |
| **Shibboleth IdP 4+** | Yes | Opportunistic (encrypts if SP metadata has compatible key) | AES-128-GCM (default in v4 new installs); upgraded systems retain AES-CBC | `KeyDescriptor use="encryption"` in SP metadata | v4 defaulted new installs to AES-GCM. Upgraded installs may still use AES-CBC. The `idp.encryption.optional` property can make encryption conditional on key availability. |
| **ADFS** | Yes | Off (opt-in) | AES-256-CBC (default); RSA-OAEP for key transport | Upload SP cert in relying party trust | ADFS typically defaults to CBC content encryption. CBC is insecure without authenticated encryption; the escape-hatch mechanism applies here. |
| **Google Workspace** | No | N/A | N/A | N/A | Google's SAML IdP does not support assertion encryption. Encryption support is irrelevant for Google Workspace integrations. |
| **Keycloak** | Yes | Off | Configurable | `KeyDescriptor use="encryption"` in SP metadata | Supports both AES-CBC and AES-GCM. GCM is available and recommended. |
| **OneLogin** | Yes | Off | AES-256-CBC (default) | Upload SP cert in app settings | Similar to Okta; AES-CBC default. |
| **PingFederate / PingOne** | Yes | Off | Configurable; RSA-OAEP + AES-GCM fully supported | `KeyDescriptor use="encryption"` in SP metadata | Best support for standards-compliant GCM + OAEP combination. |

### Signed AuthnRequests

| IdP | `WantAuthnRequestsSigned` | Default Enforcement | Binding | Algorithm Requirement | Notes |
|-----|--------------------------|--------------------|---------|-----------------------|-------|
| **ADFS** | Yes | **Required in most installs** (hard to disable) | HTTP-Redirect (most common) or POST | RSA-SHA256 typical | The primary motivation for AUTHN-01. ADFS reads `AuthnRequestsSigned` from SP metadata and enforces accordingly. The PowerShell `Set-ADFSRelyingPartyTrust` can configure `WantAuthnRequestsSigned` but operators often cannot disable it in locked-down environments. |
| **Shibboleth IdP** | Yes | **Enforced when SP metadata has `AuthnRequestsSigned="true"`** | HTTP-Redirect | RSA-SHA1 or RSA-SHA256 (SHA256 preferred) | Shibboleth reads the SP's `SPSSODescriptor/@AuthnRequestsSigned` attribute. When true, unsigned requests are rejected with "AuthnRequests must be signed." Additionally, `AuthnRequestsSigned="true"` blocks IdP-initiated SSO — documented footgun. |
| **Microsoft Entra ID** | Optional | Off (opt-in; "Require Verification certificates" checkbox) | HTTP-Redirect or POST | **RSA-SHA256 only** (rejects RSA-SHA1) | Entra ID is lenient by default — if verification is not enabled, signed requests are accepted but not verified. When verification is enabled, only RSA-SHA256 is accepted (SHA1 rejected). The SP public key must be uploaded to the app, not read from SP metadata. |
| **Okta** | Optional | Off | HTTP-Redirect or POST | RSA-SHA256 preferred | Okta does not typically require signed requests for most apps. Some SAML app templates expose the option. |
| **Google Workspace** | No | N/A | N/A | N/A | Google does not support signed AuthnRequests. Enabling signing on the SP side does not cause errors (Google ignores the signature), but publishing `AuthnRequestsSigned="true"` in metadata may confuse federation tools. |
| **Keycloak** | Optional | Off | HTTP-Redirect or POST | RSA-SHA256 | Configurable per realm/client. Off by default. |
| **PingFederate** | Optional | Configurable | HTTP-Redirect or POST | RSA-SHA256 | Fully configurable. Some enterprise Ping deployments enable it. |

### Critical Interoperability Detail: HTTP-Redirect Signature Construction

The SAML Bindings spec §3.4.4.1 (normative) defines that the signature input string for
HTTP-Redirect binding is the concatenation of **URL-encoded** query parameters in exact order:
`SAMLRequest=<url-encoded>&RelayState=<url-encoded>&SigAlg=<url-encoded>` — where RelayState is
omitted entirely (not empty-string) if absent. The relying party **must** verify using the original
URL-encoded bytes received, not re-encoded values. URL-encoding is not canonical: `space` can be
`%20` or `+`; different implementations produce different byte strings. ADFS is known to use `+`
encoding in some cases. Signing re-serialized content is a real production bug seen in Ruby and
Java SAML implementations.

**This is the single most important implementation detail in AUTHN-01.** The investigation thread
identifies it as a CVE-class footgun.

---

## Feature Dependencies

```
ENC-01: EncryptedAssertion / XML-Enc
    requires── SIGV-01/02 (XMLDSig verify) — DONE in v1.1
    requires── hardened saxy seam (PureBeam) — DONE in v1.1
    requires── AlgorithmPolicy extension (AES-GCM + RSA-OAEP allowlist)
    requires── KeyResolver behaviour (new)
    requires── SP metadata: KeyDescriptor use="encryption" publication

AUTHN-01: Signed AuthnRequests
    requires── SIGV-01 signing primitives (XmldsigSigner exists from v1.1) — DONE
    requires── SP signing key config (sp_signing_key: runtime config)
    requires── SP metadata: KeyDescriptor use="signing" + AuthnRequestsSigned flag publication
    enhances── ADFS preset (primary motivation)

ADFS Preset
    requires── AUTHN-01 (signed AuthnRequests)
    enhances── DOCS-02 (generic runbook; ADFS is a major non-SaaS IdP)

DOCS-02 (Generic SAML runbook)
    requires── ENC-01 (runbook must cover encrypted assertion setup)
    requires── AUTHN-01 (runbook must cover signed request setup)
    enhances── ADFS preset (ADFS runbook is the reference for the generic guide structure)

DOCS-03 (Identity mapping guide)
    requires── existing UserMapper behaviour — DONE
    enhances── DOCS-02 (cross-referenced; attribute decoder tables feed the identity mapping section)

EncryptedAttribute (inside ENC-01)
    requires── ENC-01 decrypt pipeline (same primitive)
    enhances── ENC-01 (completeness for Shibboleth academic federations)
```

### Dependency Notes

- **ENC-01 requires re-parse through hardened seam.** The decrypted bytes are untrusted until they pass through `PureBeam.parse_safely/2` with all pre-parse guards active. This is not optional.
- **AUTHN-01 does not require ENC-01.** They are independent features. The investigation thread recommends shipping ENC-01 first (higher priority, harder), then AUTHN-01, because AUTHN-01 shares the signing primitive already built in v1.1.
- **ADFS preset requires AUTHN-01.** ADFS without signed requests is misconfigured. The preset must enable `sign_authn_requests: true` by default or it is actively misleading.
- **`AuthnRequestsSigned="true"` in SP metadata blocks IdP-initiated SSO** (Shibboleth enforces this strictly). The connection `sign_authn_requests` flag must co-document this tradeoff.

---

## MVP Definition for v1.3

### Launch With (all four requirements)

- [ ] **ENC-01:** `EncryptedAssertion` decryption (RSA-OAEP + AES-GCM, reject AES-CBC/PKCS1v1.5, opaque error atom, decrypt-then-reparse, `EncryptedAttribute` included, KeyResolver behaviour, SP metadata KeyDescriptor) — required for Entra/Okta/Shibboleth enterprise customers who have encryption enabled.
- [ ] **AUTHN-01:** Signed AuthnRequests, HTTP-Redirect binding only, raw-octet signing, per-connection toggle, SP metadata publication — required for ADFS and locked-down Shibboleth deployments.
- [ ] **ADFS preset** — primary motivation for AUTHN-01; ships with the feature to make it immediately useful.
- [ ] **DOCS-02:** Generic SAML runbook with field-name decoder tables — high adopter value at low cost; needed before v1.3 is the "go-to" library.
- [ ] **DOCS-03:** Identity mapping guide with JIT decision tree — closes the most common day-2 support question.

### Add After Validation (v1.4+)

- [ ] **HTTP-POST binding signed AuthnRequests** — needs enveloped XML signature, distinct C14N path. Defer until real demand from POST-binding-only environments.
- [ ] **KMS-native KeyResolver adapter** — documented extension point in v1.3; full adapter with AWS KMS / GCP KMS in v1.4 if demand materializes.
- [ ] **Signed metadata (`EntityDescriptor` for SP metadata endpoint)** — some academic federations require it. Out of scope for v1.3.

### Future Consideration (v2+)

- [ ] **`EncryptedID` (NameID encryption) as explicit feature** — handled silently in v1.3 pipeline; explicit runbook documentation in v2 if it surfaces as a support question.
- [ ] **Attribute Query** — SAML-defined back-channel query for attributes. Explicitly out of scope per PROJECT.md.
- [ ] **Full SCIM integration** — explicitly out of scope per PROJECT.md; guide (DOCS-03) sets the boundary clearly.

---

## Feature Prioritization Matrix

| Feature | Adopter Value | Implementation Cost | Priority |
|---------|--------------|---------------------|----------|
| ENC-01: EncryptedAssertion (OAEP + GCM) | HIGH (enterprise blocker for Entra/Shibboleth/ADFS users) | HIGH (KeyResolver, crypto pipeline, re-parse, corpus) | P1 |
| ENC-01: EncryptedAttribute | MEDIUM (Shibboleth academic federations) | LOW (same pipeline as EncryptedAssertion) | P1 (rides on ENC-01) |
| ENC-01: AES-CBC/PKCS1v1.5 rejection + escape hatch | HIGH (security posture; differentiator) | LOW (AlgorithmPolicy extension) | P1 |
| ENC-01: Adversarial corpus (padding oracle, XSW4) | HIGH (security assurance claim) | MEDIUM (6 corpus fixtures) | P1 |
| AUTHN-01: HTTP-Redirect signed AuthnRequests | HIGH (ADFS blocker; Shibboleth enterprise) | HIGH (raw-octet signing, signature construction, footgun prevention) | P1 |
| ADFS provider preset | HIGH (closes the last major enterprise IdP gap) | MEDIUM (preset + claim rules + runbook) | P1 |
| DOCS-02: Generic SAML runbook | HIGH (long-tail adopter onboarding) | LOW (documentation) | P1 |
| DOCS-03: Identity mapping guide + JIT decision tree | HIGH (day-2 question prevention) | LOW (documentation) | P1 |
| HTTP-POST signed AuthnRequests | LOW (niche; ADFS works on Redirect) | HIGH (new XML signature path) | P3 |
| KMS KeyResolver adapter | MEDIUM (enterprise key management) | MEDIUM (AWS/GCP API integration) | P2 (v1.4) |

---

## Generic SAML Runbook: Required Coverage

This specifies what `guides/recipes/generic_saml.md` must cover to be a useful first-class peer
of the existing preset runbooks.

### Minimum Safe Checklist

1. **SP Metadata fields** — Entity ID format, ACS URL format, NameID format choices (persistent,
   transient, email, unspecified), SLO endpoint, `AuthnRequestsSigned` flag, certificate
   `KeyDescriptor` blocks (signing + encryption where applicable).
2. **IdP Metadata import** — What to look for: `SingleSignOnService` URL (binding + location),
   `IDPSSODescriptor` certificates, `WantAuthnRequestsSigned` flag (trigger: enable
   `sign_authn_requests`), `WantAssertionsSigned` flag (always true for Relyra; should already
   be signed), entity ID for IdP-side claim rule configuration.
3. **Claim / attribute configuration table** — Decoder tables for top non-preset IdPs. At
   minimum: IBM Security Verify, CyberArk Idaptive, Oracle Access Manager / OCI IAM,
   PingFederate, CA SiteMinder. For each: the claim URI for email, given name, surname, groups,
   and the NameID format they default to.
4. **NameID format decision** — When to use `persistent` (stable opaque ID, best for user
   record anchoring), `email` (convenient but changes), `transient` (stateless/pseudonymous),
   `unspecified` (IdP decides; ADFS transforms to email via claim rule).
5. **Signing and encryption setup** — When to enable `sign_authn_requests: true` (look for
   `WantAuthnRequestsSigned="true"` in IdP metadata or a rejection error about unsigned
   requests). When to enable assertion decryption (look for `WantAssertionsEncrypted="true"` in
   IdP metadata or for `EncryptedAssertion` nodes in the response).
6. **Minimum-safe security settings** — What Relyra enforces by default and why: SHA-1
   rejection, replay cache requirement, signature required, AES-CBC rejection. How to interpret
   an algorithm policy error.
7. **Debugging flow** — SAML tracer → Relyra validation trace → common error atoms → what to
   fix. Reference the existing error taxonomy.
8. **Certificate rotation** — How to add a next cert in the IdP and stage the rollover in
   Relyra cert inventory. When both certs are live. When to promote.

### Optional / Differentiator Sections

- ADFS-specific table: claim rules for email/name/groups, NameID transform rule,
  `MessageAndAssertion` signing PowerShell command.
- Shibboleth-specific: `AuthnRequestsSigned` footgun with IdP-initiated SSO, AES-GCM upgrade
  path.
- Academic federation / InCommon: attribute release policy, scoped attributes,
  `EncryptedAttribute` expectations.

---

## Identity Mapping Guide: Required Coverage

This specifies what `guides/identity_mapping_and_provisioning.md` must cover.

### Three Mapping Patterns to Document

1. **NameID-as-local-identifier** — map `subject.name_id` directly to the local user record's
   external ID field. Works for persistent NameID. Breaks for transient or email NameID.
2. **Attribute-as-local-identifier** — use a stable attribute (e.g., `employeeId`, `objectGUID`)
   as the user record anchor. The attribute name is IdP-specific; the guide must provide a
   decoder table. This is the recommended pattern for enterprise IdPs that use email NameID
   (email changes).
3. **JIT create-or-update** — on first login, create the local user record from assertion
   attributes. On subsequent logins, update the record if attributes changed. This is Relyra's
   `UserMapper` behaviour. The guide must document: what attributes are available, when the
   callback fires, and what must be returned.

### JIT Decision Tree

```
Does the IdP support SCIM?
├─ No  → Use JIT (SAML-only provisioning)
└─ Yes → Do you need deprovisioning (account disable on removal)?
          ├─ Yes → Use SCIM (SAML for auth, SCIM for lifecycle)
          └─ No  → Use JIT (simpler; no SCIM connector required)

Are you using JIT?
├─ Use persistent NameID or a stable attribute as the anchor — NOT email
├─ Save the anchor in your user table for subsequent login lookups
└─ Do NOT enable JIT and SCIM simultaneously (JIT overwrites SCIM updates on every login)
```

### SCIM Non-Goal Statement

DOCS-03 must explicitly state: "Relyra handles login-time identity assertion (JIT create/update
via `UserMapper`). Full provisioning lifecycle — deprovisioning, group sync, account suspension —
is out of scope. Use a dedicated SCIM connector (WorkOS, Okta SCIM, Entra SCIM, or an in-house
SCIM provider) for lifecycle management."

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| ENC-01: AlgorithmPolicy extension | Temptation to accept AES-CBC "to support legacy IdPs" | Escape hatch only. The padding oracle risk is documented and practical. Default must reject. |
| ENC-01: Decrypt pipeline | Reading assertion fields before re-parse through the hardened seam | Architecture gate: `decrypt_assertion/3` → `parse_safely/2` → `do_verify`. Never shortcut this path. Document in code comments. |
| ENC-01: Error taxonomy | Returning different errors for "wrong key" vs "bad padding" vs "bad ciphertext" | Single `:decryption_failed` atom. The oracle is closed only if all paths return the same atom. |
| ENC-01: KeyResolver | Storing the SP private key in the Ecto connection schema | Runtime config only. `KeyResolver` behaviour with PEM default. Private key never hits the DB schema or diagnostic bundle. |
| AUTHN-01: Redirect signature construction | Re-encoding the URL parameters before signing | Sign the raw query-string bytes as received/as built. Never re-serialize. Write a golden-output test (known-good bit-for-bit comparison) for this path. |
| AUTHN-01: RelayState handling | Including `RelayState=` (empty) in the signature input when RelayState is absent | The spec says omit the parameter entirely when absent. Empty string and absent are not the same. |
| AUTHN-01: SP metadata flag + IdP-initiated SSO | Publishing `AuthnRequestsSigned="true"` breaks IdP-initiated SSO for Shibboleth | Co-document the tradeoff. When `sign_authn_requests: true`, IdP-initiated SSO with Shibboleth IdP requires the IdP to have compatible configuration, or the feature must be disabled at the IdP side. |
| ADFS preset | Claim rules not configured in ADFS after metadata import | Runbook must include the two required claim rules (LDAP-to-claims + NameID transform) and the `Set-ADFSRelyingPartyTrust -SamlResponseSignature "MessageAndAssertion"` PowerShell command. |
| DOCS-02 decoder tables | Attribute names go stale as IdP vendors update their SAML app templates | Pin the IdP software versions the tables apply to. Date the tables in the guide. Note that attribute names are case-sensitive. |
| DOCS-03 JIT decision tree | Teams enabling JIT + SCIM simultaneously | Explicit warning: JIT overwrites SCIM-provisioned attributes on every login. One or the other, not both. |

---

## Sources

- [Microsoft Entra ID — Configure SAML Token Encryption](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/howto-saml-token-encryption) — HIGH confidence (official Microsoft docs, updated 2026-02-19)
- [Microsoft Entra ID — Enforce Signed SAML Authentication](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/howto-enforce-signed-saml-authentication) — HIGH confidence (official Microsoft docs; confirms RSA-SHA256 only, Require Verification Certificates flag)
- [Shibboleth IdP 4 GCM Encryption docs](https://shibboleth.atlassian.net/wiki/spaces/IDP4/pages/1285914730/GCMEncryption) — MEDIUM confidence (Shibboleth Confluence; AES-GCM default for new v4 installs confirmed)
- [Shibboleth SP3 Signing and Encryption](https://shibboleth.atlassian.net/wiki/spaces/SP3/pages/2065334379/SigningEncryption) — MEDIUM confidence (AuthnRequestsSigned flag behavior confirmed)
- [SAML Bindings Spec §3.4.4.1 — OASIS](https://docs.oasis-open.org/security/saml/v2.0/saml-bindings-2.0-os.pdf) — HIGH confidence (normative spec for HTTP-Redirect binding signature construction)
- [OASIS SAML Core 2.0 — Assertions and Protocols §3.3](https://docs.oasis-open.org/security/saml/v2.0/saml-core-2.0-os.pdf) — HIGH confidence (EncryptedAssertion structure, normative)
- [Mattermost ADFS SAML Setup Guide](https://docs.mattermost.com/administration-guide/onboard/sso-saml-adfs-msws2016.html) — MEDIUM confidence (ADFS claim rules, NameID "Unspecified", Set-ADFSRelyingPartyTrust PowerShell command confirmed)
- [Jager–Somorovsky XML-Enc Padding Oracle](https://di-mgt.com.au/xmlenc-breaking-xml-encryption.html) — HIGH confidence (well-documented CCS'11 paper; rationale for AES-CBC rejection)
- [Compass Security SAML Padding Oracle (2021)](https://blog.compass-security.com/2021/09/saml-padding-oracle/) — HIGH confidence (SAML-specific CBC padding oracle demonstration; confirms practical exploitability)
- [Okta SAML Assertion Encryption](https://docs.trendmicro.com/en-us/documentation/article/trend-micro-cloud-one-identity-account-management-config-saml-assert-encrypt-okta) — MEDIUM confidence (Okta Advanced Settings; Assertion Encryption field confirmed)
- [PingAM Signing and Encryption](https://docs.pingidentity.com/pingam/8/am-saml2/saml2-encryption.html) — MEDIUM confidence (PingAM RSA-OAEP + AES-GCM support confirmed)
- [WorkOS: Hidden Pitfalls of SAML Metadata](https://workos.com/blog/the-hidden-pitfalls-of-saml-metadata-how-to-avoid-downtime) — MEDIUM confidence (metadata misconfig patterns; entity ID/ACS URL typos, cert rotation downtime)
- [Relyra investigation threads](../.planning/threads/encrypted-assertions-investigation.md) and [signed-authn-requests-investigation.md](../.planning/threads/signed-authn-requests-investigation.md) — HIGH confidence (project-specific analysis by the core team)

---

*Feature research for: Relyra v1.3 Advanced Federation — EncryptedAssertion, Signed AuthnRequests, ADFS preset, Generic SAML runbook, Identity mapping guide*
*Researched: 2026-05-25*
