if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Relyra.LiveAdmin.Components.ConnectionList do
    @moduledoc false
    use Phoenix.Component

    def connection_list(assigns) do
      ~H"""
      <aside>
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;">
          <h2 style="font-size: 18px; margin: 0;">Connections</h2>
          <a href={new_path(@base_path)}>New</a>
        </div>

        <div :if={@connections == []} style="padding: 16px; border: 1px solid #ddd;">
          No connections found for this scope.
        </div>

        <ul :if={@connections != []} style="list-style: none; margin: 0; padding: 0; border: 1px solid #ddd;">
          <li :for={connection <- @connections} style="border-bottom: 1px solid #eee; padding: 12px; display: flex; align-items: flex-start; gap: 12px;">
            <input
              type="checkbox"
              style="margin-top: 4px;"
              phx-click="toggle_selection"
              phx-value-connection-id={connection.connection_id}
              checked={MapSet.member?(@selected_ids, connection.connection_id)}
            />
            <div style="flex: 1;">
              <a href={show_path(@base_path, connection.connection_id)}>
                <strong>{connection.display_name || connection.connection_id}</strong>
              </a>
              <div style="font-size: 12px; color: #666; margin-top: 4px;">
                {connection.organization_id} · {connection.status} · {connection.provider_label}
              </div>
            </div>
          </li>
        </ul>
      </aside>
      """
    end

    defp new_path(base_path), do: "#{base_path}/connections/new"
    defp show_path(base_path, connection_id), do: "#{base_path}/connections/#{connection_id}"
  end
else
  defmodule Relyra.LiveAdmin.Components.ConnectionList do
    @moduledoc false
  end
end
