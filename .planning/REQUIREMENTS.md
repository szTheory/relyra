# Requirements: Relyra v1.3 — Advanced Federation

**Defined:** 2026-05-25
**Core Value:** Every SAML login ends in a verified trust path or a typed rejection — never a silent compromise. Trust mutations are durable, attributable, and reviewable.

## v1.3 Requirements

Requirements for this milestone. Each maps to a roadmap phase.

### Encryption (XML-Enc)

- [x] **ENC-01**: SP can decrypt `EncryptedAssertion` (and `EncryptedAttribute`) using RSA-OAEP key transport and AES-GCM content encryption; decrypted bytes pass through `PureBeam.parse_safely/2` (hardened saxy seam) and `Signature.do_verify/4` (XMLDSig verification) before any identity fields are read; all decryption failures return opaque `:decryption_failed` atom regardless of failure mode
- [x] **ENC-02**: SP metadata endpoint publishes `KeyDescriptor use="encryption"` with the SP encryption certificate so IdPs can encrypt assertions
- [ ] **ENC-03**: Algorithm policy hard-rejects RSA-PKCS1v1.5 key transport (no escape hatch — no legitimate production use case) and rejects AES-CBC content encryption by default with a time-boxed escape hatch (identical to SHA-1 override pattern) for legacy IdP compatibility; AES-GCM auth tag length is validated (== 16 bytes) before any call to `:crypto.crypto_one_time_aead/7`
- [ ] **ENC-04**: Operator can configure SP decryption private key via `KeyResolver` behaviour (PEM config default implementation ships; KMS extension point is documented for v1.4+); SP private key material is never stored in any Ecto schema column or surfaced in diagnostic bundles; cert inventory `party`/`use` fields isolate encryption certs from signing certs

### Signed AuthnRequests

- [ ] **AUTHN-01**: SP can sign AuthnRequests for HTTP-Redirect binding by signing the raw pre-assembled query-string binary verbatim (RSA-SHA256 default; never re-serialized); adversarial corpus includes a bit-for-bit golden output test and an ADFS-style `+`-encoding variant
- [ ] **AUTHN-02**: Operator can enable or disable signed AuthnRequests per connection via `sign_authn_requests` boolean field (default: `false`; additive and backward-compatible with all existing connections)
- [ ] **AUTHN-03**: SP metadata endpoint publishes `KeyDescriptor use="signing"` and sets `AuthnRequestsSigned="true"` when `sign_authn_requests: true` is configured for a connection; SP metadata omits signing `KeyDescriptor` when the toggle is off
- [ ] **AUTHN-04**: ADFS provider preset ships with `sign_authn_requests: true` by default and includes an ADFS-specific runbook (`guides/providers/adfs.md`) covering claim rules, PowerShell `Set-ADFSRelyingPartyTrust` commands, SHA-1 vs SHA-256 redirect binding interop notes, and the `WantAuthnRequestsSigned` flag behavior

### Documentation

- [x] **DOCS-02**: Generic SAML runbook (`guides/recipes/generic_saml.md`) published as a first-class peer of `okta.md` — covering: SP metadata field reference, IdP metadata import checklist, attribute decoder tables for IBM Security Verify / CyberArk / Oracle Access Manager / PingFederate / CA SiteMinder, ADFS-specific and Shibboleth-specific subsections, minimum-safe security checklist, certificate rotation procedure, debugging flow
- [x] **DOCS-03**: Identity mapping and provisioning guide (`guides/identity_mapping_and_provisioning.md`) published — covering: NameID vs app identity (three mapping patterns: NameID-as-local-id, attribute-as-local-id, JIT create-or-update), JIT decision tree, `UserMapper` behaviour documentation with examples, JIT+SCIM simultaneous-use conflict warning, explicit SCIM-lifecycle non-goal statement

## Future Requirements

Deferred to future milestones. Tracked but not in current roadmap.

### v1.4 Candidates

- **AUTHN-POST-01**: HTTP-POST binding signed AuthnRequests — requires enveloped XML signature + C14N path; ADFS works on HTTP-Redirect; insufficient marginal demand to justify v1.3 scope
- **KMS-01**: KMS-native `KeyResolver` adapters (AWS KMS, GCP KMS) — extension point documented in v1.3; full adapters in v1.4 if adoption demand materializes
- **SLO-FULL-01**: Full SLO round-trip (SP-initiated + IdP-initiated, `SessionIndex` correlation, `SessionAdapter` extension) — scoped to v1.4 per milestone arc

### Post-v1.4

- **SIGNED-META-01**: Signed SP metadata (`EntityDescriptor`) — academic federation / InCommon requirement; out of v1.3/v1.4 scope
- **ENC-ID-01**: Explicit `EncryptedID` (NameID-level encryption) runbook section — handled silently in v1.3 pipeline; explicit docs if it surfaces as a support pattern

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| RSA-OAEP SHA-256 key transport (`xmlenc11#rsa-oaep`) | OTP stdlib limitation — `{:rsa_oaep_hash, :sha256}` raises `{:badarg}` on OTP 26-28; all major enterprise IdPs use SHA-1 OAEP. AlgorithmPolicy blocks with a clear error until OTP exposes the option. |
| HTTP-Artifact and ECP bindings | Diminishing-returns boundary from v1.0 milestone arc; demand-gated only |
| SCIM lifecycle ownership | Relyra handles login-time identity assertion; SCIM lifecycle stays in host app |
| NIF-based XML-Enc library | Would create a second XML parse entry point, bypassing the hardened saxy seam |
| Full standalone ADFS test environment | ADFS integration validated via runbook + per-connection `sig_alg` override; no hosted infra in OSS model |
| Signed SP metadata | Academic federation requirement; out of scope at this stage |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| ENC-03 | Phase 32 | Pending |
| ENC-04 | Phase 32 | Pending |
| AUTHN-02 | Phase 32 | Pending |
| ENC-01 | Phase 34 | Complete |
| ENC-02 | Phase 34 | Complete |
| AUTHN-01 | Phase 35 | Pending |
| AUTHN-03 | Phase 35 | Pending |
| AUTHN-04 | Phase 35 | Pending |
| DOCS-02 | Phase 36 | Complete |
| DOCS-03 | Phase 37 | Complete |

**Coverage:**

- v1.3 requirements: 10 total
- Mapped to phases: 10/10 ✓
- Unmapped: 0

---
*Requirements defined: 2026-05-25*
*Last updated: 2026-05-25 — traceability populated by roadmapper (Phases 32-37)*
