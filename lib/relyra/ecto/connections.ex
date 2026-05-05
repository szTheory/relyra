defmodule Relyra.Ecto.Connections do
  @moduledoc false

  alias Relyra.Ecto.AuditWriter
  alias Relyra.Error

  @ecto_repo Ecto.Repo
  @connection_schema Relyra.Ecto.Connection

  @spec create(map(), keyword()) :: {:ok, struct()} | {:error, Error.t()}
  def create(attrs, opts \\ [])

  def create(attrs, opts) when is_map(attrs) and is_list(opts) do
    with {:ok, repo} <- fetch_repo(opts, :create),
         :ok <- ensure_optional_dependency!(:create, repo) do
      changeset = @connection_schema.draft_changeset(struct(@connection_schema), attrs)

      transact(repo, fn ->
        with {:ok, record} <- persist_changeset(repo, changeset, :insert, :create),
             {:ok, audited_record} <-
               maybe_append_audit(
                 repo,
                 record,
                 %{},
                 connection_trust_view(record),
                 :created,
                 changeset_changed_fields(changeset),
                 opts
               ) do
          {:ok, audited_record}
        end
      end)
      |> normalize_transaction_result(:create)
    end
  end

  def create(_attrs, opts) do
    {:error,
     Error.new(
       :invalid_connection_record,
       "Connection attrs must be a map",
       error_details(opts, :create, :invalid_input)
     )}
  end

  @spec update(binary(), map(), keyword()) :: {:ok, struct()} | {:error, Error.t()}
  def update(connection_id, attrs, opts \\ [])

  def update(connection_id, attrs, opts)
      when is_binary(connection_id) and is_map(attrs) and is_list(opts) do
    with {:ok, repo} <- fetch_repo(opts, :update),
         :ok <- ensure_optional_dependency!(:update, repo),
         {:ok, connection} <- fetch_connection(repo, connection_id, :update) do
      changeset = @connection_schema.update_changeset(connection, attrs)
      before_view = connection_trust_view(connection)

      transact(repo, fn ->
        with {:ok, record} <- persist_changeset(repo, changeset, :update, :update),
             {:ok, audited_record} <-
               maybe_append_audit(
                 repo,
                 record,
                 before_view,
                 connection_trust_view(record),
                 :updated,
                 changeset_changed_fields(changeset),
                 opts
               ) do
          {:ok, audited_record}
        end
      end)
      |> normalize_transaction_result(:update)
    end
  end

  def update(_connection_id, _attrs, opts) do
    {:error,
     Error.new(
       :invalid_connection_record,
       "connection_id and attrs are required for update",
       error_details(opts, :update, :invalid_input)
     )}
  end

  @spec disable(binary(), keyword()) :: {:ok, struct()} | {:error, Error.t()}
  def disable(connection_id, opts \\ [])

  def disable(connection_id, opts) when is_binary(connection_id) and is_list(opts) do
    with {:ok, repo} <- fetch_repo(opts, :disable),
         :ok <- ensure_optional_dependency!(:disable, repo),
         {:ok, connection} <- fetch_connection(repo, connection_id, :disable) do
      changeset = @connection_schema.disable_changeset(connection)
      before_view = connection_trust_view(connection)

      transact(repo, fn ->
        with {:ok, record} <- persist_changeset(repo, changeset, :update, :disable),
             {:ok, audited_record} <-
               maybe_append_audit(
                 repo,
                 record,
                 before_view,
                 connection_trust_view(record),
                 :disabled,
                 [:status],
                 opts
               ) do
          {:ok, audited_record}
        end
      end)
      |> normalize_transaction_result(:disable)
    end
  end

  def disable(_connection_id, opts) do
    {:error,
     Error.new(
       :invalid_connection_record,
       "connection_id is required for disable",
       error_details(opts, :disable, :invalid_input)
     )}
  end

  @spec enable(binary(), keyword()) :: {:ok, struct()} | {:error, Error.t()}
  def enable(connection_id, opts \\ [])

  def enable(connection_id, opts) when is_binary(connection_id) and is_list(opts) do
    with {:ok, repo} <- fetch_repo(opts, :enable),
         :ok <- ensure_optional_dependency!(:enable, repo),
         {:ok, connection} <- fetch_connection(repo, connection_id, :enable) do
      changeset = @connection_schema.publish_changeset(connection, %{})
      before_view = connection_trust_view(connection)

      transact(repo, fn ->
        with {:ok, record} <- persist_changeset(repo, changeset, :update, :enable),
             {:ok, audited_record} <-
               maybe_append_audit(
                 repo,
                 record,
                 before_view,
                 connection_trust_view(record),
                 :enabled,
                 [:status],
                 opts
               ) do
          {:ok, audited_record}
        end
      end)
      |> normalize_transaction_result(:enable)
    end
  end

  def enable(_connection_id, opts) do
    {:error,
     Error.new(
       :invalid_connection_record,
       "connection_id is required for enable",
       error_details(opts, :enable, :invalid_input)
     )}
  end

  defp fetch_repo(opts, operation) when is_list(opts) do
    case Keyword.fetch(opts, :repo) do
      {:ok, repo} when is_atom(repo) ->
        {:ok, repo}

      _ ->
        {:error,
         Error.new(
           :adapter_not_configured,
           "opts[:repo] is required for Ecto connection operations",
           error_details(opts, operation, :missing_repo)
         )}
    end
  end

  defp ensure_optional_dependency!(operation, repo) do
    if Code.ensure_loaded?(@ecto_repo) and Code.ensure_loaded?(@connection_schema) do
      :ok
    else
      {:error,
       Error.new(
         :optional_dependency_missing,
         "Ecto connection persistence is unavailable; add optional Ecto dependencies before using this adapter",
         repo_details(repo, operation, :ecto_unavailable)
       )}
    end
  end

  defp fetch_connection(repo, connection_id, operation) do
    case repo.get_by(@connection_schema, connection_id: connection_id)
         |> repo.preload(:certificates) do
      nil ->
        {:error,
         Error.new(
           :connection_not_found,
           "Connection record was not found",
           repo_details(repo, operation, %{connection_id: connection_id, reason: :not_found})
         )}

      connection ->
        {:ok, connection}
    end
  end

  defp persist_changeset(repo, changeset, action, operation) do
    result =
      case action do
        :insert -> repo.insert(changeset)
        :update -> repo.update(changeset)
      end

    case result do
      {:ok, record} ->
        {:ok, repo.preload(record, :certificates)}

      {:error, %Ecto.Changeset{} = invalid_changeset} ->
        {:error,
         Error.new(
           :invalid_connection_record,
           "Connection record failed validation",
           %{
             operation: operation,
             errors: format_changeset_errors(invalid_changeset)
           }
         )}
    end
  end

  defp maybe_append_audit(repo, record, before_view, after_view, action, changed_fields, opts) do
    case Keyword.get(opts, :audit) do
      nil ->
        {:ok, record}

      audit when is_map(audit) ->
        audit_attrs = %{
          connection_record_id: record.id,
          domain: :connection,
          action: action,
          actor: Map.get(audit, :actor),
          cause: Map.get(audit, :cause),
          correlation_id: Map.get(audit, :correlation_id),
          before_view: before_view,
          after_view: after_view,
          diff_summary: %{
            changed_fields: changed_fields,
            status_transition: status_transition(before_view, after_view)
          }
        }

        case AuditWriter.append_event(repo, audit_attrs) do
          {:ok, _event} -> {:ok, record}
          {:error, %Error{} = error} -> rollback(repo, error)
        end

      _other ->
        rollback(
          repo,
          Error.new(
            :invalid_connection_record,
            "opts[:audit] must be a map when provided",
            error_details(opts, action, :invalid_audit_context)
          )
        )
    end
  end

  defp connection_trust_view(connection) do
    %{
      connection_id: connection.connection_id,
      display_name: connection.display_name,
      organization_id: connection.organization_id,
      status: connection.status,
      provider_preset: connection.provider_preset,
      sp_entity_id: connection.sp_entity_id,
      acs_url: connection.acs_url,
      idp_entity_id: connection.idp_entity_id,
      idp_sso_url: connection.idp_sso_url,
      active_metadata_revision_id: connection.active_metadata_revision_id,
      last_known_good_metadata_revision_id: connection.last_known_good_metadata_revision_id,
      certificate_count: Enum.count(Map.get(connection, :certificates, [])),
      active_signing_certificate_count:
        connection
        |> Map.get(:certificates, [])
        |> Enum.count(&(&1.role == :signing and &1.lifecycle_state == :active)),
      runtime_policy: runtime_policy_view(connection.runtime_policy)
    }
  end

  defp runtime_policy_view(nil), do: %{}

  defp runtime_policy_view(runtime_policy) do
    %{
      allow_idp_initiated?: Map.get(runtime_policy, :allow_idp_initiated?),
      require_signed_assertions?: Map.get(runtime_policy, :require_signed_assertions?),
      require_signed_response?: Map.get(runtime_policy, :require_signed_response?)
    }
  end

  defp changeset_changed_fields(changeset) do
    changeset.changes
    |> Map.keys()
    |> Enum.reject(&(&1 in [:updated_at, :inserted_at]))
    |> Enum.sort()
  end

  defp status_transition(before_view, after_view) do
    case {Map.get(before_view, :status), Map.get(after_view, :status)} do
      {nil, nil} -> nil
      {before_status, after_status} -> "#{before_status || "nil"}->#{after_status || "nil"}"
    end
  end

  defp transact(repo, fun) do
    if function_exported?(repo, :transact, 1) do
      repo.transact(fun)
    else
      repo.transaction(fun)
    end
  end

  defp rollback(repo, value), do: repo.rollback(value)

  defp normalize_transaction_result({:ok, {:ok, record}}, _operation), do: {:ok, record}
  defp normalize_transaction_result({:ok, record}, _operation), do: {:ok, record}
  defp normalize_transaction_result({:error, %Error{} = error}, _operation), do: {:error, error}

  defp normalize_transaction_result({:error, {:error, %Error{} = error}}, _operation),
    do: {:error, error}

  defp normalize_transaction_result({:error, reason}, operation) do
    {:error,
     Error.new(
       :internal_protocol_error,
       "Connection persistence transaction failed",
       %{operation: operation, reason: inspect(reason)}
     )}
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  defp repo_details(repo, operation, reason) do
    %{
      repo: inspect(repo),
      operation: operation,
      reason: inspect(reason)
    }
  end

  defp error_details(opts, operation, reason) do
    repo_details(Keyword.get(opts, :repo), operation, reason)
  end
end
