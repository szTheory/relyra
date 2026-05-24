defmodule Relyra.Telemetry.TestRequestStore do
  @moduledoc false

  @behaviour Relyra.RequestStore

  @impl true
  def put_intent(_relay_state, _intent, _opts), do: :ok

  @impl true
  def fetch_intent(_relay_state, _opts), do: {:error, :not_used}

  @impl true
  def consume_intent(_relay_state, _request_id, _opts), do: :ok
end

defmodule Relyra.Telemetry.TestReplayStore do
  @moduledoc false

  @behaviour Relyra.ReplayStore

  @impl true
  def consume_replay_key(_replay_key, _metadata, _opts), do: :ok
end

defmodule Relyra.Telemetry.TestUserMapper do
  @moduledoc false

  @behaviour Relyra.UserMapper

  @impl true
  def map_attributes(_assertion, _connection, _opts), do: {:ok, %{user_id: "user-1"}}
end

defmodule Relyra.Telemetry.TestSessionAdapter do
  @moduledoc false

  @behaviour Relyra.SessionAdapter

  @impl true
  def establish_session(_subject, _context, _opts), do: {:ok, %{session_id: "session-1"}}

  @impl true
  def revoke_session(_subject, _session_index, _context, _opts), do: {:ok, :revoked}
end

defmodule Relyra.TelemetryTest do
  use ExUnit.Case, async: false

  @success_status "urn:oasis:names:tc:SAML:2.0:status:Success"
  @rsa_sha256 "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
  @digest_sha256 "http://www.w3.org/2001/04/xmlenc#sha256"

  test "span emits start, stop, and exception telemetry with duration_ms" do
    handler_id = attach_telemetry([:custom])

    assert_raise RuntimeError, "boom", fn ->
      Relyra.Telemetry.span([:custom], %{connection_id: "conn-123"}, fn ->
        raise "boom"
      end)
    end

    assert_receive {:telemetry_event, [:relyra, :saml, :custom, :start],
                    %{system_time: _system_time}, %{connection_id: "conn-123"}},
                   100

    assert_receive {:telemetry_event, [:relyra, :saml, :custom, :exception],
                    %{duration_ms: duration_ms}, metadata},
                   100

    assert is_integer(duration_ms)
    assert duration_ms >= 0
    assert metadata.kind == :error
    assert metadata.reason == "boom"

    refute_receive {:telemetry_event, _, _, _}, 50
    :telemetry.detach(handler_id)
  end

  test "start_login emits login and authn_request telemetry" do
    handler_id = attach_telemetry([:login, :authn_request])

    assert {:ok, _login_result} =
             Relyra.start_login(connection(), relay_context(),
               request_store: Relyra.Telemetry.TestRequestStore
             )

    assert_receive {:telemetry_event, [:relyra, :saml, :login, :start], %{system_time: _},
                    %{connection_id: "conn-123", binding: :redirect, flow: :sp_initiated}},
                   100

    assert_receive {:telemetry_event, [:relyra, :saml, :authn_request, :start], %{system_time: _},
                    %{binding: :redirect, flow: :sp_initiated}},
                   100

    assert_receive {:telemetry_event, [:relyra, :saml, :authn_request, :stop],
                    %{duration_ms: duration_ms}, metadata},
                   100

    assert is_integer(duration_ms)
    assert duration_ms >= 0
    assert metadata.outcome == :ok
    assert metadata.xml_bytes > 0
    assert metadata.base64_bytes > 0
    assert is_integer(metadata.request_store_latency_ms)
    assert metadata.request_store_latency_ms >= 0

    assert_receive {:telemetry_event, [:relyra, :saml, :login, :stop],
                    %{duration_ms: duration_ms}, %{outcome: :ok}},
                   100

    assert is_integer(duration_ms)
    assert duration_ms >= 0

    refute_receive {:telemetry_event, _, _, _}, 50
    :telemetry.detach(handler_id)
  end

  test "metadata refresh telemetry emits redaction-safe identifiers and counts only" do
    handler_id = attach_telemetry([[:metadata, :refresh]])

    assert {:ok, :refreshed} =
             Relyra.Telemetry.span(
               [:metadata, :refresh],
               %{connection_id: "conn-123", source_kind: :remote_url, trigger: :manual_refresh},
               fn ->
                 {{:ok, :refreshed},
                  %{outcome: :ok, certificate_count: 2, metadata_source_id: "source-1"}}
               end
             )

    assert_receive {:telemetry_event, [:relyra, :saml, :metadata, :refresh, :start],
                    %{system_time: _},
                    %{
                      connection_id: "conn-123",
                      source_kind: :remote_url,
                      trigger: :manual_refresh
                    }},
                   100

    assert_receive {:telemetry_event, [:relyra, :saml, :metadata, :refresh, :stop],
                    %{duration_ms: duration_ms},
                    %{outcome: :ok, certificate_count: 2, metadata_source_id: "source-1"}},
                   100

    assert is_integer(duration_ms)
    assert duration_ms >= 0

    refute_receive {:telemetry_event, _, _, _}, 50
    :telemetry.detach(handler_id)
  end

  test "ACS decode and consume flow emits response, signature, replay, user, and session telemetry" do
    handler_id =
      attach_telemetry([
        [:response, :decode],
        [:response, :validate],
        [:signature, :verify],
        [:replay, :check],
        [:user, :map],
        [:session, :establish]
      ])

    response_xml = response_xml()
    request_intent = request_intent()

    assert {:ok, decoded} =
             Relyra.Protocol.Binding.decode_post(%{
               "SAMLResponse" => encoded_response(response_xml),
               "RelayState" => request_intent.relay_state
             })

    assert decoded.response_xml == response_xml

    assert_receive {:telemetry_event, [:relyra, :saml, :response, :decode, :start],
                    %{system_time: _}, %{binding: :post, flow: :sp_initiated}},
                   100

    assert_receive {:telemetry_event, [:relyra, :saml, :response, :decode, :stop],
                    %{duration_ms: duration_ms},
                    %{outcome: :ok, xml_bytes: xml_bytes, base64_bytes: base64_bytes}},
                   100

    assert is_integer(duration_ms)
    assert duration_ms >= 0
    assert xml_bytes == byte_size(response_xml)
    assert base64_bytes == byte_size(encoded_response(response_xml))

    assert {:ok, login_result} =
             Relyra.consume_response(
               response_xml,
               request_intent,
               connection: connection(),
               relay_state: request_intent.relay_state,
               request_store: Relyra.Telemetry.TestRequestStore,
               replay_store: Relyra.Telemetry.TestReplayStore,
               now: ~U[2026-04-24 16:00:00Z]
             )

    assert is_map(login_result)

    assert_receive {:telemetry_event, [:relyra, :saml, :response, :validate, :start],
                    %{system_time: _}, %{flow: :sp_initiated, connection_id: "conn-123"}},
                   100

    assert_receive {:telemetry_event, [:relyra, :saml, :signature, :verify, :start],
                    %{system_time: _}, %{flow: :sp_initiated, connection_id: "conn-123"}},
                   100

    assert_receive {:telemetry_event, [:relyra, :saml, :signature, :verify, :stop],
                    %{duration_ms: duration_ms},
                    %{
                      outcome: :ok,
                      signature_algorithm: @rsa_sha256,
                      digest_algorithm: @digest_sha256
                    }},
                   100

    assert is_integer(duration_ms)
    assert duration_ms >= 0

    assert_receive {:telemetry_event, [:relyra, :saml, :response, :validate, :stop],
                    %{duration_ms: duration_ms}, %{outcome: :ok, assertion_count: 1}},
                   100

    assert is_integer(duration_ms)
    assert duration_ms >= 0

    assert_receive {:telemetry_event, [:relyra, :saml, :replay, :check, :start],
                    %{system_time: _},
                    %{
                      connection_id: "conn-123",
                      issuer: "https://idp.example.com/metadata",
                      assertion_id: "assertion-1"
                    }},
                   100

    assert_receive {:telemetry_event, [:relyra, :saml, :replay, :check, :stop],
                    %{duration_ms: duration_ms},
                    %{outcome: :ok, replay_store_latency_ms: replay_store_latency_ms}},
                   100

    assert is_integer(duration_ms)
    assert duration_ms >= 0
    assert is_integer(replay_store_latency_ms)
    assert replay_store_latency_ms >= 0

    assert {:ok, mapped_user} =
             Relyra.UserMapper.map_attributes(
               %{attributes: %{"email" => ["user@example.com"], "groups" => ["dev"]}},
               connection(),
               user_mapper: Relyra.Telemetry.TestUserMapper
             )

    assert mapped_user == %{user_id: "user-1"}

    assert_receive {:telemetry_event, [:relyra, :saml, :user, :map, :start], %{system_time: _},
                    %{flow: :sp_initiated}},
                   100

    assert_receive {:telemetry_event, [:relyra, :saml, :user, :map, :stop],
                    %{duration_ms: duration_ms}, %{outcome: :ok, attribute_count: 2}},
                   100

    assert is_integer(duration_ms)
    assert duration_ms >= 0

    assert {:ok, _session_result} =
             Relyra.SessionAdapter.establish_session(
               mapped_user,
               %{connection_id: "conn-123"},
               session_adapter: Relyra.Telemetry.TestSessionAdapter
             )

    assert_receive {:telemetry_event, [:relyra, :saml, :session, :establish, :start],
                    %{system_time: _}, %{flow: :sp_initiated, connection_id: "conn-123"}},
                   100

    assert_receive {:telemetry_event, [:relyra, :saml, :session, :establish, :stop],
                    %{duration_ms: duration_ms}, %{outcome: :ok}},
                   100

    assert is_integer(duration_ms)
    assert duration_ms >= 0

    refute_receive {:telemetry_event, _, _, _}, 50
    :telemetry.detach(handler_id)
  end

  defp attach_telemetry(event_prefixes) do
    handler_id = {__MODULE__, make_ref()}

    event_names =
      Enum.flat_map(event_prefixes, fn prefix ->
        [
          [:relyra, :saml | List.wrap(prefix)] ++ [:start],
          [:relyra, :saml | List.wrap(prefix)] ++ [:stop],
          [:relyra, :saml | List.wrap(prefix)] ++ [:exception]
        ]
      end)

    :ok = :telemetry.attach_many(handler_id, event_names, &__MODULE__.handle_event/4, self())
    handler_id
  end

  def handle_event(event_name, measurements, metadata, pid) do
    send(pid, {:telemetry_event, event_name, measurements, metadata})
  end

  # Plan 04 triage: carries the GENUINE FakeIdP-derived cert so the now-real
  # crypto step verifies the genuinely-signed response_xml/0 and the
  # `signature.verify` telemetry emits `outcome: :ok` for the right reason.
  defp connection do
    %{
      connection_id: "conn-123",
      organization_id: "org-456",
      provider_preset: "okta",
      idp_entity_id: "https://idp.example.com/metadata",
      issuer: "https://idp.example.com/metadata",
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs",
      idp_sso_url: "https://idp.example.com/sso",
      cert_chain: [Relyra.TestSupport.XmldsigSigner.self_signed_cert_pem()]
    }
  end

  defp relay_context do
    %{connection_id: "conn-123", return_to: "/account"}
  end

  defp request_intent do
    %{
      request_id: "id_request_123",
      connection_id: "conn-123",
      relay_state: "rs_1234567890abcdef",
      in_response_to: "id_request_123",
      destination: "https://sp.example.com/saml/acs",
      recipient: "https://sp.example.com/saml/acs",
      issuer: "https://idp.example.com/metadata",
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs",
      return_to: "/account"
    }
  end

  # Plan 04 triage: a GENUINELY-signed success Response (real ds:DigestValue +
  # ds:SignatureValue from FakeIdP's keypair via the reusable D-11 signer) so the
  # consume flow passes the now-cryptographic verify step and emits the success
  # telemetry this test asserts. Whitespace-free so the digest canonicalizes over
  # the exact emitted bytes.
  defp response_xml do
    structure_only =
      "<Response Destination=\"https://sp.example.com/saml/acs\" InResponseTo=\"id_request_123\" ConnectionId=\"conn-123\">" <>
        "<Issuer>https://idp.example.com/metadata</Issuer>" <>
        "<Status><StatusCode Value=\"#{@success_status}\"/></Status>" <>
        "<Assertion ID=\"assertion-1\">" <>
        "<Issuer>https://idp.example.com/metadata</Issuer>" <>
        "<Subject>" <>
        "<NameID>user@example.com</NameID>" <>
        "<SubjectConfirmation>" <>
        "<SubjectConfirmationData Recipient=\"https://sp.example.com/saml/acs\" NotOnOrAfter=\"2026-04-24T16:05:00Z\"/>" <>
        "</SubjectConfirmation>" <>
        "</Subject>" <>
        "<Conditions NotBefore=\"2026-04-24T15:58:00Z\" NotOnOrAfter=\"2026-04-24T16:05:00Z\">" <>
        "<AudienceRestriction><Audience>https://sp.example.com/metadata</Audience></AudienceRestriction>" <>
        "</Conditions>" <>
        "</Assertion>" <>
        "<Signature>" <>
        "<SignedInfo>" <>
        "<SignatureMethod Algorithm=\"#{@rsa_sha256}\"/>" <>
        "<Reference URI=\"#assertion-1\">" <>
        "<DigestMethod Algorithm=\"#{@digest_sha256}\"/>" <>
        "</Reference>" <>
        "</SignedInfo>" <>
        "</Signature>" <>
        "</Response>"

    %{response_xml: signed_xml} = Relyra.TestSupport.XmldsigSigner.sign_response(structure_only)
    signed_xml
  end

  defp encoded_response(xml), do: Base.encode64(xml, padding: false)
end
