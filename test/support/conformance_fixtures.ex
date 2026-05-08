defmodule Relyra.TestSupport.ConformanceFixtures do
  @moduledoc false

  defdelegate load_manifest!(manifest_path), to: Relyra.ConformanceFixtures
  defdelegate require_keys!(rows, required_keys), to: Relyra.ConformanceFixtures
  defdelegate executed_rows(rows), to: Relyra.ConformanceFixtures
  defdelegate coverage_rows(rows), to: Relyra.ConformanceFixtures
  defdelegate fixture_xml(row), to: Relyra.ConformanceFixtures
end
