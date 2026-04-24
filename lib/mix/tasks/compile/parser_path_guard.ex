defmodule Mix.Tasks.Compile.ParserPathGuard do
  @moduledoc false
  use Mix.Task.Compiler

  @recursive true
  @shortdoc "Fails compile when parser usage escapes the XML seam"

  @parser_patterns [~r/\bSaxy\b/, ~r/\bSweetXml\b/, ~r/\bxmerl\b/]
  @allowed_roots [
    "lib/relyra/security/xml.ex",
    "lib/relyra/security/xml/",
    "lib/mix/tasks/compile/parser_path_guard.ex"
  ]

  @impl true
  def run(_args) do
    violations =
      "lib/**/*.ex"
      |> Path.wildcard()
      |> Enum.reject(&allowed_file?/1)
      |> Enum.flat_map(&scan_file/1)

    if violations == [] do
      {:ok, []}
    else
      Mix.shell().error(
        "ParserPathGuard blocked parser references outside Relyra.Security.XML seam:"
      )

      Enum.each(violations, fn {path, line, text} ->
        Mix.shell().error("  #{path}:#{line} -> #{text}")
      end)

      {:error, []}
    end
  end

  defp allowed_file?(path) do
    relative_path = Path.relative_to_cwd(path)

    Enum.any?(@allowed_roots, fn root ->
      String.starts_with?(relative_path, root)
    end)
  end

  defp scan_file(path) do
    path
    |> File.read!()
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.reduce([], fn {line, line_no}, acc ->
      if Enum.any?(@parser_patterns, &Regex.match?(&1, line)) do
        [{path, line_no, String.trim(line)} | acc]
      else
        acc
      end
    end)
    |> Enum.reverse()
  end
end
