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

  alias Relyra.TestSupport.XmldsigSigner
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

    def revoke_session(_subject, _session_index, _context, _opts) do
      {:ok, :revoked}
    end

    def index_session(_connection, _session_index, _user_id, _opts), do: :ok
    def terminate_by_session_index(_connection, _session_index, _issuer, _opts), do: :ok
  end

  # Plan 04 triage: a connection resolver that returns the GENUINE
  # FakeIdP-derived cert (instead of the shared resolver's "fake-cert"
  # placeholder), so the now-cryptographic verify step accepts the
  # genuinely-signed @valid_xml in the success test.
  defmodule GenuineCertConnectionResolver do
    @behaviour Relyra.ConnectionResolver
    alias Relyra.Connection

    def resolve_connection(%{connection_id: "valid"}, _opts) do
      cert = Relyra.TestSupport.XmldsigSigner.self_signed_cert_pem()

      {:ok,
       %Connection{
         id: "valid",
         connection_id: "valid",
         idp_sso_url: "https://idp.example.com/sso",
         sp_entity_id: "https://sp.example.com",
         idp_entity_id: "https://idp.example.com",
         acs_url: "https://sp.example.com/acs",
         idp_certificates: [cert],
         cert_chain: [cert]
       }}
    end

    def resolve_connection(_, _opts) do
      {:error,
       Relyra.Error.new(:connection_unavailable, "Unknown connection", %{
         reason: :not_found,
         operation: :resolve_connection
       })}
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

    # Plan 04 triage: real cryptographic XMLDSig verification now runs, so the
    # ACS success path needs a GENUINELY-signed Response verified against the
    # genuine FakeIdP-derived cert (returned by GenuineCertConnectionResolver).
    %{response_xml: signed_xml} = XmldsigSigner.sign_response(@valid_xml)

    Application.put_env(:relyra, :connection_resolver, GenuineCertConnectionResolver)
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
        "SAMLResponse" => Base.encode64(signed_xml),
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
