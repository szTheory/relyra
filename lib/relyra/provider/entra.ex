defmodule Relyra.Provider.Entra do
  @moduledoc false

  @behaviour Relyra.Provider

  @impl true
  def id, do: :entra

  @impl true
  def display_name, do: "Microsoft Entra ID"

  @impl true
  def default_config do
    [
      provider_preset: :entra,
      allow_idp_initiated?: false,
      require_signed_assertions?: true,
      require_signed_response?: true,
      name_id_format: "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent",
      algorithm_policy: %{
        signing: :rsa_sha256,
        digest: :sha256
      }
    ]
  end

  @impl true
  def labels do
    %{
      sp_entity_id: %{
        idp_label: "Identifier (Entity ID)",
        idp_section: "Basic SAML Configuration",
        hint: "Must match the app registration exactly"
      },
      acs_url: %{
        idp_label: "Reply URL (Assertion Consumer Service URL)",
        idp_section: "Basic SAML Configuration"
      },
      idp_sso_url: %{
        idp_label: "Login URL",
        idp_section: "Set up",
        hint: "Copy from the Entra SAML metadata"
      },
      idp_certificate: %{
        idp_label: "Certificate (Base64)",
        idp_section: "SAML Signing Certificate"
      },
      name_id_format: %{
        idp_label: "Name ID format",
        idp_section: "Attributes & Claims",
        hint: "Persistent is the safest default"
      },
      signing_algorithm: %{
        idp_label: "Sign SAML response",
        idp_section: "SAML Signing Certificate"
      }
    }
  end

  @impl true
  def footguns do
    [
      %{
        id: :entra_nameid_format,
        severity: :warning,
        message: "Entra works best with persistent NameID values",
        check: fn connection ->
          if Map.get(connection, :name_id_format) in [nil, "", "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent"] do
            :ok
          else
            {:warn, "Use persistent NameID unless you have a clear claim-mapping reason not to"}
          end
        end
      },
      %{
        id: :entra_idp_initiated,
        severity: :warning,
        message: "IdP-initiated login should be explicit",
        check: fn connection ->
          if Map.get(connection, :allow_idp_initiated?) do
            {:warn, "Only enable IdP-initiated flows if your app intentionally supports them"}
          else
            :ok
          end
        end
      }
    ]
  end

  @impl true
  def guide_url,
    do: "https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/configure-saml-single-sign-on"
end
