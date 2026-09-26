defmodule LedgerLoop.Demo.Reset do
  @moduledoc """
  Orchestrates the deterministic reset of the LedgerLoop demo state.
  """

  alias LedgerLoop.Repo
  alias LedgerLoop.Demo.Fixtures
  alias LedgerLoop.Accounts.{Tenant, User, Group, Membership, SAMLIdentity}

  alias Relyra.Ecto.{
    Connection,
    Certificate,
    AttributeMapping,
    GroupMapping,
    AuditEvent,
    MetadataSource,
    MetadataRevision
  }

  import Ecto.Query

  @doc """
  Deterministically recreates the demo state.
  """
  def reset! do
    Repo.transaction(fn ->
      # Delete Relyra data
      tenant_ids = Enum.map(Fixtures.tenants(), & &1.id)
      connection_ids = Enum.map(Fixtures.relyra_connections(), & &1.id)
      connections = Repo.all(from c in Connection, where: c.id in ^connection_ids)
      conn_ids = Enum.map(connections, & &1.id)

      if length(conn_ids) > 0 do
        Repo.update_all(
          from(c in Connection, where: c.id in ^conn_ids),
          set: [active_metadata_revision_id: nil, last_known_good_metadata_revision_id: nil]
        )

        Repo.delete_all(from a in AuditEvent, where: a.connection_record_id in ^conn_ids)
        Repo.delete_all(from c in Certificate, where: c.connection_record_id in ^conn_ids)
        Repo.delete_all(from r in MetadataRevision, where: r.connection_record_id in ^conn_ids)
        Repo.delete_all(from s in MetadataSource, where: s.connection_record_id in ^conn_ids)
        Repo.delete_all(from am in AttributeMapping, where: am.connection_record_id in ^conn_ids)
        Repo.delete_all(from gm in GroupMapping, where: gm.connection_record_id in ^conn_ids)
        Repo.delete_all(from c in Connection, where: c.id in ^conn_ids)
      end

      # Delete only host tenants explicitly owned by this fixture catalog.
      Repo.delete_all(from t in Tenant, where: t.id in ^tenant_ids)

      # Insert fixed data
      Repo.insert_all(Tenant, Fixtures.tenants())
      Repo.insert_all(User, Fixtures.users())
      Repo.insert_all(Group, Fixtures.groups())
      Repo.insert_all(Membership, Fixtures.memberships())
      Repo.insert_all(SAMLIdentity, Fixtures.saml_identities())

      # Insert Relyra data
      Repo.insert_all(Connection, Fixtures.relyra_connections())
      Repo.insert_all(MetadataSource, Fixtures.relyra_metadata_sources())
      Repo.insert_all(MetadataRevision, Fixtures.relyra_metadata_revisions())
      # Rebuild only the fixture-owned trust catalog, including Harborline's
      # active certificate for paired route-level tenant journeys.
      Repo.insert_all(Certificate, Fixtures.relyra_certificates())
      Repo.insert_all(AttributeMapping, Fixtures.relyra_attribute_mappings())
      Repo.insert_all(GroupMapping, Fixtures.relyra_group_mappings())

      recovery_revision =
        Enum.find(Fixtures.relyra_metadata_revisions(), &(&1.cause == "metadata_recovery"))

      Repo.update_all(
        from(c in Connection, where: c.id == ^Fixtures.trust_scenario_connection_id()),
        set: [
          active_metadata_revision_id: recovery_revision.id,
          last_known_good_metadata_revision_id: recovery_revision.id
        ]
      )

      visual_events =
        if System.get_env("DEMO_TRACE_VISUAL_FIXTURE") == "1",
          do: Fixtures.relyra_support_visual_events(),
          else: []

      Repo.insert_all(
        AuditEvent,
        Fixtures.relyra_trust_audit_events() ++
          Fixtures.relyra_support_trace_events() ++
          Fixtures.relyra_support_incident_events() ++ visual_events
      )
    end)

    :ok
  end
end
