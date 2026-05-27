defmodule Relyra.Security.LogoutValidatorTest do
  use ExUnit.Case, async: true

  alias Relyra.Security.LogoutValidator
  alias Relyra.Error
  alias Relyra.TestSupport.FakeIdP

  @issuer "https://idp.example.com/metadata"
  @connection %{idp_entity_id: @issuer, connection_id: "conn_123"}
  
  setup do
    # Clear ETS store before each test if using ETS ReplayStore
    # We will use the Default ETS store for testing Replay
    opts = [
      cert_chain: [FakeIdP.self_signed_cert_pem()],
      replay_store: Relyra.ReplayStore.ETS
    ]
    {:ok, opts: opts}
  end

  describe "validate_logout_request/3 (redirect binding)" do
    test "success: strictly verifies signature, inflates payload, checks replay, returns typed struct", %{opts: opts} do
      id = "req_#{Ecto.UUID.generate()}"
      xml = """
      <samlp:LogoutRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="#{id}" Version="2.0" IssueInstant="2026-05-27T00:00:00Z">
        <saml:Issuer>#{@issuer}</saml:Issuer>
        <saml:NameID>user@example.com</saml:NameID>
        <samlp:SessionIndex>session_123</samlp:SessionIndex>
      </samlp:LogoutRequest>
      """
      
      query = build_signed_redirect_query(xml, "SAMLRequest")
      
      assert {:ok, %{id: _} = req} = LogoutValidator.validate_logout_request(query, @connection, opts ++ [binding: :redirect])
      assert req.id == id
      assert req.issuer == @issuer
      
      # Replay check: submitting the exact same request again should fail
      assert {:error, %Error{type: :replayed_assertion}} = LogoutValidator.validate_logout_request(query, @connection, opts ++ [binding: :redirect])
    end

    test "failure: invalid signature", %{opts: opts} do
      id = "req_#{Ecto.UUID.generate()}"
      xml = """
      <samlp:LogoutRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="#{id}" Version="2.0" IssueInstant="2026-05-27T00:00:00Z">
        <saml:Issuer>#{@issuer}</saml:Issuer>
        <saml:NameID>user@example.com</saml:NameID>
        <samlp:SessionIndex>session_123</samlp:SessionIndex>
      </samlp:LogoutRequest>
      """
      query = build_signed_redirect_query(xml, "SAMLRequest")
      # Tamper with signature
      tampered_query = String.replace(query, ~r/Signature=[^&]+/, "Signature=badbytes")
      
      assert {:error, %Error{type: :invalid_signature}} = LogoutValidator.validate_logout_request(tampered_query, @connection, opts ++ [binding: :redirect])
    end

    test "failure: issuer mismatch", %{opts: opts} do
      xml = """
      <samlp:LogoutRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="req_1" Version="2.0" IssueInstant="2026-05-27T00:00:00Z">
        <saml:Issuer>https://attacker.example.com</saml:Issuer>
        <saml:NameID>user@example.com</saml:NameID>
        <samlp:SessionIndex>session_123</samlp:SessionIndex>
      </samlp:LogoutRequest>
      """
      query = build_signed_redirect_query(xml, "SAMLRequest")
      
      assert {:error, %Error{type: :issuer_mismatch}} = LogoutValidator.validate_logout_request(query, @connection, opts ++ [binding: :redirect])
    end
  end

  describe "validate_logout_response/3 (redirect binding)" do
    test "success: returns typed LogoutResponse struct", %{opts: opts} do
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
      
      assert {:ok, %{id: _} = res} = LogoutValidator.validate_logout_response(query, @connection, opts ++ [binding: :redirect])
      assert res.id == id
      assert res.status == "urn:oasis:names:tc:SAML:2.0:status:Success"
      
      # Replay check
      assert {:error, %Error{type: :replayed_assertion}} = LogoutValidator.validate_logout_response(query, @connection, opts ++ [binding: :redirect])
    end

    test "failure: invalid status code returns error", %{opts: opts} do
      xml = """
      <samlp:LogoutResponse xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="res_1" Version="2.0" IssueInstant="2026-05-27T00:00:00Z">
        <saml:Issuer>#{@issuer}</saml:Issuer>
        <samlp:Status>
          <samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Responder"/>
        </samlp:Status>
      </samlp:LogoutResponse>
      """
      query = build_signed_redirect_query(xml, "SAMLResponse")
      
      assert {:error, %Error{type: :unsupported_status}} = LogoutValidator.validate_logout_response(query, @connection, opts ++ [binding: :redirect])
    end
  end

  describe "validate_logout_request/3 (post binding)" do
    test "failure: missing signature rejects immediately before replay", %{opts: opts} do
      xml = """
      <samlp:LogoutRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="post_1" Version="2.0" IssueInstant="2026-05-27T00:00:00Z">
        <saml:Issuer>#{@issuer}</saml:Issuer>
      </samlp:LogoutRequest>
      """
      
      # For POST binding without enveloped signature, verify/4 returns error.
      assert {:error, %Error{type: :missing_signature}} = LogoutValidator.validate_logout_request(xml, @connection, opts ++ [binding: :post])
    end
  end

  # Helper to build a signed redirect query (Deflated SAML payload + SigAlg + Signature)
  defp build_signed_redirect_query(xml, param_name) do
    # Deflate and base64
    z = :zlib.open()
    :zlib.deflateInit(z, :default, :deflated, -15, 8, :default)
    deflated = :zlib.deflate(z, xml, :finish) |> IO.iodata_to_binary()
    :zlib.close(z)
    
    payload_b64 = Base.encode64(deflated) |> URI.encode_www_form()
    
    sig_alg = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
    sig_alg_enc = URI.encode_www_form(sig_alg)
    
    raw_signed_query = "#{param_name}=#{payload_b64}&SigAlg=#{sig_alg_enc}"
    
    # Sign it using FakeIdP's keypair
    {:RSAPrivateKey, _, _, _, _, _, _, _, _, _, _} = private_key = FakeIdP.keypair()
    signature_bytes = :public_key.sign(raw_signed_query, :sha256, private_key)
    signature_b64 = Base.encode64(signature_bytes) |> URI.encode_www_form()
    
    "#{raw_signed_query}&Signature=#{signature_b64}"
  end
end
