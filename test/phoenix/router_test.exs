defmodule Relyra.Phoenix.TestRouter do
  use Phoenix.Router
  import Relyra.Phoenix.Router

  pipeline :browser do
    plug(:accepts, ["html"])
  end

  scope "/" do
    pipe_through(:browser)
    saml_routes()
  end
end

defmodule Relyra.Phoenix.RouterTest do
  use ExUnit.Case, async: true
  import Phoenix.ConnTest

  alias Relyra.Phoenix.TestRouter

  @endpoint TestRouter

  test "saml_routes/0 registers expected routes" do
    routes = TestRouter.__routes__()

    paths = Enum.map(routes, fn r -> r.path end)

    assert "/:connection_id/metadata" in paths
    assert "/:connection_id/login" in paths
    assert "/:connection_id/acs" in paths
  end

  test "metadata route is accessible" do
    conn = Phoenix.ConnTest.build_conn()
    conn = get(conn, "/my-conn/metadata")
    assert conn.status == 400
    assert conn.resp_body =~ "SAML Metadata Error"
  end
end
