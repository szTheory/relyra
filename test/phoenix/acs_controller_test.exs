defmodule Relyra.Phoenix.ACSTestRouter do
  use Phoenix.Router
  import Relyra.Phoenix.Router

  scope "/" do
    saml_routes()
  end
end

defmodule Relyra.Phoenix.ACSControllerTest do
  use ExUnit.Case, async: false
  import Phoenix.ConnTest

  alias Relyra.TestSupport.FakeConnectionResolver
  alias Relyra.Phoenix.ACSTestRouter

  defmodule FakeUserMapper do
    @behaviour Relyra.UserMapper
    def map_attributes(result, _connection, _opts) do
      {:ok, %{id: 1, email: "user@example.com", name_id: result.principal.name_id}}
    end
  end

  defmodule FakeSessionAdapter do
    @behaviour Relyra.SessionAdapter
    def establish_session(user, _result, _opts) do
      {:ok, %{user_id: user.id}}
    end
  end

  @endpoint ACSTestRouter

  @valid_xml """
  <Response xmlns="urn:oasis:names:tc:SAML:2.0:protocol" Destination="https://sp.example.com/acs" InResponseTo="id_123" ConnectionId="valid">
    <Issuer xmlns="urn:oasis:names:tc:SAML:2.0:assertion">https://idp.example.com</Issuer>
    <Status><StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/></Status>
    <Assertion xmlns="urn:oasis:names:tc:SAML:2.0:assertion" ID="assertion_123">
      <Issuer>https://idp.example.com</Issuer>
      <Subject><NameID>user@example.com</NameID><SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer"><SubjectConfirmationData Recipient="https://sp.example.com/acs" NotOnOrAfter="2099-01-01T00:00:00Z"/></SubjectConfirmation></Subject>
      <Conditions NotBefore="2000-01-01T00:00:00Z" NotOnOrAfter="2099-01-01T00:00:00Z"><AudienceRestriction><Audience>https://sp.example.com</Audience></AudienceRestriction></Conditions>
    </Assertion>
    <Signature xmlns="http://www.w3.org/2000/09/xmldsig#">
      <SignedInfo><SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"/><Reference URI="#assertion_123"><DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256"/></Reference></SignedInfo>
    </Signature>
  </Response>
  """

  test "POST /:connection_id/acs success" do
    conn = Phoenix.ConnTest.build_conn()

    request_intent = %{
      request_id: "id_123",
      in_response_to: "id_123",
      relay_state: "rs_123",
      connection_id: "valid",
      sp_entity_id: "https://sp.example.com",
      acs_url: "https://sp.example.com/acs",
      return_to: "/welcome",
      expires_at: DateTime.utc_now() |> DateTime.add(3600)
    }

    Application.put_env(:relyra, :connection_resolver, FakeConnectionResolver)
    Application.put_env(:relyra, :request_store, Relyra.RequestStore.ETS)
    Application.put_env(:relyra, :replay_store, Relyra.ReplayStore.ETS)
    Application.put_env(:relyra, :user_mapper, FakeUserMapper)
    Application.put_env(:relyra, :session_adapter, FakeSessionAdapter)

    Relyra.RequestStore.ETS.ensure_table!()
    Relyra.ReplayStore.ETS.ensure_table!()

    # Pre-populate request store
    Relyra.RequestStore.ETS.put_intent("rs_123", request_intent)

    conn =
      post(conn, "/valid/acs", %{
        "SAMLResponse" => Base.encode64(@valid_xml),
        "RelayState" => "rs_123"
      })

    assert redirected_to(conn) == "/welcome"
  end

  test "POST /:connection_id/acs with missing params returns error" do
    conn = Phoenix.ConnTest.build_conn()
    conn = post(conn, "/valid/acs", %{})
    assert conn.status == 400
    assert conn.resp_body =~ "SAML Authentication Error"
  end
end
