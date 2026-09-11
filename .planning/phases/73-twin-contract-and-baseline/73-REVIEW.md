---
phase: 73-twin-contract-and-baseline
reviewed: 2026-09-11T19:23:38Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - test/adoption/evidence_contract_test.exs
  - test/governance/milestone_scope_test.exs
  - test/support/adoption_evidence.ex
findings:
  critical: 6
  warning: 1
  info: 0
  total: 7
status: issues_found
---

# Phase 73: Code Review Report

**Reviewed:** 2026-09-11T19:23:38Z
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

The three scoped files contain six blocker-class fail-open paths in the evidence and governance gates, plus one filter-semantics defect. The existing scoped suite is green (`103 tests, 0 failures`), but it does not exercise the accepted counterexamples below. Direct probes confirmed that (1) deleting a governed path from both snapshot lists is accepted, (2) an owner command using `--stale` is accepted even when a subsequent run exits zero with `No stale tests`, and (3) a `security` job depending on a skipped job is still accepted as mandatory.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: The alleged authoritative inventory is forgeable with the candidate list

**Classification:** BLOCKER

**File:** `/Users/jon/projects/relyra/test/support/adoption_evidence.ex:361-369,483-489,573-580`

**Issue:** `governed_input_inventory` and `governed_inputs` are two ordinary fields in the same caller-supplied map. Validation checks only that they equal each other; it never checks either field against repository authority. A caller can delete `.planning/STATE.md` from both fields, add `.planning/STATE.md` to both workflow `paths-ignore` lists, and `validate_repository_snapshot!/2` returns `:ok`. This is the exact T-73-85/T-73-86 workflow-coverage bypass the new twin-field design claims to close. The new test mutates only `governed_inputs`, so it misses the two-field forgery.

**Fix:** Bind validation to authority outside the mutable candidate. For example, capture the expanded repository root and recompute only the governed inventory (not ExUnit discovery) during validation, then compare both supplied lists to that result:

```elixir
def validate_repository_snapshot!(entries, %{root: root} = snapshot) do
  authoritative_inputs = governed_inputs!(root)
  require_exact_inventory!(snapshot.governed_input_inventory, authoritative_inputs)
  require_exact_inventory!(snapshot.governed_inputs, authoritative_inputs)
  # continue with workflow and owner validation
end
```

Alternatively pass the original captured inventory as a separate, unmodified argument. Add a regression that removes or substitutes the same element in both map fields and asserts rejection before workflow reduction.

### CR-02: Unparsed Mix options can turn an accepted owner into a zero-test success

**Classification:** BLOCKER

**File:** `/Users/jon/projects/relyra/test/support/adoption_evidence.ex:855-890,986-1029`

**Issue:** The command grammar accepts arbitrary Mix-test options, while effective selection models only `--only` and `--exclude`. Selection-changing modes such as `--stale`, `--failed`, `--name-pattern`, `--partitions`, and `--profile-require` are silently ignored. A direct probe showed that `validate_automated_command!/2` returns `:ok` for `mix test test/adoption/evidence_contract_test.exs --stale --warnings-as-errors`; after the stale manifest is current, the real command prints `No stale tests` and exits 0. A plan can therefore satisfy executable/non-zero ownership with a command that executes no acceptance test.

**Fix:** Parse the complete Mix argv and reject every option outside a closed allowlist required by this contract. At minimum reject all incremental, historical, partition, name, profiling, alternate-exit, and formatter modes:

```elixir
@allowed_test_options ~w(--warnings-as-errors --only --exclude)

defp validate_test_argv!(arguments) do
  # consume owner paths and the allowed filters with their values;
  # reject every unconsumed token beginning with "-"
end
```

Add a regression that first seeds `--stale`, proves the second real invocation reports no tests with exit 0, and requires the validator to reject the command.

### CR-03: A skipped dependency can silently suppress the mandatory security job

**Classification:** BLOCKER

**File:** `/Users/jon/projects/relyra/test/support/adoption_evidence.ex:1267-1285`

**Issue:** `mandatory_security_step?/3` rejects a job-level `if`, but ignores `needs`. In GitHub Actions, a job whose dependency is skipped is itself skipped unless its conditional explicitly overrides that behavior. A probe that added a `never_runs` job with `if: false` and `needs: never_runs` to `jobs.security` was accepted by `validate_repository_snapshot!/2` as `:ok`, even though the Evidence contract step will never execute. This defeats the claimed mandatory CI ownership chain with a valid workflow construct.

**Fix:** Fail closed on job dependencies unless their execution semantics are parsed and proven mandatory. The safe contract is to forbid `needs` on `jobs.security`:

```elixir
with nil <- property_at_indent(security, "if", 4),
     nil <- property_at_indent(security, "needs", 4),
     :ok <- blocking_fallibility!(security, 4, "jobs.security") do
  # validate the exact Evidence contract step
end
```

Add a regression with a skipped prerequisite and assert that the diagnostic names `jobs.security needs`.

### CR-04: Malformed or attribute-free tasks disappear from governance

**Classification:** BLOCKER

**File:** `/Users/jon/projects/relyra/test/governance/milestone_scope_test.exs:2364-2395,3364-3389`

**Issue:** `plan_tasks/1` recognizes only `<task` tags followed by whitespace and attributes. `plan_scope_violations/3` never requires a non-empty task set and never compares raw task/acceptance tags with parsed tasks. Consequently an acceptance-bearing `<task>...</task>` with no attributes, an unterminated task, or a plan whose task block is emptied produces no task-type, risk-metadata, deterministic-owner, capability, or checkpoint checks. Risky action text and acceptance criteria can be hidden in an unparsed task while the surrounding unchanged scope assertions pass.

**Fix:** Parse a closed task grammar and fail whenever any task-shaped source is not consumed. At minimum require a non-empty parsed set and exact raw/parsed cardinality before reducing task semantics:

```elixir
raw_tasks = Regex.scan(~r/<task(?:\s|>)/, markdown) |> length()
tasks = plan_tasks(markdown)

cond do
  raw_tasks == 0 -> ["plan must contain at least one task"]
  raw_tasks != length(tasks) -> ["every task must use the closed task grammar"]
  true -> validate_tasks(tasks)
end
```

Also compare all `<acceptance_criteria>` occurrences to parsed task ownership. Add empty, attribute-free, unterminated, and nested-tag regressions.

### CR-05: Source changes co-committed with SUMMARY creation are never reviewed

**Classification:** BLOCKER

**File:** `/Users/jon/projects/relyra/test/governance/milestone_scope_test.exs:3525-3549,3562-3581,3595-3616`

**Issue:** The unique commit that adds `*-SUMMARY.md` is designated the completion boundary, then deliberately excluded from both `pre_boundary` (`commit != boundary`) and the post-boundary range (`boundary..endpoint`). There is no check that the boundary changes only planning bookkeeping. A completion commit can add the summary and change `lib/relyra.ex`, a security seam, `mix.exs`, or `.github/**`; those changes never reach `commit_changed_surfaces/2` and therefore require no plan-local approval checkpoint. The current test explicitly asserts that the completion commit is absent without proving its changed paths are harmless.

**Fix:** Keep the boundary out of Task Commits if desired, but always inspect its tree delta. Either append boundary changes to the provenance `changes` list or reject any boundary path outside an exact planning-bookkeeping allowlist:

```elixir
{:ok, task_changes} = commit_changed_surfaces(root, history.commits)
{:ok, boundary_changes} = commit_changed_surfaces(root, [boundary])
changes = task_changes ++ boundary_changes
```

Add a fixture where SUMMARY creation and a public-API change share the boundary commit and assert a `public_api` checkpoint violation.

### CR-06: Merge-commit changes collapse to an empty surface set

**Classification:** BLOCKER

**File:** `/Users/jon/projects/relyra/test/governance/milestone_scope_test.exs:3812-3848`

**Issue:** `commit_paths/2` invokes `git diff-tree --no-commit-id --name-only -r <commit>` without merge handling. For a merge commit, Git emits no per-parent diff under this invocation; this was reproduced against an existing repository merge, while adding `-m --first-parent` returned its changed paths. An exact-plan-scope merge can therefore introduce public API or protected-seam changes yet contribute `[]` to `commit_changed_surfaces/2`, bypassing approval classification.

**Fix:** Either reject merge commits in the trusted implementation set or analyze their first-parent delta explicitly:

```elixir
System.cmd("git", [
  "-C", root,
  "diff-tree", "-m", "--first-parent",
  "--no-commit-id", "--name-only", "-r", commit
])
```

Add a fixture that merges a branch containing a `lib/relyra.ex` signature change under an exact plan-scoped merge subject and assert that `public_api` is detected.

## Warnings

### WR-01: Multiple include filters are modeled as AND instead of ExUnit's OR semantics

**Classification:** WARNING

**File:** `/Users/jon/projects/relyra/test/support/adoption_evidence.ex:868-880,986-1055`

**Issue:** Effective counts require `Enum.all?(includes, ...)`, but ExUnit includes a test when any include filter matches (after normalization against exclusions). A probe using `--only plan_73_21_task_1 --only plan_73_21_task_2` ran two real tests successfully, while `validate_automated_command!/2` rejected the same command as zero-selection because no single test carries both tags. This incorrectly rejects valid deterministic owners and can block legitimate plan verification.

**Fix:** Reuse ExUnit's filter normalization/evaluation semantics, or faithfully implement `includes == [] or Enum.any?(includes, ...)` together with ExUnit's include-overrides-exclude and skip behavior. Add multi-include and include/exclude overlap regressions against the real Mix result.

---

_Reviewed: 2026-09-11T19:23:38Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
