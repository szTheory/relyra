defmodule Relyra.Adoption.Journey04EctoProductionPathTest do
  use Relyra.TestSupport.MigrationCase, async: false
  import Phoenix.ConnTest

  alias Relyra.TestSupport.AdoptionFixtures

  @endpoint DemoHostWeb.Router

  setup do
    AdoptionFixtures.configure_ecto_runtime!()
    :ok
  end

  @tag :integration
  test "seeded Ecto connection resolves and accepts a signed ACS post" do
    AdoptionFixtures.seed_ecto_connection!(:okta, "ecto_demo")

    post_params = AdoptionFixtures.build_signed_acs_post!("ecto_demo")

    conn =
      build_conn()
      |> post("/ecto_demo/acs", %{
        "SAMLResponse" => post_params.saml_response,
        "RelayState" => post_params.relay_state
      })

    assert redirected_to(conn) == "/welcome"
  end
end
