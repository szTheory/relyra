# Technology Stack

**Project:** Relyra v1.3 — Advanced Federation (Encrypted Assertions + Signed AuthnRequests)
**Researched:** 2026-05-25
**Overall confidence:** HIGH — all function signatures live-verified on OTP 28; OTP 26/27 sources cross-checked via GitHub

---

## Executive Finding

**Zero new Hex dependencies.** Every cryptographic operation required for v1.3 is covered by OTP
stdlib modules. The full pipeline — RSA-OAEP key transport, AES-GCM content decryption, RSA-SHA256
redirect-binding signing, and DEFLATE compression for the query string — is available in `:public_key`,
`:crypto`, and `:zlib`. Adding a NIF-based XML-Enc library would add supply-chain risk, a new
maintenance surface, and a second code path into the XML trust boundary. None of that is justified
when OTP already provides everything needed.

---

## Recommended Stack — New Capabilities

### Encrypted Assertions (ENC-01): RSA-OAEP Key Transport

**Module:** `:public_key`
**Function:** `:public_key.decrypt_private/3`
**Signature (OTP 26/27/28 — unchanged):**
```erlang
decrypt_private(CipherText :: binary(), Key :: rsa_private_key(), Options :: pk_encrypt_decrypt_opts()) -> PlainText :: binary()
```

**Calling convention for RSA-OAEP:**
```elixir
:public_key.decrypt_private(encrypted_key_bytes, rsa_private_key_record, [{:rsa_padding, :rsa_pkcs1_oaep_padding}])
```

**Critical behaviour:** raises `ErlangError` on wrong key or malformed ciphertext — MUST wrap in `try/rescue`,
same discipline as the existing `safe_verify/4` in `Relyra.Security.Signature`. Wrong-key decryption
emits `{:error, {"pkey.c", 1474}, "Couldn't get the result"}` (OpenSSL opaque string).

**Key loading path:** `[priv_entry] = :public_key.pem_decode(pem); sp_priv_key = :public_key.pem_entry_decode(priv_entry)`
→ returns `{:RSAPrivateKey, ...}` record that `decrypt_private/3` accepts. Live-verified on OTP 28.

**OAEP hash note:** `:rsa_pkcs1_oaep_padding` uses SHA-1 as the MGF1 hash (the XML-Enc standard
default per `http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p`). SHA-256 OAEP (`xmlenc11#rsa-oaep`
with `ds:DigestMethod Algorithm="sha256"`) is NOT supported via this OTP API — OTP does not expose
`{:rsa_oaep_hash, :sha256}` option (tested on OTP 28; the option raises `{:badarg, "Unknown option"}`).
In practice this is not a blocker: Okta, Entra, ADFS, and Shibboleth all emit SHA-1 OAEP key
transport when encrypting assertions. The AlgorithmPolicy extension for ENC-01 should map
`http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p` to `:allowed` and map
`http://www.w3.org/2009/xmlenc11#rsa-oaep` to `:blocked_pending_otp_support` with an explanatory
error atom (not silently allowed, not silently failed).

**Reject RSA-PKCS1v1.5:** AlgorithmPolicy must explicitly reject
`http://www.w3.org/2001/04/xmlenc#rsa-1_5` (Bleichenbacher). OTP 28 flags `decrypt_private` itself
as "Legacy RSA Encryption API — do not use with rsa_pkcs1_padding" in its docs. This reinforces the
design to route through AlgorithmPolicy before ever calling `decrypt_private`.

---

### Encrypted Assertions (ENC-01): AES-GCM Content Decryption

**Module:** `:crypto`
**Function:** `:crypto.crypto_one_time_aead/7`
**Signature (OTP 22+ through OTP 28 — unchanged):**
```erlang
crypto_one_time_aead(Cipher, Key, IV, InText, AAD, TagOrTagLength, EncFlag) -> Result
```

**CRITICAL argument order — InText BEFORE AAD:**
```
(Cipher, Key, IV, InText :: iodata(), AAD :: iodata(), TagOrTagLength, EncFlag :: boolean())
```

This order is consistent across OTP 26, 27, and 28 (all sourced from GitHub). An empty `AAD = <<>>`
is correct and required — passing `<<>>` as `InText` produces zero-byte ciphertext (verified:
the function encrypts the InText arg, not the AAD arg).

**Calling convention for AES-256-GCM decrypt (XML-Enc format):**
```elixir
# XML-Enc CipherValue layout: IV (12 bytes) || Ciphertext || AuthTag (16 bytes)
iv   = :binary.part(cipher_value, 0, 12)
ct   = :binary.part(cipher_value, 12, total - 12 - 16)
tag  = :binary.part(cipher_value, total - 16, 16)
:crypto.crypto_one_time_aead(:aes_256_gcm, aes_key, iv, ct, <<>>, tag, false)
# Returns plaintext binary | :error
```

**Authentication failure:** returns atom `:error` (does NOT raise) when tag check fails — safe to
pattern-match directly. Tampered ciphertext live-verified: `:error` returned, not an exception.

**Supported ciphers (OTP 28):** `:aes_128_gcm`, `:aes_192_gcm`, `:aes_256_gcm` — all confirmed via
`:crypto.supports(:ciphers)`. Use `:aes_256_gcm` as the default; allow `:aes_128_gcm` with an
explicit policy entry.

**Reject AES-CBC:** `http://www.w3.org/2001/04/xmlenc#aes256-cbc` and `#aes128-cbc` must be
blocked by AlgorithmPolicy default (Jager–Somorovsky padding oracle). AES-CBC for content
encryption is technically available via `:crypto.crypto_one_time/5` (no auth tag) but the
padding-oracle risk class is the same reason we reject AES-CBC by default and require an explicit,
audited, time-boxed escape hatch — same mechanism as SHA-1 override.

**NIST test vector verified:** AES-256-GCM with K=0×32, IV=0×12, PT=0×16, AAD='' produces
`cea7403d4d606b6e074ec5d3baf39d18` / `d0d1c8a799996bf0265b98b5d48ab919` on OTP 28. Correct.

---

### Signed AuthnRequests (AUTHN-01): HTTP-Redirect Binding Signing

**Module:** `:public_key`
**Function:** `:public_key.sign/3`
**Signature (OTP 26/27/28 — unchanged):**
```erlang
sign(Msg :: binary() | {digest, binary()}, DigestType :: digest_type(), Key :: private_key()) -> Signature :: binary()
```

**Calling convention for redirect-binding query signing:**
```elixir
# SAML spec §3.4.4.1: sign the raw query-string octet string, NOT a re-serialized map.
# Build exactly: SAMLRequest=<url-encoded>&RelayState=<url-encoded>&SigAlg=<url-encoded>
# Order: SAMLRequest first, RelayState only when present, SigAlg last.
raw_query_string_octets = "SAMLRequest=...&RelayState=...&SigAlg=..."
signature_bytes = :public_key.sign(raw_query_string_octets, :sha256, sp_rsa_private_key)
signature_b64 = Base.encode64(signature_bytes)
```

**Default algorithm:** RSA-SHA256 (`:sha256` digest atom, `http://www.w3.org/2001/04/xmldsig-more#rsa-sha256`).
PKCS#1 v1.5 padding is the default and is correct for SAML Redirect binding (no explicit padding opt needed).

**Key format:** same `{:RSAPrivateKey, ...}` record loaded via `pem_entry_decode` — same pattern as
the IdP-cert-extraction code in `signature.ex`. No new key-loading mechanism needed.

**Result size:** 256 bytes for RSA-2048 key, base64-encodes to 344 characters. Live-verified on OTP 28.

**Tampered-input test:** `verify(tampered, :sha256, sig, pub_key)` returns `false` — does not raise.
Existing `safe_verify/4` already wraps exceptions; the new signing path does not need an equivalent
rescue because signing raises only on a malformed KEY, not on a signing operation.

---

### HTTP-Redirect Binding: DEFLATE Compression

**Module:** `:zlib`
**Functions:** `:zlib.open/0`, `:zlib.deflateInit/6`, `:zlib.deflate/3`, `:zlib.deflateEnd/1`, `:zlib.close/1`
**SAML-spec DEFLATE format:** raw DEFLATE (no zlib header/trailer), window size `-15`:

```elixir
z = :zlib.open()
:zlib.deflateInit(z, :best_compression, :deflated, -15, 8, :default)
compressed = :zlib.deflate(z, saml_request_xml, :finish)
:zlib.deflateEnd(z)
:zlib.close(z)
deflated = IO.iodata_to_binary(compressed)
```

**Inflate (for test round-trip / response parsing):**
```elixir
z = :zlib.open()
:zlib.inflateInit(z, -15)
inflated = :zlib.inflate(z, compressed)
:zlib.inflateEnd(z)
:zlib.close(z)
```

`:zlib` is already used in the ecosystem for SAML redirect binding (samly, ruby-saml, python3-saml
all use the same `-15` window spec). Live round-trip verified on OTP 28.

---

### Existing Functions Verified for Continued Use in v1.3

These are currently used in `Relyra.Security.Signature` and are confirmed correct for OTP 28:

| Function | Usage | OTP 28 Status |
|----------|-------|---------------|
| `:public_key.pem_decode/1` | Load SP private key | Unchanged |
| `:public_key.pem_entry_decode/1` | Decode PEM entry to RSAPrivateKey | Unchanged |
| `:public_key.pkix_decode_cert/2` | Extract IdP public key from cert | ASN.1 modules replaced in OTP 28 (Public_Key 1.18 / OTP-19612) but documented API kept compatible — adversarial corpus (6/6 tests) passes on OTP 28 |
| `:public_key.verify/4` | SignedInfo RSA signature check | Unchanged |
| `:crypto.hash/2` | DigestValue recompute | Unchanged |
| `:crypto.hash_equals/2` | Constant-time digest comparison (OTP 25.2+) | Unchanged |

---

## OTP Version Matrix

| Feature | OTP 26 | OTP 27 | OTP 28 | Notes |
|---------|--------|--------|--------|-------|
| `decrypt_private/3` with `:rsa_pkcs1_oaep_padding` | ✓ | ✓ | ✓ | Stable since OTP R14B |
| `crypto_one_time_aead/7` with `(Cipher,Key,IV,InText,AAD,TagLen,Flag)` | ✓ | ✓ | ✓ | Stable since OTP 22.0; InText BEFORE AAD is correct across all three |
| `sign/3` RSA-SHA256 | ✓ | ✓ | ✓ | Stable |
| `:zlib` raw DEFLATE (`-15` window) | ✓ | ✓ | ✓ | Stable |
| `hash_equals/2` | ✓ | ✓ | ✓ | Added OTP 25.2; safe for matrix |
| `pkix_decode_cert/2` + `OTPCertificate` record | ✓ | ✓ | ✓ | OTP 28 replaced ASN.1 modules but kept API compatible (verified by running adversarial corpus) |
| RSA-OAEP with SHA-256 hash (`{:rsa_oaep_hash, :sha256}`) | ✗ | ✗ | ✗ | Not exposed by OTP; AlgorithmPolicy must block this URI until a future OTP adds it |

---

## What NOT to Add

| Rejected Option | Reason |
|-----------------|--------|
| `xmlenc` / `exml` / NIF-based XML-Enc libraries | Would create a second XML parsing entry point, bypassing the hardened saxy seam (violates SEC-01 invariant). Supply-chain risk. Zero benefit since OTP covers all needed crypto. |
| `libgcrypt` / `rustler_precompiled` NIFs for crypto | OTP's OpenSSL-backed crypto is already FIPS-grade. A Rust NIF adds compilation complexity and breaks the pure-BEAM security audit story without adding capability. |
| `erlang-jose` / `ex_crypto` | These provide JWT/JWK APIs, not XML-Enc. Their RSA/AES wrappers call the same `:public_key`/`:crypto` NIFs underneath — net add is zero capability with added indirection. |
| POST binding enveloped XML signing | Requires C14N over a new XML document + `ds:Signature` injection — more complex than redirect signing; deferred to v1.4. Not needed for initial ADFS/Shibboleth interop (they primarily use redirect binding for SP AuthnRequests). |

---

## AlgorithmPolicy Extension Requirements

The existing `AlgorithmPolicy` struct needs two new allowlist dimensions for v1.3:

**Key Transport Methods** (new field, e.g. `allowed_key_transport_methods`):
- Default allow: `http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p` (RSA-OAEP SHA-1)
- Default block: `http://www.w3.org/2001/04/xmlenc#rsa-1_5` (Bleichenbacher — hard reject, no escape hatch)
- Default block: `http://www.w3.org/2009/xmlenc11#rsa-oaep` (OAEP SHA-256 — unsupported in OTP; block until OTP exposes it)

**Content Encryption Methods** (new field, e.g. `allowed_content_encryption_methods`):
- Default allow: `http://www.w3.org/2009/xmlenc11#aes256-gcm` (AES-256-GCM)
- Default allow: `http://www.w3.org/2009/xmlenc11#aes128-gcm` (AES-128-GCM)
- Default block: `http://www.w3.org/2001/04/xmlenc#aes256-cbc` (padding oracle — escape hatch same as SHA-1: time-boxed, audited)
- Default block: `http://www.w3.org/2001/04/xmlenc#aes128-cbc` (same)

**Signing Digest Methods** (extend existing `allowed_signature_methods`):
- For AuthnRequests, reuse existing `digest_atom_for_signature_method/1` mapping (`:sha256` for RSA-SHA256)

---

## No New Hex Dependencies

Confirmed dependency list delta: **zero new entries** in `mix.exs`.

All required OTP modules (`:public_key`, `:crypto`, `:zlib`) are standard Erlang/OTP applications
already present in any OTP 26+ runtime. The existing `mix.exs` `elixir: "~> 1.19"` + `OTP 26+`
matrix covers everything needed for v1.3.

---

## Sources

- OTP 26.2.5 source: `lib/crypto/src/crypto.erl`, `lib/public_key/src/public_key.erl` — confirmed argument order for `crypto_one_time_aead/7` and specs for `decrypt_private/3`, `sign/3`
- OTP 27.3.3 source: same files — confirmed argument order unchanged
- OTP 28.0 source: same files + `lib/public_key/doc/notes.md` (OTP-19612 ASN.1 compatibility note)
- OTP 28 `crypto` docs: `https://www.erlang.org/docs/28/apps/crypto/crypto` — confirmed `crypto_one_time_aead/7` spec
- NIST AES-256-GCM test vector (K=0×32, IV=0×12, PT=0×16, AAD='') — verified live on OTP 28
- Live verification: all function signatures tested interactively on OTP 28 / Elixir 1.19.5
- Adversarial crypto corpus: `mix test test/security/xml/adversarial_crypto_test.exs --only adversarial_crypto` — 6/6 pass confirming OTPCertificate decode compatibility in OTP 28
- Investigation threads: `.planning/threads/encrypted-assertions-investigation.md`, `.planning/threads/signed-authn-requests-investigation.md`
- SAML 2.0 Bindings spec §3.4.4.1 — normative source for redirect-binding query string signing order
- XML Encryption Syntax and Processing Version 1.1 — IV layout for AES-GCM CipherValue
