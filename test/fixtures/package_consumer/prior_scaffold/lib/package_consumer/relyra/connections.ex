defmodule PackageConsumer.Relyra.Connections do
  @moduledoc false
  @behaviour Relyra.ConnectionResolver

  @impl true
  def resolve_connection(%{connection_id: "conn-123"}, opts) do
    case Keyword.get(opts, :resolved_connection) do
      %{connection_id: "conn-123"} = connection ->
        {:ok, connection}

      _ ->
        {:error,
         Relyra.Error.new(:connection_unavailable, "Prior consumer connection is unavailable", %{
           reason: :not_found,
           operation: :resolve_connection
         })}
    end
  end

  def resolve_connection(_request_context, _opts) do
    {:error,
     Relyra.Error.new(:connection_unavailable, "Prior consumer connection is unavailable", %{
       reason: :not_found,
       operation: :resolve_connection
     })}
  end
end
