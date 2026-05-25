# Project Research Summary

**Project:** Relyra v1.3 — Advanced Federation (EncryptedAssertion + Signed AuthnRequests)
**Domain:** SAML 2.0 SP library — cryptographic extensions for enterprise IdP interoperability
**Researched:** 2026-05-25
**Confidence:** HIGH

## Executive Summary

Relyra v1.3 adds two independent but complementary features to an existing hardened SAML SP library: assertion-level XML-Enc decryption (ENC-01) and outbound signed AuthnRequests for HTTP-Redirect binding (AUTHN-01). Both are enterprise IdP unblockers — ENC-01 unblocks Entra ID, Okta, Shibboleth, and ADFS encryption configurations; AUTHN-01 unblocks ADFS (which requires signed requests in most installations) and locked-down Shibboleth deployments. The correct implementation order is: AlgorithmPolicy extension first (shared dependency), then the ENC-01 crypto core and pipeline wiring, then AUTHN-01 signing. ADFS preset, generic SAML runbook, and identity mapping guide are independent deliverables with no code dependencies and can proceed in parallel with the crypto work.

The most critical architectural constraint for v1.3 is the decrypt-then-reparse invariant: decrypted assertion bytes must be fed back through the hardened saxy seam (`PureBeam.parse_safely/2`) before any field is accessed, and XMLDSig verification must succeed before any identity data is consumed. This is not optional — CVE-2025-54419 in node-saml (CVSS 10.0) and CVE-2024-45409 in ruby-saml (CVSS 9.8) demonstrate exactly what happens when libraries shortcut this step. Zero new Hex dependencies are needed: `:public_key.decrypt_private/3`, `:crypto.crypto_one_time_aead/7`, `:public_key.sign/3`, and `:zlib` cover the entire cryptographic surface, all live-verified on OTP 28.

The key risk cluster for v1.3 is algorithm policy enforcement. Five specific CVE-class mistakes must be prevented by design: RSA-PKCS1v1.5 key transport (Bleichenbacher), AES-CBC content encryption (Jager-Somorovsky padding oracle), AES-GCM auth tag truncation (GHASH key recovery), distinct decryption error atoms (behavioral oracle), and simultaneous cleartext+encrypted assertions (injection attack). All five are addressed by routing through `AlgorithmPolicy` before any crypto operation and collapsing all decryption failures to a single opaque `:decryption_failed` atom. The redirect binding signature construction has one critical correctness invariant: raw URL-encoded query string octets must be signed verbatim, never re-serialized — a known production CVE-class bug in multiple SAML libraries.

## Key Findings

### Recommended Stack

Every cryptographic operation required for v1.3 is covered by OTP stdlib. There are zero new Hex dependencies. Adding any NIF-based XML-Enc library would create a second XML parsing entry point, bypassing the hardened saxy seam, and provide zero capability benefit. All function signatures have been live-verified on OTP 28; the OTP version matrix confirms stability across OTP 26, 27, and 28.

One OTP limitation: RSA-OAEP with SHA-256 hash (`xmlenc11#rsa-oaep`) is not exposed by OTP — `{:rsa_oaep_hash, :sha256}` raises `{:badarg}` on OTP 28. This is not a blocker: all major enterprise IdPs (Okta, Entra, ADFS, Shibboleth) use SHA-1 OAEP key transport when encrypting assertions. The AlgorithmPolicy must map the SHA-256 OAEP URI to `:blocked_pending_otp_support` with a clear error, not silently accept or silently fail it.

**Core technologies:**
- `:public_key.decrypt_private/3` with `{:rsa_padding, :rsa_pkcs1_oaep_padding}`: RSA-OAEP key transport — stable OTP 26-28; raises on failure, must wrap in try/rescue (same discipline as existing `safe_verify/4`)
- `:crypto.crypto_one_time_aead/7` with `:aes_256_gcm`: AES-GCM content decryption — CRITICAL argument order: `(Cipher, Key, IV, InText, AAD, TagOrTagLength, Flag)` — InText BEFORE AAD; returns atom `:error` on auth-tag failure, does not raise
- `:public_key.sign/3`: RSA-SHA256 signing for redirect-binding query strings — same `{:RSAPrivateKey, ...}` record loaded via existing `pem_entry_decode` pattern; PKCS#1 v1.5 padding is correct for SAML Redirect binding
- `:zlib` with `-15` window: raw DEFLATE (no header/trailer) for AuthnRequest redirect encoding — universal SAML redirect binding format; live round-trip verified on OTP 28
- `:public_key.pem_decode/1` + `:public_key.pem_entry_decode/1`: SP private key loading — already used in signature.ex; no new mechanism needed

### Expected Features

**Must have (table stakes):**
- EncryptedAssertion decryption (RSA-OAEP + AES-GCM) — enterprise IdP blocker; Entra, Okta, Shibboleth, ADFS all support encryption; SP is unusable with encrypted-assertion configs without this
- EncryptedAttribute handled alongside EncryptedAssertion — same decrypt pipeline, marginal additional cost, required for Shibboleth academic federation completeness
- SP metadata `KeyDescriptor use="encryption"` publication — IdPs cannot encrypt without this; Entra ID raises explicit `AADB2C90164` error when missing
- Decrypt-then-reparse through hardened saxy seam — not optional; CVE-class if shortcut
- Single opaque `:decryption_failed` atom for all decryption failures — padding oracle is open if error paths differ
- Signed AuthnRequests for HTTP-Redirect binding — ADFS requires this in most installations; Shibboleth enforces when `AuthnRequestsSigned="true"` in SP metadata
- `AuthnRequestsSigned="true"` + `KeyDescriptor use="signing"` in SP metadata when signing enabled — IdPs verify against the published key
- Per-connection `sign_authn_requests` boolean toggle, default `false` — backward-compatible; Okta/Google do not require signing
- AES-CBC and RSA-PKCS1v1.5 rejection via AlgorithmPolicy — prevents Jager-Somorovsky and Bleichenbacher oracles
- ADFS provider preset with `sign_authn_requests: true` by default — closes the last major enterprise IdP gap

**Should have (competitive differentiators):**
- Time-boxed AES-CBC escape hatch (same pattern as existing SHA-1 override) — legacy Shibboleth and ADFS installations may default to CBC; operator must explicitly acknowledge risk with reason string + expiry date
- KeyResolver behaviour for SP decryption key — PEM default ships in v1.3; KMS extension point documented for v1.4+
- SP signing key as runtime config only (`sp_signing_key_pem`), never in Ecto schema — diagnostic surface redaction contract; private keys off the DB
- Adversarial corpus for all encryption attack scenarios (7 ENC-01 + 5 AUTHN-01 fixtures) wired into `mix ci.security`
- Dev-mode footgun warning when connection targets ADFS preset but `sign_authn_requests: false`
- Generic SAML runbook (DOCS-02) with decoder tables for non-preset IdPs (IBM, CyberArk, Oracle, Ping, CA SiteMinder)
- Identity mapping guide (DOCS-03) with JIT decision tree and explicit SCIM non-goal statement
- Per-connection `sig_alg` override for ADFS installations that cannot accept SHA-256 on redirect binding

**Defer (v1.4+):**
- HTTP-POST binding signed AuthnRequests — requires new enveloped XML signature + C14N path; ADFS works on Redirect; insufficient marginal demand to justify v1.3 scope
- KMS-native KeyResolver adapter (AWS KMS / GCP KMS) — extension point documented in v1.3; full adapter in v1.4 if demand materializes
- Signed SP metadata (`EntityDescriptor`) — academic federation requirement; out of v1.3 scope
- `EncryptedID` (NameID encryption) as explicitly documented feature — handled silently in v1.3 pipeline; explicit runbook section in v2 if it surfaces as support question

### Architecture Approach

The v1.3 work is cleanly partitioned into three non-circular concerns: ENC-01 (new module `Security.XMLEnc` + `KeyResolver` behaviour + extensions to `PureBeam`, `ValidationPipeline`, `AlgorithmPolicy`, `Protocol.Metadata`, and `Ecto.Certificate`), AUTHN-01 (new function `Signature.sign_redirect_query/3` + extensions to `Protocol.AuthnRequest`, `Ecto.Connection`, and `LoginController`), and documentation (zero module changes). The pipeline wiring for ENC-01 inserts a single new `:decrypt_assertion` step in `ValidationPipeline.@ordered_stages` between `:issuer_connection_match` and `:signature_verify`; this step is a pure no-op when `:encrypted_assertion_bytes` is absent, so all existing non-encrypted flows are structurally unchanged. Both DB migrations use safe defaults that preserve all existing row behavior.

**Major components:**
1. `Relyra.Security.XMLEnc` (new module) — XML-Enc decryption only; takes raw EncryptedAssertion bytes, returns decrypted plaintext bytes or `:decryption_failed`; never reads assertion fields; AlgorithmPolicy checked before any key operation; all cipher failures collapse to the same opaque atom
2. `Relyra.KeyResolver` behaviour (new) — mirrors existing `ReplayStore` / `ConnectionResolver` pattern; `Default` impl reads SP decryption private key from app config only (never DB); `KMS` stub as documented extension point for v1.4
3. `Relyra.Security.AlgorithmPolicy` (extended) — two new struct fields: `allowed_key_transport_algorithms` (OAEP-SHA1 only by default) and `allowed_content_encryption_algorithms` (AES-GCM only by default); new helper `signing_digest_atom/1` for AUTHN-01; PKCS1v1.5 and AES-CBC permanently absent from defaults (no default escape hatch for PKCS1v1.5)
4. `Relyra.Protocol.ValidationPipeline` (extended) — `:decrypt_assertion` stage inserted; handles ambiguity guard (both cleartext + encrypted assertion → `:ambiguous_assertion`); wires second `PureBeam.parse_safely/2` call on decrypted bytes
5. `Relyra.Security.Signature.sign_redirect_query/3` (new function in existing module) — signs raw pre-assembled query-string binary verbatim; no parsing or re-encoding inside the function
6. `Relyra.Protocol.AuthnRequest.sign_redirect_params/3` (new function) — assembles canonical `SAMLRequest=...&RelayState=...&SigAlg=...` binary in exact spec order, calls `sign_redirect_query/3`, returns query string + base64 signature

### Critical Pitfalls

1. **Read assertion fields before XMLDSig verify** — decrypt pipeline must enforce structurally: decrypt → `PureBeam.parse_safely/2` → `Signature.do_verify/4` → field access. No shortcut. CVE-2025-54419 (node-saml, CVSS 10.0) was exactly this. Enforce via the `with` chain in `do_run_validations` so field accessors are only reachable after verify succeeds.

2. **Sign re-serialized redirect-binding parameters** — SAML Bindings spec §3.4.4.1 requires signing exact URL-encoded query string bytes as built. Re-encoding after map construction produces different bytes; IdP signature check fails. `sign_redirect_query/3` must accept a pre-built binary. Catch with a bit-for-bit golden output corpus fixture committed to `adversarial_crypto_test.exs`.

3. **RSA-PKCS1v1.5 key transport accepted** — `AlgorithmPolicy` must hard-reject `xmlenc#rsa-1_5` URI before any call to `:public_key.decrypt_private/3`. No escape hatch — no legitimate production use case for PKCS1v1.5 in new deployments. Bleichenbacher attack (CCS 2012) enables full session key recovery in ~14,000 queries.

4. **AES-CBC content encryption accepted** — `AlgorithmPolicy` must reject `xmlenc#aes128-cbc` and `xmlenc#aes256-cbc` by default. Jager-Somorovsky padding oracle (CCS 2011) recovers assertion plaintext in ~14 queries/byte. Time-boxed escape hatch (identical to SHA-1 pattern) for legacy IdP compatibility — but default must reject.

5. **AES-GCM auth tag not length-validated** — explicit `byte_size(auth_tag) == 16` guard required before calling `:crypto.crypto_one_time_aead/7`. OTP does not enforce tag length; shorter tag enables GHASH key recovery (GHSA-4v26-v6cg-g6f9, CVSS 8.2). Return opaque `:decryption_failed` if tag is wrong length.

6. **Both cleartext and encrypted assertion in same response** — detect in `PureBeam.build_parsed_doc/1`; return `:ambiguous_assertion` before any crypto. CVE-2026-2092 (Keycloak) was injection of a cleartext assertion alongside a valid encrypted one.

7. **SP private key stored in Ecto schema** — SP decryption key and SP signing key must be runtime config only. DB cert inventory stores public cert material only (for expiry tracking). Diagnostic bundle allow-list must exclude all `KeyResolver`-sourced key material.

## Implications for Roadmap

Based on combined research, the dependency graph mandates six phases. Minimum serialized path for ENC-01 GA: Plan 1 → Plan 2 → Plan 3. Plan 4 (AUTHN-01) can begin after Plan 1 and run in parallel with Plans 2-3. Plans 5-6 are fully independent.

### Phase 1: AlgorithmPolicy Extension + Cert Schema Migration

**Rationale:** Shared prerequisite for both ENC-01 and AUTHN-01. AlgorithmPolicy must be extended before any crypto code is written — it is the gate all new cipher operations pass through first. Retrofitting algorithm checks after crypto code exists is high-risk. Cert schema migration is additive with safe defaults and blocks no subsequent work.
**Delivers:** Extended `AlgorithmPolicy` struct with `allowed_key_transport_algorithms` + `allowed_content_encryption_algorithms` fields + `signing_digest_atom/1` helper; `enforce_key_transport_algorithm/2` + `enforce_content_encryption_algorithm/2` functions; cert schema migration adding `party` + `use` fields with `:idp`/`:signing` defaults for all existing rows; connection schema migration adding `sign_authn_requests: boolean, default: false`; all existing tests still passing.
**Avoids:** AES-CBC padding oracle (P3), RSA-PKCS1v1.5 Bleichenbacher (P2), algorithm policy gaps discovered after crypto code ships

### Phase 2: KeyResolver Behaviour + XMLEnc Crypto Core

**Rationale:** Depends on Phase 1 (AlgorithmPolicy calls inside XMLEnc). Highest-complexity phase — RSA-OAEP decryption, AES-GCM decryption with tag validation, opaque error handling, KeyResolver behaviour, and key isolation invariants.
**Delivers:** `Relyra.KeyResolver` behaviour + `KeyResolver.Default` (PEM from app config only) + `KeyResolver.KMS` stub; `Relyra.Security.XMLEnc` with `decrypt/3` (RSA-OAEP + AES-GCM, opaque errors, tag length guard, document KeyInfo ignored); unit corpus validating PKCS1v1.5 rejection, AES-CBC rejection, truncated-tag rejection, malformed ciphertext → uniform `:decryption_failed`.
**Uses:** `:public_key.decrypt_private/3` with `:rsa_pkcs1_oaep_padding`, `:crypto.crypto_one_time_aead/7` with `:aes_256_gcm`
**Avoids:** PKCS1v1.5 Bleichenbacher (P2), AES-CBC padding oracle (P3), GCM tag truncation (P4), error opaqueness oracle (P5), document KeyInfo SSRF (P11), private key in DB (P9)

### Phase 3: ValidationPipeline Wiring + PureBeam ENC Detection + Metadata + ENC-01 Corpus

**Rationale:** Depends on Phase 2 (XMLEnc.decrypt/3 must exist). Completes ENC-01 end-to-end.
**Delivers:** `PureBeam.build_parsed_doc/1` detecting EncryptedAssertion + ambiguity guard (`:ambiguous_assertion` on simultaneous cleartext + encrypted); `ValidationPipeline` with `:decrypt_assertion` step (no-op for non-encrypted paths, second `parse_safely/2` call for encrypted); `Protocol.Metadata` emitting `KeyDescriptor use="encryption"`; EncryptedAttribute handled inside same pipeline; full 7-fixture ENC-01 adversarial corpus in `mix ci.security`.
**Avoids:** Read-before-verify (P1), parser differential after decrypt (P10), cleartext+encrypted coexistence injection (P6)

### Phase 4: Signed AuthnRequests (AUTHN-01) + ADFS Preset

**Rationale:** Depends only on Phase 1 (needs `signing_digest_atom/1`). Can run in parallel with Phases 2-3. Primary unlocker for ADFS. Critical correctness constraint: raw-octet query construction.
**Delivers:** `Signature.sign_redirect_query/3`; `AuthnRequest.sign_redirect_params/3`; `LoginController` signing branch; `Protocol.Metadata` emitting `KeyDescriptor use="signing"` + `AuthnRequestsSigned="true"` when toggle is on; ADFS provider preset with `sign_authn_requests: true` by default; ADFS runbook with claim rules + PowerShell commands; 5-fixture AUTHN-01 adversarial corpus including bit-for-bit golden redirect query test and ADFS-style `+`-encoded variant; per-connection `sig_alg` override for SHA-1 ADFS interop.
**Avoids:** Re-serialized signing (P7), key confusion between signing and encryption certs (P8), ADFS SHA-1 interop gotcha

### Phase 5: Generic SAML Runbook (DOCS-02)

**Rationale:** No code dependency. Pure documentation with high adopter value. Can start any time after ENC-01 and AUTHN-01 are functionally complete so setup steps can be documented accurately.
**Delivers:** `guides/recipes/generic_saml.md` covering SP metadata fields, IdP metadata import checklist, claim/attribute decoder tables for IBM Security Verify + CyberArk + Oracle Access Manager + PingFederate + CA SiteMinder, NameID format decision guide, signing and encryption setup triggers, minimum-safe security settings, debugging flow, certificate rotation procedure, ADFS-specific and Shibboleth-specific subsections, academic federation / InCommon notes.

### Phase 6: Identity Mapping and Provisioning Guide (DOCS-03)

**Rationale:** No code dependency. Fully parallel with all phases. Closes the most common day-2 support question.
**Delivers:** `guides/identity_mapping_and_provisioning.md` covering three mapping patterns (NameID-as-local-identifier, attribute-as-local-identifier, JIT create-or-update), JIT decision tree, explicit SCIM non-goal statement, `UserMapper` behaviour documentation, JIT+SCIM simultaneous-use warning, anchor stability guidance.

### Phase Ordering Rationale

- Phase 1 must be first: AlgorithmPolicy is consumed by both ENC-01 and AUTHN-01. Retrofitting after crypto code exists risks gaps.
- Phase 2 before Phase 3: `XMLEnc.decrypt/3` must exist before pipeline wiring.
- Phase 4 parallel with Phases 2-3: AUTHN-01 depends only on Phase 1; parallelizing reduces total delivery time.
- Phases 5-6 fully parallel: pure documentation; no code dependencies.
- Minimum path to ENC-01 GA: Phase 1 → Phase 2 → Phase 3 (three sequential plans).
- Minimum path to AUTHN-01 GA: Phase 1 → Phase 4 (two sequential plans, can overlap with ENC-01 work).

### Research Flags

Phases needing deeper research during planning: **None identified.** All four research files are HIGH confidence; OTP function signatures are live-verified; architecture is fully specified with concrete module and function names; pitfalls cross-referenced against actual CVEs. The roadmapper can structure all six phases from this research without additional `--research-phase` runs.

Phases with standard patterns (skip `--research-phase`): All six phases.

One runtime validation to flag: the ADFS SHA-1 vs SHA-256 redirect binding interop question should be confirmed against a real ADFS instance during Phase 4 execution. Per-connection `sig_alg` override is required regardless; the runbook must note the version-specific behavior.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All OTP function signatures live-verified on OTP 28; OTP 26/27 cross-checked via GitHub source; NIST AES-256-GCM test vector verified; adversarial corpus 6/6 passes on OTP 28. Known gap: RSA-OAEP SHA-256 not exposed by OTP, but not a blocker — all major IdPs use SHA-1 OAEP. |
| Features | HIGH | Table stakes derived from normative SAML specs and official IdP docs (Entra, Shibboleth, ADFS). IdP-specific quirks (Okta AES-CBC default, ADFS SHA-1 interop) are MEDIUM — confirmed via multiple secondary sources but not against live IdP instances. |
| Architecture | HIGH | Derived from direct source reading of all affected modules in the actual codebase. Module boundaries, function signatures, pipeline ordering, and migration strategies are fully specified. Risk levels calibrated against actual code structure. |
| Pitfalls | HIGH | Cross-referenced against peer-reviewed CCS papers (Jager-Somorovsky 2011/2012) and specific CVEs (CVE-2025-54419 CVSS 10.0, CVE-2024-45409 CVSS 9.8, GHSA-4v26-v6cg-g6f9 CVSS 8.2, CVE-2026-2092, CVE-2021-29108). All 11 critical pitfalls have specific prevention strategies tied to named phases. |

**Overall confidence: HIGH**

### Gaps to Address

- **ADFS SHA-1 redirect binding interop**: ADFS 2016 may require SHA-1 for redirect-binding signatures; ADFS 2019+ accepts SHA-256. Confirm against authoritative ADFS docs or a real instance during Phase 4. Mitigation already baked in: per-connection `sig_alg` override is a Phase 4 deliverable.
- **Okta AES-CBC default**: Okta app templates still default to AES-128-CBC in many cases. The escape-hatch mechanism must be documented clearly in the generic runbook so operators enabling Okta encryption can use it without confusion. Documentation gap, not implementation gap.
- **EncryptedID (NameID-level encryption) handling**: Research recommends handling silently inside the ENC-01 decrypt pipeline. The exact NameID extraction path after decryption should be validated against a real test fixture or NameID-encrypting IdP during Phase 3 implementation.

## Sources

### Primary (HIGH confidence)

- OTP 26.2.5 / 27.3.3 / 28.0 source (`lib/crypto/src/crypto.erl`, `lib/public_key/src/public_key.erl`) — `crypto_one_time_aead/7` argument order, `decrypt_private/3` spec, `sign/3` spec
- NIST AES-256-GCM test vector verified live on OTP 28
- SAML 2.0 Bindings spec §3.4.4.1 (OASIS) — normative HTTP-Redirect binding signature construction
- OASIS SAML Core 2.0 §3.3 — `EncryptedAssertion` structure (normative)
- XML Encryption Syntax and Processing Version 1.1 — IV layout for AES-GCM `CipherValue`; key transport algorithm URIs
- Jager & Somorovsky, "How to Break XML Encryption," CCS 2011 — AES-CBC padding oracle
- Jager & Somorovsky, "Bleichenbacher's Attack Strikes Again," CCS 2012 — PKCS1v1.5 key transport
- CVE-2025-54419 / GHSA-4mxg-3p6v-xgq3 (node-saml, CVSS 10.0) — read-before-verify
- CVE-2024-45409 + CVE-2025-25291/25292 (ruby-saml, CVSS 9.8 / 8.8) — parser differential attacks
- GHSA-4v26-v6cg-g6f9 (xmlseclibs) — AES-GCM auth tag truncation
- CVE-2026-2092 (Keycloak) — simultaneous cleartext + encrypted assertion injection
- CVE-2021-29108 (ArcGIS Portal) — padding oracle via distinct error messages + XSW4
- Microsoft Entra ID docs — `howto-saml-token-encryption`, `howto-enforce-signed-saml-authentication` (official, updated 2026-02-19)
- Relyra investigation threads: `.planning/threads/encrypted-assertions-investigation.md`, `.planning/threads/signed-authn-requests-investigation.md`
- Direct codebase source reading: all affected modules in `lib/relyra/`

### Secondary (MEDIUM confidence)

- Shibboleth IdP 4 GCM Encryption docs — AES-GCM default for new v4 installs
- Shibboleth SP3 Signing and Encryption — `AuthnRequestsSigned` flag behavior; IdP-initiated SSO footgun
- Mattermost ADFS SAML Setup Guide — claim rules, NameID "Unspecified", PowerShell `Set-ADFSRelyingPartyTrust`
- Okta SAML Assertion Encryption (Advanced Settings) — AES-CBC default in Okta app templates
- PingAM docs — RSA-OAEP + AES-GCM support confirmed
- Compass Security Blog (2021) — SAML-specific CBC padding oracle; CVE-2021-29108 practical exploitability
- FusionAuth issue #1496 — URL-encoding case sensitivity in redirect-binding signature
- python3-saml issue #304 — `wantMessagesSigned` + encrypted assertions conflict

### Tertiary (LOW confidence)

- crewjam/saml issue #270 — key confusion in Go SAML library (cautionary pattern only)
- Shibboleth Concepts, "A Primer on SAML Keys and Certificates" — signing vs. encryption keypair separation rationale

---
*Research completed: 2026-05-25*
*Ready for roadmap: yes*
