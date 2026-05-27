---
phase: 42-stepwise-login-trace-liveview
plan: 02
subsystem: auth
tags: [login-trace, export, redaction, live-admin, audit]

requires:
  - phase: 42-stepwise-login-trace-liveview
    provides: domain:login audit persistence and validation_trace population (42-01)
provides:
  - Relyra.LoginTrace.Export shared redaction for steps and login rows
  - LiveAdmin.Query.get_login_traces/4 with default limit 20
  - Trust audit timeline excludes domain:login rows in get_connection_detail/4
affects:
  - 42-03 (ConnectionTraceLive UI)
  - 42-04 (mix relyra.trace CLI + security corpus)

tech-stack:
  added: []
  patterns:
    - "Single export path (LoginTrace.Export) consumed by LiveView and CLI"
    - "correlation_id hashed at export time via AllowList.hash_correlation_id/1"
    - "Trust timeline and login trace timeline query separately by domain"

key-files:
  created:
    - lib/relyra/login_trace/export.ex
    - test/relyra/login_trace/export_test.exs
  modified:
    - lib/relyra/diagnostic/allow_list.ex
    - lib/relyra/live_admin/query.ex

key-decisions:
  - "LoginTrace.Export is the canonical export module; AllowList adds thin delegates only"
  - "get_connection_detail/4 excludes domain:login so trust and login timelines stay separate"

patterns-established:
  - "export_step/1 allows outcome, error_code, duration_ms, attributes, roles with recursive scrub"
  - "get_login_traces/4 maps rows through Export.export_login/1 before returning to UI/CLI"

requirements-completed: []

duration: 8min
completed: 2026-05-27
---

# Phase 42 Plan 02: Shared Export and Query Summary

**LoginTrace.Export redacts audit rows for UI/CLI parity; LiveAdmin query helpers fetch login traces and keep trust timelines login-free**

## Performance

- **Duration:** 8 min
- **Started:** 2026-05-27T19:45:00Z
- **Completed:** 2026-05-27T19:53:03Z
- **Tasks:** 2
- **Files modified:** 4 (2 created, 2 modified)

## Accomplishments

- Created `Relyra.LoginTrace.Export` with recursive scrub for AuditWriter-sensitive keys and forbidden PEM/XML patterns
- `export_login/1` hashes `correlation_id`, drops `actor`, and returns ordered step summaries
- Added `AllowList.export_login_trace/1` and `export_trace_step/1` thin delegates
- `Query.get_login_traces/4` returns last N `:login` rows (default 20) through export redaction
- `get_connection_detail/4` trust audit preload excludes `domain: :login`

## Task Commits

Each task was committed atomically:

1. **Task 1: Create LoginTrace.Export module** - `cae579d` (feat)
2. **Task 2: Query helpers and trust-audit filter** - `fa2ec93` (feat)

## Files Created/Modified

- `lib/relyra/login_trace/export.ex` - Shared step/login export with redaction
- `test/relyra/login_trace/export_test.exs` - Hashed correlation_id, response_xml, PEM redaction tests
- `lib/relyra/diagnostic/allow_list.ex` - Thin delegates to LoginTrace.Export
- `lib/relyra/live_admin/query.ex` - get_login_traces/4 + trust timeline domain filter

## Decisions Made

- `LoginTrace.Export` is the single redaction path; AllowList delegates preserve D-11 naming without duplicate logic
- Step export drops nil fields (matches handler summarize_step behavior)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- Local PostgreSQL hit `too_many_connections` during initial test run; resolved by restarting `postgresql@14`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 42-03 can mount ConnectionTraceLive using `Query.get_login_traces/4`
- Plan 42-04 can wire `mix relyra.trace` against the same export module
- Security corpus (`test/security/login_trace_test.exs`) remains for plan 42-04

## Self-Check: PASSED

- `mix test test/relyra/login_trace/export_test.exs --warnings-as-errors` — 5 tests, 0 failures
- `mix test test/relyra/live_admin/ --warnings-as-errors` — 29 tests, 0 failures

---
*Phase: 42-stepwise-login-trace-liveview*
*Completed: 2026-05-27*
