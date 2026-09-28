---
phase: 78-ci-efficiency-and-reliability
plan: 05
subsystem: ci
tags: [github-actions, browser-e2e, canary, action-pinning]

# Dependency graph
requires:
  - phase: 78-ci-efficiency-and-reliability
    provides: Workflow hygiene contracts, read-only token defaults, and event-qualified concurrency patterns
provides:
  - Required fake IdP, trace, Fleet, and owned Keycloak browser workflow ownership with parsed contract coverage
  - Separate scheduled/manual real-provider canary workflow with preserved secrets and job identity
  - Immutable action pins and synchronized trace artifact producer contract
affects: [78-06, 78-07]

# Actuals (#2632)
actuals:
  tokens: 9248
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Parse workflow YAML and evaluate event, job, permission, concurrency, and action-pin contracts with positive and mutation fixtures.
    - Keep owned browser journeys blocking while external provider health remains an isolated scheduled or manual canary.

key-files:
  created: []
  modified:
    - .github/workflows/demo-app-e2e.yml
    - .github/workflows/fleet-proxy-e2e.yml
    - .github/workflows/keycloak-proxy-e2e.yml
    - .github/workflows/real-idp-canary.yml
    - test/release/fleet_proxy_ci_integrity_test.exs
    - test/adoption/external_canary_contract_test.exs
    - scripts/test_trace_visual_status_contract.sh

key-decisions:
  - "Keep the real-provider canary schedule/manual-only and preserve the owned deterministic browser jobs as merge evidence."
  - "Pin workflow actions to verified release SHAs and synchronize the existing trace artifact contract with the upload-action pin."
  - "Use workflow and event identity in concurrency groups and cancel only superseded pull-request runs."

patterns-established:
  - "Contract tests parse workflow YAML and evaluate event and concurrency fixtures instead of relying on descriptive text searches."
  - "Action-pin tests require the exact SHA, release comment, count, and approved repository."

requirements-completed: [PIPE-04, PIPE-05]

coverage:
  - id: D1
    description: "Fake IdP, trace, Fleet, and owned Keycloak browser workflows remain deterministic blocking evidence with scoped permissions, isolated scheduling, verified pins, and mutation-tested ownership contracts."
    requirement: PIPE-04
    verification:
      - kind: unit
        ref: "test/release/fleet_proxy_ci_integrity_test.exs — 6 tests, 0 failures; test/adoption/external_canary_contract_test.exs — 7 tests, 0 failures"
        status: pass
      - kind: e2e
        ref: "npm run demo:fake-idp (2 passed); demo:trace-visual (1 passed); demo:fleet-proxy (owned lifecycle and browser checks passed); demo:keycloak-proxy (1 passed)"
        status: pass
      - kind: integration
        ref: "actionlint on all four edited workflows; both ExUnit invocations, mix format --check-formatted, and git diff --check exited 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "Real-provider checks remain an isolated scheduled/manual canary, with parsed contracts rejecting canary ownership of required acceptance or pull-request/main triggers."
    requirement: PIPE-05
    verification:
      - kind: unit
        ref: "test/adoption/external_canary_contract_test.exs — trigger, job, permission, concurrency, pin, and negative-fixture assertions; 7 tests, 0 failures"
        status: pass
    human_judgment: false

# Metrics
duration: 26m
completed: 2026-09-28
status: complete
---

# Phase 78 Plan 05: Browser Gate and Provider Canary Ownership

**Required browser journeys now have parsed ownership and scheduling contracts, while real-provider availability stays isolated in a scheduled/manual canary.**

## Performance

- **Duration:** About 26 minutes
- **Started:** 2026-09-28T01:40:29Z
- **Completed:** 2026-09-28T02:06:43Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Preserved the existing required fake IdP, trace, Fleet, and owned Keycloak checks and their stable workflow/job identities; added read-only permissions, workflow/event-qualified concurrency, and verified immutable action pins.
- Kept the external real-provider workflow schedule/manual-only and added parsed workflow contracts for triggers, commands, required job behavior, secrets, concurrency collision cases, and pins.
- Repaired literal-backtick ShellCheck findings in demo and canary summaries without changing their output, and synchronized the trace status contract with the pinned upload action.

## Task Commits

1. **Task 1: Preserve deterministic demo and Fleet browser gates** — `a386764` (`ci(workflows)`)
2. **Task 2: Separate owned Keycloak proof from real-provider canaries** — `a386764` (`ci(workflows)`)

Supporting trace upload contract synchronization: `6552ff3` (`test(ci)`).

## Files Created/Modified

- `.github/workflows/demo-app-e2e.yml` — secured and pinned the deterministic fake IdP and trace browser gates; preserved summary output.
- `.github/workflows/fleet-proxy-e2e.yml` — isolated required Fleet workflow runs and pinned its actions.
- `.github/workflows/keycloak-proxy-e2e.yml` — retained the owned Keycloak browser journey as required deterministic evidence.
- `.github/workflows/real-idp-canary.yml` — retained scheduled/manual provider checks outside PR and main acceptance.
- `test/release/fleet_proxy_ci_integrity_test.exs` — validates workflow structure, blocking ownership, event fixtures, concurrency isolation, and action pins.
- `test/adoption/external_canary_contract_test.exs` — validates browser/canary separation, protected trigger/job contracts, pins, and negative fixtures.
- `scripts/test_trace_visual_status_contract.sh` — checks the pinned upload action and escaped summary literals while exercising success and failure receipts.

## Decisions Made

- Kept owned browser and container harnesses as the deterministic merge evidence; no live external provider credentials were needed for this plan.
- Used immutable official action release SHAs and kept the trace status assertion synchronized with the upload-artifact action.
- Left branch protection and remote GitHub configuration untouched.

## Deviations from Plan

### Supporting contract update

The workflow’s existing trace status harness still asserted the old upload-artifact v4 literal after the planned action pin update. Updated that exact assertion and its escaped summary literals so the producer contract remains executable. This supporting edit touched a file that Plan 78-06 will extend, without taking over its bounded artifact work.

**Total deviations:** 1 supporting contract synchronization.
**Impact on plan:** Required for the new pin to pass the existing workflow-owned contract; no scope expansion.

## Issues Encountered

- Chromium could not start inside the filesystem sandbox because the browser could not access the macOS Mach service. Re-ran the four locally owned browser harnesses with the required host access; all passed. The Fleet harness preserved the pre-existing shared Traefik container and cleaned up its own stack.

## User Setup Required

None. Real-provider credentials are used only by the existing scheduled/manual canary and were not required for deterministic local evidence.

## Next Plan Readiness

- Plan 78-06 can extend the workflow-owned status contract to bounded failure artifacts; its scheduled canary and trace producer changes can build on the workflow ownership and pin contracts recorded here.
- Global PIPE-04 readiness remains co-owned by later Phase 78 plans and should be evaluated after those plans complete.

---
*Phase: 78-ci-efficiency-and-reliability*
*Completed: 2026-09-28*
