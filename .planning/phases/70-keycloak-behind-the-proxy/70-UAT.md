---
status: diagnosed
phase: 70-keycloak-behind-the-proxy
source: [70-VERIFICATION.md]
started: 2026-08-26T21:11:23Z
updated: 2026-08-26T21:47:29Z
---

## Current Test

[testing complete]

## Tests

### 1. Live full round trip

expected: Run `npm run demo:keycloak-proxy` with Docker and the host browser available. Public proxy hosts, descriptor trust, the browser ACS journey, one receipt, and exactly Validate response, Verify signature, and Replay check must all pass.
result: issue
reported: "Automated run passed the real Keycloak Chromium journey, scoped ACS 302, one durable receipt, and the exact three canonical trace steps, but the command exited 1 in root_security because mint 1.8.0 and req 0.5.18 are vulnerable."
severity: major

### 2. Visual and failed-state backstops

expected: Exercise a failed Keycloak journey and inspect Login Trace with keyboard navigation, a narrow viewport, and long values. No false success or receipt remains after failure; recovery is clear and all evidence stays visible and operable.
result: issue
reported: "Automated inspection found no executable browser assertions for the failed-destination, keyboard, narrow-viewport, or long-value expectations; they remain manual prose-only backstops."
severity: major

## Summary

total: 2
passed: 0
issues: 2
pending: 0
skipped: 0
blocked: 0

## Gaps

- gap_id: G-70-1
  truth: "Run `npm run demo:keycloak-proxy` with Docker and the host browser available. Public proxy hosts, descriptor trust, the browser ACS journey, one receipt, and exactly Validate response, Verify signature, and Replay check must all pass."
  status: failed
  reason: "Automated run passed the real Keycloak Chromium journey, scoped ACS 302, one durable receipt, and the exact three canonical trace steps, but the command exited 1 in root_security because mint 1.8.0 and req 0.5.18 are vulnerable."
  severity: major
  test: 1
  root_cause: "The Keycloak behavior is green, but its scenario harness unconditionally runs repository-wide mix ci.security afterward; deps.audit then rejects the independently vulnerable req 0.5.18 and transitive mint 1.8.0 lock resolution."
  artifacts:
    - path: "scripts/test_keycloak_proxy_e2e.sh"
      issue: "Couples the focused Keycloak lifecycle proof to repository-wide QA, security, and format gates after all scenario assertions pass."
    - path: "mix.lock"
      issue: "Resolves req 0.5.18 and mint 1.8.0, which current advisories reject."
    - path: ".github/workflows/security-gates.yml"
      issue: "Already owns the recurring repository dependency-security gate, making the same audit inside the scenario harness redundant."
  missing:
    - "Decouple repository-wide gates from the focused Keycloak acceptance command without suppressing advisories."
    - "Upgrade Req and its resolved Finch/Mint graph in a dedicated security dependency change."
    - "Add a focused recurring Keycloak proxy CI gate as the only public Keycloak/Traefik/ACS integration proof."
  debug_session: .planning/debug/phase-70-keycloak-gate-not-green.md
- gap_id: G-70-2
  truth: "Exercise a failed Keycloak journey and inspect Login Trace with keyboard navigation, a narrow viewport, and long values. No false success or receipt remains after failure; recovery is clear and all evidence stays visible and operable."
  status: failed
  reason: "Automated inspection found no executable browser assertions for the failed-destination, keyboard, narrow-viewport, or long-value expectations; they remain manual prose-only backstops."
  severity: major
  test: 2
  root_cause: "Phase 70 intentionally left these expectations as manual backstops: the only Keycloak Playwright test covers the happy path, while the deterministic FakeIdP rejection and stable Login Trace selectors were never composed into a credential-safe visual browser fixture."
  artifacts:
    - path: "demo/ledger_loop/test/browser/keycloak.spec.ts"
      issue: "Contains one happy-path signed-login test and no failed-state, keyboard, viewport, or long-value assertions."
    - path: "demo/ledger_loop/test/browser/fake_idp.spec.ts"
      issue: "Provides the deterministic typed-rejection/no-workspace seam but does not inspect authenticated Login Trace recovery or presentation."
    - path: "lib/relyra/live_admin/connection_trace_live.ex"
      issue: "Provides stable trace selectors and native details controls, but the fixed table lacks explicit narrow-viewport overflow treatment."
    - path: ".github/workflows/demo-app-e2e.yml"
      issue: "Is the existing recurring FakeIdP browser lane but does not execute a trace-visual project."
  missing:
    - "Add a dedicated FakeIdP-backed trace-visual Playwright project with ephemeral Basic credentials and all attachment channels disabled."
    - "Assert failed ACS leaves no workspace or receipt, exposes the typed rejection, and provides operable Back recovery."
    - "Assert native details keyboard behavior, narrow-viewport accessibility, and visible safe long cause/error-code values."
    - "Run the deterministic trace-visual project in the existing demo-app E2E CI lane."
  debug_session: .planning/debug/phase-70-visual-failure-automation-gap.md
