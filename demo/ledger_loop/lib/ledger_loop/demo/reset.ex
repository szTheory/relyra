defmodule LedgerLoop.Demo.Reset do
  @moduledoc """
  Orchestrates the deterministic reset of the LedgerLoop demo state.
  """

  alias LedgerLoop.Repo
  alias LedgerLoop.Demo.Fixtures
  alias LedgerLoop.Accounts.{Tenant, User, Group, Membership, SAMLIdentity}
  alias Relyra.Ecto.{Connection, Certificate, AttributeMapping, GroupMapping, AuditEvent}
  alias Relyra.Ecto.AuditWriter
  import Ecto.Query

  @doc """
  Deterministically recreates the demo state.
  """
  def reset! do
    Repo.transaction(fn ->
      # Delete existing demo data starting with tenant (cascades)
      Repo.delete_all(from t in Tenant, where: t.id == ^Fixtures.tenant().id)

      # Delete Relyra data
      connections = Repo.all(from c in Connection, where: c.organization_id == "northstar")
      conn_ids = Enum.map(connections, & &1.id)

      if length(conn_ids) > 0 do
        Repo.delete_all(from a in AuditEvent, where: a.connection_record_id in ^conn_ids)
        Repo.delete_all(from c in Certificate, where: c.connection_record_id in ^conn_ids)
        Repo.delete_all(from am in AttributeMapping, where: am.connection_record_id in ^conn_ids)
        Repo.delete_all(from gm in GroupMapping, where: gm.connection_record_id in ^conn_ids)
        Repo.delete_all(from c in Connection, where: c.id in ^conn_ids)
      end

      # Insert fixed data
      Repo.insert_all(Tenant, [Fixtures.tenant()])
      Repo.insert_all(User, Fixtures.users())
      Repo.insert_all(Group, Fixtures.groups())
      Repo.insert_all(Membership, Fixtures.memberships())
      Repo.insert_all(SAMLIdentity, Fixtures.saml_identities())

      # Insert Relyra data
      Repo.insert_all(Connection, Fixtures.relyra_connections())
      Repo.insert_all(Certificate, Fixtures.relyra_certificates())
      Repo.insert_all(AttributeMapping, Fixtures.relyra_attribute_mappings())
      Repo.insert_all(GroupMapping, Fixtures.relyra_group_mappings())

      # Insert Support Failure Trace Events.
      # AuditEvent.connection_record_id is a :binary_id FK to Relyra.Ecto.Connection.id,
      # so use the connection's internal record id (UUID), not the public ULID connection_id.
      support_id = Fixtures.relyra_support_scenario_record_id()

      trace_steps = [
        "response.decode",
        "response.validate",
        "signature.verify",
        "replay.check",
        "user.map",
        "session.establish"
      ]

      for {step, index} <- Enum.with_index(trace_steps) do
        action = if step == "session.establish", do: :failed, else: :succeeded

        attrs = %{
          connection_record_id: support_id,
          domain: :login,
          action: action,
          actor: "sso_trace",
          cause: "demo_seed",
          correlation_id: "demo-trace-1234",
          after_summary: %{"status" => "traced"},
          diff_summary: %{
            "kind" => "login_trace",
            "step" => step,
            "order" => index,
            "status" => if(action == :failed, do: "error", else: "ok")
          }
        }

        {:ok, _} = AuditWriter.append_event(Repo, attrs)
      end
    end)

    :ok
  end
end
