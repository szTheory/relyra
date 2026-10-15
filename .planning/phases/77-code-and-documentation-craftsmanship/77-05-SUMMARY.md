---
phase: 77-code-and-documentation-craftsmanship
plan: 05
subsystem: documentation-policy
tags: [markdown, docs, exunit, fences]
requires:
  - phase: 77-01
    provides: active incomplete-phase Markdown policy scanner
provides:
  - Markdown-consistent fenced-code removal in the active policy scanner
  - Deterministic regression coverage for closing-fence boundaries
affects: [phase-77-verification, docs-policy]
actuals:
  tokens: 1794
  tasks: 2
  commits: 4
plan_head_before: 33263f42c88223657e22353bd2be2ef6dbb5cb59
tech-stack:
  added: []
  patterns: [line-oriented Markdown fence scan, temporary phase-document fixtures]
key-files:
  created: [.planning/phases/77-code-and-documentation-craftsmanship/77-05-SUMMARY.md]
  modified: [test/docs/demo_guide_drift_test.exs]
key-decisions:
  - "Only homogeneous same-character runs of sufficient length close a Markdown fence."
  - "Quoted fence contents are removed before inline-code and blockquote filtering."
requirements-completed: [QUAL-04]
duration: 9min
completed: 2026-09-27
status: complete
---

# Phase 77 Plan 05: Markdown Fence Policy Summary

**The active documentation policy scanner now follows Markdown fence boundaries and resumes checking directives after a valid close.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-09-27T00:55:31Z
- **Completed:** 2026-09-27T01:04:51Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Replaced exact-run fence stripping with a line-oriented scan that accepts equal or longer homogeneous backtick and tilde closing runs, optional trailing spaces or tabs, and zero-to-three-space indentation.
- Added table-driven checks for shorter, opposite-character, mixed-character, trailing-content, and over-indented non-closing lines, plus an unclosed fence that continues through EOF.
- Kept existing inline-code, blockquote, active-directive, and required-UAT controls in the docs test module and mandatory `mix ci.docs` lane.

## Files Created/Modified

- `test/docs/demo_guide_drift_test.exs` — fence scanner and quoted-versus-active policy regressions.

## Task Commits

1. **Task 1: Recognize a longer Markdown closing fence** — `30f4034` (RED test).
2. **Task 1: Recognize a longer Markdown closing fence** — `f63d465` (GREEN scanner).
3. **Task 2: Lock fence boundaries into the docs lane** — `23146d9` (RED mixed-run regression).
4. **Task 2: Lock fence boundaries into the docs lane** — `afd1941` (GREEN homogeneous-run validation).

**Plan metadata:** included with the summary, state, and roadmap close-out commit.

## Verification

- RED evidence: the longer-fence fixture failed on its target assertion because a quoted `status: human_needed` marker was reported as active prose; it passed after the scanner change.
- RED evidence: the mixed-character boundary fixture failed on its target assertion because a mixed run was accepted as a close; it passed after close-run validation required one repeated fence character.
- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/docs/demo_guide_drift_test.exs --warnings-as-errors` — passed, 35 tests, 0 failures.
- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix ci.docs` — passed, including the 35-test docs module and its companion docs suites.
- `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix format --check-formatted` — passed.

## Decisions Made

- Require every character in a closing run to match the opening fence character; a mixed run cannot close a Markdown fence.
- Strip fenced content before applying the existing inline-code and blockquote filters.

## Deviations from Plan

**1. [Rule 1 - Bug] Rejected mixed-character closing runs**
- **Found during:** Task 2
- **Issue:** The initial close matcher accepted a run made from both backticks and tildes when its first character matched the opener.
- **Fix:** Match a homogeneous run of either backticks or tildes before checking character and length.
- **Files modified:** `test/docs/demo_guide_drift_test.exs`
- **Verification:** The mixed-run assertion failed before the fix and passed in the focused module and `mix ci.docs` afterward.
- **Commit:** `afd1941`
- **Broken-windows ledger:** `.planning/WINDOWS.md` entry 31.

## TDD Evidence

Both tasks recorded target-test RED evidence before their corresponding GREEN commits. The plan-level TDD gate does not apply because this is an `execute` plan with TDD-scoped tasks rather than a `type: tdd` plan.

## Self-Check: PASSED

- The scoped test file exists and all four task commits are present.
- The required focused test, docs lane, and formatting checks passed.
