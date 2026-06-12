defmodule LedgerLoopWeb.PageController do
  use LedgerLoopWeb, :controller

  def home(conn, _params) do
    readiness = if LedgerLoop.Health.ready?(), do: "Ready", else: "Unavailable"

    render(conn, :home,
      health_status: "Booted",
      readiness_status: readiness
    )
  end
end
