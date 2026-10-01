---
phase: 79-adopter-ready-closeout
plan: 05
subsystem: infra
tags: [github, branch-protection, governance, evidence, ci]

# Dependency graph
requires:
  - phase: 79-adopter-ready-closeout
    provides: Inventory, no-action batch, and source-bound closeout artifacts from Plans 01–04
provides:
  - Bounded same-ref REST and GraphQL branch-protection capture that fails closed on disagreement
  - Refreshed Phase 73 governed proof and dependent Phase 78 proof identity
  - Current Phase 79 inventory and blocked no-action artifacts bound to the live main SHA
affects: [phase-79-wave-6, branch-protection, milestone-governance]

# Actuals (#2632)
actuals:
  tokens: 28000
  tasks: 2
  commits: 3

# Tech tracking
tech-stack:
  added: [Python standard library]
  patterns: [Independent same-ref reads must agree before composing writable state, No-action artifacts bind exact source and record hashes]

key-files:
  created:
    - scripts/capture_phase79_protection.py
    - .planning/phases/79-adopter-ready-closeout/79-PROTECTION-CAPTURE.json
  modified:
    - scripts/collect_phase79_inventory.py
    - test/governance/milestone_scope_test.exs
    - .planning/phases/73-twin-contract-and-baseline/73-RECONCILIATION-PROOF.json
    - .planning/phases/78-ci-efficiency-and-reliability/78-CLEAN-STATE-RECEIPT.json
    - .planning/phases/79-adopter-ready-closeout/79-REMOTE-BATCH.md
    - .planning/phases/79-adopter-ready-closeout/79-VALIDATION.md

key-decisions:
  - "Do not choose between REST and GraphQL approval values; disagreement keeps the complete resource and all writable payloads unavailable."
  - "Keep Plan 79-06 read-only. A future remote mutation needs its own concrete exact batch and approval gate."
  - "Preserve Phase 78 historical matrix evidence while refreshing only the dependent Phase 73 proof identity."

patterns-established:
  - "Composite protection capture: read independent same-ref sources, bind them to one SHA, and reject missing or conflicting values without defaults."
  - "Evidence refresh: validate the canonical proof and replay its dedicated lane before updating dependent proof identities."

requirements-completed: [REPO-01, REPO-02, REPO-03, EXIT-01]
coverage:
  - id: D1
    description: "Same-ref protection capture records the live REST/GraphQL disagreement and exposes no writable resource or payload."
    requirement: REPO-03
    verification:
      - kind: unit
        ref: "mix ci.evidence (156 tests, 0 failures)"
        status: pass
      - kind: other
        ref: "python3 scripts/capture_phase79_protection.py --verify .planning/phases/79-adopter-ready-closeout/79-PROTECTION-CAPTURE.json"
        status: pass
    human_judgment: false
  - id: D2
    description: "Current governed Phase 73 proof and its dependent current identity references verify against live sources."
    requirement: EXIT-01
    verification:
      - kind: integration
        ref: "mix ci.phase73.reconciliation (1 test, 0 failures; replay passed)"
        status: pass
      - kind: other
        ref: "Relyra.Phase73Reconciliation.validate_repository!/1"
        status: pass
    human_judgment: false
  - id: D3
    description: "Inventory, desired/rollback records, risk ledger, closeout, and batch remain bound to the same main SHA with readiness unknown."
    requirement: REPO-02
    verification:
      - kind: other
        ref: "python3 scripts/collect_phase79_inventory.py --verify .planning/phases/79-adopter-ready-closeout/79-INVENTORY.json"
        status: pass
      - kind: unit
        ref: "mix ci.evidence (156 tests, 0 failures)"
        status: pass
    human_judgment: false

# Metrics
duration: "unmeasured across resumed execution"
completed: 2026-09-30
status: complete
---

# Phase 79 Plan 05 Summary

**A fail-closed protection capture and refreshed governed proof keep the closeout blocked on a live REST/GraphQL conflict**

## Performance

- **Duration:** Not measured across resumed execution
- **Started:** Earlier resumed session; exact timestamp unavailable
- **Completed:** 2026-09-30
- **Tasks:** 2
- **Files modified:** 22 declared plan files

## Accomplishments

- Added a bounded, read-only composite capture for the main ref, parent protection response, review and restriction subresources, GraphQL rule, and current-SHA fleet check run. It records no resource when modeled sources conflict.
- Re-captured `szTheory/relyra@refs/heads/main` at `c786a9890f2f99f0dd98f89a1d9713db7c486837`. REST explicitly reports one required approval; same-ref GraphQL reports a null approval count and `requiresApprovingReviews=false`. The capture remains incomplete with no writable resource.
- Refreshed the Phase 73 proof to `phase73-0e2474a0fd58f14f`, updated both governed reports and the dependent Phase 78 proof identity fields, and passed `mix ci.phase73.reconciliation` (1 test, 0 failures).
- Refreshed the Phase 79 inventory on the same main SHA. Readiness remains unknown; all nine mandatory lanes lack passing current-SHA evidence. Desired and rollback records contain no payload, and the remote batch proposes no action.
- Corrected Plan 79-04's task commit provenance from repository history and aligned Phase 79's roadmap and execution state to Wave 5 complete, Wave 6 next.

## Verification

- `mix ci.evidence` — 156 tests, 0 failures (64.8 seconds); it passed again after the final summary-boundary update (34.8 seconds).
- `mix format --check-formatted` — passed.
- `python3 scripts/capture_phase79_protection.py --verify ...79-PROTECTION-CAPTURE.json` — valid incomplete capture on the current main SHA.
- `python3 scripts/collect_phase79_inventory.py --verify ...79-INVENTORY.json` — valid inventory; readiness unknown on the same SHA.
- `mix ci.phase73.reconciliation` — 1 test, 0 failures; replay validated the refreshed proof.

Final artifact identities: the composite capture SHA-256 is `6a66b5df7f1e7e9010aa2a095b15d376a625f2be14b456ad5b6617e0b70c48fa` (source digest `86cd985a122acd911db7aa13c10894ce1f9db50912af43b108c8d227ddfde777`); the inventory SHA-256 is `7cfd398ccb1c3c090eb953b6c235c0295482230d9bce59ff77011954d8edbdd9`, observed `2026-10-01T01:43:45Z` before the local task commits. It records the tracked Phase 79 edits and the untracked summary as owned worktree state. Desired and rollback records are blocked with null payloads; their hashes are `cea6498aa6ff1e0026f261c35e369fc25f18fb934ac948d1f3d8c90354301651` and `314abdcaedf9e03eb6f4ec79ba7329e77773a5a757c58534bfa1645c1430066d`. The no-action batch SHA-256 is `be4b2145a437d069b64285cc756b86fef65e1e316555b7032bf26c1ee3db5ee4`.

The Phase 73 proof records three 156-test evidence runs (48.598, 52.820, and 50.582 seconds), 13 passing security constituents, and source digest `sha256:2d90d850203fedcf2cb6b44d64a37eb09b9439e778bdaac8181fecca15721543`. Its proof file SHA-256 is `4d06a6692022dead4d733a5000af330de9949f28323f51ba4a2e929fca5d481c`.

## Task Commits

1. **Task 1: Add deterministic composite protection capture** — `5f5a606532dac966455b0e3a308056daac07863b` (feat)
2. **Task 2: Refresh local evidence and prepare the exact unexecuted batch** — `aa22364d4b19184fe35f65d5c0396e6b79dcc495`, `897eae850285b01d757278a3fee21a7c4bcf4bd2` (docs/fix)

**Plan metadata:** recorded in the completion-boundary summary commit.

## Files Created/Modified

- `scripts/capture_phase79_protection.py` — read-only composite capture and fail-closed verification.
- `scripts/collect_phase79_inventory.py` — ownership classification for Phase 79 execution artifacts.
- `test/governance/milestone_scope_test.exs` — capture, inventory, ownership, and no-action contract coverage.
- `.planning/phases/73-twin-contract-and-baseline/73-RECONCILIATION-PROOF.json` and its reports — refreshed canonical source-bound proof.
- `.planning/phases/78-ci-efficiency-and-reliability/78-CLEAN-STATE-RECEIPT.json` — current Phase 73 proof identity refreshed; historical matrix evidence retained.
- `.planning/phases/79-adopter-ready-closeout/` — capture, inventory, blocked payload records, no-action batch, risks, closeout, validation, Plan 79-05 summary, and read-only Plan 79-06.
- `.planning/STATE.md` and `.planning/ROADMAP.md` — Wave 5 completion and Wave 6 next position.

## Decisions Made

- Preserve the source conflict explicitly. The parent protection response also omits review and restriction objects, so neither a complete current writable state nor a reversible payload can be proven.
- Keep Wave 6 read-only. A later change to GitHub requires source-consistent evidence, an exact current batch, a separate approval checkpoint, immediate preflight, and automated read-back.
- Keep release readiness unknown while required main-SHA lane evidence is absent.

## Deviations from Plan

**1. Reworked the Wave 6 plan as read-only source reconciliation**
- **Found during:** Task 2 (local evidence and next-plan preparation)
- **Issue:** The pre-existing draft combined source reconciliation, a human checkpoint, workflow dispatches, and a protection write even though no exact writable batch existed. It also used unsupported open-ended scope assertions.
- **Fix:** Replaced it with a closed-scope, fixture-tested evidence-generation plan that performs no remote operation. Any future mutation must be specified in a separate plan after a verified exact batch exists.
- **Files modified:** `.planning/phases/79-adopter-ready-closeout/79-06-PLAN.md`, `.planning/ROADMAP.md`, `.planning/STATE.md`
- **Verification:** `mix ci.evidence` passed after the plan and state updates.

**2. Repaired Plan 79-04 task commit provenance**
- **Found during:** Task 1 (mandatory Phase 73 governed-source validation)
- **Issue:** The predecessor summary's task commit list did not match its plan-scoped Git history, so the governed proof rejected the repository state.
- **Fix:** Corrected the predecessor task hashes and excluded the unrelated provenance-scoped commit.
- **Files modified:** `.planning/phases/79-adopter-ready-closeout/79-04-SUMMARY.md`
- **Verification:** Phase 73 reconciliation validation and replay passed.

**Total deviations:** 2 auto-fixed
**Impact on plan:** Both corrections were required to keep the next plan valid and restore the source-bound proof; no remote scope was added.

## Issues Encountered

The live protection sources continue to disagree. The exact blocker is recorded in `79-PROTECTION-CAPTURE.json`, and all derived artifacts fail closed. The first commit hook attempt lacked the pinned Elixir environment; retrying with Elixir 1.19.5/OTP 28 passed. No GitHub write or workflow dispatch occurred.

## User Setup Required

None.

## Next Phase Readiness

Wave 6 / Plan 79-06 is ready for read-only re-capture and deterministic local batch generation. If the REST/GraphQL conflict persists, keep the closeout blocked and record the exact discrepancy. If they agree, stop at a verified inert batch and create a separate exact-approval plan before any remote mutation. Phase 79 remains incomplete.

---
*Phase: 79-adopter-ready-closeout*
*Plan: 05*
*Completed: 2026-09-30*
