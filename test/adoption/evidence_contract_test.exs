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

    assert_raise ArgumentError, ~r/EVID-01.*workflow has no executable mix ci\.evidence/s, fn ->
      AdoptionEvidence.validate_repository!(entries, root)
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

  defp repository_fixture! do
    root =
      Path.join(System.tmp_dir!(), "relyra-evidence-#{System.unique_integer([:positive])}")

    File.mkdir_p!(Path.join(root, "test/adoption"))
    File.mkdir_p!(Path.join(root, ".github/workflows"))
    File.cp!("mix.exs", Path.join(root, "mix.exs"))
    File.cp!(__ENV__.file, Path.join(root, "test/adoption/evidence_contract_test.exs"))
    File.cp!(@workflow_path, Path.join(root, @workflow_path))
    on_exit(fn -> File.rm_rf!(root) end)
    root
  end
end
