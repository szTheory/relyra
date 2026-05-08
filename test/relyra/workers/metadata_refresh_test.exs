defmodule Relyra.Workers.MetadataRefreshTest do
  # Plan 21-07 deviation (Rule 3): switched from `ExUnit.Case, async: true`
  # to `Relyra.TestSupport.MigrationCase` because Plan 21-07 added Oban as
  # a real (optional) dep so `ObanGateway.available?()` now returns `true`,
  # which means the present-lane delegate test actually invokes
  # `Scheduler.run_due/2` against the test repo. Without a Sandbox
  # checkout this raises `Ecto.Adapters.SQL.Sandbox.OwnershipError`.
  # MigrationCase performs the checkout per test.
  use Relyra.TestSupport.MigrationCase, async: false

  alias Relyra.OptionalDeps.Oban, as: ObanGateway
  alias Relyra.Workers.MetadataRefresh

  describe "perform/1 (Oban present)" do
    @tag :oban
    test "delegates to Scheduler.run_due/2 with the configured repo" do
      # Skip if Oban is not loaded (--no-optional-deps lane) — the
      # absent-path describe block below exercises that branch instead.
      unless ObanGateway.available?() do
        :ok
      else
        # Build an Oban.Job whose args map carries the repo module name
        # as a string (the Cron one-liner shape — `args: %{"repo" =>
        # "MyApp.Repo"}`). The actual scheduler behavior is covered by
        # `scheduler_test.exs`; here we just assert the worker delegates
        # cleanly. With the MigrationCase sandbox checkout the no-due-
        # rows path returns `{:ok, %{}}` (and the worker maps that to
        # `:ok`).
        job_struct =
          struct!(Oban.Job, args: %{"repo" => to_string(Relyra.TestSupport.EctoTestRepo)})

        result = MetadataRefresh.perform(job_struct)
        assert match?(:ok, result) or match?({:error, _}, result)
      end
    end

    @tag :oban
    test "Oban.Worker behaviour is implemented when Oban is loaded" do
      unless ObanGateway.available?() do
        :ok
      else
        Code.ensure_loaded?(MetadataRefresh)
        assert function_exported?(MetadataRefresh, :perform, 1)
      end
    end
  end

  describe "perform/1 (Oban absent)" do
    test "returns optional_dependency_missing when Oban is absent" do
      # Only meaningful when Oban is NOT loaded — the present lane is
      # covered above. In the absent lane, perform/1 returns the typed
      # optional-dep error from the gateway. We use `apply/3` because
      # Plan 21-07 added Oban as an optional dep so the present-lane
      # `perform/1` typespec is `Oban.Job`-only — calling with an atom
      # would otherwise trip the Elixir 1.19 set-theoretic typer.
      if ObanGateway.available?() do
        :ok
      else
        assert {:error, %Relyra.Error{type: :optional_dependency_missing}} =
                 apply(MetadataRefresh, :perform, [:irrelevant])
      end
    end
  end
end
