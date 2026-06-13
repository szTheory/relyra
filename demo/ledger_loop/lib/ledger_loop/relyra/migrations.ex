defmodule LedgerLoop.Relyra.Migrations do
  @moduledoc """
  Provides functions to run Relyra's shipped migrations directly from the
  dependency path, avoiding the need to copy them into the demo application.
  """

  @doc """
  Returns the path to Relyra's root migrations directory.
  """
  def relyra_migrations_path do
    Path.expand("../../priv/repo/migrations", File.cwd!())
  end

  @doc """
  Runs Relyra migrations in the given repository.
  """
  def migrate_relyra!(opts \\ []) do
    path = relyra_migrations_path()

    # Run the migrations via Ecto.Migrator
    Ecto.Migrator.with_repo(LedgerLoop.Repo, fn repo ->
      Ecto.Migrator.run(repo, path, :up, Keyword.merge([all: true], opts))
    end)
  end
end
