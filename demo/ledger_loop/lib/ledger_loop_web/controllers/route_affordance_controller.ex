defmodule LedgerLoopWeb.RouteAffordanceController do
  use LedgerLoopWeb, :controller

  def setup(conn, _params) do
    render(conn, :setup)
  end

  def login(conn, _params) do
    render(conn, :login)
  end

  def support(conn, _params) do
    render(conn, :support)
  end
end
