defmodule LedgerLoop.Demo.Reset do
  @moduledoc """
  Orchestrates the deterministic reset of the LedgerLoop demo state.
  """

  alias LedgerLoop.Repo
  alias LedgerLoop.Demo.Fixtures
  alias LedgerLoop.Accounts.{Tenant, User, Group, Membership, SAMLIdentity}
  import Ecto.Query

  @doc """
  Deterministically recreates the demo state.
  """
  def reset! do
    Repo.transaction(fn ->
      # Delete existing demo data starting with tenant (cascades)
      # In reality, delete_all on tenant with on_delete: :delete_all should clean up everything else,
      # but we can do it explicitly just to be safe, or just rely on the DB.
      Repo.delete_all(from t in Tenant, where: t.id == ^Fixtures.tenant().id)

      # Insert fixed data
      Repo.insert_all(Tenant, [Fixtures.tenant()])
      Repo.insert_all(User, Fixtures.users())
      Repo.insert_all(Group, Fixtures.groups())
      Repo.insert_all(Membership, Fixtures.memberships())
      Repo.insert_all(SAMLIdentity, Fixtures.saml_identities())
      # LoginReceipt isn't seeded with rows, it just gets created during test/demo interactions.
    end)

    :ok
  end
end
