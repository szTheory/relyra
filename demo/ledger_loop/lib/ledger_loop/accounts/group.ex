defmodule LedgerLoop.Accounts.Group do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "ledger_loop_groups" do
    field :name, :string
    field :key, :string

    belongs_to :tenant, LedgerLoop.Accounts.Tenant

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(group, attrs) do
    group
    |> cast(attrs, [:name, :key, :tenant_id])
    |> validate_required([:name, :key, :tenant_id])
    |> unique_constraint([:tenant_id, :key])
  end
end
