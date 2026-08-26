---
phase: 70-keycloak-behind-the-proxy
reviewed: 2026-08-26T17:20:06Z
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
  critical: 2
  warning: 0
  info: 0
  total: 2
status: issues_found
---

# Phase 70: Code Review Report

**Reviewed:** 2026-08-26T17:20:06Z
**Depth:** standard
**Files Reviewed:** 12
**Status:** issues_found

## Summary

The optional Keycloak flow has two blockers at trust and diagnostic boundaries. The provisioner parses the same descriptor twice before installing trust, contrary to the project's one-parse invariant. In addition, the failure-artifact path retains raw Playwright traces even though the browser submits both the test password and SAML response; the harness redacts only text logs.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Descriptor bytes are parsed twice on the trust-install path

**File:** `/Users/jon/projects/relyra/demo/ledger_loop/lib/ledger_loop/demo/keycloak_provisioner.ex:67-76,143-149`

**Issue:** `descriptor_facts/2` parses the fetched XML with `Parser.parse/1`, then `import_descriptor/2` passes the same bytes to `Import.import_xml/3`, which parses them again before applying the metadata. This violates the project’s non-negotiable one-parse/no-parser-differential invariant at the descriptor-to-trust boundary. A future change to either parsing path or its options can make the issuer/certificate facts checked before disable differ from the facts persisted as authentication trust.

**Fix:** Refactor the metadata seam so parsing occurs once and both preflight validation and persistence consume that parsed candidate. For example, have the existing import seam return or accept the already parsed/canonical candidate, validate its issuer before any mutation, and apply that exact candidate; do not call `Parser.parse/1` independently in the provisioner.

### CR-02: Failure artifacts retain credentials and signed assertions without redaction

**File:** `/Users/jon/projects/relyra/scripts/test_keycloak_proxy_e2e.sh:247-251`

**Issue:** The harness directs Playwright failure output into the retained diagnostic directory. The Keycloak Playwright configuration uses `trace: "retain-on-failure"`; those trace ZIPs capture browser network activity, including the password form submission and the `POST` body containing `SAMLResponse`. `redact_diagnostics/0` is applied only to shell/Compose text logs and never inspects or sanitizes these binary artifacts. This breaks the phase’s explicit prohibition against retaining test credentials or raw assertions in diagnostic artifacts.

**Fix:** Do not retain Playwright traces for this credential-bearing flow (set trace retention to `off` for this config/run), or implement a reliable sanitizer that removes request bodies and sensitive snapshots before artifacts are retained. Keep only redacted, allowlisted failure metadata in `${ARTIFACT_DIR}` and add a test that fails the browser lane and proves no trace/archive contains `KEYCLOAK_SARAH_PASSWORD` or `SAMLResponse` content.

---

_Reviewed: 2026-08-26T17:20:06Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
