defmodule LedgerLoopWeb.RouteAffordanceController do
  use LedgerLoopWeb, :controller

  def setup(conn, _params) do
    render(conn, :setup)
  end

  def login(conn, _params) do
    render(conn, :login)
  end

  def admin_login(conn, _params) do
    conn
    |> put_session(:admin_actor, "demo_admin")
    |> put_session(:admin_actor_label, "Demo Administrator")
    |> put_session(:admin_organization_id, "northstar")
    |> redirect(to: "/relyra/admin")
  end

  def support(conn, _params) do
    id = LedgerLoop.Demo.Fixtures.relyra_support_scenario_id()
    redirect(conn, to: "/relyra/admin/connections/#{id}/trace")
  end
end
