defmodule Relyra.Provider.Okta do
  @moduledoc false

  @behaviour Relyra.Provider

  @impl true
  def id, do: :okta

  @impl true
  def display_name, do: "Okta"

  @impl true
  def default_config do
    [
      provider_preset: :okta,
      allow_idp_initiated?: false,
      require_signed_assertions?: true,
      require_signed_response?: true,
      name_id_format: "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified",
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
        idp_label: "Audience URI (SP Entity ID)",
        idp_section: "General",
        hint: "Exact match, including trailing slash"
      },
      acs_url: %{
        idp_label: "Single sign-on URL",
        idp_section: "General"
      },
      idp_sso_url: %{
        idp_label: "Identity Provider Single Sign-On URL",
        idp_section: "Sign On"
      },
      idp_certificate: %{
        idp_label: "X.509 Certificate",
        idp_section: "Sign On",
        hint: "Use the active SHA-256 cert"
      },
      name_id_format: %{
        idp_label: "Name ID format",
        idp_section: "General",
        hint: "Okta defaults to Unspecified"
      },
      signing_algorithm: %{
        idp_label: "Signature Algorithm",
        idp_section: "Advanced Settings",
        hint: "Use RSA-SHA256"
      }
    }
  end

  @impl true
  def footguns do
    [
      %{
        id: :okta_sha1,
        severity: :error,
        message: "Okta apps must not rely on SHA-1 signing",
        check: fn connection ->
          case connection |> Map.get(:algorithm_policy, %{}) |> Map.get(:signing) do
            :rsa_sha1 -> {:warn, "SHA-1 signing is too weak for production use"}
            :sha1 -> {:warn, "SHA-1 signing is too weak for production use"}
            _ -> :ok
          end
        end
      },
      %{
        id: :okta_idp_initiated,
        severity: :warning,
        message: "IdP-initiated login should stay off unless explicitly needed",
        check: fn connection ->
          if Map.get(connection, :allow_idp_initiated?) do
            {:warn, "Okta preset is safest with SP-initiated flows only"}
          else
            :ok
          end
        end
      }
    ]
  end

  @impl true
  def guide_url,
    do: "https://help.okta.com/oie/en-us/content/topics/apps/apps_app_integration_wizard_saml.htm"
end
