---
phase: 73-twin-contract-and-baseline
plan: 28
status: complete
completed: 2026-09-23
commits:
  - 3defa54
---

# Plan 73-28 Summary: Bind triggers and mandatory reconciliation

## Outcome

Workflow trigger evidence now comes only from direct children of one exact top-level `on:` mapping. The mandatory `jobs.security` contract now includes one unconditional Phase 73 reconciliation step after Evidence contract. A flat fresh-process Mix alias selects a dedicated replay owner that validates checked-in reports and proof, then replays the required evidence lanes without recursion.

The adoption snapshot validates the top-level trigger owner and reconciliation alias, selector, test owner, and workflow-step chain. Mutation coverage rejects malformed or nested trigger declarations and missing, moved, duplicated, renamed, conditional, fallible, recursive, or orphaned replay ownership.

## Verification

- `mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors` — passed, 1 test.
- `mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors` — passed, 2 tests.
- `mix ci.evidence` — passed, 121 tests, 0 failures.
- `actionlint .github/workflows/security-gates.yml` — passed.
- `mix format` and `git diff --check` — passed.

The mandatory lane was run after Plan 29's parser/provenance updates because the lane verifies the combined evidence owners. Plans 28 and 29 were executed in dependency-compatible order for this reason.

## Scope and risks

No public/runtime API, security policy, or remote GitHub state changed. Workflow parsing remains dependency-free. The mandatory workflow now performs the real reconciliation replay in a separate Mix process, increasing CI work by that bounded replay.

## Task Commits

1. **Tasks 1 and 2: Bind required events and wire mandatory reconciliation** — `3defa54`
