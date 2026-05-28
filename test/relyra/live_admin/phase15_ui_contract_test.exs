defmodule Relyra.LiveAdmin.Phase15UiContractTest do
  use Relyra.TestSupport.MigrationCase, async: false

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  alias Relyra.Ecto.{AuditWriter, Certificate, Connection}
  alias Relyra.TestSupport.LiveAdminEndpointSupport

  @endpoint Relyra.TestSupport.LiveAdminEndpoint
  @repo Relyra.TestSupport.EctoTestRepo
  @legacy_sha1_label "Legacy SHA-1 support enabled (compatibility override)"
  @okta_name_id_format "urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified"
  @entra_name_id_format "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent"
  @empty_trace_copy "No login attempts recorded yet — traces appear after the first SAML response is consumed."
  @trace_step_names [
    "response.decode",
    "response.validate",
    "signature.verify",
    "replay.check",
    "user.map",
    "session.establish"
  ]

  setup_all do
    LiveAdminEndpointSupport.ensure_started!()
    :ok
  end

  setup do
    LiveAdminEndpointSupport.ensure_started!()
    :ok
  end

  test "admin shell keeps the list and detail regions visible on connection detail routes" do
    connection =
      insert_connection!("conn_shell", "org_phase15", status: :enabled, cert_ready?: true)

    {:ok, view, _html} =
      live(authed_conn("org_phase15"), "/admin/connections/#{connection.connection_id}")

    assert has_element?(view, ~s([data-testid="admin-shell"]))
    assert has_element?(view, ~s([data-testid="admin-shell-grid"]))
    assert has_element?(view, ~s([data-testid="connection-list-region"]))
    assert has_element?(view, ~s([data-testid="admin-main-region"]))
    assert has_element?(view, ~s([data-testid="connection-detail-region"]))
    assert has_element?(view, ~s([data-testid="connection-list-item-conn_shell"]))
    assert has_element?(view, ~s([data-testid="connection-status-badge"][data-status="enabled"]))
  end

  test "new connection editor keeps the shell visible while preset choices patch the URL and prefill defaults" do
    _seed = insert_connection!("conn_seed", "org_phase15", status: :enabled)

    {:ok, view, _html} = live(authed_conn("org_phase15"), "/admin/connections/new")

    assert has_element?(view, ~s([data-testid="connection-list-region"]))
    assert has_element?(view, ~s([data-testid="connection-editor-region"]))
    assert has_element?(view, ~s([data-testid="preset-picker"]))
    refute has_element?(view, ~s([data-testid="connection-selection-empty-state"]))

    view
    |> element(~s([data-testid="preset-okta"]))
    |> render_click()

    assert_patch(view, "/admin/connections/new?preset=okta")
    assert has_element?(view, ~s([data-testid="connection-provider-preset-input"][value="okta"]))

    assert has_element?(
             view,
             ~s([data-testid="connection-name-id-format-input"][value="#{@okta_name_id_format}"])
           )

    view
    |> element(~s([data-testid="preset-entra"]))
    |> render_click()

    assert_patch(view, "/admin/connections/new?preset=entra")
    assert has_element?(view, ~s([data-testid="connection-provider-preset-input"][value="entra"]))

    assert has_element?(
             view,
             ~s([data-testid="connection-name-id-format-input"][value="#{@entra_name_id_format}"])
           )
  end

  test "legacy sha1 risk warnings remain visible across detail, edit, and enable flows" do
    connection =
      insert_connection!("conn_risk_ci", "org_phase15",
        status: :draft,
        legacy_sha1?: true,
        cert_ready?: true
      )

    {:ok, view, _html} =
      live(authed_conn("org_phase15"), "/admin/connections/#{connection.connection_id}")

    assert has_element?(view, ~s([data-testid="connection-status-badge"][data-status="draft"]))

    assert has_element?(
             view,
             ~s([data-testid="risk-panel"][data-risk-label="#{@legacy_sha1_label}"])
           )

    detail_html = render(view)

    assert appears_before?(
             detail_html,
             ~s(data-testid="risk-panel"),
             ~s(Manage Metadata)
           )

    render_click(element(view, ~s([data-testid="enable-connection-button"])))

    assert has_element?(view, ~s([data-testid="connection-status-badge"][data-status="enabled"]))

    assert has_element?(
             view,
             ~s([data-testid="risk-panel"][data-risk-label="#{@legacy_sha1_label}"])
           )

    {:ok, edit_view, _html} =
      live(authed_conn("org_phase15"), "/admin/connections/#{connection.connection_id}/edit")

    assert has_element?(edit_view, ~s([data-testid="connection-editor-region"]))
    assert has_element?(edit_view, ~s([data-testid="connection-editor-form-region"]))

    assert has_element?(
             edit_view,
             ~s([data-testid="risk-panel"][data-risk-label="#{@legacy_sha1_label}"])
           )

    edit_html = render(edit_view)

    assert appears_before?(
             edit_html,
             ~s(data-testid="risk-panel"),
             ~s(data-testid="connection-form")
           )
  end

  test "login trace page lists seeded login rows with six expandable step rows" do
    connection =
      insert_connection!("conn_trace", "org_phase15", status: :enabled, cert_ready?: true)

    {:ok, event} =
      AuditWriter.append_event(@repo, %{
        connection_record_id: connection.id,
        domain: :login,
        action: :succeeded,
        actor: "system:login_trace",
        cause: "sp_initiated",
        correlation_id: "corr-phase15-trace",
        before_summary: %{},
        after_summary: %{
          "steps" => login_trace_steps(),
          "overall_outcome" => "ok"
        },
        diff_summary: %{"kind" => "login_trace"}
      })

    {:ok, view, html} =
      live(authed_conn("org_phase15"), "/admin/connections/#{connection.connection_id}/trace")

    assert has_element?(view, ~s([data-testid="login-trace-page"]))
    assert has_element?(view, ~s([data-testid="login-trace-row-#{event.id}"]))

    for step_name <- @trace_step_names do
      assert has_element?(view, ~s([data-testid="login-trace-step-#{step_name}"]))
    end

    refute html =~ "corr-phase15-trace"
  end

  test "login trace page shows empty-state copy when no login rows exist" do
    connection =
      insert_connection!("conn_trace_empty", "org_phase15", status: :enabled, cert_ready?: true)

    {:ok, view, html} =
      live(authed_conn("org_phase15"), "/admin/connections/#{connection.connection_id}/trace")

    assert has_element?(view, ~s([data-testid="login-trace-page"]))
    assert html =~ @empty_trace_copy
  end

  test "connection detail links to login trace page" do
    connection =
      insert_connection!("conn_trace_link", "org_phase15", status: :enabled, cert_ready?: true)

    {:ok, view, _html} =
      live(authed_conn("org_phase15"), "/admin/connections/#{connection.connection_id}")

    assert has_element?(view, ~s([data-testid="view-login-trace-link"]))

    assert has_element?(
             view,
             ~s([data-testid="view-login-trace-link"][href="/admin/connections/#{connection.connection_id}/trace"])
           )
  end

  defp login_trace_steps do
    Map.new(@trace_step_names, fn step_name ->
      {step_name, %{"outcome" => "ok", "duration_ms" => 5}}
    end)
  end

  defp authed_conn(organization_id) do
    build_conn()
    |> init_test_session(%{
      "admin_actor" => "ops@example.com",
      "admin_actor_label" => "Ops User",
      "admin_organization_id" => organization_id
    })
  end

  defp insert_connection!(connection_id, organization_id, opts) do
    now = DateTime.utc_now()
    status = Keyword.get(opts, :status, :draft)
    legacy_sha1? = Keyword.get(opts, :legacy_sha1?, false)
    cert_ready? = Keyword.get(opts, :cert_ready?, false)

    algorithm_policy =
      if legacy_sha1? do
        %{
          "legacy_sha1" => %{
            "allow_until" => "2030-01-01",
            "reason" => "phase15-ci-contract"
          }
        }
      else
        %{}
      end

    connection =
      @repo.insert!(%Connection{
        id: Ecto.UUID.generate(),
        connection_id: connection_id,
        organization_id: organization_id,
        display_name: "Display #{connection_id}",
        status: status,
        provider_preset: :okta,
        sp_entity_id: "https://sp.example.com/#{connection_id}/metadata",
        acs_url: "https://sp.example.com/#{connection_id}/acs",
        idp_entity_id: "https://idp.example.com/#{connection_id}/metadata",
        idp_sso_url: "https://idp.example.com/#{connection_id}/sso",
        runtime_policy: %{
          allow_idp_initiated?: false,
          require_signed_assertions?: true,
          require_signed_response?: true,
          name_id_format: @okta_name_id_format,
          algorithm_policy: algorithm_policy
        },
        inserted_at: now,
        updated_at: now
      })

    if cert_ready? do
      @repo.insert!(%Certificate{
        id: Ecto.UUID.generate(),
        connection_record_id: connection.id,
        fingerprint_sha256: "sha256:#{connection_id}",
        pem: "-----BEGIN CERTIFICATE-----\nTEST\n-----END CERTIFICATE-----",
        source: "phase15-ui-contract",
        role: :signing,
        lifecycle_state: :active,
        party: :idp,
        use: :signing,
        activated_at: now
      })
    end

    connection
  end

  defp appears_before?(html, earlier, later) do
    {earlier_index, _length} = :binary.match(html, earlier)
    {later_index, _length} = :binary.match(html, later)
    earlier_index < later_index
  end
end
