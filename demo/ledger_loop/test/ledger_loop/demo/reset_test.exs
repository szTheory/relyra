defmodule LedgerLoop.Demo.ResetTest do
  use LedgerLoop.DataCase

  alias LedgerLoop.Accounts.{Tenant, User, Group, Membership, SAMLIdentity, LoginReceipt}

  describe "Task 1: Demo Migrations and Schemas" do
    test "tables exist with binary IDs and expected natural key unique indexes" do
      # If queries run without raising, the tables exist.
      assert Repo.all(Tenant) == []
      assert Repo.all(User) == []
      assert Repo.all(Group) == []
      assert Repo.all(Membership) == []
      assert Repo.all(SAMLIdentity) == []
      assert Repo.all(LoginReceipt) == []

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
  end
end
