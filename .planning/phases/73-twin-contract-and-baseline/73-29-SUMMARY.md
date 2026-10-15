---
phase: 73-twin-contract-and-baseline
plan: 29
status: complete
completed: 2026-09-23
commits:
  - 99bcc99
---

# Plan 73-29 Summary: Make governance task and descendant inputs total

## Outcome

Governance now parses singular balanced direct-child task fields before building semantic task records. Duplicate, malformed, or unmatched children cannot disappear through first/last/empty reduction, and tag-shaped text nested in action prose does not become a sibling field. Current and legacy tracked plans retain their existing policy handling.

Plan-shaped commits after a summary boundary are now assigned against exactly one tracked plan path before filtering to the current plan. Missing, unknown, or ambiguous scopes fail closed with diagnostics. Fixture histories cover those cases and multiple current-plan descendants.

The existing Plan 27 summary's duplicate task commit hash was corrected so provenance sees one unique claim. Three stale assertions in the evidence lane were updated to match current workflow ownership and append-only report chronology; the archived Plan 73-26 proof remains required and present.

## Verification

- `mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors` — passed, 2 tests.
- `mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors` — passed, 1 test.
- `mix ci.evidence` — passed after the parser/provenance and Plan 28 changes, 121 tests, 0 failures.
- `mix format` and `git diff --check` — passed.

The first evidence-lane attempt preceded Plan 28's new owner selector and failed as expected. The final lane passed after both dependent owner sets were in place.

## Scope and risks

Changes are confined to governance tests and their evidence assertions. No product/runtime code or remote Git state changed. The provenance rule deliberately rejects every plan-shaped descendant that cannot be mapped to exactly one tracked plan.

## Task Commits

1. **Tasks 1 and 2: Validate direct task children and all plan-shaped descendants** — `99bcc99`
