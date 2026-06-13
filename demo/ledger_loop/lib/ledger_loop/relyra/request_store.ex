defmodule LedgerLoop.Relyra.RequestStore do
  @moduledoc """
  Fixed-table wrapper around Relyra.RequestStore.Ecto for the demo app.
  """
  @behaviour Relyra.RequestStore

  alias Relyra.RequestStore.Ecto, as: RelyraEcto

  @repo LedgerLoop.Repo
  @table "ledger_loop_relyra_request_intents"

  @impl Relyra.RequestStore
  def put_intent(relay_state, intent, opts \\ []) do
    fixed_opts = Keyword.merge(opts, repo: @repo, table: @table)
    RelyraEcto.put_intent(relay_state, intent, fixed_opts)
  end

  @impl Relyra.RequestStore
  def fetch_intent(relay_state, opts \\ []) do
    fixed_opts = Keyword.merge(opts, repo: @repo, table: @table)
    RelyraEcto.fetch_intent(relay_state, fixed_opts)
  end

  @impl Relyra.RequestStore
  def consume_intent(relay_state, request_id, opts \\ []) do
    fixed_opts = Keyword.merge(opts, repo: @repo, table: @table)
    RelyraEcto.consume_intent(relay_state, request_id, fixed_opts)
  end
end
