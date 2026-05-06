# Phase 15: Admin shell + connection lifecycle - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Mount the optional Relyra LiveView admin surface inside a host Phoenix app so operators can create tenant-scoped SAML connections from a provider preset or blank form, edit draft configuration, move connections through draft/enabled/disabled lifecycle states, and see strict-default compatibility risks without leaving the host app's auth boundary.

</domain>

<decisions>
## Implementation Decisions

### Admin shell shape
- **D-01:** Phase 15 should use a persistent, routable LiveView admin shell: connection list/navigation on the left, selected connection detail/editor on the right.
- **D-02:** The URL remains canonical state through explicit routes such as index, new, show, and edit. Do not hide state in a client-side pseudo-SPA.
- **D-03:** The shell should be designed as the long-lived frame future phases extend for metadata, certificates, mappings, and audit, rather than as a temporary CRUD page set.
- **D-04:** Avoid a monolithic LiveView by keeping the shell stable while extracting detail regions into focused components/partials and loading heavy sections by route/tab as later phases land.

### Connection creation flow
- **D-05:** New connection creation should start with provider choice first: explicit preset picker plus explicit `Custom` / blank path.
- **D-06:** After preset selection, show one editable form prefilled with that preset's defaults before save. Operators must see the effective starting configuration, not infer it from runtime hydration later.
- **D-07:** Preset choice should be reflected in routable LiveView state, e.g. `new?preset=okta`, so the flow is shareable, inspectable, and predictable.
- **D-08:** `Custom` must be explicit. Do not treat an empty preset dropdown as the primary custom flow.
- **D-09:** If the operator changes presets after entering data, the UI must treat it as a reset-level action rather than silently merging over existing edits.

### Lifecycle controls
- **D-10:** Keep `Save` / `Edit` separate from `Enable` / `Disable`. Editing draft configuration and promoting runtime-eligible trust state are different operator intents.
- **D-11:** The admin surface should expose immediate status badges plus a server-derived readiness summary for draft connections.
- **D-12:** Readiness blockers must come from the existing server-side runtime-readiness contract, not from ad hoc UI-side duplication.
- **D-13:** Typed readiness failures such as missing runtime fields or missing active signing certificates should be shown as explicit blockers before enable, not collapsed into a generic failed-save experience.
- **D-14:** Lifecycle transitions must continue to flow through the dedicated connection context commands so audit rows remain attributable as `updated`, `enabled`, and `disabled` rather than one overloaded mutation.

### Risk visibility
- **D-15:** Connections with weakening compatibility overrides must show an always-visible risk panel on both detail and edit views while the risky state exists.
- **D-16:** Save-time or enable-time warnings may exist as secondary confirmations, but they must not be the only risk surface.
- **D-17:** Risk panels should be human-readable and operator-facing: what was weakened, why it is risky, any expiry/time-box, and who/what introduced it if available.
- **D-18:** Planning and implementation should normalize the naming/story around compatibility overrides so the admin UI does not expose mismatched concepts between roadmap language (`legacy_algorithm_policy`) and current runtime fields (`algorithm_policy`, `legacy_sha1` semantics).

### DX and posture
- **D-19:** The Phase 15 admin UX should optimize for principle of least surprise for both adopters and operators: explicit routes, explicit lifecycle actions, explicit preset choice, explicit risk visibility.
- **D-20:** Recommendation-first behavior is preferred downstream. Low-impact UI or implementation choices should be decided by research/planning/implementation agents without reopening user discussion unless they materially change trust guarantees, milestone scope, or host-app integration semantics.

### the agent's Discretion
- Exact component/module decomposition inside the persistent shell, provided route-driven state and future extensibility remain intact.
- Exact visual styling, layout density, and copy tone, provided the result remains calm, exact, operator-friendly, and consistent with the Relyra brand.
- Exact readiness badge wording and section names, provided draft vs enabled vs disabled and blocker reasons remain explicit.
- Exact route/query-param naming for preset-driven new flows, provided preset choice is URL-visible and least-surprise.
- Exact confirmation UX for risky save/enable flows, provided persistent contextual risk visibility remains primary.

</decisions>

<specifics>
## Specific Ideas

- The right mental model is closer to Phoenix LiveDashboard's persistent shell than a generic scaffolded CRUD admin.
- The connection creation flow should feel like strong enterprise SSO products: choose the IdP first, then edit a concrete prefilled configuration with provider-aware defaults and labels.
- The admin surface should optimize for "understand this connection's trust state before mutating it", not "edit rows quickly".
- The user preference for this and future similar phases is recommendation-first, one-shot, low-friction decision handling. Escalate only unusually impactful product/security/architecture choices.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and milestone anchors
- `.planning/ROADMAP.md` — Phase 15 goal, success criteria, and v0.3 ordering.
- `.planning/REQUIREMENTS.md` — `ADM-01`, `ADM-02`, and `RISK-01` requirement anchors.
- `.planning/PROJECT.md` — strict-defaults philosophy, host-app auth boundary, LiveView admin milestone intent, and compatibility-override posture.
- `.planning/STATE.md` — current milestone/phase status.
- `.planning/MILESTONE-ARC.md` — v0.3 rationale and why admin UX is the biggest current adoption multiplier.

### Locked prior decisions
- `.planning/phases/07-schema-connection-aggregate/07-CONTEXT.md` — public `connection_id`, draft/disabled lifecycle semantics, runtime-readiness separation, and aggregate boundaries.
- `.planning/phases/08-resolver-adapter-snapshotting/08-CONTEXT.md` — pure runtime snapshot boundary, preset/default normalization, and typed resolver errors.
- `.planning/phases/09-metadata-import-export-refresh/09-CONTEXT.md` — operator-triggered metadata changes and last-known-good trust posture that the admin must surface later.
- `.planning/phases/10-certificate-inventory-rollover/10-CONTEXT.md` — staged certificate lifecycle semantics the admin shell will eventually expose.
- `.planning/phases/11-mapping-persistence-audit-hardening/11-CONTEXT.md` — dedicated mapping mutation boundary and same-transaction audit posture.
- `.planning/phases/14-mapping-audit-milestone-verification/14-CONTEXT.md` — persistence/audit semantics and recommendation-first decision posture carried into v0.3.

### Existing admin and runtime seams
- `lib/relyra/live_admin/router.ex` — mountable router macro and canonical admin routes.
- `lib/relyra/live_admin/on_mount.ex` — host-app auth/scope boundary and required mount options.
- `lib/relyra/live_admin/scope_provider.ex` — host callback contract for actor/scope resolution.
- `lib/relyra/live_admin/scope.ex` — current admin scope model.
- `lib/relyra/live_admin/connections_live.ex` — existing Phase 15 scaffold and current UI direction.
- `lib/relyra/live_admin/query.ex` — current query/detail/risk-flag seam.
- `test/phoenix/live_admin_test.exs` — existing route/mount/create smoke coverage.

### Connection, preset, and trust contracts
- `lib/relyra/ecto/connection.ex` — persisted connection schema, draft/update/publish/disable changesets, and runtime-readiness validation.
- `lib/relyra/ecto/connections.ex` — explicit create/update/enable/disable commands and audit integration.
- `lib/relyra/ecto/connection_loader.ex` — fail-closed resolver treatment of draft/disabled/unready connections.
- `lib/relyra/ecto/connection_snapshot.ex` — runtime preset/default expansion boundary.
- `lib/relyra/provider.ex` — provider preset registry, defaults, labels, and footgun checks.
- `lib/relyra/provider/okta.ex` — preset defaults and footguns for Okta.
- `lib/relyra/provider/entra.ex` — preset defaults and footguns for Entra.
- `lib/relyra/provider/google_workspace.ex` — preset defaults and footguns for Google Workspace.
- `lib/relyra/ecto/connection/runtime_policy.ex` — current runtime policy shape edited by the admin surface.
- `lib/relyra/security/algorithm_policy.ex` — strict-default algorithm policy semantics and legacy SHA-1 override behavior.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Relyra.LiveAdmin.Router` already gives the right library-hosted mount shape: one macro, host-owned pipeline, canonical LiveView routes.
- `Relyra.LiveAdmin.OnMount` and `Relyra.LiveAdmin.ScopeProvider` already preserve the required host-app auth/authz boundary.
- `Relyra.LiveAdmin.Query` already centralizes scoped connection listing, detail loading, and risk-flag derivation.
- `Relyra.Ecto.Connections` already exposes explicit lifecycle commands that match the preferred UI model.
- `Relyra.Provider` already contains the preset/default/label/footgun information the new-connection flow should surface directly.

### Established Patterns
- Runtime trust is fail-closed and server-derived. Admin UX should present that truth, not recreate it loosely in the client.
- Public/operator-facing identity uses `connection_id`, not a database primary key.
- Risky compatibility exists only as an explicit escape hatch, never as a silent convenience.
- Auditability matters as much as mutation success; operator intent should remain attributable and legible.

### Integration Points
- Phase 15 should solidify the shell and connection editor/detail model that Phases 16-18 extend instead of replacing.
- The creation flow must line up with provider presets now so later metadata/certificate/mapping screens inherit a coherent operator story.
- Readiness and risk presentation should become reusable detail/edit abstractions that later phases can enrich with metadata, certificate, and audit context.

</code_context>

<deferred>
## Deferred Ideas

- Project-level GSD preference tuning so recommendation-first, one-shot defaults become more standard across future phases except for truly high-impact decisions.
- Broader provider catalog expansion beyond the currently implemented preset set.
- Richer tabbed or lazy-loaded subsection architecture for metadata, certificates, mappings, and audit once Phases 16-18 land.
- Any redesign that collapses draft configuration and live runtime eligibility into one implicit save/publish step.

</deferred>

---

*Phase: 15-admin-shell-connection-lifecycle*
*Context gathered: 2026-05-06*
