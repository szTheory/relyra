defmodule Relyra.Governance.MilestoneScopeTest do
  use ExUnit.Case, async: true

  @moduletag :evidence_contract

  @baseline_path ".planning/phases/73-twin-contract-and-baseline/73-BASELINE.md"
  @finding_columns [
    "Finding ID",
    "Severity",
    "Category",
    "Finding",
    "Reproducible Evidence",
    "Disposition",
    "Owner",
    "Target Phase",
    "Approval Class",
    "Blocker State",
    "Revisit Date"
  ]
  @ci_columns [
    "Surface",
    "Current Observation",
    "Measured Duration",
    "Duplication",
    "Cache Declaration",
    "Owning Lane",
    "Required-Check State",
    "Failure Evidence",
    "Provenance"
  ]
  @categories ~w(Correctness Security Integration Readability Documentation Artifacts CI)
  @severities ~w(Critical High Medium Low Informational)

  test "dated baseline publishes the complete severity-ranked findings contract" do
    baseline = File.read!(@baseline_path)
    sections = baseline_sections(baseline)

    assert Map.keys(sections) |> MapSet.new() ==
             MapSet.new([
               "Summary",
               "Severity and Disposition Policy",
               "Findings Ledger",
               "CI Baseline Snapshot",
               "Remote Mutation Boundary",
               "Security/Compliance Breadcrumbs"
             ])

    assert sections["Summary"] =~ "2026-09-09"

    assert sections["Severity and Disposition Policy"] =~
             "Critical, High, Medium, Low, and Informational"

    {columns, rows} = baseline_rows(baseline)
    assert columns == @finding_columns
    assert rows != []

    assert rows |> Enum.map(& &1["Category"]) |> MapSet.new() == MapSet.new(@categories)
    assert rows |> Enum.map(& &1["Severity"]) |> MapSet.new() == MapSet.new(@severities)

    for row <- rows, column <- @finding_columns do
      assert String.trim(row[column]) != "", "#{row["Finding ID"]} has empty #{column}"
    end

    findings = Enum.map_join(rows, "\n", & &1["Finding"])
    evidence = Enum.map_join(rows, "\n", & &1["Reproducible Evidence"])

    for expected <- [
          "checkout-private adoption proof",
          "required-check drift",
          "ownerless acceptance closure",
          "repeated QA/fast CI work",
          "internal narration in production/tests",
          "planning narration in adopter docs",
          "four golden-fixture test-pattern warnings",
          "historical signature bypass",
          "clean tracked-artifact scan"
        ] do
      assert findings =~ expected
    end

    assert evidence =~ "[VERIFIED:"
  end

  test "CI before-snapshot records cost, ownership, drift, and redaction-safe failure evidence" do
    baseline = File.read!(@baseline_path)
    {columns, rows} = ci_snapshot_rows(baseline)

    assert columns == @ci_columns
    assert rows != []

    for row <- rows, column <- @ci_columns do
      assert String.trim(row[column]) != "", "#{row["Surface"]} has empty #{column}"
    end

    observations = Enum.map_join(rows, "\n", & &1["Current Observation"])
    assert observations =~ "14 tracked workflow"
    assert observations =~ "337s"
    assert observations =~ "sample"

    surfaces = MapSet.new(rows, & &1["Surface"])

    for expected <- [
          "Workflow topology",
          "Main security gate",
          "Security independence",
          "Root dependency caching",
          "Demo app CI",
          "Demo browser E2E",
          "Fleet proxy",
          "Keycloak proxy",
          "Branch protection"
        ] do
      assert MapSet.member?(surfaces, expected)
    end

    branch_protection = Enum.find(rows, &(&1["Surface"] == "Branch protection"))
    assert branch_protection["Required-Check State"] =~ "security (27, 1.19.5)"
    assert branch_protection["Required-Check State"] =~ "security (28, 1.19.5)"
    assert branch_protection["Required-Check State"] =~ "fleet-proxy-e2e"
    assert branch_protection["Required-Check State"] =~ "HIGH drift"
  end

  test "ci.evidence executes adoption and governance contracts in one fresh process" do
    assert [step] = mix_alias_steps("ci.evidence")
    assert step =~ ~r/^cmd mix test\b/
    assert step =~ "test/adoption/evidence_contract_test.exs"
    assert step =~ "test/governance/milestone_scope_test.exs"
    assert step =~ "--warnings-as-errors"
  end

  test "baseline parser is anchored, non-vacuous, and rejects duplicate exact headings" do
    baseline = File.read!(@baseline_path)

    incidental =
      String.replace(
        baseline,
        "## Findings Ledger",
        "The phrase Findings Ledger is incidental here.\n\n### Findings Ledger\n\n## Findings Ledger",
        global: false
      )

    assert baseline_rows(incidental) == baseline_rows(baseline)

    duplicated = baseline <> "\n## Findings Ledger\n\n| decoy |\n| --- |\n| row |\n"
    assert_violation(duplicated, "document", "Findings Ledger duplicate heading")

    empty = String.replace(baseline, "| QUAL-73-001 |", "|", global: false)
    assert_violation(empty, "Findings Ledger", "non-vacuous table")
  end

  test "malformed finding rows fail with the finding ID and field" do
    baseline = File.read!(@baseline_path)

    controls = [
      {String.replace(baseline, "| High | Integration |", "| Urgent | Integration |",
         global: false
       ), "QUAL-73-001", "Severity"},
      {String.replace(baseline, "| High | Integration |", "| High | Governance |", global: false),
       "QUAL-73-001", "Category"},
      {String.replace(baseline, "| PIPE-73-001 |", "| QUAL-73-001 |", global: false),
       "QUAL-73-001", "Finding ID duplicate"},
      {String.replace(baseline, "| Phase 74 implementer |", "|  |", global: false), "QUAL-73-001",
       "Owner"},
      {String.replace(baseline, "| Phase 74 |", "|  |", global: false), "QUAL-73-001",
       "Target Phase"},
      {String.replace(baseline, "| release-blocker |", "| watching |", global: false),
       "QUAL-73-001", "Blocker State"},
      {String.replace(
         baseline,
         "Root adoption journeys execute inside Relyra and use private fixtures. [VERIFIED:",
         " [VERIFIED:",
         global: false
       ), "QUAL-73-001", "Reproducible Evidence"}
    ]

    for {markdown, id, field} <- controls do
      assert_violation(markdown, id, field)
    end
  end

  test "severity-specific disposition and blocker rules fail closed" do
    baseline = File.read!(@baseline_path)

    high_deferred =
      String.replace(
        baseline,
        "| release-blocker | Phase 74 completion |",
        "| deferred | Phase 74 completion |",
        global: false
      )

    assert_violation(high_deferred, "QUAL-73-001", "Blocker State")

    critical_unresolved =
      String.replace(
        baseline,
        "| resolved | At v1.11 security review |",
        "| disposition-required | At v1.11 security review |",
        global: false
      )

    assert_violation(critical_unresolved, "RELYRA-2026-001", "Blocker State")

    medium_without_disposition =
      String.replace(
        baseline,
        "| Baseline only; Phase 78 must measure multiple runs before optimizing and must preserve fresh security suites plus standalone GATE-02. |",
        "| none |",
        global: false
      )

    assert_violation(medium_without_disposition, "PIPE-73-002", "Disposition")

    low_without_revisit =
      String.replace(baseline, "| deferred | Phase 77 completion |", "| deferred |  |",
        global: false
      )

    assert_violation(low_without_revisit, "QUAL-73-004", "Revisit Date")
  end

  test "redaction-sensitive CI evidence rejects copied payloads and clean baseline passes" do
    baseline = File.read!(@baseline_path)
    assert baseline_violations(baseline) == []

    leaked =
      String.replace(
        baseline,
        "Redaction-safe step logs identify the failed lane",
        "Cookie: relyra_session=secret identifies the failed lane",
        global: false
      )

    assert_violation(leaked, "Main security gate", "Failure Evidence sensitive payload")
  end

  defp baseline_sections(markdown) do
    headings =
      Regex.scan(~r/^## ([^\n]+)$/m, markdown, return: :index)
      |> Enum.map(fn [{start, length}, {name_start, name_length}] ->
        {binary_part(markdown, name_start, name_length), start, length}
      end)

    headings
    |> Enum.with_index()
    |> Map.new(fn {{name, start, heading_length}, index} ->
      content_start = start + heading_length

      content_end =
        case Enum.at(headings, index + 1) do
          {_next_name, next_start, _length} -> next_start
          nil -> byte_size(markdown)
        end

      {name, binary_part(markdown, content_start, content_end - content_start)}
    end)
  end

  defp baseline_rows(markdown), do: table_rows(markdown, "Findings Ledger")
  defp ci_snapshot_rows(markdown), do: table_rows(markdown, "CI Baseline Snapshot")

  defp table_rows(markdown, heading) do
    section = Map.fetch!(baseline_sections(markdown), heading)

    [header, separator | data] =
      section
      |> String.split("\n")
      |> Enum.filter(&String.starts_with?(String.trim(&1), "|"))

    columns = table_cells(header)
    assert Enum.all?(table_cells(separator), &Regex.match?(~r/^:?-{3,}:?$/, &1))

    rows =
      Enum.map(data, fn line ->
        cells = table_cells(line)
        assert length(cells) == length(columns)
        Map.new(Enum.zip(columns, cells))
      end)

    {columns, rows}
  end

  defp table_cells(line) do
    line
    |> String.trim()
    |> String.trim("|")
    |> String.split("|")
    |> Enum.map(&String.trim/1)
  end

  defp mix_alias_steps(name) do
    "mix.exs"
    |> File.read!()
    |> Code.string_to_quoted!()
    |> Macro.prewalker()
    |> Enum.find_value(fn
      {key, steps} when is_atom(key) and is_list(steps) ->
        if Atom.to_string(key) == name and Enum.all?(steps, &is_binary/1), do: steps

      _other ->
        nil
    end)
  end

  defp baseline_violations(_markdown), do: []

  defp assert_violation(markdown, id, field) do
    path = write_baseline_fixture!(markdown)
    violations = path |> File.read!() |> baseline_violations()

    assert Enum.any?(violations, &(&1 =~ id and &1 =~ field)),
           "expected violation containing #{inspect(id)} and #{inspect(field)}, got: #{inspect(violations)}"
  end

  defp write_baseline_fixture!(markdown) do
    tmp_dir =
      Path.join(System.tmp_dir!(), "relyra-baseline-#{System.unique_integer([:positive])}")

    File.mkdir_p!(tmp_dir)
    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    path = Path.join(tmp_dir, "73-BASELINE.md")
    File.write!(path, markdown)
    path
  end
end
