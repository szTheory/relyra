---
phase: 73-twin-contract-and-baseline
reviewed: 2026-09-10T02:04:49Z
depth: standard
files_reviewed: 5
files_reviewed_list:
  - .github/workflows/security-gates.yml
  - mix.exs
  - test/support/adoption_evidence.ex
  - test/adoption/evidence_contract_test.exs
  - test/governance/milestone_scope_test.exs
findings:
  critical: 9
  warning: 0
  info: 0
  total: 9
status: issues_found
---

# Phase 73: Code Review Report

**Reviewed:** 2026-09-10T02:04:49Z
**Depth:** standard
**Files Reviewed:** 5
**Status:** issues_found

## Summary

The evidence lane is wired and its 53 scoped tests pass, but the governance implementation is not fail-closed. Nine blocker-class defects allow shell semantics, decoy Mix aliases, non-ExUnit syntax, alternate workflow configuration, incomplete phase discovery, legacy parsing, untrusted summary commit lists, or unverified remote payloads to satisfy or bypass the contracts. These are correctness and security-governance failures, not style concerns.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Shell comments and redirections bypass automated-command validation

**Classification:** BLOCKER
**File:** `test/support/adoption_evidence.ex:340-355`
**Issue:** The validator rejects only `[;&|`]` and `$(`, then interprets the command with `String.split/1`. It accepts shell operators that change the effective command. Both `mix test test/adoption/evidence_contract_test.exs --warnings-as-errors > /tmp/out` and `mix test test/adoption/evidence_contract_test.exs # --warnings-as-errors` return `:ok`; in the second case the shell discards the supposedly mandatory flag. Variable expansion, globbing, `<`, `>`, `#`, quoting, and escapes likewise are not represented by this tokenization. A plan can therefore obtain deterministic-evidence credit for a materially different command from the one the validator analyzed.
**Fix:** Do not validate shell text with a partial denylist. Represent verification as an executable plus an argument array and invoke it without a shell. If the Markdown format must remain textual, accept a deliberately narrow anchored grammar whose arguments contain only approved path/filter characters and reject every shell metacharacter, quote, escape, expansion, comment, and redirection. Add adversarial tests for `#`, `<`, `>`, `${...}`, `*`, quotes, and backslashes.

### CR-02: Removing one optional-looking tag downgrades active plans to the permissive legacy validator

**Classification:** BLOCKER
**File:** `test/governance/milestone_scope_test.exs:2062-2077`
**Issue:** `repository_plan_scope_violations/2` chooses the legacy validator solely when `<demand_gated_exclusions>` is absent. The legacy path omits approval-scope validation, per-task risk metadata, governed-surface classification, demand-gated exclusions, and forbidden-capability checks. Deleting that tag from an active plan therefore disables the new GOV-01/GOV-02 controls instead of producing a missing-contract violation. The repository-level test uses this dispatcher, so direct unit tests of `plan_scope_violations/2` do not protect the real gate.
**Fix:** Select the schema from trusted milestone/version metadata, not from the presence of an attacker-controlled tag. For every active v1.11 plan, always call `plan_scope_violations/2`; absence of `<demand_gated_exclusions>` must fail. Restrict legacy validation to an explicit, immutable set of historical completed plan paths if backward compatibility is required.

### CR-03: Active-plan discovery can become empty and pass vacuously

**Classification:** BLOCKER
**File:** `test/governance/milestone_scope_test.exs:40-53`
**Issue:** The repository gate derives all active plans from `incomplete_phase_numbers/1`, whose only accepted form is the exact regex `- [ ] **Phase N:` (`test/governance/milestone_scope_test.exs:1150-1154`). A formatting change, deletion, or alternate checkbox syntax in `ROADMAP.md` yields an empty list, after which `violations == []` passes without reviewing any plan. The companion automation-policy check uses the same discovery function, so it fails open at the same boundary.
**Fix:** Parse and validate the roadmap structure, assert that the set of active milestone phases equals the expected state from a trusted project-state source, and fail when discovery is empty while the milestone is active. Add controls that mutate/remove the active phase line and assert a diagnostic rather than a green zero-plan result.

### CR-04: Job-level `continue-on-error` makes the required evidence gate optional

**Classification:** BLOCKER
**File:** `test/support/adoption_evidence.ex:641-655`
**Issue:** `mandatory_security_step?/3` checks job-level `if` and step-level `if`/`continue-on-error`, but never checks `jobs.security.continue-on-error`. GitHub Actions supports `continue-on-error` at the job level; setting it to `true` allows a failing security matrix job to be treated as non-blocking while this validator still returns true. The adversarial workflow tests mutate only the step-level property, so their stated blocking-owner guarantee does not cover the job-level bypass.
**Fix:** Parse the workflow as YAML and require both the job and the evidence step to have no conditional and no truthy/dynamic `continue-on-error`. Add a fixture with `jobs.security.continue-on-error: true` and an expression-valued variant, and require both to fail validation.

### CR-05: Alternate planning ignore patterns bypass workflow-ownership validation

**Classification:** BLOCKER
**File:** `test/support/adoption_evidence.ex:728-747`
**Issue:** Planning-trigger validation recognizes only the literal ignore entry `.planning/**`. Equivalent GitHub path filters such as `.planning/*`, `.planning/**/**`, or broader patterns that exclude the planning tree are not detected. Conversely, when `paths:` is present it treats a literal `**` as sufficient without evaluating later negative patterns. Because this is a hand-written indentation/regex parser rather than GitHub workflow/path-filter semantics, the evidence validator can certify a workflow that does not run for the planning changes it is meant to govern.
**Fix:** Parse YAML, then evaluate the ordered GitHub glob patterns against representative required paths (for example the active plan, baseline, requirements, roadmap, and state files). Fail unless both pull-request and main-push triggers include every required path. Add adversarial fixtures for alternate ignores, broad ignores, and ordered negative `paths` patterns.

### CR-06: Mix alias ownership can be forged by unrelated AST tuples

**Classification:** BLOCKER
**File:** `test/support/adoption_evidence.ex:625-639`
**Issue:** `mix_aliases!/1` walks every tuple in `mix.exs` and treats any atom-key/list-value tuple as an alias entry. It does not locate the list returned by `aliases/0`. Unrelated public functions or literals placed before and after the real alias can make both `Enum.find_value`-based tests and the reducer see a valid `ci.evidence` tuple while the actual `aliases/0` entry is hollow (for example `cmd true`). The workflow then runs the hollow real alias and still passes.
**Fix:** Extract exactly the `defp aliases do ... end` AST and require a single literal definition for the target key, or load the Mix project and inspect the resolved project aliases. Reject duplicate target keys/definitions. Add a control containing valid decoy tuples around an invalid real alias.

### CR-07: Any macro named `test` is counted as executable ExUnit evidence

**Classification:** BLOCKER
**File:** `test/support/adoption_evidence.ex:424-455`
**Issue:** Selector ownership counts every top-level AST node shaped as `{:test, ...}` inside any module. It never establishes `use ExUnit.Case`, never expands the macro, and never checks the tests registered by ExUnit. A module can define its own no-op `test` macro, add `@moduletag :evidence_contract`, and contain zero executable ExUnit tests; this parser still counts it. The existing inert-source controls omit precisely this adversary. Because the lane also runs the governance file, the process can still exit successfully while the declared owner contributes no test.
**Fix:** Discover tests from ExUnit after compiling the owner in an isolated process, or require and validate an actual `use ExUnit.Case` module and reject local/imported shadowing of `test`. The stronger proof is to run the exact command with ExUnit trace/manifest output and require at least one selected test from each declared owner. Add a no-op custom `test` macro fixture that compiles to zero ExUnit tests.

### CR-08: Completed-plan change provenance trusts an arbitrary, incomplete commit list

**Classification:** BLOCKER
**File:** `test/governance/milestone_scope_test.exs:2112-2149`
**Issue:** For a completed plan, changed surfaces come only from hashes written under `## Task Commits` in its summary. The code verifies that each listed hash resolves, but never proves that the list contains the plan's actual commits, is contiguous, belongs to the phase, or covers all changed files. A summary can cite one harmless repository commit and omit the commit that changed a public API or security seam; `repository_plan_violations/2` then sees no risky class and does not require prior approval.
**Fix:** Derive the reviewed range from trusted execution metadata/manifest maintained by the orchestrator, and verify every phase commit is present exactly once and belongs to the expected ancestry/range. Treat any mismatch or uncovered commit as a provenance error. Add a test with a valid harmless hash plus an omitted risky phase commit.

### CR-09: Remote approval does not bind file-backed mutations to the approved desired/current state

**Classification:** BLOCKER
**File:** `test/governance/milestone_scope_test.exs:1569-1635`
**Issue:** Remote validation compares textual state/check sets with command targets, but the accepted mutation and rollback commands use `desired-protection.json` and `captured-current.json` without validating either file's existence, provenance, or contents. The setup-script variant is likewise accepted solely from repository/branch arguments. Those files/scripts can apply checks different from `desired_state`, and a read-back failure happens only after the unapproved mutation. Duplicate scalar fields are also silently reduced to the first match by `parse_remote_batch/1`, leaving an ambiguous approval document.
**Fix:** Require one occurrence of every remote-batch field. Resolve file-backed payloads as tracked, non-symlink repository files; parse their JSON and prove the mutation payload equals `desired_state` and the rollback payload equals the captured `current_state` contract. Bind script-backed mutations to a reviewed immutable script revision and its exact resulting check set. Add controls with mismatched payload contents, missing/untracked/symlink payloads, and duplicate scalar fields.

---

_Reviewed: 2026-09-10T02:04:49Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
