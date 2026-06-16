---
phase: 64-public-testing-api-package-boundary
plan: 02
subsystem: testing
tags: [elixir, saml, xmldsig, public-api, security-ci]

requires:
  - phase: 64-public-testing-api-package-boundary
    provides: Phoenix-free `Relyra.Testing` signed success fixture core from Plan 01
provides:
  - Public representative negative fixtures for wrong audience, digest tamper, and wrong-key signature rejection
  - Exact public fixture crypto proof through `Relyra.consume_response/3`
  - Dedicated `ci.security` process lane for the public testing fixture crypto suite
affects: [phase-65-documentation-truth, public-testing-api, security-ci]

tech-stack:
  added: []
  patterns:
    - Public negative fixture helpers return explicit expected rejection atoms
    - Negative fixture tests prove behavior through the real consume_response verifier path
    - Security CI suites remain separate `cmd mix test` OS processes

key-files:
  created:
    - test/security/testing_fixture_crypto_test.exs
  modified:
    - lib/relyra/testing.ex
    - lib/relyra/testing/signer.ex
    - mix.exs
    - test/security/ci_gate_integrity_test.exs

key-decisions:
  - "Representative public negative fixtures stay limited to wrong audience, post-signing digest tamper, and wrong-key invalid signature."
  - "Public negative fixture tests pin exact `%Relyra.Error{type: ...}` results through `Relyra.consume_response/3`."
  - "The new security lane is also listed in the anti-hollow meta-gate so it remains a real `cmd mix test` process."

patterns-established:
  - "Wrong audience signs valid XML with an assertion audience different from the returned connection `sp_entity_id`."
  - "Digest tamper mutates signed `<NameID>` content after signing and raises if the mutation is a no-op."
  - "Invalid signature signs with one ephemeral keypair but returns trust material from a distinct ephemeral cert chain."

requirements-completed: [TEST-02, TEST-03, TEST-04]

duration: 8min
completed: 2026-06-16
---

# Phase 64 Plan 02: Representative Negative Fixtures Summary

**Public `Relyra.Testing` negative fixtures that reject with exact typed errors through the real verifier path.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-16T02:35:00Z
- **Completed:** 2026-06-16T02:42:56Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added `Relyra.Testing.wrong_audience/1`, `tampered_digest/1`, and `invalid_signature/1`.
- Added `Relyra.Testing.Signer.tamper_name_id!/3` as the post-signing mutation seam with a no-op guard.
- Added `test/security/testing_fixture_crypto_test.exs`, proving all public negative fixtures through `Relyra.consume_response/3` with exact `%Relyra.Error{type: ...}` outcomes.
- Added the public testing fixture crypto suite to `ci.security` as its own `cmd mix test` process.
- Extended the Phase 30 anti-hollow meta-gate so the new security suite is tracked as a required `cmd mix test` lane.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: public negative fixture crypto tests** - `6fb7efa` (test)
2. **Task 1 GREEN: public negative fixture helpers** - `465a6b4` (feat)
3. **Task 2: security CI lane** - `f3b9492` (ci)

## Files Created/Modified

- `lib/relyra/testing.ex` - Adds public wrong-audience, digest-tamper, and wrong-key fixture helpers.
- `lib/relyra/testing/signer.ex` - Adds the guarded post-signing NameID tamper helper.
- `test/security/testing_fixture_crypto_test.exs` - Public fixture crypto proof through `Relyra.consume_response/3`.
- `mix.exs` - Adds the public fixture crypto suite as a dedicated `ci.security` command.
- `test/security/ci_gate_integrity_test.exs` - Tracks the new security suite in the anti-hollow meta-gate.

## Decisions Made

- Used explicit returned fixture trust material only; no document `KeyInfo` trust or global trust mutation.
- Kept public negative coverage representative rather than exposing the private adversarial corpus.
- Treated meta-gate coverage for the new suite as required security-CI integrity, even though the plan named only the alias change.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added new security suite to anti-hollow meta-gate**
- **Found during:** Task 2 (Add public fixture crypto suite to ci.security)
- **Issue:** Adding a `ci.security` command without updating `test/security/ci_gate_integrity_test.exs` would let the new lane drift out of the Phase 30 structural guard.
- **Fix:** Added `test/security/testing_fixture_crypto_test.exs` to `@gated_suites`.
- **Files modified:** `test/security/ci_gate_integrity_test.exs`
- **Verification:** `mix test test/security/testing_fixture_crypto_test.exs test/security/ci_gate_integrity_test.exs --warnings-as-errors`
- **Committed in:** `f3b9492`

---

**Total deviations:** 1 auto-fixed (Rule 2).
**Impact on plan:** The change tightens CI integrity for the new suite without altering public API shape or verifier behavior.

## Issues Encountered

- `mix ci.security` failed twice in an existing Ecto migration bootstrap lane before reaching the later security suites: `DBConnection.ConnectionError` while creating `schema_migrations` for `Relyra.TestSupport.EctoTestRepo`. Focused verification, the CI integrity suite, and the exact new `mix cmd mix test test/security/testing_fixture_crypto_test.exs --warnings-as-errors` lane all passed. `psql` showed no lingering `relyra_test` sessions afterward. This appears to be local/pre-existing Ecto test bootstrap pressure, not a regression in the public testing fixture code.

## Verification

- `mix test test/security/testing_fixture_crypto_test.exs --warnings-as-errors` - PASS, 4 tests, 0 failures.
- `mix test test/security/testing_fixture_crypto_test.exs test/security/ci_gate_integrity_test.exs --warnings-as-errors` - PASS, 8 tests, 0 failures.
- `mix cmd mix test test/security/testing_fixture_crypto_test.exs --warnings-as-errors` - PASS, 4 tests, 0 failures.
- `rg "Relyra\\.TestSupport" lib/relyra/testing.ex lib/relyra/testing/signer.ex test/security/testing_fixture_crypto_test.exs` - no matches.
- `rg -n "^\\s*alias Relyra\\.Security\\.Signature\\b" test/security/testing_fixture_crypto_test.exs` - no matches.
- `rg -n "cmd mix test test/security/testing_fixture_crypto_test\\.exs --warnings-as-errors|test/security/xml/adversarial_crypto_test\\.exs --only adversarial_crypto|test/security/ci_gate_integrity_test\\.exs" mix.exs` - all required security alias entries present.
- `mix ci.security` - FAIL in an existing Ecto migration bootstrap lane before the new suite; see Issues Encountered.

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 64-03 can proceed with optional Phoenix helper and dependency isolation work. The public core negative fixtures now exist and are proven without depending on `Relyra.TestSupport`.

## Self-Check: PASSED

- Created/modified files exist: `lib/relyra/testing.ex`, `lib/relyra/testing/signer.ex`, `test/security/testing_fixture_crypto_test.exs`, `mix.exs`, `test/security/ci_gate_integrity_test.exs`.
- Task commits exist: `6fb7efa`, `465a6b4`, `f3b9492`.
- Stub scan found no blocking stubs; signer placeholder variables are internal signing scaffolding, not user-facing placeholder behavior.
- No accidental file deletions were detected in task commits.

---
*Phase: 64-public-testing-api-package-boundary*
*Completed: 2026-06-16*
