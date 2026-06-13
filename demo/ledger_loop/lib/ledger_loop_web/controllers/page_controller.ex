defmodule LedgerLoopWeb.PageController do
  use LedgerLoopWeb, :controller

  def home(conn, _params) do
    readiness = if LedgerLoop.Health.ready?(), do: "Ready", else: "Unavailable"

    # Query stable scenario summaries from the database
    connections = LedgerLoop.Repo.all(Relyra.Ecto.Connection)

    scenarios =
      connections
      |> Enum.sort_by(& &1.display_name)
      |> Enum.map(&%{name: &1.display_name, status: &1.status})

    render(conn, :home,
      health_status: "Booted",
      readiness_status: readiness,
      has_tenant?: length(scenarios) > 0,
      scenarios: scenarios
    )
  end
end
