if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Relyra.LiveAdmin.ConnectionMetadataLive do
    @moduledoc false

    use Phoenix.LiveView

    alias Relyra.LiveAdmin.Scope

    @impl true
    def mount(params, session, socket) do
      try do
        socket = ensure_admin_assigns(socket, session)
        connection_id = params["connection_id"] || socket.assigns[:connection_id]

        {:ok,
         socket
         |> assign(:page_title, "Relyra Admin")
         |> assign(:connection_id, connection_id)
         |> assign(:mode, "xml")}
      rescue
        e -> 
          IO.inspect(e, label: "MOUNT ERROR")
          reraise e, __STACKTRACE__
      end
    end

    @impl true
    def handle_params(params, _uri, socket) do
      connection_id = params["connection_id"] || socket.assigns.connection_id
      mode = params["mode"] || "xml"

      {:noreply,
       socket
       |> assign(:connection_id, connection_id)
       |> assign(:mode, mode)}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <div id="metadata-management">
        <h1>Relyra Admin</h1>
        <h2>Metadata Management</h2>
        <div id="mode-panel"><%= if @mode == "xml", do: "XML Mode", else: "URL Mode" %></div>
      </div>
      """
    end

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
