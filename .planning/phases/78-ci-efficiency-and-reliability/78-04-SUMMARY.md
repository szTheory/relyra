---
phase: 78-ci-efficiency-and-reliability
plan: 04
subsystem: ci
tags: [github-actions, yaml, concurrency, permissions, action-pinning]

# Dependency graph
requires:
  - phase: 78-ci-efficiency-and-reliability
    provides: Measured CI topology and independent docs, verification, and security test gates
provides:
  - Explicit least-privilege permissions and event-qualified concurrency for root, demo, adoption, planning, and release workflows
  - YAML-structure contracts for workflow identities, permissions, runners, cancellation isolation, blocking steps, and action pins
  - Rechecked immutable official action pins for the scoped workflows
affects: [78-05, 78-06, 78-07]

# Actuals (#2632)
actuals:
  tokens: 6321
  tasks: 3
  commits: 1

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Parse workflow YAML and evaluate supported GitHub concurrency expressions against PR, main, dispatch, and workflow-run fixtures.
    - Pair immutable action commit pins with version comments and exact literal contract expectations.

key-files:
  created:
    - test/adoption/workflow_hygiene_test.exs
  modified:
    - .github/workflows/security-gates.yml
    - .github/workflows/demo-app-ci.yml
    - .github/workflows/adoption-external-idp.yml
    - .github/workflows/planning-pr-checks.yml
    - .github/workflows/release-please-pr-checks.yml
    - .github/workflows/release-please.yml

key-decisions:
  - "Use a read-only workflow-level token default and grant write scopes only to the planning, dispatch, and release jobs that need them."
  - "Use workflow and event identity plus PR number or run ID for concurrency groups; only pull_request runs cancel prior runs."
  - "Pin only applicable actions in the scoped workflows; planning and release PR dispatch workflows have no third-party uses lines to pin."

patterns-established:
  - "Workflow contracts parse YAML structure and evaluate scheduling expressions instead of searching for descriptive text."
  - "Action contracts require the exact verified full SHA, matching release label, expected count, and a supported hosted runner."

requirements-completed: [PIPE-04]

coverage:
  - id: D1
    description: "Root, demo, adoption, planning, and release workflows preserve their names and blocking checks while enforcing narrow permissions, isolated concurrency, supported runners, and verified immutable action pins."
    requirement: PIPE-04
    verification:
      - kind: unit
        ref: "test/adoption/workflow_hygiene_test.exs — independently run for Tasks 1, 2, and 3; each run: 7 tests, 0 failures"
        status: pass
      - kind: integration
        ref: "actionlint on the six edited workflow files — exit 0"
        status: pass
      - kind: other
        ref: "mix format --check-formatted and git diff --check — both exit 0"
        status: pass
    human_judgment: false

# Metrics
duration: 15m
completed: 2026-09-28
status: complete
---

# Phase 78 Plan 04: Scoped Workflow Permissions and Scheduling

**Root and release workflows now use explicit least-privilege permissions, collision-isolated concurrency, and verified immutable action pins guarded by parsed YAML contracts.**

## Performance

- **Duration:** About 15 minutes
- **Completed:** 2026-09-28T01:37:02Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments

- Added explicit `contents: read` defaults and workflow/event-qualified cancellation groups to root, demo, adoption, planning, and release workflows; scoped write permissions to the specific jobs that create release state or dispatch checks.
- Added a parsed YAML contract for stable workflow and job names, least-privilege permissions, runner support, PR/main/cross-workflow isolation, and the required blocking Evidence, package-consumer, security, GATE-02, and external IdP steps.
- Rechecked current official action releases and pinned applicable checkout, setup-node, setup-beam, cache, and Release Please actions to full SHAs with version comments. No upload-artifact action is used in these scoped workflows.

## Task Commits

1. **Tasks 1–3: Scope workflow permissions, concurrency, names, and verified action pins** — `cde76f2` (`ci(workflows)`)

**Plan metadata:** pending state update commit.

## Files Created/Modified

- `.github/workflows/security-gates.yml` — read-only default, isolated cancellation, pinned checkout, BEAM, and Node actions.
- `.github/workflows/demo-app-ci.yml` — read-only default, isolated cancellation, pinned checkout and BEAM actions.
- `.github/workflows/adoption-external-idp.yml` — explicit read-only access, isolated scheduling, pinned checkout and BEAM actions.
- `.github/workflows/planning-pr-checks.yml` — moved write scopes to its dispatch job and isolated workflow runs.
- `.github/workflows/release-please-pr-checks.yml` — scoped `actions: write` to the dispatch job and isolated runs.
- `.github/workflows/release-please.yml` — scoped release writes to the release job, kept publish read-only, and pinned its actions.
- `test/adoption/workflow_hygiene_test.exs` — parses workflow YAML, evaluates group expressions, checks stable blocking ownership and permissions, and rejects mutable or mismatched action pins.

## Decisions Made

- Applied a single shared concurrency expression across these workflows. PR updates share only the same workflow and PR group; pushes and other events use unique run IDs.
- Kept the global token default read-only and put each required write scope on only the existing job that consumes it.
- Left planning and release PR-check workflows without action pins because those workflows contain no third-party action references.

## Deviations from Plan

None. The release workflow's `googleapis/release-please-action` pin was also refreshed as part of checking all applicable official actions.

## Issues Encountered

- The first formatter check identified one wrapped tuple in the new test file. Ran `mix format`, then the formatter, focused test, actionlint, and diff checks all passed.

## User Setup Required

None.

## Next Plan Readiness

Plan 78-05 can proceed. It owns the browser and canary workflows, separate from this plan's root and release workflow scope.

---
*Phase: 78-ci-efficiency-and-reliability*
*Completed: 2026-09-28*

## Governance Provenance Reconciliation

The original implementation is preserved in `cde76f2` (`ci(workflows)`). This follow-up records the completed plan under its plan-scoped history identity so the Phase 73 governance replay can verify the exact implementation boundary.
