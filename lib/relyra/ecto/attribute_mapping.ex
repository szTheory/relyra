if Code.ensure_loaded?(Ecto.Schema) do
  defmodule Relyra.Ecto.AttributeMapping do
    @moduledoc false

    use Ecto.Schema

    import Ecto.Changeset

    alias Relyra.Ecto.Connection

    @primary_key {:id, :binary_id, autogenerate: true}
    @foreign_key_type :binary_id
    @target_field_values [:email, :first_name, :last_name, :display_name, :name_id]
    @multivalue_strategy_values [:first, :all]

    schema "relyra_attribute_mappings" do
      field :source_attribute, :string
      field :target_field, Ecto.Enum, values: @target_field_values
      field :multivalue_strategy, Ecto.Enum, values: @multivalue_strategy_values

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
        :target_field,
        :multivalue_strategy
      ])
      |> validate_required([
        :connection_record_id,
        :source_attribute,
        :target_field,
        :multivalue_strategy
      ])
      |> validate_length(:source_attribute, min: 1)
      |> foreign_key_constraint(:connection_record_id)
    end
  end
else
  defmodule Relyra.Ecto.AttributeMapping do
    @moduledoc false
  end
end
