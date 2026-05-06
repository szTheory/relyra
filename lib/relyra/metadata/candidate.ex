defmodule Relyra.Metadata.Candidate do
  @moduledoc false

  alias Relyra.Error

  defstruct [
    :idp_entity_id,
    :idp_sso_url,
    :sso_binding,
    :provider_preset,
    :source_kind,
    :trust_summary,
    certificates: [],
    certificate_facts: [],
    certificate_pems: [],
    certificate_fingerprints: []
  ]

  @type normalized_certificate ::
          %{
            pem: binary(),
            fingerprint_sha256: binary(),
            not_before: DateTime.t(),
            not_after: DateTime.t()
          }
          | %{
              pem: binary(),
              fingerprint_sha256: binary(),
              error: Error.t()
            }

  @type t :: %__MODULE__{
          idp_entity_id: binary(),
          idp_sso_url: binary(),
          sso_binding: binary() | nil,
          provider_preset: atom() | nil,
          source_kind: atom(),
          trust_summary: map(),
          certificates: [normalized_certificate()],
          certificate_facts: [normalized_certificate()],
          certificate_pems: [binary()],
          certificate_fingerprints: [binary()]
        }

  @spec new(map()) :: t()
  def new(attrs) when is_map(attrs) do
    certificates = Map.get(attrs, :certificates, [])

    struct!(__MODULE__, %{
      idp_entity_id: Map.get(attrs, :idp_entity_id),
      idp_sso_url: Map.get(attrs, :idp_sso_url),
      sso_binding: Map.get(attrs, :sso_binding),
      provider_preset: Map.get(attrs, :provider_preset),
      source_kind: Map.get(attrs, :source_kind),
      trust_summary: Map.get(attrs, :trust_summary, %{}),
      certificates: certificates,
      # Compatibility mirrors for the Phase 09 apply path. These stay derived from
      # the canonical normalized collection to avoid drift.
      certificate_facts: certificates,
      certificate_pems: Enum.map(certificates, & &1.pem),
      certificate_fingerprints: Enum.map(certificates, & &1.fingerprint_sha256)
    })
  end
end
