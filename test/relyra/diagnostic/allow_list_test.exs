defmodule Relyra.Diagnostic.AllowListTest do
  use ExUnit.Case, async: true

  alias Relyra.Diagnostic.AllowList

  describe "export_connection/1" do
    test "explicitly maps allowed fields and drops secrets" do
      conn = %{
        id: "conn_123",
        connection_id: "ULID123",
        display_name: "Test Conn",
        status: :enabled,
        sp_entity_id: "sp",
        acs_url: "acs",
        idp_entity_id: "idp",
        idp_sso_url: "sso",
        allow_idp_initiated: true,
        private_key: "SECRET_KEY",
        password: "SECRET_PASSWORD",
        certificates: [
          %{pem: "SECRET_PEM", fingerprint_sha256: "FP1"}
        ]
      }

      result = AllowList.export_connection(conn)

      assert result.id == "conn_123"
      assert result.connection_id == "ULID123"
      assert result.display_name == "Test Conn"
      assert result.status == :enabled
      assert result.sp_entity_id == "sp"
      assert result.acs_url == "acs"
      assert result.idp_entity_id == "idp"
      assert result.idp_sso_url == "sso"
      assert result.allow_idp_initiated == true
      
      refute Map.has_key?(result, :private_key)
      refute Map.has_key?(result, :password)
      refute Map.has_key?(result, :certificates)
    end
  end

  describe "export_audit_log/1" do
    test "drops actor and hashes correlation_id" do
      event = %{
        id: "evt_123",
        domain: :connection,
        action: :updated,
        actor: "admin@example.com",
        ip_address: "192.168.1.1",
        correlation_id: "corr_456",
        cause: "user request",
        before_summary: %{foo: "bar"},
        after_summary: %{foo: "baz"},
        diff_summary: %{foo: ["bar", "baz"]}
      }

      result = AllowList.export_audit_log(event)

      assert result.id == "evt_123"
      assert result.domain == :connection
      assert result.action == :updated
      assert result.cause == "user request"
      assert result.before_summary == %{foo: "bar"}
      assert result.after_summary == %{foo: "baz"}
      assert result.diff_summary == %{foo: ["bar", "baz"]}
      
      refute Map.has_key?(result, :actor)
      refute Map.has_key?(result, :ip_address)
      
      expected_hash = AllowList.hash_correlation_id("corr_456")
      assert result.correlation_id == expected_hash
    end

    test "handles nil correlation_id" do
      event = %{
        id: "evt_123",
        actor: "admin",
        correlation_id: nil
      }

      result = AllowList.export_audit_log(event)
      assert Map.get(result, :correlation_id) == nil
    end
  end

  describe "hash_correlation_id/1" do
    test "hashes using sha256 and base16 lowercase encoding" do
      result = AllowList.hash_correlation_id("test_id")
      
      expected = 
        :crypto.hash(:sha256, "test_id") 
        |> Base.encode16(case: :lower)
        
      assert result == expected
    end
    
    test "returns nil for nil input" do
      assert AllowList.hash_correlation_id(nil) == nil
    end
  end

  describe "export_certificate_inventory/1" do
    test "summarizes certificates" do
      cert = %{
        id: "cert_1",
        pem: "SECRET_PEM",
        fingerprint_sha256: "FP_123",
        not_before: ~U[2023-01-01 00:00:00Z],
        not_after: ~U[2024-01-01 00:00:00Z],
        issuer: "CN=Test",
        role: :signing,
        lifecycle_state: :active
      }

      result = AllowList.export_certificate_inventory(cert)

      assert result.id == "cert_1"
      assert result.fingerprint_sha256 == "FP_123"
      assert result.not_before == ~U[2023-01-01 00:00:00Z]
      assert result.not_after == ~U[2024-01-01 00:00:00Z]
      assert result.issuer == "CN=Test"
      assert result.role == :signing
      assert result.lifecycle_state == :active
      
      refute Map.has_key?(result, :pem)
    end
  end

  describe "export_metadata_revision/1" do
    test "exports mapped fields" do
      rev = %{
        id: "rev_1",
        source_kind: :xml_import,
        trigger: :manual_import,
        outcome: :applied,
        content_hash_sha256: "HASH",
        effective_idp_entity_id: "idp",
        certificate_fingerprints: ["FP1"],
        trust_summary: %{status: "trusted"},
        actor: "user1",
        cause: "test",
        details: %{foo: "bar"}
      }

      result = AllowList.export_metadata_revision(rev)
      
      assert result.id == "rev_1"
      assert result.source_kind == :xml_import
      assert result.trigger == :manual_import
      assert result.outcome == :applied
      assert result.content_hash_sha256 == "HASH"
      assert result.effective_idp_entity_id == "idp"
      assert result.certificate_fingerprints == ["FP1"]
      assert result.trust_summary == %{status: "trusted"}
      assert result.cause == "test"
      assert result.details == %{foo: "bar"}
      
      # Should we strip actor from metadata revision? The task doesn't explicitly mention it for metadata revision, but for audit logs it does. Let's assume we keep actor out to be safe for PII, or include it if not required. The requirement says: "For audit logs, strictly hash the correlation_id and omit actor." It doesn't mention actor for metadata_revision, but maybe it's best to omit. Wait, I'll just omit actor as it could be PII.
      refute Map.has_key?(result, :actor)
    end
  end
end
