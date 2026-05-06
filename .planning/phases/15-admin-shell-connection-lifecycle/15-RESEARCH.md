# Phase 15: Admin shell + connection lifecycle - Research

**Researched:** 2026-05-06
**Domain:** Phoenix LiveView Admin Interface
**Confidence:** HIGH

## Summary

This phase solidifies the optional LiveView admin shell that operators will use to manage SAML connections. The focus is on establishing a persistent routable frame (list on the left, detail on the right) and extracting the current monolithic scaffold into focused LiveView components. This sets the foundation for future phases (metadata, certificates, mappings).

**Primary recommendation:** Break `Relyra.LiveAdmin.ConnectionsLive` into smaller function/live components, ensuring URL routing handles all primary state transitions (new vs edit vs show) and preset selections (`?preset=okta`).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Phase 15 should use a persistent, routable LiveView admin shell: connection list/navigation on the left, selected connection detail/editor on the right.
- **D-02:** The URL remains canonical state through explicit routes such as index, new, show, and edit. Do not hide state in a client-side pseudo-SPA.
- **D-03:** The shell should be designed as the long-lived frame future phases extend for metadata, certificates, mappings, and audit, rather than as a temporary CRUD page set.
- **D-04:** Avoid a monolithic LiveView by keeping the shell stable while extracting detail regions into focused components/partials and loading heavy sections by route/tab as later phases land.
- **D-05:** New connection creation should start with provider choice first: explicit preset picker plus explicit `Custom` / blank path.
- **D-06:** After preset selection, show one editable form prefilled with that preset's defaults before save. Operators must see the effective starting configuration, not infer it from runtime hydration later.
- **D-07:** Preset choice should be reflected in routable LiveView state, e.g. `new?preset=okta`, so the flow is shareable, inspectable, and predictable.
- **D-08:** `Custom` must be explicit. Do not treat an empty preset dropdown as the primary custom flow.
- **D-09:** If the operator changes presets after entering data, the UI must treat it as a reset-level action rather than silently merging over existing edits.
- **D-10:** Keep `Save` / `Edit` separate from `Enable` / `Disable`. Editing draft configuration and promoting runtime-eligible trust state are different operator intents.
- **D-11:** The admin surface should expose immediate status badges plus a server-derived readiness summary for draft connections.
- **D-12:** Readiness blockers must come from the existing server-side runtime-readiness contract, not from ad hoc UI-side duplication.
- **D-13:** Typed readiness failures such as missing runtime fields or missing active signing certificates should be shown as explicit blockers before enable, not collapsed into a generic failed-save experience.
- **D-14:** Lifecycle transitions must continue to flow through the dedicated connection context commands so audit rows remain attributable as `updated`, `enabled`, and `disabled` rather than one overloaded mutation.
- **D-15:** Connections with weakening compatibility overrides must show an always-visible risk panel on both detail and edit views while the risky state exists.
- **D-16:** Save-time or enable-time warnings may exist as secondary confirmations, but they must not be the only risk surface.
- **D-17:** Risk panels should be human-readable and operator-facing: what was weakened, why it is risky, any expiry/time-box, and who/what introduced it if available.
- **D-18:** Planning and implementation should normalize the naming/story around compatibility overrides so the admin UI does not expose mismatched concepts between roadmap language (`legacy_algorithm_policy`) and current runtime fields (`algorithm_policy`, `legacy_sha1` semantics).
- **D-19:** The Phase 15 admin UX should optimize for principle of least surprise for both adopters and operators: explicit routes, explicit lifecycle actions, explicit preset choice, explicit risk visibility.
- **D-20:** Recommendation-first behavior is preferred downstream. Low-impact UI or implementation choices should be decided by research/planning/implementation agents without reopening user discussion unless they materially change trust guarantees, milestone scope, or host-app integration semantics.

### the agent's Discretion
- Exact component/module decomposition inside the persistent shell, provided route-driven state and future extensibility remain intact.
- Exact visual styling, layout density, and copy tone, provided the result remains calm, exact, operator-friendly, and consistent with the Relyra brand.
- Exact readiness badge wording and section names, provided draft vs enabled vs disabled and blocker reasons remain explicit.
- Exact route/query-param naming for preset-driven new flows, provided preset choice is URL-visible and least-surprise.
- Exact confirmation UX for risky save/enable flows, provided persistent contextual risk visibility remains primary.

### Deferred Ideas (OUT OF SCOPE)
- Project-level GSD preference tuning so recommendation-first, one-shot defaults become more standard across future phases except for truly high-impact decisions.
- Broader provider catalog expansion beyond the currently implemented preset set.
- Richer tabbed or lazy-loaded subsection architecture for metadata, certificates, mappings, and audit once Phases 16-18 land.
- Any redesign that collapses draft configuration and live runtime eligibility into one implicit save/publish step.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ADM-01 | Adopter can mount the optional Relyra LiveView admin surface with one router integration point while keeping authentication and authorization in the host app. | The current `Relyra.LiveAdmin.Router` macro already fulfills this structure. Implementation needs to verify the macro remains intact and fully functional. |
| ADM-02 | Operator can create a new SAML connection from a provider preset or blank form and move it through draft, enabled, and disabled lifecycle states. | Preset parameters (`?preset=X`) need to drive UI state, and Ecto context operations (`Connections.create`, `.update`, `.enable`, `.disable`) must back the lifecycle transitions. |
| RISK-01 | Operator can see clear risk panels whenever a connection uses `legacy_algorithm_policy` or similar compatibility overrides that weaken strict defaults. | `Relyra.LiveAdmin.Query` risk flags should be mapped directly to always-visible LiveView panels in the UI. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Router Integration & Host Mount | Frontend Server (SSR) | — | Phoenix router macro correctly maps LiveView routes in the host app while maintaining boundary control. |
| Admin UI State & Layout | Frontend Server (SSR) | — | Phoenix LiveView handles routing (`handle_params`), view layout (nav + detail), and preset prefill parameters. |
| Connection Persistence & Commands | API / Backend | Frontend Server | Ecto contexts (`Relyra.Ecto.Connections`) manage mutations and audit writes. UI only issues commands. |
| Default/Preset Expansion | API / Backend | — | `Relyra.Provider` defines provider settings and `ConnectionSnapshot` enforces boundaries before passing defaults to the UI layer. |
| Risk Factor Evaluation | API / Backend | Frontend Server | Server derives risk flags (`Relyra.LiveAdmin.Query`) based on schema fields; UI displays them. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix LiveView | ~> 0.20 / 1.0.0-rc | Reactive admin UI | Standard for building stateful interfaces in Phoenix. |
| Phoenix HTML | ~> 4.0 | UI rendering | Standard components and form builders. |

## Architecture Patterns

### Recommended Project Structure
```
lib/relyra/live_admin/
├── router.ex                # Canonical routes macro
├── on_mount.ex              # Mount and Auth hooks
├── query.ex                 # Repo access, list/detail loading, and risk flag derivation
├── connections_live.ex      # Main route handler, orchestrator, layout
└── components/
    ├── connection_list.ex   # Sidebar navigation and listing
    ├── connection_detail.ex # Main view for a selected connection
    ├── connection_form.ex   # The new/edit connection form
    ├── preset_picker.ex     # Provider preset selection
    └── risk_panel.ex        # The always-visible risk warnings
```

### Pattern 1: URL-Driven State
**What:** Using `handle_params` to process route changes rather than `handle_event` with local assigns, specifically for UI states like creating from a preset.
**When to use:** Whenever the user changes the "current page" state, such as moving between list, show, edit, and preset selection modes.
**Example:**
```elixir
def handle_params(params, _uri, socket) do
  preset = params["preset"]
  connection_id = params["connection_id"]
  # assign appropriate data to socket based on these params
end
```

### Anti-Patterns to Avoid
- **Hiding UI State:** Using client-side boolean flags (e.g. `@show_modal`) or internal assign states for things that represent distinct views (like `new` or `edit`).
- **Fat Controllers:** Keeping rendering logic inside the main LiveView module (`connections_live.ex`) instead of extracting them to function components.
- **Client-side Business Logic:** Validating connection readiness in the UI instead of relying on `Relyra.Ecto.Connection` changesets.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Lifecycle State Handling | Custom `status` logic | `Relyra.Ecto.Connections.enable/disable` | Existing boundaries ensure audit trails and readiness validation are executed transactionally. |
| Provider Defaults | UI-side dictionaries | `Relyra.Provider` registry | The provider module has specific logic for defaults and footguns. |
| Mount Authentication | Custom LiveView mounts | `Relyra.LiveAdmin.OnMount` | Ensures boundary protection within the host application. |

## Common Pitfalls

### Pitfall 1: Breaking Route Continuity
**What goes wrong:** Adding new LiveView pages or breaking the single-page layout look, disrupting the standard admin UI shell.
**Why it happens:** Attempting to build entirely separate live views for "New" vs "Edit" rather than changing the active detail component.
**How to avoid:** Use LiveView's live actions (e.g., `:index`, `:new`, `:edit`) with conditional component rendering inside the layout structure.

### Pitfall 2: Silent Preset Overwrites
**What goes wrong:** A user edits form data, then changes the preset selection, causing their custom data to be erased without warning or merging unexpectedly.
**Why it happens:** Implicit state updates during parameter changes.
**How to avoid:** Changing a preset should be treated as a reset-level action, or the UI should warn the user that changing presets will clear modifications.

### Pitfall 3: Recreating Risk Logic
**What goes wrong:** Trying to determine what makes a configuration "risky" inside `connection_detail.ex`.
**Why it happens:** Coupling UI design with domain rules.
**How to avoid:** `Relyra.LiveAdmin.Query` already generates `risk_flags`. The UI should only render the array of returned flags.

## Environment Availability

Step 2.6: SKIPPED (no external dependencies identified beyond Elixir runtime, which is inherently available in the development environment).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `mix.exs` and `config/test.exs` |
| Quick run command | `mix test test/phoenix/live_admin_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ADM-01 | Mounts in host app | unit/integration | `mix test test/phoenix/live_admin_test.exs` | ✅ Wave 0 |
| ADM-02 | Preset choice + lifecycle | integration | `mix test test/phoenix/live_admin_test.exs` | ✅ Wave 0 |
| RISK-01| Risk panels displayed | unit/integration | `mix test test/phoenix/live_admin_test.exs` | ✅ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/phoenix/live_admin_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
None — existing test infrastructure covers all phase requirements, though specific test cases for preset prefilling and detailed risk panel rendering will need expansion within `live_admin_test.exs`.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Host-app integration via `Relyra.LiveAdmin.OnMount` |
| V3 Session Management | yes | Host-app session token tracking |
| V4 Access Control | yes | `Relyra.LiveAdmin.ScopeProvider` |
| V5 Input Validation | yes | `Relyra.Ecto.Connection` changesets |
| V6 Cryptography | no | — |

### Known Threat Patterns for Phoenix LiveView

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cross-Site Scripting (XSS) | Tampering | Phoenix HTML's automatic escaping. Use `HEEx` safely. |
| Insecure Direct Object Reference | Information Disclosure | Parameter queries MUST filter by `admin_scope` from the host. |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/15-admin-shell-connection-lifecycle/15-CONTEXT.md` - Confirmed UI patterns, required lifecycle flows, and risk visibility strategies.
- `.planning/phases/15-admin-shell-connection-lifecycle/15-PATTERNS.md` - Verified current source code layout, pattern mappings for refactoring into components.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Phoenix LiveView is explicitly dictated by existing project stack.
- Architecture: HIGH - Matches explicitly documented goals in 15-CONTEXT.md and 15-PATTERNS.md.
- Pitfalls: HIGH - Pitfalls derived from specific strict user constraints regarding UI logic separation.

**Research date:** 2026-05-06
**Valid until:** 2026-06-06