defmodule DemoHost.Relyra.Connections do
  @moduledoc false
  @behaviour Relyra.ConnectionResolver

  @impl true
  def resolve_connection(_request_context, _opts) do
    {:error,
     Relyra.Error.new(:adapter_not_configured, "Configure DemoHost.Relyra.Connections", %{})}
  end
end
