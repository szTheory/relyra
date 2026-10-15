---
phase: 79-adopter-ready-closeout
plan: 03
subsystem: governance
tags: [phase79, inventory, branch-protection, provenance, github-read-only]
requires:
  - phase: 79-02
    provides: Source-bound risk ledger, closeout, and inert remote-action boundary
provides:
  - Version 2 protection receipt that retains the complete modeled resource or records an incomplete capture
  - Fresh protected-main inventory and risk/closeout records bound to one observation
  - Explicit no-action record when complete current state and rollback cannot be established
affects: [phase-79, release-readiness, governance]
actuals:
  tokens: 18000
  tasks: 3
  commits: 4
tech-stack:
  added: []
  patterns: [complete-resource capture, fail-closed protection modeling, source-bound no-action records]
key-files:
  created:
    - .planning/phases/79-adopter-ready-closeout/79-PROTECTION-DESIRED.json
    - .planning/phases/79-adopter-ready-closeout/79-PROTECTION-ROLLBACK.json
  modified:
    - scripts/collect_phase79_inventory.py
    - test/governance/milestone_scope_test.exs
    - .planning/phases/79-adopter-ready-closeout/79-INVENTORY.json
    - .planning/phases/79-adopter-ready-closeout/79-INVENTORY.md
    - .planning/phases/79-adopter-ready-closeout/79-RISKS.json
    - .planning/phases/79-adopter-ready-closeout/79-CLOSEOUT.md
    - .planning/phases/79-adopter-ready-closeout/79-REMOTE-BATCH.md
key-decisions:
  - "An allowed protection GET is incomplete when required settings are omitted; readiness stays unknown until every modeled setting is captured."
  - "No remote batch or approval request is prepared without a complete current resource and exact rollback payload."
  - "Unknown local paths remain preserved; the two new proposal records are Phase 79-owned and GSD execution state is classified separately."
requirements-completed: [REPO-01, REPO-02, REPO-03, EXIT-01]
coverage:
  - id: D1
    description: "The production collector retains all modeled branch-protection settings and rejects incomplete or unmodeled responses."
    requirement: REPO-02
    verification:
      - kind: integration
        ref: "ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/governance/milestone_scope_test.exs --warnings-as-errors (87 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The inventory, local owner dispositions, risk ledger, and closeout bind to one fresh observation."
    requirement: REPO-01
    verification:
      - kind: unit
        ref: "python3 scripts/collect_phase79_inventory.py --verify .planning/phases/79-adopter-ready-closeout/79-INVENTORY.json"
        status: pass
      - kind: integration
        ref: "ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/governance/milestone_scope_test.exs --warnings-as-errors (87 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D3
    description: "An incomplete protection observation produces no executable batch or approval request."
    requirement: REPO-03
    verification:
      - kind: integration
        ref: "ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/governance/milestone_scope_test.exs --warnings-as-errors (87 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D4
    description: "The High readiness blocker remains visible with a precise source and owner boundary."
    requirement: EXIT-01
    verification:
      - kind: unit
        ref: "python3 scripts/collect_phase79_inventory.py --verify .planning/phases/79-adopter-ready-closeout/79-INVENTORY.json"
        status: pass
      - kind: integration
        ref: "ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/governance/milestone_scope_test.exs --warnings-as-errors (87 tests, 0 failures)"
        status: pass
    human_judgment: false
duration: 58min
completed: 2026-09-30
status: complete
---

# Phase 79 Plan 03: Complete Protection Capture and Closeout Summary

**A complete-resource collector contract now fails closed, and the current protected-main closeout remains blocked on absent lane evidence and omitted protection settings.**

## Performance

- **Duration:** 58 min
- **Started:** 2026-09-30T15:57:56Z
- **Completed:** 2026-09-30T16:56:10Z
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments

- Bumped the Phase 79 inventory schema to version 2. A complete protection GET retains every modeled configuration setting, check-app association, and actor identity while removing only known API/profile metadata. Missing, unmodeled, unsafe, or oversized data produces an incomplete capture and unknown readiness.
- Added positive and negative production-collector fixtures for full resource capture, dropped settings, unknown nested fields, secret-shaped values, oversized responses, and tampered persisted resources. The fixtures also preserve Phase 79 ownership of its new payload artifacts and classify GSD execution state separately.
- Refreshed the live inventory, local disposition report, risk ledger, and decision-first closeout against `szTheory/relyra@refs/heads/main` SHA `c786a9890f2f99f0dd98f89a1d9713db7c486837`, observed `2026-09-30T16:51:05Z`. Main revalidation matched. All nine mandatory lanes remain absent.
- Recorded that the protection GET was allowed but incomplete because it omitted `required_pull_request_reviews` and `restrictions`. The expected configuration candidate is stored for review; no rollback payload, executable batch, or approval request was produced. Readiness remains unknown and release remains blocked.

## Task Commits

1. **Task 1 RED: protection-resource contract test** — `708a9c6` (test)
2. **Task 1 GREEN: complete protection-resource capture** — `6be2584` (feat)
3. **Plan contract corrections before execution** — `837b9de4046e557e4458b6949a531d4c6291cd09` (docs)
4. **Task 1 follow-up: classify proposal artifacts** — `faa82cb` (fix)
5. **Task 1 follow-up: classify GSD execution state** — `0849442` (fix)

Task 2 and Task 3 artifacts are included in this summary's completion-boundary documentation commit.

## Files Created/Modified

- `scripts/collect_phase79_inventory.py` — full protection-resource capture, validation, and Phase 79/GSD local ownership classification.
- `test/governance/milestone_scope_test.exs` — complete-resource, no-action, source identity, and local ownership assertions.
- `79-INVENTORY.json` and `79-INVENTORY.md` — verified live receipt and owner-aware report.
- `79-RISKS.json` and `79-CLOSEOUT.md` — refreshed blocker evidence and decision-first verdict.
- `79-PROTECTION-DESIRED.json` — exact output from the expected-configuration printer; reference only under the incomplete capture.
- `79-PROTECTION-ROLLBACK.json` — explicit record that no rollback payload can be formed.
- `79-REMOTE-BATCH.md` — current-source no-action record; no mutation or approval requested.

## Decisions Made

- The collector does not infer omitted settings as disabled. The missing fields keep the complete-resource status incomplete.
- The user-facing approval gate stays unavailable until a complete current resource and verified rollback payload exist.
- The partial required-context list is reported as partial because the full resource was not returned.

## Deviations from Plan

### Auto-fixed governance gaps

1. The gap-plan documents lacked required acceptance criteria and some risk/exclusion metadata. These contracts were added as the active-plan governance checks surfaced them; the missing 79-04 metadata was fixed at handoff before that plan executes.
2. The summary-commit parser missed a second commit hash on the same task row. It now extracts every hash from a task row.
3. Local inventory ownership omitted the new desired/rollback outputs and GSD execution state. The classifier and fixtures now label those known paths while leaving unrelated paths unknown and preserved.
4. Plan policy accepts deterministic Mix test/alias owners, not raw Python commands. The plan uses the mandatory governance test as its executable owner; the production collector verifier was also run directly against the fresh receipt.

**Total deviations:** 4 auto-fixed governance/input gaps.
**Impact on plan:** Each correction was required for truthful provenance and mandatory governance coverage. No product API, default, security policy, or remote state changed.

## Issues Encountered

The live protection GET omitted two required settings. The capture was recorded as incomplete; no attempt was made to infer values, create a rollback payload, dispatch workflows, or write branch protection.

## User Setup Required

None — no external service configuration is required.

## Next Plan Readiness

Plan 79-04 can validate the no-action artifact and reconcile local proof provenance. The protected-main readiness criterion remains open. Plan 79-05 must not present an approve option while the full protection resource and rollback payload are unavailable.

---
*Phase: 79-adopter-ready-closeout*
*Completed: 2026-09-30*
