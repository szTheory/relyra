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
    
    # Click next to IdP Metadata
    view |> element("button", "Next") |> render_click()
    html = render(view)
    assert html =~ "IdP Metadata"
    assert html =~ "Save Metadata"
    
    # Submit metadata form
    view |> form("form[phx-submit=\"save_metadata\"]", %{metadata: "<EntityDescriptor />"}) |> render_submit()
    html = render(view)
    assert html =~ "Metadata saved successfully!"

    # Click next to Mapping Preview
    view |> element("button", "Next") |> render_click()
    html = render(view)
    assert html =~ "Mapping Preview"
    assert html =~ "urn:oid:0.9.2342.19200300.100.1.3"
    assert html =~ "email"

    # Click next to Test &amp; Enable
    view |> element("button", "Next") |> render_click()
    html = render(view)
    assert html =~ "Test &amp; Enable"
    
    # Test Login redirect
    conn_id = LedgerLoop.Demo.Fixtures.relyra_connections() |> List.first() |> Map.get(:connection_id)
    view |> element("button", "Start Test Login") |> render_click()
    assert_redirect(view, "/auth/saml/login?connection_id=" <> conn_id)
  end

  test "The receipt step securely renders redacted verification fields", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/setup/sso")

    # Navigate to the final step (Test &amp; Enable)
    view |> element("button", "Next") |> render_click() # To IdP Metadata
    view |> element("button", "Next") |> render_click() # To Mapping Preview
    view |> element("button", "Next") |> render_click() # To Test &amp; Enable
    
    html = render(view)
    assert html =~ "Enablement Receipt"
    
    # Assert connection ID from real data is shown
    conn_id = LedgerLoop.Demo.Fixtures.relyra_connections() |> List.first() |> Map.get(:connection_id)
    assert html =~ conn_id
    
    # Assert no raw PEM or XML is leaked
    refute html =~ "MOCK_PEM_NOT_REAL"
    refute html =~ "<?xml"
  end
end
