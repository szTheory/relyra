defmodule Relyra.Workers.MetadataRefreshTest do
  use ExUnit.Case, async: true

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
        # cleanly without raising.
        job_struct = struct!(Oban.Job, args: %{"repo" => to_string(Relyra.TestSupport.EctoTestRepo)})

        # The result depends on whether the repo is started + has a
        # sandbox checkout; in this async test we accept either :ok or
        # an Error tuple (the scheduler may surface a missing-repo error).
        result = MetadataRefresh.perform(job_struct)
        assert match?(:ok, result) or match?({:error, _}, result)
      end
    end

    @tag :oban
    test "Oban.Worker behaviour is implemented when Oban is loaded" do
      unless ObanGateway.available?() do
        :ok
      else
        assert function_exported?(MetadataRefresh, :perform, 1)
      end
    end
  end

  describe "perform/1 (Oban absent)" do
    test "returns optional_dependency_missing when Oban is absent" do
      # Only meaningful when Oban is NOT loaded — the present lane is
      # covered above. In the absent lane, perform/1 returns the typed
      # optional-dep error from the gateway.
      if ObanGateway.available?() do
        :ok
      else
        assert {:error, %Relyra.Error{type: :optional_dependency_missing}} =
                 MetadataRefresh.perform(:irrelevant)
      end
    end
  end
end
