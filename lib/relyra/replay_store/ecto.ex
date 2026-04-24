defmodule Relyra.ReplayStore.Ecto do
  @moduledoc false

  @behaviour Relyra.ReplayStore

  alias Relyra.Error

  @ecto_repo Ecto.Repo

  @impl true
  @spec consume_replay_key(binary(), map(), keyword()) :: :ok | {:error, Error.t()}
  def consume_replay_key(replay_key, metadata, opts \\ [])

  def consume_replay_key(replay_key, metadata, opts)
      when is_binary(replay_key) and is_map(metadata) and is_list(opts) do
    with {:ok, repo} <- fetch_repo(opts, :consume_replay_key),
         {:ok, table} <- fetch_table(opts, :consume_replay_key, repo),
         :ok <- ensure_optional_dependency!(:consume_replay_key, repo, table),
         :ok <- insert_replay_key(repo, table, replay_key, metadata) do
      :ok
    end
  end

  def consume_replay_key(_replay_key, _metadata, opts) do
    {:error,
     Error.new(
       :replayed_assertion,
       "Replay key input is invalid",
       error_details(opts, :consume_replay_key, :invalid_input)
     )}
  end

  defp insert_replay_key(repo, table, replay_key, metadata) do
    inserted_at = DateTime.utc_now()

    sql = """
    INSERT INTO #{table} (replay_key, inserted_at, metadata)
    VALUES ($1, $2, $3)
    """

    case repo_query(repo, sql, [replay_key, inserted_at, metadata]) do
      {:ok, _query_result} ->
        :ok

      {:error, reason} ->
        if unique_violation?(reason) do
          {:error,
           Error.new(
             :replayed_assertion,
             "Replay key has already been consumed",
             repo_details(repo, table, :consume_replay_key, reason, %{replay_key: replay_key})
           )}
        else
          {:error,
           Error.new(
             :internal_protocol_error,
             "Failed to persist replay key",
             repo_details(repo, table, :consume_replay_key, reason, %{replay_key: replay_key})
           )}
        end
    end
  end

  defp fetch_repo(opts, operation) when is_list(opts) do
    case Keyword.fetch(opts, :repo) do
      {:ok, repo} when is_atom(repo) ->
        {:ok, repo}

      _ ->
        {:error,
         Error.new(
           :replayed_assertion,
           "opts[:repo] is required for Ecto replay-store operations",
           error_details(opts, operation, :missing_repo)
         )}
    end
  end

  defp fetch_table(opts, operation, repo) when is_list(opts) do
    case Keyword.fetch(opts, :table) do
      {:ok, table} when is_binary(table) and table != "" ->
        {:ok, table}

      {:ok, table} when is_atom(table) ->
        {:ok, Atom.to_string(table)}

      _ ->
        {:error,
         Error.new(
           :replayed_assertion,
           "opts[:table] is required for Ecto replay-store operations",
           repo_details(repo, nil, operation, :missing_table)
         )}
    end
  end

  defp ensure_optional_dependency!(operation, repo, table) do
    if Code.ensure_loaded?(@ecto_repo) do
      :ok
    else
      {:error,
       Error.new(
         :optional_dependency_missing,
         "Ecto.Repo is unavailable; add optional Ecto dependencies before using this adapter",
         repo_details(repo, table, operation, :ecto_repo_unavailable)
       )}
    end
  end

  defp repo_query(repo, sql, params) when is_atom(repo) and is_binary(sql) and is_list(params) do
    cond do
      function_exported?(repo, :query, 3) ->
        apply(repo, :query, [sql, params, []])

      function_exported?(repo, :query, 2) ->
        apply(repo, :query, [sql, params])

      true ->
        {:error, :repo_query_unavailable}
    end
  end

  defp unique_violation?(reason) do
    case reason do
      :unique_violation -> true
      %{postgres: %{code: :unique_violation}} -> true
      %{code: :unique_violation} -> true
      _ -> false
    end
  end

  defp repo_details(repo, table, operation, reason, extra \\ %{}) do
    Map.merge(extra, %{
      repo: inspect(repo),
      table: table,
      operation: operation,
      reason: inspect(reason)
    })
  end

  defp error_details(opts, operation, reason) do
    repo = Keyword.get(opts, :repo)
    table = Keyword.get(opts, :table)
    repo_details(repo, table, operation, reason)
  end
end
