defmodule LedgerLoop.Demo.ConnectionScenariosTest do
  use LedgerLoop.DataCase, async: false

  alias LedgerLoop.Demo.Reset
  alias Relyra.Ecto.{Connection, AuditEvent}
  alias LedgerLoop.Repo

  setup do
    Reset.reset!()
    :ok
  end

  test "Test 1: reset seeds exactly four scenario keys: enabled happy path, draft/missing metadata, staged-certificate rollover, and failure/support" do
    connections = Repo.all(Connection)
    assert length(connections) == 4

    statuses = Enum.map(connections, & &1.status) |> Enum.sort()
    # We should have at least draft and enabled
    assert :enabled in statuses
    assert :draft in statuses

    connection_ids = Enum.map(connections, & &1.connection_id)
    # Check that they have stable connection_ids defined by the scenarios
    assert length(Enum.uniq(connection_ids)) == 4
  end

  test "Test 2: enabled scenario has an active signing certificate, attribute mappings, and group mappings queryable through Relyra Ecto schemas" do
    enabled_conn = Repo.get_by!(Connection, display_name: "Northstar Health (Enabled)")
    assert enabled_conn.status == :enabled

    certs = Repo.all(Ecto.assoc(enabled_conn, :certificates))
    assert Enum.any?(certs, &(&1.lifecycle_state == :active and &1.role == :signing))

    attr_mappings = Repo.all(Ecto.assoc(enabled_conn, :attribute_mappings))
    assert length(attr_mappings) > 0

    group_mappings = Repo.all(Ecto.assoc(enabled_conn, :group_mappings))
    assert length(group_mappings) > 0
  end

  test "Test 3: staged-certificate scenario has active and next certificate lifecycle rows" do
    staged_conn = Repo.get_by!(Connection, display_name: "Northstar Health (Staged Rollover)")
    certs = Repo.all(Ecto.assoc(staged_conn, :certificates))
    
    assert Enum.any?(certs, &(&1.lifecycle_state == :active))
    assert Enum.any?(certs, &(&1.lifecycle_state == :next))
  end

  test "Test 4: support scenario has domain: :login audit rows with the six required trace step names and no raw XML/PEM/secrets in summaries" do
    support_conn = Repo.get_by!(Connection, display_name: "Northstar Health (Support Failure)")
    
    audit_events = 
      AuditEvent
      |> Ecto.Query.where(connection_record_id: ^support_conn.id, domain: :login)
      |> Repo.all()

    assert length(audit_events) > 0

    # Actually, let's check the required trace step names
    required_steps = ["response.decode", "response.validate", "signature.verify", "replay.check", "user.map", "session.establish"]
    
    found_steps = 
      audit_events
      |> Enum.map(& &1.diff_summary["step"])
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()

    for step <- required_steps do
      assert step in found_steps
    end

    # Check for forbidden tokens
    forbidden_tokens = ["<?xml", "BEGIN CERTIFICATE", "PRIVATE KEY", "SAMLResponse", "RelayState", "FakeIdP", "Keycloak"]
    
    for event <- audit_events do
      summary_json = Jason.encode!(event.diff_summary)
      
      for token <- forbidden_tokens do
        refute String.contains?(summary_json, token), "Found forbidden token #{token} in audit summary"
      end
    end
  end
end