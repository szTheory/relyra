# Phase 53: Setup And Operator UX - Context

**Gathered:** 2026-06-12 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 53 builds the host-owned setup pages showing SP settings, metadata intake, mapping preview, and test-login actions using a checklist pattern. It shows clear receipts stating what was verified. It mounts Relyra LiveAdmin for operator trust-state workflows, linking support scenarios to trace surfaces without confusing login traces with trust mutations.
</domain>

<decisions>
## Implementation Decisions

### Setup Checklist Implementation
- **D-01:** The host-owned setup placeholder will be replaced with a stateful Phoenix LiveView (`LedgerLoopWeb.SetupLive`) to handle the nonlinear steps without adding external frontend frameworks.

### Operator Admin Session Bootstrap
- **D-02:** The host app must introduce a mechanism (e.g., a mock admin login or a demo-only plug) to inject an `"admin_actor"` into the session so evaluators can actually view the mounted operator UI.

### Support Trace Surface Handoff
- **D-03:** The host-owned `/support/scenario` affordance will deep-link directly into the pre-existing mounted Relyra LiveAdmin trace surface (e.g., `/relyra/admin/connections/:id/trace`) rather than reinventing a custom trace viewer in the LedgerLoop UI.

### Receipt Presentation Boundary
- **D-04:** The test-login and enablement receipts will strictly render redacted summary data (e.g., from `Relyra.Ecto.Connection` or mapping schemas) instead of consuming raw protocol artifacts.

### Claude's Discretion
None - all assumptions locked as decisions.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- `.planning/PROJECT.md`
- `.planning/STATE.md`
- `demo/ledger_loop/lib/ledger_loop_web/router.ex`
- `demo/ledger_loop/lib/ledger_loop/relyra/admin_scope.ex`
- `demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_html/setup.html.heex`
- `demo/ledger_loop/lib/ledger_loop/demo/reset.ex`
- `.planning/phases/51-demo-app-foundation/51-UI-SPEC.md`
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The existing LiveAdmin UI (`Relyra.LiveAdmin.ConnectionTraceLive`) is natively designed to display `domain: :login` audit rows.
- Existing placeholder templates such as `demo/ledger_loop/lib/ledger_loop_web/controllers/route_affordance_html/setup.html.heex` provide a skeleton.

### Established Patterns
- Admin routes are protected by checking for `"admin_actor"` in the Plug session (`demo/ledger_loop/lib/ledger_loop/relyra/admin_scope.ex`).
- Redacted summary data is preferred over raw protocol artifacts per the `AuditWriter` implementation.

### Integration Points
- Setup flow will integrate with the LiveAdmin trace URL structure for seamless support handoffs.
</code_context>

<specifics>
## Specific Ideas

No specific requirements — open to standard approaches
</specifics>

<deferred>
## Deferred Ideas

None — analysis stayed within phase scope
</deferred>