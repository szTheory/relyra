defmodule Relyra.Metadata do
  @moduledoc false

  alias Relyra.Error
  alias Relyra.Metadata.{Import, Refresh, SourceRegistry}

  # `Relyra.Ecto.Connection` and `Relyra.Ecto.MetadataSource` are referenced
  # via fully-qualified names below so the no-optional-deps compile lane
  # (where Ecto schemas may not be loaded) does not warn on alias of an
  # absent module.

  @spec import_xml(binary(), binary(), keyword()) :: {:ok, struct()} | {:error, Error.t()}
  def import_xml(connection_id, xml, opts \\ [])

  def import_xml(connection_id, xml, opts)
      when is_binary(connection_id) and is_binary(xml) and is_list(opts) do
    with {:ok, _repo} <- fetch_repo(opts, :import_xml) do
      Import.import_xml(connection_id, xml, opts)
    end
  end

  def import_xml(_connection_id, _xml, opts) do
    {:error,
     Error.new(
       :invalid_connection_record,
       "connection_id and XML bytes are required for metadata import",
       %{operation: :import_xml, repo: inspect(Keyword.get(opts, :repo))}
     )}
  end

  @spec register_source(binary(), map(), keyword()) :: {:ok, struct()} | {:error, Error.t()}
  def register_source(connection_id, attrs, opts \\ [])

  def register_source(connection_id, attrs, opts)
      when is_binary(connection_id) and is_map(attrs) and is_list(opts) do
    with {:ok, _repo} <- fetch_repo(opts, :register_source) do
      SourceRegistry.register_source(connection_id, attrs, opts)
    end
  end

  def register_source(_connection_id, _attrs, opts) do
    {:error,
     Error.new(
       :invalid_connection_record,
       "connection_id and source attrs are required for source registration",
       %{operation: :register_source, repo: inspect(Keyword.get(opts, :repo))}
     )}
  end

  @spec refresh(binary(), keyword()) :: {:ok, struct()} | {:error, Error.t()}
  def refresh(connection_id, opts \\ [])

  def refresh(connection_id, opts) when is_binary(connection_id) and is_list(opts) do
    with {:ok, _repo} <- fetch_repo(opts, :refresh) do
      Refresh.refresh(connection_id, opts)
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

  @doc """
  Pins one or more SHA-256 trust fingerprints onto the connection's
  metadata source.

  Used by both the admin LiveView fingerprint UX (deferred to v0.6) and
  the `mix relyra.metadata.pin` task — they share one underlying
  `auto_refresh_changeset/2` so the two paths cannot drift (D-22 +
  RESEARCH Q1 recommendation).

  `attrs` may include any subset of the operator-facing auto-refresh
  fields:
    - `:metadata_trust_fingerprints` — list of SHA-256 hex strings
      (typically the union of existing pinned + the new fingerprint;
      pin REPLACES the array)
    - `:auto_refresh_enabled` — boolean
    - `:refresh_cadence` — `:hourly | :every_6h | :daily | :weekly`
    - `:require_signed_metadata` — boolean
    - `:legacy_unsigned_metadata_policy` — map (D-19 escape hatch)

  The validation in `auto_refresh_changeset/2` will refuse to enable
  auto-refresh without at least one pinned fingerprint (D-09 great-error).
  """
  @spec pin_trust_fingerprint(binary(), map(), keyword()) ::
          {:ok, struct()} | {:error, Error.t()}
  def pin_trust_fingerprint(connection_id, attrs, opts \\ [])

  def pin_trust_fingerprint(connection_id, attrs, opts)
      when is_binary(connection_id) and is_map(attrs) and is_list(opts) do
    with {:ok, repo} <- fetch_repo(opts, :pin_trust_fingerprint) do
      case repo.get_by(Relyra.Ecto.Connection, connection_id: connection_id) do
        nil ->
          {:error,
           Error.new(
             :connection_not_found,
             "Connection record was not found",
             %{connection_id: connection_id, operation: :pin_trust_fingerprint}
           )}

        connection ->
          case repo.get_by(Relyra.Ecto.MetadataSource,
                 connection_record_id: connection.id
               ) do
            nil ->
              {:error,
               Error.new(
                 :metadata_source_not_found,
                 "No registered metadata source exists for this connection — register one first via `Metadata.register_source/3`",
                 %{connection_id: connection_id, operation: :pin_trust_fingerprint}
               )}

            source ->
              source
              |> Relyra.Ecto.MetadataSource.auto_refresh_changeset(attrs)
              |> repo.update()
              |> case do
                {:ok, updated} ->
                  {:ok, updated}

                {:error, %Ecto.Changeset{} = changeset} ->
                  {:error,
                   Error.new(
                     :invalid_metadata_source,
                     "Trust fingerprint pin failed validation",
                     %{
                       connection_id: connection_id,
                       errors: format_changeset_errors(changeset)
                     }
                   )}
              end
          end
      end
    end
  end

  def pin_trust_fingerprint(_connection_id, _attrs, opts) do
    {:error,
     Error.new(
       :invalid_connection_record,
       "connection_id and attrs are required for trust fingerprint pinning",
       %{operation: :pin_trust_fingerprint, repo: inspect(Keyword.get(opts, :repo))}
     )}
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  defp fetch_repo(opts, operation) do
    case Keyword.fetch(opts, :repo) do
      {:ok, repo} when is_atom(repo) ->
        {:ok, repo}

      _ ->
        {:error,
         Error.new(:adapter_not_configured, "opts[:repo] is required for metadata operations", %{
           operation: operation,
           reason: :missing_repo
         })}
    end
  end
end
