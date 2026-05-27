defmodule Relyra.Phoenix.LoginTestRouter do
  use Phoenix.Router
  import Relyra.Phoenix.Router

  scope "/" do
    saml_routes()
  end
end

defmodule Relyra.Phoenix.LoginControllerTest do
  use ExUnit.Case, async: false
  import Phoenix.ConnTest

  alias Relyra.Phoenix.LoginTestRouter
  alias Relyra.TestSupport.FakeConnectionResolver

  @endpoint LoginTestRouter

  test "GET /:connection_id/login redirects to IdP" do
    conn = Phoenix.ConnTest.build_conn()

    # We pass opts via application env for simplicity in tests
    Application.put_env(:relyra, :connection_resolver, FakeConnectionResolver)
    Application.put_env(:relyra, :request_store, Relyra.RequestStore.ETS)

    # Ensure ETS table exists
    Relyra.RequestStore.ETS.ensure_table!()

    conn = get(conn, "/valid/login")

    assert redirected_to(conn) =~ "https://idp.example.com/sso"
    assert redirected_to(conn) =~ "SAMLRequest="
    assert redirected_to(conn) =~ "RelayState="
  end

  test "GET /:connection_id/login appends signed query verbatim" do
    conn = Phoenix.ConnTest.build_conn()

    Application.put_env(:relyra, :connection_resolver, FakeConnectionResolver)
    Application.put_env(:relyra, :request_store, Relyra.RequestStore.ETS)
    pem = File.read!("test/fixtures/security/authn_request_signing/golden_signing_key.pem")
    Application.put_env(:relyra, :sp_signing_key_pem, pem)

    on_exit(fn -> Application.delete_env(:relyra, :sp_signing_key_pem) end)

    Relyra.RequestStore.ETS.ensure_table!()

    conn = get(conn, "/valid_signed/login")
    url = redirected_to(conn)

    assert url =~ "https://idp.example.com/sso?"
    assert url =~ "Signature="
    assert url =~ "SigAlg="
    refute url =~ "Signature%3D"
  end

  test "GET /:connection_id/login with unknown connection returns error" do
    conn = Phoenix.ConnTest.build_conn()
    Application.put_env(:relyra, :connection_resolver, FakeConnectionResolver)

    conn = get(conn, "/invalid/login")
    assert conn.status == 400
    assert conn.resp_body =~ "SAML Login Error"
    assert conn.resp_body =~ "connection_unavailable"
  end
end
