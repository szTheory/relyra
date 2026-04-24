defmodule Relyra.ReplayStore.ETS do
  @moduledoc false

  @behaviour Relyra.ReplayStore

  use GenServer

  require Logger

  alias Relyra.Error

  @table :relyra_replay_keys

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
  @spec consume_replay_key(binary(), map(), keyword()) :: :ok | {:error, Error.t()}
  def consume_replay_key(replay_key, metadata, opts \\ [])

  def consume_replay_key(replay_key, metadata, opts)
      when is_binary(replay_key) and is_map(metadata) and is_list(opts) do
    :ok = ensure_table!(opts)

    now = Keyword.get(opts, :now, DateTime.utc_now())

    case :ets.insert_new(@table, {replay_key, %{inserted_at: now, metadata: metadata}}) do
      true ->
        :ok

      false ->
        {:error,
         Error.new(
           :replayed_assertion,
           "Replay key has already been consumed",
           %{replay_key: replay_key, operation: :consume_replay_key}
         )}
    end
  end

  def consume_replay_key(_replay_key, _metadata, _opts) do
    {:error,
     Error.new(
       :replayed_assertion,
       "Replay key input is invalid",
       %{operation: :consume_replay_key, reason: :invalid_input}
     )}
  end

  @spec warn_prod_ets!(keyword()) :: :ok
  def warn_prod_ets!(opts \\ []) when is_list(opts) do
    if prod_runtime?(opts) do
      Logger.warning(
        "Relyra.ReplayStore.ETS is single-node only and provides non-durable replay protection; use an Ecto adapter for production-safe replay guarantees."
      )
    end

    :ok
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
