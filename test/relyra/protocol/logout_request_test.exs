defmodule Relyra.Protocol.LogoutRequestTest do
  use ExUnit.Case, async: true

  alias Relyra.Protocol.LogoutRequest
  alias Relyra.Security.XML.SaxyTree

  @connection %{
    idp_slo_url: "https://idp.example.com/slo",
    sp_entity_id: "https://sp.example.com/metadata"
  }

  test "build/3 returns required fields with deterministic shape" do
    opts = [
      name_id: "user@example.com",
      session_index: "session-123"
    ]

    assert {:ok, logout_request} = LogoutRequest.build(@connection, %{}, opts)

    assert is_binary(logout_request.id)
    assert logout_request.id != ""
    assert String.starts_with?(logout_request.id, "id_")

    assert logout_request.destination == @connection.idp_slo_url
    assert logout_request.issuer == @connection.sp_entity_id
    assert logout_request.name_id == "user@example.com"
    assert logout_request.session_index == "session-123"
    assert is_binary(logout_request.issue_instant)
  end

  test "from_parsed_doc/1 strictly traverses the SaxyTree structure to extract fields" do
    xml = """
    <samlp:LogoutRequest xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="id_123" Version="2.0" IssueInstant="2023-01-01T00:00:00Z" Destination="https://idp.example.com/slo">
      <saml:Issuer>https://sp.example.com/metadata</saml:Issuer>
      <saml:NameID Format="urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified">user@example.com</saml:NameID>
      <samlp:SessionIndex>session-123</samlp:SessionIndex>
    </samlp:LogoutRequest>
    """

    {:ok, tree} = SaxyTree.parse(xml)
    
    assert {:ok, req} = LogoutRequest.from_parsed_doc(tree)
    assert req.issuer == "https://sp.example.com/metadata"
    assert req.name_id == "user@example.com"
    assert req.session_index == "session-123"
    assert req.destination == "https://idp.example.com/slo"
    assert req.id == "id_123"
  end

  test "to_xml/1 generates a valid XML string" do
    req = %{
      id: "id_123",
      issue_instant: "2023-01-01T00:00:00Z",
      destination: "https://idp.example.com/slo",
      issuer: "https://sp.example.com/metadata",
      name_id: "user@example.com",
      name_id_format: "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified",
      session_index: "session-123"
    }

    xml = LogoutRequest.to_xml(req)
    assert String.contains?(xml, "ID=\"id_123\"")
    assert String.contains?(xml, "<saml:Issuer>https://sp.example.com/metadata</saml:Issuer>")
    assert String.contains?(xml, "<saml:NameID Format=\"urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified\">user@example.com</saml:NameID>")
    assert String.contains?(xml, "<samlp:SessionIndex>session-123</samlp:SessionIndex>")
  end
end
