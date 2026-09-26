---
phase: 76-lifecycle-and-recovery-journeys
plan: 01
subsystem: auth
tags: [phoenix, ecto, replay, journeys, testing]
requires:
  - phase: 75-saas-twin-domain-realism
    provides: tenant-owned Northstar users, memberships, groups, and persisted connection fixtures
provides:
  - Reusable test-only SP login driver through LedgerLoop's real Phoenix routes
  - Endpoint proof for mapped Northstar administrator login and accepted-response replay rejection
  - Replay keys derived from trusted request/connection context
affects: [76-lifecycle-and-recovery-journeys]
actuals:
  tokens: 3645
  tasks: 2
  commits: 4
plan_head_before: 407e005f87fdb53dbb19904a76e8248220fc3726
commits: 4
tech-stack:
  added: []
  patterns:
    - Reusable ConnTest flow driver signs responses with the configured demo IdP certificate and posts through the scoped ACS route
key-files:
  created:
    - demo/ledger_loop/test/support/lifecycle_flow.ex
    - demo/ledger_loop/test/ledger_loop_web/lifecycle_journeys_test.exs
  modified:
    - lib/relyra/protocol/validation_pipeline.ex
    - lib/relyra.ex
    - lib/relyra/request_store.ex
    - lib/relyra/request_store/ecto.ex
    - demo/ledger_loop/lib/ledger_loop/relyra/request_store.ex
key-decisions:
  - Replay identity comes from the persisted request intent or resolved connection, never the response document's ConnectionId attribute.
  - A consumed RelayState may recover correlation context only from the configured request store, allowing the replay store to reject an exact retry atomically without changing behaviour callback signatures.
patterns-established:
  - LifecycleFlow drives login and ACS through LedgerLoop routes while exposing the exact signed response and RelayState for repeat submissions.
requirements-completed: [JOUR-01, JOUR-03]
coverage:
  - id: D1
    description: A signed Northstar SP login maps Dr. Sarah to the Northstar tenant and administrators group, then creates one host receipt.
    requirement: JOUR-01
    verification:
      - kind: integration
        ref: demo/ledger_loop/test/ledger_loop_web/lifecycle_journeys_test.exs#SP login establishes exactly the mapped Northstar administrator receipt
        status: pass
      - kind: integration
        ref: mix ci.demo_app
        status: pass
    human_judgment: false
  - id: D2
    description: Posting the exact accepted response and RelayState again returns :replayed_assertion without creating another receipt; a fresh login remains accepted.
    requirement: JOUR-03
    verification:
      - kind: integration
        ref: demo/ledger_loop/test/ledger_loop_web/lifecycle_journeys_test.exs#an accepted assertion replay is rejected without a second host receipt
        status: pass
      - kind: integration
        ref: mix ci.demo_app
        status: pass
    human_judgment: false
duration: 29 min
completed: 2026-09-26
status: complete
---

# Phase 76 Plan 01: Lifecycle and Recovery Journeys Summary

**Northstar's configured SP route now proves mapped administrator login, trusted replay scoping, and atomic repeat rejection.**

## Performance

- **Duration:** 29 min
- **Started:** 2026-09-26T12:26:36Z
- **Completed:** 2026-09-26T12:55:46Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Added a reusable test driver that starts at LedgerLoop's SP login route, carries the generated request ID and RelayState, signs with the configured demo IdP key, and submits to the scoped ACS route.
- Proved the verified response creates exactly one Dr. Sarah receipt and that her mapped user, Northstar tenant, administrator group, consumed request intent, configured IdP certificate, replay row, and success trace align.
- Proved a byte-identical retry returns `:replayed_assertion` without changing receipt or replay state; a fresh assertion through a new login remains accepted.

## Task Commits

1. **Task 1: Complete one verified Northstar login from SP redirect through adopter session** — `b0ac248` (RED test), `15d9847` (GREEN fix and route contract).
2. **Task 2: Reject the accepted assertion when it is posted again** — `1806a79` (RED test), `c29ab84` (GREEN consumed-intent recovery and replay rejection).

**Measured plan commits:** 4 (`407e005f87fdb53dbb19904a76e8248220fc3726..HEAD` at summary creation).

## Files Created/Modified

- `demo/ledger_loop/test/support/lifecycle_flow.ex` — reusable signed SP login and ACS route driver.
- `demo/ledger_loop/test/ledger_loop_web/lifecycle_journeys_test.exs` — endpoint acceptance and replay contracts.
- `lib/relyra/protocol/validation_pipeline.ex` — derives replay scope from trusted request/connection state.
- `lib/relyra.ex`, `lib/relyra/request_store.ex`, `lib/relyra/request_store/ecto.ex`, and `demo/ledger_loop/lib/ledger_loop/relyra/request_store.ex` — recover consumed request intent from the configured adapter for replay validation without changing behaviour callback signatures.

## Decisions Made

- Bind replay keys to the trusted persisted request or resolved connection; ignore the response document's `ConnectionId` for replay scope.
- Recover consumed request context only from the configured request-store adapter, then let the existing replay-store uniqueness constraint reject duplicates.

## TDD Gate Compliance

- **Task 1:** RED `b0ac248` exposed that the signed response's `ConnectionId="valid"` controlled replay identity; GREEN `15d9847` scopes it to trusted request/connection data. The RED evidence check returned `RED_EVIDENCE_OK`.
- **Task 2:** RED `1806a79` exposed an `internal_protocol_error` when a consumed RelayState was mistaken for a missing IdP-initiated request; GREEN `c29ab84` recovers persisted intent context and reaches the atomic replay store. The RED evidence check returned `RED_EVIDENCE_OK`.
- No REFACTOR commit was needed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Scope replay identity to trusted connection context**
- **Found during:** Task 1
- **Issue:** The response's `ConnectionId` attribute supplied the replay key's connection prefix (`valid`) instead of the configured Northstar connection.
- **Fix:** Always derive the replay connection ID from the stored request intent or resolved connection.
- **Files modified:** `lib/relyra/protocol/validation_pipeline.ex`
- **Verification:** The route test asserts the replay key and metadata use the configured connection; `mix ci.demo_app` and `mix ci.security` pass.
- **Committed in:** `15d9847`

**2. [Rule 1 - Bug] Recover consumed request intent before replay validation**
- **Found during:** Task 2
- **Issue:** An exact ACS retry encountered a consumed request intent, fell through as IdP-initiated, and raised `read_field/2` instead of reaching replay protection.
- **Fix:** Added an optional internal store operation to retrieve already-consumed intent data from the configured adapter. Core validates that stored correlation context, then the existing atomic replay store returns `:replayed_assertion`. Published behaviour callback signatures remain unchanged.
- **Files modified:** `lib/relyra.ex`, `lib/relyra/request_store.ex`, `lib/relyra/request_store/ecto.ex`, `demo/ledger_loop/lib/ledger_loop/relyra/request_store.ex`
- **Verification:** Exact retry returns `:replayed_assertion`, leaves one receipt and one replay key, and a fresh login succeeds; focused suite, `mix ci.demo_app`, and `mix ci.security` pass.
- **Committed in:** `c29ab84`

---

**Total deviations:** 2 auto-fixed (1 Rule 1 bug, 1 Rule 2 missing critical behavior).
**Impact on plan:** Both changes were needed to prove the declared route-level replay boundary and preserve configured connection scoping.

## Deferred Issues

- Concurrent duplicate ACS submissions were not automated. `LedgerLoopWeb.ConnCase` starts a separate SQL Sandbox owner process without exposing its PID; `Sandbox.allow(Repo, self(), task)` returned `:not_found`. The sequential exact-retry case remains covered and the database replay key uses its existing unique constraint.

## Issues Encountered

- The repository's `.tool-versions` has no current `mix` selection. Tests used the installed baseline `ASDF_ELIXIR_VERSION=1.19.5-otp-28` and `ASDF_ERLANG_VERSION=28.5` without changing that user-owned file.
- `mix ci.demo_app` initially could not write Hex's cache under the read-only home directory. Re-running with `HEX_HOME=/private/tmp/gsd-76-hex` passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The reusable driver is ready for later tenant and recovery journeys. The only deferred proof is coordinated concurrent retry execution under the current SQL Sandbox owner setup.

---
*Phase: 76-lifecycle-and-recovery-journeys*
*Completed: 2026-09-26*

## Self-Check: PASSED

- Summary file exists at the expected phase path.
- All four task commits (`b0ac248`, `15d9847`, `1806a79`, `c29ab84`) exist in git history.
- The task test file has no uncommitted changes, and `git diff --check` passes.
