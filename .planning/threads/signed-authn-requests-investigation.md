# Investigation: Signed AuthnRequests (WantAuthnRequestsSigned)

Status: PARTIAL — redirect AUTHN-01 shipped Phase 35 (2026-05-26); POST deferral (AUTHN-POST-01) still save-for-demand
Priority: Low (demand-gated — save-for-demand)
Depends: v1.1 XMLDSig (DONE); redirect signing (DONE — Phase 35); encrypted assertions (DONE — Phase 34)

## Technical approach

- **Target:** HTTP-Redirect binding signing FIRST. It is the most common case, and it is mechanically
  DIFFERENT from POST binding (detached signature over raw query-string octets, not an enveloped document signature).
- **Critical footgun (CVE-class):** sign the RAW query-string octets of the form
  `SAMLRequest=<url-encoded>&RelayState=<url-encoded>&SigAlg=<url-encoded>` — NOT a re-serialized map.
  Signing re-serialized content is a real bug seen in production SAML libs (alters the byte string being signed,
  making the signature unverifiable by the IdP or — worse — verifiable with subtly different content).
- **SP signing key:** runtime-injected via `sp_signing_key:` config (NOT stored in DB schema).
  Keeps secrets off the schema + diagnostic surfaces that are hardened around public material only.
- **Per-connection toggle:** `sign_authn_requests: true` (default: `false`; additive, backward-compatible).
- **Metadata:** publish SP signing `KeyDescriptor use="signing"` + SLO service endpoints in the metadata endpoint.
- **Defer:** POST binding enveloped signing (needs C14N engine + document signature; lower demand; more complexity;
  save for v1.4 if real demand materializes).

## Adversarial corpus additions (for `mix ci.security`)

| Fixture | Expected outcome |
|---------|-----------------|
| Golden redirect-binding signed query → IdP verifies | bit-for-bit match with known-good output |
| ADFS-style URL encoding variant (space → `+`) | handled via raw-octet signing (no re-serialization) |
| Tampered `SAMLRequest` after signing | `:invalid_authn_request_signature` |
| Tampered `SigAlg` after signing | `:invalid_authn_request_signature` |
| Unsigned request sent to IdP requiring signing | provider footgun warning in dev; runtime error for strict IdPs |

## Implementation plan estimate (~3 plans)

1. **SP signing primitive + AlgorithmPolicy extension:** `Signature.sign_redirect_query/3` (raw-octet, RSA-SHA256 default), `sp_signing_key:` config parsing + validation, AlgorithmPolicy `signing_digest_atom/1`
2. **Connection config + metadata publication:** `sign_authn_requests` connection field + validation, metadata endpoint `KeyDescriptor use="signing"` + `SingleLogoutService` publication, connection test UI "signed AuthnRequest" indicator
3. **Redirect-binding integration + corpus:** wire into `start_login/3` redirect-binding path, all corpus fixtures above, conformance manifest update, ADFS/Shibboleth provider runbook notes

## Relevant prior art

- **passport-saml** (Node) HTTP-Redirect signing — good raw-octet handling example
- **ruby-saml** signed AuthnRequest — covers the footgun explicitly in comments
- **SAML 2.0 Bindings spec §3.4.4.1** — the normative source for redirect-binding signature construction
- **ADFS documentation** — `WantAuthnRequestsSigned` behavior and key expectations

## Open questions for milestone planning

- Should `sign_authn_requests` default to `false` with a provider-preset override (e.g., ADFS preset enables it automatically), or always require explicit config? (Recommend: always explicit for v1.3; provider presets can set a `footgun_check` warning if the IdP is known to require it and the option is off)
- For the ADFS preset: should we add it in v1.3 as part of signed AuthnRequests, or keep it for a later preset milestone? (Recommend: add minimal ADFS preset in v1.3 since it's the primary motivation for this feature)
