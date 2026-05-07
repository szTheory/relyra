defmodule Relyra.OptionalDeps.ObanTest do
  use ExUnit.Case, async: true

  alias Relyra.Error
  alias Relyra.OptionalDeps.Oban, as: ObanGateway

  describe "available?/0" do
    test "returns a boolean reflecting whether all required Oban modules are loaded" do
      # In the test environment Oban may or may not be present (Plan 07
      # adds it as a test dep). Either way, available?/0 returns a strict
      # boolean; the absent-path is exercised by ensure_available!/1 below.
      assert is_boolean(ObanGateway.available?())
    end
  end

  describe "ensure_available!/1" do
    test "returns :ok when Oban is available" do
      if ObanGateway.available?() do
        assert :ok == ObanGateway.ensure_available!(:test_op)
      end
    end

    test "returns {:error, %Relyra.Error{type: :optional_dependency_missing}} when absent" do
      unless ObanGateway.available?() do
        assert {:error, %Error{type: :optional_dependency_missing} = err} =
                 ObanGateway.ensure_available!(:test_op)

        assert err.details.missing_dependency == :oban
        assert err.details.operation == :test_op

        assert err.message =~ ":oban"
      end
    end

    test "always accepts an atom operation argument without raising" do
      assert match?(:ok, ObanGateway.ensure_available!(:probe)) or
               match?({:error, _}, ObanGateway.ensure_available!(:probe))
    end
  end

  describe "required_modules/0" do
    test "lists exactly [Oban, Oban.Worker, Oban.Job, Oban.Plugins.Cron]" do
      assert ObanGateway.required_modules() == [
               Oban,
               Oban.Worker,
               Oban.Job,
               Oban.Plugins.Cron
             ]
    end
  end
end
