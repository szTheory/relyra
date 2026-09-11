---
phase: 73-twin-contract-and-baseline
reviewed: 2026-09-10T16:43:00Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - .github/workflows/security-gates.yml
  - mix.exs
  - mix.lock
  - test/adoption/evidence_contract_test.exs
  - test/governance/milestone_scope_test.exs
  - test/support/adoption_evidence.ex
findings:
  critical: 2
  warning: 1
  info: 0
  total: 3
status: issues_found
---

# Phase 73: Code Review Report

**Reviewed:** 2026-09-10T16:43:00Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

The new evidence contract has two release-blocking correctness failures. Its mandatory CI lane is nondeterministic because evidence tests repeatedly launch nested BEAM/Mix processes inside ordinary 60-second ExUnit tests, and its hand-written GitHub path-glob matcher disagrees with GitHub's documented `?` semantics, allowing governed planning changes to skip the workflow while validation passes. The owner-path validation also follows symlinks, weakening the claimed repository-local evidence boundary.

The independently observed `LoginTraceTest` ETS race and the archival planning-vocabulary failure are outside the Phase 73 source changes reviewed here and are not counted as findings in this report.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Mandatory evidence tests repeatedly exceed ExUnit's timeout

**File:** `test/support/adoption_evidence.ex:425-479`

**Issue:** `registered_test_tags!/2` starts a fresh `mix run` OS process for every owner inspection. `validate_repository!/2` invokes that probe once for every distinct owner/selector and then invokes it again for every owner in the lane command. The evidence suite calls full repository validation dozens of times, including from an `async: true` module and from table-driven tests such as `test/adoption/evidence_contract_test.exs:815-847`. This creates many concurrent nested BEAM VMs and makes an unchanged mandatory lane fail at ExUnit's default 60-second timeout. Two observed `mix ci.evidence` attempts timed out at line 464; an unchanged third attempt passed only after roughly 220 seconds. A mandatory acceptance lane that sometimes fails without an input change is incorrect and cannot gate releases reliably.

**Fix:** Separate pure workflow/alias validation from expensive test discovery. Discover registered tests once per owner per lane invocation (or generate a deterministic manifest once in a single helper process), pass that snapshot into repository validation, and have mutation tests call only the pure validator for the seam they mutate. Keep test discovery bounded and serialize any unavoidable external BEAM probes; do not paper over the defect by increasing ExUnit timeouts.

### CR-02: GitHub path-filter semantics can bypass the mandatory evidence workflow

**File:** `test/support/adoption_evidence.ex:1133-1135`

**Issue:** `glob_source!/1` translates `?` to exactly one arbitrary non-slash character. GitHub Actions documents `?` in path patterns as matching zero or one occurrence of the preceding character. Consequently, a filter such as `.planning/STATE.md?` matches `.planning/STATE.md` on GitHub and can suppress an evidence-only change, but this validator translates it to a pattern requiring one character after `.md` and accepts the workflow. The contract therefore does not prove that governed planning inputs trigger the mandatory lane. The same custom grammar should not be assumed correct for other GitHub metacharacters it does not model.

**Fix:** Use a parser/matcher with GitHub Actions-compatible path-filter semantics. Given that the checked-in ignore policy only needs `prompts/**`, the safer minimal fix is to reject unsupported metacharacters such as `?` and `+` outright, then add an adversarial test showing `.planning/STATE.md?` is rejected rather than accepted.

## Warnings

### WR-01: Evidence owners may resolve through symlinks outside their declared path

**File:** `test/support/adoption_evidence.ex:642-649`

**Issue:** `repository_path!/2` performs only lexical `Path.expand/2` containment and then calls `File.regular?/1`, which follows symlinks. A tracked owner path can therefore be replaced by a symlink to another tagged test (including a target outside the repository), and both source discovery and alias validation will accept it as the declared owner. This undermines diagnostics and the claim that the ledger points to a specific repository-local executable owner. The governance baseline path validator already rejects symlinks component-by-component, so the two evidence paths enforce inconsistent boundaries.

**Fix:** Require a relative tracked path and reject a symlink at every path component before compiling an owner. Reuse the component-wise `File.lstat/1` plus `git ls-files --error-unmatch` approach already used by `allowed_repository_path?/2` in the governance test.

---

_Reviewed: 2026-09-10T16:43:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
