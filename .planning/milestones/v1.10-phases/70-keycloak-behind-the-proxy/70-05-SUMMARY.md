---
phase: 70-keycloak-behind-the-proxy
plan: "05"
subsystem: demo-browser-e2e
tags: [keycloak, playwright, saml, security-gates]
dependency_graph:
  requires: [70-03, 70-04]
  provides: [KC-01 evaluator-grade public Keycloak proof]
  affects: [phase-70-verification, demo-keycloak-profile]
tech_stack:
  added: []
  patterns: [public-origin assertion, scoped ACS response capture, correlation-scoped Login Trace, harness-owned failure artifacts]
key_files:
  created: []
  modified:
    - demo/ledger_loop/test/browser/keycloak.spec.ts
    - playwright.keycloak-proxy.config.mjs
    - scripts/test_keycloak_proxy_e2e.sh
decisions:
  - "The canonical successful Login Trace proves only response validation, signature verification, and replay checking; workspace return plus LoginReceipt separately prove host mapping and session establishment."
  - "The optional Keycloak path starts from its conditional semantic link and asserts public origins plus the exact connection-scoped ACS POST."
metrics:
  duration: "~7 minutes"
  completed: "2026-08-26"
status: complete
---

# Phase 70 Plan 05: Keycloak proof and regression gates Summary

The optional Keycloak profile now supplies host-side evidence for the exact public SAML ACS journey, durable LedgerLoop receipt, and one correlation's validation/signature/replay trace, while FakeIdP and permanent crypto gates remain independent.

## Completed Tasks

1. Replaced the redirect-only Keycloak browser smoke test with the full optional-link → public Keycloak → Sarah → exact scoped ACS POST → workspace journey. It verifies the exact receipt copy and scopes the Login Trace assertion to the newest successful correlation's `Validate response`, `Verify signature`, and `Replay check` rows.
2. Extended the owned Keycloak proxy harness with a FakeIdP-first regression lane, focused demo coverage, root warnings-as-errors, QA, security subprocess, and formatting gates. Playwright failure-only trace, screenshot, and video artifacts are placed beneath the harness-owned diagnostics directory.

## Verification

- `npx playwright test --config=playwright.keycloak-proxy.config.mjs --list` — passed (one Keycloak spec selected).
- `npm run demo:keycloak-proxy` — passed: FakeIdP success/tamper tests (2), public Keycloak Playwright proof (1), exact canonical trace steps, receipt checks, focused demo tests (16), root `mix test --warnings-as-errors`, `mix qa`, `mix ci.security`, and `mix format --check-formatted`.
- `mix qa` exited 0. The previously recorded advisory-only dependency state for `mint 1.8.0` and `req 0.5.18` remains distinct and out of scope; no dependency change was made.

## TDD Gate Compliance

- RED: `36fc37f` records the stronger public browser contract and the harness failed at the intentionally over-specific Keycloak root-path assertion.
- GREEN: `643d388` corrects that assertion to the exact public Keycloak origin and the full harness passes.

## Deviations from Plan

None - plan executed exactly as written.

## Security Boundaries Preserved

- No `lib/relyra/**`, dependency, public API, or security-policy changes.
- No browser database query, XML mutation, cookie-session claim, response-body logging, or credential logging.
- The FakeIdP typed digest-tamper and permanent adversarial crypto paths are unchanged and executed independently.

## Self-Check: PASSED

- Confirmed all three task artifacts and this summary exist.
- Confirmed commits `36fc37f`, `643d388`, and `0bb99e9` exist in git history.
