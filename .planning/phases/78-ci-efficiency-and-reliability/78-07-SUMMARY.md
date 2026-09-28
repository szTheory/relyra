---
phase: 78-ci-efficiency-and-reliability
plan: 07
subsystem: ci
tags: [github-actions, mix, playwright, docker, cold-ci, evidence]

# Dependency graph
requires:
  - phase: 78-ci-efficiency-and-reliability
    provides: Named mandatory CI lanes, independent security gates, isolated consumer profiles, and bounded browser evidence
provides:
  - Source-bound cold producer and fail-closed mandatory receipt owner
  - Current Phase 73 proof embedded identically in both reports and replayed
  - Complete OTP 27/28 cold receipts with positive command evidence
affects: [ci, security-gates, phase-78-verification]

# Actuals (#2632)
actuals:
  tokens: 78710
  tasks: 3
  commits: 22

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Run acceptance commands in an owned cold checkout with isolated tool homes, database, browser assets, and bounded per-command receipts.
    - Keep the real receipt selector outside producer aliases and execute it only as a separate mandatory owner.
    - Bind cold receipts to a committed source digest, Phase 73 proof identity, and distinct runner identities.

key-files:
  created:
    - scripts/check_phase78_clean_state.sh
    - test/adoption/phase78_clean_state_contract_test.exs
    - .planning/phases/78-ci-efficiency-and-reliability/78-CLEAN-STATE-RECEIPT.json
  modified:
    - .github/workflows/security-gates.yml
    - mix.exs
    - test/test_helper.exs
    - demo/ledger_loop/test/ledger_loop/demo/reset_test.exs
    - .planning/phases/73-twin-contract-and-baseline/73-RECONCILIATION-PROOF.json
    - .planning/phases/73-twin-contract-and-baseline/73-SECURITY.md
    - .planning/phases/73-twin-contract-and-baseline/73-VALIDATION.md

key-decisions:
  - "Require a separate PR/main receipt owner after both cold producers; producer aliases cannot satisfy their own selector."
  - "Copy Buildx into the runner's isolated Docker configuration and run browser/demo commands with the same dev environment as CI."
  - "Sort PostgreSQL reset rows by primary key before comparing results because SQL query order is unspecified without ORDER BY."
  - "Accept the canonical sha256: prefix in Phase 73 source digests while retaining bare SHA-256 support for fixtures."

patterns-established:
  - "A receipt is accepted only when its closed command manifest, positive evidence counts, source digest, proof bytes, and isolated OTP 27/28 identities all validate."
  - "Cold browser journeys use the owned runner's downloaded browser and an execution environment that permits Chromium's macOS Mach service."

requirements-completed: [PIPE-02, PIPE-03, PIPE-04, PIPE-05]

coverage:
  - id: D1
    description: "A source-bound cold producer records every command and a separate mandatory selector rejects stale, incomplete, failed, or zero-evidence receipts."
    requirement: PIPE-02
    verification:
      - kind: unit
        ref: "test/adoption/phase78_clean_state_contract_test.exs --only phase78_clean_state_schema — 1 test, 0 failures"
        status: pass
      - kind: integration
        ref: "mix ci.phase78.receipt — real selector, 1 test, 0 failures"
        status: pass
    human_judgment: false
  - id: D2
    description: "The final Phase 73 proof is source-bound, identical in SECURITY and VALIDATION, and replays successfully."
    requirement: PIPE-03
    verification:
      - kind: integration
        ref: "Relyra.Phase73Reconciliation.validate_repository!/1 — passed"
        status: pass
      - kind: integration
        ref: "mix ci.phase73.reconciliation — 1 test, 0 failures on OTP 27 and OTP 28"
        status: pass
    human_judgment: false
  - id: D3
    description: "The complete clean-state manifest passes on isolated OTP 27 and OTP 28 environments with current source and proof digests."
    requirement: PIPE-04
    verification:
      - kind: other
        ref: "78-CLEAN-STATE-RECEIPT.json — both runs passed all 22 commands; 1111 tracked source files; 2603 positive tests/checks/journey assertions per toolchain"
        status: pass
    human_judgment: false
  - id: D4
    description: "The cold manifest retains independent security, consumer, demo, browser, Docker proxy, trace-status, and actionlint checks."
    requirement: PIPE-05
    verification:
      - kind: integration
        ref: "78-CLEAN-STATE-RECEIPT.json — security 71, evidence 150, consumer profiles 18/3/26, demo suites 106/106, browser journeys 1/2/1, Fleet 2, Keycloak 1, trace status 1; all passed on both OTP versions"
        status: pass
    human_judgment: false

# Metrics
duration: 17h
completed: 2026-09-28
status: complete
---

# Phase 78 Plan 07: Source-Bound Cold CI Matrix

**A fail-closed receipt owner now validates complete cold CI evidence and the current Phase 73 proof across OTP 27 and OTP 28.**

## Performance

- **Duration:** About 17 hours across the execution and final cold-matrix runs
- **Started:** 2026-09-28T01:51:27-04:00
- **Completed:** 2026-09-28T18:50:19-04:00
- **Tasks:** 3
- **Files modified:** 23

## Accomplishments

- Added an owned cold-checkout producer that captures the full 22-command manifest, exact source digest, Phase 73 proof identity, runner identity, exits, positive evidence counts, and bounded output digests.
- Added a separate mandatory `mix ci.phase78.receipt` owner and unconditional security-gates workflow step. The real selector remains excluded from producer aliases.
- Recaptured and replayed the canonical Phase 73 proof after the last governed code change; both append-only reports contain the identical proof block.
- Passed the full 22-command matrix on OTP 27 and OTP 28 at source `38265b8a12a12c44dcfafe9950eb273365f2e96f`. Both runs covered 1111 tracked operational files and produced 2603 positive test/check/journey results with no nonzero exits.
- Passed the committed receipt owner: 1 selected real-selector test, 0 failures.

## Task Commits

1. **Task 1: Build the source-bound producer and mandatory receipt owner**

   - `c2564d84a8c5d2c612d8778b7c404f6d54162349` — require cold source-bound receipt
   - `a8d2d9c91d338ad4c671d6ecc688dc174ae0f954` — canonicalize cold workspace temp root
   - `8eaebec074e7091fe8781bfe72696e28305edba6` — prepare fresh LedgerLoop test metadata
   - `46e6b25d8b9162bed0cead35db93bd03a7da17b2` — stabilize clean-state test contracts
   - `59a3d6098ae85dec0baa6abaa59e95a24a70f1ba` — preserve isolated Node shim resolution
   - `d52a9a5939249d4462b27dc9130aadf0d0994f89` — preserve tools in isolated cold runner

2. **Task 2: Capture and replay final Phase 73 proof**

   - `8e3b9cc39976e00d6eecac0205af867713dfb047` — initial final-source proof capture
   - `f2d7316d15c0ae138512cc0555a7cf352e5c0ba2` — refresh proof after producer fix
   - `120a0621ca59496a0518fb5fddad212b31f23583` — refresh proof after LedgerLoop setup
   - `6bf60bf782211d60e9a4c0b3651eb1075c166f81` — refresh proof after contract fixes
   - `df1f7b1b25f5fa8285001c8d4163bef8c58b46fa` — refresh proof after ASDF fix
   - `c739b7ff7b5f296ee5b86f2e97cd81cdb2e11988` — stabilize LedgerLoop cold checks
   - `93d088bbf2dfec7c1c7fc67e342f8b1442a72fc7` — stabilize evidence contract execution
   - `d89aa65d6aab6fda7946cb6725ae92775adf5b94` — refresh Phase 73 reconciliation proof
   - `5c60db8aeacbcb739038338a62915d4e00658b9e` — align cold producer environments
   - `545e216d7c63e2188c402b056ab4640b9094377c` — refresh Phase 73 proof
   - `c36ad4d4bae378131f82212cc5b0189bef31ee37` — compare LedgerLoop reset rows in stable order
   - `cbe0b38d39cb837b0b22ffa836d5f2fd8bb7aa59` — refresh proof after reset test fix
   - `2bb5281d9b35686098e4630cb8983b0a799931a9` — accept canonical Phase 73 digests
   - `38265b8a12a12c44dcfafe9950eb273365f2e96f` — refresh proof for digest validator

3. **Task 3: Run the cold matrix and mandatory receipt owner**

   - `70b3a8389dea8c992efea40696a064e3fe3bd4ba` — provisional receipt, superseded after the owner exposed the digest-prefix mismatch
   - `095283a672d8591e3fc5ef4f1512c4dc764dd775` — validated OTP 27/28 receipt

Supporting proof refresh commits created during Tasks 1–3 are listed above under Task 2. The current receipt records source commit `38265b8a12a12c44dcfafe9950eb273365f2e96f`, source digest `2fc6137a4128bf31460883c6d061739367e85e5813460366eda1f00d0b0ccd4d`, and Phase 73 proof `phase73-b634149892e68a9e` (`ce739537248e3607f6a76df572cb4312eda8e2f97a95fc2d30a7c23ee4a65b55`).

## Files Created/Modified

- `scripts/check_phase78_clean_state.sh` — owns isolated setup, runs the full manifest, records evidence, and assembles the final OTP matrix receipt.
- `test/adoption/phase78_clean_state_contract_test.exs` — covers closed schemas, fixtures, stale and failed evidence, and the actual receipt selector.
- `.github/workflows/security-gates.yml`, `mix.exs`, and `test/test_helper.exs` — keep the receipt owner separate and mandatory.
- `demo/ledger_loop/test/ledger_loop/demo/reset_test.exs` — compares PostgreSQL result rows deterministically.
- `78-CLEAN-STATE-RECEIPT.json` — records both cold runs and all command outcomes.
- Phase 73 proof, SECURITY, and VALIDATION reports — carry identical current proof blocks.

## Decisions Made

- Kept cold producers and the real receipt selector acyclic so an incomplete producer cannot validate itself.
- Preserved Phase 73’s `sha256:` digest representation and corrected the Phase 78 selector to validate that canonical form.
- Used elevated process permissions only for the isolated matrix because macOS blocked Chromium’s Mach port registration in the restricted process sandbox; the same owned-workspace browser launch passed with elevated execution.

## Deviations from Plan

### Auto-fixed Issues

**1. Cold runner lacked tools/config needed by isolated proxy builds and browser apps**
- **Found during:** Task 3 cold producer runs
- **Issue:** The isolated Docker config lacked Buildx, and inherited `MIX_ENV=test` prevented demo HTTP servers from starting as they do in CI.
- **Fix:** Copy the installed Buildx plugin into the owned Docker config and run the browser/demo commands in `MIX_ENV=dev`.
- **Files modified:** `scripts/check_phase78_clean_state.sh`, `test/adoption/phase78_clean_state_contract_test.exs`
- **Verification:** Both final OTP producers passed Fleet, Keycloak, and all browser journeys.
- **Committed in:** `5c60db8aeacbcb739038338a62915d4e00658b9e`

**2. LedgerLoop reset test depended on unspecified PostgreSQL row order**
- **Found during:** Task 3 OTP 28 producer run
- **Issue:** Equal rows could arrive in different orders because the queries have no `ORDER BY`.
- **Fix:** Sort the six queried collections by primary key before comparison.
- **Files modified:** `demo/ledger_loop/test/ledger_loop/demo/reset_test.exs`
- **Verification:** `mix ci.demo_app` and nested LedgerLoop tests passed on both OTP versions.
- **Committed in:** `c36ad4d4bae378131f82212cc5b0189bef31ee37`

**3. Receipt selector rejected Phase 73’s canonical prefixed SHA-256**
- **Found during:** Task 3 mandatory receipt-owner test
- **Issue:** The receipt copied `sha256:<hex>` from the proof, while the selector accepted only bare hexadecimal at the schema check.
- **Fix:** Accept either representation at the Phase 73 digest field and retain exact equality against the checked-in proof.
- **Files modified:** `test/adoption/phase78_clean_state_contract_test.exs`
- **Verification:** Focused schema test passed; refreshed proof and both final cold producers passed; real receipt owner passed.
- **Committed in:** `2bb5281d9b35686098e4630cb8983b0a799931a9`

**Total deviations:** 3 auto-fixed implementation issues; one environment-only elevated rerun after Chromium was blocked by the restricted sandbox.
**Impact on plan:** Each fix was required to make the planned clean-state evidence deterministic and representative. No security gate or acceptance criterion was weakened.

## Issues Encountered

- A first receipt-owner run exposed the Phase 73 digest-prefix mismatch; the selector contract was fixed and the proof and cold matrix were regenerated.
- Chromium failed to register `MachPortRendezvousServer` under the restricted process sandbox. A one-off launch in the retained owned workspace passed with elevated execution, and the final matrix passed with those permissions.
- Earlier cold runs exposed runner environment assumptions and the LedgerLoop ordering flake; all are covered by the final passing receipts.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 07 evidence is ready for Phase 78 goal verification and final tracking updates.
- No push or Hex publish was performed.

---
*Phase: 78-ci-efficiency-and-reliability*
*Completed: 2026-09-28*
