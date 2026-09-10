---
phase: 73-twin-contract-and-baseline
verified: 2026-09-10T20:02:04Z
status: gaps_found
score: 6/9 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 6/9
  gaps_closed:
    - "Earlier shell-shape, selector-registration, schema-dispatch, path-provenance, and state-binding reproductions named in Plans 73-09 through 73-11 now pass their committed tests."
  gaps_remaining:
    - "Deterministic evidence ownership is hollowable through an alias with an empty effective selection and restrictive positive workflow paths."
    - "Remote authorization discards nine security-relevant branch-protection values and executes a plan-selected script with ambient CI authority."
    - "Completed-plan provenance trusts a phase manifest that may omit exact-scope commits."
  regressions: []
decision_coverage:
  honored: 13
  total: 13
  not_honored: []
gaps:
  - truth: "Automated policy checks prevent new acceptance criteria from being closed without a mandatory deterministic owner."
    status: failed
    reason: "Independent fixtures returned :ok for an alias whose --only/--exclude combination selects zero tests and for a workflow whose positive paths list includes only five planning files while excluding the ledger, owner tests, Mix alias, and workflow itself."
    artifacts:
      - path: "test/support/adoption_evidence.ex"
        issue: "validate_owner_chain!/4 uses substring checks for alias ownership, and required_planning_paths/0 samples only five planning paths."
      - path: "test/adoption/evidence_contract_test.exs"
        issue: "The 26 active tests do not cover these adjacent hollow-owner mutations."
    missing:
      - "Parse the actual alias command through the shared command validator and require each owner to remain selected after all include/exclude filters."
      - "Reject restrictive positive paths or prove coverage of every governed source and planning input."
  - truth: "Plans and execution stop at named checkpoints for governed changes and exclude speculative protocol work."
    status: failed
    reason: "Branch-protection authorization validates only strict/status contexts, executes a plan-selected tracked script during validation, and lets a phase manifest replace the Git-derived complete commit set. These seams can authorize broader protection changes, perform mutation during validation, or hide a governed commit."
    artifacts:
      - path: "test/governance/milestone_scope_test.exs"
        issue: "normalize_branch_protection_json/1 discards nine accepted values; run_script_print_mode/3 executes plan-selected code; trusted_plan_commits/3 trusts manifest membership without equality to Git discovery."
    missing:
      - "Normalize and compare every accepted branch-protection field, or enforce invariant constants for fields outside the declared state."
      - "Do not execute plan-selected mutation scripts with ambient CI authority; bind approval to static tracked data or a separately trusted sandboxed harness."
      - "Always derive the complete ordered exact-scope commit set from Git and require manifest equality as a cross-check."
  - truth: "Remote GitHub approval requires one exact reversible batch whose operations implement the complete approved current and desired state."
    status: failed
    reason: "The state comparator covers only required_status_checks.strict and contexts, so payloads may alter enforce_admins, reviews, restrictions, force pushes, deletions, branch creation, conversation resolution, locking, or fork syncing without affecting authorization. Script validation also executes the plan-selected executable rather than proving it is non-mutating."
    artifacts:
      - path: "test/governance/milestone_scope_test.exs"
        issue: "The remote state model is incomplete and the print probe crosses the non-mutating authorization boundary."
    missing:
      - "Represent and compare the complete branch-protection state."
      - "Replace ambient script execution with static provenance/result binding or a no-network, no-credentials, read-only sandbox."
deferred:
  - truth: "The repository-wide warnings-as-errors suite is green despite legacy human-verification vocabulary in Phase 73 planning artifacts."
    addressed_in: "Phase 77"
    evidence: "Phase 77 success criterion 2 owns stale phase/plan/UAT/GSD narration cleanup while preserving archived planning history; baseline finding QUAL-73-006 records the known assertion."
---

# Phase 73: Twin Contract and Baseline Verification Report

**Phase Goal:** A maintainer can see exactly which adopter jobs v1.11 proves, where each proof runs, what the current quality/CI baseline is, and which changes require approval.
**Verified:** 2026-09-10T20:02:04Z
**Status:** gaps_found
**Re-verification:** Yes — after all 11 plans and the final independent code review

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A machine-checked ledger maps every in-scope persona and lifecycle outcome to a named job, outcome, evidence class, owner, selector, lane, and planned/existing state. | ✓ VERIFIED | `entries/0` contains exactly the 37 active v1.11 requirement IDs and all six required personas; its schema/coverage tests run in `ci.evidence`. |
| 2 | The repository has a dated severity-ranked baseline for correctness, security, integration, readability, documentation, artifacts, and CI cost/duplication. | ✓ VERIFIED | `73-BASELINE.md` contains ten findings across all seven categories, the five-level severity policy, and nine dated CI snapshot surfaces. |
| 3 | Automated policy checks prevent new acceptance criteria from closing without a mandatory deterministic owner. | ✗ FAILED — BLOCKER | Isolated fixtures returned `:ok` for an alias with `--only evidence_contract --exclude evidence_contract` and for a workflow restricted to five planning files. The lane can be green while selecting no proof or not running for owner changes. |
| 4 | Plans and execution stop at named checkpoints before public API, default, security, SemVer-major, or remote GitHub mutation and exclude speculative protocol work. | ✗ FAILED — BLOCKER | The validator executes a plan-selected script, ignores most branch-protection values, and permits a manifest to omit governed phase commits. |
| 5 | Planned and external-canary rows remain visible but cannot themselves close a completed requirement. | ✓ VERIFIED | `deterministic_owners/2` excludes planned and external-canary rows; active closure tests cover both cases. |
| 6 | Planning-only changes run the evidence contract through the current required security workflow. | ✓ VERIFIED | The checked-in workflow currently ignores only `prompts/**`; PR and main-push events reach the enabled Evidence contract step, and `actionlint` exits 0. |
| 7 | Every current baseline finding names evidence, disposition, owner, target phase, approval class, blocker state, and revisit date. | ✓ VERIFIED | All ten rows retain the complete lifecycle schema and severity-specific states. |
| 8 | The baseline shape and each finding's reproducible evidence are machine-checked by `ci.evidence`. | ✓ VERIFIED | The governance contract validates anchored rows, tracked non-symlink paths, and shared executable-command provenance; its active tests pass. |
| 9 | Remote GitHub approval requires one exact reversible batch whose operations implement the complete approved state. | ✗ FAILED — BLOCKER | Only strict/status contexts survive normalization; nine accepted protection fields are discarded, and script validation executes plan-selected code with ambient authority. |

**Score:** 6/9 truths verified (0 present, behavior-unverified)

### Roadmap Success Criteria

| # | Roadmap Contract | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Ledger maps every in-scope persona and lifecycle outcome to deterministic evidence or a scheduled canary. | ✓ VERIFIED | Literal ledger coverage and planned/existing/canary separation are present and tested. |
| 2 | Severity-ranked quality and CI baseline covers all required dimensions. | ✓ VERIFIED | The dated findings ledger and CI snapshot contain the required categories and fields. |
| 3 | Policy prevents acceptance closure without a mandatory deterministic owner. | ✗ FAILED — BLOCKER | Empty-effective aliases and source-excluding positive workflow filters are accepted. |
| 4 | Plans stop for governed changes and exclude speculative protocol work. | ✗ FAILED — BLOCKER | Incomplete state comparison, ambient script execution, and manifest-selected provenance leave governed changes bypassable. |

### Deferred Item

| Item | Addressed In | Evidence |
| --- | --- | --- |
| Legacy human-verification vocabulary assertion | Phase 77 | Phase 77 owns standalone vocabulary cleanup; `QUAL-73-006` records the failure. This is not a Phase 73 implementation gap. |

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `test/support/adoption_evidence.ex` | Literal ledger and fail-closed deterministic-owner chain | ✗ PARTIAL / BLOCKER | Exists (1,029 lines), substantive, exports are present and used. Alias and trigger validation remain hollowable. |
| `test/adoption/evidence_contract_test.exs` | Adversarial ledger/owner/workflow contract | ⚠ PARTIAL | Exists (856 lines), substantive, 26 active and 0 skipped tests, and wired into `ci.evidence`; it omits the two reproduced bypasses. |
| `.planning/phases/73-twin-contract-and-baseline/73-BASELINE.md` | Dated quality and CI inventory | ✓ VERIFIED | Exists, substantive, ten findings, seven categories, five severities, and nine CI surfaces. |
| `test/governance/milestone_scope_test.exs` | Baseline, approval, scope, provenance, and remote policy | ✗ PARTIAL / BLOCKER | Exists (3,776 lines), substantive, 44 active and 0 skipped tests; three authority boundaries remain fail-open. |
| `mix.exs` | Focused fresh-process `ci.evidence` alias | ✓ VERIFIED CURRENT ARTIFACT | The checked-in alias names both contract files, the evidence selector, and warnings-as-errors. Its validator accepts an empty effective selection. |
| `.github/workflows/security-gates.yml` | Mandatory planning-aware Evidence contract step | ✓ VERIFIED CURRENT ARTIFACT | Current wiring is enabled and blocking and passes `actionlint`; its guard accepts restrictive source-excluding `paths`. |

The generic artifact query falsely reports Elixir `def` exports as missing and cannot interpret conceptual key-link labels. Direct source inspection above is authoritative for those rows.

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Evidence contract tests | Adoption ledger | Public validation functions | ✓ WIRED | Tests call ledger, closure, repository, and command validators. |
| Adoption ledger | Mix alias and selected ExUnit owners | Actual alias resolution plus owner selection | ✗ PARTIAL | Owner files select tests, but `validate_owner_chain!/4` authorizes alias steps by substring and ignores effective exclusions. |
| Mix alias | Required security workflow | Exact Evidence contract step and triggers | ✗ PARTIAL | Current link works, but enforcement samples only five planning paths and can omit all owner/source inputs. |
| Governance contract | Completed-plan changes | Git/manifest provenance to changed-surface classification | ✗ PARTIAL | Git derivation exists only when no manifest exists; a present manifest becomes the selectable commit set. |
| Remote batch | Approved protection state | Payload/script normalization and comparison | ✗ PARTIAL | Only strict and contexts flow into comparison; nine security-relevant values are dropped. |
| Governance contract | Baseline | Anchored table and provenance checks | ✓ WIRED | Baseline rows flow into structural and tracked/executable evidence checks. |

### Data-Flow Trace (Level 4)

Not applicable. This phase produces test-only registries, Markdown inventories, and CI/governance policy rather than rendered dynamic data.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Nominal mandatory evidence lane | `ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix ci.evidence` | 70 tests, 0 failures, exit 0 in 159.4s | ✓ PASS, but not sufficient |
| Empty-effective alias rejection | Isolated repo with alias adding `--exclude evidence_contract`, then `validate_repository!/2` | Returned `empty-effective-alias: :ok`, exit 0 | ✗ FAIL |
| Restrictive workflow paths rejection | Isolated repo with PR/push `paths` containing only five sampled planning files | Returned `restrictive-paths: :ok`, exit 0 | ✗ FAIL |
| Workflow syntax | `actionlint .github/workflows/security-gates.yml` | Exit 0 | ✓ PASS |
| Patch hygiene | `git diff --check` | Exit 0 | ✓ PASS |

### Probe Execution

No phase-declared or conventional `scripts/**/tests/probe-*.sh` probe exists. The declared executable owner, `mix ci.evidence`, was run independently as recorded above.

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| EVID-01 | 73-01, 73-06, 73-09, 73-11 | Inspectable six-persona evidence ledger | ✓ SATISFIED | Exactly 37 active IDs and all six personas remain inspectable with named jobs and truthful states. |
| EVID-02 | 73-01, 73-04, 73-06, 73-09, 73-11 | Every criterion has deterministic automation in a mandatory lane | ✗ BLOCKED | Empty-effective aliases and source-excluding workflow paths are accepted. |
| QUAL-01 | 73-02, 73-05, 73-08, 73-11 | Severity-ranked repository quality inventory | ✓ SATISFIED | Ten-row, seven-category, five-severity inventory with owned evidence. |
| PIPE-01 | 73-02, 73-08, 73-11 | Inspectable CI duration, duplication, ownership, cache, and failure evidence | ✓ SATISFIED | Nine-surface dated before-snapshot explicitly labels measurements as samples. |
| GOV-01 | 73-03, 73-05, 73-07, 73-08, 73-10, 73-11 | Approval checkpoint before governed mutations | ✗ BLOCKED | Remote state is incomplete, validation executes plan-selected code, and manifests can hide changed surfaces. |
| GOV-02 | 73-03, 73-05, 73-07, 73-10, 73-11 | No speculative protocol capability or unrelated expansion | ✗ BLOCKED | Manifest-selected provenance can omit a commit containing governed or speculative changes from classification. |

All six requirement IDs declared across the eleven plans exist in `REQUIREMENTS.md`, map to Phase 73, and are accounted for above. No Phase 73 requirement is orphaned.

### Decision Coverage

The non-blocking decision-coverage query reports 13/13 trackable `73-CONTEXT.md` decisions referenced by shipped artifacts. This does not override the reproduced authority failures.

### Test Quality Audit

| Test File | Linked Requirements | Active | Skipped | Circular | Assertion Level | Verdict |
| --- | --- | ---: | ---: | --- | --- | --- |
| `test/adoption/evidence_contract_test.exs` | EVID-01, EVID-02 | 26 | 0 | No | Behavioral isolated-repository mutations | BLOCKER — adjacent alias and path-filter bypasses are untested and reproduced. |
| `test/governance/milestone_scope_test.exs` | QUAL-01, PIPE-01, GOV-01, GOV-02 | 44 | 0 | No | Behavioral plan/git/filesystem mutations | BLOCKER — assertions omit full protection-state semantics, script non-mutation, and manifest completeness. |

**Disabled requirement tests:** 0. **Circular patterns:** 0. **Insufficient/missing adversarial assertions:** 5 critical authority cases.

### Anti-Patterns and Confirmed Review Findings

| ID | File / Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| CR-01 | `test/support/adoption_evidence.ex:374` | Alias ownership by substring | 🛑 BLOCKER | An include/exclude combination with zero selected tests is accepted. |
| CR-02 | `test/support/adoption_evidence.ex:855` | Five-path trigger sampling | 🛑 BLOCKER | The workflow can exclude all source/owner changes and still be certified mandatory. |
| CR-03 | `test/governance/milestone_scope_test.exs:2769` | Decode ten protection keys, compare two values | 🛑 BLOCKER | Nine protection controls may change without authorization detecting it. |
| CR-04 | `test/governance/milestone_scope_test.exs:2846` | Execute a plan-selected script during validation | 🛑 BLOCKER | A tracked malicious script receives ambient CI filesystem, credential, and network authority. |
| CR-05 | `test/governance/milestone_scope_test.exs:3269` | Manifest replaces Git-derived commit discovery | 🛑 BLOCKER | A scoped governed commit may be omitted from review and checkpoint classification. |

No unreferenced `TBD`, `FIXME`, or `XXX` marker exists in phase-owned implementation files. Placeholder text is confined to deliberate negative fixtures.

### Prohibition Review

The eleven plans declare 26 prohibitions. Their `judgment` or non-canonical `unverified` dispositions are not silently treated as green. The five confirmed defects directly violate prohibitions against hollow ownership, skippable mandatory CI, self-selected historical evidence, incomplete state authorization, and mutation during validation. Because project policy forbids manual completion gates, these are retained as deterministic automation gaps rather than routed to `human_needed`.

### Human Verification Required

N/A — infrastructure/governance phase with no user-facing behavior. Project policy requires deterministic automated evidence and forbids manual UAT as completion evidence.

### Gaps Summary

The nominal 70-test `ci.evidence` lane is green, but it does not prove the phase goal. Two hollow-gate bypasses reproduce independently, and direct source inspection confirms three additional critical authorization/provenance defects. These failures invalidate roadmap criteria 3 and 4 and block EVID-02, GOV-01, and GOV-02. The `73-VALIDATION.md` and `73-SECURITY.md` green sign-offs are contradicted by current code and cannot establish completion.

The known documentation-vocabulary assertion remains explicitly deferred to Phase 77 and is not counted as a Phase 73 gap.

---

_Verified: 2026-09-10T20:02:04Z_
_Verifier: OpenAI Codex (gsd-verifier)_
