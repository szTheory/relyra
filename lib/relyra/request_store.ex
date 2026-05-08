defmodule Relyra.RequestStore do
  @moduledoc """
  Public extension contract for request-intent persistence and one-time consumption.
  """

  alias Relyra.Error

  # Verification anchor: put_intent(relay_state, intent, opts  [])
  @callback put_intent(relay_state :: binary(), intent :: map(), opts :: keyword()) ::
              :ok | {:error, Error.t()}

  # Verification anchor: fetch_intent(relay_state, opts  [])
  @callback fetch_intent(relay_state :: binary(), opts :: keyword()) ::
              {:ok, map()} | {:error, Error.t()}

  # Verification anchor: consume_intent(relay_state, request_id, opts  [])
  @callback consume_intent(relay_state :: binary(), request_id :: binary(), opts :: keyword()) ::
              :ok | {:error, Error.t()}

  @spec put_intent(binary(), map(), keyword()) :: :ok | {:error, Error.t()}
  def put_intent(relay_state, intent, opts \\ [])

  def put_intent(relay_state, intent, opts)
      when is_binary(relay_state) and is_map(intent) and is_list(opts) do
    intent = Map.put_new(intent, :type, :authn)
    dispatch_request_store(request_store(opts), :put_intent, [relay_state, intent, opts])
  end

  @spec fetch_intent(binary(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def fetch_intent(relay_state, opts \\ [])

  def fetch_intent(relay_state, opts) when is_binary(relay_state) and is_list(opts) do
    dispatch_request_store(request_store(opts), :fetch_intent, [relay_state, opts])
  end

  @spec consume_intent(binary(), binary(), keyword()) :: :ok | {:error, Error.t()}
  def consume_intent(relay_state, request_id, opts \\ [])

  def consume_intent(relay_state, request_id, opts)
      when is_binary(relay_state) and is_binary(request_id) and is_list(opts) do
    dispatch_request_store(request_store(opts), :consume_intent, [relay_state, request_id, opts])
  end

  defp request_store(opts) do
    Keyword.get(opts, :request_store, Relyra.RequestStore.Default)
  end

  defp dispatch_request_store(adapter, operation, args)
       when is_atom(adapter) and is_atom(operation) and is_list(args) do
    if Code.ensure_loaded?(adapter) and function_exported?(adapter, operation, length(args)) do
      try do
        case apply(adapter, operation, args) do
          {:ok, result} when is_map(result) -> {:ok, result}
          {:error, %Error{} = error} -> {:error, error}
          :ok -> :ok
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

  defp dispatch_request_store(adapter, operation, _args) do
    {:error, adapter_not_configured(adapter, operation)}
  end

  defp adapter_not_configured(adapter, operation) do
    Error.new(
      :adapter_not_configured,
      "Request store adapter is unavailable",
      %{
        adapter: inspect(adapter),
        operation: operation,
        hint: "Configure :request_store with a module implementing Relyra.RequestStore"
      }
    )
  end

  defp invalid_adapter_result(adapter, operation, actual) do
    Error.new(
      :adapter_not_configured,
      "Request store adapter returned an invalid tuple",
      %{adapter: inspect(adapter), operation: operation, actual: inspect(actual)}
    )
  end

  defp adapter_dispatch_error(adapter, operation, reason) do
    Error.new(
      :adapter_not_configured,
      "Request store adapter raised during dispatch",
      %{adapter: inspect(adapter), operation: operation, reason: reason}
    )
  end
end
