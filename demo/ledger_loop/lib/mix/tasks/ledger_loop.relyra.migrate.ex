defmodule Mix.Tasks.LedgerLoop.Relyra.Migrate do
  use Mix.Task

  @shortdoc "Runs Relyra's internal database migrations for the demo app"

  @moduledoc """
  Runs Relyra's database migrations directly from the dependency path
  without copying files into the demo app.

  This task can be used like `mix ecto.migrate`, and accepts `--quiet`
  to suppress log output.
  """

  @impl true
  def run(args) do
    # Start Repo/Ecto apps if not started
    Mix.Task.run("app.start")

    opts =
      if "--quiet" in args do
        [log: false]
      else
        []
      end

    LedgerLoop.Relyra.Migrations.migrate_relyra!(opts)
  end
end
