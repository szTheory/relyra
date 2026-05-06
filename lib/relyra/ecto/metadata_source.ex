if Code.ensure_loaded?(Ecto.Schema) do
  defmodule Relyra.Ecto.MetadataSource do
    @moduledoc false

    use Ecto.Schema

    import Ecto.Changeset

    alias Relyra.Ecto.Connection

    @primary_key {:id, :binary_id, autogenerate: true}
    @foreign_key_type :binary_id
    @kind_values [:remote_url]
    @outcome_values [:registered, :fetch_failed, :fetched, :applied, :parse_failed, :validation_failed, :apply_failed]

    schema "relyra_metadata_sources" do
      field :url, :string
      field :kind, Ecto.Enum, values: @kind_values
      field :registered_by, :string
      field :registered_reason, :string
      field :last_fetched_at, :utc_datetime_usec
      field :last_outcome, Ecto.Enum, values: @outcome_values
      field :metadata, :map, default: %{}

      belongs_to :connection, Connection,
        foreign_key: :connection_record_id,
        references: :id,
        type: :binary_id

      timestamps(type: :utc_datetime_usec)
    end

    @type t :: %__MODULE__{}

    @spec changeset(t(), map()) :: Ecto.Changeset.t()
    def changeset(source, attrs) do
      source
      |> cast(attrs, [
        :connection_record_id,
        :url,
        :kind,
        :registered_by,
        :registered_reason,
        :last_fetched_at,
        :last_outcome,
        :metadata
      ])
      |> validate_required([:connection_record_id, :url, :kind, :registered_by, :registered_reason])
      |> validate_change(:url, &validate_https_url/2)
      |> unique_constraint(:connection_record_id)
      |> foreign_key_constraint(:connection_record_id)
    end

    defp validate_https_url(:url, value) when is_binary(value) do
      case URI.parse(value) do
        %URI{scheme: "https", host: host} when is_binary(host) and host != "" ->
          []

        _ ->
          [url: "must be an HTTPS URL"]
      end
    end

    defp validate_https_url(:url, _value), do: [url: "must be an HTTPS URL"]
  end
else
  defmodule Relyra.Ecto.MetadataSource do
    @moduledoc false
  end
end
