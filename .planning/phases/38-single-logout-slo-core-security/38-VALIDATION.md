# Phase 38 Validation Criteria

## Goal-Backward Validation

This document outlines the Nyquist goal-backward verification criteria for Phase 38 (Single Logout - SLO Core Security), ensuring that the `SLO-01` requirements and project security invariants are met.

### Truths (Observable Behaviors)
1. **SessionAdapter specified:** `SessionAdapter` provides `index_session/4` and `terminate_by_session_index/4` callbacks, allowing SAML SessionIndex decoupling from local sessions.
2. **Redirect Signatures Verified:** HTTP-Redirect bindings verify signatures strictly against raw query octets, bypassing XMLDSig entirely.
3. **Logout Message Pipeline Strictness:** Logout messages (both requests and responses) run through a strict Parse -> Verify -> Replay -> Execute pipeline. Reversing this sequence or bypassing steps is impossible.
4. **Replay Protection Enforced:** Replay protection is enforced on all consumed logout messages via `ReplayStore`.
5. **Facade Integration:** Host applications can start and consume logout flows via the primary `Relyra` API facade (`start_logout/3`, `consume_logout/3`).

### Artifacts (Required Files/Structures)
- `lib/relyra/session_adapter.ex`: Must contain the new callbacks and their public wrapper functions.
- `lib/relyra/security/signature.ex`: Must contain `verify_redirect_signature/4`.
- `lib/relyra/security/logout_validator.ex`: Must implement the strict validation pipeline for logout messages.
- `lib/relyra.ex`: Must expose `start_logout/3` and `consume_logout/3`.
- `priv/security_corpus.json` & `test/security/xml/adversarial_crypto_test.exs`: Must be updated to include and test HTTP-Redirect signature tampered payloads.

### Key Links (Critical Connections)
- **Signature Verification to Crypto:** `lib/relyra/security/signature.ex` must route to `:public_key.verify/4` utilizing the raw query octets.
- **Logout Validation to Replay Protection:** `lib/relyra/security/logout_validator.ex` must ensure `ReplayStore` is consulted before considering a message valid.
- **Facade to Session Adapter:** `Relyra.consume_logout/3` must successfully invoke `SessionAdapter.terminate_by_session_index/4` when a valid IdP-initiated logout request is received.

### Security Invariants Validated
- [ ] No second XML parse.
- [ ] Signature source is strictly configured IdP certs.
- [ ] Crypto is required (Redirect signature validated).
- [ ] Replay protection is enforced on logout payloads.