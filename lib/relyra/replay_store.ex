defmodule Relyra.ReplayStore do
  @moduledoc """
  Public extension contract for atomic replay-key consumption.
  """

  alias Relyra.Error

  # Verification anchor: consume_replay_key(replay_key, metadata, opts  [])
  @callback consume_replay_key(replay_key :: binary(), metadata :: map(), opts :: keyword()) ::
              :ok | {:error, Error.t()}
end
