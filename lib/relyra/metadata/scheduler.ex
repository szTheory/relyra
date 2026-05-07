if Code.ensure_loaded?(Ecto.Query) do
  defmodule Relyra.Metadata.Scheduler do
    @moduledoc """
    Phase 21 scheduled metadata refresh entry point per D-01.

    `run_due/2` is the canonical pure-function entry point any host
    scheduler can drive (Oban Cron, Quantum, k8s `CronJob`, fly.io
    scheduled machines, plain `mix relyra.refresh_due`). The function:

      1. Generates one `correlation_id` for the batch (D-39).
      2. Queries the partial index (`relyra_metadata_sources_due_idx`)
         for sources whose `next_refresh_at` is in the past AND
         `auto_refresh_enabled = true` AND not currently suspended (D-12).
         The runtime query keeps the suspension/time filter at query
         time (Plan 01 deviation — Postgres rejects STABLE functions in
         partial-index predicates).
      3. If no due rows: emits
         `[:relyra, :saml, :metadata, :auto_refresh, :skipped]` per D-07
         and returns `{:ok, %{}}`.
      4. Otherwise: loops sequentially per Phase 20 BulkActions pattern
         (D-38), invoking `Relyra.Metadata.AutoRefresh.refresh/2` per
         source. The same `correlation_id` flows through every
         per-source `MetadataRevision` + `AuditWriter.append_event`
         co-commit.

    D-04: there is NO supervised auto-starting ticker. This module is
    dormant until something invokes `run_due/2`.
    """

    import Ecto.Query, only: [from: 2]

    alias Relyra.Ecto.MetadataSource
    alias Relyra.Error
    alias Relyra.Metadata.AutoRefresh

    @doc """
    Runs scheduled metadata refresh for every due source.

    `opts`:
      - `:audit` — map; if `:correlation_id` is missing, one is generated.
      - `:source_ids` — optional list of source IDs to scope this tick
        to a specific subset (used by the LiveView "Resume now" probe in
        Plan 06; bypasses the due-rows query).
      - any opts forwarded to `AutoRefresh.refresh/2` (`:req`, etc.).

    Returns `{:ok, %{source_id => result}}` where each result is
    `{:ok, %MetadataRevision{}}` or `{:error, %Relyra.Error{}}`.
    """
    @spec run_due(module(), keyword()) ::
            {:ok, %{optional(binary()) => term()}} | {:error, Error.t()}
    def run_due(repo, opts \\ []) when is_atom(repo) and is_list(opts) do
      audit = Keyword.get(opts, :audit, %{})
      correlation_id = Map.get(audit, :correlation_id) || Ecto.UUID.generate()

      opts =
        opts
        |> Keyword.put(:audit, Map.put(audit, :correlation_id, correlation_id))
        |> Keyword.put(:repo, repo)

      sources = fetch_sources(repo, Keyword.get(opts, :source_ids), DateTime.utc_now())

      case sources do
        [] ->
          emit_skipped(correlation_id)
          {:ok, %{}}

        sources ->
          # D-38: sequential per-source loop (Phase 20 BulkActions shape)
          # to avoid stampeding the database — and so the same
          # correlation_id flows through every per-source revision/audit
          # co-commit.
          results =
            sources
            |> Enum.map(fn source ->
              {source.id, AutoRefresh.refresh(source, opts)}
            end)
            |> Map.new()

          {:ok, results}
      end
    end

    # When :source_ids is provided, bypass the due-rows query — used by
    # the LiveView "Resume now" probe in Plan 06 (the operator already
    # cleared auto_suspended_until via the audit row; this is the
    # half-open probe).
    defp fetch_sources(repo, source_ids, _now) when is_list(source_ids) do
      repo.all(
        from(src in MetadataSource,
          where: src.id in ^source_ids,
          select: src
        )
      )
    end

    defp fetch_sources(repo, nil, now) do
      repo.all(due_query(now))
    end

    # The query MUST match the partial index's WHERE clause (Plan 01
    # ships the index as `WHERE auto_refresh_enabled = true`). The
    # suspension/time filter is applied at query time per Plan 01's
    # IMMUTABLE-only partial-index decision (Postgres rejects STABLE
    # `now()` in CREATE INDEX WHERE) — the Postgres planner still picks
    # the partial index because `auto_refresh_enabled = true` is the
    # gating predicate.
    defp due_query(now) do
      from(src in MetadataSource,
        where: src.auto_refresh_enabled == true,
        where: is_nil(src.auto_suspended_until) or src.auto_suspended_until <= ^now,
        where: is_nil(src.next_refresh_at) or src.next_refresh_at <= ^now,
        order_by: [asc: src.next_refresh_at],
        select: src
      )
    end

    defp emit_skipped(correlation_id) do
      :telemetry.execute(
        [:relyra, :saml, :metadata, :auto_refresh, :skipped],
        %{},
        %{correlation_id: correlation_id, count: 0}
      )

      :ok
    end
  end
else
  defmodule Relyra.Metadata.Scheduler do
    @moduledoc """
    Ecto-absent compile lane (engineering-DNA §3 / Pitfall 5). The
    module name still exists so docs/examples that reference
    `Relyra.Metadata.Scheduler.run_due/2` still type-check; calling
    `run_due/2` returns the typed optional-dep error.
    """

    alias Relyra.Error

    @spec run_due(module(), keyword()) :: {:error, Error.t()}
    def run_due(_repo, _opts \\ []) do
      {:error,
       Error.new(
         :optional_dependency_missing,
         "Ecto is required for scheduled metadata refresh; add `{:ecto, \"~> 3.13\"}` and `{:ecto_sql, \"~> 3.13\"}` to deps",
         %{operation: :run_due, missing_dependency: :ecto}
       )}
    end
  end
end
