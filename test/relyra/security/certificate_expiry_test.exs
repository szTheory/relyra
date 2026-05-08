defmodule Relyra.Security.CertificateExpiryTest do
  use Relyra.TestSupport.MigrationCase, async: false

  alias Relyra.Ecto.Certificate
  alias Relyra.Ecto.Connection
  alias Relyra.Security.CertificateExpiry
  alias Relyra.TestSupport.EctoTestRepo, as: Repo

  import ExUnit.CaptureLog

  setup do
    conn_id = Ecto.UUID.generate()
    disabled_conn_id = Ecto.UUID.generate()
    now = DateTime.utc_now()
    thirty_one_days_from_now = DateTime.add(now, 31, :day)
    twenty_nine_days_from_now = DateTime.add(now, 29, :day)

    conn =
      %Connection{
        id: conn_id,
        connection_id: "conn-123",
        status: :enabled,
        inserted_at: now,
        updated_at: now
      }
      |> Repo.insert!()

    disabled_conn =
      %Connection{
        id: disabled_conn_id,
        connection_id: "conn-disabled",
        status: :disabled,
        inserted_at: now,
        updated_at: now
      }
      |> Repo.insert!()

    expiring_cert =
      %Certificate{
        id: Ecto.UUID.generate(),
        connection_record_id: conn.id,
        fingerprint_sha256: "expiring-fingerprint",
        not_after: twenty_nine_days_from_now,
        lifecycle_state: :active,
        role: :signing,
        pem: "pem",
        source: "manual",
        inserted_at: now,
        updated_at: now,
        activated_at: now
      }
      |> Repo.insert!()

    non_expiring_cert =
      %Certificate{
        id: Ecto.UUID.generate(),
        connection_record_id: conn.id,
        fingerprint_sha256: "non-expiring-fingerprint",
        not_after: thirty_one_days_from_now,
        lifecycle_state: :active,
        role: :signing,
        pem: "pem",
        source: "manual",
        inserted_at: now,
        updated_at: now,
        activated_at: now
      }
      |> Repo.insert!()

    disabled_cert =
      %Certificate{
        id: Ecto.UUID.generate(),
        connection_record_id: disabled_conn.id,
        fingerprint_sha256: "disabled-fingerprint",
        not_after: twenty_nine_days_from_now,
        lifecycle_state: :active,
        role: :signing,
        pem: "pem",
        source: "manual",
        inserted_at: now,
        updated_at: now,
        activated_at: now
      }
      |> Repo.insert!()

    retired_cert =
      %Certificate{
        id: Ecto.UUID.generate(),
        connection_record_id: conn.id,
        fingerprint_sha256: "retired-fingerprint",
        not_after: twenty_nine_days_from_now,
        lifecycle_state: :retired,
        role: :signing,
        pem: "pem",
        source: "manual",
        inserted_at: now,
        updated_at: now,
        activated_at: now,
        retired_at: now
      }
      |> Repo.insert!()

    %{
      conn: conn,
      disabled_conn: disabled_conn,
      expiring_cert: expiring_cert,
      non_expiring_cert: non_expiring_cert,
      disabled_cert: disabled_cert,
      retired_cert: retired_cert
    }
  end

  describe "check_all/2" do
    test "correctly queries active/next certificates approaching threshold on enabled connections",
         %{expiring_cert: expiring_cert} do
      Relyra.Telemetry.Handlers.LogAlerts.attach()

      log =
        capture_log(fn ->
          assert {:ok, results} = CertificateExpiry.check_all(Repo)
          assert Map.has_key?(results, expiring_cert.id)
          assert Map.get(results, expiring_cert.id) == :ok
        end)

      assert log =~ "certificate expiring"
      assert log =~ "conn-123"
      assert log =~ "days_until_expiry"

      Relyra.Telemetry.Handlers.LogAlerts.detach()
    end

    test "traversal skips certificates on disabled connections, or retired certificates", %{
      disabled_cert: disabled_cert,
      retired_cert: retired_cert,
      non_expiring_cert: non_expiring_cert
    } do
      assert {:ok, results} = CertificateExpiry.check_all(Repo)
      refute Map.has_key?(results, disabled_cert.id)
      refute Map.has_key?(results, retired_cert.id)
      refute Map.has_key?(results, non_expiring_cert.id)
    end
  end
end
