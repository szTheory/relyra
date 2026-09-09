defmodule Relyra.Governance.MilestoneScopeTest do
  use ExUnit.Case, async: true

  @moduletag :evidence_contract

  alias Relyra.AdoptionEvidence

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
  @approval_classes ~w(public_api default_tightening security_posture semver_major remote_github)
  @risk_values ~w(unchanged mutation)

  test "active v1.11 plans declare scope and stop before every risky mutation" do
    roadmap = File.read!(".planning/ROADMAP.md")

    violations =
      roadmap
      |> incomplete_phase_numbers()
      |> Enum.flat_map(fn phase ->
        ".planning/phases/#{phase}-*/*-PLAN.md"
        |> Path.wildcard()
        |> Enum.flat_map(fn path ->
          path
          |> File.read!()
          |> plan_scope_violations()
          |> Enum.map(&"#{path}: #{&1}")
        end)
      end)

    assert violations == [],
           "Active milestone plans violate approval policy:\n" <>
             Enum.map_join(violations, "\n", &"  - #{&1}")
  end

  test "all approval classes require a matching plan-local blocking decision before mutation" do
    for approval_class <- @approval_classes -- ["remote_github"] do
      clean = risky_plan_fixture(approval_class)
      assert plan_scope_violations(clean) == []

      missing = remove_checkpoint(clean)
      assert_plan_violation(missing, approval_class, "checkpoint")

      late = move_checkpoint_after_mutation(clean)
      assert_plan_violation(late, approval_class, "before mutation")

      non_blocking = String.replace(clean, ~s(gate="blocking"), ~s(gate="advisory"))
      assert_plan_violation(non_blocking, approval_class, "blocking")

      wrong_class =
        String.replace(
          clean,
          "<decision>approval_class: #{approval_class}</decision>",
          "<decision>approval_class: remote_github</decision>"
        )

      assert_plan_violation(wrong_class, approval_class, "matching")
    end
  end

  test "remote GitHub approval owns an exact reversible batch and read-back" do
    clean = risky_plan_fixture("remote_github")
    assert plan_scope_violations(clean) == []

    for {token, diagnostic} <- [
          {"current state", "current state"},
          {"desired state", "desired state"},
          {"exact commands", "exact commands"},
          {"affected checks", "affected checks"},
          {"automated preflight", "automated preflight"},
          {"rollback", "rollback"},
          {"postcondition read-back", "postcondition read-back"}
        ] do
      incomplete = String.replace(clean, token, "omitted detail", global: false)
      assert_plan_violation(incomplete, "remote_github", diagnostic)
    end

    without_resume = Regex.replace(~r/\s*<resume-signal>.*?<\/resume-signal>/s, clean, "")
    assert_plan_violation(without_resume, "remote_github", "resume signal")
  end

  test "approval cannot be borrowed across plans or concurrent branches" do
    approving_plan = risky_plan_fixture("public_api")
    mutation_only = remove_checkpoint(approving_plan)

    assert plan_scope_violations(approving_plan) == []
    assert_plan_violation(mutation_only, "public_api", "checkpoint")

    concurrent_branch =
      mutation_only <>
        "\n<!-- concurrent branch checkpoint lives outside this plan and cannot authorize it -->\n"

    assert_plan_violation(concurrent_branch, "public_api", "checkpoint")
  end

  test "no-risk plans must explicitly negate every approval class" do
    clean = no_risk_plan_fixture()
    assert plan_scope_violations(clean) == []

    for approval_class <- @approval_classes do
      missing = Regex.replace(~r/^#{approval_class}:.*\n/m, clean, "")
      assert_plan_violation(missing, approval_class, "scope assertion")
    end
  end

  test "unexecuted implementation tasks require one exact closed risk value per class" do
    clean = no_risk_plan_fixture()
    assert plan_scope_violations(clean) == []

    controls = [
      {Regex.replace(~r/^\s*public_api: unchanged\n/m, clean, "", global: false), "public_api",
       "risk_metadata"},
      {String.replace(
         clean,
         "public_api: unchanged",
         "public_api: unchanged\n      public_api: unchanged",
         global: false
       ), "public_api", "exactly once"},
      {String.replace(clean, "public_api: unchanged", "public_api: safe", global: false),
       "public_api", "unsupported"},
      {String.replace(clean, "public_api: unchanged", "public_api: unchanged mutation",
         global: false
       ), "public_api", "unsupported"},
      {String.replace(clean, "public_api: unchanged", "public_api: unchanged; mutation required",
         global: false
       ), "public_api", "unsupported"}
    ]

    for {plan, risk_class, diagnostic} <- controls do
      assert_plan_violation(plan, risk_class, diagnostic)
    end
  end

  test "governed task surfaces override optimistic risk metadata" do
    public_api =
      no_risk_plan_fixture()
      |> String.replace(
        "Extend deterministic policy tests only.",
        "Change the published Relyra.start_login/3 entry point."
      )

    assert_plan_violation(public_api, "public_api", "contradicts governed surface")
    assert_plan_violation(public_api, "public_api", "checkpoint")

    protected_path =
      no_risk_plan_fixture()
      |> String.replace(
        "test/governance/milestone_scope_test.exs",
        "lib/relyra/security/signature.ex",
        global: false
      )

    assert_plan_violation(protected_path, "security_posture", "contradicts governed surface")
    assert_plan_violation(protected_path, "security_posture", "checkpoint")
  end

  test "changed-surface classifier detects published signatures and protected seams" do
    before_api = "def start_login(connection, relay_context, opts \\\\ [])"
    after_api = "def start_login(connection, relay_context, policy, opts \\\\ [])"

    assert "public_api" in changed_surface_classes("lib/relyra.ex", before_api, after_api)

    assert "security_posture" in changed_surface_classes(
             "lib/relyra/security/signature.ex",
             "defp do_verify(parsed, connection, certs, opts)",
             "defp do_verify(parsed, connection, certs, policy, opts)"
           )

    assert changed_surface_classes("lib/relyra.ex", before_api, before_api) == []
    assert changed_surface_classes("test/governance/milestone_scope_test.exs", "a", "b") == []
  end

  test "decision checkpoints authorize mutations but never satisfy acceptance" do
    clean = risky_plan_fixture("public_api")
    assert plan_scope_violations(clean) == []

    manual_verify =
      String.replace(
        clean,
        "<automated>mix test test/governance/milestone_scope_test.exs --warnings-as-errors</automated>",
        "<automated>checkpoint:decision approval</automated>"
      )

    assert_plan_violation(manual_verify, "verification", "deterministic")
  end

  test "every acceptance-bearing task requires its own executable non-zero owner" do
    clean = no_risk_plan_fixture()
    assert plan_scope_violations(clean) == []

    for command <- ["mix help", "mix deps.get", "echo mix test --warnings-as-errors"] do
      invalid = replace_fixture_command(clean, command)
      assert_plan_violation(invalid, "Run the governance contract", "executable ownership")
    end

    zero_selector =
      replace_fixture_command(
        clean,
        "mix test test/governance/milestone_scope_test.exs --only no_such_selector --warnings-as-errors"
      )

    assert_plan_violation(zero_selector, "Run the governance contract", "zero selected tests")

    missing_warnings =
      replace_fixture_command(clean, "mix test test/governance/milestone_scope_test.exs")

    assert_plan_violation(missing_warnings, "Run the governance contract", "warnings-as-errors")

    uncovered_sibling =
      String.replace(
        clean,
        "</tasks>",
        """
        <task type="auto">
          <name>Task 2: Uncovered sibling</name>
          <files>test/governance/milestone_scope_test.exs</files>
          <action>Exercise a second acceptance branch.</action>
          <verify></verify>
          <acceptance_criteria><criterion>Second branch is proven.</criterion></acceptance_criteria>
        </task>
        </tasks>
        """
      )

    assert_plan_violation(uncovered_sibling, "Task 2: Uncovered sibling", "executable ownership")

    named_alias =
      replace_fixture_command(
        clean,
        "ASDF_ELIXIR_VERSION=1.19.5-otp-28 ASDF_ERLANG_VERSION=28.4.1 mix ci.evidence"
      )

    assert plan_scope_violations(named_alias) == []
  end

  test "active plans use only requirements owned by their roadmap phase" do
    roadmap = File.read!(".planning/ROADMAP.md")
    ownership = roadmap_requirement_ownership(roadmap)

    violations =
      roadmap
      |> incomplete_phase_numbers()
      |> Enum.flat_map(fn phase ->
        ".planning/phases/#{phase}-*/*-PLAN.md"
        |> Path.wildcard()
        |> Enum.flat_map(fn path ->
          path
          |> File.read!()
          |> requirement_membership_violations(ownership)
          |> Enum.map(&"#{path}: #{&1}")
        end)
      end)

    assert violations == [],
           "Active plans contain requirements owned by another phase:\n" <>
             Enum.map_join(violations, "\n", &"  - #{&1}")

    mismapped = String.replace(no_risk_plan_fixture(), "[GOV-01]", "[PKG-01]")
    assert_requirement_violation(mismapped, ownership, "PKG-01", "Phase 74")
  end

  test "demand-gated capabilities are legal only in explicit negative policy regions" do
    clean = no_risk_plan_fixture()
    assert plan_scope_violations(clean) == []

    policy_only =
      clean <>
        """
        <must_haves><prohibitions>
        AUTHN-POST-01, KMS-01, and SIGNED-META-01 remain excluded.
        </prohibitions></must_haves>
        """

    assert plan_scope_violations(policy_only) == []

    for capability <- ~w(AUTHN-POST-01 KMS-01 SIGNED-META-01) do
      implementation =
        String.replace(
          clean,
          "Extend deterministic policy tests only.",
          "Implement #{capability} in the library."
        )

      assert_plan_violation(implementation, capability, "implementation scope")
    end
  end

  test "renaming forbidden product expansion as cleanup does not bypass scope" do
    disguised =
      String.replace(
        no_risk_plan_fixture(),
        "<name>Run the governance contract</name>",
        "<name>Cleanup signed metadata helpers for SIGNED-META-01</name>"
      )

    assert_plan_violation(disguised, "SIGNED-META-01", "implementation scope")
  end

  test "incomplete phases reject manual completion markers and required UAT artifacts" do
    for marker <- ["<human-check>", "## Manual-Only Verifications", "status: human_needed"] do
      assert_plan_violation(
        no_risk_plan_fixture() <> "\n#{marker}\n",
        marker,
        "manual acceptance"
      )
    end

    orphan_checkpoint =
      String.replace(
        no_risk_plan_fixture(),
        "<task type=\"auto\">",
        """
        <task type="checkpoint:decision" gate="blocking">
          <decision>Approve completion.</decision>
          <resume-signal>Say approved.</resume-signal>
        </task>
        <task type="auto">
        """,
        global: false
      )

    assert_plan_violation(orphan_checkpoint, "checkpoint:decision", "named risky mutation")

    fixture_dir =
      Path.join(
        System.tmp_dir!(),
        "relyra-automation-policy-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(fixture_dir)
    on_exit(fn -> File.rm_rf!(fixture_dir) end)
    File.write!(Path.join(fixture_dir, "99-01-UAT.md"), "required manual evidence")

    assert Enum.any?(
             automation_policy_violations(fixture_dir),
             &String.contains?(&1, "UAT artifact")
           )
  end

  test "active incomplete phases keep completion evidence automated" do
    violations =
      ".planning/ROADMAP.md"
      |> File.read!()
      |> incomplete_phase_numbers()
      |> Enum.flat_map(&automation_policy_violations/1)

    assert violations == [],
           "Incomplete phases must use deterministic completion evidence:\n" <>
             Enum.map_join(violations, "\n", &"  - #{&1}")
  end

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
          "incomplete-phase vocabulary scan failure",
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

  test "completed baseline requirements have deterministic mandatory evidence owners" do
    entries = AdoptionEvidence.entries()

    for requirement <- ["QUAL-01", "PIPE-01"] do
      assert [owner] = AdoptionEvidence.deterministic_owners(entries, requirement)
      assert owner.owner == "test/governance/milestone_scope_test.exs"
      assert owner.selector == "evidence_contract"
      assert owner.lane == "ci.evidence"
    end

    assert :ok = AdoptionEvidence.validate_repository!(entries, File.cwd!())
  end

  test "completed governance requirements have deterministic mandatory evidence owners" do
    entries = AdoptionEvidence.entries()

    for requirement <- ["GOV-01", "GOV-02"] do
      assert [owner] = AdoptionEvidence.deterministic_owners(entries, requirement)
      assert owner.owner == "test/governance/milestone_scope_test.exs"
      assert owner.selector == "evidence_contract"
      assert owner.lane == "ci.evidence"
    end

    assert :ok = AdoptionEvidence.validate_repository!(entries, File.cwd!())
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

  defp no_risk_plan_fixture do
    """
    ---
    phase: 73-twin-contract-and-baseline
    plan: 99
    requirements: [GOV-01]
    ---
    <scope_assertions>
    public_api: unchanged
    default_tightening: none
    security_posture: unchanged
    semver_major: none
    remote_github: no mutation
    protocol_scope: AUTHN-POST-01, KMS-01, and SIGNED-META-01 remain excluded
    </scope_assertions>
    <tasks>
    <task type="auto">
      <name>Run the governance contract</name>
      <files>test/governance/milestone_scope_test.exs</files>
      <risk_metadata>
      public_api: unchanged
      default_tightening: unchanged
      security_posture: unchanged
      semver_major: unchanged
      remote_github: unchanged
      </risk_metadata>
      <action>Extend deterministic policy tests only.</action>
      <verify><automated>mix test test/governance/milestone_scope_test.exs --warnings-as-errors</automated></verify>
      <acceptance_criteria><criterion>The governance contract passes.</criterion></acceptance_criteria>
    </task>
    </tasks>
    """
  end

  defp risky_plan_fixture(approval_class) do
    impact =
      case approval_class do
        "public_api" -> "Change the published Relyra.start_login/3 API."
        "default_tightening" -> "Tighten the default validation mode."
        "security_posture" -> "Change the assertion trust policy."
        "semver_major" -> "Release a real SemVer major version."
        "remote_github" -> "Mutate remote GitHub branch protection."
      end

    remote_details =
      if approval_class == "remote_github" do
        """
        Record current state and desired state, exact commands, affected checks,
        automated preflight, rollback, and postcondition read-back.
        """
      else
        "Record the proposed mutation, impact, and automated preflight."
      end

    """
    ---
    phase: 73-twin-contract-and-baseline
    plan: 99
    requirements: [GOV-01]
    ---
    <scope_assertions>
    public_api: unchanged
    default_tightening: none
    security_posture: unchanged
    semver_major: none
    remote_github: no mutation
    protocol_scope: feature-neutral; demand-gated capabilities remain excluded
    #{approval_class}: mutation proposed
    </scope_assertions>
    <tasks>
    <task type="checkpoint:decision" gate="blocking">
      <name>Approve #{approval_class} mutation</name>
      <decision>approval_class: #{approval_class}</decision>
      <action>#{remote_details}</action>
      <resume-signal>Explicitly approve this exact #{approval_class} batch.</resume-signal>
    </task>
    <task type="auto">
      <name>Apply #{approval_class} mutation</name>
      <files>governed/file.ex</files>
      <risk_metadata>
      public_api: #{if approval_class == "public_api", do: "mutation", else: "unchanged"}
      default_tightening: #{if approval_class == "default_tightening", do: "mutation", else: "unchanged"}
      security_posture: #{if approval_class == "security_posture", do: "mutation", else: "unchanged"}
      semver_major: #{if approval_class == "semver_major", do: "mutation", else: "unchanged"}
      remote_github: #{if approval_class == "remote_github", do: "mutation", else: "unchanged"}
      </risk_metadata>
      <action>approval_class: #{approval_class}. #{impact}</action>
      <verify><automated>mix test test/governance/milestone_scope_test.exs --warnings-as-errors</automated></verify>
      <acceptance_criteria><criterion>The governed mutation is proven.</criterion></acceptance_criteria>
    </task>
    </tasks>
    """
  end

  defp remove_checkpoint(plan) do
    Regex.replace(~r/\s*<task type="checkpoint:decision".*?<\/task>/s, plan, "")
  end

  defp move_checkpoint_after_mutation(plan) do
    [checkpoint] = Regex.run(~r/<task type="checkpoint:decision".*?<\/task>/s, plan)
    plan |> remove_checkpoint() |> String.replace("</tasks>", "#{checkpoint}\n</tasks>")
  end

  defp assert_plan_violation(plan, identity, detail) do
    violations = plan_scope_violations(plan)

    assert Enum.any?(violations, &(&1 =~ identity and &1 =~ detail)),
           "expected plan violation containing #{inspect(identity)} and #{inspect(detail)}, got: #{inspect(violations)}"
  end

  defp replace_fixture_command(plan, command) do
    Regex.replace(~r/<automated>.*?<\/automated>/s, plan, "<automated>#{command}</automated>",
      global: false
    )
  end

  defp assert_requirement_violation(plan, ownership, requirement, expected_owner) do
    violations = requirement_membership_violations(plan, ownership)

    assert Enum.any?(violations, &(&1 =~ requirement and &1 =~ expected_owner)),
           "expected requirement violation containing #{inspect(requirement)} and #{inspect(expected_owner)}, got: #{inspect(violations)}"
  end

  defp incomplete_phase_numbers(roadmap) do
    ~r/^- \[ \] \*\*Phase ([0-9.]+):/m
    |> Regex.scan(roadmap, capture: :all_but_first)
    |> Enum.map(fn [phase] -> phase end)
  end

  defp plan_scope_violations(markdown) do
    scope_sections = tag_sections(markdown, "scope_assertions")
    tasks = plan_tasks(markdown)

    scope_violations =
      case scope_sections do
        [scope] -> approval_scope_violations(parse_scope_assertions(scope), tasks)
        _other -> ["scope_assertions must appear exactly once"]
      end

    scope_violations ++
      deterministic_verification_violations(tasks) ++
      forbidden_capability_violations(tasks) ++
      manual_acceptance_violations(markdown) ++
      orphan_checkpoint_violations(tasks)
  end

  defp approval_scope_violations(scope, tasks) do
    Enum.flat_map(@approval_classes, fn approval_class ->
      values = Map.get(scope, approval_class, [])

      cond do
        values == [] ->
          ["#{approval_class} scope assertion is required"]

        risky_scope?(approval_class, values, tasks) ->
          mutation_index = mutation_task_index(tasks, approval_class)
          checkpoint_index = matching_checkpoint_index(tasks, approval_class)

          checkpoint_violations(approval_class, mutation_index, checkpoint_index, tasks)

        true ->
          []
      end
    end)
  end

  defp risky_scope?(approval_class, values, tasks) do
    Enum.any?(values, &(not negative_scope_value?(approval_class, &1))) or
      mutation_task_index(tasks, approval_class) != nil
  end

  defp negative_scope_value?(approval_class, value) do
    normalized = String.downcase(value)

    case approval_class do
      "remote_github" ->
        Enum.any?(
          ["no mutation", "read-only", "unchanged", "none"],
          &String.contains?(normalized, &1)
        )

      _other ->
        Enum.any?(
          ["unchanged", "none", "no change", "no mutation"],
          &String.contains?(normalized, &1)
        )
    end
  end

  defp checkpoint_violations(approval_class, mutation_index, checkpoint_index, tasks) do
    cond do
      mutation_index == nil ->
        ["#{approval_class} mutation task is missing"]

      checkpoint_index == nil ->
        ["#{approval_class} matching checkpoint is missing"]

      not checkpoint_precedes_mutation?({checkpoint_index, mutation_index}, tasks) ->
        ["#{approval_class} checkpoint must be before mutation"]

      true ->
        checkpoint = Enum.at(tasks, checkpoint_index)

        blocking =
          if checkpoint.gate == "blocking",
            do: [],
            else: ["#{approval_class} checkpoint must be blocking"]

        exact_batch =
          if approval_class == "remote_github",
            do: remote_checkpoint_violations(checkpoint),
            else: []

        blocking ++ exact_batch
    end
  end

  defp checkpoint_precedes_mutation?({checkpoint_index, mutation_index}, tasks) do
    checkpoint_index < mutation_index and
      Enum.at(tasks, checkpoint_index).type == "checkpoint:decision"
  end

  defp matching_checkpoint_index(tasks, approval_class) do
    Enum.find_index(tasks, fn task ->
      task.type == "checkpoint:decision" and
        String.contains?(task.body, "approval_class: #{approval_class}")
    end)
  end

  defp mutation_task_index(tasks, approval_class) do
    Enum.find_index(tasks, fn task ->
      not String.starts_with?(task.type, "checkpoint") and
        String.contains?(task.action, "approval_class: #{approval_class}")
    end)
  end

  defp remote_checkpoint_violations(checkpoint) do
    required = [
      "current state",
      "desired state",
      "exact commands",
      "affected checks",
      "automated preflight",
      "rollback",
      "postcondition read-back"
    ]

    content = String.downcase(checkpoint.body)

    missing =
      for detail <- required,
          not String.contains?(content, detail),
          do: "remote_github checkpoint is missing #{detail}"

    resume =
      if String.trim(checkpoint.resume_signal) == "",
        do: ["remote_github checkpoint is missing resume signal"],
        else: []

    missing ++ resume
  end

  defp deterministic_verification_violations(tasks) do
    tasks
    |> Enum.reject(&String.starts_with?(&1.type, "checkpoint"))
    |> Enum.flat_map(fn task ->
      if String.trim(task.acceptance_criteria) == "" do
        []
      else
        commands = tag_sections(task.verify, "automated")

        results =
          Enum.map(commands, fn command ->
            try do
              AdoptionEvidence.validate_automated_command!(command, File.cwd!())
              :ok
            rescue
              error in ArgumentError -> {:error, Exception.message(error)}
            end
          end)

        if :ok in results do
          []
        else
          reasons =
            case results do
              [] -> "no immediately associated <automated> command"
              failures -> Enum.map_join(failures, "; ", fn {:error, reason} -> reason end)
            end

          identity = nonempty(task.name, "unnamed task")

          [
            "verification for task #{identity} requires deterministic executable ownership: #{reasons}"
          ]
        end
      end
    end)
  end

  defp forbidden_capability_violations(tasks) do
    capabilities = ~w(AUTHN-POST-01 KMS-01 SIGNED-META-01)

    Enum.flat_map(tasks, fn task ->
      if String.starts_with?(task.type, "checkpoint") do
        []
      else
        [
          {"name", task.name, false},
          {"files", task.files, false},
          {"action", task.action, governance_policy_action?(task)}
        ]
        |> Enum.flat_map(fn {region, content, governance_policy?} ->
          for capability <- capabilities,
              String.contains?(content, capability),
              not governance_policy?,
              not negative_capability_reference?(content, capability),
              do: "#{capability} implementation scope appears in task #{region}"
        end)
      end
    end)
  end

  defp governance_policy_action?(task) do
    files = String.split(task.files, ",", trim: true) |> Enum.map(&String.trim/1)
    action = String.downcase(task.action)

    files != [] and Enum.all?(files, &String.starts_with?(&1, "test/governance/")) and
      Enum.any?(
        ["scope validation", "scope validator", "policy test", "reject implementation"],
        &String.contains?(action, &1)
      )
  end

  defp negative_capability_reference?(content, capability) do
    content
    |> String.split(~r/(?<=[.!?])\s+|\n/)
    |> Enum.filter(&String.contains?(&1, capability))
    |> Enum.all?(fn sentence ->
      normalized = String.downcase(sentence)

      Enum.any?(
        ["remain excluded", "remains excluded", "do not", "must not", "forbid", "reject"],
        &String.contains?(normalized, &1)
      )
    end)
  end

  defp manual_acceptance_violations(markdown) do
    for marker <- ["<human-check>", "## Manual-Only Verifications", "status: human_needed"],
        String.contains?(markdown, marker),
        do: "#{marker} manual acceptance is prohibited"
  end

  defp orphan_checkpoint_violations(tasks) do
    tasks
    |> Enum.with_index()
    |> Enum.flat_map(fn {task, checkpoint_index} ->
      if task.type == "checkpoint:decision" do
        case Regex.run(~r/approval_class:\s*([a-z_]+)/, task.body, capture: :all_but_first) do
          [approval_class] when approval_class in @approval_classes ->
            mutation_index = mutation_task_index(tasks, approval_class)

            if mutation_index != nil and checkpoint_index < mutation_index,
              do: [],
              else: ["checkpoint:decision must precede a named risky mutation"]

          _other ->
            ["checkpoint:decision must precede a named risky mutation"]
        end
      else
        []
      end
    end)
  end

  defp roadmap_requirement_ownership(roadmap) do
    ~r/^### Phase ([0-9.]+):.*?^\*\*Requirements:\*\*\s*([^\n]+)$/ms
    |> Regex.scan(roadmap, capture: :all_but_first)
    |> Enum.reduce(%{}, fn [phase, requirements], ownership ->
      requirements
      |> String.split(",", trim: true)
      |> Enum.reduce(ownership, fn requirement, acc ->
        Map.put(acc, String.trim(requirement), "Phase #{phase}")
      end)
    end)
  end

  defp requirement_membership_violations(markdown, ownership) do
    phase = plan_phase(markdown)

    for requirement <- plan_requirements(markdown),
        Map.get(ownership, requirement) != phase do
      case Map.get(ownership, requirement) do
        nil -> "#{requirement} is not assigned to any roadmap phase"
        owner -> "#{requirement} belongs to #{owner}, not #{phase}"
      end
    end
  end

  defp plan_phase(markdown) do
    frontmatter = plan_frontmatter(markdown)

    case Regex.run(~r/^phase:\s*([0-9.]+)/m, frontmatter, capture: :all_but_first) do
      [phase] -> "Phase #{phase}"
      nil -> "Phase unknown"
    end
  end

  defp plan_requirements(markdown) do
    frontmatter = plan_frontmatter(markdown)

    case Regex.run(~r/^requirements:\s*\[([^\]]*)\]/m, frontmatter, capture: :all_but_first) do
      [inline] ->
        inline |> String.split(",", trim: true) |> Enum.map(&String.trim/1)

      nil ->
        case Regex.run(~r/^requirements:\s*\n((?:\s+-\s+[^\n]+\n?)+)/m, frontmatter,
               capture: :all_but_first
             ) do
          [lines] ->
            ~r/^\s+-\s+([^\n]+)$/m
            |> Regex.scan(lines, capture: :all_but_first)
            |> Enum.map(fn [requirement] -> String.trim(requirement) end)

          nil ->
            []
        end
    end
  end

  defp plan_frontmatter(markdown) do
    case Regex.run(~r/\A---\s*\n(.*?)\n---/s, markdown, capture: :all_but_first) do
      [frontmatter] -> frontmatter
      nil -> ""
    end
  end

  defp automation_policy_violations(phase_or_directory) do
    directories =
      if File.dir?(phase_or_directory) do
        [phase_or_directory]
      else
        Path.wildcard(".planning/phases/#{phase_or_directory}-*")
      end

    document_violations =
      for directory <- directories,
          path <- Path.wildcard(Path.join(directory, "*-PLAN.md")),
          marker <- ["<human-check>", "## Manual-Only Verifications", "status: human_needed"],
          String.contains?(File.read!(path), marker),
          do: "#{path} contains #{inspect(marker)}"

    uat_violations =
      for directory <- directories,
          path <- Path.wildcard(Path.join(directory, "*-UAT.md")),
          do: "#{path} requires a UAT artifact"

    document_violations ++ uat_violations
  end

  defp parse_scope_assertions(section) do
    section
    |> String.split("\n")
    |> Enum.reduce(%{}, fn line, scope ->
      case String.split(line, ":", parts: 2) do
        [key, value] ->
          key = String.trim(key)

          if key in @approval_classes do
            Map.update(scope, key, [String.trim(value)], &[String.trim(value) | &1])
          else
            scope
          end

        _other ->
          scope
      end
    end)
  end

  defp plan_tasks(markdown) do
    ~r/<task\s+(?<attributes>[^>]*)>(?<body>.*?)<\/task>/s
    |> Regex.scan(markdown, capture: ["attributes", "body"])
    |> Enum.map(fn [attributes, body] ->
      %{
        type: attribute_value(attributes, "type"),
        gate: attribute_value(attributes, "gate"),
        body: body,
        name: tag_content(body, "name"),
        action: tag_content(body, "action"),
        files: tag_content(body, "files"),
        verify: tag_content(body, "verify"),
        acceptance_criteria: tag_content(body, "acceptance_criteria"),
        resume_signal: tag_content(body, "resume-signal")
      }
    end)
  end

  defp attribute_value(attributes, name) do
    case Regex.run(~r/(?:^|\s)#{Regex.escape(name)}="([^"]*)"/, attributes,
           capture: :all_but_first
         ) do
      [value] -> value
      nil -> ""
    end
  end

  defp tag_sections(markdown, tag) do
    ~r/<#{Regex.escape(tag)}>(.*?)<\/#{Regex.escape(tag)}>/s
    |> Regex.scan(markdown, capture: :all_but_first)
    |> Enum.map(fn [content] -> content end)
  end

  defp tag_content(markdown, tag) do
    case tag_sections(markdown, tag) do
      [content] -> String.trim(content)
      _other -> ""
    end
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

  defp baseline_violations(markdown) do
    duplicate_heading_violations(markdown) ++
      finding_violations(markdown) ++ ci_violations(markdown)
  end

  defp duplicate_heading_violations(markdown) do
    ["Findings Ledger", "CI Baseline Snapshot"]
    |> Enum.flat_map(fn heading ->
      count = Regex.scan(~r/^## #{Regex.escape(heading)}$/m, markdown) |> length()

      if count == 1,
        do: [],
        else: ["document #{heading} duplicate heading or missing heading: found #{count}"]
    end)
  end

  defp finding_violations(markdown) do
    case parsed_table(markdown, "Findings Ledger", @finding_columns) do
      {:ok, rows} ->
        required_field_violations(rows, @finding_columns, "Finding ID") ++
          enum_violations(rows, "Severity", @severities, "Finding ID") ++
          enum_violations(rows, "Category", @categories, "Finding ID") ++
          enum_violations(
            rows,
            "Blocker State",
            ~w(release-blocker disposition-required deferred resolved),
            "Finding ID"
          ) ++
          duplicate_id_violations(rows) ++
          evidence_violations(rows) ++
          severity_policy_violations(rows)

      {:error, reason} ->
        ["Findings Ledger non-vacuous table #{reason}"]
    end
  end

  defp ci_violations(markdown) do
    case parsed_table(markdown, "CI Baseline Snapshot", @ci_columns) do
      {:ok, rows} ->
        required_field_violations(rows, @ci_columns, "Surface") ++
          sensitive_payload_violations(rows)

      {:error, reason} ->
        ["CI Baseline Snapshot non-vacuous table #{reason}"]
    end
  end

  defp parsed_table(markdown, heading, expected_columns) do
    with [section] <- exact_sections(markdown, heading),
         [header, separator | data] <-
           section
           |> String.split("\n")
           |> Enum.filter(&String.starts_with?(String.trim(&1), "|")),
         columns <- table_cells(header),
         true <- columns == expected_columns,
         true <- Enum.all?(table_cells(separator), &Regex.match?(~r/^:?-{3,}:?$/, &1)),
         true <- data != [],
         parsed <- Enum.map(data, &table_cells/1),
         true <- Enum.all?(parsed, &(length(&1) == length(columns))) do
      {:ok, Enum.map(parsed, &Map.new(Enum.zip(columns, &1)))}
    else
      _other -> {:error, "is missing, malformed, or empty"}
    end
  end

  defp exact_sections(markdown, heading) do
    pattern =
      ~r/^## #{Regex.escape(heading)}\n(?<content>.*?)(?=^## |\z)/ms

    Regex.scan(pattern, markdown, capture: ["content"])
    |> List.flatten()
  end

  defp required_field_violations(rows, columns, identity_column) do
    Enum.flat_map(rows, fn row ->
      identity = nonempty(row[identity_column], identity_column)

      for column <- columns,
          String.trim(row[column] || "") == "",
          do: "#{identity} #{column} is empty"
    end)
  end

  defp enum_violations(rows, column, allowed, identity_column) do
    for row <- rows,
        value = row[column],
        value not in allowed,
        do:
          "#{nonempty(row[identity_column], identity_column)} #{column} is unsupported: #{value}"
  end

  defp duplicate_id_violations(rows) do
    rows
    |> Enum.group_by(& &1["Finding ID"])
    |> Enum.flat_map(fn
      {id, duplicates} when length(duplicates) > 1 -> ["#{id} Finding ID duplicate"]
      {_id, _single} -> []
    end)
  end

  defp evidence_violations(rows) do
    for row <- rows,
        [prefix | _rest] = String.split(row["Reproducible Evidence"], "[VERIFIED:", parts: 2),
        String.trim(prefix) == "",
        do: "#{row["Finding ID"]} Reproducible Evidence lacks a named command or source"
  end

  defp severity_policy_violations(rows) do
    Enum.flat_map(rows, fn row ->
      id = row["Finding ID"]
      severity = row["Severity"]
      blocker_state = row["Blocker State"]
      disposition = String.downcase(String.trim(row["Disposition"]))

      cond do
        severity in ["Critical", "High"] and blocker_state not in ["release-blocker", "resolved"] ->
          ["#{id} Blocker State must be release-blocker until resolved"]

        severity == "Medium" and disposition in ["", "none", "n/a", "not applicable"] ->
          ["#{id} Disposition must be explicit for Medium severity"]

        severity in ["Low", "Informational"] and blocker_state == "deferred" and
            String.trim(row["Owner"]) == "" ->
          ["#{id} Owner is required for deferred #{severity} severity"]

        severity in ["Low", "Informational"] and blocker_state == "deferred" and
            String.trim(row["Revisit Date"]) == "" ->
          ["#{id} Revisit Date is required for deferred #{severity} severity"]

        true ->
          []
      end
    end)
  end

  defp sensitive_payload_violations(rows) do
    sensitive =
      ~r/<(?:saml\w*:)?Assertion\b|BEGIN (?:RSA )?(?:PRIVATE KEY|CERTIFICATE)|Cookie:|Authorization:|(?:GH_TOKEN|PASSWORD)=/i

    for row <- rows,
        field <- ["Current Observation", "Failure Evidence", "Provenance"],
        Regex.match?(sensitive, row[field]),
        do: "#{row["Surface"]} #{field} sensitive payload"
  end

  defp nonempty(value, fallback) do
    case String.trim(value || "") do
      "" -> fallback
      identity -> identity
    end
  end

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
