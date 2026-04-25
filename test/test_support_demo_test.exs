defmodule Relyra.TestSupportDemoRouter do
  use Phoenix.Router

  post "/:connection_id/acs", Relyra.TestSupportDemoController, :acs
end

defmodule Relyra.TestSupportDemoController do
  use Phoenix.Controller, formats: [html: "Phoenix.HTML"]

  def acs(conn, _params) do
    conn
    |> Plug.Conn.assign(:current_user, %{email: "alice@example.com"})
    |> Phoenix.Controller.text("ok")
  end
end

defmodule Relyra.TestSupportDemoTest do
  use ExUnit.Case, async: false
  use Relyra.TestSupport, endpoint: Relyra.TestSupportDemoRouter

  test "adopters can write a tiny integration test" do
    conn = Phoenix.ConnTest.build_conn() |> setup_saml_connection(connection_id: "demo")

    response = build_saml_response() |> sign_saml_response()
    conn = post_saml_response(conn, Base.decode64!(response, padding: false))

    assert_saml_login(conn, %{email: "alice@example.com"})
    assert saml_login(conn) == {:ok, %{email: "alice@example.com"}}
  end
end
