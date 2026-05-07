defmodule Relyra.Ecto.MetadataApply do
  @moduledoc false

  alias Relyra.Ecto.{
    AuditWriter,
    CertificateInventory,
    Connection,
    MetadataRevision,
    MetadataSource
  }

  alias Relyra.Error
  alias Relyra.Metadata.{Backoff, Cadence, FailureClassifier}

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
                     ),
                   :ok <- maybe_reset_health_state_on_apply(repo, revision_attrs, candidate) do
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

      transact(repo, fn ->
        with {:ok, revision} <- insert_revision(repo, attrs) do
          case maybe_update_health_state_on_attempt(repo, attrs) do
            :ok -> {:ok, revision}
            {:error, %Error{} = error} -> rollback(repo, error)
          end
        end
      end)
      |> normalize_transaction_result(:record_attempt)
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

  @doc """
  Records a `:validity_warning` for a metadata source per D-14.

  At-most-once per `validUntil` window per source: if `source.last_validity_warning_for`
  is non-nil AND equal to (or newer than) the candidate's `valid_until`, this is a
  no-op. Otherwise, updates `last_validity_warning_for` AND emits the telemetry event
  inside ONE `transact/2` block.

  `attrs` MUST include:
    - `:valid_until` — `DateTime.t()` from the freshly-parsed metadata root
    - `:refresh_interval_seconds` — `pos_integer` (the source's preset interval)
    - `:correlation_id` — the batch correlation_id (D-39)
  `attrs` MAY include:
    - `:slack_seconds` — `(valid_until - now) - 2 * refresh_interval_seconds`
      (negative when warning fires)
  """
  @spec record_validity_warning(module(), MetadataSource.t(), map()) ::
          {:ok, :emitted | :suppressed} | {:error, Error.t()}
  def record_validity_warning(repo, source, attrs)

  def record_validity_warning(
        repo,
        %MetadataSource{} = source,
        %{valid_until: %DateTime{} = valid_until} = attrs
      )
      when is_atom(repo) do
    with :ok <- ensure_optional_dependency!(:record_validity_warning, repo) do
      if already_warned_for?(source, valid_until) do
        {:ok, :suppressed}
      else
        transact(repo, fn ->
          health_attrs = %{last_validity_warning_for: valid_until}

          case source |> MetadataSource.health_state_changeset(health_attrs) |> repo.update() do
            {:ok, _updated} ->
              payload = %{
                source_id: source.id,
                connection_record_id: source.connection_record_id,
                correlation_id: Map.get(attrs, :correlation_id),
                valid_until: valid_until,
                refresh_interval_seconds: Map.get(attrs, :refresh_interval_seconds),
                slack_seconds: Map.get(attrs, :slack_seconds)
              }

              :telemetry.execute(
                [:relyra, :saml, :metadata, :auto_refresh, :validity_warning],
                %{},
                payload
              )

              {:ok, :emitted}

            {:error, %Ecto.Changeset{} = invalid_changeset} ->
              rollback(
                repo,
                changeset_error(
                  :record_validity_warning,
                  "Validity-warning persistence failed validation",
                  invalid_changeset
                )
              )
          end
        end)
        |> normalize_transaction_result(:record_validity_warning)
      end
    end
  end

  def record_validity_warning(_repo, _source, _attrs) do
    {:error,
     Error.new(
       :invalid_record_validity_warning_inputs,
       "record_validity_warning/3 requires (repo, %MetadataSource{}, %{valid_until: %DateTime{}})",
       %{}
     )}
  end

  @doc """
  Resume the auto-refresh schedule for a previously-auto-suspended source
  per D-28: clears `auto_suspended_until` and `auto_suspended_reason` AND
  writes the operator-intent audit row inside ONE transaction. Called by
  Plan 06's "Resume now" LiveView button.

  The LiveView MUST NOT perform a parallel `repo.update` to clear the
  suspend — doing so would re-introduce the audit/state divergence Phase
  21 is designed to prevent. This function is the single seam (D-35).

  `opts` MUST include:
    - `:actor` — the operator identity for the audit row
  `opts` MAY include:
    - `:cause` — overrides the default `"live_admin_auto_refresh_resume"`
      (rarely needed; mostly for testing)
    - `:correlation_id` — propagated to the audit row for cross-referencing
  """
  @spec resume_auto_refresh(module(), MetadataSource.t(), map()) ::
          {:ok, %{audit_event: term(), source: MetadataSource.t()}}
          | {:error, Error.t()}
  def resume_auto_refresh(repo, source, opts)

  def resume_auto_refresh(repo, %MetadataSource{} = source, %{} = opts)
      when is_atom(repo) do
    with :ok <- ensure_optional_dependency!(:resume_auto_refresh, repo),
         {:ok, connection} <- fetch_connection_by_id(repo, source.connection_record_id) do
      actor = Map.get(opts, :actor) || "operator"
      cause = Map.get(opts, :cause, "live_admin_auto_refresh_resume")
      correlation_id = Map.get(opts, :correlation_id)

      transact(repo, fn ->
        # Step 1: clear the suspend state via the SAME health_state_changeset
        # path that record_attempt/3 uses; co-committed in this transaction.
        health_attrs = %{auto_suspended_until: nil, auto_suspended_reason: nil}

        case apply_health_changeset(repo, source, health_attrs) do
          :ok ->
            updated_source = repo.get(MetadataSource, source.id)

            # Step 2: append the operator-intent audit row via the single
            # audit-writer seam (D-35). Domain :metadata + action :refreshed
            # is the closest schema-allowed shape for "schedule resumed".
            audit_attrs = %{
              connection_record_id: connection.id,
              domain: :metadata,
              action: :refreshed,
              actor: actor,
              cause: cause,
              correlation_id: correlation_id,
              before_view: %{
                auto_suspended_until: format_datetime(source.auto_suspended_until),
                auto_suspended_reason: format_reason(source.auto_suspended_reason)
              },
              after_view: %{
                auto_suspended_until: nil,
                auto_suspended_reason: nil
              },
              diff_summary: %{
                action: "auto_refresh_resumed",
                metadata_source_id: source.id
              },
              subject_ref: source.id,
              metadata: %{metadata_source_id: source.id}
            }

            case AuditWriter.append_event(repo, audit_attrs) do
              {:ok, audit_event} ->
                {:ok, %{audit_event: audit_event, source: updated_source}}

              {:error, %Error{} = error} ->
                rollback(repo, error)

              {:error, %Ecto.Changeset{} = invalid_changeset} ->
                rollback(
                  repo,
                  changeset_error(
                    :resume_auto_refresh_audit,
                    "Resume audit-event write failed validation",
                    invalid_changeset
                  )
                )
            end

          {:error, %Error{} = error} ->
            rollback(repo, error)
        end
      end)
      |> normalize_resume_transaction_result()
    end
  end

  def resume_auto_refresh(_repo, _source, _opts) do
    {:error,
     Error.new(
       :invalid_resume_auto_refresh_inputs,
       "resume_auto_refresh/3 requires (repo_module, %MetadataSource{}, %{actor: _})",
       %{}
     )}
  end

  defp fetch_connection_by_id(repo, connection_record_id) do
    case repo.get(Connection, connection_record_id) do
      nil ->
        {:error,
         Error.new(
           :connection_not_found,
           "Connection record was not found",
           %{
             connection_record_id: connection_record_id,
             operation: :resume_auto_refresh,
             reason: :not_found
           }
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
           connection_record_id: connection_record_id,
           operation: :resume_auto_refresh,
           reason: :repo_misconfigured,
           repo: inspect(repo),
           failure: Exception.message(exception)
         }
       )}
  end

  defp format_reason(nil), do: nil
  defp format_reason(value) when is_atom(value), do: Atom.to_string(value)
  defp format_reason(value), do: value

  defp format_datetime(nil), do: nil
  defp format_datetime(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp format_datetime(value), do: value

  defp normalize_resume_transaction_result({:ok, {:ok, %{} = result}}), do: {:ok, result}
  defp normalize_resume_transaction_result({:ok, %{} = result}), do: {:ok, result}

  defp normalize_resume_transaction_result({:error, %Error{} = error}), do: {:error, error}

  defp normalize_resume_transaction_result({:error, {:error, %Error{} = error}}),
    do: {:error, error}

  defp normalize_resume_transaction_result(other) do
    {:error,
     Error.new(
       :internal_protocol_error,
       "Metadata apply transaction returned an unexpected result",
       %{operation: :resume_auto_refresh, result: inspect(other)}
     )}
  end

  defp already_warned_for?(%MetadataSource{last_validity_warning_for: nil}, _valid_until),
    do: false

  defp already_warned_for?(
         %MetadataSource{last_validity_warning_for: %DateTime{} = stored},
         %DateTime{} = candidate
       ) do
    # At-most-once per D-14: warning is suppressed when we already warned for THIS
    # validUntil (or a newer one — IdP shortened the validity window since our last
    # warning, no need to re-fire). Re-fires only when IdP publishes a NEW (later)
    # validUntil.
    DateTime.compare(stored, candidate) in [:eq, :gt]
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

  # D-28: Phase 21 health-state co-commit. Only fires when the attempt was
  # part of a scheduled-refresh batch (trigger == :scheduled_refresh or
  # :scheduled_probe). Manual triggers (:manual_refresh / :manual_import)
  # are unaffected — Phase 21 does not change the manual path's behavior.
  defp maybe_update_health_state_on_attempt(repo, %{outcome: outcome} = attrs) do
    source_id = Map.get(attrs, :metadata_source_id)
    trigger = Map.get(attrs, :trigger)

    cond do
      not is_binary(source_id) ->
        :ok

      not scheduled_trigger?(trigger) ->
        :ok

      true ->
        do_update_health_state_on_attempt(repo, source_id, outcome, attrs)
    end
  end

  defp maybe_update_health_state_on_attempt(_repo, _attrs), do: :ok

  defp scheduled_trigger?(:scheduled_refresh), do: true
  defp scheduled_trigger?(:scheduled_probe), do: true
  defp scheduled_trigger?(_other), do: false

  defp do_update_health_state_on_attempt(repo, source_id, outcome, attrs) do
    case repo.get(MetadataSource, source_id) do
      nil ->
        # Source row was deleted between the scheduler tick and this write —
        # nothing to update. Do not fail the transaction; the audit row is
        # the canonical record of the attempt.
        :ok

      %MetadataSource{} = source ->
        health_attrs = compute_failure_health_state(source, outcome, attrs)
        apply_health_changeset(repo, source, health_attrs)
    end
  end

  # Pitfall 1 + D-25 + D-27: every failure outcome that surfaces an
  # error_code goes through the classifier. Transient codes increment the
  # counter and may set auto_suspended_until via Backoff. Suspicious codes
  # do NOT count toward suspend per D-27 (they alert immediately and
  # require human review).
  defp compute_failure_health_state(%MetadataSource{} = source, outcome, attrs)
       when outcome in [
              :fetch_failed,
              :parse_failed,
              :validation_failed,
              :apply_failed
            ] do
    now = DateTime.utc_now()
    error_code = error_code_from_attrs(attrs)
    classification = FailureClassifier.classify(error_code)
    correlation_id = correlation_id_from_attrs(attrs)

    base = %{last_failure_error_code: Atom.to_string(error_code)}

    cond do
      classification.counts_toward_suspend? ->
        new_count = (source.consecutive_failure_count || 0) + 1
        first_failure_at = source.first_failure_at || now

        base
        |> Map.put(:consecutive_failure_count, new_count)
        |> Map.put(:first_failure_at, first_failure_at)
        |> maybe_put_suspend(new_count, attrs, now)
        |> Map.put(:_phase21_classification, classification)
        |> Map.put(:_phase21_correlation_id, correlation_id)

      true ->
        # Suspicious failure: mark the failure code but do NOT advance the
        # counter or schedule a backoff (D-27 — these need human eyes).
        base
        |> Map.put(:_phase21_classification, classification)
        |> Map.put(:_phase21_correlation_id, correlation_id)
    end
  end

  defp compute_failure_health_state(_source, _outcome, _attrs), do: %{}

  defp maybe_put_suspend(attrs, new_count, source_attrs, now) do
    if new_count >= Backoff.suspend_threshold() do
      attrs
      |> Map.put(:auto_suspended_until, Backoff.backoff_until(new_count, now))
      |> Map.put(:auto_suspended_reason, suspend_reason_from_attrs(source_attrs))
    else
      attrs
    end
  end

  # Default reason when a suspend fires from accumulated transient
  # failures (D-25). Drift / signature / corpus suspends override this
  # at their respective call sites by setting `:auto_suspended_reason`
  # explicitly in the attrs map BEFORE calling record_attempt/3.
  defp suspend_reason_from_attrs(attrs) do
    Map.get(attrs, :auto_suspended_reason, :transient_failures_exceeded)
  end

  defp error_code_from_attrs(attrs) do
    cond do
      is_atom(Map.get(attrs, :error_code)) and not is_nil(Map.get(attrs, :error_code)) ->
        Map.get(attrs, :error_code)

      is_binary(Map.get(attrs, :error_code)) ->
        String.to_atom(Map.get(attrs, :error_code))

      is_map(Map.get(attrs, :details)) and is_atom(Map.get(attrs.details, :error_code)) and
          not is_nil(Map.get(attrs.details, :error_code)) ->
        Map.get(attrs.details, :error_code)

      is_map(Map.get(attrs, :details)) and is_binary(Map.get(attrs.details, :error_code)) ->
        String.to_atom(Map.fetch!(attrs.details, :error_code))

      true ->
        :unknown
    end
  end

  defp correlation_id_from_attrs(attrs) do
    cond do
      is_binary(Map.get(attrs, :correlation_id)) ->
        Map.get(attrs, :correlation_id)

      is_map(Map.get(attrs, :audit)) and is_binary(Map.get(attrs.audit, :correlation_id)) ->
        Map.fetch!(attrs.audit, :correlation_id)

      true ->
        nil
    end
  end

  defp apply_health_changeset(repo, source, attrs)

  defp apply_health_changeset(repo, %MetadataSource{} = source, attrs) when map_size(attrs) > 0 do
    classification_attrs =
      Map.take(attrs, [:_phase21_classification, :_phase21_correlation_id])

    cast_attrs = Map.drop(attrs, [:_phase21_classification, :_phase21_correlation_id])

    case source |> MetadataSource.health_state_changeset(cast_attrs) |> repo.update() do
      {:ok, updated} ->
        emit_state_transitions(source, updated, Map.merge(cast_attrs, classification_attrs))
        :ok

      {:error, %Ecto.Changeset{} = invalid_changeset} ->
        {:error,
         changeset_error(
           :record_attempt_health_state,
           "Phase 21 auto-refresh health-state write failed validation",
           invalid_changeset
         )}
    end
  end

  defp apply_health_changeset(_repo, _source, _empty), do: :ok

  # D-24 state-transition events fire INSIDE the transact/2 block so the
  # audit row + telemetry event are co-committed (or both rolled back).
  # :telemetry.execute is synchronous and side-effect-only; if the
  # surrounding transaction rolls back, the emit already happened but
  # the listener's downstream effects are the host's responsibility (the
  # event payload carries `correlation_id` so the host can dedupe against
  # an audit row that never landed).
  defp emit_state_transitions(
         %MetadataSource{} = before_source,
         %MetadataSource{} = updated,
         attrs
       ) do
    payload = state_transition_payload(updated, attrs)

    # :degraded — first transient failure that takes consecutive_failure_count from 0 -> 1
    if (before_source.consecutive_failure_count || 0) == 0 and
         (updated.consecutive_failure_count || 0) == 1 do
      :telemetry.execute(
        [:relyra, :saml, :metadata, :auto_refresh, :degraded],
        %{},
        payload
      )
    end

    # :suspended — the attempt that set auto_suspended_until from nil to a value
    if is_nil(before_source.auto_suspended_until) and not is_nil(updated.auto_suspended_until) do
      :telemetry.execute(
        [:relyra, :saml, :metadata, :auto_refresh, :suspended],
        %{},
        payload
      )
    end

    # :recovered — successful apply on a previously-suspended source
    # (auto_suspended_until cleared by the success path)
    if not is_nil(before_source.auto_suspended_until) and is_nil(updated.auto_suspended_until) do
      :telemetry.execute(
        [:relyra, :saml, :metadata, :auto_refresh, :recovered],
        %{},
        payload
      )
    end

    :ok
  end

  defp state_transition_payload(%MetadataSource{} = source, attrs) do
    classification = classification_for(attrs)

    %{
      source_id: source.id,
      connection_record_id: source.connection_record_id,
      correlation_id: Map.get(attrs, :_phase21_correlation_id),
      error_code: source.last_failure_error_code,
      consecutive_failure_count: source.consecutive_failure_count || 0,
      auto_suspended_reason: source.auto_suspended_reason,
      transient?: classification.transient?,
      counts_toward_suspend?: classification.counts_toward_suspend?
    }
  end

  defp classification_for(attrs) do
    case Map.get(attrs, :_phase21_classification) do
      %{transient?: _} = c -> c
      _ -> %{transient?: false, counts_toward_suspend?: false}
    end
  end

  # Pitfall 6 + D-25 (recovered) + D-12 (next_refresh_at advance): on a
  # successful scheduled apply, reset every counter, clear suspend, set
  # last_success_at, advance next_refresh_at via Cadence, AND extend
  # last_known_metadata_signing_certs with the candidate's fingerprints.
  defp maybe_reset_health_state_on_apply(repo, revision_attrs, candidate) do
    source_id = Map.get(revision_attrs, :metadata_source_id)
    trigger = Map.get(revision_attrs, :trigger)

    cond do
      is_nil(source_id) ->
        :ok

      not scheduled_trigger?(trigger) ->
        :ok

      true ->
        case repo.get(MetadataSource, source_id) do
          nil ->
            :ok

          %MetadataSource{} = source ->
            now = DateTime.utc_now()
            correlation_id = correlation_id_from_attrs(revision_attrs)

            health_attrs = %{
              consecutive_failure_count: 0,
              first_failure_at: nil,
              last_success_at: now,
              last_failure_error_code: nil,
              auto_suspended_until: nil,
              auto_suspended_reason: nil,
              next_refresh_at: Cadence.next_refresh_at(source.refresh_cadence, now),
              last_known_metadata_signing_certs:
                union_known_certs(
                  source.last_known_metadata_signing_certs,
                  Map.get(candidate, :certificate_fingerprints, [])
                ),
              _phase21_classification: %{transient?: false, counts_toward_suspend?: false},
              _phase21_correlation_id: correlation_id
            }

            apply_health_changeset(repo, source, health_attrs)
        end
    end
  end

  defp union_known_certs(existing, fresh) when is_list(existing) and is_list(fresh) do
    MapSet.new(existing) |> MapSet.union(MapSet.new(fresh)) |> MapSet.to_list()
  end

  defp union_known_certs(_existing, fresh) when is_list(fresh), do: fresh
  defp union_known_certs(existing, _fresh) when is_list(existing), do: existing
  defp union_known_certs(_existing, _fresh), do: []

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
        String.replace(acc, "%{#{key}}", safe_to_string(value))
      end)
    end)
  end

  # Ecto.Changeset error opts can include parameterized-type tuples (e.g. for
  # Ecto.Enum casts). String.Chars is not implemented for Tuple, so guard with
  # inspect/1 for non-stringable values.
  defp safe_to_string(value) do
    to_string(value)
  rescue
    Protocol.UndefinedError -> inspect(value)
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
