defmodule Relyra.TestSupport.ReplayStoreCase do
  @moduledoc false

  alias Relyra.TestSupport.IsolatedReplayStore

  def setup_isolated_replay_store(_tags) do
    {:ok, agent} =
      ExUnit.Callbacks.start_supervised(%{
        id: {:isolated_replay_store, make_ref()},
        start: {IsolatedReplayStore, :start_link, [[]]},
        restart: :temporary
      })

    [
      replay_store: IsolatedReplayStore,
      replay_agent: agent
    ]
  end
end
