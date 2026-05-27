if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Relyra.LiveAdmin.Components.RiskPanel do
    @moduledoc false
    use Phoenix.Component

    def risk_panel(assigns) do
      ~H"""
      <div
        :for={risk <- @risk_flags}
        data-testid="risk-panel"
        data-risk-label={risk.label}
        style="border: 1px solid #d98b00; background: #fff7e6; padding: 12px; margin-bottom: 16px;"
      >
        <strong data-testid="risk-panel-label">{risk.label}</strong>
        <pre data-testid="risk-panel-details" style="white-space: pre-wrap; margin: 8px 0 0;">{Jason.encode!(risk.details, pretty: true)}</pre>
      </div>
      """
    end
  end
else
  defmodule Relyra.LiveAdmin.Components.RiskPanel do
    @moduledoc false
  end
end
