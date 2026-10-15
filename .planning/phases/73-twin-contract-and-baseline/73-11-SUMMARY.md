---
phase: 73-twin-contract-and-baseline
plan: 11
subsystem: testing
tags: [elixir, exunit, governance, branch-protection, git-provenance]
requires:
  - phase: 73-twin-contract-and-baseline
    provides: deterministic evidence ownership and trusted governance provenance from Plans 73-09 and 73-10
provides:
  - Singular closed remote-batch parsing before field reduction
  - Tracked non-symlink branch-protection payloads bound to declared current and desired state
  - Executable indexed script revisions whose print-only result is bound to desired state
affects: [74-clean-room-package-consumer, 79-adopter-ready-closeout]
actuals:
  tokens: 9403
  tasks: 2
  commits: 4
tech-stack:
  added: []
  patterns: [occurrence-preserving batch parsing, cumulative path provenance, closed JSON normalization, indexed script result probing]
key-files:
  created: []
  modified: [test/governance/milestone_scope_test.exs]
key-decisions:
  - "Remote authorization reduces fields only after exact scalar/list cardinality, closed syntax, non-empty values, and list uniqueness are established."
  - "File-backed and script-backed operations share repository provenance, while scripts additionally require executable index mode, working-tree blob equality, and a fixed local print-mode result."
patterns-established:
  - "Branch-protection state has one closed normalizer shared by desired payloads, rollback payloads, and script print output."
  - "Remote-batch validation uses only local filesystem, git-index, and print-only process operations; authorization never contacts GitHub."
requirements-completed: [EVID-01, EVID-02, QUAL-01, PIPE-01, GOV-01, GOV-02]
coverage:
  - id: D1
    description: "Every remote-batch field is singular, closed, non-empty, and fully consumed before semantic validation."
    requirement: GOV-01
    verification:
      - kind: integration
        ref: "mix test test/governance/milestone_scope_test.exs --only plan_73_11_task_1 --warnings-as-errors (2 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Mutation and rollback payloads are tracked regular non-symlink repository inputs whose normalized states equal the declared desired and current states."
    requirement: GOV-01
    verification:
      - kind: integration
        ref: "mix test test/governance/milestone_scope_test.exs --only plan_73_11_task_1 --warnings-as-errors (2 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Script-backed authorization is tied to one executable indexed revision and its fixed local print result."
    requirement: GOV-01
    verification:
      - kind: integration
        ref: "mix test test/governance/milestone_scope_test.exs --only plan_73_11_task_2 --warnings-as-errors (2 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D4
    description: "The existing mandatory fresh-process evidence lane proves all Phase 73 evidence and governance contracts together."
    requirement: EVID-02
    verification:
      - kind: ci
        ref: "mix ci.evidence (69 tests, 0 failures)"
        status: pass
    human_judgment: false
duration: 18min
completed: 2026-09-10
status: complete
---

# Phase 73 Plan 11: State-Bound Remote Authorization Summary

**Singular tracked branch-protection inputs and immutable script print results now bind remote authorization to exact declared current and desired state**

## Performance

- **Duration:** 18 min
- **Started:** 2026-09-10T18:55:52Z
- **Completed:** 2026-09-10T19:13:25Z
- **Tasks:** 2
- **Files modified:** 1 implementation/test file

## Accomplishments

- Replaced first-match remote-batch reduction with occurrence-preserving parsing that rejects duplicate or mixed scalar/list fields, empty or duplicate list items, unknown fields, and unparsed lines.
- Bound API mutation and rollback `--input` operands to repository-relative tracked regular files reached without any symlink component, then normalized one closed branch-protection JSON shape with duplicate-key rejection.
- Required desired payloads to equal declared desired state and rollback payloads to equal declared current state, including strictness and ordered unique required contexts.
- Bound script-backed mutation to an executable git-index entry, exact indexed blob, fixed repository/branch argv, and local `--print-expected-json` output equal to desired state.
- Preserved the dated quality and CI baseline and passed the combined 69-test mandatory evidence lane without remote access or mutation.

## Task Commits

1. **Task 1 RED: Define remote payload binding adversaries** — `5540237` (test)
2. **Task 1 GREEN: Bind remote payloads to declared state** — `e7cc23b` (fix)
3. **Task 2 RED: Define script result binding adversaries** — `53a3aaa` (test)
4. **Task 2 GREEN: Bind script output to approved state** — `6233d35` (fix)

## Files Created/Modified

- `test/governance/milestone_scope_test.exs` — Singular remote-batch parser, shared tracked-input provenance, closed branch-protection normalizer, desired/current equality, indexed executable script probe, and standalone Plan 73-11 selectors.

## Decisions Made

- Preserve ordered context lists and reject duplicates instead of normalizing ambiguous input through a set that could hide repeated declarations.
- Treat payload provenance and script revision provenance separately: both must be tracked regular non-symlink paths, while scripts also require git mode `100755` and a working blob equal to the indexed object ID.
- Capture script stderr with stdout and accept exactly one JSON document, so stderr, banners, and trailing output all fail before state comparison.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Kept the inherited appended-command regression on a script-backed fixture**

- **Found during:** Task 2 complete mandatory evidence run
- **Issue:** After API payloads became the default remote fixture, the Plan 73-08 script-command mutations no longer changed the fixture and one assertion became vacuous.
- **Fix:** Routed that inherited test through the script-backed fixture and retained field-scoped unparsed-line diagnostics.
- **Files modified:** `test/governance/milestone_scope_test.exs`
- **Verification:** Plan 73-08 selector passed and the complete 69-test `mix ci.evidence` lane passed.
- **Committed in:** `6233d35`

**2. [Rule 1 - Bug] Reconciled final-plan SDK progress and next-step prose**

- **Found during:** State and roadmap updates
- **Issue:** `state.update-progress` could not parse the YAML progress block after `state.advance-plan` reset the final 11/11 percentage to zero and left activity/next-step prose on Plan 73-10.
- **Fix:** Reconciled STATE to 11/11 and 100 percent, recorded Plan 73-11 as the latest activity, and routed the operator to phase verification.
- **Files modified:** `.planning/STATE.md`
- **Verification:** Eleven on-disk summaries and ROADMAP's 11/11 plan count agree with STATE.
- **Committed in:** Final metadata commit

---

**Total deviations:** 2 auto-fixed Rule 1 bugs.
**Impact on plan:** The compatibility fix restores the existing adversarial guarantee. It does not change runtime behavior, public API, defaults, security posture, dependencies, workflow topology, baseline findings, or remote GitHub state.

## Automated Evidence

- Task 1 selector — 2 tests, 0 failures.
- Task 2 selector — 2 tests, 0 failures.
- Plan 73-08 appended-command selector — 1 test, 0 failures.
- `mix ci.evidence` — 69 tests, 0 failures across both mandatory contract modules.
- `mix format --check-formatted` — passed.
- `git diff --check` — passed.

## Issues Encountered

- The evidence lane emitted the existing isolated Mix-project module redefinition warnings; all 69 selected contract tests passed. Phase 77 retains ownership of broader archival vocabulary cleanup and no out-of-scope full-suite repair was attempted.

## Known Stubs

None. Placeholder strings, malformed JSON, empty values, and missing paths in the modified test file are deliberate fail-closed adversarial fixtures.

## Threat Review

T-73-46 through T-73-50 are mitigated by occurrence-preserving parsing, cumulative non-symlink provenance, exact state equality, indexed script revision binding, and fixed print-only execution. No unplanned network endpoint, authentication path, runtime file-access surface, schema, dependency, public API, default, security posture, workflow topology, or remote GitHub state was introduced.

## TDD Gate Compliance

- Task 1 RED `5540237` preceded GREEN `e7cc23b`.
- Task 2 RED `53a3aaa` preceded GREEN `6233d35`.
- Both RED runs failed on the intended missing behavior before implementation, and both focused selectors turned green afterward.

## User Setup Required

None.

## Next Phase Readiness

- All three Phase 73 verification gap clusters now pass together through the existing mandatory evidence lane.
- Phase 74 can begin the clean-room packaged-consumer work from a fail-closed evidence and governance baseline.
- Live GitHub branch-protection repair remains explicitly deferred to Phase 79 and requires its own plan-local approval.

## Self-Check: PASSED

The modified governance contract, this summary, and all four RED/GREEN commits were found. Fresh focused selectors, the inherited compatibility selector, the mandatory evidence lane, formatting, and diff verification produced the results recorded above.

---
*Phase: 73-twin-contract-and-baseline*
*Completed: 2026-09-10*
