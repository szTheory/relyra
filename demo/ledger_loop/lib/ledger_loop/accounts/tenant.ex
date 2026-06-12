defmodule LedgerLoop.Accounts.Tenant do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "ledger_loop_tenants" do
    field :name, :string
    field :slug, :string

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(tenant, attrs) do
    tenant
    |> cast(attrs, [:name, :slug])
    |> validate_required([:name, :slug])
    |> unique_constraint(:slug)
  end
end
