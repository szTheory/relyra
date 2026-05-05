defmodule Relyra.Ecto.ConnectionLoader do
  @moduledoc false

  import Ecto.Query

  alias Relyra.Ecto.Connection
  alias Relyra.Error

  @attribute_table "relyra_attribute_mappings"
  @group_table "relyra_group_mappings"

  @spec fetch(module(), binary(), keyword()) :: {:ok, Connection.t()} | {:error, Error.t()}
  def fetch(repo, connection_id, opts \\ [])

  def fetch(repo, connection_id, opts)
      when is_atom(repo) and is_binary(connection_id) and is_list(opts) do
    operation = Keyword.get(opts, :operation, :resolve_connection)

    with :ok <- ensure_optional_dependencies(repo, operation),
         {:ok, connection} <- load_connection(repo, connection_id, operation),
         :ok <- ensure_runtime_ready(connection, operation) do
      {:ok, connection}
    end
  end

  def fetch(repo, _connection_id, opts) do
    operation = Keyword.get(opts, :operation, :resolve_connection)

    {:error,
     Error.new(
       :resolver_misconfigured,
       "Persisted connection loader requires a repo module and connection_id",
       %{
         repo: inspect(repo),
         operation: operation,
         reason: :invalid_loader_arguments
       }
     )}
  end

  defp ensure_optional_dependencies(repo, operation) do
    cond do
      not Code.ensure_loaded?(Ecto.Repo) ->
        {:error, repo_misconfigured(repo, operation, :ecto_unavailable)}

      not Code.ensure_loaded?(Connection) ->
        {:error, repo_misconfigured(repo, operation, :connection_schema_unavailable)}

      not function_exported?(repo, :get_by, 2) ->
        {:error, repo_misconfigured(repo, operation, :repo_missing_get_by)}

      not function_exported?(repo, :preload, 2) ->
        {:error, repo_misconfigured(repo, operation, :repo_missing_preload)}

      not function_exported?(repo, :all, 1) ->
        {:error, repo_misconfigured(repo, operation, :repo_missing_all)}

      true ->
        :ok
    end
  end

  defp load_connection(repo, connection_id, operation) do
    case repo.get_by(Connection, connection_id: connection_id) do
      nil ->
        {:error,
         Error.new(
           :connection_unavailable,
           "Persisted connection was not found",
           %{
             connection_id: connection_id,
             operation: operation,
             reason: :not_found
           }
         )}

      connection ->
        connection =
          connection
          |> repo.preload([:certificates, :attribute_mappings, :group_mappings])
          |> attach_mapping_rows(repo)

        {:ok, connection}
    end
  rescue
    exception ->
      {:error,
       Error.new(
         :resolver_misconfigured,
         "Persisted connection repo access failed",
         %{
           connection_id: connection_id,
           operation: operation,
           reason: :repo_misconfigured,
           repo: inspect(repo),
           failure: Exception.message(exception)
         }
       )}
  end

  defp ensure_runtime_ready(%Connection{} = connection, operation) do
    cond do
      connection.status == :draft ->
        {:error,
         Error.new(
           :connection_unavailable,
           "Persisted connection is still in draft state",
           base_details(connection, operation, :draft)
         )}

      connection.status == :disabled ->
        {:error,
         Error.new(
           :connection_unavailable,
           "Persisted connection is disabled",
           base_details(connection, operation, :disabled)
         )}

      true ->
        case Connection.runtime_ready(connection) do
          :ok ->
            :ok

          {:error, %Error{} = error} ->
            {:error, classify_runtime_readiness(error, connection, operation)}
        end
    end
  end

  defp classify_runtime_readiness(%Error{details: details}, connection, operation) do
    reason =
      cond do
        Map.has_key?(details, :missing) -> :missing_runtime_fields
        true -> Map.get(details, :reason, :runtime_not_ready)
      end

    type =
      case reason do
        :missing_runtime_fields -> :connection_invalid
        :missing_certificates -> :connection_invalid
        :invalid_certificates -> :connection_invalid
        _ -> :connection_invalid
      end

    message =
      case reason do
        :missing_runtime_fields -> "Persisted connection is missing runtime fields"
        :missing_certificates -> "Persisted connection is missing active trusted certificates"
        :invalid_certificates -> "Persisted connection has invalid active trusted certificates"
        _ -> "Persisted connection is not runtime ready"
      end

    Error.new(
      type,
      message,
      Map.merge(base_details(connection, operation, reason), Map.take(details, [:missing]))
    )
  end

  defp repo_misconfigured(repo, operation, reason) do
    Error.new(
      :resolver_misconfigured,
      "Persisted connection repo is misconfigured",
      %{
        repo: inspect(repo),
        operation: operation,
        reason: reason
      }
    )
  end

  defp base_details(connection, operation, reason) do
    %{
      connection_id: Map.get(connection, :connection_id),
      operation: operation,
      reason: reason
    }
  end

  defp attach_mapping_rows(connection, repo) do
    connection
    |> Map.put(:attribute_mappings, load_attribute_rows(repo, connection.id))
    |> Map.put(:group_mappings, load_group_rows(repo, connection.id))
  end

  defp load_attribute_rows(repo, connection_record_id) do
    repo.all(
      from row in @attribute_table,
        where: field(row, :connection_record_id) == type(^connection_record_id, :binary_id),
        order_by: [asc: field(row, :position), asc: field(row, :inserted_at)],
        select: %{
          position: field(row, :position),
          source_attribute: field(row, :source_attribute),
          target_field: field(row, :target_field),
          multivalue_strategy: field(row, :multivalue_strategy)
        }
    )
  end

  defp load_group_rows(repo, connection_record_id) do
    repo.all(
      from row in @group_table,
        where: field(row, :connection_record_id) == type(^connection_record_id, :binary_id),
        order_by: [asc: field(row, :position), asc: field(row, :inserted_at)],
        select: %{
          position: field(row, :position),
          source_attribute: field(row, :source_attribute),
          source_value: field(row, :source_value),
          role_target: field(row, :role_target),
          role_value: field(row, :role_value)
        }
    )
  end
end
