defmodule LedgerLoop.Twin.OrganizationTest do
  use LedgerLoop.DataCase, async: false

  alias LedgerLoop.Demo.{Fixtures, Reset}
  alias LedgerLoop.Repo
  alias LedgerLoop.Accounts.{Tenant, User, Group, Membership}
  alias LedgerLoop.Relyra.UserMapper
  alias Relyra.Ecto.Connection

  setup do
    Reset.reset!()
    :ok
  end

  test "each named principal maps to only its tenant and declared group outcome" do
    expected = [
      {"sarah@northstar.example.com", "https://idp.northstar.example.com", "northstar", "admins",
       :allow},
      {"chen@northstar.example.com", "https://idp.northstar.example.com", "northstar", "clinical",
       :deny},
      {"maya@harborline.example.com", "https://idp.harborline.example.com", "harborline",
       "admins", :allow},
      {"luis@harborline.example.com", "https://idp.harborline.example.com", "harborline",
       "operations", :deny}
    ]

    for {subject, issuer, slug, group_key, outcome} <- expected do
      connection =
        Repo.one!(
          from(connection in Connection,
            where:
              connection.organization_id == ^slug and
                connection.idp_entity_id == ^issuer,
            order_by: connection.display_name,
            limit: 1
          )
        )

      assert {:ok, mapped} =
               UserMapper.map_attributes(%{principal: %{name_id: subject}}, connection, [])

      assert mapped.tenant.slug == slug
      assert Enum.map(mapped.groups, & &1.key) == [group_key]
      assert group_key == "admins" == (outcome == :allow)
    end
  end

  test "every membership connects users and groups within the same tenant" do
    memberships = Repo.all(Membership) |> Repo.preload([:user, :group])
    assert length(memberships) == length(Fixtures.memberships())
    assert Enum.all?(memberships, &(&1.user.tenant_id == &1.group.tenant_id))
    assert Enum.map(Repo.all(Tenant), & &1.slug) |> Enum.sort() == ["harborline", "northstar"]
    assert length(Repo.all(User)) == length(Fixtures.users())
    assert length(Repo.all(Group)) == length(Fixtures.groups())
  end
end
