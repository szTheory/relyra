# Phase 53: Setup and Operator UX - Validation

## Validation Strategy
This phase introduces the setup checklist UI (`LedgerLoopWeb.SetupLive`) and admin/support linking affordances.
The core of the validation ensures the UI workflows correctly advance state, securely display data without reducing scope, and properly link external routes without bypassing the trust boundaries.

## Testing Framework
- ExUnit for unit testing the controller actions and LiveView rendering.
- `Phoenix.LiveViewTest` for verifying the interactive task-list checklist step transitions.

## Scenarios to Validate

### Scenario 1: Setup Checklist Flow
- **Description:** Users can navigate the nonlinear setup checklist steps.
- **Acceptance Criteria:**
  - `SetupLive` mounts successfully.
  - Clicking on a step via `phx-click` transitions the UI state to that specific step.
  - The forms for "SP Settings", "IdP Metadata", "Mapping Preview", and "Test & Enable" correctly render on their respective steps.

### Scenario 2: Secure Receipt Rendering with Real Data
- **Description:** The enablement receipts render actual, redacted setup data, without exposing XML, PEM, or using dummy data.
- **Acceptance Criteria:**
  - The LiveView displays a receipt upon completing a connection configuration.
  - The receipt correctly queries `Relyra.Ecto.Connection` or mapping schemas to render redacted summary data (e.g., status, mapped identities).
  - The receipt MUST NOT use dummy or fixture data (enforces D-04).
  - No raw protocol artifacts (XML signatures, KeyInfo, PEMs) are leaked in the HTML response.

### Scenario 3: Admin Mock Session Injection
- **Description:** Evaluators can mock an administrative session to view Relyra LiveAdmin.
- **Acceptance Criteria:**
  - Sending `GET /login/admin` sets `"admin_actor"`, `"admin_actor_label"`, and `"admin_organization_id"` keys in the Plug session.
  - The response redirects to `/relyra/admin`.

### Scenario 4: Support Trace Handoff
- **Description:** The demo linking affordance successfully passes users into the existing LiveAdmin trace surface.
- **Acceptance Criteria:**
  - Sending `GET /support/scenario` resolves the connection ID from `LedgerLoop.Demo.Fixtures.relyra_support_scenario_id()`.
  - The response redirects precisely to `/relyra/admin/connections/:id/trace`.

## Automated Tests
- `demo/ledger_loop/test/ledger_loop_web/live/setup_live_test.exs` MUST cover the Setup Checklist Flow and Secure Receipt Rendering.
- `demo/ledger_loop/test/ledger_loop_web/controllers/route_affordance_controller_test.exs` MUST cover the Admin Mock Session and Support Trace Handoff.

## Manual Acceptance Testing
- Visit `localhost:4000/setup/sso` and click through the 4 steps. Verify that the receipt on the final step pulls real redacted data and is not mocked.
- Visit `localhost:4000/login/admin` and verify that the app redirects to the mounted Admin panel without returning a 401/403.
- Visit `localhost:4000/support/scenario` and verify it lands directly on a specific failing connection trace in the Admin UI.
