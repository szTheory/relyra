defmodule LedgerLoopWeb.HealthController do
  use LedgerLoopWeb, :controller

  def health(conn, _params) do
    text(conn, "booted")
  end

  def ready(conn, _params) do
    if LedgerLoop.Health.ready?() do
      text(conn, "ready")
    else
      conn
      |> put_status(:service_unavailable)
      |> text("unavailable")
    end
  end
end
