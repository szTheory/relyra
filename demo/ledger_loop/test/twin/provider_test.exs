defmodule LedgerLoop.Twin.ProviderTest do
  use LedgerLoop.DataCase, async: false

  alias LedgerLoop.Demo.{Fixtures, Reset}
  alias LedgerLoop.Repo
  alias LedgerLoop.Accounts.Tenant
  alias Relyra.Ecto.Connection

  setup do
    Reset.reset!()
    :ok
  end

  test "named connections belong to fixture tenants and retain provider-specific identity and readiness" do
    tenants = Map.new(Repo.all(Tenant), &{&1.slug, &1})
    connections = Repo.all(Connection)

    assert Enum.sort(Enum.map(connections, & &1.connection_id)) ==
             Enum.sort(Enum.map(Fixtures.relyra_connections(), & &1.connection_id))

    for connection <- connections do
      assert tenant = tenants[connection.organization_id]
      assert tenant.slug == connection.organization_id
    end

    harborline = Repo.get_by!(Connection, organization_id: "harborline")
    assert harborline.provider_preset == :google_workspace
    assert harborline.idp_entity_id == "https://idp.harborline.example.com"
    assert harborline.status == :enabled

    northstar_draft =
      Repo.get_by!(Connection, display_name: "Northstar Health (Draft/Missing Metadata)")

    assert northstar_draft.organization_id == "northstar"
    assert northstar_draft.status == :draft
    assert northstar_draft.provider_preset == :entra
  end
end
