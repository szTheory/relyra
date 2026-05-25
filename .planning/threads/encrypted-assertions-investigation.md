# Investigation: Encrypted Assertions (EncryptedAssertion / XML-Enc)

Status: OPEN — researched 2026-05-25; not yet in a milestone
Priority: High (B1 from Strategic Assessment 2026-05-23)
Depends: v1.1 XMLDSig verification (DONE — v1.2.0)

## Technical approach

- **Pipeline:** decrypt (XML-Enc) → re-parse through SAME hardened saxy seam → existing `verify` → protocol-validate.
  Never read any field from a decrypted-but-unverified assertion.
- **Key transport:** RSA-OAEP (default). **Reject RSA-PKCS1v1.5 (Bleichenbacher)** via AlgorithmPolicy.
- **Content encryption:** AES-GCM (default). **Reject AES-CBC (Jager–Somorovsky padding oracle)** via AlgorithmPolicy.
  Same escape-hatch override mechanism as SHA-1: time-boxed, audit-logged.
- **Error taxonomy:** Single opaque `:decryption_failed` for ALL decryption failures — no oracle in the error atom.
- **Simultaneous cleartext+encrypted assertion:** reject immediately; never process both.
- **SP decryption key:** via `KeyResolver` behaviour (PEM config default + KMS hook). Never store raw private key in
  DB schema or surface in diagnostics. Extend cert inventory with `party:` / `use:` fields to prevent key confusion
  with the existing signing cert inventory (key-confusion blast radius — isolate in its own plan).
- **Metadata:** publish SP encryption `KeyDescriptor use="encryption"` in the metadata endpoint.

## Adversarial corpus additions (for `mix ci.security`)

| Fixture | Expected outcome |
|---------|-----------------|
| RSA-OAEP + AES-GCM encrypted assertion → decrypt → verify | `{:ok, %SignedNode{}}` |
| RSA-PKCS1v1.5 encrypted assertion | `:unsupported_key_transport_algorithm` |
| AES-CBC encrypted assertion | `:unsupported_content_encryption_algorithm` |
| Padding-oracle probe (malformed ciphertext, repeated) | `:decryption_failed` (opaque, no oracle) |
| Encrypted-then-XSW: XSW attack on decrypted plaintext | `:invalid_signature` or `:digest_mismatch` (re-parse catches it) |
| Both cleartext + encrypted assertion in same response | `:ambiguous_assertion` |
| Encrypted NameID mapping | verifies + maps correctly |

## Implementation plan estimate (~4 plans)

1. **AlgorithmPolicy extension + crypto core:** OAEP/GCM allowlist, `KeyResolver` behaviour, RSA decrypt + AES-GCM unwrap in pure-BEAM (`:public_key` + `:crypto`)
2. **Key management + schema:** `KeyResolver` PEM default impl, cert inventory `party:` / `use:` extension, `KeyResolver` KMS stub
3. **Pipeline integration + re-parse:** wire `decrypt_assertion/3` into `do_verify` before the parse step; route decrypted bytes through `PureBeam.parse_safely/2`; extend metadata endpoint to publish `KeyDescriptor`
4. **Adversarial corpus + metadata + conformance:** all fixtures above wired into `ci.security`; CONFORMANCE.md updated; provider runbooks updated (Entra encrypted-assertion enable guide)

## Relevant prior art

- **ruby-saml** XML-Enc implementation — clean model for the decrypt-then-re-validate pipeline
- **python3-saml** encrypted assertion support — good error-opaqueness example
- **crewjam/saml** (Go) — shows the key-confusion pitfall with shared signing/encryption certs
- **Erlang stdlib:** `:public_key.decrypt_private/3` for RSA-OAEP; `:crypto.crypto_one_time_aead/6` for AES-GCM
- **SAML 2.0 XML-Enc spec:** Assertions and Protocols §3.3; XML-Enc §5 (key transport) + §5.2 (content encryption)

## Open questions for milestone planning

- Does `KeyResolver` need async/KMS-native support in v1.3, or is PEM config sufficient? (Recommend: PEM default in v1.3; KMS stub as a documented extension point)
- Do we need to handle encrypted attributes (`EncryptedAttribute`) in v1.3, or just `EncryptedAssertion`? (Recommend: both — same pipeline; smaller effort than a separate milestone)
