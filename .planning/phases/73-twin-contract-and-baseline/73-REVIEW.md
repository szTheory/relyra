---
phase: 73-twin-contract-and-baseline
reviewed: 2026-09-11T05:04:38Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - test/adoption/evidence_contract_test.exs
  - test/support/adoption_evidence.ex
findings:
  critical: 1
  warning: 1
  info: 0
  total: 2
status: issues_found
---

# Phase 73: Code Review Report

**Reviewed:** 2026-09-11T05:04:38Z
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

The Plan 73-17/18 changes close all three findings from the prior report: repository validation now captures registered tags once per owner and reuses a pure snapshot, the workflow matcher rejects unsupported GitHub glob syntax, and owner provenance rejects symlink components and non-tracked lexical paths. The replacement discovery cache still does not provide its claimed cross-process single-flight guarantee, however, because each caller uses a different global lock identifier. Snapshot shape validation also labels governed inputs as normalized without enforcing normalization or preserving the required governed-input set.

The focused Plan 73-17/18 selector passed 9 tests with no failures. The five current `mix ci.evidence` failures caused by `.planning/STATE.md` entering `ready_for_verification` are in `test/governance/milestone_scope_test.exs`, outside this incremental file scope, and are not counted below; they remain a known gate blocker.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Per-caller lock identifiers defeat single-flight owner discovery

**File:** `test/support/adoption_evidence.ex:670-687`

**Issue:** `registered_test_tags!/2` attempts to serialize a cache miss with `:global.trans({cache_key, self()}, ...)`. Including `self()` makes the lock identifier different for every concurrent test process, so two callers that miss the same `:persistent_term` key do not contend on the same lock. Both can enter `discover_registered_test_tags!/2` and launch duplicate Elixir/BEAM probes for the same owner. Because evidence modules run asynchronously and multiple tests call `validate_repository!/2`, this preserves the process fan-out and timeout race that Plan 73-17 was intended to remove. Passing focused tests does not exercise the concurrent cache-miss boundary.

**Fix:** Lock on a caller-independent resource identifier, then repeat the cache check inside the lock. For example:

```elixir
lock_id = {__MODULE__, :registered_test_tags, cache_key}

:global.trans(lock_id, fn ->
  case :persistent_term.get(cache_key, :missing) do
    :missing ->
      tags = discover_registered_test_tags!(path, root)
      :persistent_term.put(cache_key, tags)
      tags

    tags ->
      tags
  end
end)
```

Add a barrier-controlled concurrency regression that starts multiple callers before the cache is populated and asserts the discovery function runs exactly once.

## Warnings

### WR-01: Snapshot validation accepts substituted and non-normalized governed inputs

**File:** `test/support/adoption_evidence.ex:482-490`

**Issue:** The snapshot validator only requires `governed_inputs` to be a non-empty unique list of non-empty strings. It does not enforce the diagnostic's claimed normalization rule (relative paths with no `.`/`..` components), lexical ordering, or equality with the required governed-input inventory. A pure snapshot mutation can therefore replace the captured inventory with a harmless value such as `["README.md"]`; workflow validation then stops checking every Phase 73 planning and evidence input and may return `:ok`. This leaves an untested degenerate snapshot field despite Plan 73-17 requiring all snapshot fields to fail closed. The normal `validate_repository!/2` capture path supplies the real inventory, so this is a robustness defect in the exported pure-validation seam rather than a direct workflow bypass.

**Fix:** Store or derive an immutable expected inventory and require exact equality (including stable lexical order) during `validate_snapshot_shape!/2`. At minimum, validate every value with the same normalized repository-relative path grammar used for owners and reject missing, unexpected, or reordered governed paths with deterministic diagnostics. Add mutations for omission, substitution, `../` escape, absolute path, and unstable order.

---

_Reviewed: 2026-09-11T05:04:38Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
