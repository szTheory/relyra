---
phase: 34-validationpipeline-wiring-enc-01-complete
plan: 01
subsystem: protocol-metadata
tags: [enc-02, sp-metadata, key-descriptor, xml-enc]
requires:
  - Phase 33 SP key seam convention (`:sp_private_key_pem` `:_pem` config pattern; the
    public-cert siblings `:sp_signing_cert_pem` / `:sp_encryption_cert_pem` are net-new here)
  - XMLEnc accept-list URIs (`lib/relyra/security/xml_enc.ex` — xmlenc# aes256-gcm / aes128-gcm / rsa-oaep-mgf1p)
provides:
  - "build_sp_metadata/2 emitting <md:KeyDescriptor use=\"signing\"> + use=\"encryption\" in schema-valid SPSSODescriptor order"
  - "Encryption KeyDescriptor advertising the xmlenc# EncryptionMethod accept-list so an IdP can encrypt assertions to the SP (ENC-02)"
affects:
  - lib/relyra/protocol/metadata.ex
  - test/relyra/protocol/metadata_test.exs
tech-stack:
  added: []
  patterns:
    - "Cert PEM -> base64-of-DER via Base.encode64(elem(hd(:public_key.pem_decode(pem)), 1)) (mirrors signature.ex:288-289), nil-safe"
    - "PUBLIC-cert-only config read: :sp_signing_cert_pem / :sp_encryption_cert_pem; never private key material"
key-files:
  created:
    - test/relyra/protocol/metadata_test.exs
  modified:
    - lib/relyra/protocol/metadata.ex
decisions:
  - "Two distinct real self-signed cert PEMs in the test (fresh keypair per call) — SC#4 requires distinct KeyDescriptor ELEMENTS, not distinct cert bytes; distinct certs satisfy both."
  - "EncryptionMethod URIs match the decryptor accept-list (xmlenc#), NOT the xmlenc11# spec menu — advertising an algorithm the SP hard-rejects would invite unrecoverable ciphertext (T-34-03)."
  - "Signing descriptor emitted UNCONDITIONALLY (D-05); Phase 35 owns toggle-gating. Absent cert config yields an empty X509Certificate body, never a crash."
metrics:
  duration: 2m
  completed: 2026-05-25
  tasks: 2
  files: 2
---

# Phase 34 Plan 01: SP Metadata Encryption KeyDescriptor Summary

SP metadata now publishes both a `<md:KeyDescriptor use="signing">` and a distinct
`<md:KeyDescriptor use="encryption">` (advertising the xmlenc# AES-GCM / RSA-OAEP accept-list)
inside `<md:SPSSODescriptor>`, in schema-valid order, sourced from PUBLIC-cert app config —
satisfying ENC-02 / SC#4.

## What Was Built

**Task 1 — `build_sp_metadata/2` emits both KeyDescriptors (`b562482`)**
- Extended the heredoc builder to splice two `<md:KeyDescriptor>` elements into
  `<md:SPSSODescriptor>` BEFORE `<md:AssertionConsumerService>` (schema-valid child order,
  T-34-02): `use="signing"` first, then `use="encryption"`.
- Certs read from net-new PUBLIC config seams `Application.get_env(:relyra, :sp_signing_cert_pem)`
  and `:sp_encryption_cert_pem` — never private key material (T-34-01).
- Private `cert_body/1` helper converts PEM -> DER -> base64 via
  `Base.encode64(elem(hd(:public_key.pem_decode(pem)), 1))` (mirrors signature.ex:288-289);
  nil-safe — absent config returns `""` so the XML stays well-formed and never raises.
- Encryption descriptor advertises three `<md:EncryptionMethod>` URIs from the XMLEnc accept-list
  (aes256-gcm, aes128-gcm, rsa-oaep-mgf1p), with `<ds:KeyInfo>` before `<md:EncryptionMethod>`
  (T-34-03 / schema order).

**Task 2 — metadata test asserting SC#4 (`a4a68e8`)**
- New `test/relyra/protocol/metadata_test.exs` (7 tests, 0 failures).
- Asserts both descriptors present; byte-offset ordering (signing < encryption < ACS via
  `:binary.match`); each `<ds:X509Certificate>` body is base64-of-DER (no `-----BEGIN` armor,
  no embedded newline, round-trips via `Base.decode64`); KeyInfo precedes EncryptionMethod;
  aes256-gcm advertised and `xmlenc11#` absent.
- Absent-config test proves `build_sp_metadata/2` does not raise and still emits both descriptors
  with empty `<ds:X509Certificate></ds:X509Certificate>` bodies.
- `setup` wires two distinct real self-signed cert PEMs with `on_exit` cleanup.

## Verification

- `mix compile --warnings-as-errors` — clean.
- `mix test test/relyra/protocol/metadata_test.exs --warnings-as-errors` — 7 tests, 0 failures.
- `mix format --check-formatted` — exit 0.
- Wave-merge regression: `mix test --warnings-as-errors` — 607 tests, 0 failures (change is additive).

## Threat Model Compliance

| Threat ID | Disposition | Status |
|-----------|-------------|--------|
| T-34-01 (Info Disclosure: cert source) | mitigate | Builder reads ONLY `:sp_signing_cert_pem` / `:sp_encryption_cert_pem`; source contains no private-key config literal. |
| T-34-02 (Tampering: schema ordering) | mitigate | KeyDescriptors emitted before AssertionConsumerService; KeyInfo before EncryptionMethod; ordering asserted by byte-offset test. |
| T-34-03 (Spoofing: advertised algorithms) | mitigate | Advertises EXACTLY the xmlenc# decryptor accept-list; `xmlenc11#` asserted absent. |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Reworded source comments to avoid forbidden literal substrings**
- **Found during:** Task 1 acceptance verification.
- **Issue:** Initial comments mentioned `sp_private_key_pem` and `xmlenc11#` as the things NOT to
  use. The acceptance criteria are literal substring checks ("source does NOT contain
  `sp_private_key_pem`"); a literal grep would fail even though the security intent (never read the
  private key, never advertise xmlenc11#) was satisfied.
- **Fix:** Reworded the explanatory comments ("private key material" / "later-spec OAEP URI")
  while keeping the security guidance. No behavioral change.
- **Files modified:** lib/relyra/protocol/metadata.ex
- **Commit:** b562482

## Known Stubs

None. The signing descriptor is emitted unconditionally by design (D-05); the empty-body path on
absent config is an intentional, documented well-formed-XML behavior, not a stub — Phase 35 layers
toggle-gating on top of the unconditional signing descriptor.

## Self-Check: PASSED

- FOUND: lib/relyra/protocol/metadata.ex
- FOUND: test/relyra/protocol/metadata_test.exs
- FOUND commit: b562482 (feat — KeyDescriptor emission)
- FOUND commit: a4a68e8 (test — SC#4 assertions)
