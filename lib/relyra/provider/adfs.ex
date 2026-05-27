defmodule Relyra.Provider.ADFS do
  @moduledoc false

  @behaviour Relyra.Provider

  @impl true
  def id, do: :adfs

  @impl true
  def display_name, do: "Active Directory Federation Services"

  @impl true
  def default_config do
    [
      provider_preset: :adfs,
      sign_authn_requests: true,
      signed_request_encoding: :adfs_lower,
      allow_idp_initiated?: false,
      require_signed_assertions?: true,
      require_signed_response?: true,
      algorithm_policy: %{signing: :rsa_sha256, digest: :sha256}
    ]
  end

  @impl true
  def labels do
    %{
      sp_entity_id: %{
        idp_label: "Relying Party Trust Identifier",
        idp_section: "Identifiers",
        hint: "ADFS uses this as the SAML audience"
      },
      acs_url: %{
        idp_label: "SAML Assertion Consumer Endpoint",
        idp_section: "Endpoints",
        hint: "Use the POST SAML Assertion Consumer endpoint"
      },
      idp_sso_url: %{
        idp_label: "SAML 2.0/WS-Federation URL",
        idp_section: "Endpoints",
        hint: "Typically https://<adfs-host>/adfs/ls/"
      },
      idp_certificate: %{
        idp_label: "Token-signing certificate",
        idp_section: "Certificates",
        hint: "Export the active token-signing certificate as Base-64 X.509"
      },
      signing_algorithm: %{
        idp_label: "Secure hash algorithm",
        idp_section: "Advanced",
        hint: "Use SHA-256"
      }
    }
  end

  @impl true
  def footguns do
    [
      %{
        id: :adfs_unsigned_authn_requests,
        severity: :error,
        message: "ADFS integrations should keep signed AuthnRequests enabled",
        check: fn connection ->
          if Map.get(connection, :sign_authn_requests) == false do
            {:warn, "ADFS commonly requires WantAuthnRequestsSigned-style behavior"}
          else
            :ok
          end
        end
      },
      %{
        id: :adfs_sha1,
        severity: :error,
        message: "ADFS integrations must not rely on SHA-1 signing",
        check: fn connection ->
          case connection |> Map.get(:algorithm_policy, %{}) |> Map.get(:signing) do
            :rsa_sha1 -> {:warn, "Use RSA-SHA256 instead of SHA-1"}
            :sha1 -> {:warn, "Use RSA-SHA256 instead of SHA-1"}
            _ -> :ok
          end
        end
      }
    ]
  end

  @impl true
  def guide_url,
    do:
      "https://learn.microsoft.com/en-us/windows-server/identity/ad-fs/operations/create-a-relying-party-trust"
end
