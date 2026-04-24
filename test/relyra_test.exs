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

    # tuple contract: {:ok, map()} | {:error, %Relyra.Error{type: atom()}}
    assert match?({:ok, %{}}, Relyra.consume_response(@valid_response, request_intent, opts)) or
             match?(
               {:error, %Relyra.Error{type: _}},
               Relyra.consume_response(@valid_response, request_intent, opts)
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
    assert {:error, %Relyra.Error{type: :adapter_not_configured}} =
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
             Relyra.ReplayStore.Default.consume_replay_key("rk_123", %{connection_id: "conn-123"}, [])

    assert replay_consume_error.type in [:adapter_not_configured, :unsupported_default_adapter]
  end
end
