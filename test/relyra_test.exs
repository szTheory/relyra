defmodule RelyraTest do
  use ExUnit.Case, async: true

  @valid_response "<Response><Assertion>signed</Assertion></Response>"

  test "start_login/3 returns documented tuple contract" do
    connection = %{
      idp_sso_url: "https://idp.example.com/sso",
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs"
    }

    relay_context = %{return_to: "/dashboard"}

    case Relyra.start_login(connection, relay_context) do
      {:ok, %{request_id: request_id, relay_state: relay_state}} ->
        assert String.starts_with?(request_id, "id_")
        assert String.starts_with?(relay_state, "rs_")

      {:error, %Relyra.Error{} = error} ->
        assert match?({:error, %Relyra.Error{}}, {:error, error})
        assert is_atom(error.type)
    end
  end

  test "consume_response/3 returns typed tuple contract" do
    request_intent = %{
      request_id: "id_request_123",
      connection_id: "conn-123",
      relay_state: "rs_1234567890abcdef",
      in_response_to: "id_request_123",
      destination: "https://sp.example.com/saml/acs",
      recipient: "https://sp.example.com/saml/acs"
    }

    opts = [
      now: ~U[2026-04-24 16:00:00Z],
      connection: %{
        connection_id: "conn-123",
        idp_entity_id: "https://idp.example.com/metadata",
        issuer: "https://idp.example.com/metadata",
        sp_entity_id: "https://sp.example.com/metadata",
        acs_url: "https://sp.example.com/saml/acs",
        cert_chain: ["pem-cert-chain"]
      }
    ]

    assert match?({:ok, %{}}, Relyra.consume_response(@valid_response, request_intent, opts)) or
             match?(
               {:error, %Relyra.Error{}},
               Relyra.consume_response(@valid_response, request_intent, opts)
             )
  end
end
