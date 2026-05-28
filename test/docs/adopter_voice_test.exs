defmodule Relyra.Docs.AdopterVoiceTest do
  @moduledoc """
  Guards adopter-facing guides against maintainer and planning vocabulary.
  """

  use ExUnit.Case, async: true

  @guide_globs ["guides/**/*.md", "README.md"]
  @allowlist_files MapSet.new(["CHANGELOG.md"])

  @forbidden_patterns [
    {~r/\.planning/, ".planning path"},
    {~r/\bPhase\s+\d+/, "phase number"},
    {~r/\bADOPT-\d+/, "ADOPT requirement id"},
    {~r/Relyra repository/, "Relyra repository maintainer phrase"},
    {~r/\/gsd-/, "GSD command reference"},
    {~r/release-please/, "release-please maintainer note"}
  ]

  test "guides and README avoid maintainer-only vocabulary outside details blocks" do
    offenders =
      @guide_globs
      |> Enum.flat_map(&Path.wildcard/1)
      |> Enum.filter(&File.regular?/1)
      |> Enum.reject(&MapSet.member?(@allowlist_files, &1))
      |> Enum.flat_map(&scan_file/1)

    assert offenders == [],
           "maintainer vocabulary in adopter docs:\n#{format_offenders(offenders)}"
  end

  defp scan_file(path) do
    path
    |> File.read!()
    |> strip_details_blocks()
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {line, line_no} ->
      @forbidden_patterns
      |> Enum.filter(fn {pattern, _} -> Regex.match?(pattern, line) end)
      |> Enum.map(fn {_, label} -> {path, line_no, label, String.trim(line)} end)
    end)
  end

  defp strip_details_blocks(content) do
    content
    |> String.replace(~r/<details>.*?<\/details>/s, "")
  end

  defp format_offenders(offenders) do
    Enum.map_join(offenders, "\n", fn {path, line_no, label, line} ->
      "  #{path}:#{line_no} (#{label}): #{line}"
    end)
  end
end
