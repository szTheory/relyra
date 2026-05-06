defmodule Relyra.ConnectionResolver.Ecto do
  @moduledoc """
  Thin persisted-connection resolver adapter.

  This module owns request-context orchestration plus public error mapping only.
  Ecto access and aggregate-to-snapshot normalization stay in internal helpers.
  """

  @behaviour Relyra.ConnectionResolver

  alias Relyra.Ecto.{ConnectionLoader, ConnectionSnapshot}
  alias Relyra.Error

  @impl true
  @spec resolve_connection(map(), keyword()) :: {:ok, Relyra.Connection.t()} | {:error, Error.t()}
  def resolve_connection(%{connection_id: connection_id}, opts)
      when is_binary(connection_id) and connection_id != "" and is_list(opts) do
    with {:ok, repo} <- fetch_repo(opts),
         {:ok, aggregate} <-
           ConnectionLoader.fetch(repo, connection_id, operation: :resolve_connection),
         {:ok, snapshot} <- ConnectionSnapshot.hydrate(aggregate, operation: :resolve_connection) do
      {:ok, snapshot}
    end
  end

  def resolve_connection(request_context, _opts) when is_map(request_context) do
    {:error,
     Error.new(
       :connection_unavailable,
       "Connection ID is required to resolve a persisted connection",
       %{
         operation: :resolve_connection,
         reason: :missing_connection_id
       }
     )}
  end

  def resolve_connection(_request_context, _opts) do
    {:error,
     Error.new(
       :connection_unavailable,
       "Request context for persisted connection resolution is invalid",
       %{
         operation: :resolve_connection,
         reason: :invalid_request_context
       }
     )}
  end

  defp fetch_repo(opts) do
    case Keyword.fetch(opts, :repo) do
      {:ok, repo} when is_atom(repo) ->
        {:ok, repo}

      _ ->
        {:error,
         Error.new(
           :resolver_misconfigured,
           "opts[:repo] is required for the Ecto connection resolver",
           %{
             operation: :resolve_connection,
             reason: :repo_missing
           }
         )}
    end
  end
end
