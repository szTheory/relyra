defmodule LedgerLoop.Demo.Fixtures do
  @moduledoc """
  Stable constants for the LedgerLoop/Northstar Health demo story.
  """

  # Stable UUIDs generated once to ensure determinism.
  @northstar_tenant_id "11111111-1111-1111-1111-111111111111"
  @dr_sarah_id "22222222-2222-2222-2222-222222222222"
  @nurse_chen_id "33333333-3333-3333-3333-333333333333"
  @admin_group_id "44444444-4444-4444-4444-444444444444"
  @clinical_group_id "55555555-5555-5555-5555-555555555555"

  @dr_sarah_membership_id "66666666-6666-6666-6666-666666666666"
  @nurse_chen_membership_id "77777777-7777-7777-7777-777777777777"
  @dr_sarah_identity_id "88888888-8888-8888-8888-888888888888"
  @nurse_chen_identity_id "99999999-9999-9999-9999-999999999999"

  # Relyra scenario IDs
  @enabled_conn_id "aaaaaaaa-1111-1111-1111-aaaaaaaaaaaa"
  @enabled_conn_ulid "01H0B4Y1A2B3C4D5E6F7G8H9J0"

  @draft_conn_id "bbbbbbbb-2222-2222-2222-bbbbbbbbbbbb"
  @draft_conn_ulid "01H0B4Y1A2B3C4D5E6F7G8H9J1"

  @staged_conn_id "cccccccc-3333-3333-3333-cccccccccccc"
  @staged_conn_ulid "01H0B4Y1A2B3C4D5E6F7G8H9J2"

  @support_conn_id "dddddddd-4444-4444-4444-dddddddddddd"
  @support_conn_ulid "01H0B4Y1A2B3C4D5E6F7G8H9J3"

  # Certificate IDs
  @enabled_cert_id "eeeeeeee-5555-5555-5555-eeeeeeeeeeee"
  @staged_active_cert_id "ffffffff-6666-6666-6666-ffffffffffff"
  @staged_next_cert_id "00000000-7777-7777-7777-000000000000"

  # Stable UTC timestamp
  @fixed_timestamp ~U[2026-06-12 12:00:00.000000Z]

  def relyra_connections do
    [
      %{
        id: @enabled_conn_id,
        connection_id: @enabled_conn_ulid,
        display_name: "Northstar Health (Enabled)",
        organization_id: "northstar",
        status: :enabled,
        provider_preset: :okta,
        sp_entity_id: "https://ledgerloop.example.com/sp",
        acs_url: "https://ledgerloop.example.com/sso/acs",
        idp_entity_id: "https://idp.northstar.example.com",
        idp_sso_url: "https://idp.northstar.example.com/sso",
        inserted_at: @fixed_timestamp,
        updated_at: @fixed_timestamp
      },
      %{
        id: @draft_conn_id,
        connection_id: @draft_conn_ulid,
        display_name: "Northstar Health (Draft/Missing Metadata)",
        organization_id: "northstar",
        status: :draft,
        provider_preset: :entra,
        sp_entity_id: "https://ledgerloop.example.com/sp",
        acs_url: "https://ledgerloop.example.com/sso/acs",
        idp_entity_id: nil,
        idp_sso_url: nil,
        inserted_at: @fixed_timestamp,
        updated_at: @fixed_timestamp
      },
      %{
        id: @staged_conn_id,
        connection_id: @staged_conn_ulid,
        display_name: "Northstar Health (Staged Rollover)",
        organization_id: "northstar",
        status: :enabled,
        provider_preset: :okta,
        sp_entity_id: "https://ledgerloop.example.com/sp",
        acs_url: "https://ledgerloop.example.com/sso/acs",
        idp_entity_id: "https://idp.northstar.example.com",
        idp_sso_url: "https://idp.northstar.example.com/sso",
        inserted_at: @fixed_timestamp,
        updated_at: @fixed_timestamp
      },
      %{
        id: @support_conn_id,
        connection_id: @support_conn_ulid,
        display_name: "Northstar Health (Support Failure)",
        organization_id: "northstar",
        status: :enabled,
        provider_preset: :okta,
        sp_entity_id: "https://ledgerloop.example.com/sp",
        acs_url: "https://ledgerloop.example.com/sso/acs",
        idp_entity_id: "https://idp.northstar.example.com",
        idp_sso_url: "https://idp.northstar.example.com/sso",
        inserted_at: @fixed_timestamp,
        updated_at: @fixed_timestamp
      }
    ]
  end

  def relyra_certificates do
    [
      %{
        id: @enabled_cert_id,
        connection_record_id: @enabled_conn_id,
        fingerprint_sha256: "E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855",
        pem: "MOCK_PEM_NOT_REAL",
        source: "metadata",
        role: :signing,
        lifecycle_state: :active,
        party: :idp,
        use: :signing,
        activated_at: @fixed_timestamp,
        inserted_at: @fixed_timestamp,
        updated_at: @fixed_timestamp
      },
      %{
        id: @staged_active_cert_id,
        connection_record_id: @staged_conn_id,
        fingerprint_sha256: "E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855",
        pem: "MOCK_PEM_NOT_REAL",
        source: "metadata",
        role: :signing,
        lifecycle_state: :active,
        party: :idp,
        use: :signing,
        activated_at: @fixed_timestamp,
        inserted_at: @fixed_timestamp,
        updated_at: @fixed_timestamp
      },
      %{
        id: @staged_next_cert_id,
        connection_record_id: @staged_conn_id,
        fingerprint_sha256: "8D969EEF6ECAD3C29A3A629280E686CF0C3F5D5A86AFF3CA12020C923ADC6C92",
        pem: "MOCK_PEM_NOT_REAL_NEXT",
        source: "metadata",
        role: :signing,
        lifecycle_state: :next,
        party: :idp,
        use: :signing,
        staged_at: @fixed_timestamp,
        inserted_at: @fixed_timestamp,
        updated_at: @fixed_timestamp
      }
    ]
  end

  def relyra_attribute_mappings do
    [
      %{
        id: "11111111-9999-9999-9999-111111111111",
        connection_record_id: @enabled_conn_id,
        target_field: :email,
        source_attribute: "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress",
        multivalue_strategy: :first,
        inserted_at: @fixed_timestamp,
        updated_at: @fixed_timestamp
      }
    ]
  end

  def relyra_group_mappings do
    [
      %{
        id: "22222222-9999-9999-9999-222222222222",
        connection_record_id: @enabled_conn_id,
        source_attribute: "groups",
        source_value: "IdP_Administrators",
        role_target: :role,
        role_value: "admin",
        inserted_at: @fixed_timestamp,
        updated_at: @fixed_timestamp
      }
    ]
  end

  def relyra_support_scenario_id do
    @support_conn_ulid
  end

  def relyra_enabled_scenario_id do
    @enabled_conn_ulid
  end

  def tenant do
    %{
      id: @northstar_tenant_id,
      name: "Northstar Health",
      slug: "northstar",
      inserted_at: @fixed_timestamp,
      updated_at: @fixed_timestamp
    }
  end

  def users do
    [
      %{
        id: @dr_sarah_id,
        tenant_id: @northstar_tenant_id,
        name: "Dr. Sarah",
        email: "sarah@northstar.example.com",
        inserted_at: @fixed_timestamp,
        updated_at: @fixed_timestamp
      },
      %{
        id: @nurse_chen_id,
        tenant_id: @northstar_tenant_id,
        name: "Nurse Chen",
        email: "chen@northstar.example.com",
        inserted_at: @fixed_timestamp,
        updated_at: @fixed_timestamp
      }
    ]
  end

  def groups do
    [
      %{
        id: @admin_group_id,
        tenant_id: @northstar_tenant_id,
        name: "Administrators",
        key: "admins",
        inserted_at: @fixed_timestamp,
        updated_at: @fixed_timestamp
      },
      %{
        id: @clinical_group_id,
        tenant_id: @northstar_tenant_id,
        name: "Clinical Staff",
        key: "clinical",
        inserted_at: @fixed_timestamp,
        updated_at: @fixed_timestamp
      }
    ]
  end

  def memberships do
    [
      %{
        id: @dr_sarah_membership_id,
        user_id: @dr_sarah_id,
        group_id: @admin_group_id,
        inserted_at: @fixed_timestamp,
        updated_at: @fixed_timestamp
      },
      %{
        id: @nurse_chen_membership_id,
        user_id: @nurse_chen_id,
        group_id: @clinical_group_id,
        inserted_at: @fixed_timestamp,
        updated_at: @fixed_timestamp
      }
    ]
  end

  def saml_identities do
    [
      %{
        id: @dr_sarah_identity_id,
        user_id: @dr_sarah_id,
        subject: "sarah@northstar.example.com",
        issuer: "https://idp.northstar.example.com",
        inserted_at: @fixed_timestamp,
        updated_at: @fixed_timestamp
      },
      %{
        id: @nurse_chen_identity_id,
        user_id: @nurse_chen_id,
        subject: "chen@northstar.example.com",
        issuer: "https://idp.northstar.example.com",
        inserted_at: @fixed_timestamp,
        updated_at: @fixed_timestamp
      }
    ]
  end
end
