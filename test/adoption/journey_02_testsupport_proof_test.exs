defmodule Relyra.Adoption.Journey02TestSupportProofTest do
  use ExUnit.Case, async: false
  use Relyra.TestSupport, endpoint: DemoHostWeb.TestRouter

  alias Relyra.TestSupport.AdoptionFixtures

  @tag :integration
  test "TestSupport macro proves local SAML round-trip on demo host stub ACS" do
    AdoptionFixtures.setup_ets_runtime!()
    AdoptionFixtures.seed_preset_connection!(:okta, "demo")

    conn = Phoenix.ConnTest.build_conn() |> setup_saml_connection(connection_id: "demo")

    response = build_saml_response() |> sign_saml_response()
    conn = post_saml_response(conn, Base.decode64!(response, padding: false))

    assert_saml_login(conn, %{email: "alice@example.com"})
    assert saml_login(conn) == {:ok, %{email: "alice@example.com"}}
  end

  @tag :integration
  test "preset connection shapes cover all four batteries-included presets" do
    for preset <- [:okta, :entra, :google_workspace, :adfs] do
      connection = AdoptionFixtures.connection_from_preset(preset, Atom.to_string(preset))
      assert connection.provider_preset == preset
      assert connection.idp_certificates != []
    end
  end
end
