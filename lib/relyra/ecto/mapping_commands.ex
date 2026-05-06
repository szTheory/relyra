defmodule Relyra.Ecto.MappingCommands do
  @moduledoc false

  import Ecto.Query

  alias Relyra.Ecto.{AuditWriter, Connection, MappingRevision}
  alias Relyra.Error

  @ecto_repo Ecto.Repo
  @attribute_table "relyra_attribute_mappings"
  @group_table "relyra_group_mappings"
  @attribute_fields [:source_attribute, :target_field, :multivalue_strategy]
  @group_fields [:source_attribute, :source_value, :role_target, :role_value]
  @attribute_targets [:email, :first_name, :last_name, :display_name, :name_id]
  @multivalue_strategies [:first, :all]
  @group_targets [:role]
  @unsupported_mapping_keys ~w(regex script expression transform template)

  @spec replace_attribute_mappings(binary(), [map()], keyword()) ::
          {:ok, map()} | {:error, Error.t()}
  def replace_attribute_mappings(connection_id, mappings, opts \\ [])

  def replace_attribute_mappings(connection_id, mappings, opts)
      when is_binary(connection_id) and is_list(mappings) and is_list(opts) do
    with {:ok, repo} <- fetch_repo(opts, :replace_attribute_mappings),
         :ok <- ensure_optional_dependencies(repo, :replace_attribute_mappings),
         {:ok, audit} <- fetch_audit_context(opts, :replace_attribute_mappings),
         {:ok, normalized_mappings} <- normalize_attribute_mappings(mappings),
         {:ok, _connection} <- fetch_connection(repo, connection_id, :replace_attribute_mappings) do
      transact(repo, fn ->
        with {:ok, connection} <- fetch_locked_connection(repo, connection_id, :replace_attribute_mappings),
             :ok <- bump_connection_lock(repo, connection, :replace_attribute_mappings),
             {:ok, current_snapshot} <- mapping_snapshot(repo, connection.id),
             {:ok, _deleted} <- replace_attribute_rows(repo, connection.id, normalized_mappings),
             {:ok, after_snapshot} <- mapping_snapshot(repo, connection.id),
             action = mapping_action(current_snapshot.attribute_rules, after_snapshot.attribute_rules),
             {:ok, revision} <-
               insert_revision(repo, connection, audit, action, current_snapshot, after_snapshot, :attribute_mappings),
             {:ok, audit_event} <-
               append_audit(
                 repo,
                 connection,
                 audit,
                 action,
                 current_snapshot,
                 after_snapshot,
                 :attribute_mappings,
                 revision.id,
                 :replace_attribute_mappings
               ) do
          {:ok,
           %{
             connection_id: connection.connection_id,
             mapping_type: :attribute,
             action: action,
             mappings: after_snapshot.attribute_rules,
             revision_id: revision.id,
             audit_event_id: audit_event.id
           }}
        end
      end)
      |> normalize_transaction_result(:replace_attribute_mappings)
    end
  end

  def replace_attribute_mappings(_connection_id, _mappings, opts) do
    {:error,
     Error.new(
       :invalid_connection_record,
       "connection_id and mappings are required for attribute mapping replacement",
       error_details(opts, :replace_attribute_mappings, :invalid_input)
     )}
  end

  @spec replace_group_mappings(binary(), [map()], keyword()) :: {:ok, map()} | {:error, Error.t()}
  def replace_group_mappings(connection_id, mappings, opts \\ [])

  def replace_group_mappings(connection_id, mappings, opts)
      when is_binary(connection_id) and is_list(mappings) and is_list(opts) do
    with {:ok, repo} <- fetch_repo(opts, :replace_group_mappings),
         :ok <- ensure_optional_dependencies(repo, :replace_group_mappings),
         {:ok, audit} <- fetch_audit_context(opts, :replace_group_mappings),
         {:ok, normalized_mappings} <- normalize_group_mappings(mappings),
         {:ok, _connection} <- fetch_connection(repo, connection_id, :replace_group_mappings) do
      transact(repo, fn ->
        with {:ok, connection} <- fetch_locked_connection(repo, connection_id, :replace_group_mappings),
             :ok <- bump_connection_lock(repo, connection, :replace_group_mappings),
             {:ok, current_snapshot} <- mapping_snapshot(repo, connection.id),
             {:ok, _deleted} <- replace_group_rows(repo, connection.id, normalized_mappings),
             {:ok, after_snapshot} <- mapping_snapshot(repo, connection.id),
             action = mapping_action(current_snapshot.group_rules, after_snapshot.group_rules),
             {:ok, revision} <-
               insert_revision(repo, connection, audit, action, current_snapshot, after_snapshot, :group_mappings),
             {:ok, audit_event} <-
               append_audit(
                 repo,
                 connection,
                 audit,
                 action,
                 current_snapshot,
                 after_snapshot,
                 :group_mappings,
                 revision.id,
                 :replace_group_mappings
               ) do
          {:ok,
           %{
             connection_id: connection.connection_id,
             mapping_type: :group,
             action: action,
             mappings: after_snapshot.group_rules,
             revision_id: revision.id,
             audit_event_id: audit_event.id
           }}
        end
      end)
      |> normalize_transaction_result(:replace_group_mappings)
    end
  end

  def replace_group_mappings(_connection_id, _mappings, opts) do
    {:error,
     Error.new(
       :invalid_connection_record,
       "connection_id and mappings are required for group mapping replacement",
       error_details(opts, :replace_group_mappings, :invalid_input)
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
           "opts[:repo] is required for mapping persistence",
           error_details(opts, operation, :missing_repo)
         )}
    end
  end

  defp fetch_audit_context(opts, operation) do
    case Keyword.get(opts, :audit) do
      %{actor: actor, cause: cause} = audit when is_binary(actor) and is_binary(cause) ->
        {:ok, audit}

      nil ->
        {:error,
         Error.new(
           :invalid_connection_record,
           "opts[:audit] is required for mapping persistence",
           error_details(opts, operation, :missing_audit_context)
         )}

      _other ->
        {:error,
         Error.new(
           :invalid_connection_record,
           "opts[:audit] must include actor and cause",
           error_details(opts, operation, :invalid_audit_context)
         )}
    end
  end

  defp ensure_optional_dependencies(repo, operation) do
    cond do
      not Code.ensure_loaded?(@ecto_repo) ->
        optional_dependency_error(repo, operation, :ecto_unavailable)

      not Code.ensure_loaded?(Connection) ->
        optional_dependency_error(repo, operation, :connection_schema_unavailable)

      not Code.ensure_loaded?(MappingRevision) ->
        optional_dependency_error(repo, operation, :mapping_revision_unavailable)

      not function_exported?(repo, :get_by, 2) ->
        optional_dependency_error(repo, operation, :repo_missing_get_by)

      not function_exported?(repo, :update, 1) ->
        optional_dependency_error(repo, operation, :repo_missing_update)

      not function_exported?(repo, :insert, 1) ->
        optional_dependency_error(repo, operation, :repo_missing_insert)

      not function_exported?(repo, :insert_all, 3) ->
        optional_dependency_error(repo, operation, :repo_missing_insert_all)

      not function_exported?(repo, :delete_all, 1) ->
        optional_dependency_error(repo, operation, :repo_missing_delete_all)

      not function_exported?(repo, :one, 1) ->
        optional_dependency_error(repo, operation, :repo_missing_one)

      not function_exported?(repo, :all, 1) ->
        optional_dependency_error(repo, operation, :repo_missing_all)

      true ->
        :ok
    end
  end

  defp normalize_attribute_mappings(mappings) do
    mappings
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {mapping, position}, {:ok, acc} ->
      case normalize_attribute_mapping(mapping, position) do
        {:ok, normalized} -> {:cont, {:ok, [normalized | acc]}}
        {:error, %Error{} = error} -> {:halt, {:error, error}}
      end
    end)
    |> case do
      {:ok, normalized} -> {:ok, Enum.reverse(normalized)}
      {:error, %Error{} = error} -> {:error, error}
    end
  end

  defp normalize_attribute_mapping(mapping, position) when is_map(mapping) do
    with :ok <- reject_unsupported_keys(mapping, @attribute_fields, :replace_attribute_mappings),
         {:ok, source_attribute} <-
           fetch_required_string(mapping, :source_attribute, :replace_attribute_mappings),
         {:ok, target_field} <-
           fetch_enum(mapping, :target_field, @attribute_targets, :replace_attribute_mappings),
         {:ok, multivalue_strategy} <-
           fetch_enum(
             mapping,
             :multivalue_strategy,
             @multivalue_strategies,
             :replace_attribute_mappings
           ) do
      {:ok,
       %{
         position: position,
         source_attribute: source_attribute,
         target_field: target_field,
         multivalue_strategy: multivalue_strategy
       }}
    end
  end

  defp normalize_attribute_mapping(_mapping, _position) do
    {:error,
     Error.new(
       :invalid_connection_record,
       "Attribute mappings must be maps",
       %{operation: :replace_attribute_mappings, reason: :invalid_mapping}
     )}
  end

  defp normalize_group_mappings(mappings) do
    mappings
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {mapping, position}, {:ok, acc} ->
      case normalize_group_mapping(mapping, position) do
        {:ok, normalized} -> {:cont, {:ok, [normalized | acc]}}
        {:error, %Error{} = error} -> {:halt, {:error, error}}
      end
    end)
    |> case do
      {:ok, normalized} -> {:ok, Enum.reverse(normalized)}
      {:error, %Error{} = error} -> {:error, error}
    end
  end

  defp normalize_group_mapping(mapping, position) when is_map(mapping) do
    with :ok <- reject_unsupported_keys(mapping, @group_fields, :replace_group_mappings),
         {:ok, source_attribute} <-
           fetch_required_string(mapping, :source_attribute, :replace_group_mappings),
         {:ok, source_value} <-
           fetch_required_string(mapping, :source_value, :replace_group_mappings),
         {:ok, role_target} <-
           fetch_enum(mapping, :role_target, @group_targets, :replace_group_mappings),
         {:ok, role_value} <-
           fetch_required_string(mapping, :role_value, :replace_group_mappings) do
      {:ok,
       %{
         position: position,
         source_attribute: source_attribute,
         source_value: source_value,
         role_target: role_target,
         role_value: role_value
       }}
    end
  end

  defp normalize_group_mapping(_mapping, _position) do
    {:error,
     Error.new(
       :invalid_connection_record,
       "Group mappings must be maps",
       %{operation: :replace_group_mappings, reason: :invalid_mapping}
     )}
  end

  defp reject_unsupported_keys(mapping, allowed_fields, operation) do
    allowed_keys =
      allowed_fields
      |> Enum.flat_map(fn field -> [Atom.to_string(field)] end)
      |> MapSet.new()

    unsupported_keys =
      mapping
      |> Map.keys()
      |> Enum.filter(fn key ->
        normalized = normalize_key(key)
        normalized in @unsupported_mapping_keys or not MapSet.member?(allowed_keys, normalized)
      end)

    if unsupported_keys == [] do
      :ok
    else
      {:error,
       Error.new(
         :invalid_connection_record,
         "Mapping input includes unsupported transform semantics",
         %{
           operation: operation,
           reason: :unsupported_mapping_keys,
           unsupported_keys: Enum.map(unsupported_keys, &to_string/1)
         }
       )}
    end
  end

  defp fetch_required_string(mapping, key, operation) do
    value =
      mapping
      |> fetch_value(key)
      |> normalize_string()

    if is_binary(value) and value != "" do
      {:ok, value}
    else
      {:error,
       Error.new(
         :invalid_connection_record,
         "Mapping input is missing required fields",
         %{operation: operation, reason: :missing_required_field, field: key}
       )}
    end
  end

  defp fetch_enum(mapping, key, allowed, operation) do
    value =
      mapping
      |> fetch_value(key)
      |> normalize_enum()

    if value in allowed do
      {:ok, value}
    else
      {:error,
       Error.new(
         :invalid_connection_record,
         "Mapping input is outside the bounded mapping contract",
         %{
           operation: operation,
           reason: :invalid_enum,
           field: key,
           allowed: allowed,
           got: value
         }
       )}
    end
  end

  defp fetch_connection(repo, connection_id, operation) do
    case repo.get_by(Connection, connection_id: connection_id) do
      nil ->
        {:error,
         Error.new(
           :connection_not_found,
           "Connection record was not found",
           %{connection_id: connection_id, operation: operation, reason: :not_found}
         )}

      connection ->
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

  defp fetch_locked_connection(repo, connection_id, operation) do
    Connection
    |> where([connection], connection.connection_id == ^connection_id)
    |> lock("FOR UPDATE")
    |> repo.one()
    |> case do
      nil ->
        {:error,
         Error.new(
           :connection_not_found,
           "Connection record was not found",
           %{connection_id: connection_id, operation: operation, reason: :not_found}
         )}

      connection ->
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

  defp bump_connection_lock(repo, connection, operation) do
    changeset =
      connection
      |> Ecto.Changeset.change(updated_at: DateTime.utc_now())
      |> Ecto.Changeset.optimistic_lock(:lock_version)

    try do
      case repo.update(changeset) do
        {:ok, _updated_connection} ->
          :ok

        {:error, %Ecto.Changeset{} = stale_changeset} ->
          if stale_entry_error?(stale_changeset) do
            conflict_error(connection, operation)
          else
            {:error,
             changeset_error(
               operation,
               "Connection lock update failed validation",
               stale_changeset
             )}
          end
      end
    rescue
      Ecto.StaleEntryError -> conflict_error(connection, operation)
    end
  end

  defp replace_attribute_rows(repo, connection_record_id, mappings) do
    dumped_connection_record_id = Ecto.UUID.dump!(connection_record_id)

    repo.delete_all(
      from row in @attribute_table,
        where: field(row, :connection_record_id) == type(^connection_record_id, :binary_id)
    )

    rows =
      Enum.map(mappings, fn mapping ->
        %{
          id: Ecto.UUID.dump!(Ecto.UUID.generate()),
          connection_record_id: dumped_connection_record_id,
          position: mapping.position,
          source_attribute: mapping.source_attribute,
          target_field: Atom.to_string(mapping.target_field),
          multivalue_strategy: Atom.to_string(mapping.multivalue_strategy),
          inserted_at: DateTime.utc_now(),
          updated_at: DateTime.utc_now()
        }
      end)

    case rows do
      [] ->
        {:ok, 0}

      _rows ->
        {count, _} = repo.insert_all(@attribute_table, rows)
        {:ok, count}
    end
  end

  defp replace_group_rows(repo, connection_record_id, mappings) do
    dumped_connection_record_id = Ecto.UUID.dump!(connection_record_id)

    repo.delete_all(
      from row in @group_table,
        where: field(row, :connection_record_id) == type(^connection_record_id, :binary_id)
    )

    rows =
      Enum.map(mappings, fn mapping ->
        %{
          id: Ecto.UUID.dump!(Ecto.UUID.generate()),
          connection_record_id: dumped_connection_record_id,
          position: mapping.position,
          source_attribute: mapping.source_attribute,
          source_value: mapping.source_value,
          role_target: Atom.to_string(mapping.role_target),
          role_value: mapping.role_value,
          inserted_at: DateTime.utc_now(),
          updated_at: DateTime.utc_now()
        }
      end)

    case rows do
      [] ->
        {:ok, 0}

      _rows ->
        {count, _} = repo.insert_all(@group_table, rows)
        {:ok, count}
    end
  end

  defp mapping_snapshot(repo, connection_record_id) do
    attribute_rules =
      repo.all(
        from row in @attribute_table,
          where: field(row, :connection_record_id) == type(^connection_record_id, :binary_id),
          order_by: [asc: field(row, :position), asc: field(row, :inserted_at)],
          select: %{
            source_attribute: field(row, :source_attribute),
            target_field: field(row, :target_field),
            multivalue_strategy: field(row, :multivalue_strategy)
          }
      )

    group_rules =
      repo.all(
        from row in @group_table,
          where: field(row, :connection_record_id) == type(^connection_record_id, :binary_id),
          order_by: [asc: field(row, :position), asc: field(row, :inserted_at)],
          select: %{
            source_attribute: field(row, :source_attribute),
            source_value: field(row, :source_value),
            role_target: field(row, :role_target),
            role_value: field(row, :role_value)
          }
      )

    {:ok, %{attribute_rules: attribute_rules, group_rules: group_rules}}
  end

  defp mapping_action(before_rules, after_rules) do
    cond do
      before_rules == [] and after_rules != [] -> :created
      before_rules != [] and after_rules == [] -> :deleted
      true -> :replaced
    end
  end

  defp insert_revision(repo, connection, audit, action, before_snapshot, after_snapshot, changed_field) do
    diff_summary = diff_summary(before_snapshot, after_snapshot, changed_field)

    attrs = %{
      connection_record_id: connection.id,
      actor: normalize_string(Map.get(audit, :actor)),
      action: action,
      cause: normalize_string(Map.get(audit, :cause)),
      correlation_id: normalize_string(Map.get(audit, :correlation_id)),
      before_snapshot: before_snapshot,
      after_snapshot: after_snapshot,
      diff_summary: diff_summary
    }

    case %MappingRevision{} |> MappingRevision.changeset(attrs) |> repo.insert() do
      {:ok, revision} ->
        {:ok, revision}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error,
         changeset_error(
           :mapping_revision,
           "Mapping revision failed validation",
           changeset
         )}
    end
  end

  defp append_audit(
         repo,
         connection,
         audit,
         action,
         before_snapshot,
         after_snapshot,
         changed_field,
         revision_id,
         operation
       ) do
    case AuditWriter.append_event(repo, %{
           connection_record_id: connection.id,
           domain: :mapping,
           action: action,
           actor: Map.get(audit, :actor),
           cause: Map.get(audit, :cause),
           correlation_id: Map.get(audit, :correlation_id),
           before_view: before_snapshot,
           after_view: after_snapshot,
           diff_summary:
             diff_summary(before_snapshot, after_snapshot, changed_field)
             |> Map.put(:mapping_revision_id, revision_id)
         }) do
      {:ok, event} ->
        {:ok, event}

      {:error, %Error{} = error} ->
        rollback(
          repo,
          Error.new(
            error.type,
            error.message,
            Map.put(error.details, :operation, operation)
          )
        )
    end
  end

  defp diff_summary(before_snapshot, after_snapshot, changed_field) do
    before_rules = Map.get(before_snapshot, changed_field_to_rules_key(changed_field), [])
    after_rules = Map.get(after_snapshot, changed_field_to_rules_key(changed_field), [])

    %{
      changed_fields: [changed_field],
      before_count: length(before_rules),
      after_count: length(after_rules),
      added_count: max(length(after_rules) - length(before_rules), 0),
      removed_count: max(length(before_rules) - length(after_rules), 0)
    }
  end

  defp changed_field_to_rules_key(:attribute_mappings), do: :attribute_rules
  defp changed_field_to_rules_key(:group_mappings), do: :group_rules

  defp transact(repo, fun) do
    if function_exported?(repo, :transact, 1) do
      repo.transact(fun)
    else
      repo.transaction(fun)
    end
  end

  defp normalize_transaction_result({:ok, {:ok, result}}, _operation), do: {:ok, result}
  defp normalize_transaction_result({:ok, result}, _operation), do: {:ok, result}
  defp normalize_transaction_result({:error, %Error{} = error}, _operation), do: {:error, error}
  defp normalize_transaction_result({:error, {:error, %Error{} = error}}, _operation), do: {:error, error}

  defp normalize_transaction_result({:error, _step, %Error{} = error, _changes}, _operation),
    do: {:error, error}

  defp normalize_transaction_result(
         {:error, _step, {:error, %Error{} = error}, _changes},
         _operation
       ),
       do: {:error, error}

  defp normalize_transaction_result({:error, reason}, operation) do
    {:error,
     Error.new(
       :internal_protocol_error,
       "Mapping command transaction failed",
       %{operation: operation, reason: inspect(reason)}
     )}
  end

  defp normalize_transaction_result(other, operation) do
    {:error,
     Error.new(
       :internal_protocol_error,
       "Mapping command transaction returned an unexpected result",
       %{operation: operation, result: inspect(other)}
     )}
  end

  defp rollback(repo, value), do: repo.rollback(value)

  defp conflict_error(connection, operation) do
    {:error,
     Error.new(
       :invalid_connection_record,
       "Concurrent mapping mutation conflict",
       %{
         operation: operation,
         connection_id: connection.connection_id,
         reason: :conflict
       }
     )}
  end

  defp stale_entry_error?(%Ecto.Changeset{errors: errors}) do
    Enum.any?(errors, fn
      {:lock_version, {"is stale", _opts}} -> true
      _other -> false
    end)
  end

  defp changeset_error(operation, message, changeset) do
    Error.new(:invalid_connection_record, message, %{
      operation: operation,
      errors: format_changeset_errors(changeset)
    })
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  defp optional_dependency_error(repo, operation, reason) do
    {:error,
     Error.new(
       :optional_dependency_missing,
       "Ecto mapping persistence is unavailable",
       %{repo: inspect(repo), operation: operation, reason: inspect(reason)}
     )}
  end

  defp error_details(opts, operation, reason) do
    %{
      repo: inspect(Keyword.get(opts, :repo)),
      operation: operation,
      reason: inspect(reason)
    }
  end

  defp fetch_value(mapping, key), do: Map.get(mapping, key) || Map.get(mapping, Atom.to_string(key))

  defp normalize_string(value) when is_binary(value), do: String.trim(value)
  defp normalize_string(nil), do: nil
  defp normalize_string(value), do: value |> to_string() |> normalize_string()

  defp normalize_enum(value) when is_atom(value), do: value

  defp normalize_enum(value) when is_binary(value) do
    case String.trim(value) do
      "" ->
        nil

      normalized ->
        try do
          String.to_existing_atom(normalized)
        rescue
          ArgumentError -> nil
        end
    end
  end

  defp normalize_enum(_value), do: nil

  defp normalize_key(key) when is_atom(key), do: Atom.to_string(key)
  defp normalize_key(key) when is_binary(key), do: key
  defp normalize_key(key), do: to_string(key)
end
