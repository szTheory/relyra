defmodule LedgerLoop.Twin.IncidentRecoveryTest do
  use LedgerLoopWeb.ConnCase, async: false

  unless Code.ensure_loaded?(LedgerLoop.TestSupport.LifecycleFlow) do
    Code.require_file("../support/lifecycle_flow.ex", __DIR__)
  end

  import Ecto.Query

  alias LedgerLoop.Accounts.{LoginReceipt, User}
  alias LedgerLoop.Demo.{Fixtures, Reset}
  alias LedgerLoop.FakeIdP.Keypair
  alias LedgerLoop.Repo
  alias LedgerLoop.Relyra.AdminScope
  alias LedgerLoop.TestSupport.LifecycleFlow
  alias Relyra.ConnectionResolver.Ecto, as: ConnectionResolver
  alias Relyra.Diagnostic.AllowList
  alias Relyra.Ecto.{AuditEvent, Certificate, CertificateInventory, MetadataApply}
  alias Relyra.LiveAdmin.{Query, Scope}
  alias Relyra.Metadata.Import

  @connection_id Fixtures.relyra_support_scenario_id()
  @connection_record_id Fixtures.relyra_support_scenario_record_id()
  @issuer "https://idp.northstar.example.com"
  @subject "sarah@northstar.example.com"
  @actor "northstar-support-admin@example.com"
  @incident_correlation "support-incident-northstar-20260612"

  setup do
    previous_visual_fixture = System.get_env("DEMO_TRACE_VISUAL_FIXTURE")
    System.delete_env("DEMO_TRACE_VISUAL_FIXTURE")
    Reset.reset!()

    on_exit(fn ->
      case previous_visual_fixture do
        nil -> System.delete_env("DEMO_TRACE_VISUAL_FIXTURE")
        value -> System.put_env("DEMO_TRACE_VISUAL_FIXTURE", value)
      end
    end)

    :ok
  end

  test "a scoped support incident moves from real failed login through audited repair to verified retry",
       %{
         conn: conn
       } do
    support_route = get(conn, "/support/scenario")

    assert redirected_to(support_route) ==
             "/relyra/admin/connections/#{@connection_id}/trace"

    admin_scope = northstar_admin_scope()
    assert {:ok, initial_exports} = Query.get_login_traces(Repo, admin_scope, @connection_id)
    assert Enum.any?(initial_exports, &(&1.cause == "synthetic_support_symptom"))

    assert [] ==
             Repo.all(
               from certificate in Certificate,
                 where:
                   certificate.connection_record_id == ^@connection_record_id and
                     certificate.lifecycle_state == :active and certificate.role == :signing
             )

    wrong_certificate =
      Fixtures.relyra_certificates()
      |> Enum.find(&(&1.lifecycle_state == :next))
      |> Map.fetch!(:pem)

    wrong_fingerprint =
      install_and_activate_certificate!(
        wrong_certificate,
        "support_incident_seed_wrong_trust",
        "support_incident_seed_activate_wrong_trust"
      )

    assert {:ok, wrong_trust_connection} =
             ConnectionResolver.resolve_connection(%{connection_id: @connection_id}, repo: Repo)

    assert Enum.map(wrong_trust_connection.idp_certificates, &fingerprint/1) == [
             String.upcase(wrong_fingerprint)
           ]

    failed_flow = LifecycleFlow.start_login(@connection_id, @issuer, @subject)
    failed_response = LifecycleFlow.post_acs(failed_flow)

    assert failed_response.status == 400
    assert Phoenix.ConnTest.response(failed_response, 400) =~ "invalid_signature"
    assert Repo.aggregate(LoginReceipt, :count, :id) == 0

    failed_audit =
      Repo.one!(
        from event in AuditEvent,
          where:
            event.connection_record_id == ^@connection_record_id and
              event.domain == :login and event.action == :failed,
          order_by: [desc: event.inserted_at],
          limit: 1
      )

    assert failed_audit.after_summary["overall_outcome"] == "error"

    assert failed_audit.after_summary["steps"]["signature.verify"]["error_code"] ==
             "invalid_signature"

    assert {:ok, after_failure_exports} =
             Query.get_login_traces(Repo, admin_scope, @connection_id)

    failed_export = Enum.find(after_failure_exports, &(&1.id == failed_audit.id))
    assert failed_export.action == :failed

    assert failed_export.correlation_id ==
             AllowList.hash_correlation_id(failed_audit.correlation_id)

    refute failed_export.correlation_id == failed_flow.request_id

    correct_fingerprint =
      install_and_activate_certificate!(
        Keypair.cert_pem(),
        "support_incident_recovery_import_verified_trust",
        "support_incident_recovery_activate_verified_trust"
      )

    assert is_binary(correct_fingerprint)

    assert {:ok, _retired_wrong_certificate} =
             CertificateInventory.retire_signing_certificate(
               Repo,
               @connection_id,
               wrong_fingerprint,
               audit: audit_context("support_incident_recovery_retire_wrong_trust")
             )

    assert {:ok, recovered_connection} =
             ConnectionResolver.resolve_connection(%{connection_id: @connection_id}, repo: Repo)

    assert Enum.map(recovered_connection.idp_certificates, &fingerprint/1) == [
             String.upcase(correct_fingerprint)
           ]

    retry_flow = LifecycleFlow.start_login(@connection_id, @issuer, @subject)
    successful_response = LifecycleFlow.post_acs(retry_flow)

    assert successful_response.status == 302
    assert get_resp_header(successful_response, "location") == ["/"]

    user = Repo.get_by!(User, email: @subject)
    assert user.tenant_id == Fixtures.tenant().id

    assert [%LoginReceipt{user_id: user_id, scenario_key: scenario_key}] =
             Repo.all(from receipt in LoginReceipt, where: receipt.user_id == ^user.id)

    assert user_id == user.id
    assert scenario_key =~ @connection_id

    successful_audit =
      Repo.one!(
        from event in AuditEvent,
          where:
            event.connection_record_id == ^@connection_record_id and
              event.domain == :login and event.action == :succeeded,
          order_by: [desc: event.inserted_at],
          limit: 1
      )

    assert successful_audit.after_summary["overall_outcome"] == "ok"

    assert {:ok, after_retry_exports} =
             Query.get_login_traces(Repo, admin_scope, @connection_id)

    successful_export = Enum.find(after_retry_exports, &(&1.id == successful_audit.id))
    assert successful_export.action == :succeeded

    assert successful_export.correlation_id ==
             AllowList.hash_correlation_id(successful_audit.correlation_id)

    refute successful_export.correlation_id == failed_export.correlation_id

    remediation_events =
      Repo.all(
        from event in AuditEvent,
          where:
            event.connection_record_id == ^@connection_record_id and
              event.domain in [:metadata, :certificate] and
              event.cause in [
                "support_incident_seed_wrong_trust",
                "support_incident_seed_activate_wrong_trust",
                "support_incident_recovery_import_verified_trust",
                "support_incident_recovery_activate_verified_trust",
                "support_incident_recovery_retire_wrong_trust"
              ],
          order_by: [asc: event.inserted_at, asc: event.id]
      )

    assert Enum.any?(remediation_events, &(&1.action == :activated))
    assert Enum.any?(remediation_events, &(&1.action == :retired))
    assert Enum.any?(remediation_events, &(&1.action == :applied))
    assert Enum.all?(remediation_events, &(&1.actor == @actor))

    correlated_repairs = Enum.reject(remediation_events, &is_nil(&1.correlation_id))
    assert correlated_repairs != []
    assert Enum.all?(correlated_repairs, &(&1.correlation_id == @incident_correlation))

    seeded_stages =
      Repo.all(
        from event in AuditEvent,
          where:
            event.connection_record_id == ^@connection_record_id and
              event.diff_summary["kind"] == "support_incident",
          order_by: [asc: event.inserted_at, asc: event.id]
      )

    assert Enum.map(seeded_stages, & &1.diff_summary["stage"]) ==
             Enum.map(Fixtures.relyra_support_incident_stages(), &Atom.to_string/1)

    assert Enum.all?(seeded_stages, &(&1.correlation_id == @incident_correlation))
    assert failed_audit.connection_record_id == successful_audit.connection_record_id
    assert failed_audit.correlation_id != successful_audit.correlation_id

    assert_safe_export!(
      [failed_export, successful_export],
      [failed_flow, retry_flow],
      [wrong_certificate, Keypair.cert_pem()],
      remediation_events
    )
  end

  defp install_and_activate_certificate!(pem, cause, activate_cause) do
    candidate = metadata_candidate(pem)
    audit = audit_context(cause)

    revision_attrs = %{
      source_kind: :xml_import,
      trigger: :manual_import,
      outcome: :applied,
      actor: audit.actor,
      cause: audit.cause,
      correlation_id: audit.correlation_id,
      trust_summary: %{status: "applied", certificate_count: 1}
    }

    assert {:ok, _revision} =
             MetadataApply.apply_revision(
               @connection_id,
               candidate,
               revision_attrs,
               repo: Repo,
               audit: audit
             )

    certificate =
      Repo.get_by!(Certificate,
        connection_record_id: @connection_record_id,
        fingerprint_sha256: hd(candidate.certificate_fingerprints),
        lifecycle_state: :next
      )

    assert {:ok, %Certificate{lifecycle_state: :active}} =
             CertificateInventory.activate_signing_certificate(
               Repo,
               @connection_id,
               certificate.fingerprint_sha256,
               audit: audit_context(activate_cause)
             )

    certificate.fingerprint_sha256
  end

  defp metadata_candidate(pem) do
    certificate_body =
      pem
      |> String.replace("-----BEGIN CERTIFICATE-----", "")
      |> String.replace("-----END CERTIFICATE-----", "")
      |> String.replace(~r/\s+/, "")

    Import.build_candidate(%{
      entity_id: @issuer,
      sso_services: [
        %{
          binding: "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect",
          location: "https://idp.northstar.example.com/sso"
        }
      ],
      certificates: [certificate_body]
    })
    |> Map.from_struct()
  end

  defp audit_context(cause) do
    %{actor: @actor, cause: cause, correlation_id: @incident_correlation}
  end

  defp fingerprint(pem) do
    [{:Certificate, der, :not_encrypted}] = :public_key.pem_decode(pem)
    Base.encode16(:crypto.hash(:sha256, der))
  end

  defp northstar_admin_scope do
    assert {:ok, %Scope{organization_id: "northstar"} = scope} =
             AdminScope.resolve_admin_scope(
               %{
                 "admin_actor" => @actor,
                 "admin_actor_label" => "Northstar Support Operator",
                 "admin_organization_id" => "northstar"
               },
               %{},
               []
             )

    scope
  end

  defp assert_safe_export!(exports, flows, certificate_pems, audit_events) do
    summaries =
      Enum.map(audit_events, fn event ->
        [event.before_summary, event.after_summary, event.diff_summary]
      end)

    safe_text = inspect([exports, summaries])
    refute safe_text =~ "<Response"
    refute safe_text =~ "<Assertion"
    refute safe_text =~ "BEGIN CERTIFICATE"
    refute safe_text =~ "PRIVATE KEY"
    refute safe_text =~ "SAMLResponse"
    refute safe_text =~ "RelayState"
    refute safe_text =~ @subject
    refute safe_text =~ @incident_correlation

    for flow <- flows do
      refute safe_text =~ flow.request_id
      refute safe_text =~ flow.relay_state
      refute safe_text =~ flow.saml_response
    end

    for pem <- certificate_pems do
      refute safe_text =~ pem
    end

    allowed_step_keys = ["outcome", "error_code", "duration_ms", "attributes", "roles", "step"]

    for exported <- exports do
      assert exported.correlation_id =~ ~r/\A[0-9a-f]{64}\z/

      for step <- exported.steps do
        assert Map.keys(step) |> Enum.all?(&(&1 in allowed_step_keys))
      end
    end
  end
end
