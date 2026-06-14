# Phase 53: Setup and Operator UX - Research

**Researched:** 2026-06-12
**Domain:** Frontend UI / User Experience / Setup State Management
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** The host-owned setup placeholder will be replaced with a stateful Phoenix LiveView (`LedgerLoopWeb.SetupLive`) to handle the nonlinear steps without adding external frontend frameworks.
- **D-02:** The host app must introduce a mechanism (e.g., a mock admin login or a demo-only plug) to inject an `"admin_actor"` into the session so evaluators can actually view the mounted operator UI.
- **D-03:** The host-owned `/support/scenario` affordance will deep-link directly into the pre-existing mounted Relyra LiveAdmin trace surface (e.g., `/relyra/admin/connections/:id/trace`) rather than reinventing a custom trace viewer in the LedgerLoop UI.
- **D-04:** The test-login and enablement receipts will strictly render redacted summary data (e.g., from `Relyra.Ecto.Connection` or mapping schemas) instead of consuming raw protocol artifacts.

### the agent's Discretion
None - all assumptions locked as decisions.

### Deferred Ideas (OUT OF SCOPE)
None — analysis stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FLOW-01 | Customer/admin setup page shows copyable SP settings, provider vocabulary, IdP metadata/manual intake, mapping preview, test-login action, and enablement receipt. | Uses `LedgerLoopWeb.SetupLive` to build a stateful, interactive configuration wizard. |
| FLOW-02 | Setup UX uses a task-list/checklist pattern suitable for nonlinear SAML setup across multiple systems and people. | Phoenix LiveView state handles the linear steps without client-side frameworks. |
| FLOW-03 | Login/setup receipts state what was verified, mapped, replay-checked, and handed to the host app without exposing raw XML, PEM, or secrets. | Receipts will render sanitized data directly from `Relyra.Ecto.Connection` and `AuditWriter` representations. |
| ADMIN-01 | Demo mounts Relyra LiveAdmin for operator trust-state workflows using a proper repo and scope provider. | Mounts via existing `relyra_admin_routes` supplemented by a mock admin login to inject `"admin_actor"`. |
| ADMIN-02 | Demo links support scenarios to LiveAdmin trace/diagnostic surfaces without confusing login trace evidence with trust-mutation audit rows. | `RouteAffordanceController` for `/support/scenario` redirects to `/relyra/admin/connections/:id/trace` utilizing the seed scenario ID. |
| UX-01 | Demo UI follows Relyra's calm/operator brand: accessible status text, clear microcopy, light/dark/system support, and no color-only risk indicators. | Standard Elixir/Phoenix html/css components following the specifics from `53-UI-SPEC.md`. |
</phase_requirements>

## Summary

This phase replaces the placeholder setup UI in the demo application with a robust, checklist-based setup workflow built entirely in Phoenix LiveView. It focuses on safely presenting setup and enablement states without leaking cryptographic details or raw protocol inputs. A major part of this work involves creating the `LedgerLoopWeb.SetupLive` wizard for configuring and previewing SAML connections.

Additionally, we need to bridge the host application with the built-in `Relyra.LiveAdmin`. Since the router already mounts the routes with `LedgerLoop.Relyra.AdminScope`, we just need a developer affordance to mock the session injection (`admin_actor`) to prove access, alongside wiring the support trace link directly to the LiveAdmin trace view using the seeded fixture ID.

**Primary recommendation:** Build a multi-step checklist within `LedgerLoopWeb.SetupLive` using pure Phoenix components, keeping UI state strictly server-side. Implement a simple "Demo Admin Login" action in `RouteAffordanceController` that seeds the session for LiveAdmin testing.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Setup Checklist & Flow | Frontend Server (SSR) | API / Backend | Stateful Phoenix LiveView (`LedgerLoopWeb.SetupLive`) rendering non-linear state while managing backing Ecto records. |
| Operator Admin Session Bootstrap | API / Backend | Frontend Server (SSR) | Plug/controller action to inject `"admin_actor"` into the Plug session, mocking the host's admin authentication. |
| Support Trace Surface Handoff | Frontend Server (SSR) | — | Host UI affording a deep link to the existing Relyra LiveAdmin route (`/relyra/admin/connections/:id/trace`). |
| Receipt Presentation Boundary | Frontend Server (SSR) | API / Backend | LiveView rendering redacted summary data stored in Ecto without handling raw protocol artifacts. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Phoenix LiveView | ~> 1.1.0 | Real-time frontend rendering | Elixir standard for highly interactive, server-rendered UIs. |
| Phoenix HTML | ~> 4.1 | Template rendering | Baseline template rendering component for Phoenix. |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Relyra.LiveAdmin | ~> Local | Built-in admin UI | Mounted to display deep operator trace views. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Phoenix LiveView | React / Vue | Added build complexity, requires JSON API layer, violates UI-SPEC. |

**Installation:**
No new dependencies are required for this phase.

## Package Legitimacy Audit

No external packages are being added or installed during this phase.

## Architecture Patterns

### Recommended Project Structure
```
demo/ledger_loop/lib/ledger_loop_web/
├── live/
│   ├── setup_live.ex               # Manages state across checklist steps
│   └── setup_live.html.heex        # Structure for steps, receipts, and forms
├── controllers/
│   └── route_affordance_controller.ex # Adds `admin_login` to inject "admin_actor"
```

### Pattern 1: Admin Session Mocking
**What:** Mocking standard authentication flow to expose internal admin panels.
**When to use:** Local demo apps to simulate an authenticated operator.
**Example:**
```elixir
# In RouteAffordanceController
def admin_login(conn, _params) do
  conn
  |> put_session("admin_actor", "demo_admin")
  |> put_session("admin_actor_label", "Demo Administrator")
  |> put_session("admin_organization_id", "northstar")
  |> redirect(to: "/relyra/admin")
end
```

### Pattern 2: Linking Support Affordances
**What:** Bypassing standard host UI implementation to drop right into library trace surfaces.
**When to use:** Troubleshooting SAML traces and errors without building custom UI.
**Example:**
```elixir
# In RouteAffordanceController
def support(conn, _params) do
  # Fixtures.relyra_support_scenario_id() represents the seeded failing connection
  support_conn_id = LedgerLoop.Demo.Fixtures.relyra_support_scenario_id()
  redirect(conn, to: "/relyra/admin/connections/#{support_conn_id}/trace")
end
```

### Anti-Patterns to Avoid
- **Using Dummy Data for D-04:** Falling back to mock, dummy, or fixture data for enablement receipts instead of querying actual `Relyra.Ecto.Connection` state. We MUST NOT reduce scope.
- **Raw Artifact Exposure:** Displaying raw XML signatures, `KeyInfo` blobs, or PEM certificates on receipts (violates D-04 and FLOW-03).
- **Client-side Interactivity:** Using JavaScript hooks or Alpine.js for checklist switching when standard LiveView state events `phx-click` perfectly serve the purpose (violates D-01).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Trace Visualization | Custom Trace View | `Relyra.LiveAdmin.ConnectionTraceLive` | Relyra already built an audit-driven trace panel for failures. |
| Admin Session Mgmt | Guardian / Pow | Direct Plug session mutation | Mocking admin state in a demo does not warrant heavy auth layers. |

## Common Pitfalls

### Pitfall 1: Bypassing Admin Scope Injection
**What goes wrong:** Attempting to view `/relyra/admin` results in unauthorized errors.
**Why it happens:** The mounted `Relyra.LiveAdmin` expects a valid session scope (`admin_actor`) resolved by `LedgerLoop.Relyra.AdminScope`.
**How to avoid:** Ensure the mock login route correctly puts `"admin_actor"` and related keys into the Plug session before redirect.

### Pitfall 2: Over-exposing Secrets on UI
**What goes wrong:** Receipts inadvertently leak signing keys or private SAML metadata.
**Why it happens:** Passing raw `Relyra.Connection` configuration shapes to the UI instead of rendering sanitized outputs.
**How to avoid:** Specifically extract only standard data (e.g., status, mapped identities) into assign structures meant exclusively for the frontend.

### Pitfall 3: Using Dummy Data for Receipts
**What goes wrong:** Receipts render hardcoded or dummy/fixture data instead of actual verification results.
**Why it happens:** Attempting to simplify UI implementation by skipping the retrieval of real connection state.
**How to avoid:** Never use dummy data for D-04. The receipts must fetch and render real, redacted summary data directly from `Relyra.Ecto.Connection` and actual mapping schema results.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir / Mix | Compilation & Test | ✓ | ~> 1.19 | — |
| PostgreSQL | Ecto Stores | ✓ | (via pg_isready) | — |

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `demo/ledger_loop/test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FLOW-01 | Setup shows config forms | live | `mix test test/ledger_loop_web/live/setup_live_test.exs` | ❌ Wave 0 |
| FLOW-02 | Checklist advances | live | `mix test test/ledger_loop_web/live/setup_live_test.exs` | ❌ Wave 0 |
| FLOW-03 | Receipts show redacted data | live | `mix test test/ledger_loop_web/live/setup_live_test.exs` | ❌ Wave 0 |
| ADMIN-01 | Mock admin injects session | unit | `mix test test/ledger_loop_web/controllers/route_affordance_controller_test.exs` | ✅ Wave 0 |
| ADMIN-02 | Support links to trace | unit | `mix test test/ledger_loop_web/controllers/route_affordance_controller_test.exs` | ✅ Wave 0 |

### Wave 0 Gaps
- [ ] `demo/ledger_loop/test/ledger_loop_web/live/setup_live_test.exs` — covers FLOW-01, FLOW-02, FLOW-03

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Admin Mocking strictly confined to demo environment |
| V3 Session Management | yes | Plug session controls for mock admin authentication |
| V4 Access Control | yes | `LedgerLoop.Relyra.AdminScope` resolves bounds before mounting Admin |
| V5 Input Validation | yes | LiveView Ecto cast/validation for metadata ingestion |
| V6 Cryptography | no | Cryptography handled inherently by Relyra Core |

### Known Threat Patterns for Elixir / Phoenix

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Cross-Site Scripting (XSS) | Tampering | Phoenix HTML HEEx templates inherently escape inputs. |
| Admin Session Escalation | Privilege Elevation | Ensure mock login mechanisms never bypass security guards inside production. |

## Sources

### Primary (HIGH confidence)
- `.planning/phases/53-setup-and-operator-ux/53-CONTEXT.md` - Confirmed structural limits and decisions.
- `.planning/phases/53-setup-and-operator-ux/53-UI-SPEC.md` - Confirmed styling layout limits.
- `demo/ledger_loop/lib/ledger_loop_web/router.ex` - Verified location for LiveView mapping and admin routes.
- `demo/ledger_loop/lib/ledger_loop/demo/reset.ex` - Verified trace injection values.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Core Elixir/Phoenix ecosystem tools.
- Architecture: HIGH - Fully detailed out per decisions in CONTEXT.md.
- Pitfalls: HIGH - Documented anti-patterns map to requirements and invariants.

**Research date:** 2026-06-12
**Valid until:** 2026-07-12
