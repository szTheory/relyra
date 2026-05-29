defmodule Relyra.Adoption.KeycloakSamlJourneyTest do
  use ExUnit.Case, async: false
  import Phoenix.ConnTest

  alias Relyra.TestSupport.AdoptionFixtures
  alias Relyra.TestSupport.KeycloakAdoption

  @endpoint DemoHostWeb.Router
  @moduletag :external_idp

  setup _context do
    if is_nil(System.get_env("KEYCLOAK_BASE_URL")) do
      {:skip, "KEYCLOAK_BASE_URL not set"}
    else
      base_url = KeycloakAdoption.base_url!()
      KeycloakAdoption.wait_for_ready!(base_url)

      AdoptionFixtures.setup_ets_runtime!()

      cert_chain = KeycloakAdoption.fetch_signing_cert_pem!(base_url)
      connection = KeycloakAdoption.build_connection!(base_url, cert_chain)
      :ok = DemoHost.Relyra.Connections.put_connection("keycloak", connection)

      fixture =
        Path.expand("fixtures/connection.json", __DIR__)
        |> File.read!()
        |> Jason.decode!()

      {:ok,
       base_url: base_url,
       connection: connection,
       username: fixture["username"],
       password: fixture["password"]}
    end
  end

  @tag :external_idp
  @tag timeout: 120_000
  test "SP-initiated Keycloak login completes via production ACS", %{
    base_url: base_url,
    connection: connection,
    username: username,
    password: password
  } do
    opts = Application.get_all_env(:relyra)

    login = KeycloakAdoption.start_login!(connection, opts)

    {saml_response, relay_state} =
      KeycloakAdoption.fetch_saml_response!(base_url, connection, login, username, password)

    conn =
      build_conn()
      |> post("/keycloak/acs", %{
        "SAMLResponse" => saml_response,
        "RelayState" => relay_state
      })

    assert redirected_to(conn) == "/welcome"
  end
end
