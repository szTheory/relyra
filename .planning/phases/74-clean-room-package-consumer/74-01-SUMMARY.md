---
phase: 74-clean-room-package-consumer
plan: 01
subsystem: testing
tags: [hex, phoenix, postgres, package-consumer, saml]
requires: []
provides:
  - Clean-room Phoenix consumer built from the unpacked local Hex artifact.
  - Signed ACS success through the real endpoint with an exact consumer-owned receipt.
  - Runtime assertions for artifact provenance, isolated BEAM output and private-support exclusion.
affects: [74-02, 74-03, 74-04]
actuals:
  tokens: 11000
  tasks: 2
  commits: 2
tech-stack:
  added: [Phoenix consumer fixture, isolated Hex/Mix environment, owned PostgreSQL container]
  patterns: [unpacked artifact path dependency, per-run disposable state, host receipt after verified ACS]
key-files:
  created:
    - scripts/check_clean_room_consumer.sh
    - test/fixtures/package_consumer/consumer/mix.exs
    - test/fixtures/package_consumer/consumer/lib/package_consumer.ex
    - test/fixtures/package_consumer/consumer/lib/package_consumer_web/router.ex
    - test/fixtures/package_consumer/consumer/smoke/signed_acs.exs
  modified: []
key-decisions:
  - "Build and unpack the local Hex artifact, then resolve the consumer dependency directly from the unpacked package."
  - "Use the shipped Relyra.Testing fixture and the real Phoenix ACS route; the consumer session callback records only after verified consumption."
  - "Add Req to the full consumer profile because the current package source expands Req.Response structs at compile time; minimal-profile optional-dependency compilation remains for Plan 74-04."
requirements-completed: [PKG-01, PKG-02, PKG-03]
coverage:
  - id: D1
    description: The installed clean-room Phoenix consumer compiles, queries its owned PostgreSQL and accepts a signed ACS response with the expected host receipt and redirect.
    requirement: PKG-03
    verification:
      - kind: integration
        ref: scripts/check_clean_room_consumer.sh --profile full
        status: pass
    human_judgment: false
  - id: D2
    description: The consumer resolves Relyra from the unpacked artifact, loads BEAM output from the isolated build root and cannot load checkout test support.
    requirement: PKG-01
    verification:
      - kind: integration
        ref: scripts/check_clean_room_consumer.sh --profile full
        status: pass
    human_judgment: false
duration: 160 min
completed: 2026-09-24
status: complete
---

# Phase 74 Plan 01: Clean-Room Phoenix Consumer Summary

**A Phoenix app built from the unpacked Hex artifact verifies a signed ACS response and records the expected host session receipt.**

## Performance

- **Duration:** About 160 minutes
- **Started:** 2026-09-24T22:20:00Z
- **Completed:** 2026-09-25T01:00:03Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added a disposable package consumer harness that isolates the app, Mix, Hex, dependencies, build output, PostgreSQL data and command logs under a unique run root.
- Added a Phoenix consumer fixture whose real ACS route accepts the package-shipped signed response and redirects to `/welcome` after recording exactly `%{user_id: "alice@example.com", connection_id: "conn-123"}`.
- Added explicit artifact source, compiled output, private-support and checkout-path assertions with actionable diagnostics.

## Task Commits

Each task was committed atomically:

1. **Task 1: Run one packaged Phoenix ACS success from a fresh consumer** - `bacb2be` (test)
2. **Task 2: Make artifact provenance and checkout isolation executable** - `5471a33` (test)

**Plan metadata:** `c1ad91a` (recorded plan summary)

## Files Created/Modified

- `scripts/check_clean_room_consumer.sh` - Builds/unpacks the package, creates isolated consumer state, starts owned PostgreSQL and runs install, compile and signed ACS checks.
- `test/fixtures/package_consumer/consumer/mix.exs` - Defines the clean-room Phoenix/Ecto consumer dependencies.
- `test/fixtures/package_consumer/consumer/lib/package_consumer.ex` - Defines the consumer application, Repo, Endpoint and host resolver/mapper/session adapters.
- `test/fixtures/package_consumer/consumer/lib/package_consumer_web/router.ex` - Supplies the router target for the public installer.
- `test/fixtures/package_consumer/consumer/smoke/signed_acs.exs` - Checks database access, package provenance, support exclusion, receipt and redirect.

## Decisions Made

- Kept the consumer dependency pointed at the unpacked local Hex artifact and required the package source and compiled code paths to remain isolated.
- Included Req in the full profile because Relyra source currently references `Req.Response` structs during compilation. Plan 74-04 still owns the no-optional-dependency compile contract.

## Deviations from Plan

### Auto-fixed Issues

**1. Full consumer compile requires the optional Req integration dependency**
- **Found during:** Task 1 (packaged Phoenix ACS success)
- **Issue:** Relyra compilation failed because `Relyra.Metadata.Refresh` and `Relyra.Metadata.AutoRefresh` expand `Req.Response` structs, while the planned full consumer dependencies did not include Req.
- **Fix:** Added Req to the full consumer's dependency list; the consumer still resolves Relyra exclusively from the unpacked artifact.
- **Files modified:** `test/fixtures/package_consumer/consumer/mix.exs`
- **Verification:** `scripts/check_clean_room_consumer.sh --profile full` passed with warnings-as-errors compile and signed ACS checks.
- **Committed in:** `bacb2be`

**Total deviations:** 1 auto-fixed dependency mismatch.
**Impact on plan:** The full profile now compiles with the package's current optional integration requirements. The minimal profile remains an explicit open check for Plan 74-04.

## Issues Encountered

- Canonicalized the macOS temporary root because `/var` and `/private/var` refer to the same location but string-prefix checks treated them as different paths.
- Defined the options Plug before the Endpoint module because Phoenix resolves Plug initialization during Endpoint compilation.
- Allowed the resolved Relyra source path to equal the unpacked artifact root, which is where the package `mix.exs` lives.

## User Setup Required

None - the harness manages its temporary PostgreSQL container and package state.

## Next Phase Readiness

Plan 74-02 can add the host-owned runtime-store migration and Ecto adapter smoke to the existing full-profile harness.

---
*Phase: 74-clean-room-package-consumer*
*Completed: 2026-09-24*

## Self-Check: PASSED

- All five declared artifacts exist in the repository.
- Task commits `bacb2be` and `5471a33` are reachable in Git history.
- `scripts/check_clean_room_consumer.sh --profile full` passed after both tasks.
- The consumer provenance, private-support and signed ACS markers passed.
