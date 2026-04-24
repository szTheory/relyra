defmodule Relyra.ConnectionResolver do
  @moduledoc """
  Public extension contract for resolving the SAML connection context.

  The returned connection map is consumed by protocol core and must include:

  - `:connection_id`
  - `:idp_entity_id`
  - `:sp_entity_id`
  - `:acs_url`
  - `:idp_sso_url`
  - `:cert_chain`
  """

  alias Relyra.Error

  # Verification anchor: @callback resolve_connection(request_context, opts  [])
  @callback resolve_connection(request_context :: map(), opts :: keyword()) ::
              {:ok, map()} | {:error, Error.t()}
end
