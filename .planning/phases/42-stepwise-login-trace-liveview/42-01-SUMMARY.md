---
phase: 42-stepwise-login-trace-liveview
plan: 01
subsystem: auth
tags: [telemetry, audit, login-trace, ecto]

requires:
  - phase: 41-pre-publish-hygiene-tech-debt-sweep-security-hardening
    provides: Clean parse-tree trust path upstream of trace work
provides:
  - LoginTrace telemetry handler with process-scoped span accumulation
  - domain:login audit persistence via AuditWriter.append_event/2
  - LoginResult.validation_trace populated on successful consume
affects:
  - 42-02 (LiveView trace UI)
  - 42-03 (export/redaction)
  - 42-04 (security corpus + ci.security wiring)

tech-stack:
  added: []
  patterns:
    - "Process-scoped span accumulation bracketed by response.consume telemetry"
    - "Append-only login audit rows outside trust-mutation transactions"

key-files:
  created:
    - lib/relyra/telemetry/handlers/login_trace.ex
    - test/relyra/telemetry/handlers/login_trace_test.exs
  modified:
    - lib/relyra/ecto/audit_event.ex
    - lib/relyra.ex

key-decisions:
  - "Incremental validation_trace updates on child span :stop events (consume :stop fires after normalize_consume_result)"
  - "diff_summary uses %{\"kind\" => \"login_trace\"} because empty diff maps fail AuditEvent validation"

patterns-established:
  - "Login traces use domain :login with actions :succeeded/:failed and actor system:login_trace"
  - "Hosts attach LoginTrace with repo: in Application.start/2"

requirements-completed: [TRACE-01]

duration: 25min
completed: 2026-05-27
---

# Phase 42 Plan 01: Login Trace Persistence Summary

**Process-scoped LoginTrace handler flushes domain:login audit rows and populates LoginResult.validation_trace from consume-path telemetry spans**

## Performance

- **Duration:** 25 min
- **Started:** 2026-05-27T19:47:00Z
- **Completed:** 2026-05-27T19:52:00Z
- **Tasks:** 3
- **Files modified:** 4 (2 created, 2 modified)

## Accomplishments

- Extended `AuditEvent` with `:login` domain and `:succeeded`/`:failed` actions (no migration — string column)
- Built `Relyra.Telemetry.Handlers.LoginTrace` attaching to consume start/stop/exception plus six child span `:stop` events
- Populated `LoginResult.validation_trace` from process-scoped span summaries; partial traces cleared on error paths
- Tests prove success/failure audit append, redaction-safe `after_summary`, and non-empty `validation_trace`

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend audit domain and login actions** - `8e8a7f7` (feat)
2. **Task 2: Implement LoginTrace telemetry handler** - `43a1a4d` (feat)
3. **Task 3: Populate validation_trace on consume** - `44f089c` (feat)

## Files Created/Modified

- `lib/relyra/ecto/audit_event.ex` - Added `:login` domain and outcome actions
- `lib/relyra/telemetry/handlers/login_trace.ex` - Span accumulation + audit flush handler
- `lib/relyra.ex` - `validation_trace` population and error-path cleanup
- `test/relyra/telemetry/handlers/login_trace_test.exs` - End-to-end persistence tests

## Decisions Made

- Child span `:stop` handlers update `:relyra_validation_trace` incrementally because `consume :stop` fires after `normalize_consume_result/1` returns inside the telemetry span
- Used `%{"kind" => "login_trace"}` for `diff_summary` since `AuditEvent` rejects empty diff maps

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] diff_summary cannot be empty map**
- **Found during:** Task 2 (LoginTrace handler flush)
- **Issue:** Plan specified `diff_summary: %{}` but `AuditEvent.changeset/2` rejects blank diff maps
- **Fix:** Set `diff_summary: %{"kind" => "login_trace"}`
- **Files modified:** `lib/relyra/telemetry/handlers/login_trace.ex`
- **Verification:** `mix test test/relyra/telemetry/handlers/login_trace_test.exs --warnings-as-errors` exits 0
- **Committed in:** `43a1a4d`

**2. [Rule 1 - Bug] validation_trace timing vs consume :stop**
- **Found during:** Task 3 (normalize_consume_result wiring)
- **Issue:** Handler sets `:relyra_validation_trace` on consume `:stop`, which runs after `normalize_consume_result/1`
- **Fix:** Incrementally update `:relyra_validation_trace` on each child span `:stop` so normalize can read completed steps
- **Files modified:** `lib/relyra/telemetry/handlers/login_trace.ex`
- **Verification:** Success test asserts non-empty `validation_trace` on `{:ok, %LoginResult{}}`
- **Committed in:** `43a1a4d` / `44f089c`

---

**Total deviations:** 2 auto-fixed (2 bugs)
**Impact on plan:** Both fixes required for correct end-to-end behavior; no scope creep.

## Issues Encountered

- Local PostgreSQL hit `too_many_connections` during verification; resolved by restarting PostgreSQL and pausing competing `mix phx.server` processes.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 42-02 can wire LiveView query against `domain: :login` audit rows
- Handler attach documented in moduledoc; hosts must call `LoginTrace.attach(repo:)` from `Application.start/2`
- Security corpus (`test/security/login_trace_test.exs`) and export module remain for later plans

## Self-Check: PASSED

- `mix test test/relyra/telemetry/handlers/login_trace_test.exs --warnings-as-errors` — 2 tests, 0 failures
- `mix test test/relyra/ecto/audit_hardening_test.exs --warnings-as-errors` — 3 tests, 0 failures
- `mix compile --warnings-as-errors` — exit 0

---
*Phase: 42-stepwise-login-trace-liveview*
*Completed: 2026-05-27*
