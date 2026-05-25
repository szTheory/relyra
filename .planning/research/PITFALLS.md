# Pitfalls Research

**Domain:** Adding EncryptedAssertion (XML-Enc) + Signed AuthnRequests to a hardened SAML SP
**Researched:** 2026-05-25
**Confidence:** HIGH — cross-referenced CVE advisories, library source issues, and peer-reviewed attack papers

---

## Critical Pitfalls

### Pitfall 1: Reading Fields from a Decrypted-but-Unverified Assertion

**What goes wrong:**
Decryption succeeds and the plaintext XML bytes are available. Code then reads `NameID`, attributes, or session index from those bytes before running the bytes through the signature-verification pipeline. The unverified plaintext is consumed directly as if it were trusted.

**Why it happens:**
Decryption "feels like" the security check — if the SP can decrypt, the IdP must have encrypted it, right? Developers wire the happy path as: decrypt → read fields → verify later (or forget to verify). This is the pipeline ordering mistake that produced CVE-2025-54419 in Node-SAML (CVSS 10.0): "Node-SAML loads the assertion data from the original, unsigned XML document rather than from the cryptographically validated content" after signature verification. The library verified a signature, then read assertion content from the untrusted original document rather than from the verified segment.

**How to avoid:**
The pipeline must be: decrypt → re-parse through the hardened saxy seam → XMLDSig verify the resulting `SignedNode` → only then read any fields from that `SignedNode`. No field from decrypted bytes may be read before `do_verify/4` succeeds and returns `{:ok, %SignedNode{}}`. Enforce this structurally: make decrypted-but-unverified bytes an opaque type that cannot produce a field accessor until it passes through the verify gate.

**Warning signs:**
Code that calls `get_name_id/1` or any field-reading function on a value that did not come out of `Relyra.Security.Signature.do_verify/4`. Any match on the result of `decrypt_assertion/3` before passing it to the verify step.

**Phase to address:**
ENC-01 pipeline integration plan (Plan 3 of the encrypted assertions implementation estimate). Must be a named invariant in the plan's acceptance criteria.

---

### Pitfall 2: RSA-PKCS1v1.5 Key Transport (Bleichenbacher)

**What goes wrong:**
The SP decrypts the XML-Enc `EncryptedKey` element using RSA-PKCS1v1.5 (`rsa_pkcs1_padding` in `:public_key`). An attacker submits ~thousands of crafted ciphertexts and observes whether decryption "succeeds" (produces well-formed XML) or fails, using the server as a Bleichenbacher oracle. Over enough queries the symmetric session key is recovered, allowing decryption of all past and future assertions encrypted for this SP. The attack was formalized for XML-Enc in "Bleichenbacher's Attack Strikes Again: Breaking PKCS#1 v1.5 in XML Encryption" (Jager/Somorovsky, CCS 2012). CVE-2021-29108 (ArcGIS Portal) was exploited using this exact technique combined with an XSW4 attack.

**Why it happens:**
PKCS1v1.5 is the default in many RSA APIs. The XML-Enc spec (`http://www.w3.org/2001/04/xmlenc#rsa-1_5`) allows it. Library authors choose it because it is available everywhere without extra configuration.

**How to avoid:**
Reject `http://www.w3.org/2001/04/xmlenc#rsa-1_5` at `AlgorithmPolicy` before any decryption attempt. Return `:unsupported_key_transport_algorithm`. Only `http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p` (RSA-OAEP-SHA1) and `http://www.w3.org/2009/xmlenc11#rsa-oaep` (RSA-OAEP-SHA256) are allowed by default. No escape hatch — unlike SHA-1, PKCS1v1.5 for key transport has no legitimate production use case in new deployments.

**Warning signs:**
Any `algorithm` atom or URI string containing `rsa-1_5` being accepted. Missing `AlgorithmPolicy` check before calling `:public_key.decrypt_private/3`.

**Phase to address:**
ENC-01 Plan 1 (AlgorithmPolicy extension + crypto core). Must appear in `adversarial_crypto_test.exs` corpus.

---

### Pitfall 3: AES-CBC Content Encryption (Jager–Somorovsky Padding Oracle)

**What goes wrong:**
The SP decrypts the `EncryptedData` element using AES-128-CBC or AES-256-CBC. An attacker submits modified ciphertexts and observes whether the decrypted content is valid XML (padding oracle). With approximately 14 requests per byte, the attacker decrypts the full assertion plaintext without the SP's private key. This is the "How to Break XML Encryption" attack (Jager/Somorovsky, CCS 2011) — it predates GCM's widespread adoption and affected every major SAML implementation of its era. The W3C published a note on this in November 2011.

**Why it happens:**
AES-CBC is ubiquitous and was the only option in early XML-Enc implementations. The SAML spec and many IdPs still support it. Library defaults often still emit CBC because changing them breaks interop with legacy IdPs.

**How to avoid:**
Reject `http://www.w3.org/2001/04/xmlenc#aes128-cbc` and `http://www.w3.org/2001/04/xmlenc#aes256-cbc` at `AlgorithmPolicy`. Default to `http://www.w3.org/2009/xmlenc11#aes256-gcm` and `http://www.w3.org/2009/xmlenc11#aes128-gcm` only. Provide the same time-boxed, audit-logged escape hatch as SHA-1 for legacy IdPs that cannot emit GCM, but make the override explicitly acknowledged and visible in the admin UI.

**Warning signs:**
An `algorithm` URI containing `aes128-cbc` or `aes256-cbc` passing through to `:crypto.crypto_one_time/5` without AlgorithmPolicy rejection.

**Phase to address:**
ENC-01 Plan 1 (AlgorithmPolicy extension). Escape hatch implementation in Plan 2. Adversarial corpus row in Plan 4.

---

### Pitfall 4: AES-GCM Authentication Tag Truncation (xmlseclibs GHSA-4v26-v6cg-g6f9)

**What goes wrong:**
The decryption implementation extracts the GCM authentication tag from the ciphertext using `binary_part` but does not validate that the extracted slice is exactly 128 bits (16 bytes). An attacker submits assertions with progressively shorter authentication tags. By observing whether the SP accepts or rejects each attempt, the attacker recovers the GHASH key. Once the GHASH key is known, arbitrary ciphertexts can be authenticated offline, enabling forgery of encrypted assertions. This was CVE-class in robrichards/xmlseclibs (GHSA-4v26-v6cg-g6f9, CVSS 8.2), where `substr()` was called without length validation.

**Why it happens:**
The tag is extracted from raw bytes and developers assume the slice is correct. The GCM API in `:crypto.crypto_one_time_aead/6` accepts any binary as the tag; it does not enforce length on the caller.

**How to avoid:**
Before calling `:crypto.crypto_one_time_aead/6`, assert `byte_size(auth_tag) == 16`. Return `:decryption_failed` (opaque) if the tag is any other length. Never pass a shorter tag to the AEAD primitive.

**Warning signs:**
Any path where `auth_tag` is extracted from the ciphertext binary without an explicit `== 16` guard before the AEAD call.

**Phase to address:**
ENC-01 Plan 1 (crypto core). Adversarial corpus row: truncated-tag fixture → `:decryption_failed`.

---

### Pitfall 5: Opaque Error Atom Leak — Decryption Oracle via Error Differentiation

**What goes wrong:**
The decryption pipeline returns distinct typed errors for distinct failure modes — e.g., `:padding_error`, `:wrong_key`, `:bad_ciphertext`, `:malformed_xml_after_decrypt`. An attacker submits modified ciphertexts and distinguishes padding errors from wrong-key errors. Even with AES-GCM, distinct error atoms for authentication-tag failure vs. wrong-key vs. structurally invalid ciphertext give the attacker a behavioral oracle. CVE-2021-29108 (ArcGIS) was exploited precisely because the server returned the error message "Given final block not properly padded" verbatim, distinguishing padding failures from other errors.

**Why it happens:**
Rich error atoms are good design elsewhere in Relyra — `:invalid_signature`, `:digest_mismatch`, etc. Developers naively apply the same pattern to decryption failures.

**How to avoid:**
ALL decryption failures — wrong key, bad tag, malformed ciphertext, unsupported algorithm already rejected above, wrong-length tag, XML parse failure on the decrypted bytes — collapse to the single opaque atom `:decryption_failed`. The only exception is algorithm policy rejection, which may return a distinct typed atom (`:unsupported_key_transport_algorithm`, `:unsupported_content_encryption_algorithm`) because algorithm policy rejection happens BEFORE any decryption attempt and leaks nothing about the SP's private key material.

**Warning signs:**
Multiple distinct return values from the decryption path that include any error from the actual RSA or AES operation. Any `{:error, reason}` where `reason` contains padding, key, tag, or cipher-related details propagating past the decryption boundary.

**Phase to address:**
ENC-01 Plan 1 (crypto core). Explicitly named invariant in the plan's acceptance criteria. Adversarial corpus row: repeated malformed ciphertexts → all return identical `:decryption_failed`.

---

### Pitfall 6: Simultaneous Cleartext + Encrypted Assertion in One Response

**What goes wrong:**
A `<samlp:Response>` contains both an `<Assertion>` (cleartext, signed) and an `<EncryptedAssertion>`. An SP that processes "whichever assertion is found first" or "all assertions found" can be forced into processing the attacker-controlled encrypted assertion after the attacker has recovered the plaintext via the padding oracle (CVE-2021-29108 chain), or into accepting an unsigned cleartext assertion while the encrypted one passes validation. CVE-2026-2092 in Keycloak was exactly this: "Keycloak validates that plaintext elements are signed when the response root is not signed, but does not apply the same binding requirement to encrypted assertions."

**Why it happens:**
SAML does not forbid multiple assertions. Some IdPs send both for backward-compatibility. Processing code iterates over all assertion elements without a "exactly one" enforcement gate.

**How to avoid:**
After parsing the `<samlp:Response>`, count `Assertion` + `EncryptedAssertion` elements. If the count is anything other than exactly one, return `:ambiguous_assertion` immediately — no decryption, no verification, no field reading. This check must run before any crypto operation.

**Warning signs:**
Code that iterates over a list of assertions (e.g., `Enum.map(assertions, ...)`) rather than extracting exactly one. Any conditional path that processes "the first assertion found."

**Phase to address:**
ENC-01 Plan 3 (pipeline integration + re-parse). Adversarial corpus row: both cleartext + encrypted in same response → `:ambiguous_assertion`.

---

### Pitfall 7: Signing the Re-Serialized AuthnRequest Map, Not the Raw Query-String Octets

**What goes wrong:**
For HTTP-Redirect binding, the signed content is the exact URL-encoded query string bytes of the form `SAMLRequest=<encoded>&RelayState=<encoded>&SigAlg=<encoded>`. If the SP decodes the parameters, builds a map, re-encodes the map, and then signs the re-encoded string, the bytes being signed differ from the bytes the IdP received and will attempt to verify. The resulting signature is cryptographically valid over something the IdP never saw. The IdP rejects every login with a signature verification failure. Real-world example: FusionAuth had a bug where lowercase vs. uppercase percent-encoding (`%3d` vs. `%3D`) caused verification failures because the relying party re-encoded instead of using raw received octets. The SAML Bindings spec §3.4.4.1 states explicitly: "the relying party MUST perform the verification step using the original URL-encoded values it received on the query string."

**Why it happens:**
The natural code structure is to parse query parameters into a map, then work with them. Re-encoding that map for signing feels equivalent. It is not — URL encoding is not canonical.

**How to avoid:**
In `start_login/3`, construct the query string by concatenating the raw URL-encoded parameter values in the mandated order (`SAMLRequest=...&RelayState=...&SigAlg=...`) as a binary, sign that binary directly, and then append `&Signature=<base64>`. Never decode-then-reencode. The signing function `Signature.sign_redirect_query/3` must accept a raw pre-built binary, not a map.

**Warning signs:**
Any use of `URI.encode_query/1` or `URI.encode/1` on already-constructed parameters before signing. Any decode step followed by a re-encode step in the signing path.

**Phase to address:**
AUTHN-01 Plan 1 (SP signing primitive). The test `golden redirect-binding signed query → bit-for-bit match` in the adversarial corpus catches this immediately if a known-good reference output is committed.

---

### Pitfall 8: Key Confusion Between SP Signing Key and SP Decryption Key

**What goes wrong:**
The same certificate and private key are used for both signing AuthnRequests and decrypting EncryptedAssertions. Metadata publishes a single `<KeyDescriptor>` without a `use` attribute (or with `use="signing"` only). The IdP encrypts assertions using the signing certificate's public key. The SP decrypts with the signing private key. This is technically correct — RSA can do both — but it creates two operational hazards: (1) rotating the signing key (for ADFS WantAuthnRequestsSigned) now also rotates the decryption key, potentially breaking assertion decryption during the overlap window; (2) if the private signing key is compromised, past ciphertexts are also retrospectively decryptable.

**Why it happens:**
Using one keypair is simpler. The SAML spec permits it. crewjam/saml (Go) uses a single `KeyPair` struct for both roles by default — the investigation thread explicitly flags this as the "key-confusion blast radius" pattern.

**How to avoid:**
Maintain separate keypairs for signing (`use="signing"`) and encryption (`use="encryption"`) in the cert inventory. Publish both `<KeyDescriptor>` elements in SP metadata. The cert inventory `party:` / `use:` fields (planned in ENC-01 Plan 2) must enforce this separation. The `KeyResolver` behaviour must only accept keys tagged `use: :encryption` for decryption operations.

**Warning signs:**
A single `sp_private_key` config option serving both roles. `KeyDescriptor` elements without a `use` attribute in generated SP metadata. `KeyResolver` implementation that falls back to the signing key when no encryption key is found.

**Phase to address:**
ENC-01 Plan 2 (Key management + schema). Must be a named invariant in the cert inventory extension design.

---

### Pitfall 9: SP Decryption Private Key Stored in DB Schema or Surfaced in Diagnostic Bundles

**What goes wrong:**
The SP decryption private key is stored as a column in the connection record Ecto schema, or is included in the redacted diagnostic bundle export (Phase 23). When the DB is breached or a diagnostic bundle is shared with a vendor, the private key is exposed. An attacker with the SP decryption private key can decrypt all past and future encrypted assertions — the forward-secrecy argument for XML-Enc (vs. TLS) is entirely negated.

**Why it happens:**
Other connection-scoped fields (IdP cert, EntityID, metadata URL) are stored in the DB schema. Developers follow the same pattern for the decryption key without recognizing the asymmetry: IdP certs are public material; SP private keys are private material.

**How to avoid:**
The SP decryption key must be runtime-injected via the `KeyResolver` behaviour from an environment variable or secrets manager — never stored in the database. The `KeyResolver` PEM default implementation reads from config/env at startup. The DB schema must have no column for SP private key material. The diagnostic bundle serialization allow-list must exclude any field that could contain key material (verify the allow-list covers `KeyResolver`-sourced values).

**Warning signs:**
Any Ecto migration adding a `sp_private_key` or `sp_decryption_key` column. Any `%ConnectionRecord{}` struct field that holds a PEM binary. Any path in the diagnostic bundle exporter that touches key material.

**Phase to address:**
ENC-01 Plan 2 (Key management + schema). Must explicitly state "no DB column for private key material" as a named constraint. Cross-check against Phase 23 (diagnostic bundles) allow-list.

---

### Pitfall 10: Missing Re-Parse Through the Hardened Saxy Seam After Decryption

**What goes wrong:**
After AES-GCM decryption, the plaintext bytes are fed to a second XML parser (e.g., a `String.contains?` check, a regex field extractor, or a lightweight DOM parser) rather than through `PureBeam.parse_safely/2` (the single hardened saxy entry point). The decrypted bytes may contain a DTD, crafted namespace declarations, or entity references that the secondary parser interprets differently from saxy. This creates a post-decryption parser differential — the signature was verified over the saxy interpretation, but the fields consumed come from the secondary parser. CVE-2025-25292 in ruby-saml (CVSS 8.8) and the broad ruby-saml CVE-2024-45409 (CVSS 9.8) both exploited parser differential attacks of this class.

**Why it happens:**
"I just need to extract the NameID from the XML string" is the classic rationalization for a quick regex or `Floki.find` call. The hardened parser seam is designed for full SAMLResponse documents; applying it to a decrypted inner assertion feels like over-engineering.

**How to avoid:**
Enforce the single-parse-path invariant (CLAUDE.md key seam: `lib/relyra/security/xml/pure_beam.ex`) for ALL XML, including decrypted assertion bytes. The `decrypt_assertion/3` function must return raw bytes only; the caller must immediately pass those bytes through `PureBeam.parse_safely/2` before any further processing. Wrap this in a typed function boundary so the compiler makes it impossible to skip.

**Warning signs:**
Any regex or string operation on decrypted assertion bytes before they reach `PureBeam.parse_safely/2`. Any second call path into an XML library other than through the `Relyra.Security.XML` seam.

**Phase to address:**
ENC-01 Plan 3 (Pipeline integration + re-parse). The existing `adversarial_crypto_test.exs` corpus row "Encrypted-then-XSW: XSW attack on decrypted plaintext" directly tests this — it must reject with `:invalid_signature` or `:digest_mismatch`, not return data.

---

### Pitfall 11: Trusting `<KeyInfo>` Inside `<EncryptedKey>` to Locate the Decryption Key

**What goes wrong:**
The `<EncryptedKey>` element may contain a `<KeyInfo>` child with an `<X509Certificate>` or `<RetrievalMethod>` pointing to the intended recipient key. If the SP uses that `<KeyInfo>` to decide which of its private keys to use for decryption (rather than attempting each configured key), an attacker controls which key the SP uses. A `<RetrievalMethod>` with an external URI can cause a SSRF/TOCTOU — the library fetches a URL the attacker controls before any signature check. This is the XML-Enc analogue of the XMLDSig `KeyInfo` trust problem (the one Relyra already guards against for signature verification via CLAUDE.md invariant #1).

**Why it happens:**
The XML-Enc spec designates `<KeyInfo>` as a hint for key selection. Some OpenSAML / Java-based implementations use `InlineEncryptedKeyResolver` and `ChainingEncryptedKeyResolver` that walk the `<KeyInfo>` tree. Porting that pattern naively to Elixir would reproduce the flaw.

**How to avoid:**
Ignore `<KeyInfo>` in `<EncryptedKey>` entirely. The `KeyResolver` behaviour resolves the SP decryption key from configured private key material only — it does not inspect document-provided key identifiers. Never fetch any external URI from inside the XML document during decryption. This is the encryption-side mirror of CLAUDE.md invariant #1: "configured IdP certs only — NEVER trust document `KeyInfo`."

**Warning signs:**
Any code path that calls `KeyResolver.resolve/2` or equivalent with a URI or certificate fragment extracted from the `<KeyInfo>` inside the `<EncryptedKey>` element.

**Phase to address:**
ENC-01 Plan 1 (AlgorithmPolicy + crypto core). Document as a named invariant parallel to CLAUDE.md §1.

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Use RSA-PKCS1v1.5 for EncryptedKey (default in many RSA APIs) | Zero config, widely supported | Bleichenbacher oracle; complete session-key recovery | Never |
| Use AES-CBC for EncryptedData | Broad IdP support without GCM flag | Jager–Somorovsky padding oracle; assertion plaintext recovery | Only via time-boxed legacy escape hatch with explicit admin acknowledge |
| Share signing and encryption keypair | One cert to manage, simpler SP metadata | Key rotation breaks both concerns simultaneously; compromise of one exposes both | Never for new deployments |
| Store SP decryption private key in DB column | Consistent with other connection fields | Key leaked in DB breach, backup exfil, or diagnostic bundle share | Never |
| Expose distinct error atoms for decryption failures | Better observability for debugging | Behavioral oracle for Bleichenbacher/padding attacks | Never past the decryption boundary; log internally, expose only `:decryption_failed` externally |
| Skip re-parse after decryption for "simple" NameID extraction | Faster, less code | Parser differential attack; unsigned data consumed as verified | Never |
| Sign re-serialized parameters for redirect binding | Simpler code (encode map → sign) | Signature mismatches at IdP; or worse, IdP accepts different bytes than what SP signed | Never |

---

## Integration Gotchas

Common mistakes when connecting to external services.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| ADFS + signed AuthnRequests | Use SHA-256 for HTTP-Redirect binding by default | ADFS historically did not accept SHA-256 for redirect-binding signatures (only SHA-1). Verify ADFS version; ADFS 2019+ accepts SHA-256. Expose `sig_alg` as a per-connection override. |
| ADFS + encrypted assertions | Use the same cert for signing and encryption | ADFS assigns the encryption cert separately from the signing cert in Relying Party Trust configuration. Publish separate `<KeyDescriptor use="encryption">` in SP metadata. |
| Shibboleth IdP + `WantAuthnRequestsSigned` | Assume the flag means the same thing as ADFS | Shibboleth's `WantAuthnRequestsSigned` is advisory; the IdP will not necessarily reject unsigned requests. Shibboleth's own docs note this is not interoperable for unsolicited SSO. |
| Entra ID + EncryptedAssertion | Use default token signing cert for encryption | Entra requires a separate "Token Encryption" certificate uploaded to the Enterprise App configuration (not the token signing cert). Metadata endpoint must publish `use="encryption"` KeyDescriptor. |
| IdP-provided `<KeyInfo>` in `<EncryptedKey>` | Use document-provided key hint to select decryption key | Ignore completely; select decryption key from `KeyResolver` configuration only. |
| python3-saml + wantMessagesSigned + encryption | Treat them as compatible defaults | python3-saml issue #304: enabling both `wantMessagesSigned` and encrypted assertions causes "invalid response" — signature validation runs on encrypted bytes. In Relyra, ensure signature verification runs on decrypted bytes only, after re-parse. |

---

## Security Mistakes

Domain-specific security issues beyond general web security.

| Mistake | Risk | CVE / Reference |
|---------|------|-----------------|
| Accept RSA-PKCS1v1.5 for EncryptedKey | Full session key recovery in ~14,000 queries | Jager/Somorovsky CCS 2012; CVE-2021-29108 (ArcGIS) |
| Accept AES-CBC for EncryptedData | Assertion plaintext recovery in ~14 queries/byte | Jager/Somorovsky CCS 2011 |
| AES-GCM auth tag not length-validated | GHASH key recovery → forge arbitrary ciphertexts | GHSA-4v26-v6cg-g6f9 (xmlseclibs, CVSS 8.2) |
| Distinct decryption error atoms exposed externally | Behavioral oracle; distinguishes padding from wrong-key failures | CVE-2021-29108 (ArcGIS, "Given final block not properly padded" message) |
| Both cleartext + encrypted assertion in one response | Assertion injection allows impersonation | CVE-2026-2092 (Keycloak SAML broker) |
| Read assertion fields before XMLDSig verify | Attacker controls consumed identity data | CVE-2025-54419 (node-saml, CVSS 10.0); CVE-2022-39299 (passport-saml) |
| Parser differential: second parser on decrypted bytes | Signature verified over different content than consumed | CVE-2024-45409 (ruby-saml, CVSS 9.8); CVE-2025-25291/25292 (ruby-saml, CVSS 8.8) |
| Sign re-serialized redirect-binding params | Signature over different bytes than IdP verifies | FusionAuth URL-encoding bug; SAML Bindings spec §3.4.4.1 normative warning |
| Trust document `<KeyInfo>` in `<EncryptedKey>` for key selection | SSRF / key confusion attack pre-auth | Analogous to XMLDSig KeyInfo trust (Relyra invariant #1 already forbids for signatures) |
| SP private key stored in DB | Key leaked in breach / backup / diagnostic export | OWASP SAML Security Cheat Sheet; "Golden SAML" attack prerequisite |
| Shared signing/encryption keypair | Rotation coupling; single compromise exposes both | crewjam/saml default pattern; Shibboleth Concepts "A Primer on SAML Keys and Certificates" |

---

## "Looks Done But Isn't" Checklist

- [ ] **EncryptedAssertion decryption:** Decryption succeeds — but has the decrypted bytes been re-parsed through `PureBeam.parse_safely/2` AND passed through `do_verify/4` before any field is read?
- [ ] **AlgorithmPolicy:** RSA-PKCS1v1.5 rejection tested with adversarial corpus fixture, not just "not in the allowlist."
- [ ] **AlgorithmPolicy:** AES-CBC rejection tested with adversarial corpus fixture.
- [ ] **AES-GCM tag length:** Explicit `byte_size(auth_tag) == 16` guard present in the decryption path before calling `:crypto.crypto_one_time_aead/6`.
- [ ] **Error opaqueness:** All decryption failures from any branch (wrong key, bad tag, truncated tag, malformed plaintext, parse failure) return `:decryption_failed` and nothing else.
- [ ] **Ambiguous assertion:** Response with both `<Assertion>` and `<EncryptedAssertion>` returns `:ambiguous_assertion` before any crypto.
- [ ] **Key isolation:** SP metadata publishes two `<KeyDescriptor>` elements — `use="signing"` and `use="encryption"` — with distinct keys.
- [ ] **DB schema:** No Ecto migration column for SP private key material in any connection or cert schema.
- [ ] **Diagnostic bundle:** Allow-list serializer verified to exclude any `KeyResolver`-sourced private key material.
- [ ] **Redirect binding signature:** Signed over raw pre-built query string binary, not over a re-encoded map. Test includes a `bit-for-bit` golden output fixture committed to the corpus.
- [ ] **SP metadata:** `<KeyDescriptor use="signing">` published when `sign_authn_requests: true`, so IdPs can verify the request signature.
- [ ] **ADFS SHA-1 interop:** `sig_alg` override available per-connection for ADFS deployments that cannot accept SHA-256 on redirect binding.

---

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| PKCS1v1.5 shipped in production | HIGH | Emergency release to reject PKCS1v1.5 at AlgorithmPolicy gate; rotate SP decryption keypair immediately; treat all past assertions as potentially compromised; advisory disclosure |
| AES-CBC shipped in production | HIGH | Emergency release to reject CBC; rotate keypair; advisory disclosure |
| SP private key in DB | HIGH | Rotate key immediately; audit who had DB read access; disclosure if breach cannot be ruled out |
| Read-before-verify bug in production | HIGH | Emergency release; security advisory analogous to Relyra RELYRA-2026-001; regression fixture added to `adversarial_crypto_test.exs` |
| GCM tag not length-validated | HIGH | Emergency release; no key rotation required if no exploitation evidence, but treat as high severity |
| Distinct decryption error atoms exposed | MEDIUM | Patch release; coalesce to `:decryption_failed`; no key rotation required unless behavioral oracle was exploited |
| Redirect binding signing of re-serialized params | LOW | Patch release; fix raw-octet signing; no security impact (signatures just failed at IdP) |

---

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Read fields before verify (P1) | ENC-01 Plan 3 pipeline integration | Corpus row: encrypted-then-XSW → `:invalid_signature` (not data) |
| PKCS1v1.5 (P2) | ENC-01 Plan 1 AlgorithmPolicy | Corpus row: PKCS1v1.5 EncryptedKey → `:unsupported_key_transport_algorithm` |
| AES-CBC (P3) | ENC-01 Plan 1 AlgorithmPolicy | Corpus row: AES-CBC EncryptedData → `:unsupported_content_encryption_algorithm` |
| GCM tag truncation (P4) | ENC-01 Plan 1 crypto core | Corpus row: truncated auth tag → `:decryption_failed` |
| Error opaqueness (P5) | ENC-01 Plan 1 crypto core | Corpus row: repeated malformed ciphertexts → all return identical `:decryption_failed` |
| Cleartext + encrypted coexistence (P6) | ENC-01 Plan 3 pipeline integration | Corpus row: both Assertion + EncryptedAssertion → `:ambiguous_assertion` |
| Redirect binding raw-octet signing (P7) | AUTHN-01 Plan 1 signing primitive | Corpus row: golden bit-for-bit redirect query match; ADFS-style `+`-encoded variant |
| Signing/encryption key confusion (P8) | ENC-01 Plan 2 key management | SP metadata test: two distinct `<KeyDescriptor>` elements with `use` attributes |
| Private key in DB (P9) | ENC-01 Plan 2 key management | Schema review: no column for private key material; diagnostic bundle allow-list test |
| No re-parse after decrypt (P10) | ENC-01 Plan 3 pipeline integration | Corpus row: XSW on decrypted plaintext → `:invalid_signature` / `:digest_mismatch` |
| Document KeyInfo trust (P11) | ENC-01 Plan 1 crypto core | Unit test: KeyResolver called with only configured keys, ignoring document `<KeyInfo>` |
| ADFS SHA-1 interop (integration gotcha) | AUTHN-01 Plan 3 integration | Per-connection `sig_alg` override; ADFS runbook note in provider presets |

---

## Sources

- Jager & Somorovsky, "How to Break XML Encryption," CCS 2011 — AES-CBC padding oracle against XML-Enc
- Jager & Somorovsky, "Bleichenbacher's Attack Strikes Again: Breaking PKCS#1 v1.5 in XML Encryption," CCS 2012
- Compass Security Blog, "SAML Padding Oracle," September 2021 — CVE-2021-29108 (ArcGIS Portal) exploit chain
- GHSA-4v26-v6cg-g6f9 (robrichards/xmlseclibs) — AES-GCM auth tag truncation → GHASH key recovery
- CVE-2025-54419 / GHSA-4mxg-3p6v-xgq3 (node-saml, CVSS 10.0) — assertion loaded from unsigned original document
- CVE-2024-45409 (ruby-saml, CVSS 9.8) — `//ds:DigestValue` XPath anywhere-in-document selector
- CVE-2025-25291 + CVE-2025-25292 (ruby-saml, CVSS 8.8) — REXML/Nokogiri parser differential
- CVE-2026-2092 (Keycloak SAML broker) — encrypted assertion injection alongside valid signed assertion
- CVE-2022-39299 (passport-saml, CVSS 7.4) — improper signature verification bypass
- FusionAuth issue #1496 — URL-encoding case sensitivity in redirect-binding signature verification
- python3-saml issue #304 — `wantMessagesSigned` + encrypted assertions conflict (verify runs on encrypted bytes)
- crewjam/saml issue #270 — signed response + encrypted assertion: document replaced before signature check
- SAML Bindings spec §3.4.4.1 — normative requirement to sign raw URL-encoded octets
- W3C Blog, "Some notes on the recent XML Encryption attack," November 2011
- Shibboleth Concepts, "A Primer on SAML Keys and Certificates" — separation of signing and encryption keypairs
- WorkOS, "Understanding SAML Request Signing and Response Encryption" — key separation best practices

---
*Pitfalls research for: Adding EncryptedAssertion (XML-Enc) + Signed AuthnRequests to Relyra v1.3*
*Researched: 2026-05-25*
