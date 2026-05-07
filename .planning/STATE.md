---
gsd_state_version: 1.0
milestone: v0.5
milestone_name: — Operational maturity
status: executing
last_updated: "2026-05-07T01:59:12.560Z"
last_activity: 2026-05-07 -- Phase 21 execution started
progress:
  total_phases: 2
  completed_phases: 1
  total_plans: 9
  completed_plans: 2
  percent: 22
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-06 — v0.5 Operational maturity milestone started)

**Core value:** Every SAML login ends in a verified trust path or a typed rejection — never a silent compromise. Trust mutations are durable, attributable, and reviewable.
**Current focus:** Phase 21 — scheduled-metadata-refresh

## Current Position

Phase: 21 (scheduled-metadata-refresh) — EXECUTING
Plan: 1 of 7
Status: Executing Phase 21
Last activity: 2026-05-07 -- Phase 21 execution started

Resume file: `.planning/phases/21-scheduled-metadata-refresh/21-01-schema-extension-PLAN.md` (Wave 0 starts here)

Plan wave layout:

- W0: 21-01 schema-extension (3 tasks) — migration + schema + 17 Wave-0 test stubs
- W1 (parallel): 21-02 pure-helpers (cadence + backoff + failure_classifier), 21-03 trust-boundary-helpers (TrustAnchor + DriftDetector + CorpusGate)
- W2: 21-04 audit-seam-extension (record_attempt extension + verify_metadata_root + resume_auto_refresh)
- W3: 21-05 scheduler-wrapper-worker (OptionalDeps.Oban + AutoRefresh wrapper + Scheduler.run_due/2 + Workers.MetadataRefresh)
- W4: 21-06 live-admin-surface (micro-badge + health card + Resume now button)
- W5: 21-07 mix-tasks-telemetry-docs (relyra.refresh_due + relyra.metadata.pin + telemetry catalog + LogAlerts handler + README recipes + Oban CI smoke lane)

Progress: [==--------] 22%

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
