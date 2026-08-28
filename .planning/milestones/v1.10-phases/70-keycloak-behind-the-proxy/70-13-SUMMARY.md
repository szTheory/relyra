---
phase: 70-keycloak-behind-the-proxy
plan: "13"
subsystem: demo-login-trace
tags: [keycloak, demo, login-trace, accessibility, tdd]
requires:
  - 70-10
provides:
  - opt-in safe long Login Trace fixture
  - keyboard-focusable horizontal Login Trace evidence region
affects:
  - demo/ledger_loop
  - Relyra.LiveAdmin.ConnectionTraceLive
tech-stack:
  added: []
  patterns: [AuditWriter fixture, native details, labelled overflow region]
key-files:
  created: []
  modified:
    - demo/ledger_loop/lib/ledger_loop/demo/reset.ex
    - demo/ledger_loop/test/ledger_loop/demo/reset_test.exs
    - lib/relyra/live_admin/connection_trace_live.ex
    - test/relyra/live_admin/phase15_ui_contract_test.exs
decisions:
  - "The visual fixture is enabled only when DEMO_TRACE_VISUAL_FIXTURE equals 1."
  - "The inherited trace table stays inside native details and is exposed through a labelled focusable overflow region."
metrics:
  tasks_completed: 1
  files_modified: 4
  completed_date: 2026-08-26
status: complete
---

# Phase 70 Plan 13: Safe Login Trace Fixture and Narrow Evidence Access Summary

An exact opt-in synthetic failure trace gives browser automation long, redaction-safe evidence while Login Trace tables remain operable at narrow widths.

## Completed Work

- Added a single canonical failed login event through `Relyra.Ecto.AuditWriter` only when `DEMO_TRACE_VISUAL_FIXTURE=1`; ordinary reset continues to seed its original six support events.
- Kept fixture data synthetic: a long operator-readable cause, a long `response.validate` error code, and a correlation value that the existing export hashes.
- Wrapped the existing four-column table in a `role="region"` container with an accessible label, `tabindex="0"`, stable test id, and horizontal overflow; native `<details>`, selectors, table columns, and Back link are unchanged.
- Added RED/GREEN contract coverage for opt-in gating, safe exported data, native details, and keyboard-reachable narrow evidence.

## Verification

- `mix cmd --cd demo/ledger_loop mix test test/ledger_loop/demo/reset_test.exs --warnings-as-errors` — 6 tests, 0 failures.
- `mix test test/relyra/live_admin/phase15_ui_contract_test.exs --warnings-as-errors` — 6 tests, 0 failures.
- `mix format --check-formatted` — passed.
- `git diff --check 6450213^..HEAD` — passed; commit-range inspection confirms the only `lib/relyra/**` file changed is `connection_trace_live.ex` presentation markup.

## TDD Gate Compliance

- RED: `6450213` — fixture and semantic overflow assertions failed before implementation.
- GREEN: `7f8d6ca` — focused tests passed after the implementation.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 1 - Bug] Corrected the fixture export assertion to expect the existing 64-character hashed correlation identifier.
- **Found during:** Task 1 GREEN verification.
- **Issue:** The initial test assumed a 16-character hash, while `Relyra.LoginTrace.Export` correctly returns the existing SHA-256 hexadecimal value.
- **Fix:** Assert the established 64-character lowercase hexadecimal representation instead.
- **Files modified:** `demo/ledger_loop/test/ledger_loop/demo/reset_test.exs`
- **Commit:** `7f8d6ca`

## Known Stubs

None.

## Tracking Notes

`.planning/STATE.md` and the phase verification artifact were already modified by concurrent work, so they were preserved and not included in this plan's commits.

## Self-Check: PASSED

All four scoped implementation/test files and both TDD commits are present.
