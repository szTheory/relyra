defmodule Relyra.ReleaseHardeningTest do
  use ExUnit.Case, async: true

  test "release discipline artifacts exist" do
    assert File.exists?("CHANGELOG.md")
    assert File.exists?(".release-please-config.json")
    assert File.exists?(".release-please-manifest.json")
    assert File.exists?(".github/workflows/release-please.yml")
    assert File.exists?(".github/workflows/publish-hex.yml")
  end

  test "release prerequisites are documented" do
    security = File.read!("SECURITY.md")

    assert security =~ "Release prerequisites"
    assert security =~ "domain / namespace"
    assert security =~ "Keycloak"
    assert security =~ "pin"
  end

  test "release CI/CD workflows are wired" do
    mixfile = File.read!("mix.exs")
    release_please = File.read!(".github/workflows/release-please.yml")
    publish_hex = File.read!(".github/workflows/publish-hex.yml")
    parity = File.read!(".github/workflows/release-parity.yml")
    config = File.read!(".release-please-config.json")

    assert mixfile =~ "ci.release"
    assert mixfile =~ "@version"

    assert release_please =~
             "googleapis/release-please-action@45996ed1f6d02564a971a2fa1b5860e934307cf7 # v5.0.0"

    assert release_please =~ "mix ci.release"
    assert release_please =~ "mix hex.publish --yes"
    assert release_please =~ "release_created"
    assert publish_hex =~ "workflow_dispatch"
    assert publish_hex =~ "mix ci.release"
    assert publish_hex =~ "mix hex.publish --yes"
    assert parity =~ "mix ci.release"
    assert config =~ "\"release-type\": \"elixir\""
    assert config =~ "\"include-v-in-tag\": true"
  end

  # SEED-004 item 7: publish gates on a green ci-gate for the exact release
  # tree (scripts/check_release_ci_gate.sh) instead of re-running qa and
  # ci.security, and the gate runs before anything touches Hex.
  @release_gate_step "Require green ci-gate for the release tree"
  @release_gate_run ~S|scripts/check_release_ci_gate.sh "$(git rev-parse 'HEAD^{commit}')"|

  test "both publish jobs gate on ci-gate before any Hex step" do
    for {path, job_id} <- [
          {".github/workflows/release-please.yml", "publish-hex"},
          {".github/workflows/publish-hex.yml", "publish"}
        ] do
      job = release_job!(path, job_id)
      assert :ok = validate_release_gate!(job), path
      runs = Enum.map(job["steps"], &to_string(&1["run"]))

      refute Enum.any?(runs, &(&1 =~ ~r/\bmix (qa|ci\.security)\b/)),
             "#{path} must not re-run qa or ci.security; the gate proves them"

      assert "mix ci.release" in runs
    end
  end

  test "release gate mutations fail closed" do
    job = release_job!(".github/workflows/release-please.yml", "publish-hex")
    gate? = &(&1["name"] == @release_gate_step)

    update_gate = fn update ->
      Map.update!(job, "steps", fn steps ->
        Enum.map(steps, &if(gate?.(&1), do: update.(&1), else: &1))
      end)
    end

    move_gate_last = fn ->
      {[gate], rest} = Enum.split_with(job["steps"], gate?)
      Map.put(job, "steps", rest ++ [gate])
    end

    mutations = [
      {:missing, Map.update!(job, "steps", &Enum.reject(&1, gate?)), ~r/exactly one/},
      {:conditional, update_gate.(&Map.put(&1, "if", "false")), ~r/unconditional/},
      {:fallible, update_gate.(&Map.put(&1, "continue-on-error", true)), ~r/unconditional/},
      {:other_ref, update_gate.(&Map.put(&1, "run", "scripts/check_release_ci_gate.sh HEAD~1")),
       ~r/must run/},
      {:after_publish, move_gate_last.(), ~r/before/},
      {:no_checks_permission, update_in(job, ["permissions"], &Map.delete(&1, "checks")),
       ~r/permissions/},
      {:write_permission, put_in(job, ["permissions", "contents"], "write"), ~r/permissions/}
    ]

    for {name, mutated, message} <- mutations do
      result =
        try do
          validate_release_gate!(mutated)
        rescue
          error in ArgumentError -> Exception.message(error)
        end

      assert is_binary(result) and result =~ message,
             "#{name} mutation was not rejected: #{inspect(result)}"
    end
  end

  test "only security-gates defines a ci-gate job" do
    owners =
      for path <- Path.wildcard(".github/workflows/*.y*ml"),
          {job_id, job} <- load_yaml!(path)["jobs"],
          "ci-gate" in [job_id, job["name"]],
          do: {path, job_id}

    assert owners == [{".github/workflows/security-gates.yml", "ci-gate"}]
  end

  defp validate_release_gate!(job) do
    unless job["permissions"] == %{
             "contents" => "read",
             "checks" => "read",
             "pull-requests" => "read"
           } do
      raise ArgumentError,
            "release gate job permissions must be contents/checks/pull-requests read"
    end

    steps = job["steps"]

    gate =
      case Enum.filter(steps, &(&1["name"] == @release_gate_step)) do
        [gate] -> gate
        _ -> raise ArgumentError, "expected exactly one #{@release_gate_step} step"
      end

    if Map.has_key?(gate, "if") or Map.get(gate, "continue-on-error", false) do
      raise ArgumentError, "#{@release_gate_step} must be unconditional and blocking"
    end

    unless gate["run"] == @release_gate_run and
             gate["env"] == %{
               "GH_TOKEN" => "${{ github.token }}",
               "GH_REPO" => "${{ github.repository }}"
             } do
      raise ArgumentError, "#{@release_gate_step} must run #{@release_gate_run}"
    end

    gate_index = Enum.find_index(steps, &(&1 == gate))

    first_hex =
      Enum.find_index(steps, fn step ->
        step["run"] |> to_string() |> String.contains?(["hex.publish", "hex.info"])
      end)

    unless (first_hex && gate_index < first_hex) and gate_index == 1 do
      raise ArgumentError,
            "#{@release_gate_step} must run right after Checkout, before any Hex step"
    end

    :ok
  end

  defp release_job!(path, job_id), do: load_yaml!(path)["jobs"][job_id]

  defp load_yaml!(path) do
    [document] = path |> File.read!() |> String.to_charlist() |> :yamerl_constr.string()
    yaml(document)
  end

  defp yaml(value) when is_list(value) do
    cond do
      Enum.all?(value, &(is_integer(&1) and (&1 >= 32 or &1 in [9, 10, 13]))) ->
        List.to_string(value)

      Enum.all?(value, &match?({_, _}, &1)) ->
        Map.new(value, fn {key, item} -> {yaml(key), yaml(item)} end)

      true ->
        Enum.map(value, &yaml/1)
    end
  end

  defp yaml(:null), do: nil
  defp yaml(other), do: other

  test "changelog exposes an unreleased section" do
    changelog = File.read!("CHANGELOG.md")

    assert changelog =~ "## [Unreleased]"
    assert changelog =~ "Keep a Changelog"
  end
end
