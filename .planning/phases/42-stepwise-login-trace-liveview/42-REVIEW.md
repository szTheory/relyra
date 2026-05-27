---
phase: 42-stepwise-login-trace-liveview
status: clean
reviewed: 2026-05-27
depth: standard
findings:
  critical: 0
  warning: 0
  info: 3
---

# Phase 42 Code Review

## Summary

Reviewed 16 source files across plans 42-01..42-04 (telemetry handler, export/redaction,
LiveView, CLI, query helpers, audit domain extension, and security gate wiring). Focus areas
(TRACE-02 redaction, handler crash safety, LiveView export-only rendering, hollow-gate wiring)
all pass. No blocking bugs or security regressions found.

## Focus-area verdicts

### TRACE-02 redaction (no PEM/XML/signature leakage)

**Pass.** Defense in depth is sound:

- `LoginTrace` handler whitelists persisted step fields to `outcome`, `error_code`, and
  `duration_ms` after dropping `@sensitive_keys` from span metadata — raw XML/PEM never reaches
  `after_summary`.
- `LoginTrace.Export` scrubs sensitive keys, PEM markers, and `-----BEGIN`/`<saml` patterns;
  hashes `correlation_id`; drops `actor`.
- LiveView and CLI both route through `Query.get_login_traces/4` → `Export.export_login/1`.
- `test/security/login_trace_test.exs` refutes forbidden substrings in HTML and CLI output
  using a real signed consume fixture (3 tests, all green).

### Login trace handler crash safety

**Pass.** `handle_event/4` wraps `do_handle_event/4` in `try/rescue`, logs the exception,
clears `:relyra_login_trace` and `:relyra_validation_trace` process keys, and does not re-raise
— telemetry emitters stay safe. Audit append failures are silently ignored (see I-02).

### LiveView rendering only exported data

**Pass.** `ConnectionTraceLive` loads traces exclusively via `Query.get_login_traces/4`; the
template renders only exported fields (`id`, `inserted_at`, `action`, hashed `correlation_id`,
`cause`, and per-step `outcome`/`error_code`/`duration_ms`). Trust timeline on connection
detail uses the filtered `audit_events` query (`domain != :login`), not raw preloads.

### ci.security hollow-gate wiring

**Pass.** `test/security/login_trace_test.exs` is registered in `@gated_suites` and referenced
by a dedicated `cmd mix test test/security/login_trace_test.exs --warnings-as-errors` step in
`mix.exs` `ci.security`. `ci_gate_integrity_test.exs` (4 tests) passes.

## Files reviewed

| Plan | File | Role |
|------|------|------|
| 42-01 | `lib/relyra/telemetry/handlers/login_trace.ex` | Span accumulation + audit flush |
| 42-01 | `lib/relyra/ecto/audit_event.ex` | `:login` domain, `:succeeded`/`:failed` actions |
| 42-01 | `lib/relyra.ex` | `validation_trace` population / error cleanup |
| 42-02 | `lib/relyra/login_trace/export.ex` | Canonical redaction export |
| 42-02 | `lib/relyra/diagnostic/allow_list.ex` | Thin delegates |
| 42-02 | `lib/relyra/live_admin/query.ex` | `get_login_traces/4`, trust timeline filter |
| 42-03 | `lib/relyra/live_admin/connection_trace_live.ex` | Trace LiveView |
| 42-03 | `lib/relyra/live_admin/router.ex` | Route mount |
| 42-03 | `lib/relyra/live_admin/components/connection_detail.ex` | Nav link |
| 42-04 | `lib/mix/tasks/relyra.trace.ex` | Headless CLI |
| 42-04 | `mix.exs` | `ci.security` lane |
| 42-04 | `test/security/login_trace_test.exs` | TRACE-02/03 corpus |
| 42-04 | `test/security/ci_gate_integrity_test.exs` | Hollow-gate meta-gate |

## Findings

### Info

**I-01: Diagnostic bundle bypasses LoginTrace.Export for login rows**
- `Relyra.Diagnostic.create_bundle/1` maps all audit events through
  `AllowList.export_audit_log/1`, which passes `after_summary` through without
  `LoginTrace.Export` scrubbing.
- Currently safe because the handler only persists whitelisted step fields, but a future
  change that widens persisted step metadata would not be covered by the diagnostic export path.
- File: `lib/relyra/diagnostic.ex`
- Remediation (optional): route `domain: :login` rows through `AllowList.export_login_trace/1`.

**I-02: Handler ignores AuditWriter.append_event/2 failures**
- `maybe_append_event/3` discards the return value (`_ = AuditWriter.append_event(...)`).
- Failed persistence is silent — operators lose trace rows without signal.
- File: `lib/relyra/telemetry/handlers/login_trace.ex`

**I-03: user.map attributes/roles not persisted for trace UI**
- Phase context D-08 calls for redacted post-mapping attributes/roles on the `user.map` step.
- Handler `summarize_step/1` captures only `outcome`, `error_code`, `duration_ms`; telemetry
  emits `attribute_count` but not mapped attributes. Export allows `attributes`/`roles` keys but
  they are never populated.
- Not a security issue (less data exposed); incomplete against stated UI spec.
- File: `lib/relyra/telemetry/handlers/login_trace.ex`

## Spot-checks performed

- `mix test test/security/login_trace_test.exs test/security/ci_gate_integrity_test.exs test/relyra/login_trace/export_test.exs test/relyra/telemetry/handlers/login_trace_test.exs --warnings-as-errors` — 14 tests, 0 failures
- Handler `@sensitive_keys` aligned with export scrub list; AuditWriter re-normalizes summaries on append
- Security corpus refutes `-----BEGIN`, `<?xml`, fixture `SignatureValue`, cert base64 prefix, and raw correlation id
- LiveView step table does not bind `after_summary` or raw audit structs
