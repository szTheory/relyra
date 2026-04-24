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
    replay_store(opts).consume_replay_key(replay_key, metadata, opts)
  end

  defp replay_store(opts) do
    Keyword.get(opts, :replay_store, Relyra.ReplayStore.Default)
  end
end
