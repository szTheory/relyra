defmodule LedgerLoop.Repo do
  use Ecto.Repo,
    otp_app: :ledger_loop,
    adapter: Ecto.Adapters.Postgres
end
