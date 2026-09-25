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
