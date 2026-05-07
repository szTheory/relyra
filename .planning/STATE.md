---
gsd_state_version: 1.0
milestone: v0.5
milestone_name: — Operational maturity
status: executing
last_updated: "2026-05-07T02:40:53.000Z"
last_activity: 2026-05-07 -- Phase 21 plan 04 (audit-seam-extension) complete
progress:
  total_phases: 2
  completed_phases: 1
  total_plans: 9
  completed_plans: 4
  percent: 44
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-06 — v0.5 Operational maturity milestone started)

**Core value:** Every SAML login ends in a verified trust path or a typed rejection — never a silent compromise. Trust mutations are durable, attributable, and reviewable.
**Current focus:** Phase 21 — scheduled-metadata-refresh (Wave 1 next)

## Current Position

Phase: 21 (scheduled-metadata-refresh) — EXECUTING
Plan: 5 of 7 (Wave 3 next — scheduler-wrapper-worker)
Status: Executing Phase 21
Last activity: 2026-05-07 -- Phase 21 plan 04 (audit-seam-extension) complete

Resume file: `.planning/phases/21-scheduled-metadata-refresh/21-05-scheduler-wrapper-worker-PLAN.md` (Wave 3)

Plan wave layout:

- W0: 21-01 schema-extension (3 tasks) — migration + schema + 17 Wave-0 test stubs
- W1 (parallel): 21-02 pure-helpers (cadence + backoff + failure_classifier), 21-03 trust-boundary-helpers (TrustAnchor + DriftDetector + CorpusGate)
- W2: 21-04 audit-seam-extension (record_attempt extension + verify_metadata_root + resume_auto_refresh)
- W3: 21-05 scheduler-wrapper-worker (OptionalDeps.Oban + AutoRefresh wrapper + Scheduler.run_due/2 + Workers.MetadataRefresh)
- W4: 21-06 live-admin-surface (micro-badge + health card + Resume now button)
- W5: 21-07 mix-tasks-telemetry-docs (relyra.refresh_due + relyra.metadata.pin + telemetry catalog + LogAlerts handler + README recipes + Oban CI smoke lane)

Progress: [====------] 44%

## Accumulated Context

**Decisions log:** Full log lives in `.planning/PROJECT.md` Key Decisions table. Highlights from v0.5:

- Sequential execution for BulkActions to avoid DB pressure (Phase 20).
- Automatic correlation_id generation for bulk operations (Phase 20).
- Phase 21 scheduler is dormant by default — no auto-starting ticker. `Relyra.Metadata.Scheduler.run_due/2` + Oban worker behind `Relyra.OptionalDeps.Oban` gateway.
- Phase 21 cadence is a 4-preset enum (`:hourly`, `:every_6h`, `:daily`, `:weekly`), default `:daily`, with ±15% persisted jitter and a 1-hour InCommon hard floor.
- Phase 21 introduces asymmetric strictness: signed metadata required for the scheduled (unattended) apply path; manual import unchanged.
- Phase 21 trust anchor for metadata signing = operator-pinned SHA-256 fingerprints. No TOFU. No reuse of assertion-signing certs.
- Phase 21 separate telemetry namespace `[:relyra, :saml, :metadata, :auto_refresh, ...]`; auto-suspend after 5 consecutive transient failures with exponential backoff (1h → 6h → 24h cap).
- Plan 21-01: Postgres partial-index predicates accept IMMUTABLE-only expressions. The relyra_metadata_sources_due_idx ships as `WHERE auto_refresh_enabled = true`; the runtime due-query keeps the suspension/time filter at query time (canonical Postgres pattern; preserves D-12 single-index-scan intent).
- Plan 21-01: Schema mutation surface split into operator-facing (`auto_refresh_changeset/2`) and internal-only (`health_state_changeset/2`); the cast whitelist encodes D-28 (no parallel audit/health writers).
- Plan 21-01: Wave-0 :pending stub pattern — pre-create test files for every module a multi-wave phase will introduce, so PLAN <automated> commands point at real paths from day one. `flunk` body (vs `assert true`) gives a loud signal if a future wave forgets to overwrite the stub.
- Plan 21-04: D-28 single-transaction discipline implemented as a `transact/2`-wrapped `record_attempt/3` + `apply_revision/4` co-commit pattern; health-state side-effects are gated by `scheduled_trigger?/1` so manual paths (Phase 9/12) flow through the same entry points unchanged. Pattern reusable for any future LiveView+Mix-task pair that needs to thread audit context through the single seam.
- Plan 21-04: D-24 telemetry events (`:degraded`, `:suspended`, `:recovered`) fire INSIDE the `transact/2` block via `emit_state_transitions/3`. Trade-off accepted: a downstream listener could see an event whose surrounding transaction later rolled back; mitigation is the `correlation_id` on every payload so hosts can dedupe against an audit row that never landed. After-commit emission would require `Ecto.Multi` rewiring — out of scope and structurally inconsistent with `Telemetry.span` around `apply_revision/4`.
- Plan 21-04: Single-audit-writer-seam invariant (D-35) enforced numerically — exactly two `AuditWriter.append_event` call sites in `lib/relyra/ecto/metadata_apply.ex` (`apply_revision/4` + `resume_auto_refresh/3`), both inside `transact/2` blocks. Future seams MUST wrap any new audit-writing path in `transact/2`.
- Plan 21-04 (Rule 3 deviation): `Relyra.Ecto.MetadataRevision.@trigger_values` extended with `:scheduled_refresh` and `:scheduled_probe` — Plan 21-01 added the source-side cadence/health columns but did NOT enumerate the scheduled triggers on the revision schema. Single-line edit; landed in plan 21-04's first commit so Plan 05's wrapper has the trigger atoms it needs.

**Open blockers:** None.

**Pre-existing out-of-scope items surfaced during 21-01 (logged in `.planning/phases/21-scheduled-metadata-refresh/deferred-items.md`):**
- `Relyra.Phoenix.ACSControllerTest` — `:name_id` KeyError pre-dates Phase 21.
- `lib/relyra/live_admin/connections_live.ex` — pre-existing `mix format` drift from Phase 20 commit `6e75525`.

**Roadmap coverage:** Phase 21 covers CFG-08 (scheduled metadata refresh automation with guardrails). Plan 21-01 lands the schema foundation; CFG-08 marks complete only after Phase 21 W5 (plan 21-07) ships.
