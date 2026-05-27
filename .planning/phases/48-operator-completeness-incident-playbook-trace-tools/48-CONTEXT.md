# Phase 48: Operator completeness — incident playbook trace tools - Context

**Gathered:** 2026-05-27 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the login-trace operator surfaces discoverable from the incident playbook and Day-2 doc navigation — without reading source or v1.5 release notes. Doc-only ADOPT-03: update `guides/operations/incident_playbook.md` to document `/relyra/admin/connections/:connection_id/trace` and `mix relyra.trace`, wire when-to-use guidance into playbook scenarios, and cross-link from Getting Started §5 and `guides/overview.md` Day-2. No new SAML protocol surface, no public API changes, no new Mix tasks or LiveView code (trace shipped Phase 42).
</domain>

<decisions>
## Implementation Decisions

### Playbook centerpiece tables (ADOPT-03)
- **D-01:** Add login trace as a **sixth row** in the **Evidence surfaces** centerpiece table — name the LiveView route and CLI task with when-to-use one-liners (stepwise per-login timeline vs trust-mutation audit).
- **D-02:** Extend the **LiveView admin routes** table with `/relyra/admin/connections/:connection_id/trace` → `Relyra.LiveAdmin.ConnectionTraceLive` `:trace` (path prefix remains configurable via `relyra_admin_routes/2`; suffix shape is fixed per existing playbook convention).
- **D-03:** Add `mix relyra.trace` to the **Mix tasks** table with purpose: headless redacted login-trace inspection for the same connection-scoped step timeline as the LiveView.
- **D-04:** Update stale counts/copy: "7 `mix relyra.*` operator hand-tools" → **8** everywhere in the playbook (intro + Mix tasks section).
- **D-05:** Replace Scenario 3 Diagnose stale text ("no admin LiveView surface for replay activity in v1.4") with login-trace guidance — trace shows `replay.check` step outcomes; audit ledger still does not corroborate replays (retain that invariant).

### Scenario when-to-use wiring (≥2 required; target four)
- **D-06:** **Scenario 4 (Signature regression)** — Diagnose step: open login trace to see `signature.verify` step with exact `:error_code` (`:digest_mismatch`, `:invalid_signature`, `:trust_anchor_mismatch`) before/alongside cert inventory and `mix relyra.diagnostic`.
- **D-07:** **Scenario 5 (ACS misconfiguration)** — Diagnose step: login trace shows `response.validate` failures (`:destination_mismatch`, `:recipient_mismatch`, `:in_response_to_mismatch`) to pinpoint which field mismatched.
- **D-08:** **Scenario 6 (Attribute mapping breakage)** — Diagnose step: login trace shows `user.map` step outcome when mapping-stage telemetry alone is insufficient.
- **D-09:** **Scenario 3 (Replay storm)** — Diagnose step: login trace for `replay.check` step volume/outcomes per connection; retain note that replays write no audit rows.

### CLI contract & tool positioning
- **D-10:** Document the **actual** CLI invocation (ROADMAP shorthand omits required `--repo`):
  ```bash
  mix relyra.trace --repo MyApp.Repo --connection CONNECTION_ID [--last N]
  ```
  Default `--last` is **20**; aliases `-r`, `-c`, `-n` optional in docs footnote only if space permits.
- **D-11:** **When-to-use split:** LiveView for browser triage during an incident (reachable from connection detail `View Login Trace` link); CLI for headless/SSH/on-call without browser — both use `Query.get_login_traces/4` and shared redaction export (TRACE-03 equivalence).
- **D-12:** Clarify **"When in doubt"** section: `mix relyra.diagnostic` = redacted bundle for IdP/vendor or security handoff; **login trace** = per-attempt step timeline answering "which pipeline stage failed and with what error_code." Do not conflate the two as "the trace."

### Cross-doc sync (ROADMAP SC#2)
- **D-13:** Add Day-2 bullet in `guides/overview.md` for login-trace debugging → link to the updated incident playbook trace/evidence section (Phase 47 hub pattern).
- **D-14:** Add incident playbook / login-trace link under Getting Started §5 **Useful follow-on references** (same pattern as `production_ecto_path.md` from Phase 47).

### CI gates
- **D-15:** No new drift test this phase — existing `cmd test -f guides/operations/incident_playbook.md` presence guard in `mix ci.docs` is sufficient (Phase 47 D-11 precedent; no behaviour-callback copy-paste rot vector).
- **D-16:** `test/security/login_trace_test.exs` stays in `mix ci.security` only; do not move or duplicate into `ci.docs`.

### Claude's Discretion
- Exact Evidence surfaces row wording and subsection anchor text for login trace.
- Whether Getting Started §5 mentions trace inline vs playbook-only link.
- Mix tasks table ordering (alphabetical vs ops-workflow grouping).
- Whether to add a short "Login trace vs audit ledger" callout box under Evidence surfaces.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase Scope
- `.planning/ROADMAP.md` — Phase 48 goal, success criteria, ADOPT-03 requirements.
- `.planning/REQUIREMENTS.md` — ADOPT-03 definition.
- `.planning/PROJECT.md` — v1.6 Adoption Truth milestone; doc-only boundary; trace shipped v1.5.
- `.planning/STATE.md` — ci.docs gates; Phase 47 completion context.
- `.planning/threads/v1-6-milestone-assessment-2026-05-27.md` — Original ops-doc gap ("trace under-documented in ops table").

### Prior Phase Context
- `.planning/phases/47-onboarding-truth-getting-started-production-ecto-path/47-CONTEXT.md` — overview Day-2 hub pattern; ci.docs presence-gate precedent (D-11); deferred Phase 48 scope.
- `.planning/milestones/v1.5-phases/42-stepwise-login-trace-liveview/42-CONTEXT.md` — TRACE-01/02/03 decisions; shared export/redaction; audit `domain: :login` separate from trust mutations.

### Implementation Touchpoints
- `guides/operations/incident_playbook.md` — **primary edit target** (Evidence surfaces, LiveView routes, Mix tasks, Scenarios 3/4/5/6, "When in doubt").
- `guides/overview.md` — Day-2 cross-link (D-13).
- `guides/getting_started.md` — §5 follow-on references cross-link (D-14).
- `lib/relyra/live_admin/router.ex` — Trace route mount at `/connections/:connection_id/trace`.
- `lib/relyra/live_admin/connection_trace_live.ex` — LiveView step labels and empty-state copy.
- `lib/relyra/live_admin/components/connection_detail.ex` — `view-login-trace-link` navigation anchor.
- `lib/mix/tasks/relyra.trace.ex` — CLI flags (`--repo`, `--connection`, `--last`), default limit 20.
- `lib/relyra/live_admin/query.ex` — `get_login_traces/4` shared by LiveView and CLI.
- `lib/relyra/login_trace/export.ex` — Shared redaction export module.
- `test/security/login_trace_test.exs` — TRACE-02/03 security corpus (ci.security only).
- `mix.exs` — `ci.docs` alias (presence guard for incident playbook).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Relyra.LiveAdmin.ConnectionTraceLive` — six-step expandable login rows (decode → validate → signature → replay → user.map → session.establish) with redaction-gated output.
- `Mix.Tasks.Relyra.Trace` — headless companion; requires `--repo` and `--connection`; prints same export as LiveView.
- `Relyra.LiveAdmin.Query.get_login_traces/4` — single data path for LiveView and CLI.
- Connection detail `View Login Trace` link — already wires operators from connection show to trace page.

### Established Patterns
- Incident playbook uses three synchronized tables (Evidence surfaces centerpiece, LiveView routes, Mix tasks) with exact code anchors — extend, do not replace structure.
- Login traces persist as `domain: :login` audit rows — separate from trust-mutation audit vocabulary (`:connection`, `:metadata`, etc.).
- Phase 47 ci.docs pattern: presence guards via `cmd test -f`; drift tests only when copy-paste callback blocks can rot.
- Playbook scenarios follow Triage → Diagnose → Recover; trace belongs in **Diagnose** steps.

### Integration Points
- Playbook Evidence surfaces → scenario Diagnose steps (Scenarios 3, 4, 5, 6).
- `guides/overview.md` Day-2 → incident playbook trace section.
- Getting Started §5 → incident playbook (ops escalation path after first login).
- Existing `ci.docs` presence gate on `guides/operations/incident_playbook.md` — doc edits must keep file present; no alias change required unless planner finds gap.
</code_context>

<specifics>
## Specific Ideas

- v1.6 assessment flagged exact gap: "Operator / diagnostic 90% — trace under-documented in ops table."
- Scenario 3 currently contradicts shipped code — fixing stale v1.4 copy is in-scope doc honesty, not feature work.
- User confirmed all assumptions without correction (assumptions mode, 2026-05-27).
</specifics>

<deferred>
## Deferred Ideas

- New `test/docs/incident_playbook_drift_test.exs` for Mix-task table rot — not warranted this phase per Phase 47 precedent; revisit if playbook table drifts again post-ship.
- Phase 49: CONFORMANCE honesty, jtbd_gap_map refresh, preset taxonomy alignment (ADOPT-04/05/06).
- Updating troubleshooting.md cross-links to mention login trace explicitly — not in ADOPT-03 success criteria; optional if planner sees low-cost win.
</deferred>

---

*Phase: 48-operator-completeness-incident-playbook-trace-tools*
*Context gathered: 2026-05-27*
