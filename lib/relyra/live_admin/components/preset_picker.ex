if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule Relyra.LiveAdmin.Components.PresetPicker do
    @moduledoc false

    use Phoenix.Component

    attr :provider_options, :list, required: true
    attr :selected_preset, :string, required: true
    attr :base_path, :string, required: true

    def preset_picker(assigns) do
      ~H"""
      <div style="margin-bottom: 24px;">
        <h3 style="font-size: 16px; margin-bottom: 8px; margin-top: 0;">Select Provider Preset</h3>
        <div style="display: flex; gap: 8px; flex-wrap: wrap;">
          <.preset_button
            label="Custom"
            value=""
            selected={@selected_preset == ""}
            base_path={@base_path}
          />
          <.preset_button
            :for={{label, value} <- @provider_options}
            label={label}
            value={value}
            selected={@selected_preset == value}
            base_path={@base_path}
          />
        </div>
      </div>
      """
    end

    attr :label, :string, required: true
    attr :value, :string, required: true
    attr :selected, :boolean, required: true
    attr :base_path, :string, required: true

    defp preset_button(assigns) do
      assigns =
        assign_new(assigns, :href, fn ->
          if assigns.value == "" do
            "#{assigns.base_path}/connections/new"
          else
            "#{assigns.base_path}/connections/new?preset=#{assigns.value}"
          end
        end)

      ~H"""
      <.link
        patch={@href}
        style={"padding: 8px 16px; border: 1px solid #ccc; border-radius: 4px; text-decoration: none; color: inherit; background-color: " <> if(@selected, do: "#e0e0e0", else: "transparent")}
      >
        {@label}
      </.link>
      """
    end
  end
else
  defmodule Relyra.LiveAdmin.Components.PresetPicker do
    @moduledoc false
  end
end
