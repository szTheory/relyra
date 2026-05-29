defmodule Relyra.TestSupport.NoopRequestStore do
  @moduledoc false

  @behaviour Relyra.RequestStore

  alias Relyra.Error

  @impl true
  def put_intent(_relay_state, _intent, _opts), do: :ok

  @impl true
  def fetch_intent(relay_state, opts) when is_binary(relay_state) and is_list(opts) do
    case Keyword.get(opts, :request_intent) do
      intent when is_map(intent) ->
        {:ok, intent}

      _ ->
        {:error,
         Error.new(
           :request_intent_not_found,
           "No request intent present in relyra test options",
           %{relay_state: relay_state}
         )}
    end
  end

  @impl true
  def consume_intent(_relay_state, _request_id, _opts), do: :ok
end

defmodule Relyra.TestSupport.NoopReplayStore do
  @moduledoc false

  @behaviour Relyra.ReplayStore

  @impl true
  def consume_replay_key(_replay_key, _metadata, _opts), do: :ok
end

defmodule Relyra.TestSupport.NoopConnectionResolver do
  @moduledoc false

  @behaviour Relyra.ConnectionResolver

  alias Relyra.Error

  @impl true
  def resolve_connection(_request_context, opts) when is_list(opts) do
    case Keyword.get(opts, :resolved_connection) do
      connection when is_map(connection) ->
        {:ok, connection}

      _ ->
        {:error,
         Error.new(
           :adapter_not_configured,
           "Test connection resolver expected :resolved_connection option",
           %{operation: :resolve_connection}
         )}
    end
  end
end
