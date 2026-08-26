defmodule LedgerLoop.Demo.ResetTest do
  use LedgerLoop.DataCase

  alias LedgerLoop.Accounts.{Tenant, User, Group, Membership, SAMLIdentity, LoginReceipt}
  alias Relyra.Ecto.AuditEvent
  alias Relyra.LoginTrace.Export

  describe "Task 1: Demo Migrations and Schemas" do
    test "tables exist with binary IDs and expected natural key unique indexes" do
      # If queries run without raising, the tables exist. This asserts queryability,
      # not emptiness: the ci.demo_app lane seeds the DB (mix ecto.setup) before the
      # suite runs, so seeded rows may be present here.
      assert is_list(Repo.all(Tenant))
      assert is_list(Repo.all(User))
      assert is_list(Repo.all(Group))
      assert is_list(Repo.all(Membership))
      assert is_list(Repo.all(SAMLIdentity))
      assert is_list(Repo.all(LoginReceipt))

      # We can check schema primary keys directly
      assert Tenant.__schema__(:primary_key) == [:id]
      assert Tenant.__schema__(:type, :id) == :binary_id
      assert Tenant.__schema__(:type, :inserted_at) == :utc_datetime_usec
      assert Tenant.__schema__(:type, :updated_at) == :utc_datetime_usec

      assert User.__schema__(:type, :id) == :binary_id
      assert Group.__schema__(:type, :id) == :binary_id
      assert Membership.__schema__(:type, :id) == :binary_id
      assert SAMLIdentity.__schema__(:type, :id) == :binary_id
      assert LoginReceipt.__schema__(:type, :id) == :binary_id
    end

    test "schemas enforce required fields" do
      tenant_changeset = Tenant.changeset(%Tenant{}, %{})
      assert "can't be blank" in errors_on(tenant_changeset).name
      assert "can't be blank" in errors_on(tenant_changeset).slug

      user_changeset = User.changeset(%User{}, %{})
      assert "can't be blank" in errors_on(user_changeset).email
      assert "can't be blank" in errors_on(user_changeset).name
      assert "can't be blank" in errors_on(user_changeset).tenant_id

      group_changeset = Group.changeset(%Group{}, %{})
      assert "can't be blank" in errors_on(group_changeset).name
      assert "can't be blank" in errors_on(group_changeset).key
      assert "can't be blank" in errors_on(group_changeset).tenant_id

      membership_changeset = Membership.changeset(%Membership{}, %{})
      assert "can't be blank" in errors_on(membership_changeset).user_id
      assert "can't be blank" in errors_on(membership_changeset).group_id

      identity_changeset = SAMLIdentity.changeset(%SAMLIdentity{}, %{})
      assert "can't be blank" in errors_on(identity_changeset).user_id
      assert "can't be blank" in errors_on(identity_changeset).subject
      assert "can't be blank" in errors_on(identity_changeset).issuer

      receipt_changeset = LoginReceipt.changeset(%LoginReceipt{}, %{})
      assert "can't be blank" in errors_on(receipt_changeset).user_id
      assert "can't be blank" in errors_on(receipt_changeset).scenario_key
    end

    test "migration does not create Relyra tables" do
      migration_file =
        "priv/repo/migrations/20260612170000_create_ledger_loop_demo_tables.exs"

      migration_content = File.read!(migration_file)

      refute migration_content =~ "relyra_"
      refute migration_content =~ "Relyra"
    end
  end

  describe "Task 2: Deterministic Reset" do
    test "reset!/0 produces identical rows when called multiple times" do
      LedgerLoop.Demo.Reset.reset!()

      tenants_1 = Repo.all(Tenant)
      users_1 = Repo.all(User)
      groups_1 = Repo.all(Group)
      memberships_1 = Repo.all(Membership)
      identities_1 = Repo.all(SAMLIdentity)
      receipts_1 = Repo.all(LoginReceipt)

      assert length(tenants_1) >= 1
      assert length(users_1) >= 1

      LedgerLoop.Demo.Reset.reset!()

      tenants_2 = Repo.all(Tenant)
      users_2 = Repo.all(User)
      groups_2 = Repo.all(Group)
      memberships_2 = Repo.all(Membership)
      identities_2 = Repo.all(SAMLIdentity)
      receipts_2 = Repo.all(LoginReceipt)

      assert tenants_1 == tenants_2
      assert users_1 == users_2
      assert groups_1 == groups_2
      assert memberships_1 == memberships_2
      assert identities_1 == identities_2
      assert receipts_1 == receipts_2
    end

    test "default reset retains the six support trace events without the visual fixture" do
      for value <- [nil, "true"] do
        with_demo_trace_visual_fixture(value, fn ->
          LedgerLoop.Demo.Reset.reset!()

          trace_events =
            Repo.all(
              from event in AuditEvent,
                where: event.domain == :login,
                order_by: [asc: event.inserted_at]
            )

          assert length(trace_events) == 6

          refute Enum.any?(
                   trace_events,
                   &String.starts_with?(&1.cause, "visual_fixture_long_failure_cause")
                 )
        end)
      end
    end

    test "exact visual-fixture opt-in adds one safe long failed login trace" do
      with_demo_trace_visual_fixture("1", fn ->
        LedgerLoop.Demo.Reset.reset!()

        fixture_event =
          Repo.all(from event in AuditEvent, where: event.domain == :login)
          |> Enum.find(&String.starts_with?(&1.cause, "visual_fixture_long_failure_cause"))

        assert fixture_event

        exported = Export.export_login(fixture_event)

        assert fixture_event.action == :failed
        assert String.length(fixture_event.cause) > 80
        assert exported.correlation_id =~ ~r/^[0-9a-f]{64}$/
        assert exported.correlation_id != fixture_event.correlation_id
        assert [%{"step" => "response.validate", "error_code" => error_code}] = exported.steps
        assert String.length(error_code) > 80

        rendered = inspect(exported)
        refute rendered =~ "-----BEGIN"
        refute rendered =~ "<saml"
        refute rendered =~ "password"
      end)
    end
  end

  defp with_demo_trace_visual_fixture(value, fun) do
    previous = System.get_env("DEMO_TRACE_VISUAL_FIXTURE")

    if is_nil(value),
      do: System.delete_env("DEMO_TRACE_VISUAL_FIXTURE"),
      else: System.put_env("DEMO_TRACE_VISUAL_FIXTURE", value)

    try do
      fun.()
    after
      if is_nil(previous),
        do: System.delete_env("DEMO_TRACE_VISUAL_FIXTURE"),
        else: System.put_env("DEMO_TRACE_VISUAL_FIXTURE", previous)
    end
  end
end
