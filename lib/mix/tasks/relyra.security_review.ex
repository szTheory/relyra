defmodule Mix.Tasks.Relyra.SecurityReview do
  @moduledoc """
  Generates the checked-in security review evidence packet from executable security state.

      mix relyra.security_review
      mix relyra.security_review --output tmp/SECURITY_REVIEW_EVIDENCE.md
      mix relyra.security_review --check
  """
  @shortdoc "Generate or drift-check SECURITY_REVIEW_EVIDENCE.md."

  use Mix.Task

  alias Relyra.Security.AlgorithmPolicy

  @default_output "SECURITY_REVIEW_EVIDENCE.md"
  @legacy_override_path "test/security/strict_default_proof_test.exs"
  @escape_hatch_path "test/relyra/ecto/escape_hatch_audit_test.exs"

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
      Mix.shell().info("relyra.security_review: wrote generated report to #{output_path}")
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
          "relyra.security_review: #{output_path} matches generated security-review state"
        )

        :ok

      {:ok, _existing} ->
        Mix.raise(
          "relyra.security_review drift detected for #{output_path}; rerun mix relyra.security_review"
        )

      {:error, :enoent} ->
        Mix.raise("relyra.security_review --check target is missing: #{output_path}")

      {:error, reason} ->
        Mix.raise(
          "relyra.security_review could not read #{output_path}: #{:file.format_error(reason)}"
        )
    end
  end

  defp render_report do
    policy = AlgorithmPolicy.default()

    [
      "# Security Review Evidence",
      "",
      "Generated from executable security defaults and checked-in proof lanes in this repository.",
      "",
      "## Rerun Commands",
      "",
      "- `mix ci.security`",
      "- `mix ci.verify`",
      "- `mix relyra.conformance --check`",
      "- `mix relyra.security_review --check`",
      "- `mix test #{@legacy_override_path} --warnings-as-errors`",
      "- `mix test #{@escape_hatch_path} --warnings-as-errors`",
      "",
      "## Strict Default Evidence",
      "",
      strict_default_table(policy),
      "",
      "## Escape Hatch And Audit Evidence",
      "",
      escape_hatch_table(),
      "",
      "## Linked Artifacts",
      "",
      linked_artifacts_table(),
      ""
    ]
    |> Enum.join("\n")
  end

  defp strict_default_table(policy) do
    [
      "| claim | executable state | seam | proof command | artifact |",
      "| --- | --- | --- | --- | --- |",
      "| strict default signature policy | #{length(policy.allowed_signature_methods)} allowed signature methods; legacy SHA-1 override absent by default | `Relyra.Security.AlgorithmPolicy.default/0` | `mix test #{@legacy_override_path} --warnings-as-errors` | `test/security/strict_default_proof_test.exs` |",
      "| strict default digest policy | #{length(policy.allowed_digest_methods)} allowed digest methods; SHA-1 rejected unless time-boxed | `Relyra.Security.AlgorithmPolicy.enforce_digest_method/2` | `mix test #{@legacy_override_path} --warnings-as-errors` | `test/security/strict_default_proof_test.exs` |",
      "| relay_state raw URL rejection | opaque `rs_` handles only; raw URLs fail closed | `Relyra.Security.RelayState.validate/1` | `mix test #{@legacy_override_path} --warnings-as-errors` | `test/security/strict_default_proof_test.exs` |",
      "| signed content trust rejection | document-provided `KeyInfo` is never accepted as a trust source | `Relyra.Security.Signature.verify/3` | `mix test #{@legacy_override_path} --warnings-as-errors` | `test/security/strict_default_proof_test.exs` |"
    ]
    |> Enum.join("\n")
  end

  defp escape_hatch_table do
    [
      "| claim | executable state | seam | proof command | artifact |",
      "| --- | --- | --- | --- | --- |",
      "| legacy unsigned metadata escape hatch is explicit and time-boxed | bypass exists only through `legacy_unsigned_metadata_policy.allow_until` on a metadata source | `Relyra.Metadata.AutoRefresh.refresh/2` | `mix test #{@escape_hatch_path} --warnings-as-errors` | `test/relyra/ecto/escape_hatch_audit_test.exs` |",
      "| risky compatibility paths remain attributable | actor, cause, and correlation_id remain attached to metadata and audit rows | `Relyra.Ecto.MetadataApply` + `Relyra.Ecto.AuditWriter` | `mix test #{@escape_hatch_path} --warnings-as-errors` | `test/relyra/ecto/escape_hatch_audit_test.exs` |",
      "| reviewer-facing evidence stays redaction-safe | actor PII is omitted and correlation_id is hashed in export | `Relyra.Diagnostic.AllowList.export_audit_log/1` | `mix test #{@escape_hatch_path} --warnings-as-errors` | `test/relyra/ecto/escape_hatch_audit_test.exs` |",
      "| prior conformance and corpus regressions remain part of the packet | existing generated evidence is still required for review reruns | `Mix.Tasks.Relyra.Conformance` | `mix relyra.conformance --check` | `CONFORMANCE.md` |"
    ]
    |> Enum.join("\n")
  end

  defp linked_artifacts_table do
    [
      "| artifact | role |",
      "| --- | --- |",
      "| `SECURITY_REVIEW.md` | canonical reviewer entry point |",
      "| `docs/security_boundary.md` | trust-boundary and scope map |",
      "| `docs/security_findings.md` | findings ledger and remediation policy |",
      "| `SECURITY.md` | public policy and release prerequisites |",
      "| `CONFORMANCE.md` | generated conformance and CVE regression evidence |"
    ]
    |> Enum.join("\n")
  end
end
