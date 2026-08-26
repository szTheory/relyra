defmodule LedgerLoopWeb.PageController do
  use LedgerLoopWeb, :controller

  import Ecto.Query

  alias LedgerLoop.Accounts.LoginReceipt
  alias LedgerLoop.Repo

  def home(conn, _params) do
    readiness = if LedgerLoop.Health.ready?(), do: "Ready", else: "Unavailable"

    # Query stable scenario summaries from the database
    connections = LedgerLoop.Repo.all(Relyra.Ecto.Connection)

    scenarios =
      connections
      |> Enum.sort_by(& &1.display_name)
      |> Enum.map(&%{name: &1.display_name, status: &1.status})

    has_login_receipt? =
      Repo.one(from receipt in LoginReceipt, order_by: [desc: receipt.inserted_at], limit: 1) !=
        nil

    render(conn, :home,
      health_status: "Booted",
      readiness_status: readiness,
      has_tenant?: length(scenarios) > 0,
      has_login_receipt?: has_login_receipt?,
      scenarios: scenarios
    )
  end
end
