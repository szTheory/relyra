defmodule Relyra.Telemetry do
  @moduledoc """
  Telemetry catalog for Relyra SAML events.

  Relyra emits events using the `[:relyra, :saml, event_name, stage]` namespace.
  Each event follows the `:start`, `:stop`, and `:exception` triplet pattern.

  ## Events

  ### login
  Emitted when an SP-initiated login flow starts.
  - Namespace: `[:relyra, :saml, :login]`
  - Measurements: `[:duration, :monotonic_time, :system_time]`
  - Metadata: `[:connection_id, :organization_id, :provider_preset, :flow, :outcome, :error_code]`

  ### authn_request
  Emitted when a SAML AuthnRequest is generated.
  - Namespace: `[:relyra, :saml, :authn_request]`
  - Measurements: `[:duration, :xml_bytes]`
  - Metadata: `[:connection_id, :outcome, :error_code]`

  ### response.decode
  Emitted when an inbound SAMLResponse is base64-decoded and inflated.
  - Namespace: `[:relyra, :saml, :response, :decode]`
  - Measurements: `[:duration, :base64_bytes, :xml_bytes]`
  - Metadata: `[:connection_id, :binding, :outcome, :error_code]`

  ### response.validate
  Emitted during the SAML protocol validation pipeline.
  - Namespace: `[:relyra, :saml, :response, :validate]`
  - Measurements: `[:duration, :assertion_count]`
  - Metadata: `[:connection_id, :outcome, :error_code, :validation_step]`

  ### signature.verify
  Emitted when verifying XML signatures.
  - Namespace: `[:relyra, :saml, :signature, :verify]`
  - Measurements: `[:duration]`
  - Metadata: `[:connection_id, :outcome, :error_code, :signature_algorithm, :digest_algorithm]`

  ### replay.check
  Emitted when checking for replayed assertions.
  - Namespace: `[:relyra, :saml, :replay, :check]`
  - Measurements: `[:duration, :replay_store_latency_ms]`
  - Metadata: `[:connection_id, :outcome, :error_code]`

  ### user.map
  Emitted when mapping SAML principal to a host user.
  - Namespace: `[:relyra, :saml, :user, :map]`
  - Measurements: `[:duration, :attribute_count]`
  - Metadata: `[:connection_id, :outcome, :error_code]`

  ### session.establish
  Emitted when handing off to the host session adapter.
  - Namespace: `[:relyra, :saml, :session, :establish]`
  - Measurements: `[:duration]`
  - Metadata: `[:connection_id, :outcome, :error_code]`
  """

  @doc false
  def execute(event, measurements, metadata \\ %{}) do
    :telemetry.execute([:relyra, :saml | List.wrap(event)], measurements, metadata)
  end

  @doc false
  def span(event, metadata, span_fun) do
    :telemetry.span([:relyra, :saml | List.wrap(event)], metadata, span_fun)
  end
end
