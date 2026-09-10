---
phase: 73-twin-contract-and-baseline
reviewed: 2026-09-10T21:55:47Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - .github/workflows/security-gates.yml
  - mix.exs
  - test/adoption/evidence_contract_test.exs
  - test/governance/milestone_scope_test.exs
  - test/support/adoption_evidence.ex
findings:
  critical: 3
  warning: 0
  info: 0
  total: 3
status: issues_found
---

# Phase 73: Code Review Report

**Reviewed:** 2026-09-10T21:55:47Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

Plans 73-12 and 73-13 close the originally reported empty-alias, positive-path-filter, discarded branch-protection-field, and manifest-selection reproductions (former CR-01, CR-02, CR-03, and CR-05). The mandatory `mix ci.evidence` lane also passes 82 tests. However, the hardened contracts still contain three fail-open authorization paths: valid GitHub event filters can suppress the supposedly mandatory workflow, an unrelated static JSON file can authorize arbitrary indexed mutation code, and same-plan commits after the SUMMARY-add boundary are never inspected. The script defect is a transformed continuation of former CR-04; the other two are new bypasses exposed by tracing the gap-closure logic beyond its fixtures.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-06: Valid event filters can suppress the mandatory evidence workflow

**Classification:** BLOCKER
**File:** `test/support/adoption_evidence.ex:850-873`
**Issue:** `required_planning_triggers!/2` treats `push.branches` as an unordered membership list and ignores the rest of each event's filter grammar. GitHub branch patterns are ordered, so `branches: [main, "!main"]` is a valid configuration that excludes `main`; the validator sees the positive `main` entry and returns `:ok`. This bypass was reproduced against `validate_repository!/2`. Likewise, a restrictive `pull_request.types` block is never inspected and can omit the normal `opened`, `reopened`, and `synchronize` activity that must gate code changes. Plan 73-12 correctly rejects positive path filters but therefore does not establish that the required events actually run for the required branch/activity set.
**Fix:** Parse a closed event schema. For `push`, require an exact non-negated `branches: [main]` value and reject `branches-ignore` and additional/negative patterns. For `pull_request`, either forbid `types` or require a set containing every merge-gating activity (`opened`, `reopened`, and `synchronize`). Reject duplicate event keys and unsupported event-level filters so unparsed YAML cannot change trigger semantics.

### CR-07: Unrelated static JSON authorizes arbitrary mutation script behavior

**Classification:** BLOCKER
**File:** `test/governance/milestone_scope_test.exs:522-528, 1632-1647, 3089-3117`
**Issue:** The non-execution fix validates the script's current index object and separately parses `mutation_result_source`, but it never binds the JSON result to that script object or proves the script implements that state. The regression fixture explicitly replaces the approved script with code that writes files, reads credential presence, or contacts the network, stages it, pairs it with the unchanged benign `predicted-protection.json`, and asserts that authorization has no violations. Validation no longer executes attacker code, but it now approves attacker code for later execution based solely on an unrelated declaration. The retrieved `indexed_oid` is discarded after the working-tree comparison and is not pinned in the approved batch.
**Fix:** Prefer removing script-backed remote mutations and authorize only the already-supported declarative `gh api ... --input <tracked-json>` operation. If script support must remain, the approved batch must pin the exact script blob OID and a trusted, independently generated attestation binding that OID to the normalized result; verify both against the index and reject arbitrary script/result pairings. A plan-authored result file alone cannot attest to executable behavior.

### CR-08: Same-plan commits after the SUMMARY boundary bypass changed-surface review

**Classification:** BLOCKER
**File:** `test/governance/milestone_scope_test.exs:3507-3569`
**Issue:** `completion_boundaries/3` defines the boundary as the commit that first adds the SUMMARY, and `trusted_plan_commits/3` searches only that commit's ancestry. It never scans descendants through the governed review point or rejects a later commit with the same plan scope. Consequently, adding a valid SUMMARY and then committing `fix(73-99): ...` can change a public API, security seam, or remote workflow without that commit entering `derived`, the manifest equality check, the SUMMARY equality check, or `commit_changed_surfaces/2`. The new Git-first logic prevents a manifest from hiding commits before the boundary, but remains fail-open for scoped implementation or hardening commits after it.
**Fix:** Establish an explicit review endpoint (normally the current governed `HEAD`) and derive all exact-scope commits in the range through that endpoint. Either include post-SUMMARY same-plan commits and require the SUMMARY/manifest to be updated to match, or reject any exact-scope descendant of the completion boundary. Add an adversarial fixture that creates a risky same-plan commit after SUMMARY creation and requires provenance validation to fail closed while still surfacing that commit's changed classes.

---

_Reviewed: 2026-09-10T21:55:47Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
