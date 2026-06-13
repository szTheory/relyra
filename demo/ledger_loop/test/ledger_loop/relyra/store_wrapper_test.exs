defmodule LedgerLoop.Relyra.StoreWrapperTest do
  use LedgerLoop.DataCase

  alias Relyra.RequestStore.Ecto, as: RequestEcto
  alias Relyra.ReplayStore.Ecto, as: ReplayEcto
  alias LedgerLoop.Relyra.RequestStore
  alias LedgerLoop.Relyra.ReplayStore

  @request_table "ledger_loop_relyra_request_intents"
  @replay_table "ledger_loop_relyra_replay_keys"

  describe "Task 1: Relyra Ecto adapters can insert/fetch/consume directly through fixed tables" do
    test "can use Relyra.RequestStore.Ecto against request intents table" do
      relay_state = "rs_123"
      request_id = "req_123"

      intent = %{
        "request_id" => request_id,
        "expires_at" => DateTime.utc_now() |> DateTime.add(3600, :second)
      }

      opts = [repo: LedgerLoop.Repo, table: @request_table]

      assert :ok = RequestEcto.put_intent(relay_state, intent, opts)

      assert {:ok, fetched} = RequestEcto.fetch_intent(relay_state, opts)
      # Relyra.RequestStore.Ecto.fetch_intent/2 atomizes the stored intent keys and
      # returns :request_id / :expires_at as atoms, so fetch with the atom key.
      assert fetched[:request_id] == request_id

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

  describe "Task 2: Implement fixed request/replay wrappers and runtime config" do
    test "wrapper uses ledger_loop_relyra_request_intents even when caller opts try to override" do
      relay_state = "rs_fixed_123"
      request_id = "req_fixed_123"

      intent = %{
        "request_id" => request_id,
        "expires_at" => DateTime.utc_now() |> DateTime.add(3600, :second)
      }

      # Pass an attacker table and incorrect repo
      opts = [repo: SomeAttackerRepo, table: "attacker_table"]

      assert :ok = RequestStore.put_intent(relay_state, intent, opts)

      assert {:ok, fetched} = RequestStore.fetch_intent(relay_state, opts)
      # Relyra.RequestStore.Ecto.fetch_intent/2 atomizes the stored intent keys and
      # returns :request_id / :expires_at as atoms, so fetch with the atom key.
      assert fetched[:request_id] == request_id

      assert :ok = RequestStore.consume_intent(relay_state, request_id, opts)
    end

    test "wrapper calls insert replay keys even when caller opts contain alternate table names" do
      replay_key = "replay_fixed_123"
      metadata = %{"some" => "data"}
      opts = [repo: SomeAttackerRepo, table: "attacker_table"]

      assert :ok = ReplayStore.consume_replay_key(replay_key, metadata, opts)

      # Duplicate key should fail with Relyra replay error
      assert {:error, error} = ReplayStore.consume_replay_key(replay_key, metadata, opts)
      assert error.type == :replayed_assertion
    end

    test "config :relyra uses expected modules" do
      config = Application.get_env(:relyra, :connection_resolver)
      assert config == Relyra.ConnectionResolver.Ecto

      config = Application.get_env(:relyra, :request_store)
      assert config == LedgerLoop.Relyra.RequestStore

      config = Application.get_env(:relyra, :replay_store)
      assert config == LedgerLoop.Relyra.ReplayStore

      config = Application.get_env(:relyra, :repo)
      assert config == LedgerLoop.Repo
    end
  end
end
