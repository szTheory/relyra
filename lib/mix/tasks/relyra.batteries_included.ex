defmodule Mix.Tasks.Relyra.BatteriesIncluded do
  @moduledoc """
  Generates the checked-in batteries-included proof artifact from executable repo state.

      mix relyra.batteries_included
      mix relyra.batteries_included --output tmp/BATTERIES_INCLUDED.md
      mix relyra.batteries_included --check
  """
  @shortdoc "Generate or drift-check BATTERIES_INCLUDED.md."

  use Mix.Task

  @default_output "BATTERIES_INCLUDED.md"
  @install_test "test/mix/relyra_install_test.exs"
  @demo_test "test/testing_demo_test.exs"
  @task_test "test/mix/tasks/relyra_batteries_included_test.exs"

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
    contents = render_report()

    if Keyword.get(opts, :check, false) do
      check_report!(output_path, contents)
    else
      File.write!(output_path, contents)
      Mix.shell().info("relyra.batteries_included: wrote generated report to #{output_path}")
      :ok
    end
  end

  defp output_path(opts) do
    opts
    |> Keyword.get(:output, @default_output)
    |> Path.expand()
  end

  defp check_report!(output_path, contents) do
    case File.read(output_path) do
      {:ok, existing} when existing == contents ->
        Mix.shell().info(
          "relyra.batteries_included: #{output_path} matches generated batteries-included state"
        )

        :ok

      {:ok, _existing} ->
        Mix.raise(
          "relyra.batteries_included drift detected for #{output_path}; rerun mix relyra.batteries_included"
        )

      {:error, :enoent} ->
        Mix.raise("relyra.batteries_included --check target is missing: #{output_path}")

      {:error, reason} ->
        Mix.raise(
          "relyra.batteries_included could not read #{output_path}: #{:file.format_error(reason)}"
        )
    end
  end

  defp render_report do
    providers =
      [:okta, :entra, :google_workspace, :adfs]
      |> Enum.map(&Relyra.Provider.fetch!/1)

    [
      "# Batteries Included Proof",
      "",
      "Generated from the shipped installer, test-support seam, provider registry, and focused proof commands in this repository.",
      "",
      "## Rerun Commands",
      "",
      "- `mix ci.docs`",
      "- `mix relyra.batteries_included --check`",
      "- `mix test #{@install_test} #{@demo_test} --warnings-as-errors`",
      "",
      "## Supported Provider Scope",
      "",
      "- First-class batteries-included providers: #{provider_name_list(providers)}",
      "- Runbooks: #{provider_guide_list(providers)}",
      "",
      "## Claim To Proof Map",
      "",
      claim_table(providers),
      ""
    ]
    |> Enum.join("\n")
  end

  defp claim_table(providers) do
    provider_scope = provider_name_list(providers)

    [
      "| claim | executable state | seam | proof command | artifact |",
      "| --- | --- | --- | --- | --- |",
      "| install path is blessed and reproducible | `mix relyra.install` scaffolds the host integration surface and optional LiveAdmin contract | `Mix.Tasks.Relyra.Install.run/1` | `mix test #{@install_test} --warnings-as-errors` | `#{@install_test}` |",
      "| local-first proof uses testing fixtures | a tiny host-side ACS flow succeeds before any real IdP setup | `Relyra.Testing` data-first helpers | `mix test #{@demo_test} --warnings-as-errors` | `#{@demo_test}` |",
      "| supported provider scope stays narrow | first-class scope is limited to #{provider_scope} | `Relyra.Provider.list/0` | `mix test #{@task_test} --warnings-as-errors` | `guides/recipes/okta.md`, `guides/recipes/entra.md`, `guides/recipes/google_workspace.md`, `guides/recipes/adfs.md` |",
      "| provider runbooks stay tied to repo reality | Day-1 routing points to authoritative runbooks and no broader preset catalog | `guides/getting_started.md` + `Relyra.Provider.guide_url/1` | `mix test #{@task_test} --warnings-as-errors` | `guides/getting_started.md` |",
      "| optional admin remains a later receipt | LiveAdmin is optional and the installer can scaffold its host-side scope contract | `Relyra.LiveAdmin.ScopeProvider` | `mix test #{@install_test} --warnings-as-errors` | `#{@install_test}` |",
      "| metadata and certificate lifecycle stay observable | metadata refresh and certificate transitions have focused proof lanes and operator-facing docs | `Relyra.Metadata.AutoRefresh` + `Relyra.Ecto.CertificateInventory` | `mix test test/relyra/metadata/auto_refresh_test.exs test/relyra/ecto/certificate_inventory_transition_test.exs --warnings-as-errors` | `guides/case_studies/operator_managed_rollout.md` |",
      "| audit and telemetry are explicit follow-ons | operator receipts include audit evidence and telemetry-facing proof seams | `Relyra.Ecto.AuditWriter` + `Relyra.Telemetry` | `mix test test/relyra/ecto/audit_hardening_test.exs test/relyra/telemetry_test.exs --warnings-as-errors` | `BATTERIES_INCLUDED.md` |",
      "| scheduled refresh is not a marketing claim | background refresh remains backed by focused tests and explicit operator review posture | `Relyra.Metadata.AutoRefresh` + `Relyra.Workers.MetadataRefresh` | `mix test test/relyra/metadata/scheduler_test.exs test/relyra/workers/metadata_refresh_test.exs --warnings-as-errors` | `BATTERIES_INCLUDED.md` |",
      "| diagnostic bundle support is real and bounded | diagnostic export exists as a library-owned surface with controller and allow-list coverage | `Relyra.Diagnostic` + `Relyra.Diagnostic.AllowList` | `mix test test/phoenix/diagnostic_controller_test.exs test/relyra/diagnostic_test.exs test/relyra/diagnostic/allow_list_test.exs --warnings-as-errors` | `BATTERIES_INCLUDED.md` |"
    ]
    |> Enum.join("\n")
  end

  defp provider_name_list(providers) do
    providers
    |> Enum.map(& &1.display_name())
    |> Enum.join(", ")
  end

  defp provider_guide_list(providers) do
    providers
    |> Enum.map(fn provider ->
      "#{provider.display_name()} (`#{local_guide_path(provider.id())}`)"
    end)
    |> Enum.join("; ")
  end

  defp local_guide_path(:okta), do: "guides/recipes/okta.md"
  defp local_guide_path(:entra), do: "guides/recipes/entra.md"
  defp local_guide_path(:google_workspace), do: "guides/recipes/google_workspace.md"
  defp local_guide_path(:adfs), do: "guides/recipes/adfs.md"
end
