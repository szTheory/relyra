defmodule Relyra.Protocol.LogoutResponseTest do
  use ExUnit.Case, async: true

  alias Relyra.Protocol.LogoutResponse
  alias Relyra.Security.XML.SaxyTree

  @connection %{
    idp_slo_url: "https://idp.example.com/slo",
    sp_entity_id: "https://sp.example.com/metadata"
  }

  test "build/3 returns required fields with deterministic shape" do
    opts = [
      in_response_to: "id_123",
      status: "urn:oasis:names:tc:SAML:2.0:status:Success"
    ]

    assert {:ok, logout_response} = LogoutResponse.build(@connection, %{}, opts)

    assert is_binary(logout_response.id)
    assert logout_response.id != ""
    assert String.starts_with?(logout_response.id, "id_")

    assert logout_response.destination == @connection.idp_slo_url
    assert logout_response.issuer == @connection.sp_entity_id
    assert logout_response.in_response_to == "id_123"
    assert logout_response.status == "urn:oasis:names:tc:SAML:2.0:status:Success"
    assert is_binary(logout_response.issue_instant)
  end

  test "from_parsed_doc/1 strictly traverses the SaxyTree structure to extract fields" do
    xml = """
    <samlp:LogoutResponse xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="id_456" InResponseTo="id_123" Version="2.0" IssueInstant="2023-01-01T00:00:00Z" Destination="https://idp.example.com/slo">
      <saml:Issuer>https://sp.example.com/metadata</saml:Issuer>
      <samlp:Status>
        <samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success" />
      </samlp:Status>
    </samlp:LogoutResponse>
    """

    {:ok, tree} = SaxyTree.parse(xml)
    
    assert {:ok, resp} = LogoutResponse.from_parsed_doc(tree)
    assert resp.issuer == "https://sp.example.com/metadata"
    assert resp.destination == "https://idp.example.com/slo"
    assert resp.id == "id_456"
    assert resp.in_response_to == "id_123"
    assert resp.status == "urn:oasis:names:tc:SAML:2.0:status:Success"
  end

  test "to_xml/1 generates a valid XML string" do
    resp = %{
      id: "id_456",
      in_response_to: "id_123",
      issue_instant: "2023-01-01T00:00:00Z",
      destination: "https://idp.example.com/slo",
      issuer: "https://sp.example.com/metadata",
      status: "urn:oasis:names:tc:SAML:2.0:status:Success"
    }

    xml = LogoutResponse.to_xml(resp)
    assert String.contains?(xml, "ID=\"id_456\"")
    assert String.contains?(xml, "InResponseTo=\"id_123\"")
    assert String.contains?(xml, "<saml:Issuer>https://sp.example.com/metadata</saml:Issuer>")
    assert String.contains?(xml, "<samlp:StatusCode Value=\"urn:oasis:names:tc:SAML:2.0:status:Success\"")
  end
  
  test "validate_issuer/2 delegates to Relyra.Protocol.Response or works correctly" do
    assert :ok == LogoutResponse.validate_issuer("issuer", "issuer")
    assert {:error, _} = LogoutResponse.validate_issuer("actual", "expected")
  end
end
