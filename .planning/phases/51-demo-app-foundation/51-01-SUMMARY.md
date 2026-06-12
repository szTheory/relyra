---
phase: 51-demo-app-foundation
plan: 01
subsystem: demo-app-foundation
tags: [phoenix, ecto, postgres, path-dependency, ledger-loop]

requires: []
provides:
  - Conventional Phoenix app scaffold at demo/ledger_loop
  - Local Relyra path dependency for the demo host app
  - LedgerLoop repo, endpoint, supervision tree, config, tests, and lockfile
affects: [phase-51, demo-app, ledger-loop, phase-52]

tech-stack:
  added: [phoenix, phoenix_ecto, ecto_sql, postgrex, phoenix_live_view, bandit, req]
  patterns:
    - Phoenix host app with Relyra as a local path dependency
    - Generated Ecto repo and endpoint supervised by the host application

key-files:
  created:
    - demo/ledger_loop/mix.exs
    - demo/ledger_loop/mix.lock
    - demo/ledger_loop/config/config.exs
    - demo/ledger_loop/config/dev.exs
    - demo/ledger_loop/config/runtime.exs
    - demo/ledger_loop/config/test.exs
    - demo/ledger_loop/lib/ledger_loop/application.ex
    - demo/ledger_loop/lib/ledger_loop/repo.ex
    - demo/ledger_loop/lib/ledger_loop_web/endpoint.ex
  modified: []

key-decisions:
  - "Used the planned Phoenix generator path with --no-assets and --no-install."
  - "Added req as a host app dependency because Relyra's path dependency compile references Req.Response."

patterns-established:
  - "LedgerLoop is a normal host Phoenix app under demo/ledger_loop, not an umbrella or test fixture."
  - "Relyra is consumed through {:relyra, path: \"../..\"}; no vendoring or published package dependency is used."

requirements-completed: [DEMO-01]

duration: 7 min
completed: 2026-06-12
---

# Phase 51 Plan 01: Scaffold LedgerLoop Phoenix Foundation Summary

**Conventional Phoenix LedgerLoop host app scaffold with local Relyra path dependency and compile-ready repo/endpoint foundation**

## Performance

- **Duration:** 7 min
- **Started:** 2026-06-12T15:41:00Z
- **Completed:** 2026-06-12T15:47:55Z
- **Tasks:** 1
- **Files modified:** 39

## Accomplishments

- Generated a conventional Phoenix app at `demo/ledger_loop` with app `:ledger_loop` and module `LedgerLoop`.
- Added `{:relyra, path: "../.."}` so the demo compiles against the repository-local library.
- Preserved the generated `LedgerLoop.Repo`, `LedgerLoop.Application`, and `LedgerLoopWeb.Endpoint` foundation needed by later route, readiness, UI, and packaging plans.

## Task Commits

Each task was committed atomically:

1. **Task 1: Scaffold LedgerLoop Phoenix foundation** - `c651f8a` (`feat`)

**Plan metadata:** this summary is committed in the follow-up `docs(51-01)` metadata commit.

## Files Created/Modified

- `demo/ledger_loop/mix.exs` - Phoenix app project, generated dependencies, local Relyra path dependency, and required `req` host dependency.
- `demo/ledger_loop/mix.lock` - Locked Phoenix, Ecto, Relyra transitive, and `req` dependency graph.
- `demo/ledger_loop/config/*.exs` - Generated environment config for repo, endpoint, runtime, dev, prod, and test.
- `demo/ledger_loop/lib/ledger_loop/application.ex` - OTP supervision tree for telemetry, repo, DNS cluster, PubSub, and endpoint.
- `demo/ledger_loop/lib/ledger_loop/repo.ex` - Host Ecto repo for later demo storage proof.
- `demo/ledger_loop/lib/ledger_loop_web/endpoint.ex` - Phoenix endpoint plugged to `LedgerLoopWeb.Router`.
- `demo/ledger_loop/lib/ledger_loop_web/**` - Generated router, controllers, components, layouts, telemetry, and starter page files for later Phase 51 plans to replace or extend.
- `demo/ledger_loop/test/**` - Generated ConnCase/DataCase and starter controller tests.

## Decisions Made

- Kept the generator-created Phoenix skeleton instead of hand-rolling the host app, matching the plan's conventional-app requirement.
- Added `req` to the demo app because path dependency compilation of Relyra requires `Req.Response`; downstream optional deps are not pulled automatically by Mix.
- Removed generated Tailwind/daisyUI comment references from `CoreComponents` so the plan's forbidden-stack source assertion is exact.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added `req` as a demo host dependency**
- **Found during:** Task 1 (Scaffold LedgerLoop Phoenix foundation)
- **Issue:** `cd demo/ledger_loop && mix compile --warnings-as-errors` failed while compiling the Relyra path dependency because `Req.Response` was unavailable.
- **Fix:** Added `{:req, "~> 0.5"}` to `demo/ledger_loop/mix.exs`.
- **Files modified:** `demo/ledger_loop/mix.exs`, `demo/ledger_loop/mix.lock`
- **Verification:** `cd demo/ledger_loop && mix deps.get && mix compile --warnings-as-errors`
- **Committed in:** `c651f8a`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Required for the demo host app to compile the repository-local Relyra dependency. No public API, trust-boundary, parser, crypto, audit, or replay behavior changed.

## Issues Encountered

- Relyra path dependency compilation needs `req` present in the host app dependency graph; resolved as a host-app dependency.

## User Setup Required

None - no external service configuration required.

## Verification

- `grep -q 'app: :ledger_loop' demo/ledger_loop/mix.exs`
- `grep -q '{:relyra, path: "../.."}' demo/ledger_loop/mix.exs`
- `! rg -n "tailwind|daisyui|esbuild|shadcn|react|Relyra\\.TestSupport|FakeIdP|Keycloak" demo/ledger_loop/mix.exs demo/ledger_loop/config demo/ledger_loop/lib`
- `grep -q 'LedgerLoop.Repo' demo/ledger_loop/lib/ledger_loop/application.ex`
- `grep -q 'LedgerLoopWeb.Endpoint' demo/ledger_loop/lib/ledger_loop/application.ex`
- `grep -q 'use Ecto.Repo' demo/ledger_loop/lib/ledger_loop/repo.ex`
- `grep -q 'plug LedgerLoopWeb.Router' demo/ledger_loop/lib/ledger_loop_web/endpoint.ex`
- `cd demo/ledger_loop && mix deps.get`
- `cd demo/ledger_loop && mix compile --warnings-as-errors`
- `cd demo/ledger_loop && mix format --check-formatted`

## Self-Check: PASSED

- Key files exist on disk.
- `git log --oneline --all --grep="51-01"` returns the task commit.
- All task acceptance criteria passed.

## Next Phase Readiness

Ready for Plan 51-02 to mount Relyra SAML and LiveAdmin route seams, and Plan 51-06 to prove the package boundary.

---
*Phase: 51-demo-app-foundation*
*Completed: 2026-06-12*
