defmodule Relyra.LiveAdmin.ConnectionsLiveTest do
  @moduledoc """
  Phase 21 W4 — `21-06-live-admin-surface`.

  Verifies the auto-refresh micro-badge surface on the connection list:

    1. `Relyra.LiveAdmin.Query.list_connections/2` returns connection
       summaries enriched with `:auto_refresh_health ∈ {nil, :healthy,
       :degraded, :suspended}` (D-29).
    2. `Relyra.LiveAdmin.Components.ConnectionList.connection_list/1`
       renders the amber "Auto-refresh degraded" / red "Auto-refresh
       suspended" micro-badge with brand-approved copy ONLY when the
       health state is `:degraded` or `:suspended`.
    3. The brand-voice invariant is grep-enforced inside the rendered
       HTML (no "polling" / "cron job" / "blocked" / "retry" /
       "circuit breaker").
  """
  use Relyra.TestSupport.MigrationCase, async: false

  import Phoenix.LiveViewTest

  alias Ecto.Changeset
  alias Relyra.Ecto.{Connection, MetadataSource}
  alias Relyra.LiveAdmin.Components.ConnectionList
  alias Relyra.LiveAdmin.Query
  alias Relyra.LiveAdmin.Scope

  @repo Relyra.TestSupport.EctoTestRepo

  describe "Query.list_connections/2 :auto_refresh_health derivation (D-29)" do
    test "returns auto_refresh_health: nil when no MetadataSource exists" do
      _connection = insert_connection!("01JT71VSVCKX7RZ9KD5W6F5L01", "org_a")

      {:ok, [summary]} = Query.list_connections(@repo, scope())

      assert summary.auto_refresh_health == nil
    end

    test "returns auto_refresh_health: nil when source has auto_refresh_enabled: false (do not render badge)" do
      connection = insert_connection!("01JT71VSVCKX7RZ9KD5W6F5L02", "org_a")

      _source =
        insert_metadata_source!(connection.id,
          auto_refresh_enabled: false,
          # Even with a populated failure count, we MUST NOT badge a
          # source whose auto-refresh is disabled. The operator opted
          # out; the badge would be noise.
          consecutive_failure_count: 3
        )

      {:ok, [summary]} = Query.list_connections(@repo, scope())

      assert summary.auto_refresh_health == nil
    end

    test "returns auto_refresh_health: :degraded when consecutive_failure_count >= 1 and auto_suspended_until is nil" do
      connection = insert_connection!("01JT71VSVCKX7RZ9KD5W6F5L03", "org_a")

      _source =
        insert_metadata_source!(connection.id,
          auto_refresh_enabled: true,
          metadata_trust_fingerprints: ["sha256:aaaa"],
          consecutive_failure_count: 1,
          auto_suspended_until: nil
        )

      {:ok, [summary]} = Query.list_connections(@repo, scope())

      assert summary.auto_refresh_health == :degraded
    end

    test "returns auto_refresh_health: :suspended when auto_suspended_until > now()" do
      connection = insert_connection!("01JT71VSVCKX7RZ9KD5W6F5L04", "org_a")
      future = DateTime.add(DateTime.utc_now(), 3600, :second)

      _source =
        insert_metadata_source!(connection.id,
          auto_refresh_enabled: true,
          metadata_trust_fingerprints: ["sha256:aaaa"],
          consecutive_failure_count: 5,
          auto_suspended_until: future,
          auto_suspended_reason: :transient_failures_exceeded
        )

      {:ok, [summary]} = Query.list_connections(@repo, scope())

      assert summary.auto_refresh_health == :suspended
    end

    test "returns auto_refresh_health: :healthy when source is enabled with no failures and no suspend" do
      connection = insert_connection!("01JT71VSVCKX7RZ9KD5W6F5L05", "org_a")

      _source =
        insert_metadata_source!(connection.id,
          auto_refresh_enabled: true,
          metadata_trust_fingerprints: ["sha256:aaaa"],
          consecutive_failure_count: 0,
          auto_suspended_until: nil
        )

      {:ok, [summary]} = Query.list_connections(@repo, scope())

      assert summary.auto_refresh_health == :healthy
    end

    test "an auto_suspended_until timestamp in the PAST is NOT :suspended (cool-off has elapsed)" do
      connection = insert_connection!("01JT71VSVCKX7RZ9KD5W6F5L06", "org_a")
      past = DateTime.add(DateTime.utc_now(), -3600, :second)

      _source =
        insert_metadata_source!(connection.id,
          auto_refresh_enabled: true,
          metadata_trust_fingerprints: ["sha256:aaaa"],
          consecutive_failure_count: 5,
          auto_suspended_until: past,
          auto_suspended_reason: :transient_failures_exceeded
        )

      {:ok, [summary]} = Query.list_connections(@repo, scope())

      # Past timestamp: cool-off has elapsed. We still have failure
      # counts > 0, so the badge falls through to :degraded.
      assert summary.auto_refresh_health == :degraded
    end
  end

  describe "ConnectionList.connection_list/1 micro-badge rendering (D-29)" do
    test "renders the amber 'Auto-refresh degraded' badge when health is :degraded" do
      html = render_list([connection_summary("c1", :degraded)])

      assert html =~ "Auto-refresh degraded"
      refute html =~ "Auto-refresh suspended"
    end

    test "renders the red 'Auto-refresh suspended' badge when health is :suspended" do
      html = render_list([connection_summary("c1", :suspended)])

      assert html =~ "Auto-refresh suspended"
      refute html =~ "Auto-refresh degraded"
    end

    test "does NOT render any auto-refresh badge for :healthy" do
      html = render_list([connection_summary("c1", :healthy)])

      refute html =~ "Auto-refresh degraded"
      refute html =~ "Auto-refresh suspended"
    end

    test "does NOT render any auto-refresh badge for nil (no source / disabled)" do
      html = render_list([connection_summary("c1", nil)])

      refute html =~ "Auto-refresh degraded"
      refute html =~ "Auto-refresh suspended"
    end

    test "brand-voice invariant: rendered HTML never contains 'polling', 'cron job', 'blocked', 'retry', 'circuit breaker'" do
      banned = ~w(polling cron\ job blocked retry circuit\ breaker)

      for state <- [nil, :healthy, :degraded, :suspended] do
        html = render_list([connection_summary("c_#{state}", state)])

        for word <- banned do
          refute String.match?(html, ~r/#{word}/i),
                 "brand-voice violation for state=#{inspect(state)}: rendered HTML matched /#{word}/i — #{inspect(html)}"
        end
      end
    end
  end

  defp render_list(connections) do
    render_component(&ConnectionList.connection_list/1, %{
      connections: connections,
      base_path: "/admin",
      selected_ids: MapSet.new()
    })
  end

  defp connection_summary(connection_id, auto_refresh_health) do
    %{
      connection_id: connection_id,
      display_name: "Display #{connection_id}",
      organization_id: "org_a",
      status: :enabled,
      provider_preset: nil,
      provider_label: "Custom",
      inserted_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now(),
      auto_refresh_health: auto_refresh_health
    }
  end

  defp scope do
    %Scope{actor: "ops@example.com", actor_label: "Ops", organization_id: "org_a"}
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
