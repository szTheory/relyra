defmodule LedgerLoopWeb.FakeIdPControllerTest do
  use LedgerLoopWeb.ConnCase, async: true

  alias LedgerLoop.Demo.Fixtures

  @conn_ulid Fixtures.relyra_enabled_scenario_id()

  describe "GET /fake_idp/login" do
    test "renders the local test support warning banner", %{conn: conn} do
      conn = get(conn, "/fake_idp/login")

      assert html_response(conn, 200) =~ "Local Test Support / FakeIdP"
      assert html_response(conn, 200) =~ "This is a local testing harness"
      assert html_response(conn, 200) =~ "form action=\"/fake_idp/sso\" method=\"post\""
    end

    test "passes through RelayState", %{conn: conn} do
      conn = get(conn, "/fake_idp/login", %{"RelayState" => "my_relay_state"})

      assert html_response(conn, 200) =~ "value=\"my_relay_state\""
    end

    test "renders without in_response_to on direct visit (no SAMLRequest)", %{conn: conn} do
      conn = get(conn, "/fake_idp/login")

      # No hidden in_response_to field when SAMLRequest is absent
      refute html_response(conn, 200) =~ "name=\"in_response_to\""
    end
  end

  describe "POST /fake_idp/sso" do
    test "renders a self-submitting form with a SAMLResponse for success", %{conn: conn} do
      conn =
        post(conn, "/fake_idp/sso", %{
          "idp_action" => "success",
          "RelayState" => "test_relay_state"
        })

      response = html_response(conn, 200)
      assert response =~ "onload=\"document.forms[0].submit()\""
      assert response =~ "name=\"SAMLResponse\""
      assert response =~ "name=\"RelayState\" value=\"test_relay_state\""
      assert response =~ "action=\"/saml/#{@conn_ulid}/acs\""
    end

    test "renders a self-submitting form with a Tampered signature for failure", %{conn: conn} do
      conn = post(conn, "/fake_idp/sso", %{"idp_action" => "failure"})

      response = html_response(conn, 200)
      assert response =~ "onload=\"document.forms[0].submit()\""
      assert response =~ "name=\"SAMLResponse\""
      assert response =~ "action=\"/saml/#{@conn_ulid}/acs\""
    end
  end
end
