defmodule LedgerLoopWeb.PageControllerTest do
  use LedgerLoopWeb.ConnCase

  test "GET /", %{conn: conn} do
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

    for forbidden <- [
          "BEGIN CERTIFICATE",
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
