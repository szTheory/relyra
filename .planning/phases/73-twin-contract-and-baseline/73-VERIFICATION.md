---
phase: 73-twin-contract-and-baseline
verified: 2026-09-10T22:02:42Z
status: gaps_found
score: 6/9 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 6/9
  gaps_closed:
    - "The ci.evidence alias now applies include/exclude filters to each registered owner and rejects an empty effective selection."
    - "Positive workflow paths are rejected and paths-ignore is checked against fixed and Git-discovered governed inputs."
    - "All ten accepted branch-protection fields are retained and non-declared controls are fixed to exact safe invariants."
    - "Validation no longer launches the plan-selected mutation script."
    - "Pre-boundary exact-scope commits are Git-derived, with manifest and SUMMARY data used only as equality audits."
  gaps_remaining:
    - "CR-06: valid event filters can suppress the mandatory evidence workflow."
    - "CR-07: unrelated static JSON can authorize arbitrary indexed mutation script behavior."
    - "CR-08: same-plan commits after the SUMMARY boundary bypass changed-surface review."
  regressions: []
decision_coverage:
  honored: 13
  total: 13
  not_honored: []
gaps:
  - truth: "Automated policy checks prevent new acceptance criteria from being closed without a mandatory deterministic owner."
    status: failed
    reason: "The workflow validator accepts trigger configurations that do not run for the required event set: push.branches is checked only for membership of main, so ordered patterns such as [main, '!main'] pass validation while excluding main, and pull_request.types is not parsed at all."
    artifacts:
      - path: "test/support/adoption_evidence.ex"
        issue: "required_planning_triggers!/2 validates path filters but does not enforce a closed push/pull_request event schema or effective ordered branch/activity coverage."
      - path: "test/adoption/evidence_contract_test.exs"
        issue: "No active regression rejects ordered negative push branch filters, restrictive pull_request activity types, duplicate event keys, or unsupported event-level filters."
    missing:
      - "Parse a closed event schema for both required events."
      - "Require push to target main effectively and reject negated/additional branches and branches-ignore."
      - "For pull_request, forbid types or require opened, reopened, and synchronize; reject duplicate and unsupported event keys."
      - "Add deterministic adversarial tests for each bypass to mix ci.evidence."
  - truth: "Plans and execution stop at named checkpoints for governed changes and exclude speculative protocol work."
    status: failed
    reason: "Remote script authorization proves only indexed script identity plus an unrelated plan-authored result file, and completed-plan provenance inspects only the SUMMARY boundary's ancestry. Arbitrary script behavior and same-plan descendant commits can therefore evade the governed changed-surface/approval decision."
    artifacts:
      - path: "test/governance/milestone_scope_test.exs"
        issue: "parse_script_operation/5 discards indexed_oid after a working-tree check and never binds script behavior to result_source; trusted_plan_commits/3 logs only boundary ancestry and never considers exact-scope descendants through a governed review endpoint."
    missing:
      - "Prefer declarative gh api --input operations, or pin the exact script blob OID in the approved batch and require an independently trusted attestation binding that OID to the normalized result."
      - "Define a governed review endpoint and include or reject every exact-scope descendant after SUMMARY creation through that endpoint."
      - "Add deterministic failures for arbitrary script/result pairings and risky same-plan post-SUMMARY commits."
  - truth: "Remote GitHub approval requires one exact reversible batch whose operations implement the complete approved current and desired state."
    status: failed
    reason: "The complete branch-protection JSON shape is now compared, but a script-backed operation is still authorized from an executable's identity and a separate static result that need not be produced or implemented by that executable. The active test deliberately stages write/credential/network scripts with the benign result and asserts zero violations."
    artifacts:
      - path: "test/governance/milestone_scope_test.exs"
        issue: "The plan_73_13_task_2 non-execution test proves only that validation does not launch the script; it affirmatively accepts malicious indexed scripts paired with unchanged predicted-protection.json."
      - path: ".planning/phases/73-twin-contract-and-baseline/73-SECURITY.md"
        issue: "threats_open: 0 and closed T-73-47/T-73-49 do not account for CR-06 through CR-08; T-73-50 understates the continuing script-authorization defect as medium despite the current critical authorization bypass."
    missing:
      - "Remove script-backed mutation authorization or establish a trusted immutable binding from the approved script blob to its complete normalized effect."
      - "Update SECURITY.md to register and disposition CR-06, CR-07, and CR-08 at their observed blocking severity; threats_open cannot remain zero while they are unresolved."
deferred:
  - truth: "The repository-wide warnings-as-errors suite is green despite legacy human-verification vocabulary in Phase 73 planning artifacts."
    addressed_in: "Phase 77"
    evidence: "Phase 77 success criterion 2 owns stale phase/plan/UAT/GSD narration cleanup; baseline finding QUAL-73-006 records the known assertion."
---

# Phase 73: Twin Contract and Baseline Verification Report

**Phase Goal:** A maintainer can see exactly which adopter jobs v1.11 proves, where each proof runs, what the current quality/CI baseline is, and which changes require approval.
**Verified:** 2026-09-10T22:02:42Z
**Status:** gaps_found
**Re-verification:** Yes — after gap-closure Plans 73-12 and 73-13 and review findings CR-06 through CR-08

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A machine-checked ledger maps every in-scope persona and lifecycle outcome to a named job, outcome, evidence class, owner, selector, lane, and planned/existing state. | ✓ VERIFIED | The literal registry remains substantive and wired; the fresh mandatory lane exercised its schema/coverage owner. |
| 2 | The repository has a dated severity-ranked baseline for correctness, security, integration, readability, documentation, artifacts, and CI cost/duplication. | ✓ VERIFIED | `73-BASELINE.md` retains the dated findings ledger, five severities, seven quality categories, and CI before-snapshot. |
| 3 | Automated policy checks prevent new acceptance criteria from closing without a mandatory deterministic owner. | ✗ FAILED — BLOCKER | CR-06: event semantics outside path filters are not closed; valid ordered branch or PR activity filters can suppress the required lane while repository validation accepts it. |
| 4 | Plans and execution stop at named checkpoints before public API, default, security, SemVer-major, or remote GitHub mutation and exclude speculative protocol work. | ✗ FAILED — BLOCKER | CR-07 and CR-08 allow unbound executable behavior and post-SUMMARY exact-scope commits to evade the complete governed surface. |
| 5 | Planned and external-canary rows remain visible but cannot themselves close a completed requirement. | ✓ VERIFIED | Deterministic-owner filtering and active negative tests still exclude planned/canary-only closure. |
| 6 | Planning-only changes run the evidence contract through the current required security workflow. | ✓ VERIFIED (current file) | The checked-in workflow currently has only `prompts/**` path ignores and an enabled blocking Evidence contract step. This does not cure CR-06's fail-open validator. |
| 7 | Every current baseline finding names evidence, disposition, owner, target phase, approval class, blocker state, and revisit date. | ✓ VERIFIED | The ten-row inventory remains structurally populated and is exercised by the governance owner. |
| 8 | The baseline shape and each finding's reproducible evidence are machine-checked by `ci.evidence`. | ✓ VERIFIED | Fresh `mix ci.evidence` completed 82 tests with zero failures. |
| 9 | Remote GitHub approval requires one exact reversible batch whose operations implement the complete approved state. | ✗ FAILED — BLOCKER | CR-07: the static result is not causally or cryptographically bound to the indexed script; the current malicious-script fixture is authorized. |

**Score:** 6/9 truths verified (0 present, behavior-unverified)

### Roadmap Success Criteria

| # | Roadmap Contract | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Ledger maps every in-scope persona and lifecycle outcome to deterministic evidence or a scheduled canary. | ✓ VERIFIED | Literal ledger coverage and state separation remain active in the owner lane. |
| 2 | Severity-ranked quality and CI baseline covers all required dimensions. | ✓ VERIFIED | The committed dated baseline remains substantive and machine-checked. |
| 3 | Policy prevents acceptance closure without a mandatory deterministic owner. | ✗ FAILED — BLOCKER | CR-06 leaves required event branch/activity semantics bypassable. |
| 4 | Plans stop for governed changes and exclude speculative protocol work. | ✗ FAILED — BLOCKER | CR-07 and CR-08 leave executable behavior and descendant commits outside complete authorization review. |

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `test/support/adoption_evidence.ex` | Literal ledger and fail-closed deterministic-owner chain | ✗ PARTIAL / BLOCKER | Exists (1,115 lines), substantive, exported validators are called. Alias/path closures landed, but event semantics remain incomplete at lines 850-873. |
| `test/adoption/evidence_contract_test.exs` | Adversarial ledger/owner/workflow contract | ⚠ PARTIAL | Exists (1,047 lines), substantive, active in `ci.evidence`; lacks CR-06 branch/activity controls. |
| `.planning/phases/73-twin-contract-and-baseline/73-BASELINE.md` | Dated quality and CI inventory | ✓ VERIFIED | Exists (53 lines), substantive, and consumed by the governance contract. |
| `test/governance/milestone_scope_test.exs` | Baseline, approval, scope, provenance, and remote policy | ✗ PARTIAL / BLOCKER | Exists (4,109 lines), substantive, active in `ci.evidence`; CR-07 is encoded as an accepted control and CR-08 is absent. |
| `mix.exs` | Focused fresh-process `ci.evidence` alias | ✓ VERIFIED | The alias owns both Phase 73 contract modules with warnings as errors and non-empty effective selection. |
| `.github/workflows/security-gates.yml` | Mandatory planning-aware Evidence contract step | ✓ VERIFIED CURRENT ARTIFACT | Current workflow is enabled/blocking and `actionlint` passes; the validator does not guarantee equivalent future trigger semantics. |
| `73-SECURITY.md` | Current threat disposition consistent with code/review evidence | ✗ STALE / BLOCKER | Claims `threats_open: 0`, but omits three current critical findings and classifies the continuing script seam below the observed severity. |

The generic artifact query reports Elixir `def` exports as missing and conceptual links as missing file paths; direct source inspection is authoritative here.

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Evidence registry | Registered ExUnit owners | Parsed `ci.evidence` command and effective include/exclude selection | ✓ WIRED | Plan 73-12 closes the former empty-effective-owner gap. |
| Required workflow events | Evidence contract lane | Push/PR trigger semantics | ✗ NOT FAIL-CLOSED | Path coverage is checked, but ordered branches and PR activity types are not. |
| Remote script operation | Declared desired state | Indexed executable plus static result | ✗ DISCONNECTED SEMANTICS | Script identity and result provenance are checked independently; no evidence proves the executable implements the result. |
| Completed plan | Changed-surface classes | Git exact-scope commit derivation | ✗ PARTIAL | Derivation ends at the SUMMARY-add boundary and ignores later same-plan commits through review HEAD. |
| Governance contract | Baseline | Anchored table and provenance checks | ✓ WIRED | Baseline data flows into structural and evidence checks. |

### Data-Flow Trace (Level 4)

Not applicable to rendered data. This phase produces test-only registries, Markdown inventories, and CI/governance policy. The relevant authority flows are traced in Key Link Verification.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Complete mandatory evidence lane | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.1 mix ci.evidence` | 82 tests, 0 failures, 179.4s | ✓ PASS, but insufficient against uncovered bypasses |
| Script authorization controls | `... mix test test/governance/milestone_scope_test.exs --only plan_73_13_task_2 --warnings-as-errors` | 2 tests, 0 failures; source at lines 522-528 authorizes write/credential/network scripts | ✗ FAIL AS SECURITY PROOF |
| Workflow syntax | `actionlint .github/workflows/security-gates.yml` | Exit 0 | ✓ PASS |
| Patch hygiene | `git diff --check` | Exit 0 | ✓ PASS |

### Probe Execution

No phase-declared or conventional `scripts/**/tests/probe-*.sh` exists. The declared executable owner, `mix ci.evidence`, was run independently above.

### Requirements Coverage

| Requirement | Source Plans | Status | Evidence |
| --- | --- | --- | --- |
| EVID-01 | 73-01, 73-06, 73-09, 73-11, 73-12 | ✓ SATISFIED | Inspectable 37-requirement/six-persona ledger with truthful planned/existing/canary states. |
| EVID-02 | 73-01, 73-04, 73-06, 73-09, 73-11, 73-12 | ✗ BLOCKED | CR-06 permits a supposedly mandatory owner not to run for required branch/activity events. |
| QUAL-01 | 73-02, 73-05, 73-08, 73-11, 73-13 | ✓ SATISFIED | Severity-ranked repository-wide inventory remains present and checked. |
| PIPE-01 | 73-02, 73-08, 73-11, 73-13 | ✓ SATISFIED | Current CI duration, duplication, ownership, cache, and failure evidence remain inspectable. |
| GOV-01 | 73-03, 73-05, 73-07, 73-08, 73-10, 73-11, 73-13 | ✗ BLOCKED | CR-07 and CR-08 allow governed effects or commits outside complete approval enforcement. |
| GOV-02 | 73-03, 73-05, 73-07, 73-10, 73-11, 73-13 | ✗ BLOCKED | CR-08 can hide a post-SUMMARY same-plan speculative/governed change from classification. |

All six Phase 73 requirement IDs exist in `REQUIREMENTS.md`, map to Phase 73, and are claimed by plans. No Phase 73 requirement is orphaned.

### Decision Coverage

The canonical non-blocking decision query reports 13/13 trackable CONTEXT decisions honored. This heuristic warning gate does not override the three observable authority failures.

### Test Quality Audit

| Test File | Linked Requirements | Active | Skipped | Circular | Assertion Level | Verdict |
| --- | --- | ---: | ---: | --- | --- | --- |
| `test/adoption/evidence_contract_test.exs` | EVID-01, EVID-02 | 32 | 0 | No | Behavioral isolated-repository mutations | BLOCKER — no CR-06 effective-event controls. |
| `test/governance/milestone_scope_test.exs` | QUAL-01, PIPE-01, GOV-01, GOV-02 | 50 | 0 | No | Behavioral plan/git/filesystem mutations | BLOCKER — CR-07's test asserts malicious script authorization succeeds; CR-08 has no descendant-commit control. |

**Disabled requirement tests:** 0. **Circular fixture generation:** 0 observed. **Missing/adverse assertions:** 3 critical authority cases.

### Anti-Patterns and Security Reconciliation

| ID | File / Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| CR-06 | `test/support/adoption_evidence.ex:850-873` | Partial GitHub event grammar | 🛑 BLOCKER | Mandatory evidence may not run for main pushes or normal PR activities. |
| CR-07 | `test/governance/milestone_scope_test.exs:522-528, 1632-1647, 3089-3103` | Unbound executable/result authorization | 🛑 BLOCKER | Arbitrary indexed code is approved using unrelated benign JSON. |
| CR-08 | `test/governance/milestone_scope_test.exs:3507-3569` | Review frontier ends at SUMMARY ancestry | 🛑 BLOCKER | Later same-plan governed changes escape changed-surface review. |

No unreferenced `TBD`, `FIXME`, or `XXX` debt marker exists in phase-owned implementation files; the one `TBD` occurrence is an intentional rejected placeholder fixture.

`73-SECURITY.md` cannot support `threats_open: 0` against current evidence. Its register predates or omits CR-06 through CR-08, and T-73-50 describes the same script boundary too narrowly as a non-blocking medium side-effect concern. The observed issue is authorization of arbitrary behavior for later execution, which is a critical/high trust-boundary failure. The security verdict must be reopened until all three findings have deterministic closing evidence.

### Human Verification Required

N/A — infrastructure/governance phase with no user-facing behavior. Project policy requires deterministic automated evidence and forbids manual UAT as completion proof.

### Deferred Item Review

Only the archived vocabulary assertion is specifically owned by Phase 77. CR-06 cannot be deferred to Phase 78 because EVID-02 and roadmap criterion 3 are Phase 73 contracts. CR-07 and CR-08 cannot be deferred to Phase 79 because GOV-01/GOV-02 require the approval boundary before later remote or release work begins.

### Gaps Summary

Plans 73-12 and 73-13 close the five previously recorded reproductions, and the fresh 82-test lane is green. The phase goal is nevertheless not achieved: three adjacent authorization paths remain fail-open. Required CI can be filtered away through unparsed event semantics, arbitrary mutation scripts can borrow an unrelated static result, and same-plan commits after the SUMMARY boundary are outside provenance review. These block EVID-02, GOV-01, and GOV-02 and contradict the current zero-open-threat security sign-off.

---

_Verified: 2026-09-10T22:02:42Z_
_Verifier: OpenAI Codex (gsd-verifier)_
