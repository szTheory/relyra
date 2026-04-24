defmodule Relyra.Protocol.AuthnRequestTest do
  use ExUnit.Case, async: true

  alias Relyra.Protocol.AuthnRequest

  @connection %{
    idp_sso_url: "https://idp.example.com/sso",
    sp_entity_id: "https://sp.example.com/metadata",
    acs_url: "https://sp.example.com/saml/acs"
  }

  test "build/3 returns required fields with deterministic shape" do
    assert {:ok, authn_request} = AuthnRequest.build(@connection, %{}, [])

    assert is_binary(authn_request.id)
    assert authn_request.id != ""
    assert String.starts_with?(authn_request.id, "id_")

    assert authn_request.destination == @connection.idp_sso_url
    assert authn_request.issuer == @connection.sp_entity_id
    assert authn_request.acs_url == @connection.acs_url
    assert authn_request.protocol_binding == "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
    assert is_binary(authn_request.issue_instant)
  end
end
