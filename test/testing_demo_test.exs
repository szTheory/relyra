defmodule Relyra.TestingDemoRouter do
  use Phoenix.Router

  post("/:connection_id/acs", Relyra.TestingDemoController, :acs)
end

defmodule Relyra.TestingDemoController do
  use Phoenix.Controller, formats: [html: "Phoenix.HTML"]

  def acs(conn, _params) do
    conn
    |> Plug.Conn.assign(:current_user, %{email: "alice@example.com"})
    |> Phoenix.Controller.text("ok")
  end
end

defmodule Relyra.TestingDemoTest do
  use ExUnit.Case, async: false

  @endpoint Relyra.TestingDemoRouter

  test "adopters can write a tiny integration test" do
    conn = Phoenix.ConnTest.build_conn()
    fixture = Relyra.Testing.signed_success(name_id: "alice@example.com")

    assert {:ok, login_result} =
             Relyra.consume_response(
               fixture.response_xml,
               fixture.request_intent,
               Relyra.Testing.consume_opts(fixture)
             )

    assert login_result.principal.name_id == "alice@example.com"

    conn =
      Relyra.Testing.Phoenix.post_response(
        conn,
        @endpoint,
        "/#{fixture.connection.id}/acs",
        fixture
      )

    assert %Plug.Conn{assigns: %{current_user: %{email: "alice@example.com"}}} = conn
  end
end
