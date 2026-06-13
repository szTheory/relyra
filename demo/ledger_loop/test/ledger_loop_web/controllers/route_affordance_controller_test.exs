defmodule LedgerLoopWeb.RouteAffordanceControllerTest do
  use LedgerLoopWeb.ConnCase, async: true

  describe "login" do
    test "renders the login page with a FakeIdP SSO link", %{conn: conn} do
      conn = get(conn, "/login/test")

      expected_id = LedgerLoop.Demo.Fixtures.relyra_enabled_scenario_id()
      assert html_response(conn, 200) =~ "/fake_idp/#{expected_id}/sso"
    end
  end

  describe "admin_login" do
    test "sets admin session keys and redirects to /relyra/admin", %{conn: conn} do
      conn = get(conn, "/login/admin")

      assert redirected_to(conn) == "/relyra/admin"
      assert get_session(conn, :admin_actor) == "demo_admin"
      assert get_session(conn, :admin_actor_label) == "Demo Administrator"
      assert get_session(conn, :admin_organization_id) == "northstar"
    end
  end

  describe "support" do
    test "redirects to LiveAdmin trace URL", %{conn: conn} do
      conn = get(conn, "/support/scenario")

      expected_id = LedgerLoop.Demo.Fixtures.relyra_support_scenario_id()
      assert redirected_to(conn) == "/relyra/admin/connections/#{expected_id}/trace"
    end
  end
end
