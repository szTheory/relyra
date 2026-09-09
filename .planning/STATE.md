---
gsd_state_version: 1.0
milestone: v1.11
milestone_name: Phases
current_phase: 73
current_phase_name: Twin Contract and Baseline
status: executing
stopped_at: Phase 73 gap-closure plans 04-05 ready to execute
last_updated: "2026-09-09T20:37:34.517Z"
last_activity: 2026-09-09
last_activity_desc: Phase 73 gap-closure planning completed
state_head: 5fdc516ee1e7763b03d8acafb92f38af11868e99
progress:
  total_phases: 7
  completed_phases: 0
  total_plans: 5
  completed_plans: 3
  percent: 60
---

# Project State

## Project Reference

See `.planning/PROJECT.md`.

**Core value:** Every SAML login ends in a verified trust path or a typed rejection —
never a silent compromise. Trust mutations are durable, attributable, and reviewable.

**Current focus:** Phase 73 — Twin Contract and Baseline

## Current Position

Phase: 73 (Twin Contract and Baseline) — READY TO EXECUTE

Plan: 3 of 5

Status: Ready to execute

Last activity: 2026-09-09 — Phase 73 gap-closure planning completed

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

**Last session:** 2026-09-09T20:12:18.558Z

**Stopped at:** Phase 73 context gathered (assumptions mode)

**Resume file:** .planning/phases/73-twin-contract-and-baseline/73-CONTEXT.md

## Operator Next Step

Replan Phase 73 from `73-CONTEXT.md` and the fail-open gaps in `73-VERIFICATION.md`,
retaining the documented QA and Phoenix advisory blockers for their downstream owners.

## Performance Metrics

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 73 P01 | 9min | 2 tasks | 4 files |
| Phase 73 P02 | 20min | 2 tasks | 5 files |
| Phase 73 P03 | 17min | 2 tasks | 4 files |

### Blockers

- Phoenix was upgraded from 1.8.7 to 1.8.13 in `ae1f0aa`, resolving GHSA-63mc-hw7g-86rr and high-severity GHSA-6983-jfq8-485w; `mix ci.security` now passes.
