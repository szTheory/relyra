defmodule LedgerLoop.Accounts.Membership do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "ledger_loop_memberships" do
    belongs_to :user, LedgerLoop.Accounts.User
    belongs_to :group, LedgerLoop.Accounts.Group

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:user_id, :group_id])
    |> validate_required([:user_id, :group_id])
    |> unique_constraint([:user_id, :group_id])
  end
end
