defmodule Relyra.TestingTest do
  use ExUnit.Case, async: true

  alias Relyra.Connection
  alias Relyra.Testing
  alias Relyra.Testing.Fixture

  @request_intent %{
    request_id: "id_request_123",
    connection_id: "conn-123",
    relay_state: "rs_1234567890abcdef",
    in_response_to: "id_request_123",
    destination: "https://sp.example.com/saml/acs",
    recipient: "https://sp.example.com/saml/acs",
    issuer: "https://idp.example.com/metadata",
    sp_entity_id: "https://sp.example.com/metadata",
    acs_url: "https://sp.example.com/saml/acs"
  }

  @fixture %Fixture{
    response_xml: "<Response/>",
    encoded_response: "PFJlc3BvbnNlLz4=",
    cert_chain: ["test-cert-pem"],
    idp_certificates: ["test-cert-pem"],
    connection: %Connection{
      id: "conn-123",
      connection_id: "conn-123",
      idp_entity_id: "https://idp.example.com/metadata",
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs",
      idp_certificates: ["test-cert-pem"],
      cert_chain: ["test-cert-pem"]
    },
    request_intent: @request_intent,
    relay_state: "rs_1234567890abcdef",
    expected: {:ok, :verified}
  }

  test "fixture struct exposes the public testing data fields" do
    assert %Fixture{
             response_xml: "<Response/>",
             encoded_response: "PFJlc3BvbnNlLz4=",
             cert_chain: ["test-cert-pem"],
             idp_certificates: ["test-cert-pem"],
             connection: %Connection{},
             request_intent: @request_intent,
             relay_state: "rs_1234567890abcdef",
             expected: {:ok, :verified}
           } = @fixture
  end

  test "post_params/2 returns SAMLResponse and preserves non-empty relay state" do
    assert Testing.post_params(@fixture) == %{
             "SAMLResponse" => @fixture.encoded_response,
             "RelayState" => @fixture.relay_state
           }
  end

  test "post_params/2 omits nil or empty relay state values" do
    assert Testing.post_params(%Fixture{@fixture | relay_state: nil}) == %{
             "SAMLResponse" => @fixture.encoded_response
           }

    assert Testing.post_params(%Fixture{@fixture | relay_state: ""}) == %{
             "SAMLResponse" => @fixture.encoded_response
           }
  end

  test "post_params/2 supports custom SAML response and relay state keys" do
    assert Testing.post_params(@fixture,
             saml_response_key: :saml_response,
             relay_state_key: :relay_state
           ) == %{
             :saml_response => @fixture.encoded_response,
             :relay_state => @fixture.relay_state
           }
  end

  test "consume_opts/2 returns public testing adapters and fixture data" do
    opts = Testing.consume_opts(@fixture, now: ~U[2026-04-24 16:00:00Z])

    assert opts[:connection] == @fixture.connection
    assert opts[:resolved_connection] == @fixture.connection
    assert opts[:relay_state] == @fixture.relay_state
    assert opts[:request_intent] == @fixture.request_intent
    assert opts[:request_store] == Relyra.Testing.Adapters.RequestStore
    assert opts[:replay_store] == Relyra.Testing.Adapters.ReplayStore
    assert opts[:connection_resolver] == Relyra.Testing.Adapters.ConnectionResolver
    assert opts[:now] == ~U[2026-04-24 16:00:00Z]
  end

  test "signed_success/1 returns a real signed response that consume_response/3 verifies" do
    fixed_now = ~U[2026-04-24 16:00:00Z]
    name_id = "alice@example.com"

    fixture =
      Testing.signed_success(
        name_id: name_id,
        request_id: "id_request_public_success",
        relay_state: "rs_public_success",
        assertion_id: "assertion-public-success",
        not_before: "2026-04-24T15:55:00Z",
        not_on_or_after: "2026-04-24T16:05:00Z",
        subject_confirmation_not_on_or_after: "2026-04-24T16:05:00Z"
      )

    assert %Fixture{
             response_xml: response_xml,
             encoded_response: encoded_response,
             cert_chain: [cert_pem],
             idp_certificates: idp_certificates,
             connection: %Connection{} = connection,
             request_intent: %{request_id: "id_request_public_success"},
             relay_state: "rs_public_success",
             expected: {:ok, :verified}
           } = fixture

    assert idp_certificates == [cert_pem]
    assert connection.idp_certificates == [cert_pem]
    assert connection.cert_chain == [cert_pem]
    assert Base.decode64!(encoded_response) == response_xml
    assert response_xml =~ "<DigestValue>"
    assert response_xml =~ "<SignatureValue>"
    refute response_xml =~ "<KeyInfo"

    assert {:ok, login_result} =
             Relyra.consume_response(
               response_xml,
               fixture.request_intent,
               Testing.consume_opts(fixture, now: fixed_now)
             )

    assert login_result.principal.name_id == name_id
  end
end
