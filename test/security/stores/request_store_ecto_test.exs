defmodule Relyra.Security.Stores.RequestStoreEctoTest do
  use ExUnit.Case, async: false

  alias Relyra.Error
  alias Relyra.RequestStore.Ecto

  @repo Relyra.Security.Stores.RequestStoreEctoFakeRepo
  @table "request_intents"

  setup do
    start_supervised!(@repo)
    @repo.reset!()
    :ok
  end

  test "consume_intent maps consumed-row update conflicts under concurrency" do
    relay_state = "rs_ecto_concurrency"
    request_id = "req_ecto_concurrency"
    intent = request_intent(relay_state, request_id)

    assert :ok = Ecto.put_intent(relay_state, intent, repo: @repo, table: @table)

    results =
      1..12
      |> Task.async_stream(
        fn _ ->
          Ecto.consume_intent(relay_state, request_id, repo: @repo, table: @table)
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
    assert Enum.all?(loser_types, &(&1 == :request_intent_consumed))
  end

  test "consume_intent returns :request_intent_not_found for missing relay/request pair" do
    assert {:error, %Error{type: :request_intent_not_found}} =
             Ecto.consume_intent("rs_missing", "req_missing", repo: @repo, table: @table)
  end

  defp request_intent(relay_state, request_id) do
    %{
      request_id: request_id,
      connection_id: "conn_ecto",
      relay_state: relay_state,
      in_response_to: request_id,
      expires_at: DateTime.add(DateTime.utc_now(), 600, :second)
    }
  end
end

defmodule Relyra.Security.Stores.RequestStoreEctoFakeRepo do
  use Agent

  @spec start_link(term()) :: Agent.on_start()
  def start_link(_opts) do
    Agent.start_link(fn -> %{request_intents: %{}} end, name: __MODULE__)
  end

  @spec reset!() :: :ok
  def reset! do
    Agent.update(__MODULE__, fn _ -> %{request_intents: %{}} end)
  end

  @spec query(binary(), list(), keyword()) :: {:ok, map()} | {:error, term()}
  def query(sql, params, _opts), do: query(sql, params)

  @spec query(binary(), list()) :: {:ok, map()} | {:error, term()}
  def query(sql, params) do
    cond do
      String.contains?(sql, "INSERT INTO") and String.contains?(sql, "request_id") ->
        insert_request_intent(params)

      String.contains?(sql, "UPDATE") and String.contains?(sql, "SET consumed_at") ->
        consume_request_intent(params)

      String.contains?(sql, "SELECT consumed_at") ->
        select_consumed_at(params)

      String.contains?(sql, "SELECT request_id, intent, consumed_at, expires_at") ->
        fetch_request_intent(params)

      true ->
        {:error, :unsupported_query}
    end
  end

  defp insert_request_intent([relay_state, request_id, intent, expires_at]) do
    Agent.get_and_update(__MODULE__, fn state ->
      key = {relay_state, request_id}

      if Map.has_key?(state.request_intents, key) do
        {{:error, :unique_violation}, state}
      else
        updated =
          Map.put(state.request_intents, key, %{
            relay_state: relay_state,
            request_id: request_id,
            intent: intent,
            consumed_at: nil,
            expires_at: expires_at
          })

        {{:ok, %{num_rows: 1, rows: []}}, %{state | request_intents: updated}}
      end
    end)
  end

  defp consume_request_intent([consumed_at, relay_state, request_id]) do
    Agent.get_and_update(__MODULE__, fn state ->
      key = {relay_state, request_id}

      case Map.get(state.request_intents, key) do
        %{consumed_at: nil} = row ->
          updated = Map.put(state.request_intents, key, %{row | consumed_at: consumed_at})
          {{:ok, %{num_rows: 1, rows: []}}, %{state | request_intents: updated}}

        _ ->
          {{:ok, %{num_rows: 0, rows: []}}, state}
      end
    end)
  end

  defp select_consumed_at([relay_state, request_id]) do
    Agent.get(__MODULE__, fn state ->
      key = {relay_state, request_id}

      case Map.get(state.request_intents, key) do
        nil -> {:ok, %{rows: []}}
        row -> {:ok, %{rows: [[row.consumed_at]]}}
      end
    end)
  end

  defp fetch_request_intent([relay_state]) do
    Agent.get(__MODULE__, fn state ->
      row =
        state.request_intents
        |> Enum.find_value(fn
          {{stored_relay_state, _request_id}, value} when stored_relay_state == relay_state ->
            value

          _ ->
            nil
        end)

      case row do
        nil ->
          {:ok, %{rows: []}}

        %{
          request_id: request_id,
          intent: intent,
          consumed_at: consumed_at,
          expires_at: expires_at
        } ->
          {:ok, %{rows: [[request_id, intent, consumed_at, expires_at]]}}
      end
    end)
  end
end
