defmodule Relyra.TestSupport.IsolatedReplayStore do
  @moduledoc false

  @behaviour Relyra.ReplayStore

  alias Relyra.Error

  @prod_build Mix.env() == :prod

  @spec start_link(keyword()) :: Agent.on_start()
  def start_link(_opts \\ []) do
    ensure_not_prod!()
    Agent.start_link(fn -> MapSet.new() end)
  end

  @impl true
  @spec consume_replay_key(binary(), map(), keyword()) :: :ok | {:error, Error.t()}
  def consume_replay_key(replay_key, metadata, opts)
      when is_binary(replay_key) and is_map(metadata) and is_list(opts) do
    ensure_not_prod!()

    agent = Keyword.fetch!(opts, :replay_agent)

    case Agent.get_and_update(agent, fn keys ->
           if MapSet.member?(keys, replay_key) do
             {{:error, :duplicate}, keys}
           else
             {:ok, MapSet.put(keys, replay_key)}
           end
         end) do
      :ok ->
        :ok

      {:error, :duplicate} ->
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

  defp ensure_not_prod! do
    if @prod_build do
      raise "Relyra.TestSupport.IsolatedReplayStore is test-only"
    end
  end
end
