defmodule Relyra.Testing.Adapters.RequestStore do
  @moduledoc """
  Option-backed request store for public Relyra testing fixtures.
  """

  @behaviour Relyra.RequestStore

  alias Relyra.Error

  @impl true
  def put_intent(_relay_state, _intent, _opts), do: :ok

  @impl true
  def fetch_intent(relay_state, opts) when is_binary(relay_state) and is_list(opts) do
    case Keyword.get(opts, :request_store_fetch) do
      fun when is_function(fun, 2) ->
        fun.(relay_state, opts)

      _ ->
        case Keyword.get(opts, :request_intent) do
          intent when is_map(intent) ->
            {:ok, intent}

          _ ->
            {:error,
             Error.new(
               :request_intent_not_found,
               "No request intent present in Relyra.Testing opts",
               %{relay_state: relay_state}
             )}
        end
    end
  end

  @impl true
  def consume_intent(relay_state, request_id, opts)
      when is_binary(relay_state) and is_binary(request_id) and is_list(opts) do
    case Keyword.get(opts, :request_store_consume) do
      fun when is_function(fun, 3) -> fun.(relay_state, request_id, opts)
      _ -> :ok
    end
  end
end

defmodule Relyra.Testing.Adapters.ReplayStore do
  @moduledoc """
  Option-backed replay store for public Relyra testing fixtures.
  """

  @behaviour Relyra.ReplayStore

  @impl true
  def consume_replay_key(replay_key, metadata, opts)
      when is_binary(replay_key) and is_map(metadata) and is_list(opts) do
    case Keyword.get(opts, :replay_store_consume) do
      fun when is_function(fun, 3) -> fun.(replay_key, metadata, opts)
      _ -> :ok
    end
  end
end

defmodule Relyra.Testing.Adapters.ConnectionResolver do
  @moduledoc """
  Option-backed connection resolver for public Relyra testing fixtures.
  """

  @behaviour Relyra.ConnectionResolver

  alias Relyra.Error

  @impl true
  def resolve_connection(request_context, opts) when is_map(request_context) and is_list(opts) do
    case Keyword.get(opts, :connection_resolver_resolve) do
      fun when is_function(fun, 2) ->
        fun.(request_context, opts)

      _ ->
        case Keyword.get(opts, :resolved_connection) do
          connection when is_map(connection) ->
            {:ok, connection}

          _ ->
            {:error,
             Error.new(
               :resolver_failed,
               "No resolved connection present in Relyra.Testing opts",
               %{request_context: request_context, reason: :missing_resolved_connection}
             )}
        end
    end
  end
end
