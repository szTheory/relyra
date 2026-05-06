if Code.ensure_loaded?(Ecto.Schema) do
  defmodule Relyra.Ecto.MappingRevision do
    @moduledoc false

    use Ecto.Schema

    import Ecto.Changeset

    alias Relyra.Ecto.Connection

    @primary_key {:id, :binary_id, autogenerate: true}
    @foreign_key_type :binary_id
    @action_values [:created, :replaced, :deleted]
    @max_map_entries 32
    @max_list_entries 32
    @max_binary_bytes 512

    schema "relyra_mapping_revisions" do
      field :actor, :string
      field :action, Ecto.Enum, values: @action_values
      field :cause, :string
      field :correlation_id, :string
      field :before_snapshot, :map, default: %{}
      field :after_snapshot, :map, default: %{}
      field :diff_summary, :map, default: %{}

      belongs_to :connection, Connection,
        foreign_key: :connection_record_id,
        references: :id,
        type: :binary_id

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    @type t :: %__MODULE__{}

    @spec changeset(t(), map()) :: Ecto.Changeset.t()
    def changeset(revision, attrs) do
      revision
      |> cast(attrs, [
        :connection_record_id,
        :actor,
        :action,
        :cause,
        :correlation_id,
        :before_snapshot,
        :after_snapshot,
        :diff_summary
      ])
      |> validate_required([
        :connection_record_id,
        :actor,
        :action,
        :cause,
        :before_snapshot,
        :after_snapshot,
        :diff_summary
      ])
      |> validate_length(:actor, min: 1)
      |> validate_length(:cause, min: 1)
      |> validate_bounded_map(:before_snapshot, allow_empty?: true)
      |> validate_bounded_map(:after_snapshot)
      |> validate_bounded_map(:diff_summary)
      |> foreign_key_constraint(:connection_record_id)
    end

    defp validate_bounded_map(changeset, field, opts \\ []) do
      allow_empty? = Keyword.get(opts, :allow_empty?, false)

      case get_field(changeset, field) do
        value when is_map(value) ->
          cond do
            value == %{} and not allow_empty? -> add_error(changeset, field, "can't be blank")
            map_size(value) > @max_map_entries -> add_error(changeset, field, "is too large")
            oversized_value?(value) -> add_error(changeset, field, "contains oversized values")
            true -> changeset
          end

        nil ->
          changeset

        _other ->
          add_error(changeset, field, "must be a map")
      end
    end

    defp oversized_value?(value) when is_map(value) do
      map_size(value) > @max_map_entries or
        Enum.any?(value, fn {_key, nested} -> oversized_value?(nested) end)
    end

    defp oversized_value?(value) when is_list(value) do
      length(value) > @max_list_entries or Enum.any?(value, &oversized_value?/1)
    end

    defp oversized_value?(value) when is_binary(value), do: byte_size(value) > @max_binary_bytes
    defp oversized_value?(_value), do: false
  end
else
  defmodule Relyra.Ecto.MappingRevision do
    @moduledoc false
  end
end
