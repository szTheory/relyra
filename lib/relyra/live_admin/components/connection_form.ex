if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Relyra.LiveAdmin.Components.ConnectionForm do
    @moduledoc false

    use Phoenix.Component

    alias Relyra.LiveAdmin.Components.RiskPanel

    attr(:connection_form_data, :map, required: true)
    attr(:admin_scope, :map, required: true)
    attr(:risk_flags, :list, default: [])

    def connection_form(assigns) do
      ~H"""
      <div style="display: grid; gap: 16px;">
        <RiskPanel.risk_panel risk_flags={@risk_flags} />

        <form phx-submit="save_connection" style="display: grid; gap: 12px; border: 1px solid #ddd; padding: 16px;">
        <label>
          Display name
          <input type="text" name="connection[display_name]" value={@connection_form_data["display_name"]} style="width: 100%;" />
        </label>

        <label :if={is_nil(@admin_scope.organization_id)}>
          Organization ID
          <input type="text" name="connection[organization_id]" value={@connection_form_data["organization_id"]} style="width: 100%;" />
        </label>

        <input :if={!is_nil(@admin_scope.organization_id)} type="hidden" name="connection[organization_id]" value={@admin_scope.organization_id} />

        <input type="hidden" name="connection[provider_preset]" value={@connection_form_data["provider_preset"]} />

        <label>
          SP entity ID
          <input type="text" name="connection[sp_entity_id]" value={@connection_form_data["sp_entity_id"]} style="width: 100%;" />
        </label>

        <label>
          ACS URL
          <input type="text" name="connection[acs_url]" value={@connection_form_data["acs_url"]} style="width: 100%;" />
        </label>

        <label>
          IdP entity ID
          <input type="text" name="connection[idp_entity_id]" value={@connection_form_data["idp_entity_id"]} style="width: 100%;" />
        </label>

        <label>
          IdP SSO URL
          <input type="text" name="connection[idp_sso_url]" value={@connection_form_data["idp_sso_url"]} style="width: 100%;" />
        </label>

        <label>
          <input type="hidden" name="connection[allow_idp_initiated?]" value="false" />
          <input type="checkbox" name="connection[allow_idp_initiated?]" value="true" checked={@connection_form_data["allow_idp_initiated?"] == "true"} />
          Allow IdP-initiated SSO
        </label>

        <label>
          <input type="hidden" name="connection[require_signed_assertions?]" value="false" />
          <input type="checkbox" name="connection[require_signed_assertions?]" value="true" checked={@connection_form_data["require_signed_assertions?"] == "true"} />
          Require signed assertions
        </label>

        <label>
          <input type="hidden" name="connection[require_signed_response?]" value="false" />
          <input type="checkbox" name="connection[require_signed_response?]" value="true" checked={@connection_form_data["require_signed_response?"] == "true"} />
          Require signed response
        </label>

        <label>
          Clock skew seconds
          <input type="text" name="connection[clock_skew_seconds]" value={@connection_form_data["clock_skew_seconds"]} style="width: 100%;" />
        </label>

        <label>
          NameID format
          <input type="text" name="connection[name_id_format]" value={@connection_form_data["name_id_format"]} style="width: 100%;" />
        </label>

        <label>
          Algorithm policy JSON
          <textarea name="connection[algorithm_policy_json]" rows="6" style="width: 100%;">{@connection_form_data["algorithm_policy_json"]}</textarea>
        </label>

        <button type="submit">Save connection</button>
      </form>
      </div>
      """
    end
  end
else
  defmodule Relyra.LiveAdmin.Components.ConnectionForm do
    @moduledoc false
  end
end
