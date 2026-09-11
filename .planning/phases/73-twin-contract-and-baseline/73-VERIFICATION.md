---
phase: 73-twin-contract-and-baseline
verified: 2026-09-11T02:19:37Z
status: gaps_found
score: 8/9 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 6/9
  gaps_closed:
    - "CR-06: push and pull_request now use occurrence-preserving closed event schemas; the Plan 73-14 selectors pass."
    - "CR-07: script-backed remote authorization was removed; complete tracked gh api --input payloads are now the only mutation and rollback grammar."
    - "CR-08: completed-plan provenance now includes every reachable exact-scope descendant through the full HEAD review endpoint."
  gaps_remaining: []
  regressions:
    - "The mandatory ci.evidence owner is nondeterministic: the Nyquist audit observed two unchanged 60-second test timeouts and one 220-second pass; this re-verification passed in 229.0 seconds."
    - "The workflow path matcher implements custom question-mark semantics that diverge from GitHub Actions and can accept an ignore pattern that suppresses a governed planning path."
    - "Adoption evidence owner paths are accepted through symlinks because repository_path!/2 uses lexical containment plus File.regular?/1."
decision_coverage:
  honored: 13
  total: 13
  not_honored: []
gaps:
  - truth: "Automated policy checks prevent new acceptance criteria from being closed without a mandatory deterministic owner."
    status: failed
    reason: "The mandatory owner lane is not deterministic under its declared ExUnit timeout. Two of three unchanged Nyquist runs timed out at 60 seconds in registered_test_tags!/2; the one audit pass took 220 seconds, and this independent run took 229.0 seconds."
    artifacts:
      - path: "test/support/adoption_evidence.ex"
        issue: "registered_test_tags!/2 launches a fresh nested Mix/BEAM process for repeated owner inspection; repository validation repeats the expensive discovery from async tests."
      - path: "test/adoption/evidence_contract_test.exs"
        issue: "The async evidence corpus repeatedly invokes full repository validation and has no bounded once-per-owner discovery snapshot."
      - path: ".planning/phases/73-twin-contract-and-baseline/73-VALIDATION.md"
        issue: "Correctly records nyquist_compliant: false and only 1/3 successful unchanged mandatory-lane attempts."
    missing:
      - "Discover registered tests once per owner per lane invocation, or build one deterministic manifest in a serialized helper process."
      - "Make mutation cases exercise pure validation against the snapshot instead of spawning nested BEAM VMs repeatedly."
      - "Add a deterministic runtime/timeout regression and make repeated unchanged mix ci.evidence runs pass within the declared timeout."
  - truth: "A workflow path filter that omits an evidence owner or governed planning input must not count as mandatory CI ownership."
    status: failed
    reason: "glob_source!/1 translates ? as one arbitrary non-slash character, while GitHub Actions path-filter semantics treat ? as zero or one occurrence of the preceding character. A pattern such as .planning/STATE.md? can suppress STATE.md on GitHub but does not match in the validator, so the validator can credit a workflow that skips governed evidence changes."
    artifacts:
      - path: "test/support/adoption_evidence.ex"
        issue: "The hand-written glob translator at glob_source!/1 is not GitHub-compatible and does not fail closed on unsupported metacharacters."
      - path: "test/adoption/evidence_contract_test.exs"
        issue: "The corpus covers .planning/STAT?.md under the custom semantics but lacks the decisive .planning/STATE.md? bypass regression."
    missing:
      - "Use GitHub-compatible path-filter matching, or reject unsupported metacharacters such as ? and + because the checked-in policy only needs prompts/**."
      - "Add a mix ci.evidence regression proving .planning/STATE.md? and adjacent unsupported patterns are rejected."
  - truth: "Named deterministic evidence owners resolve only to the declared tracked repository-local file."
    status: failed
    reason: "repository_path!/2 checks lexical containment and File.regular?/1, which follows symlinks. A declared owner can therefore resolve through an intermediate or leaf symlink, including outside the repository, while still being credited as the named owner."
    artifacts:
      - path: "test/support/adoption_evidence.ex"
        issue: "Owner validation lacks component-wise lstat checks and a git ls-files --error-unmatch proof for the lexical owner path."
      - path: "test/adoption/evidence_contract_test.exs"
        issue: "No active evidence-owner regression rejects intermediate/leaf symlinks or an untracked owner path."
    missing:
      - "Reject symlinks at every owner path component and require the relative lexical owner path to be tracked."
      - "Add intermediate-symlink, leaf-symlink, repository-escape, and untracked-owner controls to mix ci.evidence."
  - truth: "The final Phase 73 security verdict reports zero open high-threshold threats only after all blocking evidence-contract findings are closed."
    status: failed
    reason: "73-SECURITY.md says status: verified and threats_open: 0, but the later standard review establishes two current Critical evidence-contract defects. The register closes the older CR-06 through CR-08 findings but does not register or disposition mandatory-lane nondeterminism or the GitHub path-glob bypass."
    artifacts:
      - path: ".planning/phases/73-twin-contract-and-baseline/73-SECURITY.md"
        issue: "Aggregate zero-open-threat sign-off is stale relative to 73-REVIEW.md and current source evidence."
      - path: ".planning/phases/73-twin-contract-and-baseline/73-REVIEW.md"
        issue: "Records 2 Critical and 1 Warning after the Plan 73-16 security closeout."
    missing:
      - "Reopen and register the current Critical findings at their observed severity."
      - "After implementation and deterministic regression evidence, reconcile the threat rows, audit trail, sign-off, status, and threats_open count again."
deferred:
  - truth: "The repository-wide warnings-as-errors suite is green despite archival Phase 73 vocabulary in planning/reference artifacts."
    addressed_in: "Phase 77"
    evidence: "Phase 77 success criterion 2 owns stale phase/plan/UAT/GSD narration cleanup; baseline finding QUAL-73-006 records the exact known assertion."
---

# Phase 73: Twin Contract and Baseline Verification Report

**Phase Goal:** A maintainer can see exactly which adopter jobs v1.11 proves, where each proof runs, what the current quality/CI baseline is, and which changes require approval.
**Verified:** 2026-09-11T02:19:37Z
**Status:** gaps_found
**Re-verification:** Yes — after Plans 73-14 through 73-16, the final Nyquist audit, standard code review, and independent command execution

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A machine-checked ledger maps every in-scope persona and lifecycle outcome to a named job, outcome, evidence class, owner, selector, lane, and planned/existing state. | ✓ VERIFIED | `Relyra.AdoptionEvidence` retains exactly 37 requirement IDs, all six personas, closed row fields, and live owner queries. The complete 91-test contract passed once in this run. |
| 2 | The repository has a dated severity-ranked baseline for correctness, security, integration, readability, documentation, artifacts, and CI cost/duplication. | ✓ VERIFIED | `73-BASELINE.md` remains a substantive ten-finding, seven-category, five-severity inventory with a nine-surface CI snapshot. |
| 3 | Automated policy checks prevent new acceptance criteria from closing without a mandatory deterministic owner. | ✗ FAILED — BLOCKER | The owner lane is nondeterministic, its custom glob grammar can miss a GitHub-effective ignore, and owner paths can resolve through symlinks. EVID-02 is not achieved. |
| 4 | Plans and execution stop at named checkpoints before governed public API/default/security/SemVer-major/remote changes and exclude speculative protocol work. | ✓ VERIFIED | Plan 73-15 removed script authorization and extended Git-derived changed-surface review through exact HEAD. Both focused selectors pass. |
| 5 | Planned and external-canary rows remain visible but cannot themselves close a completed requirement. | ✓ VERIFIED | Closed-state filtering and canary/planned negative controls remain active in the adoption contract. |
| 6 | Planning-only changes run the evidence contract through the checked-in required security workflow. | ✓ VERIFIED (current workflow) | The tracked workflow has pull_request plus push-to-main, ignores only `prompts/**`, and has an unconditional non-fallible `Evidence contract` step. This does not cure the validator's future `?`-pattern bypass. |
| 7 | Every current baseline finding names evidence, disposition, owner, target phase, approval class, blocker state, and revisit date. | ✓ VERIFIED | The baseline contract parses and checks every lifecycle field and redaction-safe evidence marker. |
| 8 | The baseline shape and each finding's reproducible evidence are machine-checked by `ci.evidence`. | ✓ VERIFIED | The governance owner is included in the actual one-step fresh-process alias; the 91-test lane completed with zero failures, albeit too slowly and nondeterministically for EVID-02. |
| 9 | Remote GitHub approval requires one exact reversible batch whose operations implement the complete approved state. | ✓ VERIFIED | Only tracked declarative `gh api --input` mutation/rollback payloads remain; Plan 73-15 Task 1 passes 2 tests and script/result pairings are rejected. |

**Score:** 8/9 truths verified (0 present, behavior-unverified)

### Roadmap Success Criteria

| # | Roadmap Contract | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Ledger maps every in-scope persona and lifecycle outcome to deterministic evidence or a scheduled canary. | ✓ VERIFIED | Literal registry, six-persona coverage, and planned/existing/canary separation remain present and exercised. |
| 2 | Severity-ranked quality and CI baseline covers all required dimensions. | ✓ VERIFIED | Dated baseline and structural owner remain intact. |
| 3 | Policy prevents acceptance closure without a mandatory deterministic owner. | ✗ FAILED — BLOCKER | The 1/3 Nyquist success rate, 229-second independent pass, GitHub `?` mismatch, and symlink-following owner path invalidate mandatory deterministic ownership. |
| 4 | Plans stop for governed changes and exclude speculative protocol work. | ✓ VERIFIED | CR-07/CR-08 repairs are substantive, wired, and exercised by passing Plan 73-15 selectors. |

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `test/support/adoption_evidence.ex` | Literal ledger and fail-closed deterministic-owner chain | ✗ PARTIAL / BLOCKER | Exists (1,176 lines), substantive, and exported validators are used. `registered_test_tags!/2`, `repository_path!/2`, and `glob_source!/1` contain the three open owner defects. |
| `test/adoption/evidence_contract_test.exs` | Adversarial ledger/owner/workflow contract | ✗ PARTIAL / BLOCKER | Exists (1,247 lines), substantive, and selected by `ci.evidence`; it lacks timeout/cached-discovery, `.planning/STATE.md?`, and owner-symlink regressions. |
| `.planning/phases/73-twin-contract-and-baseline/73-BASELINE.md` | Dated quality and CI inventory | ✓ VERIFIED | Exists (53 lines), populated, and consumed by the governance contract. |
| `test/governance/milestone_scope_test.exs` | Baseline, approval, scope, provenance, and remote policy | ✓ VERIFIED | Exists (4,113 lines); Plan 73-15 selectors independently pass and the CR-07/CR-08 links are present. |
| `mix.exs` | Focused fresh-process `ci.evidence` alias | ⚠ WIRED BUT UNRELIABLE | One `cmd mix test` owns both contract files with `--only evidence_contract --warnings-as-errors`; execution is non-empty but repeatedly exceeds the default test timeout. |
| `.github/workflows/security-gates.yml` | Mandatory planning-aware Evidence contract step | ✓ VERIFIED CURRENT ARTIFACT | `actionlint` exits 0; current push/PR triggers and blocking step are correct. The repository validator can nevertheless approve a future suppressing glob. |
| `.planning/phases/73-twin-contract-and-baseline/73-SECURITY.md` | Evidence-bound high-threat disposition | ✗ STALE / BLOCKER | Exists and closes CR-06 through CR-08, but `status: verified` / `threats_open: 0` predates the two current Critical review findings. |

The generic artifact query's missing-export result for `validate_repository!/2` is a parser false negative: the public function exists at `test/support/adoption_evidence.ex:322`. Conceptual key links in Plans 73-14 through 73-16 are likewise verified manually because their `from` values are descriptions rather than file paths.

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Ledger rows | Registered ExUnit owners | Actual Mix alias plus effective tag selection | ✗ UNRELIABLE | Wired and non-empty, but repeated nested Mix discovery makes the mandatory lane nondeterministic. |
| Workflow path policy | Governed Phase 73 inputs | Custom glob matcher | ✗ NOT FAIL-CLOSED | GitHub-effective `.planning/STATE.md?` is not modeled correctly. |
| Declared owner path | Compiled test module | Lexical expansion plus `File.regular?/1` | ✗ HOLLOW BOUNDARY | Symlink targets are followed and the lexical owner path is not proven tracked. |
| Remote batch | Desired/current branch-protection state | Declarative tracked JSON normalization | ✓ WIRED | Script alternative removed; complete payload equality and rollback checks remain active. |
| SUMMARY boundary | HEAD review endpoint | Git-derived pre-boundary plus descendant commits | ✓ WIRED | All reachable exact-scope descendants enter changed-surface classification. |
| Governance contract | Baseline | Anchored table and evidence checks | ✓ WIRED | Baseline fields and evidence markers flow into executable validation. |

### Data-Flow Trace (Level 4)

Not applicable to rendered data. This phase produces test-only registries, Markdown inventories, and CI/governance policy. Authority flow is covered in Key Link Verification.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| CR-06 push grammar | `mix test test/adoption/evidence_contract_test.exs --only plan_73_14_task_1 --warnings-as-errors` | 3 tests, 0 failures | ✓ PASS |
| CR-06 pull-request grammar | `mix test test/adoption/evidence_contract_test.exs --only plan_73_14_task_2 --warnings-as-errors` | 3 tests, 0 failures | ✓ PASS |
| CR-07 declarative authorization | `mix test test/governance/milestone_scope_test.exs --only plan_73_15_task_1 --warnings-as-errors` | 2 tests, 0 failures in isolated rerun | ✓ PASS |
| CR-08 endpoint-complete provenance | `mix test test/governance/milestone_scope_test.exs --only plan_73_15_task_2 --warnings-as-errors` | 3 tests, 0 failures | ✓ PASS |
| Mandatory Phase 73 evidence lane | `mix ci.evidence` | 91 tests, 0 failures in 229.0 seconds; Nyquist audit separately observed two 60-second timeouts and one 220-second pass | ✗ FAIL DETERMINISM CONTRACT |
| Security lane | `mix ci.security` | Exit 0; fresh security suites and dependency audit passed | ✓ PASS |
| Workflow syntax | `actionlint .github/workflows/security-gates.yml` | Exit 0 | ✓ PASS |

One parallel focused invocation encountered a PostgreSQL schema-migration race; the exact Plan 73-15 Task 1 selector passed immediately when rerun alone. It is not counted as a Phase 73 governance failure.

### Probe Execution

No phase-declared or conventional `scripts/**/tests/probe-*.sh` exists. The declared executable owner is `mix ci.evidence`, run independently above.

### Requirements Coverage

| Requirement | Source Plans | Status | Evidence |
| --- | --- | --- | --- |
| EVID-01 | 73-01, 06, 09, 11, 12, 14 | ✓ SATISFIED | Inspectable 37-requirement/six-persona ledger with truthful planned/existing/canary states. |
| EVID-02 | 73-01, 04, 06, 09, 11, 12, 14, 16 | ✗ BLOCKED | Mandatory deterministic ownership fails on repeated timeouts, GitHub path semantics, and symlink-resolved owners. |
| QUAL-01 | 73-02, 05, 08, 11, 13, 15 | ✓ SATISFIED | Severity-ranked repository inventory is present, populated, and machine-checked. |
| PIPE-01 | 73-02, 08, 11, 13, 15 | ✓ SATISFIED | Current CI topology, sampled duration, duplication, cache, ownership, drift, and failure evidence are inspectable. |
| GOV-01 | 73-03, 05, 07, 08, 10, 11, 13, 15, 16 | ✓ SATISFIED | Declarative-only remote operations and full-HEAD exact-scope provenance close the prior authorization gaps. |
| GOV-02 | 73-03, 05, 07, 10, 11, 13, 15, 16 | ✓ SATISFIED | Current plan identity, requirement membership, demand-gated exclusions, and descendant classification remain enforced. |

All six Phase 73 requirement IDs exist in `REQUIREMENTS.md`, map to Phase 73, and are claimed by plans. No Phase 73 requirement is orphaned.

### Plan Must-Haves and Prohibitions

| Plans | Regression Result | Prohibition Result |
| --- | --- | --- |
| 73-01 through 73-13 | Core ledger, baseline, command, approval, remote-state, and provenance behaviors remain present; the 91-test lane reaches both owners. | Most negative controls remain active. The broad named-owner prohibition (73-01), path/symlink provenance prohibition (73-08), and path-filter prohibition (73-09) fail on the current review findings. |
| 73-14 | Both focused selectors pass; closed push/PR event keys and activity/branch rules exist. | The duplicate/unsupported-event prohibition is verified. The syntactically-valid-filter prohibition is failed because the downstream custom path glob grammar diverges on `?`. |
| 73-15 | Both focused selectors pass; script authorization is absent and exact-HEAD descendants are classified. | Both script/result and post-SUMMARY prohibitions are verified. |
| 73-16 | Security report retains T-73-12 and cites passing 73-14/15 owners. | The no-false-zero prohibition is failed: the report claims zero open blocking threats despite the later Critical findings. The lower-severity preservation prohibition is verified. |

All 37 plan prohibitions were reviewed against source and active controls. Five are failed as identified above; no prohibition is routed to human review because project policy requires deterministic automated enforcement.

### Decision Coverage

The canonical non-blocking decision query reports 13/13 trackable CONTEXT decisions honored. This heuristic does not override the observable EVID-02 failures.

### Test Quality Audit

| Test File | Linked Requirements | Active | Skipped | Circular | Assertion Level | Verdict |
| --- | --- | ---: | ---: | --- | --- | --- |
| `test/adoption/evidence_contract_test.exs` | EVID-01, EVID-02 | 38 | 0 | No | Behavioral isolated-repository mutations | BLOCKER — expensive discovery is repeated; decisive GitHub `?` and owner-symlink cases are absent. |
| `test/governance/milestone_scope_test.exs` | QUAL-01, PIPE-01, GOV-01, GOV-02 | 53 | 0 | No | Behavioral plan/Git/filesystem mutations | PASS for CR-07/CR-08 and baseline/governance ownership. |

**Disabled requirement tests:** 0. **Circular fixture generation:** 0 observed. **Insufficient/adverse owner cases:** 3.

The Nyquist artifact covers 16/16 plans and 34/34 acceptance-bearing tasks, but correctly leaves `nyquist_compliant: false` because deterministic execution is part of the contract, not merely test enumeration.

### Anti-Patterns and Security Reconciliation

| ID | File / Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| CR-01 | `test/support/adoption_evidence.ex:425-479` | Repeated nested Mix/BEAM discovery from async validation | 🛑 BLOCKER | Required evidence times out without source changes. |
| CR-02 | `test/support/adoption_evidence.ex:1111-1158` | Hand-written GitHub glob semantics | 🛑 BLOCKER | A governed planning-only change can skip the workflow while validation passes. |
| WR-01 | `test/support/adoption_evidence.ex:642-650` | Lexical containment plus symlink-following regular-file check | 🛑 BLOCKER under EVID-02 | The declared repository-local owner identity is not enforced. |
| SEC-STALE | `73-SECURITY.md` | Zero-open-threat sign-off predates current Critical findings | 🛑 BLOCKER | Security status contradicts the latest code/review evidence. |

No unreferenced `TBD`, `FIXME`, or `XXX` marker exists in phase-owned implementation files. Placeholder values occur only in deliberate negative fixtures.

### Full-Suite Context

The exact-seed full suite retains the documented Phase 77 archival-vocabulary assertion. It is deferred below because the later roadmap explicitly owns stale planning narration. One unrelated concurrent LoginTrace ETS race was observed in a broad run and passed 3/3 immediately in isolation; the standard review excludes it from Phase 73 findings, so it is recorded as context rather than a phase gap.

### Human Verification Required

N/A — this is an infrastructure/governance phase. Project policy forbids manual-only completion gates; observable automation failures are gaps, not `human_needed` items.

### Deferred Item Review

Only the archival vocabulary assertion is specifically owned by Phase 77. The mandatory-lane runtime, path-matching, owner-path, and stale-security gaps are not deferred to Phase 77 or Phase 78: EVID-02 and the Plan 73 owner/security prohibitions require those properties before Phase 73 can close.

### Gaps Summary

The previous CR-06, CR-07, and CR-08 gaps are closed, and all four focused gap-closure selectors plus `mix ci.security` pass. The phase still cannot pass. Its mandatory evidence lane is nondeterministic (two audited 60-second failures; 220/229-second passes), the custom workflow glob matcher can approve a GitHub-effective governed-path ignore, and declared test owners may resolve through symlinks. Because the security report was sealed before these findings, its `verified` / zero-open-threat state is also stale. These failures block EVID-02 and roadmap success criterion 3.

**Next command:** `$gsd-plan-phase 73 --gaps`

---

_Verified: 2026-09-11T02:19:37Z_
_Verifier: OpenAI Codex (gsd-verifier)_
