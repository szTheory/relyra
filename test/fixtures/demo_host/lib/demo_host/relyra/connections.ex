defmodule DemoHost.Relyra.Connections do
  @moduledoc false
  @behaviour Relyra.ConnectionResolver

  alias Relyra.ConnectionResolver.Ecto, as: EctoResolver
  alias Relyra.Error

  @connections_key {__MODULE__, :connections}
  @ecto_mode_key {__MODULE__, :ecto_mode}

  def reset! do
    :persistent_term.put(@connections_key, %{})
    :persistent_term.put(@ecto_mode_key, false)
  end

  def enable_ecto!(repo \\ Relyra.TestSupport.EctoTestRepo) do
    :persistent_term.put(@ecto_mode_key, repo)
  end

  def disable_ecto! do
    :persistent_term.put(@ecto_mode_key, false)
  end

  def put_connection(connection_id, %Relyra.Connection{} = connection)
      when is_binary(connection_id) do
    connections = :persistent_term.get(@connections_key, %{})
    :persistent_term.put(@connections_key, Map.put(connections, connection_id, connection))
    :ok
  end

  @impl true
  def resolve_connection(%{connection_id: connection_id}, opts) when is_binary(connection_id) do
    case :persistent_term.get(@ecto_mode_key, false) do
      false ->
        case Map.get(:persistent_term.get(@connections_key, %{}), connection_id) do
          %Relyra.Connection{} = connection ->
            {:ok, connection}

          _ ->
            {:error,
             Error.new(:connection_unavailable, "Unknown demo host connection", %{
               reason: :not_found,
               connection_id: connection_id,
               operation: :resolve_connection
             })}
        end

      repo ->
        EctoResolver.resolve_connection(
          %{connection_id: connection_id},
          Keyword.put_new(opts, :repo, repo)
        )
    end
  end

  def resolve_connection(_request_context, _opts) do
    {:error,
     Error.new(:connection_unavailable, "Missing connection_id in request context", %{
       reason: :invalid_context,
       operation: :resolve_connection
     })}
  end
end
