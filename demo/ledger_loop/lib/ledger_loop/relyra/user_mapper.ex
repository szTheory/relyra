defmodule LedgerLoop.Relyra.UserMapper do
  @moduledoc """
  LedgerLoop-owned implementation of the Relyra.UserMapper behaviour.
  Maps a verified Relyra principal to the seeded host user and their group/tenant context.
  """
  @behaviour Relyra.UserMapper

  alias LedgerLoop.Repo
  alias LedgerLoop.Accounts.SAMLIdentity
  import Ecto.Query

  @impl Relyra.UserMapper
  def map_attributes(%{principal: principal}, connection, _opts) do
    subject = principal.name_id
    issuer = connection.idp_entity_id

    query =
      from identity in SAMLIdentity,
        where: identity.subject == ^subject and identity.issuer == ^issuer,
        join: user in assoc(identity, :user),
        join: tenant in assoc(user, :tenant),
        preload: [user: {user, tenant: tenant}]

    case Repo.one(query) do
      nil ->
        {:error,
         Relyra.Error.new(
           :user_not_found,
           "No user found for subject '#{subject}' and issuer '#{issuer}'"
         )}

      identity ->
        user = identity.user
        tenant = user.tenant

        # Fetch groups directly
        group_query =
          from membership in LedgerLoop.Accounts.Membership,
            where: membership.user_id == ^user.id,
            join: group in assoc(membership, :group),
            select: group

        groups = Repo.all(group_query)

        {:ok,
         %{
           id: user.id,
           email: user.email,
           name: user.name,
           tenant: %{
             id: tenant.id,
             name: tenant.name,
             slug: tenant.slug
           },
           groups: Enum.map(groups, fn g -> %{id: g.id, name: g.name, key: g.key} end)
         }}
    end
  end
end
