---
phase: 73-twin-contract-and-baseline
verified: 2026-09-11T05:15:20Z
status: gaps_found
score: 8/9 must-haves verified
covered_files:
  - ".github/workflows/security-gates.yml"
  - ".planning/REQUIREMENTS.md"
  - ".planning/ROADMAP.md"
  - ".planning/STATE.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-01-PLAN.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-01-SUMMARY.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-02-PLAN.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-02-SUMMARY.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-03-PLAN.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-03-SUMMARY.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-04-PLAN.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-04-SUMMARY.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-05-PLAN.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-05-SUMMARY.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-06-PLAN.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-06-SUMMARY.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-07-PLAN.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-07-SUMMARY.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-08-PLAN.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-08-SUMMARY.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-09-PLAN.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-09-SUMMARY.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-10-PLAN.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-10-SUMMARY.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-11-PLAN.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-11-SUMMARY.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-12-PLAN.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-12-SUMMARY.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-13-PLAN.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-13-SUMMARY.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-14-PLAN.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-14-SUMMARY.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-15-PLAN.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-15-SUMMARY.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-16-PLAN.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-16-SUMMARY.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-17-PLAN.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-17-SUMMARY.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-18-PLAN.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-18-SUMMARY.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-19-PLAN.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-19-SUMMARY.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-BASELINE.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-CONTEXT.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-REVIEW.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-SECURITY.md"
  - ".planning/phases/73-twin-contract-and-baseline/73-VALIDATION.md"
  - "mix.exs"
  - "test/adoption/evidence_contract_test.exs"
  - "test/governance/milestone_scope_test.exs"
  - "test/support/adoption_evidence.ex"
covered_digest: "v1:sha256:9a5e7b5bb9bc9a352c8ac5a914224e552f639fcc4d7a7a4f5674e13cafd5b73f"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 8/9
  gaps_closed:
    - "The closed workflow path grammar now rejects unsupported metacharacters before coverage comparison."
    - "Evidence-owner provenance now rejects symlinks, lexical escapes, absolute paths, and untracked files before discovery."
  gaps_remaining:
    - "Mandatory deterministic ownership is still not established: ci.evidence is red in ready_for_verification, the cache lock is caller-specific, and governed_inputs can be substituted."
    - "The Phase 73 security verdict is stale relative to the later Critical review finding and current red mandatory lane."
  regressions:
    - "After STATE moved to ready_for_verification, parse_state_identity/1 rejects the legitimate lifecycle state and mix ci.evidence fails five governance tests."
    - "The exported pure snapshot validator accepts a substituted governed_inputs inventory such as [README.md]."
gaps:
  - truth: "Automated policy checks prevent new acceptance criteria from being closed without a mandatory deterministic owner."
    status: failed
    reason: "The mandatory evidence lane exits non-zero in ready_for_verification; its registered-test cache uses a per-caller lock that cannot serialize concurrent misses; and pure snapshot validation accepts a substituted governed-input inventory."
    artifacts:
      - path: "test/governance/milestone_scope_test.exs"
        issue: "parse_state_identity/1 accepts only executing or in_progress, rejecting ready_for_verification and causing five current ci.evidence failures."
      - path: "test/support/adoption_evidence.ex"
        issue: "registered_test_tags!/2 locks on {cache_key, self()}; validate_snapshot_shape!/2 does not bind governed_inputs to the required normalized inventory."
      - path: "test/adoption/evidence_contract_test.exs"
        issue: "No concurrent cache-miss test proves single-flight behavior, and no omission/substitution/path-normalization mutations protect governed_inputs."
      - path: "mix.exs"
        issue: "ci.evidence is wired to both owners but currently selects 99 tests and exits non-zero with five failures."
    missing:
      - "Accept ready_for_verification as an active lifecycle state and add a regression for the checked-in state."
      - "Use a caller-independent lock identity and add a concurrency test proving one discovery for simultaneous cache misses."
      - "Bind governed_inputs to the complete normalized stable inventory and test omission, substitution, escape, absolute, and reorder mutations."
      - "Run the unchanged mandatory ci.evidence lane green after the final STATE transition."
  - truth: "The final Phase 73 security verdict reports zero open high-threshold threats only after every current blocking evidence-contract finding is closed."
    status: failed
    reason: "73-SECURITY.md was sealed before the 05:04:38Z review found a new Critical single-flight defect, and it asserts three green ci.evidence runs although the current mandatory lane fails. Its verified/threats_open: 0 state is stale."
    artifacts:
      - path: ".planning/phases/73-twin-contract-and-baseline/73-SECURITY.md"
        issue: "Closes T-73-67 using pre-transition evidence that no longer describes current source and lane state."
      - path: ".planning/phases/73-twin-contract-and-baseline/73-REVIEW.md"
        issue: "Later review records one Critical and one Warning; the Critical is absent from the closed threat chronology."
    missing:
      - "Reopen/register the current Critical single-flight finding and record the red final-state lane."
      - "After all blockers close, rerun evidence/security lanes and reconcile frontmatter, rows, audit trail, sign-off, and approval prose."
deferred:
  - truth: "The repository-wide warnings-as-errors suite is green despite archival Phase 73 vocabulary in planning/reference artifacts."
    addressed_in: "Phase 77"
    evidence: "Phase 77 owns stale phase/plan/UAT/GSD narration cleanup; QUAL-73-006 records the archival-vocabulary failure."
advisory: []
---

# Phase 73: Twin Contract and Baseline Verification Report

**Phase Goal:** Maintainers can inspect exactly which adopter journeys exist, where their deterministic proof runs, what the current quality/CI baseline is, and which changes require approval before Phase 74 begins.
**Verified:** 2026-09-11T05:15:20Z
**Status:** gaps_found
**Re-verification:** Yes — after gap-closure Plans 73-17 through 73-19

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A machine-checked ledger maps every in-scope persona and lifecycle outcome to a named job, outcome, evidence class, owner, selector, lane, and state. | ✓ VERIFIED | Live registry: 42 rows, 37 active requirement IDs, all six personas. `plan_73_17_task_1` passed 3 tests including the EVID-01 tracer and snapshot-owner checks. |
| 2 | The repository has a dated severity-ranked baseline for correctness, security, integration, readability, documentation, artifacts, and CI cost/duplication. | ✓ VERIFIED | `73-BASELINE.md` is a populated ten-finding, seven-category, five-severity inventory with a nine-surface CI snapshot. |
| 3 | Automated policy checks prevent new acceptance criteria from closing without a mandatory deterministic owner. | ✗ FAILED — BLOCKER | `mix ci.evidence` selects 99 tests but fails 5. The cache lock includes `self()`, and a direct probe shows `governed_inputs: ["README.md"]` is accepted. |
| 4 | Plans stop before governed API/default/security/SemVer-major/remote changes and exclude speculative protocol work. | ✓ VERIFIED | Plan 73-15 Task 1 passed 2 tests and Task 2 passed 3; exact declarative authorization and endpoint-complete provenance remain wired. |
| 5 | Planned and external-canary rows remain visible but cannot close a completed requirement. | ✓ VERIFIED | Closed-state filtering is substantive; planned/canary negative controls ran without adoption-test failures in the 99-test lane. |
| 6 | Planning-only changes run the evidence contract through the checked-in required security workflow. | ✓ VERIFIED (wiring) | Pull-request and push-to-main ignore only `prompts/**`; an unconditional `Evidence contract` step runs `mix ci.evidence`; `actionlint` exits 0. |
| 7 | Every baseline finding names evidence, disposition, owner, target phase, approval class, blocker state, and revisit date. | ✓ VERIFIED | All ten rows contain the required lifecycle fields and verification markers. |
| 8 | Baseline shape and reproducible evidence are machine-checked by `ci.evidence`. | ✓ VERIFIED | The flat alias includes the baseline/governance owner. Its baseline tests passed within the 99-test invocation; the lane's separate state-identity failures are Truth 3. |
| 9 | Remote GitHub approval requires one exact reversible batch implementing the complete approved state. | ✓ VERIFIED | Plan 73-15 Task 1 passed 2 tests; only tracked declarative `gh api --input` complete-state payloads cross the parser. |

**Score:** 8/9 truths verified (0 present, behavior-unverified)

### Roadmap Success Criteria

| # | Roadmap Contract | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Ledger maps each in-scope persona/outcome to deterministic evidence or scheduled canary. | ✓ VERIFIED | Literal registry, six-persona coverage, tracing, and state separation are exercised. |
| 2 | Severity-ranked quality and CI baseline covers every required dimension. | ✓ VERIFIED | Dated baseline and structural validator are substantive and wired. |
| 3 | Policy prevents closure without a mandatory deterministic owner. | ✗ FAILED — BLOCKER | Final-state lane is red, concurrent cache misses are not single-flight, and governed inputs can be substituted. |
| 4 | Plans stop for governed changes and exclude speculative protocol work. | ✓ VERIFIED | Plan 73-15 governance selectors pass 5/5 tests. |

### Deferred Items

| # | Item | Addressed In | Evidence |
| --- | --- | --- | --- |
| 1 | Repository-wide archival-vocabulary assertion | Phase 77 | Roadmap and QUAL-73-006 assign stale planning narration cleanup to Phase 77. |

### Advisory (New Scope, Unevidenced)

None. Current-state findings have deterministic source or command evidence and are gaps.

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `test/support/adoption_evidence.ex` | Ledger and deterministic-owner chain | ✗ PARTIAL / BLOCKER | Exists (1,603 lines), substantive, used; caller-specific locking and replaceable governed inputs leave EVID-02 open. |
| `test/adoption/evidence_contract_test.exs` | Adversarial owner/workflow contract | ✗ PARTIAL / BLOCKER | Exists (1,558 lines), selected by `ci.evidence`; lacks concurrent-miss and governed-input substitution regressions. |
| `test/governance/milestone_scope_test.exs` | Baseline, lifecycle, approval, scope, provenance policy | ✗ PARTIAL / BLOCKER | Exists (4,113 lines); focused approval tests pass, but final lifecycle status is rejected. |
| `73-BASELINE.md` | Dated quality/CI inventory | ✓ VERIFIED | Exists (53 lines), populated, consumed by governance tests. |
| `mix.exs` | Fresh-process `ci.evidence` alias | ✗ WIRED BUT RED | Correct one-command alias; current execution exits non-zero. |
| `.github/workflows/security-gates.yml` | Mandatory Evidence contract step | ✓ VERIFIED | Required trigger/step wiring is present; path and provenance focused tests pass. |
| `73-SECURITY.md` | Current evidence-bound threat disposition | ✗ STALE / BLOCKER | Exists (119 lines); zero-open sign-off predates current review/final-state failure. |
| `73-VALIDATION.md` | Current Nyquist inventory | ⚠ STALE | Still covers Plans 1-16 and says `nyquist_compliant: false`; current command evidence controls this verdict. |

The generic artifact query's missing-export result for `validate_repository!/2` is a parser false negative: its public definition exists at line 322. Generic key-link queries also treat descriptive `from` values as paths, so conceptual links were inspected manually.

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Ledger rows | Registered ExUnit owners | Snapshot plus effective tag selection | ✗ PARTIAL | One invocation deduplicates owners, but concurrent misses use distinct lock IDs because `self()` is included. |
| Snapshot inputs | Workflow coverage | Required-input comparison | ✗ HOLLOW | Normal capture supplies the list, but pure validation accepts and checks only a substituted list. |
| Checked-in STATE | Active governance identity | `parse_state_identity/1` | ✗ NOT WIRED FOR FINAL STATE | Only `executing`/`in_progress` are accepted; `ready_for_verification` causes five failures. |
| Owner path | Registered owner snapshot | Relative normalization, component lstat, regular leaf, exact Git tracking | ✓ WIRED | Plan 73-18 provenance tests pass 2/2. |
| Workflow filters | Governed inputs | Closed path grammar | ✓ WIRED | Plan 73-18 grammar tests pass 3/3. |
| Review | Security register | Evidence-before-disposition chronology | ✗ STALE | Review at 05:04:38Z is later; its new Critical is absent from zero-open verdict. |
| Remote batch | Desired/current state | Declarative tracked JSON normalization | ✓ WIRED | Exact-state tests pass. |

### Data-Flow Trace (Level 4)

No rendered data exists. Authority flow was traced from ledger/planning inputs through snapshot, alias, workflow, and command exit status above.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Plan 73-17 tracer/owner controls | `mix test ... --only plan_73_17_task_1` | 3 tests, 0 failures | ✓ PASS |
| Plan 73-17 pure mutation bounds | `mix test ... --only plan_73_17_task_2` | 1 test, 0 failures | ✓ PASS |
| Plan 73-18 closed path grammar | `mix test ... --only plan_73_18_task_1` | 3 tests, 0 failures | ✓ PASS |
| Plan 73-18 exact owner provenance | `mix test ... --only plan_73_18_task_2` | 2 tests, 0 failures | ✓ PASS |
| Plan 73-15 exact remote authorization | `mix test ... --only plan_73_15_task_1` | 2 tests, 0 failures | ✓ PASS |
| Plan 73-15 endpoint provenance | `mix test ... --only plan_73_15_task_2` | 3 tests, 0 failures | ✓ PASS |
| Mandatory final-state lane | `mix ci.evidence` | 99 tests, 5 failures; exit 1 in 12.2s | ✗ FAIL |
| Governed-input substitution | `MIX_ENV=test mix run -e '<capture; replace governed_inputs with README.md; validate>'` | `substituted_governed_inputs: :ok` | ✗ FAIL CLOSEDNESS |
| Security lane | `mix ci.security` | Exit 0; fresh-process suites/audits pass | ✓ PASS |
| Syntax/format | `actionlint .github/workflows/*.yml`; `mix format --check-formatted` | Both exit 0 | ✓ PASS |

### Probe Execution

No phase-declared or conventional `scripts/**/tests/probe-*.sh` exists. The declared executable owner is `mix ci.evidence`, run above.

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| EVID-01 | 73-01, 06, 09, 11, 12, 14, 17, 18 | Six-persona journey ledger | ✓ SATISFIED | 42 rows, 37 active IDs, six personas; tracer/provenance tests pass. |
| EVID-02 | 73-01, 04, 06, 09, 11, 12, 14, 16, 17, 18, 19 | Deterministic automation in mandatory CI | ✗ BLOCKED | Final-state lane red; cache not single-flight; governed inputs replaceable. |
| QUAL-01 | 73-02, 05, 08, 11, 13, 15, 16, 19 | Severity-ranked quality inventory | ✓ SATISFIED | Ten findings cover all required categories and dispositions. |
| PIPE-01 | 73-02, 08, 11, 13, 15, 16, 17, 19 | CI duration/duplication/ownership/cache/failure baseline | ✓ SATISFIED | Nine dated surfaces preserve every requested field. |
| GOV-01 | 73-03, 05, 07, 08, 10, 11, 13, 15, 16, 19 | Approval before governed mutation | ✓ SATISFIED | Focused authorization/provenance tests pass; final-state error fails closed. |
| GOV-02 | 73-03, 05, 07, 10, 11, 13, 15, 16, 19 | No speculative protocol/product expansion | ✓ SATISFIED | Exclusions and descendant classification remain tested. |

All six IDs exist in `REQUIREMENTS.md`, map to Phase 73, and are claimed by plans. None is orphaned.

### Plan 73-17 through 73-19 Must-Haves and Prohibitions

| Plan | Result | Prohibition Result |
| --- | --- | --- |
| 73-17 | ✗ PARTIAL / BLOCKER | Snapshot/pure validation exist, but caller-specific locking permits concurrent rediscovery, three final-state green runs do not exist, and no simultaneous-miss test exists. |
| 73-18 | ✓ VERIFIED | Unsupported metacharacters and symlink/untracked owner substitutions fail closed; all 5 focused tests pass. |
| 73-19 | ✗ FAILED / BLOCKER | Zero-open verdict is stale: a current Critical remains and current `mix ci.evidence` is red. |

No prohibition is routed to human review; missing or contradicted deterministic enforcement is a gap.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `test/support/adoption_evidence.ex` | 676 | `:global.trans({cache_key, self()}, ...)` | 🛑 BLOCKER | Distinct caller locks defeat single-flight misses. |
| `test/support/adoption_evidence.ex` | 482 | Weak governed-input shape validation | 🛑 BLOCKER | A substituted inventory returns `:ok`. |
| `test/governance/milestone_scope_test.exs` | 2187 | Active-state set omits `ready_for_verification` | 🛑 BLOCKER | Five mandatory checks fail after phase transition. |
| `73-SECURITY.md` | 4-5 | Verified/zero-open after later Critical | 🛑 BLOCKER | Security chronology is stale. |

No unreferenced `TBD`, `FIXME`, or `XXX` exists in phase-owned implementation files. Placeholder matches are deliberate negative fixtures.

### Human Verification Required

N/A. This phase is fully automatable; project policy forbids manual-only completion gates. Observed failures are deterministic gaps.

### Gaps Summary

Plans 73-17/18 close the focused intra-invocation discovery, path-grammar, and owner-provenance cases they test. Phase 73 still cannot close: final `ready_for_verification` state makes `mix ci.evidence` fail 5/99; caller-specific locking leaves cross-process single-flight false; pure snapshots accept substituted governed inputs; and the security report was sealed before the current Critical review and red final-state lane.

These block EVID-02 and roadmap success criterion 3. They are Phase 73 defects, not Phase 77/78 deferred work.

**Next command:** `$gsd-plan-phase 73 --gaps`

---

_Verified: 2026-09-11T05:15:20Z_
_Verifier: OpenAI Codex (gsd-verifier)_
