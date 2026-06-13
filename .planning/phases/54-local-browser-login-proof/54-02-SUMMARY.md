---
phase: 54
plan: 02
subsystem: demo_app
tags: [affordance, login, e2e, fake-idp]
dependency_graph:
  requires: [54-01]
  provides: [54-03]
  affects: [demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_controller.ex]
tech_stack:
  added: []
  patterns: [FakeIdP UI wiring]
key_files:
  created: []
  modified:
    - demo/ledger_loop/lib/ledger_loop/demo/fixtures.ex
    - demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_controller.ex
    - demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_html/login.html.heex
    - demo/ledger_loop/test/ledger_loop_web/controllers/route_affordance_controller_test.exs
key_decisions:
  - Wired the existing test login affordance directly to FakeIdP simulation using the hardcoded deterministically generated `enabled_conn_ulid` from Fixtures.
metrics:
  duration: "1 minute"
  completed_at: "2026-06-12T13:00:00Z"
---

# Phase 54 Plan 02: Route Affordance Controller Updates Summary

Wired the local login affordance view directly to the FakeIdP SSO endpoint to allow E2E visual browser testing.

## Task 1: Wire Login Affordance
- Fetched `@enabled_conn_ulid` from `LedgerLoop.Demo.Fixtures` via a new helper `relyra_enabled_scenario_id/0`.
- Passed the `conn_id` to the login view via `render(conn, :login, conn_id: conn_id)`.
- Replaced the placeholder UI copy with a functional link button directing the user to `/fake_idp/#{@conn_id}/sso`.

## Task 2: Affordance Tests
- Added a controller test asserting that the login view properly renders a link directing the user to the FakeIdP simulation URL.

## Deviations from Plan
None - plan executed exactly as written.

## Threat Flags
None.

## Known Stubs
None.
## Self-Check: PASSED

