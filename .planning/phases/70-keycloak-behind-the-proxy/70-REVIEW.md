---
phase: 70-keycloak-behind-the-proxy
reviewed: 2026-08-26T20:24:17Z
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

**Reviewed:** 2026-08-26T20:24:17Z
**Depth:** standard
**Files Reviewed:** 16
**Status:** issues_found

## Summary

The reviewed provisioner now correctly encloses identity creation, its mapping audit, and final enablement in one outer transaction; the focused rollback and retry tests pass. The remaining blocker is in the harness's claimed fail-closed diagnostic redaction: namespaced, multiline SAML XML can retain assertion contents. The Basic-auth fail-closed behavior itself is implemented, but its missing-configuration branch lacks a regression test.

## Critical Issues

### CR-01: Namespaced multiline SAML XML can be retained in failure diagnostics

**File:** `scripts/test_keycloak_proxy_e2e.sh:37-46, 92-98`

**Issue:** The redactor and post-redaction validator recognize only unprefixed opening tags (`<Response>`, `<Assertion>`, and `<EntityDescriptor>`). SAML responses normally use namespace-qualified elements such as `<samlp:Response>` and `<saml:Assertion>`. For a multiline prefixed response, the final `sed` rule redacts the opening-tag line but does not enter the AWK XML-drop state; subsequent lines such as `<saml:AttributeValue>secret</saml:AttributeValue>` are preserved. The validator repeats the same unprefixed pattern, so it promotes that artifact. This violates the phase's explicit no-assertion/credential diagnostic-retention guarantee.

**Fix:** Treat optional namespace prefixes as part of every XML detector and test the actual multiline form before promotion. A single stateful redactor/validator is less error-prone than split AWK/sed rules; at minimum, cover both start and end tags:

```bash
# Match <Response>, <samlp:Response>, etc. in the redactor and validator.
xml_start_re='<(?:[[:alnum:]_.-]+:)?(Response|Assertion|EntityDescriptor)([[:space:]>]|$)'
xml_end_re='</(?:[[:alnum:]_.-]+:)?(Response|Assertion|EntityDescriptor)[[:space:]]*>'
```

Add a sentinel self-test containing a multiline `<samlp:Response>` with nested `<saml:Assertion>`/`<saml:AttributeValue>` and assert neither the sentinel nor any inner XML is retained.

## Warnings

### WR-01: Missing-runtime-credential deny-by-default behavior is untested

**File:** `demo/ledger_loop/test/ledger_loop_web/controllers/route_affordance_controller_test.exs:8-27`

**Issue:** The setup always installs valid `:demo_admin_auth` credentials, so only absent or invalid request credentials are exercised. The required branch where runtime credentials are missing or partial and `DemoAdminAuth` must challenge and halt has no regression coverage. A configuration fallback or shape regression could reopen the mounted admin surface without failing the suite.

**Fix:** Add a separate test that removes the application config (and covers empty username/password), requests both `/login/admin` and `/relyra/admin/connections/new`, and asserts `401`, the Basic challenge, and absence of all admin session keys. Restore the previous setting in `on_exit`, following the existing setup pattern.

---

_Reviewed: 2026-08-26T20:24:17Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
