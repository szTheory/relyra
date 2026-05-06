defmodule Relyra.Ecto.MetadataApply do
  @moduledoc false

  alias Relyra.Ecto.{AuditWriter, CertificateInventory, Connection, MetadataRevision}
  alias Relyra.Error

  @ecto_repo Ecto.Repo

  @spec apply_revision(binary(), map(), map(), keyword()) ::
          {:ok, MetadataRevision.t()} | {:error, Error.t()}
  def apply_revision(connection_id, candidate, revision_attrs, opts \\ [])

  def apply_revision(connection_id, candidate, revision_attrs, opts)
      when is_binary(connection_id) and is_map(candidate) and is_map(revision_attrs) and
             is_list(opts) do
    candidate = normalized_candidate(candidate)

    with {:ok, repo} <- fetch_repo(opts, :apply_revision),
         :ok <- ensure_optional_dependency!(:apply_revision, repo),
         {:ok, _connection} <- fetch_connection(repo, connection_id, :apply_revision) do
      transact(repo, fn ->
        connection = load_connection!(repo, connection_id)
        revision_attrs = revision_attrs_for_apply(connection, candidate, revision_attrs)
        before_view = metadata_trust_view(connection)

        with {:ok, revision} <- insert_revision(repo, revision_attrs) do
          case apply_outcome(revision) do
            :applied ->
              with {:ok, applied_revision} <-
                     apply_candidate(repo, connection, candidate, revision),
                   {:ok, latest_connection} <-
                     fetch_connection(repo, connection_id, :apply_revision),
                   {:ok, _audit_event} <-
                     append_metadata_audit(
                       repo,
                       latest_connection,
                       applied_revision,
                       before_view,
                       metadata_trust_view(latest_connection),
                       audit_context(opts, revision_attrs)
                     ) do
                {:ok, applied_revision}
              end

            _other ->
              {:ok, revision}
          end
        end
      end)
      |> normalize_transaction_result(:apply_revision)
    end
  end

  def apply_revision(_connection_id, _candidate, _revision_attrs, opts) do
    {:error,
     Error.new(
       :invalid_connection_record,
       "connection_id, candidate, and revision_attrs are required for metadata apply",
       error_details(opts, :apply_revision, :invalid_input)
     )}
  end

  @spec record_attempt(binary(), map(), keyword()) ::
          {:ok, MetadataRevision.t()} | {:error, Error.t()}
  def record_attempt(connection_id, revision_attrs, opts \\ [])

  def record_attempt(connection_id, revision_attrs, opts)
      when is_binary(connection_id) and is_map(revision_attrs) and is_list(opts) do
    with {:ok, repo} <- fetch_repo(opts, :record_attempt),
         :ok <- ensure_optional_dependency!(:record_attempt, repo),
         {:ok, connection} <- fetch_connection(repo, connection_id, :record_attempt) do
      attrs =
        revision_attrs
        |> Map.put(:connection_record_id, connection.id)
        |> Map.put_new(:trust_summary, %{status: "attempt_recorded"})
        |> Map.update(:details, %{}, &redact_large_binaries/1)

      insert_revision(repo, attrs)
    end
  end

  def record_attempt(_connection_id, _revision_attrs, opts) do
    {:error,
     Error.new(
       :invalid_connection_record,
       "connection_id and revision_attrs are required for metadata attempt recording",
       error_details(opts, :record_attempt, :invalid_input)
     )}
  end

  defp apply_candidate(repo, connection, candidate, revision) do
    attrs = connection_attrs_for_candidate(connection, revision)

    case connection |> Connection.update_changeset(attrs) |> repo.update() do
      {:ok, updated_connection} ->
        case CertificateInventory.stage_metadata_certificates(
               repo,
               repo.preload(updated_connection, :certificates),
               revision,
               candidate,
               audit: audit_context_from_revision(revision)
             ) do
          :ok ->
            {:ok, revision}

          {:error, %Error{} = error} ->
            rollback(repo, error)
        end

      {:error, %Ecto.Changeset{} = invalid_changeset} ->
        rollback(
          repo,
          changeset_error(:apply_revision, "Metadata apply failed validation", invalid_changeset)
        )
    end
  end

  defp connection_attrs_for_candidate(connection, revision) do
    last_known_good_metadata_revision_id =
      case apply_outcome(revision) do
        :applied -> revision.id
        _other -> connection.last_known_good_metadata_revision_id
      end

    %{
      idp_entity_id: revision.effective_idp_entity_id,
      idp_sso_url: revision.effective_idp_sso_url,
      active_metadata_revision_id: revision.id,
      last_known_good_metadata_revision_id: last_known_good_metadata_revision_id
    }
  end

  defp revision_attrs_for_apply(connection, candidate, revision_attrs) do
    revision_attrs
    |> Map.put(:connection_record_id, connection.id)
    |> Map.put_new(:outcome, :applied)
    |> Map.put_new(:effective_idp_entity_id, Map.get(candidate, :idp_entity_id))
    |> Map.put_new(:effective_idp_sso_url, Map.get(candidate, :idp_sso_url))
    |> Map.put_new(:certificate_fingerprints, Map.get(candidate, :certificate_fingerprints, []))
    |> Map.put_new(:trust_summary, default_trust_summary(candidate))
    |> Map.update(:details, %{}, &redact_large_binaries/1)
  end

  defp default_trust_summary(candidate) do
    %{
      certificate_count: candidate |> Map.get(:certificate_fingerprints, []) |> length(),
      sso_binding: Map.get(candidate, :sso_binding),
      status: "applied"
    }
  end

  defp normalized_candidate(candidate) do
    certificates = Map.get(candidate, :certificates, [])

    if certificates == [] do
      candidate
    else
      candidate
      |> Map.put(:certificate_facts, certificates)
      |> Map.put(:certificate_pems, Enum.map(certificates, &Map.fetch!(&1, :pem)))
      |> Map.put(
        :certificate_fingerprints,
        Enum.map(certificates, &Map.fetch!(&1, :fingerprint_sha256))
      )
    end
  end

  defp insert_revision(repo, attrs) do
    case %MetadataRevision{} |> MetadataRevision.changeset(attrs) |> repo.insert() do
      {:ok, revision} ->
        {:ok, revision}

      {:error, %Ecto.Changeset{} = invalid_changeset} ->
        {:error,
         changeset_error(
           :record_attempt,
           "Metadata revision failed validation",
           invalid_changeset
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
           :adapter_not_configured,
           "opts[:repo] is required for metadata persistence",
           error_details(opts, operation, :missing_repo)
         )}
    end
  end

  defp ensure_optional_dependency!(operation, repo) do
    cond do
      not Code.ensure_loaded?(@ecto_repo) ->
        {:error, repo_details(repo, operation, :ecto_unavailable)}

      not Code.ensure_loaded?(Connection) ->
        {:error, repo_details(repo, operation, :connection_schema_unavailable)}

      not Code.ensure_loaded?(MetadataRevision) ->
        {:error, repo_details(repo, operation, :metadata_revision_unavailable)}

      true ->
        :ok
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
        {:ok, repo.preload(connection, :certificates)}
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

  defp load_connection!(repo, connection_id) do
    repo.get_by!(Connection, connection_id: connection_id)
    |> repo.preload(:certificates)
  end

  defp transact(repo, fun) do
    if function_exported?(repo, :transact, 1) do
      repo.transact(fun)
    else
      repo.transaction(fun)
    end
  end

  defp rollback(repo, value) do
    repo.rollback(value)
  end

  defp normalize_transaction_result({:ok, {:ok, revision}}, _operation), do: {:ok, revision}
  defp normalize_transaction_result({:ok, revision}, _operation), do: {:ok, revision}
  defp normalize_transaction_result({:error, %Error{} = error}, _operation), do: {:error, error}

  defp normalize_transaction_result({:error, {:error, %Error{} = error}}, _operation),
    do: {:error, error}

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
       "Metadata apply transaction failed",
       %{operation: operation, reason: inspect(reason)}
     )}
  end

  defp normalize_transaction_result(other, operation) do
    {:error,
     Error.new(
       :internal_protocol_error,
       "Metadata apply transaction returned an unexpected result",
       %{operation: operation, result: inspect(other)}
     )}
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

  defp repo_details(repo, operation, reason) do
    {:error,
     Error.new(
       :optional_dependency_missing,
       "Ecto metadata persistence is unavailable; add optional Ecto dependencies before using this adapter",
       %{repo: inspect(repo), operation: operation, reason: inspect(reason)}
     )}
  end

  defp error_details(opts, operation, reason) do
    %{repo: inspect(Keyword.get(opts, :repo)), operation: operation, reason: inspect(reason)}
  end

  defp apply_outcome(revision), do: Map.get(revision, :outcome, :applied)

  defp append_metadata_audit(_repo, _connection, _revision, _before_view, _after_view, nil),
    do: {:ok, :skipped}

  defp append_metadata_audit(repo, connection, revision, before_view, after_view, audit) do
    diff_summary = %{
      changed_fields: [
        :idp_entity_id,
        :idp_sso_url,
        :active_metadata_revision_id,
        :last_known_good_metadata_revision_id,
        :certificate_inventory
      ],
      certificate_fingerprints: Map.get(revision, :certificate_fingerprints, []),
      outcome: apply_outcome(revision)
    }

    case AuditWriter.append_event(repo, %{
           connection_record_id: connection.id,
           domain: :metadata,
           action: :applied,
           actor: Map.get(audit, :actor),
           cause: Map.get(audit, :cause),
           correlation_id: Map.get(audit, :correlation_id),
           before_view: before_view,
           after_view: after_view,
           diff_summary: diff_summary,
           subject_ref: revision.id,
           metadata: %{metadata_revision_id: revision.id}
         }) do
      {:ok, event} -> {:ok, event}
      {:error, %Error{} = error} -> rollback(repo, error)
    end
  end

  defp metadata_trust_view(connection) do
    %{
      idp_entity_id: connection.idp_entity_id,
      idp_sso_url: connection.idp_sso_url,
      active_metadata_revision_id: connection.active_metadata_revision_id,
      last_known_good_metadata_revision_id: connection.last_known_good_metadata_revision_id,
      certificate_inventory:
        connection
        |> Map.get(:certificates, [])
        |> Enum.map(fn cert ->
          %{
            fingerprint_sha256: cert.fingerprint_sha256,
            lifecycle_state: cert.lifecycle_state,
            role: cert.role
          }
        end)
        |> Enum.sort_by(& &1.fingerprint_sha256)
    }
  end

  defp audit_context(opts, revision_attrs) do
    case Keyword.get(opts, :audit) do
      audit when is_map(audit) ->
        audit

      nil ->
        audit_context_from_revision(revision_attrs)

      _other ->
        nil
    end
  end

  defp audit_context_from_revision(revision_like) do
    actor = Map.get(revision_like, :actor)
    cause = Map.get(revision_like, :cause)

    if present_string?(actor) and present_string?(cause) do
      %{
        actor: actor,
        cause: cause,
        correlation_id: Map.get(revision_like, :correlation_id)
      }
    else
      nil
    end
  end

  defp present_string?(value) when is_binary(value), do: String.trim(value) != ""
  defp present_string?(_value), do: false

  defp redact_large_binaries(map) when is_map(map) do
    map
    |> Enum.map(fn
      {key, value} when is_binary(value) and byte_size(value) > 256 -> {key, "[REDACTED]"}
      {key, value} -> {key, value}
    end)
    |> Enum.into(%{})
  end

  defp redact_large_binaries(other), do: other
end
