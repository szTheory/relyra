---
phase: 73-twin-contract-and-baseline
plan: 03
subsystem: governance
tags: [elixir, exunit, plan-policy, approval-checkpoints, scope-governance]
requires:
  - phase: 73-twin-contract-and-baseline
    provides: deterministic evidence ownership and the quality/CI baseline from Plans 01-02
provides:
  - Plan-local blocking approval contract for public API, default, security-posture, SemVer-major, and remote GitHub mutations
  - Feature-neutral active-plan validation with roadmap requirement ownership and demand-gated capability exclusions
  - Focused automated-completion policy for active plans and required UAT artifacts
affects: [74-clean-room-package-consumer, 75-saas-twin-domain-realism, 76-lifecycle-and-recovery-journeys, 77-craftsmanship, 78-ci-quality, 79-release-readiness]
actuals:
  tokens: 7135
  tasks: 2
  commits: 6
tech-stack:
  added: []
  patterns: [anchored XML-like plan parsing, plan-local ordered authorization, implementation-region scope validation]
key-files:
  created: []
  modified: [test/governance/milestone_scope_test.exs, test/support/adoption_evidence.ex, .planning/phases/73-twin-contract-and-baseline/deferred-items.md, .planning/WINDOWS.md]
key-decisions:
  - "Require each risky task to carry an explicit approval_class marker matched by a blocking plan-local checkpoint before mutation."
  - "Treat remote GitHub authorization as its own exact reversible batch with current/desired state, commands, preflight, rollback, read-back, and resume signal."
  - "Scan active PLAN and required UAT artifacts for completion policy while treating archived research and policy examples as non-executable documentation."
patterns-established:
  - "Risk boundary: explicit negative scope assertion or matching plan-local blocking checkpoint before the first named mutation."
  - "Feature-neutral boundary: plan requirements belong to their roadmap phase and demand-gated identifiers may appear only in negative or governance-policy regions."
requirements-completed: [GOV-01, GOV-02]
coverage:
  - id: D1
    description: "Every active plan either negates all five risky mutation classes or stops at a matching plan-local blocking checkpoint before mutation."
    requirement: GOV-01
    verification:
      - kind: integration
        ref: "test/governance/milestone_scope_test.exs#active v1.11 plans declare scope and stop before every risky mutation"
        status: pass
      - kind: integration
        ref: "ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix ci.evidence (29 tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Active plans remain feature-neutral through roadmap requirement ownership and implementation-region exclusion of demand-gated capabilities."
    requirement: GOV-02
    verification:
      - kind: integration
        ref: "test/governance/milestone_scope_test.exs#demand-gated capabilities are legal only in explicit negative policy regions"
        status: pass
      - kind: integration
        ref: "ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix ci.evidence (29 tests)"
        status: pass
    human_judgment: false
duration: 17min
completed: 2026-09-09
status: complete
---

# Phase 73 Plan 03: Approval and Feature-Neutral Governance Summary

**Fail-closed active-plan governance with ordered local approvals, roadmap-owned requirements, and deterministic completion evidence**

## Performance

- **Duration:** 17 min
- **Started:** 2026-09-09T18:14:46Z
- **Completed:** 2026-09-09T18:31:50Z
- **Tasks:** 2
- **Files modified:** 2 implementation files plus planning ledgers

## Accomplishments

- Enforced explicit negative declarations or correctly classified plan-local approval before public API, default-tightening, security-posture, real SemVer-major, and remote GitHub mutations.
- Proved missing, late, wrong-class, non-blocking, cross-plan, concurrent-branch, interrupted, and incomplete remote approval fixtures fail closed.
- Bound plan requirements to their roadmap phase and rejected forbidden or disguised implementation of `AUTHN-POST-01`, `KMS-01`, and `SIGNED-META-01` while allowing explicit exclusions and governance-policy citations.
- Moved active completion-policy ownership into the governance contract, where PLAN files and required UAT artifacts are scanned without treating archival research examples as executable acceptance.
- Promoted GOV-01 and GOV-02 to existing deterministic owners on the mandatory `ci.evidence` lane.

## Task Commits

1. **Task 1 RED: Define failing approval boundary contract** — `f37ca7c` (test)
2. **Task 1 GREEN: Enforce approval boundaries before mutation** — `cc46b9a` (feat)
3. **Task 2 RED: Define failing feature-neutral scope contract** — `0af13ce` (test)
4. **Task 2 GREEN: Enforce feature-neutral milestone scope** — `0e23a71` (feat)
5. **Deviation RED: Require live governance evidence owners** — `bd0824f` (test)
6. **Deviation GREEN: Promote governance evidence owners** — `9611488` (feat)

## Files Created/Modified

- `test/governance/milestone_scope_test.exs` — Ordered plan parser, approval/scope/requirement/automation validators, and isolated negative fixtures.
- `test/support/adoption_evidence.ex` — Existing deterministic GOV-01/GOV-02 owners on `ci.evidence`.
- `.planning/phases/73-twin-contract-and-baseline/deferred-items.md` — Closeout failures retained for their owning phases.
- `.planning/WINDOWS.md` — Open Phoenix advisory truth recorded for ship-time visibility.

## Decisions Made

- Made authorization plan-local and class-specific; approval from another plan or execution branch cannot be borrowed.
- Required the remote GitHub class to describe one exact reversible command batch and its postcondition read-back.
- Kept authorization separate from acceptance: only deterministic automated commands can satisfy completion evidence.
- Limited active automation scanning to executable plan artifacts and required UAT files; archived research, patterns, and historical milestones remain documentary context.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Functionality] Promoted completed governance evidence owners**

- **Found during:** Overall verification after Task 2
- **Issue:** GOV-01 and GOV-02 still had planned rows pointing at nonexistent `ci.governance`, so marking them complete would violate Phase 73's own anti-hollow closure contract.
- **Fix:** Added RED coverage, promoted exactly GOV-01 and GOV-02 to existing `test/governance/milestone_scope_test.exs` owners using selector `evidence_contract` and lane `ci.evidence`, and left later requirements planned.
- **Files modified:** `test/governance/milestone_scope_test.exs`, `test/support/adoption_evidence.ex`
- **Verification:** `mix ci.evidence` passes 29 tests with 0 failures.
- **Commits:** `bd0824f`, `9611488`

**2. [Rule 1 - Bug] Corrected contradictory SDK state output**

- **Found during:** State and roadmap updates
- **Issue:** `state.update-progress` could not recognize the repository's YAML progress field after `state.advance-plan`, leaving 3/3 completed plans with `percent: 0`; `state.add-decision` also duplicated the phase prefix.
- **Fix:** Restored `percent: 100`, normalized the three decision prefixes, and aligned the current-position/operator-next-step prose with verification state.
- **Files modified:** `.planning/STATE.md`
- **Verification:** STATE now reports 3 completed plans, 100 percent, and `status: verifying`; ROADMAP reports 3/3 plans executed.
- **Committed in:** Final metadata commit

---

**Total deviations:** 2 auto-fixed (1 Rule 1, 1 Rule 2)
**Impact on plan:** Both corrections preserve deterministic closure and truthful state without adding runtime, public API, dependency, protocol, or remote-state surface.

## Verification

- `mix test test/governance/milestone_scope_test.exs --warnings-as-errors` — 20 tests, 0 failures after the final governance-owner assertion.
- `mix ci.evidence` — 29 tests, 0 failures after all implementation changes.
- `mix format --check-formatted` — passed.
- `mix qa` — 822 tests, 1 known failure in `Relyra.Docs.DemoGuideDriftTest`; the older broad vocabulary scanner still flags archival Phase 73 policy examples. This is existing finding `QUAL-73-006`, routed to Phase 77, and was not changed under the approved wave decision.
- `mix ci.security` — every dedicated fresh-process security test passed, then `deps.audit` failed because Phoenix `1.8.7` is affected by `GHSA-63mc-hw7g-86rr` and high-severity `GHSA-6983-jfq8-485w` (first patched `1.8.x`: `1.8.9`). Dependency mutation is outside this plan's security-posture-unchanged scope; the finding is recorded in deferred items and `.planning/WINDOWS.md`.

## Known Stubs

None. Empty values in the changed files are negative validation controls or fail-closed predicates, not user-visible data stubs.

## Threat Review

No runtime trust surface changed. Plan parsing and fixtures remain test-only; configured-certificate trust, the single Saxy parse path, raw-input guards, genuine digest/signature verification, audit co-commit, replay protection, and all behavior seams remain untouched. No remote GitHub mutation occurred.

## User Setup Required

None.

## Next Phase Readiness

- Phase 74 can rely on executable scope, requirement-ownership, and deterministic-evidence governance for every new plan.
- Phase 77 still owns the archival-vocabulary false positive and fixture-pattern warnings.
- The Phoenix `1.8.7` advisories need dependency-upgrade ownership before the milestone can claim a green security gate; no upgrade was attempted in this test-only plan.

## Self-Check: PASSED

All implementation/planning files and all six task/deviation commits were found. `git diff --check` reports no whitespace errors.

---
*Phase: 73-twin-contract-and-baseline*
*Completed: 2026-09-09*
