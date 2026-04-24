defmodule Relyra.Security.Extensions.SeamContractTest do
  use ExUnit.Case, async: true

  alias Relyra.ConnectionResolver
  alias Relyra.ReplayStore
  alias Relyra.RequestStore
  alias Relyra.SessionAdapter
  alias Relyra.UserMapper

  @tag :extension_seam
  test "phase 3 extension behaviours expose frozen callback names and arities" do
    assert {:resolve_connection, 2} in ConnectionResolver.behaviour_info(:callbacks)
    assert {:establish_session, 3} in SessionAdapter.behaviour_info(:callbacks)
    assert {:map_attributes, 3} in UserMapper.behaviour_info(:callbacks)

    request_callbacks = RequestStore.behaviour_info(:callbacks)
    assert {:put_intent, 3} in request_callbacks
    assert {:fetch_intent, 2} in request_callbacks
    assert {:consume_intent, 3} in request_callbacks

    assert {:consume_replay_key, 3} in ReplayStore.behaviour_info(:callbacks)
  end
end
