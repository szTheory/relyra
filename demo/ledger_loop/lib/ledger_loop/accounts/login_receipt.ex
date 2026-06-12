defmodule LedgerLoop.Accounts.LoginReceipt do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "ledger_loop_login_receipts" do
    field :scenario_key, :string

    belongs_to :user, LedgerLoop.Accounts.User

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(login_receipt, attrs) do
    login_receipt
    |> cast(attrs, [:scenario_key, :user_id])
    |> validate_required([:scenario_key, :user_id])
    |> unique_constraint([:user_id, :scenario_key])
  end
end
