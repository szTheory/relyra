defmodule Relyra.Security.Stores.ReplayStoreETSTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias Relyra.Error
  alias Relyra.ReplayStore.ETS

  @table :relyra_replay_keys

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

  test "consume_replay_key enforces one-time replay rejection under concurrency" do
    replay_key = "conn:issuer:assertion_concurrency"
    metadata = %{connection_id: "conn", issuer: "issuer", signed_xml_id: "assertion_concurrency"}

    results =
      1..12
      |> Task.async_stream(
        fn _ -> ETS.consume_replay_key(replay_key, metadata) end,
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

  @tag :prod_runtime_warning
  test "warn_prod_ets!/1 emits loud warning when opts prod_runtime? is true" do
    replay_key = "conn:issuer:assertion_warning_opts"
    metadata = %{connection_id: "conn", issuer: "issuer", signed_xml_id: "assertion_warning_opts"}

    log =
      capture_log(fn ->
        assert :ok = ETS.consume_replay_key(replay_key, metadata, prod_runtime?: true)
      end)

    assert log =~ "single-node only"
    assert log =~ "non-durable replay protection"
  end

  @tag :prod_runtime_warning
  test "warn_prod_ets!/1 emits loud warning when app env enables runtime warning" do
    replay_key = "conn:issuer:assertion_warning_env"
    metadata = %{connection_id: "conn", issuer: "issuer", signed_xml_id: "assertion_warning_env"}

    Application.put_env(:relyra, :prod_runtime_ets_warning, true)

    log =
      capture_log(fn ->
        assert :ok = ETS.consume_replay_key(replay_key, metadata)
      end)

    assert log =~ "single-node only"
    assert log =~ "non-durable replay protection"
  end
end
