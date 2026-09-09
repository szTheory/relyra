---
phase: 73-twin-contract-and-baseline
verified: 2026-09-09T22:17:45Z
status: gaps_found
score: 5/9 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 5/9
  gaps_closed: []
  gaps_remaining:
    - "Automated policy checks prevent new acceptance criteria from being closed without a mandatory deterministic owner."
    - "Plans and execution stop at named checkpoints for public API, default, security, SemVer-major, or remote GitHub changes."
    - "Active v1.11 plans exclude AUTHN-POST-01, KMS-01, SIGNED-META-01, and unrelated speculative product work."
    - "The baseline shape and each finding's reproducible evidence are fail-closed and machine-checked by ci.evidence."
  regressions: []
decision_coverage:
  honored: 13
  total: 13
  not_honored: []
gaps:
  - truth: "Automated policy checks prevent new acceptance criteria from being closed without a mandatory deterministic owner."
    status: failed
    reason: "Committed RED tests prove that command substitution, empty effective test filters, cross-module/tag-value selector matches, and event-conditional or expression-fallible workflow steps are accepted."
    artifacts:
      - path: "test/support/adoption_evidence.ex"
        issue: "Command, selector, and mandatory-workflow validation remains fail-open at CR-01 through CR-03 boundaries."
      - path: "test/adoption/evidence_contract_test.exs"
        issue: "Five active adversarial contract tests fail against the implementation."
    missing:
      - "Reject shell substitution before environment-prefix normalization and calculate the effective selected ExUnit set, including equals-form and exclusion filters."
      - "Associate selector tags with executable tests inside the correct ExUnit module using ExUnit tag semantics."
      - "Require the Evidence contract step to execute and block on every required event; reject unsupported conditions and continue-on-error expressions."
  - truth: "Plans and execution stop at named checkpoints for public API, default, security, SemVer-major, or remote GitHub changes."
    status: failed
    reason: "Committed RED tests prove that checkpoint-shaped unknown task types, negated approval text, contradictory scope assertions, summary-file exemptions, disconnected governed-diff inference, and appended remote commands bypass governance."
    artifacts:
      - path: "test/governance/milestone_scope_test.exs"
        issue: "CR-04 through CR-08 remain observable fail-open authorization paths."
    missing:
      - "Validate a closed task-type vocabulary and exempt only exact authorization checkpoint types."
      - "Parse exact positive decisions and exact scope values rather than substring-bearing prose."
      - "Wire actual scoped-diff classification into active and completed-plan enforcement instead of treating SUMMARY existence as authorization evidence."
      - "Parse remote commands with a closed single-operation grammar and reject appended shell or remote operations."
  - truth: "Active v1.11 plans exclude AUTHN-POST-01, KMS-01, SIGNED-META-01, and unrelated speculative product work."
    status: failed
    reason: "An unknown checkpoint-prefixed implementation task bypasses the forbidden-capability validator, so the structural exclusion contract is not universal across implementation-bearing task types."
    artifacts:
      - path: "test/governance/milestone_scope_test.exs"
        issue: "The shared checkpoint-prefix exemption permits checkpoint-bypass tasks to implement excluded capability IDs."
    missing:
      - "Apply demand-gated task-region rejection to every implementation-bearing task and reject unknown checkpoint-like types before exemptions."
  - truth: "The baseline shape and each finding's reproducible evidence are fail-closed and machine-checked by ci.evidence."
    status: failed
    reason: "A backticked allowed-prefix path is accepted without proving the referenced repository file exists; `.planning/no-such-evidence.md` satisfies the current validator."
    artifacts:
      - path: "test/governance/milestone_scope_test.exs"
        issue: "CR-09 leaves QUAL-01 provenance fabricable; the active nonexistent-path test fails."
    missing:
      - "Resolve source references beneath the repository root and require existing regular tracked files."
      - "Validate command references through the same executable, non-zero owner contract as acceptance evidence."
deferred:
  - truth: "The repository-wide warnings-as-errors suite is green despite archival planning vocabulary."
    addressed_in: "Phase 77"
    evidence: "Phase 77 owns removal of stale phase/plan/UAT/GSD narration while retaining archived planning history; baseline finding QUAL-73-006 records the current one-test failure."
---

# Phase 73: Twin Contract and Baseline Verification Report

**Phase Goal:** A maintainer can see exactly which adopter jobs v1.11 proves, where each proof runs, what the current quality/CI baseline is, and which changes require approval.
**Verified:** 2026-09-09T22:17:45Z
**Status:** gaps_found
**Re-verification:** Yes — after gap-closure Plans 73-04 and 73-05

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A machine-checked ledger maps every in-scope persona and lifecycle outcome to a named job, outcome, evidence class, owner, selector, lane, and planned/existing state. | ✓ VERIFIED | Quick regression check: `Relyra.AdoptionEvidence.entries/0` still contains the 37 active requirement IDs and all six required personas; corresponding positive coverage passes. |
| 2 | The repository has a dated severity-ranked baseline for correctness, security, integration, readability, documentation, artifacts, and CI cost/duplication. | ✓ VERIFIED | Quick regression check: `73-BASELINE.md` retains all seven quality categories, the five-level severity policy, ten findings, and the nine-surface dated CI snapshot. |
| 3 | Automated policy checks prevent new acceptance criteria from closing without a mandatory deterministic owner. | ✗ FAILED | `mix ci.evidence` fails on command substitution, zero-effective-test filters, selector module/tag semantics, and conditional/fallible workflow placement. |
| 4 | Plans and execution stop at named checkpoints before public API, default, security, SemVer-major, or remote GitHub mutation and exclude speculative protocol work. | ✗ FAILED | Active RED tests show unknown checkpoint-shaped tasks, negated decisions, contradictory scope, summary exemptions, and appended remote commands are accepted. |
| 5 | Planned and external-canary rows remain visible but cannot themselves close a completed requirement. | ✓ VERIFIED | `deterministic_owners/2` still excludes non-existing and external-canary rows; the focused planned/canary regression tests pass. |
| 6 | Planning-only changes run the evidence contract through the required security workflow. | ✓ VERIFIED | `.planning/**` is not ignored, `prompts/**` remains ignored, and the current enabled `jobs.security` step invokes `mix ci.evidence`; `actionlint` exits 0. |
| 7 | Every current baseline finding names evidence, disposition, owner, target phase, approval class, blocker state, and revisit date. | ✓ VERIFIED | The current findings ledger retains every required non-empty column and severity-specific lifecycle field. |
| 8 | The baseline shape and each finding's reproducible evidence are fail-closed and machine-checked by `ci.evidence`. | ✗ FAILED | The nonexistent-path adversarial test fails because `.planning/no-such-evidence.md` is accepted as provenance. |
| 9 | Remote GitHub approval requires one exact reversible batch rather than keyword- or substring-only authorization. | ✗ FAILED | Appending `&& gh api -X DELETE repos/szTheory/relyra` to an otherwise accepted mutation command produces no violation. |

**Score:** 5/9 truths verified (0 present, behavior-unverified)

### Roadmap Success Criteria

| # | Roadmap Contract | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Ledger maps every in-scope persona and lifecycle outcome to deterministic evidence or a scheduled canary. | ✓ VERIFIED | Literal ledger coverage and planned/existing/canary state remain present and tested. |
| 2 | Severity-ranked quality and CI baseline covers all required dimensions. | ✓ VERIFIED | The dated findings ledger and CI snapshot exist with the required scope. |
| 3 | Policy prevents acceptance closure without a mandatory deterministic owner. | ✗ FAILED — BLOCKER | Five adoption-contract tests expose hollow or optional ownership. |
| 4 | Plans stop for governed changes and exclude speculative protocol work. | ✗ FAILED — BLOCKER | Governance tests expose multiple approval and task-type bypasses. |

### Deferred Items

| # | Item | Addressed In | Evidence |
| --- | --- | --- | --- |
| 1 | Repository-wide archival-vocabulary failure | Phase 77 | Phase 77 explicitly owns cleanup of stale planning narration; `QUAL-73-006` records the current failure. |

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `test/support/adoption_evidence.ex` | Closed literal ledger and executable deterministic-owner chain | ✗ PARTIAL / BLOCKER | Exists (676 lines), substantive, exported functions are present, and consumers call it. The generic artifact query misreads Elixir `def name` exports, but direct inspection confirms them. CR-01 through CR-03 prove enforcement is not fail-closed. |
| `test/adoption/evidence_contract_test.exs` | Adversarial schema, closure, selector, alias, and workflow contract | ✓ VERIFIED TEST ARTIFACT | Exists (477 lines), wired through `ci.evidence`, has 18 active tests, and contains strong RED coverage. Five tests correctly expose missing implementation. |
| `.planning/phases/73-twin-contract-and-baseline/73-BASELINE.md` | Dated severity-ranked quality and CI inventory | ✓ VERIFIED CURRENT ARTIFACT | Exists (53 substantive lines) with ten findings and a nine-surface snapshot. Its future provenance integrity is not protected. |
| `test/governance/milestone_scope_test.exs` | Baseline, approval, scope, and automated-completion policy | ✗ PARTIAL / BLOCKER | Exists (2,018 lines), substantive, and selected by `ci.evidence`; six of 34 active tests fail on CR-04 through CR-09. |
| `mix.exs` | Focused fresh-process `ci.evidence` alias | ✓ VERIFIED | Alias at line 235 invokes both contract files with `--only evidence_contract --warnings-as-errors`. |
| `.github/workflows/security-gates.yml` | Mandatory, planning-aware Evidence contract step | ✓ VERIFIED CURRENT ARTIFACT | Current `jobs.security` step invokes the alias and workflow syntax passes. The validator would certify conditional/fallible variants. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Evidence contract tests | Adoption ledger | Closed-row and owner-chain calls | ✗ PARTIAL | Calls are wired, but semantic selection and workflow-mandatory invariants fail active tests. |
| Adoption ledger | ExUnit owner source | Selector-to-executable-test inspection | ✗ NOT RELIABLY WIRED | File-wide AST accumulation crosses module boundaries and treats incidental tag values as selectors. |
| `mix.exs` | Both Phase 73 contracts | One fresh-process `ci.evidence` command | ✓ WIRED | Direct inspection confirms both paths, selector, and warnings-as-errors. |
| `mix.exs` | Security workflow | `mix ci.evidence` | ✓ WIRED CURRENTLY | Current lane is enabled and blocking, though its enforcing validator is fail-open. |
| Governance contract | Active/completed plans and governed surfaces | Parsed risk, checkpoint, and diff classification | ✗ PARTIAL | `changed_surface_classes/3` is exercised only by self-test and not fed into active-plan enforcement; SUMMARY existence suppresses validation. |
| Governance contract | Baseline | Anchored parsing and row-local provenance | ✗ PARTIAL | Table/marker parsing is wired; referenced path existence is not. |

### Data-Flow Trace (Level 4)

Not applicable. Phase 73 produces test-only registries, Markdown planning evidence, and CI configuration; it has no rendered dynamic data path.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Adoption evidence contract | `mix test test/adoption/evidence_contract_test.exs --warnings-as-errors` with required ASDF versions | 18 tests, 5 failures, exit 2 | ✗ FAIL |
| Governance contract | `mix test test/governance/milestone_scope_test.exs --warnings-as-errors` with required ASDF versions | 34 tests, 6 failures, exit 2 | ✗ FAIL |
| Mandatory owning lane | `mix ci.evidence` with required ASDF versions | 52 tests, 11 failures, exit 1 | ✗ FAIL |
| Workflow syntax | `actionlint .github/workflows/security-gates.yml` | exit 0 | ✓ PASS |
| Patch hygiene | `git diff --check` | exit 0 | ✓ PASS |

### Probe Execution

No phase-declared or conventional `scripts/**/tests/probe-*.sh` probe exists. The phase-declared executable owner, `mix ci.evidence`, was run independently and failed as recorded above.

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| EVID-01 | 73-01 | Inspectable six-persona evidence ledger | ✓ SATISFIED | Literal all-requirement ledger and six-persona coverage remain present; focused positive coverage passes. |
| EVID-02 | 73-01, 73-04 | Every criterion has deterministic automation in a mandatory lane | ✗ BLOCKED | CR-01 through CR-03 and five active RED tests prove hollow/optional evidence can still be accepted. |
| QUAL-01 | 73-02, 73-05 | Severity-ranked repository quality inventory | ⚠️ PARTIAL / BLOCKED PLAN CONTRACT | The current inventory is inspectable, but Plan 73-05's required fail-closed provenance contract accepts nonexistent sources (CR-09). |
| PIPE-01 | 73-02 | Inspectable current CI duration, duplication, ownership, cache, and failure evidence | ✓ SATISFIED | The dated nine-surface snapshot contains every required dimension and labels measurements as samples. |
| GOV-01 | 73-03, 73-05 | Approval checkpoint before governed mutations | ✗ BLOCKED | CR-04 through CR-08 expose task-type, decision, scope, completed-plan, diff-wiring, and remote-command bypasses. |
| GOV-02 | 73-03, 73-05 | No speculative protocol capability or unrelated expansion | ✗ BLOCKED | A `checkpoint-bypass` task can carry forbidden implementation while skipping the structural exclusion check. |

All six Phase 73 requirements appear in plan frontmatter and the roadmap mapping; no requirement is orphaned.

### Decision Coverage

All 13 trackable decisions in `73-CONTEXT.md` are referenced by shipped artifacts according to `check.decision-coverage-verify`. This warning-only heuristic does not override the failing behavioral contracts.

### Test Quality Audit

| Test File | Linked Reqs | Active | Skipped | Circular | Assertion Level | Verdict |
| --- | --- | ---: | ---: | --- | --- | --- |
| `test/adoption/evidence_contract_test.exs` | EVID-01, EVID-02 | 18 | 0 | No | Behavioral isolated-repository mutations | BLOCKER — 5 tests fail and expose CR-01 through CR-03. |
| `test/governance/milestone_scope_test.exs` | QUAL-01, PIPE-01, GOV-01, GOV-02 | 34 | 0 | No; writes are isolated fixture mutations | Behavioral plan/baseline mutations | BLOCKER — 6 tests fail and expose CR-04 through CR-09. |

**Disabled requirement tests:** 0. **Circular expected-value generation:** 0. **Insufficient assertions:** 0 in the new RED coverage; the implementation fails the asserted behavior.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | ---: | --- | --- | --- |
| `test/support/adoption_evidence.ex` | 340 | Environment prefixes stripped before shell metacharacter rejection; filters do not model effective selection | 🛑 Blocker | Shell execution or zero-test commands can close acceptance. |
| `test/support/adoption_evidence.ex` | 406 | File-wide selector AST state crosses modules and accepts incidental atom values | 🛑 Blocker | Non-executable ownership appears real. |
| `test/support/adoption_evidence.ex` | 565 | Unknown workflow conditions/fallibility are treated as mandatory | 🛑 Blocker | Evidence can be skipped on required events. |
| `test/governance/milestone_scope_test.exs` | 1005 | Prefix-based checkpoint exemption without closed task types | 🛑 Blocker | Risk, evidence, and excluded-capability checks are bypassed together. |
| `test/governance/milestone_scope_test.exs` | 1101 | Free-form substring search accepts negated approval text | 🛑 Blocker | A non-approval authorizes governed mutation. |
| `test/governance/milestone_scope_test.exs` | 1050 | Plan scope remains substring-based | 🛑 Blocker | Contradictory mutation intent suppresses checkpoints. |
| `test/governance/milestone_scope_test.exs` | 1189 | Governed before/after classifier is disconnected from repository enforcement | 🛑 Blocker | Misstated changes and premature summaries bypass approval. |
| `test/governance/milestone_scope_test.exs` | 1408 | Remote command target comparison accepts appended commands | 🛑 Blocker | Approval can include unreviewed remote mutations. |
| `test/governance/milestone_scope_test.exs` | 1839 | Allowed path prefixes are not resolved to real tracked files | 🛑 Blocker | Fabricated evidence satisfies baseline provenance. |
| `mix.lock` | 2 | Phoenix remediation widened four coupled transport/pubsub dependency locks | ⚠️ Warning | Compatibility surface is broader than the named advisory fix; not a Phase 73 goal blocker. |

No unreferenced `TBD`, `FIXME`, or `XXX` debt marker exists in phase-owned implementation files. Placeholder strings in governance tests are deliberate negative fixtures, not incomplete implementation markers.

### Prohibition Review

The eleven plan prohibitions are not silently passed. Deterministic failures directly contradict the prohibitions against hollow selectors, optional workflow evidence, ambiguous approval, demand-gated task smuggling, and fabricated baseline references. Those contradictions are represented by the four blocking gaps above. The inventory-only/single-sample prohibition remains supported by the baseline text. No separate manual disposition is created because project policy requires automated evidence and the failures are observable.

### Human Verification Required

N/A — infrastructure/governance phase with no user-facing elements. All acceptance criteria are deterministically checkable, and project policy forbids substituting manual UAT for failed automated evidence.

### Gaps Summary

Plans 73-04 and 73-05 closed the literal bypass examples from the first verification, but they did not close the underlying four failed truths. The committed Nyquist corpus in `69aa4dd` proves nine adjacent fail-open implementation defects: five adoption tests and six governance tests fail, and the mandatory `ci.evidence` lane fails with all 11 failures. EVID-02, GOV-01, GOV-02, and Plan 73-05's fail-closed QUAL-01 provenance contract remain blocking. These failures are Phase 73 contract work and are not deferred by later milestone phases.

---

_Verified: 2026-09-09T22:17:45Z_
_Verifier: the agent (gsd-verifier)_
