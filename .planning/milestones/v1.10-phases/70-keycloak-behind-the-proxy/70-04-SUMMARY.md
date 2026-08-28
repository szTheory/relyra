---
phase: 70-keycloak-behind-the-proxy
plan: "04"
subsystem: ledger-loop-workspace
tags: [keycloak, phoenix, accessibility, login-receipt]
dependency_graph:
  requires: [70-02-keycloak-provisioner, 70-03-keycloak-proxy-contract]
  provides: [conditional-real-idp-affordance, durable-verified-sign-in-receipt]
  affects: [70-05-phase-verification, 71-launcher-dx, 72-docker-dx-docs]
tech_stack:
  added: []
  patterns: [enabled-connection-gate, durable-receipt-presence, native-semantic-links]
key_files:
  created: []
  modified:
    - demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_controller.ex
    - demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_html/login.html.heex
    - demo/ledger_loop/test/ledger_loop_web/controllers/route_affordance_controller_test.exs
    - demo/ledger_loop/lib/ledger_loop_web/controllers/page_controller.ex
    - demo/ledger_loop/lib/ledger_loop_web/controllers/page_html/home.html.heex
    - demo/ledger_loop/test/ledger_loop_web/controllers/page_controller_test.exs
decisions:
  - "The optional Keycloak job is visible only when the stable provisioner connection exists in enabled state; missing, draft, and disabled records do not render a target."
  - "Workspace proof is derived solely from persisted LoginReceipt existence and uses the locked receipt wording without asserting a browser cookie or authorization state."
metrics:
  duration: 14min
  completed: 2026-08-26
  tasks_completed: 2
  files: 6
status: complete
---

# Phase 70 Plan 04: Honest Login Affordance and Receipt Summary

**LedgerLoop now exposes the optional Keycloak sign-in job only when its configured trust is enabled and displays a durable, exact verified-sign-in receipt after host mapping and session-establishment evidence exists.**

## Accomplishments

- Kept the FakeIdP link as the first, always-present deterministic login job.
- Gated the native `Test with Keycloak (optional real IdP)` link on the provisioner's stable connection being persisted with `:enabled` status.
- Added focused absent, disabled, and enabled affordance coverage with the exact connection-scoped href.
- Added receipt presence coverage that inserts a valid host-owned `LoginReceipt` and confirms the exact locked workspace evidence appears only afterward.
- Preserved native anchors, existing layout classes, accessible link names, visible focus behavior, and the calm Canonical Lock Set voice.

## Task Commits

1. **Task 1 RED: Specify conditional Keycloak login affordance** — `3ee95f9` (test)
2. **Task 1 GREEN: Gate Keycloak login affordance by trust state** — `8ec33dd` (feat)
3. **Task 2 RED: Specify durable workspace receipt evidence** — `2c41902` (test)
4. **Task 2 GREEN: Show durable verified sign-in receipt** — `5c2dfa5` (feat)

## Verification

- Passed `cd demo/ledger_loop && mix test test/ledger_loop_web/controllers/page_controller_test.exs test/ledger_loop_web/controllers/route_affordance_controller_test.exs --warnings-as-errors` (9 tests, 0 failures).
- Passed `git diff --check` for the plan changes.
- The plan commits modify only demo-owned Phoenix controllers/templates and their focused tests; no `lib/relyra/**`, public behavior, SessionAdapter, cookie, or authorization boundary changed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Commit scope] Corrected the first RED commit before proceeding**
- **Found during:** Task 1
- **Issue:** Existing user-staged demo files were included by a normal commit after path staging.
- **Fix:** Rewrote only that immediately preceding commit with `git commit --only`, preserving the user files staged and excluding them from every Plan 70-04 commit.
- **Files modified:** `demo/ledger_loop/test/ledger_loop_web/controllers/route_affordance_controller_test.exs`
- **Verification:** The corrected commit contains one file; user-owned staged files remain staged and unchanged.
- **Commit:** `3ee95f9`

**Total deviations:** 1 auto-fixed (Rule 1). **Impact:** No product or security scope change.

## Known Stubs

None.

## Deferred Issues

- Repository-wide `cd demo/ledger_loop && mix format --check-formatted` remains blocked by pre-existing formatting drift in `lib/ledger_loop_web/live/setup_live.html.heex`, `lib/ledger_loop_web/components/layouts/root.html.heex`, `lib/ledger_loop_web/controllers/fake_idp_html/login.html.heex`, `lib/ledger_loop_web/controllers/fake_idp_html/sso.html.heex`, `lib/ledger_loop/demo/keycloak_provisioner.ex`, and existing unrelated tests. These files are outside Plan 70-04 scope and were left unchanged.

## Self-Check: PASSED

- All six plan files exist and the four RED/GREEN commits are present in git history.
- Focused controller verification passed after the final implementation change.
- The optional link is absent without enabled configured trust, while FakeIdP remains available.
