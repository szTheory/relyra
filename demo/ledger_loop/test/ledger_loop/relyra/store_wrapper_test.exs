defmodule LedgerLoop.Relyra.StoreWrapperTest do
  use LedgerLoop.DataCase

  alias Relyra.RequestStore.Ecto, as: RequestEcto
  alias Relyra.ReplayStore.Ecto, as: ReplayEcto

  @request_table "ledger_loop_relyra_request_intents"
  @replay_table "ledger_loop_relyra_replay_keys"

  describe "Task 1: Relyra Ecto adapters can insert/fetch/consume directly through fixed tables" do
    test "can use Relyra.RequestStore.Ecto against request intents table" do
      relay_state = "rs_123"
      request_id = "req_123"
      intent = %{"request_id" => request_id, "expires_at" => DateTime.utc_now() |> DateTime.add(3600, :second)}
      opts = [repo: LedgerLoop.Repo, table: @request_table]

      assert :ok = RequestEcto.put_intent(relay_state, intent, opts)

      assert {:ok, fetched} = RequestEcto.fetch_intent(relay_state, opts)
      assert fetched["request_id"] == request_id

      assert :ok = RequestEcto.consume_intent(relay_state, request_id, opts)
      
      # Should be consumed now
      assert {:error, error} = RequestEcto.fetch_intent(relay_state, opts)
      assert error.type == :request_intent_consumed
    end

    test "can use Relyra.ReplayStore.Ecto against replay keys table" do
      replay_key = "replay_123"
      metadata = %{"some" => "data"}
      opts = [repo: LedgerLoop.Repo, table: @replay_table]

      assert :ok = ReplayEcto.consume_replay_key(replay_key, metadata, opts)

      # Duplicate key should fail
      assert {:error, error} = ReplayEcto.consume_replay_key(replay_key, metadata, opts)
      assert error.type == :replayed_assertion
    end
  end
end
