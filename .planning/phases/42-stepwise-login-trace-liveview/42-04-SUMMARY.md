---
phase: 42-stepwise-login-trace-liveview
plan: 04
subsystem: testing
tags: [login-trace, security, cli, mix-task, trace-02, trace-03, hollow-gate]

requires:
  - phase: 42-stepwise-login-trace-liveview
    provides: ConnectionTraceLive and Query.get_login_traces/4 (42-03), LoginTrace.Export (42-02)
provides:
  - mix relyra.trace headless CLI
  - test/security/login_trace_test.exs security corpus
  - ci.security dedicated login_trace_test.exs lane
affects:
  - Phase 43 (publish prep — trace feature complete for v1.4.0 tarball)

tech-stack:
  added: []
  patterns:
    - "CLI and LiveView both route through Query.get_login_traces/4 → LoginTrace.Export.export_login/1"
    - "Security corpus drives real signed consume fixture and refutes forbidden substrings in HTML and CLI output"
    - "login_trace_test.exs registered in @gated_suites with dedicated cmd mix test step"

key-files:
  created:
    - lib/mix/tasks/relyra.trace.ex
    - test/security/login_trace_test.exs
  modified:
    - mix.exs
    - test/security/ci_gate_integrity_test.exs

key-decisions:
  - "CLI uses global admin scope (organization_id: nil) matching diagnostic task patterns"
  - "Security test ensures EctoTestRepo module is loaded before invoking Mix task in test context"

patterns-established:
  - "mix relyra.trace --repo --connection [--last N] prints redacted step rows via Mix.shell().info/1"
  - "login_trace_test.exs: LiveView refute, CLI refute, export equivalence (3 tests minimum)"

requirements-completed: [TRACE-02, TRACE-03]

duration: 18min
completed: 2026-05-27
---

# Phase 42 Plan 04: Login Trace CLI + Security Gate Summary

**Headless `mix relyra.trace` CLI and security corpus proving LiveView/CLI redaction equivalence, wired into hollow-gate `ci.security`**

## Performance

- **Duration:** 18 min
- **Started:** 2026-05-27T19:40:00Z
- **Completed:** 2026-05-27T19:57:55Z
- **Tasks:** 2
- **Files modified:** 4 (2 created, 2 modified)

## Accomplishments

- Added `Mix.Tasks.Relyra.Trace` with required `--repo` and `--connection`, optional `--last` (default 20)
- Created `test/security/login_trace_test.exs` with LiveView refute, CLI refute, and export-equivalence tests
- Wired `cmd mix test test/security/login_trace_test.exs --warnings-as-errors` into `mix ci.security`
- Registered suite in `@gated_suites` for hollow-gate integrity enforcement

## Task Commits

Each task was committed atomically:

1. **Task 1: Add mix relyra.trace task** - `36ee5d9` (feat)
2. **Task 2: Security corpus and ci.security lane** - `9021616` (test)

## Files Created/Modified

- `lib/mix/tasks/relyra.trace.ex` - Headless login trace CLI via Query.get_login_traces/4
- `test/security/login_trace_test.exs` - TRACE-02/03 security corpus (LiveView, CLI, equivalence)
- `mix.exs` - Added login_trace_test.exs to ci.security alias
- `test/security/ci_gate_integrity_test.exs` - Registered login_trace suite in @gated_suites

## Decisions Made

- CLI uses `%Scope{actor: "system:relyra.trace", organization_id: nil}` for global connection lookup
- Security test calls `Code.ensure_loaded!(@repo)` before Mix task invocation so `to_existing_atom/1` succeeds in test

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Setup referenced fixture.cert_chain instead of cert_pem**
- **Found during:** Task 2 (security corpus)
- **Issue:** `signed_fixture/0` returns `cert_pem` key, not `cert_chain`
- **Fix:** Pass `[fixture.cert_pem]` to `consume_opts/2`
- **Files modified:** `test/security/login_trace_test.exs`
- **Verification:** `mix test test/security/login_trace_test.exs --warnings-as-errors` — 3 tests, 0 failures
- **Committed in:** `9021616` (Task 2 commit)

**2. [Rule 1 - Bug] Mix task repo atom not loaded in test process**
- **Found during:** Task 2 (CLI refute test)
- **Issue:** `String.to_existing_atom("Relyra.TestSupport.EctoTestRepo")` failed before module load
- **Fix:** `Code.ensure_loaded!(@repo)` before `TraceTask.run/1`
- **Files modified:** `test/security/login_trace_test.exs`
- **Verification:** CLI refute test passes
- **Committed in:** `9021616` (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (2 bugs, test-only)
**Impact on plan:** Test harness fixes only; production CLI and export path unchanged.

## Issues Encountered

PostgreSQL connection pool saturation during local test runs required restarting `postgresql@14` — environmental, not code-related.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 42 complete — all TRACE-01..TRACE-03 requirements satisfied
- Phase 43 (Hex publish prep) can proceed with trace LiveView + CLI + security gate in tree

## Self-Check: PASSED

- `mix help relyra.trace` — lists required `--repo` and `--connection`
- `mix test test/security/login_trace_test.exs --warnings-as-errors` — 3 tests, 0 failures
- `mix test test/security/ci_gate_integrity_test.exs --warnings-as-errors` — 4 tests, 0 failures

---
*Phase: 42-stepwise-login-trace-liveview*
*Completed: 2026-05-27*
