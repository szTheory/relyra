defmodule PackageConsumer.RequestStore do
  @moduledoc false
  @behaviour Relyra.RequestStore

  alias Relyra.RequestStore.Ecto, as: RelyraEcto

  @repo PackageConsumer.Repo
  @table "package_consumer_request_intents"

  @impl true
  def put_intent(relay_state, intent, opts \\ []) do
    RelyraEcto.put_intent(relay_state, intent, fixed_opts(opts))
  end

  @impl true
  def fetch_intent(relay_state, opts \\ []) do
    RelyraEcto.fetch_intent(relay_state, fixed_opts(opts))
  end

  @impl true
  def consume_intent(relay_state, request_id, opts \\ []) do
    RelyraEcto.consume_intent(relay_state, request_id, fixed_opts(opts))
  end

  defp fixed_opts(opts), do: Keyword.merge(opts, repo: @repo, table: @table)
end

defmodule PackageConsumer.ReplayStore do
  @moduledoc false
  @behaviour Relyra.ReplayStore

  alias Relyra.ReplayStore.Ecto, as: RelyraEcto

  @repo PackageConsumer.Repo
  @table "package_consumer_replay_keys"

  @impl true
  def consume_replay_key(replay_key, metadata, opts \\ []) do
    RelyraEcto.consume_replay_key(replay_key, metadata, fixed_opts(opts))
  end

  defp fixed_opts(opts), do: Keyword.merge(opts, repo: @repo, table: @table)
end
