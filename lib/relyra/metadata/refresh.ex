defmodule Relyra.Metadata.Refresh do
  @moduledoc false

  alias Relyra.Ecto.{Connection, MetadataApply, MetadataSource}
  alias Relyra.Error
  alias Relyra.Log
  alias Relyra.Metadata.{Import, Parser}
  alias Relyra.Telemetry

  @ecto_repo Ecto.Repo

  @spec refresh(binary(), keyword()) :: {:ok, struct()} | {:error, Error.t()}
  def refresh(connection_id, opts \\ [])

  def refresh(connection_id, opts) when is_binary(connection_id) and is_list(opts) do
    with {:ok, repo} <- fetch_repo(opts),
         :ok <- ensure_optional_dependencies(repo),
         {:ok, req} <- fetch_req(opts),
         {:ok, connection} <- fetch_connection(repo, connection_id),
         {:ok, source} <- fetch_source(repo, connection.id) do
      metadata = %{
        connection_id: connection_id,
        metadata_source_id: source.id,
        source_kind: :remote_url,
        trigger: :manual_refresh
      }

      Telemetry.span([:metadata, :refresh], metadata, fn ->
        do_refresh(connection, source, req, repo, opts, metadata)
      end)
    end
  end

  def refresh(_connection_id, opts) do
    {:error,
     Error.new(
       :invalid_connection_record,
       "connection_id is required for metadata refresh",
       %{operation: :refresh, repo: inspect(Keyword.get(opts, :repo))}
     )}
  end

  defp do_refresh(connection, source, req, repo, opts, metadata) do
    case fetch_xml(req, source.url) do
      {:ok, xml} ->
        case Parser.parse(xml, opts) do
          {:ok, parsed} ->
            candidate = Import.build_candidate(parsed)
            certificate_count = candidate_certificate_count(candidate)
            certificate_pem = first_candidate_pem(candidate)

            case MetadataApply.apply_revision(
                   connection.connection_id,
                   Map.from_struct(candidate),
                   %{
                     metadata_source_id: source.id,
                     source_kind: :remote_url,
                     trigger: :manual_refresh,
                     actor: Keyword.get(opts, :actor, "unknown"),
                     cause: Keyword.get(opts, :cause, "manual refresh"),
                     content_hash_sha256: sha256(xml),
                     trust_summary: candidate.trust_summary
                   },
                   repo: repo,
                   audit: resolve_audit(opts)
                 ) do
              {:ok, revision} ->
                update_source(repo, source, :applied)

                Log.info("metadata refresh applied",
                  connection_id: connection.connection_id,
                  metadata_xml: xml,
                  certificate_pem: certificate_pem
                )

                {{:ok, revision},
                 Map.merge(metadata, %{outcome: :ok, certificate_count: certificate_count})}

              {:error, %Error{} = error} ->
                record_refresh_failure(connection, source, repo, xml, error, :apply_failed, opts)

                {{:error, error},
                 Map.merge(metadata, %{
                   outcome: :error,
                   error_code: error.type,
                   certificate_count: 0
                 })}
            end

          {:error, %Error{} = error} ->
            record_refresh_failure(
              connection,
              source,
              repo,
              xml,
              error,
              failure_outcome(error),
              opts
            )

            {{:error, error},
             Map.merge(metadata, %{outcome: :error, error_code: error.type, certificate_count: 0})}
        end

      {:error, %Error{} = error} ->
        record_refresh_failure(connection, source, repo, nil, error, :fetch_failed, opts)

        {{:error, error},
         Map.merge(metadata, %{outcome: :error, error_code: error.type, certificate_count: 0})}
    end
  end

  defp record_refresh_failure(connection, source, repo, xml, error, outcome, opts) do
    _ =
      MetadataApply.record_attempt(
        connection.connection_id,
        %{
          metadata_source_id: source.id,
          source_kind: :remote_url,
          trigger: :manual_refresh,
          actor: Keyword.get(opts, :actor, "unknown"),
          cause: Keyword.get(opts, :cause, Atom.to_string(error.type)),
          outcome: outcome,
          content_hash_sha256: if(is_binary(xml), do: sha256(xml), else: nil),
          details: failure_details(xml, error),
          trust_summary: %{status: "failed", error_code: error.type}
        },
        repo: repo,
        audit: resolve_audit(opts)
      )

    update_source(repo, source, outcome)

    Log.error("metadata refresh failed",
      connection_id: connection.connection_id,
      error_code: error.type,
      metadata_xml: xml || "",
      certificate_pem: ""
    )
  end

  defp fetch_xml(req, url) do
    case Req.get(req, url: url) do
      {:ok, %Req.Response{status: 200, body: body}} when is_binary(body) ->
        {:ok, body}

      {:ok, %Req.Response{status: status}} ->
        {:error,
         Error.new(:metadata_fetch_failed, "Metadata refresh returned an unexpected status", %{
           status: status
         })}

      {:error, exception} ->
        {:error,
         Error.new(:metadata_fetch_failed, "Metadata refresh failed", %{
           reason: Exception.message(exception)
         })}
    end
  end

  defp fetch_repo(opts) do
    case Keyword.fetch(opts, :repo) do
      {:ok, repo} when is_atom(repo) ->
        {:ok, repo}

      _ ->
        {:error,
         Error.new(:adapter_not_configured, "opts[:repo] is required for metadata refresh", %{
           operation: :refresh,
           reason: :missing_repo
         })}
    end
  end

  defp fetch_req(opts) do
    case Keyword.fetch(opts, :req) do
      {:ok, %Req.Request{} = req} ->
        {:ok, req}

      {:ok, req_opts} when is_list(req_opts) ->
        {:ok, Req.new(req_opts)}

      _ ->
        {:error,
         Error.new(:adapter_not_configured, "opts[:req] is required for metadata refresh", %{
           operation: :refresh,
           reason: :missing_req
         })}
    end
  end

  defp ensure_optional_dependencies(repo) do
    cond do
      not Code.ensure_loaded?(@ecto_repo) ->
        {:error,
         Error.new(:optional_dependency_missing, "Ecto.Repo is unavailable", %{
           repo: inspect(repo),
           operation: :refresh
         })}

      not Code.ensure_loaded?(Req) ->
        {:error,
         Error.new(
           :optional_dependency_missing,
           "Req is unavailable; add optional Req dependency before using metadata refresh",
           %{operation: :refresh}
         )}

      true ->
        :ok
    end
  end

  defp fetch_connection(repo, connection_id) do
    case repo.get_by(Connection, connection_id: connection_id) do
      nil ->
        {:error,
         Error.new(:connection_not_found, "Connection record was not found", %{
           connection_id: connection_id,
           operation: :refresh
         })}

      connection ->
        {:ok, connection}
    end
  end

  defp fetch_source(repo, connection_record_id) do
    case repo.get_by(MetadataSource, connection_record_id: connection_record_id) do
      nil ->
        {:error,
         Error.new(
           :metadata_source_not_found,
           "No registered metadata source exists for this connection",
           %{operation: :refresh}
         )}

      source ->
        {:ok, source}
    end
  end

  defp update_source(repo, source, outcome) do
    source
    |> Ecto.Changeset.change(last_fetched_at: DateTime.utc_now(), last_outcome: outcome)
    |> repo.update()
  end

  defp failure_outcome(%Error{type: :malformed_xml}), do: :parse_failed
  defp failure_outcome(%Error{type: :metadata_wrong_root}), do: :parse_failed
  defp failure_outcome(%Error{}), do: :validation_failed

  # Resolves the audit context per D-21.1-03 fallback ordering:
  #   1. opts[:audit] map (preferred — bulk path via BulkActions, scheduled path
  #      via AutoRefresh — already provides actor/cause/correlation_id)
  #   2. Top-level opts[:actor] / opts[:cause] keyword opts (single-connection
  #      callers: connection_metadata_live.ex, mix tasks, existing tests)
  #   3. Defaults actor: "unknown", cause: "manual refresh" (last resort)
  #
  # Always returns a map carrying actor, cause, and correlation_id (nil when
  # not provided by an upstream batch). The forwarded map flows into
  # MetadataApply.audit_context/2 (metadata_apply.ex:933-944), which prefers a
  # map opts[:audit] over revision_attrs-derived values — closing the Phase 20
  # batch-cohesion gap (CFG-07) without changing the apply_revision contract.
  defp resolve_audit(opts) do
    case Keyword.get(opts, :audit) do
      %{} = audit_map ->
        # Bulk / scheduled path: BulkActions or Scheduler injected
        # actor/cause/correlation_id. Merge under defaults so a partial map
        # (e.g., audit map missing :actor) still produces a valid audit row.
        Map.merge(
          %{actor: "unknown", cause: "manual refresh"},
          audit_map
        )

      _ ->
        # Single-connection path: read top-level keyword opts and synthesize
        # a fully-shaped audit map (correlation_id is nil — no batch context).
        %{
          actor: Keyword.get(opts, :actor, "unknown"),
          cause: Keyword.get(opts, :cause, "manual refresh"),
          correlation_id: nil
        }
    end
  end

  defp failure_details(xml, error) do
    details =
      %{error_code: error.type}
      |> maybe_put(:xml_bytes, is_binary(xml), if(is_binary(xml), do: byte_size(xml), else: nil))

    details
  end

  defp maybe_put(map, _key, false, _value), do: map
  defp maybe_put(map, key, true, value), do: Map.put(map, key, value)

  defp candidate_certificate_count(candidate) do
    candidate
    |> Map.get(:certificates, Map.get(candidate, :certificate_pems, []))
    |> length()
  end

  defp first_candidate_pem(candidate) do
    case Map.get(candidate, :certificates, []) do
      [%{pem: pem} | _rest] -> pem
      _other -> candidate |> Map.get(:certificate_pems, []) |> List.first()
    end
  end

  defp sha256(value), do: :crypto.hash(:sha256, value) |> Base.encode16(case: :lower)
end
