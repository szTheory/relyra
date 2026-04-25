---
phase: 05-observability-and-enforcement
plan: 01
subsystem: observability
tags: [telemetry, saml, phoenix, telemetry-span, ms-measurements]

# Dependency graph
requires:
  - phase: 04-protocol-validation
    provides: strict SAML login/ACS flow and typed error contracts
provides:
  - telemetry catalog documentation for all SAML events
  - ms-based start/stop/exception spans for the login and ACS pipeline
  - telemetry coverage proving the catalog matches emitted events
affects: [phase 05-02, downstream observability docs, replay/session/user adapters]

# Tech tracking
tech-stack:
  added: [telemetry]
  patterns: [catalog-driven instrumentation, nested event namespaces, duration_ms spans]

key-files:
  created: [test/relyra/telemetry_test.exs]
  modified: [lib/relyra/telemetry.ex, lib/relyra.ex, lib/relyra/protocol/binding.ex, lib/relyra/protocol/validation_pipeline.ex, lib/relyra/replay_store.ex, lib/relyra/security/signature.ex, lib/relyra/session_adapter.ex, lib/relyra/user_mapper.ex]

key-decisions:
  - "Emit fully-qualified telemetry event names directly so nested namespaces like response.decode and signature.verify match attached handlers."
  - "Report telemetry durations in duration_ms and include request_store_latency_ms / replay_store_latency_ms where they exist."

patterns-established:
  - "Pattern 1: telemetry spans return typed result + metadata tuples and the helper emits start/stop/exception triplets."
  - "Pattern 2: the ACS pipeline now exposes observable boundaries for decode, validate, signature, replay, mapping, and session handoff."

requirements-completed: []

# Metrics
duration: ~1h
completed: 2026-04-25
---

# Phase 05: Observability and Enforcement Summary

**SAML telemetry catalog with ms spans across login, decode, validation, replay, mapping, and session handoff**

## Performance

- **Duration:** ~1h
- **Started:** 2026-04-25 (execution window)
- **Completed:** 2026-04-25T23:47:05Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments
- Added a single telemetry catalog module documenting all observability events and namespaces.
- Instrumented the SP-initiated login and ACS pipeline with start/stop/exception spans and ms measurements.
- Added regression coverage proving the emitted telemetry matches the catalog shape.

## Task Commits

1. **Task 1: add telemetry catalog and event spans** - `07b503f` (feat)
2. **Task 2: cover telemetry emission across the SAML flow** - `32bbdc6` (test)

**Plan metadata:** none (single-plan phase)

## Files Created/Modified
- `lib/relyra/telemetry.ex` - telemetry catalog and span helper
- `lib/relyra.ex` - login/authn request instrumentation
- `lib/relyra/protocol/binding.ex` - response decode telemetry
- `lib/relyra/protocol/validation_pipeline.ex` - validation telemetry shape
- `lib/relyra/replay_store.ex` - replay telemetry with latency
- `lib/relyra/security/signature.ex` - signature telemetry metadata
- `lib/relyra/session_adapter.ex` - session telemetry metadata
- `lib/relyra/user_mapper.ex` - mapping telemetry metadata
- `test/relyra/telemetry_test.exs` - telemetry regression coverage

## Decisions Made
- Used a dedicated helper to emit fully-qualified telemetry event names so nested namespaces line up with the catalog.
- Standardized on `duration_ms` and surfaced store latencies where they materially help operators.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed nested telemetry prefix mismatch**
- **Found during:** Task 1 (instrumentation)
- **Issue:** The span helper double-prefixed nested namespaces, so handlers never matched events like `response.decode` and `signature.verify`.
- **Fix:** Switched the helper to emit fully-qualified event names directly.
- **Files modified:** `lib/relyra/telemetry.ex`
- **Verification:** `mix test test/relyra/telemetry_test.exs test/relyra_test.exs test/protocol/consume_response_pipeline_test.exs`
- **Committed in:** `07b503f`

**2. [Rule 1 - Bug] Normalized validation pipeline telemetry arity on parse failures**
- **Found during:** Task 1 (instrumentation)
- **Issue:** Parse errors could return a two-tuple instead of the telemetry-aware triple used by the catalog.
- **Fix:** Normalized validation results so telemetry metadata always has an assertion-count slot.
- **Files modified:** `lib/relyra/protocol/validation_pipeline.ex`
- **Verification:** `mix test test/relyra/telemetry_test.exs test/relyra_test.exs test/protocol/consume_response_pipeline_test.exs`
- **Committed in:** `07b503f`

---

**Total deviations:** 2 auto-fixed (2 Rule 1 bugs)
**Impact on plan:** Both fixes were required for the telemetry catalog to actually match emitted events.

## Issues Encountered
- None beyond the two auto-fixed telemetry bugs above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Telemetry boundaries are now explicit and test-covered.
- Phase 05-02 can layer redacted logging/enforcement on top of the catalog.

---
*Phase: 05-observability-and-enforcement*
*Completed: 2026-04-25*

## Self-Check: PASSED

- Summary file exists on disk.
- Both task commits are present in git history.
- Verification command passed: `mix test test/relyra/telemetry_test.exs test/relyra_test.exs test/protocol/consume_response_pipeline_test.exs`
