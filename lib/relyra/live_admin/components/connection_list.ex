if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Relyra.LiveAdmin.Components.ConnectionList do
    @moduledoc false
    use Phoenix.Component

    def connection_list(assigns) do
      ~H"""
      <aside data-testid="connection-list-region">
        <div
          data-testid="connection-list-header"
          style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;"
        >
          <h2 style="font-size: 18px; margin: 0;">Connections</h2>
          <a data-testid="new-connection-link" href={new_path(@base_path)}>New</a>
        </div>

        <div
          :if={@connections == []}
          data-testid="connection-list-empty-state"
          style="padding: 16px; border: 1px solid #ddd;"
        >
          No connections found for this scope.
        </div>

        <ul
          :if={@connections != []}
          data-testid="connection-list"
          style="list-style: none; margin: 0; padding: 0; border: 1px solid #ddd;"
        >
          <li
            :for={connection <- @connections}
            data-testid={"connection-list-item-#{connection.connection_id}"}
            style="border-bottom: 1px solid #eee; padding: 12px; display: flex; align-items: flex-start; gap: 12px;"
          >
            <input
              data-testid={"connection-select-#{connection.connection_id}"}
              type="checkbox"
              style="margin-top: 4px;"
              phx-click="toggle_selection"
              phx-value-connection-id={connection.connection_id}
              checked={MapSet.member?(@selected_ids, connection.connection_id)}
            />
            <div style="flex: 1;">
              <a
                data-testid={"connection-link-#{connection.connection_id}"}
                href={show_path(@base_path, connection.connection_id)}
              >
                <strong>{connection.display_name || connection.connection_id}</strong>
              </a>
              <div
                data-testid={"connection-summary-#{connection.connection_id}"}
                style="font-size: 12px; color: #666; margin-top: 4px;"
              >
                {connection.organization_id} · {connection.status} · {connection.provider_label}
              </div>
              <div :if={Map.get(connection, :auto_refresh_health) == :degraded} style="margin-top: 6px;">
                <span
                  data-testid={"auto-refresh-badge-#{connection.connection_id}"}
                  style="display: inline-block; padding: 2px 6px; font-size: 11px; background: #fff7e6; color: #b87600; border: 1px solid #d98b00; border-radius: 3px;"
                >
                  Auto-refresh degraded
                </span>
              </div>
              <div :if={Map.get(connection, :auto_refresh_health) == :suspended} style="margin-top: 6px;">
                <span
                  data-testid={"auto-refresh-badge-#{connection.connection_id}"}
                  style="display: inline-block; padding: 2px 6px; font-size: 11px; background: #ffebee; color: #c62828; border: 1px solid #c62828; border-radius: 3px;"
                >
                  Auto-refresh suspended
                </span>
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
