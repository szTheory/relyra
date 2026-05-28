defmodule Relyra.Adoption.Journey03ProductionAcsTest do
  use ExUnit.Case, async: false
  import Phoenix.ConnTest

  alias Relyra.TestSupport.AdoptionFixtures

  @endpoint DemoHostWeb.Router

  setup do
    AdoptionFixtures.setup_ets_runtime!()
    AdoptionFixtures.seed_preset_connection!(:okta, "demo")
    :ok
  end

  @tag :integration
  test "production saml_routes ACS completes consume_response and redirects" do
    post_params = AdoptionFixtures.build_signed_acs_post!("demo")

    conn =
      build_conn()
      |> post("/demo/acs", %{
        "SAMLResponse" => post_params.saml_response,
        "RelayState" => post_params.relay_state
      })

    assert redirected_to(conn) == "/welcome"
  end
end
