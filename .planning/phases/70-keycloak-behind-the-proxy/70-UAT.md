---
status: testing
phase: 70-keycloak-behind-the-proxy
source: [70-VERIFICATION.md]
started: 2026-08-26T21:11:23Z
updated: 2026-08-26T21:11:23Z
---

## Current Test

number: 1
name: Live full round trip
expected: |
  The full lifecycle passes: proxy hosts, descriptor trust, ACS journey, one receipt, and exactly three canonical trace steps.
awaiting: user response

## Tests

### 1. Live full round trip

expected: Run `npm run demo:keycloak-proxy` with Docker and the host browser available. Public proxy hosts, descriptor trust, the browser ACS journey, one receipt, and exactly Validate response, Verify signature, and Replay check must all pass.
result: [pending]

### 2. Visual and failed-state backstops

expected: Exercise a failed Keycloak journey and inspect Login Trace with keyboard navigation, a narrow viewport, and long values. No false success or receipt remains after failure; recovery is clear and all evidence stays visible and operable.
result: [pending]

## Summary

total: 2
passed: 0
issues: 0
pending: 2
skipped: 0
blocked: 0

## Gaps
