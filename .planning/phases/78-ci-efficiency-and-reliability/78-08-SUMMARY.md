---
phase: 78-ci-efficiency-and-reliability
plan: 08
subsystem: ci
tags: [github-actions, release-please, actionlint, workflow-hygiene]

requires:
  - phase: 78-ci-efficiency-and-reliability
    provides: Workflow pin contracts and release hardening checks from Plans 78-04 through 78-07
provides:
  - Release Please v5.0.0 pinned to its verified immutable commit
  - Exact workflow contracts and mutation checks for stale, mutable, and mislabeled pins
affects: [phase-78-verification, release-workflow]

actuals:
  tokens: 870
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns: [Exact action SHA and version-label assertions with in-memory drift mutations]

key-files:
  created: [.planning/phases/78-ci-efficiency-and-reliability/78-08-SUMMARY.md]
  modified:
    - .github/workflows/release-please.yml
    - test/adoption/workflow_hygiene_test.exs
    - test/release/release_hardening_test.exs

key-decisions:
  - "Use the official v5.0.0 tag commit 45996ed1f6d02564a971a2fa1b5860e934307cf7 and retain the ubuntu-latest runner for Node 24 compatibility."
  - "Require exact agreement between the workflow SHA, release label, and both local contracts."

patterns-established:
  - "Action pin tests reject old immutable SHAs, mutable references, and mismatched version comments."

requirements-completed: [PIPE-04]
coverage:
  - id: D1
    description: Release Please uses the verified v5.0.0 immutable action and drift is rejected by deterministic contracts.
    requirement: PIPE-04
    verification:
      - kind: unit
        ref: test/adoption/workflow_hygiene_test.exs#action pin comments, mutable references, and unsupported runners fail closed
        status: pass
      - kind: unit
        ref: test/release/release_hardening_test.exs#release CI/CD workflows are wired
        status: pass
      - kind: other
        ref: actionlint -shellcheck /opt/homebrew/bin/shellcheck .github/workflows/release-please.yml
        status: pass
    human_judgment: false

duration: 4min
completed: 2026-09-28
status: complete
---

# Phase 78 Plan 08: Release Please Pin Gap Closure Summary

**Release Please now uses the official v5.0.0 commit with exact workflow and test contracts that reject stale or mutable references.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-09-28T23:25:00Z
- **Completed:** 2026-09-28T23:29:55Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Updated the release workflow to `googleapis/release-please-action@45996ed1f6d02564a971a2fa1b5860e934307cf7 # v5.0.0`.
- Replaced the broad v4-major assertion with the exact verified SHA and v5.0.0 label.
- Added mutations proving the old v4 pin, mutable tag, and mismatched label fail the action-pin contract.
- Confirmed the official v5.0.0 release and `node24` action manifest; retained `ubuntu-latest` and all existing release job wiring.

## Task Commits

1. **Plan: Prepare Release Please pin gap closure** — `f2d853bb3a00575409f26b163b02c8aaf736adbf`
2. **Task 1: Pin Release Please v5.0.0 through the workflow and both contracts** — `304dd4c78626a685ace4ef020ef944d11a2d23cd`
3. **Task 2: Prove stale Release Please pins fail and lint the changed workflow** — `c79785e2328105a7c901ab518cd8d3be143d1290`

## Supporting Commits

- `08351a517496abf0109d47aeb928e5602b2c2cff` revised this plan after the original summary boundary `d11fa36a8d3de45035d17b3c969e5b0b2a40bc4c`; it is a descendant and stays outside the parser-owned Task Commits list.
- `588a8b727ba128d0ee1ccb5cdb8786e4f1c068d4` implements Task 3 after that original boundary.

## Files Created/Modified

- `.github/workflows/release-please.yml` - Updated only the Release Please action pin.
- `test/adoption/workflow_hygiene_test.exs` - Updated the exact expected pin and added three drift rejection fixtures.
- `test/release/release_hardening_test.exs` - Requires the exact action SHA and version label.
- `.planning/phases/78-ci-efficiency-and-reliability/78-08-SUMMARY.md` - Records plan outcomes and verification evidence.

## Decisions Made

- Used the tag’s official immutable v5.0.0 commit `45996ed1f6d02564a971a2fa1b5860e934307cf7`; the official action manifest identifies its runtime as Node 24.
- Kept the existing `ubuntu-latest` hosted runner, action inputs/outputs, scoped permissions, triggers, and publish gate unchanged.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

- The initial commit hook could not select the project Elixir version because the untracked local `.tool-versions` file is not used by that hook. Retried with the plan’s explicit ASDF Elixir 1.19.5 / OTP 28.4.1 settings; formatting passed and the commit succeeded.

## Verification

- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/adoption/workflow_hygiene_test.exs test/release/release_hardening_test.exs --warnings-as-errors` - **11 tests, 0 failures**.
- `actionlint -shellcheck /opt/homebrew/bin/shellcheck .github/workflows/release-please.yml` - **passed**.
- `mix format --check-formatted` and `git diff --check` - **passed**.
- The workflow pin and both local contracts agree on full SHA `45996ed1f6d02564a971a2fa1b5860e934307cf7` and label `v5.0.0`.

## Next Phase Readiness

The sole reported Release Please pin gap is closed with deterministic automated evidence. The orchestrator can refresh the source-bound Phase 78 receipt and rerun final phase verification after its tracking updates.

## Self-Check: PASSED

- Summary file exists.
- Pre-boundary task commits `f2d853bb3a00575409f26b163b02c8aaf736adbf`, `304dd4c78626a685ace4ef020ef944d11a2d23cd`, and `c79785e2328105a7c901ab518cd8d3be143d1290` exist in repository history.
- Scoped diff is clean under `git diff --check`.

## Follow-Up Execution Note

The original execution results above remain historical evidence. After the summary boundary, Task 3 added Phase 78's eighth plan to the governance lifecycle contract and aligned both completed-plan summaries with the Git-derived parser format. The governance suite passes with 82 tests and 0 failures; the focused Release Please suites pass with 11 tests and 0 failures; the Phase 73 reconciliation suite passes with 6 tests and 0 failures; actionlint with ShellCheck, formatting, and diff checks pass. The required Phase 73 proof refresh is `phase73-b0522b1b3ca40f35` with source digest `sha256:3c646362b072c3c5f613858c64fe8ab0f2b550da9a8296ecf4855bd36ba47821`. The earlier cold receipt remains historical and must be regenerated against the final tracked source by the phase orchestrator.

---
*Phase: 78-ci-efficiency-and-reliability*
*Completed: 2026-09-28*
