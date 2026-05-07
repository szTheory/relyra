if Code.ensure_loaded?(Ecto.Schema) do
  defmodule Relyra.Ecto.MetadataSource do
    @moduledoc false

    use Ecto.Schema

    import Ecto.Changeset

    alias Relyra.Ecto.Connection

    @primary_key {:id, :binary_id, autogenerate: true}
    @foreign_key_type :binary_id
    @kind_values [:remote_url]
    @outcome_values [
      :registered,
      :fetch_failed,
      :fetched,
      :applied,
      :parse_failed,
      :validation_failed,
      :apply_failed
    ]
    @cadence_values [:hourly, :every_6h, :daily, :weekly]
    @suspended_reason_values [
      :entity_id_drift,
      :new_signing_cert,
      :signature_invalid,
      :corpus_violation,
      :transient_failures_exceeded,
      :trust_anchor_mismatch
    ]

    schema "relyra_metadata_sources" do
      field :url, :string
      field :kind, Ecto.Enum, values: @kind_values
      field :registered_by, :string
      field :registered_reason, :string
      field :last_fetched_at, :utc_datetime_usec
      field :last_outcome, Ecto.Enum, values: @outcome_values
      field :metadata, :map, default: %{}

      # Phase 21 auto-refresh fields (in migration column order):
      field :auto_refresh_enabled, :boolean, default: false
      field :refresh_cadence, Ecto.Enum, values: @cadence_values, default: :daily
      field :next_refresh_at, :utc_datetime_usec
      field :require_signed_metadata, :boolean, default: true
      field :metadata_trust_fingerprints, {:array, :string}, default: []
      field :legacy_unsigned_metadata_policy, :map
      field :last_known_metadata_signing_certs, {:array, :string}, default: []
      field :consecutive_failure_count, :integer, default: 0
      field :first_failure_at, :utc_datetime_usec
      field :last_success_at, :utc_datetime_usec
      field :last_failure_error_code, :string
      field :last_validity_warning_for, :utc_datetime_usec
      field :auto_suspended_until, :utc_datetime_usec
      field :auto_suspended_reason, Ecto.Enum, values: @suspended_reason_values

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
      |> validate_required([
        :connection_record_id,
        :url,
        :kind,
        :registered_by,
        :registered_reason
      ])
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

    @doc """
    Operator-facing changeset for the auto-refresh sub-domain (D-09).

    Used by the admin LiveView and the planned `mix relyra.metadata.pin` task.
    Enforces the great-error invariant: cannot enable auto-refresh on a source
    without first pinning at least one SHA-256 trust fingerprint
    (TOFU-rejection precondition; D-17).

    Whitelist of cast fields explicitly excludes health-state columns
    (consecutive_failure_count, auto_suspended_until, etc.) so an operator
    cannot mutate health state through the operator-facing path (D-28).
    """
    @spec auto_refresh_changeset(t(), map()) :: Ecto.Changeset.t()
    def auto_refresh_changeset(source, attrs) do
      source
      |> cast(attrs, [
        :auto_refresh_enabled,
        :refresh_cadence,
        :next_refresh_at,
        :require_signed_metadata,
        :metadata_trust_fingerprints,
        :legacy_unsigned_metadata_policy
      ])
      |> validate_required([:auto_refresh_enabled, :refresh_cadence])
      |> validate_fingerprints_when_enabled()
    end

    @doc """
    Health-state changeset called ONLY from `Relyra.Ecto.MetadataApply.record_attempt/3`
    and `apply_revision/4` per D-28 (single audit-writer seam — no parallel audit/health
    writer). Never call from LiveView, Mix tasks, or any user-facing path.
    """
    @spec health_state_changeset(t(), map()) :: Ecto.Changeset.t()
    def health_state_changeset(source, attrs) do
      source
      |> cast(attrs, [
        :consecutive_failure_count,
        :first_failure_at,
        :last_success_at,
        :last_failure_error_code,
        :last_validity_warning_for,
        :auto_suspended_until,
        :auto_suspended_reason,
        :next_refresh_at,
        :last_known_metadata_signing_certs
      ])
    end

    defp validate_fingerprints_when_enabled(changeset) do
      enabled? = get_field(changeset, :auto_refresh_enabled)
      fingerprints = get_field(changeset, :metadata_trust_fingerprints) || []

      if enabled? == true and fingerprints == [] do
        add_error(
          changeset,
          :metadata_trust_fingerprints,
          "is required when auto_refresh_enabled is true; pin at least one SHA-256 fingerprint via the admin LiveView (or `mix relyra.metadata.pin`) before enabling auto-refresh"
        )
      else
        changeset
      end
    end
  end
else
  defmodule Relyra.Ecto.MetadataSource do
    @moduledoc false
  end
end
