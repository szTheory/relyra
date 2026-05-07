defmodule Relyra.Telemetry do
  @moduledoc """
  Telemetry catalog for Relyra SAML events.

  Relyra emits events using the `[:relyra, :saml, event_name, stage]` namespace.
  Each event follows the `:start`, `:stop`, and `:exception` triplet pattern and
  reports durations in `duration_ms`.

  ## Events

  ### login
  Emitted when an SP-initiated login flow starts.
  - Namespace: `[:relyra, :saml, :login]`
  - Measurements: `[:duration_ms]`
  - Metadata: `[:connection_id, :organization_id, :provider_preset, :flow, :binding, :outcome, :error_code]`

  ### authn_request
  Emitted when a SAML AuthnRequest is generated.
  - Namespace: `[:relyra, :saml, :authn_request]`
  - Measurements: `[:duration_ms, :xml_bytes, :base64_bytes, :request_store_latency_ms]`
  - Metadata: `[:connection_id, :organization_id, :provider_preset, :flow, :binding, :outcome, :error_code]`

  ### response.decode
  Emitted when an inbound SAMLResponse is base64-decoded and inflated.
  - Namespace: `[:relyra, :saml, :response, :decode]`
  - Measurements: `[:duration_ms, :base64_bytes, :xml_bytes]`
  - Metadata: `[:connection_id, :binding, :flow, :outcome, :error_code]`

  ### response.validate
  Emitted during the SAML protocol validation pipeline.
  - Namespace: `[:relyra, :saml, :response, :validate]`
  - Measurements: `[:duration_ms, :assertion_count]`
  - Metadata: `[:connection_id, :flow, :outcome, :error_code]`

  ### signature.verify
  Emitted when verifying XML signatures.
  - Namespace: `[:relyra, :saml, :signature, :verify]`
  - Measurements: `[:duration_ms]`
  - Metadata: `[:connection_id, :outcome, :error_code, :signature_algorithm, :digest_algorithm]`

  ### replay.check
  Emitted when checking for replayed assertions.
  - Namespace: `[:relyra, :saml, :replay, :check]`
  - Measurements: `[:duration_ms, :replay_store_latency_ms]`
  - Metadata: `[:connection_id, :issuer, :assertion_id, :outcome, :error_code]`

  ### user.map
  Emitted when mapping SAML principal to a host user.
  - Namespace: `[:relyra, :saml, :user, :map]`
  - Measurements: `[:duration_ms, :attribute_count]`
  - Metadata: `[:connection_id, :flow, :outcome, :error_code]`

  ### session.establish
  Emitted when handing off to the host session adapter.
  - Namespace: `[:relyra, :saml, :session, :establish]`
  - Measurements: `[:duration_ms]`
  - Metadata: `[:connection_id, :flow, :outcome, :error_code]`

  ### metadata.refresh
  Emitted when an operator-triggered metadata refresh starts or stops.
  - Namespace: `[:relyra, :saml, :metadata, :refresh]`
  - Measurements: `[:duration_ms]`
  - Metadata: `[:connection_id, :metadata_source_id, :source_kind, :trigger, :outcome, :error_code, :certificate_count]`

  ### metadata.import
  Emitted when an operator-triggered local XML import starts or stops.
  - Namespace: `[:relyra, :saml, :metadata, :import]`
  - Measurements: `[:duration_ms]`
  - Metadata: `[:connection_id, :source_kind, :trigger, :outcome, :error_code, :certificate_count]`

  ### metadata.auto_refresh
  Phase 21 scheduled metadata refresh. SEPARATE namespace from
  `metadata.refresh` per D-23: adopters can attach the "page me" handler
  only to the unattended channel.

  - Namespace: `[:relyra, :saml, :metadata, :auto_refresh]`

  Per-attempt span events (`Telemetry.span/3`):
  - `[:relyra, :saml, :metadata, :auto_refresh, :start]`
  - `[:relyra, :saml, :metadata, :auto_refresh, :stop]`
  - `[:relyra, :saml, :metadata, :auto_refresh, :exception]`
    - Measurements: `[:duration_ms]`
    - Metadata: `[:connection_id, :metadata_source_id, :source_kind, :trigger, :correlation_id, :outcome, :error_code, :certificate_count, :transient?, :counts_toward_suspend?]`

  State-transition events (one-shot, not span-bracketed):
  - `[:relyra, :saml, :metadata, :auto_refresh, :degraded]` — first
    transient failure that increments `consecutive_failure_count` (D-24)
  - `[:relyra, :saml, :metadata, :auto_refresh, :suspended]` — the
    attempt that crossed `consecutive_failure_count >= 5` and set
    `auto_suspended_until` (D-24, D-25)
  - `[:relyra, :saml, :metadata, :auto_refresh, :recovered]` — successful
    probe after a suspended period; counters reset to 0 (D-24, Pitfall 6)
    - Measurements: `%{}`
    - Metadata: `[:connection_id, :metadata_source_id, :consecutive_failure_count, :auto_suspended_until, :auto_suspended_reason, :error_code]`

  Validity warning event (at-most-once per validUntil window per source):
  - `[:relyra, :saml, :metadata, :auto_refresh, :validity_warning]` (D-14)
    - Measurements: `%{}`
    - Metadata: `[:connection_id, :metadata_source_id, :valid_until, :refresh_interval_seconds]`

  Empty-tick event:
  - `[:relyra, :saml, :metadata, :auto_refresh, :skipped]` (D-07)
    - Measurements: `%{}`
    - Metadata: `[:correlation_id, :count]`

  ### certificate.expiring
  Emitted when a SAML certificate is nearing expiration.
  - Namespace: `[:relyra, :saml, :certificate, :expiring]`
  - Measurements: `[:days_until_expiry]`
  - Metadata: `[:connection_id, :certificate_id, :fingerprint_sha256, :not_after]`

  Optional reference handler: `Relyra.Telemetry.Handlers.LogAlerts`
  (D-30, NOT default-attached). Adopters call
  `Relyra.Telemetry.Handlers.LogAlerts.attach/0` from their
  `Application.start/2` to opt in.
  """

  @doc false
  def execute(event, measurements, metadata \\ %{}) do
    :telemetry.execute([:relyra, :saml | List.wrap(event)], measurements, metadata)
  end

  @doc false
  def span(event, metadata, span_fun) do
    event_name = [:relyra, :saml | List.wrap(event)]
    start_metadata = normalize_metadata(metadata)
    start_time = System.monotonic_time()

    emit(event_name ++ [:start], %{system_time: System.system_time()}, start_metadata)

    try do
      case span_fun.() do
        {result, stop_metadata} ->
          stop_metadata = normalize_metadata(stop_metadata)

          emit(
            event_name ++ [:stop],
            %{duration_ms: duration_ms(start_time)},
            Map.merge(start_metadata, stop_metadata)
          )

          result

        result ->
          emit(
            event_name ++ [:stop],
            %{duration_ms: duration_ms(start_time)},
            start_metadata
          )

          result
      end
    rescue
      exception ->
        emit(
          event_name ++ [:exception],
          %{duration_ms: duration_ms(start_time)},
          Map.merge(start_metadata, %{
            kind: :error,
            reason: Exception.message(exception)
          })
        )

        reraise exception, __STACKTRACE__
    catch
      kind, reason ->
        emit(
          event_name ++ [:exception],
          %{duration_ms: duration_ms(start_time)},
          Map.merge(start_metadata, %{kind: kind, reason: inspect(reason)})
        )

        case kind do
          :throw -> throw(reason)
          :exit -> exit(reason)
          :error -> :erlang.error(reason)
        end
    end
  end

  defp normalize_metadata(metadata) when is_map(metadata), do: metadata
  defp normalize_metadata(nil), do: %{}
  defp normalize_metadata(metadata) when is_list(metadata), do: Map.new(metadata)

  defp duration_ms(start_time) do
    System.convert_time_unit(System.monotonic_time() - start_time, :native, :millisecond)
  end

  defp emit(event_name, measurements, metadata) do
    :telemetry.execute(event_name, measurements, metadata)
  end
end
