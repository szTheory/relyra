---
gsd_state_version: 1.0
milestone: v0.3
milestone_name: LiveView admin
status: execution
last_updated: "2026-05-06T18:30:00Z"
last_activity: 2026-05-06 -- Phase 17 Plan 01 executed and completed
progress:
  total_phases: 4
  completed_phases: 0
  total_plans: 3
  completed_plans: 3
  percent: 25
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-06 — v0.3 LiveView admin milestone started)

**Core value:** Every SAML login ends in a verified trust path or a typed rejection — never a silent compromise. Trust mutations are durable, attributable, and reviewable.
**Current focus:** v0.3 — LiveView admin surface (end-customer self-service for v0.2 capabilities). See `.planning/MILESTONE-ARC.md` for the v0.3 → v1.0 plan.

## Current Position

Phase: 17 - 17-certificate-inventory-staged-rollover-ui
Plan: 17-01 (Completed)
Status: Executed and verified.
Last activity: 2026-05-06 — Phase 17 Plan 01 completed.

Progress: [==========] 100%

## Accumulated Context

**Decisions log:** Full log lives in `.planning/PROJECT.md` Key Decisions table. Highlights from v0.2:
- Connection aggregate uses internal binary PK + public `connection_id`; no Ecto rows above the resolver boundary.
- `idp_certificates` is canonical; `cert_chain` is compatibility mirror.
- Metadata refresh is operator-triggered only; new signing certs stage as `:next`.
- All four mutation modules co-commit audit rows via single `Relyra.Ecto.AuditWriter.append_event` seam inside the same transaction.
- Closure-phase pattern (12 → 09's verification, etc.) is the canonical move when an audit surfaces verification orphans.

**Open blockers:** None.

**Roadmap coverage:** 10/10 v0.3 requirements mapped across Phases 15-18.

**Carryover tech debt for v0.3:**
- `Relyra.Ecto.MappingCommands.append_audit/8` does not explicitly call `repo.rollback/1` on `AuditWriter` failure (relies on `transact/1` auto-rollback); other three co-commit sites use the explicit pattern. Modern Ecto: correct. Legacy fallback: theoretically vulnerable.
- 09/10/12/13/14 VALIDATION.md frontmatter still says `status: ready_for_verify`; verification artifacts now exist. Cosmetic; not blocking.
- 07/08 host-app adopter docs (migration ergonomics; resolver-config copy) want a non-code manual review pass during adopter onboarding.
- Phase smoke suites must run serially to avoid Ecto migration bootstrap races. Operational guidance only.
