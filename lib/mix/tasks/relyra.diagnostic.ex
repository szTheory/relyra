defmodule Mix.Tasks.Relyra.Diagnostic do
  @moduledoc """
  Generates a diagnostic bundle of the current Relyra state.

  Writes the output to `./relyra_diagnostic_bundle.zip`.

      mix relyra.diagnostic --repo MyApp.Repo
  """
  @shortdoc "Generate a Relyra diagnostic bundle."

  use Mix.Task

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _argv, _invalid} =
      OptionParser.parse(args,
        strict: [repo: :string],
        aliases: [r: :repo]
      )

    repo_string =
      Keyword.get(opts, :repo) ||
        Mix.raise("--repo is required")

    repo =
      try do
        String.to_existing_atom(repo_string)
      rescue
        ArgumentError -> Mix.raise("Repo module #{repo_string} is not loaded")
      end

    case Relyra.Diagnostic.create_bundle(repo: repo) do
      {:ok, zip_binary} ->
        path = "./relyra_diagnostic_bundle.zip"
        File.write!(path, zip_binary)
        Mix.shell().info("relyra.diagnostic: Successfully wrote diagnostic bundle to #{path}")
        :ok

      {:error, error} ->
        Mix.raise("relyra.diagnostic failed: #{error.message}")
    end
  end
end
