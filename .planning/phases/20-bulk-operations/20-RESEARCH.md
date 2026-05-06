# Research: Bulk Operations (Phase 20)

## Objective
Operators can perform lifecycle and metadata actions across many connections at once, reducing operational toil for large-scale deployments.

## LiveView Integration (lib/relyra/live_admin)

### connections_live.ex (The Orchestrator)
- **Assigns:** Add `selected_ids: MapSet.new()` to track multi-selection.
- **Events:**
    - `toggle_selection`: Adds/removes a `connection_id` from `selected_ids`.
    - `toggle_all_selection`: Selects/Deselects all currently listed connections.
    - `bulk_action`: Triggers one of the supported actions (`:enable`, `:disable`, `:refresh`).
- **Flow:**
    1. Operator selects multiple items in the sidebar.
    2. A "Bulk Actions" menu appears (possibly replacing the "New" link or appearing above the list).
    3. Operator selects an action.
    4. LiveView loops through `selected_ids` and calls the domain layer.
    5. Success/Failure feedback is shown via flashes or an "Operation Summary" modal.

### connection_list.ex (The UI Component)
- Add a checkbox next to each connection display name.
- Checkbox state bound to `phx-click="toggle_selection"` with `phx-value-id`.
- Add a "Select All" checkbox at the top.

## Domain Layer (lib/relyra/ecto)

### New Module: Relyra.Ecto.BulkActions
- This module will act as a coordinator for multiple calls to `Connections` or `Metadata`.
- **Reasoning:** We want to keep the individual modules (`Connections`, `Metadata`) focused on single-record integrity and audit-atomicity.
- **Implementation Pattern:**
    ```elixir
    def run_bulk(repo, ids, action_fun, opts) do
      Enum.map(ids, fn id ->
        {id, action_fun.(id, opts)}
      end)
      |> Map.new()
    end
    ```
- **Audit Context:** Generate a `correlation_id` once and inject it into `opts[:audit]` for each individual call to ensure the whole batch is linked in the audit ledger.

## Success Criteria Checklist
- [ ] connections list supports multi-selection.
- [ ] Bulk "Enable" works and audits each connection.
- [ ] Bulk "Disable" works and audits each connection.
- [ ] Bulk "Refresh Metadata" works and audits each connection.
- [ ] Clear feedback on partial failures (e.g. 5 succeed, 1 fails).

## Security/Trust Considerations
- **Audit Atomicity:** Each connection's trust change must still co-commit its own audit row. Bulk operations are NOT a single database transaction across all connections, as one failure (e.g. external metadata timeout) should not rollback the entire batch.
- **Authorization:** Handled by the host app via `on_mount` / scope checks already in place for LiveAdmin.
