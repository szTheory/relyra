defmodule Relyra.Phase78CleanStateReceiptContract do
  @moduledoc false

  @receipt_schema "phase78-clean-state-receipt"
  @receipt_rel ".planning/phases/78-ci-efficiency-and-reliability/78-CLEAN-STATE-RECEIPT.json"
  @phase73_proof ".planning/phases/73-twin-contract-and-baseline/73-RECONCILIATION-PROOF.json"
  @manifest [
    {"mix format --check-formatted", "none"},
    {"mix compile --warnings-as-errors", "none"},
    {"mix test --warnings-as-errors", "tests"},
    {"mix qa", "tests"},
    {"mix ci.security", "tests"},
    {"mix ci.evidence", "tests"},
    {"mix ci.phase73.reconciliation", "tests"},
    {"mix ci.verify", "tests"},
    {"mix ci.integration", "tests"},
    {"scripts/check_clean_room_consumer.sh --profile full", "checks"},
    {"scripts/check_clean_room_consumer.sh --profile minimal --concurrency-check", "checks"},
    {"scripts/check_clean_room_consumer.sh --profile contracts", "checks"},
    {"mix ci.demo_app", "tests"},
    {"mix cmd --cd demo/ledger_loop mix test --warnings-as-errors", "tests"},
    {"npm ci", "none"},
    {"npm run admin-ui:smoke", "journeys"},
    {"npm run demo:fake-idp", "journeys"},
    {"npm run demo:trace-visual", "journeys"},
    {"npm run demo:fleet-proxy", "journeys"},
    {"npm run demo:keycloak-proxy", "journeys"},
    {"bash scripts/test_trace_visual_status_contract.sh", "checks"},
    {"actionlint .github/workflows/*.yml", "none"}
  ]
  @receipt_keys ~w(generated_at outcome phase73 runs schema source_commit source_digest source_file_count version)
  @run_keys ~w(architecture commands completed_at elixir_version os os_release outcome otp_release phase73 run_id runner_identity_sha256 setup source_commit source_digest started_at workspace_id)
  @result_keys ~w(argv completed_at duration_ms exit_code name output_bytes output_sha256 started_at)
  @setup_names [
    "mix local.hex --force",
    "mix local.rebar --force",
    "mix deps.get --check-locked",
    "owned PostgreSQL service",
    "owned PostgreSQL readiness",
    "LedgerLoop test metadata",
    "verified toolchain",
    "npx playwright install chromium"
  ]

  def manifest, do: @manifest
  def receipt_rel, do: @receipt_rel

  def validate_shape!(receipt) when is_map(receipt) do
    exact_keys!(receipt, @receipt_keys, "receipt")

    require!(
      receipt["schema"] == @receipt_schema and receipt["version"] == 1,
      "receipt schema is unsupported"
    )

    require!(receipt["outcome"] == "passed", "receipt did not pass")
    require!(valid_git_id?(receipt["source_commit"]), "receipt source commit is invalid")
    require!(valid_hash?(receipt["source_digest"]), "receipt source digest is invalid")

    require!(
      is_integer(receipt["source_file_count"]) and receipt["source_file_count"] > 0,
      "source manifest is empty"
    )

    valid_timestamp!(receipt["generated_at"], "receipt generated_at")

    proof = receipt["phase73"]
    exact_keys!(proof, ~w(proof_set_id proof_sha256 source_digest), "Phase 73 proof identity")
    require!(valid_hash?(proof["source_digest"]), "Phase 73 source digest is invalid")

    require!(
      Regex.match?(~r/^phase73-[0-9a-f]{16}$/, proof["proof_set_id"] || ""),
      "Phase 73 proof identity is invalid"
    )

    require!(valid_hash?(proof["proof_sha256"]), "Phase 73 proof digest is invalid")

    runs = receipt["runs"]
    require!(is_list(runs) and length(runs) == 2, "receipt must contain both supported OTP runs")

    require!(
      Enum.map(runs, & &1["otp_release"]) == ["27", "28"],
      "receipt must include OTP 27 then OTP 28"
    )

    require!(
      Enum.uniq(Enum.map(runs, & &1["workspace_id"])) == Enum.map(runs, & &1["workspace_id"]),
      "workspace identities are shared"
    )

    require!(
      Enum.uniq(Enum.map(runs, & &1["run_id"])) == Enum.map(runs, & &1["run_id"]),
      "run identities are shared"
    )

    require!(
      Enum.uniq(Enum.map(runs, & &1["runner_identity_sha256"])) ==
        Enum.map(runs, & &1["runner_identity_sha256"]),
      "runner identities are shared"
    )

    Enum.each(runs, &validate_run!(&1, receipt))
    :ok
  end

  def validate_shape!(_receipt), do: raise(ArgumentError, "receipt must be a JSON object")

  def validate_repository!(root, receipt_path \\ nil) do
    root = Path.expand(root)
    receipt_path = receipt_path || Path.join(root, @receipt_rel)
    require!(File.stat!(receipt_path).size <= 131_072, "receipt exceeds its total byte bound")
    receipt = receipt_path |> File.read!() |> Jason.decode!()
    :ok = validate_shape!(receipt)

    expected_digest =
      root
      |> source_digest!()

    require!(receipt["source_digest"] == expected_digest.digest, "receipt source is stale")

    require!(
      receipt["source_file_count"] == expected_digest.count,
      "receipt source file count is stale"
    )

    head = git!(root, ["rev-parse", "HEAD"])
    require!(valid_git_id?(head), "checkout HEAD is invalid")

    if tracked?(root, @receipt_rel) do
      require!(
        git_status(root, ["merge-base", "--is-ancestor", receipt["source_commit"], head]) == 0,
        "source commit is not an ancestor of the receipt commit"
      )
    else
      require!(
        receipt["source_commit"] == head,
        "uncommitted receipt is not bound to the current source commit"
      )
    end

    require!(
      receipt["source_commit"] == git!(root, ["rev-parse", receipt["source_commit"]]),
      "receipt source commit is absent"
    )

    proof_path = Path.join(root, @phase73_proof)
    proof_bytes = File.read!(proof_path)
    proof = Jason.decode!(proof_bytes)

    require!(
      receipt["phase73"]["proof_sha256"] == sha256(proof_bytes),
      "Phase 73 proof bytes are stale"
    )

    require!(
      receipt["phase73"]["proof_set_id"] == proof["proof_set_id"],
      "Phase 73 proof identity is stale"
    )

    require!(
      receipt["phase73"]["source_digest"] == proof["source_digest"],
      "Phase 73 source digest is stale"
    )

    :ok = Relyra.Phase73Reconciliation.validate_repository!(root)
    :ok
  rescue
    error in [ArgumentError, Jason.DecodeError, File.Error] ->
      reraise error, __STACKTRACE__
  end

  defp validate_run!(run, receipt) do
    exact_keys!(run, @run_keys, "toolchain run")
    require!(run["outcome"] == "passed", "toolchain run failed")
    require!(run["otp_release"] in ["27", "28"], "unsupported OTP version")
    require!(run["elixir_version"] == "1.19.5", "unsupported Elixir version")
    require!(valid_git_id?(run["source_commit"]), "run source commit is invalid")

    require!(
      run["source_commit"] == receipt["source_commit"],
      "toolchain runs use different source commits"
    )

    require!(
      run["source_digest"] == receipt["source_digest"],
      "toolchain runs use different source digests"
    )

    require!(run["phase73"] == receipt["phase73"], "toolchain runs use different Phase 73 proofs")
    require!(Regex.match?(~r/^[a-f0-9]{16}$/, run["run_id"] || ""), "run ID is invalid")

    require!(
      Regex.match?(~r/^[a-f0-9]{16}$/, run["workspace_id"] || ""),
      "workspace ID is invalid"
    )

    require!(valid_hash?(run["runner_identity_sha256"]), "runner identity is invalid")
    require!(run["os"] in ["Darwin", "Linux"], "runner operating system is missing")

    require!(
      is_binary(run["architecture"]) and run["architecture"] != "",
      "runner architecture is missing"
    )

    require!(
      timestamp_ordered?(run["started_at"], run["completed_at"]),
      "run timestamps are out of order"
    )

    setup = run["setup"]
    require!(is_list(setup), "setup receipt is missing")
    names = Enum.map(setup, & &1["name"])
    require!(Enum.all?(@setup_names, &(&1 in names)), "required cold setup result is missing")
    Enum.each(setup, &validate_result!(&1, "setup"))

    commands = run["commands"]

    require!(
      is_list(commands) and length(commands) == length(@manifest),
      "clean-state manifest is incomplete"
    )

    require!(
      Enum.map(commands, & &1["name"]) == Enum.map(@manifest, &elem(&1, 0)),
      "clean-state command inventory changed"
    )

    Enum.zip(commands, @manifest)
    |> Enum.each(fn {result, {name, kind}} -> validate_command!(result, name, kind) end)

    encoded = Jason.encode!(run)
    refute_sensitive_bytes!(encoded)
  end

  defp validate_command!(result, expected_name, expected_kind) do
    exact_keys!(result, @result_keys ++ ~w(evidence_count evidence_kind), "manifest command")
    require!(result["name"] == expected_name, "manifest command name changed")
    require!(result["evidence_kind"] == expected_kind, "manifest command evidence type changed")
    validate_result!(result, "manifest command")

    case expected_kind do
      "none" ->
        require!(is_nil(result["evidence_count"]), "non-test command has an execution count")

      _ ->
        require!(
          is_integer(result["evidence_count"]) and result["evidence_count"] > 0,
          "command selected zero tests or journeys"
        )
    end
  end

  defp validate_result!(result, label) do
    require!(is_map(result), "#{label} result is missing")

    exact_keys!(
      result,
      @result_keys ++
        if(Map.has_key?(result, "evidence_kind"), do: ~w(evidence_count evidence_kind), else: []),
      label
    )

    require!(is_list(result["argv"]) and result["argv"] != [], "#{label} argv is missing")
    require!(result["exit_code"] == 0, "#{label} has a failing process exit")

    require!(
      is_integer(result["duration_ms"]) and result["duration_ms"] >= 0,
      "#{label} duration is invalid"
    )

    require!(
      is_integer(result["output_bytes"]) and result["output_bytes"] >= 0 and
        result["output_bytes"] <= 16_777_216,
      "#{label} output exceeded its byte bound"
    )

    require!(valid_hash?(result["output_sha256"]), "#{label} output digest is invalid")

    require!(
      timestamp_ordered?(result["started_at"], result["completed_at"]),
      "#{label} timestamps are out of order"
    )
  end

  defp source_digest!(root) do
    script = Path.join(root, "scripts/check_phase78_clean_state.sh")
    {output, 0} = System.cmd("bash", [script, "--source-digest", root])
    [digest, count] = String.split(String.trim(output), "\n")
    %{digest: digest, count: String.to_integer(count)}
  end

  defp refute_sensitive_bytes!(encoded) do
    require!(
      !String.contains?(encoded, "-----BEGIN CERTIFICATE-----"),
      "receipt contains certificate bytes"
    )

    require!(
      !String.contains?(encoded, "Basic dXNlcjpwYXNz"),
      "receipt contains Basic credentials"
    )

    require!(
      !String.contains?(encoded, "phase78-cookie-sentinel"),
      "receipt contains cookie bytes"
    )

    require!(
      !String.contains?(encoded, "phase78-password-sentinel"),
      "receipt contains password bytes"
    )

    require!(!String.contains?(encoded, "raw_output"), "receipt contains raw command output")
    :ok
  end

  defp exact_keys!(map, keys, label) do
    require!(
      is_map(map) and Enum.sort(Map.keys(map)) == Enum.sort(keys),
      "#{label} keys are not the closed schema"
    )
  end

  defp valid_timestamp?(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, _datetime, 0} -> true
      _ -> false
    end
  end

  defp valid_timestamp?(_value), do: false

  defp timestamp_ordered?(started, completed) do
    with true <- valid_timestamp?(started),
         true <- valid_timestamp?(completed),
         {:ok, start_time, 0} <- DateTime.from_iso8601(started),
         {:ok, end_time, 0} <- DateTime.from_iso8601(completed) do
      DateTime.compare(start_time, end_time) in [:lt, :eq]
    else
      _ -> false
    end
  end

  defp valid_timestamp!(value, label),
    do: require!(valid_timestamp?(value), "#{label} must be UTC ISO-8601")

  defp valid_hash?(value), do: is_binary(value) and Regex.match?(~r/^[a-f0-9]{64}$/, value)
  defp valid_git_id?(value), do: is_binary(value) and Regex.match?(~r/^[a-f0-9]{40}$/, value)
  defp require!(true, _message), do: :ok
  defp require!(false, message), do: raise(ArgumentError, message)
  defp sha256(binary), do: :crypto.hash(:sha256, binary) |> Base.encode16(case: :lower)

  defp tracked?(root, path) do
    git_status(root, ["ls-files", "--error-unmatch", path]) == 0
  end

  defp git!(root, args) do
    {output, 0} = System.cmd("git", ["-C", root | args], stderr_to_stdout: true)
    String.trim(output)
  end

  defp git_status(root, args) do
    {_output, status} = System.cmd("git", ["-C", root | args], stderr_to_stdout: true)
    status
  end
end

defmodule Relyra.Adoption.Phase78CleanStateContractTest do
  use ExUnit.Case, async: false

  alias Relyra.Phase78CleanStateReceiptContract, as: Receipt

  @tag :phase78_clean_state_schema
  test "the closed schema requires the complete manifest, setup, and distinct OTP identities" do
    assert :ok = Receipt.validate_shape!(valid_receipt())
    assert length(Receipt.manifest()) == 22

    for {field, value} <- [
          {"unexpected", true},
          {"outcome", "failed"},
          {"source_digest", "stale"}
        ] do
      assert_raise ArgumentError, fn ->
        Receipt.validate_shape!(Map.put(valid_receipt(), field, value))
      end
    end
  end

  test "failure propagation, missing setup, zero execution, and unsupported OTP cannot pass" do
    receipt = valid_receipt()
    [first | rest] = receipt["runs"]
    failed = put_in(receipt, ["runs", Access.at(0), "commands", Access.at(0), "exit_code"], 42)
    zero = put_in(receipt, ["runs", Access.at(0), "commands", Access.at(2), "evidence_count"], 0)
    unsupported = put_in(receipt, ["runs", Access.at(0), "otp_release"], "26")
    missing_setup = update_in(first["setup"], &List.delete_at(&1, 0))
    missing_setup_receipt = put_in(receipt, ["runs", Access.at(0), "setup"], missing_setup)

    assert_raise ArgumentError, fn -> Receipt.validate_shape!(failed) end
    assert_raise ArgumentError, fn -> Receipt.validate_shape!(zero) end
    assert_raise ArgumentError, fn -> Receipt.validate_shape!(unsupported) end
    assert_raise ArgumentError, fn -> Receipt.validate_shape!(missing_setup_receipt) end

    output =
      Path.join(
        System.tmp_dir!(),
        "phase78-unsupported-#{System.unique_integer([:positive])}.json"
      )

    script = Path.expand("scripts/check_phase78_clean_state.sh")

    {_output, 64} =
      System.cmd("bash", [script, "--otp", "26", "--output", output], stderr_to_stdout: true)

    refute File.exists?(output)

    assert length(rest) == 1
  end

  test "the operational source digest covers tracked project files except generated receipts and summaries" do
    root = fixture_repository!()
    on_exit(fn -> File.rm_rf!(root) end)
    before = source_digest!(root)

    included = [
      ".github/workflows/security-gates.yml",
      "scripts/check_phase78_clean_state.sh",
      "mix.exs",
      "test/adoption/contract.exs",
      "lib/relyra.ex",
      "playwright.config.mjs",
      "demo/app.ex",
      ".planning/phases/73-twin-contract-and-baseline/73-RECONCILIATION-PROOF.json",
      ".planning/phases/73-twin-contract-and-baseline/73-SECURITY.md",
      ".planning/phases/73-twin-contract-and-baseline/73-VALIDATION.md",
      ".planning/STATE.md",
      ".planning/ROADMAP.md",
      ".planning/phases/78-fixture/78-01-PLAN.md"
    ]

    for path <- included do
      File.write!(Path.join(root, path), "changed: #{path}\n")
      assert source_digest!(root) != before, "manifest omitted #{path}"
      File.write!(Path.join(root, path), "fixture: #{path}\n")
    end

    File.write!(
      Path.join(root, ".planning/phases/78-fixture/78-01-SUMMARY.md"),
      "new task summary\n"
    )

    File.write!(Path.join(root, Receipt.receipt_rel()), "generated receipt\n")
    assert source_digest!(root) == before
  end

  test "cold producer bounds captured logs without limiting command file writes" do
    producer = File.read!("scripts/check_phase78_clean_state.sh")

    assert producer =~ "readonly MAX_OUTPUT_BYTES=16777216"
    assert producer =~ "run_bounded_command()"
    assert producer =~ "observed > limit"
    refute producer =~ "ulimit -f"
    assert producer =~ ~s(export DOCKER_CONFIG="$run_root/home/.docker")
    assert producer =~ "cli-plugins/docker-compose"
    assert producer =~ "docker compose version"
  end

  test "the assembler requires matching frozen sources and produces one ordered OTP receipt" do
    root = Path.join(System.tmp_dir!(), "phase78-assembly-#{System.unique_integer([:positive])}")
    File.mkdir_p!(root)
    on_exit(fn -> File.rm_rf!(root) end)
    receipt = valid_receipt()
    [run27, run28] = receipt["runs"]
    path27 = Path.join(root, "otp27.json")
    path28 = Path.join(root, "otp28.json")
    output = Path.join(root, "combined.json")
    write_partial!(path27, receipt, run27)
    write_partial!(path28, receipt, run28)
    script = Path.expand("scripts/check_phase78_clean_state.sh")

    {_, 0} = System.cmd("bash", [script, "--assemble", path27, path28, "--output", output])
    combined = output |> File.read!() |> Jason.decode!()
    assert :ok = Receipt.validate_shape!(combined)
    assert Enum.map(combined["runs"], & &1["otp_release"]) == ["27", "28"]

    stale = put_in(receipt, ["source_digest"], String.duplicate("f", 64))
    write_partial!(path28, stale, run28)
    mismatch = Path.join(root, "mismatch.json")

    {_output, exit_code} =
      System.cmd("bash", [script, "--assemble", path27, path28, "--output", mismatch],
        stderr_to_stdout: true
      )

    assert exit_code != 0
    refute File.exists?(mismatch)
  end

  test "the receipt schema stores output digests only and rejects raw output fields" do
    receipt = valid_receipt()
    encoded = Jason.encode!(receipt)
    refute encoded =~ "-----BEGIN CERTIFICATE-----"
    refute encoded =~ "Basic dXNlcjpwYXNz"
    refute encoded =~ "phase78-cookie-sentinel"
    assert encoded =~ "output_sha256"

    leaked =
      put_in(
        receipt,
        ["runs", Access.at(0), "commands", Access.at(0), "raw_output"],
        "phase78-password-sentinel"
      )

    assert_raise ArgumentError, fn -> Receipt.validate_shape!(leaked) end
  end

  test "only the dedicated receipt owner selects the real receipt test after producers" do
    aliases = Mix.Project.config()[:aliases]

    assert Keyword.fetch!(aliases, :"ci.phase78.receipt") == [
             "cmd mix test test/adoption/phase78_clean_state_contract_test.exs --only phase78_clean_state_receipt --warnings-as-errors"
           ]

    for {name, steps} <- aliases, name != :"ci.phase78.receipt" do
      refute inspect(steps) =~ "phase78_clean_state_receipt"
    end

    assert File.read!("test/test_helper.exs") =~ ":phase78_clean_state_receipt"
    workflow = ".github/workflows/security-gates.yml" |> File.read!() |> parse_yaml!()
    assert Map.has_key?(workflow["on"], "pull_request")
    assert Map.has_key?(workflow["on"], "push")

    job = workflow["jobs"]["phase78-clean-state"]
    assert job["needs"] == "security"
    assert job["if"] == "always()"
    steps = job["steps"]
    [otp27] = Enum.filter(steps, &(&1["name"] == "Run OTP 27 cold manifest"))
    [otp28] = Enum.filter(steps, &(&1["name"] == "Run OTP 28 cold manifest"))
    [assemble] = Enum.filter(steps, &(&1["name"] == "Assemble source-bound receipt"))
    [owner] = Enum.filter(steps, &(&1["name"] == "Require Phase 78 cold-state receipt"))
    assert otp27["if"] == "always()"
    assert otp28["if"] == "always()"
    assert assemble["if"] == "always()"
    assert owner["if"] == "always()"
    assert owner["run"] =~ "mix ci.phase78.receipt"
    assert Enum.find_index(steps, &(&1 == assemble)) < Enum.find_index(steps, &(&1 == owner))
  end

  @tag :phase78_clean_state_receipt
  @tag timeout: :infinity
  test "the real mandatory selector accepts only a current source and proof receipt" do
    assert :ok = Receipt.validate_repository!(File.cwd!())
  end

  defp valid_receipt do
    digest = String.duplicate("a", 64)

    proof = %{
      "source_digest" => digest,
      "proof_set_id" => "phase73-0123456789abcdef",
      "proof_sha256" => String.duplicate("b", 64)
    }

    runs =
      for otp <- ["27", "28"] do
        commands =
          Enum.map(Receipt.manifest(), fn {name, kind} ->
            count = if kind == "none", do: nil, else: 2
            result(name, kind, count)
          end)

        %{
          "run_id" => if(otp == "27", do: "0123456789abcdef", else: "fedcba9876543210"),
          "workspace_id" => if(otp == "27", do: "0123456789abcdef", else: "fedcba9876543210"),
          "runner_identity_sha256" => String.duplicate(if(otp == "27", do: "c", else: "d"), 64),
          "os" => "Linux",
          "os_release" => "test-kernel",
          "architecture" => "x86_64",
          "elixir_version" => "1.19.5",
          "otp_release" => otp,
          "source_commit" => String.duplicate("1", 40),
          "source_digest" => digest,
          "phase73" => proof,
          "started_at" => "2026-09-28T00:00:00Z",
          "completed_at" => "2026-09-28T00:01:00Z",
          "outcome" => "passed",
          "setup" => Enum.map(setup_names(), &result(&1, "setup", nil)),
          "commands" => commands
        }
      end

    %{
      "schema" => "phase78-clean-state-receipt",
      "version" => 1,
      "source_commit" => String.duplicate("1", 40),
      "source_digest" => digest,
      "source_file_count" => 200,
      "phase73" => proof,
      "generated_at" => "2026-09-28T00:02:00Z",
      "outcome" => "passed",
      "runs" => runs
    }
  end

  defp setup_names do
    [
      "mix local.hex --force",
      "mix local.rebar --force",
      "mix deps.get --check-locked",
      "owned PostgreSQL service",
      "owned PostgreSQL readiness",
      "LedgerLoop test metadata",
      "verified toolchain",
      "npx playwright install chromium"
    ]
  end

  defp result(name, kind, count) do
    result = %{
      "name" => name,
      "argv" => ["bash", "-c", name],
      "started_at" => "2026-09-28T00:00:00Z",
      "completed_at" => "2026-09-28T00:00:01Z",
      "duration_ms" => 1,
      "exit_code" => 0,
      "output_bytes" => 20,
      "output_sha256" => String.duplicate("e", 64)
    }

    if kind == "setup",
      do: result,
      else: Map.merge(result, %{"evidence_kind" => kind, "evidence_count" => count})
  end

  defp write_partial!(path, receipt, run) do
    partial = %{
      "schema" => "phase78-clean-state-run",
      "version" => 1,
      "source_commit" => receipt["source_commit"],
      "source_digest" => receipt["source_digest"],
      "source_file_count" => receipt["source_file_count"],
      "phase73" => receipt["phase73"],
      "generated_at" => receipt["generated_at"],
      "outcome" => run["outcome"],
      "runs" => [run]
    }

    File.write!(path, Jason.encode!(partial))
  end

  defp source_digest!(root) do
    script = Path.expand("scripts/check_phase78_clean_state.sh")
    {output, 0} = System.cmd("bash", [script, "--source-digest", root])
    [digest, _count] = String.split(String.trim(output), "\n")
    digest
  end

  defp fixture_repository! do
    root = Path.join(System.tmp_dir!(), "phase78-manifest-#{System.unique_integer([:positive])}")
    File.mkdir_p!(root)
    {_output, 0} = System.cmd("git", ["init", "--quiet", root])

    paths = [
      ".github/workflows/security-gates.yml",
      "scripts/check_phase78_clean_state.sh",
      "mix.exs",
      "test/adoption/contract.exs",
      "lib/relyra.ex",
      "playwright.config.mjs",
      "demo/app.ex",
      ".planning/phases/73-twin-contract-and-baseline/73-RECONCILIATION-PROOF.json",
      ".planning/phases/73-twin-contract-and-baseline/73-SECURITY.md",
      ".planning/phases/73-twin-contract-and-baseline/73-VALIDATION.md",
      ".planning/phases/78-fixture/78-01-SUMMARY.md",
      ".planning/STATE.md",
      ".planning/ROADMAP.md",
      ".planning/phases/78-fixture/78-01-PLAN.md",
      ".planning/phases/78-ci-efficiency-and-reliability/78-CLEAN-STATE-RECEIPT.json"
    ]

    Enum.each(paths, fn path ->
      full = Path.join(root, path)
      File.mkdir_p!(Path.dirname(full))
      File.write!(full, "fixture: #{path}\n")
    end)

    {_output, 0} = System.cmd("git", ["-C", root, "add", "--all"])
    root
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
  defp convert_yaml(value), do: value
end
