defmodule Relyra.FleetProxyCIIntegrityTest do
  use ExUnit.Case, async: true

  @required_checks [
    "security (27, 1.19.5)",
    "security (28, 1.19.5)",
    "fleet-proxy-e2e"
  ]

  @required_check_consumers [
    "scripts/setup_branch_protection.sh",
    ".github/workflows/release-please-automerge.yml",
    ".github/workflows/release-please-pr-checks.yml",
    ".github/workflows/planning-pr-checks.yml"
  ]

  @demo_path ".github/workflows/demo-app-e2e.yml"
  @fleet_path ".github/workflows/fleet-proxy-e2e.yml"
  @fleet_script "scripts/test_fleet_proxy_e2e.sh"
  @fleet_playwright_config "playwright.fleet-proxy.config.mjs"
  @trace_script "scripts/test_trace_visual_e2e.sh"
  @status_sentinels [
    "ASSERTION_SENTINEL",
    "CERTIFICATE_SENTINEL",
    "PASSWORD_SENTINEL",
    "COOKIE_SENTINEL",
    "UNEXPECTED_ATTACHMENT_SENTINEL"
  ]

  @action_pins %{
    @demo_path => [
      {"actions/checkout", "3d3c42e5aac5ba805825da76410c181273ba90b1", "v7.0.1", 1},
      {"actions/setup-node", "820762786026740c76f36085b0efc47a31fe5020", "v7.0.0", 1},
      {"actions/upload-artifact", "043fb46d1a93c77aae656e7c1c64a875d1fc6a0a", "v7.0.1", 1},
      {"erlef/setup-beam", "54075bcc5e249e4758d363f27d099f55d843f124", "v1.24.1", 1}
    ],
    @fleet_path => [
      {"actions/checkout", "3d3c42e5aac5ba805825da76410c181273ba90b1", "v7.0.1", 3},
      {"actions/setup-node", "820762786026740c76f36085b0efc47a31fe5020", "v7.0.0", 1},
      {"actions/upload-artifact", "043fb46d1a93c77aae656e7c1c64a875d1fc6a0a", "v7.0.1", 2}
    ]
  }

  test "demo and fleet browser workflows keep stable blocking owners and safe triggers" do
    demo = load_yaml!(@demo_path)
    fleet = load_yaml!(@fleet_path)

    assert :ok = validate_required_workflow!(@demo_path, demo)
    assert :ok = validate_required_workflow!(@fleet_path, fleet)

    assert_blocking_step!(
      demo["jobs"]["fake-idp-e2e"]["steps"],
      "FakeIdP browser e2e",
      "npm run demo:fake-idp"
    )

    assert_blocking_step!(
      demo["jobs"]["fake-idp-e2e"]["steps"],
      "Trace visual and failed-state browser e2e",
      "npm run demo:trace-visual"
    )

    assert_blocking_step!(
      fleet["jobs"]["fleet-proxy-e2e"]["steps"],
      "Run hermetic fleet proxy E2E",
      "npm run demo:fleet-proxy"
    )

    canary_condition = fleet["jobs"]["rulestead-main-canary"]["if"]

    assert String.replace(canary_condition, ~r/\s+/, " ") ==
             "${{ github.event_name == 'schedule' || " <>
               "(github.event_name == 'workflow_dispatch' && inputs.run_rulestead_canary) }}"
  end

  test "evaluated concurrency groups isolate PR updates, main runs, and workflows" do
    demo = load_yaml!(@demo_path)
    fleet = load_yaml!(@fleet_path)

    assert_unique_groups!(%{@demo_path => demo, @fleet_path => fleet})

    demo_pr = context(demo["name"], "pull_request", "44", "run-100")
    demo_pr_rerun = context(demo["name"], "pull_request", "44", "run-101")
    demo_other_pr = context(demo["name"], "pull_request", "45", "run-102")
    demo_main = context(demo["name"], "push", nil, "run-200")
    demo_main_next = context(demo["name"], "push", nil, "run-201")
    fleet_pr = context(fleet["name"], "pull_request", "44", "run-100")

    assert group_for!(demo, demo_pr) == group_for!(demo, demo_pr_rerun)
    refute group_for!(demo, demo_pr) == group_for!(demo, demo_other_pr)
    refute group_for!(demo, demo_pr) == group_for!(demo, demo_main)
    refute group_for!(demo, demo_main) == group_for!(demo, demo_main_next)
    refute group_for!(demo, demo_pr) == group_for!(fleet, fleet_pr)

    assert cancel_in_progress?(demo, demo_pr)
    refute cancel_in_progress?(demo, demo_main)
    refute cancel_in_progress?(fleet, context(fleet["name"], "schedule", nil, "run-300"))
  end

  test "workflow mutations reject skipped gates, changed names, canary substitution, and collisions" do
    demo = load_yaml!(@demo_path)
    fleet = load_yaml!(@fleet_path)

    skipped_gate = put_in(demo, ["jobs", "fake-idp-e2e", "if"], false)

    assert_raise ArgumentError, ~r/disabled|required job/, fn ->
      validate_required_workflow!(@demo_path, skipped_gate)
    end

    renamed_fleet = put_in(fleet, ["jobs", "fleet-proxy-e2e", "name"], "optional fleet proof")

    assert_raise ArgumentError, ~r/stable|required job/, fn ->
      validate_required_workflow!(@fleet_path, renamed_fleet)
    end

    canary_substitution = Map.update!(fleet, "jobs", &Map.delete(&1, "fleet-proxy-e2e"))

    assert_raise ArgumentError, ~r/stable|required job/, fn ->
      validate_required_workflow!(@fleet_path, canary_substitution)
    end

    colliding_group =
      "${{ github.event_name }}-${{ github.event.pull_request.number || github.run_id }}"

    colliding_demo = put_in(demo, ["concurrency", "group"], colliding_group)
    colliding_fleet = put_in(fleet, ["concurrency", "group"], colliding_group)

    assert_raise ArgumentError, ~r/colliding concurrency groups/, fn ->
      assert_unique_groups!(%{@demo_path => colliding_demo, @fleet_path => colliding_fleet})
    end
  end

  test "browser workflows use current immutable action releases and matching labels" do
    for {path, expected_pins} <- @action_pins do
      source = File.read!(path)
      assert :ok = validate_action_pins!(path, source, expected_pins)
    end

    source = File.read!(@demo_path)

    mismatched_release =
      String.replace(
        source,
        "actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1",
        "actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.0"
      )

    assert_raise ArgumentError, ~r/verified release pin/, fn ->
      validate_action_pins!(@demo_path, mismatched_release, @action_pins[@demo_path])
    end
  end

  test "browser uploads select only fixed-schema bounded receipts" do
    fleet = load_yaml!(@fleet_path)
    fleet_steps = fleet["jobs"]["fleet-proxy-e2e"]["steps"]
    fleet_upload = Enum.find(fleet_steps, &(&1["name"] == "Upload safe Fleet status"))

    fleet_validate =
      Enum.find(fleet_steps, &(&1["name"] == "Require bounded Fleet status receipt"))

    canary_upload =
      Enum.find(
        fleet["jobs"]["rulestead-main-canary"]["steps"],
        &(&1["name"] == "Upload safe canary status")
      )

    canary_validate =
      Enum.find(
        fleet["jobs"]["rulestead-main-canary"]["steps"],
        &(&1["name"] == "Require bounded canary status receipt")
      )

    assert fleet_upload["with"]["path"] ==
             "${{ runner.temp }}/relyra-fleet-proxy-status.json"

    assert canary_upload["with"]["path"] ==
             "${{ runner.temp }}/relyra-rulestead-canary-status.json"

    for {upload, verify_step, owner, guard_id} <- [
          {fleet_upload, fleet_validate, "fleet-proxy-e2e", "fleet_status_guard"},
          {canary_upload, canary_validate, "rulestead-main-canary", "canary_status_guard"}
        ] do
      assert verify_step["id"] == guard_id
      assert upload["if"] == "${{ always() && steps.#{guard_id}.conclusion == 'success' }}"
      assert upload["with"]["if-no-files-found"] == "error"
      assert upload["with"]["retention-days"] == 3
      assert upload["with"]["name"] =~ "${{ github.job }}"
      assert upload["with"]["name"] =~ "${{ strategy.job-index || 0 }}"
      assert upload["with"]["name"] =~ "${{ github.run_attempt }}"
      assert verify_step["if"] == "always()"
      assert verify_step["run"] =~ "status_bytes > 512"
      assert verify_step["run"] =~ owner
      assert verify_step["run"] =~ "status_missing"
      refute verify_step["run"] =~ "cat \"$"
    end

    refute File.read!(@fleet_path) =~ ~r/playwright-report\/|test-results\//

    demo = load_yaml!(@demo_path)
    demo_steps = demo["jobs"]["fake-idp-e2e"]["steps"]
    trace_upload = Enum.find(demo_steps, &(&1["name"] == "Upload safe trace visual status"))

    trace_validate =
      Enum.find(demo_steps, &(&1["name"] == "Require bounded trace visual status receipt"))

    assert trace_upload["with"]["path"] ==
             "${{ runner.temp }}/relyra-trace-visual-status.json"

    assert trace_upload["with"]["if-no-files-found"] == "error"
    assert trace_upload["with"]["retention-days"] == 3

    assert trace_upload["if"] ==
             "${{ always() && steps.trace_status_guard.conclusion == 'success' }}"

    assert trace_validate["id"] == "trace_status_guard"
    assert trace_validate["run"] =~ "trace_visual_status_missing"
    assert trace_validate["run"] =~ "status_bytes > 512"

    artifact_fixture = temp_dir!("relyra-status-artifact-selection")
    on_exit(fn -> File.rm_rf!(artifact_fixture) end)
    {artifact_dir, _unused_status_path} = status_paths!(artifact_fixture, "fixture.json")
    unexpected_attachment = Path.join(artifact_dir, "unexpected-attachment.zip")
    File.write!(unexpected_attachment, "UNEXPECTED_ATTACHMENT_SENTINEL")

    for upload_path <- [
          fleet_upload["with"]["path"],
          canary_upload["with"]["path"],
          trace_upload["with"]["path"]
        ] do
      selected_path = String.replace(upload_path, "${{ runner.temp }}", artifact_dir)
      File.write!(selected_path, "bounded status fixture")
      assert Path.wildcard(selected_path) == [selected_path]
      refute unexpected_attachment in Path.wildcard(selected_path)
    end
  end

  test "Fleet producer writes a bounded setup receipt and preserves the original failure" do
    temp = temp_dir!("relyra-fleet-status-failure")
    on_exit(fn -> File.rm_rf!(temp) end)
    {runner_temp, status_path} = status_paths!(temp, "relyra-fleet-proxy-status.json")
    bin = Path.join(temp, "bin")
    docker = Path.join(bin, "docker")
    File.mkdir_p!(bin)

    File.write!(
      docker,
      "#!/usr/bin/env bash\nprintf '%s\\n' ASSERTION_SENTINEL CERTIFICATE_SENTINEL PASSWORD_SENTINEL COOKIE_SENTINEL UNEXPECTED_ATTACHMENT_SENTINEL >&2\nexit 42\n"
    )

    File.chmod!(docker, 0o700)

    {output, exit_code} =
      System.cmd("bash", [@fleet_script],
        cd: File.cwd!(),
        env: fleet_test_env(temp, bin, runner_temp, status_path),
        stderr_to_stdout: true
      )

    assert exit_code == 42, output
    status = assert_safe_status!(status_path, "fleet-proxy-e2e")
    assert status["phase"] == "setup"
    assert status["outcome"] == "failed"
    assert status["failure_category"] == "setup"
    assert status["checks_failed"] == 1
    assert status["checks_passed"] == 0
    refute_contains_sentinels!(File.read!(status_path))
  end

  test "Fleet producer emits a bounded cancellation receipt without changing its exit" do
    temp = temp_dir!("relyra-fleet-status-cancel")
    on_exit(fn -> File.rm_rf!(temp) end)
    {runner_temp, status_path} = status_paths!(temp, "relyra-fleet-proxy-status.json")
    bin = Path.join(temp, "bin")
    docker = Path.join(bin, "docker")
    marker = Path.join(temp, "docker-started")
    File.mkdir_p!(bin)

    File.write!(
      docker,
      "#!/usr/bin/env bash\nif [[ ! -e \"$FLEET_FAKE_DOCKER_MARKER\" ]]; then printf '%s\\n' \"$BASHPID\" >\"$FLEET_FAKE_DOCKER_MARKER\"; exec sleep 30; fi\nexit 42\n"
    )

    File.chmod!(docker, 0o700)

    wrapper = """
    bash #{inspect(Path.expand(@fleet_script))} >/dev/null 2>&1 &
    child=$!
    for _attempt in $(seq 1 100); do
      [[ -s "$FLEET_FAKE_DOCKER_MARKER" ]] && break
      sleep 0.05
    done
    if [[ ! -s "$FLEET_FAKE_DOCKER_MARKER" ]]; then
      kill -TERM "$child" 2>/dev/null || true
      wait "$child" 2>/dev/null || true
      exit 90
    fi
    docker_pid="$(cat "$FLEET_FAKE_DOCKER_MARKER")"
    kill -TERM "$child" "$docker_pid" 2>/dev/null || true
    if wait "$child"; then child_status=0; else child_status="$?"; fi
    printf 'CHILD_STATUS=%s\\n' "$child_status"
    """

    {output, exit_code} =
      System.cmd("bash", ["-c", wrapper],
        cd: File.cwd!(),
        env:
          fleet_test_env(temp, bin, runner_temp, status_path) ++
            [{"FLEET_FAKE_DOCKER_MARKER", marker}],
        stderr_to_stdout: true
      )

    assert exit_code == 0, output
    assert output =~ "CHILD_STATUS=143"
    status = assert_safe_status!(status_path, "fleet-proxy-e2e")
    assert status["phase"] == "setup"
    assert status["outcome"] == "cancelled"
    assert status["failure_category"] == "cancelled"
    assert status["checks_failed"] == 1
    refute_contains_sentinels!(File.read!(status_path))
  end

  test "hermetic fixture and harness retain pinned lifecycle assertions" do
    fixture = File.read!("test/integration/fleet-proxy-sibling.compose.yml")
    harness = File.read!("scripts/test_fleet_proxy_e2e.sh")
    browser = File.read!("test/browser/fleet_proxy.spec.mjs")

    assert fixture =~ "traefik/whoami:v1.12.0"
    refute fixture =~ "traefik/whoami:latest"
    assert harness =~ "npx playwright test"
    assert harness =~ "docker volume inspect"
    assert harness =~ "proxy_id_first"
    assert harness =~ "proxy_id_second"
    assert harness =~ "sibling.localhost"
    assert harness =~ "fleet_compose down --remove-orphans"
    assert harness =~ "docker network inspect"
    assert harness =~ "relyra-fleet-solo-$RUN_SUFFIX"
    assert harness =~ "PROXY_OWNED"
    assert harness =~ "NETWORK_CREATED=true"
    assert harness =~ ~s(if [[ "$NETWORK_CREATED" == "true" ]])
    refute harness =~ "logs --no-color"
    refute harness =~ "capture_diagnostics"
    refute harness =~ "playwright-report/"
    assert harness =~ "checks_failed"
    assert harness =~ "byte_count <= 512"
    assert harness =~ "relyra-fleet-proxy-status.json"
    assert harness =~ "trap 'exit 143' TERM"
    assert harness =~ "fleet_compose down --remove-orphans"
    assert browser =~ "liveSockets"
    assert browser =~ "setSelectionRange"
    assert browser =~ "horizontallyAccessible"

    playwright = File.read!(@fleet_playwright_config)
    assert playwright =~ ~s(trace: "off")
    assert playwright =~ ~s(screenshot: "off")
    assert playwright =~ ~s(video: "off")
    assert playwright =~ "retries: 0"
    refute playwright =~ "html"

    trace = File.read!(@trace_script)
    assert trace =~ "checks_failed"
    assert trace =~ "failure_category"
    assert trace =~ "byte_count <= 512"
    assert trace =~ "trace_visual_status_receipt_write_failed"
  end

  test "all required-check consumers stay synchronized" do
    for path <- @required_check_consumers do
      body = File.read!(path)

      for check <- @required_checks do
        assert body =~ check, "#{path} is missing required context #{inspect(check)}"
      end
    end

    {json, 0} =
      System.cmd("bash", ["scripts/setup_branch_protection.sh", "--print-expected-json"])

    for check <- @required_checks do
      assert json =~ check
    end
  end

  defp temp_dir!(prefix) do
    temp = Path.join(System.tmp_dir!(), "#{prefix}-#{System.unique_integer([:positive])}")
    File.mkdir_p!(temp)
    temp
  end

  defp status_paths!(temp, status_name) do
    unresolved_runner_temp = Path.join(temp, "runner-temp")
    File.mkdir_p!(unresolved_runner_temp)

    {runner_temp, 0} = System.cmd("pwd", [], cd: unresolved_runner_temp)
    runner_temp = String.trim(runner_temp)
    {runner_temp, Path.join(runner_temp, status_name)}
  end

  defp fleet_test_env(temp, bin, runner_temp, status_path) do
    path = System.get_env("PATH") || "/usr/bin:/bin"

    [
      {"PATH", "#{bin}:#{path}"},
      {"GITHUB_ACTIONS", "true"},
      {"RUNNER_TEMP", runner_temp},
      {"FLEET_PROXY_STATUS_PATH", status_path},
      {"FLEET_FAKE_DOCKER_MARKER", Path.join(temp, "docker-started")},
      {"ASSERTION_SENTINEL", "ASSERTION_SENTINEL"},
      {"CERTIFICATE_SENTINEL", "CERTIFICATE_SENTINEL"},
      {"PGPASSWORD", "PASSWORD_SENTINEL"},
      {"COOKIE_SENTINEL", "COOKIE_SENTINEL"},
      {"UNEXPECTED_ATTACHMENT_SENTINEL", "UNEXPECTED_ATTACHMENT_SENTINEL"}
    ]
  end

  defp assert_safe_status!(path, owner) do
    status_bytes = File.read!(path)
    assert byte_size(status_bytes) in 1..512

    status = Jason.decode!(status_bytes)

    assert Map.keys(status) |> Enum.sort() ==
             [
               "checks_failed",
               "checks_passed",
               "failure_category",
               "outcome",
               "owner",
               "phase",
               "run_id",
               "schema_version"
             ]

    assert status["schema_version"] == 1
    assert status["owner"] == owner
    assert status["run_id"] =~ ~r/\A[a-f0-9]{16}\z/

    assert status["phase"] in [
             "setup",
             "solo",
             "proxy",
             "fleet",
             "relyra",
             "rulestead",
             "browser",
             "complete"
           ]

    assert status["outcome"] in ["passed", "failed", "cancelled"]
    assert status["failure_category"] in ["none", "setup", "assertion", "timeout", "cancelled"]
    assert status["checks_passed"] in 0..12
    assert status["checks_failed"] in 0..1
    status
  end

  defp refute_contains_sentinels!(status_bytes) do
    refute Enum.any?(@status_sentinels, &String.contains?(status_bytes, &1))
  end

  defp validate_required_workflow!(path, workflow) do
    expected =
      case path do
        @demo_path ->
          {"demo-app-e2e", %{"fake-idp-e2e" => "fake-idp-e2e"},
           ["pull_request", "push", "workflow_dispatch"]}

        @fleet_path ->
          {"fleet-proxy-e2e",
           %{
             "fleet-proxy-e2e" => "fleet-proxy-e2e",
             "rulestead-main-canary" => "rulestead-main-canary"
           }, ["pull_request", "push", "schedule", "workflow_dispatch"]}
      end

    {workflow_name, expected_jobs, expected_events} = expected

    unless workflow["name"] == workflow_name do
      raise ArgumentError, "#{path} changed its stable workflow name"
    end

    unless workflow["permissions"] == %{"contents" => "read"} do
      raise ArgumentError, "#{path} must declare explicit contents: read permissions"
    end

    unless Map.keys(workflow["jobs"] || %{}) |> Enum.sort() ==
             Map.keys(expected_jobs) |> Enum.sort() do
      raise ArgumentError, "#{path} changed its stable required job set"
    end

    events = workflow["on"] || %{}

    unless Enum.sort(Map.keys(events)) == Enum.sort(expected_events) do
      raise ArgumentError, "#{path} changed its stable workflow triggers"
    end

    unless get_in(events, ["push", "branches"]) == ["main"] do
      raise ArgumentError, "#{path} must retain its main push trigger"
    end

    if path == @fleet_path and events["pull_request"] != nil do
      raise ArgumentError, "#{path} must not filter its required pull_request gate"
    end

    if path == @fleet_path and events["push"] != %{"branches" => ["main"]} do
      raise ArgumentError, "#{path} must not filter its required main push gate"
    end

    validate_concurrency!(path, workflow)

    for {job_id, expected_name} <- expected_jobs do
      job = workflow["jobs"][job_id]
      actual_name = Map.get(job, "name", job_id)

      unless actual_name == expected_name do
        raise ArgumentError, "#{path} changed the stable name for required job #{job_id}"
      end

      unless job["runs-on"] == "ubuntu-latest" do
        raise ArgumentError, "#{path} job #{job_id} uses an unsupported runner"
      end

      unless Map.get(job, "permissions", %{}) == %{} do
        raise ArgumentError,
              "#{path} job #{job_id} must not override read-only workflow permissions"
      end

      if job_id != "rulestead-main-canary" and
           (disabled?(job) or Map.has_key?(job, "needs")) do
        raise ArgumentError, "#{path} disabled required job #{job_id}"
      end
    end

    :ok
  end

  defp validate_concurrency!(path, workflow) do
    expected_group =
      "${{ github.workflow }}-${{ github.event_name }}-" <>
        "${{ github.event.pull_request.number || github.run_id }}"

    unless get_in(workflow, ["concurrency", "group"]) == expected_group and
             get_in(workflow, ["concurrency", "cancel-in-progress"]) ==
               "${{ github.event_name == 'pull_request' }}" do
      raise ArgumentError, "#{path} must use isolated event-qualified PR-only cancellation"
    end

    for event_name <- ["pull_request", "push", "schedule", "workflow_dispatch"] do
      pr_number = if event_name == "pull_request", do: "44", else: nil
      context = context(workflow["name"], event_name, pr_number, "run-#{event_name}")

      if cancel_in_progress?(workflow, context) != (event_name == "pull_request") do
        raise ArgumentError, "#{path} must cancel only pull_request concurrency groups"
      end
    end

    :ok
  end

  defp assert_blocking_step!(steps, name, expected_run) do
    case Enum.filter(steps, &(&1["name"] == name)) do
      [%{"run" => actual_run} = step] ->
        unless normalize_script(actual_run) == normalize_script(expected_run) and
                 not disabled?(step) do
          raise ArgumentError, "#{name} must remain an unconditional blocking step"
        end

        :ok

      _ ->
        raise ArgumentError, "expected exactly one blocking browser step named #{name}"
    end
  end

  defp disabled?(value) do
    Map.has_key?(value, "if") or Map.has_key?(value, "continue-on-error")
  end

  defp normalize_script(script) do
    script
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n")
  end

  defp validate_action_pins!(path, source, expected_pins) do
    expected_repositories = MapSet.new(Enum.map(expected_pins, &elem(&1, 0)))

    actual_repositories =
      source
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.filter(&String.starts_with?(&1, "uses: "))
      |> Enum.map(fn line ->
        [repository, _reference] =
          line |> String.replace_prefix("uses: ", "") |> String.split("@", parts: 2)

        repository
      end)
      |> MapSet.new()

    unless actual_repositories == expected_repositories do
      raise ArgumentError, "#{path} contains an unexpected or unverified action reference"
    end

    for {repository, sha, version, count} <- expected_pins do
      expected_line = "uses: #{repository}@#{sha} # #{version}"

      actual_lines =
        source
        |> String.split("\n")
        |> Enum.map(&String.trim/1)
        |> Enum.filter(&String.starts_with?(&1, "uses: #{repository}@"))

      if length(actual_lines) != count or Enum.any?(actual_lines, &(&1 != expected_line)) do
        raise ArgumentError,
              "#{path} must use #{count} verified release pin(s) for #{repository}: #{expected_line}"
      end
    end

    :ok
  end

  defp assert_unique_groups!(workflows) do
    contexts = [
      {"pull_request", "44", "pr-run-a"},
      {"pull_request", "44", "pr-run-b"},
      {"pull_request", "45", "pr-run-c"},
      {"push", nil, "main-run-a"},
      {"push", nil, "main-run-b"},
      {"schedule", nil, "schedule-run"},
      {"workflow_dispatch", nil, "dispatch-run"}
    ]

    evaluated =
      for {_path, workflow} <- workflows,
          {event_name, pr_number, run_id} <- contexts do
        context = context(workflow["name"], event_name, pr_number, run_id)
        group_for!(workflow, context)
      end

    unique = Enum.uniq(evaluated)
    repeated_same_pr = Enum.count(evaluated) == length(unique) + map_size(workflows)

    unless repeated_same_pr do
      raise ArgumentError, "colliding concurrency groups across workflows or events"
    end

    :ok
  end

  defp group_for!(workflow, context) do
    Regex.replace(~r/\$\{\{\s*(.*?)\s*\}\}/, get_in(workflow, ["concurrency", "group"]), fn _,
                                                                                            body ->
      case String.trim(body) do
        "github.workflow" ->
          context.workflow

        "github.event_name" ->
          context.event_name

        "github.event.pull_request.number || github.run_id" ->
          context.pull_request_number || context.run_id

        unsupported ->
          raise ArgumentError, "unsupported concurrency expression: #{unsupported}"
      end
    end)
  end

  defp cancel_in_progress?(workflow, context) do
    case get_in(workflow, ["concurrency", "cancel-in-progress"]) do
      "${{ github.event_name == 'pull_request' }}" -> context.event_name == "pull_request"
      other -> raise ArgumentError, "unsupported cancel-in-progress expression: #{inspect(other)}"
    end
  end

  defp context(workflow, event_name, pull_request_number, run_id) do
    %{
      workflow: workflow,
      event_name: event_name,
      pull_request_number: pull_request_number,
      run_id: run_id
    }
  end

  defp load_yaml!(path) do
    [document] = path |> File.read!() |> String.to_charlist() |> :yamerl_constr.string()
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
