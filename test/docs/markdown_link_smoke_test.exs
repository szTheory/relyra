defmodule Relyra.Docs.MarkdownLinkSmokeTest do
  @moduledoc """
  Smoke gate for adopter-facing markdown: internal link targets exist and
  planning paths do not leak into `guides/` or published `docs/` extras.
  """

  use ExUnit.Case, async: true

  @guide_globs ["guides/**/*.md", "docs/*.md", "README.md"]
  @link_re ~r/\[[^\]]*\]\(([^)]+)\)/

  test "guides and published docs do not reference .planning paths" do
    offenders =
      @guide_globs
      |> Enum.flat_map(&Path.wildcard/1)
      |> Enum.filter(&File.regular?/1)
      |> Enum.flat_map(fn path ->
        path
        |> File.read!()
        |> String.split("\n")
        |> Enum.with_index(1)
        |> Enum.filter(fn {line, _line_no} -> String.contains?(line, ".planning") end)
        |> Enum.map(fn {line, line_no} -> {path, line_no, String.trim(line)} end)
      end)

    assert offenders == [],
           "planning paths must not appear in adopter docs:\n#{format_offenders(offenders)}"
  end

  test "jtbd_gap_map is not published as a Hex extra" do
    mix_contents = File.read!("mix.exs")

    refute String.contains?(mix_contents, "docs/jtbd_gap_map.md"),
           "docs/jtbd_gap_map.md is maintainers-only and must stay out of ExDoc extras"
  end

  test "relative markdown links in guides and docs resolve to files" do
    repo_root = File.cwd!()

    failures =
      @guide_globs
      |> Enum.flat_map(&Path.wildcard/1)
      |> Enum.filter(&File.regular?/1)
      |> Enum.flat_map(fn source_path ->
        source_path
        |> File.read!()
        |> extract_links()
        |> Enum.reject(&external_or_anchor_only?/1)
        |> Enum.map(fn target -> {source_path, target} end)
        |> Enum.reject(fn {source_path, target} ->
          resolved = resolve_link(repo_root, source_path, target)
          File.exists?(resolved)
        end)
      end)

    assert failures == [],
           "broken relative links:\n#{format_link_failures(failures, repo_root)}"
  end

  defp extract_links(content) do
    @link_re
    |> Regex.scan(content, capture: :all_but_first)
    |> List.flatten()
  end

  defp external_or_anchor_only?(target) do
    String.starts_with?(target, ["http://", "https://", "mailto:"]) or
      String.starts_with?(target, "#")
  end

  defp resolve_link(repo_root, source_path, target) do
    target = target |> String.split("#") |> List.first()

    source_path
    |> Path.dirname()
    |> Path.join(target)
    |> Path.expand(repo_root)
  end

  defp format_offenders(offenders) do
    Enum.map_join(offenders, "\n", fn {path, line_no, line} ->
      "  #{path}:#{line_no}: #{line}"
    end)
  end

  defp format_link_failures(failures, repo_root) do
    Enum.map_join(failures, "\n", fn {source_path, target} ->
      resolved = resolve_link(repo_root, source_path, target)
      "  #{source_path} -> #{target} (resolved #{resolved}, missing)"
    end)
  end
end
