---
phase: 34-validationpipeline-wiring-enc-01-complete
plan: 03
subsystem: auth
tags: [saml, xml-encryption, encrypted-assertion, decrypt-then-reparse, validation-pipeline, ENC-01]

# Dependency graph
requires:
  - phase: 33-xmlenc-decrypt-core
    provides: "XMLEnc.decrypt/3 (RSA-OAEP + AES-GCM, opaque :decryption_failed, AlgorithmPolicy-gated)"
  - phase: 34-02
    provides: "FakeIdP.encrypt/2 + encrypted_response/2 canonical encrypted-assertion generator"
  - phase: 28
    provides: "SaxyTree parse seam + PureBeam.parse_safely/2 single hardened parse path"
provides:
  - "ValidationPipeline.do_run/4 :decrypt_assertion pre-stage (D-01): detect -> reject-ambiguity-pre-crypto -> decrypt -> string-splice -> re-parse_safely/2"
  - ":ambiguous_assertion typed error (pre-crypto structural reject, distinct from opaque :decryption_failed)"
  - "PureBeam.build_parsed_doc/1 encrypted-only tolerance (pre-decrypt parsed_doc carrying :parse_tree)"
  - "prefix-aware exactly-one-match EncryptedAssertion splice locator (unprefixed + <saml:> prefixed)"
affects: [34-04, ENC-01-corpus, encrypted-assertion-interop]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Decrypt-then-reparse pre-stage: parse outer -> detect from tree -> reject ambiguity pre-crypto -> decrypt -> string-splice -> re-parse SAME seam"
    - "Prefix-agnostic tree-walk detector (find_first/find_all by local name) reused, no second parser"
    - "Encrypted-only parse tolerance: minimal pre-decrypt parsed_doc, strict gates re-run on re-parsed plaintext"

key-files:
  created:
    - test/relyra/protocol/decrypt_assertion_test.exs
  modified:
    - lib/relyra/protocol/validation_pipeline.ex
    - lib/relyra/security/xml/pure_beam.ex

key-decisions:
  - "Pre-stage inserts in do_run/4 between parse_safely/2 and do_run_validations/6 (D-01); do_run_validations/6 untouched (D-02)"
  - "PureBeam.build_parsed_doc/1 tolerates encrypted-only Responses (no cleartext Assertion/Signature) via a minimal pre-decrypt parsed_doc; strict gates re-run on the re-parsed plaintext (Rule 3 blocking-issue fix)"
  - "Splice locator is prefix-aware + exactly-one-match-guarded; zero or >1 substrings -> :ambiguous_assertion (RESEARCH A1)"
  - ">1 EncryptedAssertion treated as :ambiguous_assertion (same exactly-one invariant; RESEARCH open-question 1)"
  - "No-op proven dependency-free via a raise-if-invoked :key_resolver module (no Mox/:meck added)"

patterns-established:
  - "Decrypt-then-reparse via string-splice + re-parse_safely/2 (no tree-rebuild, no new serializer)"
  - "Encrypted-only pre-decrypt parsed_doc carries :parse_tree + response_fields only; no identity field read pre-verify"

requirements-completed: [ENC-01]

# Metrics
duration: 9min
completed: 2026-05-25
---

# Phase 34 Plan 03: ValidationPipeline Wiring (ENC-01) Summary

**`:decrypt_assertion` pre-stage wired into `do_run/4` — detect-from-tree, reject cleartext+encrypted ambiguity before any crypto, decrypt a single EncryptedAssertion via the unchanged `XMLEnc.decrypt/3`, prefix-aware string-splice, and re-parse through the same `parse_safely/2` seam — so decrypted bytes pass `parse_safely/2` AND `Signature.do_verify/4` before any identity field is read (CVE-2025-54419 class closed).**

## Performance

- **Duration:** ~9 min
- **Started:** 2026-05-25T19:53:41Z
- **Completed:** 2026-05-25T20:02:47Z
- **Tasks:** 2
- **Files modified:** 2 (1 created, 2 modified)

## Accomplishments

- Inserted the private `:decrypt_assertion` pre-stage into `ValidationPipeline.do_run/4` (D-01): a prefix-agnostic tree-walk detector over the outer parse tree, a pre-crypto `:ambiguous_assertion` reject (D-03/SC#2), single-EncryptedAssertion decrypt via the unchanged `XMLEnc.decrypt/3` (passing the resolver MODULE + connection in opts), a prefix-aware exactly-one-match string-splice, and a re-parse through the SAME `parse_safely/2` seam (CLAUDE.md #2/#3).
- Preserved the three-tuple `do_run/4` contract on every exit and left `do_run_validations/6` byte-unchanged (D-02 no-op path intact; full suite green).
- Added the new `:ambiguous_assertion` typed error (distinct from opaque `:decryption_failed`, mirroring the `:ambiguous_signed_node` precedent).
- Proved the no-op path WITHOUT a mock: a raise-if-invoked `:key_resolver` module shows an unencrypted, genuinely-signed Response never reaches `XMLEnc.decrypt/3` (SC#3 at the unit level).
- Pinned exact `%Error{type:}` on every guard: ambiguity-before-crypto (would-fail ciphertext), >1 EncryptedAssertion, prefix-aware splice (unprefixed + `<saml:>` prefixed), and the exactly-one-match guard (two substrings) — RESEARCH A1.

## Task Commits

1. **Task 1 (TDD) RED: failing tests for the pre-stage** - `96678db` (test)
2. **Task 1 (TDD) GREEN: wire the pre-stage + encrypted-only parse tolerance** - `ba86699` (feat)
3. **Task 2: pin pre-stage branch guards with exact typed errors** - `481952b` (test)

_Task 1 was TDD (RED -> GREEN); no REFACTOR commit needed — the GREEN implementation was already minimal and clean._

## Files Created/Modified

- `lib/relyra/protocol/validation_pipeline.ex` - Added `decrypt_assertion/4` pre-stage, `detect_encrypted/1`, prefix-agnostic `find_first`/`find_all`/`collect_nodes`, and the prefix-aware exactly-one-match `locate_encrypted_assertion/1`; rewired the `{:ok, parsed_doc}` arm of `do_run/4` to run the pre-stage first and dispatch on its `{:ok, effective_doc} | {:error, %Error{}}` result.
- `lib/relyra/security/xml/pure_beam.ex` - `build_parsed_doc/1` now branches on `encrypted_only?/1`: an encrypted-only Response (EncryptedAssertion present, no cleartext Assertion) gets a minimal pre-decrypt `parsed_doc` (`response_fields` + `:parse_tree`, `encrypted_pending: true`) so the pre-stage can run; the cleartext path keeps the strict assertion/signature gates unchanged.
- `test/relyra/protocol/decrypt_assertion_test.exs` - NEW. 6 unit tests covering the pre-stage branch logic that needs no real encrypted fixture (no-op via raise-if-invoked resolver, ambiguity-before-crypto, >1 EncryptedAssertion, prefix-aware splice pair, exactly-one-match guard).

## Decisions Made

- **Pre-stage placement (D-01):** inserted in `do_run/4`, not `do_verify` (the stale investigation-thread guidance). `do_run_validations/6` is byte-unchanged (D-02).
- **`:ambiguous_assertion` stays distinct** from opaque `:decryption_failed` — it is a pre-crypto structural reject with no oracle risk (D-03).
- **`>1 EncryptedAssertion` -> `:ambiguous_assertion`** (same exactly-one invariant; RESEARCH open-question 1).
- **Splice via string-replace, not tree-rebuild** — no canonical tree serializer exists; the verifier re-canonicalizes nodes at verify time, so the spliced original bytes are what matter (RESEARCH Pattern 1).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] PureBeam.parse_safely/2 rejected every encrypted-only Response before the pre-stage could run**
- **Found during:** Task 1 (GREEN phase — running the pre-stage tests against the real `FakeIdP.encrypted_response()`)
- **Issue:** `PureBeam.build_parsed_doc/1` hard-requires cleartext assertion fields (`audiences`, `recipient`, `Conditions`, `consumed_xml_id`) AND signature fields (`SignatureMethod`/`DigestMethod`/`signed_candidates`). An encrypted-only Response carries NONE of these in cleartext — they live inside the still-encrypted blob — so the OUTER `parse_safely/2` rejected it with `:missing_protocol_field` (`Required assertion fields are missing`) BEFORE the `do_run/4` pre-stage could detect/decrypt/re-parse. The plan's D-01 design assumes the outer parse yields a `parsed_doc` with `:parse_tree`; without this fix, the entire decrypt path was unreachable. Confirmed empirically: `FakeIdP.encrypted_response()` -> `parse_safely/2` returned `:missing_protocol_field`.
- **Fix:** Added `encrypted_only?/1` (EncryptedAssertion present AND no cleartext Assertion, prefix-agnostic) and `build_pre_decrypt_parsed_doc/1` to `pure_beam.ex`. An encrypted-only Response now gets a minimal pre-decrypt `parsed_doc` carrying only `response_fields` (Issuer/Status/Destination ARE present on the outer envelope) + `:parse_tree` + `encrypted_pending: true`. **No gate is relaxed for the cleartext path** (`build_cleartext_parsed_doc/1` is the renamed original with identical gates), and the strict assertion/signature gates re-run on the re-parsed decrypted plaintext (one parse path, CLAUDE.md #2). NO identity field is surfaced in the pre-decrypt doc (CLAUDE.md #4 / Pitfall 3).
- **Files modified:** `lib/relyra/security/xml/pure_beam.ex`
- **Verification:** `FakeIdP.encrypted_response()` now parses to a pre-decrypt doc with `:parse_tree`; full suite 617/0 (the cleartext path — every existing signed-Response test + frozen Phase-29 corpus — is byte-identical, SC#3); `mix ci.security` exit 0.
- **Committed in:** `ba86699` (Task 1 GREEN commit)

---

**Total deviations:** 1 auto-fixed (1 blocking, Rule 3)
**Impact on plan:** The fix is required for the plan's D-01 design to function at all — it makes the encrypted-only Response reachable by the pre-stage without weakening the cleartext path or the strict gates (which re-run on the decrypted plaintext). No scope creep; the change is the minimal seam adjustment that keeps one parse path and the strict-by-default posture. Worth surfacing to the planner: Plan 04's positive-control fixture (SC#1 end-to-end) depends on this tolerance being in place.

## Issues Encountered

- **Test-fixture completeness for the ambiguity case:** the cleartext-injection fixture (cleartext `<Assertion>` + `<EncryptedAssertion>`) takes the FULL cleartext parse path, so the cleartext Assertion AND a sibling `<Signature>` must be complete enough to satisfy `parse_safely/2`'s gates before the pre-stage can detect ambiguity. Resolved by giving the fixture a complete cleartext Assertion (`cleartext_assertion/0`) and a structurally-complete `<Signature>` block (`signature_block/0`); the signature never verifies — the ambiguity reject fires before verification, which is exactly the property under test (SC#2 ordering).

## User Setup Required

None - no external service configuration required (this plan is read-path pipeline wiring; no new config keys, no migrations, no trust mutations).

## Next Phase Readiness

- The decrypt-then-reparse wiring for SC#1 is in place; the end-to-end positive control + the 7-fixture ENC-01 adversarial corpus land in **Plan 04** (which depends on the encrypted-only parse tolerance delivered here).
- SC#2 (ambiguity rejected before crypto) and SC#3 (no-op path structurally unchanged) are satisfied and pinned at the unit level.
- The splice locator is prefix-aware and exactly-one-match-guarded (RESEARCH A1).
- No blockers.

## Self-Check: PASSED

- Files verified present: `validation_pipeline.ex`, `pure_beam.ex`, `decrypt_assertion_test.exs`, `34-03-SUMMARY.md`.
- Commits verified in git log: `96678db` (test/RED), `ba86699` (feat/GREEN), `481952b` (test/Task 2).
- Gates: `mix compile --warnings-as-errors` clean; `mix test test/relyra/protocol/ --warnings-as-errors` 23/0; `mix test --warnings-as-errors` 617/0; `mix format --check-formatted` exit 0; `mix ci.security` exit 0.

---
*Phase: 34-validationpipeline-wiring-enc-01-complete*
*Completed: 2026-05-25*
