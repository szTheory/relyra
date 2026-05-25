---
phase: 33
slug: key-resolver-behaviour-xmlenc-crypto-core
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-25
---

# Phase 33 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Config → KeyResolver | SP private key PEM is sourced from `Application.get_env(:relyra, :sp_private_key_pem)` only — never from network input or assertion document. The `Relyra.KeyResolver` behaviour seam is the only crossing point. | RSA private key PEM (sensitive) |
| Adapter dispatch → caller | `KeyResolver.resolve/2` normalises all adapter results and exceptions to typed `{:error, %Error{}}` — raw exceptions never escape to callers. | Typed error structs (no key material) |
| Encrypted assertion bytes → SaxyTree | Raw untrusted network bytes cross into the parse layer via `SaxyTree.parse/1` only. No secondary parse paths permitted. | Untrusted XML bytes |
| Algorithm URI → AlgorithmPolicy | Document-supplied algorithm URIs cross into the policy gate; non-allowlisted URIs are rejected before any crypto operation begins. | Algorithm URI strings (untrusted) |
| KeyResolver → private key material | SP private key PEM returned from configured adapter; decoded key term stays in `defp` function scope inside `do_decrypt/4`. | RSA private key term (sensitive) |
| do_decrypt → plaintext bytes | Decrypted plaintext returned as `{:ok, binary()}` only. Phase 34 is responsible for re-parsing through PureBeam + `do_verify` before reading any identity field. | Decrypted assertion bytes (unverified until Phase 34) |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-33-P1-01 | Information Disclosure | `KeyResolver.resolve/2` error path | mitigate | `Error.new/3` details map never includes `pem_binary` value; only adapter atom and operation atom are logged. Verified: SUMMARY-01 D-03. | closed |
| T-33-P1-02 | Elevation of Privilege | Custom adapter substitution via `:key_resolver` opt | accept | Callers who can pass opts are already trusted (in-process, not user-input-controlled); the behaviour contract gates return type to `{:ok, binary()} \| {:error, Error.t()}`. | closed |
| T-33-P1-03 | Tampering | `adapter_dispatch_error` — exception message in details | mitigate | `Exception.message/1` output is included only in the `Error` details map (not emitted to Logger directly); sensitive PEM content would not appear in a normal OTP runtime exception message. Dispatch wraps in `try/rescue/catch`. Verified: SUMMARY-01. | closed |
| T-33-P1-SC | Tampering | Supply chain (npm/pip/cargo installs) | accept | No external packages installed in Plan 01; all code is pure Elixir with no new Hex dependencies. | closed |
| T-33-02-01 | Information Disclosure | RSA-PKCS1v1.5 padding oracle | mitigate | `AlgorithmPolicy.enforce_key_transport_algorithm/2` hard-blocks the PKCS1v1.5 URI (`xmlenc#rsa-1_5`); `decrypt/3` returns `:decryption_failed` before any RSA operation. Covered by xml_enc_test.exs Case 1. | closed |
| T-33-02-02 | Information Disclosure | Truncated GCM auth tag oracle | mitigate | `enforce_content_encryption_algorithm/3` with `auth_tag:` fires BEFORE `:crypto.crypto_one_time_aead/7`; `byte_size < 16` returns `:decryption_failed` opaquely. Covered by xml_enc_test.exs Case 3. | closed |
| T-33-02-03 | Information Disclosure | Error oracle via distinct error returns | mitigate | All failure paths (parse fail, policy reject, key fail, RSA fail, AEAD fail) return the same `:decryption_failed` atom; no structured `{:error, _}` return from `decrypt/3`. Verified: SUMMARY-02 D-01. | closed |
| T-33-02-04 | Tampering | Malformed PEM causes exception escape | mitigate | Outermost `rescue _ -> :decryption_failed` in `do_decrypt/4` wraps all OTP crypto calls including `pem_decode/pem_entry_decode/decrypt_private`. Verified: SUMMARY-02. | closed |
| T-33-02-05 | Elevation of Privilege | Document KeyInfo trust | mitigate | `KeyInfo` inside `EncryptedKey` is silently ignored (D-05); private key sourced exclusively from `KeyResolver` callback, never from document-supplied key material. `resolve_key/2` calls `apply(key_resolver_module, :resolve, [connection])` exclusively. | closed |
| T-33-02-06 | Tampering | Algorithm confusion (CBC vs GCM) | mitigate | `AlgorithmPolicy` blocks AES-CBC URI by default (`xmlenc#aes256-cbc` not in allowlist); no escape hatch in default policy. Covered by xml_enc_test.exs Case 2. | closed |
| T-33-02-07 | Information Disclosure | Private key leakage via logs/telemetry | mitigate | PEM binary and decoded `RSAPrivateKey` term remain as local variables inside `defp` functions; never assigned to a map key passed to Logger, telemetry, or `Error.new/3` details. Verified: SUMMARY-02 threat surface scan. | closed |
| T-33-02-08 | Tampering | Second XML parse via `:xmerl` or regex bypass | mitigate | `XMLEnc` uses only `SaxyTree.parse/1` (the single hardened parse seam); no `:xmerl`, no regex, no secondary parse. `:xmerl` mention removed from code comments to satisfy `ParserPathGuard` Mix compiler. Verified: SUMMARY-02 deviation log. | closed |
| T-33-02-09 | Tampering | Plaintext bytes read before re-verify | accept | Phase 33 returns `{:ok, plaintext_bytes}` without identity field access; Phase 34 is responsible for the decrypt-then-reparse+verify invariant; no identity fields are readable from `XMLEnc` output. | closed |
| T-33-02-SC | Tampering | Supply chain (npm/pip/cargo installs) | accept | No external packages installed in Plan 02; all crypto is OTP stdlib (`:public_key`, `:crypto`). No new Hex dependencies. | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-33-01 | T-33-P1-02 | `:key_resolver` opt callers are in-process (Phoenix conn pipeline, not user-controlled input). Behaviour contract enforces `{:ok, binary()} \| {:error, Error.t()}` return type, bounding adapter trust surface. | szTheory | 2026-05-25 |
| AR-33-02 | T-33-P1-SC | Plan 01 introduces no new Hex dependencies. Pure Elixir behaviour/dispatch pattern. | szTheory | 2026-05-25 |
| AR-33-03 | T-33-02-09 | `XMLEnc.decrypt/3` is a raw crypto primitive; identity extraction is deferred to Phase 34 which must re-parse plaintext bytes through PureBeam + `do_verify`. This layered design prevents premature identity trust. | szTheory | 2026-05-25 |
| AR-33-04 | T-33-02-SC | Plan 02 introduces no new Hex dependencies. All crypto uses OTP `:public_key` and `:crypto` stdlib. | szTheory | 2026-05-25 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-25 | 14 | 14 | 0 | gsd-secure-phase (State B — from artifacts; register_authored_at_plan_time: true; short-circuit to write) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-25
