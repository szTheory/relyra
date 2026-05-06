# Phase 18: Mapping editor + audit timeline hardening - Pattern Map

**Mapped:** 2026-05-06
**Files analyzed:** 3
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/relyra/live_admin/components/connection_detail.ex` | component | request-response | Self (existing view) | exact |
| `lib/relyra/live_admin/connections_live.ex` | controller | event-driven | Self (existing event handlers) | exact |
| `lib/relyra/ecto/mapping_commands.ex` | model / command | CRUD | Self (existing rollback) | exact |

## Pattern Assignments

### `lib/relyra/live_admin/components/connection_detail.ex` (component, request-response)

**Analog:** `lib/relyra/live_admin/components/connection_detail.ex`

**Active Badge / Pill Pattern** (lines 20-22):
Use the existing connection status badge pattern for mapping revisions.
```elixir
<span style={"padding: 2px 8px; border-radius: 4px; font-weight: bold; #{status_style(@detail.connection.status)}"}>
  {@detail.connection.status}
</span>
```
Idiomatic translation for `is_active={index == 0}` mapping revision pill:
```elixir
<span :if={index == 0} style="padding: 2px 8px; border-radius: 4px; font-weight: bold; background: #e8f5e9; color: #2e7d32;">
  Active
</span>
```

**Audit Ledger Table Pattern** (lines 207-224):
This is the current table to be modified with `JS.toggle` expandable rows for the `diff_summary`.
```elixir
<table style="width: 100%;">
  <thead>
    <tr>
      <th align="left">When</th>
      <th align="left">Domain</th>
      <th align="left">Action</th>
      <th align="left">Actor</th>
      <th align="left">Cause</th>
    </tr>
  </thead>
  <tbody>
    <tr :for={event <- @detail.audit_events}>
      <td>{event.inserted_at}</td>
      <td>{event.domain}</td>
      <td>{event.action}</td>
      <td>{event.actor}</td>
      <td>{event.cause}</td>
    </tr>
  </tbody>
</table>
```

---

### `lib/relyra/live_admin/connections_live.ex` (controller, event-driven)

**Analog:** `lib/relyra/live_admin/connections_live.ex`

**Flash Error Handling Pattern** (lines 201-206):
This pattern correctly handles the Ecto transation `rollback` emitted by `MappingCommands`.
```elixir
defp handle_reload_result(socket, {:ok, _result}, message) do
  {:noreply, socket |> reload_detail() |> put_flash(:info, message)}
end

defp handle_reload_result(socket, {:error, error}, _message) do
  {:noreply, put_flash(socket, :error, error.message)}
end
```

**Mapping Save Event Handlers** (lines 109-138):
These handlers will be updated to accept the structured `inputs_for` form data instead of JSON strings.
```elixir
def handle_event("save_attribute_mappings", %{"mapping" => %{"json" => json}}, socket) do
  with {:ok, mappings} <- decode_mapping_json(json) do
    handle_reload_result(
      socket,
      MappingCommands.replace_attribute_mappings(
        socket.assigns.connection_id,
        mappings,
        repo: socket.assigns.relyra_admin_repo,
        audit: audit_context(socket.assigns.admin_scope, "live_admin_attribute_mapping_update")
      ),
      "Attribute mappings saved."
    )
  else
    {:error, message} ->
      {:noreply, put_flash(socket, :error, message)}
  end
end
```

---

### `lib/relyra/ecto/mapping_commands.ex` (model / command, CRUD)

**Analog:** `lib/relyra/ecto/mapping_commands.ex`

**Audit Rollback Pattern** (lines 309-335):
This confirms that the backend tech debt is already addressed via explicit rollback, requiring only UI wiring in Phase 18.
```elixir
defp append_audit(
       repo,
       connection,
       audit,
       action,
       before_snapshot,
       after_snapshot,
       changed_field,
       revision_id,
       operation
     ) do
  case AuditWriter.append_event(...) do
    {:ok, event} ->
      {:ok, event}

    {:error, %Error{} = error} ->
      rollback(
        repo,
        Error.new(
          error.type,
          error.message,
          Map.put(error.details, :operation, operation)
        )
      )
  end
end
```

## No Analog Found

Files with no close match in the codebase (planner should use RESEARCH.md/Phoenix standard patterns instead):

| Pattern | Role | Data Flow | Reason |
|---------|------|-----------|--------|
| `Phoenix.Component.inputs_for/1` | UI component | request-response | No dynamic forms using `inputs_for` currently exist in `lib/relyra/live_admin/components/`. Use standard Phoenix LiveView pattern. |
| `Phoenix.LiveView.JS.toggle` | UI interaction | event-driven | No expandable table rows using `JS.toggle` exist yet. Use standard `Phoenix.LiveView.JS` module pattern. |

## Metadata

**Analog search scope:** `lib/relyra/live_admin/**/*.ex`, `lib/relyra/ecto/**/*.ex`
**Files scanned:** 12 LiveAdmin components + `mapping_commands.ex`
**Pattern extraction date:** 2026-05-06
