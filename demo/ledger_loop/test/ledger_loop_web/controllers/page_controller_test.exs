defmodule LedgerLoopWeb.PageControllerTest do
  use LedgerLoopWeb.ConnCase

  alias LedgerLoop.Demo.Reset

  setup do
    Reset.reset!()
    :ok
  end

  test "GET / after reset shows Northstar Health and scenario labels (Test 1)", %{conn: conn} do
    conn = get(conn, ~p"/")
    response = html_response(conn, 200)

    for label <- [
          "Northstar Health",
          "Enabled",
          "Draft/Missing Metadata",
          "Staged Rollover",
          "Support Failure"
        ] do
      assert response =~ label
    end
  end

  test "GET / still includes existing route affordance and scope labels (Test 2)", %{conn: conn} do
    conn = get(conn, ~p"/")
    response = html_response(conn, 200)

    for label <- [
          "LedgerLoop Workspace",
          "Northstar Health SSO status",
          "Open SSO Setup",
          "Start Test Login",
          "Open Relyra Admin",
          "Open Support Scenario",
          "Mounted SAML routes: /saml",
          "Mounted operator routes: /relyra/admin",
          "Demo health",
          "Demo readiness"
        ] do
      assert response =~ label
    end

    for href <- [
          ~s(href="/setup/sso"),
          ~s(href="/login/test"),
          ~s(href="/relyra/admin"),
          ~s(href="/support/scenario"),
          ~s(href="/healthz"),
          ~s(href="/readyz")
        ] do
      assert response =~ href
    end
  end

  test "GET / still omits forbidden tokens (Test 3)", %{conn: conn} do
    conn = get(conn, ~p"/")
    response = html_response(conn, 200)

    for forbidden <- [
          "BEGIN CERTIFICATE",
          "PRIVATE KEY",
          "<?xml",
          "SAMLResponse",
          "Assertion",
          "RelayState=",
          "FakeIdP",
          "Keycloak"
        ] do
      refute response =~ forbidden
    end
  end
end
