---
phase: 73-twin-contract-and-baseline
reviewed: 2026-09-10T19:54:32Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - .github/workflows/security-gates.yml
  - mix.exs
  - test/adoption/evidence_contract_test.exs
  - test/governance/milestone_scope_test.exs
  - test/support/adoption_evidence.ex
findings:
  critical: 5
  warning: 0
  info: 0
  total: 5
status: issues_found
---

# Phase 73: Code Review Report

**Reviewed:** 2026-09-10T19:54:32Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

The Phase 73 contracts contain five fail-open defects in the evidence-owner, workflow-trigger, completed-plan provenance, and remote-authorization boundaries. The post-merge cwd-race correction in `b1dfbf1` is present and its regression test passes, but it does not affect these findings. A fresh `mix ci.evidence` run passed 70 tests in 156.3 seconds; two bypasses below were also reproduced independently and returned `:ok` despite hollow evidence ownership.

## Narrative Findings (AI reviewer)

### Critical Issues

#### CR-01: Alias ownership accepts a command whose effective selection is empty

**Classification:** BLOCKER
**File:** `test/support/adoption_evidence.ex:374-377`
**Issue:** Repository validation checks the lane command with substring predicates instead of the already-implemented command parser. An alias such as `cmd mix test test/adoption/evidence_contract_test.exs test/governance/milestone_scope_test.exs --only evidence_contract --exclude evidence_contract --warnings-as-errors` contains every required substring but selects zero tests. `validate_repository!/2` accepted this fixture and returned `:ok`, while ExUnit can exit successfully with zero selected tests. The mandatory evidence chain can therefore become hollow without detection.
**Fix:** Parse and validate the exact alias command once with `validate_check_alias!/2` (or a shared parser returning the normalized owner paths and effective filters), require exactly one alias step, and verify that each row's exact owner path contributes at least one test after all include/exclude filters. Remove the substring-based authority check.

#### CR-02: Restrictive workflow `paths` filters can exclude all source changes while passing validation

**Classification:** BLOCKER
**File:** `test/support/adoption_evidence.ex:855-868`
**Issue:** The trigger validator tests only five hard-coded planning paths. A workflow whose `pull_request.paths` and `push.paths` contain exactly those five files passes `validate_repository!/2`, even though changes to `test/support/adoption_evidence.ex`, either owner test, `mix.exs`, and the workflow itself do not start the security job. This bypass was reproduced and returned `:ok`, contradicting the contract that evidence is mandatory for both source and planning changes.
**Fix:** Fail closed on any positive `paths` filter for this mandatory workflow, or compute and require coverage for every governed input (ledger, owner tests, `mix.exs`, workflow, baseline, identity documents, and every governed PLAN/SUMMARY). Prefer allowing only `paths-ignore` entries that are proven disjoint from all governed source and planning surfaces.

#### CR-03: Branch-protection payload validation ignores nine security-relevant field values

**Classification:** BLOCKER
**File:** `test/governance/milestone_scope_test.exs:2769-2784`
**Issue:** The normalizer requires ten top-level key names but validates and returns only `required_status_checks.strict` and `contexts`. Values for `enforce_admins`, pull-request reviews, restrictions, force pushes, deletions, branch creation, conversation resolution, branch locking, and fork syncing are discarded. A payload can match the declared desired checks while silently setting `enforce_admins` to `false`, enabling force pushes/deletions, or otherwise weakening protection, and `operation_matches_state?/2` will still authorize it.
**Fix:** Define a closed normalized branch-protection struct containing every accepted field, validate each field's type and allowed value, include the complete normalized state in both `current_state` and `desired_state`, and compare the full payload. If Phase 73 intends those fields to be invariant constants, enforce their exact expected values instead of discarding them.

#### CR-04: Validation executes a plan-selected script with normal CI process authority

**Classification:** BLOCKER
**File:** `test/governance/milestone_scope_test.exs:2798-2803,2846-2855`
**Issue:** A remote-approval PLAN may point at any tracked executable whose index hash matches the working tree. The validator then executes that script directly to obtain `--print-expected-json`. Nothing constrains what the script does before printing JSON, so a malicious or compromised tracked script can write files, access available credentials, contact the network, or perform the remote mutation during what is supposed to be a non-mutating authorization check. Fixed argv and hash equality establish identity, not safety.
**Fix:** Do not execute the mutation script during validation. Bind authorization to a static tracked JSON artifact and the script's committed object ID, or inspect a declarative manifest generated outside the mandatory gate. If execution is unavoidable, run a separately trusted interpreter/harness in a sandbox with no network, no credentials, and a read-only filesystem; the plan-selected executable itself must not receive ambient CI authority.

#### CR-05: A phase manifest can omit scoped commits and hide governed changes

**Classification:** BLOCKER
**File:** `test/governance/milestone_scope_test.exs:3269-3297`
**Issue:** When `.planning/.phase-manifest.json` exists, its commit list replaces Git-derived discovery. Validation checks only that listed commits are reachable, ancestral, and correctly scoped; it never proves that all scoped commits before the completion boundary are listed. An edited manifest and matching SUMMARY can omit a risky plan-scoped commit, so its changed surfaces never reach approval classification.
**Fix:** Always derive the complete ordered set of exact-scope commits from Git history up to the unique completion boundary. Treat the manifest as an independent equality cross-check: resolve every manifest hash, reject duplicates, and require its ordered set to equal the Git-derived set exactly. Never let manifest contents select the reviewed commits.

---

_Reviewed: 2026-09-10T19:54:32Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
