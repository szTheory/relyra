defmodule Relyra.Security.CiGateIntegrityTest do
  @moduledoc """
  Anti-hollow meta-gate for the `ci.security` Mix alias.

  ## Why this test exists

  `mix` deduplicates the `test` task within a single `mix` invocation: if an alias
  runs `test` more than once, only the FIRST `test` actually executes, and every
  later bare `test` step is silently skipped. Worse, `ci.security` runs
  `ci.conformance` first, which runs `test ... --only conformance`. That means any
  later *bare* `test` step in `ci.security` was both skipped AND would have inherited
  the `--only conformance` filter — so the security lane was hollow: a regression in a
  security suite would still ship green.

  The fix is to run each security suite as its own `cmd mix test ...` step — a fresh
  OS process per suite, immune to the in-alias dedup and filter bleed. This meta-gate
  is the structural guard (T-30-14) that fails the build if anyone re-introduces the
  dedup bug by collapsing a `cmd mix test` line back into a bare `test` line, drops a
  gated suite from the alias, deletes a gated suite file, or removes a tag that
  `--only <tag>` depends on (which would otherwise silently match zero tests).

  This test carries no default-excluded tag (only `:pending` is excluded by default),
  so it runs under plain `mix test`, and it is also named explicitly as its own
  `cmd mix test` step in `ci.security` — so the gate gates itself.
  """
  use ExUnit.Case, async: true

  # The security contract: {relative_path, tag_or_nil}.
  # tag_or_nil is the `--only <tag>` filter that ci.security applies to that suite
  # (nil means the whole file runs). The tag-integrity test proves the tag actually
  # exists in the file source, so `--only <tag>` can never silently match zero tests.
  @gated_suites [
    {"test/security/ci_gate_integrity_test.exs", nil},
    {"test/security/strict_default_proof_test.exs", nil},
    {"test/relyra/ecto/escape_hatch_audit_test.exs", nil},
    {"test/security/xml/corpus_security_test.exs", "security_corpus"},
    {"test/relyra/security/xml/corpus_gate_test.exs", "security_corpus"},
    {"test/security/xml/corpus_security_test.exs", "gate02_c14n"},
    {"test/security/xml/adversarial_crypto_test.exs", "adversarial_crypto"},
    {"test/security/authn_request_signing_test.exs", "authn_request_signing"},
    {"test/security/xml_enc_test.exs", nil},
    {"test/security/xml_enc_adversarial_test.exs", nil},
    {"test/security/metadata_attribute_injection_test.exs", nil},
    {"test/security/login_trace_test.exs", nil},
    {"test/security/testing_fixture_crypto_test.exs", nil}
  ]

  @docs_test_commands [
    "cmd mix test test/docs/markdown_link_smoke_test.exs --warnings-as-errors",
    "cmd mix test test/docs/adopter_voice_test.exs --warnings-as-errors",
    "cmd mix test test/docs/troubleshooting_drift_test.exs --warnings-as-errors",
    "cmd mix test test/docs/testing_api_drift_test.exs --warnings-as-errors",
    "cmd mix test test/docs/logout_recipe_drift_test.exs --warnings-as-errors",
    "cmd mix test test/docs/demo_guide_drift_test.exs --warnings-as-errors",
    "cmd mix test test/mix/tasks/relyra_batteries_included_test.exs --warnings-as-errors",
    "cmd mix test test/mix/relyra_install_test.exs test/test_support_demo_test.exs test/testing_demo_test.exs --warnings-as-errors"
  ]

  @verify_test_commands [
    "cmd mix test test/relyra/ecto/audit_hardening_test.exs test/relyra/ecto/connection_record_test.exs test/relyra/ecto/metadata_apply_test.exs test/relyra/ecto/certificate_inventory_transition_test.exs test/relyra/ecto/mapping_commands_test.exs test/relyra/ecto/ecto_connection_resolver_test.exs test/relyra/connection_snapshot_test.exs test/relyra/user_mapper/default_attribute_test.exs --warnings-as-errors"
  ]

  @security_test_commands [
    "cmd mix test test/security/ci_gate_integrity_test.exs --warnings-as-errors",
    "cmd mix test test/security/strict_default_proof_test.exs --warnings-as-errors",
    "cmd mix test test/relyra/ecto/escape_hatch_audit_test.exs --warnings-as-errors",
    "cmd mix test test/security/xml/corpus_security_test.exs test/relyra/security/xml/corpus_gate_test.exs --only security_corpus --warnings-as-errors",
    "cmd mix test test/security/xml/corpus_security_test.exs --only gate02_c14n --warnings-as-errors",
    "cmd mix test test/security/xml/adversarial_crypto_test.exs --only adversarial_crypto --warnings-as-errors",
    "cmd mix test test/security/authn_request_signing_test.exs --only authn_request_signing --warnings-as-errors",
    "cmd mix test test/security/xml_enc_test.exs --warnings-as-errors",
    "cmd mix test test/security/xml_enc_adversarial_test.exs --warnings-as-errors",
    "cmd mix test test/security/metadata_attribute_injection_test.exs --warnings-as-errors",
    "cmd mix test test/security/login_trace_test.exs --warnings-as-errors",
    "cmd mix test test/security/testing_fixture_crypto_test.exs --warnings-as-errors"
  ]

  @standalone_gate_name "GATE-02 binary gate (gate02_c14n zero regressions)"
  @standalone_gate_run "mix test --only gate02_c14n --warnings-as-errors"

  @decimal_advisory "GHSA-rhv4-8758-jx7v"
  @audit_commands [
    "cmd mix deps.audit --ignore-advisory-ids #{@decimal_advisory}",
    "cmd mix hex.audit",
    "cmd mix sobelow --config"
  ]

  test "audit and SAST successors use exact independent fail-fast commands" do
    assert Enum.take(ci_security_steps(), -3) == @audit_commands
    refute File.exists?("lib/mix/tasks/hex.audit.ex")

    hex_config = Mix.Project.config()[:hex] || []
    assert Keyword.keys(hex_config) in [[], [:ignore_advisories]]
    assert Keyword.get(hex_config, :ignore_advisories, []) in [[], [@decimal_advisory]]
  end

  @tag timeout: 120_000
  test "the extracted audit pipeline succeeds once per tool in distinct VMs" do
    {output, status, markers} = audit_fixture("clean")
    assert status == 0, output
    assert Enum.map(markers, &hd/1) == ["deps.audit", "hex.audit", "sobelow"]
    assert markers |> Enum.map(&List.last/1) |> Enum.uniq() |> length() == 3
    assert output =~ "No vulnerabilities found."
    assert output =~ "No retired or security advisory packages found"
    assert output =~ "HEX_OWNER="
    assert output =~ "/hex-"
    refute output =~ "continuing without registry audit"
  end

  @tag timeout: 120_000
  test "actual MixAudit findings and unavailable data stop both successors" do
    for {scenario, message} <- [
          {"deps-finding", "Vulnerabilities found!"},
          {"deps-error", "owned advisory source unavailable"}
        ] do
      {output, status, markers} = audit_fixture(scenario)
      assert status != 0, output
      assert Enum.map(markers, &hd/1) == ["deps.audit"]
      assert output =~ message
    end
  end

  @tag timeout: 120_000
  test "real Hex advisory, retirement, unavailable registry and missing task fail closed" do
    for {scenario, message} <- [
          {"hex-advisory", "Found packages with security advisories"},
          {"hex-retired", "Found retired packages"},
          {"hex-error", "owned registry unavailable"},
          {"hex-missing", "could not be found"}
        ] do
      {output, status, markers} = audit_fixture(scenario)
      assert status != 0, output

      expected =
        if scenario == "hex-missing", do: ["deps.audit"], else: ["deps.audit", "hex.audit"]

      assert Enum.map(markers, &hd/1) == expected
      assert output =~ message
    end
  end

  @tag timeout: 120_000
  test "Sobelow nonzero status is propagated without normalizing it to success" do
    {output, status, markers} = audit_fixture("sobelow-failure")
    assert status != 0, output
    assert output =~ "** (exit) 42"
    assert Enum.map(markers, &hd/1) == ["deps.audit", "hex.audit", "sobelow"]
  end

  @tag timeout: 120_000
  test "the existing Decimal exception cannot hide another advisory or a retirement" do
    {output, status, markers} =
      audit_fixture("decimal-only", hex: [ignore_advisories: [@decimal_advisory]])

    assert status == 0, output
    assert length(markers) == 3
    assert output =~ "Ignored advisories:"
    assert output =~ @decimal_advisory

    for scenario <- ["decimal-plus-new", "decimal-plus-retired"] do
      {output, status, markers} =
        audit_fixture(scenario, hex: [ignore_advisories: [@decimal_advisory]])

      assert status != 0, output
      assert Enum.map(markers, &hd/1) == ["deps.audit", "hex.audit"]
      assert output =~ "Ignored advisories:"
      assert output =~ "Found "
    end
  end

  # Only external data providers are replaced in these owned child VMs. The
  # installed MixAudit CLI/report/version matcher/System.stop and archive Hex
  # task/ignore matcher/exit handler execute unchanged. Mix itself interprets
  # the real extracted alias strings, so removing `cmd mix` breaks this proof.
  defp audit_fixture(scenario, opts \\ []) do
    root = Path.join(System.tmp_dir!(), "relyra-audit-gate-#{System.unique_integer([:positive])}")
    File.mkdir_p!(root)
    on_exit(fn -> File.rm_rf!(root) end)
    marker = Path.join(root, "markers")

    for dir <- ["hex", "cache", "tmp", "archives"], do: File.mkdir_p!(Path.join(root, dir))

    audit_path = :mix_audit |> :code.lib_dir() |> to_string() |> Path.join("ebin")
    jason_path = :jason |> :code.lib_dir() |> to_string() |> Path.join("ebin")
    steps = Keyword.get(opts, :steps, Enum.take(ci_security_steps(), -3))
    hex = Keyword.get(opts, :hex, [])

    File.write!(Path.join(root, "mix.exs"), """
    Code.prepend_path(#{inspect(audit_path)})
    Code.prepend_path(#{inspect(jason_path)})
    defmodule OwnedAuditFixture.MixProject do
      use Mix.Project
      def project, do: [app: :owned_audit_fixture, version: "0.0.0", deps: [],
        hex: #{inspect(hex)}, aliases: [pipeline: #{inspect(steps)}]]
    end
    Code.require_file("providers.exs", __DIR__)
    """)

    File.write!(Path.join(root, "mix.lock"), """
    %{owned: {:hex, :owned, "1.0.0", "checksum", [:mix], [], "hexpm", "checksum"}}
    """)

    File.write!(Path.join(root, "providers.exs"), audit_providers())

    env = [
      {"RELYRA_AUDIT_SCENARIO", scenario},
      {"RELYRA_AUDIT_MARKERS", marker},
      {"HEX_HOME", Path.join(root, "hex")},
      {"XDG_CACHE_HOME", Path.join(root, "cache")},
      {"TMPDIR", Path.join(root, "tmp")},
      {"HEX_IGNORE_ADVISORIES", nil},
      {"HEX_IGNORE_RETIREMENTS", nil},
      {"MIX_BUILD_PATH", Path.join(root, "_build")},
      {"MIX_PATH", nil},
      {"ELIXIR_ERL_OPTIONS", "+S 2"}
    ]

    env =
      if scenario == "hex-missing",
        do: [{"MIX_ARCHIVES", Path.join(root, "archives")} | env],
        else: env

    {output, status} = System.cmd("mix", ["pipeline"], cd: root, env: env, stderr_to_stdout: true)

    markers =
      marker |> File.read!() |> String.split("\n", trim: true) |> Enum.map(&String.split(&1, ":"))

    IO.puts("audit fixture #{scenario}: exit=#{status}, markers=#{inspect(markers)}")

    if evidence = System.get_env("RELYRA_AUDIT_EVIDENCE_ROOT") do
      File.mkdir_p!(evidence)
      File.write!(Path.join(evidence, scenario <> ".log"), output)

      File.write!(
        Path.join(evidence, scenario <> ".json"),
        Jason.encode!(%{status: status, markers: markers})
      )
    end

    {output, status, markers}
  end

  defp audit_providers do
    ~S"""
    Code.compiler_options(ignore_module_conflict: true)
    defmodule OwnedAuditFixture do
      def scenario, do: System.fetch_env!("RELYRA_AUDIT_SCENARIO")
      def mark(tool), do: File.write!(System.fetch_env!("RELYRA_AUDIT_MARKERS"), tool <> ":" <> System.pid() <> "\n", [:append])
      def advisory(id), do: %{id: id, aliases: [], summary: "Owned deterministic finding", severity: :SEVERITY_HIGH}
    end
    defmodule MixAudit.Repo do
      def advisories do
        OwnedAuditFixture.mark("deps.audit")
        case OwnedAuditFixture.scenario() do
          "deps-error" -> raise "owned advisory source unavailable"
          "deps-finding" -> [struct!(MixAudit.Advisory, id: "GHSA-owned-new-finding", package: "owned",
            title: "Owned vulnerable version", url: "https://example.invalid/advisory",
            severity: "high", vulnerable_version_ranges: [">= 1.0.0, < 2.0.0"], first_patched_versions: ["2.0.0"])]
          _ -> []
        end
      end
    end
    defmodule MixAudit.Project do
      def dependencies(_), do: [struct!(MixAudit.Dependency, package: "owned", version: "1.0.0", lockfile: "owned/mix.lock")]
    end
    defmodule Mix.Tasks.Sobelow do
      use Mix.Task
      def run(["--config"]) do
        OwnedAuditFixture.mark("sobelow")
        if OwnedAuditFixture.scenario() == "sobelow-failure", do: System.halt(42)
      end
    end
    if Code.ensure_loaded?(Hex) do
      Hex.start()
      Code.compiler_options(ignore_module_conflict: true)
      defmodule Hex.Registry.Server do
        def open do
          OwnedAuditFixture.mark("hex.audit")
          IO.puts("HEX_OWNER=" <> to_string(:code.which(Mix.Tasks.Hex.Audit)))
          if OwnedAuditFixture.scenario() == "hex-error", do: raise("owned registry unavailable")
          :ok
        end
        def prefetch(_), do: :ok
        def persist, do: :ok
        def retired(_, _, _) do
          if OwnedAuditFixture.scenario() in ["hex-retired", "decimal-plus-retired"],
            do: %{reason: :RETIRED_SECURITY, message: "Owned retirement"}
        end
        def advisories(_, _, _) do
          decimal = OwnedAuditFixture.advisory("GHSA-rhv4-8758-jx7v")
          finding = OwnedAuditFixture.advisory("GHSA-owned-new-finding")
          case OwnedAuditFixture.scenario() do
            "hex-advisory" -> [finding]
            "decimal-only" -> [decimal]
            "decimal-plus-new" -> [decimal, finding]
            "decimal-plus-retired" -> [decimal]
            _ -> []
          end
        end
      end
    end
    """
  end

  # The list of `ci.security` step strings, extracted by parsing mix.exs as actual
  # Elixir AST (NOT byte/bracket scanning). The parser already strips comments and
  # understands string literals, so a stray `]`/`[` in a comment, a markdown list,
  # a CLI flag, or a literal `"ci.security": [` inside a doc string can no longer
  # truncate, over-capture, or shadow the real alias (WR-01, WR-05). We walk the
  # quoted tree for the `aliases/0` keyword entry `"ci.security": [ ... ]` and return
  # its list of step strings (comments already gone, each step a quoted literal).
  defp mix_alias_steps(alias_name) do
    ast = Code.string_to_quoted!(File.read!("mix.exs"))

    steps =
      ast
      |> Macro.prewalker()
      |> Enum.find_value(fn
        {key, list} when is_list(list) ->
          if alias_key?(key, alias_name) and Enum.all?(list, &is_binary/1) do
            list
          end

        _ ->
          nil
      end)

    refute steps == nil,
           "could not find the `\"#{alias_name}\": [ ...string steps... ]` alias in mix.exs — " <>
             "the lane may have been renamed, removed, or restructured so its steps are no " <>
             "longer a flat list of strings"

    steps
  end

  defp ci_security_steps, do: mix_alias_steps("ci.security")

  # A keyword key in quoted form. A quoted atom keyword key like `"ci.security":`
  # parses to the bare atom `:"ci.security"`; plain `foo:` parses to `:foo`. Accept
  # both, and tolerate the variable-node form `{atom, _meta, ctx}` defensively.
  defp alias_key?(key, name) when is_atom(key), do: Atom.to_string(key) == name

  defp alias_key?({key, _meta, ctx}, name) when is_atom(key) and is_atom(ctx),
    do: Atom.to_string(key) == name

  defp alias_key?(_key, _name), do: false

  # The ci.security STEP strings that reference `path`. Because steps come from the
  # AST (comments already stripped), every returned step is a real alias step. A
  # single `cmd mix test a.exs b.exs --only tag` step names MULTIPLE files, so a
  # substring match on `path` correctly covers a suite that shares its step line
  # with a sibling suite (WR-03).
  defp steps_referencing(steps, path) do
    Enum.filter(steps, &String.contains?(&1, path))
  end

  defp test_steps(steps) do
    Enum.filter(steps, &Regex.match?(~r/^(?:cmd\s+mix\s+test|test)(?:\s|$)/, &1))
  end

  defp validate_test_commands!(steps, expected, label) do
    actual = test_steps(steps)

    if Enum.any?(actual, &(not Regex.match?(~r/^cmd\s+mix\s+test(?:\s|$)/, &1))) do
      raise ArgumentError,
            "#{label} contains a bare Mix test task; use one `cmd mix test` process per suite"
    end

    if actual != expected do
      raise ArgumentError,
            "#{label} test command inventory changed; expected each suite in an independent " <>
              "fresh process, got: #{inspect(actual)}"
    end

    :ok
  end

  defp flatten_alias_steps!(steps, aliases, stack \\ []) do
    Enum.flat_map(steps, fn step ->
      case Map.fetch(aliases, step) do
        {:ok, nested} ->
          if step in stack do
            raise ArgumentError,
                  "recursive Mix alias fixture: #{inspect(Enum.reverse([step | stack]))}"
          end

          flatten_alias_steps!(nested, aliases, [step | stack])

        :error ->
          [step]
      end
    end)
  end

  defp positive_test_summaries!(output, expected_count) do
    summaries =
      Regex.scan(~r/(\d+)\s+tests?,\s+(\d+)\s+failures?\b/, output)
      |> Enum.map(fn [_, tests, failures] ->
        {String.to_integer(tests), String.to_integer(failures)}
      end)

    if length(summaries) != expected_count or
         Enum.any?(summaries, fn {tests, failures} -> tests < 1 or failures != 0 end) do
      raise ArgumentError,
            "expected #{expected_count} positive zero-failure ExUnit summaries, got: #{inspect(summaries)}"
    end

    :ok
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

  defp standalone_gate_errors(workflow) do
    steps = get_in(workflow, ["jobs", "security", "steps"]) || []

    case Enum.filter(steps, &(&1["name"] == @standalone_gate_name)) do
      [%{"run" => @standalone_gate_run} = step] ->
        if Map.has_key?(step, "if") or Map.get(step, "continue-on-error", false) do
          [:disabled_standalone_gate]
        else
          []
        end

      _ ->
        [:missing_or_changed_standalone_gate]
    end
  end

  test "ci.docs and ci.verify keep each selected suite in its own fresh Mix process" do
    docs_steps = mix_alias_steps("ci.docs")
    verify_steps = mix_alias_steps("ci.verify")

    assert :ok = validate_test_commands!(docs_steps, @docs_test_commands, "ci.docs")

    expanded_verify_steps =
      flatten_alias_steps!(verify_steps, %{"ci.docs" => docs_steps, "ci.verify" => verify_steps})

    assert :ok =
             validate_test_commands!(
               expanded_verify_steps,
               @docs_test_commands ++ @verify_test_commands,
               "ci.verify (including ci.docs)"
             )
  end

  test "docs and verify mutation fixtures reject repeat bare tasks and inherited selectors" do
    repeated_bare_test = [
      "cmd mix test test/docs/markdown_link_smoke_test.exs --warnings-as-errors",
      "test test/docs/adopter_voice_test.exs --warnings-as-errors",
      "test test/docs/troubleshooting_drift_test.exs --warnings-as-errors"
    ]

    assert_raise ArgumentError, ~r/bare Mix test task/, fn ->
      validate_test_commands!(repeated_bare_test, @docs_test_commands, "fixture")
    end

    aliases = %{
      "ci.docs" => ["test test/docs/example_test.exs --only conformance"],
      "ci.verify" => ["ci.docs", "test test/security/example_test.exs"]
    }

    inherited_selector_steps = flatten_alias_steps!(aliases["ci.verify"], aliases)

    assert_raise ArgumentError, ~r/bare Mix test task/, fn ->
      validate_test_commands!(inherited_selector_steps, [], "inherited selector fixture")
    end
  end

  test "executed ExUnit summaries must select tests and pass" do
    assert :ok = positive_test_summaries!("3 tests, 0 failures\n1 test, 0 failures\n", 2)

    for output <- [
          "0 tests, 0 failures\n",
          "2 tests, 1 failure\n",
          "no ExUnit summary\n",
          "1 test, 0 failures\n"
        ] do
      assert_raise ArgumentError, ~r/positive zero-failure ExUnit summaries/, fn ->
        positive_test_summaries!(output, 2)
      end
    end
  end

  test "every ci.security test command stays independent with its exact suite and selector" do
    steps = ci_security_steps()
    assert :ok = validate_test_commands!(steps, @security_test_commands, "ci.security")

    first_test_index = Enum.find_index(steps, &String.starts_with?(&1, "cmd mix test "))

    second_test_index =
      first_test_index
      |> Kernel.+(1)
      |> then(fn offset ->
        Enum.drop(steps, offset) |> Enum.find_index(&String.starts_with?(&1, "cmd mix test "))
      end)
      |> Kernel.+(first_test_index + 1)

    collapsed_suites =
      steps
      |> List.replace_at(
        first_test_index,
        "cmd mix test test/security/ci_gate_integrity_test.exs test/security/strict_default_proof_test.exs --warnings-as-errors"
      )
      |> List.delete_at(second_test_index)

    dropped_suite = List.delete_at(steps, first_test_index)

    bare_test =
      List.replace_at(
        steps,
        first_test_index,
        String.replace_prefix(Enum.at(steps, first_test_index), "cmd mix test", "test")
      )

    changed_selector =
      Enum.map(steps, &String.replace(&1, "--only gate02_c14n", "--only gate02"))

    for mutation <- [collapsed_suites, dropped_suite, bare_test, changed_selector] do
      assert_raise ArgumentError, fn ->
        validate_test_commands!(mutation, @security_test_commands, "ci.security fixture")
      end
    end
  end

  test "standalone GATE-02 stays an unconditional blocking workflow step" do
    workflow = ".github/workflows/security-gates.yml" |> File.read!() |> parse_yaml!()
    assert standalone_gate_errors(workflow) == []

    steps = get_in(workflow, ["jobs", "security", "steps"])
    [gate_index] = Enum.find_index(steps, &(&1["name"] == @standalone_gate_name)) |> List.wrap()

    disabled_step = List.update_at(steps, gate_index, &Map.put(&1, "if", false))
    disabled_workflow = put_in(workflow, ["jobs", "security", "steps"], disabled_step)
    assert :disabled_standalone_gate in standalone_gate_errors(disabled_workflow)

    removed_workflow =
      put_in(workflow, ["jobs", "security", "steps"], List.delete_at(steps, gate_index))

    assert :missing_or_changed_standalone_gate in standalone_gate_errors(removed_workflow)

    assert_raise ArgumentError, ~r/positive zero-failure ExUnit summaries/, fn ->
      positive_test_summaries!("0 tests, 0 failures\n", 1)
    end
  end

  test "every gated security suite file exists on disk (T-30-14 presence)" do
    for {path, _tag} <- @gated_suites do
      assert File.exists?(path),
             "gated security suite #{path} is named in ci.security but does not exist on disk — " <>
               "the alias would error or the gate would be hollow"
    end
  end

  test "every gated security suite is named in the ci.security alias" do
    steps = ci_security_steps()

    for {path, _tag} <- @gated_suites do
      assert steps_referencing(steps, path) != [],
             "gated security suite #{path} is NOT referenced in any ci.security step — " <>
               "it would never run in the security lane (hollow gate)"
    end
  end

  test "every gated suite runs as a `cmd mix test` step, never a bare `test` step (anti-hollow)" do
    steps = ci_security_steps()

    assert :ok = validate_test_commands!(steps, @security_test_commands, "ci.security")

    for {path, _tag} <- @gated_suites do
      matching_steps = steps_referencing(steps, path)

      refute matching_steps == [],
             "no ci.security step references #{path} (cannot verify it is a `cmd mix test` step)"

      for step <- matching_steps do
        trimmed = String.trim_leading(step)

        refute Regex.match?(~r/^test\s/, trimmed),
               "ci.security runs #{path} via a BARE `test` step:\n\n  #{trimmed}\n\n" <>
                 "mix dedups the `test` task within one alias run and ci.conformance already " <>
                 "consumed it with `--only conformance`, so this suite would be silently skipped " <>
                 "(hollow gate). Use `cmd mix test ...` (a fresh OS process) instead."

        assert Regex.match?(~r/^cmd mix test\s/, trimmed),
               "ci.security step for #{path} must be a `cmd mix test ...` step but is:\n\n  #{trimmed}"
      end
    end
  end

  test "every `--only <tag>` filter used by ci.security exists in the suite's source (tag integrity)" do
    for {path, tag} <- @gated_suites, tag != nil do
      source = File.read!(path)

      # Anchor on a whole-atom boundary (`\b` after the tag). A plain substring match
      # (`source =~ "@tag :\#{tag}"`) would let a PREFIX tag pass: `--only security`
      # would falsely match `@tag :security_corpus` yet `mix test --only security`
      # matches ZERO tests, leaving the gate hollow (WR-02).
      assert Regex.match?(~r/@(module)?tag\s+:#{Regex.escape(tag)}\b/, source),
             "ci.security runs #{path} with `--only #{tag}` but the file declares no exact " <>
               "`@tag :#{tag}` or `@moduletag :#{tag}` — `--only #{tag}` would silently match " <>
               "ZERO tests, leaving the gate hollow"
    end
  end
end
