defmodule Relyra.Phase73Reconciliation do
  @moduledoc false

  @phase_dir ".planning/phases/73-twin-contract-and-baseline"
  @proof_path Path.join(@phase_dir, "73-RECONCILIATION-PROOF.json")
  @security_path Path.join(@phase_dir, "73-SECURITY.md")
  @validation_path Path.join(@phase_dir, "73-VALIDATION.md")

  @schema "phase73-reconciliation-proof"
  @proof_start "<!-- phase73-reconciliation-proof:start -->\n```json\n"
  @proof_end "```\n<!-- phase73-reconciliation-proof:end -->"
  @stage_marker "PHASE73_STAGED_PROOF"
  @final_marker "PHASE73_FINAL_RECONCILIATION"
  @historical_security_open_marker "Post-review correction for the 2026-09-11T19:23:38Z review"
  @historical_validation_open_marker "## Validation Audit 2026-09-11 — Current-Review Correction"
  @security_open_marker "## Post-Review Correction — 2026-09-24"
  @validation_open_marker "## Validation Audit 2026-09-24 — Current-Review Correction"

  @focused_commands [
    "mix test test/governance/milestone_scope_test.exs --only plan_73_24_task_1 --warnings-as-errors",
    "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_2 --warnings-as-errors",
    "mix test test/adoption/evidence_contract_test.exs --only plan_73_24_task_3 --warnings-as-errors",
    "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_1 --warnings-as-errors",
    "mix test test/governance/milestone_scope_test.exs --only plan_73_25_task_2 --warnings-as-errors",
    "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_1 --warnings-as-errors",
    "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_27_task_2 --warnings-as-errors",
    "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_1 --warnings-as-errors",
    "mix test test/adoption/evidence_contract_test.exs --only plan_73_28_task_2 --warnings-as-errors",
    "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_1 --warnings-as-errors",
    "mix test test/governance/milestone_scope_test.exs --only plan_73_29_task_2 --warnings-as-errors",
    "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_1 --warnings-as-errors",
    "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_30_task_2 --warnings-as-errors",
    "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_1 --warnings-as-errors",
    "mix test test/governance/milestone_scope_test.exs --only plan_73_31_task_2 --warnings-as-errors",
    "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_1 --warnings-as-errors",
    "mix test test/governance/milestone_scope_test.exs --only plan_73_32_task_2 --warnings-as-errors",
    "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_1 --warnings-as-errors",
    "mix test test/governance/milestone_scope_test.exs --only plan_73_33_task_2 --warnings-as-errors",
    "mix test test/governance/milestone_scope_test.exs --only plan_73_34_task_1 --warnings-as-errors",
    "mix test test/governance/phase_73_reconciliation_test.exs --only plan_73_34_task_2 --warnings-as-errors"
  ]
  @evidence_command "mix ci.evidence"
  @replay_part_env "RELYRA_PHASE73_REPLAY_PART"
  @replay_parts ["focused", "evidence", "security"]
  @security_command "mix ci.security"
  @security_commands [
    "test test/conformance/sp_conformance_test.exs test/mix/tasks/relyra_conformance_test.exs --only conformance --warnings-as-errors",
    "cmd mix test test/security/ci_gate_integrity_test.exs --warnings-as-errors",
    "cmd mix test test/security/strict_default_proof_test.exs --warnings-as-errors",
    "cmd mix test test/relyra/ecto/escape_hatch_audit_test.exs --warnings-as-errors",
    "cmd mix test test/security/xml/corpus_security_test.exs test/relyra/security/xml/corpus_gate_test.exs --only security_corpus --warnings-as-errors",
    "cmd mix test test/security/xml/corpus_security_test.exs --only gate02_c14n --warnings-as-errors",
    "cmd mix test test/security/xml/adversarial_crypto_test.exs --only adversarial_crypto --warnings-as-errors",
    "cmd mix test test/security/authn_request_signing_test.exs --only authn_request_signing --warnings-as-errors",
    "cmd mix test test/security/xml_enc_test.exs --warnings-as-errors",
    "cmd mix test test/security/xml_enc_adversarial_test.exs --warnings-as-errors",
    "cmd mix test test/security/metadata_attribute_injection_test.exs --warnings-as-errors",
    "cmd mix test test/security/login_trace_test.exs --warnings-as-errors",
    "cmd mix test test/security/testing_fixture_crypto_test.exs --warnings-as-errors"
  ]

  @governed_sources [
    ".github/workflows/security-gates.yml",
    ".planning/phases/73-twin-contract-and-baseline/73-24-PLAN.md",
    ".planning/phases/73-twin-contract-and-baseline/73-24-SUMMARY.md",
    ".planning/phases/73-twin-contract-and-baseline/73-25-PLAN.md",
    ".planning/phases/73-twin-contract-and-baseline/73-25-SUMMARY.md",
    ".planning/phases/73-twin-contract-and-baseline/73-26-PLAN.md",
    ".planning/phases/73-twin-contract-and-baseline/73-26-SUMMARY.md",
    ".planning/phases/73-twin-contract-and-baseline/73-27-PLAN.md",
    ".planning/phases/73-twin-contract-and-baseline/73-27-SUMMARY.md",
    ".planning/phases/73-twin-contract-and-baseline/73-28-PLAN.md",
    ".planning/phases/73-twin-contract-and-baseline/73-28-SUMMARY.md",
    ".planning/phases/73-twin-contract-and-baseline/73-29-PLAN.md",
    ".planning/phases/73-twin-contract-and-baseline/73-29-SUMMARY.md",
    ".planning/phases/73-twin-contract-and-baseline/73-30-PLAN.md",
    ".planning/phases/73-twin-contract-and-baseline/73-31-PLAN.md",
    ".planning/phases/73-twin-contract-and-baseline/73-32-PLAN.md",
    ".planning/phases/73-twin-contract-and-baseline/73-33-PLAN.md",
    ".planning/phases/73-twin-contract-and-baseline/73-34-PLAN.md",
    "mix.exs",
    "test/adoption/evidence_contract_test.exs",
    "test/governance/milestone_scope_test.exs",
    "test/governance/phase_73_reconciliation_test.exs",
    "test/support/adoption_evidence.ex",
    "test/support/phase_73_reconciliation.ex"
  ]

  @record_keys ~w(schema version proof_set_id captured_at source_digest governed_sources acceptance_task_ids focused evidence_runs security security_constituents)
  @result_keys ~w(command duration_ms exit_code summaries output_sha256)
  @summary_keys ~w(tests failures excluded)

  def capture!(root, output_path) do
    root = Path.expand(root)
    manifest = source_manifest!(root)
    task_ids = acceptance_task_ids!(root)
    focused = Enum.map(@focused_commands, &run_command!(root, &1, 1))
    evidence = for _run <- 1..3, do: run_command!(root, @evidence_command, 1)

    require_equal_evidence_vectors!(evidence)

    security_commands = security_constituent_commands!(root)
    security = run_command!(root, @security_command, length(security_commands))

    security_constituents =
      Enum.zip_with(security_commands, security["summaries"], fn command, summary ->
        %{"command" => command, "summary" => summary}
      end)

    source_digest = source_digest(manifest)

    normalized_results = %{
      "focused" => result_vectors(focused),
      "evidence" => result_vectors(evidence),
      "security" => result_vector(security),
      "security_constituents" => security_constituents
    }

    proof_set_id = proof_identity(source_digest, normalized_results)

    proof = %{
      "schema" => @schema,
      "version" => 1,
      "proof_set_id" => proof_set_id,
      "captured_at" => DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
      "source_digest" => source_digest,
      "governed_sources" => manifest,
      "acceptance_task_ids" => task_ids,
      "focused" => focused,
      "evidence_runs" => evidence,
      "security" => security,
      "security_constituents" => security_constituents
    }

    validate_proof!(proof, root)
    atomic_write!(Path.expand(output_path, root), encode_proof(proof))
    proof
  end

  def validate_repository!(root) do
    root = Path.expand(root)
    security = File.read!(Path.join(root, @security_path))
    validation = File.read!(Path.join(root, @validation_path))
    proof_path = Path.join(root, @proof_path)

    if File.exists?(proof_path) do
      proof = proof_path |> File.read!() |> Jason.decode!()
      validate_documents!(security, validation, proof, root)
    else
      validate_open_documents!(security, validation)
    end
  end

  def validate_documents!(security, validation, proof, root) do
    root = Path.expand(root)
    validate_proof!(proof, root)

    security_block = current_embedded_proof!(security)
    validation_block = current_embedded_proof!(validation)
    canonical = encode_proof(proof)

    unless security_block == canonical and validation_block == canonical do
      raise ArgumentError,
            "reports must embed one identical canonical proof record for the current evidence"
    end

    security_state = report_state!(security, :security)
    validation_state = report_state!(validation, :validation)

    stage? =
      current_marker_before?(security, @security_open_marker, @stage_marker) and
        current_marker_before?(validation, @validation_open_marker, @stage_marker)

    final? =
      marker_after_latest?(security, @proof_start, @final_marker) and
        marker_after_latest?(validation, @proof_start, @final_marker)

    unless stage? do
      raise ArgumentError, "proof-bearing reports must contain the staged chronology row"
    end

    staged_state? =
      security_state == %{status: "issues_found", threats_open: 7} and
        validation_state == %{status: "gaps_found", nyquist_compliant: false}

    final_state? =
      security_state == %{status: "verified", threats_open: 0} and
        validation_state == %{status: "validated", nyquist_compliant: true}

    unless (staged_state? and not final?) or (final_state? and final?) do
      raise ArgumentError,
            "security and validation frontmatter state contradicts proof chronology"
    end

    assert_chronology!(security, @security_open_marker, stage?, final?)
    assert_chronology!(validation, @validation_open_marker, stage?, final?)

    if final? do
      validate_final_documents!(security, validation, proof)
    else
      validate_staged_documents!(security, validation)
    end
  end

  def verify_focused_and_evidence!(root, parts \\ @replay_parts) do
    root = Path.expand(root)
    proof = read_proof!(root)
    validate_proof!(proof, root)

    if "focused" in parts do
      fresh_focused = Enum.map(@focused_commands, &run_command!(root, &1, 1))

      unless result_vectors(fresh_focused) == result_vectors(proof["focused"]) do
        raise ArgumentError, "fresh focused result vectors differ from canonical proof"
      end
    end

    if "evidence" in parts do
      fresh_evidence = for _run <- 1..3, do: run_command!(root, @evidence_command, 1)
      require_equal_evidence_vectors!(fresh_evidence)

      unless result_vectors(fresh_evidence) == result_vectors(proof["evidence_runs"]) do
        raise ArgumentError, "fresh evidence result vectors differ from canonical proof"
      end
    end

    :ok
  end

  def verify_security_lane!(root, parts \\ @replay_parts) do
    root = Path.expand(root)
    proof = read_proof!(root)
    validate_proof!(proof, root)

    if "security" in parts do
      commands = security_constituent_commands!(root)
      fresh = run_command!(root, @security_command, length(commands))

      unless result_vector(fresh) == result_vector(proof["security"]) do
        raise ArgumentError, "fresh security result vector differs from canonical proof"
      end
    end

    :ok
  end

  # SEED-004 item 10: CI replays the three parts on parallel matrix legs and
  # ci-gate requires every leg. Unset (local runs, the Phase 78 cold manifest)
  # replays every part; any other value is rejected, never treated as "all".
  def verify_repository_evidence!(root) do
    parts = replay_parts!(System.get_env(@replay_part_env))
    :ok = validate_repository!(root)
    :ok = verify_focused_and_evidence!(root, parts)
    :ok = verify_security_lane!(root, parts)
    :ok
  end

  def replay_parts!(nil), do: @replay_parts
  def replay_parts!(part) when part in @replay_parts, do: [part]

  def replay_parts!(part) do
    raise ArgumentError,
          "#{@replay_part_env} must be unset or one of #{Enum.join(@replay_parts, ", ")}; got #{inspect(part)}"
  end

  def source_manifest!(root) do
    root = Path.expand(root)

    if @governed_sources != Enum.sort(@governed_sources) or
         length(@governed_sources) != length(Enum.uniq(@governed_sources)) do
      raise ArgumentError, "governed source inventory must be sorted and unique"
    end

    Enum.map(@governed_sources, fn relative ->
      path = Path.join(root, relative)

      unless File.regular?(path) do
        raise ArgumentError, "missing governed source #{relative}"
      end

      %{"path" => relative, "sha256" => sha256(governed_content!(relative, File.read!(path)))}
    end)
  end

  # Release Please rewrites only the `@version` literal in mix.exs on every release
  # PR. Pin everything else byte-for-byte (aliases, deps, audit ignores) and
  # normalize that single literal so a version bump does not invalidate the proof.
  @mix_version_line ~r/^  @version "\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?"$/m

  def governed_content!("mix.exs", content) do
    case Regex.scan(@mix_version_line, content) do
      [_] -> Regex.replace(@mix_version_line, content, ~s(  @version "0.0.0-governed"))
      _ -> raise ArgumentError, "mix.exs must define exactly one literal @version"
    end
  end

  def governed_content!(_relative, content), do: content

  def acceptance_task_ids!(root) do
    {tracked_output, 0} =
      System.cmd("git", ["-C", root, "ls-files", "--", "#{@phase_dir}/73-*-PLAN.md"])

    paths =
      tracked_output
      |> String.split("\n", trim: true)
      |> Enum.map(&Path.join(root, &1))
      |> Enum.sort()

    unless length(paths) == 34 do
      raise ArgumentError, "expected exactly 34 tracked Phase 73 plans, found #{length(paths)}"
    end

    ids =
      Enum.flat_map(paths, fn path ->
        plan = path |> Path.basename() |> String.replace_suffix("-PLAN.md", "")

        ~r/<task\b[^>]*>.*?<\/task>/s
        |> Regex.scan(File.read!(path))
        |> Enum.with_index(1)
        |> Enum.flat_map(fn {[task], index} ->
          if Regex.match?(~r/<acceptance_criteria>.+?<\/acceptance_criteria>/s, task) do
            ["#{plan}-#{index |> Integer.to_string() |> String.pad_leading(2, "0")}"]
          else
            []
          end
        end)
      end)

    unless length(ids) == 72 and length(Enum.uniq(ids)) == 72 and List.last(ids) == "73-34-02" do
      raise ArgumentError,
            "acceptance owner inventory must contain 72 unique task IDs through 73-34-02; got #{inspect(ids)}"
    end

    ids
  end

  def fixture_proof!(root) do
    manifest = source_manifest!(root)
    task_ids = acceptance_task_ids!(root)
    summary = %{"tests" => 1, "failures" => 0, "excluded" => 0}

    result = fn command ->
      %{
        "command" => command,
        "duration_ms" => 1,
        "exit_code" => 0,
        "summaries" => [summary],
        "output_sha256" => String.duplicate("a", 64)
      }
    end

    security_commands = security_constituent_commands!(root)
    security_summaries = Enum.map(security_commands, fn _command -> summary end)

    security = %{
      "command" => @security_command,
      "duration_ms" => 1,
      "exit_code" => 0,
      "summaries" => security_summaries,
      "output_sha256" => String.duplicate("b", 64)
    }

    proof = %{
      "schema" => @schema,
      "version" => 1,
      "proof_set_id" => "phase73-0000000000000000",
      "captured_at" => "2026-09-11T00:00:00Z",
      "source_digest" => source_digest(manifest),
      "governed_sources" => manifest,
      "acceptance_task_ids" => task_ids,
      "focused" => Enum.map(@focused_commands, result),
      "evidence_runs" => Enum.map(1..3, fn _run -> result.(@evidence_command) end),
      "security" => security,
      "security_constituents" =>
        Enum.zip_with(security_commands, security_summaries, fn command, item_summary ->
          %{"command" => command, "summary" => item_summary}
        end)
    }

    proof =
      put_in(
        proof["proof_set_id"],
        proof_identity(proof["source_digest"], normalized_result_vectors(proof))
      )

    validate_proof!(proof, root)
    proof
  end

  def fixture_documents!(proof, state) when state in [:staged, :final] do
    block = proof_block(proof)
    owner_rows = Enum.map_join(proof["acceptance_task_ids"], "\n", &"| #{&1} | automated |")

    security = """
    ---
    phase: "73"
    slug: "twin-contract-and-baseline"
    status: #{if state == :final, do: "verified", else: "issues_found"}
    threats_open: #{if state == :final, do: "0", else: "7"}
    ---
    #{@historical_security_open_marker}
    #{@security_open_marker}
    | T-73-12 | medium | open |
    | T-73-98 | high | open |
    | T-73-99 | high | open |
    | T-73-100 | high | open |
    | T-73-101 | high | open |
    | T-73-102 | high | open |
    | T-73-103 | high | open |
    | T-73-104 | high | open |
    #{@stage_marker}
    #{block}
    #{if state == :final, do: fixture_security_final(proof), else: ""}
    """

    validation = """
    ---
    phase: "73"
    slug: "twin-contract-and-baseline"
    status: #{if state == :final, do: "validated", else: "gaps_found"}
    nyquist_compliant: #{state == :final}
    ---
    #{@historical_validation_open_marker}
    #{@validation_open_marker}
    #{@stage_marker}
    #{block}
    #{if state == :final, do: @final_marker <> "\n" <> owner_rows, else: ""}
    """

    {security, validation}
  end

  def proof_block(proof), do: @proof_start <> encode_proof(proof) <> @proof_end
  def encode_proof(proof), do: Jason.encode!(proof, pretty: true) <> "\n"

  defp fixture_security_final(proof) do
    proof_id = proof["proof_set_id"]

    closures = [
      {98, "CR-01", "Plan 73-27; plan_73_27_task_1 and plan_73_27_task_2"},
      {99, "CR-02", "Plan 73-27; plan_73_27_task_1"},
      {100, "CR-03", "Plan 73-28; plan_73_28_task_1"},
      {101, "CR-04", "Plan 73-27; plan_73_27_task_2"},
      {102, "CR-05", "Plan 73-28; plan_73_28_task_2 and plan_73_30_task_1"},
      {103, "CR-06", "Plan 73-29; plan_73_29_task_1"},
      {104, "CR-07", "Plan 73-29; plan_73_29_task_2"}
    ]

    closures =
      Enum.map_join(closures, "\n", fn {id, finding, owners} ->
        "| T-73-#{id} | #{finding} | high | closed | #{owners}; proof `#{proof_id}` |\nT-73-#{id}_CLOSED"
      end)

    @final_marker <> "\n" <> closures <> "\n50 threats: 49 closed and 1 open"
  end

  defp validate_open_documents!(security, validation) do
    partial? =
      Enum.any?([security, validation], fn document ->
        String.contains?(document, @stage_marker) or String.contains?(document, @final_marker) or
          String.contains?(document, @proof_start)
      end)

    if partial?, do: raise(ArgumentError, "partial reconciliation state is not allowed")

    require_state!(report_state!(security, :security), %{status: "issues_found", threats_open: 7})
    require_contains!(security, @security_open_marker, "open security chronology")

    require_state!(report_state!(validation, :validation), %{
      status: "gaps_found",
      nyquist_compliant: false
    })

    require_contains!(validation, @validation_open_marker, "open validation chronology")
    :ok
  end

  defp validate_staged_documents!(security, validation) do
    require_state!(report_state!(security, :security), %{status: "issues_found", threats_open: 7})

    require_state!(report_state!(validation, :validation), %{
      status: "gaps_found",
      nyquist_compliant: false
    })

    :ok
  end

  defp validate_final_documents!(security, validation, proof) do
    require_state!(report_state!(security, :security), %{status: "verified", threats_open: 0})
    require_contains!(security, "50 threats: 49 closed and 1 open", "final threat totals")
    require_contains!(security, ~r/^\| T-73-12 \|.*\| open/m, "historical open T-73-12")

    final_security_section = security |> String.split(@final_marker) |> List.last()

    for id <- 98..104 do
      require_contains!(final_security_section, "T-73-#{id}_CLOSED", "T-73-#{id} closure")

      proof_id = Regex.escape(proof["proof_set_id"])

      unless Regex.match?(
               ~r/^\| T-73-#{id} \|.*\| closed \|.*#{proof_id}.*\|$/m,
               final_security_section
             ) do
        raise ArgumentError, "T-73-#{id} closure must reference the current proof set"
      end
    end

    require_state!(report_state!(validation, :validation), %{
      status: "validated",
      nyquist_compliant: true
    })

    final_section = validation |> String.split(@final_marker) |> List.last()

    owner_rows =
      Regex.scan(~r/^\| (73-\d{2}-\d{2}) \| ([^|]+) \|$/m, final_section, capture: :all_but_first)

    owner_ids = Enum.map(owner_rows, fn [id, _owner_type] -> id end)
    owner_types = Enum.map(owner_rows, fn [_id, owner_type] -> String.trim(owner_type) end)

    expected = proof["acceptance_task_ids"]

    unless owner_ids == expected and length(owner_ids) == length(Enum.uniq(owner_ids)) and
             Enum.all?(owner_types, &(&1 == "automated")) do
      raise ArgumentError,
            "validation owner map must exactly equal the canonical 72-task automated inventory; expected=#{inspect(expected)} actual=#{inspect(owner_ids)} types=#{inspect(owner_types)}"
    end

    :ok
  end

  defp validate_proof!(proof, root) when is_map(proof) do
    exact_keys!(proof, @record_keys, "proof record")
    require_equal!(proof["schema"], @schema, "proof schema")
    require_equal!(proof["version"], 1, "proof version")

    unless is_binary(proof["proof_set_id"]) and
             String.match?(proof["proof_set_id"], ~r/^phase73-[0-9a-f]{16}$/) do
      raise ArgumentError, "proof_set_id must be a complete canonical Phase 73 identity"
    end

    case DateTime.from_iso8601(proof["captured_at"] || "") do
      {:ok, _date_time, 0} -> :ok
      _other -> raise ArgumentError, "captured_at must be an ISO-8601 UTC timestamp"
    end

    manifest = source_manifest!(root)
    require_equal!(proof["governed_sources"], manifest, "governed source manifest")
    require_equal!(proof["source_digest"], source_digest(manifest), "governed source digest")

    require_equal!(
      proof["acceptance_task_ids"],
      acceptance_task_ids!(root),
      "acceptance owner inventory"
    )

    validate_result_list!(proof["focused"], @focused_commands, "focused")

    validate_result_list!(
      proof["evidence_runs"],
      List.duplicate(@evidence_command, 3),
      "evidence"
    )

    require_equal_evidence_vectors!(proof["evidence_runs"])
    validate_result!(proof["security"], @security_command, "security")

    commands = security_constituent_commands!(root)
    constituents = proof["security_constituents"]

    unless is_list(constituents) and length(constituents) == length(commands) do
      raise ArgumentError, "security constituent inventory is incomplete or ambiguous"
    end

    Enum.zip_with(constituents, commands, fn constituent, command ->
      exact_keys!(constituent, ~w(command summary), "security constituent")
      require_equal!(constituent["command"], command, "security constituent command")
      validate_summary!(constituent["summary"], "security constituent")
    end)

    require_equal!(
      Enum.map(constituents, & &1["summary"]),
      proof["security"]["summaries"],
      "security constituent summaries"
    )

    normalized_results = %{
      "focused" => result_vectors(proof["focused"]),
      "evidence" => result_vectors(proof["evidence_runs"]),
      "security" => result_vector(proof["security"]),
      "security_constituents" => constituents
    }

    require_equal!(
      proof["proof_set_id"],
      proof_identity(proof["source_digest"], normalized_results),
      "proof identity"
    )

    :ok
  end

  defp validate_proof!(_proof, _root), do: raise(ArgumentError, "proof record must be an object")

  defp validate_result_list!(results, commands, label) do
    unless is_list(results) and length(results) == length(commands) do
      raise ArgumentError, "#{label} result inventory is incomplete"
    end

    Enum.zip_with(results, commands, &validate_result!(&1, &2, label))
  end

  defp validate_result!(result, command, label) when is_map(result) do
    exact_keys!(result, @result_keys, "#{label} result")
    require_equal!(result["command"], command, "#{label} command")
    require_equal!(result["exit_code"], 0, "#{label} exit result")

    unless is_integer(result["duration_ms"]) and result["duration_ms"] >= 0 do
      raise ArgumentError, "#{label} duration must be monotonic milliseconds"
    end

    if label == "evidence" and result["duration_ms"] >= 60_000 do
      raise ArgumentError, "evidence duration must remain below 60000ms"
    end

    unless is_binary(result["output_sha256"]) and
             Regex.match?(~r/^[0-9a-f]{64}$/, result["output_sha256"]) do
      raise ArgumentError, "#{label} output digest must be complete SHA-256"
    end

    summaries = result["summaries"]

    unless is_list(summaries) and summaries != [] do
      raise ArgumentError, "#{label} output must contain positive ExUnit summaries"
    end

    Enum.each(summaries, &validate_summary!(&1, label))
    :ok
  end

  defp validate_result!(_result, _command, label),
    do: raise(ArgumentError, "#{label} result must be an object")

  defp validate_summary!(summary, label) when is_map(summary) do
    exact_keys!(summary, @summary_keys, "#{label} summary")

    unless is_integer(summary["tests"]) and summary["tests"] > 0 and
             summary["failures"] == 0 and is_integer(summary["excluded"]) and
             summary["excluded"] >= 0 do
      raise ArgumentError, "#{label} summary must select positive tests with zero failures"
    end
  end

  defp validate_summary!(_summary, label),
    do: raise(ArgumentError, "#{label} summary must be an object")

  defp require_equal_evidence_vectors!(runs) do
    vectors = Enum.map(runs, &result_vector/1)

    unless length(vectors) == 3 and length(Enum.uniq(vectors)) == 1 do
      raise ArgumentError, "three evidence result vectors must be identical"
    end

    :ok
  end

  defp run_command!(root, command, expected_summaries) do
    ["mix" | arguments] = String.split(command, " ", trim: true)
    started = System.monotonic_time(:millisecond)

    {output, exit_code} =
      System.cmd("mix", arguments,
        cd: root,
        stderr_to_stdout: true,
        env: [
          {"MIX_ENV", "test"},
          {"ASDF_ELIXIR_VERSION", "1.19.5-otp-28"},
          {"ASDF_ERLANG_VERSION", "28.4.1"}
        ]
      )

    duration_ms = System.monotonic_time(:millisecond) - started
    summaries = parse_summaries!(output)

    unless exit_code == 0 do
      raise ArgumentError, "#{command} exited #{exit_code}:\n#{output}"
    end

    unless length(summaries) == expected_summaries do
      raise ArgumentError,
            "#{command} produced #{length(summaries)} ExUnit summaries; expected #{expected_summaries}"
    end

    %{
      "command" => command,
      "duration_ms" => duration_ms,
      "exit_code" => exit_code,
      "summaries" => summaries,
      "output_sha256" => sha256(output)
    }
  end

  defp parse_summaries!(output) do
    ~r/^(\d+) tests?, (\d+) failures(?: \((\d+) excluded\)|, (\d+) excluded)?$/m
    |> Regex.scan(output, capture: :all_but_first)
    |> Enum.map(fn captures ->
      [tests, failures, parenthesized, comma] =
        captures ++ List.duplicate("", 4 - length(captures))

      excluded = Enum.find([parenthesized, comma], "", &(&1 not in [nil, ""]))

      %{
        "tests" => String.to_integer(tests),
        "failures" => String.to_integer(failures),
        "excluded" => if(excluded in [nil, ""], do: 0, else: String.to_integer(excluded))
      }
    end)
  end

  def security_constituent_commands!(root) do
    aliases =
      root |> Path.join("mix.exs") |> File.read!() |> Code.string_to_quoted!() |> aliases_ast!()

    actual =
      expand_alias!(aliases, :"ci.security", MapSet.new())
      |> Enum.filter(&exunit_command?/1)

    require_equal!(actual, @security_commands, "root ci.security constituent inventory")
    actual
  end

  defp aliases_ast!(ast) do
    {_ast, found} =
      Macro.prewalk(ast, nil, fn
        {:defp, _, [{:aliases, _, nil}, [do: body]]} = node, _acc -> {node, body}
        node, acc -> {node, acc}
      end)

    case found do
      pairs when is_list(pairs) -> Map.new(pairs)
      _ -> raise ArgumentError, "mix.exs must define a literal aliases/0 list"
    end
  rescue
    _ -> raise ArgumentError, "mix.exs must define a literal aliases/0 list"
  end

  defp expand_alias!(aliases, name, seen) do
    if MapSet.member?(seen, name), do: raise(ArgumentError, "recursive Mix alias #{name}")
    steps = Map.fetch!(aliases, name)
    seen = MapSet.put(seen, name)

    Enum.flat_map(steps, fn step ->
      first = step |> String.split(" ", parts: 2) |> hd() |> String.to_atom()

      if Map.has_key?(aliases, first) do
        expand_alias!(aliases, first, seen)
      else
        [step]
      end
    end)
  end

  defp exunit_command?("test " <> _rest), do: true
  defp exunit_command?("cmd mix test " <> _rest), do: true
  defp exunit_command?(_command), do: false

  defp read_proof!(root) do
    root |> Path.join(@proof_path) |> File.read!() |> Jason.decode!()
  end

  defp current_embedded_proof!(document) do
    pattern = ~r/#{Regex.escape(@proof_start)}(.*?)#{Regex.escape(@proof_end)}/s
    matches = Regex.scan(pattern, document, capture: :all_but_first)

    case List.last(matches) do
      [proof] -> proof
      nil -> raise ArgumentError, "report must contain a current canonical proof block"
    end
  end

  defp assert_chronology!(document, open_marker, true, final?) do
    historical_marker =
      if open_marker == @security_open_marker,
        do: @historical_security_open_marker,
        else: @historical_validation_open_marker

    historical_offset = offset!(document, historical_marker)
    open_offset = offset!(document, open_marker)
    stage_offset = last_offset!(document, @stage_marker)
    proof_offset = last_offset!(document, @proof_start)

    unless historical_offset < open_offset and open_offset < stage_offset and
             stage_offset < proof_offset do
      raise ArgumentError, "open -> staged -> final chronology is invalid"
    end

    if final? and not (proof_offset < last_offset!(document, @final_marker)) do
      raise ArgumentError, "open -> staged -> final chronology is invalid"
    end
  end

  defp last_offset!(document, marker) do
    case :binary.matches(document, marker) do
      [] -> raise ArgumentError, "chronology marker is missing: #{marker}"
      matches -> matches |> List.last() |> elem(0)
    end
  end

  defp current_marker_before?(document, current_marker, marker) do
    offset!(document, current_marker) < last_offset!(document, marker)
  end

  defp marker_after_latest?(document, earlier_marker, later_marker) do
    case {List.last(:binary.matches(document, earlier_marker)),
          List.last(:binary.matches(document, later_marker))} do
      {{earlier_offset, _}, {later_offset, _}} -> later_offset > earlier_offset
      _missing -> false
    end
  end

  defp offset!(document, marker) do
    case :binary.match(document, marker) do
      {offset, _length} -> offset
      :nomatch -> raise ArgumentError, "chronology marker is missing: #{marker}"
    end
  end

  defp result_vectors(results), do: Enum.map(results, &result_vector/1)

  defp result_vector(result),
    do: %{
      "command" => result["command"],
      "exit_code" => result["exit_code"],
      "summaries" => result["summaries"]
    }

  defp source_digest(manifest) do
    manifest
    |> Enum.map_join(fn %{"path" => path, "sha256" => digest} ->
      "#{byte_size(path)}:#{path}:#{digest}\n"
    end)
    |> then(&("sha256:" <> sha256(&1)))
  end

  defp proof_identity(source_digest, normalized_results) do
    "phase73-" <> binary_part(sha256(source_digest <> Jason.encode!(normalized_results)), 0, 16)
  end

  defp normalized_result_vectors(proof) do
    %{
      "focused" => result_vectors(proof["focused"]),
      "evidence" => result_vectors(proof["evidence_runs"]),
      "security" => result_vector(proof["security"]),
      "security_constituents" => proof["security_constituents"]
    }
  end

  defp report_state!(document, kind) do
    frontmatter =
      case Regex.run(~r/\A---\r?\n(.*?)\r?\n---(?:\r?\n|$)/s, document, capture: :all_but_first) do
        [body] -> body
        _ -> raise ArgumentError, "#{kind} report requires one leading YAML frontmatter block"
      end

    status =
      frontmatter_scalar!(
        frontmatter,
        "status",
        ~r/^(?:issues_found|verified|gaps_found|validated)$/
      )

    case kind do
      :security ->
        %{status: status, threats_open: frontmatter_integer!(frontmatter, "threats_open")}

      :validation ->
        %{
          status: status,
          nyquist_compliant: frontmatter_boolean!(frontmatter, "nyquist_compliant")
        }
    end
  end

  defp frontmatter_scalar!(frontmatter, key, allowed) do
    value = frontmatter_value!(frontmatter, key)

    unless Regex.match?(allowed, value) do
      raise ArgumentError, "frontmatter #{key} has unsupported scalar #{inspect(value)}"
    end

    value
  end

  defp frontmatter_integer!(frontmatter, key) do
    value = frontmatter_value!(frontmatter, key)

    case Integer.parse(value) do
      {integer, ""} when integer >= 0 -> integer
      _ -> raise ArgumentError, "frontmatter #{key} must be one non-negative integer"
    end
  end

  defp frontmatter_boolean!(frontmatter, key) do
    case frontmatter_value!(frontmatter, key) do
      "true" ->
        true

      "false" ->
        false

      value ->
        raise ArgumentError, "frontmatter #{key} must be true or false, got #{inspect(value)}"
    end
  end

  defp frontmatter_value!(frontmatter, key) do
    matches =
      Regex.scan(~r/^#{Regex.escape(key)}:[ \t]*([^\r\n]*)\r?$/m, frontmatter,
        capture: :all_but_first
      )

    case matches do
      [[value]] when value != "" -> value
      [[""]] -> raise ArgumentError, "frontmatter #{key} must have a single-line value"
      _ -> raise ArgumentError, "frontmatter #{key} must occur exactly once"
    end
  end

  defp require_state!(actual, expected) do
    require_equal!(actual, expected, "live frontmatter state")
  end

  defp exact_keys!(map, expected, label) do
    actual = map |> Map.keys() |> Enum.sort()
    expected = Enum.sort(expected)

    unless actual == expected do
      raise ArgumentError,
            "#{label} fields must be exact; expected=#{inspect(expected)} actual=#{inspect(actual)}"
    end
  end

  defp require_equal!(actual, expected, label) do
    unless actual == expected do
      raise ArgumentError,
            "#{label} mismatch; expected=#{inspect(expected)} actual=#{inspect(actual)}"
    end
  end

  defp require_contains!(document, %Regex{} = pattern, label) do
    unless Regex.match?(pattern, document), do: raise(ArgumentError, "missing #{label}")
  end

  defp require_contains!(document, text, label) do
    unless String.contains?(document, text), do: raise(ArgumentError, "missing #{label}")
  end

  defp sha256(value), do: :crypto.hash(:sha256, value) |> Base.encode16(case: :lower)

  defp atomic_write!(path, contents) do
    File.mkdir_p!(Path.dirname(path))
    temporary = path <> ".tmp-#{System.unique_integer([:positive, :monotonic])}"

    try do
      File.write!(temporary, contents, [:binary])
      File.rename!(temporary, path)
    after
      File.rm(temporary)
    end
  end
end
