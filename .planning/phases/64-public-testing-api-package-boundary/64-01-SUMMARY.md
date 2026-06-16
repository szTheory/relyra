---
phase: 64-public-testing-api-package-boundary
plan: 01
subsystem: testing
tags: [elixir, saml, xmldsig, public-api, package-boundary]

requires:
  - phase: 29-verify-trust-path
    provides: genuine XMLDSig verification and DigestValue recompute
  - phase: 30-security-gates
    provides: private adversarial crypto corpus and TestSupport signer pattern
provides:
  - Public Phoenix-free Relyra.Testing fixture facade
  - Explicit Relyra.Testing.Fixture data struct
  - Option-backed testing adapters for consume_response/3
  - Verifier-aligned signed success fixture generation with matching test cert material
affects: [phase-65-documentation-truth, phase-64-package-parity, public-testing-api]

tech-stack:
  added: []
  patterns:
    - Phoenix-free public test fixtures
    - Explicit fixture trust material threaded through consume_response/3 opts
    - Ephemeral RSA key and self-signed test certificate per fixture

key-files:
  created:
    - lib/relyra/testing.ex
    - lib/relyra/testing/fixture.ex
    - lib/relyra/testing/adapters.ex
    - lib/relyra/testing/signer.ex
    - test/relyra/testing_test.exs
  modified: []

key-decisions:
  - "Relyra.Testing ships as plain Phoenix-free functions and explicit fixture structs, not macros."
  - "Signed success fixtures generate fresh test key material per fixture and return trust material explicitly."
  - "Public testing code reuses the verifier parser/C14N primitives and does not call Relyra.TestSupport."

patterns-established:
  - "Public fixtures carry response_xml, encoded_response, cert_chain, idp_certificates, connection, request_intent, relay_state, and expected outcome."
  - "Testing adapters read fixture data from opts and never mutate Application env, persistent_term, ETS tables, or production resolver state."

requirements-completed: [TEST-01, TEST-02, TEST-04]

duration: 8min
completed: 2026-06-16
---

# Phase 64 Plan 01: Phoenix-Free Testing Core Summary

**Public `Relyra.Testing` core fixtures with real XMLDSig success proof through `Relyra.consume_response/3`.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-16T02:26:35Z
- **Completed:** 2026-06-16T02:33:27Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added the public Phoenix-free `Relyra.Testing` facade with `signed_success/1`, `consume_opts/2`, and `post_params/2`.
- Added `%Relyra.Testing.Fixture{}` with explicit response, trust, connection, request, relay, and expected-outcome data.
- Added public option-backed request/replay/resolver adapters for direct `consume_response/3` tests.
- Added `Relyra.Testing.Signer`, which generates real `DigestValue` and `SignatureValue` using `SaxyTree.parse/1`, `PureBeam.canonicalize/1`, `C14N.serialize/1`, `:crypto.hash/2`, and `:public_key.sign/3`.
- Proved the public success fixture succeeds through `Relyra.consume_response/3` and contains no document `KeyInfo`.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: fixture/helper contract** - `c537861` (test)
2. **Task 1 GREEN: public fixture helper plumbing** - `8ca3d10` (feat)
3. **Task 2 RED: signed success proof contract** - `f2ad89c` (test)
4. **Task 2 GREEN: signed success fixture implementation** - `7463728` (feat)

## Files Created/Modified

- `lib/relyra/testing.ex` - Public Phoenix-free facade for fixture generation, POST params, and consume opts.
- `lib/relyra/testing/fixture.ex` - Public fixture struct and type.
- `lib/relyra/testing/adapters.ex` - Public option-backed request store, replay store, and connection resolver adapters.
- `lib/relyra/testing/signer.ex` - Verifier-aligned signed test response generator.
- `test/relyra/testing_test.exs` - Public API proof tests through `Relyra.consume_response/3`.

## Decisions Made

- Public testing fixtures are data-first and Phoenix-free for the core path.
- The signer generates fresh RSA-2048 key material per fixture and returns a matching self-signed test certificate instead of using any private `Relyra.TestSupport` keypair.
- Fixture trust is explicit: no document `KeyInfo`, no global resolver mutation, and no hidden Application env state.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Close-out reruns of `mix test test/relyra/testing_test.exs --warnings-as-errors` hit local Postgres `too_many_connections` during test database bootstrap after the implementation had already passed the same command. Process inspection showed many long-lived unrelated idle `scoria_test` sessions consuming the local Postgres connection cap. No code changes were made after the successful run.

## Verification

- `mix test test/relyra/testing_test.exs --warnings-as-errors` - PASS after final Task 2 implementation: 6 tests, 0 failures.
- `mix format --check-formatted lib/relyra/testing.ex lib/relyra/testing/fixture.ex lib/relyra/testing/adapters.ex lib/relyra/testing/signer.ex test/relyra/testing_test.exs` - PASS.
- `rg "Relyra\\.TestSupport" lib/relyra/testing.ex lib/relyra/testing/signer.ex lib/relyra/testing/fixture.ex lib/relyra/testing/adapters.ex` - no matches.
- `rg -n "PureBeam\\.canonicalize|C14N\\.serialize|SaxyTree\\.parse|:crypto\\.hash|:public_key\\.sign" lib/relyra/testing/signer.ex` - all required primitives present.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 64 Plan 02 can build representative negative public fixtures on top of the public fixture data shape and signer without touching private `Relyra.TestSupport` internals.

## Self-Check: PASSED

- Created files exist: `lib/relyra/testing.ex`, `lib/relyra/testing/fixture.ex`, `lib/relyra/testing/adapters.ex`, `lib/relyra/testing/signer.ex`, `test/relyra/testing_test.exs`.
- Task commits exist: `c537861`, `8ca3d10`, `f2ad89c`, `7463728`.
- No accidental file deletions were detected in task commits.

---
*Phase: 64-public-testing-api-package-boundary*
*Completed: 2026-06-16*
