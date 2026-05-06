if Code.ensure_loaded?(Ecto.Schema) do
  defmodule Relyra.Ecto.Connection do
    @moduledoc false

    use Ecto.Schema

    import Ecto.Changeset

    alias Relyra.Ecto.{
      AttributeMapping,
      AuditEvent,
      Certificate,
      GroupMapping,
      MappingRevision,
      MetadataRevision
    }

    alias Relyra.Ecto.Connection.RuntimePolicy
    alias Relyra.Error

    @primary_key {:id, :binary_id, autogenerate: true}
    @foreign_key_type :binary_id
    @provider_presets [:okta, :entra, :google_workspace]
    @ulid_length 26
    @ulid_alphabet ~c"0123456789ABCDEFGHJKMNPQRSTVWXYZ"
    @ulid_pattern ~r/^[0-9A-HJKMNP-TV-Z]{26}$/

    schema "relyra_connections" do
      # Stored as a string but validated/generated as an Ecto.ULID-shaped public id.
      field :connection_id, :string
      field :display_name, :string
      field :organization_id, :string
      field :status, Ecto.Enum, values: [:draft, :enabled, :disabled], default: :draft
      field :provider_preset, Ecto.Enum, values: @provider_presets
      field :sp_entity_id, :string
      field :acs_url, :string
      field :idp_entity_id, :string
      field :idp_sso_url, :string
      field :allow_idp_initiated, :boolean, default: false
      field :lock_version, :integer, default: 1

      belongs_to :active_metadata_revision, MetadataRevision,
        foreign_key: :active_metadata_revision_id,
        references: :id,
        type: :binary_id

      belongs_to :last_known_good_metadata_revision, MetadataRevision,
        foreign_key: :last_known_good_metadata_revision_id,
        references: :id,
        type: :binary_id

      embeds_one :runtime_policy, RuntimePolicy, on_replace: :update
      has_many :certificates, Certificate, foreign_key: :connection_record_id, on_replace: :delete

      has_many :attribute_mappings, AttributeMapping,
        foreign_key: :connection_record_id,
        on_replace: :delete

      has_many :group_mappings, GroupMapping,
        foreign_key: :connection_record_id,
        on_replace: :delete

      has_many :mapping_revisions, MappingRevision, foreign_key: :connection_record_id
      has_many :audit_events, AuditEvent, foreign_key: :connection_record_id

      field :readiness_errors, :map, virtual: true, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    @runtime_required_fields [
      :connection_id,
      :sp_entity_id,
      :acs_url,
      :idp_entity_id,
      :idp_sso_url
    ]

    @type t :: %__MODULE__{}

    @active_signing_cert_filters [role: :signing, lifecycle_state: :active]

    @spec draft_changeset(t(), map()) :: Ecto.Changeset.t()
    def draft_changeset(connection, attrs) do
      connection
      |> cast(attrs, [
        :connection_id,
        :display_name,
        :organization_id,
        :status,
        :provider_preset,
        :sp_entity_id,
        :acs_url,
        :idp_entity_id,
        :idp_sso_url,
        :allow_idp_initiated,
        :active_metadata_revision_id,
        :last_known_good_metadata_revision_id
      ])
      |> cast_embed(:runtime_policy, with: &RuntimePolicy.changeset/2)
      |> cast_assoc(:certificates, with: &Certificate.changeset/2)
      |> reject_mapping_updates(attrs)
      |> put_generated_connection_id()
      |> put_default_status()
      |> validate_format(:connection_id, @ulid_pattern)
      |> validate_length(:connection_id, is: @ulid_length)
      |> unique_constraint(:connection_id)
    end

    @spec update_changeset(t(), map()) :: Ecto.Changeset.t()
    def update_changeset(connection, attrs) do
      connection
      |> cast(attrs, [
        :display_name,
        :organization_id,
        :status,
        :provider_preset,
        :sp_entity_id,
        :acs_url,
        :idp_entity_id,
        :idp_sso_url,
        :allow_idp_initiated,
        :active_metadata_revision_id,
        :last_known_good_metadata_revision_id
      ])
      |> cast_embed(:runtime_policy, with: &RuntimePolicy.changeset/2)
      |> reject_certificate_updates(attrs)
      |> reject_mapping_updates(attrs)
      |> validate_format(:connection_id, @ulid_pattern)
      |> validate_length(:connection_id, is: @ulid_length)
      |> unique_constraint(:connection_id)
    end

    @spec publish_changeset(t(), map()) :: Ecto.Changeset.t()
    def publish_changeset(connection, attrs) do
      connection
      |> update_changeset(Map.put(attrs, :status, :enabled))
      |> validate_runtime_ready()
    end

    @spec disable_changeset(t()) :: Ecto.Changeset.t()
    def disable_changeset(connection) do
      change(connection, status: :disabled)
    end

    @spec runtime_ready(t()) :: :ok | {:error, Error.t()}
    def runtime_ready(%__MODULE__{} = connection) do
      missing_fields =
        Enum.filter(@runtime_required_fields, fn field ->
          value = Map.get(connection, field)
          is_nil(value) or value == ""
        end)

      cond do
        connection.status != :enabled ->
          {:error,
           Error.new(
             :connection_not_runtime_ready,
             "Connection must be enabled before runtime use",
             %{
               reason: :not_enabled
             }
           )}

        missing_fields != [] ->
          {:error,
           Error.new(
             :connection_not_runtime_ready,
             "Connection is missing runtime fields",
             %{missing: missing_fields}
           )}

        active_signing_certificates(connection) == [] ->
          {:error,
           Error.new(
             :connection_not_runtime_ready,
             "Connection requires at least one active signing certificate before runtime use",
             %{reason: :missing_certificates}
           )}

        Enum.any?(active_signing_certificates(connection), &invalid_certificate?/1) ->
          {:error,
           Error.new(
             :connection_not_runtime_ready,
             "Connection active signing certificates must include PEM data and fingerprints",
             %{reason: :invalid_certificates}
           )}

        true ->
          :ok
      end
    end

    defp put_default_status(changeset) do
      case get_field(changeset, :status) do
        nil -> put_change(changeset, :status, :draft)
        _status -> changeset
      end
    end

    defp put_generated_connection_id(changeset) do
      case get_field(changeset, :connection_id) do
        nil -> put_change(changeset, :connection_id, generate_ulid())
        "" -> put_change(changeset, :connection_id, generate_ulid())
        _connection_id -> changeset
      end
    end

    defp reject_certificate_updates(changeset, attrs) do
      if Map.has_key?(attrs, :certificates) or Map.has_key?(attrs, "certificates") do
        add_error(
          changeset,
          :certificates,
          "are managed through metadata apply or Relyra.Ecto.CertificateInventory"
        )
      else
        changeset
      end
    end

    defp reject_mapping_updates(changeset, attrs) do
      changeset
      |> reject_mapping_update(attrs, :attribute_mappings)
      |> reject_mapping_update(attrs, :group_mappings)
    end

    defp reject_mapping_update(changeset, attrs, field) do
      string_field = Atom.to_string(field)

      if Map.has_key?(attrs, field) or Map.has_key?(attrs, string_field) do
        add_error(
          changeset,
          field,
          "are managed through dedicated mapping persistence commands"
        )
      else
        changeset
      end
    end

    defp validate_runtime_ready(changeset) do
      connection = %{apply_changes(changeset) | status: :enabled}

      missing_fields =
        Enum.filter(@runtime_required_fields, fn field ->
          value = Map.get(connection, field)
          is_nil(value) or value == ""
        end)

      changeset =
        Enum.reduce(missing_fields, changeset, fn field, acc ->
          add_error(acc, field, "is required before enable")
        end)

      cond do
        active_signing_certificates(connection) == [] ->
          add_error(
            changeset,
            :certificates,
            "must include at least one active signing certificate"
          )

        Enum.any?(active_signing_certificates(connection), &invalid_certificate?/1) ->
          add_error(
            changeset,
            :certificates,
            "must include valid active signing certificate PEM and fingerprint data"
          )

        true ->
          changeset
      end
    end

    defp invalid_certificate?(certificate) do
      blank?(Map.get(certificate, :fingerprint_sha256)) or blank?(Map.get(certificate, :pem))
    end

    defp active_signing_certificates(connection) do
      connection
      |> Map.get(:certificates, [])
      |> Enum.filter(fn certificate ->
        Enum.all?(@active_signing_cert_filters, fn {field, value} ->
          Map.get(certificate, field, value) == value
        end)
      end)
    end

    defp blank?(value), do: is_nil(value) or value == ""

    defp generate_ulid do
      timestamp = System.system_time(:millisecond)
      entropy = :crypto.strong_rand_bytes(10)
      <<timestamp::unsigned-big-integer-size(48), entropy::binary>> |> encode_ulid()
    end

    defp encode_ulid(binary), do: do_encode_ulid(:binary.decode_unsigned(binary), [])

    defp do_encode_ulid(0, []), do: String.duplicate("0", @ulid_length)

    defp do_encode_ulid(value, encoded) when length(encoded) < @ulid_length do
      index = rem(value, 32)
      next_value = div(value, 32)
      do_encode_ulid(next_value, [Enum.at(@ulid_alphabet, index) | encoded])
    end

    defp do_encode_ulid(_value, encoded) do
      encoded
      |> List.to_string()
      |> String.pad_leading(@ulid_length, "0")
    end
  end
else
  defmodule Relyra.Ecto.Connection do
    @moduledoc false
  end
end
