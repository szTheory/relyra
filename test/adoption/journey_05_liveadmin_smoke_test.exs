defmodule Relyra.Adoption.Journey05LiveAdminSmokeTest do
  use Relyra.TestSupport.MigrationCase, async: false

  alias Relyra.LiveAdmin.Query
  alias Relyra.LiveAdmin.Scope
  alias Relyra.TestSupport.AdoptionFixtures

  @repo Relyra.TestSupport.EctoTestRepo

  @tag :integration
  test "seeded adoption connection is visible to LiveAdmin query surface" do
    AdoptionFixtures.configure_ecto_runtime!()
    AdoptionFixtures.seed_ecto_connection!(:okta, "admin_demo")

    {:ok, summaries} =
      Query.list_connections(@repo, %Scope{actor: "ops", organization_id: "org_adoption"})

    assert Enum.any?(summaries, &(&1.connection_id == "admin_demo"))
  end

  @tag :integration
  test "diagnostic bundle can be generated for seeded adoption repo" do
    AdoptionFixtures.configure_ecto_runtime!()
    AdoptionFixtures.seed_ecto_connection!(:okta, "diag_demo")

    assert {:ok, zip_binary} = Relyra.Diagnostic.create_bundle(repo: @repo)
    assert byte_size(zip_binary) > 0
  end
end
