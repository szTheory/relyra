defmodule LedgerLoop.Relyra.ReplayStore do
  @moduledoc """
  Fixed-table wrapper around Relyra.ReplayStore.Ecto for the demo app.
  """
  @behaviour Relyra.ReplayStore

  alias Relyra.ReplayStore.Ecto, as: RelyraEcto

  @repo LedgerLoop.Repo
  @table "ledger_loop_relyra_replay_keys"

  @impl Relyra.ReplayStore
  def consume_replay_key(replay_key, metadata, opts \\ []) do
    fixed_opts = Keyword.merge(opts, repo: @repo, table: @table)
    RelyraEcto.consume_replay_key(replay_key, metadata, fixed_opts)
  end
end
