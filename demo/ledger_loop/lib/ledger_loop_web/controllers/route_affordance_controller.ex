defmodule LedgerLoopWeb.RouteAffordanceController do
  use LedgerLoopWeb, :controller

  def setup(conn, _params) do
    text(conn, "LedgerLoop host-owned SSO setup route. Full setup workflow lands in Phase 53.")
  end

  def login(conn, _params) do
    text(conn, "LedgerLoop host-owned test login route. Browser login proof lands in Phase 54.")
  end

  def support(conn, _params) do
    text(
      conn,
      "LedgerLoop host-owned support scenario route. Seeded support flows land in Phase 53."
    )
  end
end
