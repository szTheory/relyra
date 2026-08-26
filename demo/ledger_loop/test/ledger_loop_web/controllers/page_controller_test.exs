defmodule LedgerLoopWeb.PageControllerTest do
  use LedgerLoopWeb.ConnCase

  alias LedgerLoop.Accounts.{LoginReceipt, User}
  alias LedgerLoop.Demo.Reset
  alias LedgerLoop.Repo

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

  test "GET / displays the verified receipt only after LedgerLoop records it", %{conn: conn} do
    receipt_copy =
      "Relyra verified the assertion; LedgerLoop mapped the user and recorded the session-establishment receipt."

    conn = get(conn, ~p"/")
    refute html_response(conn, 200) =~ receipt_copy

    user = Repo.get_by!(User, email: "sarah@northstar.example.com")

    %LoginReceipt{}
    |> LoginReceipt.changeset(%{user_id: user.id, scenario_key: "verified-sign-in-receipt"})
    |> Repo.insert!()

    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ receipt_copy
  end
end
