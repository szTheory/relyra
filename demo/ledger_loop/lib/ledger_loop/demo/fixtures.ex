defmodule LedgerLoop.Demo.Fixtures do
  @moduledoc """
  Stable constants for the tenant-owned LedgerLoop demo scenarios.
  """

  # Demo IdP cert — sourced at build time from the committed PEM so that the
  # fixture and the FakeIdP signer can never drift (PLAN 57-01, T-57-04).
  @demo_idp_cert_pem LedgerLoop.FakeIdP.Keypair.cert_pem()

  # Compute fingerprint at compile time: sha256 of the DER-encoded cert, uppercase hex.
  @demo_idp_cert_fingerprint (case :public_key.pem_decode(@demo_idp_cert_pem) do
                                [{:Certificate, der, :not_encrypted}] ->
                                  Base.encode16(:crypto.hash(:sha256, der))
                              end)
  @rollover_next_cert_pem Application.app_dir(
                            :ledger_loop,
                            "priv/fake_idp/rollover_next_cert.pem"
                          )
                          |> File.read!()
  @rollover_next_cert_fingerprint (case :public_key.pem_decode(@rollover_next_cert_pem) do
                                     [{:Certificate, der, :not_encrypted}] ->
                                       Base.encode16(:crypto.hash(:sha256, der))
                                   end)
  @rollover_retired_cert_pem Application.app_dir(
                               :ledger_loop,
                               "priv/fake_idp/rollover_retired_cert.pem"
                             )
                             |> File.read!()
  @rollover_retired_cert_fingerprint (case :public_key.pem_decode(@rollover_retired_cert_pem) do
                                        [{:Certificate, der, :not_encrypted}] ->
                                          Base.encode16(:crypto.hash(:sha256, der))
                                      end)

  # Stable UUIDs generated once to ensure determinism.
  @northstar_tenant_id "11111111-1111-1111-1111-111111111111"
  @dr_sarah_id "22222222-2222-2222-2222-222222222222"
  @nurse_chen_id "33333333-3333-3333-3333-333333333333"
  @admin_group_id "44444444-4444-4444-4444-444444444444"
  @clinical_group_id "55555555-5555-5555-5555-555555555555"
  @harborline_tenant_id "12121212-1212-1212-1212-121212121212"
  @maya_patel_id "23232323-2323-2323-2323-232323232323"
  @luis_ortega_id "34343434-3434-3434-3434-343434343434"
  @harborline_admin_group_id "45454545-4545-4545-4545-454545454545"
  @harborline_ops_group_id "56565656-5656-5656-5656-565656565656"
  @maya_membership_id "67676767-6767-6767-6767-676767676767"
  @luis_membership_id "78787878-7878-7878-7878-787878787878"
  @maya_identity_id "89898989-8989-8989-8989-898989898989"
  @luis_identity_id "90909090-9090-9090-9090-909090909090"

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
  @harborline_conn_id "abababab-5555-5555-5555-abababababab"
  @harborline_conn_ulid "01H0B4Y1A2B3C4D5E6F7G8H9J5"

  # Certificate IDs
  @enabled_cert_id "eeeeeeee-5555-5555-5555-eeeeeeeeeeee"
  @staged_active_cert_id "ffffffff-6666-6666-6666-ffffffffffff"
  @staged_next_cert_id "00000000-7777-7777-7777-000000000000"
  @retired_cert_id "11111111-7777-7777-7777-111111111111"

  @trust_source_id "22222222-7777-7777-7777-222222222222"
  @trust_registered_revision_id "33333333-7777-7777-7777-333333333333"
  @trust_failed_revision_id "44444444-7777-7777-7777-444444444444"
  @trust_applied_revision_id "55555555-7777-7777-7777-555555555555"
  @trust_recovered_revision_id "88888888-7777-7777-7777-888888888888"
  @trust_failure_audit_id "66666666-7777-7777-7777-666666666666"
  @trust_recovery_audit_id "77777777-7777-7777-7777-777777777777"
  @support_trace_ids [
    "10101010-8888-8888-8888-101010101010",
    "20202020-8888-8888-8888-202020202020",
    "30303030-8888-8888-8888-303030303030",
    "40404040-8888-8888-8888-404040404040",
    "50505050-8888-8888-8888-505050505050",
    "60606060-8888-8888-8888-606060606060"
  ]
  @support_incident_ids [
    "11111111-8888-8888-8888-111111111111",
    "22222222-8888-8888-8888-222222222222",
    "33333333-8888-8888-8888-333333333333",
    "44444444-8888-8888-8888-444444444444",
    "55555555-8888-8888-8888-555555555555"
  ]
  @support_visual_event_id "99999999-8888-8888-8888-999999999999"

  # Stable UTC timestamp
  @fixed_timestamp ~U[2026-06-12 12:00:00.000000Z]
  @trust_registered_at ~U[2026-06-12 12:05:00.000000Z]
  @trust_applied_at ~U[2026-06-12 12:10:00.000000Z]
  @trust_failed_at ~U[2026-06-12 12:20:00.000000Z]
  @trust_recovered_at ~U[2026-06-12 12:30:00.000000Z]
  @support_trace_started_at ~U[2026-06-12 12:50:00.000000Z]
  @support_incident_started_at ~U[2026-06-12 13:00:00.000000Z]

  @support_trace_steps [
    "response.decode",
    "response.validate",
    "signature.verify",
    "replay.check",
    "user.map",
    "session.establish"
  ]
  @support_incident_stages [:symptom, :diagnosis, :remediation, :retry, :recovery]

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
        idp_sso_url: "http://localhost:4000/fake_idp/login",
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
      },
      %{
        id: @harborline_conn_id,
        connection_id: @harborline_conn_ulid,
        display_name: "Harborline Logistics (Google Workspace)",
        organization_id: "harborline",
        status: :enabled,
        provider_preset: :google_workspace,
        sp_entity_id: "https://ledgerloop.example.com/sp",
        acs_url: "https://ledgerloop.example.com/sso/acs",
        idp_entity_id: "https://idp.harborline.example.com",
        idp_sso_url: "https://idp.harborline.example.com/sso",
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
        fingerprint_sha256: @demo_idp_cert_fingerprint,
        pem: @demo_idp_cert_pem,
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
        fingerprint_sha256: @demo_idp_cert_fingerprint,
        pem: @demo_idp_cert_pem,
        source: "metadata",
        role: :signing,
        lifecycle_state: :active,
        not_before: ~U[2025-06-12 12:00:00.000000Z],
        not_after: ~U[2026-07-01 12:00:00.000000Z],
        party: :idp,
        use: :signing,
        activated_at: @trust_applied_at,
        inserted_at: @trust_applied_at,
        updated_at: @trust_applied_at
      },
      %{
        id: @staged_next_cert_id,
        connection_record_id: @staged_conn_id,
        fingerprint_sha256: @rollover_next_cert_fingerprint,
        pem: @rollover_next_cert_pem,
        source: "metadata",
        role: :signing,
        lifecycle_state: :next,
        party: :idp,
        use: :signing,
        staged_at: @trust_recovered_at,
        inserted_at: @trust_recovered_at,
        updated_at: @trust_recovered_at
      },
      %{
        id: @retired_cert_id,
        connection_record_id: @staged_conn_id,
        fingerprint_sha256: @rollover_retired_cert_fingerprint,
        pem: @rollover_retired_cert_pem,
        source: "metadata",
        role: :signing,
        lifecycle_state: :retired,
        not_before: ~U[2024-06-12 12:00:00.000000Z],
        not_after: ~U[2025-06-12 12:00:00.000000Z],
        retired_at: @trust_applied_at,
        party: :idp,
        use: :signing,
        inserted_at: @trust_applied_at,
        updated_at: @trust_applied_at
      }
    ]
  end

  def trust_scenario_as_of, do: @fixed_timestamp

  def trust_scenario_connection_id, do: @staged_conn_id

  def relyra_metadata_sources do
    [
      %{
        id: @trust_source_id,
        connection_record_id: @staged_conn_id,
        url: "https://metadata.northstar.example.com/saml.xml",
        kind: :remote_url,
        registered_by: "ledgerloop_fixture",
        registered_reason: "named_trust_history_scenario",
        last_fetched_at: @trust_recovered_at,
        last_outcome: :applied,
        last_success_at: @trust_recovered_at,
        consecutive_failure_count: 0,
        first_failure_at: nil,
        last_failure_error_code: nil,
        auto_suspended_until: nil,
        auto_suspended_reason: nil,
        inserted_at: @trust_registered_at,
        updated_at: @trust_recovered_at
      }
    ]
  end

  def relyra_metadata_revisions do
    [
      trust_revision(
        @trust_registered_revision_id,
        :registered,
        @trust_registered_at,
        "metadata_registered"
      ),
      trust_revision(
        @trust_applied_revision_id,
        :applied,
        @trust_applied_at,
        "metadata_initial_apply"
      ),
      trust_revision(
        @trust_failed_revision_id,
        :fetch_failed,
        @trust_failed_at,
        "metadata_transient_failure"
      ),
      trust_revision(
        @trust_recovered_revision_id,
        :applied,
        @trust_recovered_at,
        "metadata_recovery"
      )
    ]
  end

  def relyra_trust_audit_events do
    [
      %{
        id: @trust_failure_audit_id,
        connection_record_id: @staged_conn_id,
        domain: :metadata,
        action: :failed,
        actor: "ledgerloop_fixture",
        cause: "synthetic_metadata_fetch_failure",
        correlation_id: "northstar-trust-history-20260612",
        before_summary: %{"health" => "healthy"},
        after_summary: %{"health" => "degraded", "revision_id" => @trust_failed_revision_id},
        diff_summary: %{"scenario" => "northstar_trust_history", "event" => "degraded"},
        inserted_at: @trust_failed_at
      },
      %{
        id: @trust_recovery_audit_id,
        connection_record_id: @staged_conn_id,
        domain: :metadata,
        action: :applied,
        actor: "ledgerloop_fixture",
        cause: "synthetic_metadata_recovery",
        correlation_id: "northstar-trust-history-20260612",
        before_summary: %{"health" => "degraded"},
        after_summary: %{"health" => "healthy", "revision_id" => @trust_recovered_revision_id},
        diff_summary: %{"scenario" => "northstar_trust_history", "event" => "recovered"},
        inserted_at: @trust_recovered_at
      }
    ]
  end

  def relyra_support_trace_steps, do: @support_trace_steps

  def relyra_support_incident_stages, do: @support_incident_stages

  def relyra_support_trace_events do
    Enum.zip([@support_trace_steps, @support_trace_ids, 0..5])
    |> Enum.map(fn {step, id, index} ->
      action = if step == "session.establish", do: :failed, else: :succeeded
      status = if action == :failed, do: "error", else: "ok"

      %{
        id: id,
        connection_record_id: @support_conn_id,
        domain: :login,
        action: action,
        actor: "ledgerloop_fixture",
        cause: "synthetic_support_trace",
        correlation_id: "support-incident-northstar-20260612",
        before_summary: %{},
        after_summary: %{
          "status" => status,
          "steps" => %{
            step => %{
              "outcome" => status,
              "error_code" => if(action == :failed, do: "session_rejected", else: nil),
              "duration_ms" => 12 + index
            }
          }
        },
        diff_summary: %{
          "kind" => "login_trace",
          "step" => step,
          "order" => index,
          "status" => status
        },
        inserted_at: DateTime.add(@support_trace_started_at, index, :second)
      }
    end)
  end

  def relyra_support_incident_events do
    Enum.zip([@support_incident_stages, @support_incident_ids, 0..4])
    |> Enum.map(fn {stage, id, index} ->
      %{
        id: id,
        connection_record_id: @support_conn_id,
        domain: :login,
        action: if(stage == :symptom, do: :failed, else: :succeeded),
        actor: "ledgerloop_fixture",
        cause: "synthetic_support_#{stage}",
        correlation_id: "support-incident-northstar-20260612",
        before_summary: %{"scenario" => "northstar_support_incident"},
        after_summary: %{
          "scenario" => "northstar_support_incident",
          "stage" => Atom.to_string(stage)
        },
        diff_summary: %{
          "kind" => "support_incident",
          "stage" => Atom.to_string(stage),
          "sequence" => index,
          "trace_scenario" => "northstar_support_incident"
        },
        inserted_at: DateTime.add(@support_incident_started_at, index * 5, :minute)
      }
    end)
  end

  def relyra_support_visual_events do
    [
      %{
        id: @support_visual_event_id,
        connection_record_id: @support_conn_id,
        domain: :login,
        action: :failed,
        actor: "demo_trace_visual_fixture",
        cause:
          "visual_fixture_long_failure_cause operator-readable deterministic support evidence for narrow trace viewport validation without protected login material",
        correlation_id: "visual-fixture-correlation-safe-deterministic",
        before_summary: %{},
        after_summary: %{
          "overall_outcome" => "error",
          "steps" => %{
            "response.validate" => %{
              "outcome" => "error",
              "error_code" =>
                "SAFE_LONG_KNOWN_STEP_ERROR_CODE_for_deterministic_narrow_viewport_evidence_without_sensitive_payloads",
              "duration_ms" => 17
            }
          }
        },
        diff_summary: %{"kind" => "login_trace", "fixture" => "trace_visual"},
        inserted_at: @support_incident_started_at
      }
    ]
  end

  defp trust_revision(id, outcome, timestamp, cause) do
    %{
      id: id,
      connection_record_id: @staged_conn_id,
      metadata_source_id: @trust_source_id,
      source_kind: :remote_url,
      trigger: :manual_refresh,
      outcome: outcome,
      content_hash_sha256: nil,
      effective_idp_entity_id: "https://idp.northstar.example.com",
      effective_idp_sso_url: "https://idp.northstar.example.com/sso",
      certificate_fingerprints: [],
      trust_summary: %{
        "scenario" => "northstar_trust_history",
        "outcome" => Atom.to_string(outcome)
      },
      actor: "ledgerloop_fixture",
      cause: cause,
      details: %{},
      inserted_at: timestamp
    }
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

  @doc """
  The Support Failure connection's internal `:binary_id` record id.

  Use this (not `relyra_support_scenario_id/0`, which is the public ULID) wherever a
  `connection_record_id` foreign key is needed — e.g. seeding audit/trace events, whose
  `connection_record_id` references `Relyra.Ecto.Connection.id`.
  """
  def relyra_support_scenario_record_id do
    @support_conn_id
  end

  def relyra_enabled_scenario_id do
    @enabled_conn_ulid
  end

  def tenant do
    Enum.find(tenants(), &(&1.slug == "northstar"))
  end

  def tenants do
    [
      %{
        id: @northstar_tenant_id,
        name: "Northstar Health",
        slug: "northstar",
        inserted_at: @fixed_timestamp,
        updated_at: @fixed_timestamp
      },
      %{
        id: @harborline_tenant_id,
        name: "Harborline Logistics",
        slug: "harborline",
        inserted_at: @fixed_timestamp,
        updated_at: @fixed_timestamp
      }
    ]
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
      },
      %{
        id: @maya_patel_id,
        tenant_id: @harborline_tenant_id,
        name: "Maya Patel",
        email: "maya@harborline.example.com",
        inserted_at: @fixed_timestamp,
        updated_at: @fixed_timestamp
      },
      %{
        id: @luis_ortega_id,
        tenant_id: @harborline_tenant_id,
        name: "Luis Ortega",
        email: "luis@harborline.example.com",
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
      },
      %{
        id: @harborline_admin_group_id,
        tenant_id: @harborline_tenant_id,
        name: "Administrators",
        key: "admins",
        inserted_at: @fixed_timestamp,
        updated_at: @fixed_timestamp
      },
      %{
        id: @harborline_ops_group_id,
        tenant_id: @harborline_tenant_id,
        name: "Operations",
        key: "operations",
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
      },
      %{
        id: @maya_membership_id,
        user_id: @maya_patel_id,
        group_id: @harborline_admin_group_id,
        inserted_at: @fixed_timestamp,
        updated_at: @fixed_timestamp
      },
      %{
        id: @luis_membership_id,
        user_id: @luis_ortega_id,
        group_id: @harborline_ops_group_id,
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
      },
      %{
        id: @maya_identity_id,
        user_id: @maya_patel_id,
        subject: "maya@harborline.example.com",
        issuer: "https://idp.harborline.example.com",
        inserted_at: @fixed_timestamp,
        updated_at: @fixed_timestamp
      },
      %{
        id: @luis_identity_id,
        user_id: @luis_ortega_id,
        subject: "luis@harborline.example.com",
        issuer: "https://idp.harborline.example.com",
        inserted_at: @fixed_timestamp,
        updated_at: @fixed_timestamp
      }
    ]
  end
end
