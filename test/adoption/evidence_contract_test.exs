defmodule Relyra.Adoption.EvidenceContractTest do
  use ExUnit.Case, async: true

  @moduletag :evidence_contract

  alias Relyra.AdoptionEvidence

  @requirements_path ".planning/REQUIREMENTS.md"
  @workflow_path ".github/workflows/security-gates.yml"
  @expected_personas [
    :evaluator,
    :developer,
    :tenant_admin,
    :security_reviewer,
    :sre,
    :end_user
  ]

  test "tracer resolves EVID-01 from literal ledger through a real selector and mandatory CI" do
    entries = AdoptionEvidence.entries()

    assert :ok = AdoptionEvidence.validate_entries!(entries)

    [owner | _] = AdoptionEvidence.deterministic_owners(entries, "EVID-01")
    assert owner.owner == __ENV__.file |> Path.relative_to_cwd()
    assert owner.selector == "evidence_contract"
    assert owner.lane == "ci.evidence"

    assert :ok = AdoptionEvidence.validate_repository!(entries, File.cwd!())
  end

  test "ledger covers exactly the active milestone requirements and all adopter personas" do
    entries = AdoptionEvidence.entries()

    assert entries |> Enum.map(& &1.requirement) |> MapSet.new() == active_requirements()

    assert entries |> Enum.flat_map(& &1.personas) |> MapSet.new() ==
             MapSet.new(@expected_personas)

    assert length(Enum.uniq_by(entries, & &1.id)) == length(entries)

    for entry <- entries do
      assert entry.job != ""
      assert entry.expected_outcome != ""
      assert entry.owner != ""
      assert entry.selector != ""
      assert entry.lane != ""
      assert entry.fixture_owner != ""
      assert entry.reset_boundary != ""
      assert entry.failure_diagnostics != ""
    end
  end

  test "planned and external-canary evidence stays visible without closing requirements" do
    planned = evidence_row("planned", :package_contract, :planned)
    canary = evidence_row("canary", :external_canary, :existing)
    deterministic = evidence_row("deterministic", :security_corpus, :existing)

    assert AdoptionEvidence.deterministic_owners([planned, canary], "EVID-01") == []

    assert AdoptionEvidence.deterministic_owners(
             [planned, canary, deterministic],
             "EVID-01"
           ) == [deterministic]
  end

  test "ci.evidence is a flat fresh-process alias and the required workflow owns it" do
    assert [step] = mix_alias_steps("ci.evidence")
    assert step =~ ~r/^cmd mix test test\/adoption\/evidence_contract_test\.exs\b/
    assert step =~ "--warnings-as-errors"

    workflow = File.read!(@workflow_path)
    assert workflow_step_command(workflow, "Evidence contract") == "mix ci.evidence"
    refute workflow =~ ~r/^\s*-\s+["']?\.planning\/\*\*/m
    assert workflow =~ ~r/^\s*-\s+["']?prompts\/\*\*/m
  end

  test "nil, empty, singleton, and duplicate ledgers fail closed without merging rows" do
    assert_raise ArgumentError, ~r/non-empty list.*nil/, fn ->
      AdoptionEvidence.validate_entries!(nil)
    end

    assert_raise ArgumentError, ~r/non-empty list/, fn ->
      AdoptionEvidence.validate_entries!([])
    end

    [single | _] = AdoptionEvidence.entries()
    assert :ok = AdoptionEvidence.validate_entry!(single)

    assert_raise ArgumentError, ~r/coverage mismatch.*EVID-02/s, fn ->
      AdoptionEvidence.validate_entries!([single])
    end

    distinct = %{single | id: "distinct-owner-same-requirement"}

    assert AdoptionEvidence.deterministic_owners([single, distinct], "EVID-01") == [
             single,
             distinct
           ]

    for duplicate <- [single, Map.new(single)] do
      assert_raise ArgumentError, ~r/duplicate evidence id.*#{single.id}/, fn ->
        AdoptionEvidence.validate_entries!(AdoptionEvidence.entries() ++ [duplicate])
      end
    end
  end

  test "row schema rejects unknown states and silently discarded fields with row diagnostics" do
    [row | _] = AdoptionEvidence.entries()

    assert_raise ArgumentError, ~r/#{row.id}.*unknown state.*ready/, fn ->
      AdoptionEvidence.validate_entry!(%{row | state: :ready})
    end

    assert_raise ArgumentError, ~r/#{row.id}.*unknown=.*marketing_claim/s, fn ->
      AdoptionEvidence.validate_entry!(Map.put(row, :marketing_claim, "complete"))
    end
  end

  test "closure validates every supplied row before considering deterministic ownership" do
    [row | _] = AdoptionEvidence.entries()

    partial = %{
      requirement: "EVID-01",
      state: :existing,
      evidence_kind: :security_corpus
    }

    assert_raise ArgumentError, ~r/evidence row.*invalid fields.*id/s, fn ->
      AdoptionEvidence.validate_closure!([partial], ["EVID-01"])
    end

    assert_raise ArgumentError, ~r/#{row.id}.*unknown evidence_kind.*invented/s, fn ->
      AdoptionEvidence.validate_closure!([%{row | evidence_kind: :invented}], ["EVID-01"])
    end
  end

  test "all textual row fields reject whitespace-only values with field diagnostics" do
    [row | _] = AdoptionEvidence.entries()

    for field <- [
          :id,
          :requirement,
          :job,
          :expected_outcome,
          :owner,
          :selector,
          :lane,
          :fixture_owner,
          :reset_boundary,
          :failure_diagnostics
        ] do
      assert_raise ArgumentError, ~r/evidence row.*empty #{field}/s, fn ->
        AdoptionEvidence.validate_entry!(Map.put(row, field, " \t\n"))
      end
    end
  end

  test "deterministic owner reporting preserves declaration order and closure ignores permutation" do
    [first, second | _] =
      AdoptionEvidence.deterministic_owners(AdoptionEvidence.entries(), "EVID-01")

    rows = [first, second]

    assert AdoptionEvidence.deterministic_owners(rows, "EVID-01") == rows
    assert :ok = AdoptionEvidence.validate_closure!(rows, ["EVID-01"])
    assert :ok = AdoptionEvidence.validate_closure!(Enum.reverse(rows), ["EVID-01"])
  end

  test "canary-only evidence cannot close a completed requirement" do
    canary = evidence_row("canary-only", :external_canary, :existing)

    assert_raise ArgumentError, ~r/EVID-01.*deterministic owner/, fn ->
      AdoptionEvidence.validate_closure!([canary], ["EVID-01"])
    end
  end

  test "repository ownership diagnostics name every broken seam and the clean control passes" do
    entries = AdoptionEvidence.entries()
    root = repository_fixture!()

    assert :ok = AdoptionEvidence.validate_repository!(entries, root)

    [owner | _] = AdoptionEvidence.deterministic_owners(entries, "EVID-01")

    assert_raise ArgumentError, ~r/EVID-01.*missing owner file.*missing_owner/s, fn ->
      AdoptionEvidence.validate_repository!(
        replace_entry(entries, owner, %{owner: "test/missing_owner.exs"}),
        root
      )
    end

    assert_raise ArgumentError, ~r/EVID-01.*selector missing_selector matches zero tests/s, fn ->
      AdoptionEvidence.validate_repository!(
        replace_entry(entries, owner, %{selector: "missing_selector"}),
        root
      )
    end

    mix_path = Path.join(root, "mix.exs")
    original_mix = File.read!(mix_path)
    File.write!(mix_path, String.replace(original_mix, owner.owner, "test/adoption/unwired.exs"))

    assert_raise ArgumentError, ~r/EVID-01.*alias ci\.evidence is not wired.*owner/s, fn ->
      AdoptionEvidence.validate_repository!(entries, root)
    end

    File.write!(mix_path, original_mix)
    workflow_path = Path.join(root, @workflow_path)
    original_workflow = File.read!(workflow_path)

    File.write!(
      workflow_path,
      String.replace(original_workflow, "run: mix ci.evidence", "run: mix qa")
    )

    assert_raise ArgumentError,
                 ~r/EVID-01.*enabled blocking.*mix ci\.evidence.*jobs\.security/s,
                 fn ->
                   AdoptionEvidence.validate_repository!(entries, root)
                 end
  end

  test "comments, strings, and tagged modules without tests cannot own a selector" do
    entries = AdoptionEvidence.entries()
    root = repository_fixture!()
    owner_path = Path.join(root, "test/adoption/evidence_contract_test.exs")

    inert_sources = [
      "defmodule CommentOnly do\n  # @moduletag :evidence_contract\nend\n",
      ~S'''
      defmodule StringOnly do
        @text "@moduletag :evidence_contract"
      end
      ''',
      "defmodule EmptyTaggedModule do\n  @moduletag :evidence_contract\nend\n"
    ]

    for source <- inert_sources do
      File.write!(owner_path, source)

      assert_raise ArgumentError,
                   ~r/EVID-01.*selector evidence_contract matches zero tests/s,
                   fn ->
                     AdoptionEvidence.validate_repository!(entries, root)
                   end
    end
  end

  test "workflow ownership requires the enabled blocking Evidence contract step in security" do
    entries = AdoptionEvidence.entries()

    mutations = [
      fn workflow ->
        String.replace(workflow, "  security:\n", "  optional:\n", global: false)
      end,
      fn workflow ->
        String.replace(workflow, "  security:\n", "  security:\n    if: false\n", global: false)
      end,
      fn workflow ->
        String.replace(
          workflow,
          "      - name: Evidence contract\n        run: mix ci.evidence",
          "      - name: Evidence contract\n        if: false\n        run: mix ci.evidence"
        )
      end,
      fn workflow ->
        String.replace(
          workflow,
          "      - name: Evidence contract\n        run: mix ci.evidence",
          "      - name: Evidence contract\n        continue-on-error: true\n        run: mix ci.evidence"
        )
      end
    ]

    for mutate <- mutations do
      root = repository_fixture!()
      workflow_path = Path.join(root, @workflow_path)
      File.write!(workflow_path, mutate.(File.read!(workflow_path)))

      assert_raise ArgumentError, ~r/EVID-01.*enabled blocking.*jobs\.security/s, fn ->
        AdoptionEvidence.validate_repository!(entries, root)
      end
    end
  end

  @tag :plan_73_06_task_1
  test "automated commands reject shell substitution hidden in environment assignments" do
    assert :ok =
             AdoptionEvidence.validate_automated_command!(
               "ASDF_ELIXIR_VERSION=1.19.5-otp-28 mix test test/adoption/evidence_contract_test.exs --only plan_73_06_task_1 --warnings-as-errors",
               File.cwd!()
             )

    assert_raise ArgumentError, ~r/shell-shaped/, fn ->
      AdoptionEvidence.validate_automated_command!(
        "EVIL=$(id) mix ci.evidence",
        File.cwd!()
      )
    end
  end

  @tag :plan_73_06_task_1
  test "automated commands reject filters whose effective test selection is empty" do
    for command <- [
          "mix test test/adoption/evidence_contract_test.exs --only plan_73_06_task_1 --exclude no_such_selector --warnings-as-errors",
          "mix test test/adoption/evidence_contract_test.exs --only=plan_73_06_task_1 --exclude=no_such_selector --warnings-as-errors"
        ] do
      assert :ok = AdoptionEvidence.validate_automated_command!(command, File.cwd!())
    end

    commands = [
      "mix test test/governance/milestone_scope_test.exs --only no_such_selector --warnings-as-errors",
      "mix test test/governance/milestone_scope_test.exs --only=no_such_selector --warnings-as-errors",
      "mix test test/governance/milestone_scope_test.exs --exclude evidence_contract --warnings-as-errors",
      "mix test test/governance/milestone_scope_test.exs --exclude=evidence_contract --warnings-as-errors"
    ]

    for command <- commands do
      assert_raise ArgumentError, ~r/zero selected tests/, fn ->
        AdoptionEvidence.validate_automated_command!(command, File.cwd!())
      end
    end

    for command <- [
          "mix test test/adoption/evidence_contract_test.exs --only --warnings-as-errors",
          "mix test test/adoption/evidence_contract_test.exs --only= --warnings-as-errors",
          "mix test test/adoption/evidence_contract_test.exs --only evidence_contract --only evidence_contract --warnings-as-errors"
        ] do
      assert_raise ArgumentError, ~r/(missing its filter value|duplicate filter values)/, fn ->
        AdoptionEvidence.validate_automated_command!(command, File.cwd!())
      end
    end
  end

  @tag :plan_73_06_task_1
  test "selector ownership does not cross ExUnit module boundaries" do
    entries = AdoptionEvidence.entries()
    root = repository_fixture!()
    owner_path = Path.join(root, "test/adoption/evidence_contract_test.exs")

    File.write!(
      owner_path,
      """
      defmodule EmptySelectedModule do
        use ExUnit.Case
        @moduletag :evidence_contract
      end

      defmodule UnselectedModule do
        use ExUnit.Case
        test "not selected" do
          assert true
        end
      end
      """
    )

    assert_raise ArgumentError, ~r/selector evidence_contract matches zero tests/, fn ->
      AdoptionEvidence.validate_repository!(entries, root)
    end
  end

  @tag :plan_73_06_task_1
  test "selector ownership recognizes tag keys rather than incidental atom values" do
    entries = AdoptionEvidence.entries()
    root = repository_fixture!()
    owner_path = Path.join(root, "test/adoption/evidence_contract_test.exs")

    File.write!(
      owner_path,
      """
      defmodule ValueTaggedModule do
        use ExUnit.Case
        @moduletag other: :evidence_contract
        test "tag value is not the selector" do
          assert true
        end
      end
      """
    )

    assert_raise ArgumentError, ~r/selector evidence_contract matches zero tests/, fn ->
      AdoptionEvidence.validate_repository!(entries, root)
    end
  end

  @tag :plan_73_06_task_2
  test "mandatory workflow ownership rejects event-conditional and fallible steps" do
    entries = AdoptionEvidence.entries()
    clean_root = repository_fixture!()

    assert :ok = AdoptionEvidence.validate_repository!(entries, clean_root)

    clean_workflow_path = Path.join(clean_root, @workflow_path)

    File.write!(
      clean_workflow_path,
      String.replace(
        File.read!(clean_workflow_path),
        "      - name: Evidence contract\n        run: mix ci.evidence",
        "      - name: Evidence contract\n        continue-on-error: false\n        run: mix ci.evidence"
      )
    )

    assert :ok = AdoptionEvidence.validate_repository!(entries, clean_root)

    mutations = [
      fn workflow ->
        String.replace(
          workflow,
          "  security:\n",
          "  security:\n    if: ${{ github.event_name != 'schedule' }}\n",
          global: false
        )
      end,
      fn workflow ->
        String.replace(
          workflow,
          "      - name: Evidence contract\n        run: mix ci.evidence",
          "      - name: Evidence contract\n        if: ${{ github.event_name == 'workflow_dispatch' }}\n        run: mix ci.evidence"
        )
      end,
      fn workflow ->
        String.replace(
          workflow,
          "      - name: Evidence contract\n        run: mix ci.evidence",
          "      - name: Evidence contract\n        continue-on-error: ${{ github.ref != '' }}\n        run: mix ci.evidence"
        )
      end,
      fn workflow ->
        String.replace(
          workflow,
          "      - name: Evidence contract\n        run: mix ci.evidence",
          "      - name: Evidence contract\n        if: true\n        run: mix ci.evidence"
        )
      end,
      fn workflow ->
        String.replace(
          workflow,
          "      - name: Evidence contract\n        run: mix ci.evidence",
          "      - name: Evidence contract\n        continue-on-error: \"false\"\n        run: mix ci.evidence"
        )
      end
    ]

    for mutate <- mutations do
      root = repository_fixture!()
      workflow_path = Path.join(root, @workflow_path)
      File.write!(workflow_path, mutate.(File.read!(workflow_path)))

      assert_raise ArgumentError, ~r/enabled blocking.*jobs\.security/s, fn ->
        AdoptionEvidence.validate_repository!(entries, root)
      end
    end
  end

  @tag :plan_73_09_task_1
  test "automated commands have one fully consumed non-shell argv meaning" do
    assert :ok =
             AdoptionEvidence.validate_automated_command!(
               "ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix test test/adoption/evidence_contract_test.exs --only plan_73_09_task_1 --warnings-as-errors",
               File.cwd!()
             )

    for command <- [
          "mix test test/adoption/evidence_contract_test.exs --warnings-as-errors # ignored",
          "mix test test/adoption/evidence_contract_test.exs --warnings-as-errors > proof.txt",
          "mix test test/adoption/evidence_contract_test.exs --warnings-as-errors < input.txt",
          "TOKEN=$VALUE mix ci.evidence",
          "mix test test/adoption/*_test.exs --warnings-as-errors",
          "mix test test/adoption/{evidence,other}_test.exs --warnings-as-errors",
          "mix test 'test/adoption/evidence_contract_test.exs' --warnings-as-errors",
          ~S(mix test "test/adoption/evidence_contract_test.exs" --warnings-as-errors),
          ~S(mix test test/adoption/evidence\_contract_test.exs --warnings-as-errors)
        ] do
      assert_raise ArgumentError, ~r/shell-shaped/, fn ->
        AdoptionEvidence.validate_automated_command!(command, File.cwd!())
      end
    end
  end

  @tag :plan_73_09_task_1
  test "named owners resolve the actual Mix project alias rather than decoy tuples" do
    root = repository_fixture!()
    mix_path = Path.join(root, "mix.exs")

    File.write!(mix_path, fixture_mix_project([]))

    assert_raise ArgumentError, ~r/alias ci\.evidence.*fresh-process/, fn ->
      AdoptionEvidence.validate_automated_command!("mix ci.evidence", root)
    end

    File.write!(mix_path, fixture_mix_project([fixture_evidence_step()]))
    assert :ok = AdoptionEvidence.validate_automated_command!("mix ci.evidence", root)
  end

  @tag :cwd_isolation
  test "fixture Mix inspection never changes the VM working directory" do
    root = repository_fixture!()
    mix_path = Path.join(root, "mix.exs")
    original_cwd = File.cwd!()

    File.write!(
      mix_path,
      "Process.sleep(150)\n" <> fixture_mix_project([fixture_evidence_step()])
    )

    parent = self()

    validation =
      Task.async(fn ->
        result = AdoptionEvidence.validate_automated_command!("mix ci.evidence", root)
        send(parent, {:validation_done, self()})
        result
      end)

    observed_cwds =
      Enum.reduce_while(1..1_000, [], fn _, observed ->
        cwd = File.cwd!()

        receive do
          {:validation_done, pid} when pid == validation.pid -> {:halt, [cwd | observed]}
        after
          1 -> {:cont, [cwd | observed]}
        end
      end)

    assert observed_cwds != []
    assert Enum.all?(observed_cwds, &(&1 == original_cwd))
    assert Task.await(validation) == :ok
  end

  @tag :plan_73_09_task_1
  test "selector ownership requires genuinely registered ExUnit tests" do
    entries = AdoptionEvidence.entries()
    root = repository_fixture!()
    owner_path = Path.join(root, "test/adoption/evidence_contract_test.exs")

    File.write!(
      owner_path,
      """
      defmodule NoopTestMacro do
        defmacro test(_name, do: _body), do: quote(do: :ok)
      end

      defmodule ShadowTestMacroOwner do
        import NoopTestMacro
        @moduletag :evidence_contract

        test "looks executable but is not registered" do
          raise "must never execute"
        end
      end
      """
    )

    assert_raise ArgumentError, ~r/selector evidence_contract matches zero tests/, fn ->
      AdoptionEvidence.validate_repository!(entries, root)
    end
  end

  @tag :plan_73_12_task_1
  test "repository ownership rejects an alias with an empty effective selection" do
    entries = AdoptionEvidence.entries()
    root = repository_fixture!()
    mix_path = Path.join(root, "mix.exs")

    hollow_step =
      fixture_evidence_step() <>
        " --exclude evidence_contract"

    File.write!(mix_path, fixture_mix_project([hollow_step]))

    assert_raise ArgumentError,
                 ~r/EVID-01.*row.*ci\.evidence.*test\/adoption\/evidence_contract_test\.exs.*zero effective selected tests/s,
                 fn -> AdoptionEvidence.validate_repository!(entries, root) end
  end

  @tag :plan_73_12_task_1
  test "every alias owner must retain an effective selected test" do
    entries = AdoptionEvidence.entries()
    root = repository_fixture!()
    mix_path = Path.join(root, "mix.exs")
    empty_owner = "test/adoption/empty_owner_test.exs"

    File.write!(
      Path.join(root, empty_owner),
      """
      defmodule EmptyAliasOwnerTest do
        use ExUnit.Case
        test "not evidence" do
          assert true
        end
      end
      """
    )

    step =
      "cmd mix test test/adoption/evidence_contract_test.exs #{empty_owner} " <>
        "--only evidence_contract --warnings-as-errors"

    File.write!(mix_path, fixture_mix_project([step]))

    assert_raise ArgumentError,
                 ~r/alias ci\.evidence.*#{Regex.escape(empty_owner)}.*zero effective selected tests/s,
                 fn -> AdoptionEvidence.validate_repository!(entries, root) end
  end

  @tag :plan_73_12_task_1
  test "repository alias uses the shared filter parser and the checked-in alias remains valid" do
    entries = AdoptionEvidence.entries()

    for step <- [
          fixture_evidence_step() <> " --only evidence_contract",
          fixture_evidence_step() <> " --only",
          fixture_evidence_step() <> " --only="
        ] do
      root = repository_fixture!()
      File.write!(Path.join(root, "mix.exs"), fixture_mix_project([step]))

      assert_raise ArgumentError, ~r/(duplicate filter values|missing its filter value)/, fn ->
        AdoptionEvidence.validate_repository!(entries, root)
      end
    end

    assert :ok = AdoptionEvidence.validate_repository!(entries, File.cwd!())
  end

  @tag :plan_73_09_task_2
  test "security job ownership is absent-or-literal-false fallible" do
    entries = AdoptionEvidence.entries()

    root = repository_fixture!()
    workflow_path = Path.join(root, @workflow_path)

    File.write!(
      workflow_path,
      String.replace(
        File.read!(workflow_path),
        "  security:\n",
        "  security:\n    continue-on-error: false\n",
        global: false
      )
    )

    assert :ok = AdoptionEvidence.validate_repository!(entries, root)

    for value <- ["true", "${{ github.ref != '' }}", ~s("false")] do
      root = repository_fixture!()
      workflow_path = Path.join(root, @workflow_path)

      File.write!(
        workflow_path,
        String.replace(
          File.read!(workflow_path),
          "  security:\n",
          "  security:\n    continue-on-error: #{value}\n",
          global: false
        )
      )

      assert_raise ArgumentError, ~r/jobs\.security.*continue-on-error/s, fn ->
        AdoptionEvidence.validate_repository!(entries, root)
      end
    end
  end

  @tag :plan_73_09_task_2
  test "alternate paths-ignore patterns cannot suppress planning evidence" do
    entries = AdoptionEvidence.entries()

    for pattern <- [
          ".planning/*",
          ".planning/**",
          ".planning/**/*",
          ".planning/**/**",
          ".planning/STAT?.md",
          ".planning/[R]OADMAP.md",
          "**"
        ] do
      root = repository_fixture!()
      workflow_path = Path.join(root, @workflow_path)

      File.write!(
        workflow_path,
        replace_pull_request_filter(File.read!(workflow_path), "paths-ignore", [pattern])
      )

      assert_raise ArgumentError, ~r/pull_request.*\.planning\//s, fn ->
        AdoptionEvidence.validate_repository!(entries, root)
      end
    end
  end

  @tag :plan_73_09_task_2
  test "positive paths are rejected regardless of ordered exclusions or re-inclusions" do
    entries = AdoptionEvidence.entries()
    excluded_root = repository_fixture!()
    excluded_workflow_path = Path.join(excluded_root, @workflow_path)

    File.write!(
      excluded_workflow_path,
      replace_pull_request_filter(File.read!(excluded_workflow_path), "paths", [
        "**",
        "!.planning/**"
      ])
    )

    assert_raise ArgumentError, ~r/pull_request.*must not use positive paths/s, fn ->
      AdoptionEvidence.validate_repository!(entries, excluded_root)
    end

    included_root = repository_fixture!()
    included_workflow_path = Path.join(included_root, @workflow_path)

    File.write!(
      included_workflow_path,
      replace_pull_request_filter(File.read!(included_workflow_path), "paths", [
        "**",
        "!.planning/**",
        ".planning/**"
      ])
    )

    assert_raise ArgumentError, ~r/pull_request.*must not use positive paths/s, fn ->
      AdoptionEvidence.validate_repository!(entries, included_root)
    end

    push_root = repository_fixture!()
    push_workflow_path = Path.join(push_root, @workflow_path)

    File.write!(
      push_workflow_path,
      replace_push_filter(File.read!(push_workflow_path), "paths", [
        "**",
        "!.planning/**"
      ])
    )

    assert_raise ArgumentError, ~r/push.*must not use positive paths/s, fn ->
      AdoptionEvidence.validate_repository!(entries, push_root)
    end
  end

  @tag :plan_73_09_task_2
  test "path filters reject empty and unsupported grammars before positive policy" do
    entries = AdoptionEvidence.entries()

    for replacement <- [
          "  pull_request:\n    paths: []",
          "  pull_request:\n    paths:\n      - \"[\""
        ] do
      root = repository_fixture!()
      workflow_path = Path.join(root, @workflow_path)

      File.write!(
        workflow_path,
        String.replace(
          File.read!(workflow_path),
          "  pull_request:\n    paths-ignore:\n      - \"prompts/**\"",
          replacement,
          global: false
        )
      )

      assert_raise ArgumentError, ~r/(non-empty block list|unclosed.*character class)/, fn ->
        AdoptionEvidence.validate_repository!(entries, root)
      end
    end

    root = repository_fixture!()
    workflow_path = Path.join(root, @workflow_path)

    File.write!(
      workflow_path,
      replace_pull_request_filter(File.read!(workflow_path), "paths", [
        "**",
        "!.planning/ROADMAP.md",
        ".planning/[R]OADMAP.md"
      ])
    )

    assert_raise ArgumentError, ~r/pull_request.*must not use positive paths/s, fn ->
      AdoptionEvidence.validate_repository!(entries, root)
    end
  end

  @tag :plan_73_12_task_2
  test "mandatory pull request and main push events reject every positive paths filter" do
    entries = AdoptionEvidence.entries()

    former_sample = [
      ".planning/ROADMAP.md",
      ".planning/REQUIREMENTS.md",
      ".planning/STATE.md",
      ".planning/phases/73-twin-contract-and-baseline/73-09-PLAN.md",
      ".planning/phases/73-twin-contract-and-baseline/73-BASELINE.md"
    ]

    for replace <- [&replace_pull_request_filter/3, &replace_push_filter/3] do
      root = repository_fixture!()
      workflow_path = Path.join(root, @workflow_path)
      File.write!(workflow_path, replace.(File.read!(workflow_path), "paths", former_sample))

      assert_raise ArgumentError,
                   ~r/workflow (pull_request|push) must not use positive paths/,
                   fn ->
                     AdoptionEvidence.validate_repository!(entries, root)
                   end
    end
  end

  @tag :plan_73_12_task_2
  test "paths-ignore cannot suppress any governed source or planning class" do
    entries = AdoptionEvidence.entries()

    governed_examples = [
      "test/support/adoption_evidence.ex",
      "test/adoption/evidence_contract_test.exs",
      "test/governance/milestone_scope_test.exs",
      "mix.exs",
      @workflow_path,
      ".planning/PROJECT.md",
      ".planning/ROADMAP.md",
      ".planning/REQUIREMENTS.md",
      ".planning/STATE.md",
      ".planning/phases/73-twin-contract-and-baseline/73-BASELINE.md",
      ".planning/phases/73-twin-contract-and-baseline/73-12-PLAN.md",
      ".planning/phases/73-twin-contract-and-baseline/73-11-SUMMARY.md"
    ]

    for event <- [:pull_request, :push], path <- governed_examples do
      root = repository_fixture!()
      workflow_path = Path.join(root, @workflow_path)

      replace =
        if event == :pull_request,
          do: &replace_pull_request_filter/3,
          else: &replace_push_filter/3

      File.write!(workflow_path, replace.(File.read!(workflow_path), "paths-ignore", [path]))

      assert_raise ArgumentError,
                   ~r/workflow #{event} path filter skips governed input #{Regex.escape(path)}/,
                   fn -> AdoptionEvidence.validate_repository!(entries, root) end
    end
  end

  @tag :plan_73_12_task_2
  test "checked-in prompts ignore and unfiltered required events remain mandatory" do
    entries = AdoptionEvidence.entries()
    assert :ok = AdoptionEvidence.validate_repository!(entries, File.cwd!())

    root = repository_fixture!()
    workflow_path = Path.join(root, @workflow_path)

    workflow =
      workflow_path
      |> File.read!()
      |> String.replace(
        "  pull_request:\n    paths-ignore:\n      - \"prompts/**\"",
        "  pull_request:"
      )
      |> String.replace(
        "  push:\n    branches:\n      - main\n    paths-ignore:\n      - \"prompts/**\"",
        "  push:\n    branches:\n      - main"
      )

    File.write!(workflow_path, workflow)
    assert :ok = AdoptionEvidence.validate_repository!(entries, root)
  end

  defp active_requirements do
    @requirements_path
    |> File.read!()
    |> String.split("## Future Requirements", parts: 2)
    |> hd()
    |> then(&Regex.scan(~r/^- \[[ x]\] \*\*([A-Z]+-\d+)\*\*:/m, &1, capture: :all_but_first))
    |> List.flatten()
    |> MapSet.new()
  end

  defp mix_alias_steps(name) do
    ast = Code.string_to_quoted!(File.read!("mix.exs"))

    ast
    |> Macro.prewalker()
    |> Enum.find_value(fn
      {key, steps} when is_atom(key) and is_list(steps) ->
        if Atom.to_string(key) == name and Enum.all?(steps, &is_binary/1), do: steps

      _other ->
        nil
    end)
  end

  defp workflow_step_command(workflow, name) do
    lines = String.split(workflow, "\n")

    lines
    |> Enum.with_index()
    |> Enum.find_value(fn {line, index} ->
      if Regex.match?(~r/^\s*- name:\s*#{Regex.escape(name)}\s*$/, line) do
        lines
        |> Enum.drop(index + 1)
        |> Enum.take_while(&(not Regex.match?(~r/^\s*- name:/, &1)))
        |> Enum.find_value(fn command_line ->
          case Regex.run(~r/^\s+run:\s*([^#]+?)\s*$/, command_line, capture: :all_but_first) do
            [command] -> String.trim(command)
            nil -> nil
          end
        end)
      end
    end)
  end

  defp evidence_row(id, evidence_kind, state) do
    %{
      id: id,
      requirement: "EVID-01",
      personas: [:security_reviewer],
      job: "inspect evidence ownership",
      expected_outcome: "ownership is executable",
      evidence_kind: evidence_kind,
      owner: "test/adoption/evidence_contract_test.exs",
      selector: "evidence_contract",
      lane: "ci.evidence",
      state: state,
      fixture_owner: "repository",
      reset_boundary: "fresh checkout",
      failure_diagnostics: "EVID-01 ownership seam failed"
    }
  end

  defp replace_entry(entries, target, updates) do
    Enum.map(entries, fn entry ->
      if entry.id == target.id, do: Map.merge(entry, updates), else: entry
    end)
  end

  defp fixture_evidence_step do
    "cmd mix test test/adoption/evidence_contract_test.exs test/governance/milestone_scope_test.exs --only evidence_contract --warnings-as-errors"
  end

  defp replace_pull_request_filter(workflow, key, patterns) do
    replacement =
      ["  pull_request:", "    #{key}:"] ++
        Enum.map(patterns, &"      - \"#{&1}\"")

    String.replace(
      workflow,
      "  pull_request:\n    paths-ignore:\n      - \"prompts/**\"",
      Enum.join(replacement, "\n"),
      global: false
    )
  end

  defp replace_push_filter(workflow, key, patterns) do
    replacement =
      ["  push:", "    branches:", "      - main", "    #{key}:"] ++
        Enum.map(patterns, &"      - \"#{&1}\"")

    String.replace(
      workflow,
      "  push:\n    branches:\n      - main\n    paths-ignore:\n      - \"prompts/**\"",
      Enum.join(replacement, "\n"),
      global: false
    )
  end

  defp fixture_mix_project(actual_steps) do
    decoy_step = fixture_evidence_step()
    suffix = System.unique_integer([:positive, :monotonic])

    """
    defmodule EvidenceFixture#{suffix}.MixProject do
      use Mix.Project

      def project do
        [app: :evidence_fixture, version: "0.1.0", aliases: aliases()]
      end

      defp aliases, do: [{:"ci.evidence", #{inspect(actual_steps)}}]

      def unrelated_decoy do
        [{:"ci.evidence", [#{inspect(decoy_step)}]}]
      end
    end
    """
  end

  defp repository_fixture! do
    root =
      Path.join(System.tmp_dir!(), "relyra-evidence-#{System.unique_integer([:positive])}")

    File.mkdir_p!(Path.join(root, "test/adoption"))
    File.mkdir_p!(Path.join(root, "test/governance"))
    File.mkdir_p!(Path.join(root, "test/support"))
    File.mkdir_p!(Path.join(root, ".github/workflows"))
    File.mkdir_p!(Path.join(root, ".planning/phases/73-twin-contract-and-baseline"))
    File.write!(Path.join(root, "mix.exs"), fixture_mix_project([fixture_evidence_step()]))
    File.cp!(__ENV__.file, Path.join(root, "test/adoption/evidence_contract_test.exs"))

    File.cp!(
      "test/support/adoption_evidence.ex",
      Path.join(root, "test/support/adoption_evidence.ex")
    )

    File.cp!(
      "test/governance/milestone_scope_test.exs",
      Path.join(root, "test/governance/milestone_scope_test.exs")
    )

    File.cp!(@workflow_path, Path.join(root, @workflow_path))

    planning_paths =
      [
        ".planning/PROJECT.md",
        ".planning/ROADMAP.md",
        ".planning/REQUIREMENTS.md",
        ".planning/STATE.md",
        ".planning/phases/73-twin-contract-and-baseline/73-BASELINE.md"
      ] ++
        Path.wildcard(".planning/phases/73-twin-contract-and-baseline/73-{*-PLAN,*-SUMMARY}.md")

    for path <- planning_paths do
      File.cp!(path, Path.join(root, path))
    end

    {_, 0} = System.cmd("git", ["init", "--quiet"], cd: root, stderr_to_stdout: true)

    tracked_paths =
      [
        "mix.exs",
        @workflow_path,
        "test/support/adoption_evidence.ex",
        "test/adoption/evidence_contract_test.exs",
        "test/governance/milestone_scope_test.exs"
      ] ++ planning_paths

    {_, 0} = System.cmd("git", ["add", "--" | tracked_paths], cd: root, stderr_to_stdout: true)

    on_exit(fn -> File.rm_rf!(root) end)
    root
  end
end
