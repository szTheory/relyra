defmodule Relyra.ReplayStore.Default do
  @moduledoc false

  @behaviour Relyra.ReplayStore

  alias Relyra.Error

  @impl true
  @spec consume_replay_key(binary(), map(), keyword()) :: :ok | {:error, Error.t()}
  def consume_replay_key(replay_key, metadata, _opts \\ [])
      when is_binary(replay_key) and is_map(metadata) do
    {:error,
     Error.new(
       :unsupported_default_adapter,
       "Default replay store cannot consume replay keys",
       %{
         adapter: __MODULE__,
         operation: :consume_replay_key,
         hint: "Configure :replay_store with an adapter that provides atomic replay-key consume semantics."
       }
     )}
  end

  def consume_replay_key(_replay_key, _metadata, _opts) do
    {:error,
     Error.new(
       :adapter_not_configured,
       "Replay store adapter is not configured",
       %{
         adapter: __MODULE__,
         operation: :consume_replay_key,
         hint: "Set :replay_store in Relyra options to a module implementing Relyra.ReplayStore."
       }
     )}
  end
end
