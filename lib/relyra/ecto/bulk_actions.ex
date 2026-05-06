defmodule Relyra.Ecto.BulkActions do
  @moduledoc """
  Coordinator for bulk operations across multiple connections.
  """

  @doc """
  Runs an action function for each connection ID provided.

  Generates a `correlation_id` if one is not provided in the audit context,
  ensuring all operations in the batch can be linked together in the audit ledger.

  Returns a map of %{id => result}.
  """
  def run(repo, ids, action_fun, opts) do
    audit = Keyword.get(opts, :audit, %{})
    correlation_id = Map.get(audit, :correlation_id) || Ecto.UUID.generate()

    opts_with_audit = Keyword.put(opts, :audit, Map.put(audit, :correlation_id, correlation_id))
    opts_with_repo = Keyword.put_new(opts_with_audit, :repo, repo)

    Enum.map(ids, fn id ->
      {id, action_fun.(id, opts_with_repo)}
    end)
    |> Map.new()
  end
end
