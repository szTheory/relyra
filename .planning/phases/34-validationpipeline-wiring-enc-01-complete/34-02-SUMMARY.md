---
phase: 34-validationpipeline-wiring-enc-01-complete
plan: 02
subsystem: testing
tags: [xml-enc, rsa-oaep, aes-gcm, fake-idp, encrypted-assertion, saml, crypto]

# Dependency graph
requires:
  - phase: 33-crypto-core
    provides: "XMLEnc.decrypt/3 (RSA-OAEP + AES-256-GCM, split_cipher_value IV(12)||CT||Tag(16) layout) — consumed UNCHANGED"
  - phase: 29
    provides: "XmldsigSigner.signed_response/1 genuine signer (real DigestValue + SignatureValue over the verifier's own C14N engine)"
provides:
  - "FakeIdP.encrypt/2 + encrypt/3 — the single canonical encrypted-assertion generator (RSA-OAEP key transport + AES-256-GCM content)"
  - "FakeIdP.encrypted_response/2 — full Response binary carrying an EncryptedAssertion in place of a cleartext Assertion (sign-then-encrypt)"
  - "FakeIdP.enc_algorithm_uris/0 — the four XML-Enc URIs (rsa-oaep-mgf1p, aes256-gcm, rsa-1_5, aes256-cbc) for Plan 04 fixtures"
  - "Round-trip smoke test proving FakeIdP.encrypt -> XMLEnc.decrypt is byte-identity"
affects: [34-04-adversarial-corpus, ENC-01]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Single canonical encrypted-assertion generator (mirrors FakeIdP.sign/2 discipline; ensure_not_prod! + ensure_keypair! guards first)"
    - "Sign-then-encrypt: inner Assertion genuinely signed via XmldsigSigner BEFORE wrapping, so post-decrypt bytes carry the real signature"
    - "Self-contained namespace on the encrypted Assertion (own xmlns=urn:...:assertion) so canonical bytes survive decrypt -> re-parse -> splice"
    - "Adversarial overrides via encrypt/3 opts (key_transport_uri, key_padding, content_uri, tag_length, iv, cipher_value_b64)"

key-files:
  created:
    - test/relyra/test_support/fake_idp_encrypt_test.exs
  modified:
    - lib/relyra/test_support/fake_idp.ex

key-decisions:
  - "encrypt/2 is byte-agnostic (encrypts any plaintext); signing happens in the caller (encrypt path) or inside encrypted_response/2 — keeps the generator a single recipe"
  - "Signature stays a SIBLING of the Assertion in the encrypted fragment (matches PureBeam.signed_candidates/1 pairing of Assertion-by-ID + find_first(root, Signature)), not an enveloped child"
  - "enc_algorithm_uris/0 exposes the four URI module attrs as a map so Plan 04 fixtures read the blocked variants from one place instead of re-typing them (also makes the rsa-1_5 / aes256-cbc attrs load-bearing under warnings-as-errors)"

patterns-established:
  - "Canonical generator pattern: promote a proven test recipe (xml_enc_test.exs:39-56) into FakeIdP rather than divergent per-test recipes (Pitfall 1 anti-masking)"
  - "encrypt/3 opts seam for adversarial fixtures (fail-closed proofs in Plan 04)"

requirements-completed: [ENC-01]

# Metrics
duration: 3min
completed: 2026-05-25
---

# Phase 34 Plan 02: FakeIdP Encrypted-Assertion Generator Summary

**`FakeIdP.encrypt/2` + `encrypted_response/2` — the single canonical RSA-OAEP + AES-256-GCM encrypted-assertion generator (sign-then-encrypt, self-contained namespace) that round-trips byte-identically through the unchanged Phase-33 `XMLEnc.decrypt/3`.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-05-25T19:46:02Z
- **Completed:** 2026-05-25T19:49:20Z
- **Tasks:** 2
- **Files modified:** 2 (1 created, 1 modified)

## Accomplishments

- Added `FakeIdP.encrypt/2` (and the adversarial-aware `encrypt/3`) promoting the proven OAEP/GCM recipe from `xml_enc_test.exs` into the single canonical encrypted-assertion generator — `IV(12) || CT || Tag(16)` CipherValue layout that `XMLEnc.split_cipher_value/1` round-trips (Pitfall 4 / T-34-05).
- Added `FakeIdP.encrypted_response/2`: signs the inner Assertion FIRST via the genuine `XmldsigSigner`, THEN encrypts, then wraps it in a full `<Response>` shell (Issuer / Status / EncryptedAssertion) the pipeline can consume in Plan 04. The encrypted Assertion carries its own `xmlns="urn:oasis:names:tc:SAML:2.0:assertion"` so canonical bytes survive the decrypt -> re-parse -> splice (Pitfall 1 / T-34-04).
- Added `FakeIdP.enc_algorithm_uris/0` exposing the four XML-Enc URIs (`rsa-oaep-mgf1p`, `aes256-gcm`, `rsa-1_5`, `aes256-cbc`) for Plan 04 adversarial fixtures.
- Round-trip smoke test (4 tests): `FakeIdP.encrypt` output, fed to the UNCHANGED `XMLEnc.decrypt/3`, returns exactly the signed plaintext that went in (byte identity), plus envelope-shape and full-Response shape/round-trip assertions.
- Only the SP **public** key `{:RSAPublicKey, n, e}` touches the encrypt path (T-34-06) — no private key material in the generator.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add FakeIdP.encrypt/2 + encrypted_response/2 canonical generators** - `8d0c560` (feat) — TDD: RED test drove the implementation; transient RED file removed once GREEN, superseded by Task 2's suite.
2. **Task 2: Round-trip smoke test — FakeIdP.encrypt -> XMLEnc.decrypt -> original** - `d2c326b` (test)

**Plan metadata:** (final docs commit follows this SUMMARY)

## Files Created/Modified

- `lib/relyra/test_support/fake_idp.ex` - Added four XML-Enc URI module attrs, `encrypt/2`, `encrypt/3`, `enc_algorithm_uris/0`, `encrypted_response/2`, and private helpers (`build_encrypted_assertion/4`, `sp_public_key/0`, `signed_assertion_fragment/1`, `extract_element/2`). `sign/2` and the cleartext path untouched (additive only).
- `test/relyra/test_support/fake_idp_encrypt_test.exs` - Round-trip smoke suite (4 tests): byte-identity round-trip, envelope-shape URI pins, full-Response shape + inner round-trip. `setup` wires `:sp_private_key_pem` from `FakeIdP.keypair()` with `on_exit` cleanup (copied from `xml_enc_test.exs:12-26`).

## Decisions Made

- **encrypt/2 is byte-agnostic; signing is the caller's job** — `encrypt/2` wraps whatever plaintext it is given. `encrypted_response/2` is the helper that does the sign-then-encrypt sequence internally. This keeps the generator a single OAEP/GCM recipe (no divergent paths to mask a real bug).
- **Signature stays a SIBLING of the Assertion in the encrypted fragment** — matching the existing `XmldsigSigner` / `PureBeam.signed_candidates/1` shape (Assertion paired by ID with `find_first(root, "Signature")`), not an enveloped child. The current Reference carries no `ds:Transforms`, so a sibling Signature is the shape the verifier already binds; Plan 04 will splice this into the Response and re-verify.
- **`enc_algorithm_uris/0` exposes the four URI attrs as a map** — gives Plan 04 fixtures a single source for the blocked `rsa-1_5` / `aes256-cbc` URIs (no re-typing) and makes those module attrs load-bearing under `--warnings-as-errors`. (See Deviations: this resolved a blocking unused-attr warning.)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Unused `@rsa_pkcs1_uri` / `@aes256_cbc_uri` module attrs failed `--warnings-as-errors`**
- **Found during:** Task 1 (FakeIdP generators)
- **Issue:** The plan's acceptance criteria require the four XML-Enc URI module attrs (including the adversarial `xmlenc#rsa-1_5` and `xmlenc#aes256-cbc`) in the source, but `encrypt/3` consumes those URIs via opts, leaving the two blocked-variant attrs unreferenced — `mix compile --warnings-as-errors` failed on "module attribute set but never used".
- **Fix:** Added `FakeIdP.enc_algorithm_uris/0`, a small public accessor returning all four URIs as a map. This both satisfies the warnings-as-errors gate and gives Plan 04 fixtures a single source for the blocked-variant URIs (consistent with the plan's intent that "Plan 04 fixtures consume these").
- **Files modified:** lib/relyra/test_support/fake_idp.ex
- **Verification:** `mix compile --warnings-as-errors` exits 0; `mix format --check-formatted` exits 0.
- **Committed in:** `8d0c560` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The accessor is additive and directly serves the plan's stated Plan-04 consumption intent. No scope creep; all acceptance criteria met.

## Issues Encountered

None — both tasks executed as written. The genuine signer (`XmldsigSigner.signed_response/1`) emits a Response with `<Assertion>` and a sibling `<Signature>`; `signed_assertion_fragment/1` extracts both and re-declares the SAML assertion namespace on the Assertion so the post-decrypt fragment is self-contained.

## User Setup Required

None - no external service configuration required. (`:sp_private_key_pem` is test-only env, set in the test `setup` and deleted `on_exit`.)

## Next Phase Readiness

- The single canonical encrypted-assertion generator is corpus-ready. Plan 04 can now wrap each of its 7 adversarial fixtures (wrong-key, truncated GCM tag, PKCS1v1.5 key transport, AES-CBC content, cleartext-injection, malformed ciphertext, read-before-verify) through `FakeIdP.encrypt/3` and feed the resulting `encrypted_response/2` binaries into `ValidationPipeline.run/4`.
- Plan 03 (pipeline `:decrypt_assertion` pre-stage) and Plan 04 (corpus) consume these generators; nothing in those plans is blocked by this work.
- Full suite remains green (611 tests, 0 failures); `sign/2` and the cleartext path are untouched (additive only).

## Security / Threat Notes

- **T-34-04 (namespace-context corruption on splice):** mitigated — the encrypted `<Assertion>` carries its own `xmlns="urn:oasis:names:tc:SAML:2.0:assertion"`; sign-then-encrypt so post-decrypt bytes are byte-identical to the signed bytes. The round-trip test proves identity.
- **T-34-05 (GCM auth-tag / CipherValue layout):** mitigated — exact `IV(12) || CT || Tag(16)` 16-byte-tag layout `XMLEnc.split_cipher_value/1` round-trips. The round-trip test fails closed if the layout diverges.
- **T-34-06 (private key in test plumbing):** mitigated — the SP private key lives only in `:sp_private_key_pem` test env (deleted `on_exit`); `FakeIdP.encrypt` uses only the PUBLIC key `{:RSAPublicKey, n, e}` derived from `keypair/0` (`sp_public_key/0`). No private key in the encrypt path.

## Known Stubs

None — all generators are fully wired and exercised by the round-trip suite.

---
*Phase: 34-validationpipeline-wiring-enc-01-complete*
*Completed: 2026-05-25*

## Self-Check: PASSED

- FOUND: lib/relyra/test_support/fake_idp.ex
- FOUND: test/relyra/test_support/fake_idp_encrypt_test.exs
- FOUND: .planning/phases/34-validationpipeline-wiring-enc-01-complete/34-02-SUMMARY.md
- FOUND commit: 8d0c560 (Task 1)
- FOUND commit: d2c326b (Task 2)
