defmodule LedgerLoopWeb.PageControllerTest do
  use LedgerLoopWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    response = html_response(conn, 200)

    assert response =~ "LedgerLoop Workspace"
    assert response =~ "Northstar Health SSO status"
    assert response =~ "Open SSO Setup"
    assert response =~ "Start Test Login"
    assert response =~ "Open Relyra Admin"
    assert response =~ "Open Support Scenario"
  end
end
