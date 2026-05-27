defmodule Relyra.Conformance.TestRequestStore do
  @moduledoc false

  @behaviour Relyra.RequestStore

  @impl true
  def put_intent(_relay_state, _intent, _opts), do: :ok

  @impl true
  def fetch_intent(_relay_state, _opts),
    do: {:error, Relyra.Error.new(:request_intent_not_found, "unused")}

  @impl true
  def consume_intent(_relay_state, _request_id, _opts), do: :ok
end

defmodule Relyra.Conformance.SPConformanceTest do
  use ExUnit.Case, async: true

  alias Relyra.Protocol.AuthnRequest
  alias Relyra.Protocol.Binding
  alias Relyra.Protocol.LogoutRequest
  alias Relyra.TestSupport.ConformanceFixtures
  alias Relyra.TestSupport.XmldsigSigner

  @moduletag :conformance

  @manifest_path "priv/conformance/sp_manifest.json"
  @fixed_now ~U[2026-04-24 16:00:00Z]

  test "executed manifest rows produce their declared expected_outcome" do
    manifest()
    |> ConformanceFixtures.executed_rows()
    |> Enum.each(fn row ->
      assert evaluate_row(row) == row["expected_outcome"]
    end)
  end

  test "unsupported and deferred rows stay explicit in coverage reporting" do
    non_executed =
      manifest()
      |> ConformanceFixtures.coverage_rows()
      |> Enum.reject(&(row_status(&1) in ["pass", "reject"]))

    assert non_executed != []

    Enum.each(non_executed, fn row ->
      assert row_status(row) in ["unsupported", "deferred"]
      assert is_binary(row["notes"])
      assert String.trim(row["notes"]) != ""
    end)
  end

  defp manifest do
    ConformanceFixtures.load_manifest!(@manifest_path)
  end

  defp evaluate_row(%{"id" => "sp-authn-request-build", "input" => %{"connection" => connection}}) do
    assert {:ok, authn_request} = AuthnRequest.build(connection, %{}, now: @fixed_now)
    assert authn_request.issue_instant == "2026-04-24T16:00:00Z"
    assert authn_request.protocol_binding == "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
    assert AuthnRequest.to_xml(authn_request) =~ "AssertionConsumerServiceURL"
    %{"result" => "ok"}
  end

  defp evaluate_row(%{"id" => "sp-authn-request-redirect-transport"} = row) do
    xml = ConformanceFixtures.fixture_xml(row)

    assert {:ok, encoded} = Binding.encode_redirect(xml, request_intent().relay_state)
    assert encoded["RelayState"] == request_intent().relay_state
    assert inflate_b64(encoded["SAMLRequest"]) == xml
    %{"result" => "ok"}
  end

  defp evaluate_row(%{"id" => "sp-post-response-decode"} = row) do
    xml = ConformanceFixtures.fixture_xml(row)
    params = %{"SAMLResponse" => Base.encode64(xml, padding: false), "RelayState" => "relay-post"}

    assert {:ok, %{response_xml: ^xml, relay_state: "relay-post"}} = Binding.decode_post(params)
    %{"result" => "ok"}
  end

  defp evaluate_row(%{"id" => "sp-response-consume-pass"} = row) do
    assert {:ok, login_result} =
             Relyra.consume_response(
               genuinely_signed_fixture_xml(row),
               request_intent(),
               consume_opts(now: @fixed_now)
             )

    assert login_result.in_response_to == "id_request_123"
    assert login_result.issuer == "https://idp.example.com/metadata"
    %{"result" => "ok"}
  end

  defp evaluate_row(%{"id" => "sp-idp-initiated-accept"} = row) do
    assert {:ok, login_result} =
             Relyra.consume_response(
               genuinely_signed_fixture_xml(row),
               consume_opts(
                 connection: Map.put(connection(), :allow_idp_initiated, true),
                 resolved_connection: Map.put(connection(), :allow_idp_initiated, true),
                 relay_state: nil,
                 request_intent: nil,
                 now: @fixed_now
               )
             )

    assert login_result.in_response_to == nil
    assert login_result.connection.allow_idp_initiated == true
    %{"result" => "ok"}
  end

  defp evaluate_row(%{
         "id" => "sp-logout-request-build",
         "input" => %{"connection" => connection, "subject" => subject}
       }) do
    subject = Map.put(subject, :session_index, Map.get(subject, "session_index"))

    assert {:ok, logout_request} = LogoutRequest.build(connection, subject, now: @fixed_now)
    assert logout_request.issue_instant == "2026-04-24T16:00:00Z"

    assert LogoutRequest.to_xml(logout_request) =~
             "<samlp:SessionIndex>session_123</samlp:SessionIndex>"

    %{"result" => "ok"}
  end

  defp evaluate_row(%{"id" => "sp-logout-request-redirect-transport"} = row) do
    xml = ConformanceFixtures.fixture_xml(row)

    assert {:ok, encoded} = Binding.encode_redirect(xml, "relay-logout")
    assert inflate_b64(encoded["SAMLRequest"]) == xml
    %{"result" => "ok"}
  end

  defp evaluate_row(%{"id" => "sp-logout-response-redirect-decode"} = row) do
    xml = ConformanceFixtures.fixture_xml(row)

    params = %{
      "SAMLResponse" => Base.encode64(xml, padding: false),
      "RelayState" => "relay-logout"
    }

    assert {:ok, %{response_xml: ^xml, relay_state: "relay-logout"}} =
             Binding.decode_redirect(params)

    %{"result" => "ok"}
  end

  defp evaluate_row(row) do
    assert {:error, %Relyra.Error{type: type}} =
             Relyra.consume_response(
               genuinely_signed_fixture_xml(row),
               request_intent(),
               consume_opts(now: @fixed_now)
             )

    %{"result" => "error", "type" => Atom.to_string(type)}
  end

  defp row_status(row), do: Map.get(row, "status")

  # Plan 04 triage: Phase 29 wires real cryptographic XMLDSig verification, so a
  # conformance row that drives the CONSUME path must carry a GENUINE signature
  # to reach its declared stage. The reject rows (destination / audience /
  # recipient / time) all fail AFTER the crypto step, so they too must pass
  # crypto first to assert their declared rejection for the right reason; the
  # pass rows must verify {:ok} for the right reason. Fixtures with no signed
  # Reference are returned verbatim (they reject before crypto).
  defp genuinely_signed_fixture_xml(row) do
    xml = ConformanceFixtures.fixture_xml(row)

    if xml =~ ~r/<Reference\s+URI="#/ do
      %{response_xml: signed_xml} = XmldsigSigner.sign_response(xml)
      signed_xml
    else
      xml
    end
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
      acs_url: "https://sp.example.com/saml/acs"
    }
  end

  # Plan 04 triage: the connection carries the GENUINE FakeIdP-derived cert so
  # the real crypto step verifies the (now genuinely-signed) conformance
  # fixtures, instead of the structure-only "pem-cert-chain" placeholder.
  defp connection do
    %{
      connection_id: "conn-123",
      idp_entity_id: "https://idp.example.com/metadata",
      issuer: "https://idp.example.com/metadata",
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs",
      cert_chain: [XmldsigSigner.self_signed_cert_pem()]
    }
  end

  defp consume_opts(extra_opts) do
    Keyword.merge(
      [
        connection: connection(),
        resolved_connection: connection(),
        relay_state: request_intent().relay_state,
        request_intent: request_intent(),
        request_store: Relyra.Conformance.TestRequestStore,
        replay_store_consume: fn _replay_key, _metadata, _opts -> :ok end
      ],
      extra_opts
    )
  end

  defp inflate_b64(b64) do
    {:ok, deflated} = Base.decode64(b64, padding: false)
    z = :zlib.open()

    try do
      :ok = :zlib.inflateInit(z, -15)
      :zlib.inflate(z, deflated) |> IO.iodata_to_binary()
    after
      :zlib.close(z)
    end
  end
end
