---
gsd_state_version: 1.0
milestone: v1.11
milestone_name: Phases
current_phase: 73
current_phase_name: Twin Contract and Baseline
status: executing
stopped_at: Completed 73-06-PLAN.md
last_updated: "2026-09-10T01:07:52.391Z"
last_activity: 2026-09-09
last_activity_desc: Phase 73 Plan 06 completed
state_head: 39ad76c292f39919b469c5a5703804d9a5bff563
progress:
  total_phases: 7
  completed_phases: 0
  total_plans: 8
  completed_plans: 6
  percent: 75
---

# Project State

## Project Reference

See `.planning/PROJECT.md`.

**Core value:** Every SAML login ends in a verified trust path or a typed rejection —
never a silent compromise. Trust mutations are durable, attributable, and reviewable.

**Current focus:** Phase 73 — Twin Contract and Baseline

## Current Position

Phase: 73 (Twin Contract and Baseline) — EXECUTING

Plan: 6 of 8

Status: Executing Phase 73 gap closure

Last activity: 2026-09-09 — Phase 73 Plan 06 completed

## Milestone Metrics

- Last shipped milestone: v1.10 Docker DX & Fleet Proxy (Phases 68–72.1, shipped 2026-08-27)
- Current milestone: v1.11 First-Adopter Twin
- Requirements: 37 total, 37 mapped, 0 unmapped
- Planned phases: 7
- Highest shipped phase: 72.1
- Baseline `mix qa`: 794 tests, 0 failures on Elixir 1.19.5/OTP 28 (2026-09-09)

## Accumulated Context

### Decisions

- Use two cooperating twins: LedgerLoop for adopter/product realism and a clean-room
  Phoenix consumer for the publishable package boundary.
- The clean-room consumer builds and unpacks the local Hex artifact and cannot see root
  test support or checkout-only files.
- Deepen LedgerLoop/Northstar instead of creating a new demo theme or external repository.
- Fix adopter-significant findings in this milestone, stopping for public API, default,
  security-posture, SemVer-major, and remote GitHub changes.
- Keep scope feature-neutral. `AUTHN-POST-01`, `KMS-01`, and `SIGNED-META-01` remain
  demand-gated.
- New acceptance criteria require deterministic automated evidence in mandatory CI;
  external services remain scheduled canaries.
- Perform cleanup behind the twin's evidence and stop at diminishing returns rather than
  pursuing aesthetic purity.
- [Phase 73]: Use a closed, test-only Elixir ledger whose planned rows remain visible but cannot satisfy deterministic closure.
- [Phase 73]: Treat only existing non-canary rows with a real tagged test, fresh-process alias, and executable workflow command as closure evidence.
- [Phase 73]: Treat the quality/CI baseline as inventory only; one-run timings are samples and remediation stays routed to Phases 74, 77, 78, or 79.
- [Phase 73]: Keep live required-check repair behind remote_github approval in Phase 79 and preserve the exact desired/current context drift as a release blocker.
- [Phase 73]: Accept baseline rows only through anchored tables, closed enums, severity rules, ownership fields, and redaction-safe evidence.
- [Phase 73]: Require each risky mutation to have a matching plan-local blocking approval_class checkpoint before the first mutation task.
- [Phase 73]: Require remote GitHub approval to describe one exact reversible batch with preflight, rollback, read-back, and resume signal.
- [Phase 73]: Keep authorization separate from completion; only deterministic automated evidence can close acceptance criteria.
- [Phase 73]: Count evidence selectors only when parsed ExUnit source associates them with real test definitions.
- [Phase 73]: Recognize evidence workflow ownership only in the enabled blocking Evidence contract step under jobs.security.
- [Phase 73]: Require every acceptance-bearing non-checkpoint task to own executable non-zero proof independently.
- [Phase 73]: Task risk metadata is mandatory but governed files, entry points, and diffs independently determine approval. — Optimistic declarations cannot suppress a matching plan-local checkpoint.
- [Phase 73]: Remote approval is one parsed reversible batch bound to the same repository, branch, checks, and captured state. — Keyword prose cannot authorize an ambiguous or non-reversible remote mutation.
- [Phase 73]: Demand-gated identifiers are allowed only in the exact plan-level exclusion and fixture-data regions. — Task names, files, and actions have no negation or policy-prose exemption.
- [Phase 73]: Each baseline finding requires one complete allowed repository or executable verification reference. — Arbitrary non-empty provenance prose cannot satisfy the baseline contract.
- [Phase 73]: Model direct-test ownership as enabled include-tag intersection minus matching exclusions, rejecting an empty effective set.
- [Phase 73]: Treat the Evidence contract as mandatory only when jobs.security has one exact unconditional step with absent or literal-false fallibility.

### Baseline Findings

- Root adoption journeys execute inside Relyra and use private fixtures; they do not yet
  prove the Hex package as a clean-room consumer.
- LedgerLoop already has strong narrative and real-IdP foundations worth expanding.
- Standalone source/docs contain temporary phase, plan, decision-code, and UAT references.
- Root QA has one known incomplete-phase vocabulary-policy failure and reports Mix
  test-pattern warnings; both are inventoried for Phase 77.
- Recent main and recurring Fleet/Keycloak canaries are green; CI topology still needs
  measured duration and ownership analysis.
- Live GitHub inventory currently shows no open issues or pull requests and several old
  branches; refresh before proposing any action.
- The untracked user-owned `.tool-versions` selects Node only. Use explicit installed
  Elixir/Erlang versions for local validation unless the owner changes that file.

### Guardrails

- Never trust XML `KeyInfo`; use configured IdP certificates only.
- Keep the single Saxy parse path and raw-binary pre-parse guards.
- Require digest recomputation and genuine `:public_key.verify` signature verification.
- Co-commit every trust mutation and audit row in one transaction.
- Preserve production replay protection and the fresh-process `mix ci.security` suites.
- Do not manually publish Hex or hand-edit `CHANGELOG.md`.

## Deferred Items

| Item | Status |
|---|---|
| AUTHN-POST-01 | Demand-gated |
| KMS-01 | Demand-gated |
| SIGNED-META-01 | Demand-gated |
| Hosted external twin | Deferred until the local package twin proves insufficient |
| Exhaustive compatibility matrix | Deferred until adopter evidence justifies its cost |

## Session Continuity

**Last session:** 2026-09-10T01:07:52.373Z

**Stopped at:** Completed 73-06-PLAN.md

**Resume file:** None

## Operator Next Step

Execute Phase 73 gap-closure Plans 73-07 and 73-08, then re-run verification against
the eight completed plan summaries and mandatory evidence contract.

## Performance Metrics

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 73 P01 | 9min | 2 tasks | 4 files |
| Phase 73 P02 | 20min | 2 tasks | 5 files |
| Phase 73 P03 | 17min | 2 tasks | 4 files |
| Phase 73 P04 | 12min | 2 tasks | 3 files |
| Phase 73 P05 | 24min | 3 tasks | 1 files |
| Phase 73 P06 | 9min | 2 tasks | 2 files |

### Blockers

- Phoenix was upgraded from 1.8.7 to 1.8.13 in `ae1f0aa`, resolving GHSA-63mc-hw7g-86rr and high-severity GHSA-6983-jfq8-485w; `mix ci.security` now passes.
