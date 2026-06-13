defmodule LedgerLoop.Health do
  @moduledoc false

  def ready? do
    case Application.get_env(:ledger_loop, :ready_state, :database) do
      :force_ready -> true
      :force_unavailable -> false
      :database -> database_ready?()
    end
  end

  defp database_ready? do
    case LedgerLoop.Repo.query("SELECT 1", [], timeout: 1000) do
      {:ok, _result} -> true
      {:error, _reason} -> false
    end
  end
end
