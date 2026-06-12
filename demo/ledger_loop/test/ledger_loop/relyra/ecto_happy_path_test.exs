defmodule LedgerLoop.Relyra.EctoHappyPathTest do
  use LedgerLoop.DataCase, async: false

  alias LedgerLoop.Demo.Reset
  alias LedgerLoop.Repo
  alias Relyra.Ecto.Certificate

  @connection_id "01H0B4Y1A2B3C4D5E6F7G8H9J0"

  setup do
    Reset.reset!()

    # Override the mock PEM with a real self-signed certificate so that signature verification passes
    cert_pem = Relyra.TestSupport.XmldsigSigner.self_signed_cert_pem()
    
    cert = Repo.get_by!(Certificate, connection_record_id: "aaaaaaaa-1111-1111-1111-aaaaaaaaaaaa")
    Repo.update!(Ecto.Changeset.change(cert, pem: cert_pem))

    opts = [
      repo: Repo,
      connection_resolver: {Relyra.ConnectionResolver.Ecto, repo: Repo},
      request_store: LedgerLoop.Relyra.RequestStore,
      replay_store: LedgerLoop.Relyra.ReplayStore,
      user_mapper: LedgerLoop.Relyra.UserMapper,
      session_adapter: LedgerLoop.Relyra.SessionAdapter
    ]

    {:ok, opts: opts}
  end

  test "Ecto-backed login happy path completes and blocks replay", %{opts: opts} do
    # Test 1: Resolve the enabled connection
    {:ok, connection} = Relyra.ConnectionResolver.Ecto.resolve_connection(
      %{connection_id: @connection_id},
      opts
    )
    assert connection.organization_id == "northstar"

    # Test 2: start_login writes a request intent
    relay_context = %{"return_to" => "/welcome"}
    assert {:ok, result} = Relyra.start_login(connection, relay_context, opts)
    
    assert is_binary(result.relay_state)
    assert is_binary(result.request_id)
    
    # Verify the request intent was inserted into the fixed Ecto table
    %{rows: [[intent_req_id, intent_consumed_at]]} =
      Ecto.Adapters.SQL.query!(Repo, "SELECT request_id, consumed_at FROM ledger_loop_relyra_request_intents WHERE relay_state = $1", [result.relay_state])
    assert intent_req_id == result.request_id
    assert intent_consumed_at == nil
    


    # Test 3: Build and sign a response
    subject = "sarah@northstar.example.com"

    builder =
      Relyra.TestSupport.FakeIdP.build_response(
        subject: subject,
        audience: connection.sp_entity_id,
        destination: connection.acs_url,
        recipient: connection.acs_url,
        in_response_to: result.request_id,
        relay_state: result.relay_state,
        name_id: subject,
        issuer: connection.idp_entity_id
      )

    signed_b64 = Relyra.TestSupport.FakeIdP.sign(builder)
    


    # Test 4: Consume the response
    consume_opts = Keyword.put(opts, :relay_state, result.relay_state) |> Keyword.put(:connection, connection)
    assert {:ok, login_result} = Relyra.consume_response(Base.decode64!(signed_b64, padding: false), consume_opts)
    
    assert {:ok, mapped_user} = Relyra.UserMapper.map_attributes(login_result, connection, consume_opts)
    
    context = %{connection_id: connection.connection_id}
    assert {:ok, receipt} = Relyra.SessionAdapter.establish_session(mapped_user, context, consume_opts)
    
    # Verify the receipt proof
    assert receipt.principal_verified_by == "Relyra"
    assert receipt.mapping_owner == "LedgerLoop"
    assert receipt.session_owner == "LedgerLoop"
    assert receipt.authorization_owner == "LedgerLoop"
    assert receipt.scenario_key =~ ~r/^session_01H0B4Y1A2B3C4D5E6F7G8H9J0_\d+$/
    
    # Verify the user is Dr. Sarah
    assert receipt.user_id == "22222222-2222-2222-2222-222222222222"

    # Verify request intent was marked consumed
    %{rows: [[consumed_intent_at]]} =
      Ecto.Adapters.SQL.query!(Repo, "SELECT consumed_at FROM ledger_loop_relyra_request_intents WHERE relay_state = $1", [result.relay_state])
    assert consumed_intent_at != nil

    # Verify replay key was inserted into the fixed Ecto table
    # the replay_key is derived from the response ID. We can query the table to see if a row was inserted.
    %{rows: replay_records} = Ecto.Adapters.SQL.query!(Repo, "SELECT replay_key FROM ledger_loop_relyra_replay_keys", [])
    assert length(replay_records) == 1

    # Test 5: Replaying the same response is rejected
    assert {:error, error} = Relyra.consume_response(Base.decode64!(signed_b64, padding: false), consume_opts)
    assert error.type == :in_response_to_mismatch
  end
end
