defmodule Relyra.Governance.MilestoneScopeTest do
  use ExUnit.Case, async: true

  @moduletag :evidence_contract

  alias Relyra.AdoptionEvidence

  @baseline_path ".planning/phases/73-twin-contract-and-baseline/73-BASELINE.md"
  @signature_source_path "lib/relyra/security/signature.ex"
  @phase79_candidate_root "/private/var/folders/f3/f0clj9rd2zb85n2c849wcsrc0000gn/T/relyra-phase79-filtered-candidate"
  @phase79_base_sha "c786a9890f2f99f0dd98f89a1d9713db7c486837"
  @phase79_source_sha "a5820aac9983b7289cbc1cc816120017761a02e3"
  @phase79_source_tree_sha "4ebd2357cb25980edb80c94a144657bfe9083a56"
  @phase79_proof_path ".planning/phases/79-adopter-ready-closeout/79-FILTERED-HISTORY-PROOF.json"
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
  @phase_74_requirements ~w(PKG-01 PKG-02 PKG-03 PKG-04 PKG-05 PKG-06)
  @phase_76_requirements ~w(EVID-03 JOUR-01 JOUR-02 JOUR-03 JOUR-04 JOUR-05 JOUR-06)
  @phase_77_requirements ~w(QUAL-02 QUAL-03 QUAL-04 QUAL-05 QUAL-06)
  @phase_78_requirements ~w(PIPE-02 PIPE-03 PIPE-04 PIPE-05)

  @tag :plan_73_33_task_1
  @tag :plan_77_04_task_1
  test "completed Phase 73 accepts the ordered current planning lifecycle" do
    assert {:ok, identity} = validated_governance_identity(File.cwd!())

    case {identity.current_phase, identity.status} do
      {"74", "planning"} ->
        assert identity.governance_phase == "73"

      {"75", "planning"} ->
        assert identity.governance_phase == "73"

      {phase, "planning"} when phase in ["76", "77"] ->
        assert identity.governance_phase == "73"

      {"78", "planning"} ->
        assert identity.governance_phase == "77"

        assert Enum.all?(
                 identity.plan_paths,
                 &String.contains?(&1, "/77-code-and-documentation-craftsmanship/")
               )

      {"79", "planning"} ->
        assert identity.governance_phase == "78"

        expected_plans =
          for plan <- 1..9 do
            "78-#{plan |> Integer.to_string() |> String.pad_leading(2, "0")}-PLAN.md"
          end

        assert Enum.map(identity.plan_paths, &Path.basename/1) == expected_plans

        assert Enum.all?(
                 identity.plan_paths,
                 &String.contains?(&1, "/78-ci-efficiency-and-reliability/")
               )

      {"77", status} when status in ["executing", "in_progress", "ready_for_verification"] ->
        assert identity.governance_phase == "77"

      {"75", status} when status in ["executing", "in_progress", "ready_for_verification"] ->
        assert identity.governance_phase == "75"

      {"76", status} when status in ["executing", "in_progress", "ready_for_verification"] ->
        assert identity.governance_phase == "76"

      {"74", status} when status in ["executing", "in_progress", "ready_for_verification"] ->
        assert identity.governance_phase == "74"

      {"78", status} when status in ["executing", "in_progress", "ready_for_verification"] ->
        assert identity.governance_phase == "78"
        assert length(identity.plan_paths) == 9

      {"79", status} when status in ["executing", "in_progress", "ready_for_verification"] ->
        assert identity.governance_phase == "79"
        assert Enum.any?(identity.plan_paths, &String.ends_with?(&1, "/79-01-PLAN.md"))

      {"79", "Ready to execute"} ->
        assert identity.governance_phase == "79"
        assert Enum.any?(identity.plan_paths, &String.ends_with?(&1, "/79-01-PLAN.md"))

      {"73", status} when status in ["executing", "in_progress", "ready_for_verification"] ->
        planning_root = governance_repository_fixture()
        planning_state!(planning_root)

        File.cp!(
          ".planning/phases/73-twin-contract-and-baseline/73-10-SUMMARY.md",
          Path.join(
            planning_root,
            ".planning/phases/73-twin-contract-and-baseline/73-10-SUMMARY.md"
          )
        )

        assert {:ok, planning} = validated_governance_identity(planning_root)
        assert planning.current_phase == "74"
        assert planning.governance_phase == "73"
        assert planning.status == "planning"

        later_planning_root = governance_repository_fixture()
        planning_state!(later_planning_root, "77")

        File.cp!(
          ".planning/phases/73-twin-contract-and-baseline/73-10-SUMMARY.md",
          Path.join(
            later_planning_root,
            ".planning/phases/73-twin-contract-and-baseline/73-10-SUMMARY.md"
          )
        )

        assert {:ok, later_planning} = validated_governance_identity(later_planning_root)
        assert later_planning.current_phase == "77"
        assert later_planning.governance_phase == "73"
        assert later_planning.status == "planning"
        assert later_planning.phase_requirements["77"] == MapSet.new(@phase_77_requirements)

      other ->
        flunk("unexpected actual governance lifecycle: #{inspect(other)}")
    end

    assert identity.phase_requirements["73"] == MapSet.new(@phase_73_requirements)
    assert identity.phase_requirements["74"] == MapSet.new(@phase_74_requirements)

    assert identity.phase_requirements["75"] ==
             MapSet.new(["TWIN-01", "TWIN-02", "TWIN-03", "TWIN-04", "TWIN-05"])

    assert identity.phase_requirements["76"] == MapSet.new(@phase_76_requirements)
    assert identity.phase_requirements["77"] == MapSet.new(@phase_77_requirements)
    assert identity.phase_requirements["78"] == MapSet.new(@phase_78_requirements)
    assert identity.phase_requirements["79"] == MapSet.new(~w(REPO-01 REPO-02 REPO-03 EXIT-01))

    governed_phase_dir =
      case identity.governance_phase do
        "73" -> "/73-twin-contract-and-baseline/"
        "74" -> "/74-clean-room-package-consumer/"
        "75" -> "/75-saas-twin-domain-realism/"
        "76" -> "/76-lifecycle-and-recovery-journeys/"
        "77" -> "/77-code-and-documentation-craftsmanship/"
        "78" -> "/78-ci-efficiency-and-reliability/"
        "79" -> "/79-adopter-ready-closeout/"
      end

    assert Enum.all?(identity.plan_paths, &String.contains?(&1, governed_phase_dir))

    expected_current_plan =
      case identity.governance_phase do
        "73" -> "73-33-PLAN.md"
        "74" -> "74-04-PLAN.md"
        "75" -> "75-03-PLAN.md"
        "76" -> "76-02-PLAN.md"
        "77" -> "77-04-PLAN.md"
        "78" -> "78-01-PLAN.md"
        "79" -> "79-01-PLAN.md"
      end

    assert Enum.any?(identity.plan_paths, &String.ends_with?(&1, expected_current_plan))

    for status <- ~w(executing in_progress ready_for_verification) do
      root = governance_repository_fixture()
      planning_state!(root)
      state_for_phase!(root, "73", status)

      assert {:ok, active} = validated_governance_identity(root)
      assert active.current_phase == "73"
      assert active.governance_phase == "73"
      assert active.status == status
    end
  end

  @tag :plan_73_34_task_1
  test "completed Phase 73 accepts the ordered Phase 75 planning lifecycle" do
    root = governance_repository_fixture()
    planning_state!(root, "75")

    File.cp!(
      ".planning/phases/73-twin-contract-and-baseline/73-10-SUMMARY.md",
      Path.join(root, ".planning/phases/73-twin-contract-and-baseline/73-10-SUMMARY.md")
    )

    assert {:ok, later} = validated_governance_identity(root)
    assert later.current_phase == "75"
    assert later.governance_phase == "73"
    assert later.status == "planning"

    assert later.phase_requirements["75"] ==
             MapSet.new(["TWIN-01", "TWIN-02", "TWIN-03", "TWIN-04", "TWIN-05"])

    assert Enum.all?(later.plan_paths, &String.contains?(&1, "/73-twin-contract-and-baseline/"))

    controls = [
      {:duplicate_state,
       fn root ->
         mutate_file(root, ".planning/STATE.md", fn state ->
           String.replace(state, "current_phase: 75", "current_phase: 75\ncurrent_phase: 75")
         end)
       end},
      {:malformed_status,
       fn root ->
         mutate_file(
           root,
           ".planning/STATE.md",
           &String.replace(&1, "status: planning", "status : planning")
         )
       end},
      {:skipped_intermediate,
       fn root ->
         mutate_file(
           root,
           ".planning/ROADMAP.md",
           &String.replace(&1, "- [x] **Phase 74:", "- [ ] **Phase 74:")
         )
       end},
      {:missing_current,
       fn root ->
         mutate_file(root, ".planning/ROADMAP.md", &String.replace(&1, "- [ ] **Phase 75:", ""))
       end},
      {:mismatched_requirements,
       fn root ->
         mutate_file(
           root,
           ".planning/REQUIREMENTS.md",
           &String.replace(
             &1,
             "| TWIN-01 | Phase 75 | Pending |",
             "| TWIN-01 | Phase 74 | Pending |"
           )
         )
       end}
    ]

    for {name, mutate} <- controls do
      invalid_root = governance_repository_fixture()
      planning_state!(invalid_root, "75")
      mutate.(invalid_root)

      assert {:error, violations} = validated_governance_identity(invalid_root)
      assert violations != [], "expected #{name} to reject the later-phase lifecycle"
    end

    assert {:ok, checked_in} = validated_governance_identity(File.cwd!())
    assert checked_in.current_phase in Map.keys(checked_in.phase_requirements)
  end

  test "Phase 78 lifecycle accepts its planning and active states and rejects broken transitions" do
    planning_root = governance_repository_fixture()
    planning_state!(planning_root, "78")

    assert {:ok, planning} = validated_governance_identity(planning_root)
    assert planning.current_phase == "78"
    assert planning.status == "planning"
    assert planning.phase_requirements["78"] == MapSet.new(@phase_78_requirements)

    for status <- ~w(executing in_progress ready_for_verification) do
      active_root = governance_repository_fixture()
      state_for_phase!(active_root, "78", status)

      assert {:ok, active} = validated_governance_identity(active_root)
      assert active.current_phase == "78"
      assert active.governance_phase == "78"
      assert active.status == status
      assert length(active.plan_paths) == 9
    end

    malformed_controls = [
      {:duplicate_phase,
       fn root ->
         mutate_file(root, ".planning/STATE.md", fn state ->
           String.replace(state, "current_phase: 78", "current_phase: 78\ncurrent_phase: 78")
         end)
       end},
      {:malformed_status,
       fn root ->
         mutate_file(root, ".planning/STATE.md", fn state ->
           String.replace(state, "status: executing", "status : executing")
         end)
       end},
      {:skipped_predecessor,
       fn root ->
         mutate_file(root, ".planning/ROADMAP.md", fn roadmap ->
           String.replace(roadmap, "- [x] **Phase 77:", "- [ ] **Phase 77:")
         end)
       end}
    ]

    for {name, mutate} <- malformed_controls do
      invalid_root = governance_repository_fixture()
      state_for_phase!(invalid_root, "78", "executing")
      mutate.(invalid_root)

      assert {:error, violations} = validated_governance_identity(invalid_root)
      assert violations != [], "expected Phase 78 #{name} transition to fail closed"
    end
  end

  test "Phase 79 planning inherits all Phase 78 plans and rejects broken governance" do
    root = governance_repository_fixture()
    planning_state!(root, "79")

    assert {:ok, planning} = validated_governance_identity(root)
    assert planning.current_phase == "79"
    assert planning.governance_phase == "78"
    assert planning.status == "planning"
    assert planning.phase_requirements["78"] == MapSet.new(@phase_78_requirements)

    expected_plans =
      for plan <- 1..9 do
        "78-#{plan |> Integer.to_string() |> String.pad_leading(2, "0")}-PLAN.md"
      end

    assert Enum.map(planning.plan_paths, &Path.basename/1) == expected_plans

    ready_to_execute = governance_repository_fixture()
    state_for_phase!(ready_to_execute, "79", "executing")
    replace_state_status!(ready_to_execute, "status: Ready to execute")

    assert {:ok, active} = validated_governance_identity(ready_to_execute)
    assert active.current_phase == "79"
    assert active.governance_phase == "79"
    assert active.status == "Ready to execute"

    skipped_predecessor = governance_repository_fixture()
    planning_state!(skipped_predecessor, "79")

    mutate_file(skipped_predecessor, ".planning/ROADMAP.md", fn roadmap ->
      String.replace(roadmap, "- [x] **Phase 78:", "- [ ] **Phase 78:")
    end)

    assert {:error, predecessor_violations} = validated_governance_identity(skipped_predecessor)
    assert predecessor_violations != []

    malformed_metadata = governance_repository_fixture()
    planning_state!(malformed_metadata, "79")

    malformed_plan_path =
      Path.join([
        malformed_metadata,
        ".planning/phases/78-ci-efficiency-and-reliability/78-09-PLAN.md"
      ])

    mutate_file(
      malformed_metadata,
      Path.relative_to(malformed_plan_path, malformed_metadata),
      fn plan ->
        Regex.replace(~r/\s*<risk_metadata>.*?<\/risk_metadata>/s, plan, "", global: false)
      end
    )

    assert {:ok, malformed_identity} = validated_governance_identity(malformed_metadata)

    malformed_violations =
      repository_plan_violations(malformed_identity.plan_paths, %{}, malformed_identity)

    assert Enum.any?(malformed_violations, &(&1 =~ "risk_metadata"))

    missing_scope = governance_repository_fixture()
    planning_state!(missing_scope, "79")

    missing_scope_path =
      Path.join([
        missing_scope,
        ".planning/phases/78-ci-efficiency-and-reliability/78-09-PLAN.md"
      ])

    mutate_file(missing_scope, Path.relative_to(missing_scope_path, missing_scope), fn plan ->
      Regex.replace(~r/<scope_assertions>.*?<\/scope_assertions>/s, plan, "", global: false)
    end)

    assert {:ok, missing_scope_identity} = validated_governance_identity(missing_scope)

    missing_scope_violations =
      repository_plan_violations(missing_scope_identity.plan_paths, %{}, missing_scope_identity)

    assert Enum.any?(
             missing_scope_violations,
             &(&1 =~ "scope_assertions must appear exactly once")
           )
  end

  @tag :plan_73_33_task_2
  test "planning lifecycle controls fail closed across authoritative documents" do
    controls = [
      {:duplicate_current_phase, :state, "current_phase: 74\ncurrent_phase: 74"},
      {:malformed_status, :state, "status : planning"},
      {:skipped_phase, :state, "current_phase: 76"},
      {:nonexistent_phase, :roadmap, "### Phase 74: Clean-Room Package Consumer"},
      {:mismatched_roadmap, :roadmap, "- [x] **Phase 74: Clean-Room Package Consumer**"},
      {:mismatched_requirements, :requirements, "| PKG-01 | Phase 73 | Pending |"}
    ]

    for {name, source, replacement} <- controls do
      root = governance_repository_fixture()
      planning_state!(root)

      case source do
        :state ->
          mutate_file(root, ".planning/STATE.md", fn state ->
            case name do
              :duplicate_current_phase ->
                Regex.replace(~r/^current_phase: 74$/m, state, replacement)

              :malformed_status ->
                Regex.replace(~r/^status: .*$/m, state, replacement)

              :skipped_phase ->
                String.replace(state, "current_phase: 74", replacement)
            end
          end)

        :roadmap ->
          mutate_file(root, ".planning/ROADMAP.md", fn roadmap ->
            if name == :nonexistent_phase do
              String.replace(roadmap, "- [ ] **Phase 74:", "")
            else
              String.replace(roadmap, "- [ ] **Phase 74:", "- [x] **Phase 74:")
            end
          end)

        :requirements ->
          mutate_file(root, ".planning/REQUIREMENTS.md", fn requirements ->
            String.replace(requirements, "| PKG-01 | Phase 74 | Pending |", replacement)
          end)
      end

      case validated_governance_identity(root) do
        {:error, _violations} ->
          :ok

        {:ok, identity} ->
          flunk("expected #{name} lifecycle control to fail: #{inspect(identity)}")
      end
    end

    proof = Relyra.Phase73Reconciliation.fixture_proof!(File.cwd!())
    assert length(proof["acceptance_task_ids"]) == 72
    assert List.last(proof["acceptance_task_ids"]) == "73-34-02"
    assert length(proof["focused"]) == 21

    assert Enum.map(Enum.take(proof["focused"], -2), & &1["command"]) == [
             "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
             "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors"
           ]
  end

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
    assert checked_in_identity.current_phase in Map.keys(checked_in_identity.phase_requirements)

    expected_governance_phase =
      case {checked_in_identity.current_phase, checked_in_identity.status} do
        {"79", "planning"} -> "78"
        {_phase, "planning"} -> "73"
        {phase, _status} -> phase
      end

    assert checked_in_identity.governance_phase == expected_governance_phase

    assert checked_in_identity.status in [
             "executing",
             "in_progress",
             "ready_for_verification",
             "planning",
             "Ready to execute"
           ]

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
                 violation =~ "must be singular and supported" and
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
           &String.replace(&1, "- [ ] **Phase 73:", "- [-] **Phase 73:")
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

      case validated_governance_identity(fixture) do
        {:error, violations} ->
          assert Enum.any?(violations, &String.contains?(&1, diagnostic)),
                 "expected #{diagnostic}, got: #{inspect(violations)}"

        {:ok, identity} ->
          flunk("expected #{diagnostic} to fail, got: #{inspect(identity)}")
      end
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
    assert summary_task_commits("""
           ## Task Commits

           1. **Task 3: Artifact identity and owner assertions** — `4b91adb`, `d0eae82` (`test`)
           """) == ["4b91adb", "d0eae82"]

    assert summary_task_commits("""
           ## Task Commits

           1. `0acd5ce094b4`, `88454dbd4173` — replay verifier and fixtures
           2. `7a0023f8102a` — provenance join
           """) == ["0acd5ce094b4", "88454dbd4173", "7a0023f8102a"]

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

    assert length(plan_paths) == 34

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

    real_root = File.cwd!()
    plan_27 = Path.join(real_root, ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md")
    assert {:ok, real_provenance} = completed_plan_provenance(real_root, plan_27)
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

  @tag :evidence_contract
  test "halted phase summaries remain archival and are skipped by active plan governance" do
    root = File.cwd!()

    fixture_dir =
      Path.join(
        System.tmp_dir!(),
        "relyra-halted-plan-#{System.unique_integer([:positive])}"
      )

    fixture_phase_dir = Path.join(fixture_dir, ".planning/phases/79-fixture")
    File.mkdir_p!(fixture_phase_dir)
    on_exit(fn -> File.rm_rf!(fixture_dir) end)

    halted_top_level = Path.join(fixture_phase_dir, "79-08-PLAN.md")
    halted_nested = Path.join(fixture_phase_dir, "79-13-PLAN.md")
    File.write!(halted_top_level, "---\nphase: 79\nplan: 08\n---\n")
    File.write!(halted_nested, "---\nphase: 79\nplan: 13\n---\n")
    File.write!(Path.join(fixture_phase_dir, "79-08-SUMMARY.md"), "---\nstatus: halted\n---\n")

    File.write!(
      Path.join(fixture_phase_dir, "79-13-SUMMARY.md"),
      "---\nmetrics:\n  status: halted\n---\n"
    )

    completed = Path.join(root, ".planning/phases/79-adopter-ready-closeout/79-07-PLAN.md")

    assert halted_plan_summary?(halted_top_level)
    assert halted_plan_summary?(halted_nested)
    refute halted_plan_summary?(completed)

    identity = %{root: root}
    assert repository_plan_violations([halted_top_level, halted_nested], %{}, identity) == []

    assert {:ok, _changed_surfaces} =
             repository_changed_surfaces(
               root,
               completed,
               %{},
               repository_provenance_snapshot(root)
             )
  end

  @tag :plan_73_23_task_1
  @tag :plan_73_32_task_1
  test "active v1.11 plans declare scope and stop before every risky mutation" do
    assert {:ok, identity} = validated_governance_identity(File.cwd!())

    if identity.status == "planning" and identity.governance_phase == "73" do
      assert identity.current_phase in ["74", "75", "76", "77"]
      assert identity.governance_phase == "73"

      expected_plan_count =
        if File.exists?(".planning/phases/73-twin-contract-and-baseline/73-34-SUMMARY.md"),
          do: 34,
          else: 33

      assert length(identity.plan_paths) == expected_plan_count
      assert Enum.all?(identity.plan_paths, &executed_plan?/1)
    else
      violations = repository_plan_violations(identity.plan_paths, %{}, identity)

      assert violations == [],
             "Active milestone plans violate approval policy:\n" <>
               Enum.map_join(violations, "\n", &"  - #{&1}")
    end

    owners = Relyra.Phase73Reconciliation.acceptance_task_ids!(File.cwd!())
    assert length(owners) == 72
    assert List.last(owners) == "73-34-02"
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
    assert length(proof["acceptance_task_ids"]) == 72
    assert List.last(proof["acceptance_task_ids"]) == "73-34-02"

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
  test "current tracked plan inventory builds one validated 34-plan proof" do
    reconciliation = Relyra.Phase73Reconciliation
    root = File.cwd!()

    assert {tracked_plans, 0} =
             System.cmd("git", [
               "ls-files",
               "--",
               ".planning/phases/73-twin-contract-and-baseline/73-*-PLAN.md"
             ])

    assert length(String.split(tracked_plans, "\n", trim: true)) == 34
    proof = reconciliation.fixture_proof!(root)
    {security, validation} = reconciliation.fixture_documents!(proof, :staged)

    assert length(proof["acceptance_task_ids"]) == 72
    assert List.last(proof["acceptance_task_ids"]) == "73-34-02"

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
        |> Enum.map(&"#{Path.basename(path)}: #{&1}")
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

  @tag :plan_77_04_task_1
  test "signature rationale comments preserve approval classification" do
    source = """
    defmodule SignatureFixture do
      @doc "Verifies a signed value."
      @spec verify(term()) :: term()
      def verify(value), do: value
    end
    """

    comment_only = "# The configured certificate remains the trust source.\n" <> source

    assert changed_surface_classes("lib/relyra/security/signature.ex", source, comment_only) == []
  end

  @tag :plan_77_04_task_1
  test "signature documentation, specification, and executable changes remain posture mutations" do
    source = """
    defmodule SignatureFixture do
      @doc "Verifies a signed value."
      @spec verify(term()) :: term()
      def verify(value), do: value
    end
    """

    changed_sources = [
      String.replace(source, "Verifies a signed value.", "Uses a different trust boundary."),
      String.replace(
        source,
        "@spec verify(term()) :: term()",
        "@spec verify(binary()) :: atom()"
      ),
      String.replace(source, "def verify(value), do: value", "def verify(_value), do: :trusted")
    ]

    for changed_source <- changed_sources do
      assert "security_posture" in changed_surface_classes(
               "lib/relyra/security/signature.ex",
               source,
               changed_source
             )
    end
  end

  @tag :plan_77_04_task_1
  test "malformed signature source fails closed and other security seams stay conservative" do
    source = "defmodule SignatureFixture do\n  def verify(value), do: value\nend\n"
    malformed = source <> "def broken(\n"

    assert "security_posture" in changed_surface_classes(
             "lib/relyra/security/signature.ex",
             source,
             malformed
           )

    assert "security_posture" in changed_surface_classes(
             "lib/relyra/security/signature.ex",
             malformed,
             source
           )

    assert "security_posture" in changed_surface_classes(
             "lib/relyra/security/signature.ex",
             malformed,
             malformed
           )

    assert "security_posture" in changed_surface_classes(
             "lib/relyra/security/xml/pure_beam.ex",
             "before",
             "after"
           )
  end

  @tag :plan_77_04_task_1
  test "completed signature documentation changes retain their approved posture checkpoint" do
    assert {:ok, identity} = validated_governance_identity(File.cwd!())

    plan_path =
      Path.join(
        File.cwd!(),
        ".planning/phases/77-code-and-documentation-craftsmanship/77-02-PLAN.md"
      )

    assert {:ok, provenance} = completed_plan_provenance(File.cwd!(), plan_path)

    signature_classes =
      provenance.changes
      |> Enum.filter(&(&1.path == @signature_source_path))
      |> Enum.flat_map(&changed_surface_classes(&1.path, &1.before, &1.after))

    assert "security_posture" in signature_classes,
           "the completed @doc source edits must remain posture mutations"

    plan = File.read!(plan_path)
    assert plan =~ "security_posture: mutation"
    assert plan =~ "<decision>approval_class: security_posture</decision>"

    violations = repository_plan_violations([plan_path], %{}, identity)

    assert violations == [],
           "the approved posture checkpoint must satisfy the completed plan: #{inspect(violations)}"
  end

  @tag :plan_77_04_task_1
  test "only fully verified comment-only signature provenance suppresses posture requirements" do
    before_source = "defmodule SignatureFixture do\n  def verify(value), do: value\nend\n"
    after_source = "# Rationale only.\n" <> before_source

    comment_changes = [
      %{path: @signature_source_path, before: before_source, after: after_source}
    ]

    neutral_paths = verified_comment_only_signature_paths(comment_changes)
    assert neutral_paths == [@signature_source_path]

    plan =
      risky_plan_fixture("security_posture")
      |> String.replace("governed/file.ex", @signature_source_path)
      |> String.replace("security_posture: mutation", "security_posture: unchanged")
      |> String.replace(
        "<action>approval_class: security_posture. Change the assertion trust policy.</action>",
        "<action>Add rationale comments to the signature source.</action>"
      )
      |> remove_checkpoint()

    assert plan_scope_violations(plan, [], File.cwd!(), neutral_paths) == []

    semantic_change = %{
      path: @signature_source_path,
      before: before_source,
      after: String.replace(before_source, "do: value", "do: :trusted")
    }

    malformed_change = %{
      path: @signature_source_path,
      before: before_source,
      after: "defmodule Broken do\n  def verify(\n"
    }

    refute @signature_source_path in verified_comment_only_signature_paths([semantic_change])

    refute @signature_source_path in verified_comment_only_signature_paths(
             comment_changes ++ [malformed_change]
           )
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

  test "nested demo test commands stay scoped and bind future owners to task outputs" do
    command =
      "mix cmd --cd demo/ledger_loop mix test test/ledger_loop_web/lifecycle_journeys_test.exs --warnings-as-errors"

    assert :ok = AdoptionEvidence.validate_automated_command!(command, File.cwd!())

    future_command =
      "mix cmd --cd demo/ledger_loop mix test test/ledger_loop_web/future_journey_test.exs --warnings-as-errors"

    assert_raise ArgumentError, ~r/is missing/, fn ->
      AdoptionEvidence.validate_automated_command!(future_command, File.cwd!())
    end

    assert :ok =
             AdoptionEvidence.validate_automated_command!(future_command, File.cwd!(),
               planned_files: "demo/ledger_loop/test/ledger_loop_web/future_journey_test.exs"
             )

    for unsafe <- [
          "mix cmd --cd demo/ledger_loop mix run test/ledger_loop_web/lifecycle_journeys_test.exs --warnings-as-errors",
          "mix cmd --cd ../outside mix test test/ledger_loop_web/lifecycle_journeys_test.exs --warnings-as-errors",
          "mix cmd --cd demo/ledger_loop mix test ../test/governance/milestone_scope_test.exs --warnings-as-errors"
        ] do
      assert_raise ArgumentError, fn ->
        AdoptionEvidence.validate_automated_command!(unsafe, File.cwd!())
      end
    end
  end

  @tag :evidence_contract
  test "Phase 79 transaction verifier exceptions are exact, direct, and tracked" do
    plan_path =
      Path.join(File.cwd!(), ".planning/phases/79-adopter-ready-closeout/79-15-PLAN.md")

    command =
      "python3 scripts/verify_phase79_transaction.py --stage pr-preflight --phase-dir .planning/phases/79-adopter-ready-closeout --candidate-root #{@phase79_candidate_root}"

    assert phase79_transaction_command?(plan_path, command)
    refute phase79_transaction_command?(plan_path, command <> " && echo unsafe")

    refute phase79_transaction_command?(
             plan_path,
             String.replace(command, "pr-preflight", "delete-branch")
           )
  end

  @tag :evidence_contract
  test "Phase 79 PR-create and merge approval batches bind exact packet and provenance fields" do
    for plan_name <- ["79-15-PLAN.md", "79-09-PLAN.md"] do
      path = Path.join(File.cwd!(), ".planning/phases/79-adopter-ready-closeout/#{plan_name}")
      assert {:ok, _region, tasks} = closed_plan_tasks(File.read!(path))
      checkpoint = Enum.find(tasks, &(&1.type == "checkpoint:decision"))
      assert checkpoint

      assert ["approval_class: remote_github"] =
               tag_sections(checkpoint.body, "decision") |> Enum.map(&String.trim/1)

      assert [batch] = tag_sections(checkpoint.body, "remote_batch")
      assert validate_remote_batch(parse_remote_batch(batch), File.cwd!()) == []

      expected_kind = if plan_name == "79-15-PLAN.md", do: "pr_create", else: "merge"
      wrong_kind = if expected_kind == "pr_create", do: "merge", else: "pr_create"

      wrong_operation =
        String.replace(batch, "operation_kind: #{expected_kind}", "operation_kind: #{wrong_kind}")

      assert validate_remote_batch(parse_remote_batch(wrong_operation), File.cwd!()) != []

      wrong_branch =
        String.replace(
          batch,
          "candidate_ref=refs/heads/@publication.branch.name",
          "candidate_ref=refs/heads/relyra-phase79-filtered"
        )

      assert validate_remote_batch(parse_remote_batch(wrong_branch), File.cwd!()) != []

      altered_repository =
        String.replace(batch, "repository=szTheory/relyra;", "repository=szTheory/relyra.evil;")

      assert validate_remote_batch(parse_remote_batch(altered_repository), File.cwd!()) != []

      duplicate_repository =
        String.replace(
          batch,
          "repository=szTheory/relyra;",
          "repository=szTheory/relyra; repository=szTheory/relyra;"
        )

      assert validate_remote_batch(parse_remote_batch(duplicate_repository), File.cwd!()) != []

      wrong_preflight =
        String.replace(
          batch,
          @phase79_candidate_root,
          "/tmp/other-candidate"
        )

      assert validate_remote_batch(parse_remote_batch(wrong_preflight), File.cwd!()) != []

      wrong_checkpoint =
        %{
          checkpoint
          | body:
              String.replace(
                checkpoint.body,
                "approval_class: remote_github",
                "approval_class: public_api"
              )
        }

      altered_tasks = Enum.map(tasks, &if(&1 == checkpoint, do: wrong_checkpoint, else: &1))
      refute matching_checkpoint_index(altered_tasks, "remote_github")
      assert checkpoint_violations("remote_github", 2, nil, altered_tasks, File.cwd!()) != []
    end
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

    refute Enum.any?(
             automation_policy_violations(".planning/phases/73-twin-contract-and-baseline"),
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

  @tag :phase_77_03_task_1
  test "tracked artifact findings require path-specific ownership and ignore untracked controls" do
    root =
      Path.join(
        System.tmp_dir!(),
        "relyra-artifact-inventory-#{System.unique_integer([:positive])}"
      )

    tracked_paths = [
      "_build/generated.log",
      "deps/generated.txt",
      "node_modules/module/index.js",
      "playwright-report/index.html",
      "test-results/result.json",
      "coverage/coverage.out",
      ".DS_Store",
      "tmp/backup.bak",
      "tmp/source.orig"
    ]

    untracked_path = "test-results/phase-77-untracked-control.log"

    try do
      File.mkdir_p!(Path.join(root, "test/governance"))

      for path <- tracked_paths do
        File.mkdir_p!(Path.join(root, Path.dirname(path)))
        File.write!(Path.join(root, path), "tracked artifact control\n")
      end

      File.mkdir_p!(Path.join(root, "test-results"))
      File.write!(Path.join(root, "test/governance/milestone_scope_test.exs"), "fixture\n")
      File.write!(Path.join(root, untracked_path), "worktree-only control\n")

      {_, 0} = System.cmd("git", ["init", "--quiet", root])

      {_, 0} =
        System.cmd(
          "git",
          ["-C", root, "add", "-f", "--"] ++
            tracked_paths ++
            ["test/governance/milestone_scope_test.exs"]
        )

      {tracked_output, 0} = System.cmd("git", ["-C", root, "ls-files", "-z"])
      indexed_paths = String.split(tracked_output, <<0>>, trim: true)

      assert Enum.all?(tracked_paths, &(&1 in indexed_paths))
      refute untracked_path in indexed_paths

      unowned_baseline = artifact_control_baseline(tracked_paths)
      unowned_violations = baseline_violations(unowned_baseline, root)

      for path <- tracked_paths do
        assert Enum.any?(unowned_violations, fn violation ->
                 violation =~ "QUAL-73-005" and violation =~ path
               end),
               "#{path} must require exact path-specific ownership"
      end

      owned_baseline = artifact_control_baseline(tracked_paths, owned?: true)

      refute Enum.any?(baseline_violations(owned_baseline, root), fn violation ->
               violation =~ "QUAL-73-005" and
                 Enum.any?(tracked_paths, &String.contains?(violation, &1))
             end)
    after
      File.rm_rf!(root)
    end
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

  test "Phase 77 closures have current lane proof while critical and later ownership remain intact" do
    baseline = File.read!(@baseline_path)
    {_, rows} = baseline_rows(baseline)
    findings = Map.new(rows, &{&1["Finding ID"], &1})

    for {id, lanes} <- [
          {"QUAL-73-002", ["mix ci.docs", "mix ci.security"]},
          {"QUAL-73-003", ["mix ci.docs"]},
          {"QUAL-73-006", ["mix ci.docs"]}
        ] do
      row = findings[id]
      assert row["Blocker State"] == "resolved"
      assert row["Reproducible Evidence"] =~ "2026-09-26"

      for lane <- lanes do
        assert row["Reproducible Evidence"] =~ "`#{lane}`"
      end
    end

    critical = findings["RELYRA-2026-001"]
    assert critical["Blocker State"] == "resolved"
    assert critical["Reproducible Evidence"] =~ "adversarial and CI meta-gate proof"
    assert critical["Disposition"] =~ "configured-certificate trust path"

    later_owners = [
      {"PIPE-73-001", "Phase 79 release owner", "Phase 79", "remote_github blocking approval",
       "release-blocker", "Before v1.11 release"},
      {"PIPE-73-002", "Phase 78 CI owner", "Phase 78",
       "none unless required-check topology changes remotely", "disposition-required",
       "Phase 78 planning"},
      {"QUAL-73-005", "Phase 79 release owner", "Phase 79", "none", "deferred",
       "Before v1.11 release"}
    ]

    for {id, owner, target, approval, blocker, revisit} <- later_owners do
      row = findings[id]

      assert {row["Owner"], row["Target Phase"], row["Approval Class"], row["Blocker State"],
              row["Revisit Date"]} == {owner, target, approval, blocker, revisit}
    end

    phase_74 = File.read!(".planning/phases/74-clean-room-package-consumer/74-04-SUMMARY.md")
    assert phase_74 =~ "scripts/check_clean_room_consumer.sh --profile full"

    assert phase_74 =~
             "scripts/check_clean_room_consumer.sh --profile minimal --concurrency-check"

    assert phase_74 =~ "mix ci.evidence` — 127 tests, 0 failures"
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

  test "Phase 79 risk ledger covers every retained, deferred, and open-window item" do
    inventory =
      File.read!(".planning/phases/79-adopter-ready-closeout/79-INVENTORY.json")
      |> Jason.decode!()

    risks =
      File.read!(".planning/phases/79-adopter-ready-closeout/79-RISKS.json")
      |> Jason.decode!()

    closeout = File.read!(".planning/phases/79-adopter-ready-closeout/79-CLOSEOUT.md")
    remote_batch = File.read!(".planning/phases/79-adopter-ready-closeout/79-REMOTE-BATCH.md")
    inventory_report = File.read!(".planning/phases/79-adopter-ready-closeout/79-INVENTORY.md")
    desired_path = ".planning/phases/79-adopter-ready-closeout/79-PROTECTION-DESIRED.json"
    rollback_path = ".planning/phases/79-adopter-ready-closeout/79-PROTECTION-ROLLBACK.json"
    capture_path = ".planning/phases/79-adopter-ready-closeout/79-PROTECTION-CAPTURE.json"
    desired_bytes = File.read!(desired_path)
    rollback_bytes = File.read!(rollback_path)
    capture_bytes = File.read!(capture_path)
    capture = Jason.decode!(capture_bytes)
    desired = Jason.decode!(desired_bytes)
    rollback = Jason.decode!(rollback_bytes)
    capture_digest = :crypto.hash(:sha256, capture_bytes) |> Base.encode16(case: :lower)
    assert capture["capture_status"] == "incomplete"
    assert capture["resource"] == nil
    assert desired["schema"] == "phase79-protection-desired"
    assert desired["status"] == "blocked"
    assert desired["desired_payload"] == nil
    assert desired["source_capture_sha256"] == capture_digest
    assert rollback["source_capture_sha256"] == capture_digest

    {_, baseline} = baseline_rows(File.read!(@baseline_path))
    state_items = phase79_state_deferred_ids(File.read!(".planning/STATE.md"))
    window_items = phase79_open_window_ids(File.read!(".planning/WINDOWS.md"))
    expected_ids = Enum.map(baseline, & &1["Finding ID"]) ++ state_items ++ window_items
    identity = phase79_inventory_identity(inventory)

    phase79_owned_artifacts = [
      ".planning/phases/79-adopter-ready-closeout/79-CLOSEOUT.md",
      ".planning/ROADMAP.md",
      ".planning/phases/79-adopter-ready-closeout/79-INVENTORY.json",
      ".planning/phases/79-adopter-ready-closeout/79-INVENTORY.md",
      ".planning/phases/79-adopter-ready-closeout/79-PROTECTION-CAPTURE.json",
      ".planning/phases/79-adopter-ready-closeout/79-PROTECTION-DESIRED.json",
      ".planning/phases/79-adopter-ready-closeout/79-PROTECTION-ROLLBACK.json",
      ".planning/phases/79-adopter-ready-closeout/79-REMOTE-BATCH.md",
      ".planning/phases/79-adopter-ready-closeout/79-RISKS.json",
      ".planning/phases/79-adopter-ready-closeout/79-VALIDATION.md"
    ]

    proof_owned_paths = [
      ".planning/phases/73-twin-contract-and-baseline/73-RECONCILIATION-PROOF.json",
      ".planning/phases/73-twin-contract-and-baseline/73-SECURITY.md",
      ".planning/phases/73-twin-contract-and-baseline/73-VALIDATION.md",
      ".planning/phases/78-ci-efficiency-and-reliability/78-CLEAN-STATE-RECEIPT.json"
    ]

    tracked_edits = inventory["local"]["tracked_edits"]
    tracked_paths = Enum.map(tracked_edits, & &1["path"])

    expected_current_edits = Enum.reject(phase79_owned_artifacts, &(&1 == ".planning/ROADMAP.md"))
    assert Enum.all?(expected_current_edits, &(&1 in tracked_paths))

    assert Enum.all?(tracked_paths, fn path ->
             path in phase79_owned_artifacts or path in proof_owned_paths or
               path == ".planning/state.json" or
               path == ".planning/STATE.md" or
               path == ".planning/phases/79-adopter-ready-closeout/79-VALIDATION.md"
           end)

    assert Enum.all?(tracked_edits, fn item ->
             expected_owner =
               if item["path"] in [".planning/state.json", ".planning/STATE.md"],
                 do: "gsd-workflow",
                 else: "phase-79"

             item["owner"] == expected_owner and
               item["disposition"] == "preserve; no cleanup authority"
           end)

    assert Enum.any?(tracked_edits, fn item ->
             item["path"] in [".planning/state.json", ".planning/STATE.md"] and
               item["owner"] == "gsd-workflow"
           end)

    assert phase79_risk_violations(risks, expected_ids, identity) == []
    assert phase79_remote_batch_violations(remote_batch, identity) == []

    assert phase79_blocked_remote_violations(
             remote_batch,
             inventory,
             desired_bytes,
             rollback,
             rollback_bytes
           ) == []

    desired_digest = :crypto.hash(:sha256, desired_bytes) |> Base.encode16(case: :lower)

    tampered_desired_digest =
      String.replace(remote_batch, desired_digest, String.duplicate("0", 64))

    assert phase79_blocked_remote_violations(
             tampered_desired_digest,
             inventory,
             desired_bytes,
             rollback,
             rollback_bytes
           ) != []

    forged_desired =
      desired
      |> Map.put("desired_payload", %{"required_status_checks" => %{"contexts" => ["unsafe"]}})

    assert phase79_blocked_remote_violations(
             remote_batch,
             inventory,
             Jason.encode!(forged_desired),
             rollback,
             rollback_bytes
           ) != []

    forged_rollback =
      rollback
      |> Map.put("payload_available", true)
      |> Map.put("rollback_payload", %{"allow_deletions" => true})

    assert phase79_blocked_remote_violations(
             remote_batch,
             inventory,
             desired_bytes,
             forged_rollback,
             rollback_bytes
           ) != []

    unauthorized_batch =
      String.replace(
        remote_batch,
        "No GitHub write or workflow dispatch was prepared",
        "gh api -X PUT"
      )

    assert phase79_blocked_remote_violations(
             unauthorized_batch,
             inventory,
             desired_bytes,
             rollback,
             rollback_bytes
           ) != []

    stale_batch = String.replace(remote_batch, identity["main_sha"], String.duplicate("f", 40))

    assert phase79_blocked_remote_violations(
             stale_batch,
             inventory,
             desired_bytes,
             rollback,
             rollback_bytes
           ) != []

    assert inventory_report =~ identity["repository"]
    assert inventory_report =~ identity["ref"]
    assert inventory_report =~ identity["main_sha"]
    assert inventory_report =~ identity["observed_at"]

    assert closeout =~ "## Release readiness: BLOCKED"
    assert closeout =~ identity["repository"]
    assert closeout =~ identity["ref"]
    assert closeout =~ identity["main_sha"]
    assert closeout =~ identity["observed_at"]
    assert closeout =~ "[79-INVENTORY.json](79-INVENTORY.json)"
    assert closeout =~ "[79-RISKS.json](79-RISKS.json)"
    assert closeout =~ "[79-REMOTE-BATCH.md](79-REMOTE-BATCH.md)"
    assert closeout =~ "all nine mandatory lanes lack passing evidence"
    assert closeout =~ "canary"

    assert risks["items"]
           |> Enum.any?(&(&1["id"] == "PIPE-73-001" and &1["status"] == "release-blocker"))
  end

  test "Phase 79 risk and remote-batch contracts reject incomplete or stale evidence" do
    inventory =
      File.read!(".planning/phases/79-adopter-ready-closeout/79-INVENTORY.json")
      |> Jason.decode!()

    risks =
      File.read!(".planning/phases/79-adopter-ready-closeout/79-RISKS.json")
      |> Jason.decode!()

    batch = File.read!(".planning/phases/79-adopter-ready-closeout/79-REMOTE-BATCH.md")
    {_, baseline} = baseline_rows(File.read!(@baseline_path))

    expected_ids =
      Enum.map(baseline, & &1["Finding ID"]) ++
        phase79_state_deferred_ids(File.read!(".planning/STATE.md")) ++
        phase79_open_window_ids(File.read!(".planning/WINDOWS.md"))

    identity = phase79_inventory_identity(inventory)
    missing_owner = put_in(risks, ["items", Access.at(0), "owner"], "")
    missing_source = put_in(risks, ["items", Access.at(0), "source"], "")
    missing_severity = put_in(risks, ["items", Access.at(0), "severity"], "")
    missing_evidence = put_in(risks, ["items", Access.at(0), "evidence"], "")
    missing_status = put_in(risks, ["items", Access.at(0), "status"], "")
    missing_impact = put_in(risks, ["items", Access.at(0), "adopter_impact"], "")
    missing_demand = put_in(risks, ["items", Access.at(0), "demand_or_trigger"], "")
    missing_cost = put_in(risks, ["items", Access.at(0), "maintenance_cost"], "")
    missing_approval = put_in(risks, ["items", Access.at(0), "approval_boundary"], "")
    missing_revisit = put_in(risks, ["items", Access.at(0), "revisit"], "")

    omitted_window =
      update_in(risks["items"], &Enum.reject(&1, fn item -> item["id"] == "WINDOW-29" end))

    omitted_baseline =
      update_in(risks["items"], &Enum.reject(&1, fn item -> item["id"] == "QUAL-73-001" end))

    omitted_deferred =
      update_in(risks["items"], &Enum.reject(&1, fn item -> item["id"] == "AUTHN-POST-01" end))

    stale_source = put_in(risks, ["inventory_source", "main_sha"], String.duplicate("0", 40))
    high_not_blocking = put_in(risks, ["items", Access.at(1), "status"], "deferred")

    medium_not_disposed =
      put_in(risks, ["items", Access.at(-2), "status"], "deferred")

    missing_open_disposition = put_in(risks, ["items", Access.at(1), "open_disposition"], nil)

    for {candidate, expected_error} <- [
          {missing_owner, "owner"},
          {missing_source, "source"},
          {missing_severity, "severity"},
          {missing_evidence, "evidence"},
          {missing_status, "status"},
          {missing_impact, "adopter_impact"},
          {missing_demand, "demand_or_trigger"},
          {missing_cost, "maintenance_cost"},
          {missing_approval, "approval_boundary"},
          {missing_revisit, "revisit"},
          {omitted_window, "membership"},
          {omitted_baseline, "membership"},
          {omitted_deferred, "membership"},
          {stale_source, "inventory identity"},
          {high_not_blocking, "not blocked"},
          {medium_not_disposed, "written disposition"},
          {missing_open_disposition, "open disposition"}
        ] do
      violations = phase79_risk_violations(candidate, expected_ids, identity)
      assert Enum.any?(violations, &String.contains?(&1, expected_error)), inspect(violations)
    end

    altered_target = String.replace(batch, "szTheory/relyra", "other/repository", global: false)

    missing_reason =
      Regex.replace(
        ~r/## Why there is no proposal.*?## Authorization boundary/s,
        batch,
        "## Why there is no proposal\n\n## Authorization boundary"
      )

    assert Enum.any?(phase79_remote_batch_violations(altered_target, identity), &(&1 =~ "target"))
    assert Enum.any?(phase79_remote_batch_violations(missing_reason, identity), &(&1 =~ "reason"))

    payload = ~s({"required_status_checks":{"contexts":["fixture-context"]}})
    payload_digest = :crypto.hash(:sha256, payload) |> Base.encode16(case: :lower)

    proposal = """
    **Status:** exact proposal; not executed.
    - Target repository: `#{identity["repository"]}`
    - Target ref/resource: `#{identity["ref"]}` branch protection
    - Observed main SHA: `#{identity["main_sha"]}`
    - Observed at: `#{identity["observed_at"]}`
    - Captured current state: `{"required_status_checks":{"contexts":["current-context"]}}`
    - Desired state: `#{payload}`
    - Affected identifiers: `fixture-context`
    - Reason and least-privilege operation: add only the named fixture context
    - Read-only preflight: read-only query of the target and compare its current state
    - Proposed operation (not executed): apply the exact payload below in a separate plan
    - Exact payload JSON: `#{payload}`
    - Payload SHA-256: `#{payload_digest}`
    - Rollback: restore the exact captured current state above
    - Read-back assertion: query protection and compare exact fields
    - Resume signal: approval bound to `#{identity["repository"]}` `#{identity["ref"]}` and payload sha256 `#{payload_digest}`
    - Explicit approval: required in a separate plan after immediate same-target revalidation; if state differs, expire and renew approval
    """

    assert phase79_remote_batch_violations(proposal, identity) == []

    altered_payload = ~s({"required_status_checks":{"contexts":["other-context"]}})

    stale_payload =
      String.replace(
        proposal,
        "- Exact payload JSON: `#{payload}`",
        "- Exact payload JSON: `#{altered_payload}`",
        global: false
      )

    assert Enum.any?(phase79_remote_batch_violations(stale_payload, identity), &(&1 =~ "payload"))

    stale_resume_target =
      String.replace(
        proposal,
        "`#{identity["repository"]}` `#{identity["ref"]}` and payload sha256",
        "`#{identity["repository"]}` `refs/heads/release` and payload sha256",
        global: false
      )

    assert Enum.any?(
             phase79_remote_batch_violations(stale_resume_target, identity),
             &(&1 =~ "payload")
           )

    for {incomplete, expected_error} <- [
          {String.replace(
             proposal,
             "- Rollback: restore the exact captured current state above\n",
             "",
             global: false
           ), "rollback"},
          {String.replace(
             proposal,
             "- Read-back assertion: query protection and compare exact fields\n",
             "",
             global: false
           ), "read-back"},
          {String.replace(
             proposal,
             "- Exact payload JSON: `#{payload}`\n",
             "",
             global: false
           ), "payload"},
          {String.replace(
             proposal,
             "- Proposed operation (not executed): apply the exact payload below in a separate plan\n",
             "",
             global: false
           ), "operation"},
          {String.replace(
             proposal,
             "- Explicit approval: required in a separate plan after immediate same-target revalidation; if state differs, expire and renew approval\n",
             "- Explicit approval: acceptance evidence\n",
             global: false
           ), "approval"}
        ] do
      violations = phase79_remote_batch_violations(incomplete, identity)
      assert Enum.any?(violations, &String.contains?(&1, expected_error)), inspect(violations)
    end

    stale_target =
      String.replace(
        proposal,
        "- Target ref/resource: `#{identity["ref"]}` branch protection",
        "- Target ref/resource: `refs/heads/release` branch protection",
        global: false
      )

    assert Enum.any?(phase79_remote_batch_violations(stale_target, identity), &(&1 =~ "target"))

    malformed_no_action = String.replace(batch, "no mutation proposed", "mutation proposed")
    assert phase79_remote_batch_violations(malformed_no_action, identity) != []
  end

  @tag :phase79_artifact_state
  test "Phase 79 completion contract joins blocked artifacts and accepts a coherent ready fixture only" do
    current = phase79_current_artifact_state()
    assert phase79_completion_contract_violations(current) == []

    ready = phase79_ready_artifact_state_fixture()
    assert phase79_completion_contract_violations(ready) == []

    rest_graphql_disagreement =
      put_in(
        ready,
        [
          "capture",
          "sources",
          "graphql",
          "branch_protection",
          "rule",
          "requiredApprovingReviewCount"
        ],
        nil
      )

    null_rollback = put_in(ready, ["rollback", "rollback_payload"], nil)
    stale_capture_hash = put_in(ready, ["batch", "capture_sha256"], String.duplicate("0", 64))
    absent_lane = update_in(ready, ["ci_receipt", "lanes"], &Map.delete(&1, "mix ci.security"))
    fabricated_closeout = put_in(ready, ["protection_receipt", "status"], "partial")

    stale_hash_binding =
      put_in(ready, ["desired", "source_capture_sha256"], String.duplicate("f", 64))

    for invalid <- [
          rest_graphql_disagreement,
          null_rollback,
          stale_capture_hash,
          absent_lane,
          fabricated_closeout,
          stale_hash_binding
        ] do
      assert phase79_completion_contract_violations(invalid) != []
    end
  end

  @tag :phase79_publication_scope
  test "Phase 79 publication scope comes from the frozen source tree and rejects packet symlinks" do
    root = File.cwd!()

    temporary =
      Path.join(
        System.tmp_dir!(),
        "relyra-phase79-publication-scope-#{System.unique_integer([:positive])}"
      )

    phase_plan = Path.join(temporary, ".planning/phases/73-contract/73-01-PLAN.md")
    File.mkdir_p!(Path.dirname(phase_plan))
    File.write!(phase_plan, "---\nfiles_modified:\n  - governed.txt\n---\n# source plan\n")
    File.write!(Path.join(temporary, "governed.txt"), "in source tree\n")
    File.write!(Path.join(temporary, ".planning/STATE.md"), "state source\n")
    File.write!(Path.join(temporary, ".planning/state.json"), "state json source\n")

    on_exit(fn -> File.rm_rf!(temporary) end)

    assert {_output, 0} = System.cmd("git", ["init", "-q"], cd: temporary)

    assert {_output, 0} =
             System.cmd("git", ["config", "user.name", "Phase 79 Fixture"], cd: temporary)

    assert {_output, 0} =
             System.cmd("git", ["config", "user.email", "phase79@example.invalid"], cd: temporary)

    assert {_output, 0} = System.cmd("git", ["add", "."], cd: temporary)
    assert {_output, 0} = System.cmd("git", ["commit", "-qm", "source plan"], cd: temporary)
    assert {base_sha, 0} = System.cmd("git", ["rev-parse", "HEAD"], cd: temporary)

    File.write!(Path.join(temporary, "scope-approved.txt"), "accepted by frozen scope\n")
    assert {_output, 0} = System.cmd("git", ["add", "scope-approved.txt"], cd: temporary)

    assert {_output, 0} =
             System.cmd("git", ["commit", "-qm", "accepted scoped deliverable"], cd: temporary)

    assert {_output, 0} =
             System.cmd("git", ["commit", "--allow-empty", "-qm", "filtered mapped history"],
               cd: temporary
             )

    assert {source_sha, 0} = System.cmd("git", ["rev-parse", "HEAD"], cd: temporary)
    assert {empty_sha, 0} = System.cmd("git", ["rev-parse", "HEAD"], cd: temporary)

    File.write!(
      phase_plan,
      "---\nfiles_modified:\n  - governed.txt\n  - worktree-only.txt\n---\n# uncommitted edit\n"
    )

    File.write!(Path.join(temporary, ".planning/STATE.md"), "state edit\n")
    File.write!(Path.join(temporary, ".planning/state.json"), "state json edit\n")

    python = """
    import importlib.util, json, pathlib, sys
    spec = importlib.util.spec_from_file_location("publication", sys.argv[1])
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    root = pathlib.Path(sys.argv[2])
    accepted = {"scope-approved.txt": "include"}
    allowed, owners = module.planned_paths(root, sys.argv[3], accepted)
    inventory = module.worktree_inventory(pathlib.Path(sys.argv[2]))
    mapped, _diff, unknown = module.commit_manifest(
        root, sys.argv[4], sys.argv[3], allowed, owners, {sys.argv[5]}
    )
    unmapped, _diff, _unknown = module.commit_manifest(
        root, sys.argv[4], sys.argv[3], allowed, owners, set()
    )
    print(json.dumps({
        "governed": "governed.txt" in allowed,
        "worktree_only": "worktree-only.txt" in allowed,
        "accepted_scope": "scope-approved.txt" in allowed,
        "accepted_scope_owner": owners["scope-approved.txt"],
        "unclassified": unknown,
        "mapped_empty": mapped[-1]["classification"],
        "unmapped_empty": unmapped[-1]["classification"],
        "tracked_paths": sorted(item["path"] for item in inventory["tracked_dirty"]),
    }))
    """

    assert {output, 0} =
             System.cmd(
               "python3",
               [
                 "-c",
                 python,
                 Path.join(root, "scripts/prepare_phase79_publication.py"),
                 temporary,
                 String.trim(source_sha),
                 String.trim(base_sha),
                 String.trim(empty_sha)
               ],
               cd: root,
               stderr_to_stdout: true
             )

    assert Jason.decode!(String.trim(output)) == %{
             "governed" => true,
             "worktree_only" => false,
             "accepted_scope" => true,
             "accepted_scope_owner" => ["79-13-accepted-scope"],
             "unclassified" => [],
             "mapped_empty" => "filtered-history-preserved-empty",
             "unmapped_empty" => "unclassified",
             "tracked_paths" => [
               ".planning/STATE.md",
               ".planning/phases/73-contract/73-01-PLAN.md",
               ".planning/state.json"
             ]
           }

    phase_dir = Path.join(temporary, "phase")
    File.mkdir_p!(phase_dir)
    target = Path.join(phase_dir, "target.json")
    link = Path.join(phase_dir, "linked-packet.json")
    File.write!(target, "{}\n")
    File.ln_s!(target, link)

    assert {rejected, 1} =
             System.cmd(
               "python3",
               [
                 Path.join(root, "scripts/prepare_phase79_publication.py"),
                 "--verify",
                 link,
                 "--repo-root",
                 root,
                 "--phase-dir",
                 phase_dir
               ],
               cd: root,
               stderr_to_stdout: true
             )

    assert rejected =~ "non-symlink"
  end

  @tag :evidence_contract
  test "filtered history verifier self-test is a mandatory evidence contract" do
    script = Path.expand("../../scripts/prepare_phase79_filtered_candidate.py", __DIR__)

    assert {output, 0} = System.cmd("python3", [script, "--self-test"], stderr_to_stdout: true)
    assert output =~ "self_test"
  end

  @tag :evidence_contract
  @tag :phase79_filtered_candidate_provenance
  test "filtered proof-only commit remains verifiable after a normal merge descendant" do
    source_root = File.cwd!()
    source_sha = git_fixture!(source_root, ["rev-parse", "HEAD"]) |> String.trim()

    if git_file_at(source_root, "HEAD", @phase79_proof_path) == "" do
      assert :ok
    else
      temporary =
        Path.join(
          System.tmp_dir!(),
          "relyra-phase79-merged-proof-#{System.unique_integer([:positive])}"
        )

      checkout = Path.join(temporary, "checkout")
      File.mkdir_p!(temporary)
      on_exit(fn -> File.rm_rf!(temporary) end)

      assert {_clone_output, 0} =
               System.cmd(
                 "git",
                 ["clone", "--shared", "--no-checkout", source_root, checkout],
                 stderr_to_stdout: true
               )

      git_fixture!(checkout, ["config", "user.name", "Phase 79 Provenance Fixture"])
      git_fixture!(checkout, ["config", "user.email", "phase79@example.invalid"])
      tree = git_fixture!(checkout, ["rev-parse", "HEAD^{tree}"]) |> String.trim()

      assert {merge_sha, 0} =
               System.cmd(
                 "git",
                 [
                   "commit-tree",
                   tree,
                   "-p",
                   @phase79_base_sha,
                   "-p",
                   source_sha,
                   "-m",
                   "test(79-15): preserve proof ancestry through merge"
                 ],
                 cd: checkout,
                 stderr_to_stdout: true
               )

      merge_sha = String.trim(merge_sha)
      git_fixture!(checkout, ["update-ref", "refs/heads/phase79-merge-fixture", merge_sha])
      git_fixture!(checkout, ["checkout", "--detach", merge_sha])

      assert {:ok, %{"commit_map" => commit_map}} =
               validate_filtered_candidate_provenance(checkout)

      assert map_size(commit_map) == 613
    end
  end

  @tag :phase79_plan_handoff
  test "Phase 79 filtered-history plan handoff keeps the reviewed wave order" do
    script = Path.expand("../../scripts/verify_phase79_plan_contract.py", __DIR__)

    assert {output, 0} = System.cmd("python3", [script, "--handoff"], stderr_to_stdout: true)
    assert output =~ "handoff"
  end

  @tag :phase79_filtered_candidate_provenance
  test "filtered candidate provenance requires the proof/map branch and fails closed when proof is absent" do
    temporary =
      Path.join(
        System.tmp_dir!(),
        "relyra-phase79-filtered-provenance-#{System.unique_integer([:positive])}"
      )

    phase_dir = Path.join(temporary, ".planning/phases/79-adopter-ready-closeout")
    File.mkdir_p!(phase_dir)
    File.write!(Path.join(phase_dir, "79-FILTERED-CANDIDATE.json"), "{}\n")
    on_exit(fn -> File.rm_rf!(temporary) end)

    assert {:error, violations} = validate_filtered_candidate_provenance(temporary)
    assert Enum.any?(violations, &String.contains?(&1, "filtered-history proof contract"))
  end

  @tag :phase79_filtered_candidate_provenance
  test "malformed candidate manifest paths cannot fall back to legacy provenance" do
    temporary =
      Path.join(
        System.tmp_dir!(),
        "relyra-phase79-malformed-provenance-#{System.unique_integer([:positive])}"
      )

    phase_dir = Path.join(temporary, ".planning/phases/79-adopter-ready-closeout")
    manifest = Path.join(phase_dir, "79-FILTERED-CANDIDATE.json")
    File.mkdir_p!(manifest)
    on_exit(fn -> File.rm_rf!(temporary) end)

    assert {:error, violations} = validate_filtered_candidate_provenance(temporary)

    assert Enum.any?(
             violations,
             &String.contains?(&1, "candidate manifest must be a regular file")
           )
  end

  @tag :phase79_filtered_candidate_provenance
  test "filtered candidate resolves original abbreviated SUMMARY commit claims only through the unique map" do
    temporary =
      Path.join(
        System.tmp_dir!(),
        "relyra-phase79-filtered-summary-map-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(temporary)
    on_exit(fn -> File.rm_rf!(temporary) end)
    old_sha = String.duplicate("a", 40)
    filtered_sha = String.duplicate("b", 40)
    summary_path = Path.join(temporary, "summary.md")
    File.write!(summary_path, "## Task Commits\n1. **Task** — `aaaaaaaa`\n")

    assert {:ok, [^filtered_sha]} =
             summary_commit_cross_check(
               temporary,
               summary_path,
               [filtered_sha],
               %{old_sha => filtered_sha}
             )

    ambiguous_map = %{
      old_sha => filtered_sha,
      ("aaaaaaaa" <> String.duplicate("c", 32)) => filtered_sha
    }

    assert {:error, violations, _resolved} =
             summary_commit_cross_check(temporary, summary_path, [filtered_sha], ambiguous_map)

    assert Enum.any?(violations, &String.contains?(&1, "ambiguous original hash"))
  end

  test "Phase 79 fixture collector emits timestamped, source-bound inventory" do
    root = File.cwd!()

    temporary =
      Path.join(System.tmp_dir!(), "relyra-phase79-#{System.unique_integer([:positive])}")

    File.mkdir_p!(temporary)
    on_exit(fn -> File.rm_rf!(temporary) end)
    sha = String.duplicate("a", 40)
    fixture_path = Path.join(temporary, "fixture.json")
    output_path = Path.join(temporary, "inventory.json")
    File.write!(fixture_path, Jason.encode!(phase79_fixture(sha)))

    script = Path.join(root, "scripts/collect_phase79_inventory.py")

    assert {output, 0} =
             System.cmd("python3", [script, "--fixture", fixture_path, "--output", output_path],
               cd: root,
               stderr_to_stdout: true
             )

    assert output =~ "wrote"

    assert {verification, 0} =
             System.cmd("python3", [script, "--verify", output_path],
               cd: root,
               stderr_to_stdout: true
             )

    assert verification =~ sha
    receipt = output_path |> File.read!() |> Jason.decode!()
    assert receipt["observed_at"] =~ ~r/^\d{4}-\d{2}-\d{2}T.*Z$/
    assert receipt["repository"]["name"] == "szTheory/relyra"
    assert receipt["observation"]["main_sha"] == sha
    assert receipt["collection"]["complete"]

    assert Enum.any?(receipt["local"]["tracked_edits"], fn item ->
             item["path"] == ".planning/state.json" and item["owner"] == "gsd-workflow" and
               item["disposition"] == "preserve; no cleanup authority"
           end)

    assert Enum.any?(receipt["local"]["tracked_edits"], fn item ->
             item["path"] == ".planning/STATE.md" and item["owner"] == "gsd-workflow" and
               item["disposition"] == "preserve; no cleanup authority"
           end)

    protection = receipt["github"]["branch_protection"]
    protection_resource = protection["resource"]

    assert protection["capture_status"] == "complete"
    assert protection["source_endpoint"] == "branches/main/protection"
    assert protection["capture_errors"] == []
    assert protection["observed_fields"] == Enum.sort(["url" | Map.keys(protection_resource)])
    assert protection_resource["required_status_checks"]["strict"]

    assert Enum.sort(protection_resource["required_status_checks"]["contexts"]) ==
             protection["required_contexts"]

    assert Enum.sort_by(protection_resource["required_status_checks"]["checks"], & &1["context"]) ==
             Enum.map(protection["required_contexts"], fn context ->
               app_id =
                 case context do
                   "security (27, 1.19.5)" -> 123
                   "security (28, 1.19.5)" -> 124
                   "fleet-proxy-e2e" -> 125
                 end

               %{"context" => context, "app_id" => app_id}
             end)

    assert Enum.find(protection_resource["required_status_checks"]["checks"], fn check ->
             check["context"] == "security (27, 1.19.5)"
           end)["app_id"] == 123

    assert Enum.find(protection_resource["required_status_checks"]["checks"], fn check ->
             check["context"] == "security (28, 1.19.5)"
           end)["app_id"] == 124

    assert protection_resource["enforce_admins"] == %{"enabled" => true}

    assert protection_resource["required_pull_request_reviews"]["required_approving_review_count"] ==
             1

    assert protection_resource["required_pull_request_reviews"]["dismissal_restrictions"]["users"] ==
             [%{"id" => 5, "login" => "maintainer"}]

    assert protection_resource["restrictions"]["teams"] ==
             [%{"id" => 6, "slug" => "security", "name" => "Security Team"}]

    refute Jason.encode!(protection_resource) =~ "avatars.example"

    assert receipt["sources"]["branch_protection"]["completeness"] == "complete"

    tampered_protection =
      put_in(
        receipt,
        ["github", "branch_protection", "resource"],
        Map.delete(protection_resource, "allow_deletions")
      )

    tampered_path = Path.join(temporary, "tampered-protection.json")
    File.write!(tampered_path, Jason.encode!(tampered_protection))

    assert {tampered_output, 1} =
             System.cmd("python3", [script, "--verify", tampered_path],
               cd: root,
               stderr_to_stdout: true
             )

    assert tampered_output =~ "branch protection resource is incomplete"

    owned_paths = [
      ".planning/ROADMAP.md",
      ".planning/phases/73-twin-contract-and-baseline/73-RECONCILIATION-PROOF.json",
      ".planning/phases/73-twin-contract-and-baseline/73-SECURITY.md",
      ".planning/phases/73-twin-contract-and-baseline/73-VALIDATION.md",
      ".planning/phases/78-ci-efficiency-and-reliability/78-CLEAN-STATE-RECEIPT.json",
      ".planning/phases/79-adopter-ready-closeout/79-04-SUMMARY.md",
      ".planning/phases/79-adopter-ready-closeout/79-05-PLAN.md",
      ".planning/phases/79-adopter-ready-closeout/79-CLOSEOUT.md",
      ".planning/phases/79-adopter-ready-closeout/79-INVENTORY.json",
      ".planning/phases/79-adopter-ready-closeout/79-INVENTORY.md",
      ".planning/phases/79-adopter-ready-closeout/79-REMOTE-BATCH.md",
      ".planning/phases/79-adopter-ready-closeout/79-RISKS.json",
      ".planning/phases/79-adopter-ready-closeout/79-VALIDATION.md",
      "scripts/collect_phase79_inventory.py",
      "test/governance/milestone_scope_test.exs"
    ]

    classified_owned =
      Enum.filter(receipt["local"]["tracked_edits"], &(&1["path"] in owned_paths))

    assert Enum.map(classified_owned, & &1["path"]) |> Enum.sort() == Enum.sort(owned_paths)

    assert Enum.all?(classified_owned, fn item ->
             item["owner"] == "phase-79" and
               item["disposition"] == "preserve; no cleanup authority"
           end)

    phase79_payloads = [
      ".planning/phases/79-adopter-ready-closeout/79-PROTECTION-DESIRED.json",
      ".planning/phases/79-adopter-ready-closeout/79-PROTECTION-ROLLBACK.json",
      ".planning/phases/79-adopter-ready-closeout/79-PROTECTION-CAPTURE.json",
      ".planning/phases/79-adopter-ready-closeout/79-05-SUMMARY.md",
      ".planning/phases/79-adopter-ready-closeout/79-06-PLAN.md",
      "scripts/capture_phase79_protection.py"
    ]

    classified_payloads =
      Enum.filter(receipt["local"]["untracked_paths"], &(&1["path"] in phase79_payloads))

    assert Enum.map(classified_payloads, & &1["path"]) |> Enum.sort() ==
             Enum.sort(phase79_payloads)

    assert Enum.all?(classified_payloads, fn item ->
             item["owner"] == "phase-79" and
               item["disposition"] == "preserve; no cleanup authority"
           end)

    assert Enum.any?(receipt["local"]["tracked_edits"], fn item ->
             item["path"] == "README.md" and item["owner"] == "unknown" and
               item["disposition"] == "preserve; no cleanup authority"
           end)

    assert Enum.any?(receipt["local"]["untracked_paths"], fn item ->
             item["path"] == ".tool-versions" and item["owner"] == "maintainer"
           end)

    assert Enum.all?(receipt["sources"], fn {_name, source} ->
             source["endpoint"] != nil and source["page_count"] > 0 and
               source["completeness"] == "complete"
           end)

    assert Enum.any?(receipt["github"]["workflows"], &(&1["state"] == "active"))
    assert Enum.any?(receipt["github"]["workflows"], &(&1["state"] == "disabled"))

    assert Enum.any?(receipt["github"]["check_runs"], &(&1["name"] == "security (27, 1.19.5)"))
    assert Enum.any?(receipt["github"]["check_runs"], &(&1["name"] == "security (28, 1.19.5)"))
    assert receipt["github"]["mandatory_lanes"]["mix ci.security"]["state"] == "passed"

    assert receipt["github"]["branch_protection"]["context_results"]["fleet-proxy-e2e"]["state"] ==
             "passed"

    assert "security-gates.yml" in receipt["github"]["mandatory_lanes"]["mix ci.security"][
             "owners"
           ]

    refute "publish-hex.yml" in receipt["github"]["mandatory_lanes"]["mix ci.security"]["owners"]
    refute "release-please.yml" in receipt["github"]["mandatory_lanes"]["mix qa"]["owners"]
    refute receipt |> Jason.encode!() |> String.contains?("discard")
    assert Enum.all?(receipt["github"]["pull_requests"], &(not Map.has_key?(&1, "base")))
    assert length(receipt["github"]["issues"]) == 1
    assert receipt["github"]["canaries"] != []
    assert Enum.any?(receipt["github"]["canaries"], &(&1["source"] == "GitHub Actions check run"))
  end

  test "Phase 79 collector keeps incomplete evidence unknown and rejects tampered provenance" do
    root = File.cwd!()

    temporary =
      Path.join(
        System.tmp_dir!(),
        "relyra-phase79-negative-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(temporary)
    on_exit(fn -> File.rm_rf!(temporary) end)
    sha = String.duplicate("b", 40)
    fixture = phase79_fixture(sha)
    changed_sha = String.duplicate("c", 40)
    script = Path.join(root, "scripts/collect_phase79_inventory.py")

    changed_ref_fixture =
      put_in(fixture, ["github", "git/ref/heads/main?page=1"], %{
        "responses" => [
          %{"body" => %{"object" => %{"sha" => sha}}},
          %{"body" => %{"object" => %{"sha" => changed_sha}}}
        ]
      })

    denied_protection_fixture =
      put_in(fixture, ["github", "branches/main/protection?page=1", "status"], 403)

    missing_protection_setting_fixture =
      update_in(
        fixture,
        ["github", "branches/main/protection?page=1", "body"],
        &Map.delete(&1, "allow_fork_syncing")
      )

    unknown_protection_setting_fixture =
      put_in(
        fixture,
        ["github", "branches/main/protection?page=1", "body", "future_policy"],
        %{"enabled" => true}
      )

    unknown_nested_protection_setting_fixture =
      put_in(
        fixture,
        [
          "github",
          "branches/main/protection?page=1",
          "body",
          "required_status_checks",
          "future_setting_url"
        ],
        "https://example.invalid/future-policy"
      )

    oversized_protection_fixture =
      put_in(
        fixture,
        ["github", "branches/main/protection?page=1", "body", "restrictions", "teams"],
        [
          %{
            "id" => 7,
            "slug" => "oversized",
            "name" => String.duplicate("x", 8 * 1024 * 1024 + 1)
          }
        ]
      )

    truncated_fixture =
      fixture
      |> put_in(["github", "pulls?state=all?page=1", "next"], true)
      |> put_in(["github", "pulls?state=all?page=2"], %{"status" => 429, "body" => nil})

    unknown_workflow_fixture =
      update_in(
        fixture,
        ["github", "actions/workflows?page=1", "body", "workflows", Access.at(0)],
        fn workflow ->
          Map.delete(workflow, "state")
        end
      )

    empty_lane_fixture =
      fixture
      |> put_in(["github", "commits/#{sha}/check-runs?page=1", "body", "check_runs"], [])
      |> update_in(
        ["github", "actions/runs?head_sha=#{sha}?page=1", "body", "workflow_runs"],
        fn runs ->
          runs ++
            [
              %{
                "id" => 56,
                "name" => "Publish to Hex.pm",
                "path" => ".github/workflows/publish-hex.yml",
                "head_sha" => sha,
                "status" => "completed",
                "conclusion" => "success"
              },
              %{
                "id" => 57,
                "name" => "Release Please",
                "path" => ".github/workflows/release-please.yml",
                "head_sha" => sha,
                "status" => "completed",
                "conclusion" => "success"
              }
            ]
        end
      )

    non_owner_collision_fixture =
      update_in(
        fixture,
        ["github", "commits/#{sha}/check-runs?page=1", "body", "check_runs"],
        fn checks ->
          Enum.reject(checks, &(&1["name"] in ["security (27, 1.19.5)", "security (28, 1.19.5)"])) ++
            [
              %{
                "name" => "security (27, 1.19.5)",
                "head_sha" => sha,
                "check_suite_id" => 200,
                "status" => "completed",
                "conclusion" => "success"
              },
              %{
                "name" => "security (28, 1.19.5)",
                "head_sha" => sha,
                "check_suite_id" => 200,
                "status" => "completed",
                "conclusion" => "success"
              }
            ]
        end
      )
      |> update_in(
        ["github", "actions/runs?head_sha=#{sha}?page=1", "body", "workflow_runs"],
        fn runs ->
          runs ++
            [
              %{
                "id" => 200,
                "name" => "Security",
                "path" => ".github/workflows/release-please.yml",
                "head_sha" => sha,
                "check_suite_id" => 200,
                "status" => "completed",
                "conclusion" => "success"
              }
            ]
        end
      )

    aggregate_only_fixture =
      update_in(
        fixture,
        ["github", "commits/#{sha}/check-runs?page=1", "body", "check_runs"],
        fn checks ->
          Enum.reject(checks, &(&1["name"] in ["security (27, 1.19.5)", "security (28, 1.19.5)"]))
        end
      )

    later_failed_run_fixture =
      update_in(
        fixture,
        ["github", "commits/#{sha}/check-runs?page=1", "body", "check_runs"],
        fn checks ->
          checks ++
            [
              %{
                "id" => 601,
                "name" => "security (27, 1.19.5)",
                "head_sha" => sha,
                "check_suite_id" => 102,
                "status" => "completed",
                "conclusion" => "failure"
              },
              %{
                "id" => 602,
                "name" => "security (28, 1.19.5)",
                "head_sha" => sha,
                "check_suite_id" => 102,
                "status" => "completed",
                "conclusion" => "success"
              }
            ]
        end
      )
      |> update_in(
        ["github", "actions/runs?head_sha=#{sha}?page=1", "body", "workflow_runs"],
        fn runs ->
          runs ++
            [
              %{
                "id" => 58,
                "name" => "Security Gates",
                "workflow_id" => 1,
                "path" => ".github/workflows/security-gates.yml",
                "head_branch" => "main",
                "head_sha" => sha,
                "check_suite_id" => 102,
                "run_attempt" => 1,
                "run_started_at" => "2026-09-30T01:00:00Z",
                "status" => "completed",
                "conclusion" => "failure",
                "updated_at" => "2026-09-30T01:10:00Z"
              }
            ]
        end
      )
      |> put_in(
        ["github", "actions/runs/58/jobs?filter=latest?page=1"],
        %{
          "body" => %{
            "jobs" => [
              %{
                "id" => 6011,
                "name" => "security (27, 1.19.5)",
                "head_sha" => sha,
                "status" => "completed",
                "conclusion" => "failure",
                "check_run_url" => "https://api.github.com/repos/szTheory/relyra/check-runs/601"
              },
              %{
                "id" => 6012,
                "name" => "security (28, 1.19.5)",
                "head_sha" => sha,
                "status" => "completed",
                "conclusion" => "success",
                "check_run_url" => "https://api.github.com/repos/szTheory/relyra/check-runs/602"
              }
            ]
          }
        }
      )

    for {name, candidate} <- [
          {"changed-ref", changed_ref_fixture},
          {"denied-protection", denied_protection_fixture},
          {"missing-protection-setting", missing_protection_setting_fixture},
          {"unknown-protection-setting", unknown_protection_setting_fixture},
          {"unknown-nested-protection-setting", unknown_nested_protection_setting_fixture},
          {"oversized-protection", oversized_protection_fixture},
          {"truncated-pages", truncated_fixture},
          {"unknown-workflow", unknown_workflow_fixture},
          {"empty-lane", empty_lane_fixture},
          {"non-owner-collision", non_owner_collision_fixture},
          {"aggregate-only", aggregate_only_fixture},
          {"later-failed-run", later_failed_run_fixture}
        ] do
      fixture_path = Path.join(temporary, "#{name}.json")
      output_path = Path.join(temporary, "#{name}-inventory.json")
      File.write!(fixture_path, Jason.encode!(candidate))
      script = Path.join(root, "scripts/collect_phase79_inventory.py")

      assert {_, 0} =
               System.cmd("python3", [script, "--fixture", fixture_path, "--output", output_path],
                 cd: root,
                 stderr_to_stdout: true
               )

      receipt = output_path |> File.read!() |> Jason.decode!()
      refute receipt["collection"]["complete"]
      refute receipt["collection"]["readiness"] == "green"
      assert receipt["collection"]["gaps"] != []

      if name in [
           "missing-protection-setting",
           "unknown-protection-setting",
           "unknown-nested-protection-setting"
         ] do
        assert receipt["github"]["branch_protection"]["capture_status"] == "incomplete"
        assert receipt["sources"]["branch_protection"]["completeness"] == "incomplete"
        assert receipt["github"]["branch_protection"]["resource"] == nil
      end

      if name == "oversized-protection" do
        assert receipt["github"]["branch_protection"]["capture_status"] == "incomplete"

        assert Enum.any?(
                 receipt["github"]["branch_protection"]["capture_errors"],
                 &(&1 =~ "8 MiB")
               )
      end

      if name == "unknown-workflow",
        do: assert(Enum.any?(receipt["github"]["workflows"], &(&1["state"] == "unknown")))

      if name == "empty-lane",
        do: assert(receipt["github"]["mandatory_lanes"]["mix ci.security"]["state"] == "unknown")

      if name in ["non-owner-collision", "aggregate-only"],
        do: assert(receipt["github"]["mandatory_lanes"]["mix ci.security"]["state"] == "unknown")

      if name == "later-failed-run",
        do: assert(receipt["github"]["mandatory_lanes"]["mix ci.security"]["state"] == "failed")
    end

    foreign_context_collision =
      update_in(
        fixture,
        ["github", "commits/#{sha}/check-runs?page=1", "body", "check_runs"],
        fn checks ->
          Enum.map(checks, fn check ->
            if check["id"] == 90, do: Map.put(check, "conclusion", "failure"), else: check
          end) ++
            [
              %{
                "id" => 202,
                "name" => "fleet-proxy-e2e",
                "head_sha" => sha,
                "check_suite_id" => 101,
                "status" => "completed",
                "conclusion" => "success"
              }
            ]
        end
      )
      |> update_in(
        ["github", "actions/runs?head_sha=#{sha}?page=1", "body", "workflow_runs"],
        fn runs ->
          runs ++
            [
              %{
                "id" => 202,
                "name" => "Demo app CI",
                "path" => ".github/workflows/demo-app-ci.yml",
                "head_sha" => sha,
                "check_suite_id" => 101,
                "run_attempt" => 1,
                "run_started_at" => "2026-09-29T00:07:00Z",
                "status" => "completed",
                "conclusion" => "success"
              }
            ]
        end
      )
      |> put_in(
        ["github", "commits/#{sha}/status?page=1", "body", "statuses"],
        [%{"context" => "fleet-proxy-e2e", "state" => "success", "sha" => sha}]
      )

    status_context_collision =
      update_in(
        fixture,
        ["github", "commits/#{sha}/check-runs?page=1", "body", "check_runs"],
        &Enum.reject(&1, fn check -> check["name"] == "fleet-proxy-e2e" end)
      )
      |> update_in(
        ["github", "actions/runs?head_sha=#{sha}?page=1", "body", "workflow_runs"],
        &Enum.reject(&1, fn run -> run["id"] == 57 end)
      )
      |> put_in(
        ["github", "commits/#{sha}/status?page=1", "body", "statuses"],
        [%{"context" => "fleet-proxy-e2e", "state" => "success", "sha" => sha}]
      )

    for {name, candidate} <- [
          {"foreign-context-collision", foreign_context_collision},
          {"status-context-collision", status_context_collision}
        ] do
      fixture_path = Path.join(temporary, "#{name}.json")
      output_path = Path.join(temporary, "#{name}-inventory.json")
      File.write!(fixture_path, Jason.encode!(candidate))

      assert {_, 0} =
               System.cmd("python3", [script, "--fixture", fixture_path, "--output", output_path],
                 cd: root,
                 stderr_to_stdout: true
               )

      receipt = output_path |> File.read!() |> Jason.decode!()
      refute receipt["collection"]["complete"]

      expected_state = if name == "foreign-context-collision", do: "failed", else: "absent"

      assert receipt["github"]["branch_protection"]["context_results"]["fleet-proxy-e2e"]["state"] ==
               expected_state
    end

    for {name, origin} <- [
          {"unapproved-https", "https://gitlab.example/szTheory/relyra.git"},
          {"unapproved-ssh", "git@gitlab.example:szTheory/relyra.git"},
          {"malformed-port", "https://github.com:bad/szTheory/relyra.git"},
          {"malformed-host", "https://[github.com/szTheory/relyra.git"}
        ] do
      candidate = put_in(fixture, ["commands", "git remote get-url origin", "stdout"], origin)
      fixture_path = Path.join(temporary, "#{name}.json")
      output_path = Path.join(temporary, "#{name}-inventory.json")
      File.write!(fixture_path, Jason.encode!(candidate))

      assert {output, 1} =
               System.cmd("python3", [script, "--fixture", fixture_path, "--output", output_path],
                 cd: root,
                 stderr_to_stdout: true
               )

      assert output =~ "origin host is not an approved GitHub host"
      refute File.exists?(output_path)
    end

    credential_url_fixture =
      put_in(
        fixture,
        ["github", "commits/#{sha}/status?page=1", "body", "statuses"],
        [
          %{
            "context" => "external-userinfo",
            "state" => "success",
            "sha" => sha,
            "target_url" => "https://reader:secret@github.com/szTheory/relyra/check"
          },
          %{
            "context" => "external-query",
            "state" => "success",
            "sha" => sha,
            "target_url" => "https://github.com/szTheory/relyra/check?access_token=query-secret"
          }
        ]
      )

    credential_url_path = Path.join(temporary, "credential-url-fixture.json")
    credential_url_output = Path.join(temporary, "credential-url-inventory.json")
    File.write!(credential_url_path, Jason.encode!(credential_url_fixture))

    assert {_, 0} =
             System.cmd(
               "python3",
               [script, "--fixture", credential_url_path, "--output", credential_url_output],
               cd: root,
               stderr_to_stdout: true
             )

    credential_url_receipt = credential_url_output |> File.read!() |> Jason.decode!()
    encoded_credential_url_receipt = Jason.encode!(credential_url_receipt)
    refute encoded_credential_url_receipt =~ "reader:secret"
    refute encoded_credential_url_receipt =~ "query-secret"

    assert Enum.all?(credential_url_receipt["github"]["statuses"], fn status ->
             status["target_url"] == nil
           end)

    paginated_lane_fixture =
      fixture
      |> put_in(["github", "commits/#{sha}/check-runs?page=1", "next"], true)
      |> put_in(["github", "commits/#{sha}/check-runs?page=1", "body", "check_runs"], [])
      |> put_in(["github", "commits/#{sha}/check-runs?page=2"], %{
        "body" => %{
          "check_runs" => [
            %{
              "id" => 81,
              "name" => "security (27, 1.19.5)",
              "head_sha" => sha,
              "check_suite_id" => 100,
              "run_attempt" => 1,
              "run_started_at" => "2026-09-29T00:00:00Z",
              "status" => "completed",
              "conclusion" => "success"
            },
            %{
              "id" => 82,
              "name" => "security (28, 1.19.5)",
              "head_sha" => sha,
              "check_suite_id" => 100,
              "status" => "completed",
              "conclusion" => "success"
            }
          ]
        }
      })

    paginated_path = Path.join(temporary, "paginated-lane-fixture.json")
    paginated_output = Path.join(temporary, "paginated-lane-inventory.json")
    File.write!(paginated_path, Jason.encode!(paginated_lane_fixture))
    script = Path.join(root, "scripts/collect_phase79_inventory.py")

    assert {_, 0} =
             System.cmd(
               "python3",
               [script, "--fixture", paginated_path, "--output", paginated_output],
               cd: root,
               stderr_to_stdout: true
             )

    paginated_receipt = paginated_output |> File.read!() |> Jason.decode!()
    assert paginated_receipt["github"]["mandatory_lanes"]["mix ci.security"]["state"] == "passed"
    assert paginated_receipt["sources"]["check_runs"]["page_count"] == 2

    paginated_status_fixture =
      fixture
      |> put_in(["github", "commits/#{sha}/status?page=1", "next"], true)
      |> put_in(["github", "commits/#{sha}/status?page=2"], %{
        "body" => %{
          "statuses" => [%{"context" => "later-page-check", "state" => "success", "sha" => sha}]
        }
      })

    paginated_status_path = Path.join(temporary, "paginated-status-fixture.json")
    paginated_status_output = Path.join(temporary, "paginated-status-inventory.json")
    File.write!(paginated_status_path, Jason.encode!(paginated_status_fixture))

    assert {_, 0} =
             System.cmd(
               "python3",
               [script, "--fixture", paginated_status_path, "--output", paginated_status_output],
               cd: root,
               stderr_to_stdout: true
             )

    status_receipt = paginated_status_output |> File.read!() |> Jason.decode!()
    status_source = status_receipt["sources"]["statuses"]
    assert status_source["page_count"] == 2
    assert status_source["pages"] |> Enum.map(& &1["continuation"]) == [true, false]
    assert status_source["completeness"] == "complete"
    assert Enum.any?(status_receipt["github"]["statuses"], &(&1["context"] == "later-page-check"))

    fixture_path = Path.join(temporary, "tampered-fixture.json")
    output_path = Path.join(temporary, "tampered-inventory.json")
    File.write!(fixture_path, Jason.encode!(fixture))
    script = Path.join(root, "scripts/collect_phase79_inventory.py")

    assert {_, 0} =
             System.cmd("python3", [script, "--fixture", fixture_path, "--output", output_path],
               cd: root,
               stderr_to_stdout: true
             )

    receipt = output_path |> File.read!() |> Jason.decode!()

    referenced_check_id =
      receipt["github"]["mandatory_lanes"]["mix ci.security"]["evidence"]
      |> hd()
      |> Map.fetch!("check_run_id")

    failed_check_receipt =
      update_in(receipt, ["github", "check_runs"], fn checks ->
        Enum.map(checks, fn check ->
          if check["id"] == referenced_check_id do
            check |> Map.put("status", "completed") |> Map.put("conclusion", "failure")
          else
            check
          end
        end)
      end)

    File.write!(output_path, Jason.encode!(failed_check_receipt))

    assert {failed_check_verification, 1} =
             System.cmd("python3", [script, "--verify", output_path],
               cd: root,
               stderr_to_stdout: true
             )

    assert failed_check_verification =~ "passing state references a non-passing check run"

    malformed =
      update_in(receipt, ["sources", "pull_requests"], fn source ->
        Map.put(source, "pages", source["pages"] ++ [hd(source["pages"])])
        |> Map.put("page_count", 2)
      end)

    tampered =
      malformed
      |> put_in(["github", "check_runs", Access.at(0), "head_sha"], changed_sha)
      |> put_in(["github", "workflows", Access.at(0), "token"], "unallowlisted")

    File.write!(output_path, Jason.encode!(tampered))

    assert {verification, 1} =
             System.cmd("python3", [script, "--verify", output_path],
               cd: root,
               stderr_to_stdout: true
             )

    assert verification =~ "missing or duplicate pages"
    assert verification =~ "check run is not bound"
    assert verification =~ "unallowlisted fields"

    malformed_receipts = [
      {"top-level-array", []},
      {"repository-string", Map.put(tampered, "repository", "szTheory/relyra")},
      {"observation-array", Map.put(tampered, "observation", ["main", sha])}
    ]

    for {_name, malformed_receipt} <- malformed_receipts do
      File.write!(output_path, Jason.encode!(malformed_receipt))

      assert {malformed_output, 1} =
               System.cmd("python3", [script, "--verify", output_path],
                 cd: root,
                 stderr_to_stdout: true
               )

      assert malformed_output =~ "invalid inventory"
      refute malformed_output =~ "Traceback"
    end
  end

  test "Phase 79 composite protection capture binds sources and rejects conflicts" do
    root = File.cwd!()

    temporary =
      Path.join(
        System.tmp_dir!(),
        "relyra-phase79-protection-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(temporary)
    on_exit(fn -> File.rm_rf!(temporary) end)
    sha = String.duplicate("a", 40)
    script = Path.join(root, "scripts/capture_phase79_protection.py")
    fixture = phase79_protection_fixture(sha)

    run_capture = fn name, input ->
      fixture_path = Path.join(temporary, "#{name}-fixture.json")
      output_path = Path.join(temporary, "#{name}-capture.json")
      File.write!(fixture_path, Jason.encode!(input))

      assert {output, 0} =
               System.cmd("python3", [script, "--fixture", fixture_path, "--output", output_path],
                 cd: root,
                 stderr_to_stdout: true
               )

      assert output =~ "wrote"
      receipt = output_path |> File.read!() |> Jason.decode!()
      {receipt, output_path}
    end

    {complete, complete_path} = run_capture.(:complete, fixture)
    assert complete["capture_status"] == "complete"
    assert complete["main_sha"] == sha
    assert complete["capture_errors"] == []

    assert complete["resource"]["required_pull_request_reviews"][
             "required_approving_review_count"
           ] == 1

    assert complete["resource"]["required_pull_request_reviews"]["dismissal_restrictions"] == %{
             "apps" => [],
             "teams" => [],
             "users" => []
           }

    assert complete["writable_payload"]["required_status_checks"]["checks"] == [
             %{"app_id" => 15368, "context" => "security (27, 1.19.5)"},
             %{"app_id" => 15368, "context" => "security (28, 1.19.5)"}
           ]

    assert complete["sources"]["fleet_check_run"]["app_ids"] == [15368]

    assert {verification, 0} =
             System.cmd("python3", [script, "--verify", complete_path],
               cd: root,
               stderr_to_stdout: true
             )

    assert verification =~ "valid protection capture: complete"

    changed_sha = String.duplicate("b", 40)

    shifted_ref =
      put_in(
        fixture,
        ["rest", "main-ref", "responses", Access.at(1), "body", "object", "sha"],
        changed_sha
      )

    conflicting_review =
      fixture
      |> put_in(
        [
          "graphql",
          "protection",
          "body",
          "data",
          "repository",
          "ref",
          "branchProtectionRule",
          "requiredApprovingReviewCount"
        ],
        nil
      )
      |> put_in(
        [
          "graphql",
          "protection",
          "body",
          "data",
          "repository",
          "ref",
          "branchProtectionRule",
          "requiresApprovingReviews"
        ],
        false
      )

    generic_restriction_404 =
      put_in(fixture, ["rest", "branches/main/protection/restrictions", "status"], 404)
      |> put_in(
        ["rest", "branches/main/protection/restrictions", "body", "message"],
        "Branch not found"
      )

    unpaged_allowances =
      put_in(
        fixture,
        [
          "graphql",
          "protection",
          "body",
          "data",
          "repository",
          "ref",
          "branchProtectionRule",
          "reviewDismissalAllowances",
          "pageInfo",
          "hasNextPage"
        ],
        true
      )

    nonempty_unrestricted_allowances =
      put_in(
        fixture,
        [
          "graphql",
          "protection",
          "body",
          "data",
          "repository",
          "ref",
          "branchProtectionRule",
          "pushAllowances",
          "nodes"
        ],
        [%{"actor" => %{"__typename" => "User", "login" => "security-bot"}}]
      )
      |> put_in(
        [
          "graphql",
          "protection",
          "body",
          "data",
          "repository",
          "ref",
          "branchProtectionRule",
          "pushAllowances",
          "totalCount"
        ],
        1
      )

    unknown_setting =
      put_in(
        fixture,
        ["rest", "branches/main/protection", "body", "future_protection_mode"],
        true
      )

    for {name, candidate, expected_error} <- [
          {:shifted_ref, shifted_ref, "main ref changed"},
          {:conflicting_review, conflicting_review, "conflict"},
          {:generic_404, generic_restriction_404, "recognized explicit state"},
          {:unpaged_allowances, unpaged_allowances, "connection is incomplete"},
          {:nonempty_allowances, nonempty_unrestricted_allowances, "conflict"},
          {:unknown_setting, unknown_setting, "unknown settings"}
        ] do
      {incomplete, _path} = run_capture.(name, candidate)
      assert incomplete["capture_status"] == "incomplete"
      assert incomplete["resource"] == nil
      assert Enum.any?(incomplete["capture_errors"], &String.contains?(&1, expected_error))
    end

    tampered =
      put_in(
        complete,
        ["resource", "required_pull_request_reviews", "required_approving_review_count"],
        2
      )

    File.write!(complete_path, Jason.encode!(tampered))

    assert {invalid, 1} =
             System.cmd("python3", [script, "--verify", complete_path],
               cd: root,
               stderr_to_stdout: true
             )

    assert invalid =~ "capture source digest" or invalid =~ "capture resource"
  end

  test "Phase 79 batch builder emits exact deltas only from consistent evidence" do
    root = File.cwd!()

    temporary =
      Path.join(System.tmp_dir!(), "relyra-phase79-batch-#{System.unique_integer([:positive])}")

    File.mkdir_p!(temporary)
    on_exit(fn -> File.rm_rf!(temporary) end)
    sha = String.duplicate("a", 40)
    inventory_fixture = Path.join(temporary, "inventory-fixture.json")
    inventory_path = Path.join(temporary, "inventory.json")
    capture_fixture_path = Path.join(temporary, "capture-fixture.json")
    capture_path = Path.join(temporary, "capture.json")
    inventory_script = Path.join(root, "scripts/collect_phase79_inventory.py")
    capture_script = Path.join(root, "scripts/capture_phase79_protection.py")
    builder = Path.join(root, "scripts/prepare_phase79_batch.py")
    File.write!(inventory_fixture, Jason.encode!(phase79_fixture(sha)))

    assert {_inventory_output, 0} =
             System.cmd(
               "python3",
               [inventory_script, "--fixture", inventory_fixture, "--output", inventory_path],
               cd: root,
               stderr_to_stdout: true
             )

    inventory = inventory_path |> File.read!() |> Jason.decode!()
    capture_fixture = phase79_protection_fixture(sha)
    File.write!(capture_fixture_path, Jason.encode!(capture_fixture))

    assert {_capture_output, 0} =
             System.cmd(
               "python3",
               [capture_script, "--fixture", capture_fixture_path, "--output", capture_path],
               cd: root,
               stderr_to_stdout: true
             )

    capture_receipt = capture_path |> File.read!() |> Jason.decode!()
    current_contexts = capture_receipt["resource"]["required_status_checks"]["contexts"]

    inventory_resource =
      capture_receipt["resource"]
      |> Enum.map(fn {key, value} ->
        if key in ~w(allow_deletions allow_force_pushes allow_fork_syncing block_creations enforce_admins lock_branch required_conversation_resolution required_linear_history required_signatures) and
             is_boolean(value) do
          {key, %{"enabled" => value}}
        else
          {key, value}
        end
      end)
      |> Map.new()
      |> update_in(["required_pull_request_reviews"], fn reviews ->
        if is_map(reviews),
          do: Map.delete(reviews, "bypass_pull_request_allowances"),
          else: reviews
      end)

    inventory =
      inventory
      |> put_in(["github", "branch_protection", "resource"], inventory_resource)
      |> put_in(["github", "branch_protection", "required_contexts"], current_contexts)
      |> put_in(["github", "branch_protection", "context_match"], false)
      |> put_in(["collection", "complete"], false)
      |> put_in(["collection", "readiness"], "unknown")
      |> update_in(
        ["collection", "gaps"],
        &Enum.uniq(["live required contexts differ from repository expected contexts" | &1])
      )
      |> put_in(
        ["github", "branch_protection", "observed_fields"],
        Enum.sort(["url" | Map.keys(inventory_resource)])
      )

    File.write!(inventory_path, Jason.encode!(inventory))

    # Keep this fixture honest under the production inventory validator.
    assert {_verify_inventory, 0} =
             System.cmd("python3", [inventory_script, "--verify", inventory_path],
               cd: root,
               stderr_to_stdout: true
             )

    output_dir = Path.join(temporary, "artifacts")
    args = ["--capture", capture_path, "--inventory", inventory_path, "--output-dir", output_dir]

    assert {builder_output, 0} =
             System.cmd("python3", [builder | args], cd: root, stderr_to_stdout: true)

    assert builder_output =~ "wrote Phase 79 batch artifacts: complete"

    desired =
      Path.join(output_dir, "79-PROTECTION-DESIRED.json") |> File.read!() |> Jason.decode!()

    rollback =
      Path.join(output_dir, "79-PROTECTION-ROLLBACK.json") |> File.read!() |> Jason.decode!()

    batch_path = Path.join(output_dir, "79-REMOTE-BATCH.md")

    assert rollback["rollback_payload"] == capture_receipt["writable_payload"]

    rollback_payload = rollback["rollback_payload"]
    app_id = capture_receipt["sources"]["fleet_check_run"]["app_ids"] |> hd()

    expected_desired =
      Map.update!(rollback_payload, "required_status_checks", fn required_checks ->
        required_checks
        |> Map.update!("checks", fn checks ->
          Enum.sort_by(
            checks ++ [%{"app_id" => app_id, "context" => "fleet-proxy-e2e"}],
            & &1["context"]
          )
        end)
        |> Map.update!("contexts", fn contexts ->
          Enum.sort(contexts ++ ["fleet-proxy-e2e"])
        end)
      end)

    assert desired["desired_payload"] == expected_desired
    assert batch_path |> File.read!() =~ "no remote operation was executed"

    assert {verify_output, 0} =
             System.cmd("python3", [builder | args ++ ["--verify"]],
               cd: root,
               stderr_to_stdout: true
             )

    assert verify_output =~ "valid Phase 79 batch artifacts: complete"

    conflict_fixture =
      put_in(
        capture_fixture,
        [
          "graphql",
          "protection",
          "body",
          "data",
          "repository",
          "ref",
          "branchProtectionRule",
          "requiredApprovingReviewCount"
        ],
        nil
      )
      |> put_in(
        [
          "graphql",
          "protection",
          "body",
          "data",
          "repository",
          "ref",
          "branchProtectionRule",
          "requiresApprovingReviews"
        ],
        false
      )

    conflict_fixture_path = Path.join(temporary, "conflict-fixture.json")
    conflict_capture_path = Path.join(temporary, "conflict-capture.json")
    conflict_output = Path.join(temporary, "conflict-artifacts")
    File.write!(conflict_fixture_path, Jason.encode!(conflict_fixture))

    assert {_conflict_output, 0} =
             System.cmd(
               "python3",
               [
                 capture_script,
                 "--fixture",
                 conflict_fixture_path,
                 "--output",
                 conflict_capture_path
               ],
               cd: root,
               stderr_to_stdout: true
             )

    assert {_blocked_output, 0} =
             System.cmd(
               "python3",
               [
                 builder,
                 "--capture",
                 conflict_capture_path,
                 "--inventory",
                 inventory_path,
                 "--output-dir",
                 conflict_output
               ],
               cd: root,
               stderr_to_stdout: true
             )

    blocked =
      Path.join(conflict_output, "79-PROTECTION-DESIRED.json") |> File.read!() |> Jason.decode!()

    assert blocked["desired_payload"] == nil
    assert blocked["payload_available"] == false

    assert Path.join(conflict_output, "79-PROTECTION-ROLLBACK.json")
           |> File.read!()
           |> Jason.decode!()
           |> Map.get("rollback_payload") == nil

    assert Path.join(conflict_output, "79-REMOTE-BATCH.md") |> File.read!() =~
             "No Action Proposed"

    assert_blocked = fn name, capture_input, inventory_input ->
      destination = Path.join(temporary, "#{name}-artifacts")

      assert {_output, 0} =
               System.cmd(
                 "python3",
                 [
                   builder,
                   "--capture",
                   capture_input,
                   "--inventory",
                   inventory_input,
                   "--output-dir",
                   destination
                 ],
                 cd: root,
                 stderr_to_stdout: true
               )

      desired =
        Path.join(destination, "79-PROTECTION-DESIRED.json") |> File.read!() |> Jason.decode!()

      assert desired["payload_available"] == false
      assert desired["desired_payload"] == nil

      rollback =
        Path.join(destination, "79-PROTECTION-ROLLBACK.json")
        |> File.read!()
        |> Jason.decode!()

      assert rollback["payload_available"] == false
      assert rollback["rollback_payload"] == nil

      assert Path.join(destination, "79-REMOTE-BATCH.md") |> File.read!() =~
               "No Action Proposed"
    end

    tampered_capture = Map.put(capture_receipt, "unexpected", true)
    tampered_path = Path.join(temporary, "tampered-capture.json")
    File.write!(tampered_path, Jason.encode!(tampered_capture))
    assert_blocked.("tampered-capture", tampered_path, inventory_path)

    errored_capture = Map.put(capture_receipt, "capture_errors", ["synthetic capture failure"])
    errored_path = Path.join(temporary, "errored-capture.json")
    File.write!(errored_path, Jason.encode!(errored_capture))
    assert_blocked.("errored-capture", errored_path, inventory_path)

    boolean_app_capture_path = Path.join(temporary, "boolean-app-capture.json")

    File.write!(boolean_app_capture_path, Jason.encode!(capture_receipt))

    forge_boolean_app_id = """
    import hashlib, json, pathlib, sys
    path = pathlib.Path(sys.argv[1])
    receipt = json.loads(path.read_text(encoding="utf-8"))
    receipt["sources"]["fleet_check_run"]["app_ids"] = [True]
    source = json.dumps(receipt["sources"], sort_keys=True, separators=(",", ":"), ensure_ascii=False)
    receipt["source_digest"] = hashlib.sha256(source.encode("utf-8")).hexdigest()
    path.write_text(json.dumps(receipt, indent=2, sort_keys=True) + "\\n", encoding="utf-8")
    """

    assert {_forge_output, 0} =
             System.cmd("python3", ["-c", forge_boolean_app_id, boolean_app_capture_path],
               cd: root,
               stderr_to_stdout: true
             )

    assert_blocked.("boolean-app-id", boolean_app_capture_path, inventory_path)

    malformed_capture = Map.put(capture_receipt, "capture_errors", nil)
    malformed_path = Path.join(temporary, "malformed-capture.json")
    malformed_output_dir = Path.join(temporary, "malformed-artifacts")
    File.write!(malformed_path, Jason.encode!(malformed_capture))

    assert {malformed_output, 1} =
             System.cmd(
               "python3",
               [
                 builder,
                 "--capture",
                 malformed_path,
                 "--inventory",
                 inventory_path,
                 "--output-dir",
                 malformed_output_dir
               ],
               cd: root,
               stderr_to_stdout: true
             )

    assert malformed_output =~ "Phase 79 batch blocked: malformed capture or inventory shape"
    refute malformed_output =~ "Traceback"
    refute File.exists?(Path.join(malformed_output_dir, "79-PROTECTION-DESIRED.json"))

    invalid_utf8_path = Path.join(temporary, "invalid-utf8-capture.json")
    invalid_utf8_output_dir = Path.join(temporary, "invalid-utf8-artifacts")
    File.write!(invalid_utf8_path, <<255, 123, 125>>)

    assert {invalid_utf8_output, 1} =
             System.cmd(
               "python3",
               [
                 builder,
                 "--capture",
                 invalid_utf8_path,
                 "--inventory",
                 inventory_path,
                 "--output-dir",
                 invalid_utf8_output_dir
               ],
               cd: root,
               stderr_to_stdout: true
             )

    assert invalid_utf8_output =~ "Phase 79 batch blocked: invalid protection capture JSON"
    refute invalid_utf8_output =~ "Traceback"
    refute File.exists?(Path.join(invalid_utf8_output_dir, "79-PROTECTION-DESIRED.json"))

    ref_drift_capture = Map.put(capture_receipt, "main_sha", String.duplicate("b", 40))
    ref_drift_path = Path.join(temporary, "ref-drift-capture.json")
    File.write!(ref_drift_path, Jason.encode!(ref_drift_capture))
    assert_blocked.("ref-drift", ref_drift_path, inventory_path)

    stale_inventory =
      put_in(inventory, ["observation", "main_sha"], String.duplicate("b", 40))

    stale_inventory_path = Path.join(temporary, "stale-inventory.json")
    File.write!(stale_inventory_path, Jason.encode!(stale_inventory))
    assert_blocked.("stale-inventory", capture_path, stale_inventory_path)

    missing_app_fixture =
      put_in(
        capture_fixture,
        [
          "rest",
          "commits/#{sha}/check-runs?page=1",
          "body",
          "check_runs",
          Access.at(0),
          "app",
          "id"
        ],
        nil
      )

    missing_app_fixture_path = Path.join(temporary, "missing-app-fixture.json")
    missing_app_capture_path = Path.join(temporary, "missing-app-capture.json")
    File.write!(missing_app_fixture_path, Jason.encode!(missing_app_fixture))

    assert {_missing_app_output, 0} =
             System.cmd(
               "python3",
               [
                 capture_script,
                 "--fixture",
                 missing_app_fixture_path,
                 "--output",
                 missing_app_capture_path
               ],
               cd: root,
               stderr_to_stdout: true
             )

    assert_blocked.("missing-app", missing_app_capture_path, inventory_path)

    tampered_desired = Path.join(output_dir, "79-PROTECTION-DESIRED.json")
    File.write!(tampered_desired, "{}")

    assert {altered_output, 1} =
             System.cmd("python3", [builder | args ++ ["--verify"]],
               cd: root,
               stderr_to_stdout: true
             )

    assert altered_output =~ "altered, or stale"
  end

  @tag :phase79_ci_preflight
  test "Phase 79 CI preflight records absent current-main evidence as pending" do
    root = File.cwd!()
    unique = System.unique_integer([:positive])
    temporary = Path.join(System.tmp_dir!(), "relyra-phase79-ci-preflight-#{unique}")
    phase_dir = Path.join(temporary, "phase")
    fixture_dir = Path.join(temporary, "fixtures")
    File.mkdir_p!(phase_dir)
    File.mkdir_p!(fixture_dir)
    on_exit(fn -> File.rm_rf!(temporary) end)

    sha = String.duplicate("a", 40)

    fixture = %{
      "repository" => "szTheory/relyra",
      "ref" => "refs/heads/main",
      "main_sha" => sha,
      "enabled_workflows" => [
        %{"id" => 10, "path" => ".github/workflows/security-gates.yml", "state" => "active"},
        %{"id" => 20, "path" => ".github/workflows/fleet-proxy-e2e.yml", "state" => "active"}
      ],
      "workflow_runs" => [],
      "workflow_jobs" => [],
      "check_runs" => [],
      "fleet_context" => %{"name" => "fleet-proxy-e2e", "sha" => sha, "state" => "absent"},
      "receipts" => phase79_ci_observation(sha, false)["receipts"]
    }

    File.write!(Path.join(fixture_dir, "ci-preflight.json"), Jason.encode!(fixture))

    script = Path.join(root, "scripts/verify_phase79_transaction.py")

    {output, status} =
      System.cmd(
        "python3",
        [
          script,
          "--stage",
          "ci-preflight",
          "--phase-dir",
          phase_dir,
          "--fixture-dir",
          fixture_dir
        ],
        cd: root,
        stderr_to_stdout: true
      )

    assert status == 0, "expected an inert pending CI packet, got exit #{status}: #{output}"
    assert output =~ "pending"

    packet =
      Path.join(phase_dir, "79-CI-DISPATCH-PACKET.json")
      |> File.read!()
      |> Jason.decode!()

    assert packet["status"] == "pending"

    assert packet["target"] == %{
             "repository" => "szTheory/relyra",
             "ref" => "refs/heads/main",
             "sha" => sha
           }

    assert packet["dispatch"]["action"] == "workflow_dispatch"

    assert packet["dispatch"]["workflows"] == [
             ".github/workflows/fleet-proxy-e2e.yml",
             ".github/workflows/security-gates.yml"
           ]

    refute packet["dispatch"]["performed"]

    assert packet["missing_owner_runs"] == [
             ".github/workflows/fleet-proxy-e2e.yml",
             ".github/workflows/security-gates.yml"
           ]
  end

  @tag :phase79_ci_result
  test "Phase 79 CI result rejects absent evidence and accepts exact same-SHA owner identities" do
    root = File.cwd!()
    unique = System.unique_integer([:positive])
    temporary = Path.join(System.tmp_dir!(), "relyra-phase79-ci-result-#{unique}")
    phase_dir = Path.join(temporary, "phase")
    fixture_dir = Path.join(temporary, "fixtures")
    File.mkdir_p!(phase_dir)
    File.mkdir_p!(fixture_dir)
    on_exit(fn -> File.rm_rf!(temporary) end)

    sha = String.duplicate("a", 40)
    pending = phase79_ci_observation(sha, false)
    fixture_path = Path.join(fixture_dir, "ci-preflight.json")
    File.write!(fixture_path, Jason.encode!(pending))

    script = Path.join(root, "scripts/verify_phase79_transaction.py")

    assert {_output, 0} =
             System.cmd(
               "python3",
               [
                 script,
                 "--stage",
                 "ci-preflight",
                 "--phase-dir",
                 phase_dir,
                 "--fixture-dir",
                 fixture_dir
               ],
               cd: root,
               stderr_to_stdout: true
             )

    assert {missing_output, 1} =
             System.cmd(
               "python3",
               [
                 script,
                 "--stage",
                 "ci-result",
                 "--phase-dir",
                 phase_dir,
                 "--fixture-dir",
                 fixture_dir
               ],
               cd: root,
               stderr_to_stdout: true
             )

    assert missing_output =~ "pending CI dispatch requires explicit approval"
    refute File.exists?(Path.join(phase_dir, "79-MAIN-CI-RECEIPT.json"))

    pending_packet_path = Path.join(phase_dir, "79-CI-DISPATCH-PACKET.json")
    pending_packet = pending_packet_path |> File.read!() |> Jason.decode!()

    pending_packet =
      Map.put(pending_packet, "approval", %{
        "checkpoint_id" => "79-10-ci-dispatch",
        "packet_sha256" => pending_packet["packet_sha256"],
        "response" => "approved",
        "scope" => pending_packet["dispatch"]["requests"]
      })

    File.write!(pending_packet_path, Jason.encode!(pending_packet))
    File.write!(Path.join(fixture_dir, "ci-result-preflight.json"), Jason.encode!(pending))

    File.write!(
      Path.join(fixture_dir, "ci-dispatch.json"),
      Jason.encode!(%{
        "requests" => pending_packet["dispatch"]["requests"],
        "responses" =>
          Enum.map(pending_packet["dispatch"]["requests"], fn request ->
            %{"workflow_id" => request["workflow_id"], "status_code" => 204}
          end)
      })
    )

    passed = phase79_ci_observation(sha, true)
    File.write!(Path.join(fixture_dir, "ci-result.json"), Jason.encode!(passed))

    assert {dispatch_output, 0} =
             System.cmd(
               "python3",
               [
                 script,
                 "--stage",
                 "ci-result",
                 "--phase-dir",
                 phase_dir,
                 "--fixture-dir",
                 fixture_dir
               ],
               cd: root,
               stderr_to_stdout: true
             )

    assert dispatch_output =~ "complete"

    dispatch_receipt =
      Path.join(phase_dir, "79-MAIN-CI-RECEIPT.json")
      |> File.read!()
      |> Jason.decode!()

    assert length(dispatch_receipt["dispatch_responses"]) == 2
    assert length(dispatch_receipt["dispatch_run_identities"]) == 2
    assert dispatch_receipt["approval"]["checkpoint_id"] == "79-10-ci-dispatch"
    File.rm!(Path.join(phase_dir, "79-MAIN-CI-RECEIPT.json"))

    passed = phase79_ci_observation(sha, true)
    File.write!(fixture_path, Jason.encode!(passed))

    assert {_output, 0} =
             System.cmd(
               "python3",
               [
                 script,
                 "--stage",
                 "ci-preflight",
                 "--phase-dir",
                 phase_dir,
                 "--fixture-dir",
                 fixture_dir
               ],
               cd: root,
               stderr_to_stdout: true
             )

    File.write!(Path.join(fixture_dir, "ci-result.json"), Jason.encode!(passed))

    assert {result_output, 0} =
             System.cmd(
               "python3",
               [
                 script,
                 "--stage",
                 "ci-result",
                 "--phase-dir",
                 phase_dir,
                 "--fixture-dir",
                 fixture_dir
               ],
               cd: root,
               stderr_to_stdout: true
             )

    assert result_output =~ "complete"

    receipt =
      Path.join(phase_dir, "79-MAIN-CI-RECEIPT.json")
      |> File.read!()
      |> Jason.decode!()

    assert receipt["target"]["sha"] == sha
    assert map_size(receipt["lanes"]) == 9
    assert receipt["fleet_context"]["state"] == "passed"
    assert receipt["independent_readback"]

    wrong_owner =
      update_in(passed, ["check_runs", Access.at(0), "workflow_path"], fn _ ->
        ".github/workflows/fleet-proxy-e2e.yml"
      end)

    File.write!(Path.join(fixture_dir, "ci-result.json"), Jason.encode!(wrong_owner))
    File.rm!(Path.join(phase_dir, "79-MAIN-CI-RECEIPT.json"))

    assert {wrong_output, 1} =
             System.cmd(
               "python3",
               [
                 script,
                 "--stage",
                 "ci-result",
                 "--phase-dir",
                 phase_dir,
                 "--fixture-dir",
                 fixture_dir
               ],
               cd: root,
               stderr_to_stdout: true
             )

    assert wrong_output =~ "attributed to the wrong canonical workflow"
    refute File.exists?(Path.join(phase_dir, "79-MAIN-CI-RECEIPT.json"))
  end

  defp phase79_ci_observation(sha, passed?) do
    security_workflow = ".github/workflows/security-gates.yml"
    fleet_workflow = ".github/workflows/fleet-proxy-e2e.yml"
    base_sha = String.duplicate("b", 40)
    source_sha = String.duplicate("c", 40)
    tree_sha = String.duplicate("d", 40)

    {workflow_runs, workflow_jobs, check_runs, fleet_context} =
      if passed? do
        security_run = %{
          "id" => 100,
          "attempt" => 1,
          "head_sha" => sha,
          "head_branch" => "main",
          "path" => security_workflow,
          "status" => "completed",
          "conclusion" => "success"
        }

        fleet_run = %{
          "id" => 200,
          "attempt" => 1,
          "head_sha" => sha,
          "head_branch" => "main",
          "path" => fleet_workflow,
          "status" => "completed",
          "conclusion" => "success"
        }

        security_jobs =
          [2001, 2002]
          |> Enum.with_index(1)
          |> Enum.map(fn {job_id, index} ->
            %{
              "id" => job_id,
              "workflow_run_id" => 100,
              "name" =>
                if(index == 1, do: "security (27, 1.19.5)", else: "security (28, 1.19.5)"),
              "status" => "completed",
              "conclusion" => "success"
            }
          end)

        fleet_job = %{
          "id" => 3000,
          "workflow_run_id" => 200,
          "name" => "fleet-proxy-e2e",
          "status" => "completed",
          "conclusion" => "success"
        }

        lane_checks =
          ["security (27, 1.19.5)", "security (28, 1.19.5)"]
          |> Enum.with_index(1)
          |> Enum.map(fn {check_name, index} ->
            %{
              "id" => 1000 + index,
              "name" => check_name,
              "head_sha" => sha,
              "status" => "completed",
              "conclusion" => "success",
              "workflow_path" => security_workflow,
              "workflow_run_id" => 100,
              "workflow_job_id" => 2000 + index
            }
          end)

        fleet_check = %{
          "id" => 1100,
          "name" => "fleet-proxy-e2e",
          "head_sha" => sha,
          "status" => "completed",
          "conclusion" => "success",
          "workflow_path" => fleet_workflow,
          "workflow_run_id" => 200,
          "workflow_job_id" => 3000
        }

        fleet = %{
          "name" => "fleet-proxy-e2e",
          "sha" => sha,
          "state" => "passed",
          "workflow_run_id" => 200,
          "workflow_job_id" => 3000,
          "check_run_id" => 1100
        }

        {[security_run, fleet_run], security_jobs ++ [fleet_job], lane_checks ++ [fleet_check],
         fleet}
      else
        {[], [], [], %{"name" => "fleet-proxy-e2e", "sha" => sha, "state" => "absent"}}
      end

    %{
      "repository" => "szTheory/relyra",
      "ref" => "refs/heads/main",
      "main_sha" => sha,
      "enabled_workflows" => [
        %{"id" => 10, "path" => security_workflow, "state" => "active"},
        %{"id" => 20, "path" => fleet_workflow, "state" => "active"}
      ],
      "workflow_runs" => workflow_runs,
      "workflow_jobs" => workflow_jobs,
      "check_runs" => check_runs,
      "fleet_context" => fleet_context,
      "receipts" => %{
        "publication" => %{
          "source_sha" => source_sha,
          "candidate_head_sha" => source_sha,
          "source_tree_sha" => tree_sha,
          "base_sha" => base_sha
        },
        "pr" => %{
          "status" => "complete",
          "head_sha" => source_sha,
          "base_sha" => base_sha,
          "tree_sha" => tree_sha,
          "independent" => true
        },
        "merge" => %{
          "status" => "complete",
          "source_head_sha" => source_sha,
          "base_sha" => base_sha,
          "tree_sha" => tree_sha,
          "main_sha" => sha,
          "parents" => [base_sha, source_sha],
          "independent_readback" => true
        }
      }
    }
  end

  defp phase79_protection_fixture(sha) do
    statuses = ["security (27, 1.19.5)", "security (28, 1.19.5)"]

    parent = %{
      "required_status_checks" => %{
        "strict" => true,
        "contexts" => statuses,
        "checks" => Enum.map(statuses, &%{"context" => &1, "app_id" => 15368}),
        "url" => "https://api.github.com/ignored",
        "contexts_url" => "https://api.github.com/ignored/contexts"
      },
      "enforce_admins" => %{"enabled" => true},
      "required_signatures" => %{"enabled" => false},
      "required_linear_history" => %{"enabled" => false},
      "allow_force_pushes" => %{"enabled" => false},
      "allow_deletions" => %{"enabled" => false},
      "block_creations" => %{"enabled" => false},
      "required_conversation_resolution" => %{"enabled" => false},
      "lock_branch" => %{"enabled" => false},
      "allow_fork_syncing" => %{"enabled" => false},
      "url" => "https://api.github.com/repos/szTheory/relyra/branches/main/protection"
    }

    empty_connection = %{
      "totalCount" => 0,
      "pageInfo" => %{"hasNextPage" => false, "endCursor" => nil},
      "nodes" => []
    }

    rule = %{
      "id" => "BPR_fixture",
      "pattern" => "main",
      "requiredApprovingReviewCount" => 1,
      "requiresApprovingReviews" => true,
      "dismissesStaleReviews" => false,
      "requiresCodeOwnerReviews" => false,
      "requireLastPushApproval" => false,
      "restrictsReviewDismissals" => false,
      "reviewDismissalAllowances" => empty_connection,
      "restrictsPushes" => false,
      "pushAllowances" => empty_connection,
      "bypassPullRequestAllowances" => empty_connection,
      "bypassForcePushAllowances" => empty_connection
    }

    ref = %{"name" => "main", "target" => %{"oid" => sha}, "branchProtectionRule" => rule}

    %{
      "rest" => %{
        "main-ref" => %{
          "responses" => [
            %{"status" => 200, "body" => %{"object" => %{"sha" => sha}}},
            %{"status" => 200, "body" => %{"object" => %{"sha" => sha}}}
          ]
        },
        "branches/main/protection" => %{"status" => 200, "body" => parent},
        "branches/main/protection/required_pull_request_reviews" => %{
          "status" => 200,
          "body" => %{
            "dismiss_stale_reviews" => false,
            "require_code_owner_reviews" => false,
            "require_last_push_approval" => false,
            "required_approving_review_count" => 1,
            "url" => "https://api.github.com/ignored/reviews"
          }
        },
        "branches/main/protection/restrictions" => %{
          "status" => 404,
          "body" => %{"message" => "Push restrictions not enabled"}
        },
        "commits/#{sha}/check-runs?page=1" => %{
          "status" => 200,
          "body" => %{
            "total_count" => 1,
            "check_runs" => [
              %{
                "id" => 1,
                "name" => "fleet-proxy-e2e",
                "head_sha" => sha,
                "app" => %{"id" => 15368, "slug" => "github-actions"}
              }
            ]
          }
        }
      },
      "graphql" => %{
        "protection" => %{
          "status" => 200,
          "body" => %{"data" => %{"repository" => %{"ref" => ref}}}
        }
      }
    }
  end

  defp phase79_fixture(sha) do
    command_responses = %{
      "git status --porcelain=v1 -z --untracked-files=all" => %{
        "stdout" =>
          " M .planning/state.json\u0000" <>
            " M .planning/STATE.md\u0000" <>
            " M .planning/ROADMAP.md\u0000" <>
            " M .planning/phases/73-twin-contract-and-baseline/73-RECONCILIATION-PROOF.json\u0000" <>
            " M .planning/phases/73-twin-contract-and-baseline/73-SECURITY.md\u0000" <>
            " M .planning/phases/73-twin-contract-and-baseline/73-VALIDATION.md\u0000" <>
            " M .planning/phases/78-ci-efficiency-and-reliability/78-CLEAN-STATE-RECEIPT.json\u0000" <>
            " M .planning/phases/79-adopter-ready-closeout/79-CLOSEOUT.md\u0000" <>
            " M .planning/phases/79-adopter-ready-closeout/79-05-PLAN.md\u0000" <>
            " M .planning/phases/79-adopter-ready-closeout/79-04-SUMMARY.md\u0000" <>
            " M .planning/phases/79-adopter-ready-closeout/79-INVENTORY.json\u0000" <>
            " M .planning/phases/79-adopter-ready-closeout/79-INVENTORY.md\u0000" <>
            " M .planning/phases/79-adopter-ready-closeout/79-REMOTE-BATCH.md\u0000" <>
            " M .planning/phases/79-adopter-ready-closeout/79-RISKS.json\u0000" <>
            " M scripts/collect_phase79_inventory.py\u0000" <>
            " M test/governance/milestone_scope_test.exs\u0000" <>
            " M .planning/phases/79-adopter-ready-closeout/79-VALIDATION.md\u0000" <>
            " M README.md\u0000?? .tool-versions\u0000" <>
            "?? .planning/phases/79-adopter-ready-closeout/79-PROTECTION-DESIRED.json\u0000" <>
            "?? .planning/phases/79-adopter-ready-closeout/79-PROTECTION-ROLLBACK.json\u0000" <>
            "?? .planning/phases/79-adopter-ready-closeout/79-PROTECTION-CAPTURE.json\u0000" <>
            "?? .planning/phases/79-adopter-ready-closeout/79-05-SUMMARY.md\u0000" <>
            "?? .planning/phases/79-adopter-ready-closeout/79-06-PLAN.md\u0000" <>
            "?? scripts/capture_phase79_protection.py\u0000"
      },
      "git ls-files -z" => %{
        "stdout" =>
          "mix.exs\u0000README.md\u0000.planning/state.json\u0000" <>
            ".planning/STATE.md\u0000.planning/ROADMAP.md\u0000" <>
            ".planning/phases/73-twin-contract-and-baseline/73-RECONCILIATION-PROOF.json\u0000" <>
            ".planning/phases/73-twin-contract-and-baseline/73-SECURITY.md\u0000" <>
            ".planning/phases/73-twin-contract-and-baseline/73-VALIDATION.md\u0000" <>
            ".planning/phases/78-ci-efficiency-and-reliability/78-CLEAN-STATE-RECEIPT.json\u0000" <>
            ".planning/phases/79-adopter-ready-closeout/79-CLOSEOUT.md\u0000" <>
            ".planning/phases/79-adopter-ready-closeout/79-05-PLAN.md\u0000" <>
            ".planning/phases/79-adopter-ready-closeout/79-04-SUMMARY.md\u0000" <>
            ".planning/phases/79-adopter-ready-closeout/79-INVENTORY.json\u0000" <>
            ".planning/phases/79-adopter-ready-closeout/79-INVENTORY.md\u0000" <>
            ".planning/phases/79-adopter-ready-closeout/79-REMOTE-BATCH.md\u0000" <>
            ".planning/phases/79-adopter-ready-closeout/79-RISKS.json\u0000" <>
            ".planning/phases/79-adopter-ready-closeout/79-VALIDATION.md\u0000" <>
            "scripts/collect_phase79_inventory.py\u0000test/governance/milestone_scope_test.exs\u0000"
      },
      "git ls-files -z .github/workflows" => %{
        "stdout" =>
          ".github/workflows/security-gates.yml\u0000.github/workflows/demo-app-ci.yml\u0000.github/workflows/demo-app-e2e.yml\u0000.github/workflows/fleet-proxy-e2e.yml\u0000"
      },
      "git worktree list --porcelain" => %{
        "stdout" => "worktree /repo\nHEAD #{sha}\nbranch refs/heads/main\n"
      },
      "git for-each-ref --format=%(refname:short)%09%(objectname) refs/heads refs/remotes" => %{
        "stdout" => "main\t#{sha}\n"
      },
      "git status --ignored --porcelain=v1 -z --untracked-files=all" => %{"stdout" => ""},
      "git remote get-url origin" => %{"stdout" => "git@github.com:szTheory/relyra.git"},
      "scripts/setup_branch_protection.sh --print-expected-json" => %{
        "stdout" =>
          Jason.encode!(%{
            "required_status_checks" => %{
              "strict" => true,
              "contexts" => [
                "security (27, 1.19.5)",
                "security (28, 1.19.5)",
                "fleet-proxy-e2e"
              ]
            },
            "enforce_admins" => true,
            "required_pull_request_reviews" => nil,
            "restrictions" => nil,
            "allow_force_pushes" => false,
            "allow_deletions" => false,
            "block_creations" => false,
            "required_conversation_resolution" => false,
            "lock_branch" => false,
            "allow_fork_syncing" => false
          })
      }
    }

    checks =
      ["security (27, 1.19.5)", "security (28, 1.19.5)"]
      |> Enum.with_index(1)
      |> Enum.map(fn {name, index} ->
        %{
          "id" => 80 + index,
          "name" => name,
          "head_sha" => sha,
          "check_suite_id" => 100,
          "status" => "completed",
          "conclusion" => "success"
        }
      end)
      |> Kernel.++([
        %{
          "id" => 90,
          "name" => "fleet-proxy-e2e",
          "head_sha" => sha,
          "check_suite_id" => 101,
          "status" => "completed",
          "conclusion" => "success"
        },
        %{
          "id" => 91,
          "name" => "real-idp-canary",
          "head_sha" => sha,
          "status" => "completed",
          "conclusion" => "success",
          "completed_at" => "2026-09-29T00:00:00Z"
        }
      ])

    contexts = ["security (27, 1.19.5)", "security (28, 1.19.5)", "fleet-proxy-e2e"]

    github = %{
      "git/ref/heads/main?page=1" => %{"body" => %{"object" => %{"sha" => sha}}},
      "pulls?state=all?page=1" => %{
        "body" => [
          %{
            "number" => 42,
            "state" => "open",
            "title" => "Fixture PR",
            "html_url" => "https://github.com/szTheory/relyra/pull/42",
            "base" => %{"ref" => "main", "sha" => sha, "repo" => %{"token" => "discard"}},
            "head" => %{"ref" => "topic", "sha" => sha, "user" => %{"email" => "discard"}}
          }
        ]
      },
      "issues?state=all?page=1" => %{
        "body" => [
          %{
            "number" => 8,
            "state" => "open",
            "title" => "Fixture issue",
            "html_url" => "https://github.com/szTheory/relyra/issues/8",
            "labels" => [
              %{"name" => "triage", "url" => "https://github.com/label", "color" => "fff"}
            ]
          },
          %{"number" => 9, "state" => "open", "pull_request" => %{"url" => "discard"}}
        ]
      },
      "branches?page=1" => %{"body" => []},
      "actions/workflows?page=1" => %{
        "body" => %{
          "workflows" => [
            %{
              "id" => 1,
              "name" => "Security",
              "path" => ".github/workflows/security-gates.yml",
              "state" => "active",
              "token" => "discard"
            },
            %{
              "id" => 2,
              "name" => "Old",
              "path" => ".github/workflows/old.yml",
              "state" => "disabled_inactivity"
            }
          ]
        }
      },
      "actions/runs?head_sha=#{sha}?page=1" => %{
        "body" => %{
          "workflow_runs" => [
            %{
              "id" => 56,
              "name" => "Security Gates",
              "workflow_id" => 1,
              "path" => ".github/workflows/security-gates.yml@refs/heads/main",
              "head_branch" => "main",
              "head_sha" => sha,
              "check_suite_id" => 100,
              "run_attempt" => 1,
              "run_started_at" => "2026-09-29T00:00:00Z",
              "status" => "completed",
              "conclusion" => "success",
              "updated_at" => "2026-09-29T00:00:00Z"
            },
            %{
              "id" => 57,
              "name" => "fleet-proxy-e2e",
              "workflow_id" => 4,
              "path" => ".github/workflows/fleet-proxy-e2e.yml@refs/heads/main",
              "head_branch" => "main",
              "head_sha" => sha,
              "check_suite_id" => 101,
              "run_attempt" => 1,
              "run_started_at" => "2026-09-29T00:05:00Z",
              "status" => "completed",
              "conclusion" => "success",
              "updated_at" => "2026-09-29T00:00:00Z"
            },
            %{
              "id" => 55,
              "name" => "real-idp-canary",
              "workflow_id" => 9,
              "path" => ".github/workflows/real-idp-canary.yml",
              "head_branch" => "main",
              "head_sha" => sha,
              "status" => "completed",
              "conclusion" => "success",
              "updated_at" => "2026-09-29T00:00:00Z",
              "html_url" => "https://github.com/szTheory/relyra/actions/runs/55"
            }
          ]
        }
      },
      "commits/#{sha}/check-runs?page=1" => %{"body" => %{"check_runs" => checks}},
      "actions/runs/56/jobs?filter=latest?page=1" => %{
        "body" => %{
          "jobs" => [
            %{
              "id" => 501,
              "name" => "security (27, 1.19.5)",
              "head_sha" => sha,
              "status" => "completed",
              "conclusion" => "success",
              "check_run_url" => "https://api.github.com/repos/szTheory/relyra/check-runs/81"
            },
            %{
              "id" => 502,
              "name" => "security (28, 1.19.5)",
              "head_sha" => sha,
              "status" => "completed",
              "conclusion" => "success",
              "check_run_url" => "https://api.github.com/repos/szTheory/relyra/check-runs/82"
            }
          ]
        }
      },
      "actions/runs/57/jobs?filter=latest?page=1" => %{
        "body" => %{
          "jobs" => [
            %{
              "id" => 503,
              "name" => "fleet-proxy-e2e",
              "head_sha" => sha,
              "status" => "completed",
              "conclusion" => "success",
              "check_run_url" => "https://api.github.com/repos/szTheory/relyra/check-runs/90"
            }
          ]
        }
      },
      "commits/#{sha}/status?page=1" => %{
        "body" => %{
          "statuses" => []
        }
      },
      "branches/main/protection?page=1" => %{
        "body" => %{
          "url" => "https://api.github.com/repos/szTheory/relyra/branches/main/protection",
          "required_status_checks" => %{
            "url" =>
              "https://api.github.com/repos/szTheory/relyra/branches/main/protection/required_status_checks",
            "strict" => true,
            "contexts" => contexts,
            "contexts_url" =>
              "https://api.github.com/repos/szTheory/relyra/branches/main/protection/required_status_checks/contexts",
            "checks" =>
              contexts
              |> Enum.with_index(123)
              |> Enum.map(fn {context, app_id} -> %{"context" => context, "app_id" => app_id} end)
          },
          "enforce_admins" => %{
            "url" =>
              "https://api.github.com/repos/szTheory/relyra/branches/main/protection/enforce_admins",
            "enabled" => true
          },
          "required_pull_request_reviews" => %{
            "url" =>
              "https://api.github.com/repos/szTheory/relyra/branches/main/protection/required_pull_request_reviews",
            "dismiss_stale_reviews" => true,
            "require_code_owner_reviews" => false,
            "required_approving_review_count" => 1,
            "require_last_push_approval" => false,
            "dismissal_restrictions" => %{
              "users_url" =>
                "https://api.github.com/repos/szTheory/relyra/branches/main/protection/required_pull_request_reviews/dismissal_restrictions/users",
              "users" => [
                %{
                  "id" => 5,
                  "login" => "maintainer",
                  "avatar_url" => "https://avatars.example/maintainer.png",
                  "html_url" => "https://github.com/maintainer"
                }
              ],
              "teams" => [],
              "apps" => []
            }
          },
          "restrictions" => %{
            "teams_url" =>
              "https://api.github.com/repos/szTheory/relyra/branches/main/protection/restrictions/teams",
            "users" => [],
            "teams" => [
              %{
                "id" => 6,
                "slug" => "security",
                "name" => "Security Team",
                "url" => "https://api.github.com/teams/6"
              }
            ],
            "apps" => []
          },
          "required_signatures" => %{
            "url" =>
              "https://api.github.com/repos/szTheory/relyra/branches/main/protection/required_signatures",
            "enabled" => false
          },
          "required_linear_history" => %{"enabled" => false},
          "allow_force_pushes" => %{"enabled" => false},
          "allow_deletions" => %{"enabled" => false},
          "block_creations" => %{"enabled" => false},
          "required_conversation_resolution" => %{"enabled" => false},
          "lock_branch" => %{"enabled" => false},
          "allow_fork_syncing" => %{"enabled" => false}
        }
      }
    }

    %{"commands" => command_responses, "github" => github}
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

    phase78_dir = Path.join(root, ".planning/phases/78-ci-efficiency-and-reliability")
    File.mkdir_p!(phase78_dir)

    for path <- Path.wildcard(".planning/phases/78-ci-efficiency-and-reliability/78-*-PLAN.md") do
      File.cp!(path, Path.join(phase78_dir, Path.basename(path)))
    end

    phase79_dir = Path.join(root, ".planning/phases/79-adopter-ready-closeout")
    File.mkdir_p!(phase79_dir)

    for path <- Path.wildcard(".planning/phases/79-adopter-ready-closeout/79-*-PLAN.md") do
      File.cp!(path, Path.join(phase79_dir, Path.basename(path)))
    end

    mutate_file(root, ".planning/STATE.md", fn state ->
      state
      |> then(&Regex.replace(~r/^current_phase: .*$/m, &1, "current_phase: 73"))
      |> then(&Regex.replace(~r/^status: .*$/m, &1, "status: executing"))
    end)

    mutate_file(root, ".planning/ROADMAP.md", fn roadmap ->
      roadmap
      |> String.replace("- [x] **Phase 73:", "- [ ] **Phase 73:")
      |> String.replace("- [ ] **Phase 74:", "- [x] **Phase 74:")
    end)

    File.cp!(
      ".planning/phases/73-twin-contract-and-baseline/73-10-PLAN.md",
      Path.join(phase_dir, "73-10-PLAN.md")
    )

    root
  end

  defp state_for_phase!(root, phase, status) do
    mutate_file(root, ".planning/STATE.md", fn state ->
      state = Regex.replace(~r/^current_phase: .*$/m, state, "current_phase: #{phase}")
      Regex.replace(~r/^status: .*$/m, state, "status: #{status}")
    end)

    mutate_file(root, ".planning/ROADMAP.md", fn roadmap ->
      Regex.replace(~r/^- \[([ x])\] \*\*Phase ([0-9.]+):/m, roadmap, fn line, mark, number ->
        next_mark =
          if number == phase,
            do: " ",
            else: if(phase_order(number) < phase_order(phase), do: "x", else: mark)

        String.replace(line, "[#{mark}]", "[#{next_mark}]", global: false)
      end)
    end)
  end

  defp planning_state!(root, phase \\ "74") do
    mutate_file(root, ".planning/STATE.md", fn state ->
      state
      |> String.replace("current_phase: 73", "current_phase: #{phase}")
      |> String.replace("status: executing", "status: planning")
    end)

    mutate_file(root, ".planning/ROADMAP.md", fn roadmap ->
      Regex.replace(~r/^- \[([ x])\] \*\*Phase ([0-9.]+):/m, roadmap, fn line, mark, number ->
        previous =
          phase_order(number) < phase_order(phase) and phase_order(number) >= phase_order("73")

        next_mark = if number == phase, do: " ", else: if(previous, do: "x", else: mark)
        String.replace(line, "[#{mark}]", "[#{next_mark}]", global: false)
      end)
    end)
  end

  defp phase_order(phase), do: phase |> String.split(".") |> Enum.map(&String.to_integer/1)

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
      when status in [
             "executing",
             "in_progress",
             "ready_for_verification",
             "planning",
             "Ready to execute"
           ] ->
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

    ".planning/STATE.md: STATE milestone/current phase/status must be singular and supported; " <>
      observed
  end

  defp governance_identity_violations(project, roadmap, requirements, state) do
    lifecycle_phase =
      if state.status == "planning",
        do: completed_predecessor_phase(roadmap, state.current_phase),
        else: state.current_phase

    valid_lifecycle = valid_active_milestone_transition?(roadmap, requirements, state)

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
      valid_lifecycle,
      "STATE current phase disagrees with ROADMAP active phases"
    )
    |> add_unless(
      Map.get(roadmap.phase_requirements, lifecycle_phase) ==
        Map.get(requirements.phase_requirements, lifecycle_phase),
      "Phase #{lifecycle_phase} requirement set disagrees between ROADMAP and REQUIREMENTS"
    )
  end

  defp valid_active_milestone_transition?(roadmap, requirements, state) do
    entries = roadmap.phase_entries
    current_index = Enum.find_index(entries, &(Enum.at(&1, 1) == state.current_phase))

    if is_integer(current_index) do
      through_current = Enum.take(entries, current_index + 1)
      prior = Enum.take(through_current, current_index)
      pending = Enum.filter(through_current, &(hd(&1) == " "))

      transition_is_valid? =
        case state.status do
          "planning" ->
            length(pending) == 1 and Enum.map(pending, &Enum.at(&1, 1)) == [state.current_phase] and
              Enum.all?(prior, &(hd(&1) == "x"))

          status
          when status in [
                 "executing",
                 "in_progress",
                 "ready_for_verification",
                 "Ready to execute"
               ] ->
            case Enum.at(through_current, -1) do
              [" ", phase, _name] ->
                phase == state.current_phase and Enum.all?(prior, &(hd(&1) == "x"))

              _other ->
                false
            end
        end

      requirements_are_consistent? =
        Enum.all?(through_current, fn [_mark, phase, _name] ->
          roadmap_requirements = Map.get(roadmap.phase_requirements, phase)

          is_struct(roadmap_requirements, MapSet) and
            roadmap_requirements == Map.get(requirements.phase_requirements, phase)
        end)

      transition_is_valid? and requirements_are_consistent?
    else
      false
    end
  end

  defp completed_predecessor_phase(roadmap, phase) do
    case Enum.find_index(roadmap.phase_entries, &(Enum.at(&1, 1) == phase)) do
      index when is_integer(index) and index > 0 ->
        roadmap.phase_entries
        |> Enum.take(index)
        |> Enum.reverse()
        |> Enum.find_value(fn
          ["x", predecessor, _name] -> predecessor
          _other -> nil
        end)

      _other ->
        nil
    end
  end

  defp validate_governance_paths(root, project, roadmap, state) do
    governance_phase =
      case {state.status, state.current_phase} do
        {"planning", "79"} -> "78"
        {"planning", "78"} -> "78"
        {"planning", _phase} -> "73"
        {_status, phase} -> phase
      end

    phase_entry = Enum.find(roadmap.phase_entries, &(Enum.at(&1, 1) == governance_phase))

    case phase_entry do
      [_mark, _phase, phase_name] ->
        expected_dir =
          Path.join(
            root,
            ".planning/phases/#{governance_phase}-#{slugify_phase_name(phase_name)}"
          )

        phase_dirs = if File.dir?(expected_dir), do: [expected_dir], else: []

        case phase_dirs do
          [phase_dir] ->
            all_plan_paths =
              phase_dir
              |> Path.join("#{governance_phase}-*-PLAN.md")
              |> Path.wildcard()
              |> Enum.sort()

            {completed, incomplete} = Enum.split_with(all_plan_paths, &executed_plan?/1)

            plan_paths =
              cond do
                governance_phase == "78" -> all_plan_paths
                state.status == "planning" -> completed
                true -> completed ++ Enum.take(incomplete, 1)
              end

            if all_plan_paths == [] or plan_paths == [] do
              {:error, ["current phase PLAN set is empty"]}
            else
              {:ok,
               %{
                 root: Path.expand(root),
                 milestone_version: project.milestone_version,
                 milestone_name: project.milestone_name,
                 current_phase: state.current_phase,
                 governance_phase: governance_phase,
                 status: state.status,
                 active_phases: [state.current_phase],
                 phase_requirements: roadmap.phase_requirements,
                 plan_paths: plan_paths
               }}
            end

          _other ->
            {:error, ["current phase must have exactly one tracked phase directory"]}
        end

      _other ->
        {:error, ["STATE current phase has no completed governance predecessor"]}
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

  defp plan_scope_violations(
         markdown,
         changed_classes \\ [],
         root \\ File.cwd!(),
         verified_posture_neutral_paths \\ [],
         plan_path \\ nil
       ) do
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
              root,
              verified_posture_neutral_paths
            )

          _other ->
            ["scope_assertions must appear exactly once"]
        end

      task_type_violations(tasks) ++
        task_risk_metadata_violations(tasks, verified_posture_neutral_paths) ++
        scope_violations ++
        demand_gated_exclusion_violations(exclusion_sections, markdown, root, plan_path) ++
        deterministic_verification_violations(
          tasks,
          is_binary(plan_path) and
            String.contains?(plan_path, "/78-ci-efficiency-and-reliability/"),
          plan_path
        ) ++
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

  defp demand_gated_exclusion_violations([section], _markdown, _root, _plan_path) do
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

  defp demand_gated_exclusion_violations([], markdown, root, plan_path) do
    project_path = Path.join(root, ".planning/PROJECT.md")

    phase79_closeout_plan? =
      is_binary(plan_path) and
        String.contains?(plan_path, "/79-adopter-ready-closeout/79-01-PLAN.md")

    context_refs_project? =
      Enum.any?(tag_sections(markdown, "context"), &String.contains?(&1, "@.planning/PROJECT.md"))

    project_excludes_all? =
      with true <- phase79_closeout_plan?,
           true <- context_refs_project?,
           true <- File.regular?(project_path),
           project <- File.read!(project_path),
           true <- Enum.all?(@demand_gated_exclusions, &String.contains?(project, &1)),
           true <- project =~ ~r/Still out of scope:[^\n]*demand-gated protocol features/i do
        true
      else
        _other -> false
      end

    if project_excludes_all?,
      do: [],
      else: [
        "demand_gated_exclusions must appear exactly once or be inherited from the referenced project scope"
      ]
  end

  defp demand_gated_exclusion_violations(sections, _markdown, _root, _plan_path) do
    ["demand_gated_exclusions must appear exactly once, found #{length(sections)}"]
  end

  defp approval_scope_violations(
         scope,
         tasks,
         changed_classes,
         root,
         verified_posture_neutral_paths
       ) do
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
        if risky_scope?(
             approval_class,
             values,
             tasks,
             changed_classes,
             verified_posture_neutral_paths
           ) do
          mutation_index =
            mutation_task_index(
              tasks,
              approval_class,
              changed_classes,
              verified_posture_neutral_paths
            )

          checkpoint_index = matching_checkpoint_index(tasks, approval_class)

          checkpoint_violations(approval_class, mutation_index, checkpoint_index, tasks, root)
        else
          []
        end

      shape_violations ++ checkpoint_violations
    end)
  end

  defp task_risk_metadata_violations(tasks, verified_posture_neutral_paths) do
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
        for risk_class <- governed_task_classes(task, verified_posture_neutral_paths),
            Map.get(task.risk_metadata, risk_class) != ["mutation"],
            do: "#{identity} #{risk_class} risk_metadata contradicts governed surface"

      shape_violations ++ field_violations ++ mismatch_violations
    end)
  end

  defp risky_scope?(
         approval_class,
         values,
         tasks,
         changed_classes,
         verified_posture_neutral_paths
       ) do
    values != ["unchanged"] or
      mutation_task_index(
        tasks,
        approval_class,
        changed_classes,
        verified_posture_neutral_paths
      ) != nil
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

  defp mutation_task_index(
         tasks,
         approval_class,
         changed_classes \\ [],
         verified_posture_neutral_paths \\ []
       ) do
    Enum.find_index(tasks, fn task ->
      implementation_bearing_task?(task) and
        (Map.get(task.risk_metadata, approval_class) == ["mutation"] or
           approval_class in governed_task_classes(task, verified_posture_neutral_paths) or
           String.contains?(task.action, "approval_class: #{approval_class}"))
    end) || changed_surface_mutation_index(tasks, approval_class, changed_classes)
  end

  defp changed_surface_mutation_index(tasks, approval_class, changed_classes) do
    if approval_class in changed_classes do
      Enum.find_index(tasks, &implementation_bearing_task?/1)
    end
  end

  defp governed_task_classes(task, verified_posture_neutral_paths) do
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
      Enum.any?(files, fn path ->
        security_seam_path?(path) and
          not (path == @signature_source_path and path in verified_posture_neutral_paths)
      end) or
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

  defp changed_surface_classes(@signature_source_path, before_content, after_content) do
    case {signature_source_ast(before_content), signature_source_ast(after_content)} do
      {{:ok, before_ast}, {:ok, after_ast}} when before_ast == after_ast -> []
      _different_or_unparseable -> ["security_posture"]
    end
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

  defp signature_source_ast(source) when is_binary(source) do
    case Code.string_to_quoted(source) do
      {:ok, ast} ->
        normalized_ast =
          Macro.prewalk(ast, fn
            {form, metadata, children} when is_list(metadata) ->
              source_metadata = [:line, :column, :end_line, :end_column]
              {form, Keyword.drop(metadata, source_metadata), children}

            node ->
              node
          end)

        {:ok, normalized_ast}

      {:error, _reason} ->
        :error
    end
  end

  defp signature_source_ast(_source), do: :error

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
      ~w(operation_kind current_state desired_state affected_checks preflight_command read_back_command resume_signal)

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
    case Map.fetch!(batch.occurrences, "operation_kind") do
      [kind] when kind in ["pr_create", "merge"] ->
        validate_remote_operation_batch(batch, kind)

      [] ->
        validate_branch_protection_batch(batch, root)

      _other ->
        ["remote_github remote_batch operation_kind must occur at most once"]
    end
  end

  defp validate_branch_protection_batch(batch, root) do
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
          {field, []} -> {field, nil}
        end)

      validate_complete_remote_batch(values, root)
    else
      shape ++ syntax
    end
  end

  defp validate_remote_operation_batch(batch, kind) do
    required =
      ~w(operation_kind current_state desired_state affected_checks mutation_commands preflight_command rollback_commands read_back_command resume_signal)

    occurrences = batch.occurrences

    shape =
      Enum.flat_map(required, fn field ->
        values = Map.fetch!(occurrences, field)

        cond do
          length(values) != 1 ->
            ["remote_github remote_batch #{field} must occur exactly once"]

          remote_field_missing?(hd(values)) ->
            ["remote_github remote_batch #{field} is missing or placeholder"]

          is_list(hd(values)) and duplicated?(hd(values)) ->
            ["remote_github remote_batch #{field} contains duplicate list items"]

          true ->
            []
        end
      end)

    if shape != [] or batch.syntax_errors != [] do
      shape ++ Enum.map(batch.syntax_errors, &"remote_github remote_batch unparsed syntax: #{&1}")
    else
      values = Map.new(occurrences, fn {field, [value]} -> {field, value} end)
      mutations = values["mutation_commands"]
      expected_mutations = if kind == "pr_create", do: 2, else: 1

      rollback_text =
        if kind == "pr_create",
          do: "separate approval is required to close the PR and delete the branch",
          else: "separate approval is required to revert the merge"

      expected_current = %{
        "repository" => "szTheory/relyra",
        "base_ref" => "main",
        "base_sha" => "@live_main_sha",
        "candidate_ref" => "refs/heads/@publication.branch.name",
        "candidate_sha" => "@publication.source_sha",
        "original_base_sha" => "c786a9890f2f99f0dd98f89a1d9713db7c486837",
        "original_source_sha" => "a5820aac9983b7289cbc1cc816120017761a02e3",
        "filtered_source_sha" => "@manifest.filtered_source_sha",
        "proof_sha256" => "@manifest.proof_sha256",
        "bundle_sha256" => "@manifest.bundle_sha256",
        "packet_sha256" => "@exact_operation_packet_sha256"
      }

      expected_operation =
        if kind == "pr_create", do: "push-and-create-pr", else: "normal-two-parent-merge"

      current_state = parse_remote_operation_state(values["current_state"], :current)
      desired_state = parse_remote_operation_state(values["desired_state"], :desired)

      exact_state =
        current_state == expected_current and
          desired_state == Map.put(expected_current, "operation", expected_operation)

      mutations_valid =
        is_list(mutations) and length(mutations) == expected_mutations and
          Enum.all?(mutations, fn command ->
            if kind == "pr_create" do
              command in [
                "git push (non-force) origin @publication.source_sha:refs/heads/@publication.branch.name",
                "gh pr create --repo szTheory/relyra --base main --head @publication.branch.name --title @publication.pull_request.title --body-file exact-packet-body"
              ]
            else
              command ==
                "gh api -X PUT repos/szTheory/relyra/pulls/@readback_pr_number/merge --input exact-merge-packet.json"
            end
          end)

      expected_preflight =
        "python3 scripts/verify_phase79_transaction.py --stage #{if(kind == "pr_create", do: "pr-preflight", else: "merge-preflight")} --phase-dir .planning/phases/79-adopter-ready-closeout --candidate-root #{@phase79_candidate_root}"

      expected_read_back =
        if kind == "pr_create",
          do:
            "gh pr view @publication.branch.name --repo szTheory/relyra --json number,headRefOid,baseRefName,state",
          else: "gh api repos/szTheory/relyra/pulls/@readback_pr_number"

      []
      |> maybe_remote_violation(
        not exact_state,
        "current/desired operation states must exactly bind repository, refs, SHAs, proof, bundle, and packet"
      )
      |> maybe_remote_violation(
        not mutations_valid,
        "mutation_commands must enumerate only the exact approved operation set"
      )
      |> maybe_remote_violation(
        values["preflight_command"] != expected_preflight,
        "preflight command must exactly name the matching stage, phase directory, and candidate root"
      )
      |> maybe_remote_violation(
        values["rollback_commands"] != ["No automatic rollback; " <> rollback_text],
        "rollback_commands must state the separate-approval compensation limit"
      )
      |> maybe_remote_violation(
        values["affected_checks"] != "security-gates.yml; fleet-proxy-e2e.yml",
        "affected_checks must bind the exact required CI lanes"
      )
      |> maybe_remote_violation(
        values["resume_signal"] != "approve remote_github szTheory/relyra main exact batch",
        "resume_signal must bind the exact repository and target"
      )
      |> maybe_remote_violation(
        values["read_back_command"] != expected_read_back,
        "read_back_command must independently read back the exact packet branch or PR"
      )
      |> maybe_remote_violation(
        values["resume_signal"] != "approve remote_github szTheory/relyra main exact batch",
        "resume_signal must bind the exact repository and target"
      )
    end
  end

  defp parse_remote_operation_state(state, kind) when is_binary(state) do
    expected_keys =
      ~w(repository base_ref base_sha candidate_ref candidate_sha original_base_sha original_source_sha filtered_source_sha proof_sha256 bundle_sha256 packet_sha256) ++
        if(kind == :desired, do: ["operation"], else: [])

    parsed =
      state
      |> String.split(";", trim: false)
      |> Enum.reduce_while({:ok, %{}}, fn field, {:ok, acc} ->
        case String.split(field, "=", parts: 2) do
          [key, value] ->
            key = String.trim(key)
            value = String.trim(value)

            if key in expected_keys and value != "" and not Map.has_key?(acc, key),
              do: {:cont, {:ok, Map.put(acc, key, value)}},
              else: {:halt, :error}

          _other ->
            {:halt, :error}
        end
      end)

    case parsed do
      {:ok, values} when map_size(values) == length(expected_keys) -> values
      _other -> :error
    end
  end

  defp parse_remote_operation_state(_state, _kind), do: :error

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

  defp deterministic_verification_violations(tasks),
    do: deterministic_verification_violations(tasks, false, nil)

  defp deterministic_verification_violations(tasks, allow_planned_outputs?, plan_path) do
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
              AdoptionEvidence.validate_automated_command!(command, File.cwd!(),
                planned_files: task.files
              )

              :ok
            rescue
              error in ArgumentError ->
                if (allow_planned_outputs? and phase78_future_owner_command?(plan_path, command)) or
                     phase79_collector_command?(plan_path, task.files, command) or
                     phase79_transaction_command?(plan_path, command) do
                  :ok
                else
                  {:error, Exception.message(error)}
                end
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

  defp phase78_future_owner_command?(plan_path, command) when is_binary(command) do
    is_phase78_receipt_alias? =
      try do
        AdoptionEvidence.validate_automated_command!(command, File.cwd!())
        false
      rescue
        ArgumentError -> mix_alias_command?(command, "ci.phase78.receipt")
      end

    if is_phase78_receipt_alias? do
      phase78_future_receipt_owner_declared?(plan_path)
    else
      false
    end
  end

  defp phase79_collector_command?(plan_path, task_files, command)
       when is_binary(plan_path) and is_binary(task_files) and is_binary(command) do
    output = ".planning/phases/79-adopter-ready-closeout/79-INVENTORY.json"
    script = "scripts/collect_phase79_inventory.py"

    String.contains?(plan_path, "/79-adopter-ready-closeout/79-01-PLAN.md") and
      command == "python3 #{script} --verify #{output}" and
      output in String.split(task_files, ~r/[\s,]+/, trim: true) and
      non_symlink_regular_path?(File.cwd!(), String.split(script, "/"))
  end

  defp phase79_collector_command?(_plan_path, _task_files, _command), do: false

  defp phase79_transaction_command?(plan_path, command)
       when is_binary(plan_path) and is_binary(command) do
    relative_script = "scripts/verify_phase79_transaction.py"
    plan_name = Path.basename(plan_path)

    allowed =
      MapSet.new([
        "python3 #{relative_script} --stage pr-preflight --phase-dir .planning/phases/79-adopter-ready-closeout --candidate-root #{@phase79_candidate_root}",
        "python3 #{relative_script} --stage pr-result --phase-dir .planning/phases/79-adopter-ready-closeout --candidate-root #{@phase79_candidate_root}",
        "python3 #{relative_script} --stage merge-preflight --phase-dir .planning/phases/79-adopter-ready-closeout --candidate-root #{@phase79_candidate_root}",
        "python3 #{relative_script} --stage merge-result --phase-dir .planning/phases/79-adopter-ready-closeout --candidate-root #{@phase79_candidate_root}"
      ])

    plan_name in ["79-15-PLAN.md", "79-09-PLAN.md"] and command in allowed and
      non_symlink_regular_path?(File.cwd!(), String.split(relative_script, "/")) and
      tracked_repository_path?(File.cwd!(), relative_script)
  end

  defp phase79_transaction_command?(_plan_path, _command), do: false

  defp phase78_future_receipt_owner_declared?(plan_path) do
    owner_path = "test/adoption/phase78_clean_state_contract_test.exs"
    source = Path.join(Path.dirname(plan_path), "78-07-PLAN.md")

    with true <- File.regular?(source),
         {:ok, _region, tasks} <- closed_plan_tasks(File.read!(source)),
         indexed <- Enum.with_index(tasks),
         creator <-
           Enum.find(indexed, fn {task, _index} ->
             owner_path in String.split(task.files, ~r/[\s,]+/, trim: true) and
               String.contains?(task.action, "ci.phase78.receipt")
           end),
         verifier <-
           Enum.find(indexed, fn {task, _index} ->
             Enum.any?(
               tag_sections(task.verify, "automated"),
               &mix_alias_command?(&1, "ci.phase78.receipt")
             )
           end),
         {{creator_task, creator_index}, {verifier_task, verifier_index}}
         when creator_index < verifier_index <- {creator, verifier},
         true <- String.contains?(creator_task.action, owner_path),
         true <- String.contains?(verifier_task.action, "ci.phase78.receipt") do
      true
    else
      _other -> false
    end
  end

  defp mix_alias_command?(command, alias_name) do
    command
    |> String.split(" ", trim: true)
    |> Enum.drop_while(&String.match?(&1, ~r/^[A-Z_][A-Z0-9_]*=/))
    |> then(&(&1 == ["mix", alias_name]))
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
          not archival_uat?(File.read!(path)),
          do: "#{path} requires a UAT artifact"

    document_violations ++ uat_violations
  end

  defp archival_uat?(document) do
    Regex.match?(~r/^status: (?:diagnosed|completed)$/m, document) and
      not Enum.any?(
        ["<human-check>", "## Manual-Only Verifications", "status: human_needed"],
        &String.contains?(document, &1)
      )
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

  defp halted_plan_summary?(plan_path) do
    summary_path = String.replace_suffix(plan_path, "-PLAN.md", "-SUMMARY.md")

    case File.read(summary_path) do
      {:ok, summary} ->
        case Regex.run(~r/\A---\s*\n(.*?)\n---/s, summary, capture: :all_but_first) do
          [frontmatter] ->
            Regex.match?(~r/^status:\s*halted\s*$/m, frontmatter) or
              Regex.match?(
                ~r/^metrics:\s*\n(?:[ \t].*\n)*?[ \t]+status:\s*halted\s*$/m,
                frontmatter
              )

          nil ->
            false
        end

      {:error, _reason} ->
        false
    end
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

    plan_paths
    |> Task.async_stream(
      fn plan_path ->
        if halted_plan_summary?(plan_path) do
          []
        else
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

              verified_posture_neutral_paths = verified_comment_only_signature_paths(changes)

              repository_plan_scope_violations(
                identity,
                plan_path,
                markdown,
                changed_classes,
                verified_posture_neutral_paths
              )
              |> Enum.map(&"#{plan_path}: #{&1}")

            {:error, reason} ->
              plan_violations =
                repository_plan_scope_violations(identity, plan_path, markdown, [])
                |> Enum.map(&"#{plan_path}: #{&1}")

              plan_violations ++ ["#{plan_path} completed-plan diff provenance #{reason}"]
          end
        end
      end,
      max_concurrency: max(System.schedulers_online(), 4),
      ordered: true,
      timeout: :infinity
    )
    |> Enum.flat_map(fn
      {:ok, violations} -> violations
      {:exit, reason} -> ["completed-plan governance worker exited: #{inspect(reason)}"]
    end)
  end

  defp repository_provenance_snapshot(root) do
    root = Path.expand(root)

    with {:ok, endpoint} <- review_endpoint(root) do
      cache_key = {__MODULE__, :repository_provenance_snapshot, root, endpoint}

      case :persistent_term.get(cache_key, :missing) do
        :missing ->
          snapshot = repository_provenance_snapshot_uncached(root, endpoint)
          :persistent_term.put(cache_key, snapshot)
          snapshot

        snapshot ->
          snapshot
      end
    else
      _error -> nil
    end
  end

  defp repository_provenance_snapshot_uncached(root, endpoint) do
    with {:ok, tracked_paths} <-
           git_lines(root, ["ls-files", "--cached", "--", ".planning/phases"]),
         {:ok, commit_rows} <- git_lines(root, ["log", "--all", "--format=%H%x09%P%x09%s"]) do
      commits =
        Map.new(commit_rows, fn row ->
          [commit, parents, subject] = String.split(row, "\t", parts: 3)

          {commit, %{parents: String.split(parents, " ", trim: true), subject: subject}}
        end)

      %{
        root: root,
        endpoint: endpoint,
        tracked_paths: tracked_paths,
        commits: commits
      }
    else
      _error -> nil
    end
  end

  defp repository_plan_scope_violations(
         identity,
         plan_path,
         markdown,
         changed_classes,
         verified_posture_neutral_paths \\ []
       ) do
    if halted_plan_summary?(plan_path) do
      []
    else
      case repository_plan_schema(identity, plan_path) do
        :legacy ->
          legacy_plan_scope_violations(markdown)

        :current ->
          plan_scope_violations(
            markdown,
            changed_classes,
            identity.root,
            verified_posture_neutral_paths,
            plan_path
          )
      end
    end
  end

  defp verified_comment_only_signature_paths(changes) do
    signature_changes = Enum.filter(changes, &(&1.path == @signature_source_path))

    has_source_edit? =
      Enum.any?(signature_changes, fn change -> change.before != change.after end)

    if has_source_edit? and
         Enum.all?(signature_changes, fn change ->
           with {:ok, before_ast} <- signature_source_ast(change.before),
                {:ok, after_ast} <- signature_source_ast(change.after) do
             before_ast == after_ast
           else
             _parse_failure -> false
           end
         end) do
      [@signature_source_path]
    else
      []
    end
  end

  defp repository_plan_schema(identity, plan_path) do
    relative = Path.relative_to(Path.expand(plan_path), identity.root)

    legacy_paths =
      for plan <- ~w(01 02 03),
          do: ".planning/phases/73-twin-contract-and-baseline/73-#{plan}-PLAN.md"

    governance_phase = Map.get(identity, :governance_phase, identity.current_phase)

    if identity.milestone_version == "v1.11" and governance_phase == "73" and
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
        ~r/^\d+\.\s+([^\n]+)/mu
        |> Regex.scan(section, capture: :all_but_first)
        |> Enum.flat_map(fn [claims] ->
          Regex.scan(~r/`([0-9a-f]{7,40})`/, claims, capture: :all_but_first)
          |> Enum.map(fn [commit] -> commit end)
        end)

      nil ->
        []
    end
  end

  defp completed_plan_provenance(root, plan_path, snapshot \\ nil) do
    plan_id = plan_path |> Path.basename() |> String.replace_suffix("-PLAN.md", "")
    summary_path = String.replace_suffix(plan_path, "-PLAN.md", "-SUMMARY.md")
    summary_relative = Path.relative_to(summary_path, root)

    with {:ok, filtered_candidate} <- validate_filtered_candidate_provenance(root),
         {:ok, [boundary]} <- completion_boundaries(root, summary_relative, plan_id),
         {:ok, endpoint} <- review_endpoint(root, snapshot),
         :ok <- validate_review_endpoint(root, boundary, endpoint, snapshot),
         {:ok, history} <- trusted_plan_history(root, plan_id, boundary, endpoint, snapshot),
         :ok <-
           validate_trusted_commits(root, history.commits, boundary, endpoint, plan_id, snapshot),
         {:ok, changes} <- commit_changed_surfaces(root, history.commits, snapshot),
         {:ok, boundary_changes} <- commit_changed_surfaces(root, [boundary], snapshot) do
      provenance = %{
        commits: history.commits,
        descendant_assignments: history.descendant_assignments,
        changes: changes ++ boundary_changes,
        boundary_changes: boundary_changes,
        completion_boundary: boundary,
        review_endpoint: endpoint
      }

      case summary_commit_cross_check(
             root,
             summary_path,
             history.pre_boundary,
             filtered_candidate && filtered_candidate["commit_map"]
           ) do
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

  defp validate_filtered_candidate_provenance(root) do
    phase_dir = Path.join(root, ".planning/phases/79-adopter-ready-closeout")
    manifest = Path.join(phase_dir, "79-FILTERED-CANDIDATE.json")

    case File.lstat(manifest) do
      {:ok, %File.Stat{type: :symlink}} ->
        {:error, ["filtered-history proof contract: candidate manifest must not be a symlink"]}

      {:ok, %File.Stat{type: :regular}} ->
        if Path.expand(root) == Path.expand(File.cwd!()) and
             git_file_at(root, "HEAD", @phase79_proof_path) == "" do
          {:ok, nil}
        else
          verifier = Path.expand("../../scripts/prepare_phase79_filtered_candidate.py", __DIR__)

          case System.cmd(
                 "python3",
                 [
                   verifier,
                   "--verify-candidate",
                   "--candidate-root",
                   Path.expand(root),
                   "--phase-dir",
                   phase_dir
                 ],
                 cd: Path.expand(root),
                 stderr_to_stdout: true
               ) do
            {output, 0} ->
              case Jason.decode(String.trim(output)) do
                {:ok, %{"valid" => true} = result} ->
                  {:ok, result}

                _other ->
                  {:error,
                   ["filtered-history proof contract: verifier returned malformed result"]}
              end

            {output, _status} ->
              {:error, ["filtered-history proof contract: " <> String.trim(output)]}
          end
        end

      {:error, :enoent} ->
        proof_path = Path.join(root, @phase79_proof_path)

        case File.lstat(proof_path) do
          {:ok, %File.Stat{type: :regular}} ->
            filtered_candidate_proof_map(root, proof_path)

          {:ok, %File.Stat{type: :symlink}} ->
            {:error, ["filtered-history proof contract: candidate proof must not be a symlink"]}

          {:ok, _other} ->
            {:error, ["filtered-history proof contract: candidate proof must be a regular file"]}

          {:error, :enoent} ->
            {:ok, nil}

          {:error, reason} ->
            {:error,
             [
               "filtered-history proof contract: cannot inspect candidate proof: #{inspect(reason)}"
             ]}
        end

      {:ok, _other} ->
        {:error, ["filtered-history proof contract: candidate manifest must be a regular file"]}

      {:error, reason} ->
        {:error,
         [
           "filtered-history proof contract: cannot inspect candidate manifest: #{inspect(reason)}"
         ]}
    end
  end

  defp filtered_candidate_proof_map(root, proof_path) do
    with {:ok, raw} <- File.read(proof_path) do
      cache_key =
        {__MODULE__, :filtered_candidate_proof_map, Path.expand(root), :crypto.hash(:sha256, raw)}

      case :persistent_term.get(cache_key, :missing) do
        :missing ->
          result = filtered_candidate_proof_map_uncached(root, proof_path, raw)
          :persistent_term.put(cache_key, result)
          result

        result ->
          result
      end
    else
      {:error, reason} ->
        {:error,
         ["filtered-history proof contract: cannot read candidate proof: #{inspect(reason)}"]}
    end
  end

  defp filtered_candidate_proof_map_uncached(root, proof_path, raw) do
    proof_relative = Path.relative_to(proof_path, root)

    with true <- byte_size(raw) <= 8 * 1024 * 1024,
         {:ok,
          %{"schema" => "relyra.phase79.filtered-history-witness.v1", "proof" => proof} = witness}
         when is_map(proof) <- Jason.decode(raw),
         true <-
           Map.keys(witness) |> Enum.sort() ==
             ~w(base_tree commits dispositions evidence gpgsig limits proof schema trees),
         true <- Map.get(proof, "base_sha") == @phase79_base_sha,
         true <- Map.get(proof, "original_source_sha") == @phase79_source_sha,
         true <- Map.get(proof, "original_source_tree_sha") == @phase79_source_tree_sha,
         true <- Map.get(proof, "commit_count") == 612 and Map.get(proof, "merge_count") == 3,
         commit_map when is_map(commit_map) <- Map.get(proof, "commit_map"),
         tree_map when is_map(tree_map) <- Map.get(proof, "tree_map"),
         true <- map_size(commit_map) == 613 and map_size(tree_map) == 612,
         true <-
           Enum.all?(commit_map, fn {old, new} -> phase79_sha1?(old) and phase79_sha1?(new) end),
         true <-
           Enum.all?(tree_map, fn {old, new} -> phase79_sha1?(old) and phase79_sha1?(new) end),
         true <- length(Enum.uniq(Map.values(commit_map))) == 613,
         true <- Map.get(commit_map, @phase79_base_sha) == @phase79_base_sha,
         {:ok, filtered_source} <- Map.fetch(commit_map, @phase79_source_sha),
         true <- Map.get(proof, "filtered_source_sha") == filtered_source,
         {:ok, reachable_commits} <- git_lines(root, ["rev-list", "--all"]),
         true <- MapSet.subset?(MapSet.new(Map.values(commit_map)), MapSet.new(reachable_commits)),
         true <- git_file_at(root, "HEAD", proof_relative) == raw,
         {:ok, _proof_commit} <-
           filtered_candidate_proof_commit(root, proof_relative, raw, filtered_source),
         true <- git_success?(root, ["merge-base", "--is-ancestor", filtered_source, "HEAD"]) do
      {:ok, %{"commit_map" => commit_map}}
    else
      false ->
        {:error,
         [
           "filtered-history proof contract: candidate proof-only commit failed identity or ancestry checks"
         ]}

      {:error, reason} ->
        {:error,
         ["filtered-history proof contract: cannot read candidate proof: #{inspect(reason)}"]}

      _other ->
        {:error, ["filtered-history proof contract: candidate proof-only commit is malformed"]}
    end
  end

  defp filtered_candidate_proof_commit(root, proof_relative, raw, filtered_source) do
    with {:ok, additions} <-
           git_lines(root, [
             "log",
             "--all",
             "--format=%H",
             "--diff-filter=A",
             "--",
             proof_relative
           ]) do
      matches =
        Enum.filter(additions, fn commit ->
          git_file_at(root, commit, proof_relative) == raw and
            git_lines(root, ["diff-tree", "--no-commit-id", "--name-only", "-r", commit]) ==
              {:ok, [proof_relative]} and
            git_success?(root, ["merge-base", "--is-ancestor", filtered_source, commit]) and
            git_success?(root, ["merge-base", "--is-ancestor", commit, "HEAD"])
        end)

      case matches do
        [commit] -> {:ok, commit}
        _other -> {:error, "candidate proof-only commit is not unique and reachable"}
      end
    end
  end

  defp phase79_sha1?(value), do: is_binary(value) and Regex.match?(~r/^[0-9a-f]{40}$/, value)

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

  defp validate_review_endpoint(root, boundary, endpoint, snapshot \\ nil) do
    if snapshot_is_ancestor?(snapshot, boundary, endpoint) or
         (is_nil(snapshot) and
            git_success?(root, ["merge-base", "--is-ancestor", boundary, endpoint])),
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
            if halted_plan_scope?(root, scope, snapshot) do
              {:cont, {:ok, assignments}}
            else
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

  defp halted_plan_scope?(root, scope, snapshot) do
    paths =
      case tracked_plan_paths(root, scope, snapshot) do
        {:ok, [_ | _] = tracked} -> tracked
        _ -> Path.wildcard(Path.join(root, ".planning/phases/**/#{scope}-PLAN.md"))
      end

    Enum.any?(paths, &halted_plan_summary?/1)
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

  defp validate_trusted_commits(root, commits, boundary, endpoint, plan_id, snapshot) do
    violations =
      []
      |> add_if(commits == [], "trusted implementation set is empty for #{plan_id}")
      |> add_if(duplicated?(commits), "trusted implementation set contains duplicate commits")

    violations =
      Enum.reduce(commits, violations, fn commit, found ->
        found
        |> add_unless(
          snapshot_is_ancestor?(snapshot, commit, endpoint) or
            (is_nil(snapshot) and
               git_success?(root, ["merge-base", "--is-ancestor", commit, endpoint])),
          "commit #{commit} is not reachable from review endpoint"
        )
        |> add_unless(
          snapshot_is_ancestor?(snapshot, commit, boundary) or
            snapshot_is_ancestor?(snapshot, boundary, commit) or
            (is_nil(snapshot) and
               (git_success?(root, ["merge-base", "--is-ancestor", commit, boundary]) or
                  git_success?(root, ["merge-base", "--is-ancestor", boundary, commit]))),
          "commit #{commit} is not on completion boundary history"
        )
        |> add_unless(
          commit_scope(root, commit, snapshot) == plan_id,
          "commit #{commit} has foreign plan scope"
        )
      end)

    if violations == [], do: :ok, else: {:error, violations}
  end

  defp summary_commit_cross_check(root, summary_path, trusted_commits, old_to_filtered) do
    claimed =
      case File.read(summary_path) do
        {:ok, summary} -> summary_task_commits(summary)
        {:error, _reason} -> []
      end

    {resolved, resolution_violations} =
      Enum.map_reduce(claimed, [], fn claim, violations ->
        resolution =
          if is_map(old_to_filtered) do
            matches =
              Enum.filter(Map.keys(old_to_filtered), &String.starts_with?(&1, claim))

            case matches do
              [old_sha] -> {:ok, Map.fetch!(old_to_filtered, old_sha)}
              [] -> {:error, "SUMMARY Task Commits contains unmapped original hash #{claim}"}
              _many -> {:error, "SUMMARY Task Commits contains ambiguous original hash #{claim}"}
            end
          else
            resolve_commit(root, claim)
          end

        case resolution do
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

  defp commit_scope(root, commit, snapshot) do
    if is_map(snapshot) and snapshot.root == Path.expand(root) and
         Map.has_key?(snapshot.commits, commit) do
      snapshot.commits |> Map.fetch!(commit) |> Map.fetch!(:subject) |> conventional_scope()
    else
      case System.cmd("git", ["-C", root, "show", "-s", "--format=%s", commit],
             stderr_to_stdout: true
           ) do
        {subject, 0} -> subject |> String.trim() |> conventional_scope()
        _other -> nil
      end
    end
  end

  defp commit_changed_surfaces(root, commits, snapshot \\ nil) do
    Enum.reduce_while(commits, {:ok, []}, fn commit, {:ok, changes} ->
      case commit_paths(root, commit, snapshot) do
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

  defp commit_paths(root, commit, snapshot) do
    case commit_parent_count(root, commit, snapshot) do
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

  defp commit_parent_count(root, commit, snapshot) do
    if is_map(snapshot) and snapshot.root == Path.expand(root) and
         Map.has_key?(snapshot.commits, commit) do
      {:ok, snapshot.commits |> Map.fetch!(commit) |> Map.fetch!(:parents) |> length()}
    else
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
  end

  defp snapshot_is_ancestor?(snapshot, ancestor, descendant) do
    if is_map(snapshot) and Map.has_key?(snapshot.commits, ancestor) do
      snapshot_ancestor_walk?(snapshot, ancestor, [descendant], MapSet.new())
    else
      false
    end
  end

  defp snapshot_ancestor_walk?(_snapshot, _ancestor, [], _visited), do: false

  defp snapshot_ancestor_walk?(snapshot, ancestor, [commit | rest], visited) do
    cond do
      commit == ancestor ->
        true

      MapSet.member?(visited, commit) ->
        snapshot_ancestor_walk?(snapshot, ancestor, rest, visited)

      true ->
        parents = get_in(snapshot, [:commits, commit, :parents]) || []

        snapshot_ancestor_walk?(
          snapshot,
          ancestor,
          parents ++ rest,
          MapSet.put(visited, commit)
        )
    end
  end

  defp git_file_at(root, revision, path) do
    root = Path.expand(root)

    resolved_revision =
      if revision == "HEAD" do
        case git_lines(root, ["rev-parse", "HEAD"]) do
          {:ok, [head]} -> head
          _error -> revision
        end
      else
        revision
      end

    cache_key = {__MODULE__, :git_file_at, root, resolved_revision, path}

    case :persistent_term.get(cache_key, :missing) do
      :missing ->
        content =
          case System.cmd("git", ["-C", root, "show", "#{resolved_revision}:#{path}"],
                 stderr_to_stdout: true
               ) do
            {content, 0} -> content
            {_output, _status} -> ""
          end

        :persistent_term.put(cache_key, content)
        content

      content ->
        content
    end
  end

  defp git_lines(root, args) do
    root = Path.expand(root)

    if root == Path.expand(File.cwd!()) do
      cache_key = {__MODULE__, :git_lines, root, args}

      case :persistent_term.get(cache_key, :missing) do
        :missing ->
          result = git_lines_uncached(root, args)
          if match?({:ok, _rows}, result), do: :persistent_term.put(cache_key, result)
          result

        result ->
          result
      end
    else
      git_lines_uncached(root, args)
    end
  end

  defp git_lines_uncached(root, args) do
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

  defp artifact_control_baseline(tracked_paths, opts \\ []) do
    owned? = Keyword.get(opts, :owned?, false)
    path_refs = Enum.map_join(tracked_paths, ", ", &"`#{&1}`")

    evidence =
      if owned? do
        "Tracked paths #{path_refs} are controlled artifact fixtures; purpose: prove Git-index ownership checks. " <>
          "[VERIFIED: `test/governance/milestone_scope_test.exs`, isolated Git-index fixture]"
      else
        "The repository artifact inventory is clean. " <>
          "[VERIFIED: `test/governance/milestone_scope_test.exs`, isolated Git-index fixture]"
      end

    disposition =
      if owned? do
        "Retain #{path_refs} as controlled artifacts; purpose: inventory assertion; owner: Repository quality test owner."
      else
        "Inventory generated paths."
      end

    """
    ## Findings Ledger

    | Finding ID | Severity | Category | Finding | Reproducible Evidence | Disposition | Owner | Target Phase | Approval Class | Blocker State | Revisit Date |
    | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
    | QUAL-73-005 | Informational | Artifacts | clean tracked-artifact scan | #{evidence} | #{disposition} | Repository quality test owner | Phase 77 | none | deferred | Next quality audit |

    ## CI Baseline Snapshot

    | Surface | Current Observation | Measured Duration | Duplication | Cache Declaration | Owning Lane | Required-Check State | Failure Evidence | Provenance |
    | --- | --- | --- | --- | --- | --- | --- | --- | --- |
    | Artifact inventory | Git-index fixture | Not timed | None | None | ci.evidence | Mandatory | Test assertion | `test/governance/milestone_scope_test.exs` |
    """
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
          severity_policy_violations(rows) ++
          tracked_artifact_ownership_violations(rows, root)

      {:error, reason} ->
        ["Findings Ledger non-vacuous table #{reason}"]
    end
  end

  defp tracked_artifact_ownership_violations(rows, root) do
    case System.cmd("git", ["-C", root, "ls-files", "-z"], stderr_to_stdout: true) do
      {output, 0} ->
        output
        |> String.split(<<0>>, trim: true)
        |> Enum.filter(&suspicious_tracked_artifact?/1)
        |> Enum.flat_map(fn path ->
          owned? =
            Enum.any?(rows, fn row ->
              owner = String.trim(row["Owner"] || "")
              evidence = row["Reproducible Evidence"] || ""
              disposition = row["Disposition"] || ""

              row["Finding ID"] == "QUAL-73-005" and
                String.contains?(evidence, "`#{path}`") and
                String.contains?(evidence, "purpose:") and
                String.contains?(disposition, "`#{path}`") and
                String.contains?(disposition, "purpose:") and
                String.contains?(disposition, "owner: #{owner}")
            end)

          if owned?,
            do: [],
            else: [
              "QUAL-73-005 tracked artifact #{path} requires path-specific purpose, owner, and disposition"
            ]
        end)

      {output, status} ->
        ["QUAL-73-005 Git-index inventory failed (#{status}): #{String.trim(output)}"]
    end
  end

  defp suspicious_tracked_artifact?(path) do
    components = Path.split(path)
    directories = ~w(_build deps node_modules playwright-report test-results coverage)
    filename = Path.basename(path)

    Enum.any?(components, &(&1 in directories)) or filename == ".DS_Store" or
      Path.extname(filename) in [".log", ".bak", ".orig"]
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

  defp phase79_inventory_identity(inventory) do
    %{
      "repository" => inventory["repository"]["name"],
      "ref" => inventory["observation"]["ref"],
      "main_sha" => inventory["observation"]["main_sha"],
      "observed_at" => inventory["observed_at"]
    }
  end

  defp phase79_state_deferred_ids(state) do
    state
    |> String.split("\n")
    |> Enum.flat_map(fn line ->
      case String.split(line, "|", trim: true) do
        [id, status] when id not in ["Item", "---"] and status != "Status" ->
          id = String.trim(id)

          case id do
            "Hosted external twin" -> ["HOSTED-TWIN"]
            "Exhaustive compatibility matrix" -> ["COMPATIBILITY-MATRIX"]
            id -> if(Regex.match?(~r/^[A-Z][A-Z0-9-]+$/, id), do: [id], else: [])
          end

        _ ->
          []
      end
    end)
  end

  defp phase79_open_window_ids(windows) do
    windows
    |> String.split("\n")
    |> Enum.flat_map(fn line ->
      case line |> String.split("|") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == "")) do
        [id, _phase, _kind, _file, _description, "open" | _] ->
          ["WINDOW-#{String.trim(id)}"]

        _ ->
          []
      end
    end)
  end

  defp phase79_risk_violations(ledger, expected_ids, identity) do
    required_fields =
      ~w(id source evidence owner severity status adopter_impact demand_or_trigger maintenance_cost approval_boundary open_disposition revisit)

    allowed_severities = ~w(Critical High Medium Low Informational)
    allowed_statuses = ~w(release-blocker disposition-required deferred resolved)

    allowed_open_dispositions =
      ~w(low-value demand-gated approval-blocked more-costly-than-retired-risk)

    items = ledger["items"] || []
    ids = Enum.map(items, & &1["id"])

    identity_errors =
      if ledger["inventory_source"] == %{
           "path" => ".planning/phases/79-adopter-ready-closeout/79-INVENTORY.json",
           "repository" => identity["repository"],
           "ref" => identity["ref"],
           "main_sha" => identity["main_sha"],
           "observed_at" => identity["observed_at"]
         } do
        []
      else
        ["risk ledger inventory identity does not match current inventory"]
      end

    field_errors =
      Enum.flat_map(items, fn item ->
        id = item["id"] || "<missing-id>"

        missing =
          Enum.flat_map(required_fields, fn field ->
            value = item[field]

            if is_binary(value) and String.trim(value) == "",
              do: ["#{id} missing #{field}"],
              else: []
          end)

        status_errors =
          cond do
            item["severity"] not in allowed_severities ->
              ["#{id} invalid severity"]

            item["status"] not in allowed_statuses ->
              ["#{id} invalid status"]

            item["severity"] in ["Critical", "High"] and
                item["status"] not in ["release-blocker", "resolved"] ->
              ["#{id} high/critical finding is not blocked until resolved"]

            item["severity"] == "Medium" and item["status"] != "resolved" and
                item["status"] != "disposition-required" ->
              ["#{id} medium finding requires written disposition"]

            item["severity"] in ["Low", "Informational"] and item["status"] != "resolved" and
                item["status"] not in ["deferred", "disposition-required"] ->
              ["#{id} low/informational item needs an owner and revisit"]

            item["status"] == "resolved" and item["open_disposition"] != nil ->
              ["#{id} resolved item has an open disposition"]

            item["status"] != "resolved" and
                item["open_disposition"] not in allowed_open_dispositions ->
              ["#{id} open disposition is missing or invalid"]

            true ->
              []
          end

        missing ++ status_errors
      end)

    membership_errors =
      cond do
        length(ids) != length(Enum.uniq(ids)) ->
          ["risk ledger membership contains duplicate IDs"]

        MapSet.new(ids) != MapSet.new(expected_ids) ->
          ["risk ledger membership differs from retained/deferred/window sources"]

        true ->
          []
      end

    schema_errors =
      if ledger["schema"] == "phase79-risk-ledger" and ledger["version"] == 1 and
           is_list(ledger["items"]) do
        []
      else
        ["risk ledger schema is unsupported"]
      end

    identity_errors ++ schema_errors ++ field_errors ++ membership_errors
  end

  defp phase79_remote_batch_violations(markdown, identity) do
    if String.contains?(markdown, "**Status:** no mutation proposed") do
      reason =
        Regex.run(~r/## Why there is no proposal\s+(.+?)\s+## Authorization boundary/s, markdown,
          capture: :all_but_first
        )

      reason_errors =
        if reason && String.trim(hd(reason)) != "",
          do: [],
          else: ["no-action record lacks a reason"]

      execution_errors =
        if String.contains?(markdown, "no command was executed") and
             String.contains?(markdown, "automated read-back") and
             String.contains?(markdown, "proves its postcondition") and
             String.contains?(markdown, "grants no permission") do
          []
        else
          ["no-action record lacks execution/approval boundary"]
        end

      identity_errors =
        phase79_remote_identity_errors(markdown, identity, [
          {"- **Target repository:**", "repository", :equal},
          {"- **Target ref/resource:**", "ref", :prefix},
          {"- **Observed main SHA:**", "main_sha", :equal},
          {"- **Observed at:**", "observed_at", :equal}
        ])

      status_errors =
        if String.contains?(
             markdown,
             "**Status:** no mutation proposed; no command was executed."
           ),
           do: [],
           else: ["no-action status must state that no mutation was proposed or executed"]

      contradictory_action_errors =
        if String.contains?(markdown, "Proposed operation") or
             String.contains?(markdown, "exact proposal; not executed") do
          ["no-action record contains a proposed mutation"]
        else
          []
        end

      identity_errors ++
        status_errors ++ reason_errors ++ execution_errors ++ contradictory_action_errors
    else
      fields = [
        {"- Target repository:", "target"},
        {"- Target ref/resource:", "target"},
        {"- Observed main SHA:", "source identity"},
        {"- Observed at:", "source identity"},
        {"- Captured current state:", "current state"},
        {"- Desired state:", "desired state"},
        {"- Affected identifiers:", "affected identifiers"},
        {"- Reason and least-privilege operation:", "operation"},
        {"- Read-only preflight:", "preflight"},
        {"- Proposed operation (not executed):", "operation"},
        {"- Exact payload JSON:", "payload"},
        {"- Payload SHA-256:", "payload"},
        {"- Rollback:", "rollback"},
        {"- Read-back assertion:", "read-back"},
        {"- Resume signal:", "resume signal"},
        {"- Explicit approval:", "approval"}
      ]

      proposal_errors =
        Enum.flat_map(fields, fn {label, error} ->
          case phase79_remote_field(markdown, label) do
            nil ->
              ["remote proposal missing #{error}"]

            value ->
              if(String.trim(value) == "", do: ["remote proposal missing #{error}"], else: [])
          end
        end)

      identity_errors =
        phase79_remote_identity_errors(markdown, identity, [
          {"- Target repository:", "repository", :equal},
          {"- Target ref/resource:", "ref", :prefix},
          {"- Observed main SHA:", "main_sha", :equal},
          {"- Observed at:", "observed_at", :equal}
        ])

      desired = phase79_remote_field(markdown, "- Desired state:") |> phase79_unwrap_code()
      payload = phase79_remote_field(markdown, "- Exact payload JSON:") |> phase79_unwrap_code()

      payload_digest =
        phase79_remote_field(markdown, "- Payload SHA-256:") |> phase79_unwrap_code()

      resume = phase79_remote_field(markdown, "- Resume signal:") || ""
      approval = phase79_remote_field(markdown, "- Explicit approval:") || ""
      rollback = phase79_remote_field(markdown, "- Rollback:") || ""
      preflight = phase79_remote_field(markdown, "- Read-only preflight:") || ""
      read_back = phase79_remote_field(markdown, "- Read-back assertion:") || ""

      payload_binding_errors =
        cond do
          not is_binary(payload) or payload == "" ->
            ["remote proposal missing payload"]

          desired != payload ->
            ["remote proposal desired state differs from exact payload"]

          match?({:error, _}, Jason.decode(payload)) ->
            ["remote proposal payload is not valid JSON"]

          true ->
            expected_digest = :crypto.hash(:sha256, payload) |> Base.encode16(case: :lower)

            if(payload_digest == expected_digest,
              do: [],
              else: ["remote proposal payload digest does not match its exact payload"]
            ) ++
              if String.contains?(resume, expected_digest) and
                   String.contains?(resume, identity["repository"]) and
                   String.contains?(resume, identity["ref"]),
                 do: [],
                 else: ["remote proposal resume signal is not bound to target and payload"]
        end

      state_control_errors =
        if(String.contains?(rollback, "captured current state"),
          do: [],
          else: ["remote proposal rollback does not restore captured current state"]
        ) ++
          if(
            String.contains?(preflight, "read-only") and String.contains?(preflight, "query") and
              String.contains?(preflight, "compare"),
            do: [],
            else: ["remote proposal preflight is not a read-only state comparison"]
          ) ++
          if(String.contains?(read_back, "query") and String.contains?(read_back, "compare"),
            do: [],
            else: ["remote proposal lacks automated read-back"]
          ) ++
          if String.contains?(approval, "separate plan") and
               String.contains?(approval, "immediate same-target revalidation") and
               String.contains?(approval, "expire") and String.contains?(approval, "renew"),
             do: [],
             else: ["remote proposal approval is not target-bound and state-expiring"]

      proposal_errors =
        proposal_errors ++
          if String.contains?(markdown, "approval is acceptance") or
               String.contains?(markdown, "approval: acceptance evidence") or
               String.contains?(approval, "acceptance"),
             do: ["approval cannot be used as acceptance"],
             else: []

      status_errors =
        if String.contains?(markdown, "**Status:** exact proposal; not executed."),
          do: [],
          else: ["remote proposal status must remain exact and unexecuted"]

      identity_errors ++
        proposal_errors ++ status_errors ++ payload_binding_errors ++ state_control_errors
    end
  end

  defp phase79_blocked_remote_violations(
         markdown,
         inventory,
         desired_bytes,
         rollback,
         rollback_bytes
       ) do
    identity = phase79_inventory_identity(inventory)
    protection = get_in(inventory, ["github", "branch_protection"]) || %{}
    missing_settings = ["required_pull_request_reviews", "restrictions"]
    capture_path = ".planning/phases/79-adopter-ready-closeout/79-PROTECTION-CAPTURE.json"
    capture_bytes = File.read!(capture_path)
    capture = Jason.decode!(capture_bytes)
    capture_digest = :crypto.hash(:sha256, capture_bytes) |> Base.encode16(case: :lower)
    desired_digest = :crypto.hash(:sha256, desired_bytes) |> Base.encode16(case: :lower)
    rollback_digest = :crypto.hash(:sha256, rollback_bytes) |> Base.encode16(case: :lower)

    capture_errors =
      if protection["capture_status"] == "incomplete" and protection["resource"] == nil and
           protection["capture_errors"] == [
             "branch protection response is missing settings: required_pull_request_reviews, restrictions"
           ],
         do: [],
         else: ["inventory does not prove the current protection resource is incomplete"]

    composite_capture_errors =
      if capture["schema"] == "phase79-protection-capture" and capture["version"] == 1 and
           capture["capture_status"] == "incomplete" and capture["resource"] == nil and
           capture["main_sha"] == identity["main_sha"] and
           capture["capture_errors"] == [
             "GraphQL approval settings conflict with the REST review subresource"
           ] and
           get_in(capture, [
             "sources",
             "review_subresource",
             "configuration",
             "required_approving_review_count"
           ]) ==
             1 and
           get_in(capture, [
             "sources",
             "graphql",
             "branch_protection",
             "rule",
             "requiredApprovingReviewCount"
           ]) ==
             nil and
           get_in(capture, [
             "sources",
             "graphql",
             "branch_protection",
             "rule",
             "requiresApprovingReviews"
           ]) ==
             false,
         do: [],
         else: ["composite capture does not prove the explicit REST/GraphQL conflict"]

    rollback_errors =
      if rollback["schema"] == "phase79-protection-rollback" and rollback["version"] == 1 and
           rollback["status"] == "blocked" and rollback["payload_available"] == false and
           rollback["rollback_payload"] == nil and
           rollback["source_capture_status"] == "incomplete" and
           rollback["source_capture_sha256"] == capture_digest and
           rollback["source_capture_digest"] == capture["source_digest"] and
           rollback["required_missing_settings"] == missing_settings and
           rollback["target"] == identity and
           rollback["source_endpoint"] == "composite protection capture" and
           rollback["source_capture_errors"] == capture["capture_errors"] and
           Jason.decode!(rollback_bytes) == rollback,
         do: [],
         else: [
           "rollback record does not bind the conflicting capture without an executable payload"
         ]

    missing_setting_errors =
      if MapSet.new(protection["capture_errors"] || []) ==
           MapSet.new([
             "branch protection response is missing settings: required_pull_request_reviews, restrictions"
           ]) and
           MapSet.new(rollback["required_missing_settings"] || []) == MapSet.new(missing_settings),
         do: [],
         else: ["missing protection settings are not consistently recorded"]

    desired_record_errors =
      case Jason.decode(desired_bytes) do
        {:ok, desired_record} ->
          if desired_record["schema"] == "phase79-protection-desired" and
               desired_record["version"] == 1 and desired_record["status"] == "blocked" and
               desired_record["payload_available"] == false and
               desired_record["desired_payload"] == nil and
               desired_record["target"] == identity and
               desired_record["source_capture_status"] == "incomplete" and
               desired_record["source_capture_sha256"] == capture_digest and
               desired_record["source_capture_digest"] == capture["source_digest"] and
               desired_record["source_capture_errors"] == capture["capture_errors"] do
            []
          else
            ["desired record contains a payload or is not bound to the conflict capture"]
          end

        _ ->
          ["desired record is invalid JSON"]
      end

    desired_errors =
      if String.contains?(markdown, "79-PROTECTION-DESIRED.json") and
           String.contains?(markdown, "SHA-256 `#{desired_digest}`"),
         do: [],
         else: ["no-action record is not bound to the exact desired reference bytes"]

    rollback_hash_errors =
      if String.contains?(markdown, "79-PROTECTION-ROLLBACK.json") and
           String.contains?(markdown, "record SHA-256 `#{rollback_digest}`"),
         do: [],
         else: ["no-action record is not bound to the exact rollback record bytes"]

    action_markers = [
      "gh api -X PUT",
      "gh workflow run",
      "workflow_dispatch",
      "- Proposed operation",
      "- Exact payload JSON:",
      "- Explicit approval:",
      "approve remote_github"
    ]

    action_errors =
      Enum.flat_map(action_markers, fn marker ->
        if String.contains?(markdown, marker),
          do: ["no-action record contains executable or approval content: #{marker}"],
          else: []
      end)

    phase79_remote_batch_violations(markdown, identity) ++
      capture_errors ++
      composite_capture_errors ++
      rollback_errors ++
      desired_record_errors ++
      missing_setting_errors ++ desired_errors ++ rollback_hash_errors ++ action_errors
  end

  defp phase79_remote_identity_errors(markdown, identity, fields) do
    Enum.flat_map(fields, fn {label, identity_key, match_kind} ->
      value = phase79_remote_field(markdown, label) || ""
      expected = identity[identity_key]
      normalized = String.trim(value, "`")

      matches? =
        case match_kind do
          :equal -> normalized == expected
          :prefix -> String.starts_with?(normalized, expected)
        end

      if matches?, do: [], else: ["remote batch target/source identity is stale"]
    end)
  end

  defp phase79_current_artifact_state do
    phase_dir = ".planning/phases/79-adopter-ready-closeout"
    capture_bytes = File.read!(Path.join(phase_dir, "79-PROTECTION-CAPTURE.json"))
    desired_bytes = File.read!(Path.join(phase_dir, "79-PROTECTION-DESIRED.json"))
    rollback_bytes = File.read!(Path.join(phase_dir, "79-PROTECTION-ROLLBACK.json"))
    inventory_bytes = File.read!(Path.join(phase_dir, "79-INVENTORY.json"))
    batch_bytes = File.read!(Path.join(phase_dir, "79-REMOTE-BATCH.md"))
    closeout = File.read!(Path.join(phase_dir, "79-CLOSEOUT.md"))

    optional_json = fn name ->
      path = Path.join(phase_dir, name)
      if File.regular?(path), do: path |> File.read!() |> Jason.decode!(), else: nil
    end

    capture = Jason.decode!(capture_bytes)
    desired = Jason.decode!(desired_bytes)
    rollback = Jason.decode!(rollback_bytes)
    inventory = Jason.decode!(inventory_bytes)
    digest = fn bytes -> :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower) end

    %{
      "capture" => capture,
      "capture_bytes" => capture_bytes,
      "desired" => desired,
      "desired_bytes" => desired_bytes,
      "rollback" => rollback,
      "rollback_bytes" => rollback_bytes,
      "inventory" => inventory,
      "post_capture" => optional_json.("79-PROTECTION-POST-CAPTURE.json"),
      "post_inventory" => optional_json.("79-POST-INVENTORY.json"),
      "publication" => optional_json.("79-PUBLICATION-PACKET.json"),
      "pr_receipt" => optional_json.("79-PR-TRANSACTION.json"),
      "merge_receipt" => optional_json.("79-MERGE-RECEIPT.json"),
      "ci_receipt" => optional_json.("79-MAIN-CI-RECEIPT.json"),
      "protection_receipt" => optional_json.("79-PROTECTION-TRANSACTION.json"),
      "risks" => File.read!(Path.join(phase_dir, "79-RISKS.json")) |> Jason.decode!(),
      "batch" => %{
        "status" =>
          if(String.contains?(batch_bytes, "**Status:** no mutation proposed"),
            do: "blocked_no_action",
            else: "proposal"
          ),
        "capture_sha256" => digest.(capture_bytes),
        "desired_sha256" => digest.(desired_bytes),
        "rollback_sha256" => digest.(rollback_bytes),
        "batch_sha256" => digest.(batch_bytes),
        "operations" => []
      },
      "batch_bytes" => batch_bytes,
      "closeout_status" =>
        if(String.contains?(closeout, "Release readiness: READY"), do: "READY", else: "BLOCKED")
    }
  end

  defp phase79_ready_artifact_state_fixture do
    sha = String.duplicate("a", 40)
    base_sha = String.duplicate("b", 40)
    source_sha = String.duplicate("c", 40)
    tree_sha = String.duplicate("d", 40)
    repository = "szTheory/relyra"
    ref = "refs/heads/main"

    target = %{
      "repository" => repository,
      "ref" => ref,
      "main_sha" => sha,
      "observed_at" => "2026-10-01T00:00:00Z"
    }

    lane_names = [
      "browser defenses",
      "mix ci.evidence",
      "mix ci.ledger_loop",
      "mix ci.package",
      "mix ci.phase73.reconciliation",
      "mix ci.security",
      "mix ci.verify",
      "mix qa",
      "standalone defenses"
    ]

    payload = %{
      "required_status_checks" => %{
        "strict" => true,
        "contexts" => ["fleet-proxy-e2e", "security (27, 1.19.5)", "security (28, 1.19.5)"],
        "checks" => [
          %{"app_id" => 15368, "context" => "fleet-proxy-e2e"},
          %{"app_id" => 15368, "context" => "security (27, 1.19.5)"},
          %{"app_id" => 15368, "context" => "security (28, 1.19.5)"}
        ]
      },
      "required_pull_request_reviews" => %{"required_approving_review_count" => 1},
      "enforce_admins" => %{"enabled" => true}
    }

    capture = %{
      "schema" => "phase79-protection-capture",
      "version" => 1,
      "capture_status" => "complete",
      "capture_errors" => [],
      "repository" => repository,
      "ref" => ref,
      "main_sha" => sha,
      "observed_at" => target["observed_at"],
      "target" => target,
      "resource" => payload,
      "writable_payload" => payload,
      "sources" => %{
        "review_subresource" => %{"configuration" => %{"required_approving_review_count" => 1}},
        "graphql" => %{
          "branch_protection" => %{
            "rule" => %{
              "requiredApprovingReviewCount" => 1,
              "requiresApprovingReviews" => true
            }
          }
        },
        "parent_protection" => %{
          "configuration" => %{
            "required_pull_request_reviews" => payload["required_pull_request_reviews"],
            "restrictions" => %{"users" => [], "teams" => [], "apps" => []}
          }
        }
      }
    }

    digest = fn bytes -> :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower) end
    capture_bytes = Jason.encode!(capture)
    capture_sha = digest.(capture_bytes)

    desired = %{
      "schema" => "phase79-protection-desired",
      "version" => 1,
      "status" => "ready",
      "payload_available" => true,
      "target" => target,
      "source_capture_sha256" => capture_sha,
      "desired_payload" => payload
    }

    desired_bytes = Jason.encode!(desired)
    desired_sha = digest.(desired_bytes)

    rollback = %{
      "schema" => "phase79-protection-rollback",
      "version" => 1,
      "status" => "ready",
      "payload_available" => true,
      "target" => target,
      "source_capture_sha256" => capture_sha,
      "rollback_payload" => payload
    }

    rollback_bytes = Jason.encode!(rollback)
    rollback_sha = digest.(rollback_bytes)

    batch = %{
      "status" => "no_action",
      "capture_sha256" => capture_sha,
      "desired_sha256" => desired_sha,
      "rollback_sha256" => rollback_sha,
      "operations" => [],
      "approval" => nil,
      "read_only" => true
    }

    batch_bytes = Jason.encode!(batch)
    batch_sha = digest.(batch_bytes)

    lanes =
      Map.new(lane_names, fn name ->
        {name,
         %{
           "state" => "passed",
           "sha" => sha,
           "evidence" => [
             %{
               "sha" => sha,
               "workflow_run_id" => 100,
               "job_id" => 200,
               "check_run_id" => 300,
               "conclusion" => "success"
             }
           ]
         }}
      end)

    inventory = %{
      "observation" => %{
        "repository" => repository,
        "ref" => ref,
        "main_sha" => sha,
        "revalidated_sha" => sha
      },
      "collection" => %{"complete" => true, "readiness" => "green", "gaps" => []},
      "github" => %{
        "branch_protection" => %{"capture_status" => "complete", "resource" => payload},
        "mandatory_lanes" => Map.new(lane_names, &{&1, %{"state" => "passed", "sha" => sha}})
      }
    }

    inventory_bytes = Jason.encode!(inventory)
    inventory_sha = digest.(inventory_bytes)
    post_capture = capture
    post_capture_bytes = Jason.encode!(post_capture)
    post_capture_sha = digest.(post_capture_bytes)
    post_inventory = inventory
    post_inventory_bytes = Jason.encode!(post_inventory)
    post_inventory_sha = digest.(post_inventory_bytes)

    publication = %{
      "status" => "ready",
      "source_sha" => source_sha,
      "candidate_head_sha" => source_sha,
      "base_sha" => base_sha,
      "source_tree_sha" => tree_sha
    }

    pr = %{
      "status" => "complete",
      "head_sha" => source_sha,
      "base_sha" => base_sha,
      "tree_sha" => tree_sha,
      "independent" => true,
      "approval" => %{"checkpoint_id" => "79-08-pr-create", "response" => "approved"}
    }

    merge = %{
      "status" => "complete",
      "source_head_sha" => source_sha,
      "base_sha" => base_sha,
      "tree_sha" => tree_sha,
      "main_sha" => sha,
      "parents" => [base_sha, source_sha]
    }

    ci = %{
      "status" => "complete",
      "target" => %{"repository" => repository, "ref" => ref, "sha" => sha},
      "lanes" => lanes,
      "fleet_context" => %{
        "state" => "passed",
        "sha" => sha,
        "workflow_run_id" => 400,
        "job_id" => 500,
        "check_run_id" => 600
      }
    }

    protection = %{
      "status" => "complete",
      "target" => target,
      "capture_sha256" => capture_sha,
      "inventory_sha256" => inventory_sha,
      "desired_sha256" => desired_sha,
      "rollback_sha256" => rollback_sha,
      "batch_sha256" => batch_sha,
      "post_capture_sha256" => post_capture_sha,
      "post_inventory_sha256" => post_inventory_sha,
      "readback_payload" => payload,
      "source_agreement" => true
    }

    risks = %{
      "items" => [
        %{
          "id" => "PIPE-73-001",
          "severity" => "High",
          "status" => "resolved",
          "evidence" => "All required evidence passes on #{sha}."
        }
      ]
    }

    %{
      "capture" => capture,
      "capture_bytes" => capture_bytes,
      "desired" => desired,
      "desired_bytes" => desired_bytes,
      "rollback" => rollback,
      "rollback_bytes" => rollback_bytes,
      "inventory" => inventory,
      "inventory_bytes" => inventory_bytes,
      "post_capture" => post_capture,
      "post_capture_bytes" => post_capture_bytes,
      "post_inventory" => post_inventory,
      "post_inventory_bytes" => post_inventory_bytes,
      "publication" => publication,
      "pr_receipt" => pr,
      "merge_receipt" => merge,
      "ci_receipt" => ci,
      "protection_receipt" => protection,
      "risks" => risks,
      "batch" => Map.put(batch, "batch_sha256", batch_sha),
      "batch_bytes" => batch_bytes,
      "closeout_status" => "READY"
    }
  end

  defp phase79_completion_contract_violations(state) do
    capture = state["capture"] || %{}
    desired = state["desired"] || %{}
    rollback = state["rollback"] || %{}
    inventory = state["inventory"] || %{}
    batch = state["batch"] || %{}
    target_sha = get_in(inventory, ["observation", "main_sha"])
    digest = fn bytes -> :crypto.hash(:sha256, bytes || "") |> Base.encode16(case: :lower) end
    capture_sha = digest.(state["capture_bytes"])
    desired_sha = digest.(state["desired_bytes"])
    rollback_sha = digest.(state["rollback_bytes"])

    if state["closeout_status"] == "BLOCKED" do
      []
      |> maybe_add_phase79_error(
        capture["capture_status"] == "incomplete",
        "blocked capture is not explicitly incomplete"
      )
      |> maybe_add_phase79_error(
        capture["resource"] == nil and capture["capture_errors"] != [],
        "blocked capture lacks its source conflict"
      )
      |> maybe_add_phase79_error(
        desired["status"] == "blocked" and desired["desired_payload"] == nil and
          desired["source_capture_sha256"] == capture_sha,
        "blocked desired payload is available or stale"
      )
      |> maybe_add_phase79_error(
        rollback["status"] == "blocked" and rollback["rollback_payload"] == nil and
          rollback["source_capture_sha256"] == capture_sha,
        "blocked rollback payload is available or stale"
      )
      |> maybe_add_phase79_error(
        get_in(inventory, ["collection", "complete"]) == false and
          get_in(inventory, ["collection", "readiness"]) == "unknown",
        "blocked inventory is reported complete or green"
      )
      |> maybe_add_phase79_error(
        target_sha == capture["main_sha"],
        "blocked capture and inventory target different main SHAs"
      )
      |> maybe_add_phase79_error(
        batch["status"] == "blocked_no_action" and batch["operations"] == [] and
          String.contains?(state["batch_bytes"] || "", "no mutation proposed"),
        "blocked batch contains a write or lacks no-action evidence"
      )
      |> maybe_add_phase79_error(
        batch["capture_sha256"] == capture_sha and batch["desired_sha256"] == desired_sha and
          batch["rollback_sha256"] == rollback_sha,
        "blocked batch hashes are stale"
      )
      |> maybe_add_phase79_error(
        Enum.all?(
          ["pr_receipt", "merge_receipt", "ci_receipt", "post_inventory", "protection_receipt"],
          &(state[&1] == nil)
        ),
        "blocked artifacts fabricate a completed remote transaction"
      )
    else
      ready_phase79_completion_violations(
        state,
        capture,
        desired,
        rollback,
        inventory,
        batch,
        target_sha,
        capture_sha,
        desired_sha,
        rollback_sha,
        digest
      )
    end
  end

  defp ready_phase79_completion_violations(
         state,
         capture,
         desired,
         rollback,
         inventory,
         batch,
         target_sha,
         capture_sha,
         desired_sha,
         rollback_sha,
         digest
       ) do
    post_inventory = state["post_inventory"] || %{}
    post_capture = state["post_capture"] || %{}
    publication = state["publication"] || %{}
    pr = state["pr_receipt"] || %{}
    merge = state["merge_receipt"] || %{}
    ci = state["ci_receipt"] || %{}
    protection = state["protection_receipt"] || %{}
    lanes = get_in(inventory, ["github", "mandatory_lanes"]) || %{}
    risks = get_in(state, ["risks", "items"])

    errors =
      []
      |> maybe_add_phase79_error(
        state["closeout_status"] == "READY",
        "ready closeout status is absent"
      )
      |> maybe_add_phase79_error(
        is_binary(target_sha) and target_sha == capture["main_sha"],
        "ready capture and inventory target different SHAs"
      )
      |> maybe_add_phase79_error(
        capture["capture_status"] == "complete" and capture["capture_errors"] == [] and
          is_map(capture["writable_payload"]),
        "ready capture lacks complete writable source agreement"
      )
      |> maybe_add_phase79_error(
        capture["resource"] == capture["writable_payload"],
        "capture resource disagrees with its writable payload"
      )
      |> maybe_add_phase79_error(
        get_in(capture, [
          "sources",
          "review_subresource",
          "configuration",
          "required_approving_review_count"
        ]) ==
          get_in(capture, [
            "sources",
            "graphql",
            "branch_protection",
            "rule",
            "requiredApprovingReviewCount"
          ]) and
          get_in(capture, [
            "sources",
            "graphql",
            "branch_protection",
            "rule",
            "requiresApprovingReviews"
          ]) ==
            get_in(capture, [
              "sources",
              "review_subresource",
              "configuration",
              "required_approving_review_count"
            ]) > 0,
        "REST and GraphQL review requirements disagree"
      )
      |> maybe_add_phase79_error(
        desired["status"] == "ready" and desired["payload_available"] == true and
          desired["desired_payload"] == capture["writable_payload"] and
          desired["source_capture_sha256"] == capture_sha,
        "ready desired payload or capture hash is inconsistent"
      )
      |> maybe_add_phase79_error(
        rollback["status"] == "ready" and rollback["payload_available"] == true and
          rollback["rollback_payload"] == capture["writable_payload"] and
          rollback["source_capture_sha256"] == capture_sha,
        "ready rollback is not the exact captured current state"
      )
      |> maybe_add_phase79_error(
        batch["status"] == "no_action" and batch["operations"] == [] and batch["approval"] == nil and
          batch["read_only"] == true,
        "ready no-action batch contains an operation or authorization"
      )
      |> maybe_add_phase79_error(
        batch["capture_sha256"] == capture_sha and batch["desired_sha256"] == desired_sha and
          batch["rollback_sha256"] == rollback_sha and
          batch["batch_sha256"] == digest.(state["batch_bytes"]),
        "ready batch hashes do not join to immutable artifacts"
      )
      |> maybe_add_phase79_error(
        get_in(inventory, ["collection", "complete"]) == true and
          get_in(inventory, ["collection", "readiness"]) == "green" and
          get_in(inventory, ["observation", "revalidated_sha"]) == target_sha,
        "pre-inventory is not green on the verified SHA"
      )
      |> maybe_add_phase79_error(
        map_size(lanes) == 9 and
          Enum.all?(Map.values(lanes), &(&1["state"] == "passed" and &1["sha"] == target_sha)),
        "pre-inventory lacks nine passing same-SHA lanes"
      )
      |> maybe_add_phase79_error(
        get_in(post_inventory, ["collection", "complete"]) == true and
          get_in(post_inventory, ["collection", "readiness"]) == "green" and
          get_in(post_inventory, ["observation", "main_sha"]) == target_sha and
          get_in(post_inventory, ["observation", "revalidated_sha"]) == target_sha,
        "post-inventory is not green on the same SHA"
      )
      |> maybe_add_phase79_error(
        post_capture["capture_status"] == "complete" and post_capture["capture_errors"] == [] and
          post_capture["main_sha"] == target_sha,
        "post-capture is incomplete or stale"
      )
      |> maybe_add_phase79_error(
        publication["status"] == "ready" and
          publication["candidate_head_sha"] == publication["source_sha"] and
          publication["source_tree_sha"] == merge["tree_sha"],
        "publication source/tree is not joined to merged main"
      )
      |> maybe_add_phase79_error(
        pr["status"] == "complete" and pr["head_sha"] == publication["source_sha"] and
          pr["base_sha"] == publication["base_sha"] and
          pr["tree_sha"] == publication["source_tree_sha"] and pr["independent"] == true and
          get_in(pr, ["approval", "response"]) == "approved",
        "PR receipt or approval is absent or stale"
      )
      |> maybe_add_phase79_error(
        merge["status"] == "complete" and merge["main_sha"] == target_sha and
          merge["source_head_sha"] == publication["source_sha"] and
          merge["base_sha"] == publication["base_sha"] and
          merge["parents"] == [publication["base_sha"], publication["source_sha"]],
        "merge receipt does not prove normal source-preserving merge"
      )
      |> maybe_add_phase79_error(
        ci["status"] == "complete" and get_in(ci, ["target", "sha"]) == target_sha and
          is_map(ci["lanes"]) and map_size(ci["lanes"]) == 9 and
          Enum.all?(Map.values(ci["lanes"]), &phase79_lane_passed?(&1, target_sha)),
        "CI receipt lacks nine passing same-SHA lanes"
      )
      |> maybe_add_phase79_error(
        phase79_fleet_passed?(ci["fleet_context"], target_sha),
        "fleet context lacks passing same-SHA owner identities"
      )
      |> maybe_add_phase79_error(
        protection["status"] == "complete" and
          get_in(protection, ["target", "main_sha"]) == target_sha and
          protection["source_agreement"] == true and
          protection["readback_payload"] == desired["desired_payload"] and
          protection["capture_sha256"] == capture_sha and
          protection["desired_sha256"] == desired_sha and
          protection["rollback_sha256"] == rollback_sha and
          protection["batch_sha256"] == batch["batch_sha256"] and
          protection["post_capture_sha256"] == digest.(state["post_capture_bytes"]) and
          protection["post_inventory_sha256"] == digest.(state["post_inventory_bytes"]),
        "protection receipt/read-back does not join to approved artifacts"
      )
      |> maybe_add_phase79_error(
        is_list(risks) and risks != [] and
          Enum.all?(risks, fn item ->
            if item["severity"] in ["High", "Critical"],
              do:
                item["status"] == "resolved" and
                  String.contains?(item["evidence"] || "", target_sha),
              else: true
          end),
        "a High/Critical risk was closed without same-SHA source evidence"
      )

    errors
  end

  defp phase79_lane_passed?(lane, sha) do
    lane["state"] == "passed" and is_list(lane["evidence"]) and lane["evidence"] != [] and
      Enum.all?(lane["evidence"], fn item ->
        item["sha"] == sha and item["conclusion"] == "success" and
          Enum.all?(
            ["workflow_run_id", "job_id", "check_run_id"],
            &(is_integer(item[&1]) and item[&1] > 0)
          )
      end)
  end

  defp phase79_fleet_passed?(fleet, sha) when is_map(fleet) do
    fleet["state"] == "passed" and fleet["sha"] == sha and
      Enum.all?(
        ["workflow_run_id", "job_id", "check_run_id"],
        &(is_integer(fleet[&1]) and fleet[&1] > 0)
      )
  end

  defp phase79_fleet_passed?(_fleet, _sha), do: false

  defp maybe_add_phase79_error(errors, true, _message), do: errors
  defp maybe_add_phase79_error(errors, false, message), do: errors ++ [message]

  defp phase79_remote_field(markdown, label) do
    case Regex.run(~r/^#{Regex.escape(label)}\s*(.+)$/m, markdown, capture: :all_but_first) do
      [value] -> String.trim(value)
      _ -> nil
    end
  end

  defp phase79_unwrap_code(nil), do: nil
  defp phase79_unwrap_code(value), do: String.trim(value, "`")

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
