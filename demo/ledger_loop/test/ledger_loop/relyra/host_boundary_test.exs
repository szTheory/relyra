defmodule LedgerLoop.Relyra.HostBoundaryTest do
  use LedgerLoop.DataCase

  alias LedgerLoop.Relyra.UserMapper
  alias LedgerLoop.Accounts.User
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

      assert {:error, %Relyra.Error{} = error} = UserMapper.map_attributes(assertion, connection, [])
      assert error.type == :user_not_found
      
      # Verify no user was created
      assert Repo.one(from u in User, where: u.email == "unknown@northstar.example.com") == nil
    end
  end
end
