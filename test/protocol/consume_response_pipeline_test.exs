defmodule Relyra.Protocol.TestRequestStore do
  @moduledoc false

  @behaviour Relyra.RequestStore

  alias Relyra.Error

  @impl true
  def put_intent(_relay_state, _intent, _opts), do: :ok

  @impl true
  def fetch_intent(relay_state, opts) when is_binary(relay_state) and is_list(opts) do
    case Keyword.get(opts, :request_store_fetch) do
      fun when is_function(fun, 2) ->
        fun.(relay_state, opts)

      _ ->
        case Keyword.get(opts, :request_intent) do
          intent when is_map(intent) ->
            {:ok, intent}

          _ ->
            {:error,
             Error.new(
               :request_intent_not_found,
               "No request intent present in test opts",
               %{relay_state: relay_state}
             )}
        end
    end
  end

  @impl true
  def consume_intent(relay_state, request_id, opts)
      when is_binary(relay_state) and is_binary(request_id) and is_list(opts) do
    case Keyword.get(opts, :request_store_consume) do
      fun when is_function(fun, 3) -> fun.(relay_state, request_id, opts)
      _ -> :ok
    end
  end
end

defmodule Relyra.Protocol.TestReplayStore do
  @moduledoc false

  @behaviour Relyra.ReplayStore

  @impl true
  def consume_replay_key(replay_key, metadata, opts)
      when is_binary(replay_key) and is_map(metadata) and is_list(opts) do
    case Keyword.get(opts, :replay_store_consume) do
      fun when is_function(fun, 3) -> fun.(replay_key, metadata, opts)
      _ -> :ok
    end
  end
end

defmodule Relyra.Protocol.TestConnectionResolver do
  @moduledoc false

  @behaviour Relyra.ConnectionResolver

  alias Relyra.Error

  @impl true
  def resolve_connection(request_context, opts) when is_map(request_context) and is_list(opts) do
    case Keyword.get(opts, :connection_resolver_resolve) do
      fun when is_function(fun, 2) ->
        fun.(request_context, opts)

      _ ->
        case Keyword.get(opts, :resolved_connection) do
          connection when is_map(connection) ->
            {:ok, connection}

          _ ->
            {:error,
             Error.new(
               :adapter_not_configured,
               "Test connection resolver expected :resolved_connection option",
               %{request_context: request_context}
             )}
        end
    end
  end
end

defmodule Relyra.Protocol.ConsumeResponsePipelineTest do
  use ExUnit.Case, async: false

  alias Relyra.Error
  alias Relyra.Protocol.ValidationPipeline
  alias Relyra.Protocol.TestConnectionResolver
  alias Relyra.Protocol.TestReplayStore
  alias Relyra.Protocol.TestRequestStore

  @manifest_path "test/fixtures/security/protocol/manifest.json"
  @fixed_now ~U[2026-04-24 16:00:00Z]
  @success_status "urn:oasis:names:tc:SAML:2.0:status:Success"
  @rsa_sha256 "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
  @digest_sha256 "http://www.w3.org/2001/04/xmlenc#sha256"

  test "ordered_stages/0 returns the strict consume order" do
    assert ValidationPipeline.ordered_stages() == [
             :parse_safely,
             :issuer_connection_match,
             :signature_verify,
             :signed_node_bind,
             :status,
             :destination,
             :audience,
             :recipient,
             :time_conditions
           ]
  end

  test "manifest fixtures map to expected_error_type classes and explicit request_intent success" do
    manifest()
    |> Enum.each(fn fixture ->
      result = run_manifest_fixture(fixture)

      case fixture do
        %{"expected_error_type" => expected_error_type} ->
          assert {:error, %Relyra.Error{type: expected_type}} = result
          assert expected_type == String.to_atom(expected_error_type)

        %{"expected_success" => true} ->
          assert {:ok, login_result} = result
          assert is_map(login_result)
      end
    end)
  end

  test "skew_seconds boundary accepts exact edge and rejects edge+1" do
    exact_edge_payload =
      response_xml(%{
        not_before: DateTime.add(@fixed_now, 120, :second) |> DateTime.to_iso8601(),
        not_on_or_after: DateTime.add(@fixed_now, -120, :second) |> DateTime.to_iso8601(),
        subject_confirmation_not_on_or_after:
          DateTime.add(@fixed_now, -120, :second) |> DateTime.to_iso8601()
      })

    assert {:ok, login_result} =
             Relyra.consume_response(
               exact_edge_payload,
               request_intent(),
               consume_opts(now: @fixed_now, skew_seconds: 120)
             )

    assert is_map(login_result)

    edge_plus_one_payload =
      response_xml(%{
        not_before: DateTime.add(@fixed_now, 121, :second) |> DateTime.to_iso8601(),
        not_on_or_after: DateTime.add(@fixed_now, 600, :second) |> DateTime.to_iso8601(),
        subject_confirmation_not_on_or_after:
          DateTime.add(@fixed_now, 600, :second) |> DateTime.to_iso8601()
      })

    assert {:error, %Error{type: :assertion_not_yet_valid}} =
             Relyra.consume_response(
               edge_plus_one_payload,
               request_intent(),
               consume_opts(now: @fixed_now, skew_seconds: 120)
             )
  end

  test "clock skew config rejects invalid skew_seconds values" do
    assert {:error, %Error{type: :clock_skew_exceeded}} =
             Relyra.consume_response(
               response_xml(),
               request_intent(),
               consume_opts(now: @fixed_now, skew_seconds: -1)
             )
  end

  test "consume_response/3 only returns typed success or typed error tuples" do
    success_result =
      Relyra.consume_response(response_xml(), request_intent(), consume_opts(now: @fixed_now))

    error_result =
      Relyra.consume_response(
        response_xml(%{status: "urn:oasis:names:tc:SAML:2.0:status:Responder"}),
        request_intent(),
        consume_opts(now: @fixed_now)
      )

    Enum.each([success_result, error_result], fn result ->
      assert match?({:ok, %{}}, result) or match?({:error, %Relyra.Error{}}, result)
    end)
  end

  test "request-correlation checks reject missing and mismatched relay state" do
    assert {:error, %Error{type: :relay_state_missing}} =
             Relyra.consume_response(
               response_xml(),
               request_intent(),
               connection: connection(),
               now: @fixed_now
             )

    assert {:error, %Error{type: :relay_state_mismatch}} =
             Relyra.consume_response(
               response_xml(),
               request_intent(),
               consume_opts(now: @fixed_now, relay_state: "rs_wrong")
             )
  end

  test "request-correlation checks reject mismatched in_response_to" do
    assert {:error, %Error{type: :in_response_to_mismatch}} =
             Relyra.consume_response(
               response_xml(%{in_response_to: "id_request_999"}),
               request_intent(),
               consume_opts(now: @fixed_now)
             )
  end

  test "explicit request_intent compatibility path still succeeds" do
    assert {:ok, login_result} =
             Relyra.consume_response(
               response_xml(%{assertion_id: "assertion-compat"}),
               request_intent(),
               consume_opts(now: @fixed_now)
             )

    assert login_result.in_response_to == "id_request_123"
  end

  test "unsigned payload never returns {:ok, _}" do
    assert {:error, %Error{type: error_type}} =
             Relyra.consume_response(
               "<Fake>unsigned</Fake>",
               request_intent(),
               consume_opts(now: @fixed_now)
             )

    assert error_type in [:missing_signature, :missing_protocol_field, :malformed_xml]
  end

  @tag :replay_consume_failure_blocks_success
  test "replay consume failure blocks success tuple" do
    result =
      Relyra.consume_response(
        response_xml(%{assertion_id: "assertion-replay-fail"}),
        request_intent(),
        consume_opts(
          now: @fixed_now,
          replay_store_consume: fn _replay_key, _metadata, _opts ->
            {:error,
             Error.new(:replayed_assertion, "forced replay conflict", %{source: :replay_consume})}
          end,
          request_store_consume: fn _relay_state, _request_id, _opts ->
            send(self(), :request_consume_called)
            :ok
          end
        )
      )

    assert {:error, %Error{type: :replayed_assertion}} = result
    refute match?({:ok, _}, result)
    refute_received :request_consume_called
  end

  @tag :request_consume_failure_blocks_success
  test "request consume failure blocks success tuple" do
    result =
      Relyra.consume_response(
        response_xml(%{assertion_id: "assertion-request-fail"}),
        request_intent(),
        consume_opts(
          now: @fixed_now,
          request_store_consume: fn _relay_state, _request_id, _opts ->
            {:error,
             Error.new(
               :request_intent_consumed,
               "forced request consume conflict",
               %{source: :request_consume}
             )}
          end
        )
      )

    assert {:error, %Error{type: :request_intent_consumed}} = result
    refute match?({:ok, _}, result)
  end

  @tag :consume_ordering_gate
  test "consume order gate executes replay consume before request consume and both gates pass before success" do
    replay_key_probe = make_ref()
    relay_probe = make_ref()
    parent = self()

    result =
      Relyra.consume_response(
        response_xml(%{assertion_id: "assertion-ordering-gate"}),
        consume_opts(
          now: @fixed_now,
          request_intent: request_intent(),
          replay_store_consume: fn replay_key, _metadata, _opts ->
            send(parent, {:consume_order, :replay, replay_key_probe, replay_key})
            :ok
          end,
          request_store_consume: fn relay_state, request_id, _opts ->
            send(parent, {:consume_order, :request, relay_probe, relay_state, request_id})
            :ok
          end
        )
      )

    assert_receive {:consume_order, :replay, ^replay_key_probe, _replay_key}
    assert_receive {:consume_order, :request, ^relay_probe, _relay_state, _request_id}
    assert {:ok, login_result} = result
    assert is_map(login_result)
  end

  defp run_manifest_fixture(fixture) do
    opts = fixture_opts(fixture)
    payload = fixture["payload"]
    request_mode = Map.get(fixture, "request_mode", "explicit")

    case request_mode do
      "store" ->
        Relyra.consume_response(payload, opts)

      _ ->
        Relyra.consume_response(payload, fixture_request_intent(fixture), opts)
    end
  end

  defp fixture_opts(fixture) do
    opts = consume_opts(now: @fixed_now, relay_state: relay_state_for_fixture(fixture))

    opts =
      case fixture_request_intent(fixture) do
        nil -> Keyword.delete(opts, :request_intent)
        intent -> Keyword.put(opts, :request_intent, intent)
      end

    opts
    |> maybe_use_resolver(fixture)
    |> maybe_force_replay_conflict(fixture)
  end

  defp maybe_use_resolver(opts, %{"connection_source" => "resolver"}) do
    opts
    |> Keyword.delete(:connection)
    |> Keyword.put(:resolved_connection, connection())
  end

  defp maybe_use_resolver(opts, _fixture), do: opts

  defp maybe_force_replay_conflict(opts, %{"class" => "replayed_assertion"}) do
    Keyword.put(opts, :replay_store_consume, fn _replay_key, _metadata, _consume_opts ->
      {:error, Error.new(:replayed_assertion, "manifest replay duplicate", %{source: :fixture})}
    end)
  end

  defp maybe_force_replay_conflict(opts, _fixture), do: opts

  defp fixture_request_intent(%{"class" => "request_intent_missing"}), do: nil

  defp fixture_request_intent(%{"class" => "request_intent_expired"}) do
    Map.put(request_intent(), :expires_at, "2026-04-24T15:59:59Z")
  end

  defp fixture_request_intent(_fixture), do: request_intent()

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

  defp connection do
    %{
      connection_id: "conn-123",
      idp_entity_id: "https://idp.example.com/metadata",
      issuer: "https://idp.example.com/metadata",
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs",
      cert_chain: ["pem-cert-chain"]
    }
  end

  defp consume_opts(extra_opts) do
    Keyword.merge(
      [
        connection: connection(),
        resolved_connection: connection(),
        relay_state: request_intent().relay_state,
        request_store: TestRequestStore,
        replay_store: TestReplayStore,
        connection_resolver: TestConnectionResolver,
        request_intent: request_intent()
      ],
      extra_opts
    )
  end

  defp relay_state_for_fixture(%{"class" => "relay_state_mismatch"}), do: "rs_wrong"
  defp relay_state_for_fixture(_fixture), do: request_intent().relay_state

  defp response_xml(overrides \\ %{}) do
    fields =
      Map.merge(
        %{
          destination: "https://sp.example.com/saml/acs",
          in_response_to: "id_request_123",
          connection_id: "conn-123",
          issuer: "https://idp.example.com/metadata",
          status: @success_status,
          assertion_id: "assertion-1",
          audience: "https://sp.example.com/metadata",
          recipient: "https://sp.example.com/saml/acs",
          not_before: "2026-04-24T15:58:00Z",
          not_on_or_after: "2026-04-24T16:05:00Z",
          subject_confirmation_not_on_or_after: "2026-04-24T16:05:00Z",
          signature_method: @rsa_sha256,
          digest_method: @digest_sha256
        },
        overrides
      )

    """
    <Response Destination="#{fields.destination}" InResponseTo="#{fields.in_response_to}" ConnectionId="#{fields.connection_id}">
      <Issuer>#{fields.issuer}</Issuer>
      <Status><StatusCode Value="#{fields.status}"/></Status>
      <Assertion ID="#{fields.assertion_id}">
        <Issuer>#{fields.issuer}</Issuer>
        <Subject>
          <NameID>user@example.com</NameID>
          <SubjectConfirmation>
            <SubjectConfirmationData Recipient="#{fields.recipient}" NotOnOrAfter="#{fields.subject_confirmation_not_on_or_after}"/>
          </SubjectConfirmation>
        </Subject>
        <Conditions NotBefore="#{fields.not_before}" NotOnOrAfter="#{fields.not_on_or_after}">
          <AudienceRestriction><Audience>#{fields.audience}</Audience></AudienceRestriction>
        </Conditions>
      </Assertion>
      <Signature>
        <SignedInfo>
          <SignatureMethod Algorithm="#{fields.signature_method}"/>
          <Reference URI="##{fields.assertion_id}">
            <DigestMethod Algorithm="#{fields.digest_method}"/>
          </Reference>
        </SignedInfo>
      </Signature>
    </Response>
    """
    |> String.trim()
  end

  defp manifest do
    @manifest_path
    |> File.read!()
    |> :json.decode()
  end
end
