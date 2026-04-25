---
phase: 02-protocol-and-signature-core
plan: 04
subsystem: security
tags: [saml, xml, signature, protocol-validation]
requires:
  - phase: 02-03
    provides: strict validation pipeline ordering and typed consume entrypoint
provides:
  - parser-driven extraction of protocol/signature fields
  - strict request-correlation guards (InResponseTo + RelayState)
  - fail-closed signature method/digest enforcement
affects: [phase-02-verification, phase-03-request-store]
tech-stack:
  added: []
  patterns: [fail-closed parser extraction, parser-first trust binding]
key-files:
  created: []
  modified:
    - lib/relyra/security/xml/pure_beam.ex
    - lib/relyra/security/xml.ex
    - lib/relyra/protocol/validation_pipeline.ex
    - lib/relyra/security/signature.ex
    - lib/relyra.ex
    - test/protocol/consume_response_pipeline_test.exs
    - test/fixtures/security/protocol/manifest.json
    - test/fixtures/security/signature/manifest.json
key-decisions:
  - "Consume-path trust checks must evaluate extracted XML fields only; synthetic defaults are forbidden."
  - "RelayState is a required consume option and must match request_intent before any success path."
patterns-established:
  - "Parser extraction pattern: response/assertion/signature fields are parsed once and reused by protocol and signature stages."
  - "Correlation-first validation: InResponseTo and RelayState mismatches return deterministic typed errors."
requirements-completed: [SEC-02, SEC-03, SEC-04, SEC-05, PROT-02, PROT-03, PROT-05]
duration: 32min
completed: 2026-04-24
---

# Phase 02 Plan 04: Close fail-open trust path by removing synthetic payload defaults and enforcing request correlation Summary

**Fail-open consume behavior was removed by shifting protocol and signature checks to parser-extracted fields with strict request-correlation guards.**

## Performance

- **Duration:** 32 min
- **Started:** 2026-04-24T16:35:00Z
- **Completed:** 2026-04-24T17:07:00Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments
- Reworked XML parsing to extract required response/assertion/signature fields and fail closed when missing.
- Removed synthetic trust defaults from `ValidationPipeline` and added strict `InResponseTo` + RelayState correlation checks.
- Hardened signature verification to require extracted algorithm fields and parser-derived signed candidates.

## Task Commits

Each task was completed atomically in this execution, but commits were intentionally deferred in this workspace run.

1. **Task 1: Parser field extraction and fail-closed errors** - deferred
2. **Task 2: Validation pipeline hardening and request correlation checks** - deferred
3. **Task 3: Signature verification strict algorithm and candidate binding** - deferred

## Files Created/Modified
- `lib/relyra/security/xml/pure_beam.ex` - Added extraction helpers and fail-closed parse semantics.
- `lib/relyra/protocol/validation_pipeline.ex` - Removed defaults and enforced correlation guards.
- `lib/relyra/security/signature.ex` - Enforced extracted algorithm presence and stricter candidate validation.
- `lib/relyra.ex` - Required `opts[:relay_state]` for `consume_response/3`.

## Decisions Made
- Required response/assertion/signature fields are now parser responsibilities and missing values are terminal typed errors.
- Request correlation moved to an explicit guardrail path with stable `:in_response_to_mismatch`, `:relay_state_missing`, and `:relay_state_mismatch` outcomes.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- Formatting gate failures after refactors were resolved by running `mix format` before verification reruns.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Regression fixtures and tests are now aligned with parser-driven trust checks, enabling final phase-2 verification closure in plan 02-05.
- No blockers for executing 02-05.

---
*Phase: 02-protocol-and-signature-core*
*Completed: 2026-04-24*
