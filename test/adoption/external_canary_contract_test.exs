defmodule Relyra.Adoption.ExternalCanaryContractTest do
  use ExUnit.Case, async: true

  @moduletag :evidence_contract

  alias Relyra.AdoptionEvidence

  @workflow_path ".github/workflows/real-idp-canary.yml"
  @runner_path "scripts/test_real_idp_canary.sh"
  @browser_path "demo/ledger_loop/test/browser/real_idp_canary.spec.ts"
  @playwright_config_path "playwright.real-idp.config.mjs"
  @demo_workflow_path ".github/workflows/demo-app-e2e.yml"
  @keycloak_workflow_path ".github/workflows/keycloak-proxy-e2e.yml"
  @fleet_proxy_workflow_path ".github/workflows/fleet-proxy-e2e.yml"
  @rulestead_canary_runner_path "scripts/test_rulestead_proxy_canary.sh"

  @action_pin_expectations %{
    @keycloak_workflow_path => [
      {"actions/checkout", "3d3c42e5aac5ba805825da76410c181273ba90b1", "v7.0.1", 1},
      {"actions/setup-node", "820762786026740c76f36085b0efc47a31fe5020", "v7.0.0", 1}
    ],
    @workflow_path => [
      {"actions/checkout", "3d3c42e5aac5ba805825da76410c181273ba90b1", "v7.0.1", 1},
      {"actions/setup-node", "820762786026740c76f36085b0efc47a31fe5020", "v7.0.0", 1},
      {"actions/upload-artifact", "043fb46d1a93c77aae656e7c1c64a875d1fc6a0a", "v7.0.1", 1}
    ],
    @fleet_proxy_workflow_path => [
      {"actions/checkout", "3d3c42e5aac5ba805825da76410c181273ba90b1", "v7.0.1", 3},
      {"actions/setup-node", "820762786026740c76f36085b0efc47a31fe5020", "v7.0.0", 1},
      {"actions/upload-artifact", "043fb46d1a93c77aae656e7c1c64a875d1fc6a0a", "v7.0.1", 2}
    ]
  }

  test "EVID-03 has a deterministic mandatory owner and supplemental scheduled signal" do
    entries = AdoptionEvidence.entries()
    [contract] = AdoptionEvidence.deterministic_owners(entries, "EVID-03")
    scheduled = Enum.find(entries, &(&1.id == "evid-03-scheduled-real-idp-canary"))

    assert contract.id == "evid-03-deterministic-canary-contract"
    assert contract.evidence_kind == :security_corpus
    assert contract.owner == "test/adoption/external_canary_contract_test.exs"
    assert contract.selector == "evidence_contract"
    assert contract.lane == "ci.evidence"
    assert contract.state == :existing

    assert scheduled.requirement == "EVID-03"
    assert scheduled.evidence_kind == :external_canary
    assert scheduled.state == :existing
    assert scheduled.owner == @workflow_path
    assert scheduled.lane == "scheduled:real-idp-canary"

    assert :ok = AdoptionEvidence.validate_closure!(entries, ["EVID-03"])

    assert_raise ArgumentError, ~r/EVID-03.*deterministic owner/, fn ->
      AdoptionEvidence.validate_closure!([scheduled], ["EVID-03"])
    end

    assert :ok = AdoptionEvidence.validate_repository!(entries, File.cwd!())
  end

  test "scheduled workflow is independent and uploads only the bounded status artifact" do
    workflow = File.read!(@workflow_path)

    [triggers, _permissions_and_jobs] =
      String.split(workflow, "\npermissions:\n", parts: 2)

    assert triggers =~ "on:\n  schedule:"
    assert triggers =~ "\n  workflow_dispatch:"
    refute workflow =~ ~r/^\s*(pull_request|push):/m
    refute workflow =~ ~r/^\s+needs:/m
    assert workflow =~ ~r/^permissions:\n  contents: read$/m
    assert workflow =~ "environment: real-idp-canary"
    assert workflow =~ "REAL_IDP_CANARY_USERNAME: ${{ secrets.REAL_IDP_CANARY_USERNAME }}"
    assert workflow =~ "REAL_IDP_CANARY_PASSWORD: ${{ secrets.REAL_IDP_CANARY_PASSWORD }}"
    assert workflow =~ "REAL_IDP_CANARY_OWNER: ${{ vars.REAL_IDP_CANARY_OWNER }}"

    assert workflow =~
             "REAL_IDP_CANARY_CREDENTIAL_OWNER: ${{ vars.REAL_IDP_CANARY_CREDENTIAL_OWNER }}"

    assert workflow =~ "REAL_IDP_CANARY_RESPONDER: ${{ vars.REAL_IDP_CANARY_RESPONDER }}"
    assert workflow =~ "REAL_IDP_CANARY_RUNBOOK: ${{ vars.REAL_IDP_CANARY_RUNBOOK }}"

    assert workflow =~ "if: always()"
    assert workflow =~ "path: ${{ runner.temp }}/relyra-real-idp-canary-status.json"
    assert workflow =~ "if-no-files-found: error"
    assert workflow =~ "retention-days: 7"
    refute workflow =~ ~r/^\s+path:.*(?:playwright-report\/|test-results\/|\.zip|\.webm|\.png)/mi

    demo_workflow = File.read!(@demo_workflow_path)
    assert demo_workflow =~ "path: ${{ runner.temp }}/relyra-trace-visual-status.json"

    refute demo_workflow =~
             ~r/^\s+path:.*(?:playwright-report\/|test-results\/|\.zip|\.webm|\.png)/mi
  end

  test "parsed provider workflow stays scheduled, read-only, and separate from required browser jobs" do
    provider = load_yaml!(@workflow_path)
    demo = load_yaml!(@demo_workflow_path)
    keycloak = load_yaml!(@keycloak_workflow_path)

    assert :ok = validate_provider_workflow!(provider)
    assert :ok = validate_deterministic_demo!(demo)
    assert :ok = validate_deterministic_keycloak!(keycloak)

    assert_unique_groups!(%{
      @workflow_path => provider,
      @demo_workflow_path => demo,
      @keycloak_workflow_path => keycloak
    })

    for {path, _expected_pins} <- @action_pin_expectations do
      assert :ok = validate_action_pins!(path, File.read!(path))
    end
  end

  test "Rulestead canary uploads only a fixed safe receipt and preserves its separate owner" do
    workflow = load_yaml!(@fleet_proxy_workflow_path)
    job = workflow["jobs"]["rulestead-main-canary"]
    steps = job["steps"]
    runner = File.read!(@rulestead_canary_runner_path)
    upload = Enum.find(steps, &(&1["name"] == "Upload safe canary status"))
    validation = Enum.find(steps, &(&1["name"] == "Require bounded canary status receipt"))

    assert job["if"] =~ "github.event_name == 'schedule'"
    assert job["if"] =~ "inputs.run_rulestead_canary"

    assert upload["with"]["path"] ==
             "${{ runner.temp }}/relyra-rulestead-canary-status.json"

    assert upload["with"]["if-no-files-found"] == "error"
    assert upload["with"]["retention-days"] == 3

    assert upload["if"] ==
             "${{ always() && steps.canary_status_guard.conclusion == 'success' }}"

    assert upload["with"]["name"] =~ "${{ github.job }}"
    assert upload["with"]["name"] =~ "${{ strategy.job-index || 0 }}"
    assert upload["with"]["name"] =~ "${{ github.run_attempt }}"
    assert validation["run"] =~ "rulestead_canary_status_missing"
    assert validation["run"] =~ "status_bytes > 512"
    assert validation["id"] == "canary_status_guard"

    refute File.read!(@fleet_proxy_workflow_path) =~
             ~r/playwright-report\/|test-results\/|path:\s*\|/

    refute runner =~ "logs --no-color"
    refute runner =~ "capture_diagnostics"
    assert runner =~ "checks_failed"
    assert runner =~ "byte_count <= 512"
    assert runner =~ "trap 'exit 143' TERM"
    assert runner =~ "NETWORK_CREATED=true"

    assert :ok =
             validate_action_pins!(
               @fleet_proxy_workflow_path,
               File.read!(@fleet_proxy_workflow_path)
             )
  end

  test "Rulestead canary success, failure, and setup failure serialize only bounded status fields" do
    temp = temp_dir!("relyra-rulestead-canary-status")
    on_exit(fn -> File.rm_rf!(temp) end)
    {runner_temp, status_path} = status_paths!(temp, "relyra-rulestead-canary-status.json")
    bin = Path.join(temp, "bin")
    rulesstead = Path.join(temp, "rulestead")
    File.mkdir_p!(Path.join(bin, "scripts"))
    File.mkdir_p!(Path.join(rulesstead, "scripts/demo"))

    proxy_up = Path.join(rulesstead, "scripts/demo/proxy-up.sh")
    File.write!(proxy_up, "#!/usr/bin/env bash\nexit 0\n")
    File.chmod!(proxy_up, 0o700)

    write_canary_stubs!(bin)
    canary_env = canary_test_env(temp, bin, runner_temp, status_path, rulesstead)

    {success_output, success_exit} =
      System.cmd("bash", [@rulestead_canary_runner_path],
        cd: File.cwd!(),
        env: canary_env,
        stderr_to_stdout: true
      )

    assert success_exit == 0, success_output
    success = assert_safe_canary_status!(status_path)
    assert success["phase"] == "complete"
    assert success["outcome"] == "passed"
    assert success["failure_category"] == "none"
    assert success["checks_passed"] == 8
    assert_no_sensitive_canary_data!(File.read!(status_path))
    docker_calls = File.read!(Path.join(temp, "docker-calls.log"))
    refute docker_calls =~ ~r/^dev_proxy\|.* down/m
    assert docker_calls =~ "relyra-rulestead-canary-"

    {failure_output, failure_exit} =
      System.cmd("bash", [@rulestead_canary_runner_path],
        cd: File.cwd!(),
        env:
          List.keystore(
            canary_env,
            "CANARY_FAKE_DOCKER_FAIL",
            0,
            {"CANARY_FAKE_DOCKER_FAIL", "1"}
          ),
        stderr_to_stdout: true
      )

    assert failure_exit == 42, failure_output
    failure = assert_safe_canary_status!(status_path)
    assert failure["phase"] == "relyra"
    assert failure["outcome"] == "failed"
    assert failure["failure_category"] == "assertion"
    assert failure["checks_failed"] == 1
    assert_no_sensitive_canary_data!(File.read!(status_path))

    missing_rulesstead = Path.join(temp, "missing-rulestead")

    {setup_output, setup_exit} =
      System.cmd("bash", [@rulestead_canary_runner_path],
        cd: File.cwd!(),
        env: List.keystore(canary_env, "RULESTEAD_DIR", 0, {"RULESTEAD_DIR", missing_rulesstead}),
        stderr_to_stdout: true
      )

    assert setup_exit == 1, setup_output
    setup = assert_safe_canary_status!(status_path)
    assert setup["phase"] == "setup"
    assert setup["outcome"] == "failed"
    assert setup["failure_category"] == "setup"
    assert setup["checks_passed"] == 0
    assert_no_sensitive_canary_data!(File.read!(status_path))
  end

  test "canary and browser gate mutations reject trigger leakage, skips, collisions, and pin mismatches" do
    provider = load_yaml!(@workflow_path)
    demo = load_yaml!(@demo_workflow_path)

    provider_on_pr = put_in(provider, ["on", "pull_request"], %{})

    assert_raise ArgumentError, ~r/scheduled only/, fn ->
      validate_provider_workflow!(provider_on_pr)
    end

    skipped_browser = put_in(demo, ["jobs", "fake-idp-e2e", "if"], false)

    assert_raise ArgumentError, ~r/unconditional|required/, fn ->
      validate_deterministic_demo!(skipped_browser)
    end

    colliding_group =
      "${{ github.workflow }}-${{ github.event.pull_request.number || github.run_id }}"

    colliding_provider = put_in(provider, ["concurrency", "group"], colliding_group)

    assert_raise ArgumentError, ~r/colliding concurrency groups/, fn ->
      assert_unique_groups!(%{
        @workflow_path => colliding_provider,
        @demo_workflow_path => demo,
        @keycloak_workflow_path => load_yaml!(@keycloak_workflow_path)
      })
    end

    mismatched_pin =
      File.read!(@workflow_path)
      |> String.replace(
        "actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1",
        "actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.0"
      )

    assert_raise ArgumentError, ~r/verified release pin/, fn ->
      validate_action_pins!(@workflow_path, mismatched_pin)
    end
  end

  test "origin checks precede credential entry and browser recordings stay disabled" do
    browser = File.read!(@browser_path)
    config = File.read!(@playwright_config_path)
    runner = File.read!(@runner_path)

    assert index(browser, "currentIdpUrl.origin !== idpOrigin") <
             index(browser, ".locator(usernameSelector).fill(username)")

    assert browser =~ "currentIdpUrl.protocol !== \"https:\""
    assert browser =~ "url.origin === spOrigin"
    assert browser =~ "page.locator(\"#workspace-title\")"
    assert browser =~ ~r/status = "(passed|unexpected_origin|idp_rejected|callback_failure)"/

    assert config =~ ~s(trace: "off")
    assert config =~ ~s(screenshot: "off")
    assert config =~ ~s(video: "off")

    assert runner =~ "REAL_IDP_CANARY_SP_LOGIN_URL"
    assert runner =~ "login.origin !== sp.origin"
    assert runner =~ "process.env.REAL_IDP_CANARY_IDP_ORIGIN"
    assert runner =~ "https:"
    assert runner =~ "configuration_incomplete"
    assert runner =~ "relyra-real-idp-canary-status.json"
    refute runner =~ ~r/console\.log|page\.content\(|storageState\(/
  end

  test "contract probe exercises missing config and provider failure without invoking npx" do
    temp =
      Path.join(
        System.tmp_dir!(),
        "relyra-canary-contract-#{System.pid()}-#{System.unique_integer([:positive])}"
      )

    bin = Path.join(temp, "bin")
    runner_temp = Path.join(temp, "runner-temp")
    marker = Path.join(temp, "npx-was-called")
    npx_stub = Path.join(bin, "npx")
    File.mkdir_p!(bin)
    File.mkdir_p!(runner_temp)
    File.write!(npx_stub, "#!/bin/sh\nprintf called > '#{marker}'\nexit 86\n")
    File.chmod!(npx_stub, 0o755)
    on_exit(fn -> File.rm_rf!(temp) end)

    path = System.get_env("PATH") || "/usr/bin:/bin"
    probe_path = "#{bin}:#{path}"

    tool_resolution_env =
      ["ASDF_DATA_DIR", "ASDF_NODEJS_VERSION"]
      |> Enum.flat_map(fn name ->
        case System.get_env(name) do
          nil -> []
          value -> ["#{name}=#{value}"]
        end
      end)

    {syntax_output, syntax_exit} =
      System.cmd("bash", ["-n", @runner_path], cd: File.cwd!(), stderr_to_stdout: true)

    assert syntax_exit == 0, syntax_output

    {output, exit_code} =
      System.cmd(
        "env",
        [
          "-i",
          "PATH=#{probe_path}",
          "HOME=#{System.user_home!()}",
          "RUNNER_TEMP=#{runner_temp}",
          "CANARY_NPX_MARKER=#{marker}"
        ] ++
          tool_resolution_env ++
          [
            "bash",
            @runner_path,
            "--contract-probe"
          ],
        cd: File.cwd!(),
        stderr_to_stdout: true
      )

    assert exit_code == 0, output
    assert output =~ "contract probe passed"
    refute File.exists?(marker)
    refute output =~ ~r/https?:\/\/|password|username|samlrequest|assertion/i
  end

  test "ci.evidence owns the external canary contract in its own fresh test process" do
    mix_file = File.read!("mix.exs")
    [evidence_alias] = Regex.scan(~r/"ci\.evidence": \[(.*?)\n      \]/s, mix_file)

    assert Enum.at(evidence_alias, 1) =~
             "cmd mix test test/adoption/evidence_contract_test.exs test/adoption/external_canary_contract_test.exs test/governance/milestone_scope_test.exs --only evidence_contract --warnings-as-errors"

    assert Enum.count(String.split(Enum.at(evidence_alias, 1), "\n"), fn line ->
             String.contains?(line, "cmd mix test")
           end) == 1
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

  defp write_canary_stubs!(bin) do
    docker = Path.join(bin, "docker")
    curl = Path.join(bin, "curl")
    sleep = Path.join(bin, "sleep")

    File.write!(
      docker,
      """
      #!/usr/bin/env bash
      printf '%s|%s\\n' "${COMPOSE_PROJECT_NAME:-none}" "$*" >>"$CANARY_DOCKER_CALLS"
      printf '%s\\n' ASSERTION_SENTINEL CERTIFICATE_SENTINEL PASSWORD_SENTINEL COOKIE_SENTINEL UNEXPECTED_ATTACHMENT_SENTINEL >&2
      if [[ "${CANARY_FAKE_DOCKER_FAIL:-0}" == "1" && "$*" == *"up -d --build --wait"* ]]; then
        exit 42
      fi
      case "$*" in
        *"ps -q traefik"*) printf '%s\\n' proxy-id ;;
        *"ps -q backend"*) printf '%s\\n' backend-id ;;
        *"ps -q frontend"*) printf '%s\\n' frontend-id ;;
        *"inspect --format {{if .State.Health}}"*) printf '%s\\n' healthy ;;
        *"inspect --format {{.State.Running}}"*) printf '%s\\n' true ;;
      esac
      exit 0
      """
    )

    File.write!(
      curl,
      """
      #!/usr/bin/env bash
      url=""
      for argument in "$@"; do
        case "$argument" in http://*) url="$argument" ;; esac
      done
      case "$url" in
        *fleetdesk*) printf '%s\\n' FleetDesk ;;
        *rulestead*) printf '%s\\n' Rulestead ;;
        *relyra*) printf '%s\\n' "SSO Setup" ;;
      esac
      """
    )

    File.write!(sleep, "#!/usr/bin/env bash\nexit 0\n")
    Enum.each([docker, curl, sleep], &File.chmod!(&1, 0o700))
  end

  defp canary_test_env(temp, bin, runner_temp, status_path, rulesstead) do
    path = System.get_env("PATH") || "/usr/bin:/bin"

    [
      {"PATH", "#{bin}:#{path}"},
      {"GITHUB_ACTIONS", "true"},
      {"RUNNER_TEMP", runner_temp},
      {"RULESTEAD_CANARY_STATUS_PATH", status_path},
      {"RULESTEAD_DIR", rulesstead},
      {"CANARY_DOCKER_CALLS", Path.join(temp, "docker-calls.log")},
      {"CANARY_FAKE_DOCKER_FAIL", "0"},
      {"ASSERTION_SENTINEL", "ASSERTION_SENTINEL"},
      {"CERTIFICATE_SENTINEL", "CERTIFICATE_SENTINEL"},
      {"PGPASSWORD", "PASSWORD_SENTINEL"},
      {"COOKIE_SENTINEL", "COOKIE_SENTINEL"},
      {"UNEXPECTED_ATTACHMENT_SENTINEL", "UNEXPECTED_ATTACHMENT_SENTINEL"}
    ]
  end

  defp assert_safe_canary_status!(path) do
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
    assert status["owner"] == "rulestead-main-canary"
    assert status["run_id"] =~ ~r/\A[a-f0-9]{16}\z/
    assert status["phase"] in ["setup", "proxy", "relyra", "rulestead", "complete"]
    assert status["outcome"] in ["passed", "failed", "cancelled"]
    assert status["failure_category"] in ["none", "setup", "assertion", "timeout", "cancelled"]
    assert status["checks_passed"] in 0..12
    assert status["checks_failed"] in 0..1
    status
  end

  defp assert_no_sensitive_canary_data!(status_bytes) do
    for sentinel <- [
          "ASSERTION_SENTINEL",
          "CERTIFICATE_SENTINEL",
          "PASSWORD_SENTINEL",
          "COOKIE_SENTINEL",
          "UNEXPECTED_ATTACHMENT_SENTINEL"
        ] do
      refute String.contains?(status_bytes, sentinel)
    end
  end

  defp index(source, fragment) do
    case :binary.match(source, fragment) do
      {position, _length} -> position
      :nomatch -> flunk("expected source fragment #{inspect(fragment)}")
    end
  end

  defp validate_provider_workflow!(workflow) do
    unless workflow["name"] == "real-idp-canary" do
      raise ArgumentError, "real provider workflow changed its stable name"
    end

    events = workflow["on"] || %{}

    unless Enum.sort(Map.keys(events)) == ["schedule", "workflow_dispatch"] and
             events["workflow_dispatch"] == nil do
      raise ArgumentError, "real provider canary must remain scheduled only with manual dispatch"
    end

    unless length(events["schedule"] || []) == 1 and
             get_in(events, ["schedule", Access.at(0), "cron"]) == "31 8 * * *" do
      raise ArgumentError, "real provider schedule changed"
    end

    unless workflow["permissions"] == %{"contents" => "read"} do
      raise ArgumentError, "real provider canary must use explicit read-only permissions"
    end

    unless Map.keys(workflow["jobs"] || %{}) == ["real-idp-canary"] do
      raise ArgumentError, "real provider workflow changed its stable job identity"
    end

    job = workflow["jobs"]["real-idp-canary"]

    unless job["name"] == "real-idp-canary" and job["runs-on"] == "ubuntu-latest" and
             Map.get(job, "permissions", %{}) == %{} and not disabled?(job) and
             not Map.has_key?(job, "needs") do
      raise ArgumentError, "real provider canary must keep its blocking scheduled job identity"
    end

    unless Map.has_key?(job["env"] || %{}, "REAL_IDP_CANARY_USERNAME") and
             Map.has_key?(job["env"] || %{}, "REAL_IDP_CANARY_PASSWORD") do
      raise ArgumentError, "real provider credential secret names changed"
    end

    assert_blocking_step!(
      job["steps"],
      "Run scheduled real IdP canary",
      "bash scripts/test_real_idp_canary.sh"
    )

    validate_concurrency!(workflow)
    :ok
  end

  defp validate_deterministic_demo!(workflow) do
    unless workflow["name"] == "demo-app-e2e" and
             Enum.all?(["pull_request", "push"], &Map.has_key?(workflow["on"] || %{}, &1)) do
      raise ArgumentError, "demo browser owner must retain PR and main triggers"
    end

    unless Map.has_key?(workflow["on"] || %{}, "pull_request") and
             get_in(workflow, ["on", "push", "branches"]) == ["main"] and
             workflow["permissions"] == %{"contents" => "read"} do
      raise ArgumentError,
            "demo browser owner must retain main and read-only workflow permissions"
    end

    job = get_in(workflow, ["jobs", "fake-idp-e2e"])

    unless is_map(job) and job["runs-on"] == "ubuntu-latest" and
             Map.get(job, "permissions", %{}) == %{} and not disabled?(job) and
             not Map.has_key?(job, "needs") do
      raise ArgumentError, "demo browser owner must remain an unconditional required job"
    end

    assert_blocking_step!(job["steps"], "FakeIdP browser e2e", "npm run demo:fake-idp")
    validate_concurrency!(workflow)
    :ok
  end

  defp validate_deterministic_keycloak!(workflow) do
    unless workflow["name"] == "keycloak-proxy-e2e" and
             Enum.sort(Map.keys(workflow["on"] || %{})) ==
               ["pull_request", "push", "schedule", "workflow_dispatch"] and
             workflow["on"]["pull_request"] == nil and
             get_in(workflow, ["on", "push"]) == %{"branches" => ["main"]} do
      raise ArgumentError, "owned Keycloak browser owner must retain PR and main triggers"
    end

    unless workflow["permissions"] == %{"contents" => "read"} do
      raise ArgumentError,
            "owned Keycloak browser workflow must use explicit read-only permissions"
    end

    unless Map.keys(workflow["jobs"] || %{}) == ["keycloak-proxy-e2e"] do
      raise ArgumentError, "owned Keycloak browser workflow changed its stable job identity"
    end

    job = get_in(workflow, ["jobs", "keycloak-proxy-e2e"])

    unless is_map(job) and job["name"] == "keycloak-proxy-e2e" and
             job["runs-on"] == "ubuntu-latest" and Map.get(job, "permissions", %{}) == %{} and
             not disabled?(job) and not Map.has_key?(job, "needs") do
      raise ArgumentError, "owned Keycloak browser job must remain unconditional and stable"
    end

    assert_blocking_step!(
      job["steps"],
      "Run public Keycloak proxy E2E",
      "npm run demo:keycloak-proxy"
    )

    validate_concurrency!(workflow)
    :ok
  end

  defp assert_blocking_step!(steps, name, expected_run) do
    case Enum.filter(steps || [], &(&1["name"] == name)) do
      [%{"run" => actual_run} = step] ->
        unless normalize_script(actual_run) == normalize_script(expected_run) and
                 not disabled?(step) do
          raise ArgumentError, "#{name} must remain an unconditional blocking step"
        end

        :ok

      _ ->
        raise ArgumentError, "expected exactly one blocking step named #{name}"
    end
  end

  defp disabled?(job_or_step) do
    Map.has_key?(job_or_step, "if") or Map.has_key?(job_or_step, "continue-on-error")
  end

  defp normalize_script(script) do
    script
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n")
  end

  defp validate_concurrency!(workflow) do
    group =
      "${{ github.workflow }}-${{ github.event_name }}-" <>
        "${{ github.event.pull_request.number || github.run_id }}"

    unless get_in(workflow, ["concurrency", "group"]) == group and
             get_in(workflow, ["concurrency", "cancel-in-progress"]) ==
               "${{ github.event_name == 'pull_request' }}" do
      raise ArgumentError, "#{workflow["name"]} must separate events and cancel only PR runs"
    end

    for event_name <- ["pull_request", "push", "schedule", "workflow_dispatch"] do
      pr_number = if event_name == "pull_request", do: "44", else: nil
      event_context = context(workflow["name"], event_name, pr_number, "run-#{event_name}")

      unless cancel_in_progress?(workflow, event_context) == (event_name == "pull_request") do
        raise ArgumentError, "#{workflow["name"]} must cancel only pull_request events"
      end
    end

    :ok
  end

  defp assert_unique_groups!(workflows) do
    contexts = [
      {"pull_request", "44", "pr-44"},
      {"push", nil, "main-100"},
      {"push", nil, "main-101"},
      {"schedule", nil, "shared-run"},
      {"workflow_dispatch", nil, "shared-run"}
    ]

    evaluated =
      for {_path, workflow} <- workflows,
          {event_name, pr_number, run_id} <- contexts do
        context = context(workflow["name"], event_name, pr_number, run_id)
        group_for!(workflow, context)
      end

    if length(Enum.uniq(evaluated)) != length(evaluated) do
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

  defp validate_action_pins!(path, source) do
    expected_pins = @action_pin_expectations[path]
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
