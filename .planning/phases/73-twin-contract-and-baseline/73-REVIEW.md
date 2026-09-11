---
phase: 73-twin-contract-and-baseline
reviewed: 2026-09-11T23:25:40Z
depth: standard
files_reviewed: 4
files_reviewed_list:
  - test/adoption/evidence_contract_test.exs
  - test/governance/milestone_scope_test.exs
  - test/support/adoption_evidence.ex
  - test/support/phase_73_reconciliation.ex
findings:
  critical: 7
  warning: 1
  info: 0
  total: 8
status: issues_found
---

# Phase 73: Code Review Report

**Reviewed:** 2026-09-11T23:25:40Z
**Depth:** standard
**Files Reviewed:** 4
**Status:** issues_found

## Summary

The gap-closure implementation still contains seven blocker-class fail-open paths in its proof, workflow, plan, and Git-provenance contracts, plus one repository-root attribution defect. Direct probes confirmed that the workflow validator accepts a document after its real `on:` key is removed, final reconciliation accepts incorrect live statuses when matching decoy strings are appended, and positive evidence counts can be altered without changing the proof-set identity. The focused Plan 73-26 tests remain green (2 tests, 0 failures), but they validate synthetic fixture documents rather than the checked-in proof and reports.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Proof-set identity is not verified against the recorded results

**Classification:** BLOCKER

**File:** `/Users/jon/projects/relyra/test/support/phase_73_reconciliation.ex:64-74,367-420`

**Issue:** `capture!/2` derives `proof_set_id` from the source digest and normalized result vectors, but `validate_proof!/2` only checks that the supplied ID begins with `phase73-`. It never recomputes the digest. A direct probe loaded the checked-in proof, incremented all three evidence-run test counts, retained the original `proof_set_id`, embedded the modified proof in both generated final documents, and `validate_documents!/4` returned `:ok`. Any positive fabricated counts therefore remain valid under an identity that purports to bind the original results.

**Fix:** Rebuild the exact `normalized_results` map used by `capture!/2` during validation and require exact equality with the recomputed ID:

```elixir
expected_id =
  ("phase73-" <>
     sha256(proof["source_digest"] <> Jason.encode!(normalized_results(proof))))
  |> binary_part(0, 24)

require_equal!(proof["proof_set_id"], expected_id, "proof set identity")
```

Add a regression that changes a positive summary count while leaving the old ID in place and requires rejection.

### CR-02: Final report state is satisfied by decoy substrings outside frontmatter

**Classification:** BLOCKER

**File:** `/Users/jon/projects/relyra/test/support/phase_73_reconciliation.ex:121-137,339-350,640-646`

**Issue:** Final-state detection and field validation use document-wide `String.contains?/2`. They do not parse singular frontmatter fields or constrain status text to the live report header. The real reports already contain historical prose mentioning old statuses. A direct probe changed the generated final security status to `issues_found` and validation status to `gaps_found`, appended `status: verified` and `status: validated` as decoys, and `validate_documents!/4` returned `:ok`. The same weakness applies to `threats_open` and `nyquist_compliant`, so an open report can be approved as final.

**Fix:** Parse the first exact frontmatter block, require each governed field exactly once, and compare typed values there. Require unique staged/final markers and validate closure rows only in the section after the final marker; do not use document-wide substring checks for live state.

### CR-03: Required workflow events are not anchored beneath the `on` mapping

**Classification:** BLOCKER

**File:** `/Users/jon/projects/relyra/test/support/adoption_evidence.ex:1458-1523`

**Issue:** `required_planning_triggers!/2` searches the entire workflow for two-space-indented `pull_request:` and `push:` lines without first locating a unique top-level `on:` block. A direct probe renamed the checked-in `on:` key to `env:` while leaving those nested lines unchanged; `validate_repository_snapshot!/3` still returned `:ok`. The evidence contract can therefore approve a workflow with no usable mandatory PR/push trigger at all.

**Fix:** Parse a unique exact top-level `on:` mapping and pass only its bounded child block to `required_event_contract!/3`. Prefer a duplicate-key-rejecting YAML parser; if the closed text grammar is retained, explicitly require one `on:` header, reject unsupported direct children, and stop the block at the next top-level key. Add a regression that removes or renames `on:` while retaining decoy event text.

### CR-04: Security-suite removal lowers the expected constituent count instead of failing

**Classification:** BLOCKER

**File:** `/Users/jon/projects/relyra/test/support/phase_73_reconciliation.ex:54-60,403-419,542-567`

**Issue:** The expected security summary count is derived from whatever test-bearing commands remain in the current `ci.security` alias. `security_constituent_commands!/0` silently drops every non-test leaf, and validation only requires the proof list to have the same reduced length. Replacing twelve of the thirteen security suites with non-test steps leaves one derived constituent; one successful ExUnit summary then satisfies capture and validation. This directly violates the repository invariant that every security suite remains an independent mandatory `cmd mix test` process.

**Fix:** Pin the exact ordered security constituent command set (or an independently governed manifest) and reject every unknown/non-test leaf during recursive expansion. Require exactly 13 unique commands and exact equality before executing or validating the aggregate lane.

### CR-05: Mandatory CI never validates the checked-in proof or reports

**Classification:** BLOCKER

**File:** `/Users/jon/projects/relyra/test/governance/milestone_scope_test.exs:506-623`

**Issue:** Both Plan 73-26 tests build `fixture_proof!/1` and `fixture_documents!/2`. The final test merely asserts that `validate_repository!/1` is exported; it never calls it. Repository-wide search found no caller for `Relyra.Phase73Reconciliation.validate_repository!/1`, `verify_focused_and_evidence!/1`, or `verify_security_lane!/1` outside their definitions. Consequently the mandatory `ci.evidence` lane can stay green if the checked-in proof is deleted, the real reports drift, or the fresh evidence/security results no longer match the proof.

**Fix:** Add a fast mandatory assertion against the real artifacts:

```elixir
assert :ok = Relyra.Phase73Reconciliation.validate_repository!(File.cwd!())
```

Wire the fresh focused/evidence and security replay functions into non-recursive mandatory CI owners (separate aliases/jobs so `ci.evidence` does not invoke itself), and assert those owners in the workflow contract.

### CR-06: Duplicate task child sections erase risky intent before governance

**Classification:** BLOCKER

**File:** `/Users/jon/projects/relyra/test/governance/milestone_scope_test.exs:3839-3860,4465-4475`

**Issue:** The closed task parser validates task and acceptance tags, but `tag_content/2` converts every missing or duplicate `name`, `action`, `files`, `verify`, or `resume-signal` section to the empty string. There is no cardinality/closedness validation for those children. Adding a second `<action>` containing a public-API or security-posture mutation makes `task.action` empty, so governed-surface classification never sees the risky text; similarly, a second `<files>` hides protected paths. With unchanged risk metadata and a valid acceptance/verify section, the plan passes without the required approval checkpoint.

**Fix:** Parse task children with a closed, linearly consumed grammar. Require exactly one non-empty `name`; exactly one non-empty `action`, `files`, `verify`, `risk_metadata`, and `acceptance_criteria` for implementation tasks; and the exact checkpoint-specific fields for decision tasks. Reject duplicates before semantic reduction. Add duplicate-action and duplicate-files smuggling regressions.

### CR-07: A foreign-scoped descendant commit is intentionally omitted from all plan review

**Classification:** BLOCKER

**File:** `/Users/jon/projects/relyra/test/governance/milestone_scope_test.exs:371-378,4215-4232`

**Issue:** Post-summary provenance retains only commits whose subject scope exactly equals the plan ID. The `post_summary_foreign` regression explicitly accepts a risky descendant with another scope and expects it to disappear from provenance. A commit such as `fix(73-98): ...` can therefore modify `lib/relyra.ex` or a protected security seam after a completed plan even when no `73-98-PLAN.md` exists; no active plan receives its changed surfaces, so no approval checkpoint is required. Commit subjects are attacker-controlled metadata and cannot be the authority for whether a repository change is reviewed.

**Fix:** Build the descendant commit range independently of subject scope, classify every changed surface, and then require each commit to map to exactly one existing governed plan. Foreign or nonexistent scopes must be explicit violations, not filtered out. Keep unrelated commits only when another reviewed plan demonstrably owns them.

## Warnings

### WR-01: Security constituents are read from ambient Mix state instead of the supplied root

**Classification:** WARNING

**File:** `/Users/jon/projects/relyra/test/support/phase_73_reconciliation.ex:45-60,161-169,382-404,542-546`

**Issue:** Public capture and verification functions accept a repository `root`, and commands execute with `cd: root`, but `security_constituent_commands!/0` reads `Mix.Project.config()` from the ambient VM. Against another checkout or fixture with a different `mix.exs`, summaries from the supplied root are zipped with commands from the caller's project. Equal list lengths can produce a falsely attributed proof; unequal lengths cause a false rejection.

**Fix:** Change the helper to `security_constituent_commands!(root)` and inspect aliases from that root in a fresh process, using the same explicit-root strategy already implemented by `AdoptionEvidence.mix_aliases!/1`. Pass `root` through every capture and validation call.

---

_Reviewed: 2026-09-11T23:25:40Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
