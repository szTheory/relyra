if Code.ensure_loaded?(Ecto.Schema) do
  defmodule Relyra.Ecto.Connection.RuntimePolicy do
    @moduledoc false

    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false

    embedded_schema do
      field :allow_idp_initiated?, :boolean, default: false
      field :require_signed_assertions?, :boolean, default: true
      field :require_signed_response?, :boolean, default: true
      field :clock_skew_seconds, :integer
      field :name_id_format, :string
      field :algorithm_policy, :map, default: %{}
    end

    @type t :: %__MODULE__{
            allow_idp_initiated?: boolean(),
            require_signed_assertions?: boolean(),
            require_signed_response?: boolean(),
            clock_skew_seconds: integer() | nil,
            name_id_format: String.t() | nil,
            algorithm_policy: map()
          }

    @spec changeset(t(), map()) :: Ecto.Changeset.t()
    def changeset(policy, attrs) do
      policy
      |> cast(attrs, [
        :allow_idp_initiated?,
        :require_signed_assertions?,
        :require_signed_response?,
        :clock_skew_seconds,
        :name_id_format,
        :algorithm_policy
      ])
      |> validate_number(:clock_skew_seconds, greater_than_or_equal_to: 0)
    end
  end
else
  defmodule Relyra.Ecto.Connection.RuntimePolicy do
    @moduledoc false
  end
end
