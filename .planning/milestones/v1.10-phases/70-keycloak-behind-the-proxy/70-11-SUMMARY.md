---
phase: 70-keycloak-behind-the-proxy
plan: "11"
subsystem: ci
tags: [keycloak, traefik, playwright, github-actions, docker]
requires:
  - phase: 70-10
    provides: credential-safe Keycloak browser proof and diagnostics policy
provides:
  - Focused Keycloak public-host acceptance command with truthful scenario status
  - Recurring artifact-free GitHub Actions proof for the Keycloak/Traefik ACS path
affects: [security-gates, keycloak-proxy-e2e, demo]
tech-stack:
  added: []
  patterns:
    - Dedicated integration workflows own their focused scenario without duplicating repository security gates
key-files:
  created:
    - .github/workflows/keycloak-proxy-e2e.yml
  modified:
    - scripts/test_keycloak_proxy_e2e.sh
key-decisions:
  - "The Keycloak harness exits on topology, browser ACS, receipt, trace, diagnostics, and cleanup evidence only."
  - "The recurring workflow retains no browser or credential-bearing artifacts and leaves dependency/security gates to security-gates.yml."
patterns-established:
  - "Public Keycloak proof runs on PRs, main, manual dispatch, and a daily offset schedule."
requirements-completed: [KC-01]
coverage:
  - id: D1
    description: Focused public Keycloak signed-ACS acceptance harness
    requirement: KC-01
    verification:
      - kind: e2e
        ref: npm run demo:keycloak-proxy
        status: pass
    human_judgment: false
  - id: D2
    description: Recurring artifact-free Keycloak proxy CI workflow
    requirement: KC-01
    verification:
      - kind: other
        ref: python3 YAML parse plus workflow command and policy checks
        status: pass
    human_judgment: false
metrics:
  duration: 7m
  completed: 2026-08-26
status: complete
---

# Phase 70 Plan 11: Focused Keycloak Scenario Gate Summary

**A truthful public Keycloak/Traefik signed-ACS acceptance command, now run in recurring artifact-free CI without masking dependency or security status.**

## Performance

- **Duration:** 7m
- **Started:** 2026-08-26T22:00:57Z
- **Completed:** 2026-08-26T22:07:40Z
- **Tasks:** 2/2
- **Files modified:** 2

## Accomplishments

- Removed FakeIdP, ExUnit, QA, dependency-security, and format gates from the Keycloak scenario's exit path while retaining its topology, browser, receipt, trace, redaction, and cleanup assertions.
- Added a 30-minute Keycloak proxy workflow for pull requests, `main`, manual dispatch, and a daily schedule offset from the fleet job.
- Kept browser attachments and workflow uploads absent; `security-gates.yml` remains the repository security and advisory owner.

## Task Commits

1. **Task 1: Make the Keycloak command a focused end-to-end acceptance gate** — `7956fbb` (`fix`)
2. **Task 2: Add the recurring public Keycloak integration workflow** — `c152f4f` (`ci`)

## Files Created/Modified

- `scripts/test_keycloak_proxy_e2e.sh` — reports only focused Keycloak public-host evidence.
- `.github/workflows/keycloak-proxy-e2e.yml` — runs the focused scenario in recurring, artifact-free CI.

## Decisions Made

- The focused command owns only its real Keycloak integration evidence; repository QA and dependency advisories remain independently visible through security CI.
- The workflow follows the fleet proof's checkout, Node 22, npm, and Chromium setup but intentionally has no artifact upload step.

## Verification

- `bash -n scripts/test_keycloak_proxy_e2e.sh` — passed.
- `KEYCLOAK_PROXY_STATIC_ONLY=1 bash scripts/test_keycloak_proxy_e2e.sh` — passed.
- `KEYCLOAK_PROXY_ARTIFACT_POLICY_SELF_TEST=1 bash scripts/test_keycloak_proxy_e2e.sh` — passed.
- `npm run demo:keycloak-proxy` — exited 0; Playwright passed 1/1, receipt count was 1, and trace steps were exactly `response.validate`, `signature.verify`, and `replay.check`.
- Workflow YAML parsed with installed Python PyYAML; trigger, timeout, command, and no-upload/security-command policy checks passed.

## Deviations from Plan

### Validation Environment Limitations

**1. [Rule 3 - Blocking tool unavailable] Used installed PyYAML for workflow parsing**
- **Found during:** Task 2
- **Issue:** The planned Ruby validator was unavailable because this checkout has no Ruby version configured; `scripts/ci_monitor.cjs` is absent, so its action-version checker could not run.
- **Fix:** Parsed the workflow with installed Python PyYAML and compared `actions/checkout@v6`, `actions/setup-node@v7`, Node 22, and Chromium setup against `fleet-proxy-e2e.yml`.
- **Verification:** YAML parse and workflow policy checks passed.
- **Committed in:** `c152f4f`

**Total deviations:** 1 validation-environment limitation.
**Impact on plan:** No product or workflow scope changed; equivalent local syntax and established-version checks passed.

## Issues Encountered

- The local Ruby version manager has no Ruby selected, and the repository does not include the CI monitor wrapper. Neither prevented validated workflow creation.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- G-70-1's focused scenario and recurring CI ownership are complete.
- Existing repository dependency advisories remain independently tracked by security CI and are intentionally untouched.

## Self-Check: PASSED

- `scripts/test_keycloak_proxy_e2e.sh` and `.github/workflows/keycloak-proxy-e2e.yml` exist.
- Task commits `7956fbb` and `c152f4f` exist in git history.

---
*Phase: 70-keycloak-behind-the-proxy*
*Completed: 2026-08-26*
