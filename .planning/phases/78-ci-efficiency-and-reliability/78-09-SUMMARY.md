---
phase: 78-ci-efficiency-and-reliability
plan: 09
subsystem: testing
tags: [ci, governance, otp27, otp28, phase73, clean-state]
requires:
  - phase: 78
    provides: CI ownership, cold-state producer, and mandatory receipt owner from Plans 78-01 through 78-08
provides:
  - Phase 79 planning lifecycle coverage under Phase 78 governance
  - Refreshed Phase 73 reconciliation proof and matching append-only report blocks
  - Source-bound OTP 27 and OTP 28 cold receipts with 22 passing commands each
affects: [phase-79, phase-73-reconciliation, ci-clean-state, governance]
actuals:
  tokens: 26112
  tasks: 3
  commits: 17
plan_head_before: 14143152bedf68dce677f89776e59547dab5dd76
tech-stack:
  added: []
  patterns:
    - Bounded source digest exclusions for generated report artifacts
    - Serial isolated cold matrices with matching source and proof identities
key-files:
  created:
    - .planning/phases/78-ci-efficiency-and-reliability/78-09-SUMMARY.md
  modified:
    - test/governance/milestone_scope_test.exs
    - .planning/phases/73-twin-contract-and-baseline/73-RECONCILIATION-PROOF.json
    - .planning/phases/73-twin-contract-and-baseline/73-SECURITY.md
    - .planning/phases/73-twin-contract-and-baseline/73-VALIDATION.md
    - scripts/check_phase78_clean_state.sh
    - scripts/test_trace_visual_status_contract.sh
    - test/adoption/phase78_clean_state_contract_test.exs
    - .planning/phases/78-ci-efficiency-and-reliability/78-CLEAN-STATE-RECEIPT.json
    - .planning/phases/78-ci-efficiency-and-reliability/78-VERIFICATION.md
key-decisions:
  - "Accept Phase 79 planning as governance Phase 78 while retaining ordered-transition and risk-metadata rejection checks."
  - "Exclude generated verification reports only under .planning/phases/ from the operational digest; same-suffix files elsewhere remain covered."
  - "Run the OTP 27 and OTP 28 cold matrices serially against one frozen committed source and Phase 73 proof."
patterns-established:
  - "A generated report may be finalized after cold evidence only when its path is bounded out of the operational digest and mutation-tested."
  - "Cold receipts bind both toolchains to identical source commit, digest, file count, and proof identity."
requirements-completed: [PIPE-05]
coverage:
  - id: D1
    description: Phase 79 planning resolves to Phase 78 governance and validates all nine Phase 78 plans.
    requirement: PIPE-05
    verification:
      - kind: unit
        ref: test/governance/milestone_scope_test.exs (83 tests)
        status: pass
    human_judgment: false
  - id: D2
    description: The current Phase 73 proof is generated through the reconciliation API and replays with matching report blocks.
    requirement: PIPE-05
    verification:
      - kind: integration
        ref: mix ci.phase73.reconciliation
        status: pass
    human_judgment: false
  - id: D3
    description: The receipt records both full cold matrices against the same source and passes its mandatory repository owner.
    requirement: PIPE-05
    verification:
      - kind: integration
        ref: scripts/check_phase78_clean_state.sh --otp 27 and --otp 28 (22 commands each)
        status: pass
      - kind: integration
        ref: mix ci.phase78.receipt
        status: pass
    human_judgment: false
metrics:
  duration: "16h53m+ (lower bound from first task commit; initial start time was not captured)"
  completed: 2026-09-29
status: complete
---

# Phase 78 Plan 09: Phase 79 Lifecycle and Clean-State Receipt Summary

**Phase 79 governance coverage, the Phase 73 proof, and both source-bound OTP cold matrices pass against the final post-completion source `7bc19dc`.**

## Performance

- **Duration:** At least 16 hours 53 minutes from the first task commit; initial execution start time was not captured.
- **Started:** 2026-09-28T22:39:38-04:00 (first committed task; execution began earlier).
- **Completed:** 2026-09-29T15:33:11-04:00 (post-phase.complete OTP 27/28 matrices and receipt owner passed).
- **Tasks:** 3
- **Files modified:** 9 plan-scoped source and evidence files, plus this summary.

## Accomplishments

- Extended the governance lifecycle contract to accept Phase 79 planning through Phase 78, require all nine tracked Phase 78 plans, and retain Phase 73 semantics and malformed or skipped-transition rejection coverage. The focused governance module passed 83 tests.
- Captured Phase 73 proof `phase73-098ef9c4fb32ec31` from the governed source, appended identical proof blocks to both reports, and passed `mix ci.phase73.reconciliation`.
- Bounded the source-digest exclusion to generated `*-VERIFICATION.md` paths under `.planning/phases/`. The contract proves a phase report mutation leaves both digest and file count unchanged while a same-suffix path outside that directory changes the digest.
- Fixed the trace cancellation contract after command 21 exposed a PID publication race and the cold macOS runner revealed that Bash 3.2 does not define `BASHPID`. The marker now publishes atomically, the consumer waits for a numeric PID, and the fake `npx` uses portable `$$`.
- Ran the full 22-command cold manifest on OTP 27 and OTP 28, serially, against the post-phase.complete source commit `7bc19dcf01c94771e165c1ccf6feff7b7e69f0d8`. Each run passed all commands, including 18 positive-evidence commands, across 1,108 tracked operational files.
- Assembled and committed the final replacement receipt as `ee86790`; `mix ci.phase78.receipt` passed against the actual tracked receipt (1 test, 0 failures).

## Source and Proof Identity

- **Matrix source commit:** `7bc19dcf01c94771e165c1ccf6feff7b7e69f0d8`
- **Operational source digest:** `7d747d5a2b90dbb53cb41acb33c5ca0b1a5dfdd48127bfbfa7e4b9221031df5e`
- **Tracked operational files:** 1,108
- **Phase 73 proof ID:** `phase73-098ef9c4fb32ec31`
- **Phase 73 source digest:** `sha256:c95aa360c9c0d7619928ee78f50f999777db4cb7a8d2edb76a235ceff693079b`
- **Phase 73 proof SHA-256:** `93e9cd2e3fe3c77aa2e769b89ec41f32a301f3d87c94212c54055966a44aa376`
- **OTP 27:** 22/22 commands passed; all required evidence counts were positive.
- **OTP 28:** 22/22 commands passed; all required evidence counts were positive.
- **Receipt commit:** `ee86790` — `mix ci.phase78.receipt` passed against the committed post-completion receipt (1 test, 0 failures).

## Task Commits

1. **Task 1: Phase 79 planning lifecycle coverage** — `9b4d31e` (`test(78-09): cover Phase 79 planning lifecycle`)
2. **Task 2: Phase 73 proof and report refresh** — `f62e189` (`docs(78-09): refresh Phase 73 reconciliation proof`)
3. **Plan review amendment: exclude generated verification reports from the digest cycle** — `d6379f8` (`docs(78-09): bound verification report digest cycle`)
4. **Plan review amendment: bind the receipt to completion trackers** — `79810ce` (`docs(78-09): bind final receipt to completion trackers`)
5. **Plan review amendment: use the supported phase completion command** — `324395f` (`docs(78-09): use supported phase completion command`)
6. **Task 3: Digest boundary and mutation coverage** — `2242e2c` (`fix(78-09): bound generated report digest exclusion`)
7. **Task 3 evidence: Interim Phase 78 gap report** — `c674abe` (`docs(78-09): record interim Phase 78 gap audit`)
8. **Task 3 evidence: Initial combined OTP receipt** — `305b2a4` (`docs(78-09): record final OTP 27 and 28 clean matrix`; superseded by the final source-bound rerun below)

**Measured plan commit count:** 17 commits from ledger base `14143152bedf68dce677f89776e59547dab5dd76` at this summary revision.

## Final Closeout Commits

- `886ae3b` — recorded the initial source-bound matrix summary.
- `8e80fc0` — reconciled completion trackers before the final-source matrix.
- `bc20deb` — repaired the ordered summary provenance after the first final-source diagnostic exposed the omitted plan amendments.
- `bb22e7e` — committed the first replacement receipt, later superseded after tracker changes.
- `2002274` — recorded final-source receipt results before tracker correction.
- `8c50e8e` — committed the corrected completion trackers.
- `22135f7` — atomically published the trace cancellation PID marker after command 21 exposed the redirection race.
- `28cf229` — used portable `$$` because Bash 3.2 does not define `BASHPID`.
- `7bc19dc` — recorded the canonical `phase.complete` tracker updates before the post-completion matrix.
- `aceea5a` — committed an earlier OTP27/OTP28 receipt for source `28cf229`, superseded after phase completion.
- `ee86790` — committed the final OTP27/OTP28 receipt for source `7bc19dc`.

## Files Created/Modified

- `test/governance/milestone_scope_test.exs` — Phase 79 planning lifecycle and negative controls.
- `.planning/phases/73-twin-contract-and-baseline/73-RECONCILIATION-PROOF.json` — canonical refreshed proof.
- `.planning/phases/73-twin-contract-and-baseline/73-SECURITY.md` and `73-VALIDATION.md` — matching current proof blocks.
- `scripts/check_phase78_clean_state.sh` — bounded generated-report source-digest exclusion.
- `scripts/test_trace_visual_status_contract.sh` — atomic and Bash 3.2-compatible cancellation PID handoff.
- `test/adoption/phase78_clean_state_contract_test.exs` — digest and file-count mutation coverage.
- `.planning/phases/78-ci-efficiency-and-reliability/78-CLEAN-STATE-RECEIPT.json` — combined source-bound OTP receipt.
- `.planning/phases/78-ci-efficiency-and-reliability/78-VERIFICATION.md` — interim verifier gap findings, to be finalized by the parent closeout workflow.

## Decisions Made

- Phase 79 planning selects Phase 78 governance and receives the same scope and risk checks as the tracked Phase 78 plan set; the earlier Phase 73 planning behavior remains intact.
- Only generated verification reports beneath `.planning/phases/` are excluded from the operational digest. Reports with the same suffix elsewhere remain digest-covered.
- The two toolchain matrices share one frozen source commit and proof identity and run serially to avoid sharing Docker and browser resources.

## Deviations from Plan

**1. [Rule 1 - Bug] Repaired summary commit provenance after the diagnostic matrix caught an incomplete Task Commits list.**
- **Found during:** Final-source cold matrix.
- **Issue:** The three approved plan-amendment commits appeared outside the ordered `Task Commits` section, so governance provenance validation rejected the summary.
- **Fix:** Added all eight pre-summary commits in Git-derived order and recorded the persisted plan base and measured count.
- **Files modified:** `.planning/phases/78-ci-efficiency-and-reliability/78-09-SUMMARY.md`.
- **Commit:** `bc20deb`.

**2. [Rule 1 - Bug] Made the trace cancellation contract publish and consume a portable PID.**
- **Found during:** Task 3 final-source cold matrix, command 21.
- **Issue:** The redirection created the marker before writing its PID; after making publication atomic, Bash 3.2 still left `BASHPID` empty, so the test could not terminate its fake `npx` child.
- **Fix:** Publish through a same-directory temporary file and atomic rename, poll for a nonempty numeric PID, and use portable `$$`. The focused contract passes under Bash 3.2; both final matrices were rerun without intervention.
- **Files modified:** `scripts/test_trace_visual_status_contract.sh`.
- **Commits:** `22135f7`, `28cf229`.

The initial default-sandbox OTP 27 attempt could not launch Chromium because macOS denied `org.chromium.Chromium.MachPortRendezvousServer` registration (permission error 1100). The complete final-source OTP 27 and OTP 28 matrices were run with elevated execution; all browser and non-browser commands passed.

## Issues Encountered

- **Chromium sandbox restriction:** The first OTP 27 run failed browser commands 16–20 before tests could launch. The retained logs showed Mach service registration permission denial. The elevated final-source OTP 27 rerun passed all five browser lanes, and the elevated final-source OTP 28 run passed all five as well.
- **Summary provenance assertion:** The first final-source OTP 27 diagnostic exposed the missing amendment hashes. After repairing the summary, the full OTP 27 and OTP 28 matrices each passed all 22 commands.
- **Trace cancellation contract:** The first fixed-source diagnostic stalled at command 21 because macOS Bash 3.2 does not define `BASHPID`. Its result was excluded; the portable PID correction was focused-checked, committed, and followed by clean OTP 27 and OTP 28 22/22 runs.

## User Setup Required

None.

## Next Phase Readiness

- The completion tracker records Phase 78 Plan 09 checked and 9/9 complete, with Phase 79 as the current planning phase.
- The final receipt binds the post-completion tracker source, current Phase 73 proof, and both passing OTP matrices. The generated verification report can be finalized without changing the operational digest because its bounded exclusion is mutation-tested.

---
*Phase: 78-ci-efficiency-and-reliability*
*Completed: 2026-09-29*

## Self-Check: PASSED

- Summary file exists at the planned path.
- All 17 measured plan and closeout commits listed above exist.
- `gsd_run query verify-summary` passed with no errors.
