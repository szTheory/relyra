defmodule LedgerLoop.Accounts.SAMLIdentity do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "ledger_loop_saml_identities" do
    field :subject, :string
    field :issuer, :string

    belongs_to :user, LedgerLoop.Accounts.User

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(saml_identity, attrs) do
    saml_identity
    |> cast(attrs, [:subject, :issuer, :user_id])
    |> validate_required([:subject, :issuer, :user_id])
    |> unique_constraint([:issuer, :subject])
    |> unique_constraint([:user_id, :issuer])
  end
end
