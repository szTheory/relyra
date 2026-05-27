---
phase: 42-stepwise-login-trace-liveview
status: passed
verified: 2026-05-27
requirements: [TRACE-01, TRACE-02, TRACE-03]
plans_reviewed: 4
plans_executed: 4
gaps: 1
human_needed: false
score: "3/3 requirements · 16/16 tests · 4/4 plans"
---

# Phase 42 Verification

**Goal:** Stepwise login-trace LiveView + headless CLI with shared redaction and security gate (TRACE-01..TRACE-03)

**Result:** All three requirements satisfied in code and automated gates. One low-severity deferred item (user.map attribute/role summaries) documented below; does not block phase close.

## Summary

| Requirement | Status | Evidence |
|-------------|--------|----------|
| TRACE-01 | **Pass** | `ConnectionTraceLive` at `/relyra/admin/connections/:connection_id/trace`; six expandable steps; audit/telemetry persistence; UI contract tests |
| TRACE-02 | **Pass** | `test/security/login_trace_test.exs` refutes forbidden material; dedicated `ci.security` cmd; `@gated_suites` entry |
| TRACE-03 | **Pass** | `mix relyra.trace --repo --connection [--last N]`; export equivalence test proves LiveView/CLI parity |

## Plan execution

All four plans (42-01..42-04) have matching SUMMARY artifacts dated 2026-05-27.

| Plan | Requirements | Must-haves | Status |
|------|--------------|------------|--------|
| 42-01 | TRACE-01 (data) | LoginTrace handler, audit append, validation_trace | **Pass** |
| 42-02 | TRACE-01, TRACE-03 (export) | LoginTrace.Export, get_login_traces/4, trust-audit filter | **Pass** |
| 42-03 | TRACE-01 (UI) | Route, LiveView, nav link, UI contract tests | **Pass** |
| 42-04 | TRACE-02, TRACE-03 | CLI task, security corpus, hollow-gate wiring | **Pass** |

## Requirement verification

### TRACE-01 — Stepwise login-trace LiveView

**Status: Pass**

- Route registered in `lib/relyra/live_admin/router.ex` at `/connections/:connection_id/trace` → `Relyra.LiveAdmin.ConnectionTraceLive`.
- LiveView loads traces exclusively via `Query.get_login_traces/4` (limit 20); renders six steps in canonical order with `outcome`, `error_code`, `duration_ms`.
- Empty state uses exact D-16 copy: *"No login attempts recorded yet — traces appear after the first SAML response is consumed."*
- Navigation link `View Login Trace` in `connection_detail.ex` with `data-testid="view-login-trace-link"`.
- Persistence: `Relyra.Telemetry.Handlers.LoginTrace` appends `domain: :login` rows via `AuditWriter.append_event/2`; `LoginResult.validation_trace` populated in `normalize_consume_result/1`.
- No new schemas — reuses `relyra_audit_events` with extended `@domain_values` (`:login`) and actions (`:succeeded`, `:failed`).

**Phase scope note:** REQUIREMENTS.md mentions "eight" spans; phase CONTEXT D-09 resolves to **six consume-path step rows** (decode → validate → signature → replay → user.map → session.establish). Implementation matches CONTEXT.

### TRACE-02 — Security gate + hollow ci.security lane

**Status: Pass**

- `test/security/login_trace_test.exs` — 3 tests: LiveView HTML refute, CLI output refute, export equivalence.
- Forbidden patterns refuted: PEM (`-----BEGIN`), XML declaration (`<?xml`), fixture `SignatureValue`, cert base64 substring, raw correlation id.
- `mix.exs` `ci.security` includes `"cmd mix test test/security/login_trace_test.exs --warnings-as-errors"` (line 210).
- `@gated_suites` in `test/security/ci_gate_integrity_test.exs` lists `{"test/security/login_trace_test.exs", nil}`.

### TRACE-03 — Headless `mix relyra.trace` companion

**Status: Pass**

- `lib/mix/tasks/relyra.trace.ex` — requires `--repo` and `--connection`; optional `--last` (default 20).
- Prints redacted traces via `Query.get_login_traces/4` → `LoginTrace.Export.export_login/1`.
- Security test proves LiveView and CLI exported maps are identical for the same audit rows.

## Must-have artifact checklist

| Artifact | Path | Verified |
|----------|------|----------|
| LoginTrace handler | `lib/relyra/telemetry/handlers/login_trace.ex` | ✓ attach/detach, 7 event prefixes, sensitive key strip |
| Handler tests | `test/relyra/telemetry/handlers/login_trace_test.exs` | ✓ success/failure append, no xml keys |
| Export module | `lib/relyra/login_trace/export.ex` | ✓ export_step/1, export_login/1, correlation hash |
| Export tests | `test/relyra/login_trace/export_test.exs` | ✓ PEM/XML redaction, hashed correlation |
| Query helpers | `lib/relyra/live_admin/query.ex` | ✓ get_login_traces/4 limit 20; domain != :login filter |
| Trace LiveView | `lib/relyra/live_admin/connection_trace_live.ex` | ✓ testids, six steps, empty state |
| Router | `lib/relyra/live_admin/router.ex` | ✓ trace route |
| CLI task | `lib/mix/tasks/relyra.trace.ex` | ✓ --repo, --connection, --last |
| Security corpus | `test/security/login_trace_test.exs` | ✓ 3 tests, real signed consume fixture |

## Commands run

```
mix test test/relyra/telemetry/handlers/login_trace_test.exs \
         test/relyra/login_trace/export_test.exs \
         test/relyra/live_admin/phase15_ui_contract_test.exs \
         test/security/login_trace_test.exs \
         --warnings-as-errors
# 16 tests, 0 failures

mix test test/security/ci_gate_integrity_test.exs --warnings-as-errors
# 4 tests, 0 failures
```

## Validation map (42-VALIDATION.md)

| Task ID | Status | Notes |
|---------|--------|-------|
| T-42-01-a | **Pass** | login_trace_test.exs green |
| T-42-02-a | **Pass** | export_test.exs green |
| T-42-03-a | **Pass** | phase15_ui_contract_test.exs green (3 trace tests) |
| T-42-04-a | **Pass** | login_trace_test.exs security corpus green |
| T-42-04-b | **Pass** | ci_gate_integrity_test.exs green |

## Gaps and remediation

| ID | Requirement | Severity | Detail | Remediation |
|----|-------------|----------|--------|-------------|
| G-01 | TRACE-01 (partial) | Low | `user.map` step rows show `outcome` / `error_code` / `duration_ms` only — post-mapping attributes/roles are not persisted from telemetry (CONTEXT D-08 mentions them; D-10 display model and handler `summarize_step/1` omit them). Export module supports `attributes`/`roles` keys for future enrichment. | Optional follow-up: extend `user.map` span metadata + handler summary to include redacted attribute/role counts or summaries when mapping succeeds. Not blocking — phase display contract (D-10) is met. |

**Not counted as gaps:**

- LoginTrace requires explicit `attach(repo:)` in host `Application.start/2` (documented in handler moduledoc; within plan 42-01 discretion vs CONTEXT D-05 "default-on" aspiration).
- REQUIREMENTS.md "eight spans" vs six step rows — resolved by phase CONTEXT D-09.
- `42-02-SUMMARY.md` frontmatter lists `requirements-completed: []` (artifact typo; code and tests satisfy TRACE-01/TRACE-03 export path).

## Human needed

**No.** All gaps are low-severity and bounded. No security posture, API shape, or architectural decisions pending.

## Overall phase status

**passed** — TRACE-01..TRACE-03 delivered: LiveView trace surface, shared export/redaction, security gate, and headless CLI all verified green against plan must-haves and automated test corpus.
