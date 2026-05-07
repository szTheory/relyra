defmodule Relyra.Telemetry.Handlers.LogAlerts do
  @moduledoc """
  Optional reference handler for Phase 21 scheduled metadata refresh
  telemetry. Emits one redaction-aware Logger line per documented
  `[:relyra, :saml, :metadata, :auto_refresh, ...]` event.

  Per D-30: NOT default-attached. Adopters opt in by calling
  `attach/0` from their `Application.start/2`. Removes the "what do I
  do with these events?" friction without coupling Relyra to any
  vendor (Slack / PagerDuty / Sentry remain host-app territory).

  Drops sensitive keys (`:xml`, `:metadata_xml`, `:certificate_pem`,
  `:pem`, `:private_key`) before the Logger formatter sees them — same
  posture as `Relyra.Log`.
  """

  require Logger

  @handler_id :relyra_auto_refresh_log_alerts

  @events [
    [:relyra, :saml, :metadata, :auto_refresh, :start],
    [:relyra, :saml, :metadata, :auto_refresh, :stop],
    [:relyra, :saml, :metadata, :auto_refresh, :exception],
    [:relyra, :saml, :metadata, :auto_refresh, :degraded],
    [:relyra, :saml, :metadata, :auto_refresh, :suspended],
    [:relyra, :saml, :metadata, :auto_refresh, :recovered],
    [:relyra, :saml, :metadata, :auto_refresh, :validity_warning],
    [:relyra, :saml, :metadata, :auto_refresh, :skipped]
  ]

  @sensitive_keys [:xml, :metadata_xml, :certificate_pem, :pem, :private_key]

  @spec attach() :: :ok | {:error, :already_exists}
  def attach do
    :telemetry.attach_many(@handler_id, @events, &__MODULE__.handle_event/4, nil)
  end

  @spec detach() :: :ok | {:error, :not_found}
  def detach, do: :telemetry.detach(@handler_id)

  @doc false
  def handle_event(
        [:relyra, :saml, :metadata, :auto_refresh, stage],
        measurements,
        metadata,
        _config
      ) do
    case stage do
      :start ->
        Logger.info("auto_refresh start " <> inspect(redact(metadata)))

      :stop ->
        level = if metadata[:outcome] == :ok, do: :info, else: :warning

        Logger.log(
          level,
          "auto_refresh stop " <> inspect(redact(Map.merge(measurements, metadata)))
        )

      :exception ->
        Logger.error(
          "auto_refresh exception " <> inspect(redact(Map.merge(measurements, metadata)))
        )

      :degraded ->
        Logger.warning("auto_refresh degraded " <> inspect(redact(metadata)))

      :suspended ->
        Logger.error("auto_refresh suspended " <> inspect(redact(metadata)))

      :recovered ->
        Logger.info("auto_refresh recovered " <> inspect(redact(metadata)))

      :validity_warning ->
        Logger.warning("auto_refresh validity warning " <> inspect(redact(metadata)))

      :skipped ->
        Logger.debug("auto_refresh skipped " <> inspect(redact(metadata)))
    end
  end

  defp redact(metadata) when is_map(metadata) do
    Map.drop(metadata, @sensitive_keys)
  end
end
