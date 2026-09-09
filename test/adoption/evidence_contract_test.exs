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
end
