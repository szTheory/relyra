if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Relyra.LiveAdmin.ConnectionMetadataLive do
    @moduledoc false

    use Phoenix.LiveView

    alias Relyra.LiveAdmin.Scope
    alias Relyra.LiveAdmin.Query
    alias Relyra.Metadata

    @impl true
    def mount(params, session, socket) do
      socket = ensure_admin_assigns(socket, session)
      connection_id = params["connection_id"] || socket.assigns[:connection_id]

      {:ok,
       socket
       |> assign(:page_title, "Metadata Management")
       |> assign(:connection_id, connection_id)
       |> assign(:mode, "xml")
       |> assign(:detail, nil)
       |> stream_configure(:metadata_revisions, dom_id: &(&1.id))
       |> stream(:metadata_revisions, [])}
    end

    @impl true
    def handle_params(params, _uri, socket) do
      connection_id = params["connection_id"] || socket.assigns.connection_id
      mode = params["mode"] || "xml"

      {:noreply,
       socket
       |> assign(:connection_id, connection_id)
       |> assign(:mode, mode)
       |> reload_detail()}
    end

    @impl true
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

    def handle_event("refresh_metadata", _params, socket) do
      opts =
        [
          repo: socket.assigns.relyra_admin_repo,
          actor: socket.assigns.admin_scope.actor,
          cause: "live_admin_metadata_refresh"
        ]
        |> maybe_put_req(socket.assigns.relyra_admin_req)

      connection_id = socket.assigns.connection_id

      socket =
        socket
        |> assign(:refresh_status, :loading)
        |> start_async(:metadata_refresh, fn ->
          Metadata.refresh(connection_id, opts)
        end)

      {:noreply, socket}
    end

    @impl true
    def handle_async(:metadata_refresh, {:ok, {:ok, _result}}, socket) do
      socket =
        socket
        |> assign(:refresh_status, :idle)
        |> put_flash(:info, "Metadata refresh completed.")
        |> reload_detail()

      {:noreply, socket}
    end

    def handle_async(:metadata_refresh, {:ok, {:error, error}}, socket) do
      socket =
        socket
        |> assign(:refresh_status, :idle)
        |> put_flash(:error, error.message)

      {:noreply, socket}
    end

    def handle_async(:metadata_refresh, {:exit, _reason}, socket) do
      socket =
        socket
        |> assign(:refresh_status, :idle)
        |> put_flash(:error, "Metadata refresh failed to complete.")

      {:noreply, socket}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <div id="metadata-management" style="padding: 24px; font-family: Helvetica, Arial, sans-serif; max-width: 1000px; margin: 0 auto;">
        <div style="margin-bottom: 24px;">
          <a href={"#{@relyra_admin_base_path}/connections/#{@connection_id}"} style="text-decoration: none; color: #0066cc;">&larr; Back to connection</a>
        </div>
        
        <h1 style="font-size: 28px; margin-top: 0;">Metadata Management</h1>

        <div style="display: flex; gap: 16px; margin-bottom: 24px; border-bottom: 1px solid #ddd; padding-bottom: 12px;">
          <.link patch={"#{@relyra_admin_base_path}/connections/#{@connection_id}/metadata?mode=xml"} style={"padding: 8px 16px; text-decoration: none; border-radius: 4px; " <> if(@mode == "xml", do: "background: #f0f0f0; font-weight: bold; color: #333;", else: "color: #0066cc;")}>
            XML Import
          </.link>
          <.link patch={"#{@relyra_admin_base_path}/connections/#{@connection_id}/metadata?mode=url"} style={"padding: 8px 16px; text-decoration: none; border-radius: 4px; " <> if(@mode == "url", do: "background: #f0f0f0; font-weight: bold; color: #333;", else: "color: #0066cc;")}>
            URL Sync
          </.link>
        </div>

        <div :if={@mode == "xml"} style="margin-bottom: 32px;">
          <h2 style="font-size: 20px; margin-top: 0;">Import via XML</h2>
          <p style="color: #666; margin-bottom: 16px;">Paste raw SAML metadata XML to immediately update this connection.</p>
          <form phx-submit="import_metadata" style="display: grid; gap: 12px;">
            <label>
              <textarea name="metadata_import[xml]" rows="8" style="width: 100%; font-family: monospace;"></textarea>
            </label>
            <div>
              <button type="submit" style="padding: 8px 16px; background: #0066cc; color: white; border: none; border-radius: 4px; cursor: pointer;">Import metadata XML</button>
            </div>
          </form>
        </div>

        <div :if={@mode == "url"} style="margin-bottom: 32px;">
          <h2 style="font-size: 20px; margin-top: 0;">Sync via URL</h2>
          <p style="color: #666; margin-bottom: 16px;">Register a metadata URL to enable on-demand synchronization.</p>
          <form phx-submit="register_metadata_source" style="display: grid; gap: 12px; margin-bottom: 16px;">
            <label>
              Metadata URL
              <input type="text" name="metadata_source[url]" value={if @detail && @detail.metadata_source, do: @detail.metadata_source.url, else: ""} style="width: 100%; padding: 8px;" />
            </label>
            <div>
              <button type="submit" style="padding: 8px 16px; background: #0066cc; color: white; border: none; border-radius: 4px; cursor: pointer;">Register metadata source</button>
            </div>
          </form>

          <div :if={@detail && @detail.metadata_source}>
            <button phx-click="refresh_metadata" disabled={@refresh_status == :loading} style={"padding: 8px 16px; border-radius: 4px; cursor: pointer; " <> if(@refresh_status == :loading, do: "background: #e0e0e0; color: #999; border: 1px solid #ccc;", else: "background: #f0f0f0; border: 1px solid #ccc;")}>
              {if @refresh_status == :loading, do: "Refreshing...", else: "Refresh metadata now"}
            </button>
            <p style="color: #666; font-size: 13px; margin-top: 8px; margin-bottom: 0;">
              Note: Newly fetched trust material (like certificates) is not implicitly promoted and requires a manual rollover step on the main connection page.
            </p>
          </div>
        </div>

        <div style="border-top: 1px solid #ddd; padding-top: 24px;">
          <h2 style="font-size: 20px; margin-top: 0;">Revision History</h2>
          
          <table style="width: 100%; border-collapse: collapse; text-align: left; margin-top: 16px;">
            <thead>
              <tr style="border-bottom: 2px solid #eee;">
                <th style="padding: 12px 8px;">When</th>
                <th style="padding: 12px 8px;">Trigger</th>
                <th style="padding: 12px 8px;">Outcome</th>
                <th style="padding: 12px 8px;">Actor</th>
              </tr>
            </thead>
            <tbody id="metadata-revisions" phx-update="stream">
              <tr :for={{id, revision} <- @streams.metadata_revisions} id={id} style={"border-bottom: 1px solid #eee;" <> if(@detail && @detail.connection.active_metadata_revision_id == revision.id, do: " background: #f0f7ff;", else: "")}>
                <td style="padding: 12px 8px;">
                  {revision.inserted_at}
                  <span :if={@detail && @detail.connection.active_metadata_revision_id == revision.id} style="margin-left: 8px; padding: 2px 6px; font-size: 12px; background: #cce5ff; color: #004085; border-radius: 4px;">Active</span>
                </td>
                <td style="padding: 12px 8px;">{revision.trigger}</td>
                <td style="padding: 12px 8px;">
                  <span style={"padding: 4px 8px; border-radius: 4px; font-size: 14px; " <> if(revision.outcome == :success, do: "background: #e8f5e9; color: #2e7d32;", else: "background: #ffebee; color: #c62828;")}>
                    {revision.outcome}
                  </span>
                </td>
                <td style="padding: 12px 8px;">{revision.actor || "system"}</td>
              </tr>
            </tbody>
          </table>
          <p :if={Enum.empty?(@streams.metadata_revisions.inserts)} style="color: #666; margin-top: 16px;">No metadata revisions found.</p>
        </div>
      </div>
      """
    end

    defp handle_reload_result(socket, {:ok, _result}, message) do
      {:noreply, socket |> put_flash(:info, message) |> reload_detail()}
    end

    defp handle_reload_result(socket, {:error, error}, _message) do
      {:noreply, put_flash(socket, :error, error.message)}
    end

    defp reload_detail(%{assigns: %{connection_id: nil}} = socket), do: socket

    defp reload_detail(socket) do
      case Query.get_metadata_revisions(
             socket.assigns.relyra_admin_repo,
             socket.assigns.admin_scope,
             socket.assigns.connection_id
           ) do
        {:ok, detail} ->
          socket
          |> assign(:detail, detail)
          |> stream(:metadata_revisions, detail.revisions, reset: true)

        {:error, error} ->
          put_flash(socket, :error, error.message)
      end
    end

    defp maybe_put_req(opts, nil), do: opts
    defp maybe_put_req(opts, req), do: Keyword.put(opts, :req, req)

    defp ensure_admin_assigns(socket, session) do
      socket = ensure_changed_assigns(socket)
      admin_scope = socket.assigns[:admin_scope] || session_value(session, "admin_scope")
      repo = socket.assigns[:relyra_admin_repo] || session_value(session, "relyra_admin_repo")
      req = socket.assigns[:relyra_admin_req] || session_value(session, "relyra_admin_req")

      base_path =
        socket.assigns[:relyra_admin_base_path] ||
          session_value(session, "relyra_admin_base_path") ||
          "/relyra/admin"

      cond do
        is_nil(admin_scope) ->
          raise ArgumentError, "Relyra admin requires :admin_scope to be assigned before mount"

        is_nil(repo) ->
          raise ArgumentError, "Relyra admin requires :relyra_admin_repo to be assigned before mount"

        true ->
          socket
          |> assign(:admin_scope, admin_scope)
          |> assign(:relyra_admin_repo, repo)
          |> assign(:relyra_admin_req, req)
          |> assign(:relyra_admin_base_path, base_path)
      end
    end

    defp ensure_changed_assigns(%Phoenix.LiveView.Socket{assigns: assigns} = socket) do
      if Map.has_key?(assigns, :__changed__) do
        socket
      else
        %{socket | assigns: Map.put(assigns, :__changed__, %{})}
      end
    end

    defp session_value(session, key) do
      Map.get(session, key) || Map.get(session, String.to_atom(key))
    end
  end
else
  defmodule Relyra.LiveAdmin.ConnectionMetadataLive do
    @moduledoc false
  end
end
