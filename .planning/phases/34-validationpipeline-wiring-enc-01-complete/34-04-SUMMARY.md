---
phase: 34-validationpipeline-wiring-enc-01-complete
plan: 04
subsystem: security
tags: [xml-enc, encrypted-assertion, adversarial-corpus, ci-security, read-before-verify, saml, ENC-01]

# Dependency graph
requires:
  - phase: 34-02
    provides: "FakeIdP.encrypt/2 + encrypted_response/2 canonical generator + enc_algorithm_uris/0"
  - phase: 34-03
    provides: "ValidationPipeline :decrypt_assertion pre-stage + :ambiguous_assertion typed error + encrypted-only parse tolerance"
  - phase: 30
    provides: "ci.security per-suite `cmd mix test` hollow-gate discipline + ci_gate_integrity_test.exs meta-gate"
provides:
  - "test/security/xml_enc_adversarial_test.exs — pipeline-level ENC-01 corpus: positive control + 7 named fixtures + 1 bonus multi-encrypted fixture (exact %Error{type:} pins)"
  - "ci.security gains the corpus as its own `cmd mix test ... --warnings-as-errors` subprocess line (non-hollow, meta-gate enforced)"
  - "XmldsigSigner :assertion_namespace opt (default off) — signs the Assertion WITH its default namespace so the encrypted path's digest survives decrypt -> splice -> re-parse"
affects: [ENC-01, encrypted-assertion-interop]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pipeline-level adversarial corpus driven end-to-end through ValidationPipeline.run/4 via the single canonical FakeIdP.encrypt/encrypted_response generator (no divergent recipe, Pitfall 1)"
    - "Opaque-error enforcement: 5 crypto/policy fixtures all pin the SINGLE :decryption_failed atom (no oracle, T-34-13)"
    - "Pre-crypto-reject ordering proven via would-fail-decrypt ciphertext: :ambiguous_assertion fires before any decrypt (T-34-14)"
    - "Read-before-verify guard: tampered-then-encrypted assertion proves a verification-stage error AND no identity leak (T-34-12)"

key-files:
  created:
    - test/security/xml_enc_adversarial_test.exs
  modified:
    - mix.exs
    - test/security/ci_gate_integrity_test.exs
    - lib/relyra/test_support/xmldsig_signer.ex
    - lib/relyra/test_support/fake_idp.ex

key-decisions:
  - "Drive the read-before-verify fixture (7) through ValidationPipeline.run/4 (not consume_response/3): the pipeline returns %Error{} (never a login map) on rejection, so identity-leak is asserted directly on the typed error; this exercises the full decrypt -> re-parse -> verify path without the heavier connection-resolution plumbing consume_response/3 requires"
  - "Rule 1 fix lives in the signer (assertion_namespace opt) + FakeIdP.signed_assertion_fragment/1, NOT in the corpus test: the digest must be computed over the namespaced Assertion the verifier re-canonicalizes post-decrypt; the prior post-hoc namespace re-declaration invalidated the digest"
  - "wrong-key fixture (1) builds via FakeIdP.encrypt/3 against a throwaway pubkey + manual envelope (encrypted_response/2 hardcodes the SP key) — still the single canonical encrypt recipe, just a different target key"
  - "ci_gate_integrity_test.exs @gated_suites gains the corpus (nil tag — whole file runs) so the anti-hollow meta-gate enforces the new line is present, named, and a `cmd mix test` step (T-34-15)"

patterns-established:
  - "assertion_namespace signer opt: sign-then-encrypt fixtures must hash the namespaced Assertion so decrypt -> splice -> re-parse preserves the digest (T-34-04)"

requirements-completed: [ENC-01]

# Metrics
duration: 7min
completed: 2026-05-25
---

# Phase 34 Plan 04: Pipeline-Level ENC-01 Adversarial Corpus Summary

**A permanent, pipeline-level encrypted-assertion adversarial corpus driving end-to-end through `ValidationPipeline.run/4`: a positive control proving decrypt -> re-parse -> verify -> identity-read ordering, the 7 named ENC-01 fixtures each pinning their exact typed error (5 collapse to the single opaque `:decryption_failed`, fixture 5 to `:ambiguous_assertion` before crypto), a read-before-verify guard proving no identity leaks before verification (CVE-2025-54419 class), and a supplemental multi-encrypted bonus — wired into `mix ci.security` as its own non-hollow subprocess line.**

## Performance

- **Duration:** ~7 min
- **Started:** 2026-05-25T20:10:38Z
- **Completed:** 2026-05-25T20:18:00Z
- **Tasks:** 2
- **Files modified:** 4 (1 created, 3 modified)

## Accomplishments

- Created `test/security/xml_enc_adversarial_test.exs` (9 tests): a positive control (SC#1) + the 7 named ENC-01 fixtures + 1 supplemental bonus multi-encrypted fixture, all driven end-to-end through `ValidationPipeline.run/4` using the single canonical `FakeIdP.encrypt`/`encrypted_response` generator (Plan 02) and the `:decrypt_assertion` pre-stage (Plan 03).
- **Positive control (SC#1):** a genuine `FakeIdP.encrypted_response()` logs in `{:ok, login_result}` with `name_id`/`issuer` present — proving the inner Assertion was decrypted, re-parsed via `parse_safely/2`, AND verified via `Signature.verify/4` BEFORE any identity field was read.
- **Fixtures 1,2,3,4,6** all pin the SINGLE opaque `%Error{type: :decryption_failed}` (wrong-key, truncated GCM tag, PKCS1v1.5 transport, AES-CBC content, malformed ciphertext) — the no-oracle property (T-34-13).
- **Fixture 5 (cleartext-injection)** + the **bonus (multi-encrypted)** pin `%Error{type: :ambiguous_assertion}` using would-fail-decrypt ciphertext, proving the pre-crypto reject fired BEFORE any decrypt (T-34-14 / SC#2 / CVE-2026-2092 class).
- **Fixture 7 (read-before-verify, strongest guard):** a genuinely-signed-then-TAMPERED assertion (NameID rewritten after signing, then encrypted) returns a verification-stage typed error (`:digest_mismatch`) AND `refute_identity_leak/1` proves NO identity field (neither genuine nor attacker NameID, no `:name_id`/`:attributes` keys) reaches the caller (T-34-12, CVE-2025-54419 class closed end-to-end).
- Wired the corpus into `mix ci.security` as its OWN `cmd mix test ... --warnings-as-errors` subprocess line (Phase-30 hollow-gate rule) and added it to `ci_gate_integrity_test.exs` `@gated_suites` so the anti-hollow meta-gate confirms the line is present, named, and non-bare (T-34-15).

## Task Commits

1. **Task 1: pipeline-level ENC-01 adversarial corpus (SC#1, SC#5, read-before-verify)** — `408aad7` (test)
2. **Task 2: wire ENC-01 corpus into mix ci.security (hollow-gate rule)** — `2a488ab` (test)

_(Final docs commit follows this SUMMARY.)_

## Files Created/Modified

- `test/security/xml_enc_adversarial_test.exs` — NEW. 9 tests: positive control + 7 named fixtures + 1 bonus, exact `%Error{type:}` pins; local helpers (`connection/1`, `response_envelope/1`, `garbage_encrypted_assertion/0`, `cleartext_assertion/0`, `signature_block/0`, `throwaway_pub_key/0`, `refute_identity_leak/1`).
- `mix.exs` — added the corpus line to the `ci.security` alias (own subprocess line).
- `test/security/ci_gate_integrity_test.exs` — added the corpus (`nil` tag) to `@gated_suites`.
- `lib/relyra/test_support/xmldsig_signer.ex` — added the `:assertion_namespace` opt (default `false`) + `assertion_open_tag/1`; when true the signed `<Assertion>` apex carries its own default namespace (Rule 1 fix).
- `lib/relyra/test_support/fake_idp.ex` — `signed_assertion_fragment/1` now passes `assertion_namespace: true` and STOPS re-declaring the namespace after signing (Rule 1 fix).

## Decisions Made

- **Read-before-verify driven through `ValidationPipeline.run/4`, not `consume_response/3`:** the plan permitted either; the pipeline returns `%Error{}` (never a login map) on any rejection, so identity-leak is asserted directly on the typed error. `consume_response/3` adds connection-resolution + request-store plumbing that does not strengthen the read-before-verify property. The full decrypt -> re-parse -> verify path is exercised identically.
- **wrong-key fixture builds via `encrypt/3` against a throwaway pubkey + manual envelope:** `encrypted_response/2` hardcodes the SP public key, so to wrap a CEK against the wrong key the fixture calls `FakeIdP.encrypt(plaintext, throwaway_pub_key)` directly and wraps it in `response_envelope/1`. This is still the single canonical encrypt recipe — only the target key differs (the RSA-OAEP unwrap fails before content is examined, so the plaintext is irrelevant).
- **Meta-gate registration:** the corpus is added to `@gated_suites` with a `nil` tag (the whole file runs, no `--only`), so the tag-integrity check is skipped for it while presence / named-in-alias / non-bare checks enforce the non-hollow invariant.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Positive control failed `:digest_mismatch` — signed Assertion gained an unsigned namespace after decrypt/splice (T-34-04)**
- **Found during:** Task 1 (running the positive control through the full pipeline for the first time end-to-end).
- **Issue:** `FakeIdP.encrypted_response/2` (Plan 02) signed the inner `<Assertion>` via `XmldsigSigner.signed_response/1` — which emits `<Assertion ID="...">` with NO default namespace — then `signed_assertion_fragment/1` re-declared `xmlns="urn:oasis:names:tc:SAML:2.0:assertion"` on the Assertion AFTER signing. The genuine `DigestValue` was therefore computed over the NON-namespaced Assertion. After the pipeline decrypted and spliced the fragment back into the `<Response>` and re-parsed it, the Assertion carried that default namespace, and the verifier's exclusive-C14N output now INCLUDED the `xmlns` declaration on the apex. The recomputed digest no longer matched the embedded `DigestValue` -> `:digest_mismatch`. The Plan-02 round-trip smoke test only proved `FakeIdP.encrypt -> XMLEnc.decrypt` byte-identity; it never drove a full pipeline verify, so the bug was latent until Plan 04's SC#1 end-to-end fixture.
- **Fix:** Added an `:assertion_namespace` option to `XmldsigSigner.signed_response/1` (default `false`, so the cleartext signer path stays byte-identical and every existing signed-Response test is unaffected). When `true`, the signed `<Assertion>` apex is emitted WITH its own default namespace, so the genuine `DigestValue` is computed over the namespaced bytes. `FakeIdP.signed_assertion_fragment/1` now passes `assertion_namespace: true` and removed the post-signing namespace re-declaration. The post-decrypt re-canonicalized Assertion now matches the signed bytes -> the positive control verifies `{:ok}`.
- **Files modified:** `lib/relyra/test_support/xmldsig_signer.ex`, `lib/relyra/test_support/fake_idp.ex`
- **Verification:** new corpus 9/9 green; Plan-02 round-trip smoke (`fake_idp_encrypt_test.exs`) 4/4 green; Plan-03 `decrypt_assertion_test.exs` 6/6 green; full suite 626/0; `mix ci.security` exit 0; `mix format --check-formatted` exit 0.
- **Committed in:** `408aad7` (Task 1)

---

**Total deviations:** 1 auto-fixed (1 bug, Rule 1)
**Impact on plan:** The fix is the minimal seam adjustment required for the plan's stated SC#1 positive control to verify for the RIGHT reason (a genuine signature surviving decrypt -> re-parse). It is additive (opt-gated, default-off) and changes no cleartext behavior. The 34-03 SUMMARY explicitly flagged that "Plan 04's SC#1 positive control depends on" the encrypted-only parse tolerance; this completes that dependency chain by also making the digest survive the round-trip. Worth surfacing to the planner: the Plan-02 generator's `signed_assertion_fragment/1` namespace handling was the root cause, not the pipeline.

## Issues Encountered

- The wrong-key fixture could not use `encrypted_response/2` (it hardcodes the SP public key); resolved by building the encrypted half via `FakeIdP.encrypt/3` against a throwaway pubkey and wrapping it in the same `response_envelope/1` the ambiguity fixtures use. Still the single canonical encrypt recipe.

## User Setup Required

None — test-only (`:sp_private_key_pem` is set in the suite `setup` and deleted `on_exit`).

## Next Phase Readiness

- ENC-01 is now proven end-to-end at the pipeline level: a valid encrypted assertion logs in, and every failure mode returns its exact typed error from a permanent, non-hollow CI gate.
- SC#1 (positive control), SC#5 (all 7 fixtures wired + correct typed errors), and the read-before-verify guard (CVE-2025-54419 class) are satisfied. The bonus extends the multi-encrypted reject end-to-end.
- The corpus is `mix ci.security`-gated and meta-gate-enforced; a future ENC-01 regression flips a fixture red and fails the build.
- No blockers. Phase 34 (the last code plan of the ENC-01 wiring arc) is complete pending phase verification.

## Threat Flags

None — no new security surface introduced; this plan is a test corpus + a CI-wiring + a test-only signer opt (default off). All adversarial shapes route through the existing single canonical generator and the existing pipeline pre-stage.

## Known Stubs

None — every fixture is fully wired and exercised; the corpus drives real encrypted Responses end-to-end through the production pipeline.

---
*Phase: 34-validationpipeline-wiring-enc-01-complete*
*Completed: 2026-05-25*

## Self-Check: PASSED

- FOUND: test/security/xml_enc_adversarial_test.exs
- FOUND: .planning/phases/34-validationpipeline-wiring-enc-01-complete/34-04-SUMMARY.md
- FOUND commit: 408aad7 (Task 1)
- FOUND commit: 2a488ab (Task 2)
- FOUND: ci.security corpus line (`cmd mix test test/security/xml_enc_adversarial_test.exs --warnings-as-errors`)
- Gates: new corpus 9/9; full suite 626/0; `mix ci.security` exit 0; `mix format --check-formatted` exit 0.
