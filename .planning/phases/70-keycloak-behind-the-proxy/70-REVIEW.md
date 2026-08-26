---
phase: 70-keycloak-behind-the-proxy
reviewed: 2026-08-26T19:43:08Z
depth: standard
files_reviewed: 16
files_reviewed_list:
  - demo/ledger_loop/config/runtime.exs
  - demo/ledger_loop/lib/ledger_loop/demo/keycloak_provisioner.ex
  - demo/ledger_loop/lib/ledger_loop_web/controllers/page_controller.ex
  - demo/ledger_loop/lib/ledger_loop_web/controllers/page_html/home.html.heex
  - demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_controller.ex
  - demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_html/login.html.heex
  - demo/ledger_loop/lib/ledger_loop_web/plugs/demo_admin_auth.ex
  - demo/ledger_loop/lib/ledger_loop_web/router.ex
  - demo/ledger_loop/lib/mix/tasks/ledger_loop.provision_keycloak.ex
  - demo/ledger_loop/test/browser/keycloak.spec.ts
  - demo/ledger_loop/test/ledger_loop/demo/keycloak_provisioner_test.exs
  - demo/ledger_loop/test/ledger_loop_web/controllers/page_controller_test.exs
  - demo/ledger_loop/test/ledger_loop_web/controllers/route_affordance_controller_test.exs
  - demo/ledger_loop/test/ledger_loop_web/fake_idp_flow_test.exs
  - docker/keycloak/realm-demo-app.json
  - scripts/test_keycloak_proxy_e2e.sh
findings:
  critical: 1
  warning: 1
  info: 0
  total: 2
status: issues_found
---

# Phase 70: Code Review Report

**Reviewed:** 2026-08-26T19:43:08Z
**Depth:** standard
**Files Reviewed:** 16
**Status:** issues_found

## Summary

The router does correctly place both `/login/admin` and the complete LiveAdmin mount behind the runtime-configured Basic-auth plug, and the focused admin/FakeIdP tests pass. However, the Keycloak provisioner creates a durable SAML identity mapping outside the audited transaction required for trust mutations. It can leave that mapping behind when a later provisioning stage fails. The new auth boundary also lacks a regression case for missing runtime credentials.

## Critical Issues

### CR-01: Keycloak identity mapping is written without an audit co-commit

**File:** `demo/ledger_loop/lib/ledger_loop/demo/keycloak_provisioner.ex:230-245`

**Issue:** `ensure_sarah_identity/1` inserts a durable issuer/subject-to-user mapping directly with `Repo.insert/1`. Unlike the connection, metadata, and certificate operations, it neither calls `Relyra.Ecto.AuditWriter.append_event/2` nor runs the identity write and audit event in one database transaction. Further, `ensure_sarah_identity/1` runs before `enable_connection/1` (line 50), so an enable failure leaves the mapping committed while `fail_closed/2` only disables the connection. This violates the project invariant that mapping/trust mutations co-commit an append-only audit row and leaves a latent authorization association after a failed provision.

**Fix:** Move the identity creation into an explicit `Repo.transaction/1` that also appends a `:mapping` audit event using the provisioner's existing actor/cause/correlation context; roll back if either write fails. Make connection enablement part of the same transaction, or compensate by deleting/rolling back the newly-created identity when enablement fails. Add regression tests that force the identity-audit and enable stages to fail and assert both that no identity remains and that successful creation has the matching audit row.

## Warnings

### WR-01: Missing-runtime-credential deny-by-default behavior is untested

**File:** `demo/ledger_loop/test/ledger_loop_web/controllers/route_affordance_controller_test.exs:8-27`

**Issue:** The setup always installs a valid `:demo_admin_auth` configuration, so the tests only exercise absent or invalid request credentials. They never exercise the required security case where `DEMO_ADMIN_USERNAME`/`DEMO_ADMIN_PASSWORD` are absent or incomplete and `DemoAdminAuth.configured_credentials/0` must challenge and halt. A future fallback, stale configuration, or runtime config-shape regression could silently reopen the admin mount without failing this suite.

**Fix:** Add a separate test that deletes `Application.delete_env(:ledger_loop, :demo_admin_auth)` (and cases with an empty username or password), requests both `/login/admin` and `/relyra/admin/connections/new`, and asserts `401`, the Basic challenge, and absence of all three admin session keys. Restore configuration in `on_exit` as the existing setup does.

---

_Reviewed: 2026-08-26T19:43:08Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
