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

  # Stable UTC timestamp
  @fixed_timestamp ~U[2026-06-12 12:00:00.000000Z]

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
