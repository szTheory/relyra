defmodule Relyra.Ecto.CertificateInventory do
  @moduledoc false

  alias Relyra.Ecto.{AuditWriter, Certificate}
  alias Relyra.Ecto.CertificateFacts
  alias Relyra.Error

  @ecto_repo Ecto.Repo

  @spec stage_metadata_certificates(module(), struct(), struct(), map(), keyword()) ::
          :ok | {:error, Error.t()}
  def stage_metadata_certificates(repo, connection, revision, candidate, opts \\ [])

  def stage_metadata_certificates(repo, connection, revision, candidate, opts)
      when is_atom(repo) and is_map(connection) and is_map(revision) and is_map(candidate) and
             is_list(opts) do
    with :ok <- ensure_optional_dependencies(repo, :stage_metadata_certificates),
         {:ok, audit_context} <- validate_audit_context(opts, :stage_metadata_certificates),
         {:ok, certificate_attrs} <- metadata_certificate_attrs(candidate, revision) do
      before_view = certificate_trust_view(connection)

      Enum.reduce_while(certificate_attrs, :ok, fn attrs, :ok ->
        case upsert_staged_certificate(repo, connection, attrs) do
          :ok -> {:cont, :ok}
          {:error, %Error{} = error} -> {:halt, {:error, error}}
        end
      end)
      |> maybe_append_stage_audit(
        repo,
        connection.connection_id,
        connection.id,
        before_view,
        revision,
        audit_context
      )
    end
  end

  def stage_metadata_certificates(_repo, _connection, _revision, _candidate, _opts) do
    {:error,
     Error.new(
       :invalid_connection_record,
       "repo, connection, revision, and candidate are required for certificate staging",
       %{operation: :stage_metadata_certificates, reason: :invalid_input}
     )}
  end

  @spec activate_signing_certificate(module(), binary(), binary(), keyword()) ::
          {:ok, Certificate.t()} | {:error, Error.t()}
  def activate_signing_certificate(repo, connection_id, fingerprint, opts \\ [])

  def activate_signing_certificate(repo, connection_id, fingerprint, opts)
      when is_atom(repo) and is_binary(connection_id) and is_binary(fingerprint) and is_list(opts) do
    transition_certificate(repo, connection_id, fingerprint, :active, opts)
  end

  def activate_signing_certificate(_repo, _connection_id, _fingerprint, _opts) do
    {:error,
     Error.new(
       :invalid_connection_record,
       "repo, connection_id, and fingerprint are required for certificate activation",
       %{operation: :activate_signing_certificate, reason: :invalid_input}
     )}
  end

  @spec retire_signing_certificate(module(), binary(), binary(), keyword()) ::
          {:ok, Certificate.t()} | {:error, Error.t()}
  def retire_signing_certificate(repo, connection_id, fingerprint, opts \\ [])

  def retire_signing_certificate(repo, connection_id, fingerprint, opts)
      when is_atom(repo) and is_binary(connection_id) and is_binary(fingerprint) and is_list(opts) do
    transition_certificate(repo, connection_id, fingerprint, :retired, opts)
  end

  def retire_signing_certificate(_repo, _connection_id, _fingerprint, _opts) do
    {:error,
     Error.new(
       :invalid_connection_record,
       "repo, connection_id, and fingerprint are required for certificate retirement",
       %{operation: :retire_signing_certificate, reason: :invalid_input}
     )}
  end

  @spec rollback_signing_certificate(module(), binary(), binary(), binary(), keyword()) ::
          {:ok, [Certificate.t()]} | {:error, Error.t()}
  def rollback_signing_certificate(
        repo,
        connection_id,
        restore_fingerprint,
        retire_fingerprint,
        opts \\ []
      )

  def rollback_signing_certificate(
        repo,
        connection_id,
        restore_fingerprint,
        retire_fingerprint,
        opts
      )
      when is_atom(repo) and is_binary(connection_id) and is_binary(restore_fingerprint) and
             is_binary(retire_fingerprint) and is_list(opts) do
    with :ok <- ensure_optional_dependencies(repo, :rollback_signing_certificate),
         {:ok, audit_context} <- validate_audit_context(opts, :rollback_signing_certificate) do
      transact(repo, fn ->
        with {:ok, connection} <-
               fetch_connection(repo, connection_id, :rollback_signing_certificate),
             before_view = certificate_trust_view(connection),
             :ok <- bump_connection_lock(repo, connection, :rollback_signing_certificate),
             :ok <- maybe_run_after_lock(opts, :rollback_signing_certificate),
             {:ok, refreshed_connection} <-
               fetch_connection(repo, connection_id, :rollback_signing_certificate),
             {:ok, restored} <-
               do_transition(
                 repo,
                 refreshed_connection,
                 restore_fingerprint,
                 :active,
                 :rollback_signing_certificate
               ),
             {:ok, latest_connection} <-
               fetch_connection(repo, connection_id, :rollback_signing_certificate),
             {:ok, retired} <-
               do_transition(
                 repo,
                 latest_connection,
                 retire_fingerprint,
                 :retired,
                 :rollback_signing_certificate
               ),
             {:ok, final_connection} <-
               fetch_connection(repo, connection_id, :rollback_signing_certificate),
             {:ok, _audit_event} <-
               append_transition_audit(
                 repo,
                 final_connection.id,
                 :replaced,
                 before_view,
                 certificate_trust_view(final_connection),
                 audit_context,
                 %{
                   changed_fields: [:certificates],
                   restore_fingerprint: restore_fingerprint,
                   retire_fingerprint: retire_fingerprint
                 }
               ) do
          {:ok, [restored, retired]}
        end
      end)
      |> normalize_transaction_result(:rollback_signing_certificate)
    end
  end

  def rollback_signing_certificate(
        _repo,
        _connection_id,
        _restore_fingerprint,
        _retire_fingerprint,
        _opts
      ) do
    {:error,
     Error.new(
       :invalid_connection_record,
       "repo, connection_id, and rollback fingerprints are required",
       %{operation: :rollback_signing_certificate, reason: :invalid_input}
     )}
  end

  defp transition_certificate(repo, connection_id, fingerprint, target_state, opts) do
    operation = operation_for(target_state)

    with :ok <- ensure_optional_dependencies(repo, operation),
         {:ok, audit_context} <- validate_audit_context(opts, operation) do
      transact(repo, fn ->
        with {:ok, connection} <- fetch_connection(repo, connection_id, operation),
             before_view = certificate_trust_view(connection),
             :ok <- maybe_run_transition_hook(opts, :after_fetch, operation),
             :ok <- bump_connection_lock(repo, connection, operation),
             :ok <- maybe_run_after_lock(opts, operation),
             {:ok, refreshed_connection} <- fetch_connection(repo, connection_id, operation),
             {:ok, updated_certificate} <-
               do_transition(
                 repo,
                 refreshed_connection,
                 fingerprint,
                 target_state,
                 operation,
                 opts
               ),
             {:ok, latest_connection} <- fetch_connection(repo, connection_id, operation),
             {:ok, _audit_event} <-
               append_transition_audit(
                 repo,
                 latest_connection.id,
                 action_for(target_state),
                 before_view,
                 certificate_trust_view(latest_connection),
                 audit_context,
                 %{
                   changed_fields: [:certificates],
                   fingerprint_sha256: fingerprint,
                   target_state: target_state
                 }
               ) do
          {:ok, updated_certificate}
        end
      end)
      |> normalize_transaction_result(operation)
    end
  end

  defp do_transition(repo, connection, fingerprint, target_state, operation, _opts \\ []) do
    with {:ok, certificate} <- find_certificate(connection, fingerprint, operation),
         :ok <- validate_transition(connection, certificate, target_state, operation),
         {:ok, updated} <- persist_transition(repo, certificate, target_state, operation) do
      {:ok, updated}
    end
  end

  defp persist_transition(repo, certificate, target_state, operation) do
    attrs =
      case target_state do
        :active ->
          %{lifecycle_state: :active, activated_at: DateTime.utc_now()}

        :retired ->
          %{lifecycle_state: :retired, retired_at: DateTime.utc_now()}
      end

    case certificate |> Certificate.changeset(attrs) |> repo.update() do
      {:ok, updated} ->
        {:ok, updated}

      {:error, %Ecto.Changeset{} = invalid_changeset} ->
        {:error,
         changeset_error(
           operation,
           "Certificate lifecycle update failed validation",
           invalid_changeset
         )}
    end
  end

  defp validate_transition(connection, certificate, :active, operation) do
    allowed_from_states =
      case operation do
        :rollback_signing_certificate -> [:next, :retired]
        _other -> [:next]
      end

    if certificate.role == :signing and certificate.lifecycle_state in allowed_from_states do
      :ok
    else
      invalid_transition_error(connection, certificate, :active, operation)
    end
  end

  defp validate_transition(connection, certificate, :retired, operation) do
    active_signing_certs =
      connection.certificates
      |> Enum.filter(&(&1.role == :signing and &1.lifecycle_state == :active))

    cond do
      certificate.role != :signing or certificate.lifecycle_state != :active ->
        invalid_transition_error(connection, certificate, :retired, operation)

      length(active_signing_certs) == 1 ->
        {:error,
         Error.new(
           :invalid_connection_record,
           "Cannot retire the last active signing certificate",
           %{
             operation: operation,
             connection_id: connection.connection_id,
             reason: :last_active_certificate,
             fingerprint_sha256: certificate.fingerprint_sha256
           }
         )}

      true ->
        :ok
    end
  end

  defp invalid_transition_error(connection, certificate, target_state, operation) do
    {:error,
     Error.new(
       :invalid_connection_record,
       "Certificate transition is not allowed for the current lifecycle state",
       %{
         operation: operation,
         connection_id: connection.connection_id,
         fingerprint_sha256: certificate.fingerprint_sha256,
         reason: :invalid_lifecycle_transition,
         from: certificate.lifecycle_state,
         to: target_state
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

  defp conflict_error(connection, operation) do
    {:error,
     Error.new(
       :invalid_connection_record,
       "Concurrent certificate transition conflict",
       %{
         operation: operation,
         connection_id: connection.connection_id,
         reason: :conflict
       }
     )}
  end

  defp maybe_run_after_lock(opts, operation) do
    maybe_run_transition_hook(opts, :after_lock, operation)
  end

  defp maybe_run_transition_hook(opts, key, operation) do
    case Keyword.get(opts, key) do
      nil ->
        :ok

      callback when is_function(callback, 0) ->
        callback.()
        :ok

      _other ->
        {:error,
         Error.new(
           :invalid_connection_record,
           "#{key} must be a zero-arity function when provided",
           %{
             operation: operation,
             reason: :"invalid_#{key}"
           }
         )}
    end
  end

  defp stale_entry_error?(changeset) do
    Enum.any?(changeset.errors, fn
      {:lock_version, {"is stale", _opts}} -> true
      _other -> false
    end)
  end

  defp upsert_staged_certificate(repo, connection, attrs) do
    existing =
      Enum.find(
        connection.certificates,
        &(&1.fingerprint_sha256 == attrs.fingerprint_sha256 and &1.role == :signing)
      )

    changeset =
      case existing do
        nil ->
          %Certificate{}
          |> Certificate.changeset(Map.put(attrs, :connection_record_id, connection.id))

        certificate ->
          certificate
          |> Certificate.changeset(Map.put(attrs, :connection_record_id, connection.id))
      end

    persist_inventory_change(repo, changeset, :stage_metadata_certificates)
  end

  defp metadata_certificate_attrs(candidate, revision) do
    with {:ok, certificate_facts} <- certificate_facts(candidate) do
      {:ok,
       Enum.map(certificate_facts, fn %{pem: pem, fingerprint_sha256: fingerprint} = facts ->
         %{
           fingerprint_sha256: fingerprint,
           pem: pem,
           source: "metadata_revision:#{revision.id}",
           role: :signing,
           lifecycle_state: :next,
           staged_at: DateTime.utc_now(),
           not_before: facts.not_before,
           not_after: facts.not_after,
           metadata: %{metadata_revision_id: revision.id}
         }
       end)}
    end
  end

  defp certificate_facts(candidate) do
    facts = Map.get(candidate, :certificate_facts, [])

    cond do
      facts != [] ->
        normalize_certificate_facts(
          facts,
          Map.get(candidate, :certificate_fingerprints, [])
        )

      true ->
        candidate
        |> Map.get(:certificate_pems, [])
        |> Enum.zip(Map.get(candidate, :certificate_fingerprints, []))
        |> Enum.reduce_while({:ok, []}, fn {pem, fingerprint}, {:ok, acc} ->
          case CertificateFacts.extract(pem) do
            {:ok, decoded_facts} ->
              {:cont,
               {:ok,
                [
                  Map.merge(decoded_facts, %{pem: pem, fingerprint_sha256: fingerprint}) | acc
                ]}}

            {:error, %Error{} = error} ->
              {:halt, {:error, error}}
          end
        end)
        |> reverse_ok_list()
    end
  end

  defp normalize_certificate_facts(facts, fingerprints) do
    facts
    |> Enum.zip(fingerprints)
    |> Enum.reduce_while({:ok, []}, fn
      {%{error: %Error{} = error}, _fingerprint}, _acc ->
        {:halt, {:error, error}}

      {%{pem: pem, not_before: not_before, not_after: not_after}, fingerprint}, {:ok, acc} ->
        {:cont,
         {:ok,
          [
            %{
              pem: pem,
              fingerprint_sha256: fingerprint,
              not_before: not_before,
              not_after: not_after
            }
            | acc
          ]}}

      {_fact, _fingerprint}, _acc ->
        {:halt,
         {:error,
          Error.new(
            :invalid_connection_record,
            "Certificate PEM could not be decoded",
            %{reason: :invalid_certificate_pem}
          )}}
    end)
    |> reverse_ok_list()
  end

  defp reverse_ok_list({:ok, list}), do: {:ok, Enum.reverse(list)}
  defp reverse_ok_list({:error, %Error{} = error}), do: {:error, error}

  defp fetch_connection(repo, connection_id, operation) do
    case repo.get_by(Relyra.Ecto.Connection, connection_id: connection_id) do
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

  defp find_certificate(connection, fingerprint, operation) do
    case Enum.find(
           connection.certificates,
           &(&1.fingerprint_sha256 == fingerprint and &1.role == :signing)
         ) do
      nil ->
        {:error,
         Error.new(
           :connection_not_found,
           "Certificate record was not found for this connection",
           %{
             operation: operation,
             connection_id: connection.connection_id,
             fingerprint_sha256: fingerprint,
             reason: :certificate_not_found
           }
         )}

      certificate ->
        {:ok, certificate}
    end
  end

  defp persist_inventory_change(repo, changeset, operation) do
    case repo.insert_or_update(changeset) do
      {:ok, _certificate} ->
        :ok

      {:error, %Ecto.Changeset{} = invalid_changeset} ->
        {:error,
         changeset_error(
           operation,
           "Certificate inventory update failed validation",
           invalid_changeset
         )}
    end
  end

  defp ensure_optional_dependencies(repo, operation) do
    cond do
      not Code.ensure_loaded?(@ecto_repo) ->
        {:error, repo_details(repo, operation, :ecto_unavailable)}

      not Code.ensure_loaded?(Certificate) ->
        {:error, repo_details(repo, operation, :certificate_schema_unavailable)}

      not Code.ensure_loaded?(Relyra.Ecto.Connection) ->
        {:error, repo_details(repo, operation, :connection_schema_unavailable)}

      true ->
        :ok
    end
  end

  defp normalize_transaction_result({:ok, {:ok, result}}, _operation), do: {:ok, result}
  defp normalize_transaction_result({:ok, result}, _operation), do: {:ok, result}
  defp normalize_transaction_result({:error, %Error{} = error}, _operation), do: {:error, error}

  defp normalize_transaction_result({:error, {:error, %Error{} = error}}, _operation),
    do: {:error, error}

  defp normalize_transaction_result({:error, reason}, operation) do
    {:error,
     Error.new(
       :internal_protocol_error,
       "Certificate lifecycle transaction failed",
       %{operation: operation, reason: inspect(reason)}
     )}
  end

  defp transact(repo, fun) do
    if function_exported?(repo, :transact, 1) do
      repo.transact(fun)
    else
      repo.transaction(fun)
    end
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
       "Ecto certificate inventory persistence is unavailable",
       %{
         repo: inspect(repo),
         operation: operation,
         reason: reason
       }
     )}
  end

  defp operation_for(:active), do: :activate_signing_certificate
  defp operation_for(:retired), do: :retire_signing_certificate

  defp action_for(:active), do: :activated
  defp action_for(:retired), do: :retired

  defp maybe_append_stage_audit(
         :ok,
         _repo,
         _connection_id,
         _connection_record_id,
         _before_view,
         _revision,
         nil
       ),
       do: :ok

  defp maybe_append_stage_audit(
         :ok,
         repo,
         connection_id,
         connection_record_id,
         before_view,
         revision,
         audit_context
       ) do
    with {:ok, latest_connection} <-
           fetch_connection(repo, connection_id, :stage_metadata_certificates),
         {:ok, _audit_event} <-
           append_transition_audit(
             repo,
             connection_record_id,
             :staged,
             before_view,
             certificate_trust_view(latest_connection),
             audit_context,
             %{
               changed_fields: [:certificates],
               metadata_revision_id: revision.id,
               staged_fingerprints: Map.get(revision, :certificate_fingerprints, [])
             }
           ) do
      :ok
    end
  end

  defp maybe_append_stage_audit(
         {:error, %Error{} = error},
         _repo,
         _connection_id,
         _connection_record_id,
         _before_view,
         _revision,
         _audit_context
       ),
       do: {:error, error}

  defp append_transition_audit(
         _repo,
         _connection_record_id,
         _action,
         _before_view,
         _after_view,
         nil,
         _diff_summary
       ),
       do: {:ok, :skipped}

  defp append_transition_audit(
         repo,
         connection_record_id,
         action,
         before_view,
         after_view,
         audit_context,
         diff_summary
       ) do
    case AuditWriter.append_event(repo, %{
           connection_record_id: connection_record_id,
           domain: :certificate,
           action: action,
           actor: Map.get(audit_context, :actor),
           cause: Map.get(audit_context, :cause),
           correlation_id: Map.get(audit_context, :correlation_id),
           before_view: before_view,
           after_view: after_view,
           diff_summary: diff_summary,
           metadata: diff_summary
         }) do
      {:ok, event} -> {:ok, event}
      {:error, %Error{} = error} -> rollback(repo, error)
    end
  end

  defp validate_audit_context(opts, operation) do
    case Keyword.get(opts, :audit) do
      nil ->
        {:ok, nil}

      audit when is_map(audit) ->
        if present_string?(Map.get(audit, :actor)) and present_string?(Map.get(audit, :cause)) do
          {:ok, audit}
        else
          {:error,
           Error.new(
             :invalid_connection_record,
             "Audit context requires actor and cause",
             %{operation: operation, reason: :invalid_audit_context}
           )}
        end

      _other ->
        {:error,
         Error.new(
           :invalid_connection_record,
           "opts[:audit] must be a map when provided",
           %{operation: operation, reason: :invalid_audit_context}
         )}
    end
  end

  defp present_string?(value) when is_binary(value), do: String.trim(value) != ""
  defp present_string?(_value), do: false

  defp certificate_trust_view(connection) do
    certificates =
      connection
      |> Map.get(:certificates, [])
      |> Enum.map(fn cert ->
        %{
          fingerprint_sha256: cert.fingerprint_sha256,
          lifecycle_state: cert.lifecycle_state,
          role: cert.role,
          source: cert.source
        }
      end)
      |> Enum.sort_by(& &1.fingerprint_sha256)

    %{
      certificates: certificates,
      active_signing_fingerprints:
        certificates
        |> Enum.filter(&(&1.role == :signing and &1.lifecycle_state == :active))
        |> Enum.map(& &1.fingerprint_sha256),
      next_signing_fingerprints:
        certificates
        |> Enum.filter(&(&1.role == :signing and &1.lifecycle_state == :next))
        |> Enum.map(& &1.fingerprint_sha256),
      retired_signing_fingerprints:
        certificates
        |> Enum.filter(&(&1.role == :signing and &1.lifecycle_state == :retired))
        |> Enum.map(& &1.fingerprint_sha256)
    }
  end

  defp rollback(repo, value), do: repo.rollback(value)
end
