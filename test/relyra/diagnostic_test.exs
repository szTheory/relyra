defmodule Relyra.DiagnosticTest do
  use Relyra.TestSupport.MigrationCase, async: true

  alias Relyra.Diagnostic
  alias Relyra.Ecto.{Connection, Certificate, MetadataRevision, AuditEvent}

  setup do
    conn =
      %Connection{
        connection_id: "ULID123",
        display_name: "Test Conn",
        status: :enabled,
        sp_entity_id: "sp",
        acs_url: "acs",
        idp_entity_id: "idp",
        idp_sso_url: "sso",
        allow_idp_initiated: true
      }
      |> Repo.insert!()

    cert =
      %Certificate{
        connection_record_id: conn.id,
        fingerprint_sha256: "FP1",
        pem: "SECRET_PEM",
        source: "test"
      }
      |> Repo.insert!()

    rev =
      %MetadataRevision{
        connection_record_id: conn.id,
        source_kind: :xml_import,
        trigger: :manual_import,
        outcome: :applied,
        content_hash_sha256: "HASH",
        trust_summary: %{status: "trusted"}
      }
      |> Repo.insert!()

    event =
      %AuditEvent{
        connection_record_id: conn.id,
        domain: :connection,
        action: :updated,
        actor: "admin",
        cause: "test",
        correlation_id: "corr_456",
        before_summary: %{},
        after_summary: %{},
        diff_summary: %{}
      }
      |> Repo.insert!()

    {:ok, conn: conn, cert: cert, rev: rev, event: event}
  end

  describe "create_bundle/1" do
    test "fetches data, redacts, and returns an in-memory zip binary" do
      {:ok, zip_binary} = Diagnostic.create_bundle(repo: Repo)
      assert is_binary(zip_binary)

      # Extract the zip in memory to verify contents
      {:ok, files} = :zip.extract(zip_binary, [:memory])

      filenames = Enum.map(files, fn {name, _content} -> to_string(name) end)
      assert "connections.json" in filenames
      assert "certificates.json" in filenames
      assert "metadata_revisions.json" in filenames
      assert "audit_logs.json" in filenames
      assert "store_metrics.json" in filenames

      # Verify connection redaction
      {_name, conn_content} = Enum.find(files, fn {name, _} -> name == ~c"connections.json" end)
      conn_json = Jason.decode!(conn_content)
      assert length(conn_json) >= 1
      assert hd(conn_json)["connection_id"] == "ULID123"
      refute Map.has_key?(hd(conn_json), "private_key")

      # Verify audit log redaction
      {_name, audit_content} = Enum.find(files, fn {name, _} -> name == ~c"audit_logs.json" end)
      audit_json = Jason.decode!(audit_content)
      assert length(audit_json) >= 1
      assert hd(audit_json)["domain"] == "connection"
      refute Map.has_key?(hd(audit_json), "actor")

      expected_hash =
        :crypto.hash(:sha256, "corr_456")
        |> Base.encode16(case: :lower)

      assert hd(audit_json)["correlation_id"] == expected_hash

      # Verify store metrics
      {_name, metrics_content} =
        Enum.find(files, fn {name, _} -> name == ~c"store_metrics.json" end)

      metrics_json = Jason.decode!(metrics_content)
      assert Map.has_key?(metrics_json, "request_store")
      assert Map.has_key?(metrics_json, "replay_store")
    end
  end
end
