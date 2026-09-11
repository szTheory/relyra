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

  setup_all do
    {:ok,
     repository_snapshot:
       AdoptionEvidence.repository_snapshot!(AdoptionEvidence.entries(), File.cwd!(),
         registered_test_tags: fn _path, _root -> [%{"evidence_contract" => true}] end
       )}
  end

  @tag :plan_73_17_task_1
  test "tracer resolves EVID-01 from literal ledger through a real selector and mandatory CI" do
    entries = AdoptionEvidence.entries()
    snapshot = AdoptionEvidence.repository_snapshot!(entries, File.cwd!())

    assert :ok = AdoptionEvidence.validate_entries!(entries)

    [owner | _] = AdoptionEvidence.deterministic_owners(entries, "EVID-01")
    assert owner.owner == __ENV__.file |> Path.relative_to_cwd()
    assert owner.selector == "evidence_contract"
    assert owner.lane == "ci.evidence"

    assert :ok = AdoptionEvidence.validate_repository_snapshot!(entries, snapshot)
  end

  @tag :plan_73_17_task_1
  test "repository snapshot discovers each unique owner once in lexical order" do
    entries = AdoptionEvidence.entries()
    root = File.cwd!()
    test_process = self()

    registered_test_tags = fn path, _root ->
      send(test_process, {:registered_owner, Path.relative_to(path, root)})
      [%{"evidence_contract" => true}]
    end

    snapshot =
      AdoptionEvidence.repository_snapshot!(entries, root,
        registered_test_tags: registered_test_tags
      )

    expected_owners =
      entries
      |> Enum.filter(&(&1.state == :existing and &1.evidence_kind != :external_canary))
      |> Enum.map(& &1.owner)
      |> Enum.uniq()
      |> Enum.sort()

    discovered_owners =
      Enum.map(expected_owners, fn _owner ->
        assert_receive {:registered_owner, owner}
        owner
      end)

    assert discovered_owners == expected_owners
    refute_receive {:registered_owner, _owner}
    assert Enum.map(snapshot.owners, & &1.path) == expected_owners
    assert :ok = AdoptionEvidence.validate_repository_snapshot!(entries, snapshot)
  end

  @tag :plan_73_17_task_1
  test "repository snapshot rejects missing empty duplicate malformed and unstable owners" do
    entries = AdoptionEvidence.entries()
    root = File.cwd!()

    snapshot =
      AdoptionEvidence.repository_snapshot!(entries, root,
        registered_test_tags: fn _path, _root -> [%{"evidence_contract" => true}] end
      )

    [first, second] = snapshot.owners

    assert_raise ArgumentError, ~r/#{Regex.escape(first.path)}.*missing.*snapshot/s, fn ->
      AdoptionEvidence.validate_repository_snapshot!(entries, %{snapshot | owners: [second]})
    end

    assert_raise ArgumentError, ~r/#{Regex.escape(first.path)}.*empty.*registered.*tags/s, fn ->
      AdoptionEvidence.validate_repository_snapshot!(entries, %{
        snapshot
        | owners: [%{first | tags: []}, second]
      })
    end

    assert_raise ArgumentError, ~r/#{Regex.escape(first.path)}.*duplicate.*snapshot/s, fn ->
      AdoptionEvidence.validate_repository_snapshot!(entries, %{
        snapshot
        | owners: [first, second, first]
      })
    end

    assert_raise ArgumentError, ~r/#{Regex.escape(first.path)}.*normalized.*tag/s, fn ->
      AdoptionEvidence.validate_repository_snapshot!(entries, %{
        snapshot
        | owners: [%{first | tags: [%{evidence_contract: true}]}, second]
      })
    end

    assert_raise ArgumentError, ~r/stable lexical owner order/s, fn ->
      AdoptionEvidence.validate_repository_snapshot!(entries, %{
        snapshot
        | owners: Enum.reverse(snapshot.owners)
      })
    end
  end

  @tag :plan_73_22_task_1
  test "simultaneous cold misses discover each owner once per cache identity" do
    entries = AdoptionEvidence.entries()
    root = repository_fixture!()
    parent = self()
    {:ok, discovery_counts} = Agent.start_link(fn -> %{} end)
    namespace = {:plan_73_22_task_1, System.unique_integer([:positive, :monotonic])}

    discover_registered_test_tags = fn path, fixture_root ->
      owner = Path.relative_to(path, fixture_root)
      Agent.update(discovery_counts, &Map.update(&1, owner, 1, fn count -> count + 1 end))
      Process.sleep(100)
      [%{"evidence_contract" => true}]
    end

    tasks =
      for _caller <- 1..4 do
        Task.async(fn ->
          send(parent, {:plan_73_22_ready, self()})

          receive do
            :plan_73_22_release ->
              AdoptionEvidence.repository_snapshot!(entries, root,
                registration_cache_namespace: namespace,
                discover_registered_test_tags: discover_registered_test_tags
              )
          end
        end)
      end

    for _task <- tasks do
      assert_receive {:plan_73_22_ready, caller}, 5_000
      send(caller, :plan_73_22_release)
    end

    snapshots = Task.await_many(tasks, 30_000)
    [snapshot | _remaining] = snapshots
    assert Enum.uniq(snapshots) == [snapshot]

    expected_counts = Map.new(snapshot.owners, &{&1.path, 1})
    assert Agent.get(discovery_counts, & &1) == expected_counts

    distinct_snapshot =
      AdoptionEvidence.repository_snapshot!(entries, root,
        registration_cache_namespace: {namespace, :distinct},
        discover_registered_test_tags: discover_registered_test_tags
      )

    assert distinct_snapshot == snapshot
    assert Agent.get(discovery_counts, & &1) == Map.new(snapshot.owners, &{&1.path, 2})
  end

  @tag :plan_73_17_task_2
  test "pure snapshot mutations stay bounded and reject every degenerate field" do
    entries = AdoptionEvidence.entries()
    root = File.cwd!()
    {:ok, discovery_count} = Agent.start_link(fn -> 0 end)

    snapshot =
      AdoptionEvidence.repository_snapshot!(entries, root,
        registered_test_tags: fn _path, _root ->
          Agent.update(discovery_count, &(&1 + 1))
          [%{"evidence_contract" => true}]
        end
      )

    captured_count = Agent.get(discovery_count, & &1)
    [first_owner | remaining_owners] = snapshot.owners

    mutations = [
      fn clean ->
        %{clean | workflow: String.replace(clean.workflow, "run: mix ci.evidence", "run: mix qa")}
      end,
      fn clean ->
        put_in(
          clean.aliases["ci.evidence"],
          Enum.map(clean.aliases["ci.evidence"], &(&1 <> " --exclude evidence_contract"))
        )
      end,
      fn clean -> %{clean | owners: remaining_owners} end,
      fn clean -> %{clean | owners: [%{first_owner | tags: []} | remaining_owners]} end
    ]

    mutation_messages = fn ordered_mutations ->
      for _iteration <- 1..10, mutate <- ordered_mutations do
        error =
          assert_raise ArgumentError, fn ->
            AdoptionEvidence.validate_repository_snapshot!(entries, mutate.(snapshot))
          end

        Exception.message(error)
      end
    end

    forward_messages = mutation_messages.(mutations)
    reverse_messages = mutation_messages.(Enum.reverse(mutations))

    assert Enum.sort(forward_messages) == Enum.sort(reverse_messages)

    for _iteration <- 1..25 do
      assert :ok = AdoptionEvidence.validate_repository_snapshot!(entries, snapshot)
    end

    assert Agent.get(discovery_count, & &1) == captured_count

    assert_raise ArgumentError, ~r/aliases.*normalized/, fn ->
      AdoptionEvidence.validate_repository_snapshot!(entries, %{
        snapshot
        | aliases: Map.put(snapshot.aliases, :unused_alias, :malformed)
      })
    end

    assert_raise ArgumentError, ~r/governed inputs.*unique/, fn ->
      AdoptionEvidence.validate_repository_snapshot!(entries, %{
        snapshot
        | governed_inputs: snapshot.governed_inputs ++ [hd(snapshot.governed_inputs)]
      })
    end
  end

  @tag :plan_73_22_task_2
  test "governed inputs stay bound to the complete normalized capture inventory" do
    entries = AdoptionEvidence.entries()

    capture_snapshot = fn ->
      root = repository_fixture!()

      AdoptionEvidence.repository_snapshot!(entries, root,
        registered_test_tags: fn _path, _root -> [%{"evidence_contract" => true}] end
      )
    end

    clean = capture_snapshot.()
    governed_input_inventory = Map.get(clean, :governed_input_inventory)
    assert is_list(governed_input_inventory)
    assert clean.governed_inputs == governed_input_inventory
    assert clean.governed_inputs == Enum.sort(clean.governed_inputs)
    assert clean.governed_inputs == Enum.uniq(clean.governed_inputs)
    assert :ok = AdoptionEvidence.validate_repository_snapshot!(entries, clean)

    fixed_omission = capture_snapshot.()

    assert_governed_inventory_error(
      entries,
      %{
        fixed_omission
        | governed_inputs: List.delete(fixed_omission.governed_inputs, ".planning/STATE.md"),
          workflow: "workflow reduction must not run"
      },
      ~r/governed inputs.*inventory.*missing=.*\.planning\/STATE\.md.*unexpected=\[\]/s
    )

    discovered_omission = capture_snapshot.()

    discovered =
      Enum.find(discovered_omission.governed_inputs, &String.ends_with?(&1, "-PLAN.md"))

    assert discovered

    assert_governed_inventory_error(
      entries,
      %{
        discovered_omission
        | governed_inputs: List.delete(discovered_omission.governed_inputs, discovered),
          workflow: "workflow reduction must not run"
      },
      ~r/governed inputs.*inventory.*missing=.*#{Regex.escape(discovered)}.*unexpected=\[\]/s
    )

    substitution = capture_snapshot.()
    [first | remaining] = substitution.governed_inputs

    assert_governed_inventory_error(
      entries,
      %{
        substitution
        | governed_inputs: Enum.sort(["README.md" | remaining]),
          workflow: "workflow reduction must not run"
      },
      ~r/governed inputs.*inventory.*missing=.*#{Regex.escape(first)}.*unexpected=.*README\.md/s
    )

    for replacement <- ["../README.md", Path.join(File.cwd!(), "README.md")] do
      invalid_path = capture_snapshot.()
      [_first | remaining] = invalid_path.governed_inputs

      assert_governed_inventory_error(
        entries,
        %{
          invalid_path
          | governed_inputs: [replacement | remaining],
            workflow: "workflow reduction must not run"
        },
        ~r/governed inputs.*normalized repository-relative path.*#{Regex.escape(replacement)}/s
      )
    end

    reordered = capture_snapshot.()

    assert_governed_inventory_error(
      entries,
      %{
        reordered
        | governed_inputs: Enum.reverse(reordered.governed_inputs),
          workflow: "workflow reduction must not run"
      },
      ~r/governed inputs.*stable lexical order/s
    )
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

  test "repository ownership diagnostics name every broken seam and the clean control passes", %{
    repository_snapshot: snapshot
  } do
    entries = AdoptionEvidence.entries()
    root = repository_fixture!()

    assert :ok = AdoptionEvidence.validate_repository_snapshot!(entries, snapshot)

    [owner | _] = AdoptionEvidence.deterministic_owners(entries, "EVID-01")

    assert_raise ArgumentError, ~r/EVID-01.*missing owner file.*missing_owner/s, fn ->
      AdoptionEvidence.validate_repository!(
        replace_entry(entries, owner, %{owner: "test/missing_owner.exs"}),
        root
      )
    end

    assert_raise ArgumentError, ~r/EVID-01.*selector missing_selector matches zero tests/s, fn ->
      AdoptionEvidence.validate_repository_snapshot!(
        replace_entry(entries, owner, %{selector: "missing_selector"}),
        snapshot
      )
    end

    unwired_step = String.replace(fixture_evidence_step(), owner.owner <> " ", "")

    assert_raise ArgumentError, ~r/EVID-01.*alias ci\.evidence is not wired.*owner/s, fn ->
      AdoptionEvidence.validate_repository_snapshot!(entries, %{
        snapshot
        | aliases: Map.put(snapshot.aliases, "ci.evidence", [unwired_step])
      })
    end

    workflow = String.replace(snapshot.workflow, "run: mix ci.evidence", "run: mix qa")

    assert_raise ArgumentError,
                 ~r/EVID-01.*enabled blocking.*mix ci\.evidence.*jobs\.security/s,
                 fn ->
                   AdoptionEvidence.validate_repository_snapshot!(entries, %{
                     snapshot
                     | workflow: workflow
                   })
                 end
  end

  test "comments, strings, and tagged modules without tests cannot own a selector", %{
    repository_snapshot: snapshot
  } do
    entries = AdoptionEvidence.entries()

    inert_snapshot =
      replace_snapshot_owner_tags(
        snapshot,
        "test/adoption/evidence_contract_test.exs",
        [%{"test" => "inert source shapes"}]
      )

    assert_raise ArgumentError,
                 ~r/EVID-01.*selector evidence_contract matches zero tests/s,
                 fn ->
                   AdoptionEvidence.validate_repository_snapshot!(entries, inert_snapshot)
                 end
  end

  test "workflow ownership requires the enabled blocking Evidence contract step in security", %{
    repository_snapshot: snapshot
  } do
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
      assert_raise ArgumentError, ~r/EVID-01.*enabled blocking.*jobs\.security/s, fn ->
        AdoptionEvidence.validate_repository_snapshot!(entries, %{
          snapshot
          | workflow: mutate.(snapshot.workflow)
        })
      end
    end
  end

  @tag :plan_73_06_task_1
  test "automated commands reject shell substitution hidden in environment assignments" do
    assert_raise ArgumentError, ~r/shell-shaped/, fn ->
      AdoptionEvidence.validate_automated_command!(
        "EVIL=$(id) mix ci.evidence",
        File.cwd!()
      )
    end
  end

  @tag :plan_73_06_task_1
  test "automated commands reject filters whose effective test selection is empty", %{
    repository_snapshot: snapshot
  } do
    entries = AdoptionEvidence.entries()

    for command <- [
          "mix test test/adoption/evidence_contract_test.exs test/governance/milestone_scope_test.exs --only evidence_contract --exclude no_such_selector --warnings-as-errors",
          "mix test test/adoption/evidence_contract_test.exs test/governance/milestone_scope_test.exs --only=evidence_contract --exclude=no_such_selector --warnings-as-errors"
        ] do
      assert :ok =
               AdoptionEvidence.validate_repository_snapshot!(entries, %{
                 snapshot
                 | aliases: Map.put(snapshot.aliases, "ci.evidence", ["cmd " <> command])
               })
    end

    commands = [
      "mix test test/governance/milestone_scope_test.exs --only no_such_selector --warnings-as-errors",
      "mix test test/governance/milestone_scope_test.exs --only=no_such_selector --warnings-as-errors",
      "mix test test/governance/milestone_scope_test.exs --exclude evidence_contract --warnings-as-errors",
      "mix test test/governance/milestone_scope_test.exs --exclude=evidence_contract --warnings-as-errors"
    ]

    for command <- commands do
      assert_raise ArgumentError, ~r/zero selected tests/, fn ->
        AdoptionEvidence.validate_repository_snapshot!(entries, %{
          snapshot
          | aliases: Map.put(snapshot.aliases, "ci.evidence", ["cmd " <> command])
        })
      end
    end

    for command <- [
          "mix test test/adoption/evidence_contract_test.exs --only --warnings-as-errors",
          "mix test test/adoption/evidence_contract_test.exs --only= --warnings-as-errors",
          "mix test test/adoption/evidence_contract_test.exs --only evidence_contract --only evidence_contract --warnings-as-errors"
        ] do
      assert_raise ArgumentError, ~r/(missing its filter value|duplicate filter values)/, fn ->
        AdoptionEvidence.validate_repository_snapshot!(entries, %{
          snapshot
          | aliases: Map.put(snapshot.aliases, "ci.evidence", ["cmd " <> command])
        })
      end
    end
  end

  @tag :plan_73_06_task_1
  test "selector ownership does not cross ExUnit module boundaries", %{
    repository_snapshot: snapshot
  } do
    entries = AdoptionEvidence.entries()

    unselected_snapshot =
      replace_snapshot_owner_tags(
        snapshot,
        "test/adoption/evidence_contract_test.exs",
        [%{"test" => "not selected"}]
      )

    assert_raise ArgumentError, ~r/selector evidence_contract matches zero tests/, fn ->
      AdoptionEvidence.validate_repository_snapshot!(entries, unselected_snapshot)
    end
  end

  @tag :plan_73_06_task_1
  test "selector ownership recognizes tag keys rather than incidental atom values", %{
    repository_snapshot: snapshot
  } do
    entries = AdoptionEvidence.entries()

    wrong_key_snapshot =
      replace_snapshot_owner_tags(
        snapshot,
        "test/adoption/evidence_contract_test.exs",
        [%{"other" => "evidence_contract", "test" => "tag value is not the selector"}]
      )

    assert_raise ArgumentError, ~r/selector evidence_contract matches zero tests/, fn ->
      AdoptionEvidence.validate_repository_snapshot!(entries, wrong_key_snapshot)
    end
  end

  @tag :plan_73_06_task_2
  test "mandatory workflow ownership rejects event-conditional and fallible steps", %{
    repository_snapshot: snapshot
  } do
    entries = AdoptionEvidence.entries()

    literal_false =
      String.replace(
        snapshot.workflow,
        "      - name: Evidence contract\n        run: mix ci.evidence",
        "      - name: Evidence contract\n        continue-on-error: false\n        run: mix ci.evidence"
      )

    assert :ok =
             AdoptionEvidence.validate_repository_snapshot!(entries, %{
               snapshot
               | workflow: literal_false
             })

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
      assert_raise ArgumentError, ~r/enabled blocking.*jobs\.security/s, fn ->
        AdoptionEvidence.validate_repository_snapshot!(entries, %{
          snapshot
          | workflow: mutate.(snapshot.workflow)
        })
      end
    end
  end

  @tag :plan_73_09_task_1
  test "automated commands have one fully consumed non-shell argv meaning" do
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
  test "named owners reject decoy tuples outside the captured Mix alias", %{
    repository_snapshot: snapshot
  } do
    assert_raise ArgumentError, ~r/alias ci\.evidence.*fresh-process/, fn ->
      AdoptionEvidence.validate_repository_snapshot!(AdoptionEvidence.entries(), %{
        snapshot
        | aliases: Map.put(snapshot.aliases, "ci.evidence", [])
      })
    end
  end

  @tag :cwd_isolation
  test "fixture Mix inspection never changes the VM working directory" do
    root = repository_fixture!()
    mix_path = Path.join(root, "mix.exs")
    original_cwd = File.cwd!()

    File.write!(
      mix_path,
      "Process.sleep(150)\n" <> fixture_mix_project([])
    )

    parent = self()

    validation =
      Task.async(fn ->
        result =
          try do
            AdoptionEvidence.validate_automated_command!("mix ci.evidence", root)
          rescue
            ArgumentError -> :ok
          end

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
  test "selector ownership requires genuinely registered ExUnit tests", %{
    repository_snapshot: snapshot
  } do
    entries = AdoptionEvidence.entries()

    unregistered_snapshot =
      replace_snapshot_owner_tags(
        snapshot,
        "test/adoption/evidence_contract_test.exs",
        [%{"test" => "only genuinely registered tags reach the snapshot"}]
      )

    assert_raise ArgumentError, ~r/selector evidence_contract matches zero tests/, fn ->
      AdoptionEvidence.validate_repository_snapshot!(entries, unregistered_snapshot)
    end
  end

  @tag :plan_73_12_task_1
  test "repository ownership rejects an alias with an empty effective selection", %{
    repository_snapshot: snapshot
  } do
    entries = AdoptionEvidence.entries()

    hollow_step =
      fixture_evidence_step() <>
        " --exclude evidence_contract"

    assert_raise ArgumentError,
                 ~r/EVID-01.*row.*ci\.evidence.*test\/adoption\/evidence_contract_test\.exs.*zero effective selected tests/s,
                 fn ->
                   AdoptionEvidence.validate_repository_snapshot!(entries, %{
                     snapshot
                     | aliases: Map.put(snapshot.aliases, "ci.evidence", [hollow_step])
                   })
                 end
  end

  @tag :plan_73_12_task_1
  test "every alias owner must retain an effective selected test", %{
    repository_snapshot: snapshot
  } do
    entries = AdoptionEvidence.entries()
    empty_owner = "test/adoption/empty_owner_test.exs"

    step =
      "cmd mix test test/adoption/evidence_contract_test.exs #{empty_owner} " <>
        "--only evidence_contract --warnings-as-errors"

    mutated = %{
      snapshot
      | aliases: Map.put(snapshot.aliases, "ci.evidence", [step]),
        owners:
          (snapshot.owners ++ [%{path: empty_owner, tags: [%{"test" => "not evidence"}]}])
          |> Enum.sort_by(& &1.path)
    }

    assert_raise ArgumentError,
                 ~r/alias ci\.evidence.*#{Regex.escape(empty_owner)}.*zero effective selected tests/s,
                 fn -> AdoptionEvidence.validate_repository_snapshot!(entries, mutated) end
  end

  @tag :plan_73_12_task_1
  test "repository alias uses the shared filter parser and the checked-in alias remains valid", %{
    repository_snapshot: snapshot
  } do
    entries = AdoptionEvidence.entries()

    for step <- [
          fixture_evidence_step() <> " --only evidence_contract",
          fixture_evidence_step() <> " --only",
          fixture_evidence_step() <> " --only="
        ] do
      assert_raise ArgumentError, ~r/(duplicate filter values|missing its filter value)/, fn ->
        AdoptionEvidence.validate_repository_snapshot!(entries, %{
          snapshot
          | aliases: Map.put(snapshot.aliases, "ci.evidence", [step])
        })
      end
    end

    assert :ok = AdoptionEvidence.validate_repository_snapshot!(entries, snapshot)
  end

  @tag :plan_73_09_task_2
  test "security job ownership is absent-or-literal-false fallible", %{
    repository_snapshot: snapshot
  } do
    entries = AdoptionEvidence.entries()

    literal_false =
      String.replace(
        snapshot.workflow,
        "  security:\n",
        "  security:\n    continue-on-error: false\n",
        global: false
      )

    assert :ok =
             AdoptionEvidence.validate_repository_snapshot!(entries, %{
               snapshot
               | workflow: literal_false
             })

    for value <- ["true", "${{ github.ref != '' }}", ~s("false")] do
      workflow =
        String.replace(
          snapshot.workflow,
          "  security:\n",
          "  security:\n    continue-on-error: #{value}\n",
          global: false
        )

      assert_raise ArgumentError, ~r/jobs\.security.*continue-on-error/s, fn ->
        AdoptionEvidence.validate_repository_snapshot!(entries, %{snapshot | workflow: workflow})
      end
    end
  end

  @tag :plan_73_09_task_2
  test "alternate paths-ignore patterns cannot suppress planning evidence", %{
    repository_snapshot: snapshot
  } do
    entries = AdoptionEvidence.entries()

    for pattern <- [
          ".planning/*",
          ".planning/**",
          ".planning/**/*",
          ".planning/**/**",
          "**"
        ] do
      workflow = replace_pull_request_filter(snapshot.workflow, "paths-ignore", [pattern])

      assert_raise ArgumentError, ~r/pull_request.*governed input/s, fn ->
        AdoptionEvidence.validate_repository_snapshot!(entries, %{snapshot | workflow: workflow})
      end
    end

    for pattern <- [".planning/STAT?.md", ".planning/[R]OADMAP.md"] do
      workflow = replace_pull_request_filter(snapshot.workflow, "paths-ignore", [pattern])

      assert_raise ArgumentError, ~r/pull_request.*unsupported path pattern/, fn ->
        AdoptionEvidence.validate_repository_snapshot!(entries, %{snapshot | workflow: workflow})
      end
    end
  end

  @tag :plan_73_09_task_2
  test "positive paths are rejected regardless of ordered exclusions or re-inclusions", %{
    repository_snapshot: snapshot
  } do
    entries = AdoptionEvidence.entries()

    excluded_workflow =
      replace_pull_request_filter(snapshot.workflow, "paths", [
        "**",
        "!.planning/**"
      ])

    assert_raise ArgumentError, ~r/pull_request.*must not use positive paths/s, fn ->
      AdoptionEvidence.validate_repository_snapshot!(entries, %{
        snapshot
        | workflow: excluded_workflow
      })
    end

    included_workflow =
      replace_pull_request_filter(snapshot.workflow, "paths", [
        "**",
        "!.planning/**",
        ".planning/**"
      ])

    assert_raise ArgumentError, ~r/pull_request.*must not use positive paths/s, fn ->
      AdoptionEvidence.validate_repository_snapshot!(entries, %{
        snapshot
        | workflow: included_workflow
      })
    end

    push_workflow = replace_push_filter(snapshot.workflow, "paths", ["**", "!.planning/**"])

    assert_raise ArgumentError, ~r/push.*must not use positive paths/s, fn ->
      AdoptionEvidence.validate_repository_snapshot!(entries, %{
        snapshot
        | workflow: push_workflow
      })
    end
  end

  @tag :plan_73_09_task_2
  test "path filters reject empty and unsupported grammars before positive policy", %{
    repository_snapshot: snapshot
  } do
    entries = AdoptionEvidence.entries()

    for replacement <- [
          "  pull_request:\n    paths: []",
          "  pull_request:\n    paths:\n      - \"[\""
        ] do
      workflow =
        String.replace(
          snapshot.workflow,
          "  pull_request:\n    paths-ignore:\n      - \"prompts/**\"",
          replacement,
          global: false
        )

      assert_raise ArgumentError, ~r/(non-empty block list|unclosed.*character class)/, fn ->
        AdoptionEvidence.validate_repository_snapshot!(entries, %{snapshot | workflow: workflow})
      end
    end

    workflow =
      replace_pull_request_filter(snapshot.workflow, "paths", [
        "**",
        "!.planning/ROADMAP.md",
        ".planning/[R]OADMAP.md"
      ])

    assert_raise ArgumentError, ~r/pull_request.*unsupported path pattern/s, fn ->
      AdoptionEvidence.validate_repository_snapshot!(entries, %{snapshot | workflow: workflow})
    end
  end

  @tag :plan_73_12_task_2
  test "mandatory pull request and main push events reject every positive paths filter", %{
    repository_snapshot: snapshot
  } do
    entries = AdoptionEvidence.entries()

    former_sample = [
      ".planning/ROADMAP.md",
      ".planning/REQUIREMENTS.md",
      ".planning/STATE.md",
      ".planning/phases/73-twin-contract-and-baseline/73-09-PLAN.md",
      ".planning/phases/73-twin-contract-and-baseline/73-BASELINE.md"
    ]

    for replace <- [&replace_pull_request_filter/3, &replace_push_filter/3] do
      workflow = replace.(snapshot.workflow, "paths", former_sample)

      assert_raise ArgumentError,
                   ~r/workflow (pull_request|push) must not use positive paths/,
                   fn ->
                     AdoptionEvidence.validate_repository_snapshot!(entries, %{
                       snapshot
                       | workflow: workflow
                     })
                   end
    end
  end

  @tag :plan_73_12_task_2
  test "paths-ignore cannot suppress any governed source or planning class", %{
    repository_snapshot: snapshot
  } do
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
      replace =
        if event == :pull_request,
          do: &replace_pull_request_filter/3,
          else: &replace_push_filter/3

      workflow = replace.(snapshot.workflow, "paths-ignore", [path])

      assert_raise ArgumentError,
                   ~r/workflow #{event} path filter skips governed input #{Regex.escape(path)}/,
                   fn ->
                     AdoptionEvidence.validate_repository_snapshot!(entries, %{
                       snapshot
                       | workflow: workflow
                     })
                   end
    end
  end

  @tag :plan_73_12_task_2
  test "checked-in prompts ignore and unfiltered required events remain mandatory", %{
    repository_snapshot: snapshot
  } do
    entries = AdoptionEvidence.entries()
    assert :ok = AdoptionEvidence.validate_repository_snapshot!(entries, snapshot)

    workflow =
      snapshot.workflow
      |> String.replace(
        "  pull_request:\n    paths-ignore:\n      - \"prompts/**\"",
        "  pull_request:"
      )
      |> String.replace(
        "  push:\n    branches:\n      - main\n    paths-ignore:\n      - \"prompts/**\"",
        "  push:\n    branches:\n      - main"
      )

    assert :ok =
             AdoptionEvidence.validate_repository_snapshot!(entries, %{
               snapshot
               | workflow: workflow
             })
  end

  @tag :plan_73_14_task_1
  test "push requires exactly one positive main branch selector", %{
    repository_snapshot: snapshot
  } do
    entries = AdoptionEvidence.entries()

    invalid_branches = [
      ["main", "!main"],
      ["!main", "main"],
      ["main", "release"],
      ["!main"]
    ]

    for branches <- invalid_branches do
      push =
        ["  push:", "    branches:"] ++
          Enum.map(branches, &"      - \"#{&1}\"") ++
          ["    paths-ignore:", "      - \"prompts/**\""]

      workflow = replace_push_event(snapshot.workflow, push)

      assert_raise ArgumentError, ~r/workflow push.*exactly one positive main branch/, fn ->
        AdoptionEvidence.validate_repository_snapshot!(entries, %{snapshot | workflow: workflow})
      end
    end

    workflow =
      replace_push_event(snapshot.workflow, [
        "  push:",
        "    branches:",
        "      - main",
        "    branches-ignore:",
        "      - release"
      ])

    assert_raise ArgumentError, ~r/workflow push.*branches-ignore/, fn ->
      AdoptionEvidence.validate_repository_snapshot!(entries, %{snapshot | workflow: workflow})
    end
  end

  @tag :plan_73_14_task_1
  test "push rejects duplicate events, repeated keys, and unknown direct keys", %{
    repository_snapshot: snapshot
  } do
    entries = AdoptionEvidence.entries()

    fixtures = [
      {"duplicate event",
       fn workflow -> workflow <> "\n  push:\n    branches:\n      - main\n" end,
       ~r/workflow push.*exactly once/},
      {"duplicate branches",
       &replace_push_event(&1, [
         "  push:",
         "    branches:",
         "      - main",
         "    branches:",
         "      - main"
       ]), ~r/workflow push.*duplicate.*branches/},
      {"duplicate paths-ignore",
       &replace_push_event(&1, [
         "  push:",
         "    branches:",
         "      - main",
         "    paths-ignore:",
         "      - prompts/**",
         "    paths-ignore:",
         "      - docs/**"
       ]), ~r/workflow push.*duplicate.*paths-ignore/},
      {"unknown key",
       &replace_push_event(&1, [
         "  push:",
         "    branches:",
         "      - main",
         "    tags-ignore:",
         "      - preview"
       ]), ~r/workflow push.*unsupported key tags-ignore/}
    ]

    for {_name, mutate, diagnostic} <- fixtures do
      workflow = mutate.(snapshot.workflow)

      assert_raise ArgumentError, diagnostic, fn ->
        AdoptionEvidence.validate_repository_snapshot!(entries, %{snapshot | workflow: workflow})
      end
    end
  end

  @tag :plan_73_14_task_1
  test "checked-in push event reaches the real evidence owner chain", %{
    repository_snapshot: snapshot
  } do
    assert :ok =
             AdoptionEvidence.validate_repository_snapshot!(AdoptionEvidence.entries(), snapshot)
  end

  @tag :plan_73_14_task_2
  test "pull request rejects restrictive activity filters including empty types", %{
    repository_snapshot: snapshot
  } do
    entries = AdoptionEvidence.entries()

    for types <- [["opened"], ["synchronize"], ["opened", "synchronize"], []] do
      pull_request =
        ["  pull_request:", "    types:"] ++ Enum.map(types, &"      - \"#{&1}\"")

      workflow = replace_pull_request_event(snapshot.workflow, pull_request)

      assert_raise ArgumentError, ~r/workflow pull_request.*unsupported key types/, fn ->
        AdoptionEvidence.validate_repository_snapshot!(entries, %{snapshot | workflow: workflow})
      end
    end
  end

  @tag :plan_73_14_task_2
  test "pull request rejects duplicate events, keys, and unsupported grammar", %{
    repository_snapshot: snapshot
  } do
    entries = AdoptionEvidence.entries()

    fixtures = [
      {fn workflow -> workflow <> "\n  pull_request:\n" end,
       ~r/workflow pull_request.*exactly once/},
      {&replace_pull_request_event(&1, [
         "  pull_request:",
         "    paths-ignore:",
         "      - prompts/**",
         "    paths-ignore:",
         "      - docs/**"
       ]), ~r/workflow pull_request.*duplicate.*paths-ignore/},
      {&replace_pull_request_event(&1, [
         "  pull_request:",
         "    paths:",
         "      - test/**",
         "    paths:",
         "      - lib/**"
       ]), ~r/workflow pull_request.*duplicate.*paths/},
      {&replace_pull_request_event(&1, [
         "  pull_request:",
         "    branches:",
         "      - main"
       ]), ~r/workflow pull_request.*unsupported key branches/},
      {&replace_pull_request_event(&1, [
         "  pull_request:",
         "    \"types\":",
         "      - opened"
       ]), ~r/workflow pull_request.*unsupported key types/},
      {&replace_pull_request_event(&1, ["  pull_request: []"]),
       ~r/workflow pull_request.*mapping block/}
    ]

    for {mutate, diagnostic} <- fixtures do
      workflow = mutate.(snapshot.workflow)

      assert_raise ArgumentError, diagnostic, fn ->
        AdoptionEvidence.validate_repository_snapshot!(entries, %{snapshot | workflow: workflow})
      end
    end
  end

  @tag :plan_73_14_task_2
  test "checked-in and unfiltered pull request events remain mandatory", %{
    repository_snapshot: snapshot
  } do
    entries = AdoptionEvidence.entries()
    assert :ok = AdoptionEvidence.validate_repository_snapshot!(entries, snapshot)

    workflow = replace_pull_request_event(snapshot.workflow, ["  pull_request:"])

    assert :ok =
             AdoptionEvidence.validate_repository_snapshot!(entries, %{
               snapshot
               | workflow: workflow
             })
  end

  @tag :plan_73_18_task_1
  test "checked-in prompts ignore remains valid for both mandatory events", %{
    repository_snapshot: snapshot
  } do
    assert :ok =
             AdoptionEvidence.validate_repository_snapshot!(AdoptionEvidence.entries(), snapshot)

    prompts_only =
      snapshot.workflow
      |> replace_pull_request_filter("paths-ignore", ["prompts/**"])
      |> replace_push_filter("paths-ignore", ["prompts/**"])

    assert :ok =
             AdoptionEvidence.validate_repository_snapshot!(AdoptionEvidence.entries(), %{
               snapshot
               | workflow: prompts_only
             })
  end

  @tag :plan_73_18_task_1
  test "unsupported path grammar fails closed before governed input comparison", %{
    repository_snapshot: snapshot
  } do
    entries = AdoptionEvidence.entries()

    unsupported_patterns = [
      ".planning/STATE.md?",
      ".planning/STATE.md+",
      ".planning/[S]TATE.md",
      ".planning/{STATE,ROADMAP}.md",
      ".planning/(STATE).md",
      ".planning/@(STATE).md",
      ~S(.planning/STATE\.md),
      ".planning/***",
      ".planning/**suffix",
      "",
      ".",
      "../prompts/**",
      "/prompts/**",
      "prompts//**",
      "prompts/\t**"
    ]

    for {event, replace} <- [
          {"pull_request", &replace_pull_request_filter/3},
          {"push", &replace_push_filter/3}
        ],
        pattern <- unsupported_patterns do
      workflow = replace.(snapshot.workflow, "paths-ignore", [pattern])

      error =
        assert_raise ArgumentError, fn ->
          AdoptionEvidence.validate_repository_snapshot!(entries, %{
            snapshot
            | workflow: workflow
          })
        end

      message = Exception.message(error)
      assert message =~ "workflow #{event}"
      assert message =~ "unsupported path pattern"
      assert message =~ inspect(pattern)
      refute message =~ "skips governed input"
    end
  end

  @tag :plan_73_18_task_1
  test "one invalid paths-ignore sibling rejects the ordered list", %{
    repository_snapshot: snapshot
  } do
    entries = AdoptionEvidence.entries()
    invalid = ".planning/STATE.md?"

    for {event, replace} <- [
          {"pull_request", &replace_pull_request_filter/3},
          {"push", &replace_push_filter/3}
        ],
        patterns <- [["prompts/**", invalid], [invalid, "prompts/**"]] do
      workflow = replace.(snapshot.workflow, "paths-ignore", patterns)

      error =
        assert_raise ArgumentError, fn ->
          AdoptionEvidence.validate_repository_snapshot!(entries, %{
            snapshot
            | workflow: workflow
          })
        end

      assert Exception.message(error) =~
               "workflow #{event} contains unsupported path pattern #{inspect(invalid)}"
    end
  end

  @tag :plan_73_18_task_2
  test "tracked regular lexical owners and checked-in owners remain valid", %{
    repository_snapshot: checked_in_snapshot
  } do
    entries = AdoptionEvidence.entries()
    assert :ok = AdoptionEvidence.validate_repository_snapshot!(entries, checked_in_snapshot)

    root = repository_fixture!()
    owner = "test/provenance/tracked_owner_test.exs"
    write_fixture_file!(root, owner, "raise \"owner source must not compile in this fixture\"\n")
    git_add_fixture!(root, [owner])

    snapshot =
      entries
      |> replace_first_owner(owner)
      |> AdoptionEvidence.repository_snapshot!(root,
        registered_test_tags: fn path, fixture_root ->
          send(self(), {:registered_owner, Path.relative_to(path, fixture_root)})
          [%{"evidence_contract" => true}]
        end
      )

    assert %{path: ^owner} = Enum.find(snapshot.owners, &(&1.path == owner))
  end

  @tag :plan_73_18_task_2
  test "owner provenance rejects symlinks escapes absolute and untracked paths before discovery" do
    entries = AdoptionEvidence.entries()
    root = repository_fixture!()

    tracked_target = "test/provenance/tracked_target_test.exs"
    untracked_owner = "test/provenance/untracked_owner_test.exs"
    leaf_inside = "test/provenance/leaf_inside_test.exs"
    leaf_outside = "test/provenance/leaf_outside_test.exs"
    intermediate_link = "test/linked_provenance"
    intermediate_owner = intermediate_link <> "/intermediate_owner_test.exs"
    intermediate_target = "test/provenance/intermediate_owner_test.exs"
    outside_owner = root <> "-outside-owner.exs"

    for path <- [tracked_target, untracked_owner, intermediate_target] do
      write_fixture_file!(root, path, "raise \"invalid owner reached compilation\"\n")
    end

    File.write!(outside_owner, "raise \"outside owner reached compilation\"\n")
    on_exit(fn -> File.rm(outside_owner) end)

    File.ln_s!("tracked_target_test.exs", Path.join(root, leaf_inside))
    File.ln_s!(outside_owner, Path.join(root, leaf_outside))
    File.ln_s!("provenance", Path.join(root, intermediate_link))

    git_add_fixture!(root, [tracked_target, leaf_inside, leaf_outside, intermediate_link])

    rejected = [
      {intermediate_owner, ~r/symbolic link.*test\/linked_provenance/},
      {leaf_inside, ~r/symbolic link.*leaf_inside_test\.exs/},
      {leaf_outside, ~r/symbolic link.*leaf_outside_test\.exs/},
      {"../#{Path.basename(outside_owner)}", ~r/normalized repository-relative/},
      {outside_owner, ~r/normalized repository-relative/},
      {untracked_owner, ~r/not tracked.*#{Regex.escape(untracked_owner)}/}
    ]

    for {owner, diagnostic} <- rejected do
      test_process = self()

      error =
        assert_raise ArgumentError, diagnostic, fn ->
          entries
          |> replace_first_owner(owner)
          |> AdoptionEvidence.repository_snapshot!(root,
            registered_test_tags: fn path, fixture_root ->
              relative = Path.relative_to(path, fixture_root)
              send(test_process, {:registered_owner, relative})
              [%{"evidence_contract" => true}]
            end
          )
        end

      assert Exception.message(error) =~ "missing owner file"
      refute_receive {:registered_owner, ^owner}
    end
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

  defp replace_snapshot_owner_tags(snapshot, path, tags) do
    owners =
      Enum.map(snapshot.owners, fn
        %{path: ^path} = owner -> %{owner | tags: tags}
        owner -> owner
      end)

    %{snapshot | owners: owners}
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

  defp replace_first_owner(entries, owner) do
    [first | _] = AdoptionEvidence.deterministic_owners(entries, "EVID-01")
    replace_entry(entries, first, %{owner: owner})
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

  defp replace_push_event(workflow, replacement_lines) do
    String.replace(
      workflow,
      "  push:\n    branches:\n      - main\n    paths-ignore:\n      - \"prompts/**\"",
      Enum.join(replacement_lines, "\n"),
      global: false
    )
  end

  defp replace_pull_request_event(workflow, replacement_lines) do
    String.replace(
      workflow,
      "  pull_request:\n    paths-ignore:\n      - \"prompts/**\"",
      Enum.join(replacement_lines, "\n"),
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

  defp write_fixture_file!(root, path, contents) do
    destination = Path.join(root, path)
    File.mkdir_p!(Path.dirname(destination))
    File.write!(destination, contents)
  end

  defp git_add_fixture!(root, paths) do
    {output, status} = System.cmd("git", ["add", "--" | paths], cd: root, stderr_to_stdout: true)
    assert status == 0, output
  end

  defp assert_governed_inventory_error(entries, snapshot, diagnostic) do
    error =
      assert_raise ArgumentError, diagnostic, fn ->
        AdoptionEvidence.validate_repository_snapshot!(entries, snapshot)
      end

    refute Exception.message(error) =~ "workflow is missing"
  end
end
