---
phase: 64-public-testing-api-package-boundary
plan: 03
subsystem: testing
tags: [elixir, phoenix, optional-dependency, public-api, package-boundary]

requires:
  - phase: 64-public-testing-api-package-boundary
    provides: Public Phoenix-free Relyra.Testing fixture core from Plan 64-01
provides:
  - Optional Relyra.Testing.Phoenix.post_response/5 ACS dispatch helper
  - Real Phoenix ACS route proof for public signed success fixtures
  - Scoped external no-Phoenix compile/load proof for core public testing modules
  - Source-token guard keeping Phoenix.ConnTest isolated to the optional layer
affects: [phase-64-package-parity, phase-65-documentation-truth, public-testing-api]

tech-stack:
  added: []
  patterns:
    - Optional Phoenix wrapper over Phoenix-free fixture params
    - External elixir subprocess compile/load proof with filtered dependency ebins
    - Source-token guard for optional dependency isolation

key-files:
  created:
    - lib/relyra/testing/phoenix.ex
    - test/relyra/testing_phoenix_test.exs
    - test/relyra/testing_optional_dependency_test.exs
  modified:
    - lib/relyra/testing.ex

key-decisions:
  - "Relyra.Testing.Phoenix is the only public testing layer that references Phoenix.ConnTest."
  - "The Phoenix helper dispatches fixture POST params through the caller-supplied endpoint/path and leaves consume_response/session handling to ACSController."
  - "Core public testing modules are guarded by an external Phoenix-absent compile/load subprocess, not source scanning alone."

patterns-established:
  - "Phoenix convenience helpers are thin wrappers over Relyra.Testing.post_params/2."
  - "Optional dependency tests copy the scoped core source set into a temp dir and compile it with Phoenix ebins filtered out."

requirements-completed: [TEST-04, TEST-05]

duration: 5min
completed: 2026-06-16
---

# Phase 64 Plan 03: Optional Phoenix Helper and Core Dependency Isolation Summary

**Optional Phoenix ACS fixture dispatch with a scoped no-Phoenix compile/load gate for core public testing helpers.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-06-16T02:38:12Z
- **Completed:** 2026-06-16T02:43:05Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Added `Relyra.Testing.Phoenix.post_response/5` as an isolated optional wrapper around `Relyra.Testing.post_params/2` and `Phoenix.ConnTest.dispatch/5`.
- Added a Phoenix router/ACS test proving a public `Relyra.Testing.signed_success/1` fixture posts through `saml_routes()` and reaches `Relyra.Phoenix.Controllers.ACSController.create/2`.
- Added `test/relyra/testing_optional_dependency_test.exs`, which runs a fresh external `elixir` subprocess with Phoenix ebins filtered out and proves the core public testing modules compile/load without Phoenix.
- Added source guards proving core public testing files contain no Phoenix or `Plug.Conn` references and that `Phoenix.ConnTest` appears only in `lib/relyra/testing/phoenix.ex`.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Phoenix ACS helper proof** - `596317c` (test)
2. **Task 1 GREEN: optional Phoenix dispatch helper** - `3e48cb2` (feat)
3. **Task 2 RED: core optional dependency guard** - `16da0b3` (test)
4. **Task 2 GREEN: remove Phoenix token from core testing docs** - `552b81b` (fix)

_Note: Task commits interleaved with concurrent Plan 64-02 commits in git history; each 64-03 commit staged only its own files._

## Files Created/Modified

- `lib/relyra/testing/phoenix.ex` - Optional Phoenix helper that checks for `Phoenix.ConnTest`, builds public fixture POST params, and dispatches to the caller's endpoint/path.
- `test/relyra/testing_phoenix_test.exs` - Real ACS route proof using a router that imports `Relyra.Phoenix.Router` and calls `saml_routes()`.
- `test/relyra/testing_optional_dependency_test.exs` - External Phoenix-absent compile/load proof and source-token isolation checks.
- `lib/relyra/testing.ex` - Moduledoc wording changed from a framework name to "framework-neutral" so core testing source carries no Phoenix token.

## Decisions Made

- Kept the Phoenix convenience as dispatch-only: it does not call `Relyra.consume_response/3`, assign a user, establish a session, or mutate Application env.
- Used the ACS controller test's router pattern instead of a direct controller call, so the helper proves real routing and controller dispatch.
- Included `Relyra.Telemetry` in the subprocess compile set because `Relyra.ReplayStore` references it; Phoenix dependency paths remain filtered out.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Removed Phoenix token from core testing docs**
- **Found during:** Task 2 (Guard Phoenix-free core testing modules)
- **Issue:** The planned source guard requires the four core public testing files to contain no `Phoenix` references. `lib/relyra/testing.ex` used "Phoenix-free" in moduledoc text, which would make the guard fail despite no runtime dependency.
- **Fix:** Reworded the core moduledoc to "framework-neutral" without changing behavior.
- **Files modified:** `lib/relyra/testing.ex`
- **Verification:** `mix test test/relyra/testing_optional_dependency_test.exs --warnings-as-errors`; core source `rg` for Phoenix/Plug tokens returned no matches.
- **Committed in:** `552b81b`

---

**Total deviations:** 1 auto-fixed (1 missing critical)
**Impact on plan:** The adjustment was required for TEST-05's no-Phoenix source guard and did not change public behavior or security posture.

## Issues Encountered

- The first draft of the optional-dependency RED test used relative dependency ebin paths after `cd: tmp` and compiled C14N before the Saxy node struct. This was corrected before the RED commit so the committed failing test failed only on the intended core Phoenix-token guard.
- Concurrent Plan 64-02 commits appeared in history while this plan was executing. No unrelated 64-02 files were staged by this plan.

## Verification

- `mix test test/relyra/testing_phoenix_test.exs --warnings-as-errors` - PASS, 1 test, 0 failures.
- `mix test test/relyra/testing_optional_dependency_test.exs --warnings-as-errors` - PASS, 3 tests, 0 failures.
- `mix test test/relyra/testing_phoenix_test.exs test/relyra/testing_optional_dependency_test.exs --warnings-as-errors` - PASS, 4 tests, 0 failures.
- `rg -n "Relyra\\.Testing\\.post_params|Phoenix\\.ConnTest" lib/relyra/testing/phoenix.ex` - PASS, required dispatch tokens present.
- `rg -n "Relyra\\.TestSupport|Plug\\.Conn\\.assign|establish_session|Relyra\\.consume_response" lib/relyra/testing/phoenix.ex || true` - PASS, no forbidden bypass/session tokens.
- `rg -n "Phoenix|Phoenix\\.ConnTest|Plug\\.Conn|use Phoenix|import Phoenix|alias Phoenix" lib/relyra/testing.ex lib/relyra/testing/fixture.ex lib/relyra/testing/signer.ex lib/relyra/testing/adapters.ex || true` - PASS, no core matches.
- `rg -n "Phoenix\\.ConnTest" lib/relyra/testing*.ex lib/relyra/testing/*.ex` - PASS, matches only `lib/relyra/testing/phoenix.ex`.

## Known Stubs

None.

## Threat Flags

None - the new Phoenix dispatch and optional-dependency trust boundaries were already covered by the plan threat model.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 64-04 can verify package parity knowing `lib/relyra/testing/phoenix.ex` is the only optional Phoenix file and core `Relyra.Testing` modules compile/load without Phoenix.

## Self-Check: PASSED

- Created files exist: `lib/relyra/testing/phoenix.ex`, `test/relyra/testing_phoenix_test.exs`, `test/relyra/testing_optional_dependency_test.exs`.
- Modified file exists: `lib/relyra/testing.ex`.
- Task commits exist: `596317c`, `3e48cb2`, `16da0b3`, `552b81b`.
- No accidental file deletions were detected in task commits.
- Stub scan found no placeholder/TODO/FIXME or hardcoded empty UI data patterns in plan-created/modified files.

---
*Phase: 64-public-testing-api-package-boundary*
*Completed: 2026-06-16*
