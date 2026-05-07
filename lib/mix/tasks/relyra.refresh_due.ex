defmodule Mix.Tasks.Relyra.RefreshDue do
  @moduledoc """
  Runs any due Phase 21 scheduled metadata refreshes once.

  Suitable for system cron, `kubectl run`, fly.io scheduled machines, and
  any other host scheduler that prefers a CLI invocation over an Oban
  worker. Adopters who use Oban add the documented Cron one-liner
  instead — see the README "Operations" section.

      mix relyra.refresh_due --repo MyApp.Repo

  Returns `:ok` on a clean tick (including the no-due-sources case, which
  emits the `[:relyra, :saml, :metadata, :auto_refresh, :skipped]` event).
  """
  @shortdoc "Refresh any metadata sources whose schedule is due."

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
        Mix.raise("--repo is required: mix relyra.refresh_due --repo MyApp.Repo")

    repo =
      try do
        String.to_existing_atom(repo_string)
      rescue
        ArgumentError -> Mix.raise("Repo module #{repo_string} is not loaded")
      end

    case Relyra.Metadata.Scheduler.run_due(repo, []) do
      {:ok, results} when is_map(results) ->
        Mix.shell().info("relyra.refresh_due: #{map_size(results)} sources processed.")
        :ok

      other ->
        # Defensive fallback for the Ecto-absent compile lane (the
        # Scheduler stub returns `{:error, %Relyra.Error{}}`); the
        # present-Ecto body returns only `{:ok, _}` so the typer cannot
        # see this path.
        Mix.raise("relyra.refresh_due failed: " <> inspect(other))
    end
  end
end
