defmodule Relyra.Ecto.MetadataApplyTest do
  use Relyra.TestSupport.MigrationCase, async: false

  alias Relyra.ConnectionResolver.Ecto, as: EctoResolver
  alias Relyra.Metadata.Import

  alias Relyra.Ecto.{
    AuditEvent,
    Certificate,
    CertificateInventory,
    Connection,
    MetadataApply,
    MetadataRevision,
    MetadataSource
  }

  @repo Relyra.TestSupport.EctoTestRepo

  test "apply_revision stages new certificates while preserving the active runtime trust set" do
    connection = insert_enabled_connection!("01JT71VSVCKX7RZ9KD5W6F4H11")

    assert {:ok, revision} =
             MetadataApply.apply_revision(
               connection.connection_id,
               candidate(),
               applied_revision_attrs(),
               repo: @repo
             )

    updated =
      @repo.get_by!(Connection, connection_id: connection.connection_id)
      |> @repo.preload(:certificates)

    assert updated.idp_entity_id == "https://metadata.idp.example.com/entity"
    assert updated.idp_sso_url == "https://metadata.idp.example.com/sso/redirect"
    assert updated.active_metadata_revision_id == revision.id
    assert updated.last_known_good_metadata_revision_id == revision.id

    assert Enum.map(updated.certificates, & &1.fingerprint_sha256) |> Enum.sort() ==
             ["fp-old" | candidate().certificate_fingerprints] |> Enum.sort()

    assert Enum.any?(
             updated.certificates,
             &(&1.fingerprint_sha256 == "fp-old" and &1.lifecycle_state == :active)
           )

    assert Enum.all?(
             Enum.filter(
               updated.certificates,
               &(&1.fingerprint_sha256 in candidate().certificate_fingerprints)
             ),
             fn cert ->
               cert.lifecycle_state == :next and
                 String.starts_with?(cert.source, "metadata_revision:")
             end
           )

    assert {:ok, resolved} =
             EctoResolver.resolve_connection(%{connection_id: connection.connection_id},
               repo: @repo
             )

    assert resolved.idp_certificates == [
             "-----BEGIN CERTIFICATE-----\nOLD\n-----END CERTIFICATE-----"
           ]

    events =
      AuditEvent
      |> @repo.all()
      |> Enum.sort_by(&DateTime.to_unix(&1.inserted_at, :microsecond))

    assert Enum.map(events, &{&1.domain, &1.action}) == [
             {:certificate, :staged},
             {:metadata, :applied}
           ]

    assert Enum.at(events, 0).diff_summary["metadata_revision_id"] == revision.id
    assert Enum.at(events, 1).diff_summary["outcome"] == "applied"
  end

  test "apply_revision rolls back revision and certificate changes when certificate data is invalid" do
    connection = insert_enabled_connection!("01JT71VSVCKX7RZ9KD5W6F4H12")

    original =
      @repo.get_by!(Connection, connection_id: connection.connection_id)
      |> @repo.preload(:certificates)

    assert {:error, %Relyra.Error{type: :invalid_connection_record}} =
             MetadataApply.apply_revision(
               connection.connection_id,
               invalid_candidate(),
               applied_revision_attrs(),
               repo: @repo
             )

    refute @repo.get_by(MetadataRevision, effective_idp_entity_id: candidate().idp_entity_id)

    persisted =
      @repo.get_by!(Connection, connection_id: connection.connection_id)
      |> @repo.preload(:certificates)

    assert persisted.idp_entity_id == original.idp_entity_id
    assert persisted.idp_sso_url == original.idp_sso_url
    assert persisted.active_metadata_revision_id == original.active_metadata_revision_id
    assert Enum.map(persisted.certificates, & &1.fingerprint_sha256) == ["fp-old"]

    assert {:ok, resolved} =
             EctoResolver.resolve_connection(%{connection_id: connection.connection_id},
               repo: @repo
             )

    assert resolved.idp_entity_id == original.idp_entity_id
    assert resolved.idp_sso_url == original.idp_sso_url

    assert resolved.idp_certificates == [
             "-----BEGIN CERTIFICATE-----\nOLD\n-----END CERTIFICATE-----"
           ]

    assert @repo.aggregate(AuditEvent, :count) == 0
  end

  test "record_attempt persists failed metadata attempts without mutating the runtime aggregate" do
    connection = insert_enabled_connection!("01JT71VSVCKX7RZ9KD5W6F4H13")
    original = @repo.get_by!(Connection, connection_id: connection.connection_id)

    assert {:ok, revision} =
             MetadataApply.record_attempt(
               connection.connection_id,
               %{
                 source_kind: :xml_import,
                 trigger: :manual_import,
                 actor: "operator@example.com",
                 cause: "parse failure",
                 outcome: :parse_failed,
                 details: %{xml: String.duplicate("x", 400)}
               },
               repo: @repo
             )

    assert revision.source_kind == :xml_import
    assert revision.trigger == :manual_import
    assert revision.cause == "parse failure"
    assert revision.details.xml == "[REDACTED]"

    persisted = @repo.get_by!(Connection, connection_id: connection.connection_id)
    assert persisted.active_metadata_revision_id == original.active_metadata_revision_id

    assert persisted.last_known_good_metadata_revision_id ==
             original.last_known_good_metadata_revision_id

    assert {:ok, resolved} =
             EctoResolver.resolve_connection(%{connection_id: connection.connection_id},
               repo: @repo
             )

    assert resolved.idp_entity_id == original.idp_entity_id
    assert resolved.idp_sso_url == original.idp_sso_url
    assert @repo.aggregate(AuditEvent, :count) == 0
  end

  test "activate_signing_certificate and retire_signing_certificate update runtime trust explicitly" do
    connection = insert_enabled_connection!("01JT71VSVCKX7RZ9KD5W6F4H14")

    assert {:ok, revision} =
             MetadataApply.apply_revision(
               connection.connection_id,
               candidate(),
               applied_revision_attrs(),
               repo: @repo
             )

    assert {:ok, _cert} =
             CertificateInventory.activate_signing_certificate(
               @repo,
               connection.connection_id,
               List.first(candidate().certificate_fingerprints),
               audit: %{actor: "ops@example.com", cause: "promote_cert"}
             )

    assert {:ok, resolved_with_overlap} =
             EctoResolver.resolve_connection(%{connection_id: connection.connection_id},
               repo: @repo
             )

    assert resolved_with_overlap.idp_certificates == [
             "-----BEGIN CERTIFICATE-----\nOLD\n-----END CERTIFICATE-----",
             List.first(candidate().certificate_pems)
           ]

    assert {:ok, _cert} =
             CertificateInventory.retire_signing_certificate(
               @repo,
               connection.connection_id,
               "fp-old",
               audit: %{actor: "ops@example.com", cause: "retire_old"}
             )

    assert {:ok, resolved_after_retire} =
             EctoResolver.resolve_connection(%{connection_id: connection.connection_id},
               repo: @repo
             )

    assert resolved_after_retire.idp_certificates == [
             List.first(candidate().certificate_pems)
           ]

    assert revision.id == @repo.get!(Connection, connection.id).active_metadata_revision_id

    events =
      AuditEvent
      |> @repo.all()
      |> Enum.sort_by(&DateTime.to_unix(&1.inserted_at, :microsecond))

    assert Enum.map(events, &{&1.domain, &1.action}) == [
             {:certificate, :staged},
             {:metadata, :applied},
             {:certificate, :activated},
             {:certificate, :retired}
           ]
  end

  test "retiring the last active signing certificate is rejected" do
    connection = insert_enabled_connection!("01JT71VSVCKX7RZ9KD5W6F4H15")

    assert {:error, %Relyra.Error{type: :invalid_connection_record, details: details}} =
             CertificateInventory.retire_signing_certificate(
               @repo,
               connection.connection_id,
               "fp-old"
             )

    assert details.reason == :last_active_certificate
  end

  # ──────────────────────────────────────────────────────────────────────
  # Phase 21 (W2 / Plan 21-04) — audit-seam extension coverage.
  # D-28 single-transaction discipline: health-state co-commits with
  # MetadataRevision row + audit row inside ONE transact/2 block.
  # ──────────────────────────────────────────────────────────────────────

  describe "Phase 21: scheduled trigger health-state side-effect" do
    test "manual refresh path is unchanged: trigger: :manual_refresh produces a MetadataRevision row but does NOT mutate MetadataSource health fields" do
      connection = insert_enabled_connection!("01JT71VSVCKX7RZ9KD5W6F4P01")
      source = insert_metadata_source!(connection.id, consecutive_failure_count: 3)

      assert {:ok, _revision} =
               MetadataApply.record_attempt(
                 connection.connection_id,
                 %{
                   metadata_source_id: source.id,
                   source_kind: :xml_import,
                   trigger: :manual_refresh,
                   actor: "ops@example.com",
                   cause: "manual refresh test",
                   outcome: :fetch_failed,
                   details: %{error_code: :fetch_timeout}
                 },
                 repo: @repo
               )

      reloaded = @repo.get!(MetadataSource, source.id)
      assert reloaded.consecutive_failure_count == 3
      assert is_nil(reloaded.last_failure_error_code)
      assert is_nil(reloaded.auto_suspended_until)
    end

    test "scheduled refresh failure with transient error_code increments consecutive_failure_count and updates last_failure_error_code" do
      connection = insert_enabled_connection!("01JT71VSVCKX7RZ9KD5W6F4P02")
      source = insert_metadata_source!(connection.id)

      assert {:ok, _revision} =
               MetadataApply.record_attempt(
                 connection.connection_id,
                 scheduled_refresh_attrs(source.id, :fetch_timeout),
                 repo: @repo
               )

      reloaded = @repo.get!(MetadataSource, source.id)
      assert reloaded.consecutive_failure_count == 1
      assert reloaded.last_failure_error_code == "fetch_timeout"
      assert is_nil(reloaded.auto_suspended_until)
      refute is_nil(reloaded.first_failure_at)
    end

    test "scheduled refresh failure with suspicious error_code does NOT increment counter (D-27)" do
      connection = insert_enabled_connection!("01JT71VSVCKX7RZ9KD5W6F4P03")
      source = insert_metadata_source!(connection.id)

      assert {:ok, _revision} =
               MetadataApply.record_attempt(
                 connection.connection_id,
                 %{
                   metadata_source_id: source.id,
                   source_kind: :remote_url,
                   trigger: :scheduled_refresh,
                   actor: "scheduler",
                   cause: "scheduled refresh",
                   outcome: :validation_failed,
                   details: %{error_code: :signature_failed}
                 },
                 repo: @repo
               )

      reloaded = @repo.get!(MetadataSource, source.id)
      assert reloaded.consecutive_failure_count == 0
      assert reloaded.last_failure_error_code == "signature_failed"
      assert is_nil(reloaded.auto_suspended_until)
    end

    test "5 consecutive transient failures sets auto_suspended_until and auto_suspended_reason" do
      connection = insert_enabled_connection!("01JT71VSVCKX7RZ9KD5W6F4P04")
      source = insert_metadata_source!(connection.id)
      now_before = DateTime.utc_now()

      Enum.each(1..5, fn _ ->
        assert {:ok, _} =
                 MetadataApply.record_attempt(
                   connection.connection_id,
                   scheduled_refresh_attrs(source.id, :fetch_timeout),
                   repo: @repo
                 )
      end)

      reloaded = @repo.get!(MetadataSource, source.id)
      assert reloaded.consecutive_failure_count == 5
      assert reloaded.auto_suspended_reason == :transient_failures_exceeded

      # 1h ± 10% jitter window (3240–3960s after now_before)
      assert %DateTime{} = reloaded.auto_suspended_until
      diff_seconds = DateTime.diff(reloaded.auto_suspended_until, now_before, :second)
      assert diff_seconds >= 3240
      assert diff_seconds <= 3960
    end

    test "explicit auto_suspended_reason in attrs overrides the default (drift / corpus / signature paths set their own)" do
      connection = insert_enabled_connection!("01JT71VSVCKX7RZ9KD5W6F4P05")
      source = insert_metadata_source!(connection.id)

      Enum.each(1..5, fn _ ->
        assert {:ok, _} =
                 MetadataApply.record_attempt(
                   connection.connection_id,
                   scheduled_refresh_attrs(source.id, :fetch_timeout)
                   |> Map.put(:auto_suspended_reason, :entity_id_drift),
                   repo: @repo
                 )
      end)

      reloaded = @repo.get!(MetadataSource, source.id)
      assert reloaded.auto_suspended_reason == :entity_id_drift
    end

    test "successful scheduled apply resets every health field and advances next_refresh_at (Pitfall 6)" do
      connection = insert_enabled_connection!("01JT71VSVCKX7RZ9KD5W6F4P06")
      future = DateTime.add(DateTime.utc_now(), 3_600, :second)

      source =
        insert_metadata_source!(connection.id,
          consecutive_failure_count: 5,
          first_failure_at: DateTime.utc_now(),
          last_failure_error_code: "fetch_timeout",
          auto_suspended_until: future,
          auto_suspended_reason: :transient_failures_exceeded
        )

      assert {:ok, _revision} =
               MetadataApply.apply_revision(
                 connection.connection_id,
                 candidate(),
                 applied_revision_attrs()
                 |> Map.put(:trigger, :scheduled_refresh)
                 |> Map.put(:metadata_source_id, source.id),
                 repo: @repo
               )

      reloaded = @repo.get!(MetadataSource, source.id)
      assert reloaded.consecutive_failure_count == 0
      assert is_nil(reloaded.first_failure_at)
      assert is_nil(reloaded.last_failure_error_code)
      assert is_nil(reloaded.auto_suspended_until)
      assert is_nil(reloaded.auto_suspended_reason)
      assert %DateTime{} = reloaded.last_success_at
      assert %DateTime{} = reloaded.next_refresh_at

      # default cadence :daily (86_400s) ± 15% jitter — between ~73_440 and ~99_360s ahead
      ahead_seconds = DateTime.diff(reloaded.next_refresh_at, DateTime.utc_now(), :second)
      assert ahead_seconds >= 73_440
      assert ahead_seconds <= 99_360
    end

    test "successful scheduled apply unions candidate fingerprints into last_known_metadata_signing_certs" do
      connection = insert_enabled_connection!("01JT71VSVCKX7RZ9KD5W6F4P07")

      source =
        insert_metadata_source!(connection.id,
          last_known_metadata_signing_certs: ["aaa"]
        )

      candidate_fingerprints = candidate().certificate_fingerprints

      assert {:ok, _revision} =
               MetadataApply.apply_revision(
                 connection.connection_id,
                 candidate(),
                 applied_revision_attrs()
                 |> Map.put(:trigger, :scheduled_refresh)
                 |> Map.put(:metadata_source_id, source.id),
                 repo: @repo
               )

      reloaded = @repo.get!(MetadataSource, source.id)

      assert Enum.sort(reloaded.last_known_metadata_signing_certs) ==
               Enum.sort(["aaa" | candidate_fingerprints])
    end

    test "single-transaction guarantee: a health_state_changeset failure rolls back the MetadataRevision insert" do
      connection = insert_enabled_connection!("01JT71VSVCKX7RZ9KD5W6F4P08")
      source = insert_metadata_source!(connection.id, consecutive_failure_count: 4)

      # Bring count to 4 first via real failures (no suspend yet because
      # threshold is 5).
      revision_count_at_threshold = @repo.aggregate(MetadataRevision, :count, :id)

      # The 5th attempt with an invalid auto_suspended_reason atom hits the
      # threshold path inside compute_failure_health_state/3, so the invalid
      # reason DOES enter the cast — health_state_changeset/2 rejects it,
      # forcing rollback of BOTH writes.
      assert {:error, %Relyra.Error{}} =
               MetadataApply.record_attempt(
                 connection.connection_id,
                 scheduled_refresh_attrs(source.id, :fetch_timeout)
                 |> Map.put(:auto_suspended_reason, :not_a_valid_reason),
                 repo: @repo
               )

      revision_count_after = @repo.aggregate(MetadataRevision, :count, :id)
      # The failed attempt must NOT have left a MetadataRevision row behind.
      assert revision_count_after == revision_count_at_threshold

      # The source row health-state must NOT have advanced past pre-attempt state.
      reloaded = @repo.get!(MetadataSource, source.id)
      assert reloaded.consecutive_failure_count == 4
      assert is_nil(reloaded.auto_suspended_until)
      assert is_nil(reloaded.auto_suspended_reason)
    end

    test "manual import path (trigger: :manual_import) does not touch health state" do
      connection = insert_enabled_connection!("01JT71VSVCKX7RZ9KD5W6F4P09")
      source = insert_metadata_source!(connection.id, consecutive_failure_count: 2)

      assert {:ok, _revision} =
               MetadataApply.record_attempt(
                 connection.connection_id,
                 %{
                   metadata_source_id: source.id,
                   source_kind: :xml_import,
                   trigger: :manual_import,
                   actor: "operator@example.com",
                   cause: "manual import",
                   outcome: :fetch_failed,
                   details: %{error_code: :fetch_timeout}
                 },
                 repo: @repo
               )

      reloaded = @repo.get!(MetadataSource, source.id)
      assert reloaded.consecutive_failure_count == 2
      assert is_nil(reloaded.last_failure_error_code)
    end
  end

  describe "Phase 21: D-24 state-transition telemetry events (B1)" do
    setup [:attach_phase21_telemetry]

    test ":degraded telemetry event fires on the first transient failure (consecutive_failure_count 0 -> 1)" do
      connection = insert_enabled_connection!("01JT71VSVCKX7RZ9KD5W6F4P10")
      source = insert_metadata_source!(connection.id)

      assert {:ok, _} =
               MetadataApply.record_attempt(
                 connection.connection_id,
                 scheduled_refresh_attrs(source.id, :fetch_timeout),
                 repo: @repo
               )

      assert_receive {:phase21_telemetry, [:relyra, :saml, :metadata, :auto_refresh, :degraded],
                      _measurements, metadata}

      assert metadata.source_id == source.id
      assert metadata.connection_record_id == connection.id
      assert metadata.error_code == "fetch_timeout"
      assert metadata.consecutive_failure_count == 1
      assert metadata.transient? == true
      assert metadata.counts_toward_suspend? == true

      refute_received {:phase21_telemetry, [:relyra, :saml, :metadata, :auto_refresh, :suspended],
                       _, _}
    end

    test ":degraded does NOT re-fire on the 2nd, 3rd, 4th consecutive transient failure" do
      connection = insert_enabled_connection!("01JT71VSVCKX7RZ9KD5W6F4P11")
      source = insert_metadata_source!(connection.id)

      Enum.each(1..4, fn _ ->
        MetadataApply.record_attempt(
          connection.connection_id,
          scheduled_refresh_attrs(source.id, :fetch_timeout),
          repo: @repo
        )
      end)

      degraded_events =
        drain_phase21_events([:relyra, :saml, :metadata, :auto_refresh, :degraded])

      assert length(degraded_events) == 1
    end

    test ":suspended telemetry event fires on the 5th consecutive transient failure (auto_suspended_until set from nil)" do
      connection = insert_enabled_connection!("01JT71VSVCKX7RZ9KD5W6F4P12")
      source = insert_metadata_source!(connection.id)

      Enum.each(1..5, fn _ ->
        MetadataApply.record_attempt(
          connection.connection_id,
          scheduled_refresh_attrs(source.id, :fetch_timeout),
          repo: @repo
        )
      end)

      suspended_events =
        drain_phase21_events([:relyra, :saml, :metadata, :auto_refresh, :suspended])

      assert length(suspended_events) == 1

      [{_event, _measurements, metadata}] = suspended_events
      assert metadata.auto_suspended_reason == :transient_failures_exceeded
      assert metadata.consecutive_failure_count == 5
    end

    test ":recovered telemetry event fires on a successful apply against a previously-suspended source" do
      connection = insert_enabled_connection!("01JT71VSVCKX7RZ9KD5W6F4P13")
      future = DateTime.add(DateTime.utc_now(), 3_600, :second)

      source =
        insert_metadata_source!(connection.id,
          consecutive_failure_count: 5,
          auto_suspended_until: future,
          auto_suspended_reason: :transient_failures_exceeded
        )

      assert {:ok, _revision} =
               MetadataApply.apply_revision(
                 connection.connection_id,
                 candidate(),
                 applied_revision_attrs()
                 |> Map.put(:trigger, :scheduled_refresh)
                 |> Map.put(:metadata_source_id, source.id),
                 repo: @repo
               )

      recovered_events =
        drain_phase21_events([:relyra, :saml, :metadata, :auto_refresh, :recovered])

      assert length(recovered_events) == 1

      [{_event, _measurements, metadata}] = recovered_events
      assert is_nil(metadata.auto_suspended_reason)
      assert metadata.consecutive_failure_count == 0
    end

    test "telemetry events carry the correlation_id from revision_attrs[:audit][:correlation_id] when present" do
      connection = insert_enabled_connection!("01JT71VSVCKX7RZ9KD5W6F4P14")
      source = insert_metadata_source!(connection.id)

      attrs =
        scheduled_refresh_attrs(source.id, :fetch_timeout)
        |> Map.put(:audit, %{correlation_id: "uuid-xyz"})

      assert {:ok, _} =
               MetadataApply.record_attempt(connection.connection_id, attrs, repo: @repo)

      assert_receive {:phase21_telemetry, [:relyra, :saml, :metadata, :auto_refresh, :degraded],
                      _measurements, metadata}

      assert metadata.correlation_id == "uuid-xyz"
    end

    test "no state-transition events fire when the manual path is exercised" do
      connection = insert_enabled_connection!("01JT71VSVCKX7RZ9KD5W6F4P15")
      source = insert_metadata_source!(connection.id)

      assert {:ok, _} =
               MetadataApply.record_attempt(
                 connection.connection_id,
                 %{
                   metadata_source_id: source.id,
                   source_kind: :xml_import,
                   trigger: :manual_refresh,
                   actor: "operator@example.com",
                   cause: "manual refresh",
                   outcome: :fetch_failed,
                   details: %{error_code: :fetch_timeout}
                 },
                 repo: @repo
               )

      refute_received {:phase21_telemetry, [:relyra, :saml, :metadata, :auto_refresh, :degraded],
                       _, _}

      refute_received {:phase21_telemetry, [:relyra, :saml, :metadata, :auto_refresh, :suspended],
                       _, _}

      refute_received {:phase21_telemetry, [:relyra, :saml, :metadata, :auto_refresh, :recovered],
                       _, _}
    end
  end

  describe "Phase 21: resume_auto_refresh/3 (D-28 single-transaction Resume-now seam)" do
    test "co-commits audit row + suspend-clear in ONE transaction (D-28)" do
      connection = insert_enabled_connection!("01JT71VSVCKX7RZ9KD5W6F4P19")
      future = DateTime.add(DateTime.utc_now(), 3_600, :second)

      source =
        insert_metadata_source!(connection.id,
          consecutive_failure_count: 5,
          auto_suspended_until: future,
          auto_suspended_reason: :transient_failures_exceeded
        )

      assert {:ok, %{audit_event: audit_event, source: updated}} =
               MetadataApply.resume_auto_refresh(@repo, source, %{actor: "operator-test"})

      assert is_nil(updated.auto_suspended_until)
      assert is_nil(updated.auto_suspended_reason)

      events = AuditEvent |> @repo.all()
      resume_events = Enum.filter(events, &(&1.cause == "live_admin_auto_refresh_resume"))
      assert length(resume_events) == 1

      [event] = resume_events
      assert event.id == audit_event.id
      assert event.actor == "operator-test"
      assert event.domain == :metadata
      assert event.action == :refreshed
      assert event.connection_record_id == connection.id
    end

    test "rolls back BOTH writes when the audit-row insert fails (rollback proof)" do
      connection = insert_enabled_connection!("01JT71VSVCKX7RZ9KD5W6F4P20")
      future = DateTime.add(DateTime.utc_now(), 3_600, :second)

      source =
        insert_metadata_source!(connection.id,
          consecutive_failure_count: 5,
          auto_suspended_until: future,
          auto_suspended_reason: :transient_failures_exceeded
        )

      audit_count_before = @repo.aggregate(AuditEvent, :count, :id)

      # Empty actor forces AuditWriter.append_event to reject (cause/actor are
      # required and must be present strings).
      assert {:error, %Relyra.Error{}} =
               MetadataApply.resume_auto_refresh(@repo, source, %{actor: "", cause: ""})

      # Suspend-clear must NOT have persisted.
      reloaded = @repo.get!(MetadataSource, source.id)
      assert DateTime.compare(reloaded.auto_suspended_until, future) == :eq
      assert reloaded.auto_suspended_reason == :transient_failures_exceeded

      # No audit event written.
      assert @repo.aggregate(AuditEvent, :count, :id) == audit_count_before
    end
  end

  describe "Phase 21: record_validity_warning/3 (B2)" do
    setup [:attach_phase21_telemetry]

    test "emits :validity_warning when slack is negative AND last_validity_warning_for is nil" do
      connection = insert_enabled_connection!("01JT71VSVCKX7RZ9KD5W6F4P16")
      source = insert_metadata_source!(connection.id, last_validity_warning_for: nil)
      valid_until = ~U[2026-06-01 00:00:00.000000Z]

      assert {:ok, :emitted} =
               MetadataApply.record_validity_warning(@repo, source, %{
                 valid_until: valid_until,
                 refresh_interval_seconds: 86_400,
                 correlation_id: "uuid",
                 slack_seconds: -1_000
               })

      assert_receive {:phase21_telemetry,
                      [:relyra, :saml, :metadata, :auto_refresh, :validity_warning],
                      _measurements, metadata}

      assert metadata.source_id == source.id
      assert metadata.correlation_id == "uuid"
      assert metadata.valid_until == valid_until
      assert metadata.refresh_interval_seconds == 86_400
      assert metadata.slack_seconds == -1_000

      reloaded = @repo.get!(MetadataSource, source.id)
      assert DateTime.compare(reloaded.last_validity_warning_for, valid_until) == :eq
    end

    test "SUPPRESSES re-fire when last_validity_warning_for >= candidate valid_until (at-most-once per validUntil per source)" do
      connection = insert_enabled_connection!("01JT71VSVCKX7RZ9KD5W6F4P17")
      stored = ~U[2026-06-01 00:00:00.000000Z]
      source = insert_metadata_source!(connection.id, last_validity_warning_for: stored)

      assert {:ok, :suppressed} =
               MetadataApply.record_validity_warning(@repo, source, %{
                 valid_until: stored,
                 refresh_interval_seconds: 86_400,
                 correlation_id: "uuid"
               })

      refute_received {:phase21_telemetry,
                       [:relyra, :saml, :metadata, :auto_refresh, :validity_warning], _, _}

      reloaded = @repo.get!(MetadataSource, source.id)
      assert DateTime.compare(reloaded.last_validity_warning_for, stored) == :eq
    end

    test "RE-FIRES when IdP publishes a NEW (later) validUntil" do
      connection = insert_enabled_connection!("01JT71VSVCKX7RZ9KD5W6F4P18")
      stored = ~U[2026-06-01 00:00:00.000000Z]
      newer = ~U[2026-07-01 00:00:00.000000Z]
      source = insert_metadata_source!(connection.id, last_validity_warning_for: stored)

      assert {:ok, :emitted} =
               MetadataApply.record_validity_warning(@repo, source, %{
                 valid_until: newer,
                 refresh_interval_seconds: 86_400,
                 correlation_id: "uuid"
               })

      assert_receive {:phase21_telemetry,
                      [:relyra, :saml, :metadata, :auto_refresh, :validity_warning],
                      _measurements, _metadata}

      reloaded = @repo.get!(MetadataSource, source.id)
      assert DateTime.compare(reloaded.last_validity_warning_for, newer) == :eq
    end
  end

  defp attach_phase21_telemetry(_context) do
    test_pid = self()
    handler_id = "phase21-telemetry-#{System.unique_integer([:positive])}"

    events = [
      [:relyra, :saml, :metadata, :auto_refresh, :degraded],
      [:relyra, :saml, :metadata, :auto_refresh, :suspended],
      [:relyra, :saml, :metadata, :auto_refresh, :recovered],
      [:relyra, :saml, :metadata, :auto_refresh, :validity_warning]
    ]

    :telemetry.attach_many(
      handler_id,
      events,
      fn event, measurements, metadata, _config ->
        send(test_pid, {:phase21_telemetry, event, measurements, metadata})
      end,
      nil
    )

    on_exit(fn -> :telemetry.detach(handler_id) end)

    :ok
  end

  defp drain_phase21_events(target_event) do
    drain_phase21_events(target_event, [])
  end

  defp drain_phase21_events(target_event, acc) do
    receive do
      {:phase21_telemetry, ^target_event, measurements, metadata} ->
        drain_phase21_events(target_event, [{target_event, measurements, metadata} | acc])
    after
      0 -> Enum.reverse(acc)
    end
  end

  defp scheduled_refresh_attrs(source_id, error_code) do
    %{
      metadata_source_id: source_id,
      source_kind: :remote_url,
      trigger: :scheduled_refresh,
      actor: "scheduler",
      cause: "scheduled refresh tick",
      outcome: :fetch_failed,
      details: %{error_code: error_code}
    }
  end

  defp insert_metadata_source!(connection_record_id, overrides \\ []) do
    base_attrs = %{
      connection_record_id: connection_record_id,
      url: "https://idp.example.com/metadata",
      kind: :remote_url,
      registered_by: "operator@example.com",
      registered_reason: "phase 21 test fixture",
      last_outcome: :registered
    }

    {:ok, source} =
      %MetadataSource{}
      |> MetadataSource.changeset(base_attrs)
      |> @repo.insert()

    if overrides == [] do
      source
    else
      source
      |> Ecto.Changeset.change(Map.new(overrides))
      |> @repo.update!()
    end
  end

  defp insert_enabled_connection!(connection_id) do
    now = DateTime.utc_now()

    {:ok, prior_revision} =
      %MetadataRevision{}
      |> MetadataRevision.changeset(%{
        connection_record_id: insert_draft_connection!(connection_id).id,
        source_kind: :xml_import,
        trigger: :manual_import,
        outcome: :applied,
        trust_summary: %{status: "seed"}
      })
      |> @repo.insert()

    connection =
      @repo.get_by!(Connection, connection_id: connection_id)
      |> Ecto.Changeset.change(%{
        status: :enabled,
        sp_entity_id: "https://sp.example.com/metadata",
        acs_url: "https://sp.example.com/saml/acs",
        idp_entity_id: "https://old.idp.example.com/entity",
        idp_sso_url: "https://old.idp.example.com/sso",
        active_metadata_revision_id: prior_revision.id,
        last_known_good_metadata_revision_id: prior_revision.id,
        updated_at: now
      })
      |> @repo.update!()

    %Certificate{
      id: Ecto.UUID.generate(),
      connection_record_id: connection.id,
      fingerprint_sha256: "fp-old",
      pem: "-----BEGIN CERTIFICATE-----\nOLD\n-----END CERTIFICATE-----",
      source: "manual",
      role: :signing,
      lifecycle_state: :active,
      activated_at: now,
      inserted_at: now,
      updated_at: now,
      metadata: %{}
    }
    |> @repo.insert!()

    @repo.get!(Connection, connection.id)
  end

  defp insert_draft_connection!(connection_id) do
    now = DateTime.utc_now()

    %Connection{
      id: Ecto.UUID.generate(),
      connection_id: connection_id,
      status: :draft,
      inserted_at: now,
      updated_at: now
    }
    |> @repo.insert!()
  end

  defp candidate do
    Import.build_candidate(%{
      entity_id: "https://metadata.idp.example.com/entity",
      sso_services: [
        %{
          binding: "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect",
          location: "https://metadata.idp.example.com/sso/redirect"
        }
      ],
      certificates: [pem_body(cert_one_pem()), pem_body(cert_two_pem())]
    })
  end

  defp applied_revision_attrs do
    %{
      source_kind: :xml_import,
      trigger: :manual_import,
      outcome: :applied,
      actor: "operator@example.com",
      cause: "manual import",
      trust_summary: %{status: "applied", certificate_count: 2}
    }
  end

  defp invalid_candidate do
    Import.build_candidate(%{
      entity_id: "https://metadata.idp.example.com/entity",
      sso_services: [
        %{
          binding: "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect",
          location: "https://metadata.idp.example.com/sso/redirect"
        }
      ],
      certificates: ["INVALIDCERTIFICATEBODY"]
    })
    |> Map.from_struct()
  end

  defp pem_body(pem) do
    pem
    |> String.replace("-----BEGIN CERTIFICATE-----\n", "")
    |> String.replace("\n-----END CERTIFICATE-----\n", "")
    |> String.replace("\n", "")
  end

  defp cert_one_pem do
    """
    -----BEGIN CERTIFICATE-----
    MIIDEzCCAfugAwIBAgIUL4tsJefr6QE1KzzBr+YBxOfBqd8wDQYJKoZIhvcNAQEL
    BQAwGTEXMBUGA1UEAwwOcGhhc2UxMC10ZXN0LTEwHhcNMjYwNTA1MjAxODUwWhcN
    MjYwNjA0MjAxODUwWjAZMRcwFQYDVQQDDA5waGFzZTEwLXRlc3QtMTCCASIwDQYJ
    KoZIhvcNAQEBBQADggEPADCCAQoCggEBAM1cwb/hjGGAKdoFzQ3ZumZ5w2EwisU6
    JrZ1tsLZvzuBFDnQwSMIlEBnOZcxVb6gBS1yKytU04m3w8Yuz+poJIHxURndwOtD
    As4ogUEriv8Q9snb9dvjhJMUHzt8aFiG/dF8TyCbYqpyeElV6dA+gzACm570t23Z
    WFv49ucgekmOxomW6EbsuNwD3eH9eU5vLxXjXp/pdZfWHB37yuZbsawYPbZKlmlM
    Ua5iYt+cLqODJJviF9p9XqjnzgEN9MC8vE2LxSHK7sMdWpjEwVRVuIxcNqseewcY
    IFx0Qp++PrSLkkDhkH4rpkZGOCbrnkxhEwctxyc8F+WbYwuaB3Y20EUCAwEAAaNT
    MFEwHQYDVR0OBBYEFJqT5ohQRMzc7ciLx25XzHFHrQVtMB8GA1UdIwQYMBaAFJqT
    5ohQRMzc7ciLx25XzHFHrQVtMA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZIhvcNAQEL
    BQADggEBAGRp3+eeSCL/A4uKAV8zh+uYiQurc0ouQr5gBzihRrHMDj1Qf6T9wJgV
    o70LKpcuGpmrxH4Bqdf7W3s9snC+g+Cg2JK2Y2akMhjJ0W/jeiCc4SYswEbx3FK3
    oIfM63NPDsxWrFCAVQCK3k2/a2Go2FPZ8EjBTkRKsVGADK7ufYUcoyqEOhdK6+Z6
    oPE1fBjvoNomETj50YKOkEj2tAeSarR1vNLPihuV/pGsxOAx9QGnC2Vxn1LfU+G1
    sBJ8LDs/OhHf/H1rJjmgqE85KV3ACm0UV4YYW8XXmRRUQCV7nFG6cS+Gnks2bTwv
    7OBCV0aYyNmkxkWbGiyNRtwu83BRVdc=
    -----END CERTIFICATE-----
    """
  end

  defp cert_two_pem do
    """
    -----BEGIN CERTIFICATE-----
    MIIDEzCCAfugAwIBAgIUXVtzU8ffQDHWYvtv2Y0kLqwKqtYwDQYJKoZIhvcNAQEL
    BQAwGTEXMBUGA1UEAwwOcGhhc2UxMC10ZXN0LTIwHhcNMjYwNTA1MjAxODUwWhcN
    MjYwODAzMjAxODUwWjAZMRcwFQYDVQQDDA5waGFzZTEwLXRlc3QtMjCCASIwDQYJ
    KoZIhvcNAQEBBQADggEPADCCAQoCggEBANtAySPCQWOd+oNvfnfkLYeyzeoSOuHP
    K5K6Jsbj7JobGvAO6uSN1qlkOItclJH4LFK6hQXLeqnSbuuITiCg8IREElH5Z2Dj
    YPI/H9WRc+xjfyOxaQS3Q1Lm0Tm/jCgTbB6FPTfr2/EnYNpgiEOP+iIg+e++RWqi
    Zn9ub3/Rfg37eHRERhxwKxC7HYXukwIVf5vj3nasyR6LLREBpqKIYt2Hvc75h/Qf
    0ULknFOc+wa1AE5hZs6gckCph8LcLR8BYnwHWcEPr23o4QBncKSga00xdhX+TUYK
    BSXDRpz92OIfxTn+ig5xyaeYvenUtKVXn9TPC62w3ipM+tg2R9i/sY0CAwEAAaNT
    MFEwHQYDVR0OBBYEFMlYhziYSpJJxzY6fzciZDK9XRrUMB8GA1UdIwQYMBaAFMlY
    hziYSpJJxzY6fzciZDK9XRrUMA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZIhvcNAQEL
    BQADggEBAGmRgs4UZFXt/jS5HMLqF4REobCzq/LV3TC+MIp3DgT3zEk8dpJijFhX
    mvMis52P8O4u95NVKVfjvRZcW/fXYWALaFDms7pUJnnteuggVVpzF2ZB84wxB3Op
    8FSUyhD9rPZLqOOuEfaFfzySSAwN8qger1gYgrzzCEDXKmsigam2NdTeHqnBx7dW
    nZ2mWI43dw3K9zwo30njAPPELb4CuK7I80ZV7gb3Uo13qe5oN6zXjwc/zYrFkTDm
    C4m3WtD2buRS/kf5o/+3U/IPmvseekE//IoZ3ZqWh3pJhFvnAiv0mb8cKXA5Rl2U
    OBiJCYv0CChnwYhjWmr+Ot9HdHcHqM4=
    -----END CERTIFICATE-----
    """
  end
end
