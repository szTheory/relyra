defmodule LedgerLoopWeb.SetupLiveTest do
  use LedgerLoopWeb.ConnCase
  import Phoenix.LiveViewTest

  @endpoint LedgerLoopWeb.Endpoint

  setup do
    LedgerLoop.Demo.Reset.reset!()
    :ok
  end

  test "Setup checklist renders and user can navigate between steps via phx-click", %{conn: conn} do
    {:ok, view, html} = live(conn, "/setup/sso")

    assert html =~ "SP Settings"
    assert html =~ "Entity ID (Audience URI)"
    assert html =~ "ACS URL (Assertion Consumer Service)"

    # Gap #4: SP Settings exposes Entity ID + ACS URL as readonly inputs carrying
    # the real host endpoints (not placeholder text), so they can be copied verbatim.
    assert has_element?(view, ~s|input[readonly][value$="/auth/saml/metadata"]|)
    assert has_element?(view, ~s|input[readonly][value$="/auth/saml/acs"]|)

    # Click next to IdP Metadata
    view |> element("button", "Next") |> render_click()
    html = render(view)
    assert html =~ "IdP Metadata"
    assert html =~ "Save Metadata"

    # Gap #5: before save, the metadata intake form is present.
    assert has_element?(view, ~s|form[phx-submit="save_metadata"]|)
    assert has_element?(view, ~s|textarea[name="metadata"]|)

    # Submit metadata form
    view
    |> form("form[phx-submit=\"save_metadata\"]", %{metadata: "<EntityDescriptor />"})
    |> render_submit()

    html = render(view)
    assert html =~ "Metadata saved successfully!"

    # Gap #5: after save, state unlocks — the form/textarea is gone.
    refute has_element?(view, ~s|form[phx-submit="save_metadata"]|)
    refute has_element?(view, ~s|textarea[name="metadata"]|)

    # Click next to Mapping Preview
    view |> element("button", "Next") |> render_click()
    html = render(view)
    assert html =~ "Mapping Preview"

    # Gap #6: every canonical SAML attribute -> LedgerLoop field row renders inside
    # the real <table> body (not loose text). Source of truth: SetupLive mount assigns.
    for {saml, local} <- [
          {"urn:oid:0.9.2342.19200300.100.1.3", "email"},
          {"urn:oid:2.5.4.42", "first_name"},
          {"urn:oid:2.5.4.4", "last_name"}
        ] do
      assert has_element?(view, "table tbody td", saml)
      assert has_element?(view, "table tbody td", local)
    end

    # Click next to Test &amp; Enable
    view |> element("button", "Next") |> render_click()
    html = render(view)
    assert html =~ "Test &amp; Enable"

    # Gap #7: Test Login redirect carries the enabled connection context.
    conn_id =
      LedgerLoop.Demo.Fixtures.relyra_connections() |> List.first() |> Map.get(:connection_id)

    view |> element("button", "Start Test Login") |> render_click()
    assert_redirect(view, "/auth/saml/login?connection_id=" <> conn_id)
  end

  test "Setup checklist supports nonlinear navigation via the sidebar", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/setup/sso")

    # Gap #3: jump directly to the last step (skipping the middle two).
    html = view |> element(~s|a[phx-value-step="test_enable"]|) |> render_click()
    assert html =~ "Perform a test login to verify the trust path"

    # Jump backward to the second step.
    html = view |> element(~s|a[phx-value-step="idp_metadata"]|) |> render_click()
    assert html =~ "Provide XML or URLs from your IdP"

    # Jump backward to the first step.
    html = view |> element(~s|a[phx-value-step="sp_settings"]|) |> render_click()
    assert html =~ "Copy Relyra configuration to your IdP"
  end

  test "The receipt step securely renders redacted verification fields", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/setup/sso")

    # Navigate to the final step (Test &amp; Enable)
    # To IdP Metadata
    view |> element("button", "Next") |> render_click()
    # To Mapping Preview
    view |> element("button", "Next") |> render_click()
    # To Test &amp; Enable
    view |> element("button", "Next") |> render_click()

    html = render(view)
    assert html =~ "Enablement Receipt"

    # Gap #8: positively assert the redacted verified-line copy (UI-SPEC FLOW-03 / D-04).
    assert html =~ "Verified (enabled)"
    assert html =~ "Relyra verified SAML trust"
    assert html =~ "SAML Identity mapped to LedgerLoop User"
    assert html =~ "LedgerLoop established session"

    # Assert connection ID from real data is shown
    conn_id =
      LedgerLoop.Demo.Fixtures.relyra_connections() |> List.first() |> Map.get(:connection_id)

    assert html =~ conn_id

    # Assert no raw PEM or XML or secrets are leaked into the receipt UI.
    refute html =~ "MOCK_PEM_NOT_REAL"
    refute html =~ "<?xml"
    refute html =~ "BEGIN CERTIFICATE"
    refute html =~ "BEGIN PRIVATE KEY"
    refute html =~ "BEGIN RSA"
  end
end
