# Phase 15 Validation

## Goal
Mount the optional Relyra LiveView admin surface inside a host Phoenix app so operators can create tenant-scoped SAML connections from a provider preset or blank form, edit draft configuration, move connections through draft/enabled/disabled lifecycle states, and see strict-default compatibility risks.

## Nyquist Criteria (Automated Verification)

| Requirement | Test Command | Acceptance Criteria |
| ----------- | ------------ | ------------------- |
| **ADM-01** (Mount/Shell) | `mix test test/phoenix/live_admin_test.exs` | The LiveView shell mounts successfully in the host app and routing allows navigation between the connection list, new connection, and detail views. |
| **ADM-02** (Preset/Create) | `mix test test/phoenix/live_admin_test.exs` | The new connection form correctly prefills when a preset is provided in the URL (`?preset=X`) and correctly passes these defaults into the Ecto context upon save. |
| **ADM-02** (Lifecycle & Badges) | `mix test test/phoenix/live_admin_test.exs` | The UI displays explicit immediate status badges (draft, enabled, disabled). Enabling a connection fails and surfaces readiness blockers if required runtime fields are missing. Lifecycle actions hit `Relyra.Ecto.Connections`. |
| **RISK-01** (Risk Panel) | `mix test test/phoenix/live_admin_test.exs` | Connections with legacy policies render an always-visible risk panel on both detail and edit views, and map legacy overrides (e.g. `legacy_sha1`) to user-facing roadmap language (e.g., `legacy_algorithm_policy`). |

## Manual Verification (If Required)
- Open the admin UI in a local server (`mix phx.server`).
- Verify the list on the left and detail on the right persists while routing.
- Create a new connection with an Okta preset and ensure the URL reflects `?preset=okta` and fields prefill.
- Inspect the risk panel wording to ensure it matches the roadmap language.
- Attempt to enable an unready connection and assert that specific readiness blocker messages appear.
