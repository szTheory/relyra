---
gsd_state_version: 1.0
milestone: v0.5
milestone_name: Operational maturity
status: planning
last_updated: "2026-05-06T22:30:00Z"
last_activity: 2026-05-06 -- Phase 21 context gathered
progress:
  total_phases: 2
  completed_phases: 1
  total_plans: 2
  completed_plans: 2
  percent: 50
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-06 — v0.5 Operational maturity milestone started)

**Core value:** Every SAML login ends in a verified trust path or a typed rejection — never a silent compromise. Trust mutations are durable, attributable, and reviewable.
**Current focus:** v0.5 — Operational maturity. See `.planning/MILESTONE-ARC.md` for the v0.5 → v1.0 plan.

## Current Position

Phase: 21 - Scheduled metadata refresh
Plan: pending (CONTEXT.md complete; ready for plan-phase)
Status: Phase 21 context gathered.
Last activity: 2026-05-06 — Phase 21 CONTEXT.md and DISCUSSION-LOG.md written.

Resume file: `.planning/phases/21-scheduled-metadata-refresh/21-CONTEXT.md`

Progress: [=====-----] 50%

## Accumulated Context

**Decisions log:** Full log lives in `.planning/PROJECT.md` Key Decisions table. Highlights from v0.5:
- Sequential execution for BulkActions to avoid DB pressure (Phase 20).
- Automatic correlation_id generation for bulk operations (Phase 20).
- Phase 21 scheduler is dormant by default — no auto-starting ticker. `Relyra.Metadata.Scheduler.run_due/2` + Oban worker behind `Relyra.OptionalDeps.Oban` gateway.
- Phase 21 cadence is a 4-preset enum (`:hourly`, `:every_6h`, `:daily`, `:weekly`), default `:daily`, with ±15% persisted jitter and a 1-hour InCommon hard floor.
- Phase 21 introduces asymmetric strictness: signed metadata required for the scheduled (unattended) apply path; manual import unchanged.
- Phase 21 trust anchor for metadata signing = operator-pinned SHA-256 fingerprints. No TOFU. No reuse of assertion-signing certs.
- Phase 21 separate telemetry namespace `[:relyra, :saml, :metadata, :auto_refresh, ...]`; auto-suspend after 5 consecutive transient failures with exponential backoff (1h → 6h → 24h cap).

**Open blockers:** None.

**Roadmap coverage:** Phase 21 covers CFG-08 (scheduled metadata refresh automation with guardrails).
