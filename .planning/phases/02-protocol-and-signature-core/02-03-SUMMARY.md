---
phase: 02-protocol-and-signature-core
plan: 02-03
subsystem: protocol
tags: [saml, validation-pipeline, protocol-core, typed-errors, elixir]
requires:
  - phase: 02-protocol-and-signature-core
    provides: AuthnRequest, relay-state, and signature trust core from plans 02-01 and 02-02
provides:
  - Ordered consume-response validation pipeline with fixed stage contract
  - Response and assertion validators returning deterministic typed protocol errors
  - Fixture-driven consume_response contract tests including skew boundary coverage
affects: [phase-03-behaviour-contracts-and-stores, phase-04-phoenix-runtime-integration]
tech-stack:
  added: []
  patterns:
    - Ordered trust-first consume pipeline: parse -> issuer/binding -> signature -> signed-node -> protocol fields -> time
    - Public consume API returns only typed tuples and wraps unexpected failures as internal protocol errors
    - Manifest-driven protocol mismatch classes tied to requirement IDs
key-files:
  created:
    - lib/relyra/protocol/response.ex
    - lib/relyra/protocol/assertion.ex
    - lib/relyra/protocol/validation_pipeline.ex
    - test/fixtures/security/protocol/manifest.json
    - test/protocol/consume_response_pipeline_test.exs
  modified:
    - lib/relyra.ex
    - test/relyra_test.exs
key-decisions:
  - "Relyra.consume_response/3 now requires request_intent keys and always normalizes outcomes to {:ok, map()} or {:error, %Relyra.Error{}}."
  - "Response/assertion checks run only through a single ordered ValidationPipeline to prevent stage reordering bypasses."
  - "Protocol mismatch classes are asserted from a manifest so PROT-02/03/05 failures stay deterministic."
patterns-established:
  - "Protocol core remains map/keyword driven with no Plug.Conn, Ecto, or adapter coupling."
  - "Temporal validation enforces bounded skew and explicit edge behavior for NotBefore/NotOnOrAfter/SubjectConfirmation windows."
requirements-completed: [PROT-02, PROT-03, PROT-05]
duration: 5 min
completed: 2026-04-24
---

# Phase 2 Plan 03: Implement response/assertion validation pipeline with typed protocol errors Summary

**Shipped a strict consume path where trust, protocol, and temporal assertions execute in fixed order and return deterministic typed outcomes through `Relyra.consume_response/3`.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-04-24T15:59:59Z
- **Completed:** 2026-04-24T16:04:47Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments
- Added dedicated response validators for issuer/status/destination/connection binding mismatches.
- Added assertion validators for audience/recipient/time windows with bounded `skew_seconds` defaults.
- Added one canonical ordered `ValidationPipeline.run/4` and integrated it behind `Relyra.consume_response/3`.
- Added manifest-driven protocol failure fixtures and pipeline tests covering stage order, mismatch classes, and typed tuple shape.

## Task Commits

Each task was committed atomically:

1. **Task 1: response/assertion validator modules** - `47981a2` (feat)
2. **Task 2: ordered validation pipeline + consume_response contract** - `d7db968` (feat)
3. **Task 3: protocol manifest and pipeline tests** - `91ca780` (test)
4. **Verification deviation fix** - `a07ed0d` (fix)

**Plan metadata:** `(pending in docs commit)`

## Files Created/Modified
- `lib/relyra/protocol/response.ex` - Issuer/status/destination/connection response validators with typed details.
- `lib/relyra/protocol/assertion.ex` - Audience/recipient/time condition validators with bounded skew semantics.
- `lib/relyra/protocol/validation_pipeline.ex` - Canonical ordered consume pipeline and signed-node bind checks.
- `lib/relyra.ex` - Public `consume_response/3` contract, request-intent gating, and typed internal failure wrapping.
- `test/fixtures/security/protocol/manifest.json` - Requirement-tagged protocol mismatch fixtures for PROT-02/03/05.
- `test/protocol/consume_response_pipeline_test.exs` - Ordered stage, fixture failure, skew boundary, and tuple-shape assertions.
- `test/relyra_test.exs` - Root contract test coverage for `consume_response/3`.

## Decisions Made
- Kept protocol consume validation in one module with explicit stage order to prevent bypass-by-reordering.
- Required request intent keys before consume processing so connection/request binding is guaranteed at ingress.
- Preserved typed failure surfaces for every protocol and timing mismatch class in fixture-driven tests.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Verification Blocker] Formatting gate failed at plan verification**
- **Found during:** Plan-level verification
- **Issue:** `mix format --check-formatted` failed for newly added consume pipeline and test files.
- **Fix:** Ran formatter and re-ran full verification suite.
- **Files modified:** `lib/relyra.ex`, `lib/relyra/protocol/assertion.ex`, `lib/relyra/protocol/validation_pipeline.ex`, `test/protocol/consume_response_pipeline_test.exs`
- **Verification:** `mix format --check-formatted`, `mix compile --warnings-as-errors`, `mix test --warnings-as-errors`, `mix ci.fast`
- **Committed in:** `a07ed0d`

---

**Total deviations:** 1 auto-fixed (1 rule-1 verification blocker)
**Impact on plan:** Formatting-only correction required to satisfy enforced verification gates; no scope change.

## Issues Encountered
None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Phase 2 protocol core now includes strict typed consume outcomes and ordered protocol validation.
- Phase 2 is complete; Phase 3 behavior/store work can build on stable consume contracts.

---
*Phase: 02-protocol-and-signature-core*  
*Completed: 2026-04-24*
