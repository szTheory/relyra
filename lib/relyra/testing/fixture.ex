defmodule Relyra.Testing.Fixture do
  @moduledoc """
  Public data container for Relyra testing fixtures.

  A fixture carries the signed test response input, matching test certificate
  material, request correlation data, and the expected verifier outcome. These
  values are test-only and are intended to be passed through the real verifier
  path with `Relyra.consume_response/3`; they are not an IdP, broker, or
  production trust source.
  """

  alias Relyra.Connection

  @enforce_keys [
    :response_xml,
    :encoded_response,
    :cert_chain,
    :idp_certificates,
    :connection,
    :request_intent,
    :relay_state,
    :expected
  ]
  defstruct [
    :response_xml,
    :encoded_response,
    :cert_chain,
    :idp_certificates,
    :connection,
    :request_intent,
    :relay_state,
    :expected
  ]

  @type t :: %__MODULE__{
          response_xml: binary(),
          encoded_response: binary(),
          cert_chain: [binary()],
          idp_certificates: [binary()],
          connection: Connection.t(),
          request_intent: map(),
          relay_state: binary() | nil,
          expected: term()
        }
end
