---
phase: 77-code-and-documentation-craftsmanship
plan: 06
subsystem: testing
tags: [markdown, documentation-policy, exunit]
requires:
  - phase: 77-05
    provides: line-oriented Markdown fence scanner and boundary fixtures
provides:
  - Regression coverage for invalid backtick fence info strings
  - Opener validation that preserves tilde info and existing close behavior
affects: [phase-77-verification, docs-policy]
actuals:
  tokens: 463
  tasks: 2
  commits: 2
plan_head_before: 4c79774915683d281f96c0d4993947a593dbbfef
tech-stack:
  added: []
  patterns: [separate Markdown fence opener and info-string validation]
key-files:
  created: [.planning/phases/77-code-and-documentation-craftsmanship/77-06-SUMMARY.md]
  modified: [test/docs/demo_guide_drift_test.exs]
key-decisions:
  - "Reject backticks in backtick-fence info strings while continuing to allow them in tilde-fence info strings."
requirements-completed: [QUAL-04]
duration: 8min
completed: 2026-09-27
status: complete
---

# Phase 77 Plan 06: Markdown Fence Opener Summary

**The docs policy scanner now leaves active directives visible after malformed backtick openers and accepts backticks in valid tilde info strings.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-09-27T01:28:00Z
- **Completed:** 2026-09-27T01:36:57Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Added a temporary-document regression proving an invalid backtick info string cannot hide a following active policy marker.
- Added a tilde-fence control proving backticks in its info string remain valid and quoted markers stay suppressed.
- Validated the fence run and info string separately while leaving closing-fence handling unchanged.

## Task Commits

1. **Task 1: Reproduce invalid backtick opener suppression** — `3779890` (RED regression).
2. **Task 2: Validate backtick fence info strings** — `0556807` (GREEN opener validation).

## Files Created/Modified

- `test/docs/demo_guide_drift_test.exs` — opener regression, tilde control, and backtick info-string validation.

## Verification

- RED evidence: `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/docs/demo_guide_drift_test.exs --warnings-as-errors` reported the expected malformed-opener assertion failure (`phase_policy_violations/1` returned `[]` instead of the active marker). The tilde control assertion ran first and passed. The same run also exposed the unrelated generated-report failure described below.
- Post-fix regression: `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/docs/demo_guide_drift_test.exs:1109 --warnings-as-errors` — passed, 1 test, 0 failures.
- Focused module: `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/docs/demo_guide_drift_test.exs --warnings-as-errors` — 36 tests, 1 failure; the sole failure is the existing phase-wide policy scan reporting the untracked generated verification report marker below.
- Mandatory docs lane: `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix ci.docs` — failed on the same sole assertion, `test incomplete phases require automated acceptance instead of human UAT` (`test/docs/demo_guide_drift_test.exs:910`, assertion at line 918): `.planning/phases/77-code-and-documentation-craftsmanship/77-VERIFICATION.md contains "status: human_needed"`.
- Formatting: `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix format --check-formatted` — passed after formatting the changed test file.

## Decisions Made

- Backtick openers are rejected when their info string contains a backtick; tilde openers continue to accept backticks in the info string.
- Closing-fence parsing and active-policy selection remain unchanged.

## Deviations from Plan

None in implementation scope. The full focused module and mandatory docs lane were run, but their only failure is caused by the pre-existing, untracked `77-VERIFICATION.md` artifact. That artifact was left untouched; its interaction with the repository-wide scan is being handled separately.

## Issues Encountered

- The local `mix ci.docs` lane is blocked by the generated verification report marker recorded above. The CR-01 regression itself passes, and formatting passes.

## Next Phase Readiness

CR-01 has deterministic regression evidence in the existing docs test owner. Resolve the separate generated-report interaction before treating the full local docs lane as green.

---
*Phase: 77-code-and-documentation-craftsmanship*
*Completed: 2026-09-27*

## Self-Check: PASSED

- The summary file exists.
- Task commits `3779890` and `0556807` are present.
- The persisted plan base records `4c79774915683d281f96c0d4993947a593dbbfef`; `git rev-list` measured 2 task commits from that base before the separate metadata commit.
