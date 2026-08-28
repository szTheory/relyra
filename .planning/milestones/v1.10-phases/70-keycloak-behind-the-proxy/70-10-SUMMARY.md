---
phase: 70-keycloak-behind-the-proxy
plan: "10"
subsystem: security-testing
tags: [keycloak, diagnostics, redaction, saml, basic-auth]
dependency_graph:
  requires: [70-09]
  provides: [namespace-aware diagnostic retention policy, runtime admin credential denial coverage]
  affects: [keycloak-e2e, KC-01, diagnostic-artifacts]
tech_stack:
  added: []
  patterns: [independent shell state machines for redaction and promotion validation, table-driven runtime configuration denial tests]
key_files:
  created: []
  modified:
    - scripts/test_keycloak_proxy_e2e.sh
    - demo/ledger_loop/test/ledger_loop_web/controllers/route_affordance_controller_test.exs
key_decisions:
  - "Diagnostic redaction and promotion validation each track exact protected XML root QNames independently and fail closed at EOF."
  - "Incomplete demo-admin runtime configuration is covered at both guarded route families without changing authorization behavior."
requirements-completed: [KC-01]
coverage:
  - id: D1
    description: "Qualified multiline SAML and metadata XML is redacted and cannot be promoted from retained diagnostic staging."
    requirement: KC-01
    verification:
      - kind: integration
        ref: "KEYCLOAK_PROXY_ARTIFACT_POLICY_SELF_TEST=1 bash scripts/test_keycloak_proxy_e2e.sh"
        status: pass
    human_judgment: false
  - id: D2
    description: "Missing, partial, and empty demo admin credentials deny both protected route families without session scope."
    requirement: KC-01
    verification:
      - kind: integration
        ref: "demo/ledger_loop/test/ledger_loop_web/controllers/route_affordance_controller_test.exs#rejects absent and partial runtime credentials before admin scope establishment"
        status: pass
    human_judgment: false
metrics:
  duration: "~12 minutes"
  completed: "2026-08-26"
status: complete
---

# Phase 70 Plan 10: Namespace-safe diagnostics Summary

Qualified SAML and metadata XML is now suppressed across complete documents and independently blocked from promotion, while direct route coverage proves incomplete host-admin configuration cannot establish demo scope.

## Performance

- **Duration:** ~12 minutes
- **Tasks:** 2/2
- **Files modified:** 2

## Accomplishments

- Added adversarial qualified-XML fixtures for multiline, nested, same-line, alternate-prefix, and unterminated documents.
- Made diagnostic redaction and promotion validation use separate protected-root state machines with matching QName closure and EOF fail-closed behavior.
- Added table-driven denials for absent, partial, and empty runtime demo-admin credentials on both guarded routes.

## Task Commits

1. **Task 1 RED: qualified diagnostic policy regressions** — `26c70d4` (test)
2. **Task 1 GREEN: reject qualified diagnostic XML** — `b63e8e6` (fix)
3. **Task 2: cover incomplete demo admin credentials** — `edb08e3` (test)

## Files Created/Modified

- `scripts/test_keycloak_proxy_e2e.sh` — redacts protected QName documents and independently rejects retained raw XML.
- `demo/ledger_loop/test/ledger_loop_web/controllers/route_affordance_controller_test.exs` — exercises fail-closed runtime credential configurations.

## Decisions Made

- Redaction and validation do not share a state machine, marker, or sentinel dependency; either layer can independently prevent protected XML retention.
- The existing fail-closed `DemoAdminAuth` implementation needed only route-level regression evidence, not a behavior change.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test fixture] Moved the qualified XML fixture before the intentionally unterminated PEM sentinel.**
- **Found during:** Task 1 GREEN verification.
- **Issue:** The legacy PEM fixture correctly suppresses all subsequent lines, obscuring the new safe-boundary assertion.
- **Fix:** Ordered the qualified XML fixture before the PEM fixture so the test proves both redaction behavior and existing PEM fail-closed behavior.
- **Files modified:** `scripts/test_keycloak_proxy_e2e.sh`
- **Verification:** Artifact policy self-test passed.
- **Committed in:** `b63e8e6`

## Issues Encountered

- Task 2's new regression passed immediately because `DemoAdminAuth` already fail-closed for missing and empty credentials. The task intentionally adds proof only; no production authorization change was warranted.

## TDD Gate Compliance

- Task 1: RED `26c70d4` failed against the former unprefixed policy; GREEN `b63e8e6` passed both shell self-tests.
- Task 2: the test passed immediately because the planned behavior pre-existed; it is a regression-coverage-only task, so no GREEN production commit was created.

## Known Stubs

None.

## Self-Check: PASSED

- Confirmed both modified files exist.
- Confirmed task commits `26c70d4`, `b63e8e6`, and `edb08e3` exist.

## Next Phase Readiness

- D-26's qualified-XML retention bypass is covered by deterministic self-tests; the optional live Keycloak browser run remains outside this gap-closure plan.
