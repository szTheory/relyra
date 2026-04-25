defmodule Relyra.ReplayStore do
  @moduledoc """
  Public extension contract for atomic replay-key consumption.
  """

  alias Relyra.Error

  # Verification anchor: consume_replay_key(replay_key, metadata, opts  [])
  @callback consume_replay_key(replay_key :: binary(), metadata :: map(), opts :: keyword()) ::
              :ok | {:error, Error.t()}

  @spec consume_replay_key(binary(), map(), keyword()) :: :ok | {:error, Error.t()}
  def consume_replay_key(replay_key, metadata, opts \\ [])

  def consume_replay_key(replay_key, metadata, opts)
      when is_binary(replay_key) and is_map(metadata) and is_list(opts) do
    telemetry_metadata = %{
      connection_id: Map.get(metadata, :connection_id),
      issuer: Map.get(metadata, :issuer),
      assertion_id: Map.get(metadata, :assertion_id)
    }

    Relyra.Telemetry.span([:replay, :check], telemetry_metadata, fn ->
      start_time = System.monotonic_time()

      result =
        case Keyword.get(opts, :replay_store_consume) do
          fun when is_function(fun, 3) ->
            fun.(replay_key, metadata, opts)

          _ ->
            dispatch_replay_store(replay_store(opts), :consume_replay_key, [
              replay_key,
              metadata,
              opts
            ])
        end

      latency = System.monotonic_time() - start_time
      replay_store_latency_ms = System.convert_time_unit(latency, :native, :millisecond)

      case result do
        :ok ->
          {:ok,
           Map.merge(telemetry_metadata, %{
             outcome: :ok,
             replay_store_latency_ms: replay_store_latency_ms
           })}

        {:error, %Error{} = error} ->
          {{:error, error},
           Map.merge(telemetry_metadata, %{
             outcome: :error,
             error_code: error.type,
             replay_store_latency_ms: replay_store_latency_ms
           })}
      end
    end)
  end

  defp replay_store(opts) do
    Keyword.get(opts, :replay_store, Relyra.ReplayStore.Default)
  end

  defp dispatch_replay_store(adapter, operation, args)
       when is_atom(adapter) and is_atom(operation) and is_list(args) do
    if Code.ensure_loaded?(adapter) and function_exported?(adapter, operation, length(args)) do
      try do
        case apply(adapter, operation, args) do
          :ok -> :ok
          {:error, %Error{} = error} -> {:error, error}
          other -> {:error, invalid_adapter_result(adapter, operation, other)}
        end
      rescue
        exception ->
          {:error, adapter_dispatch_error(adapter, operation, Exception.message(exception))}
      catch
        kind, reason ->
          {:error, adapter_dispatch_error(adapter, operation, "#{kind}:#{inspect(reason)}")}
      end
    else
      {:error, adapter_not_configured(adapter, operation)}
    end
  end

  defp dispatch_replay_store(adapter, operation, _args) do
    {:error, adapter_not_configured(adapter, operation)}
  end

  defp adapter_not_configured(adapter, operation) do
    Error.new(
      :adapter_not_configured,
      "Replay store adapter is unavailable",
      %{
        adapter: inspect(adapter),
        operation: operation,
        hint: "Configure :replay_store with a module implementing Relyra.ReplayStore"
      }
    )
  end

  defp invalid_adapter_result(adapter, operation, actual) do
    Error.new(
      :adapter_not_configured,
      "Replay store adapter returned an invalid tuple",
      %{adapter: inspect(adapter), operation: operation, actual: inspect(actual)}
    )
  end

  defp adapter_dispatch_error(adapter, operation, reason) do
    Error.new(
      :adapter_not_configured,
      "Replay store adapter raised during dispatch",
      %{adapter: inspect(adapter), operation: operation, reason: reason}
    )
  end
end
