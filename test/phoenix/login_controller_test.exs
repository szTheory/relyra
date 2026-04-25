defmodule Relyra.Phoenix.FakeConnectionResolver do
  @behaviour Relyra.ConnectionResolver
  def resolve_connection(%{connection_id: "valid"}, _opts) do
    {:ok, %{
      id: "valid",
      idp_sso_url: "https://idp.example.com/sso",
      sp_entity_id: "https://sp.example.com",
      idp_entity_id: "https://idp.example.com",
      acs_url: "https://sp.example.com/acs"
    }}
  end
  def resolve_connection(_, _opts), do: {:error, Relyra.Error.new(:unknown_connection, "Unknown connection")}
end

defmodule Relyra.Phoenix.LoginTestRouter do
  use Phoenix.Router
  import Relyra.Phoenix.Router

  scope "/" do
    saml_routes()
  end
end

defmodule Relyra.Phoenix.LoginControllerTest do
  use ExUnit.Case, async: true
  import Phoenix.ConnTest

  alias Relyra.Phoenix.LoginTestRouter
  alias Relyra.Phoenix.FakeConnectionResolver

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

  test "GET /:connection_id/login with unknown connection returns error" do
    conn = Phoenix.ConnTest.build_conn()
    Application.put_env(:relyra, :connection_resolver, FakeConnectionResolver)
    
    conn = get(conn, "/invalid/login")
    assert conn.status == 400
    assert conn.resp_body =~ "SAML Login Error"
  end
end
