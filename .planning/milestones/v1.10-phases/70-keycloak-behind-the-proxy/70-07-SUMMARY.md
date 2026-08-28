---
phase: 70-keycloak-behind-the-proxy
plan: "07"
subsystem: testing
tags: [playwright, keycloak, diagnostics, redaction, security]
requires:
  - phase: 70-06
    provides: canonical single-parse Keycloak descriptor trust installation
provides:
  - Credential-bearing Playwright configuration with all attachment modes disabled
  - Ephemeral browser-output cleanup and fail-closed allowlisted diagnostics retention
affects: [phase-70-verification, keycloak-e2e, security-gates]
tech-stack:
  added: []
  patterns:
    - Private staged diagnostics are validated before atomic promotion
    - Browser output is isolated outside retained diagnostic paths and removed before capture
key-files:
  created: []
  modified:
    - playwright.keycloak-proxy.config.mjs
    - scripts/test_keycloak_proxy_e2e.sh
key-decisions:
  - "Credential-bearing Keycloak Playwright runs disable all attachments and delete a per-run temporary output directory before diagnostics."
  - "Keycloak E2E diagnostics retain only validated redacted container-state.log, relyra.log, and audit-actions.log files."
requirements-completed: [KC-01]
coverage:
  - id: D1
    description: Credential-bearing Keycloak Playwright capture is attachment-free and browser output is ephemeral.
    requirement: KC-01
    verification:
      - kind: other
        ref: KEYCLOAK_PROXY_ARTIFACT_POLICY_SELF_TEST=1 bash scripts/test_keycloak_proxy_e2e.sh
        status: pass
      - kind: automated_ui
        ref: npx playwright test --config=playwright.keycloak-proxy.config.mjs --list
        status: pass
    human_judgment: false
  - id: D2
    description: Failed Keycloak diagnostics are redacted, allowlisted text files promoted only after validation, and discarded on uncertainty.
    requirement: KC-01
    verification:
      - kind: other
        ref: KEYCLOAK_PROXY_ARTIFACT_POLICY_SELF_TEST=1 bash scripts/test_keycloak_proxy_e2e.sh
        status: pass
      - kind: integration
        ref: mix ci.security
        status: pass
    human_judgment: false
duration: 8m
completed: 2026-08-26
status: complete
---

# Phase 70 Plan 07: Credential-Safe Keycloak Diagnostics Summary

**Attachment-free Keycloak browser proof with ephemeral output and fail-closed, redacted text diagnostics.**

## Performance

- **Duration:** 8m
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Disabled trace, video, screenshot, and persistent attachment reporters for the credential-bearing Keycloak Playwright project.
- Isolated browser output in a validated per-run temporary directory and removed it before diagnostics capture and in every trap path.
- Added private diagnostic staging, exact three-file validation, redaction, and all-or-nothing retention with an offline policy proof.

## Task Commits

1. **Task 1: Disable sensitive browser capture and isolate all Playwright output ephemerally** — `7ec002a` (RED test), `7862c75` (GREEN fix)
2. **Task 2: Retain only policy-validated redacted text diagnostics and rerun security regressions** — `ab01140` (RED test), `52255aa` (GREEN fix)

## Files Created/Modified

- `playwright.keycloak-proxy.config.mjs` — disables all sensitive capture modes and keeps list-only reporting.
- `scripts/test_keycloak_proxy_e2e.sh` — owns temporary browser output, validates staged diagnostics, and hosts the Docker-free policy proof.

## Decisions Made

- Browser artifacts are never sanitized for retention; they are disabled and removed before any diagnostic capture.
- Only `container-state.log`, `relyra.log`, and `audit-actions.log` may be retained after redaction and validation.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Compatibility] Replaced GNU-only `find -printf` in the policy proof.**
- **Found during:** Task 2
- **Issue:** macOS `find` rejected `-printf`, preventing the offline security self-test from running.
- **Fix:** Used portable `find ... -exec basename` output for the allowlist assertion and validator.
- **Files modified:** `scripts/test_keycloak_proxy_e2e.sh`
- **Verification:** `KEYCLOAK_PROXY_ARTIFACT_POLICY_SELF_TEST=1 bash scripts/test_keycloak_proxy_e2e.sh`
- **Committed in:** `52255aa`

**Total deviations:** 1 auto-fixed (Rule 1)

## Verification

- `KEYCLOAK_PROXY_ARTIFACT_POLICY_SELF_TEST=1 bash scripts/test_keycloak_proxy_e2e.sh` — passed
- `KEYCLOAK_PROXY_STATIC_ONLY=1 bash scripts/test_keycloak_proxy_e2e.sh` — passed
- `npx playwright test --config=playwright.keycloak-proxy.config.mjs --list` — passed (one Keycloak spec selected)
- Focused Keycloak provisioner and FakeIdP flow tests — passed (11 tests)
- `mix test --warnings-as-errors` — passed (768 tests)
- `mix ci.security` — passed
- `mix format --check-formatted` — passed

## Known Stubs

None.

## Next Phase Readiness

The Keycloak proxy proof can now expose only actionable, text-only diagnostics. A live `npm run demo:keycloak-proxy` remains the owned runtime proof after the phase closure.

## Self-Check: PASSED

- Confirmed both modified implementation files and all four task commits exist.
