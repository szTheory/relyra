defmodule Relyra.AdoptionEvidence do
  @moduledoc false

  @requirements ~w(
    EVID-01 EVID-02 EVID-03
    PKG-01 PKG-02 PKG-03 PKG-04 PKG-05 PKG-06
    TWIN-01 TWIN-02 TWIN-03 TWIN-04 TWIN-05
    JOUR-01 JOUR-02 JOUR-03 JOUR-04 JOUR-05 JOUR-06
    QUAL-01 QUAL-02 QUAL-03 QUAL-04 QUAL-05 QUAL-06
    PIPE-01 PIPE-02 PIPE-03 PIPE-04 PIPE-05
    REPO-01 REPO-02 REPO-03
    GOV-01 GOV-02 EXIT-01
  )
  @personas [:evaluator, :developer, :tenant_admin, :security_reviewer, :sre, :end_user]
  @evidence_kinds [:package_contract, :application, :browser, :external_canary, :security_corpus]
  @states [:planned, :existing]
  @fields [
    :id,
    :requirement,
    :personas,
    :job,
    :expected_outcome,
    :evidence_kind,
    :owner,
    :selector,
    :lane,
    :state,
    :fixture_owner,
    :reset_boundary,
    :failure_diagnostics
  ]

  @existing_entries [
                      {"evid-01-evaluator-inspection", [:evaluator], "inspect evaluator proof",
                       "every evaluator journey names executable evidence"},
                      {"evid-01-developer-inspection", [:developer], "inspect developer proof",
                       "every developer journey names executable evidence"},
                      {"evid-01-tenant-admin-inspection", [:tenant_admin],
                       "inspect tenant-admin proof",
                       "every tenant-admin journey names executable evidence"},
                      {"evid-01-security-reviewer-inspection", [:security_reviewer],
                       "inspect security-review proof",
                       "every security-review journey names executable evidence"},
                      {"evid-01-sre-inspection", [:sre], "inspect SRE proof",
                       "every SRE journey names executable evidence"},
                      {"evid-01-end-user-inspection", [:end_user], "inspect end-user proof",
                       "every end-user journey names executable evidence"}
                    ]
                    |> Enum.map(fn {id, personas, job, expected_outcome} ->
                      %{
                        id: id,
                        requirement: "EVID-01",
                        personas: personas,
                        job: job,
                        expected_outcome: expected_outcome,
                        evidence_kind: :security_corpus,
                        owner: "test/adoption/evidence_contract_test.exs",
                        selector: "evidence_contract",
                        lane: "ci.evidence",
                        state: :existing,
                        fixture_owner: "repository evidence ledger",
                        reset_boundary: "fresh test process and immutable repository source",
                        failure_diagnostics:
                          "EVID-01 ledger-to-owner chain identifies the broken seam"
                      }
                    end)

  @evid_02_entry %{
    id: "evid-02-mandatory-ci-contract",
    requirement: "EVID-02",
    personas: [:security_reviewer],
    job: "verify deterministic acceptance ownership",
    expected_outcome: "hollow or optional evidence cannot close a requirement",
    evidence_kind: :security_corpus,
    owner: "test/adoption/evidence_contract_test.exs",
    selector: "evidence_contract",
    lane: "ci.evidence",
    state: :existing,
    fixture_owner: "repository evidence contract",
    reset_boundary: "fresh test process and temporary repository fixtures",
    failure_diagnostics: "EVID-02 reports the requirement and missing deterministic seam"
  }

  @baseline_entries [
                      {"qual-01-repository-baseline", "QUAL-01", [:security_reviewer],
                       "inspect a severity-ranked quality inventory"},
                      {"pipe-01-ci-baseline", "PIPE-01", [:sre],
                       "inspect measured CI ownership and duration"}
                    ]
                    |> Enum.map(fn {id, requirement, personas, job} ->
                      %{
                        id: id,
                        requirement: requirement,
                        personas: personas,
                        job: job,
                        expected_outcome: "#{job} has a dated, fail-closed governance contract",
                        evidence_kind: :package_contract,
                        owner: "test/governance/milestone_scope_test.exs",
                        selector: "evidence_contract",
                        lane: "ci.evidence",
                        state: :existing,
                        fixture_owner:
                          ".planning/phases/73-twin-contract-and-baseline/73-BASELINE.md",
                        reset_boundary:
                          "fresh test process and isolated temporary Markdown controls",
                        failure_diagnostics:
                          "#{requirement} reports the missing baseline field, owner, or lane"
                      }
                    end)

  @planned_rows [
    {"EVID-03", [:sre, :security_reviewer], "inspect external canary evidence", :external_canary,
     "test/adoption/external_canary_contract_test.exs", "ci.external_idp"},
    {"PKG-01", [:developer], "install from a local Hex artifact", :package_contract,
     "test/consumer/package_install_test.exs", "ci.consumer"},
    {"PKG-02", [:developer, :security_reviewer], "prove checkout internals are inaccessible",
     :package_contract, "test/consumer/package_boundary_test.exs", "ci.consumer"},
    {"PKG-03", [:developer], "install, compile, and boot from fresh state", :package_contract,
     "test/consumer/fresh_boot_test.exs", "ci.consumer"},
    {"PKG-04", [:developer, :sre], "migrate an empty PostgreSQL database", :application,
     "test/consumer/migration_test.exs", "ci.consumer"},
    {"PKG-05", [:developer], "exercise supported BEAM and dependency profiles", :package_contract,
     "test/consumer/profile_matrix_test.exs", "ci.consumer"},
    {"PKG-06", [:developer], "detect installer regeneration drift", :package_contract,
     "test/consumer/installer_drift_test.exs", "ci.consumer"},
    {"TWIN-01", [:evaluator, :tenant_admin], "inspect distinct organizations and roles",
     :application, "demo/ledger_loop/test/twin/organization_test.exs", "ci.demo_app"},
    {"TWIN-02", [:evaluator, :tenant_admin], "inspect isolated provider states", :application,
     "demo/ledger_loop/test/twin/provider_test.exs", "ci.demo_app"},
    {"TWIN-03", [:tenant_admin, :security_reviewer], "inspect certificate history", :application,
     "demo/ledger_loop/test/twin/certificate_history_test.exs", "ci.demo_app"},
    {"TWIN-04", [:sre], "follow an incident from symptom to recovery", :application,
     "demo/ledger_loop/test/twin/incident_timeline_test.exs", "ci.demo_app"},
    {"TWIN-05", [:developer, :sre], "reset deterministic safe fixtures", :application,
     "demo/ledger_loop/test/twin/reset_test.exs", "ci.demo_app"},
    {"JOUR-01", [:end_user], "complete SP-initiated login", :browser,
     "test/adoption/journeys/login_test.exs", "ci.journeys"},
    {"JOUR-02", [:end_user, :security_reviewer], "receive typed rejection without a session",
     :security_corpus, "test/adoption/journeys/rejection_test.exs", "ci.journeys"},
    {"JOUR-03", [:security_reviewer], "reject replayed assertions", :security_corpus,
     "test/adoption/journeys/replay_test.exs", "ci.journeys"},
    {"JOUR-04", [:tenant_admin, :security_reviewer], "preserve organization isolation",
     :security_corpus, "test/adoption/journeys/isolation_test.exs", "ci.journeys"},
    {"JOUR-05", [:tenant_admin], "roll metadata and certificates with audit evidence", :browser,
     "test/adoption/journeys/tenant_admin_test.exs", "ci.journeys"},
    {"JOUR-06", [:sre], "diagnose and recover with redacted evidence", :browser,
     "test/adoption/journeys/incident_recovery_test.exs", "ci.journeys"},
    {"QUAL-02", [:developer], "inspect clear production and test abstractions", :package_contract,
     "test/quality/readability_contract_test.exs", "ci.quality"},
    {"QUAL-03", [:security_reviewer], "prove security cleanup preserves invariants",
     :security_corpus, "test/quality/security_characterization_test.exs", "ci.security"},
    {"QUAL-04", [:evaluator, :developer], "read timeless standalone documentation",
     :package_contract, "test/docs/timeless_language_test.exs", "ci.docs"},
    {"QUAL-05", [:developer], "inspect an intentional tracked tree", :package_contract,
     "test/quality/tracked_tree_test.exs", "ci.quality"},
    {"QUAL-06", [:security_reviewer], "inspect dispositions for high-value findings",
     :package_contract, "test/quality/finding_disposition_test.exs", "ci.quality"},
    {"PIPE-02", [:sre, :security_reviewer], "prove every mandatory criterion has one owner",
     :security_corpus, "test/ci/ownership_contract_test.exs", "ci.quality"},
    {"PIPE-03", [:sre], "verify measured safe CI parallelism", :package_contract,
     "test/ci/parallelism_contract_test.exs", "ci.quality"},
    {"PIPE-04", [:sre, :security_reviewer], "verify workflow operational hygiene",
     :security_corpus, "test/ci/workflow_hygiene_test.exs", "ci.quality"},
    {"PIPE-05", [:developer, :sre], "run every mandatory quality lane", :security_corpus,
     "test/ci/mandatory_lanes_test.exs", "ci.quality"},
    {"REPO-01", [:developer], "verify an intentional clean repository", :package_contract,
     "test/repository/clean_state_test.exs", "ci.repository"},
    {"REPO-02", [:security_reviewer], "inspect current GitHub inventory", :external_canary,
     "test/repository/github_inventory_test.exs", "ci.repository"},
    {"REPO-03", [:security_reviewer], "approve an exact remote mutation batch", :package_contract,
     "test/repository/remote_mutation_policy_test.exs", "ci.repository"},
    {"GOV-01", [:security_reviewer], "require approval for high-impact changes", :security_corpus,
     "test/governance/milestone_scope_test.exs", "ci.governance"},
    {"GOV-02", [:evaluator, :developer], "exclude speculative protocol expansion",
     :security_corpus, "test/governance/milestone_scope_test.exs", "ci.governance"},
    {"EXIT-01", [:evaluator, :security_reviewer], "inspect final residual risk",
     :package_contract, "test/repository/residual_risk_test.exs", "ci.repository"}
  ]

  @planned_entries Enum.map(@planned_rows, fn {requirement, personas, job, evidence_kind, owner,
                                               lane} ->
                     slug = requirement |> String.downcase() |> String.replace("-", "-")

                     %{
                       id: "#{slug}-planned-owner",
                       requirement: requirement,
                       personas: personas,
                       job: job,
                       expected_outcome: "#{job} has deterministic, actionable evidence",
                       evidence_kind: evidence_kind,
                       owner: owner,
                       selector: String.downcase(String.replace(requirement, "-", "_")),
                       lane: lane,
                       state: :planned,
                       fixture_owner: "future #{requirement} implementation plan",
                       reset_boundary: "isolated fixture reset owned by #{requirement}",
                       failure_diagnostics:
                         "#{requirement} reports its unmet owner, selector, or lane"
                     }
                   end)

  @entries @existing_entries ++ [@evid_02_entry] ++ @baseline_entries ++ @planned_entries

  def entries, do: @entries

  def validate_entries!(entries) when is_list(entries) and entries != [] do
    Enum.each(entries, &validate_entry!/1)

    duplicate_ids =
      entries
      |> Enum.frequencies_by(& &1.id)
      |> Enum.filter(fn {_id, count} -> count > 1 end)
      |> Enum.map(&elem(&1, 0))

    if duplicate_ids != [] do
      raise ArgumentError, "duplicate evidence id(s): #{Enum.join(duplicate_ids, ", ")}"
    end

    requirements = MapSet.new(entries, & &1.requirement)
    personas = entries |> Enum.flat_map(& &1.personas) |> MapSet.new()

    assert_coverage!("requirement", MapSet.new(@requirements), requirements)
    assert_coverage!("persona", MapSet.new(@personas), personas)
    :ok
  end

  def validate_entries!(entries) do
    raise ArgumentError, "evidence ledger must be a non-empty list, got: #{inspect(entries)}"
  end

  def validate_entry!(entry) when is_map(entry) do
    id = Map.get(entry, :id, "<missing-id>")
    keys = entry |> Map.keys() |> MapSet.new()
    expected_keys = MapSet.new(@fields)

    unless keys == expected_keys do
      raise ArgumentError,
            "evidence row #{id} has invalid fields; missing=#{inspect(MapSet.difference(expected_keys, keys) |> MapSet.to_list())} unknown=#{inspect(MapSet.difference(keys, expected_keys) |> MapSet.to_list())}"
    end

    validate_member!(id, :requirement, entry.requirement, @requirements)
    validate_member!(id, :evidence_kind, entry.evidence_kind, @evidence_kinds)
    validate_member!(id, :state, entry.state, @states)

    if entry.personas == [] do
      raise ArgumentError, "evidence row #{id} has no personas"
    end

    Enum.each(entry.personas, &validate_member!(id, :persona, &1, @personas))

    for field <- @fields -- [:personas, :evidence_kind, :state],
        Map.get(entry, field) in [nil, ""] do
      raise ArgumentError, "evidence row #{id} has empty #{field}"
    end

    :ok
  end

  def validate_entry!(entry) do
    raise ArgumentError, "evidence row must be a map, got: #{inspect(entry)}"
  end

  def deterministic_owners(entries, requirement) do
    Enum.filter(entries, fn entry ->
      entry.requirement == requirement and entry.state == :existing and
        entry.evidence_kind != :external_canary
    end)
  end

  def validate_closure!(entries, completed_requirements) when is_list(completed_requirements) do
    completed_requirements
    |> Enum.uniq()
    |> Enum.each(fn requirement ->
      validate_member!("closure", :requirement, requirement, @requirements)

      if deterministic_owners(entries, requirement) == [] do
        raise ArgumentError,
              "#{requirement} is completed but has no existing deterministic owner; planned and external-canary evidence cannot close it"
      end
    end)

    :ok
  end

  def validate_repository!(entries, root) do
    validate_entries!(entries)

    aliases = mix_aliases!(Path.join(root, "mix.exs"))
    workflow = File.read!(Path.join(root, ".github/workflows/security-gates.yml"))

    entries
    |> Enum.filter(&(&1.state == :existing and &1.evidence_kind != :external_canary))
    |> Enum.each(&validate_owner_chain!(&1, root, aliases, workflow))

    if Regex.match?(~r/^\s*-\s+["']?\.planning\/\*\*/m, workflow) do
      raise ArgumentError,
            "workflow ignores .planning/**, so evidence status changes bypass closure"
    end

    :ok
  end

  defp validate_owner_chain!(entry, root, aliases, workflow) do
    owner_path = Path.join(root, entry.owner)

    unless File.regular?(owner_path) do
      raise ArgumentError,
            "#{entry.requirement} row #{entry.id}: missing owner file #{entry.owner}"
    end

    source = File.read!(owner_path)

    unless Regex.match?(~r/@(module)?tag\s+:#{Regex.escape(entry.selector)}\b/, source) do
      raise ArgumentError,
            "#{entry.requirement} row #{entry.id}: selector #{entry.selector} matches zero tests in #{entry.owner}"
    end

    steps = Map.get(aliases, entry.lane)

    unless is_list(steps) do
      raise ArgumentError, "#{entry.requirement} row #{entry.id}: missing alias #{entry.lane}"
    end

    unless Enum.any?(steps, fn step ->
             String.starts_with?(String.trim_leading(step), "cmd mix test ") and
               String.contains?(step, entry.owner) and
               String.contains?(step, "--only #{entry.selector}")
           end) do
      raise ArgumentError,
            "#{entry.requirement} row #{entry.id}: alias #{entry.lane} is not wired to owner #{entry.owner} with selector #{entry.selector}"
    end

    unless workflow_command?(workflow, "mix #{entry.lane}") do
      raise ArgumentError,
            "#{entry.requirement} row #{entry.id}: workflow has no executable mix #{entry.lane} command"
    end
  end

  defp mix_aliases!(path) do
    path
    |> File.read!()
    |> Code.string_to_quoted!()
    |> Macro.prewalker()
    |> Enum.reduce(%{}, fn
      {key, steps}, aliases when is_atom(key) and is_list(steps) ->
        if Enum.all?(steps, &is_binary/1),
          do: Map.put(aliases, Atom.to_string(key), steps),
          else: aliases

      _node, aliases ->
        aliases
    end)
  end

  defp workflow_command?(workflow, command) do
    workflow
    |> String.split("\n")
    |> Enum.any?(fn line ->
      case Regex.run(~r/^\s+run:\s*([^#]+?)\s*$/, line, capture: :all_but_first) do
        [run] -> String.trim(run) == command
        nil -> false
      end
    end)
  end

  defp validate_member!(id, field, value, vocabulary) do
    unless value in vocabulary do
      raise ArgumentError,
            "evidence row #{id} has unknown #{field} #{inspect(value)}; expected one of #{inspect(vocabulary)}"
    end
  end

  defp assert_coverage!(label, expected, actual) do
    missing = expected |> MapSet.difference(actual) |> MapSet.to_list() |> Enum.sort()
    unknown = actual |> MapSet.difference(expected) |> MapSet.to_list() |> Enum.sort()

    if missing != [] or unknown != [] do
      raise ArgumentError,
            "evidence ledger #{label} coverage mismatch; missing=#{inspect(missing)} unknown=#{inspect(unknown)}"
    end
  end
end
