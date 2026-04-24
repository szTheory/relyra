defmodule Relyra.RequestStore.ETS do
  @moduledoc false

  @behaviour Relyra.RequestStore

  use GenServer

  require Logger

  alias Relyra.Error

  @table :relyra_request_intents
  @consume_retry_attempts 3

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) when is_list(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec ensure_table!(keyword()) :: :ok
  def ensure_table!(opts \\ []) when is_list(opts) do
    warn_prod_ets!(opts)

    case :ets.whereis(@table) do
      :undefined ->
        _ =
          :ets.new(@table, [
            :named_table,
            :public,
            :set,
            read_concurrency: true,
            write_concurrency: true
          ])

        :ok

      _tid ->
        :ok
    end
  end

  @impl true
  @spec init(keyword()) :: {:ok, map()}
  def init(opts) when is_list(opts) do
    :ok = ensure_table!(opts)
    {:ok, %{}}
  end

  @impl true
  @spec put_intent(binary(), map(), keyword()) :: :ok | {:error, Error.t()}
  def put_intent(relay_state, intent, opts \\ [])

  def put_intent(relay_state, intent, opts)
      when is_binary(relay_state) and is_map(intent) and is_list(opts) do
    :ok = ensure_table!(opts)

    with {:ok, request_id} <- request_id_from_intent(intent),
         true <-
           :ets.insert_new(
             @table,
             {relay_state,
              %{
                request_id: request_id,
                intent: intent,
                consumed_at: nil,
                expires_at: expires_at_from_intent(intent)
              }}
           ) do
      :ok
    else
      false ->
        {:error,
         Error.new(
           :request_intent_consumed,
           "Request intent already exists for relay state",
           %{relay_state: relay_state, operation: :put_intent}
         )}

      {:error, %Error{} = error} ->
        {:error, error}
    end
  end

  def put_intent(_relay_state, _intent, _opts) do
    {:error,
     Error.new(
       :request_intent_not_found,
       "Request intent input is invalid",
       %{operation: :put_intent, reason: :invalid_input}
     )}
  end

  @impl true
  @spec fetch_intent(binary(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def fetch_intent(relay_state, opts \\ [])

  def fetch_intent(relay_state, opts) when is_binary(relay_state) and is_list(opts) do
    :ok = ensure_table!(opts)

    case :ets.lookup(@table, relay_state) do
      [{^relay_state, %{request_id: request_id, intent: intent, consumed_at: nil} = entry}] ->
        {:ok, decorate_intent(intent, request_id, entry.expires_at)}

      [{^relay_state, %{consumed_at: consumed_at}}] when not is_nil(consumed_at) ->
        {:error,
         Error.new(
           :request_intent_consumed,
           "Request intent is already consumed",
           %{relay_state: relay_state, operation: :fetch_intent}
         )}

      _ ->
        {:error,
         Error.new(
           :request_intent_not_found,
           "Request intent was not found",
           %{relay_state: relay_state, operation: :fetch_intent}
         )}
    end
  end

  def fetch_intent(_relay_state, _opts) do
    {:error,
     Error.new(
       :request_intent_not_found,
       "Relay state must be a binary",
       %{operation: :fetch_intent, reason: :invalid_relay_state}
     )}
  end

  @impl true
  @spec consume_intent(binary(), binary(), keyword()) :: :ok | {:error, Error.t()}
  def consume_intent(relay_state, request_id, opts \\ [])

  def consume_intent(relay_state, request_id, opts)
      when is_binary(relay_state) and is_binary(request_id) and is_list(opts) do
    :ok = ensure_table!(opts)
    consume_intent_with_retry(relay_state, request_id, @consume_retry_attempts, opts)
  end

  def consume_intent(_relay_state, _request_id, _opts) do
    {:error,
     Error.new(
       :request_intent_not_found,
       "Relay state and request ID must be binaries",
       %{operation: :consume_intent, reason: :invalid_input}
     )}
  end

  @spec warn_prod_ets!(keyword()) :: :ok
  def warn_prod_ets!(opts \\ []) when is_list(opts) do
    if prod_runtime?(opts) do
      Logger.warning(
        "Relyra.RequestStore.ETS is single-node only and provides non-durable replay protection; use an Ecto adapter for production-safe request intent semantics."
      )
    end

    :ok
  end

  defp consume_intent_with_retry(relay_state, request_id, retries_remaining, opts) do
    case :ets.take(@table, relay_state) do
      [{^relay_state, %{request_id: ^request_id, consumed_at: nil} = entry}] ->
        :ets.insert(
          @table,
          {relay_state, %{entry | consumed_at: Keyword.get(opts, :now, DateTime.utc_now())}}
        )

        :ok

      [{^relay_state, %{request_id: ^request_id, consumed_at: consumed_at} = entry}]
      when not is_nil(consumed_at) ->
        :ets.insert(@table, {relay_state, entry})

        {:error,
         Error.new(
           :request_intent_consumed,
           "Request intent has already been consumed",
           %{relay_state: relay_state, request_id: request_id, operation: :consume_intent}
         )}

      [{^relay_state, %{request_id: stored_request_id} = entry}] ->
        :ets.insert(@table, {relay_state, entry})

        {:error,
         Error.new(
           :request_intent_not_found,
           "Request intent request_id does not match relay state binding",
           %{
             relay_state: relay_state,
             request_id: request_id,
             stored_request_id: stored_request_id,
             operation: :consume_intent
           }
         )}

      [] ->
        handle_missing_intent(relay_state, request_id, retries_remaining, opts)
    end
  end

  defp handle_missing_intent(relay_state, request_id, retries_remaining, opts) do
    case :ets.lookup(@table, relay_state) do
      [{^relay_state, %{request_id: request_id, consumed_at: consumed_at}}]
      when not is_nil(consumed_at) ->
        {:error,
         Error.new(
           :request_intent_consumed,
           "Request intent has already been consumed",
           %{relay_state: relay_state, request_id: request_id, operation: :consume_intent}
         )}

      [{^relay_state, %{request_id: stored_request_id}}] ->
        {:error,
         Error.new(
           :request_intent_not_found,
           "Request intent request_id does not match relay state binding",
           %{
             relay_state: relay_state,
             request_id: request_id,
             stored_request_id: stored_request_id,
             operation: :consume_intent
           }
         )}

      [] when retries_remaining > 0 ->
        Process.sleep(1)
        consume_intent_with_retry(relay_state, request_id, retries_remaining - 1, opts)

      [] ->
        {:error,
         Error.new(
           :request_intent_not_found,
           "Request intent was not found",
           %{relay_state: relay_state, request_id: request_id, operation: :consume_intent}
         )}
    end
  end

  defp request_id_from_intent(intent) do
    request_id = Map.get(intent, :request_id) || Map.get(intent, "request_id")

    if is_binary(request_id) and request_id != "" do
      {:ok, request_id}
    else
      {:error,
       Error.new(
         :request_intent_not_found,
         "Request intent requires a request_id",
         %{operation: :put_intent, reason: :missing_request_id}
       )}
    end
  end

  defp expires_at_from_intent(intent) do
    Map.get(intent, :expires_at) || Map.get(intent, "expires_at")
  end

  defp decorate_intent(intent, request_id, expires_at) when is_map(intent) do
    intent
    |> Map.put_new(:request_id, request_id)
    |> Map.put_new(:expires_at, expires_at)
  end

  defp prod_runtime?(opts) do
    case Keyword.fetch(opts, :prod_runtime?) do
      {:ok, value} -> value == true
      :error -> prod_runtime_ets_warning()
    end
  end

  defp prod_runtime_ets_warning do
    Application.get_env(:relyra, :prod_runtime_ets_warning, false) == true
  end
end
