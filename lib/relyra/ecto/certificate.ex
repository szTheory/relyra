if Code.ensure_loaded?(Ecto.Schema) do
  defmodule Relyra.Ecto.Certificate do
    @moduledoc false

    use Ecto.Schema

    import Ecto.Changeset

    alias Relyra.Ecto.Connection

    @roles [:signing]
    @lifecycle_states [:active, :next, :retired]

    @primary_key {:id, :binary_id, autogenerate: true}
    @foreign_key_type :binary_id

    schema "relyra_connection_certificates" do
      field :fingerprint_sha256, :string
      field :pem, :string
      field :source, :string
      field :role, Ecto.Enum, values: @roles, default: :signing
      field :lifecycle_state, Ecto.Enum, values: @lifecycle_states, default: :active
      field :not_before, :utc_datetime_usec
      field :not_after, :utc_datetime_usec
      field :staged_at, :utc_datetime_usec
      field :activated_at, :utc_datetime_usec
      field :retired_at, :utc_datetime_usec
      field :metadata, :map, default: %{}
      field :party, Ecto.Enum, values: [:idp, :sp], default: :idp
      field :use, Ecto.Enum, values: [:signing, :encryption], default: :signing

      belongs_to :connection, Connection,
        foreign_key: :connection_record_id,
        references: :id,
        type: :binary_id

      timestamps(type: :utc_datetime_usec)
    end

    @type t :: %__MODULE__{}

    @spec changeset(t(), map()) :: Ecto.Changeset.t()
    def changeset(certificate, attrs) do
      certificate
      |> cast(attrs, [
        :connection_record_id,
        :fingerprint_sha256,
        :pem,
        :source,
        :role,
        :lifecycle_state,
        :not_before,
        :not_after,
        :staged_at,
        :activated_at,
        :retired_at,
        :metadata,
        :party,
        :use
      ])
      |> validate_required([:fingerprint_sha256, :pem, :source])
      |> put_defaults()
      |> validate_timestamp_consistency()
      |> unique_constraint(:fingerprint_sha256,
        name: :relyra_connection_certificates_connection_record_id_fingerprint_sha256_index
      )
      |> foreign_key_constraint(:connection_record_id)
    end

    defp put_defaults(changeset) do
      changeset
      |> put_change_unless_present(:role, :signing)
      |> put_change_unless_present(:lifecycle_state, :active)
      |> put_change_unless_present(:party, :idp)
      |> put_change_unless_present(:use, :signing)
      |> put_default_timestamp(:activated_at, :lifecycle_state, :active)
      |> put_default_timestamp(:staged_at, :lifecycle_state, :next)
      |> clear_timestamp_when_not_state(:staged_at, :lifecycle_state, :next)
      |> clear_timestamp_when_not_state(:activated_at, :lifecycle_state, :active)
      |> clear_timestamp_when_not_state(:retired_at, :lifecycle_state, :retired)
    end

    defp validate_timestamp_consistency(changeset) do
      lifecycle_state = get_field(changeset, :lifecycle_state)

      changeset
      |> require_timestamp_for_state(:staged_at, lifecycle_state, :next)
      |> require_timestamp_for_state(:activated_at, lifecycle_state, :active)
      |> require_timestamp_for_state(:retired_at, lifecycle_state, :retired)
    end

    defp put_change_unless_present(changeset, field, value) do
      case get_field(changeset, field) do
        nil -> put_change(changeset, field, value)
        _present -> changeset
      end
    end

    defp put_default_timestamp(changeset, timestamp_field, state_field, state) do
      if get_field(changeset, state_field) == state and
           is_nil(get_field(changeset, timestamp_field)) do
        put_change(changeset, timestamp_field, DateTime.utc_now())
      else
        changeset
      end
    end

    defp clear_timestamp_when_not_state(changeset, timestamp_field, state_field, state) do
      if get_field(changeset, state_field) == state do
        changeset
      else
        put_change(changeset, timestamp_field, nil)
      end
    end

    defp require_timestamp_for_state(changeset, timestamp_field, lifecycle_state, required_state) do
      if lifecycle_state == required_state and is_nil(get_field(changeset, timestamp_field)) do
        add_error(changeset, timestamp_field, "is required for #{required_state} certificates")
      else
        changeset
      end
    end
  end
else
  defmodule Relyra.Ecto.Certificate do
    @moduledoc false
  end
end
