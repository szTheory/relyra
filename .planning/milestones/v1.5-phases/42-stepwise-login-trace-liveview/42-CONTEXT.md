# Phase 42: Stepwise login-trace LiveView - Context

**Gathered:** 2026-05-27 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver the operator-facing login trace surface for v1.5: a LiveView at `/relyra/admin/connections/:connection_id/trace` showing the last N login attempts per connection as expandable step-by-step outcomes, plus a headless `mix relyra.trace` companion. Each login shows consume-path telemetry span outcomes with `:outcome`, `:error_code` (when present), and post-mapping role/attribute results where applicable. Reuses the existing telemetry catalog and audit ledger — no new tables, no parallel storage. Security gate ensures trace output never renders raw XML, PEM, base64 cert bodies, signature values, or key material. This phase does not add protocol features, publish versioning, or adopter DX beyond TRACE-01..TRACE-03.
</domain>

<decisions>
## Implementation Decisions

### LiveView routing & admin scaffold
- **D-01:** Mount trace LiveView at `/relyra/admin/connections/:connection_id/trace` via a new `live/3` route in `Relyra.LiveAdmin.Router`, mirroring `ConnectionMetadataLive` — no new top-level admin mount.
- **D-02:** Implement as `Relyra.LiveAdmin.ConnectionTraceLive` using existing `OnMount`, `Query`, admin shell grid, and `data-testid` conventions established by Phase 15 UI contract tests.
- **D-03:** Add a "View Login Trace" navigation link from `ConnectionDetail` (same card/link pattern as the existing metadata management section).

### Trace persistence (audit ledger, no new tables)
- **D-04:** Login traces persist via the existing `relyra_audit_events` table — no new Ecto schemas or tables. Extend `Relyra.Ecto.AuditEvent` **domain** enum with `:login` (DB column is `:string`; no migration required). **Do not** use an existing domain (`:connection`, etc.) plus a magic `cause` string as the discriminator — that pollutes trust-mutation timelines, bypasses LiveAdmin `domain`/`action` filters, and misuses lifecycle actions like `:updated`.
- **D-04a:** Add login-specific **actions** `:succeeded` and `:failed` to `@action_values`. Login attempts are outcomes, not config lifecycle events — reusing `:updated`/`:applied` would lie to operators and break audit hardening semantics (`summarizes_trust_change?/1` in `audit_hardening_test.exs`).
- **D-04b:** Reserve **`cause`** for flow context only (`"sp_initiated"`, `"idp_initiated"`), not as the primary trace discriminator. Optional one-line terminal summary in `cause` is acceptable (e.g. `"signature.verify:invalid_signature"`) for list-view scanability; the full stepwise receipt lives in `after_summary`.
- **D-05:** Introduce `Relyra.Telemetry.Handlers.LoginTrace` — a built-in handler (default-on when Ecto repo is configured) that accumulates consume-path span `:stop` metadata during `consume_response/3` and appends one audit row per login attempt via `AuditWriter.append_event/2`. Persist **both successes and failures** (Keycloak's "errors only by default" is an anti-pattern). Each row stores bounded step summaries in `after_summary`, keyed by step name, respecting `@max_map_entries` / `@max_binary_bytes` limits.
- **D-05a:** Login trace writes are **append-only observability**, not trust-mutation co-commits — they do not participate in config/cert/metadata/mapping transactions. Same table, separate domain semantics (threadline capture-vs-semantics pattern from engineering DNA).
- **D-06:** Populate `LoginResult.validation_trace` during `normalize_consume_result/1` from the same accumulated span data the handler persists — LiveView, CLI, and successful login results share one in-memory shape before audit append.
- **D-07:** Hash `correlation_id` at export/display time (same discipline as `AllowList.export_audit_log/1`) — never show raw correlation strings in UI or CLI output.
- **D-07a:** `LiveAdmin.Query.get_connection_detail/4` audit preload MUST exclude `domain: :login` rows (currently loads last 50 unfiltered audit events). Trust-mutation timeline and login trace timeline stay separate surfaces — principle of least surprise.

### Step catalog & display order
- **D-08:** Trace UI shows six primary consume-path steps in fixed order, each as an expandable row:
  1. `response.decode`
  2. `response.validate`
  3. `signature.verify` (nested inside validate pipeline in code, but displayed as its own row per requirements)
  4. `replay.check`
  5. `user.map` (include redacted post-mapping attributes/roles)
  6. `session.establish`
- **D-09:** Requirements text says "eight" spans but names six consume steps. Phase 42 treats the UI as **six step rows** plus login-level wrapper metadata (timestamp, overall outcome, hashed correlation id). Do **not** include `login` or `authn_request` spans — those belong to SP-initiated start, not ACS consumption trace.
- **D-10:** Each step row displays `:outcome`, `:error_code` (when present), and duration from telemetry measurements where available.

### Redaction & shared export
- **D-11:** Extend redaction via `Relyra.Diagnostic.AllowList` (or a sibling `Relyra.LoginTrace.Export` module called from AllowList) with `export_trace_step/1` and `export_login_trace/1`. Reuse `AuditWriter`'s `@sensitive_keys` discipline — never persist or render raw XML, PEM, base64 cert bodies, signature values, or key material.
- **D-12:** LiveView and `mix relyra.trace` MUST call the same export/redaction module so TRACE-03 "redaction-equivalent" is provable in tests.

### Headless CLI
- **D-13:** Add `Mix.Tasks.Relyra.Trace` following `Mix.Tasks.Relyra.Diagnostic` pattern: `mix app.start`, required `--repo`, required `--connection ID`, optional `--last N`.
- **D-14:** Default `--last` is **20** for both CLI and LiveView.
- **D-15:** CLI prints human-readable structured text by default. JSON output format is Claude's discretion during planning (`--format json` flag acceptable but not required in CONTEXT).

### Empty state & list bounds
- **D-16:** Empty state copy: "No login attempts recorded yet — traces appear after the first SAML response is consumed."
- **D-17:** No pagination in v1.5 — bounded list of last N only.

### Security test wiring
- **D-18:** Add `test/security/login_trace_test.exs` asserting rendered LiveView HTML and CLI output contain none of the forbidden material patterns (raw XML, PEM, base64 cert bodies, signature values, key material).
- **D-19:** Wire into `mix ci.security` as its own `cmd mix test test/security/login_trace_test.exs` line — preserve Phase 30 hollow-gate invariant.
- **D-20:** Register the suite in `@gated_suites` inside `test/security/ci_gate_integrity_test.exs`.

### Claude's Discretion
- Exact LiveView component structure and expand/collapse interaction styling (match existing inline-style admin patterns).
- Whether redaction lives as new functions on `AllowList` vs. a dedicated `LoginTrace.Export` module (must share one export path regardless).
- CLI `--format json` flag and exact text layout.
- LoginTrace handler attach point (Application.start vs. first Ecto repo use) as long as traces are captured for all consume paths without adopters manually wiring telemetry.
- Exact audit `action` atom for login events (`:completed`, `:failed`, or similar) within existing `@action_values` or a minimal enum extension on the existing schema.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope
- `.planning/ROADMAP.md` — Phase 42 goal, success criteria, TRACE-01..03 requirements, v1.5 sequencing (must complete before Phase 43 publish prep).
- `.planning/REQUIREMENTS.md` — TRACE-01, TRACE-02, TRACE-03 definitions.
- `.planning/STATE.md` — v1.5 carried decisions: no parallel trace storage, hollow-gate wiring for TRACE-02.
- `.planning/PROJECT.md` — "Explainable by default" brand pillar; audit co-commit invariant.
- `.planning/threads/v1-5-polish-milestone-assessment-2026-05-27.md` — Wedge 2 rationale, ~600-900 LOC estimate, security gate precedent.

### Prior phase context
- `.planning/phases/41-pre-publish-hygiene-tech-debt-sweep-security-hardening/41-CONTEXT.md` — Phase 41 completes before Phase 42; TD-03 parse-tree cleanup is upstream of any trace work touching encrypted-assertion paths.

### Implementation touchpoints
- `lib/relyra/live_admin/router.ex` — Route mount point.
- `lib/relyra/live_admin/connection_metadata_live.ex` — LiveView scaffold precedent.
- `lib/relyra/live_admin/components/connection_detail.ex` — Navigation link insertion point.
- `lib/relyra/live_admin/query.ex` — Connection detail / audit query patterns.
- `lib/relyra/telemetry.ex` — Span catalog and event namespaces for all six consume-path steps.
- `lib/relyra.ex` — `consume_response/3` and `normalize_consume_result/1` (validation_trace population).
- `lib/relyra/login_result.ex` — `validation_trace` field contract.
- `lib/relyra/ecto/audit_event.ex` — Audit domain enum extension target.
- `lib/relyra/ecto/audit_writer.ex` — Co-commit path, sensitive key redaction, bounded map limits.
- `lib/relyra/diagnostic/allow_list.ex` — Redaction precedent for export functions.
- `lib/mix/tasks/relyra.diagnostic.ex` — Mix task CLI pattern for `relyra.trace`.
- `test/security/ci_gate_integrity_test.exs` — `@gated_suites` contract for new security lane.
- `test/relyra/live_admin/phase15_ui_contract_test.exs` — Admin shell UI contract tests to extend.

### Span emission sites (consume path)
- `lib/relyra/protocol/binding.ex` — `response.decode`
- `lib/relyra/protocol/validation_pipeline.ex` — `response.validate`
- `lib/relyra/security/signature.ex` — `signature.verify`
- `lib/relyra/replay_store.ex` — `replay.check`
- `lib/relyra/user_mapper.ex` — `user.map`
- `lib/relyra/session_adapter.ex` — `session.establish`
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Relyra.LiveAdmin.Router.relyra_admin_routes/2` — macro for mounting admin routes; add trace route alongside metadata route.
- `Relyra.LiveAdmin.ConnectionMetadataLive` — full LiveView precedent (mount, handle_params, repo/scope assigns, stream patterns).
- `Relyra.LiveAdmin.Query.get_connection_detail/4` — connection fetch with audit preload; extend or sibling query for login trace rows filtered by `domain: :login`.
- `Relyra.Telemetry.span/3` — already wraps all six consume-path stages with `:outcome` and `:error_code` metadata on `:stop`.
- `Relyra.Diagnostic.AllowList` — export/redaction engine; extend for trace step export.
- `Relyra.Ecto.AuditWriter` — append-only audit writes with `@sensitive_keys` stripping and bounded map enforcement.
- `Mix.Tasks.Relyra.Diagnostic` — `--repo` required flag pattern, `app.start`, error handling via `Mix.raise/1`.

### Established Patterns
- LiveAdmin uses inline styles and `data-testid` attributes (Phase 15 contract); trace UI should match, not introduce a new design system.
- Security suites in `mix ci.security` are separate `cmd mix test` processes — never bare `test` steps.
- Audit co-commit: trust mutations write audit rows in the same transaction; login trace follows append-only audit pattern without bypassing `AuditWriter`.
- Telemetry handlers are opt-in reference implementations (`LogAlerts`); LoginTrace handler should attach by default when Ecto repo is configured (differs from LogAlerts opt-in — justified because trace persistence is core to the brand promise).

### Integration Points
- `router.ex` — new `live/3` route under existing `:relyra_admin` live_session.
- `connection_detail.ex` — navigation link to trace page.
- `relyra.ex` `consume_response/3` — span accumulation and `validation_trace` population.
- `audit_event.ex` — extend `@domain_values` with `:login`.
- `mix.exs` — add `ci.security` step and potentially `ci.admin_ui` coverage for trace LiveView.
- `test/security/ci_gate_integrity_test.exs` — register new gated suite.
</code_context>

<specifics>
## Specific Ideas

- The assessment thread notes `grep -r "stepwise\|login_trace" lib guides` returns nothing today — this phase is the first implementation of the brand promise UI receipt.
- Trace must ship in the v1.4.0 tarball (Phase 43+ publish prep depends on Phase 42 completing first per roadmap reorder 2026-05-27).
- `LoginResult.validation_trace` exists in the struct but is never populated — Phase 42 closes that gap alongside audit persistence.
</specifics>

<deferred>
## Deferred Ideas

None — analysis stayed within Phase 42 scope.
</deferred>

---

*Phase: 42-stepwise-login-trace-liveview*
*Context gathered: 2026-05-27*
