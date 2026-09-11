---
phase: 73-twin-contract-and-baseline
plan: 15
subsystem: testing
tags: [elixir, exunit, github-authorization, git-provenance, branch-protection]
requires:
  - phase: 73-twin-contract-and-baseline
    provides: complete branch-protection normalization, Git-first completed-plan provenance, and mandatory evidence ownership through Plan 73-14
provides:
  - Declarative-only remote mutation and rollback authorization with complete normalized payload equality
  - Endpoint-complete exact-scope Git provenance through one full HEAD commit OID
  - Post-SUMMARY changed-surface classification independent of SUMMARY and manifest claims
affects: [73-phase-verification, 74-clean-room-package-consumer, 79-github-hygiene]
actuals:
  tokens: 7323
  tasks: 2
  commits: 4
tech-stack:
  added: []
  patterns: [closed declarative operation grammar, review-endpoint-complete Git history, pre-boundary document equality audits]
key-files:
  created: []
  modified: [test/governance/milestone_scope_test.exs]
key-decisions:
  - "Authorize remote mutation and rollback only through tracked complete-state gh api --input payloads; script identity and static result files have no authorization role."
  - "Resolve one full HEAD review endpoint and classify every reachable exact-scope commit before and after the SUMMARY-add boundary."
  - "Keep SUMMARY and optional manifest equality audits restricted to the pre-boundary task set so document claims cannot omit or authorize descendants."
patterns-established:
  - "Remote authorization reduces one declarative payload into normalized state without launching plan-selected code."
  - "Completed-plan governance joins pre-boundary tasks with ordered exact-scope descendants through a named reachable endpoint."
requirements-completed: [QUAL-01, PIPE-01, GOV-01, GOV-02]
coverage:
  - id: D1
    description: "Remote mutation and rollback admit only tracked complete declarative payloads equal to the approved desired and current state."
    requirement: GOV-01
    verification:
      - kind: integration
        ref: "mix test test/governance/milestone_scope_test.exs --only plan_73_15_task_1 --warnings-as-errors (2 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Every exact-scope commit through the full HEAD review endpoint reaches changed-surface classification, including post-SUMMARY descendants."
    requirement: GOV-02
    verification:
      - kind: integration
        ref: "mix test test/governance/milestone_scope_test.exs --only plan_73_15_task_2 --warnings-as-errors (3 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The dated quality and CI inventories remain unchanged while the mandatory Phase 73 evidence contract owns both closure regressions."
    requirement: QUAL-01
    verification:
      - kind: integration
        ref: "mix ci.evidence (91 tests, 0 failures)"
        status: pass
    human_judgment: false
duration: 26min
completed: 2026-09-10
status: complete
---

# Phase 73 Plan 15: Declarative Authorization and Endpoint-Complete Provenance Summary

**Declarative complete-state remote authorization and HEAD-bounded descendant review close the script-result and post-SUMMARY governance bypasses**

## Performance

- **Duration:** 26 min
- **Started:** 2026-09-10T23:57:58Z
- **Completed:** 2026-09-11T00:24:01Z
- **Tasks:** 2
- **Files modified:** 1 implementation/test file

## Accomplishments

- Removed script-backed remote authorization and `mutation_result_source`; only tracked, regular, component-wise non-symlink JSON payloads whose complete normalized state equals the declared desired/current state can authorize mutation or rollback.
- Added adversarial proof that write, credential-read, and network-capable scripts remain rejected without execution even when indexed cleanly or paired with an exact static result.
- Resolved one full `HEAD` review endpoint, required the unique SUMMARY-add boundary to be its ancestor, and included every ordered exact-scope descendant in changed-surface review.
- Kept SUMMARY Task Commits and the optional phase manifest as exact audits of the pre-boundary implementation set, preventing document claims from trimming or authorizing descendants.

## Task Commits

1. **Task 1 RED: Reject script-backed remote mutations** — `09e17c4` (test)
2. **Task 1 GREEN: Require declarative remote mutations** — `f841242` (fix)
3. **Task 2 RED: Expose post-SUMMARY governance gap** — `bae9474` (test)
4. **Task 2 GREEN: Govern history through review endpoint** — `9fc5faf` (fix)

## Files Created/Modified

- `test/governance/milestone_scope_test.exs` — Declarative-only remote operation parsing, script rejection adversaries, full-OID review endpoint resolution, ordered descendant discovery, and changed-surface approval controls.

## Decisions Made

- Script executability, indexed object equality, and static predicted results cannot authorize remote behavior; only the existing declarative `gh api -X PUT ... --input <tracked-json>` grammar is accepted.
- The review frontier is the exact full OID of repository `HEAD`, resolved once per completed-plan provenance check, with fail-closed boundary ancestry.
- Manifest and SUMMARY hashes audit only the original implementation commits before completion; Git history independently contributes all same-plan descendants through the review endpoint.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Preserved legacy evidence ownership after replacing Plan 73-13 script controls**

- **Found during:** Task 2 complete governance verification
- **Issue:** Retagging the Plan 73-13 script tests exclusively for Plan 73-15 left the earlier evidence-owner selector with zero effective tests.
- **Fix:** Retained the original `plan_73_13_task_2` tags alongside the new Plan 73-15 tag while changing the asserted behavior from script acceptance to fail-closed rejection.
- **Files modified:** `test/governance/milestone_scope_test.exs`
- **Verification:** Complete governance contract passed 53 tests; `mix ci.evidence` passed 91 tests.
- **Committed in:** `9fc5faf`

**2. [Rule 1 - Bug] Migrated an older command-composition control to the declarative grammar**

- **Found during:** Task 2 complete governance verification
- **Issue:** The Plan 73-08 appended-command test still used a script-backed clean fixture, so its positive precondition correctly failed under the narrowed grammar.
- **Fix:** Rebased the control on the accepted direct `gh api --input` mutation and retained the shell-composition, target-mismatch, rollback, preflight, and read-back adversaries.
- **Files modified:** `test/governance/milestone_scope_test.exs`
- **Verification:** The Plan 73-08 focused selector and complete 53-test governance contract passed.
- **Committed in:** `9fc5faf`

---

**Total deviations:** 2 auto-fixed Rule 1 compatibility bugs.
**Impact on plan:** Both fixes preserve prior mandatory evidence ownership and adversarial coverage while enforcing the narrower declarative contract. No product, runtime, public API, default, SAML security posture, workflow topology, dependency, or remote state changed.

## Automated Evidence

- Task 1 focused selector — 2 tests, 0 failures; re-run at the automated tracer feedback gate.
- Task 2 focused selector — 3 tests, 0 failures.
- Complete governance contract — 53 tests, 0 failures.
- Mandatory `mix ci.evidence` lane — 91 tests, 0 failures.
- `mix ci.security` — passed all fresh-process security suites; registry-backed `hex.audit` was unavailable and retained its existing non-blocking runtime behavior.
- `mix format --check-formatted` and `git diff --check` — passed.
- `mix test --warnings-as-errors` and `mix qa` — 885 tests, 1 documented pre-existing failure in `DemoGuideDriftTest` for archival Phase 73 vocabulary in `73-PATTERNS.md`, `73-RESEARCH.md`, and `deferred-items.md`; no plan-owned test or code regression.

## Issues Encountered

- Repository-wide test and QA runs reproduced the baseline's known incomplete-phase vocabulary-policy failure. Phase 73 explicitly leaves standalone documentation cleanup to Phase 77, so the unrelated archival files were not changed.
- The user-owned `.tool-versions` remains untouched; all verification and commit hooks used explicit Elixir 1.19.5 / OTP 28.4.1 selection.

## Known Stubs

None. Placeholder strings, empty collections, nil values, malformed payloads, and missing paths in the modified test file are intentional fail-closed adversarial fixtures.

## Threat Review

- **T-73-63 mitigated:** no script-shaped command or unrelated static JSON can cross the remote mutation parser; complete tracked declarative state is required for both mutation and rollback.
- **T-73-64 mitigated:** the unique SUMMARY-add boundary must precede the full HEAD endpoint, and every reachable exact-scope descendant is classified before governance acceptance.
- No security-relevant surface outside the plan threat model was introduced, and no command execution, credential access, network request, or remote GitHub mutation occurred.

## TDD Gate Compliance

- Task 1 RED `09e17c4` failed with both script adversaries still accepted before GREEN `f841242` removed the script grammar.
- Task 2 RED `bae9474` failed because descendants were omitted and divergent history reported no endpoint boundary before GREEN `9fc5faf` made the review frontier endpoint-complete.

## User Setup Required

None.

## Next Phase Readiness

- CR-07 and CR-08 have focused deterministic proof in the mandatory evidence lane and are ready for Phase 73 security/goal re-verification.
- Plan 73-16 can reconcile the phase verification and security artifacts before Phase 74 clean-room package-consumer work begins.
- The pre-existing archival vocabulary-policy failure remains routed to Phase 77 as established by the baseline; it is not caused by Plan 73-15.

## Self-Check: PASSED

The modified governance contract, this summary, and all four RED/GREEN task commits were found. Focused selectors, the complete governance contract, mandatory evidence lane, security lane, formatting, and diff checks produced the results recorded above; repository-wide QA reproduced only its explicitly documented pre-existing archival vocabulary failure.

---
*Phase: 73-twin-contract-and-baseline*
*Completed: 2026-09-10*
