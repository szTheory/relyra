---
phase: 74-clean-room-package-consumer
plan: 04
subsystem: packaging
tags: [hex, optional-dependencies, ci, package-consumer]
requires: [74-01, 74-02, 74-03]
provides:
  - No-optional-dependency compilation and concurrent isolation proof for the unpacked artifact.
  - One mandatory OTP matrix owner for full, minimal and installer-contract consumer profiles.
  - Compile-time guards for optional Phoenix, Ecto and Req integrations.
affects: []
requirements-completed: [PKG-01, PKG-02, PKG-03, PKG-04, PKG-05, PKG-06]
actuals:
  tasks: 2
  commits: 1
tech-stack:
  added: [no-optional dependency consumer profile, isolated concurrency receipts]
  patterns: [compile-time optional integration guards, workflow contract ownership]
key-files:
  created:
    - test/adoption/package_consumer_ci_contract_test.exs
  modified:
    - .github/workflows/security-gates.yml
    - scripts/check_clean_room_consumer.sh
    - test/fixtures/package_consumer/consumer/mix.exs
    - test/governance/milestone_scope_test.exs
    - test/support/phase_73_reconciliation.ex
    - lib/relyra/ecto/audit_writer.ex
    - lib/relyra/phoenix/controllers/acs_controller.ex
    - lib/relyra/testing/phoenix.ex
    - .planning/phases/73-twin-contract-and-baseline/73-RECONCILIATION-PROOF.json
key-decisions:
  - "Guard optional integration modules at compile time so the package builds without Phoenix, Ecto, Postgrex or Req installed."
  - "Use one blocking security workflow step to run the full, minimal-concurrency and contract profiles on both OTP tuples."
  - "Keep Phase 73 proof history and append a fresh proof after changes to its governed workflow and lifecycle owners."
coverage:
  - id: D1
    description: The unpacked artifact compiles without optional dependencies and each of two concurrent consumers keeps disjoint mutable paths.
    requirement: PKG-05
    verification:
      - kind: integration
        ref: scripts/check_clean_room_consumer.sh --profile minimal --concurrency-check
        status: pass
    human_judgment: false
  - id: D2
    description: One unconditional security workflow owner runs the three consumer profiles on the configured OTP matrix.
    requirement: PKG-01
    verification:
      - kind: unit
        ref: test/adoption/package_consumer_ci_contract_test.exs
        status: pass
      - kind: other
        ref: actionlint .github/workflows/security-gates.yml
        status: pass
    human_judgment: false
  - id: D3
    description: Full package, migration, signed ACS, omission, golden installer and prior scaffold contracts pass.
    requirement: PKG-01, PKG-02, PKG-03, PKG-04, PKG-06
    verification:
      - kind: integration
        ref: scripts/check_clean_room_consumer.sh --profile full
        status: pass
      - kind: integration
        ref: scripts/check_clean_room_consumer.sh --profile contracts
        status: pass
    human_judgment: false
completed: 2026-09-25
status: complete
duration: 75 min
---

# Phase 74 Plan 04: Minimal Consumer and CI Gate Summary

The locally unpacked package now compiles without optional dependencies, and two concurrent minimal consumers prove their artifacts, Mix/Hex homes, dependencies, build outputs and receipts are isolated. A required security workflow step runs the full, minimal and contracts profiles on OTP 27 and OTP 28.

## Performance

- **Duration:** About 75 minutes
- **Started:** 2026-09-25T01:41:38Z
- **Completed:** 2026-09-25T02:56:00Z
- **Tasks:** 2
- **Files changed:** 35

## Accomplishments

- Added the minimal profile with `--no-optional-deps --warnings-as-errors`, package/build provenance checks, public testing-helper availability, and absence checks for optional Phoenix, Ecto, Postgrex, Req and private test-support modules.
- Added two simultaneous minimal consumers with pairwise-disjoint run roots and mutable paths; both passed with independent artifact receipts.
- Added one unconditional blocking package-consumer step to the security workflow and a structural ExUnit owner for its triggers, OTP matrix, commands and failure behavior.
- Made optional integrations compile-time conditional, which allows the clean-room package to compile when those optional libraries are absent.
- Refreshed Phase 73 reconciliation evidence after the workflow and lifecycle-governance changes; current proof set is `phase73-97ec1aec53d80f53`.

## Task Commits

1. **Tasks 1–2: Gate isolated package-consumer profiles** — `5e9782d`

## Verification

- `scripts/check_clean_room_consumer.sh --profile full` — passed signed ACS, artifact provenance, both migration owners, persistent stores, concurrency and migration rerun checks.
- `scripts/check_clean_room_consumer.sh --profile minimal --concurrency-check` — passed no-optional compilation and pairwise isolation for two consumers.
- `scripts/check_clean_room_consumer.sh --profile contracts` — passed omission, fresh installer golden, prior scaffold preservation, signed ACS and explicit force cases.
- `mix test test/adoption/package_consumer_ci_contract_test.exs --warnings-as-errors` — 1 test, 0 failures.
- `actionlint .github/workflows/security-gates.yml` — passed.
- `mix ci.evidence` — 127 tests, 0 failures.
- `mix ci.phase73.reconciliation` — 1 test, 0 failures; focused owners, three evidence captures and the pinned security lane replayed.
- `mix qa` — 927 tests, 0 failures (10 excluded); format and warnings-as-errors compilation passed.
- `git diff --check` — passed.

## Deviations

- Minimal compilation showed that optional Phoenix/Ecto/Req integration modules were defined unconditionally, so the compiler still required absent libraries. Added compile-time guards around the optional modules while leaving authentication, signature verification, algorithm policy and trust behavior unchanged.
- Phase 73 governance checks assumed the roadmap’s first phase was current and assumed Phase 74 remained in planning. Updated the active-phase check and fixture lifecycle so Phase 74 execution is recognized structurally. The Phase 73 proof/report refresh is tied to those source updates.
- Updated the Phase 74 plan metadata and command ownership to meet the repository’s executable governance contract. Removed the Phase 74 validation document’s empty manual-only section; all new acceptance checks remain automated.
- Plan 74-03’s interim PKG-02 and PKG-04 checkmarks were reverted while the phase remained open; that temporary transition is recorded in its summary. All six PKG requirements are now complete together.

## Issues Encountered

- The pre-commit format hook initially could not resolve `mix` because the user-owned `.tool-versions` does not select Elixir. Retried with the repository’s installed Elixir 1.19.5/OTP 28.4.1 toolchain; the hook passed.
- `mix qa` retains the previously inventoried fixture test-load-filter warning, but exits zero.

## Self-Check: PASSED

- Full, minimal-concurrency and contracts consumer profiles passed.
- The workflow owner and actionlint checks passed.
- The full QA and Phase 73 reconciliation lanes passed.
- All six phase requirements are ready for completion.
