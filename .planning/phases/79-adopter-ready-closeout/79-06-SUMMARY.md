---
phase: 79-adopter-ready-closeout
plan: 06
subsystem: infra
tags: [github, protection, governance, evidence, ci]
requires:
  - phase: 79-adopter-ready-closeout
    provides: Same-ref protection capture, inventory validators, and Wave 5 closeout artifacts
provides:
  - Fixture-tested local fail-closed protection batch builder
  - Fresh same-SHA capture and inventory with hash-bound blocked payload records
  - Read-only next action and exact live blocker for the closeout
affects: [phase-79, github-protection, release-readiness]
actuals:
  tokens: 17656
  tasks: 2
  commits: 3
tech-stack:
  added: [Python standard library]
  patterns: [fail-closed evidence builder, same-SHA hash-bound local artifacts]
key-files:
  created: [scripts/prepare_phase79_batch.py]
  modified: [test/governance/milestone_scope_test.exs, .planning/phases/79-adopter-ready-closeout/79-PROTECTION-CAPTURE.json, .planning/phases/79-adopter-ready-closeout/79-PROTECTION-DESIRED.json, .planning/phases/79-adopter-ready-closeout/79-PROTECTION-ROLLBACK.json, .planning/phases/79-adopter-ready-closeout/79-REMOTE-BATCH.md, .planning/phases/79-adopter-ready-closeout/79-INVENTORY.json, .planning/phases/79-adopter-ready-closeout/79-INVENTORY.md, .planning/phases/79-adopter-ready-closeout/79-RISKS.json, .planning/phases/79-adopter-ready-closeout/79-CLOSEOUT.md, .planning/phases/79-adopter-ready-closeout/79-VALIDATION.md, .planning/STATE.md, .planning/ROADMAP.md]
key-decisions:
  - "Require REST and GraphQL agreement for a writable protection payload; preserve conflicts as blocked records."
  - "Keep readiness unknown until all mandatory lanes have passing evidence on the captured main SHA."
  - "Any later GitHub mutation requires a separate exact plan and approval gate."
patterns-established:
  - "Validate capture and inventory before deriving payloads, then bind records to exact source bytes."
  - "Incomplete or conflicting evidence produces null payloads and a verified no-action batch."
requirements-completed: [REPO-01, REPO-02, REPO-03, EXIT-01]
coverage:
  - id: D1
    description: "Deterministic builder verifies complete source evidence and rejects conflicts, stale refs, unknown fields, missing app association, and altered bytes."
    requirement: REPO-03
    verification:
      - kind: unit
        ref: test/governance/milestone_scope_test.exs
        status: pass
      - kind: other
        ref: "ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix ci.evidence"
        status: pass
    human_judgment: false
  - id: D2
    description: "Fresh read-only evidence records the unresolved source conflict and keeps readiness unknown with no writable payload."
    requirement: REPO-02
    verification:
      - kind: other
        ref: ".planning/phases/79-adopter-ready-closeout/79-PROTECTION-CAPTURE.json and 79-INVENTORY.json verifiers"
        status: pass
    human_judgment: false
duration: 12min
completed: 2026-10-01
status: complete
plan_head_before: d3d7c498cea15f3abfddbd71ea2ad780eac26017
commits: 3
---

# Phase 79 Plan 06: Adopter-Ready Closeout Summary

**A deterministic local builder now fails closed on conflicting GitHub protection evidence, with fresh same-SHA artifacts preserving the unresolved blocker and no-action outcome.**

## Performance

- **Duration:** approximately 12 minutes
- **Started:** 2026-10-01T12:02:00Z (approximate; executor start timestamp was not retained)
- **Completed:** 2026-10-01T12:14:43Z
- **Tasks:** 2
- **Files modified:** 14 plan-scoped files, including this summary and roadmap/state updates

## Accomplishments

- Added a deterministic local builder that validates capture and inventory bytes, binds all outputs to their hashes, and emits writable payloads only when same-SHA evidence is complete and consistent.
- Added fixtures for the exact-delta success path and rejection of source disagreement, ref drift, unknown fields, stale inventory, missing app association, and altered artifacts.
- Refreshed read-only GitHub evidence and preserved the live REST/GraphQL conflict. The capture, inventory, desired/rollback records, and no-action batch all refer to main SHA `c786a9890f2f99f0dd98f89a1d9713db7c486837`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Build deterministic fail-closed batch generation** - `4caaff3` (`feat`)
2. **Task 2: Re-capture live evidence and leave the next action explicit** - `6ecf0c4` (`docs`)

The Task 1 correction commit `f476efa` is documented under deviations.

## Files Created/Modified

- `scripts/prepare_phase79_batch.py` - Local-only validation and deterministic inert batch generation.
- `test/governance/milestone_scope_test.exs` - Positive and negative builder fixtures in the mandatory evidence lane.
- `.planning/phases/79-adopter-ready-closeout/79-PROTECTION-CAPTURE.json` - Fresh composite read-only capture.
- `.planning/phases/79-adopter-ready-closeout/79-PROTECTION-DESIRED.json` and `79-PROTECTION-ROLLBACK.json` - Blocked records with no payload.
- `.planning/phases/79-adopter-ready-closeout/79-REMOTE-BATCH.md` - Verified no-action record.
- `.planning/phases/79-adopter-ready-closeout/79-INVENTORY.json` and `79-INVENTORY.md` - Same-SHA GitHub and local inventory.
- `.planning/phases/79-adopter-ready-closeout/79-CLOSEOUT.md`, `79-RISKS.json`, and `79-VALIDATION.md` - Refreshed closeout and evidence notes.

## Verified Evidence and Current Blocker

- Fresh capture observed at `2026-10-01T12:07:52Z`; capture status is `incomplete` for main SHA `c786a9890f2f99f0dd98f89a1d9713db7c486837`.
- REST review subresource reports `required_approving_review_count=1`. Same-ref GraphQL reports `requiredApprovingReviewCount=null` and `requiresApprovingReviews=false`. The exact capture error is `GraphQL approval settings conflict with the REST review subresource`.
- The parent branch-protection response also omits `required_pull_request_reviews` and `restrictions`. The inventory was observed at `2026-10-01T12:07:59Z`, revalidated the same main SHA, and reports readiness `unknown`; all nine mandatory lanes lack passing evidence on that SHA.
- SHA-256 identities: capture `933243f5dc3d01b9a0673e9270c7abdc6d6185ee2512190c7b7854014580e908`; source digest `abbfcd7bb34aed797d9ecb91414e2075f193ce929d4eb6eb50849440370e296a`; inventory `f6633e69eadf3b80d707372bb7347f50a25bec1b47c5ec8ba78d8cfbccaa3d12`; desired record `5c53f5ecd0d8b65baf87c4c0476bf1700e6e504218a69260f3bf20f77394379d`; rollback record `1ebc4cebf0cf807f6fca98c6b33d992e84af7fac835ef57cccc9660dc4bc3433`; no-action batch record `ac64a6845b996ef5b0e93188447a165af2dfe06dda2cc96a46b3dfdef8521605`.
- The exact required command `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix ci.evidence` passed: **157 tests, 0 failures**. Capture, inventory, and batch artifact verifiers also passed.
- **Exact next action:** the GitHub policy owner must resolve the REST/GraphQL disagreement and make the complete protection resource available. Once that is done, repeat the read-only capture and inventory; proceed only if source settings agree and all nine mandatory lanes have passing evidence on the same main SHA. Then create a separate exact approval plan before any remote operation.
- No approval was inferred, and no GitHub write, approval operation, or workflow dispatch was performed.

## Decisions Made

- Conflicting settings remain conflicting evidence; neither REST nor GraphQL is selected by preference.
- Missing mandatory-lane evidence keeps readiness unknown.
- A later mutation remains outside this plan and requires a separate exact plan with its own approval gate.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserve independent source and ownership findings in blocked output**
- **Found during:** Task 1 (Build deterministic fail-closed batch generation)
- **Issue:** Treating the REST and inventory protection errors as equivalent could erase the distinct GraphQL-vs-REST approval conflict and its separate missing-settings blocker.
- **Fix:** Preserve source-specific blocker details and ensure both blocked records retain null payloads; update ownership fixture expectations for the current inventory without claiming cleanup authority.
- **Files modified:** `scripts/prepare_phase79_batch.py`, `test/governance/milestone_scope_test.exs`
- **Verification:** Mandatory evidence lane passed with 157 tests and 0 failures; builder verification passed.
- **Committed in:** `f476efa`

**Total deviations:** 1 auto-fixed (Rule 1)
**Impact on plan:** Kept the fail-closed outcome and preserved provenance without expanding into any remote action.

## Issues Encountered

The REST and GraphQL protection APIs still disagree, and the parent protection response omits two writable settings. These facts were retained as explicit blockers; no source was preferred.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 79-06 is complete. Phase 79 remains blocked: the protection evidence is incomplete and mandatory same-SHA lane evidence is absent. The closeout can advance only after the source conflict is resolved, a new read-only capture proves agreement, and all nine mandatory lanes pass for the same main SHA. Any GitHub mutation requires a separate plan and approval gate.

## Self-Check: PASSED

- Summary file exists.
- Task commits `4caaff3` and `f476efa` exist.
- Plan-head ledger measurement from `d3d7c498cea15f3abfddbd71ea2ad780eac26017` records 3 plan commits: `4caaff3`, `f476efa`, and `6ecf0c4`.

---
*Phase: 79-adopter-ready-closeout*
*Completed: 2026-10-01*
