defmodule Relyra.Docs.MarkdownLinkSmokeTest do
  @moduledoc """
  Smoke gate for adopter-facing markdown: internal link targets exist and
  planning paths do not leak into `guides/` or published ExDoc extras.
  """

  use ExUnit.Case, async: true

  @published_extras [
    "README.md",
    "guides/overview.md",
    "guides/getting_started.md",
    "guides/identity_mapping_and_provisioning.md",
    "guides/production_ecto_path.md",
    "guides/jtbd_user_flows.md",
    "guides/case_studies/phoenix_saas_tenant_onboarding.md",
    "guides/case_studies/operator_managed_rollout.md",
    "guides/recipes/okta.md",
    "guides/recipes/entra.md",
    "guides/recipes/google_workspace.md",
    "guides/recipes/adfs.md",
    "guides/recipes/generic_saml.md",
    "guides/recipes/logout.md",
    "guides/troubleshooting.md",
    "guides/operations/incident_playbook.md",
    "SECURITY.md",
    "SECURITY_REVIEW.md",
    "docs/security_boundary.md",
    "docs/security_findings.md",
    "CHANGELOG.md",
    "CONFORMANCE.md",
    "BATTERIES_INCLUDED.md",
    "SECURITY_REVIEW_EVIDENCE.md"
  ]

  @link_re ~r/\[[^\]]*\]\(([^)]+)\)/

  test "guides and published docs do not reference .planning paths" do
    offenders =
      published_paths()
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

  test "relative markdown links in published docs resolve to files" do
    repo_root = File.cwd!()

    failures =
      published_paths()
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

  defp published_paths do
    (@published_extras ++ Path.wildcard("guides/**/*.md") ++ Path.wildcard("docs/*.md"))
    |> Enum.uniq()
    |> Enum.filter(&File.regular?/1)
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
