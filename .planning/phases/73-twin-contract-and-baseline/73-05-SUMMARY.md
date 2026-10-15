---
phase: 73-twin-contract-and-baseline
plan: 05
subsystem: governance
tags: [elixir, exunit, risk-metadata, remote-authorization, baseline-provenance]
requires:
  - phase: 73-twin-contract-and-baseline
    provides: evidence ownership, baseline inventory, and initial approval/scope governance from Plans 01-04
provides:
  - Closed per-task risk metadata with independent governed-surface and before/after mutation inference
  - Structured reversible remote-batch validation bound to one repository branch and affected check set
  - Exact plan-level demand-gated exclusions with unconditional implementation-region rejection
  - Row-local baseline verification markers restricted to reproducible repository paths and executable checks
affects: [74-clean-room-package-consumer, 75-saas-twin-domain-realism, 76-lifecycle-and-recovery-journeys, 77-craftsmanship, 78-ci-quality, 79-release-readiness]
actuals:
  tokens: 8973
  tasks: 3
  commits: 6
tech-stack:
  added: []
  patterns: [closed task metadata, governed-surface inference, structured reversible authorization, row-local provenance]
key-files:
  created: []
  modified: [test/governance/milestone_scope_test.exs]
key-decisions:
  - "Treat exact task risk metadata as mandatory but never authoritative over governed file, entry-point, or before/after surface evidence."
  - "Represent remote approval as one parsed batch whose state, commands, rollback, read-back, checks, and resume target agree."
  - "Permit demand-gated identifiers only in the exact plan-level exclusion and fixture-data regions, never in implementation task names, files, or actions."
  - "Accept baseline provenance only when each finding ends in one complete marker containing an approved repository path or executable check."
patterns-established:
  - "Risk closure: five exact unchanged/mutation fields per implementation task plus independent surface classification."
  - "Remote closure: captured current state and desired state share a target; every command proves the same branch/check batch."
requirements-completed: [QUAL-01, GOV-01, GOV-02]
coverage:
  - id: D1
    description: "Every unexecuted implementation task carries exact closed risk metadata, while governed files, APIs, and diffs independently trigger approval."
    requirement: GOV-01
    verification:
      - kind: integration
        ref: "test/governance/milestone_scope_test.exs#unexecuted implementation tasks require one exact closed risk value per class"
        status: pass
      - kind: integration
        ref: "mix ci.evidence (41 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Remote authorization is one non-placeholder reversible batch bound to the same repository, branch, checks, and captured state."
    requirement: GOV-01
    verification:
      - kind: integration
        ref: "test/governance/milestone_scope_test.exs#remote batch rejects placeholders and mismatched reversible targets"
        status: pass
      - kind: integration
        ref: "mix ci.evidence (41 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Demand-gated identifiers are declared once at plan level and fail unconditionally in implementation task regions."
    requirement: GOV-02
    verification:
      - kind: integration
        ref: "test/governance/milestone_scope_test.exs#task-region demand-gated smuggling fails regardless of nearby prose"
        status: pass
      - kind: integration
        ref: "mix ci.evidence (41 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Each quality-baseline finding retains one complete row-local verification marker with an allowed reproducible reference."
    requirement: QUAL-01
    verification:
      - kind: integration
        ref: "test/governance/milestone_scope_test.exs#every baseline row requires one complete allowed verification marker"
        status: pass
      - kind: integration
        ref: "mix ci.evidence (41 tests, 0 failures)"
        status: pass
    human_judgment: false
duration: 24min
completed: 2026-09-09
status: complete
---

# Phase 73 Plan 05: Fail-Closed Governance and Provenance Summary

**Closed task-risk, remote-batch, structural-exclusion, and row-local provenance contracts with adversarial controls on the mandatory evidence lane**

## Performance

- **Duration:** 24 min
- **Started:** 2026-09-09T21:08:24Z
- **Completed:** 2026-09-09T21:32:07Z
- **Tasks:** 3
- **Files modified:** 1 implementation file

## Accomplishments

- Required exactly five closed `unchanged`/`mutation` risk fields on every unexecuted implementation task and rejected missing, duplicate, unknown, multi-token, and contradictory values.
- Added independent governed-path, published-entry-point, and before/after diff classification so optimistic metadata cannot suppress a required approval checkpoint.
- Replaced remote keyword prose with a parsed, non-placeholder batch whose current/desired state, commands, rollback, read-back, affected checks, and resume signal agree on one target.
- Removed negation and governance-prose exemptions for demand-gated identifiers in task names, files, and actions while retaining a single exact plan-level exclusion region.
- Required every baseline finding to end in exactly one complete `[VERIFIED: ...]` marker containing an approved repository source or executable check reference.

## Task Commits

1. **Task 1 RED: Define closed task-risk contract** — `2642180` (test)
2. **Task 1 GREEN: Enforce governed task risk metadata** — `e54bbc7` (feat)
3. **Task 2 RED: Define structured remote-batch contract** — `77bc6d9` (test)
4. **Task 2 GREEN: Validate reversible remote batches** — `e43a37c` (feat)
5. **Task 3 RED: Define structural exclusion and provenance contract** — `6d62241` (test)
6. **Task 3 GREEN: Harden exclusions and baseline provenance** — `3f6548b` (feat)

## Files Created/Modified

- `test/governance/milestone_scope_test.exs` — Closed risk parser, governed-surface/diff classifier, structured remote-batch validator, exact exclusion parser, baseline-marker grammar, and isolated adversarial controls.

## Decisions Made

- Metadata supplies an auditable declaration, while file/content/diff classification remains an independent source of truth that can only increase required approval.
- Remote approval is batch-specific and reversible; authorization never substitutes for deterministic acceptance evidence.
- Structural task regions have no negation, cleanup, or policy-wording escape hatch for excluded product capabilities.
- Verification markers may contain explanatory/date prose, but must include at least one explicitly approved backtick-delimited repository path or executable check.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking Issue] Corrected stale ConnectionResolver read path**

- **Found during:** Task 1 mandatory read-first gate
- **Issue:** The plan named nonexistent lib/relyra/behaviours/connection_resolver.ex; the published behavior is `lib/relyra/connection_resolver.ex`.
- **Fix:** Read and classified the actual published behavior file without changing runtime code.
- **Files modified:** None
- **Verification:** `rg --files lib/relyra` resolved the real path; the governed-path controls pass on `mix ci.evidence`.
- **Commit:** Not applicable (read-only correction)

**2. [Rule 1 - Bug] Corrected contradictory SDK closeout state**

- **Found during:** State and roadmap updates
- **Issue:** `state.advance-plan` correctly reached 5/5, but `state.update-progress` could not parse the YAML progress block and reset `percent` to 0 while leaving stale “Ready to execute” and Plan 04 activity prose.
- **Fix:** Restored disk-backed 100 percent progress, set Phase 73 to verifying, recorded Plan 05 as the latest activity, and routed the operator to phase re-verification.
- **Files modified:** `.planning/STATE.md`
- **Verification:** STATE now reports 5 completed plans, 100 percent, `status: verifying`, and the Phase 73 re-verification next step.
- **Commit:** Final metadata commit

---

**Total deviations:** 2 auto-fixed (1 Rule 1, 1 Rule 3).
**Impact on plan:** The corrections preserve the intended governed-surface boundary and truthful planning state without introducing runtime, public API, dependency, protocol, security-posture, or remote-state change.

## Automated Evidence

- `mix test test/governance/milestone_scope_test.exs --only evidence_contract --warnings-as-errors` — 28 tests, 0 failures.
- `mix ci.evidence` — 41 tests, 0 failures in the mandatory fresh-process evidence owner.
- `mix format --check-formatted` — passed.
- `git diff --check` — passed.
- `mix ci.security` — all independent fresh-process security suites, dependency audit, and Sobelow scan completed successfully; `hex.audit` remained unavailable and was explicitly reported by the existing alias.
- `mix qa` — 835 tests, 1 known out-of-scope `Relyra.Docs.DemoGuideDriftTest` failure from archival Phase 73 vocabulary. This remains finding `QUAL-73-006`, owned by Phase 77, and was not changed by this plan.

## Issues Encountered

- The repository-wide QA run retains the already inventoried archival vocabulary-policy failure and four golden-fixture test-pattern warnings. Both remain explicitly downstream-owned by Phase 77.
- The user-owned untracked `.tool-versions` does not select Elixir/Erlang, so verification and commit hooks were run with the plan-mandated explicit `ASDF_ELIXIR_VERSION=1.19.5-otp-28` and `ASDF_ERLANG_VERSION=28.4.1` environment values.

## Known Stubs

None. Empty, `TBD`, `placeholder`, and omitted-command strings in the modified test file are deliberate negative controls that must fail validation; they do not flow to runtime or UI behavior.

## Threat Review

All registered T-73-18 through T-73-23 mitigations are covered by local adversarial fixtures. No runtime trust surface, parser path, signature verification, algorithm policy, key handling, audit persistence, replay behavior, public API, default, dependency, or remote GitHub state changed.

## User Setup Required

None. No remote command was executed.

## Next Phase Readiness

- Phase 73's five plans now provide fail-closed evidence, baseline, approval, and feature-neutrality contracts for Phase 74 onward.
- Phase 77 still owns the archival vocabulary scanner and golden-fixture warnings; Phase 79 still exclusively owns any approved live branch-protection repair.

## Self-Check: PASSED

The modified governance contract and all six RED/GREEN commits were found. Fresh focused, mandatory evidence, formatting, diff, and security gates produced the results recorded above.

---
*Phase: 73-twin-contract-and-baseline*
*Completed: 2026-09-09*
