defmodule Mix.Tasks.Relyra.Conformance do
  @moduledoc """
  Generates the checked-in conformance report from executable manifest state.

      mix relyra.conformance
      mix relyra.conformance --output tmp/CONFORMANCE.md
      mix relyra.conformance --check
  """
  @shortdoc "Generate or drift-check CONFORMANCE.md."

  use Mix.Task

  alias Relyra.ConformanceFixtures

  @conformance_manifest "priv/conformance/sp_manifest.json"
  @security_manifest "priv/security_corpus.json"
  @default_output "CONFORMANCE.md"

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _argv, invalid} =
      OptionParser.parse(args,
        strict: [output: :string, check: :boolean],
        aliases: [o: :output]
      )

    if invalid != [] do
      Mix.raise("invalid options: #{Enum.map_join(invalid, ", ", &elem(&1, 0))}")
    end

    output_path = output_path(opts)
    contents = render_report(load_report_rows())

    if Keyword.get(opts, :check, false) do
      check_report!(output_path, contents)
    else
      File.write!(output_path, contents)
      Mix.shell().info("relyra.conformance: wrote generated report to #{output_path}")
      :ok
    end
  end

  defp output_path(opts) do
    opts
    |> Keyword.get(:output, @default_output)
    |> Path.expand()
  end

  defp load_report_rows do
    %{
      conformance_rows: ConformanceFixtures.load_manifest!(@conformance_manifest),
      security_rows: ConformanceFixtures.load_manifest!(@security_manifest)
    }
  end

  defp check_report!(output_path, contents) do
    case File.read(output_path) do
      {:ok, existing} when existing == contents ->
        Mix.shell().info("relyra.conformance: #{output_path} matches generated manifest state")
        :ok

      {:ok, _existing} ->
        Mix.raise(
          "relyra.conformance drift detected for #{output_path}; rerun mix relyra.conformance"
        )

      {:error, :enoent} ->
        Mix.raise("relyra.conformance --check target is missing: #{output_path}")

      {:error, reason} ->
        Mix.raise(
          "relyra.conformance could not read #{output_path}: #{:file.format_error(reason)}"
        )
    end
  end

  defp render_report(%{conformance_rows: conformance_rows, security_rows: security_rows}) do
    [
      "# Conformance",
      "",
      "Generated from executable manifest state in `priv/conformance/sp_manifest.json` and `priv/security_corpus.json`.",
      "",
      "## Requirement Summary",
      "",
      requirement_summary_table(conformance_rows),
      "",
      cve_summary_lines(security_rows),
      "",
      "## CONF-01 SP Conformance Coverage",
      "",
      conformance_rows_table(conformance_rows),
      "",
      "## CVE-REG-01 Regression Coverage",
      "",
      security_rows_table(security_rows),
      "",
      scope_boundary_section()
    ]
    |> Enum.join("\n")
  end

  defp scope_boundary_section do
    [
      "## Scope boundary & diminishing returns",
      "",
      "- **Shipped surface:** strict SAML SP library with cryptographic verification, four first-class provider presets plus a generic SAML runbook, Single Logout, encrypted assertions, login trace tooling, and an operator incident playbook.",
      "- **Explicit out-of-scope (not missing):** HTTP-Artifact binding, ECP profile, Attribute Query, SCIM-in-core, additional first-class presets without generic-path investment, standalone demo app, customer-admin self-service portal.",
      "- **Demand-gated extensions (when an adopter or federation requires them):** HTTP-POST signed AuthnRequests, KMS-native `KeyResolver` adapters, signed SP metadata export and federation extensions.",
      "- **Posture:** enterprise SAML adoption flows in this library are intentionally complete for the stated scope; further protocol work ships on real demand, not coverage checklists."
    ]
    |> Enum.join("\n")
  end

  defp requirement_summary_table(conformance_rows) do
    {requirement_id, counts} = requirement_summary_row("CONF-01", conformance_rows)

    [
      "| Requirement | pass | reject | unsupported | deferred | total |",
      "| --- | --- | --- | --- | --- | --- |",
      "| #{requirement_id} | #{counts["pass"]} | #{counts["reject"]} | #{counts["unsupported"]} | #{counts["deferred"]} | #{counts["total"]} |"
    ]
    |> Enum.join("\n")
  end

  defp cve_summary_lines(security_rows) do
    families =
      security_rows
      |> Enum.map(&Map.fetch!(&1, "family"))
      |> Enum.uniq()
      |> Enum.join(", ")

    [
      "- `CVE-REG-01` fixtures pinned: #{length(security_rows)}",
      "- Families covered: #{families}"
    ]
    |> Enum.join("\n")
  end

  defp requirement_summary_row(requirement_id, rows) do
    counts =
      Enum.reduce(
        rows,
        %{"pass" => 0, "reject" => 0, "unsupported" => 0, "deferred" => 0, "total" => 0},
        fn row, acc ->
          status = Map.fetch!(row, "status")

          acc
          |> Map.update!(status, &(&1 + 1))
          |> Map.update!("total", &(&1 + 1))
        end
      )

    {requirement_id, counts}
  end

  defp conformance_rows_table(rows) do
    [
      "| Scope | status | profile | rule | binding | provenance | notes |",
      "| --- | --- | --- | --- | --- | --- | --- |"
      | Enum.map(rows, fn row ->
          "| #{Map.fetch!(row, "id")} | #{Map.fetch!(row, "status")} | #{Map.fetch!(row, "profile")} | #{Map.fetch!(row, "rule_id")} | #{Map.fetch!(row, "binding")} | #{provenance_cell(row)} | #{escape_cell(Map.get(row, "notes", ""))} |"
        end)
    ]
    |> Enum.join("\n")
  end

  defp security_rows_table(rows) do
    [
      "| Fixture | family | class | expected rejection | provenance | notes |",
      "| --- | --- | --- | --- | --- | --- |"
      | Enum.map(rows, fn row ->
          "| #{Map.fetch!(row, "id")} | #{Map.fetch!(row, "family")} | #{Map.fetch!(row, "class")} | #{Map.fetch!(row, "expected_error_type")} | #{provenance_cell(row)} | #{escape_cell(Map.get(row, "notes", ""))} |"
        end)
    ]
    |> Enum.join("\n")
  end

  defp provenance_cell(row) do
    provenance = Map.fetch!(row, "provenance")
    source = Map.get(provenance, "source", "unknown")
    section = Map.get(provenance, "section")
    kind = Map.get(provenance, "kind")

    [source, section, kind]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" / ")
    |> escape_cell()
  end

  defp escape_cell(value) do
    value
    |> to_string()
    |> String.replace("|", "\\|")
    |> String.replace("\n", " ")
  end
end
