defmodule Relyra.Provider.GoogleWorkspace do
  @moduledoc false

  @behaviour Relyra.Provider

  @impl true
  def id, do: :google_workspace

  @impl true
  def display_name, do: "Google Workspace"

  @impl true
  def default_config do
    [
      provider_preset: :google_workspace,
      allow_idp_initiated?: false,
      require_signed_assertions?: true,
      require_signed_response?: true,
      name_id_format: "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress",
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
        idp_label: "ACS URL",
        idp_section: "Service Provider Details",
        hint: "Google calls this the ACS URL"
      },
      acs_url: %{
        idp_label: "ACS URL",
        idp_section: "Service Provider Details"
      },
      idp_sso_url: %{
        idp_label: "SSO URL",
        idp_section: "IdP Details"
      },
      idp_certificate: %{
        idp_label: "Certificate",
        idp_section: "IdP Details"
      },
      name_id_format: %{
        idp_label: "Name ID format",
        idp_section: "Service Provider Details"
      }
    }
  end

  @impl true
  def footguns do
    [
      %{
        id: :google_email_claims,
        severity: :warning,
        message: "Google Workspace is happiest when NameID maps to the primary email",
        check: fn connection ->
          if Map.get(connection, :name_id_format) == "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress" do
            :ok
          else
            {:warn, "Confirm your attribute mapping returns a stable email-style principal"}
          end
        end
      }
    ]
  end

  @impl true
  def guide_url,
    do: "https://support.google.com/a/answer/6087519"
end
