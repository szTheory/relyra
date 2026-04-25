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
