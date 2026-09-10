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
  @task_types ~w(tracer auto checkpoint:decision checkpoint:human-verify checkpoint:human-action)
  @demand_gated_exclusions ~w(AUTHN-POST-01 KMS-01 SIGNED-META-01)

  test "active v1.11 plans declare scope and stop before every risky mutation" do
    roadmap = File.read!(".planning/ROADMAP.md")

    violations =
      roadmap
      |> incomplete_phase_numbers()
      |> Enum.flat_map(fn phase ->
        ".planning/phases/#{phase}-*/*-PLAN.md"
        |> Path.wildcard()
        |> Enum.reject(&executed_plan?/1)
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

    for {field, diagnostic} <- [
          {"current_state", "current_state"},
          {"desired_state", "desired_state"},
          {"mutation_commands", "mutation_commands"},
          {"affected_checks", "affected_checks"},
          {"preflight_command", "preflight_command"},
          {"rollback_commands", "rollback_commands"},
          {"read_back_command", "read_back_command"},
          {"resume_signal", "resume_signal"}
        ] do
      incomplete = remove_remote_field(clean, field)
      assert_plan_violation(incomplete, "remote_github", diagnostic)
    end

    without_resume = Regex.replace(~r/\s*<resume-signal>.*?<\/resume-signal>/s, clean, "")
    assert_plan_violation(without_resume, "remote_github", "resume signal")
  end

  test "remote batch rejects placeholders and mismatched reversible targets" do
    clean = risky_plan_fixture("remote_github")
    assert plan_scope_violations(clean) == []

    for placeholder <- ["", "   ", "TBD", "placeholder", "exact commands omitted"] do
      invalid = replace_remote_scalar(clean, "preflight_command", placeholder)
      assert_plan_violation(invalid, "remote_github", "preflight_command")
    end

    mismatched_branch =
      replace_remote_scalar(
        clean,
        "read_back_command",
        "gh api repos/szTheory/relyra/branches/develop/protection"
      )

    assert_plan_violation(mismatched_branch, "remote_github", "read_back_command target")

    mismatched_checks =
      replace_remote_scalar(
        clean,
        "affected_checks",
        "security (27, 1.19.5), security (28, 1.19.5)"
      )

    assert_plan_violation(mismatched_checks, "remote_github", "affected_checks")

    wrong_rollback =
      String.replace(
        clean,
        "repos/szTheory/relyra/branches/main/protection --input captured-current.json",
        "repos/szTheory/relyra/branches/develop/protection --input desired.json",
        global: false
      )

    assert_plan_violation(wrong_rollback, "remote_github", "rollback_commands target")
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
      {replace_risk_field(clean, "public_api: unchanged\n", ""), "public_api", "risk_metadata"},
      {replace_risk_field(
         clean,
         "public_api: unchanged",
         "public_api: unchanged\n    public_api: unchanged"
       ), "public_api", "exactly once"},
      {replace_risk_field(clean, "public_api: unchanged", "public_api: safe"), "public_api",
       "unsupported"},
      {replace_risk_field(clean, "public_api: unchanged", "public_api: unchanged mutation"),
       "public_api", "unsupported"},
      {replace_risk_field(
         clean,
         "public_api: unchanged",
         "public_api: unchanged; mutation required"
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

    fixture_data =
      clean <>
        """
        <fixture_data>
        AUTHN-POST-01
        KMS-01
        SIGNED-META-01
        </fixture_data>
        """

    assert plan_scope_violations(fixture_data) == []

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

  @tag :plan_73_07_task_2
  test "task-region demand-gated smuggling fails regardless of nearby prose" do
    controls = [
      "Do not delay; implement KMS-01 in the library.",
      "KMS-01 must not remain excluded; implement it now.",
      "Policy tests reject implementation. Then implement AUTHN-POST-01.",
      "Forbid unrelated scope while implementing SIGNED-META-01.",
      "Cleanup helpers and ship KMS-01."
    ]

    for action <- controls do
      plan =
        String.replace(no_risk_plan_fixture(), "Extend deterministic policy tests only.", action)

      capability =
        Enum.find(~w(AUTHN-POST-01 KMS-01 SIGNED-META-01), &String.contains?(action, &1))

      assert_plan_violation(plan, capability, "implementation scope appears in task action")
    end

    file_smuggling =
      String.replace(
        no_risk_plan_fixture(),
        "test/governance/milestone_scope_test.exs",
        "lib/KMS-01/cleanup.ex",
        global: false
      )

    assert_plan_violation(file_smuggling, "KMS-01", "implementation scope appears in task files")
  end

  test "plan-level demand-gated exclusions are exact and singular" do
    clean = no_risk_plan_fixture()
    assert plan_scope_violations(clean) == []

    missing =
      Regex.replace(~r/<demand_gated_exclusions>.*?<\/demand_gated_exclusions>/s, clean, "")

    assert_plan_violation(missing, "demand_gated_exclusions", "exactly once")

    duplicate =
      clean <>
        """
        <demand_gated_exclusions>
        AUTHN-POST-01
        KMS-01
        SIGNED-META-01
        </demand_gated_exclusions>
        """

    assert_plan_violation(duplicate, "demand_gated_exclusions", "exactly once")

    incomplete = String.replace(clean, "KMS-01\n", "", global: false)
    assert_plan_violation(incomplete, "demand_gated_exclusions", "exact set")
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

  test "every baseline row requires one complete allowed verification marker" do
    baseline = File.read!(@baseline_path)
    assert baseline_violations(baseline) == []
    marker = "[VERIFIED: `.planning/STATE.md` Baseline Findings, inspected 2026-09-09]"

    controls = [
      {String.replace(baseline, " #{marker}", "", global: false), "QUAL-73-001",
       "verification marker"},
      {String.replace(baseline, marker, "[VERIFIED: ]", global: false), "QUAL-73-001",
       "verification marker"},
      {String.replace(baseline, marker, "[VERIFIED: `mix ci.evidence`", global: false),
       "QUAL-73-001", "verification marker"},
      {String.replace(
         baseline,
         marker,
         "#{marker} [VERIFIED: `mix ci.evidence`]",
         global: false
       ), "QUAL-73-001", "exactly one"},
      {String.replace(baseline, marker, "[VERIFIED: source says good]", global: false),
       "QUAL-73-001", "allowed reference"},
      {String.replace(baseline, marker, "[VERIFIED: `curl example.test`]", global: false),
       "QUAL-73-001", "allowed reference"}
    ]

    for {markdown, id, detail} <- controls do
      assert_violation(markdown, id, detail)
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

  @tag :plan_73_07_task_1
  test "unknown checkpoint-prefixed task types cannot bypass governance" do
    bypass =
      no_risk_plan_fixture()
      |> String.replace(~s(<task type="auto">), ~s(<task type="checkpoint-bypass">),
        global: false
      )
      |> String.replace(
        "Extend deterministic policy tests only.",
        "Implement KMS-01 and change the published Relyra.start_login/3 entry point."
      )

    assert_plan_violation(bypass, "checkpoint-bypass", "task type")
  end

  @tag :plan_73_07_task_1
  test "negated approval text cannot authorize a governed mutation" do
    negated =
      String.replace(
        risky_plan_fixture("public_api"),
        "<decision>approval_class: public_api</decision>",
        "<decision>not approval_class: public_api</decision>"
      )

    assert_plan_violation(negated, "public_api", "decision")
  end

  @tag :plan_73_07_task_1
  test "contradictory plan-level scope cannot suppress a mutation checkpoint" do
    contradictory =
      String.replace(
        no_risk_plan_fixture(),
        "public_api: unchanged",
        "public_api: unchanged; mutation required",
        global: false
      )

    assert_plan_violation(contradictory, "public_api", "scope assertion")
  end

  @tag :plan_73_07_task_2
  test "a summary file cannot exempt an invalid plan from governance validation" do
    tmp_dir =
      Path.join(System.tmp_dir!(), "relyra-executed-plan-#{System.unique_integer([:positive])}")

    File.mkdir_p!(tmp_dir)
    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    plan_path = Path.join(tmp_dir, "99-01-PLAN.md")
    summary_path = Path.join(tmp_dir, "99-01-SUMMARY.md")

    invalid_plan =
      no_risk_plan_fixture()
      |> String.replace(
        "Extend deterministic policy tests only.",
        "Change the published Relyra.start_login/3 entry point."
      )

    File.write!(plan_path, invalid_plan)
    File.write!(summary_path, "status: complete\n")

    violations = repository_plan_violations([plan_path])

    assert violations != [], "summary presence silently exempted an invalid governed mutation"
  end

  @tag :plan_73_07_task_2
  test "completed-plan changed surfaces require the same prior checkpoint as task intent" do
    tmp_dir =
      Path.join(System.tmp_dir!(), "relyra-completed-diff-#{System.unique_integer([:positive])}")

    File.mkdir_p!(tmp_dir)
    on_exit(fn -> File.rm_rf!(tmp_dir) end)

    plan_path = Path.join(tmp_dir, "99-02-PLAN.md")
    summary_path = Path.join(tmp_dir, "99-02-SUMMARY.md")
    File.write!(plan_path, no_risk_plan_fixture())
    File.write!(summary_path, "status: complete\n")

    changes = [
      %{
        path: "lib/relyra.ex",
        before: "def start_login(connection, relay_context, opts \\\\ [])",
        after: "def start_login(connection, relay_context, policy, opts \\\\ [])"
      }
    ]

    violations = repository_plan_violations([plan_path], %{plan_path => changes})

    assert Enum.any?(violations, &(&1 =~ "public_api" and &1 =~ "checkpoint")),
           "completed-plan diff did not reach plan-local checkpoint enforcement: #{inspect(violations)}"
  end

  test "remote approval rejects appended commands outside the exact batch" do
    appended =
      String.replace(
        risky_plan_fixture("remote_github"),
        "GITHUB_REPOSITORY=szTheory/relyra ./scripts/setup_branch_protection.sh main",
        "GITHUB_REPOSITORY=szTheory/relyra ./scripts/setup_branch_protection.sh main && gh api -X DELETE repos/szTheory/relyra"
      )

    assert_plan_violation(appended, "remote_github", "mutation_commands")
  end

  test "baseline verification provenance must resolve to an existing repository path" do
    baseline = File.read!(@baseline_path)

    nonexistent =
      String.replace(
        baseline,
        "`.planning/STATE.md` Baseline Findings",
        "`.planning/no-such-evidence.md` Baseline Findings",
        global: false
      )

    assert_violation(nonexistent, "QUAL-73-001", "allowed reference")
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
    default_tightening: unchanged
    security_posture: unchanged
    semver_major: unchanged
    remote_github: unchanged
    protocol_scope: AUTHN-POST-01, KMS-01, and SIGNED-META-01 remain excluded
    </scope_assertions>
    <demand_gated_exclusions>
    AUTHN-POST-01
    KMS-01
    SIGNED-META-01
    </demand_gated_exclusions>
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
        <remote_batch>
        current_state: repository=szTheory/relyra; branch=main; checks=security (27, 1.19.5) | security (28, 1.19.5)
        desired_state: repository=szTheory/relyra; branch=main; checks=security (27, 1.19.5) | security (28, 1.19.5) | fleet-proxy-e2e
        affected_checks: security (27, 1.19.5) | security (28, 1.19.5) | fleet-proxy-e2e
        mutation_commands:
          - GITHUB_REPOSITORY=szTheory/relyra ./scripts/setup_branch_protection.sh main
        preflight_command: ./scripts/setup_branch_protection.sh --print-expected && gh api repos/szTheory/relyra/branches/main/protection
        rollback_commands:
          - gh api -X PUT repos/szTheory/relyra/branches/main/protection --input captured-current.json
        read_back_command: gh api repos/szTheory/relyra/branches/main/protection | jq -e '.["required_status_checks"]["contexts"] == ["security (27, 1.19.5)", "security (28, 1.19.5)", "fleet-proxy-e2e"]'
        resume_signal: approve remote_github szTheory/relyra main exact batch
        </remote_batch>
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
    public_api: #{if approval_class == "public_api", do: "mutation", else: "unchanged"}
    default_tightening: #{if approval_class == "default_tightening", do: "mutation", else: "unchanged"}
    security_posture: #{if approval_class == "security_posture", do: "mutation", else: "unchanged"}
    semver_major: #{if approval_class == "semver_major", do: "mutation", else: "unchanged"}
    remote_github: #{if approval_class == "remote_github", do: "mutation", else: "unchanged"}
    protocol_scope: feature-neutral; demand-gated capabilities remain excluded
    </scope_assertions>
    <demand_gated_exclusions>
    AUTHN-POST-01
    KMS-01
    SIGNED-META-01
    </demand_gated_exclusions>
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

  defp replace_risk_field(plan, old, new) do
    Regex.replace(
      ~r/(<risk_metadata>.*?)(#{Regex.escape(old)})/s,
      plan,
      fn _match, prefix, _field -> prefix <> new end,
      global: false
    )
  end

  defp remove_remote_field(plan, field) do
    Regex.replace(
      ~r/^\s*#{Regex.escape(field)}:.*?(?=^\s*[a-z_]+:|\s*<\/remote_batch>)/ms,
      plan,
      "",
      global: false
    )
  end

  defp replace_remote_scalar(plan, field, value) do
    Regex.replace(
      ~r/^(\s*#{Regex.escape(field)}:)\s*.*$/m,
      plan,
      fn _match, prefix -> "#{prefix} #{value}" end,
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

  defp plan_scope_violations(markdown, changed_classes \\ []) do
    scope_sections = tag_sections(markdown, "scope_assertions")
    exclusion_sections = tag_sections(markdown, "demand_gated_exclusions")
    tasks = plan_tasks(markdown)
    type_violations = task_type_violations(tasks)
    validated_tasks = Enum.filter(tasks, &valid_task_type?/1)

    scope_violations =
      case scope_sections do
        [scope] ->
          approval_scope_violations(
            parse_scope_assertions(scope),
            validated_tasks,
            changed_classes
          )

        _other ->
          ["scope_assertions must appear exactly once"]
      end

    exclusion_violations = demand_gated_exclusion_violations(exclusion_sections)

    type_violations ++
      task_risk_metadata_violations(validated_tasks) ++
      scope_violations ++
      exclusion_violations ++
      deterministic_verification_violations(validated_tasks) ++
      forbidden_capability_violations(validated_tasks) ++
      manual_acceptance_violations(markdown) ++
      orphan_checkpoint_violations(validated_tasks)
  end

  defp task_type_violations(tasks) do
    tasks
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {task, index} ->
      if valid_task_type?(task) do
        []
      else
        identity = nonempty(task.name, "task #{index}")
        ["#{identity} has unsupported task type #{inspect(task.type)}"]
      end
    end)
  end

  defp valid_task_type?(task), do: task.type in @task_types
  defp authorization_checkpoint?(task), do: task.type == "checkpoint:decision"

  defp implementation_bearing_task?(task),
    do: valid_task_type?(task) and not authorization_checkpoint?(task)

  defp demand_gated_exclusion_violations([section]) do
    exclusions =
      section
      |> String.split(~r/[\s,]+/, trim: true)

    cond do
      length(exclusions) != length(Enum.uniq(exclusions)) ->
        ["demand_gated_exclusions must contain each identifier exactly once"]

      MapSet.new(exclusions) != MapSet.new(@demand_gated_exclusions) ->
        [
          "demand_gated_exclusions must equal the exact set #{Enum.join(@demand_gated_exclusions, ", ")}"
        ]

      true ->
        []
    end
  end

  defp demand_gated_exclusion_violations(sections) do
    ["demand_gated_exclusions must appear exactly once, found #{length(sections)}"]
  end

  defp approval_scope_violations(scope, tasks, changed_classes) do
    Enum.flat_map(@approval_classes, fn approval_class ->
      values = Map.get(scope, approval_class, [])

      shape_violations =
        cond do
          length(values) != 1 ->
            ["#{approval_class} scope assertion must appear exactly once"]

          hd(values) not in @risk_values ->
            ["#{approval_class} scope assertion value is unsupported: #{hd(values)}"]

          true ->
            []
        end

      checkpoint_violations =
        if risky_scope?(approval_class, values, tasks, changed_classes) do
          mutation_index = mutation_task_index(tasks, approval_class, changed_classes)
          checkpoint_index = matching_checkpoint_index(tasks, approval_class)

          checkpoint_violations(approval_class, mutation_index, checkpoint_index, tasks)
        else
          []
        end

      shape_violations ++ checkpoint_violations
    end)
  end

  defp task_risk_metadata_violations(tasks) do
    tasks
    |> Enum.filter(&implementation_bearing_task?/1)
    |> Enum.flat_map(fn task ->
      identity = nonempty(task.name, "unnamed task")

      shape_violations =
        case task.risk_metadata_sections do
          [_section] ->
            []

          sections ->
            ["#{identity} risk_metadata must appear exactly once, found #{length(sections)}"]
        end

      field_violations =
        Enum.flat_map(@approval_classes, fn risk_class ->
          values = Map.get(task.risk_metadata, risk_class, [])

          cond do
            length(values) != 1 ->
              ["#{identity} #{risk_class} risk_metadata must appear exactly once"]

            hd(values) not in @risk_values ->
              ["#{identity} #{risk_class} risk_metadata value is unsupported: #{hd(values)}"]

            true ->
              []
          end
        end)

      mismatch_violations =
        for risk_class <- governed_task_classes(task),
            Map.get(task.risk_metadata, risk_class) != ["mutation"],
            do: "#{identity} #{risk_class} risk_metadata contradicts governed surface"

      shape_violations ++ field_violations ++ mismatch_violations
    end)
  end

  defp risky_scope?(approval_class, values, tasks, changed_classes) do
    values != ["unchanged"] or
      mutation_task_index(tasks, approval_class, changed_classes) != nil
  end

  defp checkpoint_violations(approval_class, mutation_index, checkpoint_index, tasks) do
    cond do
      mutation_index == nil ->
        ["#{approval_class} mutation task is missing"]

      checkpoint_index == nil ->
        ["#{approval_class} matching decision checkpoint is missing"]

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
      authorization_checkpoint?(task) and decision_approval_class(task) == approval_class
    end)
  end

  defp decision_approval_class(task) do
    case tag_sections(task.body, "decision") do
      [decision] ->
        case Regex.run(
               ~r/^approval_class:\s*(#{Enum.join(@approval_classes, "|")})$/,
               String.trim(decision),
               capture: :all_but_first
             ) do
          [approval_class] -> approval_class
          nil -> nil
        end

      _other ->
        nil
    end
  end

  defp mutation_task_index(tasks, approval_class, changed_classes \\ []) do
    Enum.find_index(tasks, fn task ->
      implementation_bearing_task?(task) and
        (Map.get(task.risk_metadata, approval_class) == ["mutation"] or
           approval_class in governed_task_classes(task) or
           String.contains?(task.action, "approval_class: #{approval_class}"))
    end) || changed_surface_mutation_index(tasks, approval_class, changed_classes)
  end

  defp changed_surface_mutation_index(tasks, approval_class, changed_classes) do
    if approval_class in changed_classes do
      Enum.find_index(tasks, &implementation_bearing_task?/1)
    end
  end

  defp governed_task_classes(task) do
    files =
      task.files
      |> String.split(~r/[\n,]/, trim: true)
      |> Enum.map(&String.trim/1)

    content = "#{task.name}\n#{task.action}"

    []
    |> maybe_add_class(
      "public_api",
      "lib/relyra.ex" in files or
        Enum.any?(files, &published_behaviour_path?/1) or
        Regex.match?(
          ~r/\b(?:change|modify|rename|remove|replace)\b.{0,100}\bRelyra\.(?:start_login|consume_response)\/3\b/is,
          content
        )
    )
    |> maybe_add_class(
      "default_tightening",
      Regex.match?(~r/\b(?:tighten|stricter|change)\b.{0,80}\bdefault\b/is, content)
    )
    |> maybe_add_class(
      "security_posture",
      Enum.any?(files, &security_seam_path?/1) or
        Regex.match?(
          ~r/\b(?:change|weaken|replace)\b.{0,100}\b(?:trust|algorithm|key material)\b/is,
          content
        )
    )
    |> maybe_add_class(
      "semver_major",
      Regex.match?(
        ~r/\b(?:bump|publish)\b.{0,80}\b(?:semver\s+)?major\b|\brelease\s+(?:a\s+)?(?:real\s+)?(?:semver\s+)?major\s+version\b/is,
        content
      )
    )
    |> maybe_add_class(
      "remote_github",
      Enum.any?(files, &remote_state_path?/1) and
        Regex.match?(~r/\b(?:mutate|apply|enable|disable|change|update)\b/i, content)
    )
    |> Enum.reverse()
  end

  defp maybe_add_class(classes, class, true), do: [class | classes]
  defp maybe_add_class(classes, _class, false), do: classes

  defp published_behaviour_path?(path) do
    path in [
      "lib/relyra/connection_resolver.ex",
      "lib/relyra/session_adapter.ex",
      "lib/relyra/user_mapper.ex",
      "lib/relyra/request_store.ex",
      "lib/relyra/replay_store.ex"
    ]
  end

  defp security_seam_path?(path) do
    path in [
      "lib/relyra/security/signature.ex",
      "lib/relyra/security/xml/pure_beam.ex",
      "lib/relyra/security/xml/c14n.ex",
      "lib/relyra/security/algorithm_policy.ex",
      "lib/relyra/ecto/audit_writer.ex"
    ]
  end

  defp remote_state_path?(path) do
    String.starts_with?(path, ".github/") or path == "scripts/setup_branch_protection.sh"
  end

  defp changed_surface_classes(_path, before_content, after_content)
       when before_content == after_content,
       do: []

  defp changed_surface_classes("lib/relyra.ex", before_content, after_content) do
    published_signatures =
      ~r/^\s*def\s+(?:start_login|consume_response)\s*\([^\n]*\)/m

    if Regex.scan(published_signatures, before_content) ==
         Regex.scan(published_signatures, after_content),
       do: [],
       else: ["public_api"]
  end

  defp changed_surface_classes(path, _before_content, _after_content) do
    cond do
      published_behaviour_path?(path) -> ["public_api"]
      security_seam_path?(path) -> ["security_posture"]
      path == "mix.exs" -> ["semver_major"]
      remote_state_path?(path) -> ["remote_github"]
      true -> []
    end
  end

  defp remote_checkpoint_violations(checkpoint) do
    batch_violations =
      case tag_sections(checkpoint.body, "remote_batch") do
        [section] ->
          validate_remote_batch(parse_remote_batch(section))

        sections ->
          [
            "remote_github checkpoint requires exactly one remote_batch, found #{length(sections)}"
          ]
      end

    outer_resume =
      if placeholder_value?(checkpoint.resume_signal),
        do: ["remote_github checkpoint is missing resume signal"],
        else: []

    batch_violations ++ outer_resume
  end

  defp parse_remote_batch(section) do
    scalar_fields =
      for field <-
            ~w(current_state desired_state affected_checks preflight_command read_back_command resume_signal),
          into: %{} do
        value =
          case Regex.run(
                 ~r/^\s*#{Regex.escape(field)}:\s*(.*?)\s*$/m,
                 section,
                 capture: :all_but_first
               ) do
            [captured] -> captured
            nil -> nil
          end

        {field, value}
      end

    list_fields =
      for field <- ~w(mutation_commands rollback_commands), into: %{} do
        values =
          case Regex.run(
                 ~r/^\s*#{Regex.escape(field)}:\s*\n((?:\s+-[^\n]*\n?)+)/m,
                 section,
                 capture: :all_but_first
               ) do
            [lines] ->
              ~r/^\s+-\s*(.*)$/m
              |> Regex.scan(lines, capture: :all_but_first)
              |> List.flatten()

            nil ->
              []
          end

        {field, values}
      end

    Map.merge(scalar_fields, list_fields)
  end

  defp validate_remote_batch(batch) do
    required =
      ~w(current_state desired_state affected_checks mutation_commands preflight_command rollback_commands read_back_command resume_signal)

    presence =
      for field <- required,
          remote_field_missing?(Map.get(batch, field)),
          do: "remote_github remote_batch #{field} is missing or placeholder"

    if presence == [] do
      validate_complete_remote_batch(batch)
    else
      presence
    end
  end

  defp validate_complete_remote_batch(batch) do
    current = parse_remote_state(batch["current_state"])
    desired = parse_remote_state(batch["desired_state"])
    affected = parse_check_set(batch["affected_checks"])

    state_shape =
      []
      |> maybe_remote_violation(current == :error, "current_state is malformed")
      |> maybe_remote_violation(desired == :error, "desired_state is malformed")

    if state_shape == [] do
      same_target = current.repository == desired.repository and current.branch == desired.branch
      target = {desired.repository, desired.branch}

      state_shape
      |> maybe_remote_violation(
        not same_target,
        "current_state and desired_state target mismatch"
      )
      |> maybe_remote_violation(
        current.checks == desired.checks,
        "desired_state must change captured current_state"
      )
      |> maybe_remote_violation(
        affected != desired.checks,
        "affected_checks must equal desired_state checks"
      )
      |> maybe_remote_violation(
        not Enum.all?(batch["mutation_commands"], &command_targets?(&1, target)),
        "mutation_commands target mismatch"
      )
      |> maybe_remote_violation(
        not (String.contains?(batch["preflight_command"], "--print-expected") and
               command_targets?(batch["preflight_command"], target)),
        "preflight_command target mismatch"
      )
      |> maybe_remote_violation(
        not (Enum.all?(batch["rollback_commands"], &command_targets?(&1, target)) and
               Enum.any?(
                 batch["rollback_commands"],
                 &String.contains?(&1, "captured-current.json")
               )),
        "rollback_commands target or captured state mismatch"
      )
      |> maybe_remote_violation(
        not (command_targets?(batch["read_back_command"], target) and
               Enum.all?(affected, &String.contains?(batch["read_back_command"], &1))),
        "read_back_command target or affected checks mismatch"
      )
      |> maybe_remote_violation(
        not (String.contains?(batch["resume_signal"], desired.repository) and
               String.contains?(batch["resume_signal"], desired.branch)),
        "resume_signal target mismatch"
      )
    else
      state_shape
    end
  end

  defp remote_field_missing?(values) when is_list(values),
    do: values == [] or Enum.any?(values, &placeholder_value?/1)

  defp remote_field_missing?(value), do: placeholder_value?(value)

  defp placeholder_value?(value) when not is_binary(value), do: true

  defp placeholder_value?(value) do
    normalized = value |> String.trim() |> String.downcase()
    normalized == "" or normalized in ["tbd", "placeholder", "exact commands omitted"]
  end

  defp parse_remote_state(value) do
    case Regex.run(
           ~r/^repository=([^;]+);\s*branch=([^;]+);\s*checks=(.+)$/,
           value,
           capture: :all_but_first
         ) do
      [repository, branch, checks] ->
        %{
          repository: String.trim(repository),
          branch: String.trim(branch),
          checks: parse_check_set(checks)
        }

      nil ->
        :error
    end
  end

  defp parse_check_set(value) do
    value
    |> String.split("|", trim: true)
    |> Enum.map(&String.trim/1)
    |> MapSet.new()
  end

  defp command_targets?(command, {repository, branch}) do
    api_target = "repos/#{repository}/branches/#{branch}/protection"

    script_target =
      "GITHUB_REPOSITORY=#{repository} ./scripts/setup_branch_protection.sh #{branch}"

    String.contains?(command, api_target) or String.contains?(command, script_target)
  end

  defp maybe_remote_violation(violations, true, detail),
    do: violations ++ ["remote_github remote_batch #{detail}"]

  defp maybe_remote_violation(violations, false, _detail), do: violations

  defp deterministic_verification_violations(tasks) do
    tasks
    |> Enum.filter(&implementation_bearing_task?/1)
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
    tasks
    |> Enum.filter(&implementation_bearing_task?/1)
    |> Enum.flat_map(fn task ->
      [
        {"name", task.name},
        {"files", task.files},
        {"action", task.action}
      ]
      |> Enum.flat_map(fn {region, content} ->
        for capability <- @demand_gated_exclusions,
            String.contains?(content, capability),
            do: "#{capability} implementation scope appears in task #{region}"
      end)
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
      if authorization_checkpoint?(task) do
        case decision_approval_class(task) do
          approval_class when approval_class in @approval_classes ->
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
      risk_metadata_sections = tag_sections(body, "risk_metadata")

      %{
        type: attribute_value(attributes, "type"),
        gate: attribute_value(attributes, "gate"),
        body: body,
        name: tag_content(body, "name"),
        action: tag_content(body, "action"),
        files: tag_content(body, "files"),
        verify: tag_content(body, "verify"),
        acceptance_criteria: tag_content(body, "acceptance_criteria"),
        resume_signal: tag_content(body, "resume-signal"),
        risk_metadata_sections: risk_metadata_sections,
        risk_metadata:
          risk_metadata_sections
          |> Enum.flat_map(&parse_key_values/1)
          |> Enum.reduce(%{}, fn {key, value}, fields ->
            Map.update(fields, key, [value], &[value | &1])
          end)
      }
    end)
  end

  defp parse_key_values(section) do
    section
    |> String.split("\n")
    |> Enum.flat_map(fn line ->
      case String.split(line, ":", parts: 2) do
        [key, value] -> [{String.trim(key), String.trim(value)}]
        _other -> []
      end
    end)
  end

  defp executed_plan?(path) do
    String.ends_with?(path, "-PLAN.md") and
      File.exists?(String.replace_suffix(path, "-PLAN.md", "-SUMMARY.md"))
  end

  defp repository_plan_violations(plan_paths, changed_surfaces_by_plan \\ %{}) do
    Enum.flat_map(plan_paths, fn plan_path ->
      case repository_changed_surfaces(plan_path, changed_surfaces_by_plan) do
        {:ok, changes} ->
          changed_classes =
            changes
            |> Enum.flat_map(fn change ->
              changed_surface_classes(change.path, change.before, change.after)
            end)
            |> Enum.uniq()

          plan_path
          |> File.read!()
          |> plan_scope_violations(changed_classes)

        {:error, reason} ->
          plan_violations = plan_path |> File.read!() |> plan_scope_violations()
          plan_violations ++ ["#{plan_path} completed-plan diff provenance #{reason}"]
      end
    end)
  end

  defp repository_changed_surfaces(plan_path, changed_surfaces_by_plan) do
    cond do
      Map.has_key?(changed_surfaces_by_plan, plan_path) ->
        validate_changed_surfaces(Map.fetch!(changed_surfaces_by_plan, plan_path))

      executed_plan?(plan_path) ->
        plan_path
        |> String.replace_suffix("-PLAN.md", "-SUMMARY.md")
        |> summary_changed_surfaces()

      true ->
        {:ok, []}
    end
  end

  defp validate_changed_surfaces(changes) when is_list(changes) do
    if Enum.all?(changes, fn
         %{path: path, before: before_content, after: after_content}
         when is_binary(path) and is_binary(before_content) and is_binary(after_content) ->
           true

         _other ->
           false
       end) do
      {:ok, changes}
    else
      {:error, "is malformed"}
    end
  end

  defp validate_changed_surfaces(_changes), do: {:error, "is malformed"}

  defp summary_changed_surfaces(summary_path) do
    with {:ok, summary} <- File.read(summary_path),
         commits when commits != [] <- summary_task_commits(summary),
         {:ok, changes} <- commit_changed_surfaces(commits) do
      {:ok, changes}
    else
      [] -> {:error, "is absent"}
      {:error, _reason} -> {:error, "is malformed"}
    end
  end

  defp summary_task_commits(summary) do
    case Regex.run(~r/^## Task Commits\s*(.*?)(?=^## |\z)/ms, summary, capture: :all_but_first) do
      [section] ->
        ~r/`([0-9a-f]{7,40})`/
        |> Regex.scan(section, capture: :all_but_first)
        |> Enum.map(fn [commit] -> commit end)
        |> Enum.uniq()

      nil ->
        []
    end
  end

  defp commit_changed_surfaces(commits) do
    Enum.reduce_while(commits, {:ok, []}, fn commit, {:ok, changes} ->
      case commit_paths(commit) do
        {:ok, paths} ->
          commit_changes =
            Enum.map(paths, fn path ->
              %{
                path: path,
                before: git_file_at("#{commit}^", path),
                after: git_file_at(commit, path)
              }
            end)

          {:cont, {:ok, changes ++ commit_changes}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
  end

  defp commit_paths(commit) do
    case System.cmd("git", ["diff-tree", "--no-commit-id", "--name-only", "-r", commit],
           stderr_to_stdout: true
         ) do
      {output, 0} -> {:ok, String.split(output, "\n", trim: true)}
      {_output, _status} -> {:error, "cannot resolve task commit #{commit}"}
    end
  end

  defp git_file_at(revision, path) do
    case System.cmd("git", ["show", "#{revision}:#{path}"], stderr_to_stdout: true) do
      {content, 0} -> content
      {_output, _status} -> ""
    end
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
    Enum.flat_map(rows, fn row ->
      evidence = String.trim(row["Reproducible Evidence"] || "")
      id = row["Finding ID"]
      marker_count = length(Regex.scan(~r/\[VERIFIED:/, evidence))

      cond do
        marker_count != 1 ->
          ["#{id} Reproducible Evidence must contain exactly one verification marker"]

        not String.ends_with?(evidence, "]") ->
          ["#{id} Reproducible Evidence verification marker is incomplete"]

        true ->
          [description, marker_body] = String.split(evidence, "[VERIFIED:", parts: 2)
          reference = marker_body |> String.trim_trailing("]") |> String.trim()

          []
          |> maybe_evidence_violation(
            String.trim(description) == "",
            "#{id} Reproducible Evidence lacks descriptive text before verification marker"
          )
          |> maybe_evidence_violation(
            reference == "",
            "#{id} Reproducible Evidence verification marker is empty"
          )
          |> maybe_evidence_violation(
            reference != "" and not allowed_verification_reference?(reference),
            "#{id} Reproducible Evidence verification marker lacks an allowed reference"
          )
      end
    end)
  end

  defp allowed_verification_reference?(reference) do
    tokens =
      ~r/`([^`]+)`/
      |> Regex.scan(reference, capture: :all_but_first)
      |> List.flatten()

    Enum.any?(tokens, &allowed_verification_token?/1)
  end

  defp allowed_verification_token?(token) do
    repository_path? =
      Enum.any?(
        [".planning/", ".github/", "docs/", "guides/", "lib/", "scripts/", "test/"],
        &String.starts_with?(token, &1)
      )

    executable_command? =
      Regex.match?(
        ~r/^(?:mix\s+(?:test\b|qa\b|format\b|ci\.[\w.-]+\b)|rg(?:\s|$)|git\s+(?:ls-files|status|diff)\b|\.\/scripts\/)/,
        token
      )

    repository_path? or executable_command?
  end

  defp maybe_evidence_violation(violations, true, message), do: violations ++ [message]
  defp maybe_evidence_violation(violations, false, _message), do: violations

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
