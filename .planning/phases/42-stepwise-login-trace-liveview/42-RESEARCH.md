# Phase 42: Stepwise login-trace LiveView — Research

**Researched:** 2026-05-27  
**Phase:** 42 — Stepwise login-trace LiveView  
**Requirements:** TRACE-01, TRACE-02, TRACE-03

## Summary

Phase 42 delivers the brand-promise "every login explains itself" surface: a LiveAdmin trace page, headless `mix relyra.trace`, and shared redaction. Persistence reuses `relyra_audit_events` with a new `:login` domain (string column — no migration). Span data is already emitted on the consume path via `Relyra.Telemetry.span/3`; the gap is accumulation, audit append, `LoginResult.validation_trace` population, export, and UI/CLI.

**Primary recommendation:** Process-scoped accumulation bracketed by `[:relyra, :saml, :response, :consume, :stop|:exception]`, six child `:stop` handlers, flush via `AuditWriter.append_event/2` (not co-commit). Single export module consumed by LiveView and CLI.

## Codebase Findings

### Telemetry (ready)

All six consume steps already call `Telemetry.span/3`:

| Step | Module | Event |
|------|--------|-------|
| `response.decode` | `binding.ex` | `[:response, :decode]` |
| `response.validate` | `validation_pipeline.ex` | `[:response, :validate]` |
| `signature.verify` | `signature.ex` | `[:signature, :verify]` |
| `replay.check` | `replay_store.ex` | `[:replay, :check]` |
| `user.map` | `user_mapper.ex` | `[:user, :map]` |
| `session.establish` | `session_adapter.ex` | `[:session, :establish]` |

Outer bracket: `relyra.ex` `consume_response/3` wraps `do_consume_response` in `[:response, :consume]`.

`:stop` metadata already carries `:outcome` and `:error_code` per catalog in `lib/relyra/telemetry.ex`.

### Gaps (must build)

| Gap | Location | Notes |
|-----|----------|-------|
| `validation_trace` never set | `normalize_consume_result/1` | Field exists on `LoginResult` but omitted in struct build |
| No `:login` audit domain | `audit_event.ex` `@domain_values` | DB is `:string` — Elixir enum extension only |
| No login actions | `@action_values` | Add `:succeeded`, `:failed` per CONTEXT D-04a |
| Trust timeline polluted risk | `query.ex` `get_connection_detail/4` | Preloads last 50 audit rows unfiltered — must exclude `domain: :login` |
| No trace handler | — | Precedent: `Handlers.LogAlerts` (opt-in); LoginTrace is default-on with `repo:` at attach |
| No export helpers | `allow_list.ex` | `export_audit_log/1` + `hash_correlation_id/1` exist; need trace-shaped export |
| No admin route | `live_admin/router.ex` | Metadata route pattern at `/connections/:id/metadata` |
| No security corpus | — | Follow Phase 41 `metadata_attribute_injection_test.exs` + `@gated_suites` pattern |

### Audit persistence shape

`after_summary` map keyed by step name (bounded by `@max_map_entries` 32):

```elixir
%{
  "steps" => %{
    "response.decode" => %{"outcome" => "ok", "duration_ms" => 12, "error_code" => nil},
    "response.validate" => %{...},
    ...
  },
  "overall_outcome" => "ok" | "error",
  "flow" => "sp_initiated" | "idp_initiated"
}
```

Strip sensitive keys via `AuditWriter` normalization (same `@sensitive_keys` as trust mutations). `correlation_id` stored raw in DB; hash only at export (D-07).

`actor` for login traces: use `"system:login_trace"` or connection-scoped synthetic actor — must satisfy `validate_length(:actor, min: 1)`.

### Span correlation strategy

`consume_response/3` runs synchronously in one process. Recommended:

1. On `[:response, :consume, :start]` — init `Process.put(:relyra_login_trace, %{steps: %{}, connection_id: ..., correlation_id: ..., repo: ...})`
2. On each of six `:stop` events — merge step into accumulator (only if accumulator present)
3. On `[:response, :consume, :stop|:exception]` — read final outcome from metadata, call `flush/1` → `AuditWriter.append_event`, clear Process dict
4. Pass `validation_trace` list to `normalize_consume_result` via Process.get before flush OR return tuple from pipeline (prefer explicit arg threading in `do_consume_response` error paths)

**Failure paths:** Early pipeline failure may skip later spans — persist partial steps; action `:failed`, still append.

### Handler attach

`Relyra.Application` only starts `StoreTables` — no global repo. Pattern:

- `Relyra.Telemetry.Handlers.LoginTrace.attach(repo: MyApp.Repo)` — idempotent, stores repo in handler config
- Call from host `Application.start/2` when Ecto enabled (document in moduledoc)
- Test setup: explicit attach + detach like `LogAlertsTest`
- Optional: `LiveAdmin.OnMount` calls attach once if `relyra_admin_repo` assign present (demo ergonomics)

### Redaction equivalence (TRACE-03)

Single module `Relyra.LoginTrace.Export` (recommended over bloating AllowList):

- `export_step/1`, `export_login/1` — delegate correlation hashing to `AllowList.hash_correlation_id/1`
- Drop/forbid keys matching `AuditWriter` sensitive set + signature/XML patterns
- LiveView and CLI both call this module only

### Security test patterns

Forbidden substrings in rendered output (from assessment + diagnostic precedent):

- `-----BEGIN` (PEM)
- `<?xml` or `<samlp:` / `<saml:` (raw assertion XML)
- Long base64 cert bodies (use fixture with known cert substring)
- `SignatureValue` element text

Drive tests through `ValidationPipeline.run/4` + LiveView render + `Mix.Tasks.Relyra.Trace` output capture.

## Architecture Decision

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Storage | `relyra_audit_events`, `domain: :login` | CONTEXT D-04/D-05; no parallel store |
| Correlation | Process dictionary per consume | Simple; consume is single-process sync |
| Step count | 6 rows (not 8) | CONTEXT D-09 resolves ROADMAP/requirements mismatch |
| Export | `Relyra.LoginTrace.Export` | TRACE-03 provable single path |
| Handler default | attach with `repo:` | Brand promise; differs from opt-in LogAlerts |

## Validation Architecture

| Requirement | Test type | Command / file |
|-------------|-----------|----------------|
| TRACE-01 LiveView | ExUnit LiveView | `test/relyra/live_admin/phase15_ui_contract_test.exs` (extend) |
| TRACE-02 redaction | Security corpus | `test/security/login_trace_test.exs` |
| TRACE-03 CLI parity | Security corpus + unit | Same file, shared export assertions |
| Audit domain | Unit | `test/relyra/telemetry/handlers/login_trace_test.exs` |
| CI hollow-gate | Meta | `ci_gate_integrity_test.exs` `@gated_suites` |

## Risks

| Risk | Mitigation |
|------|------------|
| `Ecto.Enum` rejects new domain until code deployed | String DB column; only Elixir `@domain_values` update |
| `summarizes_trust_change?/1` treats login as trust | Catch-all `false` already; add explicit test row |
| Handler missing in host app → no traces | Document attach; test asserts append when attached |
| Partial traces on early failure | Flush on consume `:exception` too |
| ROADMAP says "eight spans" | Plans follow CONTEXT six steps; update ROADMAP success text in Plan 04 doc task optional |

## RESEARCH COMPLETE
