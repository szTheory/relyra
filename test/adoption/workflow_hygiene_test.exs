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
    ".github/workflows/security-gates.yml" => %{
      "security" => nil,
      "phase73-reconciliation" => nil,
      "package-consumers" => nil,
      "ci-gate" => "ci-gate",
      "phase78-cold-producer" => "Phase 78 cold producer (OTP ${{ matrix.otp }})",
      "phase78-clean-state" => "Phase 78 cold-state receipt"
    },
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
    ".github/workflows/security-gates.yml" => %{
      "phase73-reconciliation" => %{"contents" => "read"},
      "package-consumers" => %{"contents" => "read"},
      "ci-gate" => %{"contents" => "read"},
      "phase78-cold-producer" => %{"contents" => "read"},
      "phase78-clean-state" => %{"contents" => "read"}
    },
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
      {"actions/checkout", "3d3c42e5aac5ba805825da76410c181273ba90b1", "v7.0.1", 5},
      {"actions/setup-node", "820762786026740c76f36085b0efc47a31fe5020", "v7.0.0", 2},
      {"erlef/setup-beam", "54075bcc5e249e4758d363f27d099f55d843f124", "v1.24.1", 5},
      {"actions/upload-artifact", "043fb46d1a93c77aae656e7c1c64a875d1fc6a0a", "v7.0.1", 2},
      {"actions/download-artifact", "3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c", "v8.0.1", 1},
      {"actions/cache/restore", "55cc8345863c7cc4c66a329aec7e433d2d1c52a9", "v6.1.0", 2},
      {"actions/cache/save", "55cc8345863c7cc4c66a329aec7e433d2d1c52a9", "v6.1.0", 2}
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
      {"googleapis/release-please-action", "45996ed1f6d02564a971a2fa1b5860e934307cf7", "v5.0.0",
       1}
    ]
  }

  # ci-gate is the single required check. It must need every PR-path job in
  # security-gates.yml; only the Phase 78 cold path (skipped on ordinary PRs)
  # stays outside it.
  @security_gates_path ".github/workflows/security-gates.yml"
  @ci_gate_job "ci-gate"
  @ci_gate_needs ["security", "phase73-reconciliation", "package-consumers"]
  @ci_gate_exempt_jobs ["phase78-cold-producer", "phase78-clean-state"]
  @ci_gate_max_timeout 10

  # Warm Mix caches are allowed only where SEED-004 item 5 measured a win. The
  # clean-room consumers, the Phase 78 cold path and ci-gate never touch a cache.
  @warm_cache_jobs ["security", "phase73-reconciliation"]
  @warm_cache_paths ["deps", "_build", "demo/ledger_loop/deps", "demo/ledger_loop/_build"]
  @warm_cache_save_if "github.event_name == 'push' && github.ref == 'refs/heads/main' && steps.mix-cache.outputs.cache-hit != 'true'"
  @warm_cache_key_parts [
    "${{ runner.os }}",
    "${{ github.job }}",
    "${{ matrix.otp }}",
    "${{ matrix.elixir }}",
    "'mix.lock'",
    "'mix.exs'",
    "'config/**'",
    "'demo/ledger_loop/mix.lock'",
    "'demo/ledger_loop/mix.exs'",
    "'demo/ledger_loop/config/**'"
  ]

  @standalone_gate_name "GATE-02 binary gate (gate02_c14n zero regressions)"
  @standalone_gate_command "mix test --only gate02_c14n --warnings-as-errors"

  @gsd_tools_home_path ~r{/(?:Users|home)/[^/\s"'`]+/[^\s"'`]*gsd-tools(?:\.cjs)?}

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

    assert_blocking_step!(security_steps, "Quality gate", "mix qa")
    assert_blocking_step!(security_steps, "Evidence contract", "mix ci.evidence")

    assert_blocking_step!(
      security["jobs"]["package-consumers"]["steps"],
      "Package consumer contracts",
      "scripts/check_clean_room_consumer.sh --profile full\nscripts/check_clean_room_consumer.sh --profile minimal --concurrency-check\nscripts/check_clean_room_consumer.sh --profile contracts"
    )

    assert_blocking_step!(
      security["jobs"]["phase73-reconciliation"]["steps"],
      "Phase 73 reconciliation",
      "mix ci.phase73.reconciliation"
    )

    assert_blocking_step!(security_steps, "Security lane", "mix ci.security")
    assert_blocking_step!(security_steps, @standalone_gate_name, @standalone_gate_command)

    for job_id <- @ci_gate_needs do
      job = security["jobs"][job_id]

      refute Map.has_key?(job, "needs"),
             "#{job_id} must start immediately, not after another lane"

      refute Map.has_key?(job, "if"), "#{job_id} must run on every security-gates event"
      refute Map.get(job, "continue-on-error", false)
      assert job["strategy"]["fail-fast"] == false
      assert job["strategy"]["matrix"] == %{"otp" => [27, 28], "elixir" => ["1.19.5"]}
    end

    for job_id <- ["security", "phase73-reconciliation"] do
      steps = security["jobs"][job_id]["steps"]
      checkout = Enum.find(steps, &(&1["name"] == "Checkout"))
      assert checkout["with"]["fetch-depth"] == 0, "#{job_id} needs full git history"
      assert security["jobs"][job_id]["services"]["postgres"]["image"] == "postgres:16"

      assert_blocking_step!(
        steps,
        "Prepare demo test metadata",
        "mix cmd --cd demo/ledger_loop mix deps.get\nmix cmd --cd demo/ledger_loop mix compile"
      )
    end

    adoption = workflows[".github/workflows/adoption-external-idp.yml"]

    assert_blocking_step!(
      adoption["jobs"]["keycloak"]["steps"],
      "External IdP adoption lane",
      "mix ci.external_idp"
    )
  end

  test "warm Mix caches are exact-key, restore-only on PRs, and absent from cold lanes" do
    workflow = load_yaml!(@security_gates_path)

    assert :ok = validate_warm_caches!(workflow)
  end

  test "warm cache mutations reject fallback keys, PR saves, and cold or consumer caches" do
    workflow = load_yaml!(@security_gates_path)

    update_cache_step = fn job_id, name, update ->
      update_in(workflow, ["jobs", job_id, "steps"], fn steps ->
        Enum.map(steps, fn
          %{"name" => ^name} = step -> update.(step)
          step -> step
        end)
      end)
    end

    restore = "Restore Mix build cache"
    save = "Save Mix build cache"

    [restore_step] =
      Enum.filter(workflow["jobs"]["security"]["steps"], &(&1["name"] == restore))

    mutations = [
      {:restore_keys,
       update_cache_step.("security", restore, &put_in(&1, ["with", "restore-keys"], "Linux-")),
       ~r/restore-keys/},
      {:no_toolchain,
       update_cache_step.("phase73-reconciliation", restore, fn step ->
         update_in(step, ["with", "key"], &String.replace(&1, "${{ matrix.otp }}", "27"))
       end), ~r/key/},
      {:no_lockfile,
       update_cache_step.("security", restore, fn step ->
         update_in(step, ["with", "key"], &String.replace(&1, "'mix.lock', ", ""))
       end), ~r/key/},
      {:combined_cache,
       update_cache_step.("security", restore, fn step ->
         Map.put(step, "uses", String.replace(step["uses"], "cache/restore@", "cache@"))
       end), ~r/actions\/cache/},
      {:pr_save, update_cache_step.("security", save, &Map.delete(&1, "if")), ~r/save/},
      {:always_save, update_cache_step.("security", save, &Map.put(&1, "if", "always()")),
       ~r/save/},
      {:other_key, update_cache_step.("security", save, &put_in(&1, ["with", "key"], "fixture")),
       ~r/save/},
      {:fallible_restore,
       update_cache_step.("security", restore, &Map.put(&1, "continue-on-error", true)),
       ~r/conditional|fallible/},
      {:extra_path,
       update_cache_step.("security", restore, fn step ->
         update_in(step, ["with", "path"], &(&1 <> "\n~/.mix"))
       end), ~r/path/},
      {:consumer_cache,
       update_in(workflow, ["jobs", "package-consumers", "steps"], &[restore_step | &1]),
       ~r/package-consumers/},
      {:cold_cache,
       update_in(workflow, ["jobs", "phase78-cold-producer", "steps"], &[restore_step | &1]),
       ~r/phase78-cold-producer/},
      {:receipt_cache,
       update_in(workflow, ["jobs", "phase78-clean-state", "steps"], &[restore_step | &1]),
       ~r/phase78-clean-state/},
      {:missing_save,
       update_in(workflow, ["jobs", "phase73-reconciliation", "steps"], fn steps ->
         Enum.reject(steps, &(&1["name"] == save))
       end), ~r/save/},
      {:save_before_lanes,
       update_in(workflow, ["jobs", "security", "steps"], fn steps ->
         {[save_step], rest} = Enum.split_with(steps, &(&1["name"] == save))
         [hd(rest), save_step | tl(rest)]
       end), ~r/last step/}
    ]

    for {label, mutated, message} <- mutations do
      result =
        try do
          validate_warm_caches!(mutated)
        rescue
          error in ArgumentError -> Exception.message(error)
        end

      assert is_binary(result) and result =~ message,
             "warm cache mutation #{label} was not rejected as expected: #{inspect(result)}"
    end
  end

  test "ci-gate aggregates every PR lane and accepts only success" do
    workflow = load_yaml!(@security_gates_path)

    assert :ok = validate_ci_gate!(workflow)
    assert :ok = validate_job_timeouts!(@security_gates_path, workflow)
    assert workflow["jobs"][@ci_gate_job]["needs"] == @ci_gate_needs
  end

  test "ci-gate mutations reject missing needs, skipped-as-success, and lost always()" do
    workflow = load_yaml!(@security_gates_path)
    gate_path = ["jobs", @ci_gate_job]
    [step] = get_in(workflow, gate_path ++ ["steps"])

    update_step = fn update ->
      put_in(workflow, gate_path ++ ["steps"], [update.(step)])
    end

    mutations = [
      {:missing_need,
       update_in(workflow, gate_path ++ ["needs"], &List.delete(&1, "phase73-reconciliation")),
       ~r/needs/},
      {:missing_consumer_need,
       update_in(workflow, gate_path ++ ["needs"], &List.delete(&1, "package-consumers")),
       ~r/needs/},
      {:scalar_need, put_in(workflow, gate_path ++ ["needs"], "security"), ~r/needs/},
      {:gates_cold_path,
       update_in(workflow, gate_path ++ ["needs"], &(&1 ++ ["phase78-clean-state"])), ~r/needs/},
      {:ungated_new_lane,
       put_in(workflow, ["jobs", "new-lane"], workflow["jobs"]["package-consumers"]), ~r/needs/},
      {:no_always, update_in(workflow, gate_path, &Map.delete(&1, "if")), ~r/if: always\(\)/},
      {:success_only, put_in(workflow, gate_path ++ ["if"], "success()"), ~r/if: always\(\)/},
      {:negated_always, put_in(workflow, gate_path ++ ["if"], "!always()"), ~r/if: always\(\)/},
      {:renamed, put_in(workflow, gate_path ++ ["name"], "required"), ~r/name/},
      {:fallible_job, put_in(workflow, gate_path ++ ["continue-on-error"], true),
       ~r/continue-on-error/},
      {:no_timeout, update_in(workflow, gate_path, &Map.delete(&1, "timeout-minutes")),
       ~r/timeout/},
      {:fallible_step, update_step.(&Map.put(&1, "continue-on-error", true)), ~r/step/},
      {:conditional_step, update_step.(&Map.put(&1, "if", "always()")), ~r/step/},
      {:skipped_is_success,
       update_step.(fn step ->
         Map.update!(step, "run", fn run ->
           String.replace(
             run,
             ~s(if [[ "$result" != "success" ]]; then),
             ~s(if [[ "$result" != "success" && "$result" != "skipped" ]]; then)
           )
         end)
       end), ~r/skipped|success/},
      {:any_result_passes,
       update_step.(fn step ->
         Map.update!(step, "run", &String.replace(&1, ~s(!= "success"), ~s(== "failure")))
       end), ~r/success/},
      {:lane_dropped_from_loop,
       update_step.(fn step ->
         Map.update!(step, "run", &String.replace(&1, " PACKAGE_CONSUMERS_RESULT; do", "; do"))
       end), ~r/lane|result/},
      {:result_rebound,
       update_step.(fn step ->
         put_in(step, ["env", "PHASE73_RECONCILIATION_RESULT"], "${{ needs.security.result }}")
       end), ~r/result/},
      {:needs_json_unchecked,
       update_step.(fn step ->
         Map.update!(step, "run", &String.replace(&1, "length == 3 and ", ""))
       end), ~r/toJSON|needs context/},
      {:never_fails,
       update_step.(fn step ->
         Map.update!(step, "run", &String.replace(&1, "exit 1", "exit 0"))
       end), ~r/exit 1/}
    ]

    for {name, mutated, diagnostic} <- mutations do
      error = assert_raise ArgumentError, fn -> validate_ci_gate!(mutated) end

      assert Exception.message(error) =~ diagnostic,
             "#{name} raised an unexpected diagnostic: #{Exception.message(error)}"
    end

    no_lane_timeout =
      update_in(workflow, ["jobs", "phase73-reconciliation"], &Map.delete(&1, "timeout-minutes"))

    assert_raise ArgumentError, ~r/timeout-minutes/, fn ->
      validate_job_timeouts!(@security_gates_path, no_lane_timeout)
    end

    unbounded_timeout = put_in(workflow, ["jobs", "security", "timeout-minutes"], 0)

    assert_raise ArgumentError, ~r/timeout-minutes/, fn ->
      validate_job_timeouts!(@security_gates_path, unbounded_timeout)
    end
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

    release_path = ".github/workflows/release-please.yml"
    release_source = File.read!(release_path)

    current_release_pin =
      "uses: googleapis/release-please-action@45996ed1f6d02564a971a2fa1b5860e934307cf7 # v5.0.0"

    former_release_pin =
      String.replace(
        release_source,
        current_release_pin,
        "uses: googleapis/release-please-action@5c625bfb5d1ff62eadeeb3772007f7f66fdcf071 # v4.4.1"
      )

    assert_raise ArgumentError, ~r/verified release pin/, fn ->
      validate_action_pins!(release_path, former_release_pin)
    end

    mutable_release_reference =
      String.replace(
        release_source,
        current_release_pin,
        "uses: googleapis/release-please-action@v5.0.0"
      )

    assert_raise ArgumentError, ~r/verified release pin/, fn ->
      validate_action_pins!(release_path, mutable_release_reference)
    end

    mismatched_release_label =
      String.replace(
        release_source,
        current_release_pin,
        "uses: googleapis/release-please-action@45996ed1f6d02564a971a2fa1b5860e934307cf7 # v4.4.1"
      )

    assert_raise ArgumentError, ~r/verified release pin/, fn ->
      validate_action_pins!(release_path, mismatched_release_label)
    end
  end

  @tag :gsd_tools_portability
  test "tracked scripts and tests never hardcode a developer home path to gsd-tools" do
    planted_cjs = "/" <> "Users" <> "/someone/.codex/gsd-core/bin/gsd-tools.cjs"
    planted_bare = "/" <> "home" <> "/someone/.claude/gsd-core/bin/gsd-tools"
    relative = ".codex/gsd-core/bin/" <> "gsd-tools.cjs"

    assert Regex.match?(@gsd_tools_home_path, planted_cjs)
    assert Regex.match?(@gsd_tools_home_path, planted_bare)
    refute Regex.match?(@gsd_tools_home_path, relative)

    {listing, 0} = System.cmd("git", ["ls-files", "-z", "--", "scripts", "test"])

    hits =
      listing
      |> String.split(<<0>>, trim: true)
      |> Enum.filter(&File.regular?/1)
      |> Enum.flat_map(fn path ->
        content = File.read!(path)

        if String.valid?(content) do
          content
          |> String.split("\n")
          |> Enum.with_index(1)
          |> Enum.filter(fn {line, _number} -> Regex.match?(@gsd_tools_home_path, line) end)
          |> Enum.map(fn {_line, number} -> {path, number} end)
        else
          []
        end
      end)

    assert hits == [],
           "tracked scripts/tests hardcode a developer home path to gsd-tools: #{inspect(hits)}"
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

  defp validate_warm_caches!(workflow) do
    jobs = workflow["jobs"]

    for {job_id, job} <- jobs, job_id not in @warm_cache_jobs do
      if Enum.any?(job["steps"] || [], &String.starts_with?(&1["uses"] || "", "actions/cache")) do
        raise ArgumentError, "#{job_id} must not restore or save any cache"
      end
    end

    for job_id <- @warm_cache_jobs do
      steps = jobs[job_id]["steps"]

      if Enum.any?(steps, &String.starts_with?(&1["uses"] || "", "actions/cache@")) do
        raise ArgumentError, "#{job_id} must split actions/cache into restore and save"
      end

      restore = only_step!(steps, job_id, "Restore Mix build cache")
      save = only_step!(steps, job_id, "Save Mix build cache")

      for step <- [restore, save] do
        if Map.has_key?(step, "continue-on-error"),
          do: raise(ArgumentError, "#{job_id} cache steps must not be fallible")
      end

      unless String.starts_with?(restore["uses"], "actions/cache/restore@") and
               restore["id"] == "mix-cache" and not Map.has_key?(restore, "if") do
        raise ArgumentError, "#{job_id} restore must be unconditional with id mix-cache"
      end

      if Map.has_key?(restore["with"], "restore-keys") do
        raise ArgumentError, "#{job_id} cache must not use restore-keys fallbacks"
      end

      for step <- [restore, save] do
        paths = step["with"]["path"] |> String.split("\n", trim: true) |> Enum.map(&String.trim/1)

        if paths != @warm_cache_paths,
          do:
            raise(
              ArgumentError,
              "#{job_id} cache path must be exactly #{inspect(@warm_cache_paths)}"
            )
      end

      key = restore["with"]["key"]

      unless Enum.all?(@warm_cache_key_parts, &String.contains?(key, &1)) do
        raise ArgumentError, "#{job_id} cache key must bind OS, job, toolchain and lockfiles"
      end

      unless String.starts_with?(save["uses"], "actions/cache/save@") and
               save["if"] == @warm_cache_save_if and
               save["with"]["key"] == "${{ steps.mix-cache.outputs.cache-primary-key }}" do
        raise ArgumentError,
              "#{job_id} must save only on successful main pushes, under the restored key"
      end

      if List.last(steps) != save do
        raise ArgumentError, "#{job_id} must save the cache as its last step"
      end
    end

    :ok
  end

  defp only_step!(steps, job_id, name) do
    case Enum.filter(steps, &(&1["name"] == name)) do
      [step] -> step
      _ -> raise ArgumentError, "#{job_id} must have exactly one #{name} step (save/restore)"
    end
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

  defp validate_ci_gate!(workflow) do
    jobs = workflow["jobs"] || %{}
    gate = jobs[@ci_gate_job] || raise(ArgumentError, "security-gates.yml lost its ci-gate job")

    pr_jobs =
      jobs
      |> Map.keys()
      |> Kernel.--([@ci_gate_job | @ci_gate_exempt_jobs])
      |> Enum.sort()

    unless gate["name"] == @ci_gate_job do
      raise ArgumentError, "ci-gate must keep its stable display name ci-gate"
    end

    unless gate["if"] == "always()" do
      raise ArgumentError, "ci-gate must declare exactly if: always() so it reports every outcome"
    end

    needs = gate["needs"]

    unless is_list(needs) and needs == @ci_gate_needs and Enum.sort(needs) == pr_jobs do
      raise ArgumentError,
            "ci-gate needs #{inspect(needs)} must be exactly every PR job #{inspect(pr_jobs)} " <>
              "(pinned #{inspect(@ci_gate_needs)})"
    end

    if Map.get(gate, "continue-on-error", false) != false do
      raise ArgumentError, "ci-gate must not set continue-on-error"
    end

    timeout = gate["timeout-minutes"]

    unless is_integer(timeout) and timeout > 0 and timeout <= @ci_gate_max_timeout do
      raise ArgumentError, "ci-gate needs a small positive timeout-minutes"
    end

    unless gate["permissions"] == %{"contents" => "read"} and gate["runs-on"] == "ubuntu-latest" do
      raise ArgumentError, "ci-gate must run on ubuntu-latest with contents: read"
    end

    step =
      case gate["steps"] do
        [step] -> step
        _ -> raise ArgumentError, "ci-gate must own exactly one verification step"
      end

    if Map.has_key?(step, "if") or Map.get(step, "continue-on-error", false) != false do
      raise ArgumentError, "ci-gate verification step must be unconditional and blocking"
    end

    env = step["env"] || %{}
    run = step["run"] || ""

    lanes =
      Enum.map(@ci_gate_needs, fn job_id ->
        var = (job_id |> String.upcase() |> String.replace("-", "_")) <> "_RESULT"

        unless env[var] == "${{ needs.#{job_id}.result }}" do
          raise ArgumentError, "ci-gate must bind #{var} to the #{job_id} job result"
        end

        var
      end)

    unless env["NEEDS_JSON"] == "${{ toJSON(needs) }}" and
             run =~
               ~s|jq -e 'length == #{length(@ci_gate_needs)} and all(.[]; .result == "success")'| do
      raise ArgumentError, "ci-gate must check the whole toJSON(needs) needs context for success"
    end

    unless run =~ "for lane in #{Enum.join(lanes, " ")}; do" and
             run =~ ~s(result="${!lane}") and
             run =~ ~s(if [[ "$result" != "success" ]]; then) do
      raise ArgumentError, "ci-gate must reject every lane result other than exactly success"
    end

    if run =~ "skipped" or run =~ "cancelled" do
      raise ArgumentError, "ci-gate must never accept a skipped or cancelled lane as success"
    end

    unless run =~ "set -euo pipefail" and run =~ "exit 1" and not (run =~ "exit 0") do
      raise ArgumentError, "ci-gate must exit 1 when any lane did not succeed"
    end

    :ok
  end

  defp validate_job_timeouts!(path, workflow) do
    for {job_id, job} <- workflow["jobs"] || %{} do
      timeout = Map.get(job, "timeout-minutes")

      unless is_integer(timeout) and timeout > 0 and timeout <= 180 do
        raise ArgumentError, "#{path} job #{job_id} must declare a bounded timeout-minutes"
      end
    end

    :ok
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
