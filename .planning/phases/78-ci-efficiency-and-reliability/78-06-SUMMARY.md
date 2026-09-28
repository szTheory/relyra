---
phase: 78-ci-efficiency-and-reliability
plan: 06
subsystem: ci
tags: [github-actions, playwright, docker-compose, artifact-safety]

# Dependency graph
requires:
  - phase: 78-ci-efficiency-and-reliability
    provides: Deterministic browser workflow ownership, scheduled provider canaries, and verified upload-artifact pin
provides:
  - Bounded fixed-schema Fleet, trace, and sibling canary status receipts with exact-path uploads
  - Owned Compose cleanup and disabled Playwright diagnostic output
  - Failure, setup, cancellation, and sensitive-sentinel contract coverage
affects: [78-07, ci-artifacts, browser-e2e]

# Actuals (#2632)
actuals:
  tokens: 16187
  tasks: 3
  commits: 1

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Emit closed-schema status receipts atomically under runner temp and upload only the exact bounded file.
    - Validate receipt presence, shape, byte bound, outcome consistency, retention, and unique job/matrix/attempt names in workflow-owned guards.
    - Give each browser harness unique Compose projects and tear down only its owned resources.

key-files:
  created: []
  modified:
    - .github/workflows/demo-app-e2e.yml
    - .github/workflows/fleet-proxy-e2e.yml
    - playwright.fleet-proxy.config.mjs
    - scripts/test_fleet_proxy_e2e.sh
    - scripts/test_rulestead_proxy_canary.sh
    - scripts/test_trace_visual_e2e.sh
    - scripts/test_trace_visual_status_contract.sh
    - test/adoption/external_canary_contract_test.exs
    - test/release/fleet_proxy_ci_integrity_test.exs

key-decisions:
  - "Write only allowlisted phase, outcome, failure category, bounded counts, and opaque run ID to uploaded receipts; keep browser output outside the upload path."
  - "Reuse the existing shared development proxy when present and remove only per-run Compose projects and networks created by the harness."
  - "Keep live provider availability outside merge acceptance; exercise canary receipt behavior with deterministic success, failure, and setup fixtures."

patterns-established:
  - "A workflow uploads one exact status receipt only after an always-run guard validates it; a missing or malformed receipt fails the job."
  - "Failure and cancellation traps preserve the original command conclusion while making receipt-writing failure visible."

requirements-completed: [PIPE-04, PIPE-05]

coverage:
  - id: D1
    description: "Fleet browser and Compose runs upload only a bounded receipt; failure cleanup is isolated from developer resources."
    requirement: PIPE-04
    verification:
      - kind: unit
        ref: "mix test test/release/fleet_proxy_ci_integrity_test.exs --warnings-as-errors — 9 tests, 0 failures"
        status: pass
      - kind: e2e
        ref: "GITHUB_ACTIONS=true RUNNER_TEMP=<owned temp> CI=true npm run demo:fleet-proxy — solo and Fleet Chromium checks and full Compose lifecycle passed; receipt validated at <=512 bytes"
        status: pass
      - kind: integration
        ref: "actionlint -shellcheck on Fleet and demo workflows; ShellCheck, bash -n, mix format --check-formatted, and git diff --check"
        status: pass
    human_judgment: false
  - id: D2
    description: "The Rulestead sibling canary emits a bounded receipt on success, failure, and setup errors while remaining scheduled/manual-only."
    requirement: PIPE-05
    verification:
      - kind: unit
        ref: "mix test test/adoption/external_canary_contract_test.exs --warnings-as-errors — 9 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D3
    description: "Trace browser setup, assertion failure, and cancellation have a bounded status contract aligned with the pinned workflow upload action."
    requirement: PIPE-04
    verification:
      - kind: unit
        ref: "bash scripts/test_trace_visual_status_contract.sh — success, failure, setup failure, cancellation, sentinel exclusion, and upload ownership passed"
        status: pass
      - kind: e2e
        ref: "CI=true npm run demo:trace-visual — 1 browser test passed; runner-mode receipt validated"
        status: pass
    human_judgment: false

# Metrics
duration: 43m
completed: 2026-09-28
status: complete
---

# Phase 78 Plan 06: Bounded Browser and Canary Failure Evidence

**Fleet, trace, and sibling canary workflows now upload only short-lived, schema-checked status receipts, with cleanup limited to harness-owned resources.**

## Performance

- **Duration:** About 43 minutes
- **Started:** 2026-09-28T02:09:25Z
- **Completed:** 2026-09-28T02:52:47Z
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments

- Replaced broad browser, Compose, and network diagnostics with closed-schema receipts capped at 512 bytes and uploaded from one exact runner-temp path.
- Added workflow guards for exact keys, receipt owner, run ID, phase, outcome, failure category, bounded counts, and success/failure consistency. Uploads use three-day retention and job/matrix/attempt-specific names.
- Added early setup and cancellation receipts, sensitive-sentinel and unexpected-attachment fixtures, and cleanup using unique Compose project names. The Fleet browser harness passed while preserving the pre-existing `dev_proxy-traefik-1` container.
- Disabled Playwright traces, screenshots, video, and HTML output and remove temporary browser output after each run.

## Task Commits

1. **Task 1: Bound Fleet browser and Compose failure status** — `7a5b284` (`fix(ci)`)
2. **Task 2: Bound sibling proxy canary status without changing its schedule** — `7a5b284` (`fix(ci)`)
3. **Task 3: Align trace visual status action and early-failure contract** — `7a5b284` (`fix(ci)`)

**Plan metadata:** recorded in the state update commit.

## Files Created/Modified

- `.github/workflows/demo-app-e2e.yml` — requires and uploads only a validated trace receipt.
- `.github/workflows/fleet-proxy-e2e.yml` — requires and uploads exact Fleet and canary receipts.
- `playwright.fleet-proxy.config.mjs` — disables browser attachments and directs output to temporary storage.
- `scripts/test_fleet_proxy_e2e.sh` — records bounded status and cleans only owned Compose resources.
- `scripts/test_rulestead_proxy_canary.sh` — removes raw diagnostics and writes bounded status without changing canary scheduling.
- `scripts/test_trace_visual_e2e.sh` — emits receipts on normal completion, setup failure, and cancellation.
- `scripts/test_trace_visual_status_contract.sh` — covers receipt lifecycle and upload pin contract.
- `test/adoption/external_canary_contract_test.exs` — covers canary receipts, sentinels, failure propagation, and ownership.
- `test/release/fleet_proxy_ci_integrity_test.exs` — covers receipt validation, exact artifact selection, cancellation, and owned cleanup.

## Decisions Made

- Kept receipts intentionally small and allowlisted; raw browser and container output cannot enter the artifact selection.
- Reused the shared development proxy when it already existed and verified it remained running after cleanup.
- Kept real external provider checks in their existing scheduled/manual workflow and used deterministic fixtures for local verification.

## Deviations from Plan

None — plan executed within its declared scope.

## Issues Encountered

- The first Git commit hook could not resolve Mix because the untracked `.tool-versions` selects Node only. Retried with the installed Elixir 1.19.5/OTP 28 versions; the format hook passed and the commit completed.
- An initial trace browser invocation encountered a transient local webserver connection refusal. A diagnostic rerun passed and produced a valid bounded receipt; the final trace browser run also passed.

## User Setup Required

None. No live provider credentials were needed.

## Next Plan Readiness

- Plan 78-07 can build the cold-state receipt producer and separate mandatory receipt owner on the now-finalized browser and canary artifact contracts.
- Plan 78-07 must recapture the Phase 73 proof only after its governed source commits are final.

---
*Phase: 78-ci-efficiency-and-reliability*
*Completed: 2026-09-28*
