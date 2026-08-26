---
status: complete
phase: 70-keycloak-behind-the-proxy
source: [70-VERIFICATION.md]
started: 2026-08-26T21:11:23Z
updated: 2026-08-26T21:43:02Z
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
  artifacts: []
  missing: []
- gap_id: G-70-2
  truth: "Exercise a failed Keycloak journey and inspect Login Trace with keyboard navigation, a narrow viewport, and long values. No false success or receipt remains after failure; recovery is clear and all evidence stays visible and operable."
  status: failed
  reason: "Automated inspection found no executable browser assertions for the failed-destination, keyboard, narrow-viewport, or long-value expectations; they remain manual prose-only backstops."
  severity: major
  test: 2
  artifacts: []
  missing: []
