defmodule Relyra.LiveAdmin.ConnectionMetadataLiveTest do
  @moduledoc """
  Phase 21 W4 — `21-06-live-admin-surface`.

  Verifies the auto-refresh health card + "Resume now" button surface on
  `Relyra.LiveAdmin.ConnectionMetadataLive`:

    1. Render the "Auto-refresh health" card with brand-approved labels.
    2. Render the per-state banners ("Auto-refresh suspended" / "Auto-refresh
       degraded") with brand-approved copy.
    3. Render the "Resume now" button ONLY when `state == :suspended`,
       and disable it while `@resume_status == :loading`.
    4. `handle_event("resume_auto_refresh", ...)` delegates to
       `Relyra.Ecto.MetadataApply.resume_auto_refresh/3` (single-transaction
       seam — D-28). The audit row + suspend-clear co-commit; the LiveView
       MUST NOT carry a parallel `repo.update` helper (B3 invariant).
    5. The `:auto_refresh_resume` `handle_async` chain mirrors the
       disabled-while-loading UX of `:metadata_refresh`.
    6. `legacy_unsigned_metadata_policy` renders inside the existing
       `Relyra.LiveAdmin.Components.RiskPanel` when set (D-19).
    7. Brand-voice invariant: rendered HTML never contains "polling",
       "cron job", "blocked", "retry", or "circuit breaker".
  """
  use Relyra.TestSupport.MigrationCase, async: false

  import Phoenix.LiveViewTest

  alias Ecto.Changeset
  alias Phoenix.LiveView.Socket
  alias Relyra.Ecto.{AuditEvent, Connection, MetadataSource}
  alias Relyra.LiveAdmin.ConnectionMetadataLive
  alias Relyra.LiveAdmin.Scope

  @repo Relyra.TestSupport.EctoTestRepo

  describe "Auto-refresh health card rendering (D-29)" do
    test "renders the 'Auto-refresh health' heading and the four core labels" do
      assigns = base_assigns(health_summary(state: :healthy))
      html = render_card(assigns)

      assert html =~ "Auto-refresh health"
      assert html =~ "Schedule"
      assert html =~ "Last success"
      assert html =~ "Consecutive failures"
      assert html =~ "Last error"
    end

    test "renders the 'Auto-refresh suspended' banner when state == :suspended" do
      future = DateTime.add(DateTime.utc_now(), 3600, :second)

      assigns =
        base_assigns(
          health_summary(
            state: :suspended,
            auto_suspended_until: future,
            auto_suspended_reason: :transient_failures_exceeded,
            consecutive_failure_count: 5
          )
        )

      html = render_card(assigns)

      assert html =~ "Auto-refresh suspended"
      refute html =~ "Auto-refresh degraded"
    end

    test "renders the 'Auto-refresh degraded' banner when state == :degraded" do
      assigns =
        base_assigns(health_summary(state: :degraded, consecutive_failure_count: 2))

      html = render_card(assigns)

      assert html =~ "Auto-refresh degraded"
      assert html =~ "2 consecutive failures"
      refute html =~ "Auto-refresh suspended"
    end

    test "Resume now button only renders when state == :suspended" do
      degraded_html = render_card(base_assigns(health_summary(state: :degraded)))
      refute degraded_html =~ "Resume now"
      refute degraded_html =~ "Resuming..."

      future = DateTime.add(DateTime.utc_now(), 3600, :second)

      suspended_html =
        render_card(
          base_assigns(
            health_summary(
              state: :suspended,
              auto_suspended_until: future,
              auto_suspended_reason: :transient_failures_exceeded
            )
          )
        )

      assert suspended_html =~ "Resume now"
      assert suspended_html =~ ~s(phx-click="resume_auto_refresh")
    end

    test "Resume now button is disabled while @resume_status == :loading" do
      future = DateTime.add(DateTime.utc_now(), 3600, :second)

      assigns =
        base_assigns(
          health_summary(
            state: :suspended,
            auto_suspended_until: future,
            auto_suspended_reason: :transient_failures_exceeded
          ),
          resume_status: :loading
        )

      html = render_card(assigns)

      # The button has the `disabled` attr when loading and shows
      # "Resuming..." instead of "Resume now".
      assert html =~ ~r/disabled/
      assert html =~ "Resuming..."
    end

    test "legacy_unsigned_metadata_policy renders inside a RiskPanel when set (D-19)" do
      future_date = Date.add(Date.utc_today(), 30)

      assigns =
        base_assigns(
          health_summary(
            state: :healthy,
            legacy_unsigned_metadata_policy: %{
              "allow_until" => Date.to_iso8601(future_date),
              "reason" => "regional partner without signing infrastructure"
            }
          )
        )

      html = render_card(assigns)

      assert html =~ "Unsigned metadata escape hatch active"
      assert html =~ "regional partner"
    end

    test "card is hidden when there is no auto_refresh_health summary" do
      assigns = base_assigns(nil)
      html = render_card(assigns)

      refute html =~ "Auto-refresh health"
      refute html =~ "Schedule"
    end
  end

  describe "Brand-voice invariant" do
    test "rendered HTML never contains 'polling', 'cron job', 'blocked', 'retry', or 'circuit breaker'" do
      banned = ~w(polling cron\ job blocked retry circuit\ breaker)

      future = DateTime.add(DateTime.utc_now(), 3600, :second)

      health_states = [
        nil,
        health_summary(state: :healthy),
        health_summary(state: :degraded, consecutive_failure_count: 2),
        health_summary(
          state: :suspended,
          auto_suspended_until: future,
          auto_suspended_reason: :transient_failures_exceeded
        )
      ]

      for health <- health_states do
        html = render_card(base_assigns(health))

        for word <- banned do
          refute String.match?(html, ~r/#{word}/i),
                 "brand-voice violation for health=#{inspect(health)}: rendered HTML matched /#{word}/i"
        end
      end
    end
  end

  describe "handle_event(\"resume_auto_refresh\", ...)" do
    test "delegates to MetadataApply.resume_auto_refresh/3 — single-transaction co-commit (D-28)" do
      connection = insert_connection!("01JT71VSVCKX7RZ9KD5W6F6A01", "org_b")
      future = DateTime.add(DateTime.utc_now(), 3600, :second)

      source =
        insert_metadata_source!(connection.id,
          auto_refresh_enabled: true,
          metadata_trust_fingerprints: ["sha256:aaaa"],
          consecutive_failure_count: 5,
          auto_suspended_until: future,
          auto_suspended_reason: :transient_failures_exceeded
        )

      socket = mounted_socket(connection_id: connection.connection_id, source: source)

      assert {:noreply, new_socket} =
               ConnectionMetadataLive.handle_event("resume_auto_refresh", %{}, socket)

      # The suspend-clear health write co-committed.
      reloaded = @repo.get!(MetadataSource, source.id)
      assert is_nil(reloaded.auto_suspended_until)
      assert is_nil(reloaded.auto_suspended_reason)

      # Exactly one audit row landed via the single audit-writer seam,
      # carrying the LOCKED operator-intent cause string.
      [event] = @repo.all(AuditEvent)
      assert event.cause == "live_admin_auto_refresh_resume"
      assert event.actor == "ops@example.com"
      assert event.domain == :metadata
      assert event.action == :refreshed
      assert event.connection_record_id == connection.id

      # The async probe was dispatched — resume_status flipped to :loading
      # and the LiveView did NOT block.
      assert new_socket.assigns.resume_status == :loading
    end

    test "is a no-op with an info flash when the source is not suspended" do
      connection = insert_connection!("01JT71VSVCKX7RZ9KD5W6F6A02", "org_b")

      source =
        insert_metadata_source!(connection.id,
          auto_refresh_enabled: true,
          metadata_trust_fingerprints: ["sha256:aaaa"],
          consecutive_failure_count: 0,
          auto_suspended_until: nil
        )

      socket = mounted_socket(connection_id: connection.connection_id, source: source)
      audit_count_before = @repo.aggregate(AuditEvent, :count, :id)

      assert {:noreply, new_socket} =
               ConnectionMetadataLive.handle_event("resume_auto_refresh", %{}, socket)

      assert %{"info" => info} = new_socket.assigns.flash
      assert info =~ "not currently suspended"

      # No audit row, no state change.
      assert @repo.aggregate(AuditEvent, :count, :id) == audit_count_before
      assert new_socket.assigns.resume_status == :idle
    end

    test "is a no-op with an error flash when no metadata_source is registered" do
      connection = insert_connection!("01JT71VSVCKX7RZ9KD5W6F6A03", "org_b")

      socket = mounted_socket(connection_id: connection.connection_id, source: nil)

      assert {:noreply, new_socket} =
               ConnectionMetadataLive.handle_event("resume_auto_refresh", %{}, socket)

      assert %{"error" => error} = new_socket.assigns.flash
      assert error =~ "No metadata source"
    end
  end

  describe "handle_async(:auto_refresh_resume, ...)" do
    test "{:ok, {:ok, _}} flips resume_status back to :idle and shows a success flash" do
      connection = insert_connection!("01JT71VSVCKX7RZ9KD5W6F6B01", "org_b")
      socket = mounted_socket(connection_id: connection.connection_id, source: nil)
      socket = Phoenix.Component.assign(socket, :resume_status, :loading)

      assert {:noreply, new_socket} =
               ConnectionMetadataLive.handle_async(
                 :auto_refresh_resume,
                 {:ok, {:ok, %{}}},
                 socket
               )

      assert new_socket.assigns.resume_status == :idle
      assert %{"info" => info} = new_socket.assigns.flash
      assert info =~ "Auto-refresh resumed"
    end

    test "{:ok, {:error, _}} surfaces the error.message into the flash" do
      connection = insert_connection!("01JT71VSVCKX7RZ9KD5W6F6B02", "org_b")
      socket = mounted_socket(connection_id: connection.connection_id, source: nil)
      socket = Phoenix.Component.assign(socket, :resume_status, :loading)

      error = Relyra.Error.new(:probe_failed, "Probe failed for testing", %{})

      assert {:noreply, new_socket} =
               ConnectionMetadataLive.handle_async(
                 :auto_refresh_resume,
                 {:ok, {:error, error}},
                 socket
               )

      assert new_socket.assigns.resume_status == :idle
      assert %{"error" => msg} = new_socket.assigns.flash
      assert msg == "Probe failed for testing"
    end

    test "{:exit, _} flips resume_status back to :idle and surfaces a failure flash" do
      connection = insert_connection!("01JT71VSVCKX7RZ9KD5W6F6B03", "org_b")
      socket = mounted_socket(connection_id: connection.connection_id, source: nil)
      socket = Phoenix.Component.assign(socket, :resume_status, :loading)

      assert {:noreply, new_socket} =
               ConnectionMetadataLive.handle_async(
                 :auto_refresh_resume,
                 {:exit, :killed},
                 socket
               )

      assert new_socket.assigns.resume_status == :idle
      assert %{"error" => msg} = new_socket.assigns.flash
      assert msg =~ "Resume probe failed to complete"
    end
  end

  describe "B3 invariant: no parallel-write resume helper" do
    test "no `clear_suspend_for_resume` helper exists in the LiveView (D-28)" do
      source = File.read!("lib/relyra/live_admin/connection_metadata_live.ex")
      refute source =~ "clear_suspend_for_resume"
    end
  end

  # ===== Helpers =====

  defp render_card(assigns) do
    render_component(ConnectionMetadataLive, assigns)
  end

  # The LV's `reload_detail/1` calls `stream(:metadata_revisions, items, reset:
  # true)`, which routes through `Phoenix.LiveView`'s `update_stream/3`. That
  # path expects the `streams` assign to be a map with a `:__changed__` MapSet
  # plus the configured stream entry. Build a faithful approximation here.
  defp streams_assign do
    stream = %Phoenix.LiveView.LiveStream{
      name: :metadata_revisions,
      dom_id: fn item -> "metadata_revisions-#{item.id}" end,
      ref: "test",
      inserts: [],
      deletes: [],
      reset?: false
    }

    %{
      __ref__: 1,
      __changed__: MapSet.new(),
      __configured__: %{metadata_revisions: [dom_id: stream.dom_id]},
      metadata_revisions: stream
    }
  end

  defp base_assigns(auto_refresh_health, opts \\ []) do
    detail = build_detail(auto_refresh_health)

    %{
      __changed__: %{},
      flash: %{},
      page_title: "Metadata Management",
      connection_id: "test_conn",
      mode: "xml",
      detail: detail,
      refresh_status: Keyword.get(opts, :refresh_status, :idle),
      resume_status: Keyword.get(opts, :resume_status, :idle),
      streams: streams_assign(),
      relyra_admin_repo: @repo,
      relyra_admin_req: nil,
      relyra_admin_base_path: "/admin",
      admin_scope: %Scope{
        actor: "ops@example.com",
        actor_label: "Ops",
        organization_id: "org_b"
      }
    }
  end

  defp build_detail(nil) do
    %{
      connection: %{active_metadata_revision_id: nil},
      metadata_source: nil,
      auto_refresh_health: nil
    }
  end

  defp build_detail(auto_refresh_health) do
    %{
      connection: %{active_metadata_revision_id: nil},
      metadata_source: nil,
      auto_refresh_health: auto_refresh_health
    }
  end

  defp health_summary(opts) do
    %{
      enabled?: Keyword.get(opts, :enabled?, true),
      cadence: Keyword.get(opts, :cadence, :daily),
      next_refresh_at: Keyword.get(opts, :next_refresh_at),
      last_success_at: Keyword.get(opts, :last_success_at),
      consecutive_failure_count: Keyword.get(opts, :consecutive_failure_count, 0),
      last_failure_error_code: Keyword.get(opts, :last_failure_error_code),
      last_validity_warning_for: Keyword.get(opts, :last_validity_warning_for),
      auto_suspended_until: Keyword.get(opts, :auto_suspended_until),
      auto_suspended_reason: Keyword.get(opts, :auto_suspended_reason),
      legacy_unsigned_metadata_policy: Keyword.get(opts, :legacy_unsigned_metadata_policy),
      metadata_trust_fingerprints: Keyword.get(opts, :metadata_trust_fingerprints, []),
      state: Keyword.fetch!(opts, :state)
    }
  end

  defp mounted_socket(opts) do
    connection_id = Keyword.fetch!(opts, :connection_id)
    source = Keyword.get(opts, :source)

    detail = %{
      connection: %{active_metadata_revision_id: nil},
      metadata_source: source,
      auto_refresh_health: nil
    }

    %Socket{
      assigns: %{
        __changed__: %{},
        flash: %{},
        page_title: "Metadata Management",
        connection_id: connection_id,
        mode: "url",
        detail: detail,
        refresh_status: :idle,
        resume_status: :idle,
        streams: streams_assign(),
        relyra_admin_repo: @repo,
        relyra_admin_req: nil,
        relyra_admin_base_path: "/admin",
        admin_scope: %Scope{
          actor: "ops@example.com",
          actor_label: "Ops",
          organization_id: "org_b"
        }
      }
    }
  end

  defp insert_connection!(connection_id, organization_id) do
    now = DateTime.utc_now()

    %Connection{
      id: Ecto.UUID.generate(),
      connection_id: connection_id,
      display_name: "Display #{connection_id}",
      organization_id: organization_id,
      status: :enabled,
      sp_entity_id: "https://sp.example.com/metadata",
      acs_url: "https://sp.example.com/saml/acs",
      idp_entity_id: "https://idp.example.com/entity",
      idp_sso_url: "https://idp.example.com/sso",
      inserted_at: now,
      updated_at: now
    }
    |> @repo.insert!()
  end

  defp insert_metadata_source!(connection_record_id, overrides) do
    base_attrs = %{
      connection_record_id: connection_record_id,
      url: "https://idp.example.com/metadata",
      kind: :remote_url,
      registered_by: "operator@example.com",
      registered_reason: "phase 21 plan 06 test fixture",
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
      |> Changeset.change(Map.new(overrides))
      |> @repo.update!()
    end
  end
end
