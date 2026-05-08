defmodule Relyra.Conformance.SPConformanceTest do
  use ExUnit.Case, async: true

  alias Relyra.ConformanceFixtures

  @moduletag :conformance

  @manifest_path "priv/conformance/sp_manifest.json"
  @fixed_now ~U[2026-04-24 16:00:00Z]

  test "executed manifest rows produce their declared expected_outcome" do
    manifest()
    |> ConformanceFixtures.executed_rows()
    |> Enum.each(fn row ->
      assert evaluate_row(row) == row["expected_outcome"]
    end)
  end

  test "unsupported and deferred rows stay explicit in coverage reporting" do
    non_executed =
      manifest()
      |> ConformanceFixtures.coverage_rows()
      |> Enum.reject(&(row_status(&1) in ["pass", "reject"]))

    assert non_executed != []

    Enum.each(non_executed, fn row ->
      assert row_status(row) in ["unsupported", "deferred"]
      assert is_binary(row["notes"])
      assert String.trim(row["notes"]) != ""
    end)
  end

  defp manifest do
    ConformanceFixtures.load_manifest!(@manifest_path)
  end

  defp evaluate_row(_row) do
    %{"result" => "not_implemented"}
  end

  defp row_status(row), do: Map.get(row, "status")
end
