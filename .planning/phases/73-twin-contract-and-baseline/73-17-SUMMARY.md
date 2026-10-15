---
phase: 73-twin-contract-and-baseline
plan: 17
subsystem: adoption-evidence
tags: [exunit, immutable-snapshot, deterministic-ownership, ci-evidence, tdd]
requires:
  - phase: 73-twin-contract-and-baseline
    provides: literal evidence ledger, fail-closed owner chain, and mandatory ci.evidence workflow ownership
provides:
  - Once-per-owner fresh-process ExUnit discovery into an immutable normalized repository snapshot
  - Process-free source, selector, alias, workflow, and closure mutation validation
  - Three bounded mandatory ci.evidence runs below the 60-second acceptance limit
affects: [phase-73-reverification, 74-clean-room-package-consumer, 77-quality-cleanup]
plan_head_before: f8ad6c62b6abb8ecad62533da5b92129725617e6
actuals:
  tokens: 19066
  tasks: 2
  commits: 4
tech-stack:
  added: []
  patterns: [capture-then-validate, normalized immutable snapshots, content-addressed fresh-process evidence]
key-files:
  created: [.planning/phases/73-twin-contract-and-baseline/73-17-SUMMARY.md]
  modified: [test/support/adoption_evidence.ex, test/adoption/evidence_contract_test.exs]
key-decisions:
  - "Capture each lexical owner through actual ExUnit registration once, then perform every owner-chain check against normalized immutable data."
  - "Cache fresh-process registration only by exact owner path and SHA-256 source identity, so repeated unchanged repository checks remain bounded while every source mutation forces rediscovery."
patterns-established:
  - "Mutation-heavy evidence tests derive from one clean snapshot and never launch a nested process after capture."
  - "Snapshot structure is validated before closure: aliases, governed inputs, owner order, uniqueness, and normalized tags all fail closed."
requirements-completed: [EVID-01, EVID-02]
coverage:
  - id: D1
    description: "The literal EVID-01 ledger reaches its actual registered owners and mandatory ci.evidence lane through one immutable snapshot."
    requirement: EVID-01
    verification:
      - kind: integration
        ref: "plan_73_17_task_1 (3 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Missing, empty, duplicate, malformed, unordered, and adjacent snapshot mutations fail deterministically without additional discovery."
    requirement: EVID-02
    verification:
      - kind: integration
        ref: "plan_73_17_task_2 (1 test, 0 failures) and ci.evidence (94 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The unchanged mandatory lane completes repeatably below its 60-second per-run bound."
    requirement: EVID-02
    verification:
      - kind: integration
        ref: "mix ci.evidence attempts completed in 42s, 29s, and 40s"
        status: pass
    human_judgment: false
duration: 60min
completed: 2026-09-11
status: complete
---

# Phase 73 Plan 17: Deterministic Owner Snapshot Summary

**Fresh-process ExUnit ownership is captured once per exact owner identity, while every high-fan-out evidence mutation now validates a normalized immutable snapshot and the mandatory lane completes repeatably under 60 seconds.**

## Performance

- **Duration:** 60 min
- **Started:** 2026-09-11T03:16:12Z
- **Completed:** 2026-09-11T04:15:48Z
- **Tasks:** 2
- **Files modified:** 2 test-support/test files plus this summary

## Accomplishments

- Split repository evidence validation into `repository_snapshot!/3` capture and process-free `validate_repository_snapshot!/2` reduction behind the compatible `validate_repository!/2` entry point.
- De-duplicated and lexically ordered ledger and alias owner paths, capturing normalized registered ExUnit tags once for use by source, selector, alias effective-selection, and lane checks.
- Moved workflow, path-filter, alias, selector, and closure mutation tables onto a shared clean snapshot without removing their fail-closed diagnostics.
- Replaced repeated nested Mix discovery with direct fresh-BEAM registration and exact-source single-flight reuse, preserving authoritative registration while bounding unchanged repeated checks.
- Proved the unchanged `mix ci.evidence` lane three times at 42, 29, and 40 seconds, each with 94 tests and zero failures.

## Task Commits

Each TDD gate and implementation step was committed atomically:

1. **Task 1 RED: once-only owner and malformed snapshot regressions** — `80427d9` (test)
2. **Task 1 GREEN: deterministic repository snapshot capture** — `0481abf` (feat)
3. **Task 2 RED: bounded pure mutation and degenerate-field regressions** — `4ba7e7d` (test)
4. **Task 2 GREEN: pure mutation corpus and bounded registration reuse** — `34521d4` (feat)

**Plan metadata:** pending final metadata commit

## Files Created/Modified

- `test/support/adoption_evidence.ex` — immutable repository capture, structural fail-closed checks, snapshot owner lookup, pure alias selection, and exact-source fresh-process registration reuse.
- `test/adoption/evidence_contract_test.exs` — once-only discovery, malformed/ordering controls, repeated pure mutations, and snapshot-based legacy adversarial tables.
- `.planning/phases/73-twin-contract-and-baseline/73-17-SUMMARY.md` — execution evidence and Phase 73 re-verification handoff.

## Decisions Made

- Owner tags remain derived exclusively from registered ExUnit metadata in a fresh BEAM; comments, tuples, strings, and macro-shaped source text never become an ownership fallback.
- Alias-declared `.exs` paths join ledger owners in the same sorted, unique capture, so effective-selection checks cannot trigger independent discovery or observe a different source state.
- Content reuse is keyed by absolute owner path plus SHA-256 of the exact source bytes and is single-flight within one test VM; changed source always produces a new authoritative registration result.
- Snapshot shape validation precedes closure credit and rejects malformed aliases, duplicate governed inputs, missing/duplicate/unordered owners, empty tags, and non-normalized tag data.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected generated sequential progress state**

- **Found during:** Plan close-out
- **Issue:** The state updater counted 17 completed summaries but emitted `Plan: 2 of 19`, `percent: 0`, and stale Plan 73-17 next-step prose; the roadmap count also combined 17/19 with 16 complete and 3 pending.
- **Fix:** Reconciled the next executable position to Plan 73-18, progress to 17/19 (89%), current activity to Plan 73-17 completion, and the remaining gap count to two.
- **Files modified:** `.planning/STATE.md`, `.planning/ROADMAP.md`
- **Committed in:** final metadata commit

---

**Total deviations:** 1 auto-fixed generated-state bug.
**Impact on plan:** Documentation-only reconciliation; implementation scope, security posture, public API, defaults, SemVer, and remote state remain unchanged.

## TDD Gate Compliance

- **Task 1 RED:** `80427d9`; focused evidence intentionally failed 2 of 3 tests because the snapshot interfaces did not yet exist, and `tdd-red-evidence` accepted `/tmp/relyra-73-17-task1-red.json`.
- **Task 1 GREEN:** `0481abf`; the same focused selector passed 3 tests with once-only lexical discovery and malformed snapshot rejection.
- **Task 2 RED:** `4ba7e7d`; focused evidence intentionally failed 1 test because malformed unused aliases were accepted, and `tdd-red-evidence` accepted `/tmp/relyra-73-17-task2-red.json`.
- **Task 2 GREEN:** `34521d4`; the focused selector passed and the unchanged mandatory lane passed all three bounded attempts.
- **REFACTOR:** high-fan-out legacy mutation tables were reorganized during Task 2 GREEN without a separate behavior-changing commit; all focused and lane gates remained green.

## Automated Evidence

- Task 1 focused selector: 3 tests, 0 failures.
- Task 2 focused selector: 1 test, 0 failures.
- Mandatory `mix ci.evidence` attempt 1: 94 tests, 0 failures, 42 seconds.
- Mandatory `mix ci.evidence` attempt 2: 94 tests, 0 failures, 29 seconds.
- Mandatory `mix ci.evidence` attempt 3: 94 tests, 0 failures, 40 seconds.
- `mix format --check-formatted` and `git diff --check`: passed.

## Issues Encountered

- Initial mandatory-lane measurements remained above 60 seconds after per-invocation de-duplication because other existing evidence tests independently recompiled the same 4,000-line governance owner. Exact-source, single-flight reuse retained fresh-process authority and brought every required attempt below the declared bound.
- The primary checkout initially remained on the protected default branch. Execution paused before staging until the orchestrator re-homed the preserved RED state onto `gsd/phase-73-gap-closure`; no protected-branch commit occurred.

## Known Stubs

None.

## Threat Review

- T-73-67 is mitigated by one lexical capture per owner, pure post-capture validation, exact-source single-flight registration, and three bounded mandatory-lane passes.
- T-73-68 is mitigated by structural validation of every snapshot field before owner closure is credited.
- T-73-69 is mitigated by retaining actual fresh-process ExUnit registration as the sole source authority.
- No runtime/public API, dependency, network endpoint, auth path, schema, SAML algorithm/trust/key behavior, credential use, SemVer, workflow topology, or remote GitHub state changed.

## User Setup Required

None.

## Next Phase Readiness

- Phase 73 can be re-verified with deterministic owner-chain evidence and a repeatably bounded mandatory lane.
- Phase 74 clean-room package-consumer planning may proceed after Phase 73 verification closes.
- The pre-existing Phase 77 archival vocabulary-policy work remains unaffected.

## Self-Check: PASSED

Both modified test files, this summary, and all four TDD commits were found. Task 1 and Task 2 focused selectors, three exact bounded `mix ci.evidence` runs, formatting, and diff checks produced the results recorded above.

---
*Phase: 73-twin-contract-and-baseline*
*Completed: 2026-09-11*
