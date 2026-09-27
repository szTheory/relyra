defmodule Relyra.Adoption.PackageConsumerCIContractTest do
  use ExUnit.Case, async: true

  @moduletag :package_consumer_ci_contract

  @workflow_path ".github/workflows/security-gates.yml"
  @required_commands [
    "scripts/check_clean_room_consumer.sh --profile full",
    "scripts/check_clean_room_consumer.sh --profile minimal --concurrency-check",
    "scripts/check_clean_room_consumer.sh --profile contracts"
  ]

  test "one unconditional security matrix owner runs every package consumer profile" do
    workflow = @workflow_path |> File.read!() |> parse_yaml!()

    assert Map.has_key?(workflow["on"], "pull_request")
    assert Map.has_key?(workflow["on"], "push")
    assert Map.has_key?(workflow["on"], "workflow_dispatch")

    security_job = workflow["jobs"]["security"]
    assert security_job["strategy"]["matrix"]["otp"] == [27, 28]
    assert security_job["strategy"]["matrix"]["elixir"] == ["1.19.5"]

    steps = security_job["steps"]
    all_steps = workflow["jobs"] |> Map.values() |> Enum.flat_map(& &1["steps"])

    all_package_steps =
      Enum.filter(all_steps, &(get_in(&1, ["name"]) == "Package consumer contracts"))

    package_steps = Enum.filter(steps, &(get_in(&1, ["name"]) == "Package consumer contracts"))
    assert length(all_package_steps) == 1
    assert length(package_steps) == 1

    [package_step] = package_steps
    refute Map.has_key?(package_step, "if")
    refute Map.has_key?(package_step, "continue-on-error")

    run_lines =
      package_step["run"]
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    assert run_lines == @required_commands

    Enum.each(@required_commands, fn command ->
      command_owners =
        Enum.count(all_steps, fn step ->
          if is_binary(step["run"]) do
            run_lines = step["run"] |> String.split("\n") |> Enum.map(&String.trim/1)
            command in run_lines
          else
            false
          end
        end)

      assert command_owners == 1
    end)

    step_names = Enum.map(steps, & &1["name"])

    assert Enum.find_index(step_names, &(&1 == "Package consumer contracts")) >
             Enum.find_index(step_names, &(&1 == "Setup BEAM"))

    assert Enum.find_index(step_names, &(&1 == "Package consumer contracts")) >
             Enum.find_index(step_names, &(&1 == "Install dependencies"))

    demo_setup = Enum.find(steps, &(get_in(&1, ["name"]) == "Prepare demo test metadata"))
    assert demo_setup["env"]["MIX_ENV"] == "test"

    assert String.trim(demo_setup["run"]) ==
             "mix cmd --cd demo/ledger_loop mix deps.get\nmix cmd --cd demo/ledger_loop mix compile"

    quality_gate_index = Enum.find_index(step_names, &(&1 == "Quality gate"))
    assert Enum.find_index(step_names, &(&1 == "Prepare demo test metadata")) < quality_gate_index
  end

  test "owned cost collector records passing positive-execution receipts" do
    output = Path.join(System.tmp_dir!(), "ci-cost-#{System.unique_integer([:positive])}.json")

    on_exit(fn -> File.rm(output) end)

    {result, status} =
      System.cmd(
        "bash",
        [
          "scripts/measure_ci_cost.sh",
          "--output",
          output,
          "--event",
          "fixture",
          "--cache",
          "cold",
          "--command",
          "setup:bootstrap:printf 'setup complete\\n'",
          "--command",
          "test:focused:printf '2 tests, 0 failures\\n'"
        ],
        stderr_to_stdout: true
      )

    assert status == 0, result
    sample = output |> File.read!() |> Jason.decode!()
    assert sample["schema"] == "relyra-ci-cost-sample"
    assert sample["version"] == 1
    assert sample["revision"] == String.trim(elem(System.cmd("git", ["rev-parse", "HEAD"]), 0))
    assert sample["event"] == "fixture"
    assert sample["cache"] == "cold"
    assert sample["conclusion"] == "success"
    assert sample["selected_tests"] == 2
    assert sample["runner_ms"] >= sample["setup_ms"]
    assert Enum.map(sample["steps"], & &1["exit_code"]) == [0, 0]
    assert Enum.map(sample["steps"], & &1["selected_tests"]) == [0, 2]
  end

  test "setup failure preserves its exit and rejects the partial sample" do
    output = Path.join(System.tmp_dir!(), "ci-cost-#{System.unique_integer([:positive])}.json")

    on_exit(fn -> File.rm(output) end)

    {result, status} =
      System.cmd(
        "bash",
        [
          "scripts/measure_ci_cost.sh",
          "--output",
          output,
          "--event",
          "fixture",
          "--cache",
          "none",
          "--command",
          "setup:broken:exit 7",
          "--command",
          "test:skipped:printf '1 test, 0 failures\\n'"
        ],
        stderr_to_stdout: true
      )

    assert status == 1, result
    sample = output |> File.read!() |> Jason.decode!()
    assert sample["conclusion"] == "failure"

    assert sample["steps"] |> Enum.map(&{&1["conclusion"], &1["exit_code"]}) ==
             [{"failed", 7}, {"not_run", nil}]

    assert sample["selected_tests"] == 0
  end

  test "collector rejects a completed command with no selected tests" do
    output = Path.join(System.tmp_dir!(), "ci-cost-#{System.unique_integer([:positive])}.json")

    on_exit(fn -> File.rm(output) end)

    {result, status} =
      System.cmd(
        "bash",
        [
          "scripts/measure_ci_cost.sh",
          "--output",
          output,
          "--event",
          "fixture",
          "--cache",
          "warm",
          "--command",
          "test:empty:printf '0 tests, 0 failures\\n'"
        ],
        stderr_to_stdout: true
      )

    assert status == 1, result
    assert output |> File.read!() |> Jason.decode!() |> Map.fetch!("conclusion") == "failure"
  end

  defp parse_yaml!(yaml) do
    [document] = :yamerl_constr.string(String.to_charlist(yaml))
    convert_yaml(document)
  end

  defp convert_yaml(value) when is_list(value) do
    cond do
      Enum.all?(value, &(is_integer(&1) and (&1 >= 32 or &1 in [9, 10, 13]))) ->
        List.to_string(value)

      Enum.all?(value, &match?({_, _}, &1)) ->
        Map.new(value, fn {key, item} -> {convert_yaml(key), convert_yaml(item)} end)

      true ->
        Enum.map(value, &convert_yaml/1)
    end
  end

  defp convert_yaml({key, value}), do: {convert_yaml(key), convert_yaml(value)}
  defp convert_yaml(:null), do: nil
  defp convert_yaml(value), do: value
end
