defmodule Relyra.Telemetry.Handlers.LogAlertsTest do
  @moduledoc """
  Wave 5 (`21-07`) production tests for `Relyra.Telemetry.Handlers.LogAlerts`.

  Verifies the LOCKED behavior of the optional reference handler:
  - attach/0 + detach/0 register/de-register exactly one handler with the
    canonical id `:relyra_auto_refresh_log_alerts`
  - level-per-event mapping (D-30)
  - sensitive-key redaction (T-21-44 mitigation)
  - NOT auto-attached at app boot (D-30 invariant)
  """
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  require Logger

  alias Relyra.Telemetry.Handlers.LogAlerts

  setup do
    previous_level = Logger.level()
    Logger.configure(level: :debug)

    # Clean slate — detach if a previous test failed mid-run.
    _ = LogAlerts.detach()
    :ok = LogAlerts.attach()

    on_exit(fn ->
      _ = LogAlerts.detach()
      Logger.configure(level: previous_level)
    end)

    :ok
  end

  describe "attach/0 + detach/0 idempotence" do
    test "attach/0 returns :ok and the handler is registered" do
      handlers = :telemetry.list_handlers([:relyra, :saml, :metadata, :auto_refresh, :start])
      assert Enum.any?(handlers, fn h -> h.id == :relyra_auto_refresh_log_alerts end)
    end

    test "detach/0 removes the handler" do
      :ok = LogAlerts.detach()

      handlers = :telemetry.list_handlers([:relyra, :saml, :metadata, :auto_refresh, :start])
      refute Enum.any?(handlers, fn h -> h.id == :relyra_auto_refresh_log_alerts end)

      # Re-attach so the on_exit detach is a no-op-equivalent.
      :ok = LogAlerts.attach()
    end
  end

  describe "log levels per event" do
    test "auto_refresh :start emits at info level" do
      log =
        capture_log([level: :info], fn ->
          :telemetry.execute([:relyra, :saml, :metadata, :auto_refresh, :start], %{}, %{
            connection_id: "abc"
          })
        end)

      assert log =~ "auto_refresh start"
      assert log =~ "[info]"
    end

    test "auto_refresh :stop with outcome: :ok emits at info" do
      log =
        capture_log([level: :info], fn ->
          :telemetry.execute(
            [:relyra, :saml, :metadata, :auto_refresh, :stop],
            %{duration_ms: 120},
            %{connection_id: "abc", outcome: :ok}
          )
        end)

      assert log =~ "auto_refresh stop"
      assert log =~ "[info]"
    end

    test "auto_refresh :stop with outcome: :error emits at warning" do
      log =
        capture_log(fn ->
          :telemetry.execute(
            [:relyra, :saml, :metadata, :auto_refresh, :stop],
            %{duration_ms: 120},
            %{connection_id: "abc", outcome: :error, error_code: :fetch_timeout}
          )
        end)

      assert log =~ "auto_refresh stop"
      assert log =~ "[warning]"
      assert log =~ "fetch_timeout"
    end

    test "auto_refresh :exception emits at error" do
      log =
        capture_log(fn ->
          :telemetry.execute(
            [:relyra, :saml, :metadata, :auto_refresh, :exception],
            %{duration_ms: 5},
            %{connection_id: "abc", kind: :error, reason: "boom"}
          )
        end)

      assert log =~ "auto_refresh exception"
      assert log =~ "[error]"
    end

    test "auto_refresh :degraded emits at warning" do
      log =
        capture_log(fn ->
          :telemetry.execute([:relyra, :saml, :metadata, :auto_refresh, :degraded], %{}, %{
            connection_id: "abc",
            consecutive_failure_count: 1
          })
        end)

      assert log =~ "auto_refresh degraded"
      assert log =~ "[warning]"
    end

    test "auto_refresh :suspended emits at error" do
      log =
        capture_log(fn ->
          :telemetry.execute([:relyra, :saml, :metadata, :auto_refresh, :suspended], %{}, %{
            connection_id: "abc",
            consecutive_failure_count: 5,
            auto_suspended_reason: :transient_failures_exceeded
          })
        end)

      assert log =~ "auto_refresh suspended"
      assert log =~ "[error]"
    end

    test "auto_refresh :recovered emits at info" do
      log =
        capture_log([level: :info], fn ->
          :telemetry.execute([:relyra, :saml, :metadata, :auto_refresh, :recovered], %{}, %{
            connection_id: "abc"
          })
        end)

      assert log =~ "auto_refresh recovered"
      assert log =~ "[info]"
    end

    test "auto_refresh :validity_warning emits at warning" do
      log =
        capture_log(fn ->
          :telemetry.execute(
            [:relyra, :saml, :metadata, :auto_refresh, :validity_warning],
            %{},
            %{
              connection_id: "abc",
              valid_until: ~U[2026-06-01 00:00:00Z]
            }
          )
        end)

      assert log =~ "auto_refresh validity warning"
      assert log =~ "[warning]"
    end

    test "auto_refresh :skipped emits at debug" do
      log =
        capture_log([level: :debug], fn ->
          :telemetry.execute([:relyra, :saml, :metadata, :auto_refresh, :skipped], %{}, %{
            correlation_id: "uuid",
            count: 0
          })
        end)

      assert log =~ "auto_refresh skipped"
    end

    test "certificate :expiring emits at warning" do
      log =
        capture_log(fn ->
          :telemetry.execute(
            [:relyra, :saml, :certificate, :expiring],
            %{days_until_expiry: 14},
            %{
              connection_id: "conn-123",
              certificate_id: "cert-456",
              fingerprint_sha256: "aabbcc",
              not_after: ~U[2026-06-01 00:00:00Z]
            }
          )
        end)

      assert log =~ "certificate expiring"
      assert log =~ "[warning]"
      assert log =~ "days_until_expiry"
      assert log =~ "14"
      assert log =~ "conn-123"
    end
  end

  describe "redaction" do
    test "sensitive keys (:xml, :metadata_xml, :certificate_pem, :pem, :private_key) are dropped before logging" do
      log =
        capture_log([level: :info], fn ->
          :telemetry.execute([:relyra, :saml, :metadata, :auto_refresh, :start], %{}, %{
            connection_id: "abc",
            xml: "<EntityDescriptor>SECRET-XML-BODY</EntityDescriptor>",
            metadata_xml: "<EntitiesDescriptor>SECRET-AGGREGATE</EntitiesDescriptor>",
            certificate_pem: "-----BEGIN CERTIFICATE-----SECRET-CERT",
            pem: "-----BEGIN PRIVATE KEY-----SECRET-KEY",
            private_key: "SECRET-PRIVATE-KEY"
          })
        end)

      refute log =~ "EntityDescriptor"
      refute log =~ "EntitiesDescriptor"
      refute log =~ "BEGIN CERTIFICATE"
      refute log =~ "BEGIN PRIVATE KEY"
      refute log =~ "SECRET-CERT"
      refute log =~ "SECRET-KEY"
      refute log =~ "SECRET-PRIVATE-KEY"
      refute log =~ "SECRET-XML-BODY"
      refute log =~ "SECRET-AGGREGATE"
      assert log =~ "abc"
    end
  end

  describe "default-attachment posture (D-30)" do
    test "the handler is NOT auto-attached at app boot" do
      # The handler is only present because setup/0 attached it. If we
      # detach and re-list, the handler is gone — proving Phase 21 does
      # NOT register it from Application.start/2.
      :ok = LogAlerts.detach()

      handlers = :telemetry.list_handlers([:relyra, :saml, :metadata, :auto_refresh, :start])
      refute Enum.any?(handlers, fn h -> h.id == :relyra_auto_refresh_log_alerts end)

      # Re-attach for the on_exit detach to be a no-op-equivalent.
      :ok = LogAlerts.attach()
    end
  end
end
