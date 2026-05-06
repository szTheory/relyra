# Phase 16: Metadata Management UI - Pattern Map

**Mapped:** 2024-05-15
**Files analyzed:** 3
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/relyra/live_admin/connection_metadata_live.ex` | controller | request-response | `lib/relyra/live_admin/connections_live.ex` | exact |
| `lib/relyra/live_admin/router.ex` | route | request-response | `lib/relyra/live_admin/router.ex` (self) | exact |
| `lib/relyra/live_admin/components/connection_detail.ex` | component | request-response | `lib/relyra/live_admin/components/connection_detail.ex` (self) | exact |

## Pattern Assignments

### `lib/relyra/live_admin/connection_metadata_live.ex` (controller, request-response)

**Analog:** `lib/relyra/live_admin/connections_live.ex`

**Imports and LiveView setup pattern:**
```elixir
if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Relyra.LiveAdmin.ConnectionMetadataLive do
    @moduledoc false

    use Phoenix.LiveView

    alias Relyra.Ecto.{Connections, MappingCommands}
    alias Relyra.LiveAdmin.Query
    alias Relyra.LiveAdmin.Scope
    alias Relyra.Metadata
```

**Admin Auth/Guard and Mount pattern:**
```elixir
    @impl true
    def mount(_params, session, socket) do
      socket = ensure_admin_assigns(socket, session)

      {:ok,
       socket
       |> assign(:page_title, "Metadata Management")
       |> assign(:connection_id, nil)
       |> assign(:metadata_import_xml, "")
       |> assign(:metadata_source_url, "")}
    end
```
*(Note: Copy `ensure_admin_assigns/2`, `ensure_changed_assigns/1`, and `session_value/2` private functions from `ConnectionsLive` if not extracted to a shared module).*

**Core Pattern (existing metadata event handlers to migrate):**
```elixir
    def handle_event("import_metadata", %{"metadata_import" => %{"xml" => xml}}, socket) do
      action =
        Metadata.import_xml(
          socket.assigns.connection_id,
          xml,
          repo: socket.assigns.relyra_admin_repo,
          actor: socket.assigns.admin_scope.actor,
          cause: "live_admin_metadata_import"
        )

      handle_reload_result(socket, action, "Metadata imported.")
    end

    def handle_event("register_metadata_source", %{"metadata_source" => %{"url" => url}}, socket) do
      action =
        Metadata.register_source(
          socket.assigns.connection_id,
          %{
            url: url,
            actor: socket.assigns.admin_scope.actor,
            cause: "live_admin_register_source"
          },
          repo: socket.assigns.relyra_admin_repo
        )

      handle_reload_result(socket, action, "Metadata source registered.")
    end
```

**Error Handling & Flash Pattern:**
```elixir
    defp handle_reload_result(socket, {:ok, _result}, message) do
      {:noreply, socket |> reload_detail() |> put_flash(:info, message)}
    end

    defp handle_reload_result(socket, {:error, error}, _message) do
      {:noreply, put_flash(socket, :error, error.message)}
    end
```

---

### `lib/relyra/live_admin/components/connection_detail.ex` (component, request-response)

**Analog:** Existing UI to extract/migrate from `ConnectionDetail` component.

**Forms to migrate to new LiveView (Lines 44-77):**
```elixir
            <form phx-submit="import_metadata" style="display: grid; gap: 12px; margin-bottom: 16px;">
              <label>
                Import XML
                <textarea name="metadata_import[xml]" rows="6" style="width: 100%;">{@metadata_import_xml}</textarea>
              </label>
              <button type="submit">Import metadata XML</button>
            </form>

            <form phx-submit="register_metadata_source" style="display: grid; gap: 12px; margin-bottom: 16px;">
              <label>
                Metadata URL
                <input type="text" name="metadata_source[url]" value={@metadata_source_url} style="width: 100%;" />
              </label>
              <button type="submit">Register metadata source</button>
            </form>
```
*(Note: These forms need to be separated into distinct tab panels using URL parameters `?mode=xml` and `?mode=url` as per context).*

---

### `lib/relyra/live_admin/router.ex` (route)

**Analog:** Existing router paths.

**Routing Pattern:**
```elixir
          live_session :relyra_admin,
            on_mount: [
              {Relyra.LiveAdmin.OnMount, Keyword.put(opts, :base_path, path)}
            ] do
            # ...
            live "/connections/:connection_id", Relyra.LiveAdmin.ConnectionsLive, :show
            live "/connections/:connection_id/metadata", Relyra.LiveAdmin.ConnectionMetadataLive, :metadata
            # ...
          end
```

---

## Shared Patterns

### Async Execution (start_async / assign_async)
**Source:** Standard Phoenix LiveView `start_async/3` & `assign_async/3` patterns.
**Apply to:** Manual metadata refresh in `ConnectionMetadataLive`
*(No codebase analog exists for `start_async`/`assign_async` yet. Follow standard LiveView docs: `start_async(socket, :refresh, fn -> Metadata.refresh(...) end)` and handle via `handle_async(:refresh, {:ok, _}, socket)`)*.

### URL-Driven Tabs
**Source:** None exact, standard Phoenix LiveView pattern.
**Apply to:** `ConnectionMetadataLive` tab switching (`?mode=url` vs `?mode=xml`). Update `handle_params(params, _uri, socket)` to match `mode` parameter.

## No Analog Found

| File / Pattern | Role | Data Flow | Reason |
|----------------|------|-----------|--------|
| `assign_async` / `start_async` | LiveView Async Data | async | New functionality for this project to ensure non-blocking network requests during metadata refresh. Follow Phoenix LiveView standard practices (as specified in context and deep research prompts). |

## Metadata

**Analog search scope:** `lib/relyra/live_admin/**/*.ex`
**Files scanned:** 11
**Pattern extraction date:** 2024-05-15
