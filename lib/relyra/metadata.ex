defmodule Relyra.Metadata do
  @moduledoc false

  alias Relyra.Error
  alias Relyra.Metadata.{Import, Refresh, SourceRegistry}

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

  defp fetch_repo(opts, operation) do
    case Keyword.fetch(opts, :repo) do
      {:ok, repo} when is_atom(repo) -> {:ok, repo}
      _ -> {:error, Error.new(:adapter_not_configured, "opts[:repo] is required for metadata operations", %{operation: operation, reason: :missing_repo})}
    end
  end
end
