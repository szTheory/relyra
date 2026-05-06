# Phase 15: Admin shell + connection lifecycle - Pattern Map

**Mapped:** 2026-05-06
**Files analyzed:** 6
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/relyra/live_admin/connections_live.ex` | controller | request-response | `lib/relyra/live_admin/connections_live.ex` | exact |
| `lib/relyra/live_admin/components/connection_form.ex` | component | form / CRUD | `ConnectionsLive.render_connection_editor/2` | exact (extraction) |
| `lib/relyra/live_admin/components/connection_detail.ex` | component | display | `ConnectionsLive.render_connection_detail/1` | exact (extraction) |
| `lib/relyra/live_admin/components/risk_panel.ex` | component | display | `ConnectionsLive.render_connection_detail/1` (risk block) | exact (extraction) |
| `lib/relyra/live_admin/components/preset_picker.ex` | component | display / form | `ConnectionsLive.render_connection_editor/2` (preset select) | partial |
| `lib/relyra/live_admin/router.ex` | route | request-response | `lib/relyra/live_admin/router.ex` | exact |

## Pattern Assignments

### `lib/relyra/live_admin/connections_live.ex` (controller, request-response)

**Analog:** `lib/relyra/live_admin/connections_live.ex` (current monolithic file)

**Imports pattern** (lines 4-9):
```elixir
    use Phoenix.LiveView

    alias Relyra.Ecto.{CertificateInventory, Connections, MappingCommands}
    alias Relyra.LiveAdmin.Query
    alias Relyra.LiveAdmin.Scope
    alias Relyra.Metadata
```

**Routing / handle_params pattern** (lines 35-46):
```elixir
    @impl true
    def handle_params(params, _uri, socket) do
      audit_filters = Map.take(params, ["actor", "domain", "action"])
      connection_id = params["connection_id"]
      # NEW: preset = params["preset"] (D-07 requirement)

      with {:ok, connections} <-
             Query.list_connections(socket.assigns.relyra_admin_repo, socket.assigns.admin_scope),
           {:ok, detail} <- maybe_load_detail(socket, connection_id, audit_filters) do
        {:noreply,
         socket
         |> assign(:connections, connections)
         |> assign(:connection_id, connection_id)
         |> assign(:detail, detail)
         |> assign(:audit_filters, audit_filters)
         |> assign_forms(detail)}
```

**Event / Command pattern** (lines 56-74):
```elixir
    @impl true
    def handle_event("save_connection", %{"connection" => params}, socket) do
      repo = socket.assigns.relyra_admin_repo
      scope = socket.assigns.admin_scope
      attrs = connection_attrs(params, scope)
      audit = audit_context(scope, "live_admin_connection_save")

      result =
        case socket.assigns.live_action do
          :new -> Connections.create(attrs, repo: repo, audit: audit)
          _other -> Connections.update(socket.assigns.connection_id, attrs, repo: repo, audit: audit)
        end

      case result do
        {:ok, connection} ->
          {:noreply,
           socket
           |> put_flash(:info, "Connection saved.")
           |> push_navigate(to: show_path(socket.assigns.relyra_admin_base_path, connection.connection_id))}
```

---

### `lib/relyra/live_admin/components/connection_form.ex` (component, form / CRUD)

**Analog:** `ConnectionsLive.render_connection_editor/2` (lines 280-349)

**Core pattern**:
```elixir
      <section>
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;">
          <h2 style="font-size: 20px; margin: 0;">
            <%= if @mode == :new, do: "New connection", else: "Edit connection" %>
          </h2>
          <a :if={@detail} href={show_path(@relyra_admin_base_path, @detail.connection.connection_id)}>Back</a>
        </div>

        <form phx-submit="save_connection" style="display: grid; gap: 12px; border: 1px solid #ddd; padding: 16px;">
          <label>
            Display name
            <input type="text" name="connection[display_name]" value={@connection_form_data["display_name"]} style="width: 100%;" />
          </label>
          <!-- Additional fields... -->
        </form>
      </section>
```
*Note: This component must support D-06 (editable form prefilled with preset defaults) and D-09 (treating preset changes as reset-level actions).*

---

### `lib/relyra/live_admin/components/connection_detail.ex` (component, display)

**Analog:** `ConnectionsLive.render_connection_detail/1` (lines 357-550)

**Core Lifecycle pattern** (lines 366-371):
```elixir
          <div style="display: flex; gap: 12px;">
            <a href={edit_path(@relyra_admin_base_path, @detail.connection.connection_id)}>Edit</a>
            <button :if={@detail.connection.status != :enabled} phx-click="enable_connection">Enable</button>
            <button :if={@detail.connection.status == :enabled} phx-click="disable_connection">Disable</button>
          </div>
```
*Note: This component will be broken up into tabs or partials to support future phases.*

---

### `lib/relyra/live_admin/components/risk_panel.ex` (component, display)

**Analog:** `ConnectionsLive.render_connection_detail/1` risk block (lines 374-377)

**Core pattern**:
```elixir
        <div :for={risk <- @detail.risk_flags} style="border: 1px solid #d98b00; background: #fff7e6; padding: 12px; margin-bottom: 16px;">
          <strong>{risk.label}</strong>
          <pre style="white-space: pre-wrap; margin: 8px 0 0;">{Jason.encode!(risk.details, pretty: true)}</pre>
        </div>
```
*Note: Must align with D-15 (always-visible risk panel on detail and edit views).*

---

### `lib/relyra/live_admin/router.ex` (route, request-response)

**Analog:** `lib/relyra/live_admin/router.ex` (lines 11-16)

**Core route pattern**:
```elixir
            live "/", Relyra.LiveAdmin.ConnectionsLive, :index
            live "/connections/new", Relyra.LiveAdmin.ConnectionsLive, :new
            live "/connections/:connection_id", Relyra.LiveAdmin.ConnectionsLive, :show
            live "/connections/:connection_id/edit", Relyra.LiveAdmin.ConnectionsLive, :edit
```
*Note: D-07 expects query parameters (e.g., `?preset=okta`) to drive state via the existing `/connections/new` route, rather than creating new root paths.*

---

## Shared Patterns

### Error Handling / Flash Messages
**Source:** `lib/relyra/live_admin/connections_live.ex` (lines 75-77)
**Apply to:** All component form submissions
```elixir
        {:error, error} ->
          {:noreply, put_flash(socket, :error, error.message)}
```

### Authorization / Scope Assignment
**Source:** `lib/relyra/live_admin/connections_live.ex` (lines 683-705)
**Apply to:** All root LiveView mounts
```elixir
    defp ensure_admin_assigns(socket, session) do
      # ...
      admin_scope = socket.assigns[:admin_scope] || session_value(session, "admin_scope")
      # Validation ...
      socket
      |> assign(:admin_scope, admin_scope)
```

## No Analog Found

None. All required UX layers already exist in a monolithic form in `lib/relyra/live_admin/connections_live.ex` and are simply being refactored into focused Live Components or Phoenix Function Components to satisfy the Phase 15 structural requirements.

## Metadata

**Analog search scope:** `lib/relyra/live_admin/**/*.ex`
**Files scanned:** 6
**Pattern extraction date:** 2026-05-06
