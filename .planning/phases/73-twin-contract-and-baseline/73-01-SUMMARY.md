---
phase: 73-twin-contract-and-baseline
plan: 01
subsystem: testing
tags: [elixir, exunit, evidence-ledger, ci-contract, github-actions]
requires:
  - phase: 72.1-keycloak-verification-closure
    provides: verified v1.10 baseline and existing required security workflow
provides:
  - Literal v1.11 adoption evidence registry covering all 37 requirements and six personas
  - Fail-closed deterministic owner, selector, alias, and workflow validation
  - Focused ci.evidence alias in the mandatory security workflow for source and planning changes
affects: [74-packaged-consumer, 75-saas-digital-twin, 76-lifecycle-journeys, 78-ci-quality]
actuals:
  tokens: 7023
  tasks: 2
  commits: 4
tech-stack:
  added: []
  patterns: [literal test-support registry, AST-inspected Mix alias, fresh-process CI owner]
key-files:
  created: [test/support/adoption_evidence.ex, test/adoption/evidence_contract_test.exs]
  modified: [mix.exs, .github/workflows/security-gates.yml]
key-decisions:
  - "Use a closed, test-only Elixir ledger whose planned rows remain visible but cannot satisfy deterministic closure."
  - "Treat only existing non-canary rows with a real tagged test, fresh-process alias, and executable workflow command as closure evidence."
patterns-established:
  - "Evidence ownership chain: requirement row -> existing owner file -> non-empty ExUnit tag -> fresh-process Mix alias -> mandatory workflow step."
  - "Closure queries preserve declaration order for reporting while membership remains permutation-invariant."
requirements-completed: [EVID-01, EVID-02]
coverage:
  - id: D1
    description: "Machine-checked ledger maps every active v1.11 requirement and all six adopter personas to owned evidence."
    requirement: EVID-01
    verification:
      - kind: integration
        ref: "test/adoption/evidence_contract_test.exs#tracer resolves EVID-01 from literal ledger through a real selector and mandatory CI"
        status: pass
    human_judgment: false
  - id: D2
    description: "Malformed, hollow, planned-only, and canary-only evidence cannot close a requirement."
    requirement: EVID-02
    verification:
      - kind: integration
        ref: "ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix ci.evidence"
        status: pass
      - kind: other
        ref: "actionlint .github/workflows/security-gates.yml"
        status: pass
    human_judgment: false
duration: 9min
completed: 2026-09-09
status: complete
---

# Phase 73 Plan 01: Adoption Evidence Contract Summary

**Literal v1.11 evidence ownership with fail-closed closure checks, a fresh-process Mix alias, and mandatory planning-aware CI wiring**

## Performance

- **Duration:** 9 min
- **Started:** 2026-09-09T17:33:25Z
- **Completed:** 2026-09-09T17:42:17Z
- **Tasks:** 2
- **Files modified:** 4 implementation files

## Accomplishments

- Added a closed-vocabulary ledger covering exactly 37 active requirements and evaluator, developer, tenant-admin, security-reviewer, SRE, and end-user personas.
- Enforced deterministic closure through real owner-file presence, non-zero ExUnit tag selection, AST-inspected fresh-process alias ownership, and an executable required-workflow command.
- Added characterization coverage for null, empty, singleton, duplicate, reordered, canary-only, missing-owner, zero-match-selector, unwired-alias, and absent-workflow states.
- Removed only the `.planning/**` workflow exclusion while preserving `prompts/**`, the security matrix, existing security steps, and the independent GATE-02 defense.

## Task Commits

1. **Task 1 RED: Define failing adoption evidence tracer** — `fd93f59` (test)
2. **Task 1 GREEN: Wire adoption evidence tracer** — `e3c68fd` (feat)
3. **Task 2 RED: Characterize evidence boundary failures** — `0d2448e` (test)
4. **Task 2 GREEN: Enforce deterministic evidence closure** — `bfd8a4a` (feat)

## Files Created/Modified

- `test/support/adoption_evidence.ex` — Literal registry, schema validation, deterministic closure queries, and repository-chain validation.
- `test/adoption/evidence_contract_test.exs` — Positive tracer and fail-closed boundary characterization.
- `mix.exs` — Test preferred environment and one-step fresh-process `ci.evidence` alias.
- `.github/workflows/security-gates.yml` — Mandatory Evidence contract step and planning-aware triggers.

## Decisions Made

- Kept all later-milestone evidence rows explicitly `:planned`; only EVID-01 and EVID-02 name currently executable owners.
- Used an exact ExUnit module tag as the selector so a non-empty string cannot masquerade as a test match.
- Kept external canaries inspectable as an evidence class while excluding them from deterministic closure even when marked `:existing`.

## Deviations from Plan

None - plan implementation executed exactly as written.

## Issues Encountered

- The plan-owned `mix ci.evidence` and `actionlint` checks pass.
- Repository-wide `mix qa` completed with two out-of-scope failures: the existing incomplete-phase documentation vocabulary policy rejects pre-existing Phase 73 planning artifacts, and one concurrent LiveView security test lost its endpoint ETS table. The latter passed immediately in isolation (3 tests, 0 failures). Both are recorded in `deferred-items.md`; no unrelated code was changed.

## Known Stubs

None. Planned ledger rows are intentional evidence-state declarations, not runtime or UI stubs, and validation prevents them from closing requirements.

## Threat Review

No new runtime trust surface was introduced. The changes are test-only evidence metadata and existing CI workflow wiring; configured-certificate trust, XML parsing, cryptographic verification, audit transactions, and replay protection remain unchanged.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Later twin and packaged-consumer plans can add `:existing` rows only after supplying an executable owner/tag/alias/workflow chain. The pre-existing full-QA documentation-policy failure remains for its owning governance work.

## Self-Check: PASSED

All four implementation files, the summary, and all four TDD task commits were found.

---
*Phase: 73-twin-contract-and-baseline*
*Completed: 2026-09-09*
