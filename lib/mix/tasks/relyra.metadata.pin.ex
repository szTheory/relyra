defmodule Mix.Tasks.Relyra.Metadata.Pin do
  @moduledoc """
  Pins a SHA-256 trust fingerprint onto a connection's metadata source.

  Used by IaC adopters (Terraform / Pulumi) and operators who manage
  trust state via scripts. The admin LiveView fingerprint UX (deferred
  to v0.6) shares the same underlying changeset
  (`MetadataSource.auto_refresh_changeset/2`) so the two paths cannot
  drift.

      mix relyra.metadata.pin <connection_id> --fingerprint <sha256_hex> --repo MyApp.Repo

  Multiple `--fingerprint` flags may be supplied in one invocation
  (rotation window — D-17 multi-valued anchor).

  Operator MUST verify the fingerprint out-of-band before running this
  command. The fingerprint is the SHA-256 of the IdP's signing-cert
  (lowercase hex, no colons), computed via:

      openssl x509 -in metadata-signing.pem -outform DER \\
        | openssl dgst -sha256 \\
        | tr 'A-F' 'a-f'

  The pin REPLACES the source's `metadata_trust_fingerprints` array.
  Supply every currently-pinned fingerprint plus the new one to extend
  (this matches the "explicit always" Relyra strict-defaults principle).
  """
  @shortdoc "Pin a SHA-256 metadata trust fingerprint on a connection."

  use Mix.Task

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    {opts, argv, _invalid} =
      OptionParser.parse(args,
        strict: [fingerprint: :keep, repo: :string],
        aliases: [f: :fingerprint, r: :repo]
      )

    connection_id =
      List.first(argv) ||
        Mix.raise(
          "connection_id is required: mix relyra.metadata.pin <connection_id> --fingerprint <hex>"
        )

    fingerprints = Keyword.get_values(opts, :fingerprint)

    if fingerprints == [] do
      Mix.raise("at least one --fingerprint is required")
    end

    repo_string =
      Keyword.get(opts, :repo) ||
        Mix.raise("--repo is required")

    repo =
      try do
        String.to_existing_atom(repo_string)
      rescue
        ArgumentError -> Mix.raise("Repo module #{repo_string} is not loaded")
      end

    case Relyra.Metadata.pin_trust_fingerprint(
           connection_id,
           %{metadata_trust_fingerprints: Enum.map(fingerprints, &String.downcase/1)},
           repo: repo
         ) do
      {:ok, _updated} ->
        Mix.shell().info(
          "relyra.metadata.pin: pinned #{length(fingerprints)} fingerprint(s) on #{connection_id}."
        )

        :ok

      {:error, error} ->
        Mix.raise("relyra.metadata.pin failed: #{error.message}")
    end
  end
end
