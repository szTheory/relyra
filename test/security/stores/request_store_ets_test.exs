defmodule Relyra.Security.Stores.RequestStoreETSTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias Relyra.Error
  alias Relyra.RequestStore.ETS

  @table :relyra_request_intents

  setup do
    :ok = ETS.ensure_table!()
    :ets.delete_all_objects(@table)

    on_exit(fn ->
      if :ets.whereis(@table) != :undefined do
        :ets.delete_all_objects(@table)
      end

      Application.delete_env(:relyra, :prod_runtime_ets_warning)
    end)

    :ok
  end

  test "consume_intent enforces atomic one-time semantics under concurrency" do
    relay_state = "rs_concurrency_req_1"
    request_id = "req_concurrency_1"
    intent = request_intent(relay_state, request_id)

    assert :ok = ETS.put_intent(relay_state, intent)

    results =
      1..12
      |> Task.async_stream(
        fn _ -> ETS.consume_intent(relay_state, request_id) end,
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

  test "consume_intent preserves relay/request binding checks before consume" do
    relay_state = "rs_binding_check"
    request_id = "req_binding_ok"
    intent = request_intent(relay_state, request_id)

    assert :ok = ETS.put_intent(relay_state, intent)

    assert {:error, %Error{type: :request_intent_not_found}} =
             ETS.consume_intent(relay_state, "req_binding_wrong")

    assert :ok = ETS.consume_intent(relay_state, request_id)
  end

  @tag :prod_runtime_warning
  test "warn_prod_ets!/1 emits loud warning when opts prod_runtime? is true" do
    relay_state = "rs_warning_opts"
    request_id = "req_warning_opts"
    intent = request_intent(relay_state, request_id)

    log =
      capture_log(fn ->
        assert :ok = ETS.put_intent(relay_state, intent, prod_runtime?: true)
      end)

    assert log =~ "single-node only"
    assert log =~ "non-durable replay protection"
  end

  @tag :prod_runtime_warning
  test "warn_prod_ets!/1 emits loud warning when app env enables runtime warning" do
    Application.put_env(:relyra, :prod_runtime_ets_warning, true)

    log =
      capture_log(fn ->
        assert {:error, %Error{type: :request_intent_not_found}} = ETS.fetch_intent("rs_missing")
      end)

    assert log =~ "single-node only"
    assert log =~ "non-durable replay protection"
  end

  defp request_intent(relay_state, request_id) do
    %{
      request_id: request_id,
      connection_id: "conn_test",
      relay_state: relay_state,
      in_response_to: request_id,
      expires_at: DateTime.add(DateTime.utc_now(), 600, :second)
    }
  end
end
