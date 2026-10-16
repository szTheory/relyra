defmodule Relyra.Adoption.PackageConsumerCIContractTest do
  use ExUnit.Case, async: true

  @moduletag :package_consumer_ci_contract

  @workflow_path ".github/workflows/security-gates.yml"
  @consumer_job "package-consumers"
  @phase73_job "phase73-reconciliation"
  @cost_report_path ".planning/phases/78-ci-efficiency-and-reliability/78-CI-COST.json"
  @required_commands [
    "scripts/check_clean_room_consumer.sh --profile full",
    "scripts/check_clean_room_consumer.sh --profile minimal --concurrency-check",
    "scripts/check_clean_room_consumer.sh --profile contracts"
  ]

  test "one unconditional consumer matrix owner runs every package consumer profile" do
    workflow = @workflow_path |> File.read!() |> parse_yaml!()

    assert Map.has_key?(workflow["on"], "pull_request")
    assert Map.has_key?(workflow["on"], "push")
    assert Map.has_key?(workflow["on"], "workflow_dispatch")

    security_job = workflow["jobs"]["security"]
    assert security_job["strategy"]["matrix"]["otp"] == [27, 28]
    assert security_job["strategy"]["matrix"]["elixir"] == ["1.19.5"]

    consumer_job = workflow["jobs"][@consumer_job]
    assert consumer_job["strategy"]["matrix"] == security_job["strategy"]["matrix"]
    assert consumer_job["strategy"]["fail-fast"] == false
    refute Map.has_key?(consumer_job, "if")
    refute Map.has_key?(consumer_job, "needs")
    refute Map.has_key?(consumer_job, "continue-on-error")
    assert @consumer_job in workflow["jobs"]["ci-gate"]["needs"]
    assert workflow["jobs"]["ci-gate"]["if"] == "always()"

    security_steps = security_job["steps"]
    steps = consumer_job["steps"]
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

    security_step_names = Enum.map(security_steps, & &1["name"])

    demo_setup =
      Enum.find(security_steps, &(get_in(&1, ["name"]) == "Prepare demo test metadata"))

    assert demo_setup["env"]["MIX_ENV"] == "test"

    assert String.trim(demo_setup["run"]) ==
             "mix cmd --cd demo/ledger_loop mix deps.get\nmix cmd --cd demo/ledger_loop mix compile"

    quality_gate_index = Enum.find_index(security_step_names, &(&1 == "Quality gate"))

    assert Enum.find_index(security_step_names, &(&1 == "Prepare demo test metadata")) <
             quality_gate_index
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

    [phase73_step] =
      Enum.filter(
        workflow["jobs"][@phase73_job]["steps"],
        &(&1["name"] == "Phase 73 reconciliation")
      )

    assert phase73_step["run"] == "mix ci.phase73.reconciliation"
    refute Map.has_key?(phase73_step, "if")
    refute Map.has_key?(phase73_step, "continue-on-error")
    assert @phase73_job in workflow["jobs"]["ci-gate"]["needs"]

    for gate <- [
          {"Security lane", "mix ci.security"},
          {"Evidence contract", "mix ci.evidence"},
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
      update_consumer_steps(workflow, fn steps ->
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
      update_consumer_steps(workflow, fn steps ->
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
      update_consumer_steps(workflow, fn steps ->
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
      update_consumer_steps(workflow, fn steps ->
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
      update_consumer_steps(workflow, fn steps ->
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

    assert workflow_errors(workflow) == []

    ungated =
      update_in(workflow, ["jobs", "ci-gate", "needs"], &List.delete(&1, @consumer_job))

    assert :consumer_job_not_gated in workflow_errors(ungated)

    skippable = put_in(workflow, ["jobs", @consumer_job, "if"], "github.event_name == 'push'")
    assert :consumer_job_not_gated in workflow_errors(skippable)

    moved_back =
      workflow
      |> update_in(["jobs", "security", "steps"], fn steps ->
        steps ++
          Enum.filter(
            workflow["jobs"][@consumer_job]["steps"],
            &(&1["name"] == "Package consumer contracts")
          )
      end)

    assert :consumer_profile_commands in workflow_errors(moved_back)
  end

  test "full consumer teardown removes its labeled volume before a minimal run starts" do
    fixture_root =
      Path.join(
        System.tmp_dir!(),
        "package-consumer-fixture-#{System.unique_integer([:positive])}"
      )

    {bin, tmp, events} = prepare_package_consumer_fixture!(fixture_root)
    on_exit(fn -> File.rm_rf!(fixture_root) end)

    {result, status} =
      run_consumer_fixture!(fixture_root, bin, tmp, events, [
        "-c",
        "bash scripts/check_clean_room_consumer.sh --profile full && bash scripts/check_clean_room_consumer.sh --profile minimal"
      ])

    assert status == 0, "status=#{status}, output=#{result}"
    assert result =~ "package consumer [full]: PASS"
    assert result =~ "PASS: minimal-compile"
    docker_events = File.read!(events)
    assert docker_events =~ "volume create"
    assert docker_events =~ "container inspect"
    assert docker_events =~ "volume inspect"
    assert docker_events =~ "rm --force"
    assert docker_events =~ "volume rm"
    assert File.ls!(tmp) == []

    {result, status} =
      run_consumer_fixture!(fixture_root, bin, tmp, events, [
        "scripts/check_clean_room_consumer.sh",
        "--profile",
        "minimal",
        "--concurrency-check"
      ])

    assert status == 0, "status=#{status}, output=#{result}"
    assert result =~ "concurrent run roots and all mutable paths are disjoint"
  end

  @tag contract_cleanup_case: :failure_guards
  test "cleanup failures preserve unknown resources and primary contract evidence" do
    fixture_root =
      Path.join(
        System.tmp_dir!(),
        "package-consumer-failure-fixture-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(fixture_root)
    on_exit(fn -> File.rm_rf!(fixture_root) end)

    primary_root = Path.join(fixture_root, "primary")
    {bin, tmp, events} = prepare_package_consumer_fixture!(primary_root)
    File.write!(Path.join(primary_root, "mode"), "contract-failure\n")

    {result, status} =
      run_consumer_fixture!(primary_root, bin, tmp, events, [
        "scripts/check_clean_room_consumer.sh",
        "--profile",
        "full"
      ])

    assert status == 37, result
    assert result =~ "FAIL: run the public Phoenix consumer installer exited 37"
    assert result =~ "failure state retained at"
    assert [_, log_path] = Regex.run(~r/Log retained at (.+?)\. Next:/, result)
    assert File.regular?(log_path)
    assert File.read!(log_path) =~ "intentional contract fixture failure"
    assert File.read!(events) =~ "rm --force"
    assert File.read!(events) =~ "volume rm"

    for {mode, expected_status, retained_resource} <- [
          {"volume-create-failure", 1, nil},
          {"preexisting-volume", 1, "volume"},
          {"container-start-failure", 1, nil},
          {"preexisting-container", 1, "container"},
          {"container-label-missing", 1, "container"},
          {"container-label-mismatch", 1, "container"},
          {"volume-label-missing", 1, "volume"},
          {"volume-label-mismatch", 1, "volume"},
          {"container-cleanup-failure", 1, "container"},
          {"volume-cleanup-failure", 1, "volume"},
          {"unknown-child", 1, "unknown"}
        ] do
      mode_root = Path.join(fixture_root, mode)
      {mode_bin, mode_tmp, mode_events} = prepare_package_consumer_fixture!(mode_root)
      File.write!(Path.join(mode_root, "mode"), mode <> "\n")

      {mode_result, mode_status} =
        run_consumer_fixture!(mode_root, mode_bin, mode_tmp, mode_events, [
          "scripts/check_clean_room_consumer.sh",
          "--profile",
          "full"
        ])

      assert mode_status == expected_status,
             "#{mode}: expected exit #{expected_status}, got #{mode_status}: #{mode_result}"

      assert File.read!(mode_events) =~ "volume create"

      case retained_resource do
        "container" ->
          assert mode_result =~ "container"
          assert File.regular?(Path.join(mode_root, "container-owner"))

          if mode == "container-cleanup-failure" do
            assert File.read!(mode_events) =~ "rm --force"
            assert mode_result =~ "cleanup failed removing owned container"
          else
            refute File.read!(mode_events) =~ "rm --force"
          end

        "volume" ->
          assert mode_result =~ "volume"
          assert File.regular?(Path.join(mode_root, "volume-owner"))

          if mode == "volume-cleanup-failure" do
            assert File.read!(mode_events) =~ "volume rm"
            assert mode_result =~ "cleanup failed removing owned volume"
          else
            refute File.read!(mode_events) =~ "volume rm"
          end

        "unknown" ->
          assert [_, run_root] =
                   Regex.run(~r/cleanup refused run root ([^:]+): unknown-owner/, mode_result)

          assert File.dir?(Path.join(run_root, "unknown-owner"))

        nil ->
          assert mode_result =~ "failure state retained"
      end
    end
  end

  @tag contract_cleanup_case: :omission
  test "contracts omission cleanup removes its known run-root directory" do
    fixture_root =
      Path.join(
        System.tmp_dir!(),
        "package-consumer-omission-#{System.unique_integer([:positive])}"
      )

    {repo, bin, tmp, events} = prepare_contract_cleanup_fixture!(fixture_root)
    on_exit(fn -> File.rm_rf!(fixture_root) end)
    {result, status} = run_contract_cleanup_fixture!(repo, bin, tmp, events, "omission")
    assert status == 0, "status=#{status}, output=#{result}"
    assert result =~ "package consumer [contracts]: PASS"
    assert File.ls!(tmp) == []
  end

  @tag contract_cleanup_case: :prior_force
  test "contracts prior force-probe cleanup removes its known run-root directory" do
    fixture_root =
      Path.join(System.tmp_dir!(), "package-consumer-force-#{System.unique_integer([:positive])}")

    {repo, bin, tmp, events} = prepare_contract_cleanup_fixture!(fixture_root)
    on_exit(fn -> File.rm_rf!(fixture_root) end)
    {result, status} = run_contract_cleanup_fixture!(repo, bin, tmp, events, "prior")
    assert status == 0, "status=#{status}, output=#{result}"
    assert result =~ "explicit force changed only resolver/mapper outputs"
    assert File.read!(events) =~ "volume rm"
    assert File.ls!(tmp) == []
  end

  defp prepare_contract_cleanup_fixture!(fixture_root) do
    project_source = Path.expand("../..", __DIR__)
    repo = Path.join(fixture_root, "repo")
    bin = Path.join(fixture_root, "bin")
    tmp = Path.join(fixture_root, "tmp")
    events = Path.join(fixture_root, "docker-events.log")
    fixture_base = Path.join(repo, "test/fixtures/package_consumer")
    File.mkdir_p!(Path.join(repo, "scripts"))
    File.mkdir_p!(fixture_base)
    File.mkdir_p!(bin)
    File.mkdir_p!(tmp)

    File.cp!(
      Path.join(project_source, "scripts/check_clean_room_consumer.sh"),
      Path.join(repo, "scripts/check_clean_room_consumer.sh")
    )

    for name <- ["consumer", "prior_scaffold", "golden"] do
      File.cp_r!(
        Path.join(project_source, "test/fixtures/package_consumer/#{name}"),
        Path.join(fixture_base, name)
      )
    end

    generated_connections = "defmodule PackageConsumer.GeneratedConnections do\nend\n"
    generated_mapper = "defmodule PackageConsumer.GeneratedMapper do\nend\n"
    connections_hash = :crypto.hash(:sha256, generated_connections) |> Base.encode16(case: :lower)
    mapper_hash = :crypto.hash(:sha256, generated_mapper) |> Base.encode16(case: :lower)
    # The isolated installer stub writes these bytes; align only its private golden
    # so the real consumer script reaches its cleanup branch without Mix or Docker.
    File.write!(
      Path.join(fixture_base, "golden/fresh_files.sha256"),
      "#{connections_hash}  lib/package_consumer/relyra/connections.ex\n#{mapper_hash}  lib/package_consumer/relyra/user_mapper.ex\n"
    )

    write_executable!(Path.join(bin, "mix"), """
    #!/usr/bin/env bash
    set -euo pipefail
    cmd="$1"; shift
    case "$cmd" in
      hex.build)
        out=""
        while (($#)); do if [[ "$1" == "--output" ]]; then out="$2"; shift 2; else shift; fi; done
        mkdir -p "$out/relyra/lib/relyra"
        printf 'defmodule Relyra.Mixfile do end\\n' > "$out/relyra/mix.exs"
        printf 'defmodule Relyra.Testing do end\\n' > "$out/relyra/lib/relyra/testing.ex"
        ;;
      deps.get) [[ -f mix.lock ]] || printf '{}\\n' > mix.lock ;;
      run)
        for arg in "$@"; do
          if [[ "$arg" == *"Code.ensure_loaded?"* ]]; then
            printf 'package contract missing: lib/relyra/testing.ex\\n' >&2
            exit 1
          fi
        done
        ;;
      relyra.install)
        force=false
        for arg in "$@"; do [[ "$arg" != "--force" ]] || force=true; done
        if [[ "$force" == true ]]; then
          printf 'defmodule PackageConsumer.GeneratedConnections do\\nend\\n' > lib/package_consumer/relyra/connections.ex
          printf 'defmodule PackageConsumer.GeneratedMapper do\\nend\\n' > lib/package_consumer/relyra/user_mapper.ex
        else
          printf 'Skipped existing lib/package_consumer/relyra/connections.ex\\n'
          printf 'Skipped existing lib/package_consumer/relyra/user_mapper.ex\\n'
          printf 'Relyra SAML routes already present in lib/package_consumer_web/router.ex\\n'
        fi
        ;;
      compile) printf 'prior compile: PASS\\n' ;;
    esac
    """)

    write_executable!(Path.join(bin, "docker"), """
    #!/usr/bin/env bash
    set -euo pipefail
    root="$PACKAGE_CONSUMER_FIXTURE_ROOT"
    printf '%s\\n' "$*" >> "$PACKAGE_CONSUMER_FIXTURE_EVENTS"
    case "$1" in
      volume)
        if [[ "$2" == "create" ]]; then
          volume=""; owner=""
          while (($#)); do
            if [[ "$1" == "--label" ]]; then owner="${2#*=}"; shift 2
            elif [[ "$1" == "--name" ]]; then volume="$2"; shift 2
            else shift; fi
          done
          printf '%s\\n' "$volume" > "$root/volume-name"
          printf '%s\\n' "$owner" > "$root/volume-owner"
          printf '%s\\n' "$volume"
        elif [[ "$2" == "inspect" ]]; then
          [[ "${5:-}" == "$(cat "$root/volume-name")" ]] || exit 1
          cat "$root/volume-owner"
        elif [[ "$2" == "rm" ]]; then :; fi
        ;;
      rm) : ;;
      run)
        name=""; owner=""
        while (($#)); do
          if [[ "$1" == "--name" ]]; then name="$2"; shift 2
          elif [[ "$1" == "--label" ]]; then owner="${2#*=}"; shift 2
          else shift; fi
        done
        printf '%s\\n' "$name" > "$root/container-name"
        printf '%s\\n' "$owner" > "$root/container-owner"
        printf 'container-id\\n'
        ;;
      container)
        if [[ "$2" == "inspect" ]]; then
          [[ "${5:-}" == "$(cat "$root/container-name" 2>/dev/null || true)" ]] || exit 1
          cat "$root/container-owner"
        fi
        ;;
      port) printf '127.0.0.1:49152\\n' ;;
      exec) exit 0 ;;
      *) exit 0 ;;
    esac
    """)

    {repo, bin, tmp, events}
  end

  defp run_contract_cleanup_fixture!(repo, bin, tmp, events, contract_case) do
    System.cmd(
      "bash",
      ["scripts/check_clean_room_consumer.sh", "--profile", "contracts", "--case", contract_case],
      cd: repo,
      env: [
        {"PATH", bin <> ":" <> System.get_env("PATH")},
        {"TMPDIR", tmp},
        {"PACKAGE_CONSUMER_FIXTURE_ROOT", Path.dirname(events)},
        {"PACKAGE_CONSUMER_FIXTURE_EVENTS", events}
      ],
      stderr_to_stdout: true
    )
  end

  defp prepare_package_consumer_fixture!(fixture_root) do
    bin = Path.join(fixture_root, "bin")
    tmp = Path.join(fixture_root, "tmp")
    events = Path.join(fixture_root, "docker-events.log")

    File.mkdir_p!(bin)
    File.mkdir_p!(tmp)
    File.write!(Path.join(fixture_root, "mode"), "success\n")

    write_executable!(Path.join(bin, "mix"), """
    #!/usr/bin/env bash
    set -euo pipefail
    fixture_root="$(cd "$(dirname "$0")/.." && pwd -P)"
    mode="$(cat "$fixture_root/mode")"
    if [[ "$1" == "hex.build" ]]; then
      if [[ "$mode" == "unknown-child" ]]; then mkdir -p "$PACKAGE_CONSUMER_RUN_ROOT/unknown-owner"; fi
      output=""
      while (($#)); do
        if [[ "$1" == "--output" ]]; then output="$2"; shift 2; else shift; fi
      done
      mkdir -p "$output/relyra"
      printf 'defmodule Relyra.Mixfile do end\\n' > "$output/relyra/mix.exs"
    elif [[ "$1" == "compile" ]]; then
      printf 'minimal compile: PASS — isolated fixture\\n'
    elif [[ "$mode" == "contract-failure" && "$1" == "relyra.install" ]]; then
      printf 'intentional contract fixture failure\\n' >&2
      exit 37
    fi
    """)

    write_executable!(Path.join(bin, "docker"), """
    #!/usr/bin/env bash
    set -euo pipefail
    fixture_root="$(cd "$(dirname "$0")/.." && pwd -P)"
    mode="$(cat "$fixture_root/mode")"
    printf '%s\\n' "$*" >> "$PACKAGE_CONSUMER_FIXTURE_EVENTS"
    case "$1" in
      volume)
        if [[ "$2" == "create" ]]; then
          volume=""
          while (($#)); do
            if [[ "$1" == "--label" ]]; then owner="${2#*=}"; shift 2
            elif [[ "$1" == "--name" ]]; then volume="$2"; shift 2
            else shift; fi
          done
          printf '%s\\n' "$volume" > "$fixture_root/volume-name"
          if [[ "$mode" == "preexisting-volume" ]]; then owner="foreign-owner"; printf '%s\\n' "$owner" > "$fixture_root/volume-owner"; exit 17; fi
          if [[ "$mode" == "volume-create-failure" ]]; then exit 17; fi
          case "$mode" in volume-label-missing) owner="" ;; volume-label-mismatch) owner="foreign-owner" ;; esac
          printf '%s\\n' "$owner" > "$fixture_root/volume-owner"
          printf '%s\\n' "$volume"
        elif [[ "$2" == "inspect" ]]; then
          [[ "${5:-}" == "$(cat "$fixture_root/volume-name")" ]] || exit 1
          cat "$fixture_root/volume-owner"
        elif [[ "$2" == "rm" ]]; then
          [[ "$mode" != "volume-cleanup-failure" ]] || exit 27
        fi
        ;;
      rm) [[ "$mode" != "container-cleanup-failure" ]] || exit 26 ;;
      run)
        name=""
        owner=""
        while (($#)); do
          if [[ "$1" == "--name" ]]; then name="$2"; shift 2
          elif [[ "$1" == "--label" ]]; then owner="${2#*=}"; shift 2
          else shift; fi
        done
        if [[ "$mode" == "preexisting-container" ]]; then
          printf '%s\\n' "$name" > "$fixture_root/container-name"
          printf 'foreign-owner\\n' > "$fixture_root/container-owner"
          exit 18
        fi
        [[ "$mode" != "container-start-failure" ]] || exit 19
        case "$mode" in container-label-missing) owner="" ;; container-label-mismatch) owner="foreign-owner" ;; esac
        printf '%s\\n' "$name" > "$fixture_root/container-name"
        printf '%s\\n' "$owner" > "$fixture_root/container-owner"
        printf 'container-id\\n'
        ;;
      container)
        if [[ "$2" == "inspect" ]]; then
          [[ "${5:-}" == "$(cat "$fixture_root/container-name" 2>/dev/null || true)" ]] || exit 1
          cat "$fixture_root/container-owner"
        fi
        ;;
      port) printf '127.0.0.1:49152\\n' ;;
      exec) exit 0 ;;
      *) exit 0 ;;
    esac
    """)

    {bin, tmp, events}
  end

  defp run_consumer_fixture!(fixture_root, bin, tmp, events, command) do
    System.cmd(
      "bash",
      command,
      cd: File.cwd!(),
      env: [
        {"PATH", bin <> ":" <> System.get_env("PATH")},
        {"TMPDIR", tmp},
        {"PACKAGE_CONSUMER_FIXTURE_ROOT", fixture_root},
        {"PACKAGE_CONSUMER_FIXTURE_EVENTS", events}
      ],
      stderr_to_stdout: true
    )
  end

  defp write_executable!(path, contents) do
    File.write!(path, contents)
    File.chmod!(path, 0o755)
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
    consumers = jobs[@consumer_job] || %{}
    steps = consumers["steps"] || []

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

    gate = jobs["ci-gate"] || %{}

    consumer_gated =
      is_list(gate["needs"]) and @consumer_job in gate["needs"] and gate["if"] == "always()" and
        not Map.has_key?(consumers, "if") and not Map.has_key?(consumers, "needs")

    errors = if consumer_gated, do: [], else: [:consumer_job_not_gated]
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

  defp update_consumer_steps(workflow, update) do
    put_in(
      workflow,
      ["jobs", @consumer_job, "steps"],
      update.(get_in(workflow, ["jobs", @consumer_job, "steps"]))
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
