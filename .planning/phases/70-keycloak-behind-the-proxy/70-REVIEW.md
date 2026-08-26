---
phase: 70-keycloak-behind-the-proxy
reviewed: 2026-08-26T17:37:00Z
depth: standard
files_reviewed: 12
files_reviewed_list:
  - demo/ledger_loop/lib/ledger_loop/demo/keycloak_provisioner.ex
  - demo/ledger_loop/lib/ledger_loop_web/controllers/page_controller.ex
  - demo/ledger_loop/lib/ledger_loop_web/controllers/page_html/home.html.heex
  - demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_controller.ex
  - demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_html/login.html.heex
  - demo/ledger_loop/lib/mix/tasks/ledger_loop.provision_keycloak.ex
  - demo/ledger_loop/test/browser/keycloak.spec.ts
  - demo/ledger_loop/test/ledger_loop/demo/keycloak_provisioner_test.exs
  - demo/ledger_loop/test/ledger_loop_web/controllers/page_controller_test.exs
  - demo/ledger_loop/test/ledger_loop_web/controllers/route_affordance_controller_test.exs
  - docker/keycloak/realm-demo-app.json
  - scripts/test_keycloak_proxy_e2e.sh
findings:
  critical: 1
  warning: 0
  info: 0
  total: 1
status: issues_found
---

# Phase 70: Code Review Report

**Reviewed:** 2026-08-26T17:37:00Z
**Depth:** standard
**Files Reviewed:** 12
**Status:** issues_found

## Summary

The Keycloak provisioning path uses the audited metadata and certificate seams and the harness keeps Playwright attachments disabled. However, the phase exposes an unauthenticated route that establishes the exact session values the admin scope provider treats as authorization. This gives every network caller access to privileged trust-management operations.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Public endpoint grants an administrator session

**File:** `/Users/jon/projects/relyra/demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_controller.ex:23-28`

**Issue:** `GET /login/admin` accepts no credentials or authorization proof, but writes `admin_actor`, `admin_actor_label`, and `admin_organization_id` into the caller's session. `LedgerLoop.Relyra.AdminScope` accepts any non-empty `admin_actor` as authenticated, and the mounted `/relyra/admin` LiveViews use that scope to update connections, enable/disable them, and manage certificate/metadata trust. Any unauthenticated visitor can therefore become `demo_admin` and mutate SAML trust.

**Fix:** Remove this route from the publicly reachable application and populate those session fields only after the host application's real administrator authentication/authorization check. If a demo-only shortcut is indispensable, put it behind an explicit development/test-only configuration and a local-only guard; do not mount it in a production router.

---

_Reviewed: 2026-08-26T17:37:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
