defmodule LedgerLoop.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "ledger_loop_users" do
    field :email, :string
    field :name, :string

    belongs_to :tenant, LedgerLoop.Accounts.Tenant

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :name, :tenant_id])
    |> validate_required([:email, :name, :tenant_id])
    |> unique_constraint(:email)
  end
end
