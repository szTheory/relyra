---
phase: 73-twin-contract-and-baseline
verified: 2026-09-09T19:23:37Z
status: gaps_found
score: 5/9 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "Automated policy checks prevent new acceptance criteria from being closed without a mandatory deterministic owner."
    status: failed
    reason: "The closure and owner-chain validators accept malformed evidence rows, comment-only selectors, disabled/non-blocking workflow steps, and non-test Mix commands."
    artifacts:
      - path: "test/support/adoption_evidence.ex"
        issue: "validate_closure!/2 skips row validation; selector and workflow ownership are raw-text checks that admit hollow evidence."
      - path: "test/governance/milestone_scope_test.exs"
        issue: "deterministic_verification_violations/1 accepts any automated text containing `mix `."
    missing:
      - "Validate every closure row against the closed schema and deterministic evidence-kind vocabulary."
      - "Associate selectors with at least one executable selected test, not a source token."
      - "Require an enabled, blocking Evidence contract step in the required security job."
      - "Require criterion/task-specific executable test or check commands with non-zero ownership."
  - truth: "Plans and execution stop at named checkpoints for public API, default, security, SemVer-major, or remote GitHub changes."
    status: failed
    reason: "Risk is detected only when a task self-reports `approval_class`, negative scope uses substring matching, and remote exact-batch validation accepts labels/placeholders without actual reversible commands."
    artifacts:
      - path: "test/governance/milestone_scope_test.exs"
        issue: "Unmarked public-API mutations and `public_api: not unchanged; mutation required` both produce no violation; placeholder-only remote batches also pass."
    missing:
      - "Use exact closed structured risk metadata and reject contradictory scope values."
      - "Detect governed API/security mutations independently of self-reported prose."
      - "Require structured, non-placeholder current/desired state, commands, preflight, rollback, and read-back targeting the same remote checks."
  - truth: "Active v1.11 plans exclude AUTHN-POST-01, KMS-01, SIGNED-META-01, and unrelated speculative product work."
    status: failed
    reason: "Natural-language negation and governance-policy exemptions can cover an implementation directive; `Do not delay; implement KMS-01 in the library` produces no violation."
    artifacts:
      - path: "test/governance/milestone_scope_test.exs"
        issue: "negative_capability_reference?/2 treats any nearby `do not`, `must not`, `forbid`, or `reject` token as a safe exclusion."
    missing:
      - "Represent exclusions in a structured exact list outside implementation-bearing task regions."
      - "Reject demand-gated IDs in task names/files/actions regardless of nearby negation prose."
  - truth: "The baseline shape and each finding's reproducible evidence are fail-closed and machine-checked by ci.evidence."
    status: failed
    reason: "A finding can lose its `[VERIFIED: ...]` reference while retaining arbitrary prose and baseline_violations/1 still returns no violations."
    artifacts:
      - path: "test/governance/milestone_scope_test.exs"
        issue: "evidence_violations/1 only rejects an empty prefix; it never requires the marker or validates its contents."
    missing:
      - "Require a syntactically complete per-row verification marker and an allowed command/source reference."
      - "Add a row-level missing-marker control."
deferred:
  - truth: "The repository-wide warnings-as-errors suite is green despite archival planning vocabulary."
    addressed_in: "Phase 77"
    evidence: "Phase 77 success criterion 2 explicitly removes stale phase/plan/UAT/GSD narration from public docs and tests while retaining archived planning history; QUAL-73-006 and WINDOWS entry 5 record the current one-test failure."
---

# Phase 73: Twin Contract and Baseline Verification Report

**Phase Goal:** A maintainer can see exactly which adopter jobs v1.11 proves, where each proof runs, what the current quality/CI baseline is, and which changes require approval.
**Verified:** 2026-09-09T19:23:37Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A machine-checked ledger maps every in-scope persona and lifecycle outcome to a named job, outcome, evidence class, owner, selector, lane, and planned/existing state. | ✓ VERIFIED | `Relyra.AdoptionEvidence.entries/0` contains all 37 active requirement IDs and all six personas; the focused lane's coverage assertions pass. |
| 2 | The repository has a dated severity-ranked baseline for correctness, security, integration, readability, documentation, artifacts, and CI cost/duplication. | ✓ VERIFIED | `73-BASELINE.md` contains all seven categories, all five severities, ten findings, and a nine-surface CI snapshot. |
| 3 | Automated policy checks prevent new acceptance criteria from closing without a mandatory deterministic owner. | ✗ FAILED | Direct probes returned `:ok` for a malformed closure row, a comment-only selector owner, and an `if: false` / `continue-on-error: true` workflow step; `mix help` also passed the plan policy. |
| 4 | Plans and execution stop at named checkpoints before public API, default, security, SemVer-major, or remote GitHub mutation and exclude speculative protocol work. | ✗ FAILED | Direct probes produced `[]` violations for an unmarked `Relyra.start_login/3` mutation, contradictory `not unchanged` scope, placeholder remote batch, and negation-smuggled `KMS-01` implementation. |
| 5 | Planned and external-canary rows remain visible but cannot themselves close a completed requirement. | ✓ VERIFIED | `deterministic_owners/2` filters `state != :existing` and `:external_canary`; the specific planned/canary test passes. |
| 6 | Planning-only changes run the evidence contract through the required security workflow. | ✓ VERIFIED | `.planning/**` is not ignored; `prompts/**` remains ignored; the enabled current `jobs.security` step runs `mix ci.evidence`; `actionlint` passes. |
| 7 | Every current baseline finding names evidence, disposition, owner, target phase, approval class, blocker state, and revisit date. | ✓ VERIFIED | The current findings table has all required non-empty columns and severity-specific states; focused assertions pass. |
| 8 | The baseline shape and each finding's reproducible evidence are fail-closed and machine-checked by `ci.evidence`. | ✗ FAILED | Removing the first row's `[VERIFIED: ...]` marker leaves arbitrary prose and `baseline_violations/1` returns `[]`. |
| 9 | Remote GitHub approval requires one exact reversible batch rather than keyword-only authorization. | ✗ FAILED | Replacing all seven required elements with phrases ending in `omitted` still returns `[]` violations. |

**Score:** 5/9 truths verified (0 present, behavior-unverified)

### Deferred Items

| # | Item | Addressed In | Evidence |
| --- | --- | --- | --- |
| 1 | Full-suite archival-vocabulary failure | Phase 77 | Roadmap success criterion 2 and baseline finding `QUAL-73-006` specifically own the distinction between executable markers and archival prose. |

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `test/support/adoption_evidence.ex` | Literal registry and deterministic-owner contract | ⚠️ PARTIAL | Exists, substantive, and called by both contract files. Public functions exist at lines 229–310 despite the generic artifact checker not recognizing `def name` syntax, but closure/owner validation is fail-open. |
| `test/adoption/evidence_contract_test.exs` | Evidence schema, closure, selector, alias, and workflow tests | ⚠️ PARTIAL | 9 active tests run in `ci.evidence`; they omit malformed closure, inert selector, and disabled/non-blocking workflow controls. |
| `.planning/phases/73-twin-contract-and-baseline/73-BASELINE.md` | Dated quality and CI inventory | ✓ VERIFIED | 53 substantive lines; current rows satisfy the declared schema and inventory scope. |
| `test/governance/milestone_scope_test.exs` | Baseline, approval, scope, and automation policy | ⚠️ PARTIAL | 1,208 substantive lines and 20 active tests, but the key parsers admit all reproduced bypasses. |
| `mix.exs` | Focused fresh-process evidence alias | ✓ VERIFIED | `ci.evidence` is preferred in test and runs both owner files in one `cmd mix test ... --only evidence_contract --warnings-as-errors` step. |
| `.github/workflows/security-gates.yml` | Mandatory planning-aware evidence step | ✓ VERIFIED (current state) | Current step is enabled under `jobs.security`; workflow syntax passes. The validator does not preserve this property against edits. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Evidence contract test | Adoption ledger | Direct validation and owner queries | ⚠️ PARTIAL | Wired and executed, but tests do not prove semantic selector/workflow ownership. |
| Evidence contract test | `mix.exs` | Elixir AST inspection | ✓ WIRED | Alias resolves to the focused fresh-process command. |
| `mix.exs` | Security workflow | `mix ci.evidence` | ⚠️ PARTIAL | Current command is wired, but validator accepts disabled/non-blocking placement anywhere in the workflow. |
| Governance contract | Baseline | Anchored Markdown parsing | ⚠️ PARTIAL | Table is wired, but per-row evidence provenance is not required. |
| `mix.exs` | Governance contract | Focused alias owner path | ✓ WIRED | Generic key-link regex missed the multiline alias, but direct inspection and the passing lane prove the link. |
| Governance contract | ROADMAP and active plans | Phase discovery and plan parsing | ⚠️ PARTIAL | Files are read and parsed; risk/capability semantics are fail-open. |

### Data-Flow Trace (Level 4)

Not applicable: Phase 73 contains test-only registries, planning artifacts, and CI configuration; no dynamic UI or rendered data source exists.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Focused owner lane | `mix ci.evidence` with Elixir 1.19.5 / OTP 28.4.1 | 29 tests, 0 failures | ✓ PASS |
| Workflow syntax | `actionlint .github/workflows/security-gates.yml` | exit 0 | ✓ PASS |
| Malformed closure rejection | `MIX_ENV=test mix run` calling `validate_closure!([%{requirement: "EVID-01", state: :existing, evidence_kind: :bogus}], ["EVID-01"])` | returned `:ok` | ✗ FAIL |
| Inert selector rejection | Temporary repository with owners containing only commented `@moduletag :evidence_contract` | `validate_repository!/2` returned `:ok` | ✗ FAIL |
| Mandatory workflow enforcement | Temporary workflow with `if: false` and `continue-on-error: true` on Evidence contract | `validate_repository!/2` returned `:ok` | ✗ FAIL |
| Governance bypass corpus | Exact module logic exposed in-memory and called with five mutations | Every case returned `[]`: unmarked API mutation, contradictory scope, placeholder remote batch, `mix help`, and KMS negation smuggling | ✗ FAIL |
| Per-row evidence provenance | First baseline row's verification marker removed in-memory | `baseline_violations/1` returned `[]` | ✗ FAIL |

### Probe Execution

No phase-declared or conventional `scripts/**/tests/probe-*.sh` probes were found.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| EVID-01 | 73-01 | Inspectable six-persona evidence ledger | ✓ SATISFIED | Literal 37-requirement/six-persona ledger and passing coverage test. |
| EVID-02 | 73-01 | Deterministic automation in a mandatory CI lane | ✗ BLOCKED | Hollow closure, selector, and workflow states are accepted. |
| QUAL-01 | 73-02 | Severity-ranked repository quality inventory | ✓ SATISFIED | Current dated seven-category/five-severity inventory exists. |
| PIPE-01 | 73-02 | Current CI duration, duplication, ownership, cache, and failure evidence | ✓ SATISFIED | Current nine-surface snapshot contains each required dimension and provenance. |
| GOV-01 | 73-03 | Approval before governed mutations | ✗ BLOCKED | Unmarked and placeholder mutation paths bypass the checkpoint contract. |
| GOV-02 | 73-03 | No speculative SAML or unrelated expansion | ✗ BLOCKED | Demand-gated IDs can be smuggled through negation prose. |

No Phase 73 requirements are orphaned: all six roadmap-owned IDs appear in plan frontmatter.

### Decision Coverage

Skipped: Phase 73 has no CONTEXT.md or trackable `<decisions>` block.

### Test Quality Audit

| Test File | Linked Reqs | Active | Skipped | Circular | Assertion Level | Verdict |
| --- | --- | ---: | ---: | --- | --- | --- |
| `test/adoption/evidence_contract_test.exs` | EVID-01, EVID-02 | 9 | 0 | No | Behavioral repository mutations | BLOCKER — missing semantic owner/workflow and malformed-closure cases |
| `test/governance/milestone_scope_test.exs` | QUAL-01, PIPE-01, GOV-01, GOV-02 | 20 | 0 | No; writes are isolated negative fixtures | Behavioral parser mutations | BLOCKER — mutation corpus omits simple accepted bypasses |

**Disabled requirement tests:** 0. **Circular expected-value generation:** 0. **Insufficient assertions:** 4 requirement contracts (`EVID-02`, baseline provenance under `QUAL-01`, `GOV-01`, `GOV-02`).

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | ---: | --- | --- | --- |
| `test/support/adoption_evidence.ex` | 295 | Closure path bypasses row validation | 🛑 Blocker | Malformed/unknown evidence can close a criterion. |
| `test/support/adoption_evidence.ex` | 338 | Raw regex treats selector text as executable ownership | 🛑 Blocker | Comments or strings can create hollow owners. |
| `test/support/adoption_evidence.ex` | 380 | Workflow search ignores job/step enabled and blocking state | 🛑 Blocker | Optional or permanently skipped evidence appears mandatory. |
| `test/governance/milestone_scope_test.exs` | 660 | Negative scope is substring-based | 🛑 Blocker | Contradictory mutation intent passes. |
| `test/governance/milestone_scope_test.exs` | 718 | Mutation detection relies on self-reported marker | 🛑 Blocker | Governed changes can bypass checkpoints. |
| `test/governance/milestone_scope_test.exs` | 725 | Remote batch validates keywords only | 🛑 Blocker | Placeholder authorization passes. |
| `test/governance/milestone_scope_test.exs` | 751 | Any `mix ` token counts as deterministic evidence | 🛑 Blocker | Non-test commands satisfy acceptance. |
| `test/governance/milestone_scope_test.exs` | 804 | Negation keyword exemption | 🛑 Blocker | Forbidden protocol implementation can be smuggled. |
| `test/governance/milestone_scope_test.exs` | 1137 | Missing verification marker not rejected | 🛑 Blocker | Baseline provenance can silently disappear. |
| `test/support/adoption_evidence.ex` | 276 | Whitespace-only text fields are accepted | ⚠️ Warning | Canonical rows can be visually empty. |

No unreferenced `TBD`, `FIXME`, or `XXX` debt markers and no disabled tests were found in phase-owned files. The Phoenix 1.8.13 remediation also widened Bandit, Phoenix PubSub, Thousand Island, and WebSock Adapter lock entries; this is a dependency-scope warning, not a Phase 73 goal gap, and the security lane passes.

### Prohibition Review

All six PLAN prohibitions are judgment-tier and remain formally unresolved. In this autonomous run they receive non-authoritative review only, with human review recommended; they are not converted into a required manual UAT state. The reproduced hollow-owner, weak-baseline, approval, and capability-smuggling paths contradict four of the six prohibitions, reinforcing the blocking gaps above. The single-sample/intentional-security-duplication prohibition is supported by the current baseline text. No evidence of actual out-of-scope runtime SAML changes was found.

### Human Verification Required

None. This infrastructure/governance phase is fully decidable through deterministic source inspection and isolated automated probes; project policy prohibits manual completion gates.

### Gaps Summary

The inspectable ledger and baseline exist, and the current `ci.evidence`/workflow wiring is green. The phase goal is nevertheless not achieved because the mechanisms intended to keep those guarantees true accept multiple simple, reproducible bypasses. These are Phase 73 contract failures, not later-phase polish: EVID-02, GOV-01, and GOV-02 are currently marked complete, and the roadmap's own success criteria require the missing enforcement now. The known archival-vocabulary suite failure is separately and specifically deferred to Phase 77.

---

_Verified: 2026-09-09T19:23:37Z_
_Verifier: the agent (gsd-verifier)_
