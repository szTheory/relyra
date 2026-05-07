---
gsd_state_version: 1.0
milestone: v0.5
milestone_name: — Operational maturity
status: executing
last_updated: "2026-05-07T13:56:14.345Z"
last_activity: 2026-05-07
progress:
  total_phases: 3
  completed_phases: 3
  total_plans: 10
  completed_plans: 10
  percent: 100
---

# Project State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-06 — v0.5 Operational maturity milestone started)

**Core value:** Every SAML login ends in a verified trust path or a typed rejection — never a silent compromise. Trust mutations are durable, attributable, and reviewable.
**Current focus:** Phase 21.1 — close-gap-cfg-07-bulk-refresh-audit-correlation-id-forwardin

## Current Position

Phase: 21.1
Plan: Not started
Status: Executing Phase 21.1
Last activity: 2026-05-07

Resume file: (no active resume — awaiting v0.6 milestone arc kickoff)

Plan wave layout:

- W0: 21-01 schema-extension (3 tasks) — migration + schema + 17 Wave-0 test stubs
- W1 (parallel): 21-02 pure-helpers (cadence + backoff + failure_classifier), 21-03 trust-boundary-helpers (TrustAnchor + DriftDetector + CorpusGate)
- W2: 21-04 audit-seam-extension (record_attempt extension + verify_metadata_root + resume_auto_refresh)
- W3: 21-05 scheduler-wrapper-worker (OptionalDeps.Oban + AutoRefresh wrapper + Scheduler.run_due/2 + Workers.MetadataRefresh)
- W4: 21-06 live-admin-surface (micro-badge + health card + Resume now button)
- W5: 21-07 mix-tasks-telemetry-docs (relyra.refresh_due + relyra.metadata.pin + telemetry catalog + LogAlerts handler + README recipes + Oban CI smoke lane) — SHIPPED 2026-05-07

Progress: [==========] 100%

## Accumulated Context

### Roadmap Evolution

- Phase 21.1 inserted after Phase 21 (URGENT) — Close gap: CFG-07 — bulk-refresh audit correlation_id forwarding

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
- Plan 21-05 (Rule 3 deviation): Outside-the-defmodule `Code.ensure_loaded?` gate for `use Oban.Worker` (Workers.MetadataRefresh) and `import Ecto.Query` (Metadata.Scheduler). Plan 21-05's literal in-body `if Code.ensure_loaded?(...) do use ... else def stub ... end` does NOT compile in Elixir 1.19 because Kernel.if/2 eagerly expands both branches; `use Oban.Worker` crashes with `module Oban.Worker is not loaded` regardless of the runtime branch. The canonical idiom in this codebase (Relyra.LiveAdmin / Relyra.LiveAdmin.ConnectionMetadataLive / Relyra.LiveAdmin.Query) wraps the whole `defmodule` in the gate with a stub `defmodule` in the else branch. Both compile lanes (`mix compile --warnings-as-errors` and `mix compile --no-optional-deps --warnings-as-errors`) green.
- Plan 21-05: Five-class refusal → LOCKED `auto_suspended_reason` mapping in `Relyra.Metadata.AutoRefresh.error_to_suspend_reason/1` is the single source of truth for which refusal class produces which suspend reason. Future refusal classes MUST extend BOTH the `@suspended_reason_values` enum on `Relyra.Ecto.MetadataSource` AND this mapping in lockstep — the changeset cast will reject any new atom that bypasses the enum.
- Plan 21-05: Asymmetric-strictness wrapper composition. `AutoRefresh.refresh/2` wraps `Refresh.refresh/2` from OUTSIDE rather than re-implementing it (D-05 invariant verified: `git diff lib/relyra/metadata/refresh.ex` is empty). Manual paths (`:manual_import` / `:manual_refresh`) flow through the existing entry points unchanged; the scheduled path adds the D-15..D-21 gates BEFORE the candidate reaches `MetadataApply.apply_revision/4`. Future "stricter automation" features should follow the same wrap-from-outside shape.
- Plan 21-06: D-29 health derivation as a pure function reused across surfaces. `Relyra.LiveAdmin.Query.derive_auto_refresh_health/2` returns `nil | :healthy | :degraded | :suspended` from a `MetadataSource` struct + `now`. The same helper feeds both the per-row connection-list micro-badge (via `connection_summary/3`) and the metadata-page health card (via `build_auto_refresh_health_summary/1`). Future surfaces that need the health enum MUST reuse the helper rather than recompute the cond branches — keeps the operator's mental model unified across views.
- Plan 21-06: LiveView Resume-now path enforces single-transaction discipline (D-28) by routing exclusively through `Relyra.Ecto.MetadataApply.resume_auto_refresh/3` (Plan 04 Task 3); the LiveView carries NO parallel `repo.update`-based clear helper (B3 invariant grep-enforced: `clear_suspend_for_resume` returns 0 matches across `lib/`). After the transaction commits, the LiveView dispatches an immediate scoped half-open probe via `start_async(:auto_refresh_resume, fn -> Scheduler.run_due(repo, source_ids: [source.id]) end)`. Future LiveView surfaces that mutate audit-relevant state MUST follow the same shape: delegate to a `transact/2`-wrapped `MetadataApply` seam, dispatch downstream side-effects via `start_async` only after the transaction commits.
- Plan 21-06 (Rule 1 deviation): `Map.get/2`-guarded render-block accesses for cross-test compatibility. The pre-existing `Relyra.LiveAdminMetadataTest` render fixture passes `detail: %{metadata_source: nil}` without an `:auto_refresh_health` key — the literal `@detail.auto_refresh_health` form raises `KeyError` and breaks two pre-existing render tests. Switched the new render section to `Map.get(@detail, :auto_refresh_health)`. Production data through `Query.get_metadata_revisions/3` always carries the key; the guard is purely for test-fixture flexibility. Pattern reusable wherever a render block must tolerate partial test fixtures while production data carries the full schema.
- Plan 21-06: Brand-voice invariant grep-enforcement at the test layer. Every operator-facing surface (`connection_list.ex`, `connection_metadata_live.ex`) is asserted to never render `polling`, `cron job`, `blocked`, `retry`, `circuit breaker`, or `MaxBackoff`. The grep is run against the rendered HTML across all four health states (nil / :healthy / :degraded / :suspended), so it catches drift in either the source or the data feeding the render. Pattern reusable for any future operator-facing component governed by the brand book.
- Plan 21-07: Documented telemetry-event catalog inside `Relyra.Telemetry` `@moduledoc`. Every `[:relyra, :saml, ...]` event is documented with measurements + metadata payload in the central catalog; the `### metadata.refresh` block stays byte-identical so manual-path listeners are not destabilized (D-23 invariant). Future telemetry-emitting subsystems should extend the catalog rather than scatter event docs.
- Plan 21-07: Opt-in reference telemetry handler shape (D-30). `Relyra.Telemetry.Handlers.LogAlerts` ships in `lib/` but is NOT auto-attached anywhere; adopters opt in via `Application.start/2`. The grep invariant (no `LogAlerts.attach()` outside the module itself in `lib/`) is the regression gate. Future reference handlers (metrics emitters, span exporters) MUST follow the same shape — small, redaction-aware, attach-on-demand, no vendor coupling.
- Plan 21-07: Shared-changeset UX-symmetry pattern (D-22 + RESEARCH Q1). The `mix relyra.metadata.pin` task and the (forthcoming v0.6) admin LiveView fingerprint form both delegate to `Relyra.Metadata.pin_trust_fingerprint/3`, which itself runs `MetadataSource.auto_refresh_changeset/2`. Two surfaces, one underlying changeset → audit trail and validation rules cannot drift. Future operator-facing pairs (CLI + LiveView form, IaC + UI) should share one underlying domain-API helper.
- Plan 21-07 (Rule 3 deviation): defensive wildcard fallthrough for typed cross-lane returns. Elixir 1.19's set-theoretic typer narrows `Relyra.Metadata.Scheduler.run_due/2`'s return type to `{:ok, _}` (only) in the present-Ecto lane — the Ecto-absent stub's `{:error, _}` is invisible at the call site. An explicit `{:error, _}` clause is flagged unreachable. Pattern adopted in BOTH `Mix.Tasks.Relyra.RefreshDue.run/1` and `Relyra.Workers.MetadataRefresh.perform/1`: `case ... do {:ok, _} -> ...; other -> ... end` preserves correctness for the absent-dep stub branch without violating the typer. Reusable wherever a function call straddles two `Code.ensure_loaded?`-gated compile lanes whose return types differ.
- Plan 21-07 (Rule 3 deviation): worker test fixture switched to MigrationCase. Plan 21-05's `metadata_refresh_test.exs` was written assuming Oban was NOT loaded in CI (`ObanGateway.available?()` returned `false`, test took the `unless` short-circuit). Plan 21-07 added Oban as a real optional dep so `available?()` is now `true`, the present-lane delegate test actually invokes `Scheduler.run_due/2`, and the lack of an `Ecto.Adapters.SQL.Sandbox` checkout raises `OwnershipError`. Switched to `Relyra.TestSupport.MigrationCase, async: false`. Pattern reusable for any future test that exercises a code path which becomes "real" once an optional dep is added to the project's own `mix.exs`.
- Plan 21-07: `ci.<dep>_smoke` alias as the optional-deps regression gate. The new `ci.oban_smoke` alias chains `compile --no-optional-deps --warnings-as-errors` (engineering-DNA §3 invariant) FIRST, then `compile --warnings-as-errors`, then the Oban-present worker + gateway tests. A regression in the gateway's `@compile {:no_warn_undefined, [...]}` posture is caught before the present-dep compile + tests run. Future optional-dep gateways that expose a worker / dispatcher should ship a sibling alias following this shape.

**Open blockers:** None — Phase 21 is complete; CFG-08 closed; v0.5 milestone awaits v0.6 arc kickoff.

**Pre-existing out-of-scope items surfaced during 21-01 (logged in `.planning/phases/21-scheduled-metadata-refresh/deferred-items.md`):**

- `Relyra.Phoenix.ACSControllerTest` — `:name_id` KeyError pre-dates Phase 21.
- `lib/relyra/live_admin/connections_live.ex` — pre-existing `mix format` drift from Phase 20 commit `6e75525`.

**Roadmap coverage:** Phase 21 covers CFG-08 (scheduled metadata refresh automation with guardrails). All 7 plans complete (21-01 schema → 21-07 mix-tasks-telemetry-docs); CFG-08 marked complete in REQUIREMENTS.md on 2026-05-07.
