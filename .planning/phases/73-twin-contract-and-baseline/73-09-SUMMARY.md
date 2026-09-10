---
phase: 73-twin-contract-and-baseline
plan: 09
subsystem: testing
tags: [elixir, exunit, mix, github-actions, evidence-contract, path-filters]
requires:
  - phase: 73-twin-contract-and-baseline
    provides: literal evidence ledger and first-generation deterministic owner chain from Plans 01, 04, and 06
provides:
  - Anchored non-shell verification grammar yielding one executable and ordered argv
  - Actual Mix project alias resolution without whole-file AST tuple authority
  - Isolated ExUnit registration proof with effective include/exclude filtering
  - Closed job and step fallibility plus ordered planning-path filter evaluation
affects: [73-10-governance-provenance, 73-11-remote-authorization, 74-clean-room-package-consumer, 78-ci-quality]
actuals:
  tokens: 7676
  tasks: 2
  commits: 6
tech-stack:
  added: []
  patterns: [full-string argv grammar, Mix.Project.in_project alias resolution, isolated ExUnit registry probe, dependency-free GitHub glob evaluation]
key-files:
  created: []
  modified: [test/support/adoption_evidence.ex, test/adoption/evidence_contract_test.exs]
key-decisions:
  - "Accept verification text only when one anchored ASCII grammar fully consumes uppercase environment assignments and one supported Mix argv."
  - "Treat actual Mix project configuration and fresh-process ExUnit registration, rather than source-shaped tuples or macros, as ownership authority."
  - "Evaluate workflow fallibility and ordered path filters independently for pull requests and main pushes across every acceptance-bearing planning artifact."
patterns-established:
  - "Owner probes run Mix with an argv list, MIX_ENV=test, ExUnit autorun disabled, and safe string-normalized metadata serialization."
  - "GitHub paths use last-matching positive/negative semantics; paths-ignore rejects any pattern matching a required planning path."
requirements-completed: [EVID-01, EVID-02]
coverage:
  - id: D1
    description: "One verification command has a single non-shell argv meaning and rejects comments, redirection, expansion, quoting, globbing, escaping, and composition."
    requirement: EVID-02
    verification:
      - kind: integration
        ref: "mix test test/adoption/evidence_contract_test.exs --only plan_73_09_task_1 --warnings-as-errors (3 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Named aliases come from the actual Mix project and selectors require genuinely registered ExUnit tests after effective filters."
    requirement: EVID-02
    verification:
      - kind: integration
        ref: "mix test test/adoption/evidence_contract_test.exs --only plan_73_09_task_1 --warnings-as-errors (3 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The Evidence contract is unconditional and non-fallible at job and step scope for required pull-request and main-push planning paths."
    requirement: EVID-02
    verification:
      - kind: integration
        ref: "mix test test/adoption/evidence_contract_test.exs --only plan_73_09_task_2 --warnings-as-errors (4 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D4
    description: "The existing six-persona ledger and planned/external-canary closure boundaries remain intact."
    requirement: EVID-01
    verification:
      - kind: integration
        ref: "mix test test/adoption/evidence_contract_test.exs --warnings-as-errors (25 tests, 0 failures)"
        status: pass
    human_judgment: false
duration: 39min
completed: 2026-09-10
status: complete
---

# Phase 73 Plan 09: Deterministic Evidence Owner Chain Summary

**Anchored Mix argv ownership, actual project aliases, registered ExUnit proof, and ordered mandatory workflow path evaluation**

## Performance

- **Duration:** 39 min
- **Started:** 2026-09-10T13:51:14Z
- **Completed:** 2026-09-10T14:30:00Z
- **Tasks:** 2
- **Files modified:** 2 implementation/test files

## Accomplishments

- Replaced partial shell metacharacter rejection with a full-string grammar that accepts only uppercase environment assignments followed by one supported Mix argv.
- Replaced whole-file alias tuple scanning with the actual `Mix.Project.config()[:aliases]` resolved for the validated project root.
- Replaced syntactic `test` counting with an isolated Mix subprocess that compiles owners, reads generated ExUnit case metadata, and never executes test bodies.
- Required absent-or-literal-false fallibility at both `jobs.security` and the Evidence contract step.
- Evaluated ordered `paths` and `paths-ignore` patterns for pull requests and main pushes across ROADMAP, REQUIREMENTS, STATE, the active PLAN, and the Phase 73 baseline.

## Task Commits

1. **Task 1 RED: Add evidence-owner adversaries** — `18ac763` (test)
2. **Task 1 GREEN: Require executable evidence owners** — `dc1fb2f` (fix)
3. **Task 1 hardening: Serialize isolated test tags safely** — `fd0cd9f` (fix)
4. **Task 2 RED: Add workflow-owner adversaries** — `17f8597` (test)
5. **Task 2 GREEN: Enforce mandatory planning workflow ownership** — `88488fc` (fix)
6. **Task 2 compatibility: Preserve row-scoped workflow diagnostics** — `ad65e6b` (fix)

## Files Created/Modified

- `test/support/adoption_evidence.ex` — Anchored command-to-argv parsing, actual Mix alias resolution, isolated registered-test metadata, closed fallibility checks, and ordered GitHub path matching.
- `test/adoption/evidence_contract_test.exs` — Standalone Task 1/Task 2 tags plus shell, alias, shadow-macro, job-fallibility, event, and path-filter adversaries.

## Decisions Made

- Unsupported shell characters fail before tokenization; accepted command text is never passed to a shell.
- ExUnit metadata crosses the subprocess boundary only after atom-bearing values are normalized to safe scalar strings, booleans, numbers, or nil.
- Workflow path policy is evaluated semantically against representative artifacts instead of recognizing a small set of literal planning patterns.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Normalized isolated ExUnit metadata before safe decoding**

- **Found during:** Task 2 RED verification
- **Issue:** Fresh-process tag atoms were correctly rejected by `binary_to_term/2` safe decoding in the parent VM.
- **Fix:** Normalized tag keys and non-scalar values inside the isolated probe before encoding, retaining safe decoding without owner-controlled atom creation.
- **Files modified:** `test/support/adoption_evidence.ex`
- **Commit:** `fd0cd9f`

**2. [Rule 1 - Bug] Preserved established row-scoped step diagnostics**

- **Found during:** Overall adoption contract verification
- **Issue:** Directly raising for step fallibility bypassed the existing requirement/row diagnostic expected by legacy contract tests.
- **Fix:** Kept explicit job-level diagnostics while returning step fallibility through the owner-chain predicate and its row-scoped error.
- **Files modified:** `test/support/adoption_evidence.ex`
- **Commit:** `ad65e6b`

**3. [Rule 1 - Bug] Reconciled stale SDK plan position and progress**

- **Found during:** State and roadmap updates
- **Issue:** `state.advance-plan` advanced stale prose position 1 to 2 and `state.update-progress` could not parse the YAML progress block despite nine on-disk summaries.
- **Fix:** Reconciled STATE to 9/11 plans and 82 percent, removed duplicated phase prefixes from SDK-added decisions, recorded Plan 09 as the latest activity, and routed the operator to Plan 73-10.
- **Files modified:** `.planning/STATE.md`
- **Commit:** Final metadata commit

---

**Total deviations:** 3 auto-fixed Rule 1 bugs.
**Impact on plan:** Both fixes preserve fail-closed ownership and compatibility without changing the ledger, workflow, runtime/public API, defaults, SAML security posture, dependencies, or remote state.

## Automated Evidence

- Task 1 selector — 3 tests, 0 failures.
- Task 2 selector — 4 tests, 0 failures.
- Complete adoption evidence contract — 25 tests, 0 failures.
- `mix format --check-formatted` — passed for both modified files.
- `git diff --check` — passed.
- `mix ci.evidence` — 59 tests passed and one repository-governance test remained red because Plans 73-10 and 73-11 deliberately name selectors that do not exist until those sequential plans execute; no Plan 73-09 assertion failed.

## Issues Encountered

- The broader `ci.evidence` lane remains intentionally red between sequential gap-closure plans: the governance contract rejects the not-yet-implemented Task 73-10 and 73-11 selectors. This is owned by those plans and was not bypassed or weakened here.
- Normal commit hooks initially required the plan-mandated explicit Elixir 1.19.5/OTP 28.4.1 environment because the user-owned `.tool-versions` selects Node only. The file was preserved.

## Known Stubs

None. Empty values in the modified files are deliberate negative assertions and fail-closed guards, not runtime or UI placeholders.

## Threat Review

T-73-36 through T-73-39 are mitigated by the committed adversarial corpus and closed validators. T-73-40 remains accepted: the isolated local probe receives only repository paths and selector metadata, invokes no shell or network command, reads no credentials, and executes no test body. No unplanned network endpoint, auth path, schema, dependency, public API, default, security posture, workflow topology, or remote GitHub surface was introduced.

## TDD Gate Compliance

- Task 1 RED `18ac763` precedes GREEN `dc1fb2f`.
- Task 2 RED `17f8597` precedes GREEN `88488fc`.
- Both RED runs failed on the intended bypasses before implementation, and the focused selectors turned green afterward.

## User Setup Required

None.

## Next Phase Readiness

- Plan 73-10 can reuse the hardened command and ExUnit ownership validator while repairing governance discovery, schema selection, and completed-plan provenance.
- Plan 73-11 can complete remote authorization binding; its future selector remains correctly rejected by the mandatory lane until implemented.

## Self-Check: PASSED

Both modified contract files, this summary, and all six RED/GREEN/hardening commits were found. Fresh focused, full-contract, formatting, and diff verification produced the results recorded above.

---
*Phase: 73-twin-contract-and-baseline*
*Completed: 2026-09-10*
