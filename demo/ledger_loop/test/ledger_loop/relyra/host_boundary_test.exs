defmodule LedgerLoop.Relyra.HostBoundaryTest do
  use LedgerLoop.DataCase

  alias LedgerLoop.Relyra.UserMapper
  alias LedgerLoop.Relyra.SessionAdapter
  alias LedgerLoop.Accounts.User
  alias LedgerLoop.Accounts.LoginReceipt
  alias LedgerLoop.Repo
  import Ecto.Query

  setup do
    LedgerLoop.Demo.Reset.reset!()
    :ok
  end

  describe "UserMapper.map_attributes/3" do
    test "returns host user, tenant, and group data for known principal" do
      principal = %{name_id: "chen@northstar.example.com"}
      assertion = %{principal: principal}
      connection = %{idp_entity_id: "https://idp.northstar.example.com"}

      assert {:ok, user_data} = UserMapper.map_attributes(assertion, connection, [])

      assert user_data.email == "chen@northstar.example.com"
      assert user_data.name == "Nurse Chen"
      assert user_data.tenant.slug == "northstar"
      assert Enum.any?(user_data.groups, fn g -> g.key == "clinical" end)
    end

    test "returns typed Relyra.Error for unknown principal" do
      principal = %{name_id: "unknown@northstar.example.com"}
      assertion = %{principal: principal}
      connection = %{idp_entity_id: "https://idp.northstar.example.com"}

      assert {:error, %Relyra.Error{} = error} =
               UserMapper.map_attributes(assertion, connection, [])

      assert error.type == :user_not_found

      # Verify no user was created
      assert Repo.one(from u in User, where: u.email == "unknown@northstar.example.com") == nil
    end
  end

  describe "SessionAdapter.establish_session/3" do
    test "inserts a LoginReceipt row owned by LedgerLoop" do
      user = Repo.one!(from u in User, where: u.email == "chen@northstar.example.com")
      subject = %{id: user.id, email: user.email}
      context = %{connection_id: "conn_123"}

      assert {:ok, receipt_proof} = SessionAdapter.establish_session(subject, context, [])

      # Verify receipt row was inserted
      assert receipt = Repo.get(LoginReceipt, receipt_proof.receipt_id)
      assert receipt.user_id == user.id
      assert receipt.scenario_key =~ "session_conn_123_"

      # Verify ownership fields are explicitly stated
      assert receipt_proof.principal_verified_by == "Relyra"
      assert receipt_proof.mapping_owner == "LedgerLoop"
      assert receipt_proof.session_owner == "LedgerLoop"
      assert receipt_proof.authorization_owner == "LedgerLoop"

      # Verify payload doesn't leak raw SAML data (stringified checks)
      proof_str = inspect(receipt_proof)
      refute proof_str =~ "SAMLResponse"
      refute proof_str =~ "RelayState"
      refute proof_str =~ "FakeIdP"
      refute proof_str =~ "Keycloak"
      refute proof_str =~ "private"
      refute proof_str =~ "xml"
      refute proof_str =~ "PEM"
    end
  end
end
