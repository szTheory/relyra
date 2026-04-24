defmodule Relyra.Security.Stores.ReplayStoreEctoTest do
  use ExUnit.Case, async: false

  alias Relyra.Error
  alias Relyra.ReplayStore.Ecto

  @repo Relyra.Security.Stores.ReplayStoreEctoFakeRepo
  @table "replay_keys"

  setup do
    start_supervised!(@repo)
    @repo.reset!()
    :ok
  end

  test "consume_replay_key rejects duplicate keys with :replayed_assertion" do
    replay_key = "conn:issuer:assertion_duplicate"
    metadata = %{connection_id: "conn", issuer: "issuer", signed_xml_id: "assertion_duplicate"}

    assert :ok = Ecto.consume_replay_key(replay_key, metadata, repo: @repo, table: @table)

    assert {:error, %Error{type: :replayed_assertion}} =
             Ecto.consume_replay_key(replay_key, metadata, repo: @repo, table: @table)
  end

  test "consume_replay_key enforces one-time semantics under concurrency" do
    replay_key = "conn:issuer:assertion_concurrency_ecto"

    metadata = %{
      connection_id: "conn",
      issuer: "issuer",
      signed_xml_id: "assertion_concurrency_ecto"
    }

    results =
      1..12
      |> Task.async_stream(
        fn _ ->
          Ecto.consume_replay_key(replay_key, metadata, repo: @repo, table: @table)
        end,
        max_concurrency: 12,
        ordered: false,
        timeout: 5_000
      )
      |> Enum.map(fn {:ok, result} -> result end)

    assert 1 == Enum.count(results, &(&1 == :ok))

    loser_types =
      for {:error, %Error{type: type}} <- results do
        type
      end

    assert 11 == length(loser_types)
    assert Enum.all?(loser_types, &(&1 == :replayed_assertion))
  end
end

defmodule Relyra.Security.Stores.ReplayStoreEctoFakeRepo do
  use Agent

  @spec start_link(term()) :: Agent.on_start()
  def start_link(_opts) do
    Agent.start_link(fn -> %{replay_keys: %{}} end, name: __MODULE__)
  end

  @spec reset!() :: :ok
  def reset! do
    Agent.update(__MODULE__, fn _ -> %{replay_keys: %{}} end)
  end

  @spec query(binary(), list(), keyword()) :: {:ok, map()} | {:error, term()}
  def query(sql, params, _opts), do: query(sql, params)

  @spec query(binary(), list()) :: {:ok, map()} | {:error, term()}
  def query(sql, params) do
    cond do
      String.contains?(sql, "INSERT INTO") and String.contains?(sql, "replay_key") ->
        insert_replay_key(params)

      true ->
        {:error, :unsupported_query}
    end
  end

  defp insert_replay_key([replay_key, inserted_at, metadata]) do
    Agent.get_and_update(__MODULE__, fn state ->
      if Map.has_key?(state.replay_keys, replay_key) do
        {{:error, :unique_violation}, state}
      else
        updated =
          Map.put(state.replay_keys, replay_key, %{
            replay_key: replay_key,
            inserted_at: inserted_at,
            metadata: metadata
          })

        {{:ok, %{num_rows: 1, rows: []}}, %{state | replay_keys: updated}}
      end
    end)
  end
end
