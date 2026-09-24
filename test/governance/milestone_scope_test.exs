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
  @phase_73_requirements ~w(EVID-01 EVID-02 QUAL-01 PIPE-01 GOV-01 GOV-02)

  @tag :plan_73_21_task_1
  test "ready_for_verification reaches the complete active governance identity" do
    root = governance_repository_fixture()

    mutate_file(root, ".planning/STATE.md", fn state ->
      Regex.replace(
        ~r/^status:\s*(?:executing|in_progress|ready_for_verification)$/m,
        state,
        "status: ready_for_verification"
      )
    end)

    assert {:ok, identity} = validated_governance_identity(root)
    assert identity.status == "ready_for_verification"
    assert identity.milestone_version == "v1.11"
    assert identity.milestone_name == "First-Adopter Twin"
    assert identity.current_phase == "73"
    assert identity.phase_requirements["73"] == MapSet.new(@phase_73_requirements)
    assert identity.plan_paths != []

    phase_dir = Path.join(root, ".planning/phases/73-twin-contract-and-baseline")
    assert Enum.all?(identity.plan_paths, &(Path.dirname(&1) == phase_dir))

    assert {:ok, checked_in_identity} = validated_governance_identity(File.cwd!())
    assert checked_in_identity.status in ~w(executing in_progress ready_for_verification)
    assert checked_in_identity.phase_requirements["73"] == MapSet.new(@phase_73_requirements)
    assert checked_in_identity.plan_paths != []
  end

  @tag :plan_73_21_task_2
  test "lifecycle authority accepts only the three exact active STATE values" do
    for status <- ~w(executing in_progress ready_for_verification) do
      root = governance_repository_fixture()
      replace_state_status!(root, "status: #{status}")

      assert {:ok, identity} = validated_governance_identity(root)
      assert identity.status == status
    end

    controls = [
      {"completed", "status: completed", ~s(status=["completed"])},
      {"blocked", "status: blocked", ~s(status=["blocked"])},
      {"paused", "status: paused", ~s(status=["paused"])},
      {"not started", "status: not_started", ~s(status=["not_started"])},
      {"unknown", "status: unknown", ~s(status=["unknown"])},
      {"empty", "status: ", ~s(status=[""])},
      {"whitespace only", "status:    ", ~s(status=[""])},
      {"missing", "", "status=[]"},
      {"duplicated", "status: executing\nstatus: ready_for_verification",
       ~s(status=["executing", "ready_for_verification"])},
      {"quoted lookalike", ~s(status: "ready_for_verification"),
       ~s(status=["\\\"ready_for_verification\\\""])},
      {"malformed lookalike", "status : ready_for_verification", "status=[]"}
    ]

    for {name, replacement, field_diagnostic} <- controls do
      root = governance_repository_fixture()
      replace_state_status!(root, replacement)

      assert {:error, violations} = validated_governance_identity(root)

      assert Enum.any?(violations, fn violation ->
               violation =~ ".planning/STATE.md" and
                 violation =~ "must be singular and active" and
                 violation =~ field_diagnostic
             end),
             "expected explicit STATE status diagnostic for #{name}, got: #{inspect(violations)}"
    end
  end

  @tag :plan_73_10_task_1
  test "active v1.11 discovery is closed, non-vacuous, and cross-source consistent" do
    root = governance_repository_fixture()

    assert {:ok, identity} = validated_governance_identity(root)
    assert identity.milestone_version == "v1.11"
    assert identity.milestone_name == "First-Adopter Twin"
    assert identity.current_phase == "73"
    assert identity.phase_requirements["73"] == MapSet.new(@phase_73_requirements)
    assert identity.plan_paths != []

    controls = [
      {"missing active milestone",
       fn root ->
         mutate_file(root, ".planning/ROADMAP.md", &String.replace(&1, "- Active:", "- Current:"))
       end},
      {"active phase set is empty",
       fn root ->
         mutate_file(
           root,
           ".planning/ROADMAP.md",
           &Regex.replace(~r/^- \[[ x]\] \*\*Phase 7[3-9]:.*\n/m, &1, "")
         )
       end},
      {"STATE milestone",
       fn root ->
         mutate_file(
           root,
           ".planning/STATE.md",
           &String.replace(&1, "milestone: v1.11", "milestone: v9.9")
         )
       end},
      {"STATE current phase",
       fn root ->
         mutate_file(
           root,
           ".planning/STATE.md",
           &String.replace(&1, "current_phase: 73", "current_phase: 74")
         )
       end},
      {"milestone identity",
       fn root ->
         mutate_file(
           root,
           ".planning/PROJECT.md",
           &String.replace(&1, "## Current Milestone: v1.11", "## Current Milestone: v9.9")
         )
       end},
      {"Phase 73 requirement set",
       fn root ->
         mutate_file(
           root,
           ".planning/ROADMAP.md",
           &String.replace(&1, "GOV-01, GOV-02", "GOV-01", global: false)
         )
       end},
      {"malformed phase checkbox",
       fn root ->
         mutate_file(
           root,
           ".planning/ROADMAP.md",
           &String.replace(&1, "- [x] **Phase 73:", "- [-] **Phase 73:")
         )
       end},
      {"duplicate phase identity",
       fn root ->
         mutate_file(root, ".planning/ROADMAP.md", fn roadmap ->
           roadmap <> "\n- [ ] **Phase 73: Duplicate** — invalid duplicate.\n"
         end)
       end},
      {"tracked phase directory",
       fn root ->
         File.rename!(
           Path.join(root, ".planning/phases/73-twin-contract-and-baseline"),
           Path.join(root, ".planning/phases/73-renamed")
         )
       end},
      {"current phase PLAN",
       fn root ->
         root
         |> Path.join(".planning/phases/73-twin-contract-and-baseline/73-10-PLAN.md")
         |> File.rm!()
       end}
    ]

    for {diagnostic, mutation} <- controls do
      fixture = governance_repository_fixture()
      mutation.(fixture)
      assert {:error, violations} = validated_governance_identity(fixture)

      assert Enum.any?(violations, &String.contains?(&1, diagnostic)),
             "expected #{diagnostic}, got: #{inspect(violations)}"
    end
  end

  @tag :plan_73_10_task_1
  test "trusted plan identity selects only the three immutable legacy paths" do
    root = governance_repository_fixture()
    assert {:ok, identity} = validated_governance_identity(root)

    for plan <- ~w(01 02 03) do
      path = Path.join(root, ".planning/phases/73-twin-contract-and-baseline/73-#{plan}-PLAN.md")
      File.write!(path, "<tasks></tasks>\n")
      File.write!(String.replace_suffix(path, "-PLAN.md", "-SUMMARY.md"), "status: complete\n")
      assert repository_plan_schema(identity, path) == :legacy
    end

    current_path = hd(identity.plan_paths)
    current = File.read!(current_path)

    without_exclusions =
      Regex.replace(~r/<demand_gated_exclusions>.*?<\/demand_gated_exclusions>/s, current, "")

    assert repository_plan_schema(identity, current_path) == :current

    assert Enum.any?(
             repository_plan_scope_violations(identity, current_path, without_exclusions, []),
             &(&1 =~ "demand_gated_exclusions")
           )

    renamed = Path.join(root, ".planning/phases/73-twin-contract-and-baseline/73-03-copy-PLAN.md")
    File.write!(renamed, "<tasks></tasks>\n")
    File.write!(String.replace_suffix(renamed, "-PLAN.md", "-SUMMARY.md"), "status: complete\n")
    assert repository_plan_schema(identity, renamed) == :current
  end

  @tag :plan_73_10_task_2
  test "completed plan surfaces derive from every trusted scoped commit" do
    fixture = completed_plan_git_fixture()

    assert {:ok, provenance} = completed_plan_provenance(fixture.root, fixture.plan_path)
    assert provenance.commits == fixture.implementation_commits
    assert provenance.summary_commits == fixture.implementation_commits

    classes =
      provenance.changes
      |> Enum.flat_map(&changed_surface_classes(&1.path, &1.before, &1.after))

    assert "public_api" in classes
    refute fixture.completion_commit in provenance.commits
  end

  @tag :plan_73_10_task_2
  test "summary hashes are an exact audit cross-check and never select reviewed changes" do
    for {variant, diagnostic} <- [
          {:omitted, "omitted"},
          {:duplicate, "duplicate"},
          {:foreign, "foreign"},
          {:unresolved, "unresolved"},
          {:foreign_scope, "foreign"}
        ] do
      fixture = completed_plan_git_fixture(variant)

      assert {:error, violations, provenance} =
               completed_plan_provenance(fixture.root, fixture.plan_path)

      assert Enum.any?(violations, &String.contains?(&1, diagnostic)),
             "expected #{diagnostic} for #{variant}, got: #{inspect(violations)}"

      if variant == :omitted do
        classes =
          provenance.changes
          |> Enum.flat_map(&changed_surface_classes(&1.path, &1.before, &1.after))

        assert "public_api" in classes
      end
    end
  end

  @tag :plan_73_10_task_2
  test "completed plan provenance rejects malformed or ambiguous execution boundaries" do
    for {variant, diagnostic} <- [
          {:missing_boundary, "completion boundary"},
          {:duplicate_boundary, "completion boundary"},
          {:empty_implementation, "implementation set is empty"},
          {:malformed_manifest, "phase manifest"},
          {:unreachable_manifest, "reachable"}
        ] do
      fixture = completed_plan_git_fixture(variant)
      result = completed_plan_provenance(fixture.root, fixture.plan_path)

      assert match?({:error, _, _}, result) or match?({:error, _}, result)
      violations = elem(result, 1)

      assert Enum.any?(violations, &String.contains?(&1, diagnostic)),
             "expected #{diagnostic} for #{variant}, got: #{inspect(violations)}"
    end
  end

  @tag :plan_73_13_task_3
  test "an incomplete manifest cannot hide a Git-derived governed commit" do
    fixture = completed_plan_git_fixture(:manifest_omitted)

    assert {:error, violations, commits} =
             trusted_plan_commits(fixture.root, "73-99", fixture.completion_commit)

    assert Enum.any?(violations, &String.contains?(&1, "omitted"))
    assert commits == fixture.implementation_commits
    assert {:ok, changes} = commit_changed_surfaces(fixture.root, commits)

    assert "public_api" in Enum.flat_map(
             changes,
             &changed_surface_classes(&1.path, &1.before, &1.after)
           )
  end

  @tag :plan_73_13_task_3
  test "manifest is an optional exact ordered audit of Git-derived commits" do
    for {variant, diagnostic} <- [
          {:manifest_extra, "foreign"},
          {:manifest_reordered, "reorders"},
          {:manifest_duplicate, "duplicate"},
          {:manifest_ambiguous, "ambiguous"},
          {:unreachable_manifest, "unreachable"},
          {:manifest_boundary, "completion boundary"}
        ] do
      fixture = completed_plan_git_fixture(variant)

      assert {:error, violations, commits} =
               trusted_plan_commits(fixture.root, "73-99", fixture.completion_commit)

      assert Enum.any?(violations, &String.contains?(&1, diagnostic)),
             "expected #{diagnostic} manifest violation for #{variant}, got: #{inspect(violations)}"

      assert commits == fixture.implementation_commits
    end

    full = completed_plan_git_fixture(:manifest_clean)

    assert {:ok, full.implementation_commits} ==
             trusted_plan_commits(full.root, "73-99", full.completion_commit)

    absent = completed_plan_git_fixture()

    assert {:ok, absent.implementation_commits} ==
             trusted_plan_commits(absent.root, "73-99", absent.completion_commit)
  end

  @tag :plan_73_15_task_2
  test "post-summary risky commits remain inside completed-plan governance" do
    fixture = completed_plan_git_fixture(:post_summary_risky)

    assert {:ok, provenance} = completed_plan_provenance(fixture.root, fixture.plan_path)
    assert provenance.commits == fixture.implementation_commits ++ fixture.descendant_commits
    assert provenance.summary_commits == fixture.implementation_commits
    assert provenance.review_endpoint == fixture.review_endpoint

    identity = %{
      root: fixture.root,
      milestone_version: "v1.11",
      current_phase: "73"
    }

    violations = repository_plan_violations([fixture.plan_path], %{}, identity)

    assert Enum.any?(violations, &(&1 =~ "public_api" and &1 =~ "checkpoint")),
           "expected descendant public API approval violation, got: #{inspect(violations)}"
  end

  @tag :plan_73_15_task_2
  test "review endpoint includes every ordered exact-scope descendant only" do
    for variant <- [:post_summary_harmless, :post_summary_multiple] do
      fixture = completed_plan_git_fixture(variant)
      assert {:ok, provenance} = completed_plan_provenance(fixture.root, fixture.plan_path)
      assert provenance.commits == fixture.implementation_commits ++ fixture.descendant_commits
      assert provenance.summary_commits == fixture.implementation_commits
      refute fixture.completion_commit in provenance.commits
    end
  end

  @tag :plan_73_29_task_1
  test "governance task children are singular, balanced, and direct" do
    clean = no_risk_plan_fixture()
    action = "<action>Extend deterministic policy tests only.</action>"
    files = "<files>test/governance/milestone_scope_test.exs</files>"

    controls = [
      {String.replace(clean, action, action <> "\n" <> action, global: false), "action",
       "exactly once"},
      {String.replace(clean, files, files <> "\n<files></files>", global: false), "files",
       "exactly once"},
      {String.replace(clean, action, "<action></action>\n" <> action, global: false), "action",
       "exactly once"},
      {String.replace(clean, "</action>", "", global: false), "action", "boundary"}
    ]

    for {invalid, child, diagnostic} <- controls do
      violations = plan_scope_violations(invalid)

      assert Enum.any?(violations, fn violation ->
               violation =~ "task child" and violation =~ child and violation =~ diagnostic
             end),
             "expected a singular direct #{child} diagnostic, got: #{inspect(violations)}"
    end

    nested =
      String.replace(
        clean,
        action,
        "<action>Text mentions a nested section: <files>example.txt</files>.</action>",
        global: false
      )

    assert plan_scope_violations(nested) == []
  end

  @tag :plan_73_29_task_1
  test "all tracked Phase 73 plans retain their valid current or legacy task grammar" do
    assert {:ok, _identity} = validated_governance_identity(File.cwd!())

    phase_dir = ".planning/phases/73-twin-contract-and-baseline"
    plan_paths = Path.wildcard(Path.join(phase_dir, "73-*-PLAN.md")) |> Enum.sort()

    assert length(plan_paths) == 32

    violations = Enum.flat_map(plan_paths, &plan_task_structure_violations/1)

    assert violations == [],
           "tracked plans must retain their established schema branches: #{inspect(violations)}"
  end

  @tag :plan_73_29_task_1
  test "changed-surface gates distinguish local workflow edits from real major and remote changes" do
    mix_before = File.read!("mix.exs")

    major_bump =
      Regex.replace(~r/@version "(\d+)\./, mix_before, fn _match, major ->
        "@version \"#{String.to_integer(major) + 1}."
      end)

    alias_edit = String.replace(mix_before, "ci.phase73.reconciliation", "ci.phase73.replay")
    workflow_before = File.read!(".github/workflows/security-gates.yml")
    workflow_after = workflow_before <> "\n# Local workflow policy change\n"

    assert changed_surface_classes("mix.exs", mix_before, alias_edit) == []
    assert changed_surface_classes("mix.exs", mix_before, major_bump) == ["semver_major"]

    assert changed_surface_classes(
             ".github/workflows/security-gates.yml",
             workflow_before,
             workflow_after
           ) == []

    assert changed_surface_classes(
             "scripts/setup_branch_protection.sh",
             "current remote mutation tool",
             "changed remote mutation tool"
           ) == ["remote_github"]
  end

  defp plan_task_structure_violations(path) do
    case closed_plan_tasks(File.read!(path)) do
      {:ok, task_region, tasks} ->
        task_acceptance_ownership_violations(task_region, tasks)
        |> Enum.map(&"#{path}: #{&1}")

      {:error, violations} ->
        Enum.map(violations, &"#{path}: #{&1}")
    end
  end

  @tag :plan_73_29_task_2
  test "plan-shaped descendants are assigned before current-plan filtering" do
    unknown = completed_plan_git_fixture(:post_summary_foreign)

    assert {:error, violations} = completed_plan_provenance(unknown.root, unknown.plan_path)

    assert Enum.any?(violations, fn violation ->
             violation =~ "descendant" and violation =~ "73-98" and
               violation =~ List.first(unknown.foreign_descendant_commits)
           end),
           "expected unknown plan-scope diagnostic, got: #{inspect(violations)}"

    existing = completed_plan_git_fixture(:post_summary_foreign_existing)
    assert {:ok, provenance} = completed_plan_provenance(existing.root, existing.plan_path)
    assert provenance.commits == existing.implementation_commits
    refute List.first(existing.foreign_descendant_commits) in provenance.commits

    assert Enum.any?(provenance.descendant_assignments, fn assignment ->
             assignment.scope == "73-98" and
               assignment.plan_path == existing.foreign_plan_relative
           end)

    ambiguous = completed_plan_git_fixture(:post_summary_foreign_ambiguous)

    assert {:error, ambiguous_violations} =
             completed_plan_provenance(ambiguous.root, ambiguous.plan_path)

    assert Enum.any?(ambiguous_violations, fn violation ->
             violation =~ "descendant" and violation =~ "73-98" and violation =~ "2 tracked PLAN"
           end)

    multiple = completed_plan_git_fixture(:post_summary_multiple)
    assert {:ok, provenance} = completed_plan_provenance(multiple.root, multiple.plan_path)
    assert provenance.commits == multiple.implementation_commits ++ multiple.descendant_commits

    assert {:ok, real_identity} = validated_governance_identity(File.cwd!())
    plan_27 = Enum.find(real_identity.plan_paths, &String.ends_with?(&1, "/73-27-PLAN.md"))
    assert {:ok, real_provenance} = completed_plan_provenance(real_identity.root, plan_27)
    assert is_list(real_provenance.descendant_assignments)
  end

  @tag :plan_73_15_task_2
  test "review endpoint must descend from the unique summary boundary" do
    fixture = completed_plan_git_fixture(:divergent_endpoint)

    assert {:error, violations} = completed_plan_provenance(fixture.root, fixture.plan_path)
    assert Enum.any?(violations, &String.contains?(&1, "review endpoint"))
  end

  @tag :plan_73_25_task_2
  test "completion boundary changes remain outside task equality but reach approval classification" do
    fixture = completed_plan_git_fixture(:boundary_protected)

    assert {:ok, provenance} = completed_plan_provenance(fixture.root, fixture.plan_path)
    assert provenance.commits == fixture.implementation_commits
    assert provenance.summary_commits == fixture.implementation_commits
    refute fixture.completion_commit in provenance.commits

    boundary_changes = Map.get(provenance, :boundary_changes)
    assert is_list(boundary_changes)

    assert Enum.any?(
             boundary_changes,
             &(&1.path == "lib/relyra/security/signature.ex" and &1.before != &1.after)
           )

    identity = %{root: fixture.root, milestone_version: "v1.11", current_phase: "73"}
    violations = repository_plan_violations([fixture.plan_path], %{}, identity)

    assert Enum.any?(violations, &(&1 =~ "security_posture" and &1 =~ "checkpoint")),
           "expected boundary security posture approval violation, got: #{inspect(violations)}"
  end

  @tag :plan_73_25_task_2
  test "reviewed merge commits reject explicitly before changed paths are reduced" do
    fixture = completed_plan_git_fixture(:merge_commit)

    assert {:error, violations} = completed_plan_provenance(fixture.root, fixture.plan_path)

    assert Enum.any?(violations, fn violation ->
             violation =~ "merge commit" and violation =~ fixture.merge_commit
           end),
           "expected merge diagnostic with full OID, got: #{inspect(violations)}"
  end

  @tag :plan_73_23_task_1
  @tag :plan_73_32_task_1
  test "active v1.11 plans declare scope and stop before every risky mutation" do
    violations =
      case validated_governance_identity(File.cwd!()) do
        {:ok, identity} -> repository_plan_violations(identity.plan_paths, %{}, identity)
        {:error, identity_violations} -> identity_violations
      end

    assert violations == [],
           "Active milestone plans violate approval policy:\n" <>
             Enum.map_join(violations, "\n", &"  - #{&1}")

    owners = Relyra.Phase73Reconciliation.acceptance_task_ids!(File.cwd!())
    assert length(owners) == 68
    assert List.last(owners) == "73-32-02"
  end

  @tag :plan_73_24_task_1
  test "current review findings are registered open before repair evidence" do
    phase_dir = ".planning/phases/73-twin-contract-and-baseline"
    security = File.read!(Path.join(phase_dir, "73-SECURITY.md"))
    validation = File.read!(Path.join(phase_dir, "73-VALIDATION.md"))

    assert (security =~ "status: issues_found" and security =~ "threats_open: 7") or
             (security =~ "status: verified" and security =~ "threats_open: 0")

    assert security =~ "50 threats, 42 closed, 8 open"
    assert security =~ ~r/^\| T-73-12 \|.*\| medium \|.*\| open/m

    for {threat, finding, severity} <- [
          {"T-73-98", "CR-01", "high"},
          {"T-73-99", "CR-02", "high"},
          {"T-73-100", "CR-03", "high"},
          {"T-73-101", "CR-04", "high"},
          {"T-73-102", "CR-05", "high"},
          {"T-73-103", "CR-06", "high"},
          {"T-73-104", "CR-07", "high"}
        ] do
      open_history =
        security
        |> String.split("## Plan 73-30 — Current Proof Staging", parts: 2)
        |> hd()

      rows = Regex.scan(~r/^\| #{threat} \|.*$/m, open_history) |> List.flatten()
      assert [row] = rows, "expected one unique #{threat} row, got: #{inspect(rows)}"
      assert row =~ "| #{severity} |"
      assert row =~ finding
      assert row =~ "| open"
    end

    security_correction = "## Post-Review Correction — 2026-09-24"

    validation_correction =
      "## Validation Audit 2026-09-24 — Current-Review Correction"

    assert {:ok, _security_offset} = byte_offset(security, security_correction)
    assert {:ok, _validation_offset} = byte_offset(validation, validation_correction)

    assert security =~ "50 threats, 42 closed, 8 open"
    assert security =~ "Seven high-threshold blockers"

    assert (validation =~ "status: gaps_found" and
              validation =~ "nyquist_compliant: false") or
             (validation =~ "status: validated" and
                validation =~ "nyquist_compliant: true")

    if validation =~ "PHASE73_FINAL_RECONCILIATION" do
      assert validation =~ ~r/^\| EVID-02 \|.*\| green/m
      assert validation =~ ~r/^\| GOV-01 \|.*\| green/m
      assert validation =~ ~r/^\| GOV-02 \|.*\| green/m
    else
      assert validation =~ ~r/^\| EVID-02 \|.*\| blocked/m
      assert validation =~ ~r/^\| GOV-01 \|.*\| blocked/m
      assert validation =~ ~r/^\| GOV-02 \|.*\| blocked/m
    end

    correction_section =
      validation
      |> String.split(validation_correction, parts: 2)
      |> List.last()

    assert correction_section =~ "CR-01 through CR-07"

    assert {:ok, _offset} = byte_offset(security, "## Plan 73-26 Current Proof Staging")
    assert {:ok, _offset} = byte_offset(validation, "Plan 73-26 Current Proof Staging")
  end

  @tag :plan_73_26_task_1
  test "one canonical source-bound proof stages identically before disposition changes" do
    reconciliation = Relyra.Phase73Reconciliation

    assert Code.ensure_loaded?(reconciliation)

    assert function_exported?(reconciliation, :validate_documents!, 4),
           "Phase 73 reconciliation validator must exist before proof staging"

    root = File.cwd!()
    proof = apply(reconciliation, :fixture_proof!, [root])
    {security, validation} = apply(reconciliation, :fixture_documents!, [proof, :staged])

    assert :ok = apply(reconciliation, :validate_documents!, [security, validation, proof, root])

    mutations = [
      {"stale source digest",
       Map.put(proof, "source_digest", "sha256:" <> String.duplicate("0", 64))},
      {"missing proof field", Map.delete(proof, "focused")},
      {"fabricated result", put_in(proof, ["evidence_runs", Access.at(0), "exit_code"], 1)},
      {"fabricated count",
       put_in(proof, ["focused", Access.at(0), "summaries", Access.at(0), "tests"], 0)},
      {"fabricated output digest",
       put_in(proof, ["focused", Access.at(0), "output_sha256"], "forged")},
      {"zero-test security constituent",
       put_in(proof, ["security_constituents", Access.at(0), "summary", "tests"], 0)},
      {"missing owner", update_in(proof, ["acceptance_task_ids"], &tl/1)},
      {"duplicate owner",
       update_in(proof, ["acceptance_task_ids"], fn ids -> ids ++ [hd(ids)] end)},
      {"extra owner", update_in(proof, ["acceptance_task_ids"], &(&1 ++ ["73-99-99"]))}
    ]

    for {name, corrupt} <- mutations do
      {corrupt_security, corrupt_validation} =
        apply(reconciliation, :fixture_documents!, [corrupt, :staged])

      error =
        assert_raise ArgumentError, fn ->
          apply(reconciliation, :validate_documents!, [
            corrupt_security,
            corrupt_validation,
            corrupt,
            root
          ])
        end

      assert Exception.message(error) != "", "#{name} must fail with a diagnostic"
    end

    assert_raise ArgumentError, ~r/identical canonical proof/, fn ->
      apply(reconciliation, :validate_documents!, [
        String.replace(security, proof["proof_set_id"], "phase73-forged", global: false),
        validation,
        proof,
        root
      ])
    end

    assert_raise ArgumentError, ~r/open.*staged.*final|chronology/s, fn ->
      reordered =
        String.replace(
          security,
          "Post-review correction for the 2026-09-11T19:23:38Z review",
          "missing open chronology marker"
        )

      apply(reconciliation, :validate_documents!, [reordered, validation, proof, root])
    end
  end

  @tag :plan_73_26_task_2
  test "final reconciliation requires exact closures owners and positive security constituents" do
    reconciliation = Relyra.Phase73Reconciliation

    assert Code.ensure_loaded?(reconciliation)

    assert function_exported?(reconciliation, :validate_repository!, 1),
           "Phase 73 repository reconciliation must exist before final status"

    root = File.cwd!()
    proof = apply(reconciliation, :fixture_proof!, [root])
    {security, validation} = apply(reconciliation, :fixture_documents!, [proof, :final])

    assert :ok = apply(reconciliation, :validate_documents!, [security, validation, proof, root])
    assert length(proof["acceptance_task_ids"]) == 68
    assert List.last(proof["acceptance_task_ids"]) == "73-32-02"

    [first_owner | _] = proof["acceptance_task_ids"]

    for invalid <- [
          String.replace(validation, "| #{first_owner} |", "| 73-99-99 |", global: false),
          String.replace(validation, "| #{first_owner} |", "", global: false),
          String.replace(validation, "nyquist_compliant: true", "nyquist_compliant: false",
            global: false
          ),
          String.replace(validation, "PHASE73_FINAL_RECONCILIATION", "", global: false)
        ] do
      assert_raise ArgumentError, fn ->
        apply(reconciliation, :validate_documents!, [security, invalid, proof, root])
      end
    end

    for invalid <- [
          String.replace(security, "threats_open: 0", "threats_open: 1", global: false),
          String.replace(
            security,
            "50 threats: 49 closed and 1 open",
            "50 threats: 48 closed and 2 open",
            global: false
          ),
          String.replace(security, "T-73-98_CLOSED", "", global: false),
          String.replace(security, "PHASE73_FINAL_RECONCILIATION", "", global: false)
        ] do
      assert_raise ArgumentError, fn ->
        apply(reconciliation, :validate_documents!, [invalid, validation, proof, root])
      end
    end
  end

  @tag :plan_73_31_task_1
  test "current tracked plan inventory builds one validated 32-plan proof" do
    reconciliation = Relyra.Phase73Reconciliation
    root = File.cwd!()

    assert {tracked_plans, 0} =
             System.cmd("git", [
               "ls-files",
               "--",
               ".planning/phases/73-twin-contract-and-baseline/73-*-PLAN.md"
             ])

    assert length(String.split(tracked_plans, "\n", trim: true)) == 32
    proof = reconciliation.fixture_proof!(root)
    {security, validation} = reconciliation.fixture_documents!(proof, :staged)

    assert length(proof["acceptance_task_ids"]) == 68
    assert List.last(proof["acceptance_task_ids"]) == "73-32-02"

    assert Enum.any?(
             proof["governed_sources"],
             &(&1["path"] == ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md")
           )

    assert :ok = reconciliation.validate_documents!(security, validation, proof, root)

    for owners <- [tl(proof["acceptance_task_ids"]), proof["acceptance_task_ids"] ++ ["73-99-99"]] do
      corrupt = Map.put(proof, "acceptance_task_ids", owners)
      {bad_security, bad_validation} = reconciliation.fixture_documents!(corrupt, :staged)

      assert_raise ArgumentError, fn ->
        reconciliation.validate_documents!(bad_security, bad_validation, corrupt, root)
      end
    end
  end

  @tag :plan_73_31_task_2
  test "new reconciliation owners are real tests in the mandatory fresh-process lane" do
    source = File.read!("test/governance/milestone_scope_test.exs")
    reconciliation_source = File.read!("test/support/phase_73_reconciliation.ex")

    finding_owners = [
      {"CR-01", "test/governance/phase_73_reconciliation_test.exs", "plan_73_27_task_1"},
      {"CR-01", "test/governance/phase_73_reconciliation_test.exs", "plan_73_27_task_2"},
      {"CR-02", "test/governance/phase_73_reconciliation_test.exs", "plan_73_27_task_1"},
      {"CR-03", "test/adoption/evidence_contract_test.exs", "plan_73_28_task_1"},
      {"CR-04", "test/governance/phase_73_reconciliation_test.exs", "plan_73_27_task_2"},
      {"CR-05", "test/adoption/evidence_contract_test.exs", "plan_73_28_task_2"},
      {"CR-05", "test/governance/phase_73_reconciliation_test.exs", "plan_73_30_task_1"},
      {"CR-06", "test/governance/milestone_scope_test.exs", "plan_73_29_task_1"},
      {"CR-07", "test/governance/milestone_scope_test.exs", "plan_73_29_task_2"}
    ]

    owner_sources = %{
      "test/adoption/evidence_contract_test.exs" =>
        File.read!("test/adoption/evidence_contract_test.exs"),
      "test/governance/milestone_scope_test.exs" => source,
      "test/governance/phase_73_reconciliation_test.exs" =>
        File.read!("test/governance/phase_73_reconciliation_test.exs")
    }

    for {finding, owner, tag} <- finding_owners do
      owner_source = Map.fetch!(owner_sources, owner)
      assert owner_source =~ "@tag :#{tag}", "#{finding} must retain owner #{tag}"

      assert reconciliation_source =~
               "mix test #{owner} --only #{tag} --warnings-as-errors",
             "#{finding} focused owner #{tag} must remain in the current proof"
    end

    for tag <- ["plan_73_31_task_1", "plan_73_31_task_2"] do
      assert source =~ "@tag :#{tag}"
      assert length(Regex.scan(~r/@tag :#{tag}\s+test\b/s, source)) == 1
    end

    assert [step] = mix_alias_steps("ci.evidence")
    assert step =~ "cmd mix test"
    assert step =~ "test/governance/milestone_scope_test.exs"
    assert step =~ "--only evidence_contract"
    assert step =~ "--warnings-as-errors"

    workflow = File.read!(".github/workflows/security-gates.yml")
    assert workflow =~ ~r/jobs:\s*\n  security:/
    assert workflow =~ ~r/- name: Evidence contract\n\s+run:.*mix ci\.evidence/
    assert :ok = AdoptionEvidence.validate_repository!(AdoptionEvidence.entries(), File.cwd!())
  end

  @tag :plan_73_32_task_2
  test "both current reconciliation owners are selected by mandatory fresh-process evidence" do
    source = File.read!("test/governance/milestone_scope_test.exs")
    owners = ["plan_73_32_task_1", "plan_73_32_task_2"]

    for owner <- owners do
      assert source =~ "@tag :#{owner}"
      assert length(Regex.scan(~r/@tag :#{owner}\s+test\b/s, source)) == 1
    end

    assert [step] = mix_alias_steps("ci.evidence")
    assert step =~ ~r/^cmd mix test\b/
    assert step =~ "test/governance/milestone_scope_test.exs"
    assert step =~ "--only evidence_contract"
    assert step =~ "--warnings-as-errors"

    workflow = File.read!(".github/workflows/security-gates.yml")
    assert workflow =~ ~r/jobs:\s*\n  security:/
    assert workflow =~ ~r/- name: Evidence contract\n\s+run:.*mix ci\.evidence/
  end

  @tag :plan_73_25_task_1
  test "task regions reject every unconsumed or empty executable shape" do
    clean = no_risk_plan_fixture()

    controls = [
      {String.replace(clean, ~s(<task type="auto">), ~s(<task type=auto>), global: false),
       "task opening tag uses unsupported syntax"},
      {String.replace(clean, ~s(<task type="auto">), "<task>", global: false),
       "task type must appear exactly once"},
      {String.replace(clean, "</task>", "", global: false), "task opening tag is unterminated"},
      {Regex.replace(~r/<tasks>.*?<\/tasks>/s, clean, "<tasks>\n</tasks>"),
       "tasks region must contain at least one task"},
      {String.replace(
         clean,
         "<action>Extend deterministic policy tests only.</action>",
         "<action>Extend deterministic policy tests only.</action>\n<task type=\"auto\">nested</task>",
         global: false
       ), "nested task"},
      {String.replace(clean, "</tasks>", "</task>\n</tasks>", global: false),
       "unmatched task close"}
    ]

    for {invalid, diagnostic} <- controls do
      violations = plan_scope_violations(invalid)

      assert Enum.any?(violations, &String.contains?(&1, diagnostic)),
             "expected #{inspect(diagnostic)}, got: #{inspect(violations)}"
    end
  end

  @tag :plan_73_25_task_1
  test "acceptance criteria are balanced singular and owned by one implementation task" do
    clean = no_risk_plan_fixture()
    [acceptance] = Regex.run(~r/<acceptance_criteria>.*?<\/acceptance_criteria>/s, clean)

    controls = [
      {clean
       |> String.replace(acceptance, "", global: false)
       |> String.replace("</task>", "</task>\n#{acceptance}", global: false),
       "acceptance_criteria must be wholly owned"},
      {String.replace(clean, acceptance, acceptance <> "\n" <> acceptance, global: false),
       "acceptance_criteria must appear exactly once"},
      {String.replace(
         clean,
         acceptance,
         "<acceptance_criteria>#{acceptance}</acceptance_criteria>",
         global: false
       ), "nested acceptance_criteria"},
      {String.replace(clean, "</acceptance_criteria>", "", global: false),
       "acceptance_criteria has an unmatched open boundary"},
      {String.replace(clean, "<acceptance_criteria>", "", global: false),
       "acceptance_criteria has an unmatched close boundary"},
      {String.replace(clean, acceptance, "<acceptance_criteria>   </acceptance_criteria>",
         global: false
       ), "acceptance_criteria must be non-empty"}
    ]

    for {invalid, diagnostic} <- controls do
      violations = plan_scope_violations(invalid)

      assert Enum.any?(violations, &String.contains?(&1, diagnostic)),
             "expected #{inspect(diagnostic)}, got: #{inspect(violations)}"
    end
  end

  @tag :plan_73_25_task_1
  test "closed task grammar accepts tracked plans and ignores task prose outside its region" do
    assert plan_scope_violations(no_risk_plan_fixture() <> "\nProse names `<task>` only.\n") == []

    assert {:ok, identity} = validated_governance_identity(File.cwd!())

    violations =
      Enum.flat_map(identity.plan_paths, fn path ->
        repository_plan_scope_violations(identity, path, File.read!(path), [])
      end)

    assert violations == []
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
    %{plan: clean, root: root} = remote_plan_fixture()
    assert plan_scope_violations(clean, [], root) == []

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
      assert_plan_violation(incomplete, "remote_github", diagnostic, root)
    end

    without_resume = Regex.replace(~r/\s*<resume-signal>.*?<\/resume-signal>/s, clean, "")
    assert_plan_violation(without_resume, "remote_github", "resume signal", root)
  end

  test "remote batch rejects placeholders and mismatched reversible targets" do
    %{plan: clean, root: root} = remote_plan_fixture()
    assert plan_scope_violations(clean, [], root) == []

    for placeholder <- ["", "   ", "TBD", "placeholder", "exact commands omitted"] do
      invalid = replace_remote_scalar(clean, "preflight_command", placeholder)
      assert_plan_violation(invalid, "remote_github", "preflight_command", root)
    end

    mismatched_branch =
      replace_remote_scalar(
        clean,
        "read_back_command",
        "gh api repos/szTheory/relyra/branches/develop/protection --jq '.required_status_checks.contexts == [\"security (27, 1.19.5)\",\"security (28, 1.19.5)\",\"fleet-proxy-e2e\"]'"
      )

    assert_plan_violation(mismatched_branch, "remote_github", "read_back_command target", root)

    mismatched_checks =
      replace_remote_scalar(
        clean,
        "affected_checks",
        "security (27, 1.19.5), security (28, 1.19.5)"
      )

    assert_plan_violation(mismatched_checks, "remote_github", "affected_checks", root)

    wrong_rollback =
      String.replace(
        clean,
        "repos/szTheory/relyra/branches/main/protection --input captured-current.json",
        "repos/szTheory/relyra/branches/develop/protection --input captured-current.json",
        global: false
      )

    assert_plan_violation(wrong_rollback, "remote_github", "rollback_commands target", root)
  end

  @tag :plan_73_11_task_1
  test "remote batch fields are singular closed and unreduced" do
    %{plan: clean, root: root} = remote_plan_fixture()
    assert plan_scope_violations(clean, [], root) == []

    controls = [
      {String.replace(clean, "current_state:", "current_state: duplicate\ncurrent_state:",
         global: false
       ), "current_state"},
      {String.replace(
         clean,
         "mutation_commands:",
         "mutation_commands:\n  - first\nmutation_commands:",
         global: false
       ), "mutation_commands"},
      {String.replace(
         clean,
         "  - gh api -X PUT",
         "  - duplicate\n  - duplicate\n  - gh api -X PUT",
         global: false
       ), "mutation_commands"},
      {String.replace(clean, "affected_checks:", "unknown_field: surprise\naffected_checks:",
         global: false
       ), "unparsed"},
      {String.replace(clean, "  - gh api -X PUT", "mutation_commands: gh api -X PUT",
         global: false
       ), "mutation_commands"}
    ]

    for {invalid, diagnostic} <- controls do
      assert_plan_violation(invalid, "remote_github", diagnostic, root)
    end
  end

  @tag :plan_73_11_task_1
  test "payload inputs are tracked non-symlink files bound to declared states" do
    %{plan: clean, root: root} = remote_plan_fixture()
    assert plan_scope_violations(clean, [], root) == []

    File.write!(Path.join(root, "untracked.json"), branch_protection_json(true, desired_checks()))
    File.mkdir_p!(Path.join(root, "payload-dir"))
    File.ln_s!("desired-protection.json", Path.join(root, "desired-link.json"))
    File.mkdir_p!(Path.join(root, "linked"))
    File.ln_s!("../desired-protection.json", Path.join(root, "linked/payload.json"))
    File.ln_s!("linked", Path.join(root, "intermediate-link"))

    controls = [
      {"missing.json", "missing.json"},
      {"untracked.json", "untracked.json"},
      {"../outside.json", "../outside.json"},
      {"payload-dir", "payload-dir"},
      {"desired-link.json", "desired-link.json"},
      {"intermediate-link/payload.json", "intermediate-link/payload.json"}
    ]

    for {path, diagnostic} <- controls do
      invalid = String.replace(clean, "desired-protection.json", path, global: false)
      assert_plan_violation(invalid, "remote_github", diagnostic, root)
    end

    payload_controls = [
      {"{malformed", "malformed"},
      {~s({"required_status_checks":{"strict":true,"strict":false,"contexts":[]}}), "duplicate"},
      {branch_protection_json(true, desired_checks(), %{"unexpected" => true}), "unsupported"},
      {branch_protection_json(false, desired_checks()), "desired_state"},
      {branch_protection_json(true, current_checks()), "desired_state"}
    ]

    for {contents, diagnostic} <- payload_controls do
      File.write!(Path.join(root, "desired-protection.json"), contents)
      git_fixture!(root, ["add", "desired-protection.json"])
      assert_plan_violation(clean, "remote_github", diagnostic, root)
    end
  end

  @tag :plan_73_11_task_2
  test "script-backed mutations remain rejected across repository controls" do
    %{plan: clean, root: root} = remote_plan_fixture(:script)
    assert_plan_violation(clean, "remote_github", "mutation_result_source", root)

    controls = [
      {:untracked, "untracked-script.sh"},
      {:symlink, "script-link.sh"},
      {:directory, "script-dir"},
      {:non_executable, "executable"},
      {:changed_after_index, "indexed"}
    ]

    for {variant, diagnostic} <- controls do
      %{plan: invalid, root: invalid_root} = remote_script_control_fixture(variant)
      violations = plan_scope_violations(invalid, [], invalid_root)

      assert Enum.any?(
               violations,
               &(&1 =~ "remote_github" and &1 =~ "mutation_result_source")
             ),
             "expected script rejection for #{diagnostic}, got: #{inspect(violations)}"
    end
  end

  @tag :plan_73_11_task_2
  test "real branch protection script identity is rejected without mutation" do
    %{plan: plan, root: root} = remote_plan_fixture(:script)

    assert_plan_violation(plan, "remote_github", "mutation_result_source", root)
    refute File.exists?(Path.join(root, "remote-mutation-ran"))
  end

  @tag :plan_73_13_task_1
  test "remote authorization rejects every changed branch protection invariant by field" do
    %{plan: clean, root: root} = remote_plan_fixture()
    assert plan_scope_violations(clean, [], root) == []

    controls = [
      {"enforce_admins", false},
      {"required_pull_request_reviews", %{}},
      {"restrictions", %{"users" => []}},
      {"allow_force_pushes", true},
      {"allow_deletions", true},
      {"block_creations", true},
      {"required_conversation_resolution", true},
      {"lock_branch", true},
      {"allow_fork_syncing", true}
    ]

    for {field, changed_value} <- controls do
      write_branch_protection_control!(root, field, changed_value)
      assert_plan_violation(clean, "remote_github", field, root)
    end
  end

  @tag :plan_73_13_task_1
  test "complete branch protection state rejects wrong field containers and accepts clean states" do
    %{plan: clean, root: root} = remote_plan_fixture()
    assert plan_scope_violations(clean, [], root) == []

    for {field, changed_value} <- [
          {"enforce_admins", "true"},
          {"required_pull_request_reviews", []},
          {"restrictions", false},
          {"allow_force_pushes", %{}},
          {"allow_deletions", nil},
          {"block_creations", 0},
          {"required_conversation_resolution", "false"},
          {"lock_branch", []},
          {"allow_fork_syncing", nil}
        ] do
      write_branch_protection_control!(root, field, changed_value)
      assert_plan_violation(clean, "remote_github", field, root)
    end
  end

  @tag :plan_73_15_task_1
  @tag :plan_73_13_task_2
  test "script-shaped remote mutations are rejected without execution" do
    for behavior <- [:write, :credential, :network] do
      %{plan: plan, root: root, sentinel: sentinel} = remote_nonexecution_fixture(behavior)

      assert_plan_violation(plan, "remote_github", "mutation_result_source", root)
      refute File.exists?(sentinel)
    end
  end

  @tag :plan_73_15_task_1
  @tag :plan_73_13_task_2
  test "only declarative complete-state payload operations cross the mutation parser" do
    %{plan: api_plan, root: api_root} = remote_plan_fixture()
    assert plan_scope_violations(api_plan, [], api_root) == []

    %{plan: clean_script, root: clean_root} = remote_plan_fixture(:script)
    assert_plan_violation(clean_script, "remote_github", "mutation_result_source", clean_root)

    %{plan: changed_script, root: changed_root} =
      remote_script_control_fixture(:changed_after_index)

    assert_plan_violation(
      changed_script,
      "remote_github",
      "mutation_result_source",
      changed_root
    )

    exact_result_script =
      String.replace(
        clean_script,
        "mutation_result_source: predicted-protection.json",
        "mutation_result_source: desired-protection.json",
        global: false
      )

    assert_plan_violation(
      exact_result_script,
      "remote_github",
      "mutation_result_source",
      clean_root
    )
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
      case validated_governance_identity(File.cwd!()) do
        {:ok, identity} ->
          Enum.flat_map(identity.plan_paths, fn path ->
            path
            |> File.read!()
            |> requirement_membership_violations(ownership)
            |> Enum.map(&"#{path}: #{&1}")
          end)

        {:error, identity_violations} ->
          identity_violations
      end

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
      case validated_governance_identity(File.cwd!()) do
        {:ok, identity} -> Enum.flat_map(identity.active_phases, &automation_policy_violations/1)
        {:error, identity_violations} -> identity_violations
      end

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

  @tag :plan_73_08_task_1
  test "remote approval rejects appended commands outside the exact batch" do
    %{plan: clean, root: root} = remote_plan_fixture()
    assert plan_scope_violations(clean, [], root) == []

    mutation =
      "gh api -X PUT repos/szTheory/relyra/branches/main/protection --input desired-protection.json"

    controls = [
      {mutation, mutation <> " && gh api -X DELETE repos/szTheory/relyra", "mutation_commands"},
      {mutation, mutation <> "\ngh api repos/szTheory/relyra/branches/main/protection",
       "mutation_commands"},
      {mutation, mutation <> "; true", "mutation_commands"},
      {mutation, mutation <> " | tee result.txt", "mutation_commands"},
      {mutation, mutation <> " `whoami`", "mutation_commands"},
      {mutation, mutation <> " $(whoami)", "mutation_commands"},
      {mutation, mutation <> " extra", "mutation_commands"},
      {mutation,
       "gh api -X PUT repos/szTheory/other/branches/main/protection --input desired-protection.json",
       "mutation_commands"},
      {"gh api repos/szTheory/relyra/branches/main/protection",
       "gh api -X DELETE repos/szTheory/relyra/branches/main/protection", "preflight_command"},
      {"gh api repos/szTheory/relyra/branches/main/protection",
       "gh api repos/szTheory/relyra/branches/main/protection gh api repos/szTheory/relyra/branches/main/protection",
       "preflight_command"},
      {"gh api -X PUT repos/szTheory/relyra/branches/main/protection --input captured-current.json",
       "gh api -X POST repos/szTheory/relyra/branches/main/protection --input captured-current.json",
       "rollback_commands"},
      {"gh api repos/szTheory/relyra/branches/main/protection --jq '.required_status_checks.contexts == [\"security (27, 1.19.5)\",\"security (28, 1.19.5)\",\"fleet-proxy-e2e\"]'",
       "gh api repos/szTheory/relyra/branches/develop/protection --jq '.required_status_checks.contexts == [\"security (27, 1.19.5)\",\"security (28, 1.19.5)\",\"fleet-proxy-e2e\"]'",
       "read_back_command"}
    ]

    for {original, replacement, field} <- controls do
      invalid = String.replace(clean, original, replacement, global: false)
      violations = plan_scope_violations(invalid, [], root)

      assert Enum.any?(violations, &(&1 =~ "remote_github" and &1 =~ field)),
             "#{field} control was accepted: #{replacement}"
    end
  end

  @tag :plan_73_08_task_2
  test "baseline verification provenance must resolve to an existing repository path" do
    baseline = File.read!(@baseline_path)
    marker = "`.planning/STATE.md` Baseline Findings"

    controls = [
      "`.planning/no-such-evidence.md` Baseline Findings",
      "`.planning/phases/73-twin-contract-and-baseline` directory",
      "`test/../../etc/passwd` outside root",
      "`rg source says good` command-shaped prose"
    ]

    for replacement <- controls do
      invalid = String.replace(baseline, marker, replacement, global: false)
      assert_violation(invalid, "QUAL-73-001", "allowed reference")
    end

    unique = System.unique_integer([:positive])
    untracked_relative = ".planning/phases/73-twin-contract-and-baseline/untracked-#{unique}.md"
    symlink_relative = ".planning/phases/73-twin-contract-and-baseline/symlink-#{unique}.md"
    File.write!(untracked_relative, "not indexed")
    File.ln_s!("73-BASELINE.md", symlink_relative)

    on_exit(fn ->
      File.rm(untracked_relative)
      File.rm(symlink_relative)
    end)

    for relative <- [untracked_relative, symlink_relative] do
      invalid = String.replace(baseline, marker, "`#{relative}` provenance", global: false)
      assert_violation(invalid, "QUAL-73-001", "allowed reference")
    end

    tracked =
      String.replace(
        baseline,
        marker,
        "`test/governance/milestone_scope_test.exs` policy",
        global: false
      )

    assert baseline_violations(tracked) == []

    executable =
      String.replace(baseline, marker, "`mix ci.evidence` owner", global: false)

    assert baseline_violations(executable) == []

    repo = Path.join(System.tmp_dir!(), "relyra-provenance-repo-#{unique}")
    external = Path.join(System.tmp_dir!(), "relyra-provenance-external-#{unique}")
    File.mkdir_p!(Path.join(repo, "test"))
    File.mkdir_p!(external)
    File.write!(Path.join(repo, "test/proof.md"), "indexed source")
    File.write!(Path.join(external, "proof.md"), "external source")
    assert {_, 0} = System.cmd("git", ["init", "--quiet", repo])
    assert {_, 0} = System.cmd("git", ["-C", repo, "add", "test/proof.md"])
    File.rm_rf!(Path.join(repo, "test"))
    File.ln_s!(external, Path.join(repo, "test"))

    on_exit(fn ->
      File.rm_rf!(repo)
      File.rm_rf!(external)
    end)

    assert {"test/proof.md\n", 0} =
             System.cmd("git", ["-C", repo, "ls-files", "--error-unmatch", "--", "test/proof.md"])

    intermediate_symlink =
      String.replace(baseline, marker, "`test/proof.md` indexed source", global: false)

    assert Enum.any?(
             baseline_violations(intermediate_symlink, repo),
             &(&1 =~ "QUAL-73-001" and &1 =~ "allowed reference")
           )
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
        preflight_command: gh api repos/szTheory/relyra/branches/main/protection
        rollback_commands:
          - gh api -X PUT repos/szTheory/relyra/branches/main/protection --input captured-current.json
        read_back_command: gh api repos/szTheory/relyra/branches/main/protection --jq '.required_status_checks.contexts == ["security (27, 1.19.5)","security (28, 1.19.5)","fleet-proxy-e2e"]'
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

  defp assert_plan_violation(plan, identity, detail, root \\ File.cwd!()) do
    violations = plan_scope_violations(plan, [], root)

    assert Enum.any?(violations, &(&1 =~ identity and &1 =~ detail)),
           "expected plan violation containing #{inspect(identity)} and #{inspect(detail)}, got: #{inspect(violations)}"
  end

  defp remote_plan_fixture(mutation_kind \\ :api) do
    root =
      Path.join(System.tmp_dir!(), "relyra-remote-batch-#{System.unique_integer([:positive])}")

    File.mkdir_p!(Path.join(root, "scripts"))
    on_exit(fn -> File.rm_rf!(root) end)

    File.write!(
      Path.join(root, "desired-protection.json"),
      branch_protection_json(true, desired_checks())
    )

    File.write!(
      Path.join(root, "captured-current.json"),
      branch_protection_json(true, current_checks())
    )

    File.write!(
      Path.join(root, "predicted-protection.json"),
      branch_protection_json(true, desired_checks())
    )

    File.cp!(
      "scripts/setup_branch_protection.sh",
      Path.join(root, "scripts/setup_branch_protection.sh")
    )

    File.chmod!(Path.join(root, "scripts/setup_branch_protection.sh"), 0o755)

    git_fixture!(root, ["init", "-q"])

    git_fixture!(root, [
      "add",
      "desired-protection.json",
      "captured-current.json",
      "predicted-protection.json",
      "scripts/setup_branch_protection.sh"
    ])

    plan =
      risky_plan_fixture("remote_github")
      |> String.replace(
        "current_state: repository=szTheory/relyra; branch=main; checks=",
        "current_state: repository=szTheory/relyra; branch=main; strict=true; checks=",
        global: false
      )
      |> String.replace(
        "desired_state: repository=szTheory/relyra; branch=main; checks=",
        "desired_state: repository=szTheory/relyra; branch=main; strict=true; checks=",
        global: false
      )

    plan =
      case mutation_kind do
        :api ->
          String.replace(
            plan,
            "GITHUB_REPOSITORY=szTheory/relyra ./scripts/setup_branch_protection.sh main",
            "gh api -X PUT repos/szTheory/relyra/branches/main/protection --input desired-protection.json",
            global: false
          )

        :script ->
          String.replace(
            plan,
            "affected_checks:",
            "mutation_result_source: predicted-protection.json\naffected_checks:",
            global: false
          )
      end

    %{root: root, plan: plan}
  end

  defp current_checks,
    do: ["security (27, 1.19.5)", "security (28, 1.19.5)"]

  defp desired_checks,
    do: current_checks() ++ ["fleet-proxy-e2e"]

  defp branch_protection_json(strict, contexts, extras \\ %{}) do
    %{
      "required_status_checks" => %{"strict" => strict, "contexts" => contexts},
      "enforce_admins" => true,
      "required_pull_request_reviews" => nil,
      "restrictions" => nil,
      "allow_force_pushes" => false,
      "allow_deletions" => false,
      "block_creations" => false,
      "required_conversation_resolution" => false,
      "lock_branch" => false,
      "allow_fork_syncing" => false
    }
    |> Map.merge(extras)
    |> Jason.encode!()
  end

  defp write_branch_protection_control!(root, field, value) do
    path = Path.join(root, "desired-protection.json")
    decoded = true |> branch_protection_json(desired_checks()) |> Jason.decode!()
    File.write!(path, decoded |> Map.put(field, value) |> Jason.encode!())
    git_fixture!(root, ["add", "desired-protection.json"])
  end

  defp remote_nonexecution_fixture(behavior) do
    %{plan: plan, root: root} = remote_plan_fixture(:script)
    sentinel = Path.join(root, "sentinel-#{behavior}")
    script = Path.join(root, "scripts/setup_branch_protection.sh")

    attempted_action =
      case behavior do
        :write -> "touch #{sentinel}"
        :credential -> "[ -n \"$GITHUB_TOKEN\" ] && touch #{sentinel}; touch #{sentinel}"
        :network -> "curl https://example.invalid >/dev/null 2>&1; touch #{sentinel}"
      end

    File.write!(script, "#!/bin/sh\n#{attempted_action}\n")
    File.chmod!(script, 0o755)
    git_fixture!(root, ["add", "scripts/setup_branch_protection.sh"])
    %{plan: plan, root: root, sentinel: sentinel}
  end

  defp remote_script_control_fixture(variant) do
    %{plan: plan, root: root} = remote_plan_fixture(:script)
    script = Path.join(root, "scripts/setup_branch_protection.sh")
    valid = "#!/bin/sh\nexit 0\n"

    {plan, tracked_paths} =
      case variant do
        :untracked ->
          relative = "scripts/untracked-script.sh"
          File.write!(Path.join(root, relative), valid)
          File.chmod!(Path.join(root, relative), 0o755)
          {String.replace(plan, "scripts/setup_branch_protection.sh", relative), []}

        :symlink ->
          relative = "scripts/script-link.sh"
          File.ln_s!("setup_branch_protection.sh", Path.join(root, relative))
          git_fixture!(root, ["add", relative])
          {String.replace(plan, "scripts/setup_branch_protection.sh", relative), []}

        :directory ->
          relative = "scripts/script-dir"
          File.mkdir_p!(Path.join(root, relative))
          {String.replace(plan, "scripts/setup_branch_protection.sh", relative), []}

        :non_executable ->
          File.chmod!(script, 0o644)
          {plan, ["scripts/setup_branch_protection.sh"]}

        :changed_after_index ->
          File.write!(script, valid)
          git_fixture!(root, ["add", "scripts/setup_branch_protection.sh"])
          File.write!(script, valid <> "\necho changed\n")
          {plan, []}
      end

    if tracked_paths != [] do
      File.chmod!(script, if(variant == :non_executable, do: 0o644, else: 0o755))
      git_fixture!(root, ["add" | tracked_paths])
    end

    %{plan: plan, root: root}
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

  defp governance_repository_fixture do
    root =
      Path.join(System.tmp_dir!(), "relyra-governance-#{System.unique_integer([:positive])}")

    phase_dir = Path.join(root, ".planning/phases/73-twin-contract-and-baseline")
    File.mkdir_p!(phase_dir)
    on_exit(fn -> File.rm_rf!(root) end)

    for file <- ~w(PROJECT.md ROADMAP.md REQUIREMENTS.md STATE.md) do
      File.cp!(Path.join(".planning", file), Path.join(root, ".planning/#{file}"))
    end

    File.cp!(
      ".planning/phases/73-twin-contract-and-baseline/73-10-PLAN.md",
      Path.join(phase_dir, "73-10-PLAN.md")
    )

    root
  end

  defp completed_plan_git_fixture(variant \\ :clean) do
    root = Path.join(System.tmp_dir!(), "relyra-plan-git-#{System.unique_integer([:positive])}")
    phase_dir = Path.join(root, ".planning/phases/73-twin-contract-and-baseline")
    plan_path = Path.join(phase_dir, "73-99-PLAN.md")
    summary_path = Path.join(phase_dir, "73-99-SUMMARY.md")
    File.mkdir_p!(Path.join(root, "lib/relyra/security"))
    File.mkdir_p!(phase_dir)
    on_exit(fn -> File.rm_rf!(root) end)

    foreign_plan_relative = ".planning/phases/73-twin-contract-and-baseline/73-98-PLAN.md"

    if variant in [:post_summary_foreign_existing, :post_summary_foreign_ambiguous] do
      File.write!(Path.join(root, foreign_plan_relative), no_risk_plan_fixture())
    end

    if variant == :post_summary_foreign_ambiguous do
      second_foreign_plan = Path.join(root, ".planning/phases/73-secondary/73-98-PLAN.md")
      File.mkdir_p!(Path.dirname(second_foreign_plan))
      File.write!(second_foreign_plan, no_risk_plan_fixture())
    end

    git_fixture!(root, ["init", "-q"])
    git_fixture!(root, ["config", "user.email", "governance@example.invalid"])
    git_fixture!(root, ["config", "user.name", "Governance Fixture"])
    File.write!(plan_path, no_risk_plan_fixture())
    File.write!(Path.join(root, "README.md"), "baseline\n")

    File.write!(
      Path.join(root, "lib/relyra.ex"),
      "def start_login(connection, relay_context, opts \\\\ [])\n"
    )

    File.write!(
      Path.join(root, "lib/relyra/security/signature.ex"),
      "defp do_verify(parsed, connection, certs, opts)\n"
    )

    initial_commit = fixture_commit!(root, ["."], "chore: initialize provenance fixture")

    implementation_commits =
      if variant == :empty_implementation do
        []
      else
        File.write!(Path.join(root, "README.md"), "baseline\nharmless task\n")
        harmless = fixture_commit!(root, ["README.md"], "test(73-99): harmless task")

        File.write!(
          Path.join(root, "lib/relyra.ex"),
          "def start_login(connection, relay_context, policy, opts \\\\ [])\n"
        )

        scope = if variant == :foreign_scope, do: "73-98", else: "73-99"
        risky = fixture_commit!(root, ["lib/relyra.ex"], "fix(#{scope}): risky task")
        [harmless, risky]
      end

    File.write!(Path.join(root, "foreign.txt"), "foreign\n")
    foreign = fixture_commit!(root, ["foreign.txt"], "chore(other): unrelated task")

    {implementation_commits, merge_commit} =
      if variant == :merge_commit do
        main_branch = root |> git_fixture!(["branch", "--show-current"]) |> String.trim()
        git_fixture!(root, ["checkout", "-q", "-b", "merge-side"])

        File.write!(
          Path.join(root, "lib/relyra/security/signature.ex"),
          "defp do_verify(parsed, connection, certs, policy, opts)\n"
        )

        fixture_commit!(
          root,
          ["lib/relyra/security/signature.ex"],
          "test(other): side branch change"
        )

        git_fixture!(root, ["checkout", "-q", main_branch])
        File.write!(Path.join(root, "mainline.txt"), "mainline\n")
        fixture_commit!(root, ["mainline.txt"], "test(other): mainline change")

        git_fixture!(root, [
          "merge",
          "-q",
          "--no-ff",
          "merge-side",
          "-m",
          "fix(73-99): merge implementation"
        ])

        merge = root |> git_fixture!(["rev-parse", "HEAD"]) |> String.trim()
        {implementation_commits ++ [merge], merge}
      else
        {implementation_commits, nil}
      end

    claimed =
      case {variant, implementation_commits} do
        {:omitted, [harmless, _risky]} -> [harmless]
        {:manifest_omitted, [harmless, _risky]} -> [harmless]
        {:duplicate, [harmless, risky]} -> [harmless, risky, risky]
        {:foreign, commits} -> commits ++ [foreign]
        {:unresolved, commits} -> commits ++ ["deadbeef"]
        {_other, commits} -> commits
      end

    File.write!(summary_path, fixture_summary(claimed))

    completion_commit =
      if variant == :missing_boundary do
        nil
      else
        completion_paths = [Path.relative_to(summary_path, root)]

        completion_paths =
          if variant == :boundary_protected do
            File.write!(
              Path.join(root, "lib/relyra/security/signature.ex"),
              "defp do_verify(parsed, connection, certs, policy, opts)\n"
            )

            completion_paths ++ ["lib/relyra/security/signature.ex"]
          else
            completion_paths
          end

        fixture_commit!(
          root,
          completion_paths,
          "docs(73-99): complete fixture plan"
        )
      end

    if variant == :duplicate_boundary do
      git_fixture!(root, ["rm", Path.relative_to(summary_path, root)])
      git_fixture!(root, ["commit", "-q", "-m", "docs(73-99): remove fixture summary"])

      File.write!(summary_path, fixture_summary(claimed))

      fixture_commit!(
        root,
        [Path.relative_to(summary_path, root)],
        "docs(73-99): re-add fixture summary"
      )
    end

    case variant do
      :malformed_manifest ->
        File.mkdir_p!(Path.join(root, ".planning"))
        File.write!(Path.join(root, ".planning/.phase-manifest.json"), "{not-json")

      :unreachable_manifest ->
        write_phase_manifest!(root, [String.duplicate("a", 40)])

      :manifest_clean ->
        write_phase_manifest!(root, implementation_commits)

      :manifest_omitted ->
        write_phase_manifest!(root, Enum.take(implementation_commits, 1))

      :manifest_extra ->
        write_phase_manifest!(root, implementation_commits ++ [foreign])

      :manifest_reordered ->
        write_phase_manifest!(root, Enum.reverse(implementation_commits))

      :manifest_duplicate ->
        write_phase_manifest!(root, implementation_commits ++ [List.last(implementation_commits)])

      :manifest_boundary ->
        write_phase_manifest!(root, implementation_commits ++ [completion_commit])

      :manifest_ambiguous ->
        prefix = ambiguous_commit_prefix!(root)
        write_phase_manifest!(root, [prefix | tl(implementation_commits)])

      _other ->
        :ok
    end

    descendant_commits =
      case variant do
        :post_summary_risky ->
          File.write!(
            Path.join(root, "lib/relyra.ex"),
            "def start_login(connection, relay_context, policy, audit, opts \\ [])\n"
          )

          [fixture_commit!(root, ["lib/relyra.ex"], "fix(73-99): risky descendant")]

        :post_summary_harmless ->
          File.write!(Path.join(root, "README.md"), "baseline\nharmless task\ndescendant\n")
          [fixture_commit!(root, ["README.md"], "test(73-99): harmless descendant")]

        :post_summary_foreign ->
          File.write!(
            Path.join(root, "lib/relyra.ex"),
            "def start_login(connection, relay_context, policy, audit, opts \\ [])\n"
          )

          [fixture_commit!(root, ["lib/relyra.ex"], "fix(73-98): foreign descendant")]

        :post_summary_foreign_existing ->
          File.write!(
            Path.join(root, "lib/relyra.ex"),
            "def start_login(connection, relay_context, policy, audit, opts \\ [])\n"
          )

          [fixture_commit!(root, ["lib/relyra.ex"], "fix(73-98): foreign descendant")]

        :post_summary_foreign_ambiguous ->
          File.write!(
            Path.join(root, "lib/relyra.ex"),
            "def start_login(connection, relay_context, policy, audit, opts \\ [])\n"
          )

          [fixture_commit!(root, ["lib/relyra.ex"], "fix(73-98): foreign descendant")]

        :post_summary_multiple ->
          File.write!(Path.join(root, "README.md"), "baseline\nharmless task\ndescendant one\n")
          first = fixture_commit!(root, ["README.md"], "test(73-99): first descendant")

          File.write!(
            Path.join(root, "lib/relyra.ex"),
            "def start_login(connection, relay_context, policy, audit, opts \\ [])\n"
          )

          second = fixture_commit!(root, ["lib/relyra.ex"], "fix(73-99): second descendant")
          [first, second]

        :divergent_endpoint ->
          git_fixture!(root, ["checkout", "-q", "-b", "divergent-review", initial_commit])
          File.write!(Path.join(root, "divergent.txt"), "divergent endpoint\n")
          fixture_commit!(root, ["divergent.txt"], "test(73-99): divergent endpoint")
          []

        _other ->
          []
      end

    review_endpoint = root |> git_fixture!(["rev-parse", "HEAD"]) |> String.trim()

    %{
      root: root,
      plan_path: plan_path,
      implementation_commits: implementation_commits,
      completion_commit: completion_commit,
      merge_commit: merge_commit,
      descendant_commits: descendant_commits,
      foreign_descendant_commits:
        if(
          variant in [
            :post_summary_foreign,
            :post_summary_foreign_existing,
            :post_summary_foreign_ambiguous
          ],
          do: descendant_commits,
          else: []
        ),
      foreign_plan_relative: foreign_plan_relative,
      review_endpoint: review_endpoint
    }
  end

  defp fixture_summary(commits) do
    entries =
      commits
      |> Enum.with_index(1)
      |> Enum.map_join("\n", fn {commit, index} -> "#{index}. **Task** — `#{commit}` (fix)" end)

    """
    ---
    status: complete
    ---
    # Fixture Summary

    ## Task Commits

    #{entries}

    ## Complete
    """
  end

  defp write_phase_manifest!(root, commits) do
    File.mkdir_p!(Path.join(root, ".planning"))

    File.write!(
      Path.join(root, ".planning/.phase-manifest.json"),
      Jason.encode!(%{
        "phases" => %{"73" => %{"plans" => %{"73-99" => %{"commits" => commits}}}}
      })
    )
  end

  defp ambiguous_commit_prefix!(root) do
    {prefix, first, second} =
      Enum.reduce_while(1..2_000, %{}, fn index, seen ->
        contents = "manifest collision #{index}\n"

        oid =
          :crypto.hash(:sha, "blob #{byte_size(contents)}\0#{contents}")
          |> Base.encode16(case: :lower)

        prefix = String.slice(oid, 0, 4)

        case Map.fetch(seen, prefix) do
          {:ok, first} -> {:halt, {prefix, first, contents}}
          :error -> {:cont, Map.put(seen, prefix, contents)}
        end
      end)

    for {name, contents} <- [{"collision-a", first}, {"collision-b", second}] do
      File.write!(Path.join(root, name), contents)
      git_fixture!(root, ["hash-object", "-w", "--", name])
    end

    prefix
  end

  defp fixture_commit!(root, paths, subject) do
    git_fixture!(root, ["add" | paths])
    git_fixture!(root, ["commit", "-q", "-m", subject])
    root |> git_fixture!(["rev-parse", "HEAD"]) |> String.trim()
  end

  defp git_fixture!(root, args) do
    case System.cmd("git", ["-C", root | args], stderr_to_stdout: true) do
      {output, 0} -> output
      {output, status} -> flunk("git fixture command failed (#{status}): #{output}")
    end
  end

  defp mutate_file(root, relative, mutation) do
    path = Path.join(root, relative)
    File.write!(path, mutation.(File.read!(path)))
  end

  defp replace_state_status!(root, replacement) do
    mutate_file(root, ".planning/STATE.md", fn state ->
      Regex.replace(~r/^status[ \t]*:[^\n]*$/m, state, replacement)
    end)
  end

  defp validated_governance_identity(root) do
    sources = %{
      project: File.read(Path.join(root, ".planning/PROJECT.md")),
      roadmap: File.read(Path.join(root, ".planning/ROADMAP.md")),
      requirements: File.read(Path.join(root, ".planning/REQUIREMENTS.md")),
      state: File.read(Path.join(root, ".planning/STATE.md"))
    }

    with {:ok, project} <- parse_project_identity(sources.project),
         {:ok, roadmap} <- parse_roadmap_identity(sources.roadmap),
         {:ok, requirements} <- parse_requirements_identity(sources.requirements),
         {:ok, state} <- parse_state_identity(sources.state) do
      identity_violations = governance_identity_violations(project, roadmap, requirements, state)

      case identity_violations do
        [] -> validate_governance_paths(root, project, roadmap, state)
        violations -> {:error, violations}
      end
    else
      {:error, violations} -> {:error, List.wrap(violations)}
    end
  end

  defp parse_project_identity({:ok, project}) do
    case Regex.scan(~r/^## Current Milestone: (v\d+\.\d+) (.+)$/m, project,
           capture: :all_but_first
         ) do
      [[version, name]] -> {:ok, %{milestone_version: version, milestone_name: name}}
      _other -> {:error, "PROJECT current milestone must appear exactly once"}
    end
  end

  defp parse_project_identity(_error), do: {:error, "PROJECT current milestone is unreadable"}

  defp parse_roadmap_identity({:ok, roadmap}) do
    active =
      Regex.scan(
        ~r/^- Active: \*\*(v\d+\.\d+) — (.+?)\*\* \(Phases ([0-9.]+)–([0-9.]+), \d+ requirements\)\.$/m,
        roadmap,
        capture: :all_but_first
      )

    phase_entries =
      Regex.scan(~r/^- \[([ x])\] \*\*Phase ([0-9.]+): ([^*]+)\*\*/m, roadmap,
        capture: :all_but_first
      )

    malformed_phase_lines =
      roadmap
      |> String.split("\n")
      |> Enum.filter(&Regex.match?(~r/^- \[.*Phase [0-9.]+:/, &1))
      |> length()

    phase_details =
      ~r/^### Phase ([0-9.]+):[^\n]*\n(.*?)(?=^### Phase |\z)/ms
      |> Regex.scan(roadmap, capture: :all_but_first)
      |> Enum.flat_map(fn [phase, body] ->
        case Regex.run(~r/^\*\*Requirements:\*\* (.+)$/m, body, capture: :all_but_first) do
          [requirements] -> [[phase, requirements]]
          nil -> []
        end
      end)

    cond do
      length(active) != 1 ->
        {:error, "ROADMAP missing active milestone or active milestone is not singular"}

      phase_entries == [] ->
        {:error, "ROADMAP active phase set is empty"}

      malformed_phase_lines != length(phase_entries) ->
        {:error, "ROADMAP malformed phase checkbox syntax"}

      duplicated?(Enum.map(phase_entries, &Enum.at(&1, 1))) ->
        {:error, "ROADMAP duplicate phase identity"}

      true ->
        [[version, name, first_phase, last_phase]] = active

        requirements_by_phase =
          Map.new(phase_details, fn [phase, ids] ->
            {phase,
             ids |> String.split(",", trim: true) |> Enum.map(&String.trim/1) |> MapSet.new()}
          end)

        {:ok,
         %{
           milestone_version: version,
           milestone_name: name,
           phase_range: {first_phase, last_phase},
           phase_entries: phase_entries,
           phase_requirements: requirements_by_phase
         }}
    end
  end

  defp parse_roadmap_identity(_error), do: {:error, "ROADMAP active milestone is unreadable"}

  defp parse_requirements_identity({:ok, requirements}) do
    malformed =
      requirements
      |> String.split("\n")
      |> Enum.filter(&Regex.match?(~r/^- \[.*\] \*\*[A-Z]+-[0-9]+\*\*:/, &1))
      |> Enum.reject(&Regex.match?(~r/^- \[[ x]\] \*\*[A-Z]+-[0-9]+\*\*:/, &1))

    rows =
      Regex.scan(~r/^\| ([A-Z]+-[0-9]+) \| Phase ([0-9.]+) \| [^|]+ \|$/m, requirements,
        capture: :all_but_first
      )

    cond do
      malformed != [] ->
        {:error, "REQUIREMENTS malformed checkbox syntax"}

      rows == [] ->
        {:error, "REQUIREMENTS traceability is empty"}

      duplicated?(Enum.map(rows, &hd/1)) ->
        {:error, "REQUIREMENTS duplicate requirement identity"}

      true ->
        by_phase =
          rows
          |> Enum.group_by(&Enum.at(&1, 1), &hd/1)
          |> Map.new(fn {phase, ids} -> {phase, MapSet.new(ids)} end)

        {:ok, %{phase_requirements: by_phase}}
    end
  end

  defp parse_requirements_identity(_error),
    do: {:error, "REQUIREMENTS traceability is unreadable"}

  defp parse_state_identity({:ok, state}) do
    frontmatter =
      case String.split(state, "---", parts: 3) do
        ["", yaml, _body] -> yaml
        _other -> ""
      end

    fields =
      ~r/^(milestone|current_phase|status):[ \t]*([^\n]+)$/m
      |> Regex.scan(frontmatter, capture: :all_but_first)
      |> Enum.group_by(&hd/1, &(&1 |> Enum.at(1) |> String.trim()))

    case fields do
      %{"milestone" => [milestone], "current_phase" => [phase], "status" => [status]}
      when status in ["executing", "in_progress", "ready_for_verification"] ->
        {:ok, %{milestone_version: milestone, current_phase: phase, status: status}}

      _other ->
        {:error, state_identity_diagnostic(fields)}
    end
  end

  defp parse_state_identity(_error),
    do: {:error, "STATE milestone/current phase/status is unreadable"}

  defp state_identity_diagnostic(fields) do
    observed =
      ~w(milestone current_phase status)
      |> Enum.map_join(", ", fn field -> "#{field}=#{inspect(Map.get(fields, field, []))}" end)

    ".planning/STATE.md: STATE milestone/current phase/status must be singular and active; " <>
      observed
  end

  defp governance_identity_violations(project, roadmap, requirements, state) do
    []
    |> add_unless(
      project.milestone_version == roadmap.milestone_version and
        roadmap.milestone_version == state.milestone_version,
      "PROJECT/ROADMAP/STATE milestone identity disagrees"
    )
    |> add_unless(
      project.milestone_name == roadmap.milestone_name,
      "PROJECT/ROADMAP milestone name disagrees"
    )
    |> add_unless(
      match?(
        [[_mark, phase, _name] | _] when phase == state.current_phase,
        roadmap.phase_entries
      ),
      "STATE current phase disagrees with ROADMAP active phases"
    )
    |> add_unless(
      Map.get(roadmap.phase_requirements, state.current_phase) ==
        Map.get(requirements.phase_requirements, state.current_phase),
      "Phase #{state.current_phase} requirement set disagrees between ROADMAP and REQUIREMENTS"
    )
  end

  defp validate_governance_paths(root, project, roadmap, state) do
    [_mark, _phase, phase_name] = hd(roadmap.phase_entries)

    expected_dir =
      Path.join(
        root,
        ".planning/phases/#{state.current_phase}-#{slugify_phase_name(phase_name)}"
      )

    phase_dirs = if File.dir?(expected_dir), do: [expected_dir], else: []

    case phase_dirs do
      [phase_dir] ->
        all_plan_paths =
          phase_dir
          |> Path.join("#{state.current_phase}-*-PLAN.md")
          |> Path.wildcard()
          |> Enum.sort()

        {completed, incomplete} = Enum.split_with(all_plan_paths, &executed_plan?/1)
        plan_paths = completed ++ Enum.take(incomplete, 1)

        if all_plan_paths == [] or plan_paths == [] do
          {:error, ["current phase PLAN set is empty"]}
        else
          {:ok,
           %{
             root: Path.expand(root),
             milestone_version: project.milestone_version,
             milestone_name: project.milestone_name,
             current_phase: state.current_phase,
             status: state.status,
             active_phases: [state.current_phase],
             phase_requirements: roadmap.phase_requirements,
             plan_paths: plan_paths
           }}
        end

      _other ->
        {:error, ["current phase must have exactly one tracked phase directory"]}
    end
  end

  defp duplicated?(values), do: length(values) != length(Enum.uniq(values))

  defp slugify_phase_name(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
  end

  defp add_unless(violations, true, _diagnostic), do: violations
  defp add_unless(violations, false, diagnostic), do: violations ++ [diagnostic]

  defp plan_scope_violations(markdown, changed_classes \\ [], root \\ File.cwd!()) do
    with {:ok, task_region, tasks} <- closed_plan_tasks(markdown),
         [] <- task_acceptance_ownership_violations(task_region, tasks) do
      scope_sections = tag_sections(markdown, "scope_assertions")
      exclusion_sections = tag_sections(markdown, "demand_gated_exclusions")

      scope_violations =
        case scope_sections do
          [scope] ->
            approval_scope_violations(
              parse_scope_assertions(scope),
              tasks,
              changed_classes,
              root
            )

          _other ->
            ["scope_assertions must appear exactly once"]
        end

      task_type_violations(tasks) ++
        task_risk_metadata_violations(tasks) ++
        scope_violations ++
        demand_gated_exclusion_violations(exclusion_sections) ++
        deterministic_verification_violations(tasks) ++
        forbidden_capability_violations(tasks) ++
        manual_acceptance_violations(markdown) ++
        orphan_checkpoint_violations(tasks)
    else
      {:error, violations} -> violations
      violations when is_list(violations) -> violations
    end
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

  defp approval_scope_violations(scope, tasks, changed_classes, root) do
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

          checkpoint_violations(approval_class, mutation_index, checkpoint_index, tasks, root)
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

  defp checkpoint_violations(approval_class, mutation_index, checkpoint_index, tasks, root) do
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
            do: remote_checkpoint_violations(checkpoint, root),
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
    path == "scripts/setup_branch_protection.sh"
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

  defp changed_surface_classes("mix.exs", before_content, after_content) do
    before_major = mix_major_version(before_content)
    after_major = mix_major_version(after_content)

    if before_major == after_major, do: [], else: ["semver_major"]
  end

  defp changed_surface_classes(path, _before_content, _after_content) do
    cond do
      published_behaviour_path?(path) -> ["public_api"]
      security_seam_path?(path) -> ["security_posture"]
      remote_state_path?(path) -> ["remote_github"]
      true -> []
    end
  end

  defp mix_major_version(contents) do
    case Regex.run(~r/^\s*@version\s+"(\d+)\./m, contents, capture: :all_but_first) do
      [major] -> major
      nil -> :invalid
    end
  end

  defp remote_checkpoint_violations(checkpoint, root) do
    batch_violations =
      case tag_sections(checkpoint.body, "remote_batch") do
        [section] ->
          validate_remote_batch(parse_remote_batch(section), root)

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
      ~w(current_state desired_state affected_checks preflight_command read_back_command resume_signal)

    list_fields = ~w(mutation_commands rollback_commands)
    all_fields = scalar_fields ++ list_fields
    initial = %{occurrences: Map.new(all_fields, &{&1, []}), list_field: nil, errors: []}

    parsed =
      section
      |> String.split("\n")
      |> Enum.reduce(initial, fn line, state ->
        trimmed = String.trim(line)

        cond do
          trimmed == "" ->
            state

          String.starts_with?(trimmed, "-") ->
            append_remote_list_item(state, trimmed)

          captures = Regex.run(~r/^([a-z_]+):(?:\s*(.*))?$/, trimmed, capture: :all_but_first) ->
            [field, value] = captures

            cond do
              field in scalar_fields ->
                put_remote_occurrence(state, field, value, nil)

              field in list_fields and value == "" ->
                put_remote_occurrence(state, field, [], field)

              field in list_fields ->
                %{
                  state
                  | list_field: nil,
                    errors: ["#{field} must use list syntax" | state.errors]
                }

              true ->
                %{state | list_field: nil, errors: ["unparsed field #{field}" | state.errors]}
            end

          true ->
            owner = state.list_field || "field"

            %{
              state
              | list_field: nil,
                errors: ["#{owner} contains unparsed line #{trimmed}" | state.errors]
            }
        end
      end)

    %{occurrences: parsed.occurrences, syntax_errors: Enum.reverse(parsed.errors)}
  end

  defp put_remote_occurrence(state, field, value, next_list) do
    occurrences = Map.update!(state.occurrences, field, &(&1 ++ [value]))
    %{state | occurrences: occurrences, list_field: next_list}
  end

  defp append_remote_list_item(%{list_field: nil} = state, trimmed) do
    %{state | errors: ["unparsed list item #{trimmed}" | state.errors]}
  end

  defp append_remote_list_item(state, trimmed) do
    value = trimmed |> String.trim_leading("-") |> String.trim()
    field_occurrences = Map.fetch!(state.occurrences, state.list_field)
    updated = List.update_at(field_occurrences, -1, &(&1 ++ [value]))
    %{state | occurrences: Map.put(state.occurrences, state.list_field, updated)}
  end

  defp validate_remote_batch(batch, root) do
    required =
      ~w(current_state desired_state affected_checks mutation_commands preflight_command rollback_commands read_back_command resume_signal)

    shape =
      Enum.flat_map(required, fn field ->
        occurrences = Map.fetch!(batch.occurrences, field)

        cond do
          length(occurrences) != 1 ->
            ["remote_github remote_batch #{field} must occur exactly once"]

          remote_field_missing?(hd(occurrences)) ->
            ["remote_github remote_batch #{field} is missing or placeholder"]

          is_list(hd(occurrences)) and duplicated?(hd(occurrences)) ->
            ["remote_github remote_batch #{field} contains duplicate list items"]

          true ->
            []
        end
      end)

    syntax =
      Enum.map(batch.syntax_errors, &"remote_github remote_batch unparsed syntax: #{&1}")

    if shape == [] and syntax == [] do
      values =
        Map.new(batch.occurrences, fn
          {field, [value]} -> {field, value}
        end)

      validate_complete_remote_batch(values, root)
    else
      shape ++ syntax
    end
  end

  defp validate_complete_remote_batch(batch, root) do
    current = parse_remote_state(batch["current_state"])
    desired = parse_remote_state(batch["desired_state"])
    affected = parse_check_set(batch["affected_checks"])

    parsed_commands = %{
      "mutation_commands" => parse_remote_commands(batch["mutation_commands"], :mutation, root),
      "preflight_command" => parse_remote_command(batch["preflight_command"], :preflight),
      "rollback_commands" => parse_remote_commands(batch["rollback_commands"], :rollback, root),
      "read_back_command" => parse_remote_command(batch["read_back_command"], :read_back)
    }

    state_shape =
      []
      |> maybe_remote_violation(current == :error, "current_state is malformed")
      |> maybe_remote_violation(desired == :error, "desired_state is malformed")

    command_shape =
      Enum.reduce(parsed_commands, [], fn
        {field, {:error, reason}}, violations ->
          maybe_remote_violation(
            violations,
            true,
            "#{field} must contain exactly one allowed operation: #{inspect(reason)}"
          )

        {_field, {:ok, _operation}}, violations ->
          violations
      end)

    if state_shape == [] and command_shape == [] do
      same_target = current.repository == desired.repository and current.branch == desired.branch
      target = {desired.repository, desired.branch}
      {:ok, mutations} = parsed_commands["mutation_commands"]
      {:ok, preflight} = parsed_commands["preflight_command"]
      {:ok, rollbacks} = parsed_commands["rollback_commands"]
      {:ok, read_back} = parsed_commands["read_back_command"]

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
        not Enum.all?(mutations, &operation_targets?(&1, target)),
        "mutation_commands target mismatch"
      )
      |> maybe_remote_violation(
        not Enum.all?(mutations, &operation_matches_state?(&1, desired)),
        "mutation_commands payload must equal desired_state"
      )
      |> maybe_remote_violation(
        not operation_targets?(preflight, target),
        "preflight_command target mismatch"
      )
      |> maybe_remote_violation(
        not Enum.all?(rollbacks, &operation_targets?(&1, target)),
        "rollback_commands target or captured state mismatch"
      )
      |> maybe_remote_violation(
        not Enum.all?(rollbacks, &operation_matches_state?(&1, current)),
        "rollback_commands payload must equal current_state"
      )
      |> maybe_remote_violation(
        not (operation_targets?(read_back, target) and read_back.checks == affected),
        "read_back_command target or affected checks mismatch"
      )
      |> maybe_remote_violation(
        not resume_targets?(batch["resume_signal"], target),
        "resume_signal target mismatch"
      )
    else
      state_shape ++ command_shape
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
           ~r/^repository=([^;]+);\s*branch=([^;]+);\s*strict=(true|false);\s*checks=(.+)$/,
           value,
           capture: :all_but_first
         ) do
      [repository, branch, strict, checks] ->
        case parse_check_set(checks) do
          :error ->
            :error

          parsed_checks ->
            %{
              repository: String.trim(repository),
              branch: String.trim(branch),
              strict: strict == "true",
              checks: parsed_checks
            }
        end

      nil ->
        :error
    end
  end

  defp parse_check_set(value) do
    checks = value |> String.split("|", trim: false) |> Enum.map(&String.trim/1)

    if checks == [] or Enum.any?(checks, &(&1 == "")) or duplicated?(checks),
      do: :error,
      else: checks
  end

  defp parse_remote_commands(commands, field, root) do
    commands
    |> Enum.reduce_while({:ok, []}, fn command, {:ok, parsed} ->
      case parse_remote_command(command, field, root) do
        {:ok, operation} -> {:cont, {:ok, [operation | parsed]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, parsed} -> {:ok, Enum.reverse(parsed)}
      error -> error
    end
  end

  defp parse_remote_command(command, field) do
    parse_remote_command(command, field, nil)
  end

  defp parse_remote_command(command, field, root) do
    trimmed = String.trim(command)

    if trimmed == "" or String.contains?(trimmed, "\n") or
         Regex.match?(~r/[;&|`]|\$\(/, trimmed) do
      {:error, :shell_composition}
    else
      match_remote_command(trimmed, field, root)
    end
  end

  defp match_remote_command(command, :mutation, root) do
    case Regex.run(
           ~r/^gh api -X PUT repos\/([A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+)\/branches\/([A-Za-z0-9._\/-]+)\/protection --input ([A-Za-z0-9._\/-]+)$/,
           command,
           capture: :all_but_first
         ) do
      [repository, branch, input] ->
        parse_payload_operation(root, input, :api_write, repository, branch)

      nil ->
        {:error, :invalid_mutation}
    end
  end

  defp match_remote_command(command, :preflight, _root) do
    parse_api_read(command, :preflight)
  end

  defp match_remote_command(command, :rollback, root) do
    case Regex.run(
           ~r/^gh api -X PUT repos\/([A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+)\/branches\/([A-Za-z0-9._\/-]+)\/protection --input ([A-Za-z0-9._\/-]+)$/,
           command,
           capture: :all_but_first
         ) do
      [repository, branch, input] ->
        parse_payload_operation(root, input, :rollback, repository, branch)

      nil ->
        {:error, :invalid_rollback}
    end
  end

  defp match_remote_command(command, :read_back, _root) do
    case Regex.run(
           ~r/^gh api repos\/([A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+)\/branches\/([A-Za-z0-9._\/-]+)\/protection --jq '\.required_status_checks\.contexts == (\[.*\])'$/,
           command,
           capture: :all_but_first
         ) do
      [repository, branch, encoded_checks] ->
        case Jason.decode(encoded_checks) do
          {:ok, checks} when is_list(checks) and checks != [] ->
            if Enum.all?(checks, &is_binary/1) do
              {:ok,
               %{
                 kind: :read_back,
                 repository: repository,
                 branch: branch,
                 checks: checks
               }}
            else
              {:error, :invalid_check_assertion}
            end

          _error ->
            {:error, :invalid_check_assertion}
        end

      nil ->
        {:error, :invalid_read_back}
    end
  end

  defp parse_api_read(command, kind) do
    case Regex.run(
           ~r/^gh api repos\/([A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+)\/branches\/([A-Za-z0-9._\/-]+)\/protection$/,
           command,
           capture: :all_but_first
         ) do
      [repository, branch] ->
        {:ok, %{kind: kind, repository: repository, branch: branch}}

      nil ->
        {:error, :invalid_read}
    end
  end

  defp operation_targets?(operation, {repository, branch}) do
    operation.repository == repository and operation.branch == branch
  end

  defp operation_matches_state?(%{state: state}, declared) do
    state == branch_protection_state(declared.strict, declared.checks)
  end

  defp operation_matches_state?(_operation, _declared), do: false

  defp parse_payload_operation(root, input, kind, repository, branch) do
    with :ok <- validate_remote_input(root, input),
         {:ok, state} <- normalize_branch_protection_file(root, input) do
      {:ok, %{kind: kind, repository: repository, branch: branch, input: input, state: state}}
    else
      {:error, reason} -> {:error, {input, reason}}
    end
  end

  defp validate_remote_input(root, relative) do
    expanded_root = Path.expand(root)
    components = Path.split(relative)
    candidate = Path.expand(relative, expanded_root)

    cond do
      Path.type(relative) != :relative ->
        {:error, :absolute_path}

      Enum.any?(components, &(&1 in ["", ".", ".."])) ->
        {:error, :unsafe_path}

      not String.starts_with?(candidate, expanded_root <> "/") ->
        {:error, :outside_repository}

      not non_symlink_regular_path?(expanded_root, components) ->
        {:error, :not_regular_or_symlink}

      not tracked_repository_path?(expanded_root, relative) ->
        {:error, :untracked}

      true ->
        :ok
    end
  end

  defp normalize_branch_protection_file(root, relative) do
    root |> Path.join(relative) |> File.read!() |> normalize_branch_protection_json()
  end

  defp normalize_branch_protection_json(json) do
    keys =
      ~r/"([^"\\]+)"\s*:/
      |> Regex.scan(json, capture: :all_but_first)
      |> List.flatten()

    expected_top =
      ~w(required_status_checks enforce_admins required_pull_request_reviews restrictions allow_force_pushes allow_deletions block_creations required_conversation_resolution lock_branch allow_fork_syncing)

    invariants = %{
      "enforce_admins" => true,
      "required_pull_request_reviews" => nil,
      "restrictions" => nil,
      "allow_force_pushes" => false,
      "allow_deletions" => false,
      "block_creations" => false,
      "required_conversation_resolution" => false,
      "lock_branch" => false,
      "allow_fork_syncing" => false
    }

    if duplicated?(keys) do
      {:error, :duplicate_json_key}
    else
      case Jason.decode(json) do
        {:ok, %{"required_status_checks" => status} = decoded}
        when map_size(decoded) == 10 and is_map(status) ->
          with true <- MapSet.new(Map.keys(decoded)) == MapSet.new(expected_top),
               true <- MapSet.new(Map.keys(status)) == MapSet.new(~w(strict contexts)),
               strict when is_boolean(strict) <- status["strict"],
               contexts when is_list(contexts) and contexts != [] <- status["contexts"],
               true <- Enum.all?(contexts, &is_binary/1),
               false <- duplicated?(contexts),
               :ok <- validate_branch_protection_invariants(decoded, invariants) do
            {:ok, branch_protection_state(strict, contexts)}
          else
            {:error, reason} -> {:error, reason}
            _invalid -> {:error, {:branch_protection_field, "required_status_checks"}}
          end

        {:ok, _decoded} ->
          {:error, :unsupported_branch_protection_state}

        {:error, _reason} ->
          {:error, :malformed_json}
      end
    end
  end

  defp validate_branch_protection_invariants(decoded, invariants) do
    Enum.reduce_while(invariants, :ok, fn {field, expected}, :ok ->
      if Map.fetch!(decoded, field) === expected,
        do: {:cont, :ok},
        else: {:halt, {:error, {:branch_protection_field, field}}}
    end)
  end

  defp branch_protection_state(strict, contexts) do
    %{
      strict: strict,
      checks: contexts,
      enforce_admins: true,
      required_pull_request_reviews: nil,
      restrictions: nil,
      allow_force_pushes: false,
      allow_deletions: false,
      block_creations: false,
      required_conversation_resolution: false,
      lock_branch: false,
      allow_fork_syncing: false
    }
  end

  defp resume_targets?(resume_signal, {repository, branch}) do
    resume_signal == "approve remote_github #{repository} #{branch} exact batch"
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

  defp closed_plan_tasks(markdown) do
    with {:ok, task_region} <- exact_task_region(markdown),
         {:ok, tasks} <- consume_plan_tasks(task_region.body, 0, []) do
      if tasks == [] do
        {:error, ["tasks region must contain at least one task"]}
      else
        {:ok, task_region, tasks}
      end
    end
  end

  defp exact_task_region(markdown) do
    opens = Regex.scan(~r/<tasks\b/, markdown, return: :index)
    closes = Regex.scan(~r/<\/tasks\b/, markdown, return: :index)

    with [[{open_start, _length}]] <- opens,
         [[{close_start, _length}]] <- closes,
         true <- close_start > open_start,
         true <- binary_part(markdown, open_start, 7) == "<tasks>",
         true <- binary_part(markdown, close_start, 8) == "</tasks>" do
      body_start = open_start + 7

      {:ok,
       %{
         body: binary_part(markdown, body_start, close_start - body_start),
         body_start: body_start
       }}
    else
      _other -> {:error, ["tasks region must appear exactly once with balanced exact tags"]}
    end
  end

  defp consume_plan_tasks(remaining, offset, tasks) do
    trimmed = String.trim_leading(remaining)
    skipped = byte_size(remaining) - byte_size(trimmed)
    task_start = offset + skipped

    cond do
      trimmed == "" ->
        {:ok, Enum.reverse(tasks)}

      String.starts_with?(trimmed, "</task>") ->
        {:error, ["tasks region contains unmatched task close"]}

      String.starts_with?(trimmed, "<acceptance_criteria") or
          String.starts_with?(trimmed, "</acceptance_criteria") ->
        {:error, ["acceptance_criteria must be wholly owned by one implementation task"]}

      not String.starts_with?(trimmed, "<task") ->
        {:error, ["tasks region contains unconsumed task syntax"]}

      true ->
        consume_plan_task(trimmed, task_start, tasks)
    end
  end

  defp consume_plan_task(remaining, task_start, tasks) do
    case Regex.run(~r/\A<task(?<attributes>[^>]*)>/s, remaining) do
      [opening, attributes] ->
        with {:ok, parsed_attributes} <- closed_task_attributes(attributes),
             after_opening <-
               binary_part(
                 remaining,
                 byte_size(opening),
                 byte_size(remaining) - byte_size(opening)
               ),
             {close_start, _length} <- :binary.match(after_opening, "</task>"),
             body <- binary_part(after_opening, 0, close_start),
             false <- Regex.match?(~r/<task(?:\s|>)/, body) do
          task_end = task_start + byte_size(opening) + close_start + byte_size("</task>")

          with {:ok, task} <- parsed_plan_task(parsed_attributes, body, {task_start, task_end}) do
            consumed = byte_size(opening) + close_start + byte_size("</task>")
            rest = binary_part(remaining, consumed, byte_size(remaining) - consumed)
            consume_plan_tasks(rest, task_end, [task | tasks])
          end
        else
          {:error, violations} -> {:error, violations}
          :nomatch -> {:error, ["task opening tag is unterminated"]}
          true -> {:error, ["tasks region contains nested task syntax"]}
        end

      nil ->
        {:error, ["task opening tag uses unsupported syntax"]}
    end
  end

  defp closed_task_attributes(attributes) do
    tokens =
      Regex.scan(~r/\s+([a-z][a-z0-9_-]*)="([^"]*)"/, attributes, capture: :all_but_first)

    residual = Regex.replace(~r/\s+[a-z][a-z0-9_-]*="[^"]*"/, attributes, "")
    grouped = Enum.group_by(tokens, &hd/1, &Enum.at(&1, 1))
    unknown = Map.keys(grouped) -- ~w(type tdd gate)
    type_values = Map.get(grouped, "type", [])

    violations =
      []
      |> add_if(String.trim(residual) != "", "task opening tag uses unsupported syntax")
      |> add_if(unknown != [], "task opening tag contains unsupported attributes")
      |> add_if(length(type_values) != 1, "task type must appear exactly once")
      |> add_if(
        length(type_values) == 1 and hd(type_values) not in @task_types,
        "task type is unsupported: #{inspect(List.first(type_values))}"
      )
      |> add_if(length(Map.get(grouped, "tdd", [])) > 1, "task tdd attribute must be singular")
      |> add_if(length(Map.get(grouped, "gate", [])) > 1, "task gate attribute must be singular")

    if violations == [],
      do:
        {:ok,
         %{
           type: hd(type_values),
           gate: List.first(Map.get(grouped, "gate", []), "")
         }},
      else: {:error, violations}
  end

  @task_semantic_children ~w(name action files verify acceptance_criteria risk_metadata resume-signal)

  defp direct_task_children(body) do
    tokens =
      Regex.scan(~r/<\/?[A-Za-z][A-Za-z0-9_-]*(?:\s+[^<>]*)?\/?\s*>/, body, return: :index)

    {children, root, error} =
      Enum.reduce_while(tokens, {[], nil, nil}, fn [{start, length}], {children, root, _error} ->
        token = binary_part(body, start, length)

        case Regex.run(~r/\A<(\/)?([A-Za-z][A-Za-z0-9_-]*)([^<>]*)>\z/, token,
               capture: :all_but_first
             ) do
          [closing, name, suffix] ->
            is_closing = closing == "/"
            self_closing = not is_closing and String.ends_with?(String.trim(suffix), "/")

            cond do
              root != nil and name != root.name ->
                {:cont, {children, root, nil}}

              root != nil and is_closing and root.depth > 1 ->
                {:cont, {children, %{root | depth: root.depth - 1}, nil}}

              root != nil and is_closing ->
                content = binary_part(body, root.content_start, start - root.content_start)

                children =
                  if root.semantic,
                    do: children ++ [%{name: root.name, content: content}],
                    else: children

                {:cont, {children, nil, nil}}

              root != nil and not is_closing and not self_closing ->
                {:cont, {children, %{root | depth: root.depth + 1}, nil}}

              root != nil ->
                {:cont, {children, root, nil}}

              is_closing and name in @task_semantic_children ->
                {:halt, {children, nil, "task child #{name} has an unmatched close boundary"}}

              is_closing ->
                {:cont, {children, nil, nil}}

              name in @task_semantic_children and String.trim(suffix) != "" ->
                {:halt, {children, nil, "task child #{name} uses unsupported opening syntax"}}

              self_closing and name in @task_semantic_children ->
                {:cont, {children ++ [%{name: name, content: ""}], nil, nil}}

              self_closing ->
                {:cont, {children, nil, nil}}

              true ->
                frame = %{
                  name: name,
                  semantic: name in @task_semantic_children,
                  content_start: start + length,
                  depth: 1
                }

                {:cont, {children, frame, nil}}
            end

          _other ->
            {:halt, {children, root, "task child tag syntax is malformed"}}
        end
      end)

    cond do
      is_binary(error) ->
        {:error, [error]}

      root != nil ->
        {:error, ["task child #{root.name} has an unmatched open boundary"]}

      true ->
        {:ok, children}
    end
  end

  defp parsed_plan_task(attributes, body, span) do
    with {:ok, children} <- direct_task_children(body) do
      violations =
        children
        |> Enum.group_by(& &1.name)
        |> Enum.flat_map(fn {name, sections} ->
          if name in @task_semantic_children and length(sections) > 1 do
            [
              "task child #{name} must appear exactly once when present (found #{length(sections)})"
            ]
          else
            []
          end
        end)

      if violations != [] do
        {:error, violations}
      else
        risk_metadata_sections =
          children
          |> Enum.filter(&(&1.name == "risk_metadata"))
          |> Enum.map(& &1.content)

        content = fn name ->
          case Enum.find(children, &(&1.name == name)) do
            nil -> ""
            section -> String.trim(section.content)
          end
        end

        {:ok,
         %{
           type: attributes.type,
           gate: attributes.gate,
           body: body,
           span: span,
           children: children,
           name: content.("name"),
           action: content.("action"),
           files: content.("files"),
           verify: content.("verify"),
           acceptance_criteria: content.("acceptance_criteria"),
           resume_signal: content.("resume-signal"),
           risk_metadata_sections: risk_metadata_sections,
           risk_metadata:
             risk_metadata_sections
             |> Enum.flat_map(&parse_key_values/1)
             |> Enum.reduce(%{}, fn {key, value}, fields ->
               Map.update(fields, key, [value], &[value | &1])
             end)
         }}
      end
    end
  end

  defp task_acceptance_ownership_violations(_task_region, tasks) do
    tasks
    |> Enum.filter(&implementation_bearing_task?/1)
    |> Enum.flat_map(fn task ->
      case Enum.find(task.children, &(&1.name == "acceptance_criteria")) do
        nil ->
          ["#{nonempty(task.name, "unnamed task")} acceptance_criteria must appear exactly once"]

        %{content: content} ->
          []
          |> add_if(String.trim(content) == "", "acceptance_criteria must be non-empty")
          |> add_if(
            Regex.match?(~r/<\/?acceptance_criteria\b/, content),
            "nested acceptance_criteria is not allowed"
          )
      end
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

  defp repository_plan_violations(
         plan_paths,
         changed_surfaces_by_plan \\ %{},
         identity \\ nil
       ) do
    identity =
      identity ||
        case validated_governance_identity(File.cwd!()) do
          {:ok, validated} ->
            validated

          {:error, _violations} ->
            %{root: File.cwd!(), milestone_version: "v1.11", current_phase: "73"}
        end

    provenance_snapshot = repository_provenance_snapshot(identity.root)

    Enum.flat_map(plan_paths, fn plan_path ->
      markdown = File.read!(plan_path)

      case repository_changed_surfaces(
             identity.root,
             plan_path,
             changed_surfaces_by_plan,
             provenance_snapshot
           ) do
        {:ok, changes} ->
          changed_classes =
            changes
            |> Enum.flat_map(fn change ->
              changed_surface_classes(change.path, change.before, change.after)
            end)
            |> Enum.uniq()

          repository_plan_scope_violations(identity, plan_path, markdown, changed_classes)
          |> Enum.map(&"#{plan_path}: #{&1}")

        {:error, reason} ->
          plan_violations =
            repository_plan_scope_violations(identity, plan_path, markdown, [])
            |> Enum.map(&"#{plan_path}: #{&1}")

          plan_violations ++ ["#{plan_path} completed-plan diff provenance #{reason}"]
      end
    end)
  end

  defp repository_provenance_snapshot(root) do
    with {:ok, endpoint} <- review_endpoint(root),
         {:ok, tracked_paths} <-
           git_lines(root, ["ls-files", "--cached", "--", ".planning/phases"]) do
      %{root: Path.expand(root), endpoint: endpoint, tracked_paths: tracked_paths}
    else
      _error -> nil
    end
  end

  defp repository_plan_scope_violations(identity, plan_path, markdown, changed_classes) do
    case repository_plan_schema(identity, plan_path) do
      :legacy -> legacy_plan_scope_violations(markdown)
      :current -> plan_scope_violations(markdown, changed_classes)
    end
  end

  defp repository_plan_schema(identity, plan_path) do
    relative = Path.relative_to(Path.expand(plan_path), identity.root)

    legacy_paths =
      for plan <- ~w(01 02 03),
          do: ".planning/phases/73-twin-contract-and-baseline/73-#{plan}-PLAN.md"

    if identity.milestone_version == "v1.11" and identity.current_phase == "73" and
         relative in legacy_paths and executed_plan?(plan_path) do
      :legacy
    else
      :current
    end
  end

  defp legacy_plan_scope_violations(markdown) do
    with {:ok, task_region, tasks} <- closed_plan_tasks(markdown),
         [] <- task_acceptance_ownership_violations(task_region, tasks) do
      task_type_violations(tasks) ++
        deterministic_verification_violations(tasks) ++
        manual_acceptance_violations(markdown) ++
        orphan_checkpoint_violations(tasks)
    else
      {:error, violations} -> violations
      violations when is_list(violations) -> violations
    end
  end

  defp repository_changed_surfaces(root, plan_path, changed_surfaces_by_plan, snapshot) do
    cond do
      Map.has_key?(changed_surfaces_by_plan, plan_path) ->
        validate_changed_surfaces(Map.fetch!(changed_surfaces_by_plan, plan_path))

      executed_plan?(plan_path) ->
        case completed_plan_provenance(root, plan_path, snapshot) do
          {:ok, provenance} -> {:ok, provenance.changes}
          {:error, reasons, _provenance} -> {:error, Enum.join(reasons, "; ")}
          {:error, reasons} -> {:error, Enum.join(reasons, "; ")}
        end

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

  defp summary_task_commits(summary) do
    case Regex.run(~r/^## Task Commits\s*(.*?)(?=^## |\z)/ms, summary, capture: :all_but_first) do
      [section] ->
        ~r/^\d+\.\s+\*\*[^\n]+?\*\*\s+[—-]\s+`([0-9a-f]{7,40})`/mu
        |> Regex.scan(section, capture: :all_but_first)
        |> Enum.map(fn [commit] -> commit end)

      nil ->
        []
    end
  end

  defp completed_plan_provenance(root, plan_path, snapshot \\ nil) do
    plan_id = plan_path |> Path.basename() |> String.replace_suffix("-PLAN.md", "")
    summary_path = String.replace_suffix(plan_path, "-PLAN.md", "-SUMMARY.md")
    summary_relative = Path.relative_to(summary_path, root)

    with {:ok, [boundary]} <- completion_boundaries(root, summary_relative, plan_id),
         {:ok, endpoint} <- review_endpoint(root, snapshot),
         :ok <- validate_review_endpoint(root, boundary, endpoint),
         {:ok, history} <- trusted_plan_history(root, plan_id, boundary, endpoint, snapshot),
         :ok <- validate_trusted_commits(root, history.commits, boundary, endpoint, plan_id),
         {:ok, changes} <- commit_changed_surfaces(root, history.commits),
         {:ok, boundary_changes} <- commit_changed_surfaces(root, [boundary]) do
      provenance = %{
        commits: history.commits,
        descendant_assignments: history.descendant_assignments,
        changes: changes ++ boundary_changes,
        boundary_changes: boundary_changes,
        completion_boundary: boundary,
        review_endpoint: endpoint
      }

      case summary_commit_cross_check(root, summary_path, history.pre_boundary) do
        {:ok, summary_commits} ->
          {:ok, Map.put(provenance, :summary_commits, summary_commits)}

        {:error, violations, summary_commits} ->
          {:error, violations, Map.put(provenance, :summary_commits, summary_commits)}
      end
    else
      {:ok, boundaries} ->
        {:error, ["completion boundary must be unique; found #{length(boundaries)}"]}

      {:error, reasons, _trusted_commits} ->
        {:error, List.wrap(reasons)}

      {:error, reasons} ->
        {:error, List.wrap(reasons)}
    end
  end

  defp completion_boundaries(root, summary_relative, plan_id) do
    with {:ok, rows} <-
           git_lines(root, [
             "log",
             "--all",
             "--format=%H%x09%s",
             "--diff-filter=A",
             "--",
             summary_relative
           ]) do
      boundaries =
        Enum.flat_map(rows, fn row ->
          case String.split(row, "\t", parts: 2) do
            [commit, subject] -> if conventional_scope(subject) == plan_id, do: [commit], else: []
            _other -> []
          end
        end)

      {:ok, boundaries}
    end
  end

  defp trusted_plan_commits(root, plan_id, boundary) do
    with {:ok, endpoint} <- review_endpoint(root),
         :ok <- validate_review_endpoint(root, boundary, endpoint),
         {:ok, history} <- trusted_plan_history(root, plan_id, boundary, endpoint) do
      {:ok, history.commits}
    else
      {:error, violations, history} -> {:error, violations, history.commits}
      {:error, reasons} -> {:error, reasons}
    end
  end

  defp trusted_plan_history(root, plan_id, boundary, endpoint, snapshot \\ nil) do
    manifest_path = Path.join(root, ".planning/.phase-manifest.json")

    with {:ok, rows} <- git_lines(root, ["log", "--reverse", "--format=%H%x09%s", boundary]) do
      pre_boundary =
        Enum.flat_map(rows, fn row ->
          case String.split(row, "\t", parts: 2) do
            [commit, subject] when commit != boundary ->
              if conventional_scope(subject) == plan_id, do: [commit], else: []

            _other ->
              []
          end
        end)

      with {:ok, descendants, descendant_assignments} <-
             post_summary_plan_commits(root, plan_id, boundary, endpoint, snapshot) do
        history = %{
          pre_boundary: pre_boundary,
          descendants: descendants,
          descendant_assignments: descendant_assignments,
          commits: pre_boundary ++ descendants
        }

        case manifest_commit_cross_check(root, manifest_path, plan_id, boundary, pre_boundary) do
          :ok -> {:ok, history}
          {:error, violations} -> {:error, violations, history}
        end
      end
    end
  end

  defp review_endpoint(root, snapshot \\ nil) do
    if is_map(snapshot) and snapshot.root == Path.expand(root) do
      {:ok, snapshot.endpoint}
    else
      read_review_endpoint(root)
    end
  end

  defp read_review_endpoint(root) do
    case git_lines(root, ["rev-parse", "--verify", "HEAD^{commit}"]) do
      {:ok, [endpoint]} when byte_size(endpoint) in 40..64 ->
        if Regex.match?(~r/^[0-9a-f]+$/, endpoint),
          do: {:ok, endpoint},
          else: {:error, ["review endpoint is not a full commit OID"]}

      _other ->
        {:error, ["review endpoint must resolve to one full HEAD commit OID"]}
    end
  end

  defp validate_review_endpoint(root, boundary, endpoint) do
    if git_success?(root, ["merge-base", "--is-ancestor", boundary, endpoint]),
      do: :ok,
      else: {:error, ["completion boundary must be an ancestor of review endpoint"]}
  end

  defp post_summary_plan_commits(root, plan_id, boundary, endpoint, snapshot) do
    with {:ok, rows} <-
           git_lines(root, [
             "log",
             "--reverse",
             "--format=%H%x09%s",
             "#{boundary}..#{endpoint}"
           ]) do
      with {:ok, assignments} <- assign_plan_descendants(root, rows, snapshot) do
        commits =
          assignments
          |> Enum.filter(&(&1.scope == plan_id))
          |> Enum.map(& &1.commit)

        {:ok, commits, assignments}
      end
    end
  end

  defp assign_plan_descendants(root, rows, snapshot) do
    rows
    |> Enum.reduce_while({:ok, []}, fn row, {:ok, assignments} ->
      case String.split(row, "\t", parts: 2) do
        [commit, subject] ->
          scope = conventional_scope(subject)

          if is_binary(scope) and Regex.match?(~r/^\d+(?:\.\d+)?-\d+$/, scope) do
            case tracked_plan_paths(root, scope, snapshot) do
              {:ok, [path]} ->
                assignment = %{commit: commit, scope: scope, plan_path: path}
                {:cont, {:ok, assignments ++ [assignment]}}

              {:ok, paths} ->
                {:halt,
                 {:error,
                  [
                    "descendant commit #{commit} with plan scope #{scope} resolves to #{length(paths)} tracked PLAN files (expected exactly one)"
                  ]}}

              {:error, violations} ->
                {:halt, {:error, violations}}
            end
          else
            {:cont, {:ok, assignments}}
          end

        _other ->
          {:halt, {:error, ["plan-scope descendant row is malformed: #{inspect(row)}"]}}
      end
    end)
    |> case do
      {:ok, assignments} ->
        commits = Enum.map(assignments, & &1.commit)

        if duplicated?(commits),
          do: {:error, ["plan-scope descendants contain duplicate commit assignments"]},
          else: {:ok, assignments}

      error ->
        error
    end
  end

  defp tracked_plan_paths(root, plan_id, snapshot) do
    paths_result =
      if is_map(snapshot) and snapshot.root == Path.expand(root),
        do: {:ok, snapshot.tracked_paths},
        else: git_lines(root, ["ls-files", "--cached", "--", ".planning/phases"])

    with {:ok, paths} <- paths_result do
      expected = "#{plan_id}-PLAN.md"

      matches =
        paths
        |> Enum.filter(fn path ->
          String.starts_with?(path, ".planning/phases/") and
            Path.basename(path) == expected and File.regular?(Path.join(root, path))
        end)
        |> Enum.sort()

      {:ok, matches}
    end
  end

  defp manifest_commit_cross_check(root, manifest_path, plan_id, boundary, derived) do
    if File.exists?(manifest_path) do
      phase_id = plan_id |> String.split("-", parts: 2) |> hd()

      with {:ok, json} <- File.read(manifest_path),
           {:ok, manifest} <- Jason.decode(json),
           commits when is_list(commits) <-
             get_in(manifest, ["phases", phase_id, "plans", plan_id, "commits"]),
           true <-
             commits != [] and Enum.all?(commits, &(is_binary(&1) and String.trim(&1) != "")) do
        {resolved, resolution_violations} =
          Enum.map_reduce(commits, [], fn claim, violations ->
            case resolve_commit(root, claim) do
              {:ok, commit} ->
                {commit, violations}

              {:error, reason} ->
                diagnostic =
                  String.replace(reason, "SUMMARY Task Commits", "phase manifest for #{plan_id}")

                {claim, violations ++ [diagnostic]}
            end
          end)

        omitted = derived -- resolved
        foreign = resolved -- derived

        violations =
          resolution_violations
          |> add_if(
            duplicated?(commits),
            "phase manifest for #{plan_id} contains duplicate hashes"
          )
          |> add_if(
            boundary in resolved,
            "phase manifest for #{plan_id} includes completion boundary"
          )
          |> add_if(
            omitted != [],
            "phase manifest for #{plan_id} omitted #{Enum.join(omitted, ", ")}"
          )
          |> add_if(
            foreign != [],
            "phase manifest for #{plan_id} contains foreign or unreachable hashes #{Enum.join(foreign, ", ")}"
          )
          |> add_if(
            resolved != derived and omitted == [] and foreign == [],
            "phase manifest for #{plan_id} reorders the Git-derived commits"
          )

        if violations == [], do: :ok, else: {:error, violations}
      else
        _other -> {:error, ["phase manifest is malformed for #{plan_id}"]}
      end
    else
      :ok
    end
  end

  defp validate_trusted_commits(root, commits, boundary, endpoint, plan_id) do
    violations =
      []
      |> add_if(commits == [], "trusted implementation set is empty for #{plan_id}")
      |> add_if(duplicated?(commits), "trusted implementation set contains duplicate commits")

    violations =
      Enum.reduce(commits, violations, fn commit, found ->
        found
        |> add_unless(
          git_success?(root, ["merge-base", "--is-ancestor", commit, endpoint]),
          "commit #{commit} is not reachable from review endpoint"
        )
        |> add_unless(
          git_success?(root, ["merge-base", "--is-ancestor", commit, boundary]) or
            git_success?(root, ["merge-base", "--is-ancestor", boundary, commit]),
          "commit #{commit} is not on completion boundary history"
        )
        |> add_unless(
          commit_scope(root, commit) == plan_id,
          "commit #{commit} has foreign plan scope"
        )
      end)

    if violations == [], do: :ok, else: {:error, violations}
  end

  defp summary_commit_cross_check(root, summary_path, trusted_commits) do
    claimed =
      case File.read(summary_path) do
        {:ok, summary} -> summary_task_commits(summary)
        {:error, _reason} -> []
      end

    {resolved, resolution_violations} =
      Enum.map_reduce(claimed, [], fn claim, violations ->
        case resolve_commit(root, claim) do
          {:ok, commit} -> {commit, violations}
          {:error, reason} -> {claim, violations ++ [reason]}
        end
      end)

    omitted = trusted_commits -- resolved
    foreign = resolved -- trusted_commits

    violations =
      resolution_violations
      |> add_if(duplicated?(resolved), "SUMMARY Task Commits contains duplicate hashes")
      |> add_if(omitted != [], "SUMMARY Task Commits omitted #{Enum.join(omitted, ", ")}")
      |> add_if(
        foreign != [],
        "SUMMARY Task Commits contains foreign hashes #{Enum.join(foreign, ", ")}"
      )
      |> add_if(
        resolved != trusted_commits and omitted == [] and foreign == [],
        "SUMMARY Task Commits ordering is ambiguous"
      )

    if violations == [], do: {:ok, resolved}, else: {:error, violations, resolved}
  end

  defp resolve_commit(root, claim) do
    with {:ok, candidates} <- git_lines(root, ["rev-parse", "--disambiguate=#{claim}"]),
         [candidate] <- candidates,
         true <- git_success?(root, ["cat-file", "-e", "#{candidate}^{commit}"]) do
      {:ok, candidate}
    else
      [] -> {:error, "SUMMARY Task Commits contains unresolved hash #{claim}"}
      [_ | _] -> {:error, "SUMMARY Task Commits contains ambiguous hash #{claim}"}
      _other -> {:error, "SUMMARY Task Commits contains unresolved hash #{claim}"}
    end
  end

  defp conventional_scope(subject) do
    case Regex.run(~r/^[a-z]+\(([^)]+)\)!?: /, subject, capture: :all_but_first) do
      [scope] -> scope
      nil -> nil
    end
  end

  defp commit_scope(root, commit) do
    case System.cmd("git", ["-C", root, "show", "-s", "--format=%s", commit],
           stderr_to_stdout: true
         ) do
      {subject, 0} -> subject |> String.trim() |> conventional_scope()
      _other -> nil
    end
  end

  defp commit_changed_surfaces(root, commits) do
    Enum.reduce_while(commits, {:ok, []}, fn commit, {:ok, changes} ->
      case commit_paths(root, commit) do
        {:ok, paths} ->
          commit_changes =
            Enum.map(paths, fn path ->
              %{
                path: path,
                before: git_file_at(root, "#{commit}^", path),
                after: git_file_at(root, commit, path)
              }
            end)

          {:cont, {:ok, changes ++ commit_changes}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
  end

  defp commit_paths(root, commit) do
    case commit_parent_count(root, commit) do
      {:ok, 1} ->
        case System.cmd(
               "git",
               ["-C", root, "diff-tree", "--no-commit-id", "--name-only", "-r", commit],
               stderr_to_stdout: true
             ) do
          {output, 0} -> {:ok, String.split(output, "\n", trim: true)}
          {_output, _status} -> {:error, "cannot resolve task commit #{commit}"}
        end

      {:ok, parents} when parents > 1 ->
        {:error,
         "merge commit #{commit} has #{parents} parents; reviewed provenance must be linear"}

      {:ok, parents} ->
        {:error, "reviewed commit #{commit} must have exactly one parent, found #{parents}"}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp commit_parent_count(root, commit) do
    case System.cmd("git", ["-C", root, "rev-list", "--parents", "-n", "1", commit],
           stderr_to_stdout: true
         ) do
      {row, 0} ->
        fields = String.split(row, ~r/\s+/, trim: true)

        if fields == [],
          do: {:error, "cannot resolve parent topology for commit #{commit}"},
          else: {:ok, length(fields) - 1}

      {_output, _status} ->
        {:error, "cannot resolve parent topology for commit #{commit}"}
    end
  end

  defp git_file_at(root, revision, path) do
    case System.cmd("git", ["-C", root, "show", "#{revision}:#{path}"], stderr_to_stdout: true) do
      {content, 0} -> content
      {_output, _status} -> ""
    end
  end

  defp git_lines(root, args) do
    case System.cmd("git", ["-C", root | args], stderr_to_stdout: true) do
      {output, 0} -> {:ok, String.split(output, "\n", trim: true)}
      {output, _status} -> {:error, ["git provenance command failed: #{String.trim(output)}"]}
    end
  end

  defp git_success?(root, args) do
    match?({_output, 0}, System.cmd("git", ["-C", root | args], stderr_to_stdout: true))
  end

  defp add_if(violations, true, diagnostic), do: violations ++ [diagnostic]
  defp add_if(violations, false, _diagnostic), do: violations

  defp tag_sections(markdown, tag) do
    ~r/<#{Regex.escape(tag)}>(.*?)<\/#{Regex.escape(tag)}>/s
    |> Regex.scan(markdown, capture: :all_but_first)
    |> Enum.map(fn [content] -> content end)
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

  defp baseline_violations(markdown, root \\ File.cwd!()) do
    duplicate_heading_violations(markdown) ++
      finding_violations(markdown, root) ++ ci_violations(markdown)
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

  defp finding_violations(markdown, root) do
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
          evidence_violations(rows, root) ++
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

  defp evidence_violations(rows, root) do
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
            reference != "" and not allowed_verification_reference?(reference, root),
            "#{id} Reproducible Evidence verification marker lacks an allowed reference"
          )
      end
    end)
  end

  defp allowed_verification_reference?(reference, root) do
    tokens =
      ~r/`([^`]+)`/
      |> Regex.scan(reference, capture: :all_but_first)
      |> List.flatten()

    Enum.any?(tokens, &allowed_verification_token?(&1, root))
  end

  defp allowed_verification_token?(token, root) do
    allowed_repository_path?(token, root) or allowed_evidence_command?(token, root)
  end

  defp allowed_repository_path?(token, root) do
    allowed_prefix? =
      Enum.any?(
        [".planning/", ".github/", "docs/", "guides/", "lib/", "scripts/", "test/"],
        &String.starts_with?(token, &1)
      )

    expanded_root = Path.expand(root)
    components = Path.split(token)
    candidate = Path.expand(token, expanded_root)

    allowed_prefix? and Path.type(token) == :relative and
      not Enum.any?(components, &(&1 in [".", ".."] or &1 == "")) and
      String.starts_with?(candidate, expanded_root <> "/") and
      non_symlink_regular_path?(expanded_root, components) and
      tracked_repository_path?(expanded_root, Path.relative_to(candidate, expanded_root))
  end

  defp non_symlink_regular_path?(root, components) do
    components
    |> Enum.reduce_while(root, fn component, parent ->
      candidate = Path.join(parent, component)

      case File.lstat(candidate) do
        {:ok, %File.Stat{type: :symlink}} -> {:halt, false}
        {:ok, _stat} -> {:cont, candidate}
        {:error, _reason} -> {:halt, false}
      end
    end)
    |> case do
      false -> false
      candidate -> File.regular?(candidate)
    end
  end

  defp tracked_repository_path?(root, relative_path) do
    case System.cmd(
           "git",
           ["-C", root, "ls-files", "--error-unmatch", "--", relative_path],
           stderr_to_stdout: true
         ) do
      {_output, 0} -> true
      {_output, _status} -> false
    end
  end

  defp allowed_evidence_command?(token, root) do
    AdoptionEvidence.validate_automated_command!(token, root) == :ok
  rescue
    _error in [ArgumentError, File.Error] -> false
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

  defp byte_offset(markdown, marker) do
    case :binary.match(markdown, marker) do
      {offset, _length} -> {:ok, offset}
      :nomatch -> :error
    end
  end
end
