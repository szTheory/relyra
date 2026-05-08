defmodule Relyra.TestSupport.ConformanceFixtures do
  @moduledoc false

  @required_keys ~w(id requirement_ids provenance)
  @executed_statuses MapSet.new(["pass", "reject"])

  @spec load_manifest!(Path.t()) :: [map()]
  def load_manifest!(manifest_path) when is_binary(manifest_path) do
    manifest_path = Path.expand(manifest_path)
    manifest_dir = Path.dirname(manifest_path)

    manifest_path
    |> File.read!()
    |> Jason.decode!()
    |> require_list!(manifest_path)
    |> require_keys!(@required_keys)
    |> Enum.map(fn row ->
      row
      |> Map.put(:manifest_path, manifest_path)
      |> Map.put(:manifest_dir, manifest_dir)
    end)
  end

  @spec require_keys!([map()], [String.t()]) :: [map()]
  def require_keys!(rows, required_keys) when is_list(rows) and is_list(required_keys) do
    Enum.map(rows, fn row ->
      require_row_keys!(row, required_keys)
    end)
  end

  @spec executed_rows([map()]) :: [map()]
  def executed_rows(rows) when is_list(rows) do
    Enum.filter(rows, fn row ->
      MapSet.member?(@executed_statuses, Map.get(row, "status"))
    end)
  end

  @spec coverage_rows([map()]) :: [map()]
  def coverage_rows(rows) when is_list(rows), do: rows

  @spec fixture_xml(map()) :: binary()
  def fixture_xml(row) when is_map(row) do
    cond do
      is_binary(Map.get(row, "xml")) ->
        Map.fetch!(row, "xml")

      is_binary(Map.get(row, "xml_path")) ->
        row
        |> Map.fetch!(:manifest_dir)
        |> Path.join(Map.fetch!(row, "xml_path"))
        |> File.read!()

      true ->
        raise ArgumentError,
              "fixture row #{inspect(Map.get(row, "id"))} is missing xml or xml_path content"
    end
  end

  defp require_list!(rows, _manifest_path) when is_list(rows), do: rows

  defp require_list!(other, manifest_path) do
    raise ArgumentError,
          "manifest #{manifest_path} must decode to a list of rows, got: #{inspect(other)}"
  end

  defp require_row_keys!(row, required_keys) when is_map(row) do
    missing_keys =
      required_keys
      |> Enum.reject(&present?(Map.get(row, &1)))
      |> maybe_add_fixture_content_key(row)

    if missing_keys == [] do
      row
    else
      raise ArgumentError,
            "manifest row #{inspect(Map.get(row, "id"))} missing keys: #{Enum.join(missing_keys, ", ")}"
    end
  end

  defp require_row_keys!(row, _required_keys) do
    raise ArgumentError, "manifest row must be a map, got: #{inspect(row)}"
  end

  defp maybe_add_fixture_content_key(missing_keys, row) do
    if present?(Map.get(row, "xml")) or present?(Map.get(row, "status")) do
      missing_keys
    else
      missing_keys ++ ["xml|status"]
    end
  end

  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(value) when is_list(value), do: value != []
  defp present?(value) when is_map(value), do: map_size(value) > 0
  defp present?(value), do: not is_nil(value)
end
