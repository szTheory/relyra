defmodule Relyra.Adoption.PackageConsumerCIContractTest do
  use ExUnit.Case, async: true

  @moduletag :package_consumer_ci_contract

  @workflow_path ".github/workflows/security-gates.yml"
  @cost_report_path ".planning/phases/78-ci-efficiency-and-reliability/78-CI-COST.json"
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

  test "measured topology decision removes only the duplicated fast lane" do
    workflow = @workflow_path |> File.read!() |> parse_yaml!()
    report = @cost_report_path |> File.read!() |> Jason.decode!()
    steps = workflow["jobs"]["security"]["steps"]
    step_names = Enum.map(steps, & &1["name"])

    assert report["schema"] == "relyra-ci-cost-decision"
    assert report["version"] == 1
    assert report["decision"]["action"] == "remove_fast_lane"
    assert report["decision"]["reason_code"] == "qa_and_fast_select_same_tests"
    assert report["decision"]["supported_by_complete_samples"] == true
    assert report["decision"]["sample_count_per_configuration"] == 3

    assert Enum.count(step_names, &(&1 == "Quality gate")) == 1
    assert Enum.count(step_names, &(&1 == "Fast lane")) == 0
    refute Enum.any?(steps, &(get_in(&1, ["run"]) == "mix ci.fast"))

    quality_gate = Enum.find(steps, &(&1["name"] == "Quality gate"))
    assert quality_gate["run"] == "mix qa"
    refute Map.has_key?(quality_gate, "if")

    for gate <- [
          {"Security lane", "mix ci.security"},
          {"Evidence contract", "mix ci.evidence"},
          {"Phase 73 reconciliation", "mix ci.phase73.reconciliation"},
          {"Verification lane", "mix ci.verify"},
          {"Integration lane", "mix ci.integration"},
          {"Demo lane", "mix ci.demo"},
          {"Admin UI contract lane", "mix ci.admin_ui"},
          {"Admin UI browser smoke", "npm run admin-ui:smoke"},
          {"GATE-02 binary gate (gate02_c14n zero regressions)",
           "mix test --only gate02_c14n --warnings-as-errors"}
        ] do
      [step] = Enum.filter(steps, &(&1["name"] == elem(gate, 0)))
      assert step["run"] == elem(gate, 1)
      refute Map.has_key?(step, "if")
      refute Map.has_key?(step, "continue-on-error")
    end

    assert_complete_cost_samples!(report)
  end

  test "cost decision contract rejects incomplete or incomparable fixture data" do
    report = @cost_report_path |> File.read!() |> Jason.decode!()

    missing_sample =
      update_in(report, ["configurations", "baseline", "samples"], &Enum.drop(&1, -1))

    assert :sample_count in cost_report_errors(missing_sample)

    inconsistent_revision =
      update_in(
        report,
        ["configurations", "candidate", "samples", Access.at(0), "receipts", "28", "revision"],
        fn _ ->
          "0000000000000000000000000000000000000000"
        end
      )

    assert :mixed_revision in cost_report_errors(inconsistent_revision)

    mismatched_toolchain =
      update_in(
        report,
        [
          "configurations",
          "candidate",
          "samples",
          Access.at(0),
          "receipts",
          "28",
          "runner",
          "otp"
        ],
        fn _ ->
          26
        end
      )

    assert :incomparable_toolchain in cost_report_errors(mismatched_toolchain)

    failed_sample =
      update_in(
        report,
        ["configurations", "baseline", "samples", Access.at(0), "receipts", "27", "conclusion"],
        fn _ ->
          "failure"
        end
      )

    assert :failed_conclusion in cost_report_errors(failed_sample)

    unsupported_decision =
      put_in(
        report,
        ["statistics", "candidate", "warm", "runner_cost_ms", "median_ms"],
        get_in(report, ["statistics", "baseline", "warm", "runner_cost_ms", "median_ms"]) + 1
      )

    assert :statistics_mismatch in cost_report_errors(unsupported_decision)
    assert :unsupported_decision in cost_report_errors(unsupported_decision)

    explicitly_unsupported = put_in(report, ["decision", "supported_by_complete_samples"], false)
    assert :unsupported_decision in cost_report_errors(explicitly_unsupported)
  end

  test "workflow mutation fixtures reject cache-only proof and missing locked install" do
    workflow = @workflow_path |> File.read!() |> parse_yaml!()

    cache_only =
      update_security_steps(workflow, fn steps ->
        Enum.map(steps, fn
          %{"name" => "Package consumer contracts"} = step ->
            Map.put(step, "run", "echo restored consumer cache")

          step ->
            step
        end) ++
          [
            %{
              "name" => "Restore cached consumer proof",
              "uses" => "actions/cache/restore@v4",
              "with" => %{"path" => "/tmp/consumer-cache", "key" => "fixture"}
            }
          ]
      end)

    assert :consumer_profile_commands in workflow_errors(cache_only)
    assert :cross_run_cache_reuse in workflow_errors(cache_only)

    missing_locked_install =
      update_security_steps(workflow, fn steps ->
        Enum.map(steps, fn
          %{"name" => "Install dependencies"} = step ->
            Map.put(step, "run", "mix local.hex --force\nmix local.rebar --force")

          step ->
            step
        end)
      end)

    assert :locked_dependency_install in workflow_errors(missing_locked_install)
  end

  test "workflow mutation fixtures reject duplicate or skipped profiles and cross-run consumer reuse" do
    workflow = @workflow_path |> File.read!() |> parse_yaml!()

    duplicate_profile =
      update_security_steps(workflow, fn steps ->
        Enum.map(steps, fn
          %{"name" => "Package consumer contracts"} = step ->
            Map.put(
              step,
              "run",
              step["run"] <> "\nscripts/check_clean_room_consumer.sh --profile full"
            )

          step ->
            step
        end)
      end)

    assert :consumer_profile_commands in workflow_errors(duplicate_profile)

    skipped_profile =
      update_security_steps(workflow, fn steps ->
        Enum.map(steps, fn
          %{"name" => "Package consumer contracts"} = step ->
            Map.put(
              step,
              "run",
              "scripts/check_clean_room_consumer.sh --profile full\nscripts/check_clean_room_consumer.sh --profile contracts"
            )

          step ->
            step
        end)
      end)

    assert :consumer_profile_commands in workflow_errors(skipped_profile)

    cross_run_reuse =
      update_security_steps(workflow, fn steps ->
        steps ++
          [
            %{
              "name" => "Restore consumer build",
              "uses" => "actions/cache@v4",
              "with" => %{
                "path" => "_build/test",
                "key" => "${{ runner.os }}-${{ hashFiles('mix.lock') }}",
                "restore-keys" => "${{ runner.os }}-"
              }
            }
          ]
      end)

    assert :cross_run_cache_reuse in workflow_errors(cross_run_reuse)
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

  test "cost summaries preserve an equal-duration warm-run tie" do
    assert cost_summary([1_250, 1_250]) == %{
             "median_ms" => 1_250.0,
             "min_ms" => 1_250,
             "max_ms" => 1_250
           }
  end

  defp assert_complete_cost_samples!(report) do
    expected_cache_states = ["cold", "warm", "warm"]

    expected_test_steps = [
      "qa",
      "security",
      "evidence",
      "phase73-reconciliation",
      "verify",
      "integration",
      "admin-ui",
      "gate-02"
    ]

    for configuration <- ["baseline", "candidate"] do
      samples = get_in(report, ["configurations", configuration, "samples"])
      assert length(samples) == 3
      assert Enum.map(samples, & &1["cache_state"]) == expected_cache_states
      assert samples |> Enum.map(& &1["source_revision"]) |> Enum.uniq() |> length() == 1
      assert samples |> Enum.map(& &1["workflow_sha256"]) |> Enum.uniq() |> length() == 1

      Enum.each(samples, fn sample ->
        receipts = sample["receipts"]
        assert Map.keys(receipts) |> Enum.sort() == ["27", "28"]
        assert String.match?(sample["workflow_sha256"], ~r/\A[0-9a-f]{64}\z/)
        assert sample["proof_set_id"] == report["phase73_proof_set_id"]

        Enum.each(receipts, fn {otp, receipt} ->
          assert receipt["schema"] == "relyra-ci-cost-sample"
          assert receipt["conclusion"] == "success"
          assert receipt["dirty"] == false
          assert receipt["cache"] == sample["cache_state"]
          assert receipt["selected_tests"] > 0
          assert receipt["runner"]["elixir"] =~ "1.19.5"
          assert receipt["runner"]["os"] == "Linux"
          assert receipt["runner"]["architecture"] == "aarch64"
          assert to_string(receipt["runner"]["otp"]) == otp
          assert receipt["revision"] == sample["source_revision"]
          assert receipt["wall_ms"] > 0
          assert receipt["job_ms"] == receipt["wall_ms"]
          assert receipt["runner_ms"] >= receipt["setup_ms"]

          by_name = Map.new(receipt["steps"], &{&1["name"], &1})

          for name <- expected_test_steps do
            assert by_name[name]["conclusion"] == "passed"
            assert by_name[name]["exit_code"] == 0
            assert by_name[name]["selected_tests"] > 0
          end

          if configuration == "baseline" do
            assert by_name["fast"]["selected_tests"] == by_name["qa"]["selected_tests"]
          else
            refute Map.has_key?(by_name, "fast")
          end
        end)
      end)

      assert_cost_statistics!(samples, get_in(report, ["statistics", configuration]))
    end

    baseline = get_in(report, ["statistics", "baseline", "warm"])
    candidate = get_in(report, ["statistics", "candidate", "warm"])
    assert candidate["runner_cost_ms"]["median_ms"] < baseline["runner_cost_ms"]["median_ms"]

    baseline_workflow =
      get_in(report, ["configurations", "baseline", "samples", Access.at(0), "workflow_sha256"])

    candidate_workflow =
      get_in(report, ["configurations", "candidate", "samples", Access.at(0), "workflow_sha256"])

    refute baseline_workflow == candidate_workflow
  end

  defp cost_report_errors(report) do
    errors = []

    errors =
      if report["schema"] == "relyra-ci-cost-decision", do: errors, else: [:schema | errors]

    errors =
      if report["decision"]["action"] == "remove_fast_lane",
        do: errors,
        else: [:decision | errors]

    errors =
      if report["decision"]["supported_by_complete_samples"] == true,
        do: errors,
        else: [:unsupported_decision | errors]

    errors =
      Enum.reduce(["baseline", "candidate"], errors, fn configuration, acc ->
        samples = get_in(report, ["configurations", configuration, "samples"]) || []

        if length(samples) == 3,
          do: acc,
          else: [:sample_count | acc]
      end)

    errors =
      Enum.reduce(["baseline", "candidate"], errors, fn configuration, acc ->
        samples = get_in(report, ["configurations", configuration, "samples"]) || []

        if samples |> Enum.map(& &1["source_revision"]) |> Enum.uniq() |> length() == 1,
          do: acc,
          else: [:mixed_revision | acc]
      end)

    errors =
      Enum.reduce(["baseline", "candidate"], errors, fn configuration, acc ->
        samples = get_in(report, ["configurations", configuration, "samples"]) || []
        statistics = get_in(report, ["statistics", configuration]) || %{}

        try do
          assert_cost_statistics!(samples, statistics)
          acc
        rescue
          ExUnit.AssertionError -> [:statistics_mismatch | acc]
        end
      end)

    baseline_median =
      get_in(report, ["statistics", "baseline", "warm", "runner_cost_ms", "median_ms"])

    candidate_median =
      get_in(report, ["statistics", "candidate", "warm", "runner_cost_ms", "median_ms"])

    errors =
      if report["decision"]["supported_by_complete_samples"] == true and
           is_number(baseline_median) and is_number(candidate_median) and
           candidate_median < baseline_median,
         do: errors,
         else: [:unsupported_decision | errors]

    Enum.reduce(["baseline", "candidate"], errors, fn configuration, acc ->
      samples = get_in(report, ["configurations", configuration, "samples"]) || []

      Enum.reduce(samples, acc, fn sample, sample_errors ->
        receipts = sample["receipts"] || %{}
        expected_cache = sample["cache_state"]

        sample_errors =
          if Enum.sort(Map.keys(receipts)) == ["27", "28"] and
               Enum.all?(receipts, fn {_otp, receipt} ->
                 receipt["conclusion"] == "success" and receipt["cache"] == expected_cache
               end),
             do: sample_errors,
             else: [:failed_conclusion | sample_errors]

        sample_errors =
          if Enum.all?(receipts, fn {otp, receipt} ->
               receipt["revision"] == sample["source_revision"] and
                 to_string(receipt["runner"]["otp"]) == otp
             end),
             do: sample_errors,
             else: [:mixed_revision | sample_errors]

        sample_errors =
          if Enum.all?(receipts, fn {otp, receipt} ->
               to_string(receipt["runner"]["otp"]) == otp and
                 receipt["runner"]["elixir"] =~ "1.19.5"
             end),
             do: sample_errors,
             else: [:incomparable_toolchain | sample_errors]

        sample_errors
      end)
    end)
  end

  defp assert_cost_statistics!(samples, statistics) do
    for cache_state <- ["cold", "warm"] do
      selected = Enum.filter(samples, &(&1["cache_state"] == cache_state))
      walls = Enum.map(selected, &matrix_cost(&1, "wall_ms"))
      runner_costs = Enum.map(selected, &matrix_cost(&1, "runner_ms"))

      assert statistics[cache_state]["sample_count"] == length(selected)
      assert statistics[cache_state]["matrix_wall_ms"] == cost_summary(walls)
      assert statistics[cache_state]["runner_cost_ms"] == cost_summary(runner_costs)
    end
  end

  defp matrix_cost(sample, "wall_ms") do
    sample["receipts"] |> Map.values() |> Enum.map(& &1["wall_ms"]) |> Enum.max()
  end

  defp matrix_cost(sample, "runner_ms") do
    sample["receipts"] |> Map.values() |> Enum.map(& &1["runner_ms"]) |> Enum.sum()
  end

  defp cost_summary(values) do
    sorted = Enum.sort(values)
    middle = div(length(sorted), 2)

    median =
      if rem(length(sorted), 2) == 1 do
        Enum.at(sorted, middle)
      else
        (Enum.at(sorted, middle - 1) + Enum.at(sorted, middle)) / 2
      end

    %{"median_ms" => median, "min_ms" => hd(sorted), "max_ms" => List.last(sorted)}
  end

  defp workflow_errors(workflow) do
    jobs = workflow["jobs"] || %{}
    all_steps = Enum.flat_map(Map.values(jobs), &(&1["steps"] || []))
    security = jobs["security"] || %{}
    steps = security["steps"] || []

    consumer_steps = Enum.filter(all_steps, &(&1["name"] == "Package consumer contracts"))
    dependency_steps = Enum.filter(steps, &(&1["name"] == "Install dependencies"))

    consumer_commands =
      case consumer_steps do
        [%{"run" => run} = step] when is_binary(run) ->
          run_lines =
            run |> String.split("\n") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))

          owners =
            Enum.map(@required_commands, fn command ->
              Enum.count(all_steps, fn owner ->
                is_binary(owner["run"]) and
                  command in (owner["run"] |> String.split("\n") |> Enum.map(&String.trim/1))
              end)
            end)

          run_lines == @required_commands and owners == [1, 1, 1] and
            not Map.has_key?(step, "if") and not Map.has_key?(step, "continue-on-error")

        _ ->
          false
      end

    locked_install =
      case dependency_steps do
        [%{"run" => run}] when is_binary(run) ->
          String.contains?(run, "mix deps.get") and not String.contains?(run, "--only prod")

        _ ->
          false
      end

    errors = []
    errors = if consumer_commands, do: errors, else: [:consumer_profile_commands | errors]
    errors = if locked_install, do: errors, else: [:locked_dependency_install | errors]

    if cross_run_consumer_cache?(all_steps),
      do: [:cross_run_cache_reuse | errors],
      else: errors
  end

  defp cross_run_consumer_cache?(steps) do
    Enum.any?(steps, fn step ->
      if String.starts_with?(step["uses"] || "", "actions/cache") do
        cache = step["with"] || %{}
        path = cache["path"] |> List.wrap() |> Enum.join(" ") |> String.downcase()

        Map.has_key?(cache, "restore-keys") or
          Enum.any?(
            ["_build", "/deps", "consumer", "mix_home", "hex_home"],
            &String.contains?(path, &1)
          )
      else
        false
      end
    end)
  end

  defp update_security_steps(workflow, update) do
    put_in(
      workflow,
      ["jobs", "security", "steps"],
      update.(get_in(workflow, ["jobs", "security", "steps"]))
    )
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
