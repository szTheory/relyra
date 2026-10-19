defmodule Relyra.ReleaseCiGateTest do
  # scripts/check_release_ci_gate.sh against a stub `gh` and a real git repo:
  # every outcome except a green ci-gate on the exact release tree fails closed.
  use ExUnit.Case, async: true

  @moduletag :tmp_dir
  @script Path.expand("scripts/check_release_ci_gate.sh")

  setup %{tmp_dir: tmp_dir} do
    repo = Path.join(tmp_dir, "repo")
    fixtures = Path.join(tmp_dir, "fixtures")
    bin = Path.join(tmp_dir, "bin")
    Enum.each([repo, fixtures, bin], &File.mkdir_p!/1)

    git!(repo, ["init", "-q"])
    File.write!(Path.join(repo, "lib.ex"), "base\n")
    git!(repo, ["add", "lib.ex"])
    git!(repo, ["commit", "-q", "-m", "base"])
    base = git!(repo, ["rev-parse", "HEAD"])

    File.write!(Path.join(repo, "lib.ex"), "release\n")
    git!(repo, ["commit", "-q", "-am", "release pr head"])
    head = git!(repo, ["rev-parse", "HEAD"])

    merge = commit_tree!(repo, "#{head}^{tree}", [base, head], "merge release pr")
    drifted = commit_tree!(repo, "#{base}^{tree}", [base, head], "merge with drifted tree")

    stub = Path.join(bin, "gh")

    File.write!(stub, """
    #!/usr/bin/env bash
    set -euo pipefail
    [ "$1" = api ] || exit 9
    path="$2"
    [ "$3" = --jq ] || exit 9
    key="$(printf '%s' "$path" | sed 's#^repos/o/r/##; s#[?].*##; s#/#_#g')"
    file="$GATE_FIXTURES/$key.json"
    [ -f "$file" ] || { echo "no fixture $key" >&2; exit 8; }
    jq -r "$4" "$file"
    """)

    File.chmod!(stub, 0o755)

    %{repo: repo, fixtures: fixtures, bin: bin, head: head, merge: merge, drifted: drifted}
  end

  test "a green ci-gate on the release commit itself passes", ctx do
    checks!(ctx, ctx.merge, [run(1, "success")])

    assert {output, 0} = gate(ctx, ctx.merge)
    assert output =~ "ci-gate succeeded on release commit"
  end

  test "a green merged PR head with the identical tree passes", ctx do
    checks!(ctx, ctx.merge, [])
    pulls!(ctx, ctx.merge, [merged_pr(ctx.merge, ctx.head)])
    checks!(ctx, ctx.head, [run(1, "failure"), run(2, "success")])

    assert {output, 0} = gate(ctx, ctx.merge)
    assert output =~ "merged PR head #{ctx.head} with the identical tree"
  end

  test "every other state fails closed", ctx do
    cases = [
      {"failed release commit run is final even with a green PR head",
       fn ->
         checks!(ctx, ctx.merge, [run(1, "failure")])
         pulls!(ctx, ctx.merge, [merged_pr(ctx.merge, ctx.head)])
         checks!(ctx, ctx.head, [run(1, "success")])
         ctx.merge
       end, ~r/on release commit .* is 'failure'/},
      {"newest run wins over an older success",
       fn ->
         checks!(ctx, ctx.merge, [run(7, "success"), run(9, "cancelled")])
         ctx.merge
       end, ~r/is 'cancelled'/},
      {"skipped is not success",
       fn ->
         checks!(ctx, ctx.merge, [run(1, "skipped")])
         ctx.merge
       end, ~r/is 'skipped'/},
      {"pending past the wait budget fails",
       fn ->
         checks!(ctx, ctx.merge, [%{run(1, nil) | "status" => "in_progress"}])
         ctx.merge
       end, ~r/is 'pending'/},
      {"a ci-gate from another app is ignored",
       fn ->
         checks!(ctx, ctx.merge, [put_in(run(1, "success"), ["app", "slug"], "spoof")])
         pulls!(ctx, ctx.merge, [])
         ctx.merge
       end, ~r/not the merge commit of exactly one merged PR/},
      {"a differently named check is ignored",
       fn ->
         checks!(ctx, ctx.merge, [%{run(1, "success") | "name" => "security (28, 1.19.5)"}])
         pulls!(ctx, ctx.merge, [])
         ctx.merge
       end, ~r/not the merge commit/},
      {"no merged PR",
       fn ->
         checks!(ctx, ctx.merge, [])
         pulls!(ctx, ctx.merge, [Map.put(merged_pr(ctx.merge, ctx.head), "merged_at", nil)])
         ctx.merge
       end, ~r/not the merge commit/},
      {"a PR merged as a different commit",
       fn ->
         checks!(ctx, ctx.merge, [])
         pulls!(ctx, ctx.merge, [merged_pr(ctx.drifted, ctx.head)])
         ctx.merge
       end, ~r/not the merge commit/},
      {"two merged PRs are ambiguous",
       fn ->
         checks!(ctx, ctx.merge, [])
         pulls!(ctx, ctx.merge, [merged_pr(ctx.merge, ctx.head), merged_pr(ctx.merge, ctx.head)])
         ctx.merge
       end, ~r/not the merge commit/},
      {"merged PR head tree differs from the release tree",
       fn ->
         checks!(ctx, ctx.drifted, [])
         pulls!(ctx, ctx.drifted, [merged_pr(ctx.drifted, ctx.head)])
         checks!(ctx, ctx.head, [run(1, "success")])
         ctx.drifted
       end, ~r/tree .* differs from release tree/},
      {"red merged PR head",
       fn ->
         checks!(ctx, ctx.merge, [])
         pulls!(ctx, ctx.merge, [merged_pr(ctx.merge, ctx.head)])
         checks!(ctx, ctx.head, [run(1, "success"), run(2, "failure")])
         ctx.merge
       end, ~r/on merged PR head .* is 'failure'/},
      {"merged PR head with no ci-gate",
       fn ->
         checks!(ctx, ctx.merge, [])
         pulls!(ctx, ctx.merge, [merged_pr(ctx.merge, ctx.head)])
         checks!(ctx, ctx.head, [])
         ctx.merge
       end, ~r/on merged PR head .* is 'missing'/}
    ]

    for {name, arrange, message} <- cases do
      File.rm_rf!(ctx.fixtures)
      File.mkdir_p!(ctx.fixtures)
      sha = arrange.()
      {output, status} = gate(ctx, sha)

      assert status == 1 and output =~ message,
             "#{name}: expected exit 1 matching #{inspect(message)}, got #{status}: #{output}"
    end
  end

  test "malformed arguments are rejected before any API call", ctx do
    for sha <- ["", "HEAD", "v1.10.0", String.slice(ctx.merge, 0, 12), String.upcase(ctx.merge)] do
      assert {output, 2} = gate(ctx, sha)
      assert output =~ "full 40-hex commit sha"
    end

    assert {output, 2} = gate(ctx, ctx.merge, [{"GH_REPO", "not a repo"}])
    assert output =~ "GH_REPO must be owner/repo"
  end

  defp gate(ctx, sha, env \\ []) do
    System.cmd("bash", [@script, sha],
      cd: ctx.repo,
      stderr_to_stdout: true,
      env:
        [
          {"PATH", ctx.bin <> ":" <> System.get_env("PATH")},
          {"GH_REPO", "o/r"},
          {"GATE_FIXTURES", ctx.fixtures},
          {"RELEASE_GATE_WAIT_SECONDS", "0"},
          {"RELEASE_GATE_POLL_SECONDS", "0"}
        ] ++ env
    )
  end

  defp run(id, conclusion) do
    %{
      "id" => id,
      "name" => "ci-gate",
      "status" => "completed",
      "conclusion" => conclusion,
      "app" => %{"slug" => "github-actions"}
    }
  end

  defp merged_pr(merge_commit, head),
    do: %{
      "merged_at" => "2026-10-18T00:00:00Z",
      "merge_commit_sha" => merge_commit,
      "head" => %{"sha" => head}
    }

  defp checks!(ctx, sha, runs),
    do: fixture!(ctx, "commits_#{sha}_check-runs", %{"check_runs" => runs})

  defp pulls!(ctx, sha, pulls), do: fixture!(ctx, "commits_#{sha}_pulls", pulls)

  defp fixture!(ctx, key, body),
    do: File.write!(Path.join(ctx.fixtures, key <> ".json"), Jason.encode!(body))

  defp commit_tree!(repo, tree, parents, message) do
    args = ["commit-tree", tree] ++ Enum.flat_map(parents, &["-p", &1]) ++ ["-m", message]
    git!(repo, args)
  end

  defp git!(repo, args) do
    env = [
      {"GIT_AUTHOR_NAME", "gate"},
      {"GIT_AUTHOR_EMAIL", "gate@example.invalid"},
      {"GIT_COMMITTER_NAME", "gate"},
      {"GIT_COMMITTER_EMAIL", "gate@example.invalid"},
      {"GIT_CONFIG_GLOBAL", "/dev/null"}
    ]

    {output, 0} = System.cmd("git", args, cd: repo, env: env, stderr_to_stdout: true)
    String.trim(output)
  end
end
