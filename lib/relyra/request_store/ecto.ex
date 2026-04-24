defmodule Relyra.RequestStore.Ecto do
  @moduledoc false

  @behaviour Relyra.RequestStore

  alias Relyra.Error

  @ecto_repo Ecto.Repo

  @impl true
  @spec put_intent(binary(), map(), keyword()) :: :ok | {:error, Error.t()}
  def put_intent(relay_state, intent, opts \\ [])

  def put_intent(relay_state, intent, opts)
      when is_binary(relay_state) and is_map(intent) and is_list(opts) do
    with {:ok, repo} <- fetch_repo(opts, :put_intent),
         {:ok, table} <- fetch_table(opts, :put_intent, repo),
         :ok <- ensure_optional_dependency!(:put_intent, repo, table),
         {:ok, request_id} <- request_id_from_intent(intent, repo, table, :put_intent),
         :ok <- insert_intent(repo, table, relay_state, request_id, intent) do
      :ok
    end
  end

  def put_intent(_relay_state, _intent, opts) do
    {:error,
     Error.new(
       :request_intent_not_found,
       "Request intent input is invalid",
       error_details(opts, :put_intent, :invalid_input)
     )}
  end

  @impl true
  @spec fetch_intent(binary(), keyword()) :: {:ok, map()} | {:error, Error.t()}
  def fetch_intent(relay_state, opts \\ [])

  def fetch_intent(relay_state, opts) when is_binary(relay_state) and is_list(opts) do
    with {:ok, repo} <- fetch_repo(opts, :fetch_intent),
         {:ok, table} <- fetch_table(opts, :fetch_intent, repo),
         :ok <- ensure_optional_dependency!(:fetch_intent, repo, table),
         {:ok, result} <- fetch_intent_record(repo, table, relay_state, :fetch_intent) do
      result
    end
  end

  def fetch_intent(_relay_state, opts) do
    {:error,
     Error.new(
       :request_intent_not_found,
       "Relay state must be a binary",
       error_details(opts, :fetch_intent, :invalid_relay_state)
     )}
  end

  @impl true
  @spec consume_intent(binary(), binary(), keyword()) :: :ok | {:error, Error.t()}
  def consume_intent(relay_state, request_id, opts \\ [])

  def consume_intent(relay_state, request_id, opts)
      when is_binary(relay_state) and is_binary(request_id) and is_list(opts) do
    with {:ok, repo} <- fetch_repo(opts, :consume_intent),
         {:ok, table} <- fetch_table(opts, :consume_intent, repo),
         :ok <- ensure_optional_dependency!(:consume_intent, repo, table),
         :ok <- update_intent_consume(repo, table, relay_state, request_id) do
      :ok
    end
  end

  def consume_intent(_relay_state, _request_id, opts) do
    {:error,
     Error.new(
       :request_intent_not_found,
       "Relay state and request_id must be binaries",
       error_details(opts, :consume_intent, :invalid_input)
     )}
  end

  defp insert_intent(repo, table, relay_state, request_id, intent) do
    expires_at = Map.get(intent, :expires_at) || Map.get(intent, "expires_at")

    sql = """
    INSERT INTO #{table} (relay_state, request_id, intent, consumed_at, expires_at)
    VALUES ($1, $2, $3, NULL, $4)
    """

    case repo_query(repo, sql, [relay_state, request_id, intent, expires_at]) do
      {:ok, _query_result} ->
        :ok

      {:error, reason} ->
        if unique_violation?(reason) do
          {:error,
           Error.new(
             :request_intent_consumed,
             "Request intent already exists for relay state",
             repo_details(repo, table, :put_intent, reason, %{relay_state: relay_state})
           )}
        else
          {:error,
           Error.new(
             :internal_protocol_error,
             "Failed to persist request intent",
             repo_details(repo, table, :put_intent, reason, %{relay_state: relay_state})
           )}
        end
    end
  end

  defp fetch_intent_record(repo, table, relay_state, operation) do
    sql = """
    SELECT request_id, intent, consumed_at, expires_at
    FROM #{table}
    WHERE relay_state = $1
    LIMIT 1
    """

    case repo_query(repo, sql, [relay_state]) do
      {:ok, %{rows: [[request_id, intent, nil, expires_at] | _]}}
      when is_binary(request_id) and is_map(intent) ->
        {:ok,
         {:ok,
          Map.put_new(intent, :request_id, request_id) |> Map.put_new(:expires_at, expires_at)}}

      {:ok, %{rows: [[_request_id, _intent, consumed_at, _expires_at] | _]}}
      when not is_nil(consumed_at) ->
        {:error,
         Error.new(
           :request_intent_consumed,
           "Request intent has already been consumed",
           repo_details(repo, table, operation, :already_consumed, %{relay_state: relay_state})
         )}

      {:ok, %{rows: []}} ->
        {:error,
         Error.new(
           :request_intent_not_found,
           "Request intent was not found",
           repo_details(repo, table, operation, :not_found, %{relay_state: relay_state})
         )}

      {:ok, _unexpected_shape} ->
        {:error,
         Error.new(
           :internal_protocol_error,
           "Request intent query returned unexpected shape",
           repo_details(repo, table, operation, :unexpected_shape, %{relay_state: relay_state})
         )}

      {:error, reason} ->
        {:error,
         Error.new(
           :internal_protocol_error,
           "Failed to fetch request intent",
           repo_details(repo, table, operation, reason, %{relay_state: relay_state})
         )}
    end
  end

  defp update_intent_consume(repo, table, relay_state, request_id) do
    consumed_at = DateTime.utc_now()

    update_sql = """
    UPDATE #{table}
    SET consumed_at = $1
    WHERE relay_state = $2 AND request_id = $3 AND consumed_at IS NULL
    """

    case repo_query(repo, update_sql, [consumed_at, relay_state, request_id]) do
      {:ok, %{num_rows: 1}} ->
        :ok

      {:ok, %{num_rows: 0}} ->
        classify_consume_conflict(repo, table, relay_state, request_id)

      {:ok, _unexpected_shape} ->
        {:error,
         Error.new(
           :internal_protocol_error,
           "Request consume update returned unexpected shape",
           repo_details(repo, table, :consume_intent, :unexpected_shape, %{
             relay_state: relay_state,
             request_id: request_id
           })
         )}

      {:error, reason} ->
        {:error,
         Error.new(
           :internal_protocol_error,
           "Failed to consume request intent",
           repo_details(repo, table, :consume_intent, reason, %{
             relay_state: relay_state,
             request_id: request_id
           })
         )}
    end
  end

  defp classify_consume_conflict(repo, table, relay_state, request_id) do
    sql = """
    SELECT consumed_at
    FROM #{table}
    WHERE relay_state = $1 AND request_id = $2
    LIMIT 1
    """

    case repo_query(repo, sql, [relay_state, request_id]) do
      {:ok, %{rows: [[consumed_at] | _]}} when not is_nil(consumed_at) ->
        {:error,
         Error.new(
           :request_intent_consumed,
           "Request intent has already been consumed",
           repo_details(repo, table, :consume_intent, :already_consumed, %{
             relay_state: relay_state,
             request_id: request_id
           })
         )}

      {:ok, %{rows: []}} ->
        {:error,
         Error.new(
           :request_intent_not_found,
           "Request intent was not found",
           repo_details(repo, table, :consume_intent, :not_found, %{
             relay_state: relay_state,
             request_id: request_id
           })
         )}

      {:ok, _} ->
        {:error,
         Error.new(
           :request_intent_not_found,
           "Request intent was not found",
           repo_details(repo, table, :consume_intent, :not_found, %{
             relay_state: relay_state,
             request_id: request_id
           })
         )}

      {:error, reason} ->
        {:error,
         Error.new(
           :internal_protocol_error,
           "Failed to classify request consume conflict",
           repo_details(repo, table, :consume_intent, reason, %{
             relay_state: relay_state,
             request_id: request_id
           })
         )}
    end
  end

  defp fetch_repo(opts, operation) when is_list(opts) do
    case Keyword.fetch(opts, :repo) do
      {:ok, repo} when is_atom(repo) ->
        {:ok, repo}

      _ ->
        {:error,
         Error.new(
           :request_intent_not_found,
           "opts[:repo] is required for Ecto request-store operations",
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
           :request_intent_not_found,
           "opts[:table] is required for Ecto request-store operations",
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

  defp request_id_from_intent(intent, repo, table, operation) when is_map(intent) do
    request_id = Map.get(intent, :request_id) || Map.get(intent, "request_id")

    if is_binary(request_id) and request_id != "" do
      {:ok, request_id}
    else
      {:error,
       Error.new(
         :request_intent_not_found,
         "Request intent requires a request_id",
         repo_details(repo, table, operation, :missing_request_id)
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
