defmodule Relyra.Metadata.SourceRegistry do
  @moduledoc false

  alias Relyra.Ecto.{Connection, MetadataSource}
  alias Relyra.Error

  @ecto_repo Ecto.Repo

  @spec register_source(binary(), map(), keyword()) :: {:ok, MetadataSource.t()} | {:error, Error.t()}
  def register_source(connection_id, attrs, opts \\ [])

  def register_source(connection_id, attrs, opts)
      when is_binary(connection_id) and is_map(attrs) and is_list(opts) do
    with {:ok, repo} <- fetch_repo(opts, :register_source),
         :ok <- ensure_optional_dependency!(repo, :register_source),
         {:ok, connection} <- fetch_connection(repo, connection_id, :register_source) do
      source =
        repo.get_by(MetadataSource, connection_record_id: connection.id) ||
          %MetadataSource{connection_record_id: connection.id}

      source
      |> MetadataSource.changeset(%{
        connection_record_id: connection.id,
        url: Map.get(attrs, :url) || Map.get(attrs, "url"),
        kind: :remote_url,
        registered_by: Map.get(attrs, :actor) || Map.get(attrs, "actor"),
        registered_reason: Map.get(attrs, :cause) || Map.get(attrs, "cause"),
        last_outcome: :registered,
        metadata: Map.get(attrs, :metadata) || %{}
      })
      |> persist_source(repo)
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

  defp persist_source(changeset, repo) do
    case repo.insert_or_update(changeset) do
      {:ok, source} ->
        {:ok, source}

      {:error, %Ecto.Changeset{} = invalid_changeset} ->
        {:error,
         Error.new(
           :invalid_connection_record,
           "Metadata source failed validation",
           %{operation: :register_source, errors: format_changeset_errors(invalid_changeset)}
         )}
    end
  end

  defp fetch_repo(opts, operation) do
    case Keyword.fetch(opts, :repo) do
      {:ok, repo} when is_atom(repo) -> {:ok, repo}
      _ -> {:error, Error.new(:adapter_not_configured, "opts[:repo] is required for metadata persistence", %{operation: operation, reason: :missing_repo})}
    end
  end

  defp ensure_optional_dependency!(repo, operation) do
    cond do
      not Code.ensure_loaded?(@ecto_repo) ->
        {:error, Error.new(:optional_dependency_missing, "Ecto.Repo is unavailable", %{repo: inspect(repo), operation: operation})}

      true ->
        :ok
    end
  end

  defp fetch_connection(repo, connection_id, operation) do
    case repo.get_by(Connection, connection_id: connection_id) do
      nil -> {:error, Error.new(:connection_not_found, "Connection record was not found", %{operation: operation, connection_id: connection_id})}
      connection -> {:ok, connection}
    end
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
