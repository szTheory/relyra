defmodule Relyra.Protocol.LogoutPipelineTest do
  use ExUnit.Case, async: true

  alias Relyra.Error
  alias Relyra.TestSupport.FakeIdP

  @issuer "https://idp.example.com/metadata"
  @connection %{idp_entity_id: @issuer, connection_id: "conn_123"}
  
  defmodule MockSessionAdapter do
    @behaviour Relyra.SessionAdapter

    @impl true
    def establish_session(_subject, _context, _opts), do: {:ok, %{}}
    @impl true
    def revoke_session(_subject, _session_index, _context, _opts), do: {:ok, %{}}
    @impl true
    def index_session(_session_index, _issuer, _context, _opts), do: {:ok, %{}}
    @impl true
    def terminate_by_session_index(session_index, issuer, context, opts) do
      # We send a message to the test process to assert the callback was invoked
      send(Keyword.get(opts, :test_pid), {:terminate_session, session_index, issuer, context})
      {:ok, %{}}
    end
  end

  setup do
    opts = [
      cert_chain: [FakeIdP.self_signed_cert_pem()],
      replay_store: Relyra.ReplayStore.ETS,
      session_adapter: MockSessionAdapter,
      test_pid: self()
    ]
    {:ok, opts: opts}
  end

  describe "IdP-initiated LogoutRequest via consume_logout/3 (redirect)" do
    test "success: validates signature, terminates session via adapter", %{opts: opts} do
      id = "req_#{Ecto.UUID.generate()}"
      xml = """
      <samlp:LogoutRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="#{id}" Version="2.0" IssueInstant="2026-05-27T00:00:00Z">
        <saml:Issuer>#{@issuer}</saml:Issuer>
        <saml:NameID>user@example.com</saml:NameID>
        <samlp:SessionIndex>session_abc123</samlp:SessionIndex>
      </samlp:LogoutRequest>
      """
      
      query = build_signed_redirect_query(xml, "SAMLRequest")
      
      assert {:ok, %{type: :request, message: req}} = 
               Relyra.consume_logout(@connection, query, opts ++ [binding: :redirect])
               
      assert req.id == id
      assert req.session_index == "session_abc123"
      
      # Verify session adapter was called
      assert_receive {:terminate_session, "session_abc123", @issuer, %{connection_id: "conn_123"}}
    end

    test "failure: tampered signature rejects message", %{opts: opts} do
      id = "req_#{Ecto.UUID.generate()}"
      xml = """
      <samlp:LogoutRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="#{id}" Version="2.0" IssueInstant="2026-05-27T00:00:00Z">
        <saml:Issuer>#{@issuer}</saml:Issuer>
        <saml:NameID>user@example.com</saml:NameID>
        <samlp:SessionIndex>session_abc123</samlp:SessionIndex>
      </samlp:LogoutRequest>
      """
      
      query = build_signed_redirect_query(xml, "SAMLRequest")
      tampered_query = String.replace(query, ~r/Signature=[^&]+/, "Signature=badbytes")
      
      assert {:error, %Error{type: :invalid_signature}} = 
               Relyra.consume_logout(@connection, tampered_query, opts ++ [binding: :redirect])
               
      refute_receive {:terminate_session, _, _, _}
    end

    test "failure: replayed request rejects message", %{opts: opts} do
      id = "req_#{Ecto.UUID.generate()}"
      xml = """
      <samlp:LogoutRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="#{id}" Version="2.0" IssueInstant="2026-05-27T00:00:00Z">
        <saml:Issuer>#{@issuer}</saml:Issuer>
        <saml:NameID>user@example.com</saml:NameID>
        <samlp:SessionIndex>session_abc123</samlp:SessionIndex>
      </samlp:LogoutRequest>
      """
      
      query = build_signed_redirect_query(xml, "SAMLRequest")
      
      # First consumption succeeds
      assert {:ok, _} = Relyra.consume_logout(@connection, query, opts ++ [binding: :redirect])
      
      # Second consumption fails with replay error
      assert {:error, %Error{type: :replayed_assertion}} = 
               Relyra.consume_logout(@connection, query, opts ++ [binding: :redirect])
    end
  end

  describe "SP-initiated LogoutResponse via consume_logout/3 (redirect)" do
    test "success: validates signature and returns response", %{opts: opts} do
      id = "res_#{Ecto.UUID.generate()}"
      xml = """
      <samlp:LogoutResponse xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="#{id}" InResponseTo="req_123" Version="2.0" IssueInstant="2026-05-27T00:00:00Z">
        <saml:Issuer>#{@issuer}</saml:Issuer>
        <samlp:Status>
          <samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/>
        </samlp:Status>
      </samlp:LogoutResponse>
      """
      
      query = build_signed_redirect_query(xml, "SAMLResponse")
      
      assert {:ok, %{type: :response, message: res}} = 
               Relyra.consume_logout(@connection, query, opts ++ [binding: :redirect])
               
      assert res.id == id
      assert res.status == "urn:oasis:names:tc:SAML:2.0:status:Success"
    end

    test "failure: replayed response rejects message", %{opts: opts} do
      id = "res_#{Ecto.UUID.generate()}"
      xml = """
      <samlp:LogoutResponse xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="#{id}" InResponseTo="req_123" Version="2.0" IssueInstant="2026-05-27T00:00:00Z">
        <saml:Issuer>#{@issuer}</saml:Issuer>
        <samlp:Status>
          <samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/>
        </samlp:Status>
      </samlp:LogoutResponse>
      """
      
      query = build_signed_redirect_query(xml, "SAMLResponse")
      
      assert {:ok, _} = Relyra.consume_logout(@connection, query, opts ++ [binding: :redirect])
      assert {:error, %Error{type: :replayed_assertion}} = 
               Relyra.consume_logout(@connection, query, opts ++ [binding: :redirect])
    end
  end

  describe "HTTP-POST binding edge cases" do
    test "failure: unsigned POST payload rejects immediately", %{opts: opts} do
      xml = """
      <samlp:LogoutRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="post_1" Version="2.0" IssueInstant="2026-05-27T00:00:00Z">
        <saml:Issuer>#{@issuer}</saml:Issuer>
        <saml:NameID>user@example.com</saml:NameID>
      </samlp:LogoutRequest>
      """
      
      # For POST binding without enveloped signature, verify/4 returns error.
      assert {:error, %Error{type: :missing_signature}} = 
               Relyra.consume_logout(@connection, xml, opts ++ [binding: :post])
    end
  end

  # Helper to build a signed redirect query
  defp build_signed_redirect_query(xml, param_name) do
    z = :zlib.open()
    :zlib.deflateInit(z, :default, :deflated, -15, 8, :default)
    deflated = :zlib.deflate(z, xml, :finish) |> IO.iodata_to_binary()
    :zlib.close(z)
    
    payload_b64 = Base.encode64(deflated) |> URI.encode_www_form()
    
    sig_alg = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
    sig_alg_enc = URI.encode_www_form(sig_alg)
    
    raw_signed_query = "#{param_name}=#{payload_b64}&SigAlg=#{sig_alg_enc}"
    
    {:RSAPrivateKey, _, _, _, _, _, _, _, _, _, _} = private_key = FakeIdP.keypair()
    signature_bytes = :public_key.sign(raw_signed_query, :sha256, private_key)
    signature_b64 = Base.encode64(signature_bytes) |> URI.encode_www_form()
    
    "#{raw_signed_query}&Signature=#{signature_b64}"
  end
end
