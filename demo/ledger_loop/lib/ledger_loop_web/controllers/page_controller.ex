defmodule LedgerLoopWeb.PageController do
  use LedgerLoopWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
