defmodule Relyra.Protocol.LogoutRequestTest do
  use ExUnit.Case, async: true

  alias Relyra.Protocol.LogoutRequest
  alias Relyra.Error

  describe "build/3" do
    test "generates map with required fields when connection and subject are valid" do
      connection = %{idp_slo_url: "https://idp.example.com/slo", sp_entity_id: "sp:example:com"}
      subject = %{name_id: "user@example.com"}

      assert {:ok, result} = LogoutRequest.build(connection, subject)
      assert result.destination == "https://idp.example.com/slo"
      assert result.issuer == "sp:example:com"
      assert result.name_id == "user@example.com"
      assert String.starts_with?(result.id, "id_")
      assert is_nil(result[:session_index])
    end

    test "includes session_index if provided in subject" do
      connection = %{idp_slo_url: "https://idp.example.com/slo", sp_entity_id: "sp:example:com"}
      subject = %{name_id: "user@example.com", session_index: "session_123"}

      assert {:ok, result} = LogoutRequest.build(connection, subject)
      assert result.session_index == "session_123"
    end

    test "returns error if missing required connection fields" do
      connection = %{idp_slo_url: "https://idp.example.com/slo"}
      subject = %{name_id: "user@example.com"}

      assert {:error, %Error{type: :logout_request_invalid}} =
               LogoutRequest.build(connection, subject)
    end

    test "returns error if subject is missing name_id" do
      connection = %{idp_slo_url: "https://idp.example.com/slo", sp_entity_id: "sp:example:com"}
      subject = %{}

      assert {:error, %Error{type: :logout_request_invalid}} =
               LogoutRequest.build(connection, subject)
    end
  end

  describe "to_xml/1" do
    test "generates valid XML string without session index" do
      data = %{
        id: "id_12345",
        issue_instant: "2026-05-08T00:00:00Z",
        destination: "https://idp.example.com/slo",
        issuer: "sp:example:com",
        name_id: "user@example.com"
      }

      xml = LogoutRequest.to_xml(data)
      assert xml =~ "<samlp:LogoutRequest"
      assert xml =~ ~s(ID="id_12345")
      assert xml =~ ~s(IssueInstant="2026-05-08T00:00:00Z")
      assert xml =~ ~s(Destination="https://idp.example.com/slo")
      assert xml =~ "<saml:Issuer>sp:example:com</saml:Issuer>"
      assert xml =~ "<saml:NameID>user@example.com</saml:NameID>"
      refute xml =~ "<samlp:SessionIndex>"
    end

    test "generates valid XML string with session index" do
      data = %{
        id: "id_12345",
        issue_instant: "2026-05-08T00:00:00Z",
        destination: "https://idp.example.com/slo",
        issuer: "sp:example:com",
        name_id: "user@example.com",
        session_index: "session_123"
      }

      xml = LogoutRequest.to_xml(data)
      assert xml =~ ~s(<samlp:SessionIndex>session_123</samlp:SessionIndex>)
    end
  end
end
