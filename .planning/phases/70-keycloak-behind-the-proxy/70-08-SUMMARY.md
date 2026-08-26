---
phase: 70-keycloak-behind-the-proxy
plan: "08"
subsystem: demo-admin-authentication
tags: [keycloak, basic-auth, live-admin, playwright, security]
dependency_graph:
  requires: [70-07]
  provides: [authenticated host-admin trace proof]
  affects: [keycloak-e2e, demo-live-admin, security-gates]
tech_stack:
  added: []
  patterns: [runtime-only Basic credentials, fixed authenticated principal, ephemeral redacted E2E secret]
key_files:
  created:
    - demo/ledger_loop/lib/ledger_loop_web/plugs/demo_admin_auth.ex
  modified:
    - demo/ledger_loop/config/runtime.exs
    - demo/ledger_loop/lib/ledger_loop_web/router.ex
    - demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_controller.ex
    - demo/ledger_loop/test/ledger_loop_web/controllers/route_affordance_controller_test.exs
    - demo/ledger_loop/test/ledger_loop_web/fake_idp_flow_test.exs
    - docker-compose.proxy.yml
    - demo/ledger_loop/test/browser/keycloak.spec.ts
    - scripts/test_keycloak_proxy_e2e.sh
decisions:
  - "The single DemoAdminAuth router pipeline guards both the bootstrap route and the full LiveAdmin mount, while AdminScope remains unchanged."
  - "The owned Keycloak harness generates a per-run host-admin password and treats it as forbidden diagnostic material."
metrics:
  duration: "~20 minutes"
  completed: "2026-08-26"
status: complete
---

# Phase 70 Plan 08: Authenticated Keycloak trace proof Summary

The Keycloak evidence journey now crosses a fail-closed, runtime-only host-admin Basic-auth boundary before it can establish the fixed Northstar admin scope or inspect the correlation-specific Login Trace.

## Completed Tasks

1. Added `LedgerLoopWeb.Plugs.DemoAdminAuth`, runtime credential configuration, and one router pipeline protecting both `/login/admin` and every mounted `/relyra/admin` route. The controller copies session values solely from the Plug's fixed principal assignment.
2. Added an ephemeral host-admin credential pair to the owned Keycloak Compose/Playwright harness, explicit diagnostic redaction, and an authenticated post-ACS Login Trace transition. The FakeIdP trace test now supplies the same test-only host-auth boundary.

## Verification

- Focused admin route tests: passed — unauthenticated and invalid credentials return `401` with a Basic challenge and no scope session keys; valid credentials establish only the fixed principal.
- `KEYCLOAK_PROXY_ARTIFACT_POLICY_SELF_TEST=1 bash scripts/test_keycloak_proxy_e2e.sh`: passed.
- `KEYCLOAK_PROXY_STATIC_ONLY=1 bash scripts/test_keycloak_proxy_e2e.sh`: passed.
- `npx playwright test --config=playwright.keycloak-proxy.config.mjs --list`: passed (one spec).
- Focused controller, router, and FakeIdP regression suite: passed (10 tests).
- `mix test --warnings-as-errors`: passed in the repository QA run.
- `mix qa`: passed (768 tests).
- `mix ci.security`: started after QA but the executor command window ended while its isolated security processes were still running; no failure was observed before interruption. Re-run before release.
- `mix format --check-formatted`: passed in each commit hook; the final standalone root check was not reached because the same command window ended during `mix ci.security`.

## TDD Gate Compliance

- RED: `648a36c` establishes denied bootstrap and mutation-route behavior; `64463c7` adds fail-closed Compose and diagnostic-policy expectations.
- GREEN: `46e0078` implements the runtime Basic-auth boundary; `fe00a8e` implements ephemeral credential choreography and authenticated browser evidence.
- REFACTOR: `bdac2a6` formats the admin authorization regression test.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Regression] Updated the FakeIdP trace test for the new LiveAdmin boundary**
- **Found during:** Task 2 focused verification.
- **Issue:** Its direct LiveView trace request relied on the former public admin path and received `401` after the complete admin mount became protected.
- **Fix:** Added test-only runtime credentials and Basic authorization to its admin test connection.
- **Files modified:** `demo/ledger_loop/test/ledger_loop_web/fake_idp_flow_test.exs`
- **Commit:** `fe00a8e`

**2. [Rule 1 - Existing protection] The first password-sentinel RED assertion passed because Phase 70's prior generic password redactor already covered it.**
- **Found during:** Task 2 RED.
- **Fix:** Added the required fail-closed Compose-environment assertion, then made `DEMO_ADMIN_PASSWORD` explicit in the production redaction and validation policy.
- **Files modified:** `scripts/test_keycloak_proxy_e2e.sh`
- **Commit:** `64463c7`, `fe00a8e`

## Known Stubs

None.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: authentication boundary | `demo/ledger_loop/lib/ledger_loop_web/plugs/demo_admin_auth.ex` | New host-admin Basic-auth boundary is fail-closed, runtime-configured, and supplies only a fixed principal. |

## Self-Check: PASSED

- Confirmed all planned implementation and test artifacts exist.
- Confirmed commits `648a36c`, `46e0078`, `bdac2a6`, `64463c7`, and `fe00a8e` exist.
