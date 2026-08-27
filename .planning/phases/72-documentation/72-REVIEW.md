---
phase: 72-documentation
reviewed: 2026-08-27T00:00:00Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - README.md
  - demo/ledger_loop/README.md
  - guides/demo.md
  - guides/docker_dev_dx.md
  - test/docs/demo_guide_drift_test.exs
findings:
  critical: 2
  warning: 0
  info: 0
  total: 2
status: issues_found
---

# Phase 72: Code Review Report

**Reviewed:** 2026-08-27T00:00:00Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

The documentation routes evaluators through two claimed proof paths that do not match the runnable demo: the detailed README describes a FakeIdP principal that the implementation does not emit, and the advertised Keycloak route never starts the Keycloak profile or its provisioner. The static drift test passes because it asserts copy tokens rather than these executable contracts.

## Critical Issues

### CR-01: The documented FakeIdP principal and default result contradict the demo

**Classification:** BLOCKER

**File:** `demo/ledger_loop/README.md:82-103`

**Issue:** The README says the valid FakeIdP response uses `evaluator@example.com`, does not match a seeded identity, and therefore cannot produce the session-establishment receipt it tells the evaluator to expect. The runnable form instead labels its valid action `sarah@northstar.example.com`, and `FakeIdPController.conn_fields/0` emits that same subject. `Fixtures.saml_identities/0` seeds the matching Sarah identity, so the actual default valid flow maps Sarah and can write a `LoginReceipt`. The current text gives evaluators a false expected identity and falsely characterizes the successful proof as an unresolved future exercise.

**Fix:** Replace the `evaluator@example.com` narrative and mismatch callout with the actual `sarah@northstar.example.com` successful path, and add a drift assertion that reads the FakeIdP form/controller subject (or, preferably, an end-to-end demo assertion that proves the `LoginReceipt` is created).

### CR-02: The Keycloak follow-on is documented without any command that starts it

**Classification:** BLOCKER

**File:** `demo/ledger_loop/README.md:196-213`

**Issue:** The listed commands run `make proxy` and `make up-build`. `make proxy` starts only Traefik; `make up-build` invokes the solo `docker compose` command. Neither enables Compose's `keycloak` profile, so neither the `keycloak` service nor `keycloak_provisioner` runs. The claimed `http://keycloak.relyra.localhost` route and its required connection therefore do not exist after following the guide. The same incomplete route is promoted by `guides/docker_dev_dx.md:109-121` and `guides/demo.md:12-24`.

**Fix:** Add a public Make target that invokes the fleet compose configuration with `--profile keycloak` and waits for/provisions the connection, then document that target as the required Keycloak step. Extend `test/docs/demo_guide_drift_test.exs` with an executable Make-command contract for that target rather than only checking that the docs contain Keycloak wording.

---

_Reviewed: 2026-08-27T00:00:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
