if Code.ensure_loaded?(Ecto.Schema) do
  defmodule Relyra.Ecto.MetadataRevision do
    @moduledoc false

    use Ecto.Schema

    import Ecto.Changeset

    alias Relyra.Ecto.{Connection, MetadataSource}

    @primary_key {:id, :binary_id, autogenerate: true}
    @foreign_key_type :binary_id
    @source_kind_values [:xml_import, :remote_url]
    @trigger_values [:manual_import, :manual_refresh]
    @outcome_values [:applied, :registered, :fetch_failed, :parse_failed, :validation_failed, :apply_failed]

    schema "relyra_metadata_revisions" do
      field :source_kind, Ecto.Enum, values: @source_kind_values
      field :trigger, Ecto.Enum, values: @trigger_values
      field :outcome, Ecto.Enum, values: @outcome_values
      field :content_hash_sha256, :string
      field :effective_idp_entity_id, :string
      field :effective_idp_sso_url, :string
      field :certificate_fingerprints, {:array, :string}, default: []
      field :trust_summary, :map, default: %{}
      field :actor, :string
      field :cause, :string
      field :details, :map, default: %{}

      belongs_to :connection, Connection,
        foreign_key: :connection_record_id,
        references: :id,
        type: :binary_id

      belongs_to :metadata_source, MetadataSource,
        foreign_key: :metadata_source_id,
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
        :metadata_source_id,
        :source_kind,
        :trigger,
        :outcome,
        :content_hash_sha256,
        :effective_idp_entity_id,
        :effective_idp_sso_url,
        :certificate_fingerprints,
        :trust_summary,
        :actor,
        :cause,
        :details
      ])
      |> validate_required([
        :connection_record_id,
        :source_kind,
        :trigger,
        :outcome,
        :trust_summary
      ])
      |> validate_non_empty_map(:trust_summary)
      |> foreign_key_constraint(:connection_record_id)
      |> foreign_key_constraint(:metadata_source_id)
    end

    defp validate_non_empty_map(changeset, field) do
      case get_field(changeset, field) do
        value when value in [nil, %{}] -> add_error(changeset, field, "can't be blank")
        _value -> changeset
      end
    end
  end
else
  defmodule Relyra.Ecto.MetadataRevision do
    @moduledoc false
  end
end
