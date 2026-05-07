---
phase: 21
slug: scheduled-metadata-refresh
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-06
---

# Phase 21 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.18.x / OTP 27) |
| **Config file** | `test/test_helper.exs`, `config/test.exs` |
| **Quick run command** | `mix test --stale` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~{filled at planner output} seconds |

Optional-deps + cross-cutting commands the planner SHOULD reuse:

| Command | Purpose |
|---------|---------|
| `mix compile --no-optional-deps --warnings-as-errors` | Verify Oban-absent compile lane stays green (engineering DNA §3) |
| `mix test --only oban` | Run the Oban-present worker dispatch suite |
| `mix test --only security_corpus` | Run the security regression corpus on the scheduled path |
| `mix format --check-formatted` | Style invariant |
| `mix credo --strict` | Static analysis invariant |
| `mix dialyzer` | Type analysis invariant |

---

## Sampling Rate

- **After every task commit:** Run `mix test --stale`
- **After every plan wave:** Run `mix test`
- **Before `/gsd-verify-work`:** Full suite + `mix compile --no-optional-deps --warnings-as-errors` must be green
- **Max feedback latency:** ~30 seconds (`mix test --stale` on changed modules)

---

## Per-Task Verification Map

> Populated during plan-phase from PLAN.md `<automated>` blocks. Each plan task in Phase 21 maps to one row below; the planner is the source of truth for task IDs.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 21-01-01 | 01 | 0 | CFG-08 | T-21-03, T-21-04, T-21-05 | Migration adds 14 columns + partial index; existing rows backfill cleanly; cadence enum rejects unknown presets at the type boundary | migration | `mix ecto.migrate && mix ecto.rollback && mix ecto.migrate` | ✅ | ⬜ pending |
| 21-01-02 | 01 | 0 | CFG-08 | T-21-01, T-21-02 | Schema declares 14 new fields; `auto_refresh_changeset/2` rejects enabling auto-refresh without pinned fingerprints (D-09 great-error); `health_state_changeset/2` is the MetadataApply-internal seam (D-28) | unit | `mix compile --warnings-as-errors && mix compile --no-optional-deps --warnings-as-errors` | ✅ | ⬜ pending |
| 21-01-03 | 01 | 0 | CFG-08 | T-21-01, T-21-02, T-21-04 | Schema test covers 6 changeset behaviors including the great-error string; 11 Wave 0 stub files exist with `:pending` tag so later waves drop tests in | unit | `mix test test/relyra/ecto/metadata_source_test.exs --warnings-as-errors && mix test --exclude pending --warnings-as-errors` | ✅ | ⬜ pending |
| 21-02-01 | 02 | 1 | CFG-08 | T-21-07, T-21-09, T-21-10 | Cadence helper enforces 1h hard floor + ±15% jitter (D-14, D-12); Backoff helper produces 1h→6h→24h cap with ±10% jitter (D-25); both modules pure (no Ecto/Repo/Req/telemetry/Logger) | property | `mix test test/relyra/metadata/cadence_test.exs test/relyra/metadata/backoff_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 21-02-02 | 02 | 1 | CFG-08 | T-21-08 | FailureClassifier maps every Phase-21 error code to {transient?, counts_toward_suspend?, alert_immediately?}; default catch-all returns suspicious (alert + don't count); table test enumerates all 13 codes + exhaustiveness invariant (D-27) | unit | `mix test test/relyra/metadata/failure_classifier_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 21-03-01 | 03 | 1 | CFG-08 | T-21-11, T-21-12, T-21-13 | TrustAnchor.check/2 rejects empty pinned + no-match with `:trust_anchor_mismatch` (D-17 — no TOFU); DriftDetector.diff/2 compares MapSets of fingerprints only (Pitfall 7); first-fetch is initialization not drift | unit | `mix test test/relyra/metadata/trust_anchor_test.exs test/relyra/metadata/drift_detector_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 21-03-02 | 03 | 1 | CFG-08 | T-21-14, T-21-15, T-21-16 | Security corpus manifest moves to `priv/security_corpus.json` (byte-identical via `cmp`); CorpusGate.check/2 refuses fetched XML matching any LOCKED corpus fixture with typed `:corpus_violation` (D-21); existing corpus regression test passes against new path | security | `mix test test/relyra/security/xml/corpus_gate_test.exs test/security/xml/corpus_security_test.exs --warnings-as-errors --include security_corpus` | ✅ | ⬜ pending |
| 21-04-01 | 04 | 2 | CFG-08 | T-21-17, T-21-18, T-21-19, T-21-23 | record_attempt/3 wrapped in transact/2; health-state co-commits ONLY for scheduled triggers (D-28); failure path uses FailureClassifier; success path resets counters + advances next_refresh_at (Pitfall 6); B1: D-24 :degraded/:suspended/:recovered events emitted INSIDE the same transact block; B2: record_validity_warning/3 helper exists for at-most-once :validity_warning emit (D-14) | integration + telemetry | `mix test test/relyra/ecto/metadata_apply_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 21-04-02 | 04 | 2 | CFG-08 | T-21-20, T-21-21, T-21-22 | Signature.verify_metadata_root/4 reuses do_verify/4 verbatim; emits telemetry with `flow: :metadata_refresh` (vs `:sp_initiated` for verify/4); inherits document-KeyInfo rejection + empty-cert-chain rejection + duplicate-XML-ID rejection (D-16) | telemetry + security | `mix test test/relyra/security/signature_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 21-04-03 | 04 | 2 | CFG-08 | T-21-17, T-21-30 (consumer) | MetadataApply.resume_auto_refresh/3 co-commits audit row (`cause: live_admin_auto_refresh_resume`) + suspend-clear in ONE transact block (B3 / D-28 / D-35); single audit-writer seam preserved — exactly 2 AuditWriter.append_event sites in the file (apply_revision + resume_auto_refresh) | integration | `mix test test/relyra/ecto/metadata_apply_test.exs --warnings-as-errors` | ❌ W0 | ⬜ pending |
| 21-05-01 | 05 | 3 | CFG-08 | T-21-31, T-21-46 | OptionalDeps.Oban returns result tuples (NOT raising) when Oban absent; MetadataRefresh worker compiles with AND without Oban; uses LOCKED unique constraint `[period: :infinity, states: [:available, :scheduled, :executing], keys: [:source_id]]` (D-03); max_attempts: 1 (D-25 Phase 21 owns its own backoff) | unit + optional_deps | `mix test test/relyra/optional_deps/oban_test.exs test/relyra/workers/metadata_refresh_test.exs --include oban --warnings-as-errors && mix compile --no-optional-deps --warnings-as-errors` | ✅ | ⬜ pending |
| 21-05-02 | 05 | 3 | CFG-08 | T-21-24, T-21-25, T-21-26, T-21-27, T-21-28, T-21-29, T-21-32, T-21-33, T-21-34 | Scheduler.run_due/2 queries partial index, generates one correlation_id per batch (D-39), runs sequentially (D-38), emits :skipped for empty (D-07), supports :source_ids for Resume-now probe (Plan 06); AutoRefresh wraps Refresh.refresh/2; routes TrustAnchor→verify_metadata_root→Parser→CorpusGate→`maybe_emit_validity_warning` (B2)→DriftDetector→apply_revision; W10: `pre_parse_for_signature/1` extracts signed_candidates via PureBeam (xml_id + xpath populated, NOT nil); on refusal calls record_attempt/3 with typed auto_suspended_reason; stricter Req profile (D-20) | integration + security + telemetry | `mix compile --warnings-as-errors && mix compile --no-optional-deps --warnings-as-errors && mix test test/relyra/metadata/scheduler_test.exs test/relyra/metadata/auto_refresh_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 21-06-01 | 06 | 4 | CFG-08 | T-21-37, T-21-38, T-21-40 | Query.list_connections/2 returns auto_refresh_health ∈ {nil, :healthy, :degraded, :suspended} via N+1-safe MetadataSource preload (D-29); ConnectionList renders amber/red micro-badges with brand-approved copy ONLY (no 'polling'/'cron job'/'blocked'/'retry'/'circuit breaker') | live_view + brand_voice | `mix test test/relyra/live_admin/connections_live_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 21-06-02 | 06 | 4 | CFG-08 | T-21-35, T-21-36, T-21-39, T-21-40 | ConnectionMetadataLive renders Auto-refresh health card; Resume-now button delegates to `MetadataApply.resume_auto_refresh/3` (B3 single-transaction seam, D-28); start_async dispatches scoped Scheduler.run_due/2 probe; legacy_unsigned_metadata_policy renders inside RiskPanel (D-19); brand-voice grep enforced; no `clear_suspend_for_resume` helper (B3 invariant); `if Code.ensure_loaded?(Phoenix.LiveView)` gate preserved | live_view + integration + brand_voice | `mix test test/relyra/live_admin/connection_metadata_live_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 21-07-01 | 07 | 5 | CFG-08 | T-21-44, T-21-45 | Telemetry catalog documents all 8 Phase-21 events (D-23/D-24/D-07/D-30); existing `### metadata.refresh` block byte-identical (D-23 invariant); LogAlerts ~50 LOC, attach-on-demand only, redaction-aware via key drop, NOT auto-attached anywhere in lib/ (D-30) | unit + telemetry | `mix test test/relyra/telemetry/handlers/log_alerts_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 21-07-02 | 07 | 5 | CFG-08 | T-21-41, T-21-42, T-21-43 | Metadata.pin_trust_fingerprint/3 is the shared underlying helper (D-22 + RESEARCH Q1 — Mix and LiveView paths cannot drift); mix relyra.refresh_due drives Scheduler.run_due/2 via `Mix.Task.run("app.start")`; mix relyra.metadata.pin supports `--fingerprint :keep` for D-17 rotation; both tasks publicly listed by `mix help` | unit + integration | `mix test test/mix/tasks/relyra_refresh_due_test.exs test/mix/tasks/relyra_metadata_pin_test.exs --warnings-as-errors` | ✅ | ⬜ pending |
| 21-07-03 | 07 | 5 | CFG-08 | T-21-46, T-21-47 | mix.exs declares `{:oban, "~> 2.22", optional: true}`; no-optional-deps compile lane stays green (engineering-DNA §3); ci.oban_smoke alias runs both compile lanes + Oban-present worker tests; README Operations section ships all 4 LOCKED scheduler recipes (D-06) + fingerprint pin recipe + LogAlerts attach example; W11: extended brand-voice grep covers README Operations, Mix `@moduledoc`, telemetry catalog, LogAlerts user-facing strings | ci + docs + brand_voice | `mix deps.get && mix compile --warnings-as-errors && mix compile --no-optional-deps --warnings-as-errors && mix ci.oban_smoke` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

> Planner extends this table from PLAN.md task IDs. One row per task; never collapse multiple tasks into one row.

---

## Wave 0 Requirements

- [ ] `test/relyra/metadata/scheduler_test.exs` — stubs for `run_due/2` (CFG-08, D-01, D-05, D-38, D-39)
- [ ] `test/relyra/metadata/auto_refresh_test.exs` — stubs for the wrapper module (CFG-08, D-05, D-15..D-21)
- [ ] `test/relyra/optional_deps/oban_test.exs` — stubs for the optional-deps gateway (D-02, D-37)
- [ ] `test/relyra/workers/metadata_refresh_test.exs` — Oban-present dispatch tests (D-02, D-03)
- [ ] `test/relyra/metadata/cadence_test.exs` — pure-function helpers: cadence resolver, jitter, hard floor (D-10..D-14)
- [ ] `test/relyra/metadata/failure_classifier_test.exs` — error-code metadata table (D-27)
- [ ] `test/relyra/metadata/backoff_test.exs` — auto-suspend schedule + half-open probe (D-25, D-26)
- [ ] `test/relyra/metadata/drift_detector_test.exs` — entityID + signing-cert fingerprint diff (D-18)
- [ ] `test/relyra/security/xml/corpus_gate_test.exs` — security corpus runtime gate (D-21)
- [ ] `test/relyra/security/signature_test.exs` — extended for `<EntityDescriptor>` / `<EntitiesDescriptor>` root signatures (D-16)
- [ ] `test/relyra/live_admin/connections_live_test.exs` — auto-refresh micro-badge rendering (D-29)
- [ ] `test/relyra/live_admin/connection_metadata_live_test.exs` — health card + "Resume now" button + audit row (D-29, D-35)
- [ ] `test/relyra/telemetry/handlers/log_alerts_test.exs` — reference handler emits the documented log shape (D-30)
- [ ] `test/support/oban_case.ex` — shared `use Oban.Testing` fixture if not already present
- [ ] `test/support/security_corpus_fixtures.ex` — shared loader for `priv/security_corpus.json` fixtures (D-21)
- [ ] CI lane addition: Postgres + Oban smoke job that runs `mix test --include oban` (D-37 / engineering DNA §3)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Oban Cron one-liner doc recipe is copy-pasteable into a fresh adopter project | CFG-08 / D-06 | Docs validation; full adopter integration is out of test scope | Read `README.md` "Operations" section; verify the Oban Cron block compiles in a host project that has Oban configured |
| Mix task `mix relyra.refresh_due` runs against a real Repo | CFG-08 / D-01, D-06 | Mix-task wiring requires a configured Repo | Run in a host app with `MIX_ENV=dev mix relyra.refresh_due`; observe scheduled telemetry events |
| Trust-anchor fingerprint pinning UX (Mix task + admin LiveView) feels operator-shaped | D-22 | UX evaluation; Mix-task ergonomics + LiveView risk panel copy | Walk through enabling auto-refresh on a connection: pin fingerprint via `mix relyra.metadata.pin`, then verify the admin LiveView renders the pinned fingerprints with rotation affordance |
| k8s `CronJob` and fly.io `[[machines.schedule]]` recipes are accurate | D-06 | YAML/TOML doc validation against external runtimes | Apply the `CronJob` to a sandbox k8s cluster; verify a fly.io scheduled machine recipe boots and invokes `mix relyra.refresh_due` |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies (B5: per-task map populated; every task has an `<automated>` command from its PLAN.md `<verify>` block)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify (every of the 17 tasks ships an `<automated>` command)
- [x] Wave 0 covers all MISSING references (Plan 01 Task 3 creates 11 stub test files with `:pending` tag; only 21-04-03 — `MetadataApply.resume_auto_refresh/3` test scenario added in revision iteration 1 — extends an existing Wave-0-stub-or-real file, no new infrastructure required)
- [x] No watch-mode flags (every `<automated>` command exits with a code; no `mix test.watch` / `mix test --stale --watch`)
- [x] Feedback latency < 30s for `mix test --stale`
- [x] `mix compile --no-optional-deps --warnings-as-errors` is part of CI sign-off (Plan 05 + Plan 07 both gate on this; ci.oban_smoke alias chains both compile lanes)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** ratified by planner during revision iteration 1 (B5 closure); awaits checker re-verification.
