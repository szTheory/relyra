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

  @governance_entries [
                        {"gov-01-approval-boundary", "GOV-01", [:security_reviewer],
                         "require approval before risky mutations"},
                        {"gov-02-feature-neutral-scope", "GOV-02", [:evaluator, :developer],
                         "exclude speculative protocol expansion"}
                      ]
                      |> Enum.map(fn {id, requirement, personas, job} ->
                        %{
                          id: id,
                          requirement: requirement,
                          personas: personas,
                          job: job,
                          expected_outcome:
                            "#{job} is enforced by the active-plan governance contract",
                          evidence_kind: :security_corpus,
                          owner: "test/governance/milestone_scope_test.exs",
                          selector: "evidence_contract",
                          lane: "ci.evidence",
                          state: :existing,
                          fixture_owner:
                            ".planning/phases/73-twin-contract-and-baseline/*-PLAN.md",
                          reset_boundary:
                            "fresh test process and isolated temporary plan fixtures",
                          failure_diagnostics:
                            "#{requirement} reports the plan, approval class, or forbidden scope"
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

  @entries @existing_entries ++
             [@evid_02_entry] ++ @baseline_entries ++ @governance_entries ++ @planned_entries

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
    keys = entry |> Map.keys() |> MapSet.new()
    expected_keys = MapSet.new(@fields)
    raw_id = Map.get(entry, :id)
    id = if is_binary(raw_id) and String.trim(raw_id) != "", do: raw_id, else: "<missing-id>"

    unless keys == expected_keys do
      raise ArgumentError,
            "evidence row #{id} has invalid fields; missing=#{inspect(MapSet.difference(expected_keys, keys) |> MapSet.to_list())} unknown=#{inspect(MapSet.difference(keys, expected_keys) |> MapSet.to_list())}"
    end

    for field <- @fields -- [:personas, :evidence_kind, :state] do
      value = Map.get(entry, field)

      unless is_binary(value) and String.trim(value) != "" do
        raise ArgumentError, "evidence row #{id} has empty #{field}; expected non-empty text"
      end
    end

    validate_member!(id, :requirement, entry.requirement, @requirements)
    validate_member!(id, :evidence_kind, entry.evidence_kind, @evidence_kinds)
    validate_member!(id, :state, entry.state, @states)

    unless is_list(entry.personas) and entry.personas != [] do
      raise ArgumentError, "evidence row #{id} has no personas"
    end

    Enum.each(entry.personas, &validate_member!(id, :persona, &1, @personas))

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

  def validate_closure!(entries, completed_requirements)
      when is_list(entries) and entries != [] and is_list(completed_requirements) do
    Enum.each(entries, &validate_entry!/1)

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

  def validate_closure!(entries, completed_requirements) do
    raise ArgumentError,
          "closure evidence must be a non-empty list and completed requirements must be a list, got: #{inspect(entries)}, #{inspect(completed_requirements)}"
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

  def validate_automated_command!(command, root) when is_binary(command) do
    raw_command = String.trim(command)

    if raw_command == "" or String.contains?(raw_command, "\n") or
         Regex.match?(~r/[;&|`]|\$\(/, raw_command) do
      raise ArgumentError, "verification command is shell-shaped rather than one executable owner"
    end

    normalized =
      String.replace(raw_command, ~r/\A(?:[A-Z_][A-Z0-9_]*=\S+\s+)*/, "")

    tokens = String.split(normalized)

    case tokens do
      ["mix", "test" | arguments] ->
        validate_direct_test_command!(arguments, root)

      ["mix", alias_name] ->
        validate_check_alias!(alias_name, root)

      _other ->
        raise ArgumentError,
              "verification command must be a direct mix test or named repository check alias"
    end

    :ok
  end

  def validate_automated_command!(_command, _root) do
    raise ArgumentError, "verification command must be non-empty text"
  end

  defp validate_owner_chain!(entry, root, aliases, workflow) do
    owner_path = Path.join(root, entry.owner)

    unless File.regular?(owner_path) do
      raise ArgumentError,
            "#{entry.requirement} row #{entry.id}: missing owner file #{entry.owner}"
    end

    unless selected_test_count!(owner_path, entry.selector) > 0 do
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

    unless mandatory_security_step?(workflow, "Evidence contract", "mix #{entry.lane}") do
      raise ArgumentError,
            "#{entry.requirement} row #{entry.id}: workflow has no enabled blocking Evidence contract step for mix #{entry.lane} under jobs.security"
    end
  end

  defp selected_test_count!(path, selector) do
    path
    |> executable_test_tags!()
    |> Enum.count(&enabled_tag?(&1, selector))
  end

  defp executable_test_tags!(path) do
    ast = path |> File.read!() |> Code.string_to_quoted!()

    ast
    |> module_bodies()
    |> Enum.flat_map(&module_test_tags/1)
  rescue
    error in [SyntaxError, TokenMissingError] ->
      raise ArgumentError,
            "cannot inspect executable tests in #{path}: #{Exception.message(error)}"
  end

  defp module_bodies(ast) do
    ast
    |> Macro.prewalker()
    |> Enum.flat_map(fn
      {:defmodule, _meta, [_name, [do: body]]} -> [body]
      _node -> []
    end)
  end

  defp module_test_tags(body) do
    expressions = if match?({:__block__, _, _}, body), do: elem(body, 2), else: [body]

    module_tags =
      Enum.reduce(expressions, %{}, fn
        {:@, _meta, [{:moduletag, _attribute_meta, arguments}]}, tags ->
          Map.merge(tags, literal_tags(arguments))

        _expression, tags ->
          tags
      end)

    {_pending_tags, tests} =
      Enum.reduce(expressions, {%{}, []}, fn
        {:@, _meta, [{:tag, _attribute_meta, arguments}]}, {pending_tags, tests} ->
          {Map.merge(pending_tags, literal_tags(arguments)), tests}

        {:test, _meta, _arguments}, {pending_tags, tests} ->
          {%{}, [Map.merge(module_tags, pending_tags) | tests]}

        _expression, accumulator ->
          accumulator
      end)

    Enum.reverse(tests)
  end

  defp literal_tags([tag]) when is_atom(tag), do: %{Atom.to_string(tag) => true}

  defp literal_tags([tags]) when is_list(tags) do
    Enum.reduce(tags, %{}, fn
      {key, value}, parsed when is_atom(key) and is_atom(value) ->
        Map.put(parsed, Atom.to_string(key), value)

      {key, value}, parsed when is_atom(key) and is_binary(value) ->
        Map.put(parsed, Atom.to_string(key), value)

      {key, value}, parsed when is_atom(key) and is_number(value) ->
        Map.put(parsed, Atom.to_string(key), value)

      _unsupported, parsed ->
        parsed
    end)
  end

  defp literal_tags(_arguments), do: %{}

  defp validate_direct_test_command!(arguments, root) do
    unless "--warnings-as-errors" in arguments do
      raise ArgumentError, "direct test command is missing --warnings-as-errors"
    end

    owner_paths =
      arguments
      |> Enum.filter(&(String.ends_with?(&1, ".exs") and not String.starts_with?(&1, "-")))

    if owner_paths == [] do
      raise ArgumentError, "direct test command names no executable test owner path"
    end

    {includes, exclusions} = parse_test_filters!(arguments)

    selected =
      Enum.reduce(owner_paths, 0, fn owner, count ->
        owner_path = repository_path!(root, owner)

        effective_count =
          owner_path
          |> executable_test_tags!()
          |> Enum.count(fn tags ->
            Enum.all?(includes, &filter_matches?(tags, &1)) and
              not Enum.any?(exclusions, &filter_matches?(tags, &1))
          end)

        count + effective_count
      end)

    if selected == 0 do
      raise ArgumentError,
            "direct test command has zero selected tests after include/exclusion filters"
    end
  end

  defp validate_check_alias!(alias_name, root) do
    steps = root |> Path.join("mix.exs") |> mix_aliases!() |> Map.get(alias_name)

    case steps do
      ["cmd mix test " <> arguments] ->
        validate_direct_test_command!(String.split(arguments), root)

      nil ->
        raise ArgumentError, "named repository check alias #{alias_name} does not exist"

      _other ->
        raise ArgumentError,
              "named repository check alias #{alias_name} must be one fresh-process test command"
    end
  end

  defp parse_test_filters!(arguments) do
    {includes, exclusions} = collect_test_filters!(arguments, [], [])
    reject_duplicate_filters!(includes, "--only")
    reject_duplicate_filters!(exclusions, "--exclude")
    {Enum.reverse(includes), Enum.reverse(exclusions)}
  end

  defp collect_test_filters!([], includes, exclusions), do: {includes, exclusions}

  defp collect_test_filters!([option | rest], includes, exclusions)
       when option in ["--only", "--exclude"] do
    case rest do
      [value | remaining] when value != "" ->
        if String.starts_with?(value, "-") do
          raise ArgumentError, "#{option} is missing its filter value"
        end

        filter = parse_filter!(option, value)

        if option == "--only" do
          collect_test_filters!(remaining, [filter | includes], exclusions)
        else
          collect_test_filters!(remaining, includes, [filter | exclusions])
        end

      _other ->
        raise ArgumentError, "#{option} is missing its filter value"
    end
  end

  defp collect_test_filters!([argument | rest], includes, exclusions) do
    cond do
      String.starts_with?(argument, "--only=") ->
        value = String.replace_prefix(argument, "--only=", "")
        collect_test_filters!(rest, [parse_filter!("--only", value) | includes], exclusions)

      String.starts_with?(argument, "--exclude=") ->
        value = String.replace_prefix(argument, "--exclude=", "")
        collect_test_filters!(rest, includes, [parse_filter!("--exclude", value) | exclusions])

      true ->
        collect_test_filters!(rest, includes, exclusions)
    end
  end

  defp parse_filter!(option, ""),
    do: raise(ArgumentError, "#{option} is missing its filter value")

  defp parse_filter!(option, value) do
    case String.split(value, ":", parts: 2) do
      [key] when key != "" -> {key, :enabled}
      [key, expected] when key != "" and expected != "" -> {key, expected}
      _other -> raise ArgumentError, "#{option} has invalid filter value #{inspect(value)}"
    end
  end

  defp reject_duplicate_filters!(filters, option) do
    if length(filters) != length(Enum.uniq(filters)) do
      raise ArgumentError, "#{option} has duplicate filter values"
    end
  end

  defp filter_matches?(tags, {key, :enabled}), do: enabled_tag?(tags, key)

  defp filter_matches?(tags, {key, expected}) do
    case Map.fetch(tags, key) do
      {:ok, value} -> tag_value_string(value) == expected
      :error -> false
    end
  end

  defp enabled_tag?(tags, key) do
    case Map.fetch(tags, key) do
      {:ok, value} -> value not in [false, nil]
      :error -> false
    end
  end

  defp tag_value_string(value) when is_atom(value), do: Atom.to_string(value)
  defp tag_value_string(value), do: to_string(value)

  defp repository_path!(root, owner) do
    expanded_root = Path.expand(root)
    expanded_owner = Path.expand(owner, expanded_root)

    unless String.starts_with?(expanded_owner, expanded_root <> "/") and
             File.regular?(expanded_owner) do
      raise ArgumentError, "test owner path #{owner} is missing or outside the repository"
    end

    expanded_owner
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

  defp mandatory_security_step?(workflow, step_name, command) do
    lines = String.split(workflow, "\n")

    with {:ok, jobs_index} <- find_line(lines, ~r/^jobs:\s*$/),
         jobs <- indented_block(lines, jobs_index, 0),
         {:ok, security_index} <- find_line(jobs, ~r/^  security:\s*$/),
         security <- indented_block(jobs, security_index, 2),
         false <- false_condition_in_scope?(security, 4),
         {:ok, steps_index} <- find_line(security, ~r/^    steps:\s*$/),
         steps <- indented_block(security, steps_index, 4),
         [step] <- named_steps(steps, step_name),
         ^command <- property(step, "run"),
         false <- false_condition_in_scope?(step, 8),
         false <- truthy?(property(step, "continue-on-error")),
         true <- required_planning_triggers?(lines) do
      true
    else
      _ -> false
    end
  end

  defp find_line(lines, pattern) do
    case Enum.find_index(lines, &Regex.match?(pattern, &1)) do
      nil -> :error
      index -> {:ok, index}
    end
  end

  defp indented_block(lines, header_index, header_indent) do
    lines
    |> Enum.drop(header_index + 1)
    |> Enum.take_while(fn line ->
      String.trim(line) == "" or indentation(line) > header_indent
    end)
  end

  defp named_steps(lines, name) do
    lines
    |> Enum.with_index()
    |> Enum.filter(fn {line, _index} ->
      Regex.match?(~r/^      - name:\s*#{Regex.escape(name)}\s*$/, line)
    end)
    |> Enum.map(fn {_line, index} -> indented_block(lines, index, 6) end)
  end

  defp property(lines, key) do
    Enum.find_value(lines, fn line ->
      case Regex.run(~r/^\s+#{Regex.escape(key)}:\s*([^#]*?)\s*$/, line, capture: :all_but_first) do
        [value] -> String.trim(value)
        nil -> nil
      end
    end)
  end

  defp false_condition_in_scope?(lines, indent) do
    lines
    |> Enum.filter(&(indentation(&1) == indent))
    |> property("if")
    |> false_condition?()
  end

  defp false_condition?(value) do
    normalize_expression(value) in ["false", "0", "${{false}}", "${{0}}"]
  end

  defp truthy?(value) do
    normalize_expression(value) in ["true", "1", "${{true}}", "${{1}}"]
  end

  defp normalize_expression(nil), do: nil

  defp normalize_expression(value) do
    value
    |> String.downcase()
    |> String.replace(~r/[\s"']+/, "")
  end

  defp indentation(line), do: byte_size(line) - byte_size(String.trim_leading(line))

  defp required_planning_triggers?(lines) do
    pull_request? = Enum.any?(lines, &Regex.match?(~r/^  pull_request:\s*$/, &1))
    push_index = Enum.find_index(lines, &Regex.match?(~r/^  push:\s*$/, &1))

    main_push? =
      if push_index do
        lines
        |> indented_block(push_index, 2)
        |> Enum.any?(&Regex.match?(~r/^      - main\s*$/, &1))
      else
        false
      end

    pull_request? and main_push?
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
