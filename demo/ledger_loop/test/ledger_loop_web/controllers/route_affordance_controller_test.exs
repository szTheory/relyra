defmodule LedgerLoopWeb.RouteAffordanceControllerTest do
  use LedgerLoopWeb.ConnCase, async: false

  alias LedgerLoop.Demo.{Fixtures, KeycloakProvisioner, Reset}
  alias LedgerLoop.Repo
  alias Relyra.Ecto.Connection

  setup do
    Reset.reset!()

    previous_config = Application.get_env(:ledger_loop, :demo_admin_auth)

    Application.put_env(:ledger_loop, :demo_admin_auth,
      username: "test-admin",
      password: "test-password"
    )

    on_exit(fn ->
      if previous_config do
        Application.put_env(:ledger_loop, :demo_admin_auth, previous_config)
      else
        Application.delete_env(:ledger_loop, :demo_admin_auth)
      end
    end)

    :ok
  end

  describe "login" do
    test "keeps FakeIdP available without a Keycloak connection", %{conn: conn} do
      conn = get(conn, "/login/test")

      expected_id = Fixtures.relyra_enabled_scenario_id()
      assert html_response(conn, 200) =~ "/saml/#{expected_id}/login"
      refute html_response(conn, 200) =~ "Test with Keycloak (optional real IdP)"
      refute html_response(conn, 200) =~ "/saml/#{KeycloakProvisioner.connection_id()}/login"
    end

    test "keeps the Keycloak job hidden when its connection is disabled", %{conn: conn} do
      insert_keycloak_connection!(:disabled)

      conn = get(conn, "/login/test")

      assert html_response(conn, 200) =~ "/saml/#{Fixtures.relyra_enabled_scenario_id()}/login"
      refute html_response(conn, 200) =~ "Test with Keycloak (optional real IdP)"
      refute html_response(conn, 200) =~ "/saml/#{KeycloakProvisioner.connection_id()}/login"
    end

    test "renders the optional Keycloak job only for its enabled stable connection", %{conn: conn} do
      insert_keycloak_connection!(:enabled)

      conn = get(conn, "/login/test")
      response = html_response(conn, 200)
      keycloak_id = KeycloakProvisioner.connection_id()

      assert response =~ "/saml/#{Fixtures.relyra_enabled_scenario_id()}/login"
      assert response =~ "Test with Keycloak (optional real IdP)"
      assert response =~ ~s(href="/saml/#{keycloak_id}/login")
    end
  end

  describe "admin_login" do
    test "rejects absent and invalid host credentials before admin scope establishment", %{conn: conn} do
      for conn <- [
            conn,
            put_req_header(conn, "authorization", Plug.BasicAuth.encode_basic_auth("wrong", "credentials"))
          ], path <- ["/login/admin", "/relyra/admin/connections/new"] do
        response = get(conn, path)

        assert response.status == 401
        assert get_resp_header(response, "www-authenticate") == [~s(Basic realm="Application")]
        assert get_session(response, :admin_actor) == nil
        assert get_session(response, :admin_actor_label) == nil
        assert get_session(response, :admin_organization_id) == nil
      end
    end

    test "sets fixed admin session keys only after valid host credentials", %{conn: conn} do
      conn =
        conn
        |> put_req_header(
          "authorization",
          Plug.BasicAuth.encode_basic_auth("test-admin", "test-password")
        )
        |> get("/login/admin")

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

  defp insert_keycloak_connection!(status) do
    Repo.insert!(%Connection{
      connection_id: KeycloakProvisioner.connection_id(),
      display_name: "Northstar Health — Keycloak real IdP",
      organization_id: "northstar-keycloak-test",
      status: status,
      provider_preset: :okta,
      sp_entity_id:
        "http://relyra.localhost/saml/#{KeycloakProvisioner.connection_id()}/metadata",
      acs_url: "http://relyra.localhost/saml/#{KeycloakProvisioner.connection_id()}/acs",
      idp_entity_id: KeycloakProvisioner.public_issuer(),
      idp_sso_url: "#{KeycloakProvisioner.public_issuer()}/protocol/saml"
    })
  end
end
