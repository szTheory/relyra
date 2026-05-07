---
phase: 21
plan: 04
type: execute
wave: 2
depends_on: [21-01, 21-02]
files_modified:
  - lib/relyra/ecto/metadata_apply.ex
  - lib/relyra/security/signature.ex
  - test/relyra/ecto/metadata_apply_test.exs
  - test/relyra/security/signature_test.exs
autonomous: true
requirements:
  - CFG-08
must_haves:
  truths:
    - "Every consecutive_failure_count, auto_suspended_until, last_success_at, and last_failure_error_code mutation co-commits inside the same transaction as the MetadataRevision row + AuditWriter event (D-28)"
    - "On scheduled-refresh success, the same transaction resets consecutive_failure_count to 0, clears first_failure_at, clears auto_suspended_until, sets last_success_at, and sets next_refresh_at via Cadence.next_refresh_at/2 (Pitfall 6 — half-open probe must close the circuit)"
    - "On scheduled-refresh failure, the same transaction increments consecutive_failure_count, sets last_failure_error_code, and (if the classifier marks the code as counts_toward_suspend? AND count >= Backoff.suspend_threshold()) sets auto_suspended_until via Backoff.backoff_until/2 with the typed auto_suspended_reason"
    - "Relyra.Security.Signature exposes a verify_metadata_root/4 path that emits telemetry under [:relyra, :saml, :signature, :verify] with flow: :metadata_refresh while reusing the same do_verify trust posture (D-16)"
    - "Manual-import code paths still call MetadataApply.record_attempt/3 and apply_revision/4 successfully — Phase 21 health-state writes are gated on the presence of a :metadata_source_id + :scheduled_refresh trigger so manual import is unaffected"
  artifacts:
    - path: "lib/relyra/ecto/metadata_apply.ex"
      provides: "Extended record_attempt/3 + apply_revision/4 with health-state co-commit (D-28); record_attempt/3 wrapped in transact/2"
      exports: ["apply_revision/4", "record_attempt/3"]
    - path: "lib/relyra/security/signature.ex"
      provides: "verify_metadata_root/4 — thin shim over the existing do_verify path with metadata_refresh flow tag (D-16)"
      exports: ["verify/4", "verify_metadata_root/4"]
  key_links:
    - from: "lib/relyra/ecto/metadata_apply.ex (extended record_attempt/3)"
      to: "Relyra.Ecto.MetadataSource.health_state_changeset/2 (Plan 01)"
      via: "Single transact block writes MetadataRevision + (when scheduled trigger) MetadataSource health state"
      pattern: "MetadataSource.health_state_changeset"
    - from: "Plan 04 health-state computation"
      to: "Relyra.Metadata.FailureClassifier.classify/1 + Relyra.Metadata.Backoff.backoff_until/2 + Relyra.Metadata.Cadence.next_refresh_at/2 (Plan 02)"
      via: "Pure helpers compute the new health state inside the transact block"
      pattern: "FailureClassifier.classify"
    - from: "lib/relyra/security/signature.ex verify_metadata_root/4"
      to: "lib/relyra/security/signature.ex do_verify/4 (existing private)"
      via: "Reuses the existing trust primitive verbatim — only the telemetry flow tag differs"
      pattern: "do_verify"
---

<objective>
Extend the single audit-writer seam (`MetadataApply.record_attempt/3` and `apply_revision/4`) so EVERY scheduled-refresh attempt's counter / `auto_suspended_until` / `last_success_at` / `last_failure_error_code` mutation co-commits inside the same `Repo.transact/1` block that writes the `MetadataRevision` row and the `AuditWriter.append_event` audit row. Add a thin `Relyra.Security.Signature.verify_metadata_root/4` shim so the Phase-21 wrapper can verify the `<EntityDescriptor>` / `<EntitiesDescriptor>` root signature using the SAME `do_verify/4` trust primitive (no parser differentials per PROJECT.md), distinguished only by a `flow: :metadata_refresh` telemetry tag.

Purpose: D-28 is the single most important Phase-21 discipline (RESEARCH "load-bearing recommendations" #2). Health-state writes that drift outside the `record_attempt/3` transaction would let `consecutive_failure_count` increment without an audit row recording the attempt — the audit ledger and the source row would disagree, breaking the auditability invariant from PROJECT.md. Pitfall 6 also requires the success path to RESET counters: a half-open probe that succeeds must close the circuit, not stay at `consecutive_failure_count: 5`. The signature shim is necessary because RESEARCH Pitfall 4 mandates verifying the metadata root BEFORE parse-deeply; the AutoRefresh wrapper in Plan 05 will call `verify_metadata_root/4` for that pre-verification step.

Output: Two extended modules and two extended test files. Manual-import code paths (Phase 9 / 12) MUST remain green; this plan adds new behavior gated on the `trigger: :scheduled_refresh` discriminator and never modifies the manual path's behavior.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/phases/21-scheduled-metadata-refresh/21-CONTEXT.md
@.planning/phases/21-scheduled-metadata-refresh/21-RESEARCH.md
@.planning/phases/21-scheduled-metadata-refresh/21-PATTERNS.md
@.planning/phases/21-scheduled-metadata-refresh/21-VALIDATION.md
@lib/relyra/ecto/metadata_apply.ex
@lib/relyra/security/signature.ex
@lib/relyra/ecto/metadata_source.ex

<interfaces>
Existing `MetadataApply.record_attempt/3` (lines 67-80) — currently NOT wrapped in `transact/2`:

```elixir
def record_attempt(connection_id, revision_attrs, opts) do
  with {:ok, repo} <- fetch_repo(opts, :record_attempt),
       :ok <- ensure_optional_dependency!(:record_attempt, repo),
       {:ok, connection} <- fetch_connection(repo, connection_id, :record_attempt) do
    attrs = revision_attrs |> Map.put(:connection_record_id, connection.id) |> ...
    insert_revision(repo, attrs)  # <-- SINGLE WRITE; Phase 21 wraps + adds health-state write
  end
end
```

Existing `MetadataApply.apply_revision/4` (lines 11-52) — already wrapped in `transact/2`:

```elixir
def apply_revision(...) do
  with ...do
    transact(repo, fn ->
      ...
      with {:ok, revision} <- insert_revision(repo, revision_attrs) do
        case apply_outcome(revision) do
          :applied -> ...apply_candidate + audit...
          _other -> {:ok, revision}
        end
      end
    end)
    |> normalize_transaction_result(:apply_revision)
  end
end
```

Existing `transact/2` helper (lines 248-254) — handles both `repo.transact/1` and `repo.transaction/1`:

```elixir
defp transact(repo, fun) do
  if function_exported?(repo, :transact, 1) do
    repo.transact(fun)
  else
    repo.transaction(fun)
  end
end
```

Pure helpers from Plan 02 (used inside the transact block):

- `Relyra.Metadata.FailureClassifier.classify(error_code) :: %{transient?: bool, counts_toward_suspend?: bool, alert_immediately?: bool}`
- `Relyra.Metadata.Backoff.backoff_until(consecutive_failures, base) :: DateTime.t()`
- `Relyra.Metadata.Backoff.suspend_threshold() :: 5`
- `Relyra.Metadata.Cadence.next_refresh_at(cadence, base) :: DateTime.t()`

Schema changeset from Plan 01:

- `Relyra.Ecto.MetadataSource.health_state_changeset(source, attrs)` casts the 9 health fields ONLY.

Existing `Relyra.Security.Signature.verify/4` shape (lines 8-34) — preserve unchanged:

```elixir
@spec verify(map(), map(), [binary()], keyword()) :: {:ok, SignedNode.t()} | {:error, Error.t()}
def verify(parsed_doc, connection, cert_chain, opts \\ []) do
  metadata = %{connection_id: ..., flow: :sp_initiated}
  Relyra.Telemetry.span([:signature, :verify], metadata, fn ->
    do_verify(parsed_doc, connection, cert_chain, opts)
  end)
end
```

Discriminator that determines whether health-state side-effect runs: presence of `:trigger` == `:scheduled_refresh` (or `:scheduled_probe` for Plan 06's Resume-now path) in `revision_attrs` AND presence of `:metadata_source_id`. Manual paths use `trigger: :manual_refresh` or `:manual_import` (existing — `lib/relyra/metadata/refresh.ex:25` and `lib/relyra/metadata/import.ex:26`) and SHOULD NOT trigger the new health-state write.
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Wrap record_attempt/3 in a transaction and co-commit health-state for scheduled triggers</name>
  <files>lib/relyra/ecto/metadata_apply.ex, test/relyra/ecto/metadata_apply_test.exs</files>
  <read_first>
    - lib/relyra/ecto/metadata_apply.ex (the WHOLE file — must preserve every existing private helper, every existing public function spec, and the existing transact/2 + normalize_transaction_result/2 + rollback/2 plumbing)
    - lib/relyra/ecto/metadata_source.ex (Plan 01 — confirm `health_state_changeset/2` cast list is exactly the 9 fields used below)
    - lib/relyra/metadata/failure_classifier.ex (Plan 02 — the `classify/1` shape used to decide if `counts_toward_suspend?`)
    - lib/relyra/metadata/backoff.ex (Plan 02 — `backoff_until/2`, `suspend_threshold/0`, `tier_seconds/1`)
    - lib/relyra/metadata/cadence.ex (Plan 02 — `next_refresh_at/2` for the success-path schedule update)
    - .planning/phases/21-scheduled-metadata-refresh/21-CONTEXT.md (D-25 5-failure threshold + soft backoff; D-26 suspension never flips auto_refresh_enabled; D-28 single-transaction discipline; D-32/D-33 stage-only certs + last-known-good preservation must remain intact)
    - .planning/phases/21-scheduled-metadata-refresh/21-PATTERNS.md "lib/relyra/ecto/metadata_apply.ex (EXTENDED — D-28 single-transaction discipline)" section
    - .planning/phases/21-scheduled-metadata-refresh/21-RESEARCH.md "Pitfall 1" + "Pitfall 6" + Pattern 4
  </read_first>
  <action>
    Edit `lib/relyra/ecto/metadata_apply.ex`. Two extensions: (a) `record_attempt/3` is wrapped in `transact/2` and co-commits a `MetadataSource.health_state_changeset/2` write when the trigger is scheduled; (b) `apply_revision/4`'s success branch ALSO co-commits the success-path health-state reset.

    Step 1 — Add new aliases at the top of the module (after `alias Relyra.Ecto.{AuditWriter, ...}`):

    ```elixir
    alias Relyra.Ecto.MetadataSource
    alias Relyra.Metadata.{Backoff, Cadence, FailureClassifier}
    ```

    Step 2 — Replace the body of `record_attempt/3` to wrap in `transact/2` and co-commit health state. The new body:

    ```elixir
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
    ```

    Step 3 — Add the health-state side-update private helpers. PLACE these AFTER the existing `insert_revision/2` (around line 181) and BEFORE `fetch_repo/2` (around line 183):

    ```elixir
    # D-28: Phase 21 health-state co-commit. Only fires when the attempt was
    # part of a scheduled-refresh batch (trigger == :scheduled_refresh or
    # :scheduled_probe). Manual triggers (:manual_refresh / :manual_import)
    # are unaffected — Phase 21 does not change the manual path's behavior.
    defp maybe_update_health_state_on_attempt(repo, %{
           metadata_source_id: source_id,
           outcome: outcome
         } = attrs)
         when is_binary(source_id) do
      if scheduled_trigger?(Map.get(attrs, :trigger)) do
        do_update_health_state_on_attempt(repo, source_id, outcome, attrs)
      else
        :ok
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

      base = %{last_failure_error_code: Atom.to_string(error_code)}

      cond do
        classification.counts_toward_suspend? ->
          new_count = (source.consecutive_failure_count || 0) + 1
          first_failure_at = source.first_failure_at || now

          base
          |> Map.put(:consecutive_failure_count, new_count)
          |> Map.put(:first_failure_at, first_failure_at)
          |> maybe_put_suspend(new_count, attrs, now)

        true ->
          # Suspicious failure: mark the failure code but do NOT advance the
          # counter or schedule a backoff (D-27 — these need human eyes).
          base
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
      Map.get(attrs, :auto_suspended_reason, "transient_failures_exceeded")
    end

    defp error_code_from_attrs(attrs) do
      cond do
        is_atom(Map.get(attrs, :error_code)) ->
          Map.get(attrs, :error_code)

        is_binary(Map.get(attrs, :error_code)) ->
          String.to_atom(Map.get(attrs, :error_code))

        is_map(Map.get(attrs, :details)) and is_atom(Map.get(attrs.details, :error_code)) ->
          Map.get(attrs.details, :error_code)

        is_map(Map.get(attrs, :details)) and is_binary(Map.get(attrs.details, :error_code)) ->
          String.to_atom(Map.fetch!(attrs.details, :error_code))

        true ->
          :unknown
      end
    end

    defp apply_health_changeset(repo, %MetadataSource{} = source, attrs) when map_size(attrs) > 0 do
      case source |> MetadataSource.health_state_changeset(attrs) |> repo.update() do
        {:ok, _updated} ->
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
    ```

    Step 4 — In `apply_revision/4`'s success branch (around line 26-43), the `:applied` outcome MUST also reset the health state per Pitfall 6. After `apply_candidate/4` succeeds and `append_metadata_audit/6` succeeds, BUT BEFORE the final `{:ok, applied_revision}`, call a new `maybe_reset_health_state_on_apply/3`:

    Replace the existing `:applied` branch:
    ```elixir
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
    ```

    With:
    ```elixir
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
    ```

    Then add the success-path helper. PLACE it next to `maybe_update_health_state_on_attempt/2`:

    ```elixir
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
                  )
              }

              apply_health_changeset(repo, source, health_attrs)
          end
      end
    end

    defp union_known_certs(existing, fresh) when is_list(existing) and is_list(fresh) do
      MapSet.new(existing) |> MapSet.union(MapSet.new(fresh)) |> MapSet.to_list()
    end
    ```

    Step 4.5 — Emit D-24 state-transition telemetry events from inside `apply_health_changeset/3` (B1 fix). The events fire on the SAME transaction commit as the audit row + health-state write, so a downstream observer sees the audit row and the telemetry event together. Add the following helper invocations:

    Modify `apply_health_changeset/3` to ALSO compute and emit the appropriate state-transition event AFTER the `repo.update` succeeds, BEFORE returning `:ok`. The detection logic compares the BEFORE source (`source` parameter) against the AFTER source (the `updated` returned from the changeset apply):

    ```elixir
    defp apply_health_changeset(repo, %MetadataSource{} = source, attrs) when map_size(attrs) > 0 do
      case source |> MetadataSource.health_state_changeset(attrs) |> repo.update() do
        {:ok, updated} ->
          emit_state_transitions(source, updated, attrs)
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
    # Reference call site for "emit-after-commit" pattern: existing
    # AuditWriter audit-row commit. Phase 21 uses emit-inside-transaction
    # because :telemetry.execute is synchronous and side-effect-only — if
    # the surrounding transaction rolls back, the emit already happened
    # but the listener's downstream effects are the host's responsibility
    # (the event payload carries `correlation_id` so the host can dedupe
    # against an audit row that never landed). This matches the existing
    # `Telemetry.span` pattern around `apply_revision/4`.
    defp emit_state_transitions(%MetadataSource{} = before_source, %MetadataSource{} = updated, attrs) do
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
        correlation_id: Map.get(attrs, :correlation_id),
        error_code: source.last_failure_error_code,
        consecutive_failure_count: source.consecutive_failure_count || 0,
        auto_suspended_reason: source.auto_suspended_reason,
        transient?: classification.transient?,
        counts_toward_suspend?: classification.counts_toward_suspend?
      }
    end

    defp classification_for(attrs) do
      attrs
      |> Map.get(:_phase21_classification)
      |> case do
        %{transient?: _} = c -> c
        _ -> %{transient?: false, counts_toward_suspend?: false}
      end
    end
    ```

    To make `_phase21_classification` available to `apply_health_changeset/3`, plumb it from `compute_failure_health_state/3`. Modify the failure-path branch in `compute_failure_health_state/3` to STASH the classification atom into the attrs map under a private key:

    ```elixir
    classification.counts_toward_suspend? ->
      new_count = (source.consecutive_failure_count || 0) + 1
      first_failure_at = source.first_failure_at || now

      base
      |> Map.put(:consecutive_failure_count, new_count)
      |> Map.put(:first_failure_at, first_failure_at)
      |> maybe_put_suspend(new_count, attrs, now)
      |> Map.put(:_phase21_classification, classification)
      |> Map.put(:correlation_id, Map.get(attrs, :correlation_id))
    ```

    AND update `apply_health_changeset/3` to STRIP `:_phase21_classification` and `:correlation_id` from `attrs` before passing to `MetadataSource.health_state_changeset/2` (which only casts the LOCKED 9 health fields — these private keys would not round-trip through Ecto.cast and would silently disappear, but stripping is more explicit):

    ```elixir
    defp apply_health_changeset(repo, %MetadataSource{} = source, attrs) when map_size(attrs) > 0 do
      classification_attrs = Map.take(attrs, [:_phase21_classification, :correlation_id])
      cast_attrs = Map.drop(attrs, [:_phase21_classification, :correlation_id])

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
    ```

    For the SUCCESS path (`maybe_reset_health_state_on_apply/3` — Step 4), the same classification stash applies: when the success-path attrs are built, set `:_phase21_classification` to a stub `%{transient?: false, counts_toward_suspend?: false}` (the recovered event does not have a transient/suspend flag — the existence of the recovery is what matters), and pass `:correlation_id` from `revision_attrs[:audit][:correlation_id]` if present.

    Step 4.6 — Add `MetadataApply.record_validity_warning/3` (B2 fix). The Phase-21 wrapper (Plan 05) calls this when it detects a `validUntil` slack within the warning threshold. The helper does THREE things in ONE `transact/2` block (D-28 single-transaction discipline preserved): (a) check at-most-once-per-validUntil-window via `last_validity_warning_for` comparison, (b) update `last_validity_warning_for` to the new validUntil, (c) emit `[:relyra, :saml, :metadata, :auto_refresh, :validity_warning]`.

    PLACE this AFTER `record_attempt/3` and BEFORE `insert_revision/2`:

    ```elixir
    @doc """
    Records a `:validity_warning` for a metadata source per D-14.

    At-most-once per validUntil window per source: if `source.last_validity_warning_for`
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
    @spec record_validity_warning(module(), Relyra.Ecto.MetadataSource.t(), map()) ::
            {:ok, :emitted | :suppressed} | {:error, Error.t()}
    def record_validity_warning(repo, %MetadataSource{} = source, %{valid_until: %DateTime{} = valid_until} = attrs)
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

    defp already_warned_for?(%MetadataSource{last_validity_warning_for: nil}, _valid_until), do: false

    defp already_warned_for?(%MetadataSource{last_validity_warning_for: %DateTime{} = stored}, %DateTime{} = candidate) do
      # At-most-once semantics per D-14 specifics: warning is suppressed when we
      # already warned for THIS validUntil (or a newer one — IdP shortened the
      # validity window since our last warning, no need to re-fire). Re-fires
      # only when IdP publishes a NEW (later) validUntil.
      DateTime.compare(stored, candidate) in [:eq, :gt]
    end
    ```

        Step 5 — Add tests in `test/relyra/ecto/metadata_apply_test.exs` (extend the existing file; do not overwrite). Add at minimum these scenarios using the existing test repo + fixtures:

    1. `test "manual refresh path is unchanged: trigger: :manual_refresh produces a MetadataRevision row but does NOT mutate MetadataSource health fields"` — proves D-9/Phase-9 manual path is intact.
    2. `test "scheduled refresh failure with transient error_code increments consecutive_failure_count and updates last_failure_error_code"` — record_attempt with `trigger: :scheduled_refresh, outcome: :fetch_failed, details: %{error_code: :fetch_timeout}`; assert source row's `consecutive_failure_count` == 1, `last_failure_error_code` == "fetch_timeout".
    3. `test "scheduled refresh failure with suspicious error_code does NOT increment counter (D-27)"` — same setup but `details: %{error_code: :signature_failed}`; assert `consecutive_failure_count` == 0, `last_failure_error_code` == "signature_failed".
    4. `test "5 consecutive transient failures sets auto_suspended_until and auto_suspended_reason"` — call record_attempt 5x with `:fetch_timeout`; assert `auto_suspended_until` is in the future (1h ± 10%), `auto_suspended_reason` == "transient_failures_exceeded".
    5. `test "explicit auto_suspended_reason in attrs overrides the default (drift / corpus / signature paths set their own)"` — call record_attempt 5x with `:fetch_timeout, auto_suspended_reason: "entity_id_drift"` in attrs; assert `auto_suspended_reason` == "entity_id_drift".
    6. `test "successful scheduled apply resets every health field and advances next_refresh_at (Pitfall 6)"` — set up a source with `consecutive_failure_count: 5, auto_suspended_until: <future>`; call apply_revision with `trigger: :scheduled_refresh`; assert `consecutive_failure_count` == 0, `auto_suspended_until` == nil, `last_success_at` set, `next_refresh_at` set ~24h ahead (default :daily).
    7. `test "successful scheduled apply unions candidate fingerprints into last_known_metadata_signing_certs"` — start with `last_known_metadata_signing_certs: ["aaa"]`; apply with candidate carrying `certificate_fingerprints: ["bbb"]`; assert source row's `last_known_metadata_signing_certs` == `["aaa", "bbb"]` (order-insensitive — use sort or MapSet compare).
    8. `test "single-transaction guarantee: a health_state_changeset failure rolls back the MetadataRevision insert"` — inject an invalid health-state field via a custom `attrs` map and assert NO `MetadataRevision` row is left behind.
    9. `test "manual import path (trigger: :manual_import) does not touch health state"` — proves the manual XML import path remains unchanged.
    10. `test "B1: :degraded telemetry event fires on the first transient failure (consecutive_failure_count 0 -> 1)"` — attach a telemetry handler to `[:relyra, :saml, :metadata, :auto_refresh, :degraded]` BEFORE calling record_attempt with a transient error_code; assert exactly ONE event captured with metadata containing `:source_id`, `:connection_record_id` (when accessible), `:correlation_id`, `:error_code` (= "fetch_timeout"), `:consecutive_failure_count` (= 1), `:transient?` (= true), `:counts_toward_suspend?` (= true).
    11. `test "B1: :degraded does NOT re-fire on the 2nd, 3rd, 4th consecutive transient failure"` — same handler; call record_attempt 4x with transient codes; assert exactly ONE :degraded event total.
    12. `test "B1: :suspended telemetry event fires on the 5th consecutive transient failure (auto_suspended_until set from nil)"` — attach handler for `[:relyra, :saml, :metadata, :auto_refresh, :suspended]`; call record_attempt 5x with transient codes; assert exactly ONE :suspended event captured with metadata containing `:auto_suspended_reason` (= "transient_failures_exceeded"), `:consecutive_failure_count` (= 5).
    13. `test "B1: :recovered telemetry event fires on a successful apply against a previously-suspended source"` — set up a source with `auto_suspended_until: <future>`; attach handler for `[:relyra, :saml, :metadata, :auto_refresh, :recovered]`; call apply_revision with `trigger: :scheduled_refresh`; assert exactly ONE :recovered event captured with metadata `:auto_suspended_reason` (= nil after clear), `:consecutive_failure_count` (= 0).
    14. `test "B1: telemetry events carry the correlation_id from revision_attrs[:audit][:correlation_id] when present"` — pass `audit: %{correlation_id: "uuid-xyz"}` in opts; assert the emitted event metadata's `:correlation_id` equals `"uuid-xyz"`.
    15. `test "B1: no state-transition events fire when the manual path is exercised"` — call record_attempt with `trigger: :manual_refresh` and a transient error; assert NO :degraded / :suspended / :recovered events captured (manual path does not own the auto-refresh state machine).
    16. `test "B2: record_validity_warning/3 emits :validity_warning when slack is negative AND last_validity_warning_for is nil"` — set up a source with `last_validity_warning_for: nil`; attach handler for `[:relyra, :saml, :metadata, :auto_refresh, :validity_warning]`; call `MetadataApply.record_validity_warning(repo, source, %{valid_until: ~U[2026-06-01 00:00:00Z], refresh_interval_seconds: 86_400, correlation_id: "uuid", slack_seconds: -1_000})`; assert `{:ok, :emitted}` returned, exactly ONE event captured with the documented payload (`:source_id`, `:correlation_id`, `:valid_until`, `:refresh_interval_seconds`, `:slack_seconds`); assert source row's `last_validity_warning_for` was updated to the candidate `valid_until`.
    17. `test "B2: record_validity_warning/3 SUPPRESSES re-fire when last_validity_warning_for >= candidate valid_until (at-most-once per validUntil per source)"` — set up source with `last_validity_warning_for: ~U[2026-06-01 00:00:00Z]`; call with same `valid_until`; assert `{:ok, :suppressed}` returned, NO event emitted, source row unchanged.
    18. `test "B2: record_validity_warning/3 RE-FIRES when IdP publishes a NEW (later) validUntil"` — set up source with `last_validity_warning_for: ~U[2026-06-01 00:00:00Z]`; call with `valid_until: ~U[2026-07-01 00:00:00Z]`; assert `{:ok, :emitted}`, ONE event captured, source row updated to the newer `valid_until`.
  </action>
  <verify>
    <automated>mix test test/relyra/ecto/metadata_apply_test.exs --warnings-as-errors</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "alias Relyra.Metadata.{Backoff, Cadence, FailureClassifier}" lib/relyra/ecto/metadata_apply.ex` returns at least `1`.
    - `grep -c "alias Relyra.Ecto.MetadataSource" lib/relyra/ecto/metadata_apply.ex` returns at least `1` (new alias added).
    - `grep -c "transact(repo, fn ->" lib/relyra/ecto/metadata_apply.ex` returns at least `2` (record_attempt now wrapped + apply_revision unchanged).
    - `grep -c "def maybe_update_health_state_on_attempt\\|defp maybe_update_health_state_on_attempt" lib/relyra/ecto/metadata_apply.ex` returns at least `1`.
    - `grep -c "def maybe_reset_health_state_on_apply\\|defp maybe_reset_health_state_on_apply" lib/relyra/ecto/metadata_apply.ex` returns at least `1`.
    - `grep -c "scheduled_trigger?(:scheduled_refresh)" lib/relyra/ecto/metadata_apply.ex` returns at least `1`.
    - `grep -c "scheduled_trigger?(:scheduled_probe)" lib/relyra/ecto/metadata_apply.ex` returns at least `1`.
    - `grep -c "FailureClassifier.classify" lib/relyra/ecto/metadata_apply.ex` returns at least `1`.
    - `grep -c "Backoff.backoff_until" lib/relyra/ecto/metadata_apply.ex` returns at least `1`.
    - `grep -c "Cadence.next_refresh_at" lib/relyra/ecto/metadata_apply.ex` returns at least `1`.
    - `grep -c "MetadataSource.health_state_changeset" lib/relyra/ecto/metadata_apply.ex` returns at least `1`.
    - `grep -c "AuditWriter.append_event" lib/relyra/ecto/metadata_apply.ex` returns exactly `1` AT THIS POINT (D-35 single audit-writer seam — no NEW append_event call sites in Task 1; Task 3 adds the second site for resume_auto_refresh/3 inside a transact block).
    - `mix test test/relyra/ecto/metadata_apply_test.exs --warnings-as-errors` exits 0 with at least 18 new tests passing (9 from Step 5 + 6 from Step 4.5 B1 telemetry coverage + 3 from Step 4.6 B2 record_validity_warning coverage) AND every previously-passing test still passing (manual paths intact).
    - `grep -c "def record_validity_warning" lib/relyra/ecto/metadata_apply.ex` returns at least `1` (B2 — D-14 emit seam exists).
    - `grep -c ":relyra, :saml, :metadata, :auto_refresh, :validity_warning" lib/relyra/ecto/metadata_apply.ex` returns at least `1` (B2 — :validity_warning emitted from this module).
    - `grep -c "already_warned_for?" lib/relyra/ecto/metadata_apply.ex` returns at least `1` (B2 — at-most-once predicate).
    - `grep -c "def emit_state_transitions\|defp emit_state_transitions" lib/relyra/ecto/metadata_apply.ex` returns at least `1` (B1 D-24 emit helper exists).
    - `grep -c ":relyra, :saml, :metadata, :auto_refresh, :degraded" lib/relyra/ecto/metadata_apply.ex` returns at least `1` (B1 — :degraded event emitted).
    - `grep -c ":relyra, :saml, :metadata, :auto_refresh, :suspended" lib/relyra/ecto/metadata_apply.ex` returns at least `1` (B1 — :suspended event emitted).
    - `grep -c ":relyra, :saml, :metadata, :auto_refresh, :recovered" lib/relyra/ecto/metadata_apply.ex` returns at least `1` (B1 — :recovered event emitted).
    - `grep -c "transient?:\|counts_toward_suspend?:" lib/relyra/ecto/metadata_apply.ex` returns at least `2` (telemetry payload carries the flags Plan 07 catalog promises).
    - `mix compile --no-optional-deps --warnings-as-errors` exits 0.
  </acceptance_criteria>
  <done>`record_attempt/3` is wrapped in `transact/2`. Health-state side-effect runs ONLY when `trigger ∈ {:scheduled_refresh, :scheduled_probe}` AND `metadata_source_id` is present. Failure path uses `FailureClassifier.classify/1` to decide whether to count + suspend. Success path resets every counter, advances `next_refresh_at`, and unions cert fingerprints. Manual paths are untouched. Single audit-writer seam invariant (D-35) is preserved — no new `AuditWriter.append_event` call site introduced. **B1: D-24 state-transition telemetry events (`:degraded`, `:suspended`, `:recovered`) fire INSIDE the same transact block as the health-state write, with the LOCKED payload shape Plan 07 catalogs (`correlation_id`, `source_id`, `connection_record_id`, `error_code`, `consecutive_failure_count`, `auto_suspended_reason`, `transient?`, `counts_toward_suspend?`). B2: `record_validity_warning/3` exists as the at-most-once-per-validUntil seam — co-commits `last_validity_warning_for` update + `:validity_warning` event in ONE transact block; suppresses re-fire when stored window >= candidate window per D-14 specifics.**</done>
</task>

<task type="auto">
  <name>Task 2: Add Relyra.Security.Signature.verify_metadata_root/4 shim and signature test coverage</name>
  <files>lib/relyra/security/signature.ex, test/relyra/security/signature_test.exs</files>
  <read_first>
    - lib/relyra/security/signature.ex (whole file — preserve verify/4 verbatim; the new shim only delegates to do_verify/4 with a different telemetry flow tag)
    - .planning/phases/21-scheduled-metadata-refresh/21-CONTEXT.md (D-16: XMLDSig verification on metadata root before parse-deeply; reuse existing primitive)
    - .planning/phases/21-scheduled-metadata-refresh/21-RESEARCH.md "lib/relyra/security/signature.ex (EXTENDED for metadata root)" + "Pitfall 4"
    - .planning/phases/21-scheduled-metadata-refresh/21-PATTERNS.md "lib/relyra/security/signature.ex (EXTENDED for metadata root)" section
    - test/relyra/security/signature_test.exs (extend; do not overwrite)
  </read_first>
  <action>
    Edit `lib/relyra/security/signature.ex`. Add a new public function `verify_metadata_root/4` AFTER the existing `verify/4` and BEFORE `defp do_verify(...)`. The shim has the SAME spec shape as `verify/4`, calls the SAME `do_verify/4` private helper with the SAME arguments, and ONLY differs in the telemetry metadata's `:flow` tag — `:metadata_refresh` instead of `:sp_initiated`. This is RESEARCH option (2) from the PATTERNS section: "thin shim that swaps `flow: :sp_initiated` for `flow: :metadata_refresh` in the telemetry metadata and otherwise calls `do_verify/4` verbatim."

    ```elixir
    @doc """
    Verifies the XMLDSig signature on a SAML metadata root (`<EntityDescriptor>`
    or `<EntitiesDescriptor>`) using the SAME `do_verify/4` trust primitive
    `verify/4` uses. The only difference is the telemetry payload's `:flow`
    tag (`:metadata_refresh` instead of `:sp_initiated`) so adopters can
    attach distinct handlers to the unattended metadata-refresh channel.

    Phase 21 contract per D-16: this MUST be called BEFORE the candidate is
    parsed deeply (no `Parser.parse` invocation between fetch and this call
    on the scheduled path). The caller (Phase 21 wrapper) builds a
    metadata-root-shaped `parsed_doc` map exposing the `:signed_candidates`
    rooted at the EntityDescriptor / EntitiesDescriptor envelope.

    `cert_chain` MUST be the operator-pinned PEM list resolved from
    `MetadataSource.metadata_trust_fingerprints` per D-17 — NEVER the IdP's
    assertion certs.
    """
    @spec verify_metadata_root(map(), map(), [binary()], keyword()) ::
            {:ok, SignedNode.t()} | {:error, Error.t()}
    def verify_metadata_root(parsed_doc, connection, cert_chain, opts \\ [])

    def verify_metadata_root(parsed_doc, connection, cert_chain, opts)
        when is_map(parsed_doc) and is_map(connection) and is_list(cert_chain) and is_list(opts) do
      metadata = %{
        connection_id: Map.get(connection, :connection_id) || Map.get(connection, :id),
        flow: :metadata_refresh
      }

      Relyra.Telemetry.span([:signature, :verify], metadata, fn ->
        result = do_verify(parsed_doc, connection, cert_chain, opts)

        case result do
          {:ok, signed_node} ->
            {{:ok, signed_node},
             Map.merge(metadata, %{
               outcome: :ok,
               signature_algorithm: signed_node.signature_method,
               digest_algorithm: signed_node.digest_method
             })}

          {:error, %Error{} = error} ->
            {{:error, error}, Map.merge(metadata, %{outcome: :error, error_code: error.type})}
        end
      end)
    end

    def verify_metadata_root(_parsed_doc, connection, _cert_chain, _opts) do
      details = connection_details(connection)

      {:error,
       Error.new(
         :invalid_signature,
         "Metadata-root signature verification inputs are invalid",
         Map.put(details, :reason, :invalid_signature_input)
       )}
    end
    ```

    DO NOT change `verify/4`. DO NOT change `do_verify/4`. DO NOT add a new private helper — `verify_metadata_root/4` reuses `do_verify/4` verbatim. DO NOT change the rejection-of-document-KeyInfo posture (lines 56-62 — those rejections apply to BOTH `verify/4` and `verify_metadata_root/4` because both call `do_verify/4`).

    Step 2 — Extend `test/relyra/security/signature_test.exs` (do not overwrite — the existing test file gates the assertion-signature path; add metadata-root-path tests). Add at minimum these scenarios:

    1. `test "verify_metadata_root/4 rejects when cert_chain is empty (D-17 — no pinned fingerprints == reject)"` — assert `{:error, %Error{type: :untrusted_certificate}}`.
    2. `test "verify_metadata_root/4 rejects document-provided KeyInfo (mirrors verify/4 behavior at lines 56-62)"` — pass `parsed_doc` with `key_info_trust: true`; assert `{:error, %Error{type: :untrusted_certificate, details: %{reason: :document_keyinfo_forbidden}}}`.
    3. `test "verify_metadata_root/4 rejects duplicate XML IDs"` — pass `parsed_doc` with `duplicate_ids: ["foo", "bar"]`; assert `{:error, %Error{type: :duplicate_xml_id}}`.
    4. `test "verify_metadata_root/4 emits telemetry under [:relyra, :saml, :signature, :verify, ...] with flow: :metadata_refresh"` — attach a telemetry handler that captures the start event metadata, invoke verify_metadata_root with a minimal benign parsed_doc, assert the captured `metadata.flow == :metadata_refresh`.
    5. `test "verify/4 telemetry still emits flow: :sp_initiated (no regression)"` — same harness; invoke `verify/4` and assert `metadata.flow == :sp_initiated`.

    Use ExUnit's `setup` block + `:telemetry.attach/4` + `on_exit(fn -> :telemetry.detach(handler_id) end)` for the telemetry-capture tests. Pattern: send the metadata to `self()` from the handler, then `assert_receive {:telemetry, ...}`.
  </action>
  <verify>
    <automated>mix test test/relyra/security/signature_test.exs --warnings-as-errors</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "def verify_metadata_root" lib/relyra/security/signature.ex` returns at least `1`.
    - `grep -c "flow: :metadata_refresh" lib/relyra/security/signature.ex` returns at least `1`.
    - `grep -c "flow: :sp_initiated" lib/relyra/security/signature.ex` returns at least `1` (existing path preserved).
    - `grep -c "do_verify(parsed_doc, connection, cert_chain, opts)" lib/relyra/security/signature.ex` returns at least `2` (verify/4 + verify_metadata_root/4 both call the same private helper).
    - `grep -c "key_info_trust" lib/relyra/security/signature.ex` returns `1` (the existing rejection — Phase 21 did not duplicate it).
    - `grep -c "def verify(" lib/relyra/security/signature.ex` returns at least `2` (existing 2-clause definition unchanged).
    - `mix test test/relyra/security/signature_test.exs --warnings-as-errors` exits 0 with the 5 new metadata-root tests passing AND all pre-existing assertion-path tests still passing.
    - `mix compile --no-optional-deps --warnings-as-errors` exits 0.
  </acceptance_criteria>
  <done>`verify_metadata_root/4` exists, reuses `do_verify/4` verbatim, differs only in the `:flow` tag, and has dedicated telemetry-capture tests proving the namespace is `[:relyra, :saml, :signature, :verify]` with `flow: :metadata_refresh`. The original `verify/4` continues to emit `flow: :sp_initiated` (no regression). Document-KeyInfo rejection, empty-cert-chain rejection, and duplicate-XML-ID rejection ALL apply to the new path because they live in the shared `do_verify/4`.</done>
</task>


<task type="auto">
  <name>Task 3: Add MetadataApply.resume_auto_refresh/3 (single-transaction Resume-now seam — D-28)</name>
  <files>lib/relyra/ecto/metadata_apply.ex, test/relyra/ecto/metadata_apply_test.exs</files>
  <read_first>
    - lib/relyra/ecto/metadata_apply.ex (the file extended in Task 1 — preserve everything; this task ADDS one new public function + ONE new test scenario)
    - lib/relyra/ecto/metadata_source.ex (Plan 01 — confirm `health_state_changeset/2` casts `auto_suspended_until` and `auto_suspended_reason`)
    - lib/relyra/ecto/audit_writer.ex (the single audit-writer seam — `append_event/3` shape)
    - .planning/phases/21-scheduled-metadata-refresh/21-CONTEXT.md (D-28 single-transaction discipline; D-35 single audit-writer seam; A3 cause string `"live_admin_auto_refresh_resume"`)
    - Plan 06 Task 2 (consumer — confirms the call shape `MetadataApply.resume_auto_refresh(repo, source, %{actor: operator_actor})` and that the LiveView NO LONGER does its own suspend-clear)
  </read_first>
  <action>
    Add a new public function `resume_auto_refresh/3` to `lib/relyra/ecto/metadata_apply.ex`. PLACE it AFTER the existing `record_attempt/3` definition (around line 80 post-Task-1 expansion) and BEFORE the private `insert_revision/2`. The function MUST co-commit (in ONE `transact/2` block):

    1. The audit row (via `AuditWriter.append_event/3`) with `cause: "live_admin_auto_refresh_resume"` per A3.
    2. The suspend-clear health-state update (via `MetadataSource.health_state_changeset/2` with `auto_suspended_until: nil, auto_suspended_reason: nil`).

    The result-tuple discipline applies: returns `{:ok, %{audit_event: ..., source: %MetadataSource{}}}` on success or `{:error, %Relyra.Error{}}` on failure (Postgres rolls back BOTH writes if EITHER step errors — D-28 single-transaction invariant enforced by `transact`).

    Implementation:

    ```elixir
    @doc """
    Resume the auto-refresh schedule for a previously-auto-suspended source
    per D-28: clears `auto_suspended_until` and `auto_suspended_reason` AND
    writes the operator-intent audit row inside ONE transaction. Called by
    Plan 06's "Resume now" LiveView button.

    The LiveView MUST NOT perform a parallel `repo.update` to clear the
    suspend — doing so would re-introduce the audit/state divergence Phase
    21 is designed to prevent. This function is the single seam.

    `opts` MUST include:
      - `:actor` — the operator identity for the audit row
    `opts` MAY include:
      - `:cause` — overrides the default `"live_admin_auto_refresh_resume"`
        (rarely needed; mostly for testing)
    """
    @spec resume_auto_refresh(module(), Relyra.Ecto.MetadataSource.t(), map()) ::
            {:ok, %{audit_event: term(), source: Relyra.Ecto.MetadataSource.t()}}
            | {:error, Error.t()}
    def resume_auto_refresh(repo, %MetadataSource{} = source, %{} = opts)
        when is_atom(repo) do
      with :ok <- ensure_optional_dependency!(:resume_auto_refresh, repo),
           {:ok, connection} <- fetch_connection(repo, source.connection_record_id, :resume_auto_refresh) do
        actor = Map.get(opts, :actor) || "operator"
        cause = Map.get(opts, :cause, "live_admin_auto_refresh_resume")

        transact(repo, fn ->
          # Step 1: clear the suspend state via the SAME health_state_changeset
          # path that record_attempt/3 uses; co-committed in this transaction.
          health_attrs = %{auto_suspended_until: nil, auto_suspended_reason: nil}

          case apply_health_changeset(repo, source, health_attrs) do
            :ok ->
              {:ok, updated_source} = {:ok, repo.get(MetadataSource, source.id)}

              # Step 2: append the operator-intent audit row via the single
              # audit-writer seam (D-35). The audit context carries the actor
              # and the locked cause string per A3.
              audit_context = %{
                actor: actor,
                cause: cause,
                connection_id: connection.connection_id,
                metadata_source_id: source.id,
                trigger: :scheduled_probe
              }

              case AuditWriter.append_event(repo, :metadata_auto_refresh_resume, audit_context) do
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
        |> normalize_transaction_result(:resume_auto_refresh)
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
    ```

    NOTE on `AuditWriter.append_event/3` shape: confirm the existing audit-writer's argument shape against `lib/relyra/ecto/audit_writer.ex`. If `append_event/3` requires a different shape (e.g., `(repo, event_type, context_map)` vs `(repo, connection, audit_context)`), adapt the call to the existing convention WITHOUT introducing a second writer. The constraint is single-call-site-per-transaction, NOT a literal argument shape.

    DO NOT add a NEW audit-writer call site outside this function (D-35). The grep invariant from Task 1 (`grep -c "AuditWriter.append_event" lib/relyra/ecto/metadata_apply.ex` returns exactly `1`) MUST be UPDATED to expect exactly `2` after this task: one in `apply_revision/4` and one in `resume_auto_refresh/3` — both inside `transact/2` blocks, neither outside.

    Add ONE test in `test/relyra/ecto/metadata_apply_test.exs`:

    `test "resume_auto_refresh/3 co-commits audit row + suspend-clear in ONE transaction (D-28)"`:
    1. Set up a `MetadataSource` with `auto_suspended_until: <future>, auto_suspended_reason: :transient_failures_exceeded`.
    2. Call `MetadataApply.resume_auto_refresh(repo, source, %{actor: "operator-test"})`.
    3. Assert `{:ok, %{audit_event: _, source: updated}}` is returned.
    4. Assert `updated.auto_suspended_until == nil` AND `updated.auto_suspended_reason == nil`.
    5. Query the audit ledger (via the existing audit-event reader) and assert exactly ONE event was appended with `cause == "live_admin_auto_refresh_resume"` and `actor == "operator-test"`.
    6. Optional: a negative test injecting a changeset failure to assert NEITHER write persists (rollback proof) — use a malformed audit context that the AuditWriter rejects.
  </action>
  <verify>
    <automated>mix test test/relyra/ecto/metadata_apply_test.exs --warnings-as-errors</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "def resume_auto_refresh" lib/relyra/ecto/metadata_apply.ex` returns at least `1`.
    - `grep -c "live_admin_auto_refresh_resume" lib/relyra/ecto/metadata_apply.ex` returns at least `1` (default cause string per A3).
    - `grep -c "AuditWriter.append_event" lib/relyra/ecto/metadata_apply.ex` returns exactly `2` (one in apply_revision/4, one in resume_auto_refresh/3 — D-35 single audit-writer seam preserved; both inside transact blocks).
    - `grep -c "transact(repo, fn ->" lib/relyra/ecto/metadata_apply.ex` returns at least `3` (record_attempt/3 + apply_revision/4 + resume_auto_refresh/3).
    - `grep -c "auto_suspended_until: nil" lib/relyra/ecto/metadata_apply.ex` returns at least `1` (resume clears the suspend).
    - `grep -c "auto_suspended_reason: nil" lib/relyra/ecto/metadata_apply.ex` returns at least `1`.
    - `mix test test/relyra/ecto/metadata_apply_test.exs --warnings-as-errors` exits 0 with the new resume test passing.
    - `mix compile --no-optional-deps --warnings-as-errors` exits 0.
  </acceptance_criteria>
  <done>`MetadataApply.resume_auto_refresh/3` exists; co-commits audit row (`cause: "live_admin_auto_refresh_resume"`) + suspend-clear in ONE `transact/2` block. The single audit-writer seam invariant (D-35) is preserved — exactly two `AuditWriter.append_event` call sites in the file, both inside transactions. Plan 06 Task 2 (revised) consumes this function instead of doing parallel writes.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| `record_attempt/3` revision_attrs → `MetadataSource.health_state_changeset/2` | Untrusted-but-allowlisted attrs from the wrapper cross into the health-state cast; the changeset is the allowlist (only the documented 9 fields can be cast). |
| Scheduled-refresh outcome → `FailureClassifier.classify/1` | The classifier's flags decide whether a failure increments the counter; a misclassification flips the asymmetric-strictness contract. |
| `apply_revision/4` success branch → health-state RESET | Pitfall 6: if the reset path is missed, a recovered source stays at `consecutive_failure_count: 5` forever and never re-emits. |
| `verify_metadata_root/4` parsed_doc → `do_verify/4` | The metadata-root signature is verified via the same trust primitive as assertion signatures; bypassing this would let unsigned metadata flow into the apply path. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-21-17 | Tampering | `record_attempt/3` transaction | mitigate | Wrapped in `transact/2`; if `apply_health_changeset/3` rejects (e.g., changeset error), `rollback/2` undoes the `MetadataRevision` insert. The audit ledger never disagrees with the source row (D-28 invariant enforced by Postgres transaction semantics). |
| T-21-18 | Repudiation | suspicious-failure path | mitigate | Suspicious failures (`:signature_failed`, `:parse_failed`, etc.) DO update `last_failure_error_code` so the operator can see what happened, even though they do NOT count toward the suspend counter (D-27 — suspicious failures need human eyes, not silent backoff). |
| T-21-19 | Tampering | `apply_revision/4` success-path reset | mitigate | The reset is gated on `scheduled_trigger?/1` so manual-import success paths do NOT reset auto-refresh state (which would mask a real auto-refresh-suspend that happened to coincide with a manual import). |
| T-21-20 | Information Disclosure | `verify_metadata_root/4` telemetry payload | accept | Telemetry payload includes `connection_id`, `signature_algorithm`, `digest_algorithm`, `outcome`, `error_code` — same shape as the existing assertion-signature path. No new sensitive fields exposed. |
| T-21-21 | Tampering | document-`KeyInfo` trust source | mitigate | Both `verify/4` and `verify_metadata_root/4` call the same `do_verify/4` which rejects `parsed_doc.key_info_trust == true` (lines 56-62) — Phase 21 inherits the ruby-saml CVE-2024-45409 protection without duplication. |
| T-21-22 | Spoofing | `cert_chain` argument to `verify_metadata_root/4` | mitigate (caller responsibility) | The shim documents (and the AutoRefresh wrapper in Plan 05 enforces) that `cert_chain` MUST be the PEMs derived from operator-pinned `metadata_trust_fingerprints`, NOT the IdP assertion certs (D-17 reject-reuse). The shim itself does not have the connection-specific knowledge to enforce this — it's a caller contract that Plan 05 implements. |
| T-21-23 | Denial of Service | `compute_failure_health_state/3` for unknown error codes | mitigate | `error_code_from_attrs/1` returns `:unknown` for missing codes; `FailureClassifier.classify(:unknown)` falls through to the default suspicious clause (alert + don't count) per Plan 02 — there is no path that silently increments the counter on an unrecognized failure. |
</threat_model>

<verification>
- `mix test test/relyra/ecto/metadata_apply_test.exs test/relyra/security/signature_test.exs --warnings-as-errors` is green.
- `mix test --warnings-as-errors --exclude pending` is green (full suite — proves no regression in manual import / certificate / audit paths).
- `mix compile --warnings-as-errors` is green.
- `mix compile --no-optional-deps --warnings-as-errors` is green.
- `mix format --check-formatted` is green.
</verification>

<success_criteria>
- `MetadataApply.record_attempt/3` is wrapped in `transact/2`. Health-state co-commit fires ONLY for `trigger ∈ {:scheduled_refresh, :scheduled_probe}` (D-28 single-transaction discipline; manual paths untouched).
- `MetadataApply.apply_revision/4`'s success branch resets the full health-state on scheduled apply (Pitfall 6: half-open probe must close the circuit).
- Failure path uses `FailureClassifier.classify/1` to decide whether to count toward suspend; transient errors increment the counter and (at threshold 5) call `Backoff.backoff_until/2`; suspicious errors update `last_failure_error_code` only (D-27).
- Successful scheduled apply unions candidate fingerprints into `last_known_metadata_signing_certs` so subsequent drift detection compares against the freshly-known set.
- `Relyra.Security.Signature.verify_metadata_root/4` exists, reuses `do_verify/4`, emits telemetry with `flow: :metadata_refresh`, and inherits all of `verify/4`'s rejections (empty cert chain, document-`KeyInfo`, duplicate XML IDs).
- The single audit-writer seam invariant (D-35) is preserved — no new `AuditWriter.append_event` call site is introduced.
</success_criteria>

<output>
After completion, create `.planning/phases/21-scheduled-metadata-refresh/21-04-SUMMARY.md` summarizing: line counts of MetadataApply additions, the gate predicate (`scheduled_trigger?/1`), the new test count, and the verify_metadata_root/4 spec.
</output>