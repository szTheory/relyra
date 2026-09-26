defmodule LedgerLoop.Twin.ResetTest do
  use LedgerLoop.DataCase, async: false

  alias LedgerLoop.Demo.{Fixtures, Reset}
  alias LedgerLoop.Repo
  alias LedgerLoop.Accounts.{Tenant, User, Group, Membership, SAMLIdentity}

  alias Relyra.Ecto.{
    AuditEvent,
    AttributeMapping,
    Certificate,
    Connection,
    GroupMapping,
    MetadataRevision,
    MetadataSource
  }

  setup do
    Reset.reset!()
    :ok
  end

  test "two resets reproduce every fixture-owned row and preserve unrelated tenant and connection sentinels" do
    sentinel_tenant = %{
      id: "aaaaaaaa-9999-9999-9999-aaaaaaaaaaaa",
      name: "Unrelated Sentinel",
      slug: "unrelated-sentinel",
      inserted_at: ~U[2026-06-12 14:00:00.000000Z],
      updated_at: ~U[2026-06-12 14:00:00.000000Z]
    }

    sentinel_connection = %{
      id: "bbbbbbbb-9999-9999-9999-bbbbbbbbbbbb",
      connection_id: "01H0B4Y1A2B3C4D5E6F7G8H9K0",
      display_name: "Unrelated Sentinel Connection",
      organization_id: "unrelated-sentinel",
      status: :draft,
      provider_preset: :okta,
      sp_entity_id: "https://sentinel.example.com/sp",
      acs_url: "https://sentinel.example.com/acs",
      idp_entity_id: nil,
      idp_sso_url: nil,
      inserted_at: ~U[2026-06-12 14:00:00.000000Z],
      updated_at: ~U[2026-06-12 14:00:00.000000Z]
    }

    Repo.insert_all(Tenant, [sentinel_tenant])
    Repo.insert_all(Connection, [sentinel_connection])

    sentinel_tenant_before = Repo.get!(Tenant, sentinel_tenant.id)
    sentinel_connection_before = Repo.get!(Connection, sentinel_connection.id)
    first = fixture_snapshot()

    Reset.reset!()
    second = fixture_snapshot()

    assert first == second
    assert Repo.get!(Tenant, sentinel_tenant.id) == sentinel_tenant_before
    assert Repo.get!(Connection, sentinel_connection.id) == sentinel_connection_before

    assert Enum.map(Repo.all(Tenant), & &1.slug) |> Enum.sort() == [
             "harborline",
             "northstar",
             "unrelated-sentinel"
           ]
  end

  test "fixture catalogs own each seeded row and fixture summaries contain no sensitive payload markers" do
    snapshot = fixture_snapshot()
    assert snapshot.tenants |> Enum.map(& &1.slug) |> Enum.sort() == ["harborline", "northstar"]

    assert Enum.all?(
             snapshot.memberships,
             &(&1.user_id in Enum.map(snapshot.users, fn user -> user.id end))
           )

    assert Enum.all?(
             snapshot.connections,
             &(&1.id in Enum.map(Fixtures.relyra_connections(), fn row -> row.id end))
           )

    for event <- snapshot.audit_events do
      rendered = Jason.encode!([event.before_summary, event.after_summary, event.diff_summary])
      refute rendered =~ "<?xml"
      refute rendered =~ "BEGIN CERTIFICATE"
      refute rendered =~ "PRIVATE KEY"
      refute rendered =~ "SAMLResponse"
      refute rendered =~ "RelayState"
    end
  end

  defp fixture_snapshot do
    tenant_ids = ids(Fixtures.tenants())
    user_ids = ids(Fixtures.users())
    group_ids = ids(Fixtures.groups())
    membership_ids = ids(Fixtures.memberships())
    identity_ids = ids(Fixtures.saml_identities())
    connection_ids = ids(Fixtures.relyra_connections())
    certificate_ids = ids(Fixtures.relyra_certificates())
    source_ids = ids(Fixtures.relyra_metadata_sources())
    revision_ids = ids(Fixtures.relyra_metadata_revisions())
    attribute_mapping_ids = ids(Fixtures.relyra_attribute_mappings())
    group_mapping_ids = ids(Fixtures.relyra_group_mappings())

    audit_ids =
      ids(Fixtures.relyra_trust_audit_events()) ++
        ids(Fixtures.relyra_support_trace_events()) ++
        ids(Fixtures.relyra_support_incident_events()) ++
        ids(Fixtures.relyra_support_visual_events())

    %{
      tenants: rows(Tenant, tenant_ids),
      users: rows(User, user_ids),
      groups: rows(Group, group_ids),
      memberships: rows(Membership, membership_ids),
      identities: rows(SAMLIdentity, identity_ids),
      connections: rows(Connection, connection_ids),
      certificates: rows(Certificate, certificate_ids),
      metadata_sources: rows(MetadataSource, source_ids),
      metadata_revisions: rows(MetadataRevision, revision_ids),
      attribute_mappings: rows(AttributeMapping, attribute_mapping_ids),
      group_mappings: rows(GroupMapping, group_mapping_ids),
      audit_events: rows(AuditEvent, audit_ids)
    }
  end

  defp rows(schema, ids) do
    Repo.all(from(row in schema, where: row.id in ^ids, order_by: row.id))
  end

  defp ids(rows), do: Enum.map(rows, & &1.id)
end
