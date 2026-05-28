defmodule RelyraTest do
  use ExUnit.Case, async: true

  alias Relyra.TestSupport.NoopConnectionResolver
  alias Relyra.TestSupport.NoopReplayStore
  alias Relyra.TestSupport.NoopRequestStore

  @valid_response "<Response><Assertion>signed</Assertion></Response>"

  test "start_login/3 returns documented tuple contract" do
    connection = %{
      idp_sso_url: "https://idp.example.com/sso",
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs"
    }

    relay_context = %{return_to: "/dashboard"}

    opts = [request_store: Relyra.TestSupport.NoopRequestStore, now: ~U[2026-04-24 16:00:00Z]]

    case Relyra.start_login(connection, relay_context, opts) do
      {:ok, %{request_id: request_id, relay_state: relay_state}} ->
        assert String.starts_with?(request_id, "id_")
        assert String.starts_with?(relay_state, "rs_")

      {:error, %Relyra.Error{} = error} ->
        assert match?({:error, %Relyra.Error{}}, {:error, error})
        assert is_atom(error.type)
    end
  end

  test "start_login/3 returns :redirect_query for signed AuthnRequests" do
    pem = File.read!("test/fixtures/security/authn_request_signing/golden_signing_key.pem")
    Application.put_env(:relyra, :sp_signing_key_pem, pem)
    on_exit(fn -> Application.delete_env(:relyra, :sp_signing_key_pem) end)

    connection = %{
      idp_sso_url: "https://idp.example.com/sso",
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs",
      sign_authn_requests: true,
      signed_request_encoding: :rfc3986_upper
    }

    opts = [request_store: Relyra.TestSupport.NoopRequestStore, now: ~U[2026-05-26 00:00:00Z]]

    assert {:ok, %{redirect_query: bytes, request_id: _, relay_state: _}} =
             Relyra.start_login(connection, %{return_to: "/"}, opts)

    assert is_binary(bytes)
    assert String.starts_with?(bytes, "SAMLRequest=")
    assert String.contains?(bytes, "&SigAlg=")
    assert String.contains?(bytes, "&Signature=")
  end

  test "start_login/3 keeps :redirect_params for unsigned AuthnRequests" do
    connection = %{
      idp_sso_url: "https://idp.example.com/sso",
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs",
      sign_authn_requests: false
    }

    opts = [request_store: Relyra.TestSupport.NoopRequestStore, now: ~U[2026-05-26 00:00:00Z]]

    assert {:ok, %{redirect_params: params, request_id: _, relay_state: _}} =
             Relyra.start_login(connection, %{return_to: "/"}, opts)

    assert is_map(params)
    refute Map.has_key?(params, :redirect_query)
  end

  test "start_login/3 rejects idp_sso_url collisions with reserved SAML keys" do
    opts = [request_store: Relyra.TestSupport.NoopRequestStore, now: ~U[2026-05-26 00:00:00Z]]

    for key <- ["SAMLRequest", "Signature", "SigAlg", "RelayState"] do
      connection = %{
        connection_id: "conn-123",
        idp_sso_url: "https://idp.example.com/sso?#{key}=stale",
        sp_entity_id: "https://sp.example.com/metadata",
        acs_url: "https://sp.example.com/saml/acs"
      }

      assert {:error, %Relyra.Error{type: :invalid_idp_sso_url}} =
               Relyra.start_login(connection, %{return_to: "/"}, opts)
    end
  end

  test "start_login/3 allows benign existing idp_sso_url query params" do
    connection = %{
      idp_sso_url: "https://idp.example.com/sso?tenant=acme&realm=prod",
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs"
    }

    opts = [request_store: Relyra.TestSupport.NoopRequestStore, now: ~U[2026-05-26 00:00:00Z]]

    refute match?(
             {:error, %Relyra.Error{type: :invalid_idp_sso_url}},
             Relyra.start_login(connection, %{return_to: "/"}, opts)
           )
  end

  test "start_login/3 emitted AuthnRequest includes Destination attribute" do
    connection = %{
      idp_sso_url: "https://idp.example.com/sso",
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs"
    }

    opts = [request_store: Relyra.TestSupport.NoopRequestStore, now: ~U[2026-05-26 00:00:00Z]]

    assert {:ok, %{authn_request: xml}} =
             Relyra.start_login(connection, %{return_to: "/"}, opts)

    assert xml =~ ~s(Destination="https://idp.example.com/sso")
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

    connection = %{
      connection_id: "conn-123",
      idp_entity_id: "https://idp.example.com/metadata",
      issuer: "https://idp.example.com/metadata",
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs",
      cert_chain: ["pem-cert-chain"]
    }

    opts = [
      now: ~U[2026-04-24 16:00:00Z],
      relay_state: request_intent.relay_state,
      connection: connection,
      resolved_connection: connection,
      request_store: Relyra.TestSupport.NoopRequestStore,
      replay_store: Relyra.TestSupport.NoopReplayStore,
      connection_resolver: Relyra.TestSupport.NoopConnectionResolver,
      request_intent: request_intent
    ]

    explicit_result = Relyra.consume_response(@valid_response, request_intent, opts)
    store_backed_result = Relyra.consume_response(@valid_response, opts)

    # tuple contract: {:ok, map()} | {:error, %Relyra.Error{type: atom()}}
    assert(
      case explicit_result do
        {:ok, %{}} -> true
        {:error, %Relyra.Error{type: type}} when is_atom(type) -> true
        _ -> false
      end
    )

    assert(
      case store_backed_result do
        {:ok, %{}} -> true
        {:error, %Relyra.Error{type: type}} when is_atom(type) -> true
        _ -> false
      end
    )
  end

  test "consume_response/3 returns typed relay-state error when relay_state is omitted" do
    request_intent = %{
      request_id: "id_request_123",
      connection_id: "conn-123",
      relay_state: "rs_1234567890abcdef",
      in_response_to: "id_request_123",
      destination: "https://sp.example.com/saml/acs",
      recipient: "https://sp.example.com/saml/acs"
    }

    connection = %{
      connection_id: "conn-123",
      idp_entity_id: "https://idp.example.com/metadata",
      issuer: "https://idp.example.com/metadata",
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs",
      cert_chain: ["pem-cert-chain"]
    }

    opts = [
      now: ~U[2026-04-24 16:00:00Z],
      connection: connection,
      request_store: Relyra.TestSupport.NoopRequestStore,
      replay_store: Relyra.TestSupport.NoopReplayStore,
      connection_resolver: Relyra.TestSupport.NoopConnectionResolver
    ]

    assert {:error, %Relyra.Error{type: :relay_state_missing}} =
             Relyra.consume_response(@valid_response, request_intent, opts)
  end

  test "phase 3 public extension behaviour modules are exported" do
    assert Code.ensure_loaded?(Relyra.ConnectionResolver)
    assert Code.ensure_loaded?(Relyra.SessionAdapter)
    assert Code.ensure_loaded?(Relyra.UserMapper)
    assert Code.ensure_loaded?(Relyra.RequestStore)
    assert Code.ensure_loaded?(Relyra.ReplayStore)

    assert function_exported?(Relyra.ConnectionResolver, :behaviour_info, 1)
    assert function_exported?(Relyra.SessionAdapter, :behaviour_info, 1)
    assert function_exported?(Relyra.UserMapper, :behaviour_info, 1)
    assert function_exported?(Relyra.RequestStore, :behaviour_info, 1)
    assert function_exported?(Relyra.ReplayStore, :behaviour_info, 1)
  end

  test "default extension adapters keep typed error tuple compatibility" do
    assert {:error, %Relyra.Error{type: :resolver_misconfigured}} =
             Relyra.ConnectionResolver.Default.resolve_connection(%{}, [])

    assert {:error, %Relyra.Error{} = request_put_error} =
             Relyra.RequestStore.Default.put_intent("rs_123", %{request_id: "id_123"}, [])

    assert request_put_error.type in [:adapter_not_configured, :unsupported_default_adapter]

    assert {:error, %Relyra.Error{} = request_fetch_error} =
             Relyra.RequestStore.Default.fetch_intent("rs_123", [])

    assert request_fetch_error.type in [:adapter_not_configured, :unsupported_default_adapter]

    assert {:error, %Relyra.Error{} = request_consume_error} =
             Relyra.RequestStore.Default.consume_intent("rs_123", "id_123", [])

    assert request_consume_error.type in [:adapter_not_configured, :unsupported_default_adapter]

    assert {:error, %Relyra.Error{} = replay_consume_error} =
             Relyra.ReplayStore.Default.consume_replay_key(
               "rk_123",
               %{connection_id: "conn-123"},
               []
             )

    assert replay_consume_error.type in [:adapter_not_configured, :unsupported_default_adapter]
  end

  test "misconfigured adapter modules return typed errors instead of raising" do
    connection = %{
      connection_id: "conn-123",
      idp_sso_url: "https://idp.example.com/sso",
      issuer: "https://idp.example.com/metadata",
      idp_entity_id: "https://idp.example.com/metadata",
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs",
      cert_chain: ["pem-cert-chain"]
    }

    relay_context = %{return_to: "/dashboard"}

    assert {:error, %Relyra.Error{type: :adapter_not_configured}} =
             Relyra.start_login(connection, relay_context,
               request_store: :not_a_module,
               now: ~U[2026-04-24 16:00:00Z]
             )

    consume_opts = [
      now: ~U[2026-04-24 16:00:00Z],
      relay_state: "rs_1234567890abcdef",
      request_store: :not_a_module,
      replay_store: Relyra.TestSupport.NoopReplayStore,
      connection_resolver: Relyra.TestSupport.NoopConnectionResolver,
      resolved_connection: connection
    ]

    assert {:error, %Relyra.Error{type: :adapter_not_configured}} =
             Relyra.consume_response(@valid_response, consume_opts)
  end

  test "start_logout/3 generates a valid HTTP-Redirect payload" do
    connection = %{
      connection_id: "conn-123",
      idp_slo_url: "https://idp.example.com/slo",
      sp_entity_id: "https://sp.example.com/metadata"
    }

    opts = [
      now: ~U[2026-05-26 00:00:00Z],
      name_id: "user123",
      session_index: "sess123",
      binding: :redirect
    ]

    assert {:ok, %{redirect_params: params, request_id: _id, logout_request: xml}} =
             Relyra.start_logout(connection, "sess123", opts)

    assert is_map(params)
    assert Map.has_key?(params, "SAMLRequest")
    assert String.contains?(xml, "LogoutRequest")
  end

  test "start_logout/3 generates a valid HTTP-POST payload" do
    connection = %{
      connection_id: "conn-123",
      idp_slo_url: "https://idp.example.com/slo",
      sp_entity_id: "https://sp.example.com/metadata"
    }

    opts = [
      now: ~U[2026-05-26 00:00:00Z],
      name_id: "user123",
      session_index: "sess123",
      binding: :post
    ]

    assert {:ok, %{post_params: params, request_id: _id, logout_request: xml}} =
             Relyra.start_logout(connection, "sess123", opts)

    assert is_map(params)
    assert Map.has_key?(params, "SAMLRequest")
    assert String.contains?(xml, "LogoutRequest")
  end

  test "consume_logout/3 returns typed error for invalid payload" do
    assert {:error, %Relyra.Error{type: :invalid_logout_payload}} =
             Relyra.consume_logout(%{}, "invalid-payload", [])
  end
end
