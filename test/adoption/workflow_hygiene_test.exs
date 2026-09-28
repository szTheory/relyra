defmodule Relyra.Adoption.WorkflowHygieneTest do
  use ExUnit.Case, async: true

  @workflow_paths [
    ".github/workflows/security-gates.yml",
    ".github/workflows/demo-app-ci.yml",
    ".github/workflows/adoption-external-idp.yml",
    ".github/workflows/planning-pr-checks.yml",
    ".github/workflows/release-please-pr-checks.yml",
    ".github/workflows/release-please.yml"
  ]

  @workflow_names %{
    ".github/workflows/security-gates.yml" => "security-gates",
    ".github/workflows/demo-app-ci.yml" => "demo-app-ci",
    ".github/workflows/adoption-external-idp.yml" => "adoption-external-idp",
    ".github/workflows/planning-pr-checks.yml" => "Planning PR Checks",
    ".github/workflows/release-please-pr-checks.yml" => "Release Please PR Checks",
    ".github/workflows/release-please.yml" => "Release Please"
  }

  @job_contracts %{
    ".github/workflows/security-gates.yml" => %{"security" => nil},
    ".github/workflows/demo-app-ci.yml" => %{"demo-app" => nil},
    ".github/workflows/adoption-external-idp.yml" => %{"keycloak" => nil},
    ".github/workflows/planning-pr-checks.yml" => %{
      "trigger-planning-pr-checks" => "Trigger security-gates on planning PR"
    },
    ".github/workflows/release-please-pr-checks.yml" => %{
      "trigger-release-pr-checks" => "Trigger security-gates on release-please PR"
    },
    ".github/workflows/release-please.yml" => %{
      "release-please" => "Release Please",
      "publish-hex" => "Publish to Hex.pm"
    }
  }

  @job_permissions %{
    ".github/workflows/security-gates.yml" => %{},
    ".github/workflows/demo-app-ci.yml" => %{},
    ".github/workflows/adoption-external-idp.yml" => %{},
    ".github/workflows/planning-pr-checks.yml" => %{
      "trigger-planning-pr-checks" => %{
        "contents" => "write",
        "checks" => "read",
        "pull-requests" => "read"
      }
    },
    ".github/workflows/release-please-pr-checks.yml" => %{
      "trigger-release-pr-checks" => %{"actions" => "write"}
    },
    ".github/workflows/release-please.yml" => %{
      "release-please" => %{
        "contents" => "write",
        "issues" => "write",
        "pull-requests" => "write"
      },
      "publish-hex" => %{"contents" => "read"}
    }
  }

  @action_pin_expectations %{
    ".github/workflows/security-gates.yml" => [
      {"actions/checkout", "3d3c42e5aac5ba805825da76410c181273ba90b1", "v7.0.1", 1},
      {"actions/setup-node", "820762786026740c76f36085b0efc47a31fe5020", "v7.0.0", 1},
      {"erlef/setup-beam", "54075bcc5e249e4758d363f27d099f55d843f124", "v1.24.1", 1}
    ],
    ".github/workflows/demo-app-ci.yml" => [
      {"actions/checkout", "3d3c42e5aac5ba805825da76410c181273ba90b1", "v7.0.1", 1},
      {"erlef/setup-beam", "54075bcc5e249e4758d363f27d099f55d843f124", "v1.24.1", 1}
    ],
    ".github/workflows/adoption-external-idp.yml" => [
      {"actions/checkout", "3d3c42e5aac5ba805825da76410c181273ba90b1", "v7.0.1", 1},
      {"erlef/setup-beam", "54075bcc5e249e4758d363f27d099f55d843f124", "v1.24.1", 1}
    ],
    ".github/workflows/release-please.yml" => [
      {"actions/checkout", "3d3c42e5aac5ba805825da76410c181273ba90b1", "v7.0.1", 2},
      {"actions/cache", "55cc8345863c7cc4c66a329aec7e433d2d1c52a9", "v6.1.0", 1},
      {"erlef/setup-beam", "54075bcc5e249e4758d363f27d099f55d843f124", "v1.24.1", 1},
      {"googleapis/release-please-action", "5c625bfb5d1ff62eadeeb3772007f7f66fdcf071", "v4.4.1",
       1}
    ]
  }

  @standalone_gate_name "GATE-02 binary gate (gate02_c14n zero regressions)"
  @standalone_gate_command "mix test --only gate02_c14n --warnings-as-errors"

  test "workflow identities, read defaults, job permissions, and hosted runners stay explicit" do
    workflows = load_workflows!()

    Enum.each(@workflow_paths, fn path ->
      assert :ok = validate_workflow!(path, workflows[path])
    end)

    assert :ok = assert_unique_concurrency_groups!(workflows)
  end

  test "concurrency groups isolate workflow, PR, main, and rerun identities" do
    workflows = load_workflows!()
    security = workflows[".github/workflows/security-gates.yml"]
    security_name = security["name"]

    first_pr = context(security_name, "pull_request", "44", "run-100")
    repeated_pr = context(security_name, "pull_request", "44", "run-101")
    other_pr = context(security_name, "pull_request", "45", "run-102")
    main_one = context(security_name, "push", nil, "run-200")
    main_two = context(security_name, "push", nil, "run-201")
    another_workflow_pr = context("demo-app-ci", "pull_request", "44", "run-100")

    assert group_for!(security, first_pr) == group_for!(security, repeated_pr)
    refute group_for!(security, first_pr) == group_for!(security, other_pr)
    refute group_for!(security, first_pr) == group_for!(security, main_one)
    refute group_for!(security, main_one) == group_for!(security, main_two)

    demo = workflows[".github/workflows/demo-app-ci.yml"]
    refute group_for!(security, first_pr) == group_for!(demo, another_workflow_pr)

    assert cancel_in_progress?(security, first_pr)
    refute cancel_in_progress?(security, main_one)

    refute cancel_in_progress?(
             security,
             context(security_name, "workflow_dispatch", nil, "run-202")
           )
  end

  test "permission mutations reject broad defaults, missing scoped writes, and disabled jobs" do
    workflows = load_workflows!()
    security_path = ".github/workflows/security-gates.yml"
    security = workflows[security_path]

    assert_raise ArgumentError, ~r/explicit contents: read/, fn ->
      validate_workflow!(security_path, Map.delete(security, "permissions"))
    end

    widened_test_job =
      put_in(security, ["jobs", "security", "permissions"], %{"contents" => "write"})

    assert_raise ArgumentError, ~r/permissions/, fn ->
      validate_workflow!(security_path, widened_test_job)
    end

    planning_path = ".github/workflows/planning-pr-checks.yml"
    planning = workflows[planning_path]

    missing_scoped_write =
      put_in(planning, ["jobs", "trigger-planning-pr-checks", "permissions"], %{
        "checks" => "read",
        "pull-requests" => "read"
      })

    assert_raise ArgumentError, ~r/permissions/, fn ->
      validate_workflow!(planning_path, missing_scoped_write)
    end

    disabled_job = put_in(security, ["jobs", "security", "if"], false)

    assert_raise ArgumentError, ~r/disabled job/, fn ->
      validate_workflow!(security_path, disabled_job)
    end
  end

  test "concurrency mutations reject PR-to-main cancellation and cross-workflow collisions" do
    workflows = load_workflows!()
    security_path = ".github/workflows/security-gates.yml"
    demo_path = ".github/workflows/demo-app-ci.yml"
    security = workflows[security_path]
    demo = workflows[demo_path]

    always_cancel = put_in(security, ["concurrency", "cancel-in-progress"], true)

    assert_raise ArgumentError, ~r/cancel only pull_request/, fn ->
      validate_workflow!(security_path, always_cancel)
    end

    colliding_group =
      "${{ github.event_name }}-${{ github.event.pull_request.number || github.run_id }}"

    colliding_security = put_in(security, ["concurrency", "group"], colliding_group)
    colliding_demo = put_in(demo, ["concurrency", "group"], colliding_group)

    assert_raise ArgumentError, ~r/colliding concurrency groups/, fn ->
      assert_unique_concurrency_groups!(%{
        security_path => colliding_security,
        demo_path => colliding_demo
      })
    end
  end

  test "required consumer, evidence, security, standalone gate, and Keycloak steps remain blocking" do
    workflows = load_workflows!()
    security = workflows[".github/workflows/security-gates.yml"]
    security_steps = security["jobs"]["security"]["steps"]

    assert_blocking_step!(security_steps, "Evidence contract", "mix ci.evidence")

    assert_blocking_step!(
      security_steps,
      "Package consumer contracts",
      "scripts/check_clean_room_consumer.sh --profile full\nscripts/check_clean_room_consumer.sh --profile minimal --concurrency-check\nscripts/check_clean_room_consumer.sh --profile contracts"
    )

    assert_blocking_step!(security_steps, "Security lane", "mix ci.security")
    assert_blocking_step!(security_steps, @standalone_gate_name, @standalone_gate_command)

    adoption = workflows[".github/workflows/adoption-external-idp.yml"]

    assert_blocking_step!(
      adoption["jobs"]["keycloak"]["steps"],
      "External IdP adoption lane",
      "mix ci.external_idp"
    )
  end

  test "action references use the rechecked immutable releases and matching release labels" do
    Enum.each(@action_pin_expectations, fn {path, _expected_pins} ->
      source = File.read!(path)
      assert :ok = validate_action_pins!(path, source)
    end)

    Enum.each(@workflow_paths, fn path ->
      assert :ok = validate_runners!(path, load_yaml!(path))
    end)
  end

  test "action pin comments, mutable references, and unsupported runners fail closed" do
    path = ".github/workflows/security-gates.yml"
    source = File.read!(path)
    checkout_sha = "3d3c42e5aac5ba805825da76410c181273ba90b1"

    mutable_reference =
      String.replace(
        source,
        "actions/checkout@#{checkout_sha} # v7.0.1",
        "actions/checkout@v7.0.1"
      )

    assert_raise ArgumentError, ~r/verified release pin/, fn ->
      validate_action_pins!(path, mutable_reference)
    end

    mismatched_label =
      String.replace(
        source,
        "actions/checkout@#{checkout_sha} # v7.0.1",
        "actions/checkout@#{checkout_sha} # v7.0.0"
      )

    assert_raise ArgumentError, ~r/verified release pin/, fn ->
      validate_action_pins!(path, mismatched_label)
    end

    workflow = load_yaml!(path)
    unsupported_runner = put_in(workflow, ["jobs", "security", "runs-on"], "self-hosted")

    assert_raise ArgumentError, ~r/unsupported runner/, fn ->
      validate_runners!(path, unsupported_runner)
    end
  end

  defp load_workflows! do
    Map.new(@workflow_paths, &{&1, load_yaml!(&1)})
  end

  defp load_yaml!(path) do
    path
    |> File.read!()
    |> parse_yaml!()
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

  defp validate_workflow!(path, workflow) do
    if workflow["name"] != @workflow_names[path] do
      raise ArgumentError, "#{path} changed its stable workflow name"
    end

    if workflow["permissions"] != %{"contents" => "read"} do
      raise ArgumentError, "#{path} must declare an explicit contents: read permission default"
    end

    jobs = workflow["jobs"] || %{}
    expected_jobs = @job_contracts[path]

    if Map.keys(jobs) |> Enum.sort() != Map.keys(expected_jobs) |> Enum.sort() do
      raise ArgumentError, "#{path} changed its stable job identities"
    end

    for {job_id, job} <- jobs do
      if Map.get(job, "name") != expected_jobs[job_id] do
        raise ArgumentError, "#{path} changed the display name for job #{job_id}"
      end

      if disabled_job?(job) do
        raise ArgumentError, "#{path} contains a disabled job #{job_id}"
      end
    end

    validate_job_permissions!(path, jobs)
    validate_runners!(path, workflow)
    validate_concurrency!(path, workflow)
    :ok
  end

  defp validate_job_permissions!(path, jobs) do
    expected = @job_permissions[path]

    for {job_id, job} <- jobs do
      actual = Map.get(job, "permissions", %{})
      expected_job_permissions = Map.get(expected, job_id, %{})

      if actual != expected_job_permissions do
        raise ArgumentError,
              "#{path} job #{job_id} permissions #{inspect(actual)} do not match least-privilege contract " <>
                "#{inspect(expected_job_permissions)}"
      end
    end

    :ok
  end

  defp disabled_job?(job) do
    case Map.get(job, "if") do
      false -> true
      value when is_binary(value) -> String.trim(value) in ["false", "${{ false }}"]
      _ -> false
    end
  end

  defp validate_runners!(path, workflow) do
    for {job_id, job} <- workflow["jobs"] || %{} do
      unless Map.get(job, "runs-on") == "ubuntu-latest" do
        raise ArgumentError,
              "#{path} job #{job_id} uses unsupported runner #{inspect(Map.get(job, "runs-on"))}; " <>
                "the pinned Node 24 actions require a maintained GitHub-hosted runner"
      end
    end

    :ok
  end

  defp validate_concurrency!(path, workflow) do
    concurrency = workflow["concurrency"] || %{}
    group = Map.get(concurrency, "group")

    unless is_binary(group) do
      raise ArgumentError, "#{path} must declare a concurrency group"
    end

    for {event_name, pr_number, run_id} <- [
          {"pull_request", "44", "run-100"},
          {"push", nil, "run-200"},
          {"workflow_dispatch", nil, "run-300"},
          {"workflow_run", nil, "run-400"}
        ] do
      context = context(workflow["name"], event_name, pr_number, run_id)
      _evaluated_group = group_for!(workflow, context)
      expected_cancel = event_name == "pull_request"

      unless cancel_in_progress?(workflow, context) == expected_cancel do
        raise ArgumentError,
              "#{path} must cancel only pull_request concurrency groups"
      end
    end

    :ok
  end

  defp context(workflow, event_name, pull_request_number, run_id) do
    %{
      workflow: workflow,
      event_name: event_name,
      pull_request_number: pull_request_number,
      run_id: run_id
    }
  end

  defp group_for!(workflow, context) do
    expression = get_in(workflow, ["concurrency", "group"])

    Regex.replace(~r/\$\{\{\s*(.*?)\s*\}\}/, expression, fn _match, body ->
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
      value when is_boolean(value) -> value
      "${{ github.event_name == 'pull_request' }}" -> context.event_name == "pull_request"
      other -> raise ArgumentError, "unsupported cancel-in-progress expression: #{inspect(other)}"
    end
  end

  defp assert_unique_concurrency_groups!(workflows) do
    evaluated_groups =
      for {path, workflow} <- workflows,
          {event_name, pr_number, run_id} <- [
            {"pull_request", "44", "pr-#{path}"},
            {"pull_request", "45", "pr-45-#{path}"},
            {"push", nil, "push-#{path}"},
            {"workflow_dispatch", nil, "dispatch-#{path}"},
            {"workflow_run", nil, "workflow-run-#{path}"}
          ] do
        context = context(workflow["name"], event_name, pr_number, run_id)
        group_for!(workflow, context)
      end

    if length(Enum.uniq(evaluated_groups)) != length(evaluated_groups) do
      raise ArgumentError,
            "colliding concurrency groups across workflows or events: #{inspect(evaluated_groups)}"
    end

    :ok
  end

  defp assert_blocking_step!(steps, name, expected_run) do
    case Enum.filter(steps, &(&1["name"] == name)) do
      [%{"run" => actual_run} = step] ->
        unless normalize_script(actual_run) == normalize_script(expected_run) and
                 not Map.has_key?(step, "if") and
                 not Map.get(step, "continue-on-error", false) do
          raise ArgumentError, "#{name} must remain an unconditional blocking step"
        end

        :ok

      _ ->
        raise ArgumentError, "expected exactly one blocking workflow step named #{name}"
    end
  end

  defp normalize_script(script) do
    script
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n")
  end

  defp validate_action_pins!(path, source) do
    expected = @action_pin_expectations[path] || []

    for {repository, sha, version, count} <- expected do
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
end
