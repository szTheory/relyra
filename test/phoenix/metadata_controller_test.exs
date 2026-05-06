defmodule Relyra.Phoenix.MetadataTestRouter do
  use Phoenix.Router
  import Relyra.Phoenix.Router

  scope "/" do
    saml_routes()
  end
end

defmodule Relyra.Phoenix.MetadataControllerTest do
  use ExUnit.Case, async: false
  import Phoenix.ConnTest

  alias Relyra.Phoenix.MetadataTestRouter
  alias Relyra.TestSupport.FakeConnectionResolver

  @endpoint MetadataTestRouter

  test "GET /:connection_id/metadata renders metadata from the canonical resolver snapshot" do
    Application.put_env(:relyra, :connection_resolver, FakeConnectionResolver)

    conn =
      Phoenix.ConnTest.build_conn()
      |> get("/valid/metadata")

    assert conn.status == 200
    assert conn.resp_body =~ ~s(entityID="https://sp.example.com")
    assert conn.resp_body =~ ~s(Location="https://sp.example.com/acs")
    refute conn.resp_body =~ "fake-cert"
    refute conn.resp_body =~ "https://idp.example.com/metadata"
  end

  test "GET /:connection_id/metadata preserves typed resolver failures" do
    Application.put_env(:relyra, :connection_resolver, FakeConnectionResolver)

    conn =
      Phoenix.ConnTest.build_conn()
      |> get("/invalid/metadata")

    assert conn.status == 400
    assert conn.resp_body =~ "SAML Metadata Error"
    assert conn.resp_body =~ "connection_unavailable"
  end
end
