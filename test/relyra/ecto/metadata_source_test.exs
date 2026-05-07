defmodule Relyra.Ecto.MetadataSourceTest do
  @moduledoc """
  Coverage for the new Phase-21 changeset paths on `Relyra.Ecto.MetadataSource`:

  - `auto_refresh_changeset/2` — operator-facing, enforces D-09 great-error
  - `health_state_changeset/2` — MetadataApply-internal seam (D-28)

  See also `Relyra.Ecto.MetadataSourceSchemaTest` for the existing
  `changeset/2` registration-path coverage; this file exists to keep the
  Phase-21-specific changeset behaviors grouped near the new code.
  """
  use ExUnit.Case, async: true

  alias Relyra.Ecto.MetadataSource

  describe "auto_refresh_changeset/2" do
    test "accepts cadence preset and trust fingerprints" do
      attrs = %{
        auto_refresh_enabled: true,
        refresh_cadence: :hourly,
        metadata_trust_fingerprints: [
          "abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789"
        ]
      }

      changeset = MetadataSource.auto_refresh_changeset(%MetadataSource{}, attrs)

      assert changeset.valid?
      assert changeset.changes.auto_refresh_enabled == true
      assert changeset.changes.refresh_cadence == :hourly

      assert changeset.changes.metadata_trust_fingerprints == [
               "abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789"
             ]
    end

    test "rejects enabling without pinned fingerprints (D-09 great-error)" do
      attrs = %{
        auto_refresh_enabled: true,
        refresh_cadence: :daily,
        metadata_trust_fingerprints: []
      }

      changeset = MetadataSource.auto_refresh_changeset(%MetadataSource{}, attrs)

      refute changeset.valid?

      errors = errors_on(changeset)

      assert errors[:metadata_trust_fingerprints] != nil
      [message] = errors[:metadata_trust_fingerprints]

      assert message ==
               "is required when auto_refresh_enabled is true; pin at least one SHA-256 fingerprint via the admin LiveView (or `mix relyra.metadata.pin`) before enabling auto-refresh"
    end

    test "rejects unknown cadence preset" do
      attrs = %{
        auto_refresh_enabled: false,
        refresh_cadence: :every_5min
      }

      changeset = MetadataSource.auto_refresh_changeset(%MetadataSource{}, attrs)

      refute changeset.valid?
      errors = errors_on(changeset)
      assert errors[:refresh_cadence] != nil
      assert Enum.any?(errors[:refresh_cadence], &String.contains?(&1, "is invalid"))
    end

    test "allows enabling=false with empty fingerprints" do
      attrs = %{
        auto_refresh_enabled: false,
        refresh_cadence: :daily,
        metadata_trust_fingerprints: []
      }

      changeset = MetadataSource.auto_refresh_changeset(%MetadataSource{}, attrs)

      assert changeset.valid?
    end
  end

  describe "health_state_changeset/2" do
    test "casts the documented health fields" do
      now = DateTime.utc_now()

      attrs = %{
        consecutive_failure_count: 3,
        first_failure_at: now,
        last_success_at: now,
        last_failure_error_code: "fetch_timeout",
        last_validity_warning_for: now,
        auto_suspended_until: now,
        auto_suspended_reason: :transient_failures_exceeded,
        next_refresh_at: now,
        last_known_metadata_signing_certs: [
          "ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00"
        ]
      }

      changeset = MetadataSource.health_state_changeset(%MetadataSource{}, attrs)

      assert changeset.valid?
      assert changeset.changes.consecutive_failure_count == 3
      assert changeset.changes.first_failure_at == now
      assert changeset.changes.last_success_at == now
      assert changeset.changes.last_failure_error_code == "fetch_timeout"
      assert changeset.changes.last_validity_warning_for == now
      assert changeset.changes.auto_suspended_until == now
      assert changeset.changes.auto_suspended_reason == :transient_failures_exceeded
      assert changeset.changes.next_refresh_at == now

      assert changeset.changes.last_known_metadata_signing_certs == [
               "ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00ff00"
             ]
    end
  end

  describe "changeset/2 (existing path — D-32 invariant)" do
    test "existing changeset/2 still works unchanged" do
      attrs = %{
        connection_record_id: "00000000-0000-0000-0000-000000000001",
        url: "https://idp.example.com/metadata",
        kind: :remote_url,
        registered_by: "operator@example.com",
        registered_reason: "Initial onboarding"
      }

      changeset = MetadataSource.changeset(%MetadataSource{}, attrs)

      assert changeset.valid?
      assert changeset.changes.url == "https://idp.example.com/metadata"
      assert changeset.changes.kind == :remote_url
    end
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _whole, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
