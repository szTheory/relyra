---
phase: 35-signed-authnrequests-adfs-preset
verified: 2026-05-26T14:00:00Z
status: passed
score: 5/5 must-haves verified
overrides_applied: 0
---

# Phase 35: Signed AuthnRequests + ADFS Preset Verification Report

**Phase Goal:** An SP targeting an ADFS or locked-down Shibboleth IdP that requires `WantAuthnRequestsSigned` can complete login; the redirect-binding signature is byte-exact and verified against a committed golden output.
**Verified:** 2026-05-26T14:00:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A connection with `sign_authn_requests: true` produces a redirect URL whose `SAMLRequest`, `RelayState`, and `SigAlg` bytes are signed verbatim in spec order. | ✓ VERIFIED | `lib/relyra/protocol/binding.ex` assembles the signed octets in order and delegates to `Signature.sign_redirect_query/3`; `test/relyra/protocol/binding_test.exs`, `test/relyra_test.exs`, and `test/phoenix/login_controller_test.exs` cover the runtime path. |
| 2 | The bit-for-bit golden fixture and ADFS lowercase variant both pass, and re-serializing the query before signing changes the signature. | ✓ VERIFIED | `test/security/authn_request_signing_test.exs` rows 1-4 cover the golden fixture, ADFS-lower fixture, re-serialization regression, and round-trip public-key verification. `mix ci.security` ran these as the `:authn_request_signing` suite and passed. |
| 3 | A connection with `sign_authn_requests: false` still produces the unsigned redirect path and existing providers do not regress. | ✓ VERIFIED | AUTHN-01 corpus row 5 asserts no `SigAlg` or `Signature` keys on the unsigned path; `mix test --warnings-as-errors` passed with 666 tests, 0 failures. |
| 4 | SP metadata emits `AuthnRequestsSigned="true"` and a signing `KeyDescriptor` only when the toggle is on. | ✓ VERIFIED | `test/relyra/protocol/metadata_test.exs` covers both toggle-on and toggle-off cases; the implementation lives in `lib/relyra/protocol/metadata.ex`. |
| 5 | The ADFS preset defaults to signed requests and the ADFS runbook is published and docs-gated. | ✓ VERIFIED | `lib/relyra/provider/adfs.ex` and `test/provider/provider_test.exs` verify preset defaults; `guides/recipes/adfs.md` exists and `mix ci.docs` passed sequentially with the file-presence gate in `mix.exs`. |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/relyra/security/algorithm_policy.ex` | Outbound signing digest gate | ✓ VERIFIED | `signing_digest_atom/1` exists and is covered by `test/relyra/security/algorithm_policy_test.exs`. |
| `lib/relyra/security/signature.ex` | Raw-octet redirect signing primitive | ✓ VERIFIED | `sign_redirect_query/3` signs verbatim bytes and URL-encodes only the base64 signature output. |
| `lib/relyra/protocol/binding.ex` | Raw-DEFLATE signed redirect binding | ✓ VERIFIED | Signed redirect path emits `redirect_query` and supports `:rfc3986_upper` / `:adfs_lower`. |
| `lib/relyra/provider/adfs.ex` | ADFS preset module | ✓ VERIFIED | Exists and is registered through `lib/relyra/provider.ex`. |
| `guides/recipes/adfs.md` | ADFS operator runbook | ✓ VERIFIED | Published and guarded by `ci.docs`. |
| `test/security/authn_request_signing_test.exs` | AUTHN-01 adversarial corpus | ✓ VERIFIED | Five tagged rows run in `mix ci.security`. |
| `test/fixtures/security/authn_request_signing/` | Golden redirect-signing fixtures | ✓ VERIFIED | Golden XML, two golden query strings, signing PEM, and provenance manifest are all present. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `lib/relyra/protocol/binding.ex` | `lib/relyra/security/signature.ex` | `Signature.sign_redirect_query/3` | ✓ VERIFIED | Binding delegates the already-assembled octets to the signing seam. |
| `lib/relyra.ex` | `lib/relyra/protocol/binding.ex` | `start_login/3` signed branch | ✓ VERIFIED | Signed connections return `redirect_query`; unsigned connections preserve `redirect_params`. |
| `lib/relyra/phoenix/controllers/login_controller.ex` | Signed query bytes | verbatim append to `idp_sso_url` | ✓ VERIFIED | Signed path appends the prebuilt query bytes without `URI.encode_query/1`. |
| `mix.exs` | `test/security/authn_request_signing_test.exs` | `ci.security` subprocess line | ✓ VERIFIED | AUTHN-01 corpus is a dedicated security-lane command and registered in `test/security/ci_gate_integrity_test.exs`. |
| `guides/recipes/adfs.md` | `lib/relyra/provider/adfs.ex` | preset + runbook alignment | ✓ VERIFIED | The recipe documents the preset defaults and the toggle/encoding behavior the code now ships. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Full regression suite | `mix test --warnings-as-errors` | Passed, `666` tests, `0` failures | ✓ PASS |
| Security lane | `mix ci.security` | Passed, including `:authn_request_signing` corpus and meta-gate | ✓ PASS |
| Docs lane | `mix ci.docs` | Passed when run sequentially | ✓ PASS |
| Formatting | `mix format --check-formatted` | Exit 0 | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `AUTHN-01` | `35-01` / `35-02` / `35-05` / `35-07` / `35-08` | Signed redirect-binding AuthnRequests with golden corpus and raw-octet invariant | ✓ SATISFIED | Signing seam, signed runtime path, committed fixtures, and CI-gated corpus all present and green. |
| `AUTHN-02` | `32-02` / `35-03` / `35-05` | Per-connection `sign_authn_requests` toggle, default false, backward-compatible | ✓ SATISFIED | Schema field, runtime propagation, and unsigned-path regression checks are all present. |
| `AUTHN-03` | `35-06` | Metadata expresses signing posture only when enabled | ✓ SATISFIED | Metadata tests prove toggle-on / toggle-off behavior. |
| `AUTHN-04` | `35-04` / `35-09` | ADFS preset and ADFS operator runbook | ✓ SATISFIED | Preset module, provider tests, published recipe, and docs-lane gate all passed. |

### Anti-Patterns Found

No blocker or warning-level phase-specific anti-patterns were found in the Phase 35 implementation artifacts. The raw-octet invariant is explicitly covered by tests so the historical `URI.encode_query/1` re-serialization footgun now has a corpus guard.

### Human Verification Required

None. This phase's must-haves are all verifiable from code, fixtures, and CI lanes. The runbook documents ADFS operator commands, but Phase 35's requirement is publication and defaulting, not standing up a live ADFS environment inside this repo.

### Gaps Summary

No gaps found in the Phase 35 implementation itself. The earlier milestone-close note about a stale Phase 15 `human_needed` artifact has been resolved by the dedicated admin UI re-verification pass.

---

_Verified: 2026-05-26T14:00:00Z_  
_Verifier: Codex (gsd-verifier)_
