defmodule DemoHost.Relyra.UserMapper do
  @moduledoc false
  @behaviour Relyra.UserMapper

  @impl true
  def map_attributes(_assertion, _connection, _opts) do
    {:error,
     Relyra.Error.new(:adapter_not_configured, "Configure DemoHost.Relyra.UserMapper", %{})}
  end
end
