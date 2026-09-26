defmodule LedgerLoopWeb.TenantJourneysTest do
  use LedgerLoopWeb.ConnCase, async: false

  unless Code.ensure_loaded?(LedgerLoop.TestSupport.LifecycleFlow) do
    Code.require_file("../support/lifecycle_flow.ex", __DIR__)
  end

  import Ecto.Query

  alias LedgerLoop.Accounts.{Group, LoginReceipt, Membership, Tenant, User}
  alias LedgerLoop.Demo.{Fixtures, Reset}
  alias LedgerLoop.FakeIdP.Keypair
  alias LedgerLoop.Repo
  alias LedgerLoop.Relyra.{AdminScope, UserMapper}
  alias LedgerLoop.TestSupport.LifecycleFlow
  alias Relyra.{Error, LiveAdmin.Query, LiveAdmin.Scope}
  alias Relyra.Ecto.{AuditEvent, Certificate, Connection}

  @northstar_connection_id Fixtures.relyra_enabled_scenario_id()
  @harborline_connection_id Enum.find(
                              Fixtures.relyra_connections(),
                              &(&1.organization_id == "harborline")
                            ).connection_id

  @northstar_issuer "https://idp.northstar.example.com"
  @harborline_issuer "https://idp.harborline.example.com"

  setup do
    Reset.reset!()
    :ok
  end

  test "paired signed ACS journeys preserve tenant-owned identity, role, replay, trace and admin scope" do
    northstar_flow =
      LifecycleFlow.start_login(
        @northstar_connection_id,
        @northstar_issuer,
        "sarah@northstar.example.com"
      )

    harborline_flow =
      LifecycleFlow.start_login(
        @harborline_connection_id,
        @harborline_issuer,
        "maya@harborline.example.com"
      )

    harborline_connection =
      Repo.get_by!(Connection, connection_id: @harborline_connection_id)

    assert %Certificate{pem: pem, lifecycle_state: :active} =
             Repo.get_by!(Certificate,
               connection_record_id: harborline_connection.id,
               party: :idp,
               use: :signing,
               lifecycle_state: :active
             )

    assert pem == Keypair.cert_pem()

    # Start both request intents before posting either assertion, then consume in
    # reverse order so the tenant journeys share one fixture reset without sharing
    # request or replay state.
    assert LifecycleFlow.post_acs(harborline_flow).status == 302
    assert LifecycleFlow.post_acs(northstar_flow).status == 302

    assert_owner_outcome!(
      "northstar",
      "sarah@northstar.example.com",
      @northstar_connection_id,
      northstar_flow
    )

    assert_owner_outcome!(
      "harborline",
      "maya@harborline.example.com",
      @harborline_connection_id,
      harborline_flow
    )

    replay_rows =
      Repo.query!(
        "SELECT replay_key, metadata FROM ledger_loop_relyra_replay_keys ORDER BY replay_key"
      ).rows

    assert length(replay_rows) == 2

    for {replay_key, metadata} <- replay_rows do
      assert metadata["connection_id"] in [@northstar_connection_id, @harborline_connection_id]
      assert replay_key =~ metadata["connection_id"]
    end

    northstar_scope = admin_scope("northstar")
    harborline_scope = admin_scope("harborline")

    assert {:ok, northstar_traces} =
             Query.get_login_traces(Repo, northstar_scope, @northstar_connection_id)

    assert [%{action: :succeeded, id: northstar_trace_id, correlation_id: northstar_hash} | _] =
             northstar_traces

    assert is_binary(northstar_hash)
    refute northstar_hash =~ northstar_flow.request_id

    assert {:ok, harborline_traces} =
             Query.get_login_traces(Repo, harborline_scope, @harborline_connection_id)

    assert [%{action: :succeeded, id: harborline_trace_id, correlation_id: harborline_hash} | _] =
             harborline_traces

    assert is_binary(harborline_hash)
    refute harborline_hash =~ harborline_flow.request_id

    assert {:error, %Error{type: :connection_not_found}} =
             Query.get_login_traces(Repo, northstar_scope, @harborline_connection_id)

    assert {:error, %Error{type: :connection_not_found}} =
             Query.get_login_traces(Repo, harborline_scope, @northstar_connection_id)

    # The trace IDs returned through the scoped query identify the stored login
    # audit rows, and direct scoped detail lookups cannot cross connection owners.
    assert Repo.get!(AuditEvent, northstar_trace_id).connection_record_id ==
             Repo.get_by!(Connection, connection_id: @northstar_connection_id).id

    assert Repo.get!(AuditEvent, harborline_trace_id).connection_record_id ==
             harborline_connection.id

    assert {:error, %Error{type: :connection_not_found}} =
             Query.get_connection_detail(Repo, northstar_scope, @harborline_connection_id)

    assert {:error, %Error{type: :connection_not_found}} =
             Query.get_connection_detail(Repo, harborline_scope, @northstar_connection_id)

    assert_scenario_role_outcomes!()

    receipts_before_rejections = Repo.aggregate(LoginReceipt, :count, :id)

    wrong_harborline_issuer =
      LifecycleFlow.start_login(
        @harborline_connection_id,
        @northstar_issuer,
        "maya@harborline.example.com"
      )

    assert_typed_rejection!(wrong_harborline_issuer, :issuer_mismatch)

    wrong_northstar_subject =
      LifecycleFlow.start_login(
        @northstar_connection_id,
        @northstar_issuer,
        "maya@harborline.example.com"
      )

    assert_typed_rejection!(wrong_northstar_subject, :user_not_found)

    assert Repo.aggregate(LoginReceipt, :count, :id) == receipts_before_rejections
  end

  defp assert_owner_outcome!(organization_id, email, connection_id, flow) do
    user = Repo.get_by!(User, email: email)
    tenant = Repo.get!(Tenant, user.tenant_id)
    connection = Repo.get_by!(Connection, connection_id: connection_id)

    assert tenant.slug == organization_id

    groups =
      Repo.all(
        from group in Group,
          join: membership in Membership,
          on: membership.group_id == group.id,
          where: membership.user_id == ^user.id,
          select: group
      )

    assert Enum.all?(groups, &(&1.tenant_id == tenant.id))
    assert Enum.map(groups, & &1.key) == ["admins"]

    assert [%LoginReceipt{scenario_key: scenario_key}] =
             Repo.all(from receipt in LoginReceipt, where: receipt.user_id == ^user.id)

    assert scenario_key =~ connection_id

    assert [[request_id, intent, consumed_at]] =
             Repo.query!(
               "SELECT request_id, intent, consumed_at FROM ledger_loop_relyra_request_intents WHERE relay_state = $1",
               [flow.relay_state]
             ).rows

    assert request_id == flow.request_id
    assert intent["connection_id"] == connection_id
    assert intent["organization_id"] == organization_id
    assert not is_nil(consumed_at)

    assert [event] =
             Repo.all(
               from event in AuditEvent,
                 where:
                   event.connection_record_id == ^connection.id and
                     event.domain == :login and event.action == :succeeded
             )

    assert event.after_summary["overall_outcome"] == "ok"
  end

  defp assert_scenario_role_outcomes! do
    scenarios = [
      {"sarah@northstar.example.com", @northstar_issuer, "northstar", "admins", :allow},
      {"chen@northstar.example.com", @northstar_issuer, "northstar", "clinical", :deny},
      {"maya@harborline.example.com", @harborline_issuer, "harborline", "admins", :allow},
      {"luis@harborline.example.com", @harborline_issuer, "harborline", "operations", :deny}
    ]

    for {subject, issuer, organization_id, expected_group, expected_outcome} <- scenarios do
      connection =
        Repo.one!(
          from connection in Connection,
            where:
              connection.organization_id == ^organization_id and
                connection.idp_entity_id == ^issuer and connection.status == :enabled,
            order_by: connection.display_name,
            limit: 1
        )

      assert {:ok, mapped} =
               UserMapper.map_attributes(%{principal: %{name_id: subject}}, connection, [])

      group_keys = Enum.map(mapped.groups, & &1.key)
      assert mapped.tenant.slug == organization_id
      assert group_keys == [expected_group]

      scenario_outcome = if "admins" in group_keys, do: :allow, else: :deny
      assert scenario_outcome == expected_outcome
      assert connection.idp_entity_id == issuer
    end
  end

  defp assert_typed_rejection!(flow, expected_error) do
    before = Repo.aggregate(LoginReceipt, :count, :id)
    rejected = LifecycleFlow.post_acs(flow)

    assert rejected.status == 400
    assert Phoenix.ConnTest.response(rejected, 400) =~ Atom.to_string(expected_error)
    assert Repo.aggregate(LoginReceipt, :count, :id) == before

    connection = Repo.get_by!(Connection, connection_id: flow.connection.connection_id)
    expected_code = Atom.to_string(expected_error)

    # Issuer mismatch fails inside consume_response and is retained by the
    # consume-path audit handler. Host mapping runs after that span, so a
    # user_not_found response is checked at the ACS boundary without claiming
    # that the consume-path trace captures it.
    if expected_error != :user_not_found do
      assert Enum.any?(
               Repo.all(
                 from event in AuditEvent,
                   where:
                     event.connection_record_id == ^connection.id and event.domain == :login and
                       event.action == :failed
               ),
               fn event ->
                 event.after_summary
                 |> Map.get("steps", %{})
                 |> Map.values()
                 |> Enum.any?(&(Map.get(&1, "error_code") == expected_code))
               end
             )
    end
  end

  defp admin_scope(organization_id) do
    assert {:ok, %Scope{organization_id: ^organization_id} = scope} =
             AdminScope.resolve_admin_scope(
               %{
                 "admin_actor" => "#{organization_id}-admin@example.com",
                 "admin_actor_label" => "#{organization_id} operator",
                 "admin_organization_id" => organization_id
               },
               %{},
               []
             )

    scope
  end
end
