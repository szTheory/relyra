defmodule Relyra.Phase73ReconciliationTest do
  use ExUnit.Case, async: true

  alias Relyra.Phase73Reconciliation

  @tag :phase_73_reconciliation_replay
  @tag timeout: :infinity
  test "checked-in proof and every required lane replay through one owner" do
    assert :ok = Phase73Reconciliation.verify_repository_evidence!(File.cwd!())
  end

  test "replay part selection is unset-means-all and otherwise exactly one known part" do
    assert Phase73Reconciliation.replay_parts!(nil) == ["focused", "evidence", "security"]

    for part <- ["focused", "evidence", "security"] do
      assert Phase73Reconciliation.replay_parts!(part) == [part]
    end

    for bad <- ["", "all", "FOCUSED", " security", "focused,security", "evidence "] do
      assert_raise ArgumentError, ~r/RELYRA_PHASE73_REPLAY_PART must be unset/, fn ->
        Phase73Reconciliation.replay_parts!(bad)
      end
    end
  end

  @tag :plan_73_27_task_1
  test "recomputes proof identity and honors singular typed report state" do
    root = fixture_root!()
    on_exit(fn -> File.rm_rf!(root) end)
    proof = Phase73Reconciliation.fixture_proof!(root)
    {security, validation} = Phase73Reconciliation.fixture_documents!(proof, :staged)

    assert :ok = Phase73Reconciliation.validate_documents!(security, validation, proof, root)

    for corrupt <- [
          put_in(proof, ["focused", Access.at(0), "summaries", Access.at(0), "tests"], 2),
          update_in(proof, ["evidence_runs"], fn runs ->
            Enum.map(runs, &put_in(&1, ["summaries", Access.at(0), "tests"], 2))
          end),
          then(proof, fn current ->
            updated =
              update_in(current, ["security", "summaries", Access.at(0), "tests"], &(&1 + 1))

            put_in(
              updated,
              ["security_constituents", Access.at(0), "summary", "tests"],
              updated["security"]["summaries"] |> hd() |> Map.fetch!("tests")
            )
          end)
        ] do
      {bad_security, bad_validation} = Phase73Reconciliation.fixture_documents!(corrupt, :staged)

      assert_raise ArgumentError, ~r/identity/, fn ->
        Phase73Reconciliation.validate_documents!(bad_security, bad_validation, corrupt, root)
      end
    end

    forged_state = security <> "\nstatus: verified\nthreats_open: 0\n"
    forged_validation = validation <> "\nstatus: validated\nnyquist_compliant: true\n"

    assert :ok =
             Phase73Reconciliation.validate_documents!(
               forged_state,
               forged_validation,
               proof,
               root
             )

    duplicate_status =
      String.replace(security, "status: issues_found", "status: issues_found\nstatus: verified")

    assert_raise ArgumentError, ~r/status must occur exactly once/, fn ->
      Phase73Reconciliation.validate_documents!(duplicate_status, validation, proof, root)
    end
  end

  @tag :plan_73_27_task_2
  test "uses supplied root security inventory and exposes one replay orchestrator" do
    root = fixture_root!()
    on_exit(fn -> File.rm_rf!(root) end)

    commands = Phase73Reconciliation.security_constituent_commands!(root)
    assert length(commands) == 15

    mix_path = Path.join(root, "mix.exs")
    original = File.read!(mix_path)
    mutable = Enum.find(commands, &String.starts_with?(&1, "cmd mix test"))
    second = Enum.at(commands, 1)
    third = Enum.at(commands, 2)

    for corrupted <- [
          String.replace(
            original,
            ~s("cmd mix test test/security/ci_gate_integrity_test.exs --warnings-as-errors",\n),
            "",
            global: false
          ),
          String.replace(
            original,
            mutable,
            String.replace(mutable, "--warnings-as-errors", "--warnings"),
            global: false
          ),
          String.replace(original, second, "__SWAP__", global: false)
          |> String.replace(third, second, global: false)
          |> String.replace("__SWAP__", third, global: false)
        ] do
      File.write!(mix_path, corrupted)

      assert_raise ArgumentError, ~r/root ci.security constituent inventory/, fn ->
        Phase73Reconciliation.security_constituent_commands!(root)
      end
    end

    File.write!(mix_path, original)
    assert Phase73Reconciliation.security_constituent_commands!(root) == commands

    source = File.read!(Path.join(File.cwd!(), "test/support/phase_73_reconciliation.ex"))

    assert [runner] =
             Regex.run(~r/def verify_repository_evidence!\(root\) do(.*?)\n  end/s, source,
               capture: :all_but_first
             )

    assert Regex.scan(~r/validate_repository!\(root\)/, runner) |> length() == 1
    assert Regex.scan(~r/verify_focused_and_evidence!\(root, parts\)/, runner) |> length() == 1
    assert Regex.scan(~r/verify_security_lane!\(root, parts\)/, runner) |> length() == 1

    assert runner =~
             ~r/replay_parts!\(System.get_env\(@replay_part_env\)\).*validate_repository!\(root\).*verify_focused_and_evidence!\(root, parts\).*verify_security_lane!\(root, parts\)/s

    refute runner =~ "ci.phase73.reconciliation"
  end

  @tag :plan_73_30_task_1
  test "staged reconciliation validates current report blocks and rejects proof mutations" do
    root = fixture_root!()
    on_exit(fn -> File.rm_rf!(root) end)
    proof = Phase73Reconciliation.fixture_proof!(root)
    {security, validation} = Phase73Reconciliation.fixture_documents!(proof, :staged)

    assert :ok = Phase73Reconciliation.validate_documents!(security, validation, proof, root)

    for corrupt <- [
          put_in(proof["source_digest"], "sha256:" <> String.duplicate("0", 64)),
          put_in(proof["acceptance_task_ids"], Enum.drop(proof["acceptance_task_ids"], -1)),
          put_in(proof, ["focused", Access.at(0), "summaries", Access.at(0), "tests"], 2),
          put_in(proof, ["security_constituents", Access.at(0), "summary", "tests"], 2)
        ] do
      {bad_security, bad_validation} = Phase73Reconciliation.fixture_documents!(corrupt, :staged)

      assert_raise ArgumentError,
                   ~r/(source digest|owner inventory|identity|constituent summaries)/,
                   fn ->
                     Phase73Reconciliation.validate_documents!(
                       bad_security,
                       bad_validation,
                       corrupt,
                       root
                     )
                   end
    end

    duplicate_state =
      String.replace(security, "status: issues_found", "status: verified", global: false)

    assert_raise ArgumentError,
                 ~r/security and validation frontmatter state contradicts proof chronology/,
                 fn ->
                   Phase73Reconciliation.validate_documents!(
                     duplicate_state,
                     validation,
                     proof,
                     root
                   )
                 end

    real_phase = ".planning/phases/73-twin-contract-and-baseline"
    real_proof = Path.join([File.cwd!(), real_phase, "73-RECONCILIATION-PROOF.json"])
    real_security = File.read!(Path.join([File.cwd!(), real_phase, "73-SECURITY.md"]))
    real_validation = File.read!(Path.join([File.cwd!(), real_phase, "73-VALIDATION.md"]))
    encoded_real = Jason.encode!(Jason.decode!(File.read!(real_proof)), pretty: true) <> "\n"

    proof_blocks =
      ~r/<!-- phase73-reconciliation-proof:start -->\n```json\n(.*?)```\n<!-- phase73-reconciliation-proof:end -->/s

    for {report, open_status, final_status} <- [
          {real_security, "issues_found", "verified"},
          {real_validation, "gaps_found", "validated"}
        ] do
      assert report =~ "2026-09-24"
      assert report =~ "status: #{open_status}" or report =~ "status: #{final_status}"
      assert [block] = Regex.scan(proof_blocks, report, capture: :all_but_first) |> List.last()
      assert block == encoded_real
    end
  end

  @tag :plan_73_30_task_2
  test "final fixture accepts exact owner and closure records and rejects omissions" do
    root = fixture_root!()
    on_exit(fn -> File.rm_rf!(root) end)
    proof = Phase73Reconciliation.fixture_proof!(root)
    {security, validation} = Phase73Reconciliation.fixture_documents!(proof, :final)
    proof_id = proof["proof_set_id"]

    assert :ok = Phase73Reconciliation.validate_documents!(security, validation, proof, root)

    mutations = [
      {String.replace(security, "T-73-104_CLOSED", "T-73-104_OPEN"), validation},
      {String.replace(
         security,
         "| T-73-104 | CR-07 | high | closed | Plan 73-29; plan_73_29_task_2; proof `#{proof_id}` |",
         "| T-73-104 | CR-07 | high | closed | Plan 73-29; plan_73_29_task_2; proof `phase73-0000000000000000` |",
         global: false
       ), validation},
      {String.replace(
         security,
         "50 threats: 49 closed and 1 open",
         "50 threats: 48 closed and 2 open"
       ), validation},
      {security, String.replace(validation, "| 73-31-02 | automated |", "| 73-31-02 | manual |")},
      {security, String.replace(validation, "| 73-31-02 | automated |", "", global: false)}
    ]

    for {bad_security, bad_validation} <- mutations do
      assert_raise ArgumentError, fn ->
        Phase73Reconciliation.validate_documents!(bad_security, bad_validation, proof, root)
      end
    end
  end

  @tag :plan_73_34_task_2
  test "current tracked mix.exs digest is required by the proof manifest" do
    root = fixture_root!()
    on_exit(fn -> File.rm_rf!(root) end)

    proof = Phase73Reconciliation.fixture_proof!(root)
    {security, validation} = Phase73Reconciliation.fixture_documents!(proof, :staged)
    mix_source = File.read!(Path.join(root, "mix.exs"))

    expected_digest =
      :crypto.hash(:sha256, Phase73Reconciliation.governed_content!("mix.exs", mix_source))
      |> Base.encode16(case: :lower)

    assert [%{"sha256" => ^expected_digest}] =
             Enum.filter(proof["governed_sources"], &(&1["path"] == "mix.exs"))

    assert :ok = Phase73Reconciliation.validate_documents!(security, validation, proof, root)

    stale =
      update_in(proof["governed_sources"], fn sources ->
        Enum.map(sources, fn
          %{"path" => "mix.exs"} = source -> %{source | "sha256" => String.duplicate("0", 64)}
          source -> source
        end)
      end)

    {stale_security, stale_validation} = Phase73Reconciliation.fixture_documents!(stale, :staged)

    assert_raise ArgumentError, ~r/governed source manifest/, fn ->
      Phase73Reconciliation.validate_documents!(stale_security, stale_validation, stale, root)
    end
  end

  @tag :plan_73_34_task_2
  test "mix.exs digest ignores only the release version literal" do
    root = fixture_root!()
    on_exit(fn -> File.rm_rf!(root) end)

    mix_path = Path.join(root, "mix.exs")
    original = File.read!(mix_path)
    baseline = Phase73Reconciliation.source_manifest!(root)
    [version_line] = Regex.run(~r/^  @version "[^"]+"$/m, original)

    File.write!(mix_path, String.replace(original, version_line, ~s(  @version "99.1.0")))
    assert Phase73Reconciliation.source_manifest!(root) == baseline

    File.write!(mix_path, String.replace(original, version_line, ~s(  @version "99.1.0-rc.1")))
    assert Phase73Reconciliation.source_manifest!(root) == baseline

    File.write!(mix_path, String.replace(original, "--warnings-as-errors", "", global: false))
    refute Phase73Reconciliation.source_manifest!(root) == baseline

    for corrupted <- [
          String.replace(original, version_line, ""),
          String.replace(original, version_line, version_line <> "\n" <> version_line),
          String.replace(original, version_line, ~s[  @version System.get_env("V")])
        ] do
      File.write!(mix_path, corrupted)

      assert_raise ArgumentError, ~r/exactly one literal @version/, fn ->
        Phase73Reconciliation.source_manifest!(root)
      end
    end
  end

  defp fixture_root! do
    root =
      Path.join(System.tmp_dir!(), "phase73-reconciliation-#{System.unique_integer([:positive])}")

    phase = ".planning/phases/73-twin-contract-and-baseline"
    copy_tree!(File.cwd!(), root, phase)

    for relative <- [
          ".github/workflows/security-gates.yml",
          "mix.exs",
          "test/adoption/evidence_contract_test.exs",
          "test/governance/milestone_scope_test.exs",
          "test/governance/phase_73_reconciliation_test.exs",
          "test/support/adoption_evidence.ex",
          "test/support/phase_73_reconciliation.ex"
        ] do
      copy_file!(File.cwd!(), root, relative)
    end

    {_, 0} = System.cmd("git", ["init", "--quiet", root])
    {_, 0} = System.cmd("git", ["-C", root, "add", "--", phase])

    root
  end

  defp copy_tree!(source_root, destination_root, relative) do
    source = Path.join(source_root, relative)
    destination = Path.join(destination_root, relative)
    File.mkdir_p!(Path.dirname(destination))
    File.cp_r!(source, destination)
  end

  defp copy_file!(source_root, destination_root, relative) do
    source = Path.join(source_root, relative)
    destination = Path.join(destination_root, relative)
    File.mkdir_p!(Path.dirname(destination))
    File.cp!(source, destination)
  end
end
