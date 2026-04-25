defmodule Relyra.Connection do
  @moduledoc """
  Value struct representing the resolved trust relationship for a SAML connection.
  """
  defstruct [
    :id,
    :idp_entity_id,
    :sp_entity_id,
    :acs_url,
    :idp_sso_url,
    :idp_certificates,
    :cert_chain,
    :name_id_format,
    :algorithm_policy,
    :allow_idp_initiated?,
    :require_signed_assertions?,
    :require_signed_response?,
    :clock_skew_seconds,
    :provider_preset,
    :display_name,
    :organization_id
  ]

  @type t :: %__MODULE__{
          id: binary(),
          idp_entity_id: binary(),
          sp_entity_id: binary(),
          acs_url: binary(),
          idp_sso_url: binary(),
          idp_certificates: [binary()],
          cert_chain: [binary()] | nil,
          name_id_format: binary() | nil,
          algorithm_policy: map() | nil,
          allow_idp_initiated?: boolean(),
          require_signed_assertions?: boolean(),
          require_signed_response?: boolean(),
          clock_skew_seconds: integer() | nil,
          provider_preset: atom() | nil,
          display_name: binary() | nil,
          organization_id: binary() | nil
        }
end
