defmodule Relyra.Ecto.BulkActionsTest do
  use ExUnit.Case, async: true
  alias Relyra.Ecto.BulkActions

  describe "run/4" do
    test "calls action_fun for each ID and returns results" do
      repo = :mock_repo
      ids = [1, 2, 3]
      action_fun = fn id, opts ->
        assert opts[:repo] == :mock_repo
        {:ok, id * 10}
      end

      result = BulkActions.run(repo, ids, action_fun, [])

      assert result == {:ok, %{
               1 => {:ok, 10},
               2 => {:ok, 20},
               3 => {:ok, 30}
             }}
    end

    test "generates and injects correlation_id into audit context" do
      repo = :mock_repo
      ids = [1]
      action_fun = fn _id, opts ->
        audit = opts[:audit]
        assert is_binary(audit[:correlation_id])
        {:ok, audit[:correlation_id]}
      end

      {:ok, result} = BulkActions.run(repo, ids, action_fun, [])
      
      # Since we only have one ID, the result should have that correlation_id
      assert {:ok, correlation_id} = result[1]
      assert is_binary(correlation_id)
    end

    test "respects existing correlation_id in audit context" do
      repo = :mock_repo
      ids = [1]
      existing_cid = "existing-cid"
      action_fun = fn _id, opts ->
        audit = opts[:audit]
        assert audit[:correlation_id] == existing_cid
        {:ok, :success}
      end

      result = BulkActions.run(repo, ids, action_fun, audit: %{correlation_id: existing_cid})
      
      assert result == {:ok, %{1 => {:ok, :success}}}
    end
  end
end
