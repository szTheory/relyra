---
phase: 21
slug: scheduled-metadata-refresh
status: draft
nyquist_compliant: false
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
| 21-01-01 | 01 | 0 | CFG-08 | — | Schema additions backfill cleanly; partial index created; existing rows default to `auto_refresh_enabled: false` | migration | `mix ecto.migrate && mix test test/relyra/ecto/metadata_source_test.exs` | ❌ W0 | ⬜ pending |

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

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s for `mix test --stale`
- [ ] `mix compile --no-optional-deps --warnings-as-errors` is part of CI sign-off
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
