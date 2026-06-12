defmodule LedgerLoop.Relyra.MigrationsTest do
  use ExUnit.Case, async: false

  alias LedgerLoop.Relyra.Migrations
  alias LedgerLoop.Repo
  alias Ecto.Adapters.SQL

  # No sandbox for migration tests, as they alter schema and spawn processes
  setup do
    Ecto.Adapters.SQL.Sandbox.mode(Repo, :auto)

    on_exit(fn ->
      Ecto.Adapters.SQL.Sandbox.mode(Repo, :manual)
    end)

    :ok
  end

  test "relyra_migrations_path/0 expands to the root dependency path ending in priv/repo/migrations, not demo/ledger_loop/priv/repo/migrations" do
    path = Migrations.relyra_migrations_path()
    assert String.ends_with?(path, "relyra/priv/repo/migrations")
    refute String.contains?(path, "demo/ledger_loop/priv/repo/migrations")
  end

  test "running the demo migration task creates at least relyra_connections and relyra_audit_events in LedgerLoop.Repo" do
    # Run the migration function directly or via Mix task
    Mix.Task.run("ledger_loop.relyra.migrate", ["--quiet"])

    # Verify tables exist
    result =
      SQL.query!(
        Repo,
        "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'"
      )

    tables = Enum.map(result.rows, fn [table] -> table end)

    assert "relyra_connections" in tables
    assert "relyra_audit_events" in tables
  end

  test "source scan finds no copied Relyra migration modules under demo/ledger_loop/priv/repo/migrations" do
    local_migrations_path = Path.expand("../../../priv/repo/migrations", __DIR__)

    if File.exists?(local_migrations_path) do
      files = File.ls!(local_migrations_path)
      # Assert there are no relyra prefix files
      for file <- files do
        refute String.contains?(file, "relyra_"), "Found Relyra migration copied to demo: #{file}"
      end
    end
  end

  test "mix aliases include Relyra migrations before Ecto migrations" do
    project = Mix.Project.get!()
    aliases = project.project()[:aliases]

    assert "ledger_loop.relyra.migrate" in aliases[:"ecto.setup"]
    assert "ecto.migrate" in aliases[:"ecto.setup"]

    setup_relyra_idx =
      Enum.find_index(aliases[:"ecto.setup"], &(&1 == "ledger_loop.relyra.migrate"))

    setup_ecto_idx = Enum.find_index(aliases[:"ecto.setup"], &(&1 == "ecto.migrate"))
    assert setup_relyra_idx < setup_ecto_idx

    assert "ledger_loop.relyra.migrate --quiet" in aliases[:test]
    assert "ecto.migrate --quiet" in aliases[:test]

    test_relyra_idx =
      Enum.find_index(aliases[:test], &(&1 == "ledger_loop.relyra.migrate --quiet"))

    test_ecto_idx = Enum.find_index(aliases[:test], &(&1 == "ecto.migrate --quiet"))
    assert test_relyra_idx < test_ecto_idx

    assert "ecto.setup" in aliases[:"ecto.reset"]
  end
end
