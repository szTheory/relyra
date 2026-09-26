defmodule LedgerLoopWeb.LifecycleJourneysTest do
  use LedgerLoopWeb.ConnCase, async: false

  unless Code.ensure_loaded?(LedgerLoop.TestSupport.LifecycleFlow) do
    Code.require_file("../support/lifecycle_flow.ex", __DIR__)
  end

  import Ecto.Query

  alias LedgerLoop.Accounts.{Group, LoginReceipt, Membership, Tenant, User}
  alias LedgerLoop.Demo.{Fixtures, Reset}
  alias LedgerLoop.FakeIdP.Keypair
  alias LedgerLoop.Repo
  alias LedgerLoop.TestSupport.LifecycleFlow
  alias Relyra.Ecto.Certificate
  alias Relyra.Ecto.{AuditEvent, Connection}

  @connection_id Fixtures.relyra_enabled_scenario_id()
  @issuer "https://idp.northstar.example.com"
  @sarah_subject "sarah@northstar.example.com"

  setup do
    Reset.reset!()
    :ok
  end

  test "SP login establishes exactly the mapped Northstar administrator receipt" do
    flow = LifecycleFlow.start_login(@connection_id, @issuer, @sarah_subject)
    login = flow.login_conn
    assert login.status == 302
    assert flow.idp_login.status == 200
    assert is_binary(flow.request_id) and flow.request_id != ""
    assert flow.acs_path == "/saml/#{@connection_id}/acs"

    configured_certificate =
      Repo.get_by!(Certificate,
        connection_record_id: Repo.get_by!(Connection, connection_id: @connection_id).id,
        party: :idp,
        use: :signing,
        lifecycle_state: :active
      )

    assert configured_certificate.pem == Keypair.cert_pem()

    accepted = LifecycleFlow.post_acs(flow)

    assert accepted.status == 302
    assert get_resp_header(accepted, "location") == ["/"]

    sarah = Repo.get_by!(User, email: @sarah_subject)
    tenant = Repo.get!(Tenant, sarah.tenant_id)

    groups =
      Repo.all(
        from group in Group,
          join: membership in Membership,
          on: membership.group_id == group.id,
          where: membership.user_id == ^sarah.id,
          select: group
      )

    assert tenant.slug == "northstar"
    assert Enum.map(groups, & &1.key) == ["admins"]
    assert Enum.map(groups, & &1.tenant_id) == [tenant.id]

    assert [%LoginReceipt{user_id: receipt_user_id, scenario_key: scenario_key}] =
             Repo.all(from receipt in LoginReceipt, where: receipt.user_id == ^sarah.id)

    assert receipt_user_id == sarah.id
    assert scenario_key =~ "session_"
    assert Repo.aggregate(LoginReceipt, :count, :id) == 1

    connection = Repo.get_by!(Connection, connection_id: @connection_id)

    assert [[request_id, request_intent, consumed_at]] =
             Repo.query!(
               "SELECT request_id, intent, consumed_at FROM ledger_loop_relyra_request_intents WHERE relay_state = $1",
               [flow.relay_state]
             ).rows

    assert request_id == flow.request_id
    assert request_intent["connection_id"] == @connection_id
    assert request_intent["organization_id"] == tenant.slug
    assert not is_nil(consumed_at)

    replay_rows =
      Repo.query!("SELECT replay_key, metadata FROM ledger_loop_relyra_replay_keys").rows

    assert [[replay_key, replay_metadata]] = replay_rows

    assert replay_key =~ @connection_id
    assert replay_metadata["connection_id"] == @connection_id

    assert [trace] =
             Repo.all(
               from event in AuditEvent,
                 where:
                   event.connection_record_id == ^connection.id and
                     event.domain == :login and event.action == :succeeded
             )

    assert trace.after_summary["overall_outcome"] == "success"
    assert trace.after_summary["steps"]["session.establish"]["outcome"] == "success"

    chen = Repo.get_by!(User, email: "chen@northstar.example.com")
    refute Repo.exists?(from receipt in LoginReceipt, where: receipt.user_id == ^chen.id)
  end
end
