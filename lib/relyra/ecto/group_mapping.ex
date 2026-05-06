if Code.ensure_loaded?(Ecto.Schema) do
  defmodule Relyra.Ecto.GroupMapping do
    @moduledoc false

    use Ecto.Schema

    import Ecto.Changeset

    alias Relyra.Ecto.Connection

    @primary_key {:id, :binary_id, autogenerate: true}
    @foreign_key_type :binary_id
    @role_target_values [:role]

    schema "relyra_group_mappings" do
      field :source_attribute, :string
      field :source_value, :string
      field :role_target, Ecto.Enum, values: @role_target_values
      field :role_value, :string

      belongs_to :connection, Connection,
        foreign_key: :connection_record_id,
        references: :id,
        type: :binary_id

      timestamps(type: :utc_datetime_usec)
    end

    @type t :: %__MODULE__{}

    @spec changeset(t(), map()) :: Ecto.Changeset.t()
    def changeset(mapping, attrs) do
      mapping
      |> cast(attrs, [
        :connection_record_id,
        :source_attribute,
        :source_value,
        :role_target,
        :role_value
      ])
      |> validate_required([
        :connection_record_id,
        :source_attribute,
        :source_value,
        :role_target,
        :role_value
      ])
      |> validate_length(:source_attribute, min: 1)
      |> validate_length(:source_value, min: 1)
      |> validate_length(:role_value, min: 1)
      |> foreign_key_constraint(:connection_record_id)
    end
  end
else
  defmodule Relyra.Ecto.GroupMapping do
    @moduledoc false
  end
end
