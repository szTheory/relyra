defmodule Relyra.Diagnostic do
  @moduledoc """
  Diagnostic bundle orchestration service.
  Compiles system state and metrics into an explicitly redacted, in-memory `.zip` archive.
  """

  import Ecto.Query

  alias Relyra.Diagnostic.AllowList
  alias Relyra.Ecto.{Connection, Certificate, MetadataRevision, AuditEvent}
  alias Relyra.Error

  @doc """
  Generates an in-memory ZIP archive containing diagnostic information.
  """
  @spec create_bundle(keyword()) :: {:ok, binary()} | {:error, Error.t()}
  def create_bundle(opts \\ []) do
    with {:ok, repo} <- fetch_repo(opts) do
      try do
        connections =
          repo.all(Connection)
          |> Enum.map(&AllowList.export_connection/1)

        certificates =
          repo.all(Certificate)
          |> Enum.map(&AllowList.export_certificate_inventory/1)

        metadata_revisions =
          repo.all(MetadataRevision)
          |> Enum.map(&AllowList.export_metadata_revision/1)

        audit_logs =
          AuditEvent
          |> order_by(desc: :inserted_at)
          |> limit(1000)
          |> repo.all()
          |> Enum.map(&AllowList.export_audit_log/1)

        store_metrics = fetch_store_metrics(opts)

        files = [
          {~c"connections.json", json_encode!(connections)},
          {~c"certificates.json", json_encode!(certificates)},
          {~c"metadata_revisions.json", json_encode!(metadata_revisions)},
          {~c"audit_logs.json", json_encode!(audit_logs)},
          {~c"store_metrics.json", json_encode!(store_metrics)}
        ]

        case :zip.create(~c"bundle.zip", files, [:memory]) do
          {:ok, {_filename, zip_binary}} ->
            {:ok, zip_binary}

          {:error, reason} ->
            {:error,
             Error.new(
               :diagnostic_bundle_failed,
               "Failed to generate diagnostic bundle ZIP",
               %{operation: :create_bundle, reason: inspect(reason)}
             )}
        end
      rescue
        exception ->
          {:error,
           Error.new(
             :diagnostic_bundle_failed,
             "Failed to generate diagnostic bundle",
             %{operation: :create_bundle, reason: Exception.message(exception)}
           )}
      end
    end
  end

  defp fetch_repo(opts) do
    case Keyword.get(opts, :repo, Relyra.Repo) do
      nil ->
        {:error,
         Error.new(
           :diagnostic_bundle_failed,
           "Ecto Repo is not configured for Relyra.Diagnostic",
           %{operation: :create_bundle, reason: :missing_repo}
         )}

      repo ->
        if Code.ensure_loaded?(repo) do
          {:ok, repo}
        else
          {:error,
           Error.new(
             :diagnostic_bundle_failed,
             "Configured Ecto Repo could not be loaded",
             %{operation: :create_bundle, reason: :repo_not_loaded}
           )}
        end
    end
  end

  defp fetch_store_metrics(_opts) do
    # Fallback to direct ETS query for default adapters
    request_count =
      try do
        case :ets.info(:relyra_request_intents, :size) do
          :undefined -> "unknown"
          size -> size
        end
      rescue
        _ -> "unknown"
      end

    replay_count =
      try do
        case :ets.info(:relyra_replay_keys, :size) do
          :undefined -> "unknown"
          size -> size
        end
      rescue
        _ -> "unknown"
      end

    %{
      request_store: %{count: request_count},
      replay_store: %{count: replay_count}
    }
  end

  defp json_encode!(data) do
    Jason.encode!(data, pretty: true)
  end
end
