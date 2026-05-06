if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Relyra.LiveAdmin.Components.ConnectionDetail do
    @moduledoc false
    use Phoenix.Component

    alias Relyra.LiveAdmin.Components.RiskPanel

    def connection_detail(%{detail: nil} = assigns) do
      ~H"""
      <div style="padding: 16px; border: 1px solid #ddd;">
        Connection not found.
      </div>
      """
    end

    def connection_detail(assigns) do
      ~H"""
      <section>
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;">
          <div>
            <h2 style="font-size: 20px; margin: 0;">{@detail.connection.display_name || @detail.connection.connection_id}</h2>
            <p style="color: #666; margin-top: 6px;">
              {@detail.connection.organization_id} ·
              <span style={"padding: 2px 8px; border-radius: 4px; font-weight: bold; #{status_style(@detail.connection.status)}"}>
                {@detail.connection.status}
              </span>
              · {@detail.provider_label}
            </p>
          </div>
          <div style="display: flex; flex-direction: column; align-items: flex-end; gap: 8px;">
            <div style="display: flex; gap: 12px;">
              <a href={edit_path(@base_path, @detail.connection.connection_id)}>Edit</a>
              <button :if={@detail.connection.status != :enabled} phx-click="enable_connection">Enable</button>
              <button :if={@detail.connection.status == :enabled} phx-click="disable_connection">Disable</button>
            </div>
            <div :if={map_size(@detail.connection.readiness_errors || %{}) > 0} style="color: #d32f2f; font-size: 14px; text-align: right; background: #ffebee; padding: 8px; border-radius: 4px; border: 1px solid #ffcdd2;">
              <strong style="display: block; margin-bottom: 4px;">Cannot enable connection:</strong>
              <ul style="margin: 0; padding-left: 20px; text-align: left;">
                <li :for={{field, messages} <- @detail.connection.readiness_errors}>
                  <strong>{field}:</strong> {if is_list(messages), do: Enum.join(messages, ", "), else: messages}
                </li>
              </ul>
            </div>
          </div>
        </div>

        <RiskPanel.risk_panel risk_flags={@detail.risk_flags} />

        <section style="display: grid; gap: 24px;">
          <section style="border: 1px solid #ddd; padding: 16px; display: flex; justify-content: space-between; align-items: center;">
            <div>
              <h3 style="margin-top: 0; margin-bottom: 8px;">Metadata</h3>
              <p style="margin: 0; color: #555;">Manage XML imports, metadata URLs, and view revision history.</p>
            </div>
            <a href={"#{@base_path}/connections/#{@detail.connection.connection_id}/metadata"} style="padding: 8px 16px; background: #f0f0f0; border: 1px solid #ccc; text-decoration: none; color: #333; border-radius: 4px;">Manage Metadata</a>
          </section>

          <section style="border: 1px solid #ddd; padding: 16px;">
            <h3 style="margin-top: 0;">Certificates</h3>
            <div :for={state <- [:active, :next, :retired]} style="margin-bottom: 16px;">
              <h4 style="margin-bottom: 8px;">{state}</h4>
              <div :if={Map.get(@detail.certificates_by_state, state) == []}>None</div>
              <div :for={certificate <- Map.get(@detail.certificates_by_state, state)} style="border: 1px solid #eee; padding: 12px; margin-bottom: 8px;">
                <div><strong>{certificate.fingerprint_sha256}</strong></div>
                <div style="font-size: 12px; color: #666;">
                  expires {certificate.not_after || "unknown"} · source {certificate.source}
                </div>
                <div style="display: flex; gap: 8px; margin-top: 8px;">
                  <button :if={state == :next} phx-click="activate_certificate" phx-value-fingerprint={certificate.fingerprint_sha256}>Promote next</button>
                  <button :if={state == :active} phx-click="retire_certificate" phx-value-fingerprint={certificate.fingerprint_sha256}>Retire active</button>
                  <button
                    :if={state == :retired and Map.get(@detail.certificates_by_state, :active) != []}
                    phx-click="rollback_certificate"
                    phx-value-restore_fingerprint={certificate.fingerprint_sha256}
                    phx-value-retire_fingerprint={List.first(@detail.certificates_by_state.active).fingerprint_sha256}
                  >
                    Restore and retire current active
                  </button>
                </div>
              </div>
            </div>
          </section>

          <section style="border: 1px solid #ddd; padding: 16px;">
            <h3 style="margin-top: 0;">Mappings</h3>
            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 16px;">
              <form phx-submit="save_attribute_mappings" style="display: grid; gap: 12px;">
                <label>
                  Attribute mappings JSON
                  <textarea name="mapping[json]" rows="12" style="width: 100%;">{@attribute_mappings_json}</textarea>
                </label>
                <button type="submit">Save attribute mappings</button>
              </form>

              <form phx-submit="save_group_mappings" style="display: grid; gap: 12px;">
                <label>
                  Group mappings JSON
                  <textarea name="mapping[json]" rows="12" style="width: 100%;">{@group_mappings_json}</textarea>
                </label>
                <button type="submit">Save group mappings</button>
              </form>
            </div>

            <table style="width: 100%; margin-top: 16px;">
              <thead>
                <tr>
                  <th align="left">When</th>
                  <th align="left">Action</th>
                  <th align="left">Actor</th>
                  <th align="left">Cause</th>
                </tr>
              </thead>
              <tbody>
                <tr :for={revision <- @detail.mapping_revisions}>
                  <td>{revision.inserted_at}</td>
                  <td>{revision.action}</td>
                  <td>{revision.actor}</td>
                  <td>{revision.cause}</td>
                </tr>
              </tbody>
            </table>
          </section>

          <section style="border: 1px solid #ddd; padding: 16px;">
            <h3 style="margin-top: 0;">Audit timeline</h3>
            <form method="get" action={show_path(@base_path, @detail.connection.connection_id)} style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; margin-bottom: 16px;">
              <label>
                Actor
                <input type="text" name="actor" value={@audit_filters["actor"]} style="width: 100%;" />
              </label>
              <label>
                Domain
                <input type="text" name="domain" value={@audit_filters["domain"]} style="width: 100%;" />
              </label>
              <label>
                Action
                <input type="text" name="action" value={@audit_filters["action"]} style="width: 100%;" />
              </label>
              <div style="display: flex; align-items: end;">
                <button type="submit">Filter</button>
              </div>
            </form>

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
          </section>
        </section>
      </section>
      """
    end

    defp edit_path(base_path, connection_id), do: "#{base_path}/connections/#{connection_id}/edit"
    defp show_path(base_path, connection_id), do: "#{base_path}/connections/#{connection_id}"

    defp status_style(:enabled), do: "background: #e8f5e9; color: #2e7d32;"
    defp status_style(:disabled), do: "background: #ffebee; color: #c62828;"
    defp status_style(_), do: "background: #f5f5f5; color: #616161;"
  end
else
  defmodule Relyra.LiveAdmin.Components.ConnectionDetail do
    @moduledoc false
  end
end
